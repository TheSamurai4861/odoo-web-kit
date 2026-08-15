"""Assertions executed inside ``odoo-bin shell`` by the integration job."""

from lxml import etree


module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
assert module.state == "installed", module.state
assert module.latest_version == "19.0.5.0.0", module.latest_version

snippet_ids = (
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
)
for snippet_id in snippet_ids:
    view = env.ref(f"website_webkit.{snippet_id}")
    assert view.active
    assert view.type == "qweb"

registry = etree.tostring(env.ref("website.snippets")._get_combined_arch(), encoding="unicode")
assert registry.count('snippet-group="webkit"') == 1
for snippet_id in snippet_ids:
    assert registry.count(f't-snippet="website_webkit.{snippet_id}"') == 1

print("ci_odoo_install=installed|19.0.5.0.0")
print("ci_odoo_registry=hero|features|trust|cta")
