# Testing and acceptance

## Commands

The local acceptance harness defaults to Odoo at `127.0.0.1:8069`, PostgreSQL
at `127.0.0.1:5433` and the development database `webkit_dev`. It discovers
Python, PostgreSQL and a Chromium-family browser, while the `WEBKIT_*`
variables documented in [Contributing](../CONTRIBUTING.md#setup) override every
machine-specific path and endpoint.

| Command | Purpose |
|---|---|
| `python scripts/verify-portable.py` | Cross-platform manifest, source, package and documentation checks |
| `.\scripts\verify-stage7.ps1` | Source, installed addon, documentation and committed-media checks |
| `.\scripts\verify-stage6.ps1 -Browser` | Editor behavior, responsive layout, accessibility and 200% reflow |
| `.\scripts\verify-stage6-lifecycle.ps1` | Fresh install, upgrade, uninstall, reinstall and database cleanup |
| `.\scripts\verify-stage7.ps1 -Full` | Complete release gate, including Lighthouse and a clean Git tree |
| `.\scripts\generate-stage7-media.ps1 -RepositoryUrl <https://github.com/...>` | Regenerate and atomically publish six screenshots and the demonstration video |

The lifecycle command refuses to reuse its configured QA database. By default,
it starts an isolated `webkit_qa_stage6` instance on port 8070 and removes the
database during cleanup.

## CI boundary

`.github/workflows/quality.yml` has two required jobs. `portable-checks` needs no
Odoo server: it validates Python and JavaScript syntax, XML/SVG safety, manifest
assets, Markdown links, forbidden placeholders, package budgets, UTF-8, LF line
endings and whitespace. `odoo-install` starts PostgreSQL 16, checks out the
tested Odoo revision `c2a39085ba0fbcf8a0e6a55228191e764499caea`, installs the
addon in a fresh database and verifies its four registered views.

Playwright and Lighthouse remain in the local release gate because cold Odoo
bundle compilation and browser startup make them comparatively expensive and
machine-dependent. On 14 August 2026, a candidate snapshot was committed only
inside a temporary repository, cloned again, and validated without files from
the working tree. Portable CI, fresh installation, four-block Builder insertion
and cleanup all passed. The temporary clone was then sent to the recycle bin.

## Acceptance matrix

| Boundary | Executable contract |
|---|---|
| Package | Manifest metadata, declared files and asset order are valid |
| Source | Python/JavaScript syntax and XML/SVG parsing succeed without external entities |
| Registry | One `Web Kit` group exposes exactly Hero, Features, Trust and CTA |
| Editing | Insert, edit, duplicate, move, save and reload preserve native content |
| Hero options | Alignment, media position and tone persist and remain instance-specific |
| Public page | Four blocks render in order without failed Web Kit resources or public JavaScript |
| Responsive | No horizontal overflow at 1440, 1024, 768, 390 or 360 px |
| Accessibility | Semantic names, contrast, 44 px actions, focus order, reduced motion and 200% reflow pass |
| Lifecycle | User page survives upgrade and reinstall; module records disappear on uninstall |
| Cleanup | Browser page state, QA server and disposable database are restored or removed |
| Documentation | Local links resolve and committed media satisfy their format contracts |

## Package contracts

| Asset group | Maximum |
|---|---:|
| Complete addon | 65,536 bytes |
| SCSS | 16,384 bytes |
| SVG | 16,384 bytes total; 8,192 bytes per file |
| Builder assets | 8,192 bytes |
| Public Web Kit JavaScript | 0 requests |

The scripts print current file counts and byte totals instead of copying those
values into documentation. Lighthouse acceptance requires at least 70 for
performance and 90 for accessibility, best practices and SEO, plus zero failed
Web Kit requests.

## Media contracts

The media generator records the real Builder workflow, restores the homepage
and encodes H.264 at 1280 × 720 with `yuv420p`. Validation requires six named PNG
captures, bounded file sizes and an MP4 duration between 60 and 90 seconds.
The public repository URL is mandatory and appears only over the anonymous
homepage in the closing scene. Candidate files are checked before publication;
the previous media set is copied to a timestamped directory under
`WEBKIT_RUNTIME` so replacement remains recoverable.
The encoder also stores the displayed GitHub repository URL in the MP4 comment
metadata. The release gate rejects a video without that evidence, preventing an
older technically valid recording from passing as final.

Playwright's FFmpeg binary is installed once in the local browser harness:

```powershell
cd ..\.runtime\browser-check
npx playwright-core install ffmpeg
```

## Diagnosing failures

The scripts keep the detailed failure context: viewport evidence, selected
classes, HTTP state, browser exceptions and lifecycle log paths. Expected Odoo
`website_visitor` serialization retries are counted separately; any unrelated
traceback still fails the run. The lifecycle wrapper also distinguishes known
dependency Docutils warnings from errors produced by this addon.

A first Builder launch on a cold Windows database can spend several minutes
compiling Odoo's core JavaScript and SCSS bundles. If Odoo reaches its real-time
limit during that compilation, restart it with a temporary higher
`--limit-time-real` value and retry; inspect the server log to distinguish core
bundle compilation from an addon exception.
