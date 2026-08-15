const path = require("path");

const {
    baseUrl,
    browserLaunchOptions,
    chromium,
    runtime,
} = require("./lib/browser-env.cjs");
const expectedActions = [
    "Review your workflow",
    "See the approach",
    "Map the entry point",
    "Connect the handoff",
    "Prepare delivery",
    "Discuss your handoffs",
];
const expectedOrder = [
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
];

async function verifyKeyboardNavigation(browser) {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    const browserErrors = [];
    page.on("pageerror", (error) => browserErrors.push(error.message));
    try {
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const visited = [];
        for (let index = 0; index < 50 && visited.length < expectedActions.length; index++) {
            await page.keyboard.press("Tab");
            await page.waitForTimeout(250);
            const focused = await page.evaluate(() => {
                const element = document.activeElement;
                if (!element?.closest("#wrap") || !element.matches("a, button")) {
                    return null;
                }
                const style = getComputedStyle(element);
                return {
                    text: element.textContent.trim().replace(/\s+/g, " "),
                    href: element.getAttribute("href"),
                    focusVisible: element.matches(":focus-visible"),
                    outlineWidth: parseFloat(style.outlineWidth),
                    outlineOffset: parseFloat(style.outlineOffset),
                    boxShadow: style.boxShadow,
                };
            });
            if (focused && !visited.some((item) => item.text === focused.text)) {
                visited.push(focused);
            }
        }

        if (JSON.stringify(visited.map((item) => item.text)) !== JSON.stringify(expectedActions)) {
            throw new Error(`Unexpected keyboard order: ${JSON.stringify(visited)}.`);
        }
        for (const item of visited) {
            if (
                !item.href ||
                !item.focusVisible ||
                item.outlineWidth < 3 ||
                item.outlineOffset < 3 ||
                !item.boxShadow.includes("6px")
            ) {
                throw new Error(`Inaccessible keyboard action: ${JSON.stringify(item)}.`);
            }
        }
        if (browserErrors.length) {
            throw new Error(`Keyboard browser errors: ${browserErrors.join(" | ")}.`);
        }
        return { visited, browserErrors };
    } finally {
        await page.close();
    }
}

async function verifyZoomReflow(browser) {
    // 720 CSS pixels at deviceScaleFactor 2 represents a 1440px display at
    // 200% browser zoom while retaining a 1440px physical capture.
    const context = await browser.newContext({
        viewport: { width: 720, height: 500 },
        deviceScaleFactor: 2,
    });
    const page = await context.newPage();
    const browserErrors = [];
    page.on("pageerror", (error) => browserErrors.push(error.message));
    try {
        await page.goto(`${baseUrl}/`, { waitUntil: "networkidle", timeout: 60_000 });
        const images = page.locator("#wrap img");
        for (let index = 0; index < await images.count(); index++) {
            const image = images.nth(index);
            await image.scrollIntoViewIfNeeded();
            await image.evaluate((element) => {
                if (element.complete) {
                    return;
                }
                return new Promise((resolve) => {
                    element.addEventListener("load", resolve, { once: true });
                    element.addEventListener("error", resolve, { once: true });
                });
            });
        }
        const evidence = await page.evaluate(() => ({
            devicePixelRatio,
            viewportWidth: document.documentElement.clientWidth,
            documentWidth: document.documentElement.scrollWidth,
            order: [...document.querySelectorAll("#wrap > section")].map(
                (section) => section.dataset.snippet
            ),
            brokenImages: [...document.querySelectorAll("#wrap img")]
                .filter((image) => !image.complete || !image.naturalWidth)
                .map((image) => image.src),
            clippedText: [...document.querySelectorAll(
                "#wrap h1, #wrap h2, #wrap h3, #wrap p, #wrap a"
            )].filter((element) => {
                const style = getComputedStyle(element);
                const masks = [style.overflow, style.overflowX, style.overflowY]
                    .some((value) => ["hidden", "clip"].includes(value));
                return masks && (
                    element.scrollWidth > element.clientWidth + 1 ||
                    element.scrollHeight > element.clientHeight + 1
                );
            }).map((element) => element.textContent.trim().slice(0, 80)),
            minimumActionHeight: Math.min(
                ...[...document.querySelectorAll("#wrap a, #wrap button")].map((action) =>
                    Math.round(action.getBoundingClientRect().height)
                )
            ),
        }));

        if (
            evidence.devicePixelRatio !== 2 ||
            evidence.viewportWidth !== 720 ||
            evidence.documentWidth !== 720 ||
            JSON.stringify(evidence.order) !== JSON.stringify(expectedOrder) ||
            evidence.brokenImages.length ||
            evidence.clippedText.length ||
            evidence.minimumActionHeight < 44 ||
            browserErrors.length
        ) {
            throw new Error(`200% zoom reflow failed: ${JSON.stringify({
                evidence,
                browserErrors,
            })}.`);
        }
        await page.screenshot({
            path: path.join(runtime, "stage6-zoom-200.png"),
            fullPage: true,
        });
        return { ...evidence, browserErrors };
    } finally {
        await context.close();
    }
}

(async () => {
    const browser = await chromium.launch(browserLaunchOptions());
    try {
        const keyboard = await verifyKeyboardNavigation(browser);
        const zoom200 = await verifyZoomReflow(browser);
        console.log(JSON.stringify({ keyboard, zoom200 }, null, 2));
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error);
    process.exit(1);
});
