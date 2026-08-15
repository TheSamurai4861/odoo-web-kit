{
    "name": "Odoo Web Kit",
    "summary": "Modern building blocks for Odoo Website",
    "version": "19.0.4.0.0",
    "category": "Website/Website",
    "author": "Mattéo Vanderheyden",
    "license": "LGPL-3",
    "depends": [
        "website",
    ],
    "data": [
        "views/snippets/s_webkit_hero.xml",
        "views/snippets/s_webkit_features.xml",
        "views/snippets/s_webkit_trust.xml",
        "views/snippets/s_webkit_cta.xml",
        "views/snippets/snippets.xml",
    ],
    "assets": {
        "web.assets_frontend": [
            "website_webkit/static/src/scss/_tokens.scss",
            "website_webkit/static/src/scss/_hero.scss",
            "website_webkit/static/src/scss/_features.scss",
            "website_webkit/static/src/scss/_trust.scss",
            "website_webkit/static/src/scss/_cta.scss",
            "website_webkit/static/src/scss/webkit.scss",
        ],
        "website.website_builder_assets": [
            "website_webkit/static/src/builder/**/*",
        ],
    },
    "application": False,
    "installable": True,
}
