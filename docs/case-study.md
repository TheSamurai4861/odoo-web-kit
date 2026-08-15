# Case study — Building natively inside Odoo Website

## Context

Odoo Web Kit started as a focused way to learn how Odoo 19 Website works from
the inside. I did not want to build a standalone landing page and place it next
to Odoo. The result had to behave like part of the product: appear in the
Website Builder, support drag and drop, use native editing tools and persist
after saving.

Northline is the fictional business used to demonstrate the blocks. It is not
a client project and the testimonial and metrics are sample content.

## The problem

Odoo Website already offers a large block library. The exercise was therefore
not to reproduce a complete theme, but to answer a narrower question:

> Can a small set of opinionated blocks feel native to Odoo while still having
> a recognizable visual direction?

The main risks were integration rather than visual design:

- registering a dedicated block category correctly;
- keeping editable content compatible with Odoo's authoring surface;
- loading public styles without leaking Builder code to visitors;
- using Odoo 19's current option API rather than legacy snippet hooks;
- preserving the result through install, upgrade and reinstallation.

## Scope

The module contains four blocks:

| Block | Job |
|---|---|
| Hero | Introduce the offer with two actions and a supporting visual |
| Features | Explain three benefits in a scannable layout |
| Trust | Add a testimonial, identity and outcome indicators |
| CTA | Close the page with one clear next step |

The Hero also exposes three native Builder options: content alignment, visual
position and tone.

I deliberately excluded dynamic card management, a custom form backend,
animation JavaScript and business models. Those features would have increased
the surface area without improving the core demonstration.

## Approach

### Prove the integration first

I began with the smallest possible vertical slice: one category, one basic
snippet, installation in Odoo and a saved page. This isolated manifest, asset
and registry problems before visual work began.

### Build with Odoo primitives

The final blocks use semantic QWeb templates, Bootstrap layout utilities and
Odoo color classes. Component SCSS is namespaced with `s_webkit_` or
`webkit_`. The public page does not load custom JavaScript.

### Keep Builder behavior declarative

The Hero options use Odoo 19 Builder components and class actions. Each option
changes a class on the selected Hero, so the saved HTML remains understandable
and the CSS owns the presentation.

### Treat the demo as a lifecycle, not a screenshot

The acceptance checks exercise the behavior an editor relies on: finding the
category, inserting a block, editing content, duplicating, reordering, saving
and reloading. A separate disposable database checks fresh installation,
upgrade, uninstall and reinstall.

## Key decisions

### Four finished blocks instead of a large library

A smaller collection made it possible to test every block in the editor and at
all target widths. It also kept the visual language consistent.

### Local SVG assets

All preview and demonstration illustrations are stored with the addon. This
avoids external requests, licensing ambiguity and screenshots that change over
time.

### No public JavaScript

The blocks do not need runtime behavior. Avoiding public JavaScript reduces the
download and removes a source of editor/public-page divergence. The only
JavaScript file registers the Hero option component in Builder assets.

### Theme-aware colors

The styles build on Odoo and Bootstrap variables rather than defining an
independent hardcoded palette. The blocks can therefore inherit more of the
active website theme.

## Result

The addon installs on Odoo 19 Community and adds a `Web Kit` category containing
the four blocks. The Northline page is composed entirely from those snippets
between Odoo's native header and footer.

The test suite covers five viewport widths, keyboard focus, reduced motion,
200% zoom, secure XML/SVG parsing, asset budgets and the complete module
lifecycle. The demonstration video shows the Builder workflow rather than only
the rendered homepage.

## Trade-offs

- Northline content is static demonstration data, not reusable demo records.
- Only the Hero has dedicated design options.
- The module has no translation catalogue yet.
- The current full development harness was created for Windows and is being
  separated from the portable source checks before public release.
- No backend model is included because the project focuses on Website Builder
  integration.

## What I would do next

Before expanding the block library, I would test the four existing blocks with
two contrasting Odoo themes and ask another user to build the page from a clean
database using only the README. The result of those tests should decide whether
the next investment belongs in more options, translations or simpler defaults.
