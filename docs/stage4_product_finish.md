# Étape 4 — Finition produit et responsive

## Résultat

Les quatre blocs Web Kit forment désormais une collection visuelle cohérente,
compatible avec les palettes Odoo et utilisable de 360 à 1440 px sans
débordement, contenu coupé ni interaction inaccessible. Cette finition a été
introduite avec la version `19.0.3.0.0` de l'addon.

## Système de design

Le système reste volontairement petit. Il complète Odoo et Bootstrap sans les
remplacer :

- **couleurs** : `$primary`, `$body-color`, `$white` et `var(--o-color-1)` ;
- **surfaces** : palettes natives `o_cc`, bordures dérivées de `$body-color` ;
- **rayons** : `$border-radius-lg` et `$border-radius-xl` ;
- **espacements** : `$spacer`, grille Bootstrap et classes Odoo `pt*`/`pb*` ;
- **ombres** : deux niveaux communs, dérivés de `$body-color` ;
- **mouvement** : transition commune de 180 ms, uniquement sur appareil doté
  d'un vrai pointeur de survol ;
- **focus** : anneau double blanc/primary, visible sur surfaces claires et
  sombres.

Les fichiers SCSS du module ne contiennent aucune couleur hexadécimale
hardcodée. Les SVG de démonstration conservent leur propre palette, car ils
sont des contenus graphiques et non des règles de thème.

## Matrice responsive

| Largeur | Contrat de mise en page |
| ---: | --- |
| 1440 px | Hero, Trust et CTA en colonnes ; trois cartes Features |
| 1024 px | Hero, Trust et CTA empilés ; trois cartes Features |
| 768 px | Blocs principaux empilés ; Features en grille `2 + 1` |
| 390 px | Une colonne, actions pleine largeur, espacements compacts |
| 360 px | Même contrat mobile, sans débordement horizontal |

Les rangées principales utilisent `g-4 g-xl-5`. Le passage de `g-5` à `g-4`
sur mobile élimine le dépassement initial de 9 px observé à 390 et 360 px. Les
colonnes Hero et Trust basculent désormais à `xl`, ce qui évite les CTA sur
plusieurs lignes et le titre excessivement étroit observés à 1024 px.

Les espaces verticaux Odoo sont conservés sur grand écran, puis ramenés à
`5 × $spacer` sur tablette et `4 × $spacer` sur mobile. Les titres utilisent
un équilibrage de lignes et les contenus éditables autorisent un retour à la
ligne sûr avec `overflow-wrap: anywhere`.

## Accessibilité et interactions

La recette garantit :

- une seule balise `h1` dans le contenu ;
- des images avec attribut `alt` ;
- des liens nommés et dotés d'un `href` ;
- aucune icône décorative exposée à l'arbre accessible ;
- aucun ID dupliqué ;
- une hauteur minimale de 44 px pour chaque action des snippets ;
- un focus visible de 3 px complété par un anneau externe de 6 px ;
- la neutralisation du déplacement des cartes avec
  `prefers-reduced-motion: reduce`.

Contrastes mesurés sur le thème de développement :

| Paire | Ratio |
| --- | ---: |
| Corps de texte / blanc | 15,43:1 |
| Primaire / blanc | 8,36:1 |
| Blanc / bouton primaire | 7,23:1 |
| Blanc / surface CTA | 18,20:1 |
| Réassurance atténuée / surface CTA | 11,28:1 |

Tous dépassent le seuil WCAG AA de 4,5:1 pour le texte normal.

## Vérification reproductible

Depuis le dossier `web-kit` :

```powershell
.\scripts\verify-stage4.ps1 -Browser
```

La commande exécute d'abord toutes les non-régressions de l'étape 3, y compris
les opérations réelles d'édition, duplication, déplacement, sauvegarde et
restauration. Elle contrôle ensuite :

- la version et le contrat statique des templates ;
- l'emploi des variables Odoo/Bootstrap et l'absence de couleurs SCSS
  hardcodées ;
- le bundle CSS réellement compilé et servi par Odoo ;
- les cinq viewports imposés par la roadmap ;
- la géométrie des grilles, les cibles interactives, images et textes ;
- la sémantique, les contrastes, le focus et le mouvement réduit ;
- l'intégration dans l'iframe du Website Builder ;
- les erreurs JavaScript, erreurs critiques, requêtes SQL non récupérées et
  tracebacks.

Les captures générées sont stockées hors du projet dans `.runtime` sous les
noms `stage4-responsive-<largeur>.png`.

## Critère de sortie

L'étape 4 est terminée : les quatre blocs peuvent être montrés sans explication
préalable, restent cohérents avec le thème Odoo actif et satisfont tous les
contrats responsive et interactifs automatisés.
