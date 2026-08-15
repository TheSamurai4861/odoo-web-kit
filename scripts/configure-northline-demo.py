"""Apply, verify or restore the Northline state in ``webkit_dev``.

The script runs through ``odoo-bin shell``. It changes only the first website,
its company and four website-specific QWeb copies. Their original values are
saved to a private runtime JSON before the first mutation.
"""

import base64
import json
import os
from pathlib import Path


DATABASE = "webkit_dev"
ACTION = os.environ.get("WEBKIT_DEMO_ACTION", "").lower()
LOGO_PATH = Path(os.environ.get("WEBKIT_DEMO_LOGO", ""))
STATE_PATH = Path(os.environ.get("WEBKIT_DEMO_STATE", ""))
LEGACY_VIEW_KEYS = (
    "website_webkit.northline_demo_header_text",
    "website_webkit.northline_demo_header_cta",
    "website_webkit.northline_demo_footer",
    "website_webkit.northline_demo_copyright",
)
TARGETS = (
    ("website.header_text_element", "Northline Demo Header Text"),
    ("website.header_call_to_action", "Northline Demo Header CTA"),
    ("website.footer_custom", "Northline Demo Footer"),
    ("website.footer_copyright_company_name", "Northline Demo Copyright"),
)


if env.cr.dbname != DATABASE:
    raise RuntimeError(f"Refusing Northline demo changes in {env.cr.dbname!r}.")
if ACTION not in {"apply", "verify", "restore"}:
    raise RuntimeError("WEBKIT_DEMO_ACTION must be apply, verify or restore.")

website = env["website"].search([], order="id", limit=1)
if not website:
    raise RuntimeError("No website was found in webkit_dev.")
company = website.company_id


def encode_binary(value):
    if isinstance(value, bytes):
        return value.decode("ascii")
    return value or ""


def decode_binary(value):
    return value.encode("ascii") if value else False


def legacy_views():
    return env["ir.ui.view"].search([
        ("key", "in", LEGACY_VIEW_KEYS),
        ("website_id", "=", website.id),
    ])


def specific_view(parent_xmlid):
    parent = env.ref(parent_xmlid)
    return env["ir.ui.view"].with_context(active_test=False).search([
        ("key", "=", parent.key),
        ("website_id", "=", website.id),
    ], limit=1)


def upsert_view(name, parent_xmlid, arch):
    parent = env.ref(parent_xmlid)
    view = specific_view(parent_xmlid)
    values = {
        "name": name,
        "priority": 100,
        "active": True,
        "arch_db": arch,
    }
    if view:
        view.with_context(no_cow=True).write(values)
    else:
        view = parent.copy({
            **values,
            "key": parent.key,
            "website_id": website.id,
        })
    return view


if ACTION == "apply":
    if not LOGO_PATH.is_file():
        raise RuntimeError(f"Northline logo is missing: {LOGO_PATH}")

    if STATE_PATH.exists():
        state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
    else:
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        state = {
            "website": {
                "id": website.id,
                "name": website.name,
                "logo": encode_binary(website.logo),
            },
            "company": {
                "id": company.id,
                "name": company.name,
                "email": company.email or "",
                "phone": company.phone or "",
                "website": company.website or "",
            },
        }

    # Migrate state written by the first revision before changing the actual
    # website-specific QWeb copies. The legacy extensions never rendered, so
    # these architectures are still the pristine originals.
    if "views" not in state:
        state["views"] = []
        for parent_xmlid, _name in TARGETS:
            view = specific_view(parent_xmlid)
            state["views"].append({
                "parent_xmlid": parent_xmlid,
                "existed": bool(view),
                "name": view.name if view else "",
                "arch_db": view.arch_db if view else "",
                "priority": view.priority if view else 16,
                "active": view.active if view else True,
            })
        STATE_PATH.write_text(json.dumps(state, indent=2), encoding="utf-8")

    legacy_views().unlink()
    website.write({
        "name": "Northline",
        "logo": base64.b64encode(LOGO_PATH.read_bytes()),
    })
    company.write({
        "name": "Northline Demo Studio",
        "email": "hello@northline.example",
        "phone": False,
        "website": "https://northline.example",
    })

    upsert_view(
        "Northline Demo Header Text",
        "website.header_text_element",
        """
        <data>
            <xpath expr="." position="inside">
                <li t-attf-class="#{_item_class}">
                    <div t-attf-class="s_text_block #{_div_class}" data-name="Text">
                        <a href="mailto:hello@northline.example" class="nav-link o_nav-link_secondary p-2">
                            <i class="fa fa-envelope-o me-1" aria-hidden="true"/>
                            <small>hello@northline.example</small>
                        </a>
                    </div>
                </li>
            </xpath>
        </data>
        """,
    )
    upsert_view(
        "Northline Demo Header CTA",
        "website.header_call_to_action",
        """
        <data>
            <xpath expr="." position="inside">
                <li t-attf-class="#{_item_class}">
                    <div t-attf-class="oe_structure oe_structure_solo #{_div_class}">
                        <section class="oe_unremovable oe_unmovable s_text_block" data-snippet="s_text_block" data-name="Text">
                            <div class="container">
                                <a href="/contactus" class="oe_unremovable btn btn-primary btn_cta">Review a workflow</a>
                            </div>
                        </section>
                    </div>
                </li>
            </xpath>
        </data>
        """,
    )
    upsert_view(
        "Northline Demo Footer",
        "website.footer_custom",
        """
        <data>
            <xpath expr="//div[@id='footer']" position="replace">
                <div id="footer" class="oe_structure oe_structure_solo border text-break" t-ignore="true" t-if="not no_footer">
                    <section class="s_text_block pt48 pb32" data-snippet="s_text_block" data-name="Northline Footer">
                        <div class="container">
                            <div class="row g-4 align-items-start">
                                <div class="col-lg-6">
                                    <img src="/website_webkit/static/src/img/demo/northline-logo.svg"
                                         alt="Northline" width="180" height="48" class="img img-fluid mb-3"/>
                                    <p class="mb-2">A fictional Odoo workflow studio for Belgian service teams.</p>
                                    <p class="small text-muted mb-0">Demo brand created to present Odoo Web Kit. No commercial company is represented.</p>
                                </div>
                                <div class="col-sm-6 col-lg-3">
                                    <h5 class="h6 text-uppercase">Explore</h5>
                                    <ul class="list-unstyled mb-0">
                                        <li><a href="/">Home</a></li>
                                        <li><a href="/#northline-approach">Approach</a></li>
                                        <li><a href="/contactus">Contact</a></li>
                                    </ul>
                                </div>
                                <div class="col-sm-6 col-lg-3">
                                    <h5 class="h6 text-uppercase">Demo contact</h5>
                                    <a href="mailto:hello@northline.example">hello@northline.example</a>
                                    <p class="small text-muted mt-2 mb-0">The .example domain is reserved for documentation.</p>
                                </div>
                            </div>
                        </div>
                    </section>
                </div>
            </xpath>
        </data>
        """,
    )
    upsert_view(
        "Northline Demo Copyright",
        "website.footer_copyright_company_name",
        """
        <data>
            <xpath expr="//span[hasclass('o_footer_copyright_name')]" position="replace">
                <span class="o_footer_copyright_name me-2 small">Northline demo &#183; Odoo Web Kit</span>
            </xpath>
        </data>
        """,
    )
    env.cr.commit()
    print("northline_demo_apply=OK")

elif ACTION == "restore":
    if not STATE_PATH.is_file():
        raise RuntimeError(f"Northline backup state is missing: {STATE_PATH}")
    state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
    if state["website"]["id"] != website.id or state["company"]["id"] != company.id:
        raise RuntimeError("Northline backup does not match the current records.")

    legacy_views().unlink()
    for saved_view in state.get("views", []):
        view = specific_view(saved_view["parent_xmlid"])
        if saved_view["existed"]:
            if not view:
                raise RuntimeError(f"Cannot restore missing view {saved_view['parent_xmlid']}.")
            view.with_context(no_cow=True).write({
                "name": saved_view["name"],
                "arch_db": saved_view["arch_db"],
                "priority": saved_view["priority"],
                "active": saved_view["active"],
            })
        elif view:
            view.with_context(no_cow=True).unlink()

    website.write({
        "name": state["website"]["name"],
        "logo": decode_binary(state["website"]["logo"]),
    })
    company.write({
        "name": state["company"]["name"],
        "email": state["company"]["email"] or False,
        "phone": state["company"]["phone"] or False,
        "website": state["company"]["website"] or False,
    })
    env.cr.commit()
    STATE_PATH.unlink()
    print("northline_demo_restore=OK")

else:
    if website.name != "Northline":
        raise RuntimeError(f"Unexpected website name: {website.name!r}")
    if company.name != "Northline Demo Studio":
        raise RuntimeError(f"Unexpected company name: {company.name!r}")
    if company.email != "hello@northline.example" or company.phone:
        raise RuntimeError("Unexpected Northline demo contact data.")
    for parent_xmlid, expected_name in TARGETS:
        view = specific_view(parent_xmlid)
        if not view or view.name != expected_name:
            raise RuntimeError(f"Missing Northline view for {parent_xmlid}.")
    if not website.logo:
        raise RuntimeError("Northline website logo is absent.")

    for parent_xmlid, marker in (
        ("website.header_text_element", "hello@northline.example"),
        ("website.header_call_to_action", "Review a workflow"),
        ("website.footer_custom", "A fictional Odoo workflow studio"),
        ("website.footer_copyright_company_name", "Northline demo"),
    ):
        if marker not in specific_view(parent_xmlid).arch_db:
            raise RuntimeError(
                f"Northline marker absent from stored {parent_xmlid}: {marker!r}"
            )
    print("northline_demo_verify=OK")
