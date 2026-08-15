const path = require("path");

const {
    baseUrl,
    browserLaunchOptions,
    chromium,
    database,
    getOdooAdminPassword,
    runtime,
} = require("./lib/browser-env.cjs");
const password = getOdooAdminPassword();
const expectedText = "Stage 2 verified";

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
        throw new Error("Browser authentication failed.");
    }
}

async function openEditor(page) {
    await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
        waitUntil: "domcontentloaded",
        timeout: 60_000,
    });
    await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
}

(async () => {
    const browser = await chromium.launch(browserLaunchOptions());
    const browserErrors = [];
    try {
        const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
        await authenticate(context);
        const page = await context.newPage();
        page.on("pageerror", (error) => browserErrors.push(error.message));
        await openEditor(page);

        const categoryTitle = page.getByText("Web Kit", { exact: true });
        await categoryTitle.waitFor({ timeout: 30_000 });
        const thumbnail = categoryTitle.locator(
            "xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]"
        );
        const draggable = thumbnail.locator("xpath=..");
        if (!(await draggable.getAttribute("class"))?.includes("o_draggable")) {
            throw new Error("The Web Kit category is not draggable.");
        }

        const websiteFrame = page.locator(".o_website_preview iframe").last().contentFrame();
        const target = websiteFrame.locator("#wrapwrap > footer");
        await target.waitFor({ timeout: 30_000 });
        await draggable.dragTo(target, { timeout: 30_000 });
        await page.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
        await page.locator("#tab_webkit.active[aria-selected='true']").waitFor({ timeout: 30_000 });
        await page
            .frameLocator("#tabpanel_webkit")
            .locator(".o_snippet_preview_wrap[data-snippet-id='s_webkit_hello']")
            .waitFor({ timeout: 30_000 });
        await page.screenshot({ path: path.join(runtime, "stage2-drag-dialog.png"), fullPage: true });

        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const section = page.locator(".s_webkit_hello");
        await section.waitFor({ timeout: 30_000 });
        const heading = (await section.locator("h2").innerText()).trim();
        const metadata = await section.evaluate((element) => ({
            snippet: element.dataset.snippet,
            name: element.dataset.name,
        }));
        const styles = await section.locator(".webkit_hello_card").evaluate((element) => {
            const style = getComputedStyle(element);
            return {
                borderStyle: style.borderTopStyle,
                borderWidth: style.borderTopWidth,
                borderRadius: style.borderTopLeftRadius,
                boxShadow: style.boxShadow,
            };
        });
        await page.screenshot({ path: path.join(runtime, "stage2-persisted.png"), fullPage: true });

        const evidence = { heading, metadata, styles, browserErrors };
        console.log(JSON.stringify(evidence, null, 2));
        if (
            !heading.includes(expectedText) ||
            metadata.snippet !== "s_webkit_hello" ||
            metadata.name !== "Hello Web Kit" ||
            styles.borderStyle !== "solid" ||
            styles.borderWidth !== "1px" ||
            styles.boxShadow === "none" ||
            browserErrors.length
        ) {
            throw new Error("Stage 2 browser assertions failed.");
        }
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
