# Roadmap — Odoo Web Kit

## Vision du projet

Odoo Web Kit est un addon pour **Odoo 19 Community** qui enrichit le Website
Builder avec quatre blocs modernes, réutilisables et configurables : **Hero**,
**Features**, **Trust** et **CTA / Lead**.

Le résultat attendu n'est pas une page HTML isolée ni un thème complet. Le
produit doit se comporter comme une extension native d'Odoo : installation du
module, catégorie `Web Kit` dans l'éditeur, glisser-déposer, édition du contenu,
sauvegarde et rendu responsive sans écrire de code.

La priorité directrice est la suivante : **intégration Odoo, fiabilité,
finition, puis fonctionnalités bonus**. Quatre blocs aboutis ont plus de valeur
qu'une bibliothèque plus large mais incomplète.

## Point de départ

Au 13 août 2026, le cahier de lancement est rédigé, mais le dépôt ne contient
pas encore l'addon. La roadmap part donc d'une initialisation complète du projet.

## Vue d'ensemble

| Étape | Objectif | Livrable principal | Budget indicatif |
|---|---|---|---:|
| 1. Socle de développement | Obtenir une instance Odoo 19 Website exploitable | Environnement local validé | 2 h |
| 2. Pipeline Odoo minimal | Prouver l'intégration avant le design | Snippet `Hello Web Kit` glissable | 2 h |
| 3. MVP des quatre blocs | Livrer toute la valeur fonctionnelle essentielle | Hero, Features, Trust et CTA éditables | 11 h |
| 4. Finition produit | Donner une cohérence premium et responsive | Design system léger et rendus finalisés | 3 h |
| 5. Personnalisation native | Montrer la maîtrise du Website Builder | Options Odoo ciblées, en priorité sur le Hero | 2 h |
| 6. Validation qualité | Garantir un module fiable et présentable | Recette Odoo, responsive, accessibilité et performance | 2 h |
| 7. Démonstration et livraison | Rendre le projet compréhensible en 90 secondes | README, page démo, captures et vidéo | 4 h |

Budget MVP cible : **environ 26 heures**, avec une réserve de 2 heures pour les
bugs, soit un maximum visé de **28 heures**, hors bonus optionnels.

## Projection sur quatre jours

- **Jeudi — fondations :** étapes 1 et 2, puis première version du Hero.
- **Vendredi — couverture fonctionnelle :** fin du Hero et réalisation des
  trois autres snippets.
- **Samedi — finition :** étapes 4 et 5 ; le bonus n'est ouvert que si le MVP
  est déjà stable.
- **Dimanche — livraison :** étapes 6 et 7, sans démarrer de nouvelle
  fonctionnalité.

## 1. Mettre en place le socle de développement

**Statut : terminé et validé le 13 août 2026.** La procédure et les preuves de
recette sont consignées dans `docs/development_environment.md`.

### Description

Préparer un environnement de développement séparant clairement les sources
officielles d'Odoo du code de l'addon. Utiliser Odoo 19 Community depuis les
sources, un environnement Python isolé et PostgreSQL.

### Travaux principaux

- Vérifier Git, une version Python compatible — Python 3.12 est le choix cible —
  et PostgreSQL 13 ou supérieur.
- Cloner la branche `19.0` d'Odoo et installer ses dépendances dans un virtualenv.
- Créer la base `webkit_dev`, démarrer Odoo et installer Website.
- Activer le mode développeur et valider le workflow d'édition d'une page.
- Conserver le module custom en dehors du cœur d'Odoo.

### Jalon de sortie

L'étape est terminée lorsque `http://localhost:8069` est accessible, que le
backend et Website fonctionnent, et qu'une page peut être ouverte en mode
édition.

## 2. Valider le pipeline Odoo avec un snippet minimal

**Statut : terminé et validé le 13 août 2026.** Le compte rendu technique et
les commandes de recette sont disponibles dans `docs/stage2_hello_webkit.md`.

### Description

Construire la plus petite tranche verticale possible avant de commencer le
design. Cette étape doit éliminer tôt les risques liés au manifest, aux vues
XML, aux assets et à l'enregistrement des snippets.

### Travaux principaux

- Créer l'addon `website_webkit` avec `__init__.py` et `__manifest__.py`.
- Dépendre uniquement de `website` pour le MVP.
- Déclarer une catégorie `Web Kit` dans le Website Builder.
- Ajouter un snippet minimal `Hello Web Kit`.
- Installer ou mettre à jour le module, glisser le bloc, sauvegarder puis
  recharger la page.
- Préparer la structure SCSS avec des sélecteurs strictement préfixés par
  `s_webkit_` ou `webkit_`.

### Jalon de sortie

La chaîne suivante doit être démontrable de bout en bout :

`Odoo 19 → Website → Edit → Web Kit → drag & drop → sauvegarde → rechargement`

Tant que ce jalon n'est pas atteint, le travail de design détaillé ne commence
pas.

## 3. Développer le MVP des quatre blocs

> **Statut : terminé et vérifié.** Le détail de l'implémentation et la
> procédure de validation sont consignés dans
> [stage3_mvp_blocks.md](stage3_mvp_blocks.md).

### Description

Implémenter les quatre snippets avec une approche **Bootstrap/Odoo d'abord,
SCSS spécifique ensuite**. Chaque bloc est validé dans l'éditeur avant de
passer au suivant.

### 3.1 Web Kit Hero

Créer un Hero de conversion avec badge facultatif, titre principal, texte,
deux CTA, visuel et élément de réassurance. La structure repose sur la grille
Bootstrap et garde les contenus directement éditables dans Odoo.

### 3.2 Web Kit Features

Créer une section de trois à six avantages sous forme de cartes statiques :
icône, titre, texte et lien facultatif. L'ajout ou la suppression dynamique de
cartes par JavaScript ne fait pas partie du MVP.

### 3.3 Web Kit Trust

Créer un bloc de confiance statique mettant en valeur une citation, une
identité, un rôle et éventuellement quelques indicateurs. Aucun carousel n'est
nécessaire à ce stade.

### 3.4 Web Kit CTA / Lead

Créer une fin de page orientée conversion avec argument final, texte, CTA et
réassurance. Si un formulaire est retenu, réutiliser le mécanisme Website Form
d'Odoo au lieu de reconstruire validation, soumission et backend.

### Validation commune à chaque bloc

- Le bloc apparaît dans la catégorie `Web Kit` et peut être glissé-déposé.
- Ses textes, liens et images pertinentes sont éditables.
- Il peut être déplacé, dupliqué, sauvegardé et rechargé sans casser la mise en
  page.
- Son HTML reste sémantique et son SCSS est isolé du reste du site.
- Il n'introduit ni dépendance ni JavaScript sans bénéfice démontrable.

### Jalon de sortie

Les quatre blocs sont fonctionnels dans Odoo, même si leur finition visuelle
et responsive doit encore être affinée.

## 4. Transformer le MVP en produit fini

> **Statut : terminé et vérifié.** Le système visuel, la matrice responsive et
> la procédure de recette sont détaillés dans
> [stage4_product_finish.md](stage4_product_finish.md).

### Description

Appliquer une direction visuelle cohérente, moderne, professionnelle et
légèrement premium, tout en respectant les thèmes Odoo. Le branding fictif
sert les composants ; il ne doit pas devenir un projet parallèle.

### Travaux principaux

- Définir un petit système de design : couleurs de thème, surfaces,
  typographie, rayons, bordures, ombres et espacements.
- Limiter les valeurs hardcodées et exploiter les classes, variables et styles
  disponibles dans Odoo/Bootstrap.
- Affiner hiérarchie visuelle, alignements, états interactifs et cohérence entre
  les quatre blocs.
- Tester chaque composant autour de 1440, 1024, 768, 390 et 360 px.
- Après chaque correction mobile, retester le rendu desktop.

### Jalon de sortie

Les quatre blocs forment une collection cohérente, sans débordement, texte
coupé ni interaction inaccessible, et peuvent être montrés sans explication
préalable.

## 5. Ajouter une personnalisation native ciblée

> **Statut : terminé et vérifié.** Les options du Hero, leur implémentation
> native Odoo 19 et la recette sont détaillées dans
> [stage5_native_customization.md](stage5_native_customization.md).

### Description

Une fois le MVP stable, enrichir en priorité le Hero avec les options natives
du Website Builder. Cette étape démontre une compréhension plus profonde
d'Odoo qu'une animation décorative.

### Options candidates

- Alignement gauche ou centré.
- Visuel à gauche ou à droite.
- Variante douce ou contrastée.
- Espacement de section.
- Variante de style des cartes, si le temps le permet.

Les options doivent s'appuyer sur les mécanismes Odoo tels que
`website.snippet_options`, `data-selector`, `we-button-group`, `we-button` et
`we-range`.

### Jalon de sortie

Au moins une option utile modifie réellement le Hero depuis l'éditeur, persiste
après sauvegarde et ne dégrade aucune largeur d'écran.

## 6. Effectuer la validation qualité complète

> **Statut : terminé et vérifié.** La matrice de recette, les budgets d'assets,
> le cycle de vie sur base fraîche et les preuves Lighthouse sont détaillés
> dans [stage6_quality_validation.md](stage6_quality_validation.md).

### Description

Vérifier le produit comme un utilisateur Odoo, pas seulement comme un auteur
du code. Les contrôles automatiques complètent, mais ne remplacent pas, la
recette manuelle.

### Axes de recette

- **Odoo :** installation, désinstallation, réinstallation sur base propre,
  présence de la catégorie, drag & drop, édition, duplication, déplacement,
  sauvegarde et rechargement.
- **Technique :** manifest et assets propres, absence d'erreurs XML, console
  navigateur ou logs serveur importantes, aucune modification du cœur Odoo.
- **Responsive :** contenu lisible, images maîtrisées, CTA accessibles et
  colonnes correctement réorganisées.
- **Accessibilité :** hiérarchie de titres, textes alternatifs, contraste,
  focus visible, navigation au clavier et zoom à 200 % raisonnable.
- **Performance :** images optimisées, CSS et JS limités, audit Lighthouse sans
  défaut critique.

### Jalon de sortie

Une installation fraîche permet d'utiliser immédiatement les quatre blocs sans
étape manuelle cachée ni erreur majeure.

## 7. Construire la démonstration et préparer la livraison

### Description

Transformer le module fonctionnel en preuve de candidature immédiatement
compréhensible. La présentation doit montrer à la fois le rendu et la réalité
de l'intégration dans Odoo.

### Livrables

- Une homepage fictive unique pour **Northline**, composée des quatre snippets
  entre le header et le footer natifs d'Odoo.
- Un README court : objectif, motivation, fonctionnalités, composants,
  installation, usage, architecture, décisions, accessibilité et suites
  possibles.
- Des captures desktop, mobile, Website Builder, catégorie `Web Kit`, options
  du Hero et vue des quatre composants.
- Une vidéo de 60 à 90 secondes montrant le passage en mode édition, le drag &
  drop, la modification du contenu et le responsive.
- Un dépôt propre, partageable et doté d'un historique de commits lisible.

### Jalon final

Une personne doit pouvoir cloner le dépôt, installer le module dans Odoo 19,
trouver `Web Kit`, glisser le Hero, modifier son contenu et obtenir
immédiatement un résultat professionnel.

## Bonus, uniquement après le jalon final

Les bonus ne sont engagés que si les quatre blocs, le responsive, les options,
la QA et la documentation sont terminés.

Ordre recommandé :

1. Options Odoo supplémentaires à forte valeur d'usage.
2. Petit test automatisé ou tour web pertinent.
3. Micro-interaction CSS utile.
4. Mini-composant JavaScript/Owl, limité à deux heures et conservé uniquement
   s'il produit un résultat démontrable.

## Règles de maîtrise du périmètre

- Toute nouvelle idée doit améliorer clairement la démonstration et rester
  compatible avec le budget disponible.
- En cas de retard, supprimer dans cet ordre : Owl, JavaScript custom, options
  avancées, animations, formulaire complexe, puis le quatrième snippet en
  dernier recours.
- Ne jamais sacrifier l'intégration Website Builder, la fiabilité, le
  responsive, la propreté du dépôt, le README ou la démonstration.
- Ne pas ajouter de backend métier, base spécifique, API externe, application
  mobile, moteur de thèmes ou bibliothèque étendue de snippets.

## Definition of Done synthétique

Le projet est terminé lorsque :

- l'addon s'installe proprement dans Odoo 19 Community ;
- la catégorie `Web Kit` contient les quatre blocs attendus ;
- chaque bloc est glissable, éditable, déplaçable, duplicable et persistant ;
- le rendu est cohérent sur desktop, tablette et mobile ;
- le code reste isolé, namespacé et sans dépendance inutile ;
- les vérifications accessibilité, performance et installation fraîche ont été
  effectuées ;
- la homepage, le README, les captures et la courte vidéo rendent le projet
  compréhensible en moins de 90 secondes.
