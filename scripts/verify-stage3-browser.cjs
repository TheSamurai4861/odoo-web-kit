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
const editedText = "Clear workflows, designed and edited directly in Odoo.";

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
    await frame.locator(".s_webkit_hero").waitFor({ timeout: 30_000 });
    return frame;
}

async function saveEditor(page) {
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await page.waitForFunction(
        () => !document.body.classList.contains("o_builder_open"),
        undefined,
        { timeout: 60_000 }
    );
}

async function getPublicState(page) {
    await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
    return page.evaluate(() => ({
        order: [...document.querySelectorAll("#wrap > section")].map(
            (section) => section.dataset.snippet
        ),
        heroLead: document.querySelector(".s_webkit_hero p.lead")?.textContent.trim(),
        featureCount: document.querySelectorAll(".s_webkit_features").length,
    }));
}

async function selectSection(frame, selector) {
    const section = frame.locator(selector);
    await section.scrollIntoViewIfNeeded();
    await section.click({ position: { x: 8, y: 8 } });
    return section;
}

(async () => {
    const browser = await chromium.launch({
        executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
        headless: true,
    });
    const browserErrors = [];
    let context;
    let originalHomepage;
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
        const initialState = await getPublicState(page);
        if (JSON.stringify(initialState.order) !== JSON.stringify(canonicalOrder)) {
            throw new Error(`The test requires the canonical homepage: ${JSON.stringify(initialState)}.`);
        }

        let frame = await openEditor(page);

        // The group is draggable and opens a dialog containing all four snippets.
        const categoryTitle = page.getByText("Web Kit", { exact: true });
        await categoryTitle.waitFor({ timeout: 30_000 });
        const categoryThumbnail = categoryTitle.locator(
            "xpath=ancestor::*[contains(@class, 'o_snippet_thumbnail')][1]"
        );
        const categoryDraggable = categoryThumbnail.locator("xpath=..");
        if (!(await categoryDraggable.getAttribute("class"))?.includes("o_draggable")) {
            throw new Error("The Web Kit group is not draggable.");
        }
        await categoryDraggable.dragTo(frame.locator("#wrapwrap > footer"), {
            timeout: 30_000,
        });
        await page.locator(".o_add_snippet_dialog").waitFor({ timeout: 30_000 });
        await page.locator("#tab_webkit.active[aria-selected='true']").waitFor({
            timeout: 30_000,
        });
        for (const snippetId of canonicalOrder) {
            await page
                .frameLocator("#tabpanel_webkit")
                .locator(`.o_snippet_preview_wrap[data-snippet-id='${snippetId}']`)
                .waitFor({ timeout: 30_000 });
        }
        await page.keyboard.press("Escape");
        await page.locator(".o_add_snippet_dialog").waitFor({ state: "hidden" });

        // Standard image options prove that the relevant Hero visual is editable.
        await frame.locator(".s_webkit_hero .webkit_hero_image").click();
        await page.getByText("Replace", { exact: true }).waitFor({ timeout: 30_000 });

        // Links remain native anchors and are therefore editable by Odoo's link tool.
        const primaryLink = frame.locator(".s_webkit_hero a.btn-primary").first();
        if ((await primaryLink.getAttribute("href")) !== "/contactus") {
            throw new Error("The Hero primary CTA is not a native internal link.");
        }

        // Edit text through the iframe's browser editing surface, then save and reload.
        const lead = frame.locator(".s_webkit_hero p.lead").first();
        await lead.click();
        await lead.evaluate((element) => {
            const selection = element.ownerDocument.getSelection();
            const range = element.ownerDocument.createRange();
            range.selectNodeContents(element);
            selection.removeAllRanges();
            selection.addRange(range);
        });
        await page.keyboard.insertText(editedText);
        await lead.waitFor({ state: "visible" });
        if ((await lead.innerText()).trim() !== editedText) {
            throw new Error("Text editing did not update the Hero lead.");
        }
        await saveEditor(page);
        let state = await getPublicState(page);
        if (state.heroLead !== editedText || JSON.stringify(state.order) !== JSON.stringify(canonicalOrder)) {
            throw new Error(`Text persistence failed: ${JSON.stringify(state)}.`);
        }

        // Duplicate with the Website Builder control, save, and verify persistence.
        frame = await openEditor(page);
        await selectSection(frame, ".s_webkit_features");
        await page.locator("button.oe_snippet_clone[title='Duplicate this block']").click();
        await frame.locator(".s_webkit_features").nth(1).waitFor({ timeout: 30_000 });
        await saveEditor(page);
        state = await getPublicState(page);
        if (state.featureCount !== 2) {
            throw new Error(`Snippet duplication did not persist: ${JSON.stringify(state)}.`);
        }

        // Move CTA before Trust with the native drag handle, save, and verify order.
        frame = await openEditor(page);
        await selectSection(frame, ".s_webkit_cta");
        const trust = frame.locator(".s_webkit_trust");
        await page
            .locator("button.o_move_handle[title='Drag and move']")
            .dragTo(trust, { targetPosition: { x: 20, y: 5 }, timeout: 30_000 });
        await page.waitForTimeout(1_000);
        const editorOrder = await frame.locator("#wrap > section").evaluateAll((sections) =>
            sections.map((section) => section.dataset.snippet)
        );
        if (editorOrder.indexOf("s_webkit_cta") > editorOrder.indexOf("s_webkit_trust")) {
            throw new Error(`Snippet move did not change editor order: ${editorOrder}.`);
        }
        await saveEditor(page);
        state = await getPublicState(page);
        if (state.order.indexOf("s_webkit_cta") > state.order.indexOf("s_webkit_trust")) {
            throw new Error(`Snippet move did not persist: ${JSON.stringify(state)}.`);
        }

        await page.screenshot({
            path: path.join(runtime, "stage3-browser-acceptance.png"),
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
        const restoredState = await getPublicState(page);
        if (
            JSON.stringify(restoredState.order) !== JSON.stringify(canonicalOrder) ||
            restoredState.heroLead !== initialState.heroLead ||
            restoredState.featureCount !== 1
        ) {
            throw new Error(`Homepage cleanup failed: ${JSON.stringify(restoredState)}.`);
        }

        console.log(JSON.stringify({
            registry: canonicalOrder,
            textPersistence: true,
            imageOptions: true,
            linkHref: "/contactus",
            duplicatePersistence: true,
            movePersistence: true,
            finalTestOrder: state.order,
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
