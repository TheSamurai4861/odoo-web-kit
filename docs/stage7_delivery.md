# Étape 7 — Démonstration et livraison

## Statut

**Terminée et validée le 13 août 2026.** Odoo Web Kit est présenté comme un
addon Odoo 19 installable, démontrable et partageable, avec des preuves issues
de l'interface réelle.

## Plan exécuté

1. Revalider les garanties fonctionnelles et qualité des étapes 1 à 6.
2. Stabiliser la homepage Northline avec les quatre snippets canoniques.
3. Rédiger un README orienté compréhension en moins d'une minute.
4. Automatiser six captures de preuve desktop, mobile et Website Builder.
5. Enregistrer un scénario réel de 60 à 90 secondes dans Odoo.
6. Restaurer automatiquement la homepage après toute démonstration.
7. Auditer dimensions, poids, codec, durée, liens et documentation.
8. Initialiser un historique Git lisible puis exécuter la gate finale.

## Homepage Northline

La page de référence contient exactement, entre le header et le footer natifs
d'Odoo :

1. `s_webkit_hero` ;
2. `s_webkit_features` ;
3. `s_webkit_trust` ;
4. `s_webkit_cta`.

La composition est idempotente grâce à `scripts/compose-stage3-homepage.py`.
Les contrôles Stage 3 à Stage 7 vérifient l'ordre persisté, l'absence de
ressource cassée et le rendu public.

## README

Le `README.md` place le résultat visuel en premier, puis expose la motivation,
les quatre composants, l'installation, l'usage, l'architecture, les décisions
de design, l'accessibilité, les preuves QA et les suites possibles. Tous ses
liens relatifs sont vérifiés automatiquement.

## Captures livrées

| Fichier | Preuve apportée |
|---|---|
| `homepage-desktop.png` | Homepage Northline complète à 1440 px |
| `homepage-mobile.png` | Reflow complet à 390 px |
| `four-components.png` | Collection isolée entre header et footer |
| `website-builder.png` | Page ouverte dans le Website Builder natif |
| `web-kit-category.png` | Catégorie Web Kit et ses quatre aperçus |
| `hero-options.png` | Hero sélectionné et trois options natives visibles |

Les captures sont régénérées par `scripts/capture-stage7-media.cjs`. Le script
attend le chargement effectif des images différées, vérifie l'ordre des blocs,
les débordements et les erreurs navigateur avant d'écrire les PNG.

## Vidéo de démonstration

Le fichier `docs/media/odoo-web-kit-demo.mp4` dure **72,134 secondes**. Il est
encodé en H.264, 1280 × 720, `yuv420p`, avec démarrage rapide HTTP et sans piste
audio superflue.

Storyboard observé :

- **0–13 s :** homepage finale et parcours des composants ;
- **13–20 s :** passage dans le Website Builder ;
- **20–30 s :** ouverture de la catégorie Web Kit ;
- **30–41 s :** insertion d'un nouveau Hero ;
- **41–54 s :** modification du titre et centrage natif ;
- **54–65 s :** sauvegarde et rendu public ;
- **65–72 s :** reflow mobile puis plan final desktop.

L'enregistrement s'appuie sur l'interface Odoo réelle. La vue `website.homepage`
est sauvegardée avant le scénario et restaurée dans un bloc `finally`, y compris
en cas d'échec. Le contrôle final exige de nouveau la composition canonique.

## Reproduction

Prérequis local pour l'enregistrement Playwright :

```powershell
cd ..\.runtime\browser-check
npx playwright-core install ffmpeg
```

Régénérer tous les médias :

```powershell
.\scripts\generate-stage7-media.ps1
```

Contrôle rapide de la livraison :

```powershell
.\scripts\verify-stage7.ps1
```

Gate finale, incluant toute la recette de l'étape 6 :

```powershell
.\scripts\verify-stage7.ps1 -Full
```

## Git et partage

Le workspace est un dépôt Git sur `main`. L'historique sépare la baseline
fonctionnelle et validée des étapes 1 à 6 de la livraison documentaire et
média de l'étape 7. Les caches Python et les artefacts d'exécution restent
exclus ; les six PNG et le MP4 final sont volontairement versionnés.

La publication vers un hébergeur distant n'est pas effectuée : elle nécessite
le compte et la destination choisis par le propriétaire du projet.

## Critère de sortie

Depuis un clone, une personne peut installer l'addon dans Odoo 19, ouvrir le
Website Builder, trouver `Web Kit`, déposer le Hero, modifier son contenu et
obtenir un résultat professionnel. Le README, les captures et la vidéo rendent
ce parcours compréhensible en moins de 90 secondes. Le jalon final est atteint.
