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

const baseUrl = "http://127.0.0.1:8070";
const database = "webkit_qa_stage6";
const snippetIds = [
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
];
const password = fs.readFileSync(
    path.join(runtime, "secrets", "odoo-admin-password"),
    "utf8"
).trim();

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
        throw new Error(`Fresh database authentication failed: ${JSON.stringify(body)}.`);
    }
}

(async () => {
    const browser = await chromium.launch({
        executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
        headless: true,
    });
    try {
        const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
        await authenticate(context);
        const page = await context.newPage();
        const browserErrors = [];
        page.on("pageerror", (error) => browserErrors.push(error.message));

        await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
            waitUntil: "domcontentloaded",
            timeout: 60_000,
        });
        await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
        const frame = page.locator(".o_website_preview iframe").last().contentFrame();
        await frame.locator("#wrapwrap > footer").waitFor({ timeout: 30_000 });
        const initialSnippets = await frame.locator("#wrap > section[data-snippet]").count();
        if (initialSnippets !== 0) {
            throw new Error(`Fresh homepage already contains ${initialSnippets} snippets.`);
        }

        const groupTitle = page.getByText("Web Kit", { exact: true });
        await groupTitle.waitFor({ timeout: 30_000 });
        const draggable = groupTitle
            .locator("xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]")
            .locator("xpath=..");
        if (!(await draggable.getAttribute("class"))?.includes("o_draggable")) {
            throw new Error("Fresh Web Kit group is not draggable.");
        }
        await draggable.dragTo(frame.locator("#wrapwrap > footer"), { timeout: 30_000 });
        await page.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
        for (const snippetId of snippetIds) {
            await page
                .frameLocator("#tabpanel_webkit")
                .locator(`.o_snippet_preview_wrap[data-snippet-id='${snippetId}']`)
                .waitFor({ timeout: 30_000 });
        }

        await page
            .frameLocator("#tabpanel_webkit")
            .locator(".o_snippet_preview_wrap[data-snippet-id='s_webkit_hero']")
            .click();
        await page.locator(".o_add_snippet_dialog").waitFor({
            state: "hidden",
            timeout: 30_000,
        });

        const hero = frame.locator(".s_webkit_hero");
        await hero.waitFor({ timeout: 30_000 });
        await hero.click({ position: { x: 8, y: 8 } });
        await page
            .locator(
                ".hb-row[data-label='Content alignment'] " +
                "button[data-class-action='webkit_hero_align_center']"
            )
            .click();
        if (!(await hero.getAttribute("class")).includes("webkit_hero_align_center")) {
            throw new Error("Fresh Hero option did not update the editor DOM.");
        }

        await page.getByRole("button", { name: "Save", exact: true }).click();
        await page.waitForFunction(
            () => !document.body.classList.contains("o_builder_open"),
            undefined,
            { timeout: 60_000 }
        );
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });

        const state = await page.evaluate(() => {
            const heroElement = document.querySelector(".s_webkit_hero");
            return {
                heroCount: document.querySelectorAll(".s_webkit_hero").length,
                centered: heroElement?.classList.contains("webkit_hero_align_center"),
                defaultRemoved: !heroElement?.classList.contains("webkit_hero_align_start"),
                brokenImages: [...document.querySelectorAll(".s_webkit_hero img")]
                    .filter((image) => !image.complete || !image.naturalWidth)
                    .map((image) => image.src),
                documentWidth: document.documentElement.scrollWidth,
                viewportWidth: document.documentElement.clientWidth,
            };
        });
        await page.screenshot({
            path: path.join(runtime, "stage6-fresh-hero.png"),
            fullPage: true,
        });

        if (
            state.heroCount !== 1 ||
            !state.centered ||
            !state.defaultRemoved ||
            state.brokenImages.length ||
            state.documentWidth !== state.viewportWidth ||
            browserErrors.length
        ) {
            throw new Error(`Fresh database browser assertions failed: ${JSON.stringify({
                state,
                browserErrors,
            })}.`);
        }

        console.log(JSON.stringify({
            database,
            fourPreviews: snippetIds,
            inserted: "s_webkit_hero",
            optionPersistence: "webkit_hero_align_center",
            state,
            browserErrors,
        }, null, 2));
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
