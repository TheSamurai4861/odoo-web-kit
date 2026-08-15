const path = require("path");

const {
    browserLaunchOptions,
    chromium,
    getOdooAdminPassword,
    qaBaseUrl: baseUrl,
    qaDatabase: database,
    runtime,
} = require("./lib/browser-env.cjs");
const snippetIds = [
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
];
const password = getOdooAdminPassword();

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

async function openEditor(page) {
    await page.goto(`${baseUrl}/@/?enable_editor=1`, {
        waitUntil: "domcontentloaded",
        timeout: 120_000,
    });
    await page.waitForSelector("body.o_builder_open", { timeout: 120_000 });
    const frame = page.locator(".o_website_preview iframe").last().contentFrame();
    await frame.locator("#wrapwrap > footer").waitFor({ timeout: 30_000 });
    return frame;
}

(async () => {
    const browser = await chromium.launch(browserLaunchOptions());
    try {
        const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
        await authenticate(context);
        const page = await context.newPage();
        const browserErrors = [];
        page.on("pageerror", (error) => browserErrors.push(error.message));

        // The lifecycle test exercises the production asset path. Debug assets
        // are already covered on the persistent development database and can
        // take more than one minute to compile from a completely cold DB.
        let frame = await openEditor(page);
        const initialSnippets = await frame.locator("#wrap > section[data-snippet]").count();
        if (initialSnippets !== 0) {
            throw new Error(`Fresh homepage already contains ${initialSnippets} snippets.`);
        }

        async function insertSnippet(snippetId) {
            console.log(`fresh_builder_insert=${snippetId}`);
            const blocksTab = page.locator("#blocks-tab");
            await blocksTab.click();
            await page.locator("#blocks-tab.active[aria-selected='true']").waitFor({
                timeout: 30_000,
            });
            const groupTitle = page.getByText("Web Kit", { exact: true });
            await groupTitle.waitFor({ timeout: 30_000 });
            const draggable = groupTitle
                .locator("xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]")
                .locator("xpath=..");
            if (!(await draggable.getAttribute("class"))?.includes("o_draggable")) {
                throw new Error("Fresh Web Kit group is not draggable.");
            }
            const insertedSections = frame.locator("#wrap > section[data-snippet]");
            const dropTarget = (await insertedSections.count())
                ? insertedSections.last()
                : frame.locator("#wrapwrap > footer");
            await dropTarget.scrollIntoViewIfNeeded();
            const targetBox = await dropTarget.boundingBox();
            await draggable.dragTo(dropTarget, {
                targetPosition: targetBox
                    ? { x: Math.round(targetBox.width / 2), y: targetBox.height - 5 }
                    : undefined,
                timeout: 30_000,
            });
            try {
                await page.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
            } catch (error) {
                throw new Error(`Snippet dialog did not open for ${snippetId}.`, { cause: error });
            }
            for (const expectedId of snippetIds) {
                await page
                    .frameLocator("#tabpanel_webkit")
                    .locator(`.o_snippet_preview_wrap[data-snippet-id='${expectedId}']`)
                    .waitFor({ timeout: 30_000 });
            }
            await page
                .frameLocator("#tabpanel_webkit")
                .locator(`.o_snippet_preview_wrap[data-snippet-id='${snippetId}']`)
                .click();
            await page.locator(".o_add_snippet_dialog").waitFor({
                state: "hidden",
                timeout: 30_000,
            });
            await frame.locator(`.${snippetId}`).waitFor({ timeout: 30_000 });
        }

        for (const [index, snippetId] of snippetIds.entries()) {
            await insertSnippet(snippetId);
            if (snippetId === "s_webkit_hero") {
                const hero = frame.locator(".s_webkit_hero");
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
            }

            await page.getByRole("button", { name: "Save", exact: true }).click();
            await page.waitForFunction(
                () => !document.body.classList.contains("o_builder_open"),
                undefined,
                { timeout: 60_000 }
            );
            if (index < snippetIds.length - 1) {
                frame = await openEditor(page);
            }
        }
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });

        const state = await page.evaluate(() => {
            const heroElement = document.querySelector(".s_webkit_hero");
            const snippetIds = [
                "s_webkit_hero",
                "s_webkit_features",
                "s_webkit_trust",
                "s_webkit_cta",
            ];
            return {
                heroCount: document.querySelectorAll(".s_webkit_hero").length,
                centered: heroElement?.classList.contains("webkit_hero_align_center"),
                defaultRemoved: !heroElement?.classList.contains("webkit_hero_align_start"),
                order: [...document.querySelectorAll("#wrap > section")]
                    .map((section) => snippetIds.find((id) => section.classList.contains(id)))
                    .filter(Boolean),
                brokenImages: [...document.querySelectorAll("#wrap > section[class*='s_webkit_'] img")]
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
            JSON.stringify(state.order) !== JSON.stringify(snippetIds) ||
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
            inserted: snippetIds,
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
