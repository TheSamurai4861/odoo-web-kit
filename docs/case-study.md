# Case study — Four native blocks for Odoo Website

## Context

I built Web Kit to understand the Odoo 19 Website Builder as an extension
surface, not as a container for an unrelated landing page. The result had to
appear in the block picker, use the standard editing controls and preserve page
changes after saving.

Northline is the fictional scenario used in the screenshots. Its company,
testimonial and metrics do not represent a client or measured business result.

## Question and scope

Odoo already ships a broad block library. Reproducing it would not test much.
The useful question was narrower:

> Can four opinionated blocks keep their visual identity while behaving like
> normal Odoo Website content?

The module therefore contains one category, four blocks and three Hero options.
It excludes business models, a form backend, dynamic card records and public
animation code.

## Three product decisions

### Target the current Odoo 19 Builder API

I chose Odoo 19 rather than building a compatibility layer across releases.
The Hero options use the current `BaseOptionComponent`, Owl templates and class
actions. This keeps the example small enough to explain and makes its version
boundary explicit.

### Finish four blocks before adding breadth

Hero, Features, Trust and CTA are enough to compose and test a complete page.
Limiting the collection let me exercise every block through insertion, editing,
duplication, movement and reload at each target width. A larger catalogue would
have added examples without adding a new integration problem.

### Ship no public JavaScript

The blocks do not need runtime state. QWeb, Bootstrap and SCSS cover their
public behavior, so I kept the single JavaScript plugin inside Builder assets.
That choice reduces the public asset surface and avoids separate editor and
visitor implementations.

## Result

Installing the addon adds a `Web Kit` category with four draggable previews.
The Hero's alignment, media position and tone are stored as classes in the page
architecture. The other blocks remain editable with Odoo's standard content,
image and link tools.

Acceptance runs cover the editor workflow, five viewport widths, keyboard
focus, reduced motion, 200% reflow and the install/upgrade/uninstall/reinstall
lifecycle. Local SVG files keep the demo independent of remote media.

## Limits

- Northline is database state for the demonstration, not reusable module data.
- Only the Hero exposes component-specific options.
- There is no translation catalogue or cross-theme acceptance run yet.
- The full browser harness still assumes the documented Windows development
  environment; portable checks are a separate release task.

The next useful input is observation, not another feature list: have another
editor install the addon on a clean database and build the page from the README.
That session should determine whether simpler defaults, translations or more
options deserve priority.
