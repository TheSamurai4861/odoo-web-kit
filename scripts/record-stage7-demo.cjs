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
const rawVideo = path.join(runtime, "stage7-demo-raw.webm");
const demoTitle = "Map client handoffs directly in Odoo.";
const password = getOdooAdminPassword();
const repositoryUrl = process.env.WEBKIT_REPOSITORY_URL;
if (!repositoryUrl || new URL(repositoryUrl).protocol !== "https:") {
    throw new Error("WEBKIT_REPOSITORY_URL must contain the public HTTPS repository URL.");
}

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
        throw new Error("Demo authentication failed.");
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

async function pause(page, milliseconds) {
    await page.waitForTimeout(milliseconds);
}

(async () => {
    fs.mkdirSync(media, { recursive: true });
    if (fs.existsSync(rawVideo)) {
        fs.unlinkSync(rawVideo);
    }
    const browser = await chromium.launch(browserLaunchOptions({
        args: ["--disable-features=SpellcheckService,UseBrowserSpellChecker"],
    }));
    let context;
    let originalHomepage;
    let video;
    try {
        context = await browser.newContext({
            viewport: { width: 1280, height: 720 },
            recordVideo: {
                dir: runtime,
                size: { width: 1280, height: 720 },
            },
        });
        const page = await context.newPage();
        video = page.video();
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        if (await page.locator(
            "#oe_main_menu_navbar, .o_frontend_to_backend_nav, body.o_builder_open"
        ).count()) {
            throw new Error("The opening walkthrough is not an anonymous public session.");
        }
        await pause(page, 4_000);
        await page.locator(".s_webkit_features").scrollIntoViewIfNeeded();
        await pause(page, 3_000);
        await page.locator(".s_webkit_trust").scrollIntoViewIfNeeded();
        await pause(page, 3_000);
        await page.locator(".s_webkit_cta").scrollIntoViewIfNeeded();
        await pause(page, 3_000);

        await authenticate(context);
        const homepages = await callKw(context, "ir.ui.view", "search_read", [[
            ["key", "=", "website.homepage"],
            ["website_id", "!=", false],
        ]], {
            fields: ["arch_db"],
            order: "website_id, id",
            limit: 1,
        });
        if (homepages.length !== 1) {
            throw new Error(`Expected one homepage, found ${homepages.length}.`);
        }
        originalHomepage = homepages[0];

        await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
            waitUntil: "domcontentloaded",
            timeout: 60_000,
        });
        await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
        const frame = page.locator(".o_website_preview iframe").last().contentFrame();
        await frame.locator(".s_webkit_hero").first().waitFor({ timeout: 30_000 });
        await pause(page, 5_000);

        const groupTitle = page.getByText("Web Kit", { exact: true });
        const group = groupTitle
            .locator("xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]")
            .locator("xpath=..");
        await group.dragTo(frame.locator("#wrapwrap > footer"), { timeout: 30_000 });
        await page.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
        await pause(page, 7_000);

        await page
            .frameLocator("#tabpanel_webkit")
            .locator(".o_snippet_preview_wrap[data-snippet-id='s_webkit_hero']")
            .click();
        await page.locator(".o_add_snippet_dialog").waitFor({
            state: "hidden",
            timeout: 30_000,
        });
        const insertedHero = frame.locator(".s_webkit_hero").last();
        await insertedHero.scrollIntoViewIfNeeded();
        await pause(page, 5_000);

        const heading = insertedHero.locator("h1");
        await heading.click({ force: true });
        await heading.evaluate((element) => {
            element.spellcheck = false;
            const selection = element.ownerDocument.getSelection();
            const range = element.ownerDocument.createRange();
            range.selectNodeContents(element);
            selection.removeAllRanges();
            selection.addRange(range);
        });
        await page.keyboard.insertText(demoTitle);
        await pause(page, 5_000);

        await insertedHero.click({ position: { x: 8, y: 120 }, force: true });
        const center = page.locator(
            ".hb-row[data-label='Content alignment'] " +
            "button[data-class-action='webkit_hero_align_center']"
        );
        await center.waitFor({ timeout: 30_000 });
        await center.click();
        await pause(page, 5_000);

        await page.getByRole("button", { name: "Save", exact: true }).click();
        await page.waitForFunction(
            () => !document.body.classList.contains("o_builder_open"),
            undefined,
            { timeout: 60_000 }
        );
        await pause(page, 4_000);
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        await page.getByRole("heading", { name: demoTitle }).waitFor({ timeout: 30_000 });
        await pause(page, 4_000);

        await context.clearCookies();
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        if (await page.locator(
            "#oe_main_menu_navbar, .o_frontend_to_backend_nav, body.o_builder_open"
        ).count()) {
            throw new Error("The closing walkthrough is not an anonymous public session.");
        }
        await pause(page, 4_000);
        await page.locator(".s_webkit_features").scrollIntoViewIfNeeded();
        await pause(page, 3_000);
        await page.locator(".s_webkit_cta").scrollIntoViewIfNeeded();
        await pause(page, 4_000);

        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        await page.evaluate((url) => {
            const label = document.createElement("div");
            label.setAttribute("data-webkit-repository", "");
            label.textContent = url;
            Object.assign(label.style, {
                position: "fixed",
                left: "50%",
                top: "78px",
                transform: "translateX(-50%)",
                zIndex: "2147483647",
                padding: "12px 20px",
                borderRadius: "999px",
                background: "rgba(20, 22, 31, 0.94)",
                color: "white",
                font: "600 18px/1.3 system-ui, sans-serif",
                boxShadow: "0 12px 36px rgba(0, 0, 0, 0.3)",
                whiteSpace: "nowrap",
            });
            document.body.append(label);
        }, repositoryUrl);
        await pause(page, 6_000);

        const restoreContext = await browser.newContext();
        await authenticate(restoreContext);
        await callKw(restoreContext, "ir.ui.view", "write", [
            [originalHomepage.id],
            { arch_db: originalHomepage.arch_db },
        ]);
        await restoreContext.close();
        originalHomepage = undefined;
        await page.close();
        await context.close();
        context = undefined;
        await video.saveAs(rawVideo);
        console.log(JSON.stringify({ rawVideo, repositoryUrl, restored: true }, null, 2));
    } finally {
        if (originalHomepage) {
            const recoveryContext = await browser.newContext();
            try {
                await authenticate(recoveryContext);
                await callKw(recoveryContext, "ir.ui.view", "write", [
                    [originalHomepage.id],
                    { arch_db: originalHomepage.arch_db },
                ]);
            } finally {
                await recoveryContext.close();
            }
        }
        if (context) {
            await context.close();
        }
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
