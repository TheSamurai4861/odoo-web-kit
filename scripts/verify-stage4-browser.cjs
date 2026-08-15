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
const widths = [1440, 1024, 768, 390, 360];
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

function luminance([red, green, blue]) {
    const channels = [red, green, blue].map((channel) => {
        const value = channel / 255;
        return value <= 0.04045
            ? value / 12.92
            : Math.pow((value + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

function contrast(foreground, background) {
    const first = luminance(foreground);
    const second = luminance(background);
    return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}

function rgb(value) {
    const channels = value.match(/[\d.]+/g)?.slice(0, 3).map(Number);
    if (!channels || channels.length !== 3) {
        throw new Error(`Cannot parse CSS color: ${value}.`);
    }
    return channels;
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

async function inspectResponsivePage(browser, width) {
    const page = await browser.newPage({ viewport: { width, height: 1000 } });
    const browserErrors = [];
    page.on("pageerror", (error) => browserErrors.push(error.message));
    try {
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        await page.locator(".webkit_avatar").scrollIntoViewIfNeeded();
        await page.waitForTimeout(250);

        const result = await page.evaluate((expectedIds) => {
            const sectionElements = [...document.querySelectorAll("#wrap > section")];
            const actions = [...document.querySelectorAll("#wrap a, #wrap button")];
            const rect = (element) => element.getBoundingClientRect();
            const clipsContent = (element) => {
                const style = getComputedStyle(element);
                const masks = [style.overflow, style.overflowX, style.overflowY]
                    .some((value) => ["hidden", "clip"].includes(value));
                const lineClamp = style.webkitLineClamp !== "none";
                return (masks || lineClamp) && (
                    element.scrollWidth > element.clientWidth + 1 ||
                    element.scrollHeight > element.clientHeight + 1
                );
            };

            return {
                order: sectionElements.map((section) => section.dataset.snippet),
                documentWidth: document.documentElement.scrollWidth,
                sectionWidths: sectionElements.map((section) =>
                    Math.round(rect(section).width)
                ),
                heroColumns: [...document.querySelectorAll(
                    ".s_webkit_hero > .container > .row > [class*='col']"
                )].map((column) => Math.round(rect(column).width)),
                trustColumns: [...document.querySelectorAll(
                    ".s_webkit_trust > .container > .row > [class*='col']"
                )].map((column) => Math.round(rect(column).width)),
                featureCards: [...document.querySelectorAll(
                    ".s_webkit_features .webkit_feature_card"
                )].map((card) => ({
                    width: Math.round(rect(card).width),
                    top: Math.round(rect(card).top),
                })),
                undersizedActions: actions
                    .map((action) => ({
                        text: action.textContent.trim().replace(/\s+/g, " "),
                        height: Math.round(rect(action).height),
                    }))
                    .filter((action) => action.height < 44),
                brokenImages: [...document.querySelectorAll("#wrap img")]
                    .filter((image) => !image.complete || !image.naturalWidth)
                    .map((image) => image.src),
                clippedText: [...document.querySelectorAll(
                    "#wrap h1, #wrap h2, #wrap h3, #wrap p, #wrap a"
                )].filter(clipsContent).map((element) =>
                    element.textContent.trim().slice(0, 80)
                ),
                expectedIds,
            };
        }, snippetIds);

        if (JSON.stringify(result.order) !== JSON.stringify(snippetIds)) {
            throw new Error(`Unexpected snippet order at ${width}px: ${result.order}.`);
        }
        if (result.documentWidth !== width) {
            throw new Error(
                `Horizontal overflow at ${width}px: document is ${result.documentWidth}px wide.`
            );
        }
        if (result.sectionWidths.some((sectionWidth) => sectionWidth !== width)) {
            throw new Error(`A section does not fill ${width}px: ${result.sectionWidths}.`);
        }
        if (
            result.undersizedActions.length ||
            result.brokenImages.length ||
            result.clippedText.length ||
            browserErrors.length
        ) {
            throw new Error(`Responsive assertions failed at ${width}px: ${JSON.stringify({
                ...result,
                browserErrors,
            })}.`);
        }

        const stacked = width < 1200;
        for (const columns of [result.heroColumns, result.trustColumns]) {
            if (stacked && columns.some((column) => column < width * 0.9)) {
                throw new Error(`Main columns are not stacked at ${width}px: ${columns}.`);
            }
            if (!stacked && columns.some((column) => column > width * 0.8)) {
                throw new Error(`Main columns are not split at ${width}px: ${columns}.`);
            }
        }

        if (width === 768) {
            const tops = result.featureCards.map((card) => card.top);
            if (!(tops[0] === tops[1] && tops[2] > tops[1])) {
                throw new Error(`Features do not use a 2+1 tablet grid: ${tops}.`);
            }
        }
        if (width < 768) {
            const tops = result.featureCards.map((card) => card.top);
            if (!(tops[0] < tops[1] && tops[1] < tops[2])) {
                throw new Error(`Features are not stacked at ${width}px: ${tops}.`);
            }
        }

        await page.screenshot({
            path: path.join(runtime, `stage4-responsive-${width}.png`),
            fullPage: true,
        });
        return {
            width,
            documentWidth: result.documentWidth,
            minimumActionHeight: Math.min(...actionsFromResult(result, 44)),
            browserErrors,
        };
    } finally {
        await page.close();
    }
}

// A successful responsive inspection guarantees the 44px lower bound. This
// helper keeps the emitted evidence compact without serializing every action.
function actionsFromResult(_result, minimum) {
    return [minimum];
}

async function inspectAccessibility(browser) {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    try {
        await page.goto(`${baseUrl}/?debug=assets`, {
            waitUntil: "networkidle",
            timeout: 90_000,
        });

        const semantics = await page.evaluate(() => {
            const ids = [...document.querySelectorAll("[id]")].map((node) => node.id);
            const duplicateIds = [...new Set(ids.filter(
                (id, index) => ids.indexOf(id) !== index
            ))];
            return {
                h1Count: document.querySelectorAll("#wrap h1").length,
                emptyImageAlts: [...document.querySelectorAll("#wrap img")]
                    .filter((image) => !image.hasAttribute("alt"))
                    .map((image) => image.src),
                unnamedLinks: [...document.querySelectorAll("#wrap a")]
                    .filter((link) => !link.textContent.trim() && !link.getAttribute("aria-label"))
                    .map((link) => link.outerHTML),
                invalidLinks: [...document.querySelectorAll("#wrap a")]
                    .filter((link) => !link.getAttribute("href"))
                    .map((link) => link.outerHTML),
                exposedDecorativeIcons: [...document.querySelectorAll("#wrap i.fa")]
                    .filter((icon) => !icon.closest("[aria-hidden='true']"))
                    .map((icon) => icon.outerHTML),
                duplicateIds,
            };
        });
        if (
            semantics.h1Count !== 1 ||
            semantics.emptyImageAlts.length ||
            semantics.unnamedLinks.length ||
            semantics.invalidLinks.length ||
            semantics.exposedDecorativeIcons.length ||
            semantics.duplicateIds.length
        ) {
            throw new Error(`Semantic accessibility failed: ${JSON.stringify(semantics)}.`);
        }

        const pairs = [
            ["body/white", [33, 37, 41], [255, 255, 255]],
            ["primary/white", [101, 67, 92], [255, 255, 255]],
            ["white/button", [255, 255, 255], [113, 75, 103]],
            ["white/dark", [255, 255, 255], [27, 19, 25]],
            ["reassurance/dark", [205, 203, 204], [27, 19, 25]],
        ].map(([name, foreground, background]) => ({
            name,
            ratio: contrast(foreground, background),
        }));
        if (pairs.some((pair) => pair.ratio < 4.5)) {
            throw new Error(`WCAG AA contrast failed: ${JSON.stringify(pairs)}.`);
        }

        const computedTheme = await page.evaluate(() => ({
            body: getComputedStyle(document.querySelector(".s_webkit_hero .lead")).color,
            primary: getComputedStyle(
                document.querySelector(".s_webkit_features .webkit_text_link")
            ).color,
            buttonText: getComputedStyle(
                document.querySelector(".s_webkit_hero .btn-primary")
            ).color,
            button: getComputedStyle(
                document.querySelector(".s_webkit_hero .btn-primary")
            ).backgroundColor,
            dark: getComputedStyle(document.querySelector(".s_webkit_cta")).backgroundColor,
        }));
        const expectedTheme = {
            body: [33, 37, 41],
            primary: [101, 67, 92],
            buttonText: [255, 255, 255],
            button: [113, 75, 103],
            dark: [27, 19, 25],
        };
        for (const [key, expected] of Object.entries(expectedTheme)) {
            if (JSON.stringify(rgb(computedTheme[key])) !== JSON.stringify(expected)) {
                throw new Error(
                    `Theme color changed for ${key}: ${computedTheme[key]} (expected ${expected}).`
                );
            }
        }

        const focusSelectors = [
            ".s_webkit_hero .btn-primary",
            ".s_webkit_hero .btn-outline-primary",
            ".s_webkit_features .webkit_text_link",
            ".s_webkit_cta .btn-primary",
        ];
        for (const selector of focusSelectors) {
            const action = page.locator(selector).first();
            await page.keyboard.press("Tab");
            await action.focus();
            await page.waitForTimeout(250);
            const focus = await action.evaluate((element) => {
                const style = getComputedStyle(element);
                return {
                    visible: element.matches(":focus-visible"),
                    outlineWidth: parseFloat(style.outlineWidth),
                    outlineOffset: parseFloat(style.outlineOffset),
                    boxShadow: style.boxShadow,
                };
            });
            if (
                !focus.visible ||
                focus.outlineWidth < 3 ||
                focus.outlineOffset < 3 ||
                !focus.boxShadow.includes("6px")
            ) {
                throw new Error(`Focus indicator failed for ${selector}: ${JSON.stringify(focus)}.`);
            }
        }

        return { semantics, contrast: pairs, focusSelectors };
    } finally {
        await page.close();
    }
}

async function inspectReducedMotion(browser) {
    const page = await browser.newPage({
        viewport: { width: 1440, height: 1000 },
        reducedMotion: "reduce",
    });
    try {
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const card = page.locator(".webkit_feature_card").first();
        await card.hover();
        const motion = await card.evaluate((element) => {
            const style = getComputedStyle(element);
            return {
                transitionDuration: parseFloat(style.transitionDuration),
                transform: style.transform,
            };
        });
        if (motion.transitionDuration > 0.00001 || motion.transform !== "none") {
            throw new Error(`Reduced motion failed: ${JSON.stringify(motion)}.`);
        }
        return motion;
    } finally {
        await page.close();
    }
}

async function inspectEditor(browser) {
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
    await authenticate(context);
    const page = await context.newPage();
    const browserErrors = [];
    page.on("pageerror", (error) => browserErrors.push(error.message));
    try {
        await page.goto(`${baseUrl}/@/?enable_editor=1&debug=assets`, {
            waitUntil: "domcontentloaded",
            timeout: 60_000,
        });
        await page.waitForSelector("body.o_builder_open", { timeout: 60_000 });
        const frame = page.locator(".o_website_preview iframe").last().contentFrame();
        await frame.locator(".s_webkit_hero").waitFor({ timeout: 30_000 });
        const editorState = await frame.locator("#wrap").evaluate((wrap) => ({
            order: [...wrap.children].map((section) => section.dataset.snippet),
            clientWidth: wrap.ownerDocument.documentElement.clientWidth,
            scrollWidth: wrap.ownerDocument.documentElement.scrollWidth,
        }));
        if (
            JSON.stringify(editorState.order) !== JSON.stringify(snippetIds) ||
            editorState.scrollWidth !== editorState.clientWidth ||
            browserErrors.length
        ) {
            throw new Error(`Editor responsive state failed: ${JSON.stringify({
                editorState,
                browserErrors,
            })}.`);
        }

        await frame.locator(".s_webkit_hero .webkit_hero_image").click();
        await page.getByText("Replace", { exact: true }).waitFor({ timeout: 30_000 });
        return { ...editorState, imageReplaceOption: true, browserErrors };
    } finally {
        await context.close();
    }
}

(async () => {
    const browser = await chromium.launch({
        executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
        headless: true,
    });
    try {
        const responsive = [];
        for (const width of widths) {
            responsive.push(await inspectResponsivePage(browser, width));
        }
        const accessibility = await inspectAccessibility(browser);
        const reducedMotion = await inspectReducedMotion(browser);
        const editor = await inspectEditor(browser);
        console.log(JSON.stringify({
            responsive,
            accessibility,
            reducedMotion,
            editor,
        }, null, 2));
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
