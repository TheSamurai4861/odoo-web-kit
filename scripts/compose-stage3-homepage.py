"""Compose the Stage 3 Web Kit landing page in the current Odoo shell.

Run with:
    odoo-bin shell -c <config> -d webkit_dev --no-http \
        < scripts/compose-stage3-homepage.py

The operation is idempotent: the homepage body is rebuilt from the canonical
snippet templates, so running it twice cannot accumulate duplicate sections.
"""

from copy import deepcopy

from lxml import etree


SNIPPETS = (
    ("s_webkit_hero", "Web Kit Hero"),
    ("s_webkit_features", "Web Kit Features"),
    ("s_webkit_trust", "Web Kit Trust"),
    ("s_webkit_cta", "Web Kit CTA"),
)


homepage = env["ir.ui.view"].search(
    [("key", "=", "website.homepage"), ("website_id", "!=", False)],
    order="website_id, id",
    limit=1,
)
if not homepage:
    raise RuntimeError("No website-specific homepage view was found.")

document = etree.fromstring(homepage.arch_db.encode())
wraps = document.xpath("//div[@id='wrap']")
if len(wraps) != 1:
    raise RuntimeError(f"Expected one #wrap in the homepage, found {len(wraps)}.")

wrap = wraps[0]
for child in tuple(wrap):
    wrap.remove(child)

for snippet_id, snippet_name in SNIPPETS:
    template = env.ref(f"website_webkit.{snippet_id}")
    template_document = etree.fromstring(template.arch_db.encode())
    sections = template_document.xpath("./section")
    if len(sections) != 1:
        raise RuntimeError(
            f"{template.get_external_id()[template.id]} must contain one root section."
        )
    section = deepcopy(sections[0])
    section.set("data-snippet", snippet_id)
    section.set("data-name", snippet_name)
    classes = section.get("class", "").split()
    if "o_colored_level" not in classes:
        classes.append("o_colored_level")
    section.set("class", " ".join(classes))
    wrap.append(section)

homepage.with_context(lang=None).write(
    {"arch_db": etree.tostring(document, encoding="unicode")}
)
env.cr.commit()

persisted = etree.fromstring(homepage.arch_db.encode())
actual = persisted.xpath("//div[@id='wrap']/section/@data-snippet")
expected = [snippet_id for snippet_id, _snippet_name in SNIPPETS]
if actual != expected:
    raise RuntimeError(f"Unexpected persisted snippet order: {actual!r}.")

print(f"homepage_id={homepage.id}")
print("snippet_order=" + ",".join(actual))
print("stage3_homepage_composition=OK")
