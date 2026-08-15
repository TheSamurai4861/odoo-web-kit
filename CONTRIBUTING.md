# Contributing

Contributions should preserve the addon's narrow scope: native, editable Odoo
Website blocks with no public JavaScript dependency.

## Setup

Use Odoo 19 Community, Python 3.12 and PostgreSQL 13 or newer. Clone this
repository outside the Odoo source tree, add its root to `addons_path`, then
install `website_webkit`. The [README](README.md#install) contains commands for
Windows, Linux and macOS.

The PowerShell harness discovers common local installations. Override any
resolved value when your layout differs:

| Variable | Purpose |
|---|---|
| `WEBKIT_ODOO_ROOT` | Parent directory containing Odoo and local runtime data |
| `WEBKIT_ODOO_SOURCE`, `WEBKIT_ODOO_BIN` | Odoo source directory and executable |
| `WEBKIT_PYTHON`, `WEBKIT_ODOO_CONFIG` | Python executable and Odoo configuration |
| `WEBKIT_RUNTIME` | Untracked logs, browser packages, secrets and PostgreSQL data |
| `WEBKIT_PG_BIN` | Directory containing PostgreSQL client executables |
| `WEBKIT_PG_HOST`, `WEBKIT_PG_PORT`, `WEBKIT_DB_USER` | PostgreSQL connection |
| `WEBKIT_DB`, `WEBKIT_BASE_URL` | Development database and Odoo URL |
| `WEBKIT_QA_DB`, `WEBKIT_QA_PORT`, `WEBKIT_QA_BASE_URL` | Disposable lifecycle instance |
| `WEBKIT_BROWSER_PATH` | Chromium, Chrome or Edge executable |
| `WEBKIT_REPOSITORY_URL` | Public HTTPS repository URL shown in generated media |

Individual PostgreSQL commands can also be set with `WEBKIT_PSQL`,
`WEBKIT_PG_CTL`, `WEBKIT_PG_ISREADY`, `WEBKIT_CREATEDB` and `WEBKIT_DROPDB`.

## Conventions

- Keep templates semantic and editable through standard Website Builder tools.
- Namespace addon styles with `s_webkit_`; use Odoo and Bootstrap utilities
  before adding custom rules.
- Keep Builder-only code in `website.website_builder_assets` and do not add
  public JavaScript without documenting the reason.
- Do not commit databases, credentials, logs, generated reports or raw video.
- Update the manifest version and `CHANGELOG.md` when behavior changes.

## Validation

Run the platform-independent checks before every contribution:

```bash
python3 scripts/verify-portable.py
find scripts website_webkit -type f \( -name '*.js' -o -name '*.cjs' \) -print0 \
  | xargs -0 -r -n1 node --check
```

On the documented Windows development stack, run the complete acceptance gate:

```powershell
.\scripts\verify-stage7.ps1 -Full
```

The full gate requires a running development instance and local Playwright and
Lighthouse dependencies. See [Testing](docs/testing.md) for its contracts and
diagnostics.

## Pull requests

Keep each pull request focused on one intention. Explain the user-visible
change, identify relevant trade-offs, list the checks you ran and include
screenshots for visual changes. Do not include generated runtime artifacts.
