const fs = require("fs");
const path = require("path");

const workspace = path.resolve(__dirname, "..");
const odooRoot = path.resolve(workspace, "..");
const runtime = path.join(odooRoot, ".runtime");
const { chromium } = require(path.join(
    runtime,
    "browser-check",
    "node_modules",
    "playwright-core"
));

const baseUrl = "http://127.0.0.1:8069";
const password = fs.readFileSync(
    path.join(runtime, "secrets", "odoo-admin-password"),
    "utf8"
).trim();
const canonicalOrder = [
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
];
const widths = [1440, 1024, 768, 390, 360];

const defaults = {
    alignment: "webkit_hero_align_start",
    media: "webkit_hero_media_end",
    tone: "o_cc1",
};
const variants = {
    alignment: "webkit_hero_align_center",
    media: "webkit_hero_media_start",
    tone: "o_cc5",
};

function parseRgb(value) {
    const channels = value.match(/[\d.]+/g)?.slice(0, 3).map(Number);
    if (!channels || channels.length !== 3) {
        throw new Error(`Cannot parse CSS color ${value}.`);
    }
    return channels;
}

function luminance(value) {
    const channels = parseRgb(value).map((channel) => {
        const normalized = channel / 255;
        return normalized <= 0.04045
            ? normalized / 12.92
            : Math.pow((normalized + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

function contrast(first, second) {
    const firstLuminance = luminance(first);
    const secondLuminance = luminance(second);
    return (Math.max(firstLuminance, secondLuminance) + 0.05) /
        (Math.min(firstLuminance, secondLuminance) + 0.05);
}

async function authenticate(context) {
    const response = await context.request.post(`${baseUrl}/web/session/authenticate`, {
        data: {
            jsonrpc: "2.0",
            method: "call",
            params: { db: "webkit_dev", login: "admin", password },
            id: 1,
        },
    });
    const body = await response.json();
    if (!response.ok() || !body.result?.uid) {
        throw new Error("Browser authentication failed.");
    }
}

async function callKw(context, model, method, args = [], kwargs = {}) {
    const response = await context.request.post(
        `${baseUrl}/web/dataset/call_kw/${model}/${method}`,
        {
            data: {
                jsonrpc: "2.0",
                method: "call",
                params: { model, method, args, kwargs },
                id: Date.now(),
            },
        }
    );
    const body = await response.json();
    if (!response.ok() || body.error) {
        throw new Error(`RPC ${model}.${method} failed: ${JSON.stringify(body.error)}.`);
    }
    return body.result;
}

async function openEditor(page) {
    await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
        waitUntil: "domcontentloaded",
        timeout: 60_000,
    });
    await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
    const frame = page.locator(".o_website_preview iframe").last().contentFrame();
    await frame.locator(".s_webkit_hero").first().waitFor({ timeout: 30_000 });
    return frame;
}

async function selectHero(page, frame, index = 0) {
    const hero = frame.locator(".s_webkit_hero").nth(index);
    await hero.scrollIntoViewIfNeeded();
    await hero.click({ position: { x: 8, y: 8 } });
    await page.getByText("Content alignment", { exact: true }).waitFor({ timeout: 30_000 });
    await page.getByText("Visual position", { exact: true }).waitFor({ timeout: 30_000 });
    await page.getByText("Tone", { exact: true }).waitFor({ timeout: 30_000 });
    return hero;
}

function optionButton(page, rowLabel, classAction) {
    return page.locator(
        `.hb-row[data-label='${rowLabel}'] button[data-class-action='${classAction}']`
    );
}

async function applyOption(page, hero, rowLabel, classAction) {
    await optionButton(page, rowLabel, classAction).click();
    await hero.evaluate((element, expectedClass) => {
        if (!element.classList.contains(expectedClass)) {
            throw new Error(`Class ${expectedClass} was not applied by the builder.`);
        }
    }, classAction);
}

async function saveEditor(page) {
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await page.waitForFunction(
        () => !document.body.classList.contains("o_builder_open"),
        undefined,
        { timeout: 60_000 }
    );
}

async function publicEvidence(page, width, heroIndex = 0) {
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
    const hero = page.locator(".s_webkit_hero").nth(heroIndex);
    await hero.waitFor({ timeout: 30_000 });
    return hero.evaluate((element) => {
        const columns = element.querySelectorAll(":scope > .container > .row > .col-xl-6");
        const rect = (node) => node.getBoundingClientRect();
        const style = getComputedStyle(element);
        return {
            classes: [...element.classList],
            textAlign: getComputedStyle(columns[0]).textAlign,
            contentLeft: Math.round(rect(columns[0]).left),
            visualLeft: Math.round(rect(columns[1]).left),
            backgroundColor: style.backgroundColor,
            color: style.color,
            minimumActionHeight: Math.min(
                ...[...element.querySelectorAll("a, button")].map((action) =>
                    Math.round(rect(action).height)
                )
            ),
            documentWidth: element.ownerDocument.documentElement.scrollWidth,
            viewportWidth: element.ownerDocument.documentElement.clientWidth,
            clipped: [...element.querySelectorAll("h1, p, a")].some((node) => {
                const nodeStyle = getComputedStyle(node);
                const masks = [nodeStyle.overflow, nodeStyle.overflowX, nodeStyle.overflowY]
                    .some((value) => ["hidden", "clip"].includes(value));
                return masks && (
                    node.scrollWidth > node.clientWidth + 1 ||
                    node.scrollHeight > node.clientHeight + 1
                );
            }),
            brokenImages: [...element.querySelectorAll("img")]
                .filter((image) => !image.complete || !image.naturalWidth)
                .map((image) => image.src),
        };
    });
}

function assertVariantClasses(evidence) {
    for (const className of Object.values(variants)) {
        if (!evidence.classes.includes(className)) {
            throw new Error(`Missing variant class ${className}: ${evidence.classes}.`);
        }
    }
    for (const className of Object.values(defaults)) {
        if (evidence.classes.includes(className)) {
            throw new Error(`Default class ${className} was not cleaned: ${evidence.classes}.`);
        }
    }
}

(async () => {
    const browser = await chromium.launch({
        executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
        headless: true,
    });
    let context;
    let originalHomepage;
    const browserErrors = [];
    try {
        context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
        await authenticate(context);
        const page = await context.newPage();
        page.on("pageerror", (error) => browserErrors.push(error.message));

        const homepages = await callKw(context, "ir.ui.view", "search_read", [[
            ["key", "=", "website.homepage"],
            ["website_id", "!=", false],
        ]], {
            fields: ["arch_db"],
            order: "website_id, id",
            limit: 1,
        });
        if (homepages.length !== 1) {
            throw new Error(`Expected one website homepage, found ${homepages.length}.`);
        }
        originalHomepage = homepages[0];

        let frame = await openEditor(page);
        let hero = await selectHero(page, frame);

        // Verify explicit deterministic defaults in both DOM and option UI.
        const initialClasses = await hero.evaluate((element) => [...element.classList]);
        for (const [key, className] of Object.entries(defaults)) {
            if (!initialClasses.includes(className)) {
                throw new Error(`Missing default ${key} class ${className}.`);
            }
        }
        for (const [row, className] of [
            ["Content alignment", defaults.alignment],
            ["Visual position", defaults.media],
            ["Tone", defaults.tone],
        ]) {
            if (!(await optionButton(page, row, className).getAttribute("class")).includes("active")) {
                throw new Error(`Default option ${row}/${className} is not active.`);
            }
        }

        await applyOption(page, hero, "Content alignment", variants.alignment);
        await applyOption(page, hero, "Visual position", variants.media);
        await applyOption(page, hero, "Tone", variants.tone);
        await saveEditor(page);

        // Persisted combined variant must remain sound at every roadmap width.
        const responsive = [];
        for (const width of widths) {
            const evidence = await publicEvidence(page, width);
            assertVariantClasses(evidence);
            if (
                evidence.documentWidth !== evidence.viewportWidth ||
                evidence.clipped ||
                evidence.brokenImages.length ||
                evidence.minimumActionHeight < 44
            ) {
                throw new Error(`Variant responsive failure at ${width}px: ${JSON.stringify(evidence)}.`);
            }
            if (evidence.textAlign !== "center") {
                throw new Error(`Centered alignment did not persist at ${width}px.`);
            }
            const toneContrast = contrast(evidence.color, evidence.backgroundColor);
            if (toneContrast < 4.5) {
                throw new Error(
                    `Contrast tone fails WCAG AA at ${width}px: ${toneContrast.toFixed(2)}:1.`
                );
            }
            if (width >= 1200 && evidence.visualLeft >= evidence.contentLeft) {
                throw new Error(`Visual was not moved left at ${width}px: ${JSON.stringify(evidence)}.`);
            }
            responsive.push({
                width,
                documentWidth: evidence.documentWidth,
                textAlign: evidence.textAlign,
                visualBeforeContent: width >= 1200
                    ? evidence.visualLeft < evidence.contentLeft
                    : "stacked",
                minimumActionHeight: evidence.minimumActionHeight,
                toneContrast: Number(toneContrast.toFixed(2)),
            });
        }

        // Reopen: active controls must reflect persisted classes.
        await page.setViewportSize({ width: 1440, height: 1000 });
        frame = await openEditor(page);
        hero = await selectHero(page, frame);
        for (const [row, className] of [
            ["Content alignment", variants.alignment],
            ["Visual position", variants.media],
            ["Tone", variants.tone],
        ]) {
            if (!(await optionButton(page, row, className).getAttribute("class")).includes("active")) {
                throw new Error(`Persisted option ${row}/${className} is not active after reload.`);
            }
        }

        // Duplicate the configured block, then reset only the first instance.
        await page.locator("button.oe_snippet_clone[title='Duplicate this block']").click();
        await frame.locator(".s_webkit_hero").nth(1).waitFor({ timeout: 30_000 });
        hero = await selectHero(page, frame, 0);
        await applyOption(page, hero, "Content alignment", defaults.alignment);
        await applyOption(page, hero, "Visual position", defaults.media);
        await applyOption(page, hero, "Tone", defaults.tone);

        const editorInstances = await frame.locator(".s_webkit_hero").evaluateAll((elements) =>
            elements.map((element) => [...element.classList])
        );
        for (const className of Object.values(defaults)) {
            if (!editorInstances[0].includes(className)) {
                throw new Error(`First duplicate instance did not reset ${className}.`);
            }
        }
        for (const className of Object.values(variants)) {
            if (!editorInstances[1].includes(className)) {
                throw new Error(`Second duplicate instance lost ${className}.`);
            }
        }
        await saveEditor(page);

        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const persistedInstances = await page.locator(".s_webkit_hero").evaluateAll((elements) =>
            elements.map((element) => [...element.classList])
        );
        if (persistedInstances.length !== 2) {
            throw new Error(`Expected two persisted Hero instances, found ${persistedInstances.length}.`);
        }
        for (const className of Object.values(defaults)) {
            if (!persistedInstances[0].includes(className)) {
                throw new Error(`Persisted first instance lost ${className}.`);
            }
        }
        for (const className of Object.values(variants)) {
            if (!persistedInstances[1].includes(className)) {
                throw new Error(`Persisted second instance lost ${className}.`);
            }
        }

        await page.screenshot({
            path: path.join(runtime, "stage5-options-persisted.png"),
            fullPage: true,
        });
        if (browserErrors.length) {
            throw new Error(`Browser errors: ${browserErrors.join(" | ")}`);
        }

        await callKw(context, "ir.ui.view", "write", [
            [originalHomepage.id],
            { arch_db: originalHomepage.arch_db },
        ]);
        originalHomepage = undefined;
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const restored = await page.locator("#wrap > section").evaluateAll((sections) =>
            sections.map((section) => section.dataset.snippet)
        );
        if (JSON.stringify(restored) !== JSON.stringify(canonicalOrder)) {
            throw new Error(`Canonical cleanup failed: ${restored}.`);
        }

        console.log(JSON.stringify({
            options: ["Content alignment", "Visual position", "Tone"],
            defaults,
            variants,
            variantPersistence: true,
            responsive,
            duplicateIsolation: true,
            cleanup: "canonical homepage restored",
            browserErrors,
        }, null, 2));
    } finally {
        if (context && originalHomepage) {
            await callKw(context, "ir.ui.view", "write", [
                [originalHomepage.id],
                { arch_db: originalHomepage.arch_db },
            ]);
        }
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
