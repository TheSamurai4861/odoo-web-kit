# Étape 2 — Pipeline Odoo minimal

## Résultat

Le pipeline minimal Odoo Web Kit est opérationnel :

- addon `website_webkit` installé dans Odoo Community 19 ;
- dépendance limitée à `website` ;
- catégorie `Web Kit` visible dans le Website Builder ;
- snippet `Hello Web Kit` disponible dans cette catégorie ;
- contenu éditable avec l'éditeur natif ;
- sauvegarde et rechargement validés ;
- SCSS frontend compilé et appliqué ;
- aucun JavaScript custom ;
- installation, mise à jour, désinstallation et réinstallation contrôlées.

## Structure créée

~~~text
website_webkit\
├── __init__.py
├── __manifest__.py
├── views\
│   └── snippets\
│       ├── s_webkit_hello.xml
│       └── snippets.xml
└── static\
    └── src\
        ├── img\
        │   └── wbuilder\
        │       ├── s_webkit_hello.svg
        │       └── webkit_group.svg
        └── scss\
            └── webkit.scss
~~~

## Choix d'intégration Odoo 19

La structure suit directement le registre de snippets fourni par Odoo 19 :

- héritage de `website.snippets` ;
- catégorie via `snippet-group="webkit"` ;
- ajout après `installed_snippets_hook` ;
- bloc enregistré dans `snippet_structure` ;
- référence `t-snippet="website_webkit.s_webkit_hello"` ;
- rattachement via `group="webkit"`.

### Glisser-déposer et catégorie

Dans Odoo 19, une catégorie dédiée suit ce workflow natif :

1. glisser ou cliquer la vignette `Web Kit` ;
2. Odoo ouvre la boîte `Insert a block` sur l'onglet `Web Kit` ;
3. sélectionner l'aperçu `Hello Web Kit` ;
4. Odoo insère le bloc dans la page.

La recette navigateur a validé le glisser-déposer de la catégorie vers la page,
l'ouverture automatique de l'onglet `Web Kit`, puis la présence de l'aperçu du
snippet. L'insertion par l'aperçu, l'édition, la sauvegarde et le rechargement ont
également été validés de bout en bout.

## Critères d'acceptation vérifiés

### Structure et code

- Manifest Python analysable avec `ast.literal_eval`.
- Version `19.0.1.0.0`.
- Dépendance unique `website`.
- Deux vues XML et deux SVG bien formés.
- SCSS strictement placé sous `.s_webkit_hello`.
- Classes custom préfixées `s_webkit_` ou `webkit_`.
- Aucun dossier ou module JavaScript.

### Odoo et base de données

- État `website_webkit|installed|19.0.1.0.0`.
- Deux vues QWeb actives : template du snippet et héritage du registre.
- Registre combiné contenant exactement une catégorie `webkit` et une référence
  au snippet.
- Homepage spécifique au Website contenant exactement une section
  `.s_webkit_hello`.
- Métadonnées persistantes : `data-snippet="s_webkit_hello"` et
  `data-name="Hello Web Kit"`.

### Assets et rendu

- Les deux vignettes SVG répondent en HTTP 200.
- `webkit.scss` est présent dans `web.assets_frontend` en mode debug.
- Le sélecteur `.s_webkit_hello` est présent dans le CSS compilé.
- Styles calculés dans le navigateur : bordure solide de 1 px, rayon de 16 px
  et ombre active.

### Recette navigateur

- Catégorie `Web Kit` visible avec sa vignette.
- Catégorie marquée `o_draggable` par Odoo.
- Glisser-déposer vers le footer ouvrant le dialogue `Web Kit`.
- Aperçu `Hello Web Kit` présent dans l'iframe de sélection.
- Titre passant en état éditable après sélection.
- Titre modifié en `Hello Web Kit — Stage 2 verified`.
- Sauvegarde réussie et texte identique après rechargement.
- Aucune erreur JavaScript interceptée.

### Cycle de vie

- Mise à jour `-u website_webkit` réussie.
- Sauvegarde PostgreSQL de contrôle créée avant le test destructif.
- Désinstallation réussie avec suppression des vues du module.
- Réinstallation réussie sur la même base.
- Empreinte SHA-256 de la homepage inchangée après le cycle.
- Recette complète réussie après réinstallation.

## Lancer les vérifications

Contrôle serveur, structure, base, QWeb, assets et persistance :

~~~powershell
.\scripts\verify-stage2.ps1
~~~

Contrôle complet avec navigateur headless et glisser-déposer :

~~~powershell
.\scripts\verify-stage2.ps1 -Browser
~~~

Le test navigateur utilise Microsoft Edge installé localement. Sa dépendance
Playwright Core est conservée uniquement dans `.runtime\browser-check` et ne fait
pas partie de l'addon.

## Preuves locales

Les captures de validation, exclues du dépôt, sont enregistrées dans `.runtime` :

- `stage2-category.png` ;
- `stage2-before-save.png` ;
- `stage2-persisted.png` ;
- `stage2-drag-dialog.png`.

La sauvegarde de contrôle du cycle de vie se trouve dans :

`C:\Famille\Venom\DEV\odoo\.runtime\checkpoints\pre-stage2-lifecycle.dump`

## Passage à l'étape 3

La chaîne verticale Odoo est maintenant sécurisée. Le snippet de validation peut
servir de référence technique pendant la réalisation du Hero, puis être retiré
du produit final lorsque les quatre vrais blocs seront enregistrés et validés.
