# Étape 5 — Personnalisation native ciblée

## Résultat

Le Hero Web Kit expose trois options directement dans le panneau du Website
Builder Odoo 19 :

| Option | Valeur par défaut | Variante |
| --- | --- | --- |
| Alignement du contenu | Gauche | Centré |
| Position du visuel | Droite | Gauche |
| Tonalité | Douce (`o_cc1`) | Contrastée (`o_cc5`) |

Les choix modifient immédiatement le rendu, sont persistés dans l'architecture
de la page et restent indépendants entre plusieurs instances du Hero. L'addon
est installé en version `19.0.4.0.0`.

## Décision d'architecture Odoo 19

La roadmap initiale cite `website.snippet_options`, `data-selector`,
`we-button-group` et `we-button`. Ces primitives correspondent à l'ancien
éditeur de snippets. Les sources officielles Odoo 19 utilisées par le projet
emploient désormais le builder OWL :

- `BaseOptionComponent` pour déclarer le composant d'options ;
- `Plugin` et le registre `website-plugins` pour le charger ;
- `BuilderRow`, `BuilderButtonGroup` et `BuilderButton` pour l'interface ;
- `classAction` pour appliquer et nettoyer les variantes ;
- `website.website_builder_assets` pour limiter le code au builder.

Le module utilise cette API réellement disponible. Introduire les anciennes
balises aurait produit une configuration non chargée par Odoo 19.

Le fichier JavaScript ne définit aucune action custom. Il enregistre seulement
un composant ciblant `.s_webkit_hero` à la position native
`SNIPPET_SPECIFIC`. Toutes les mutations sont réalisées par la `ClassAction`
standard d'Odoo.

## Contrat des classes

Les valeurs par défaut sont écrites explicitement sur le template :

```text
webkit_hero_align_start webkit_hero_media_end o_cc1
```

Les groupes de boutons remplacent respectivement ces classes par :

```text
webkit_hero_align_center webkit_hero_media_start o_cc5
```

Chaque groupe nettoie sa valeur précédente avant d'appliquer la nouvelle. Les
trois axes sont donc combinables sans état ambigu.

La position du visuel ne change l'ordre visuel qu'à partir du breakpoint `xl`.
Sur tablette et mobile, l'ordre sémantique du DOM est conservé : contenu puis
visuel. L'alignement centré ajuste également le titre, le texte, les CTA et la
ligne de réassurance. La tonalité contrastée utilise la palette Odoo `o_cc5`
et adapte les détails décoratifs avec les variables Bootstrap.

L'espacement n'est pas redéfini dans ce plugin : Odoo fournit déjà son contrôle
natif de padding sur les sections. Le dupliquer aurait créé deux sources de
vérité concurrentes.

## Isolation des assets

Le plugin et son template sont chargés uniquement dans :

```text
website.website_builder_assets
```

Ils ne font pas partie de `web.assets_frontend`. Un visiteur public ne télécharge
donc aucun JavaScript lié aux options. Seules les règles SCSS nécessaires au
rendu des classes persistées restent dans le bundle frontend.

## Vérification reproductible

Depuis le dossier `web-kit` :

```powershell
.\scripts\verify-stage5.ps1 -Browser
```

La commande rejoue toutes les recettes des étapes 3 et 4, puis contrôle :

- la version du module et la portée du bundle builder ;
- la syntaxe JavaScript et XML ;
- l'absence de l'ancienne API d'options ;
- l'absence de `BuilderAction` custom ;
- les trois groupes, leurs six classes et leurs états par défaut ;
- l'application immédiate des trois variantes ;
- la sauvegarde, le rechargement et les états actifs du panneau ;
- la combinaison des variantes à 1440, 1024, 768, 390 et 360 px ;
- l'absence de débordement, texte coupé, image cassée et erreur JavaScript ;
- une hauteur de CTA de 64 px et un contraste de `18,20:1` dans la variante
  contrastée ;
- l'indépendance de configuration après duplication ;
- la restauration automatique de la page canonique, même en cas d'échec.

## Critère de sortie

L'étape 5 est terminée : plusieurs options utiles modifient réellement le Hero
depuis le Website Builder, persistent après sauvegarde et ne dégradent aucune
des largeurs imposées par la roadmap.
