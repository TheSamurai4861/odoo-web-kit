# Testing and acceptance

## Test strategy

The suite tests the addon at four levels. A lower level failing stops the higher
levels so browser output is not used to hide a source or installation problem.

| Level | Main evidence |
|---|---|
| Static | Manifest, asset paths, JavaScript syntax, secure XML/SVG parsing and package budgets |
| Odoo | Installed module state, combined snippet registry, compiled assets and persisted homepage |
| Browser | Builder workflow, editing, options, responsive layout, accessibility and cleanup |
| Lifecycle | Fresh install, upgrade, uninstall, reinstall and disposable-database cleanup |

## Quick validation

With the local Odoo and PostgreSQL services running:

```powershell
.\scripts\verify-stage7.ps1
```

This command replays the static and server-side guarantees from the previous
stages, validates the public documentation and probes all committed media. It
does not create the lifecycle database or rerun Lighthouse.

## Full acceptance gate

```powershell
.\scripts\verify-stage7.ps1 -Full
```

The full gate adds:

- drag, edit, duplicate, move, save and reload in the Website Builder;
- Hero option persistence and isolation between duplicated instances;
- rendering at 1440, 1024, 768, 390 and 360 pixels;
- keyboard order, visible focus and 200% zoom reflow;
- fresh install, upgrade, uninstall and reinstall in `webkit_qa_stage6`;
- Lighthouse desktop categories and Web Kit request budgets;
- a clean Git tree with a meaningful local history.

The disposable lifecycle refuses to overwrite an existing QA database. It uses
port 8070, waits for HTTP readiness and removes the database in a `finally`
block. The persistent development database is `webkit_dev` on port 8069.

## Media generation

```powershell
.\scripts\generate-stage7-media.ps1
```

This regenerates six screenshots, records the Browser workflow, restores the
homepage and encodes the final MP4. Playwright's private FFmpeg binary must be
installed once in the local browser harness:

```powershell
cd ..\.runtime\browser-check
npx playwright-core install ffmpeg
```

Media assertions check PNG signatures and dimensions, file-size budgets and the
video stream contract. The committed demonstration is 72.134 seconds, H.264,
1280 × 720 and `yuv420p`.

## Functional acceptance matrix

| Area | Acceptance criterion |
|---|---|
| Registry | One Web Kit group and exactly four previews |
| Hero | Text, image and links editable; three native options persist |
| Features | Three cards render and native duplication/movement remain available |
| Trust | Testimonial, identity, rating and metrics remain editable |
| CTA | Final action remains a native internal link |
| Persistence | Saved content and block order survive a reload |
| Cleanup | Browser tests restore the canonical four-block homepage |
| Lifecycle | User page survives upgrade and module reinstall |

## Responsive and accessibility matrix

| Check | Contract |
|---|---|
| Horizontal layout | Document width equals viewport width at every target size |
| Images | Every image completes with a non-zero natural width |
| Text | No masked element has clipped content |
| Actions | Minimum rendered height of 44 pixels |
| Headings | One public `<h1>` and a logical section hierarchy |
| Names | No unnamed or invalid links and no duplicate IDs |
| Contrast | Tested component combinations meet WCAG AA for normal text |
| Keyboard | Six primary actions receive focus in visual order |
| Focus | Explicit outline, offset and halo remain visible |
| Motion | Nonessential transforms/transitions are disabled when requested |
| Zoom | 200% simulation reflows without a horizontal scrollbar |

## Package budgets

The release checks exclude ignored Python caches and enforce these upper bounds:

| Asset group | Budget |
|---|---:|
| Complete addon | 65,536 bytes |
| SCSS | 16,384 bytes |
| SVG | 16,384 bytes total and 8,192 bytes per file |
| Builder assets | 8,192 bytes |
| Public Web Kit JavaScript | 0 requests |

At the documented Stage 6 reference, the addon contained 22 deliverable files
for 32,935 bytes. The public page requested two Web Kit SVG files for 5,877
transferred bytes.

## Lighthouse reference

The Stage 6 desktop reference recorded:

| Category | Score |
|---|---:|
| Performance | 86 |
| Accessibility | 95 |
| Best practices | 96 |
| SEO | 100 |

The gate thresholds are deliberately lower than a single observed run to allow
normal machine variance: 70 for performance and 90 for the other categories.
Regardless of the aggregate page score, Web Kit must keep zero public
JavaScript requests, zero failed requests and zero accessibility failure tied
to its sections.

## Known environment messages

Concurrent browser visits can trigger `website_visitor` serialization retries
inside Odoo. The server recovers them; the scripts count them separately and
continue to fail on any other error or traceback.

On Windows, Chrome Launcher can occasionally report `EPERM` while removing its
temporary profile after Lighthouse has written the report. The wrapper accepts
that cleanup error only after parsing a complete report and passing every score
and Web Kit assertion.

Some Odoo dependency metadata emits Docutils indentation warnings during module
lifecycle operations. They do not originate from the Web Kit manifest and are
not present as runtime errors in the QA log.

## Last accepted full run

The final Stage 7 gate completed successfully before this documentation
consolidation with:

- fresh install and four registered snippets;
- persisted Hero option after save and upgrade;
- clean uninstall and reinstall;
- `qa_database_cleanup=OK`;
- Lighthouse 89 / 95 / 100 / 100 on that run;
- six valid screenshots and the 72.134-second video;
- no unexpected current-process Odoo log issue.

The gate must be run again after any source, branding or media change intended
for release.
