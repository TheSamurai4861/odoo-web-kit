const fs = require("fs");
const path = require("path");

const {
    baseUrl,
    browserLaunchOptions,
    chromium,
    database,
    getOdooAdminPassword,
    runtime,
    workspace,
} = require("./lib/browser-env.cjs");
const media = process.env.WEBKIT_MEDIA_DIR || path.join(workspace, "docs", "media");
const password = getOdooAdminPassword();
const expectedOrder = [
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
];

async function authenticate(context) {
    const response = await context.request.post(`${baseUrl}/web/session/authenticate`, {
        data: {
            jsonrpc: "2.0",
            method: "call",
            params: { db: database, login: "admin", password },
            id: 1,
        },
    });
    const body = await response.json();
    if (!response.ok() || !body.result?.uid) {
        throw new Error("Stage 7 browser authentication failed.");
    }
}

async function assertHomepage(page) {
    const images = page.locator("img:visible");
    for (let index = 0; index < await images.count(); index++) {
        const image = images.nth(index);
        await image.scrollIntoViewIfNeeded();
        await image.evaluate((element) => {
            if (element.complete && element.naturalWidth) {
                return;
            }
            return new Promise((resolve, reject) => {
                element.addEventListener("load", resolve, { once: true });
                element.addEventListener("error", reject, { once: true });
            });
        });
    }
    const evidence = await page.evaluate(() => ({
        order: [...document.querySelectorAll("#wrap > section")].map(
            (section) => section.dataset.snippet
        ),
        h1: document.querySelector("#wrap h1")?.textContent.trim(),
        brokenImages: [...document.querySelectorAll("img")]
            .filter((image) => image.getClientRects().length)
            .filter((image) => !image.complete || !image.naturalWidth)
            .map((image) => image.src),
        northlineLogo: Boolean(document.querySelector(
            "header img[alt='Northline'], header img[src*='/website/'][src*='/logo/']"
        )),
        publicChromeAbsent: !document.querySelector(
            "#oe_main_menu_navbar, .o_frontend_to_backend_nav, body.o_builder_open"
        ),
        requiredText: [
            "Odoo workflows for service teams",
            "Belgian service teams",
            "hello@northline.example",
            "Review a workflow",
            "fictional demo",
            "A fictional Odoo workflow studio",
            "Northline demo",
        ].filter((marker) => !document.body.textContent.includes(marker)),
        forbiddenText: [
            "Your Logo",
            "yourcompany",
            "+1 555",
            "Company name",
            "passionate people",
        ].filter((marker) => document.body.textContent.includes(marker)),
        invalidHrefs: [...document.querySelectorAll("header a, #wrap a, footer a")]
            .filter((anchor) => {
                const href = anchor.getAttribute("href");
                if (!href || /^javascript:/i.test(href)) {
                    return true;
                }
                if (href !== "#") {
                    return false;
                }
                const target = anchor.getAttribute("data-bs-target");
                return !target || !document.querySelector(target);
            })
            .map((anchor) => anchor.outerHTML.slice(0, 160)),
        localLinks: [...new Set([...document.querySelectorAll(
            "header a[href], #wrap a[href], footer a[href]"
        )].map((anchor) => anchor.href).filter((href) => {
            const url = new URL(href);
            return url.origin === location.origin && ["http:", "https:"].includes(url.protocol);
        }))],
        documentWidth: document.documentElement.scrollWidth,
        viewportWidth: document.documentElement.clientWidth,
    }));
    const deadLinks = [];
    for (const href of evidence.localLinks) {
        const url = new URL(href);
        if (url.pathname === "/" && url.hash) {
            const targetExists = await page.evaluate(
                (selector) => Boolean(document.querySelector(selector)),
                url.hash
            );
            if (!targetExists) {
                deadLinks.push(href);
            }
            continue;
        }
        const response = await page.request.get(href, { timeout: 30_000 });
        if (!response.ok()) {
            deadLinks.push(`${href} (${response.status()})`);
        }
    }
    evidence.deadLinks = deadLinks;
    delete evidence.localLinks;
    if (
        JSON.stringify(evidence.order) !== JSON.stringify(expectedOrder) ||
        !evidence.h1 ||
        evidence.brokenImages.length ||
        !evidence.northlineLogo ||
        !evidence.publicChromeAbsent ||
        evidence.requiredText.length ||
        evidence.forbiddenText.length ||
        evidence.invalidHrefs.length ||
        evidence.deadLinks.length ||
        evidence.documentWidth !== evidence.viewportWidth
    ) {
        throw new Error(`Invalid Northline homepage: ${JSON.stringify(evidence)}.`);
    }
    await page.evaluate(() => scrollTo(0, 0));
    return evidence;
}

async function openEditor(page) {
    await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
        waitUntil: "domcontentloaded",
        timeout: 60_000,
    });
    await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
    await page.locator("#blocks-tab.active[aria-selected='true']").waitFor({
        timeout: 30_000,
    });
    const frame = page.locator(".o_website_preview iframe").last().contentFrame();
    await frame.locator(".s_webkit_hero").first().waitFor({ timeout: 30_000 });
    return frame;
}

(async () => {
    fs.mkdirSync(media, { recursive: true });
    const browser = await chromium.launch(browserLaunchOptions());
    const browserErrors = [];
    try {
        const desktopContext = await browser.newContext({
            viewport: { width: 1440, height: 1000 },
            deviceScaleFactor: 1,
        });
        const desktop = await desktopContext.newPage();
        desktop.on("pageerror", (error) => browserErrors.push(error.message));
        await desktop.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const desktopEvidence = await assertHomepage(desktop);
        await desktop.screenshot({
            path: path.join(media, "homepage-desktop.png"),
            fullPage: true,
        });
        await desktop.locator("#wrap").screenshot({
            path: path.join(media, "four-components.png"),
        });
        await desktopContext.close();

        const mobileContext = await browser.newContext({
            viewport: { width: 390, height: 844 },
            deviceScaleFactor: 1,
        });
        const mobile = await mobileContext.newPage();
        mobile.on("pageerror", (error) => browserErrors.push(error.message));
        await mobile.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const mobileEvidence = await assertHomepage(mobile);
        await mobile.screenshot({
            path: path.join(media, "homepage-mobile.png"),
            fullPage: true,
        });
        await mobileContext.close();

        const builderContext = await browser.newContext({
            viewport: { width: 1440, height: 1000 },
            deviceScaleFactor: 1,
        });
        await authenticate(builderContext);
        const builder = await builderContext.newPage();
        builder.on("pageerror", (error) => browserErrors.push(error.message));
        const frame = await openEditor(builder);
        await builder.screenshot({
            path: path.join(media, "website-builder.png"),
        });

        const groupTitle = builder.getByText("Web Kit", { exact: true });
        await groupTitle.waitFor({ timeout: 30_000 });
        const group = groupTitle
            .locator("xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]")
            .locator("xpath=..");
        await group.dragTo(frame.locator("#wrapwrap > footer"), { timeout: 30_000 });
        await builder.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
        for (const snippetId of expectedOrder) {
            await builder
                .frameLocator("#tabpanel_webkit")
                .locator(`.o_snippet_preview_wrap[data-snippet-id='${snippetId}']`)
                .waitFor({ timeout: 30_000 });
        }
        await builder.screenshot({
            path: path.join(media, "web-kit-category.png"),
        });
        await builder.keyboard.press("Escape");
        await builder.locator(".o_add_snippet_dialog").waitFor({ state: "hidden" });

        const hero = frame.locator(".s_webkit_hero").first();
        await hero.scrollIntoViewIfNeeded();
        await hero.click({ position: { x: 8, y: 8 } });
        for (const label of ["Content alignment", "Visual position", "Tone"]) {
            await builder.getByText(label, { exact: true }).waitFor({ timeout: 30_000 });
        }
        await builder.screenshot({
            path: path.join(media, "hero-options.png"),
        });
        await builderContext.close();

        if (browserErrors.length) {
            throw new Error(`Browser errors: ${browserErrors.join(" | ")}`);
        }
        console.log(JSON.stringify({
            captures: [
                "homepage-desktop.png",
                "homepage-mobile.png",
                "four-components.png",
                "website-builder.png",
                "web-kit-category.png",
                "hero-options.png",
            ],
            desktop: desktopEvidence,
            mobile: mobileEvidence,
            browserErrors,
        }, null, 2));
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
