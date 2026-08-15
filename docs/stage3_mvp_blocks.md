# Étape 3 — MVP des quatre blocs Web Kit

## Résultat

L'addon `website_webkit` fournit quatre snippets Odoo Website 19 prêts à être
utilisés depuis la catégorie **Web Kit** du Website Builder :

1. **Web Kit Hero** — proposition de valeur, deux CTA, visuel et réassurance ;
2. **Web Kit Features** — trois cartes statiques de bénéfices ;
3. **Web Kit Trust** — témoignage, identité, note et indicateurs ;
4. **Web Kit CTA** — argument final, CTA et réassurance.

La page d'accueil de `webkit_dev` est composée dans cet ordre. Tous les textes
restent éditables par le moteur d'édition Odoo. Les liens sont des ancres
natives et les visuels utilisent la classe `img`, ce qui expose les outils
standard de remplacement et de transformation du Website Builder.

## Architecture

Chaque bloc possède :

- un template QWeb autonome dans `website_webkit/views/snippets/` ;
- un aperçu SVG dans `website_webkit/static/src/img/wbuilder/` ;
- un fichier SCSS isolé sous son sélecteur racine `.s_webkit_*` ;
- des classes Bootstrap/Odoo pour la grille, les espacements, les boutons et
  les palettes `o_cc`.

Les variables et le mixin communs sont centralisés dans `_tokens.scss`. Les
partiels sont déclarés explicitement et dans l'ordre dans le manifeste. Cette
stratégie est volontaire : le pipeline Sass concaténé d'Odoo ne résout pas de
façon fiable un import local court comme `@import "tokens"` lorsque Bootstrap
est déjà dans le bundle.

Aucun JavaScript custom et aucune dépendance additionnelle ne sont introduits
par ce MVP.

## Recomposer la page de démonstration

Le script de composition est idempotent. Il reconstruit le contenu de `#wrap`
depuis les quatre templates canoniques et ajoute les métadonnées attendues par
le Website Builder.

Depuis le dossier `web-kit`, dans PowerShell :

```powershell
$odooRoot = Split-Path -Parent (Get-Location)
Get-Content -Raw .\scripts\compose-stage3-homepage.py |
    & "$odooRoot\.venv-odoo19\Scripts\python.exe" `
      "$odooRoot\odoo-19\odoo-bin" shell `
      -c "$odooRoot\.runtime\odoo-dev.conf" `
      -d webkit_dev --no-http
```

Un redémarrage d'Odoo est requis après une modification effectuée par un
processus `odoo-bin shell` séparé, afin d'invalider le cache de vues du serveur
déjà actif :

```powershell
.\scripts\stop-dev.ps1
.\scripts\start-dev.ps1
```

## Vérification

La validation automatisée complète s'exécute avec :

```powershell
.\scripts\verify-stage3.ps1 -Browser
```

Elle contrôle :

- l'environnement Python, PostgreSQL et Odoo ;
- le manifeste, l'ordre du bundle, le parsing XML/SVG et la sémantique ;
- l'absence de JavaScript custom et l'isolation des styles ;
- l'installation d'une version Odoo 19 de `website_webkit` au moins égale à
  `19.0.2.0.0` ;
- les ressources statiques et le bundle CSS réellement servis par HTTP ;
- les quatre vues QWeb et le registre combiné du Website Builder ;
- l'ordre persistant de la page d'accueil ;
- la présence des quatre previews dans la catégorie **Web Kit** ;
- l'édition et la persistance d'un texte ;
- les options natives de remplacement d'image et le lien CTA ;
- la duplication, le déplacement, la sauvegarde et le rechargement ;
- l'absence d'erreur JavaScript dans le navigateur.

Le scénario navigateur sauvegarde l'architecture initiale et la restaure dans
son nettoyage, y compris si une assertion échoue. Il ne laisse donc ni texte
de test, ni duplication, ni ordre artificiel dans la base.

Les conflits de sérialisation du compteur `website_visitor` sont uniquement
classés comme récupérés lorsqu'ils portent la signature exacte de cette
transaction et qu'Odoo annonce encore des tentatives disponibles. Toute autre
erreur SQL, erreur critique ou traceback reste bloquant.

## Critère de sortie

L'étape 3 est terminée : les quatre blocs sont utilisables, éditables et
persistants dans Odoo 19. L'affinage systématique des variantes responsive,
des animations et de la finition visuelle appartient à l'étape 4 de la
roadmap.
