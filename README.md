# Odoo Web Kit

Four installable, editable website snippets for **Odoo 19 Community**: Hero,
Features, Trust and CTA.

![Northline homepage built with the four Web Kit blocks](docs/media/homepage-desktop.png)

The addon adds a `Web Kit` category to the native Website Builder. Editors can
drag, edit, duplicate, reorder and save its blocks with Odoo's standard tools.

[Watch the Builder demo](docs/media/odoo-web-kit-demo.mp4)

## Why

This repository tests one narrow product question: can a small, visually
coherent block collection use Odoo's authoring model without becoming a
standalone page embedded beside it? The implementation covers the whole path
from addon installation to saved-page rendering.

## Components

| Block | Content | Authoring support |
|---|---|---|
| Hero | Heading, actions and illustration | Native text/image/link editing; alignment, media position and tone options |
| Features | Three service steps | Native editing, duplication and reordering |
| Trust | Testimonial and two indicators | Native text and image editing |
| CTA | Final prompt and action | Native text and link editing |

## Install

Requirements: Odoo 19 Community, Python 3.12 and PostgreSQL 13 or newer.

1. Add the repository root to Odoo's `addons_path`.
2. Update the Apps list.
3. Install **Odoo Web Kit**, or run:

```powershell
python odoo-bin -d <database> -i website_webkit --stop-after-init
```

The only Odoo dependency is `website`; the addon has no external runtime
package.

## Use

Open a Website page, select **Edit**, then drag **Web Kit** from the Blocks
panel. Choose a block and edit it with the normal Website controls. Selecting
the Hero also exposes content alignment, visual position and tone.

![Web Kit category inside the native Website Builder](docs/media/web-kit-category.png)

## Architecture

- QWeb owns the editable document structure.
- Odoo/Bootstrap utilities and namespaced SCSS own the public presentation.
- Builder-only JavaScript is isolated in `website.website_builder_assets`; the
  public page loads no Web Kit JavaScript.

See [Architecture](docs/architecture.md) for the data and asset boundaries.

## Design and accessibility

The blocks use theme-aware color variables, semantic headings, alternative
text, 44 px minimum action heights, visible keyboard focus and reduced-motion
rules. Browser checks cover 1440, 1024, 768, 390 and 360 px plus reflow at 200%
zoom.

## Quality evidence

The full gate exercises installation, upgrade, uninstall/reinstall, Builder
editing and persistence, responsive behavior, keyboard navigation, source
parsing, media contracts and Lighthouse:

```powershell
.\scripts\verify-stage7.ps1 -Full
```

One retained Lighthouse reference: the desktop run on **13 August 2026** at
commit `77ef2c4` recorded a **performance score of 86**. Current acceptance
criteria and reproducible commands are in [Testing](docs/testing.md).

## Trade-offs

Northline is static demonstration content, only the Hero has dedicated options,
and the addon defines no business model or backend workflow. These limits keep
the repository focused on Website Builder integration.

## Documentation

- [Case study](docs/case-study.md) — scope, decisions and limits.
- [Architecture](docs/architecture.md) — QWeb, asset and state boundaries.
- [Testing](docs/testing.md) — commands and acceptance contracts.

## Screenshots

| Public page | Builder |
|---|---|
| [Desktop](docs/media/homepage-desktop.png) | [Editor](docs/media/website-builder.png) |
| [Mobile](docs/media/homepage-mobile.png) | [Web Kit category](docs/media/web-kit-category.png) |
| [Four blocks](docs/media/four-components.png) | [Hero options](docs/media/hero-options.png) |

## Next steps

Test contrasting Odoo themes, add translations and decide whether the remaining
blocks need options after observing another editor use the collection.
