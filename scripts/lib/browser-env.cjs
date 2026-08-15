const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const workspace = path.resolve(__dirname, "..", "..");
const odooRoot = process.env.WEBKIT_ODOO_ROOT || path.resolve(workspace, "..");
const runtime = process.env.WEBKIT_RUNTIME || path.join(odooRoot, ".runtime");
const baseUrl = (process.env.WEBKIT_BASE_URL || "http://127.0.0.1:8069").replace(/\/$/, "");
const database = process.env.WEBKIT_DB || "webkit_dev";
const qaDatabase = process.env.WEBKIT_QA_DB || "webkit_qa_stage6";
const qaBaseUrl = (
    process.env.WEBKIT_QA_BASE_URL ||
    `http://127.0.0.1:${process.env.WEBKIT_QA_PORT || "8070"}`
).replace(/\/$/, "");

function resolveCommand(commands) {
    const locator = process.platform === "win32" ? "where.exe" : "which";
    for (const command of commands) {
        const result = spawnSync(locator, [command], { encoding: "utf8" });
        if (result.status === 0) {
            const resolved = result.stdout.split(/\r?\n/).find(Boolean);
            if (resolved && fs.existsSync(resolved)) {
                return resolved;
            }
        }
    }
    return undefined;
}

function resolveBrowserExecutable() {
    if (process.env.WEBKIT_BROWSER_PATH) {
        if (!fs.existsSync(process.env.WEBKIT_BROWSER_PATH)) {
            throw new Error(`WEBKIT_BROWSER_PATH does not exist: ${process.env.WEBKIT_BROWSER_PATH}`);
        }
        return process.env.WEBKIT_BROWSER_PATH;
    }

    const candidates = [];
    if (process.platform === "win32") {
        for (const root of [
            process.env["ProgramFiles(x86)"],
            process.env.ProgramFiles,
            process.env.LOCALAPPDATA,
        ]) {
            if (root) {
                candidates.push(path.join(root, "Microsoft", "Edge", "Application", "msedge.exe"));
                candidates.push(path.join(root, "Google", "Chrome", "Application", "chrome.exe"));
            }
        }
    } else if (process.platform === "darwin") {
        candidates.push("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge");
        candidates.push("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome");
    }
    return candidates.find((candidate) => fs.existsSync(candidate)) || resolveCommand([
        "msedge",
        "microsoft-edge",
        "google-chrome",
        "chromium",
        "chromium-browser",
    ]);
}

function loadChromium() {
    try {
        return require("playwright-core").chromium;
    } catch (error) {
        const localHarness = path.join(runtime, "browser-check", "node_modules", "playwright-core");
        if (!fs.existsSync(localHarness)) {
            throw new Error(
                "playwright-core is unavailable. Install it locally or under WEBKIT_RUNTIME/browser-check."
            );
        }
        return require(localHarness).chromium;
    }
}

function getOdooAdminPassword() {
    if (process.env.WEBKIT_ODOO_ADMIN_PASSWORD) {
        return process.env.WEBKIT_ODOO_ADMIN_PASSWORD;
    }
    const passwordFile = path.join(runtime, "secrets", "odoo-admin-password");
    if (!fs.existsSync(passwordFile)) {
        throw new Error(
            "Odoo admin password is unavailable. Set WEBKIT_ODOO_ADMIN_PASSWORD " +
            "or create WEBKIT_RUNTIME/secrets/odoo-admin-password."
        );
    }
    return fs.readFileSync(passwordFile, "utf8").trim();
}

function browserLaunchOptions(extra = {}) {
    const executablePath = resolveBrowserExecutable();
    return {
        headless: true,
        ...(executablePath ? { executablePath } : {}),
        ...extra,
    };
}

module.exports = {
    baseUrl,
    browserLaunchOptions,
    chromium: loadChromium(),
    database,
    getOdooAdminPassword,
    odooRoot,
    qaBaseUrl,
    qaDatabase,
    runtime,
    workspace,
};
