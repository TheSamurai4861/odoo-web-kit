# Étape 6 — Validation qualité complète

## Statut

**Terminée et validée le 13 août 2026.** Le module `website_webkit`
`19.0.4.0.0` satisfait les critères de sortie de l'étape 6 sur Odoo 19
Community.

## Plan de validation exécuté

1. Rejouer les gates des étapes 1 à 5.
2. Auditer le manifest, les assets, les sources XML/SVG et le paquet livré.
3. Tester installation, mise à jour, désinstallation et réinstallation dans une
   base QA jetable.
4. Valider les quatre snippets dans le Website Builder sur une installation
   fraîche.
5. Contrôler édition, options du Hero, duplication, déplacement, sauvegarde et
   rechargement.
6. Vérifier le responsive aux largeurs de référence et le reflow à 200 %.
7. Parcourir les actions au clavier et contrôler le focus visible.
8. Contrôler les erreurs navigateur, serveur et les ressources cassées.
9. Mesurer les budgets d'assets et lancer Lighthouse.
10. Vérifier que le cœur Odoo est resté intact et publier un validateur unique.

## Matrice de recette

| Axe | Vérification | Résultat |
|---|---|---|
| Cycle de vie | Installation fraîche sans données de démonstration | OK |
| Cycle de vie | Mise à jour du module avec page personnalisée | OK, contenu préservé |
| Cycle de vie | Désinstallation puis réinstallation | OK, vues techniques nettoyées et page utilisateur préservée |
| Builder | Catégorie `Web Kit` et quatre aperçus | OK |
| Builder | Glisser-déposer, édition et options natives du Hero | OK |
| Builder | Duplication, déplacement, sauvegarde et rechargement | OK |
| Responsive | 1440, 1024, 768, 390 et 360 px | OK |
| Zoom | Reflow à 200 %, sans débordement horizontal ni texte coupé | OK |
| Clavier | Six actions atteignables dans l'ordre logique | OK |
| Focus | Indicateur visible de 3 px, décalage de 3 px et halo | OK |
| Médias | Images chargées et textes alternatifs présents | OK |
| Technique | XML/SVG analysables sans DTD, entité ou ressource distante | OK |
| Exécution | Aucune erreur Web Kit en console ou dans les logs Odoo | OK |
| Isolation | Branche Odoo `19.0`, commit `c2a39085`, arbre propre | OK |

La base `webkit_qa_stage6` est créée uniquement pour le test. Le script refuse
d'écraser une base existante, utilise le port isolé `8070`, arrête le serveur
QA et supprime la base dans un bloc `finally`.

## Audit du paquet

Le paquet applicatif exclut les caches Python et respecte les budgets suivants :

| Mesure | Valeur observée | Budget |
|---|---:|---:|
| Fichiers livrables | 22 | inventaire exact |
| Taille totale | 32 935 octets | 65 536 octets |
| SCSS | 7 624 octets | 16 384 octets |
| SVG | 7 996 octets | 16 384 octets |
| Assets du Builder | 2 525 octets | 8 192 octets |
| JavaScript public Web Kit | 0 requête | 0 |

Les fichiers éventuellement créés dans `__pycache__` sont des artefacts
d'exécution locaux, explicitement exclus par `.gitignore`; ils ne font pas
partie de l'inventaire livré.

## Accessibilité et zoom

La navigation par tabulation atteint, dans l'ordre visuel, les deux CTA du
Hero, les trois liens Features puis le CTA final. Chaque cible conserve un
focus visible et une hauteur minimale de 44 px.

Le contrôle à 200 % simule un écran physique de 1440 px rendu dans une fenêtre
de 720 pixels CSS avec un facteur de périphérique de 2. La page conserve
l'ordre Hero → Features → Trust → CTA, ne crée aucun débordement horizontal,
ne coupe aucun texte et ne contient aucune image cassée. Une capture complète
est générée dans `.runtime/stage6-zoom-200.png`.

## Performance

Lighthouse 13.4.1, profil desktop, a produit les résultats de référence
suivants :

| Catégorie ou métrique | Résultat |
|---|---:|
| Performance | 86 / 100 |
| Accessibilité | 95 / 100 |
| Bonnes pratiques | 96 / 100 |
| SEO | 100 / 100 |
| First Contentful Paint | 1 596 ms |
| Largest Contentful Paint | 1 756 ms |
| Total Blocking Time | 26 ms |
| Cumulative Layout Shift | 0,0204 |

La page complète transfère environ 3,24 Mo, majoritairement issus des bundles
standards d'Odoo. Web Kit ajoute seulement deux requêtes SVG pour 5 877 octets
transférés, aucune requête JavaScript publique, aucune ressource en échec et
aucun échec d'accessibilité rattaché à ses sections.

Un audit mobile de référence a aussi exposé deux défauts du footer de
démonstration fourni par Odoo (`heading-order` et `link-in-text-block`). Ils ne
touchent aucun nœud `s_webkit_*`; ils sont donc documentés comme dette du
conteneur de démonstration, sans être masqués ni attribués à l'addon.

## Commandes de vérification

Contrôle rapide, sans navigation ni création de base :

```powershell
.\scripts\verify-stage6.ps1
```

Gate de livraison complète :

```powershell
.\scripts\verify-stage6.ps1 -Full
```

`-Full` rejoue toutes les étapes précédentes, les tests navigateur, le cycle de
vie sur base fraîche et Lighthouse. Les sous-contrôles peuvent aussi être
activés séparément avec `-Browser`, `-Lifecycle` ou `-Lighthouse`.

## Critère de sortie

Une base Odoo 19 fraîche peut installer `website_webkit` sans donnée manuelle,
afficher immédiatement la catégorie `Web Kit`, déposer chacun des quatre
blocs, personnaliser le Hero et sauvegarder une page stable. Le jalon de sortie
de l'étape 6 est atteint.
