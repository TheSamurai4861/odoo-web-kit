# Architecture

## Repository layout

```text
website_webkit/
├── __init__.py
├── __manifest__.py
├── views/snippets/
│   ├── snippets.xml
│   ├── s_webkit_hero.xml
│   ├── s_webkit_features.xml
│   ├── s_webkit_trust.xml
│   └── s_webkit_cta.xml
└── static/src/
    ├── builder/
    │   ├── webkit_hero_option.xml
    │   └── webkit_hero_option_plugin.js
    ├── img/
    │   ├── demo/
    │   └── wbuilder/
    └── scss/
        ├── _tokens.scss
        ├── _hero.scss
        ├── _features.scss
        ├── _trust.scss
        ├── _cta.scss
        └── webkit.scss
```

The addon is declarative. It does not define Python models, controllers,
security rules or database tables.

## Module boundary

`website_webkit` depends only on Odoo's `website` module. The repository root is
an addons path; the Odoo source tree remains a separate sibling directory.

The manifest has three responsibilities:

1. load the four snippet templates and the Website Builder registry extension;
2. add component SCSS to `web.assets_frontend`;
3. add the Hero option component only to
   `website.website_builder_assets`.

This separation prevents Builder-specific JavaScript and templates from being
served as custom public-page behavior.

## Snippet registration

`views/snippets/snippets.xml` inherits `website.snippets`. It registers one
draggable `Web Kit` group and four previews. Each preview points to one QWeb
template with a single root `<section>`.

When an editor inserts a block, Odoo copies that section into the page's
architecture. The section carries `data-snippet` and `data-name` metadata so it
continues to participate in native selection, duplication and movement.

## Public components

Each component follows the same boundary:

- semantic QWeb markup owns content and document structure;
- Bootstrap/Odoo utilities own the main responsive layout;
- namespaced SCSS owns visual treatment and component variants;
- local SVG files provide editable images and Builder previews.

Selectors begin with `.s_webkit_` for snippet roots or `.webkit_` for internal
elements and variants. The styles do not target generic HTML elements outside
their snippet root.

## Hero options

The Builder plugin extends Odoo 19's `BaseOptionComponent`. Its selector is
`.s_webkit_hero`, so the option panel appears only for a selected Hero.

The Owl template declares three `BuilderButtonGroup` rows. Buttons use
`classAction` to manage mutually exclusive classes:

| Setting | Classes |
|---|---|
| Content alignment | `webkit_hero_align_start`, `webkit_hero_align_center` |
| Visual position | `webkit_hero_media_end`, `webkit_hero_media_start` |
| Tone | `o_cc1`, `o_cc5` |

There is no custom action protocol or frontend state store. Odoo applies the
class, saves it in the page architecture and restores the active option from
the DOM when the editor reopens.

## Design tokens and responsive behavior

`_tokens.scss` maps component values to Odoo/Bootstrap variables for color,
spacing, radius, border and shadow. Component partials consume those tokens and
remain scoped to their root.

The QWeb templates provide the responsive column order. SCSS refines spacing,
typography and card layout at the existing Bootstrap breakpoints. Interactive
targets have a minimum height of 44 pixels and explicit `:focus-visible`
styles. A reduced-motion media query removes nonessential transitions.

## Assets

The public bundle contains six SCSS sources. Web Kit makes no public JavaScript
request. Seven SVG assets cover the two content illustrations and five Builder
previews.

All SVG and XML files are parsed without external entities or network access in
the static checks. The addon contains no remote image, font or script URL.

## Page composition and persistence

The Northline homepage is demonstration state stored in the development
database, not module data installed into every customer database. The helper
`scripts/compose-stage3-homepage.py` rebuilds it idempotently from the canonical
snippet templates.

Browser tests save the original `website.homepage` architecture before making
editor changes and restore it in cleanup. Lifecycle tests use a dedicated
`webkit_qa_stage6` database and an isolated HTTP port, then remove both server
and database state in a `finally` block.

## Verification layers

The scripts deliberately separate concerns:

- static checks validate source contracts without opening a browser;
- Odoo shell checks validate installed views, assets and persisted markup;
- Playwright checks validate the real editor and public rendering;
- lifecycle checks validate install, upgrade, uninstall and reinstall;
- Lighthouse measures the final public page and Web Kit's request budget.

See [Testing](testing.md) for commands and acceptance criteria.
