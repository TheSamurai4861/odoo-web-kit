import { BaseOptionComponent } from "@html_builder/core/utils";
import { SNIPPET_SPECIFIC } from "@html_builder/utils/option_sequence";
import { Plugin } from "@html_editor/plugin";
import { withSequence } from "@html_editor/utils/resource";
import { registry } from "@web/core/registry";

export class WebkitHeroOption extends BaseOptionComponent {
    static template = "website_webkit.WebkitHeroOption";
    static selector = ".s_webkit_hero";
}

export class WebkitHeroOptionPlugin extends Plugin {
    static id = "webkitHeroOption";
    resources = {
        builder_options: [withSequence(SNIPPET_SPECIFIC, WebkitHeroOption)],
    };
}

registry.category("website-plugins").add(WebkitHeroOptionPlugin.id, WebkitHeroOptionPlugin);
