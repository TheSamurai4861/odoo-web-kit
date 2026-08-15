# ODOO WEB KIT
## Plugin de blocs premium pour Odoo Website 19
### Cahier de lancement — candidature Odoo
### Version : 1.0 — 12 août 2026



# 0. RÉSUMÉ EXÉCUTIF

## Projet

**Nom de présentation :** Odoo Web Kit  
**Nom technique conseillé :** `website_webkit`

Odoo Web Kit est un addon pour Odoo 19 qui ajoute au Website Builder une petite
bibliothèque de blocs web modernes, configurables et réutilisables.

Le projet doit permettre à un utilisateur Odoo de :

1. ouvrir le Website Builder ;
2. trouver une catégorie dédiée `Web Kit` ;
3. glisser-déposer les nouveaux blocs ;
4. modifier directement textes, images et boutons ;
5. adapter leur apparence avec les outils Odoo ;
6. construire une page professionnelle sans écrire de code.

L'objectif n'est PAS de concurrencer le Website Builder.

L'objectif est de démontrer :

- compréhension de l'écosystème Odoo ;
- capacité à apprendre rapidement son framework ;
- web design ;
- HTML/XML/QWeb ;
- SCSS ;
- Bootstrap ;
- responsive design ;
- intégration dans un produit existant ;
- UX ;
- qualité du code ;
- capacité à transformer un besoin métier en produit concret.



## Choix stratégique du projet

### DÉCISION

Créer un **addon de snippets Website**, et non :

- une application externe ;
- un clone d'Odoo ;
- un thème complet ;
- un module ERP complexe ;
- un projet React déconnecté d'Odoo.

### VÉRIFICATION OPTIMISÉE

Odoo appelle ses blocs de construction Website des **building blocks/snippets**.
Ils constituent précisément le mécanisme utilisé par les utilisateurs pour
composer leurs pages dans le Website Builder.

Odoo fournit également un tutoriel officiel montrant comment ajouter des
snippets personnalisés au builder.

Références :

[R1]
https://www.odoo.com/documentation/19.0/developer/howtos/website_themes/building_blocks.html

[R2]
https://www.odoo.com/documentation/19.0/developer/tutorials/website_theme.html

[R3]
https://github.com/odoo/tutorials/tree/19.0/website_airproof

### SIMULATION

Scénario A — application React extérieure :
- belle techniquement ;
- faible lien avec le poste ;
- le recruteur doit comprendre pourquoi elle concerne Odoo.

Scénario B — thème Odoo complet :
- excellent lien avec Odoo ;
- beaucoup de fichiers ;
- beaucoup de temps consacré au header/footer/pages/presets ;
- risque élevé de ne rien finir parfaitement.

Scénario C — addon de snippets :
- très lié au Website Builder ;
- démontrable en 30 secondes ;
- périmètre contrôlable ;
- plusieurs compétences visibles simultanément.

=> **Scénario C retenu.**



# 1. OBJECTIF DU MVP

Le projet terminé doit contenir **4 blocs réellement utilisables**.

## Bloc 1 — Web Kit Hero

Hero moderne destiné à la conversion.

Contenu :

- badge facultatif ;
- H1 ;
- texte introductif ;
- CTA principal ;
- CTA secondaire ;
- visuel ;
- zone de confiance/mini-indicateur ;
- disposition desktop/mobile propre.

### VÉRIFICATION OPTIMISÉE

Le Hero doit utiliser au maximum :

- structure HTML sémantique ;
- classes Bootstrap/Odoo ;
- variables du thème ;
- éléments éditables par Odoo.

Éviter de créer une grille CSS complexe si Bootstrap répond déjà au besoin.

### SIMULATION

Si on crée une mise en page custom avec 150 lignes de CSS :

→ plus spectaculaire techniquement  
→ mais risque responsive important.

Si on repose principalement sur :

`container > row > col-lg-*`

→ comportement compatible avec l'écosystème existant  
→ moins de CSS  
→ maintenance plus simple.

**Choix : Bootstrap d'abord, SCSS spécifique ensuite.**



## Bloc 2 — Web Kit Features

Section destinée à présenter 3 à 6 avantages/services.

Contenu :

- titre ;
- description ;
- cartes ;
- icône ;
- titre de carte ;
- texte ;
- éventuellement lien.

### VÉRIFICATION OPTIMISÉE

Ne pas créer un système JavaScript pour ajouter/supprimer des cartes dans le MVP.

La priorité est :

- drag & drop ;
- modification du contenu ;
- rendu responsive ;
- cohérence visuelle.

### SIMULATION

Version complexe :

6 cartes + interface d'administration JS dédiée.

Temps potentiel :
4-6 h.

Version optimisée :

structure HTML/QWeb éditable + grille Bootstrap.

Temps estimé :
2-3 h.

Gain :
environ une demi-journée.

**Version optimisée retenue.**



## Bloc 3 — Web Kit Trust

Bloc de confiance / témoignage.

Contenu possible :

- citation ;
- photo/avatar ;
- nom ;
- fonction ;
- entreprise ;
- étoiles ou indicateur ;
- chiffres clés facultatifs.

Le composant doit surtout montrer une bonne maîtrise de la hiérarchie
visuelle.

### VÉRIFICATION OPTIMISÉE

Pas de carousel complexe pour le MVP.

Un témoignage ou trois cartes statiques sont suffisants pour démontrer le
Web Design.

### SIMULATION

Carousel :

+ interaction visible  
- gestion navigation  
- accessibilité supplémentaire  
- comportement mobile  
- bugs possibles  
- temps supplémentaire.

Bloc statique :

+ immédiatement éditable  
+ robuste  
+ plus rapide  
+ visuellement maîtrisable.

**Bloc statique retenu.**

Le carousel devient une amélioration éventuelle uniquement.



## Bloc 4 — Web Kit CTA / Lead

Bloc de fin de page orienté conversion.

Contenu :

- argument final ;
- texte ;
- CTA ;
- éventuellement formulaire Website standard ;
- réassurance.

### VÉRIFICATION OPTIMISÉE

Ne pas reconstruire le système de formulaires Odoo.

Odoo possède déjà le mécanisme Website Form.

Le plugin doit s'intégrer à cette logique plutôt que réinventer :

- validation ;
- soumission ;
- backend ;
- messages de réussite.

Référence officielle du formulaire :

[R4]
https://github.com/odoo/odoo/blob/19.0/addons/website/views/snippets/s_website_form.xml

### SIMULATION

Option A :
créer une API Python + contrôleur + modèle + formulaire JS.

Temps :
probablement 5-10 h minimum.

Risque :
élevé.

Option B :
réutiliser les capacités Website/Odoo existantes.

Temps :
1-3 h selon l'intégration.

Valeur métier :
identique ou supérieure.

**Option B retenue.**

Principe important :

> Un bon développeur intégré à un produit existant ne recrée pas ce que le
> produit sait déjà faire correctement.



# 2. FONCTIONNALITÉ BONUS

## Custom Snippet Options

Si le MVP est terminé, ajouter au Hero un panneau de personnalisation Odoo.

Exemples :

- alignement gauche / centré ;
- variante image gauche / droite ;
- style soft / contrasté ;
- espacement ;
- style des cartes.

### VÉRIFICATION OPTIMISÉE

Cette fonctionnalité est plus intéressante pour la candidature qu'une
animation JavaScript gratuite.

Pourquoi ?

Parce qu'elle démontre la compréhension réelle du fonctionnement du Website
Builder.

Le tutoriel officiel Odoo 19 utilise par exemple :

- `website.snippet_options` ;
- `data-selector` ;
- `we-button-group` ;
- `we-button` ;
- `we-range`.

Référence exacte :

[R5]
https://github.com/odoo/tutorials/blob/19.0/website_airproof/views/snippets/s_airproof_carousel.xml

### SIMULATION

Bonus A — animation spectaculaire JS :

Impact visuel : 9/10  
Pertinence Odoo : 5/10  
Risque : 5/10

Bonus B — options natives Website Builder :

Impact visuel : 7/10  
Pertinence Odoo : 10/10  
Risque : 3/10

**Bonus B prioritaire.**



# 3. CE QU'IL NE FAUT PAS FAIRE

Pendant cette semaine, ne PAS développer :

- système de comptes ;
- nouveau backend complet ;
- base de données spécifique ;
- dashboard ;
- application mobile ;
- système AI ;
- API externe ;
- eCommerce complet ;
- moteur de thèmes ;
- bibliothèque de 15 snippets ;
- authentification ;
- déploiement complexe ;
- animations 3D ;
- réécriture du Website Builder.

### VÉRIFICATION OPTIMISÉE

Chaque nouvelle fonctionnalité doit répondre à la question :

> Est-ce qu'elle augmente significativement la qualité de ma démonstration
> auprès d'un recruteur Web Designer Odoo ?

Si la réponse est non :

**ne pas la faire.**

### SIMULATION

Projet 4 blocs à 95 % de finition :

→ paraît professionnel.

Projet 12 blocs à 50 % :

→ paraît expérimental/inachevé.

Pour une candidature :

**finition > quantité.**



# 4. STACK TECHNIQUE

## Odoo

**Version cible : Odoo 19 Community**

### VÉRIFICATION OPTIMISÉE

Utiliser la branche `19.0`.

Ne pas développer volontairement sur Odoo 18 pour ensuite migrer.

Référence :

[R6]
https://github.com/odoo/odoo/tree/19.0

### SIMULATION

Développement Odoo 18 :

→ apprentissage  
→ développement  
→ migration éventuelle.

Développement Odoo 19 directement :

→ apprentissage  
→ développement.

Une étape supprimée.



## Python

Odoo 19 demande Python >= 3.10.

### Choix conseillé pour ton environnement

**Python 3.12**

Ce n'est pas une exigence absolue d'Odoo 19 mais un choix conservateur pour
ce projet.

Le fichier `requirements.txt` officiel Odoo 19 contient explicitement des
dépendances adaptées à Python 3.12 et versions suivantes.

Références :

[R7]
https://www.odoo.com/documentation/19.0/administration/on_premise/source.html

[R8]
https://github.com/odoo/odoo/blob/19.0/requirements.txt

### VÉRIFICATION OPTIMISÉE

Avant toute installation :

~~~powershell
python --version
~~~

Objectif :

~~~text
Python 3.12.x
~~~

### SIMULATION

Si Python installé = 3.12 :

→ continuer.

Si Python installé = autre version supportée et que l'installation fonctionne :

→ ne pas perdre du temps à changer inutilement.

Si compilation de dépendances échoue :

→ utiliser Python 3.12 avant de chercher des corrections complexes.



# 5. BASE DE DONNÉES

Odoo utilise PostgreSQL.

Odoo 19 exige au minimum :

**PostgreSQL 13.**

### VÉRIFICATION OPTIMISÉE

Commande :

~~~powershell
psql --version
~~~

Puis vérifier que le serveur tourne.

Référence :

[R7]
https://www.odoo.com/documentation/19.0/administration/on_premise/source.html

### SIMULATION

PostgreSQL >= 13 :

→ OK.

PostgreSQL absent :

→ installer PostgreSQL.

PostgreSQL trop ancien :

→ mise à niveau.

Ne jamais passer plusieurs heures à diagnostiquer Odoo avant d'avoir vérifié
ce prérequis.



# 6. MÉTHODE D'INSTALLATION D'ODOO

## Choix : installation depuis les sources

Odoo indique que pour les développeurs de la communauté ainsi que ses propres
développeurs, la méthode privilégiée est l'exécution depuis les sources.

Référence :

[R9]
https://www.odoo.com/documentation/19.0/developer/tutorials/setup_guide.html

### Pourquoi c'est optimal ici

Tu vas :

- écrire un module ;
- lire le code source d'Odoo ;
- comparer tes snippets avec les leurs ;
- consulter les fichiers Website ;
- relancer régulièrement Odoo.

L'accès au repository complet est donc utile.

### SIMULATION

Installer seulement une version packagée :

+ rapide à lancer  
- code source moins directement intégré au workflow.

Installer depuis les sources :

+ environnement proche du développement Odoo  
+ sources disponibles immédiatement  
+ plus pédagogique  
- installation légèrement plus longue.

Pour une candidature de développeur/web designer :

**sources retenues.**



# 7. INSTALLATION — WINDOWS

## Étape 1 — préparer le dossier

Exemple :

~~~text
C:\
└── dev\
    ├── odoo\
    └── odoo-custom-addons\
~~~

### VÉRIFICATION OPTIMISÉE

Séparer :

- code source officiel ;
- ton propre code.

Ne mets pas directement ton addon dans :

`odoo/addons`

### SIMULATION

Addon dans `odoo/addons` :

→ fonctionne  
→ mélange ton travail au repository officiel  
→ Git plus sale.

Addon dans `odoo-custom-addons` :

→ repository indépendant  
→ README indépendant  
→ facilement partageable au recruteur.

**Deux dossiers retenus.**



## Étape 2 — cloner Odoo

~~~powershell
cd C:\dev

git clone --depth 1 --branch 19.0 https://github.com/odoo/odoo.git
~~~

### VÉRIFICATION OPTIMISÉE

`--branch 19.0`

évite de récupérer une autre version.

`--depth 1`

réduit fortement l'historique Git téléchargé puisque tu n'as pas besoin de
toute l'histoire du projet pour ce challenge.

### SIMULATION

Clone Git complet :

→ beaucoup plus de données.

Clone shallow :

→ code nécessaire uniquement.

**Shallow clone retenu.**



## Étape 3 — environnement virtuel

~~~powershell
cd C:\dev\odoo

python -m venv .venv

.\.venv\Scripts\Activate.ps1
~~~

Puis :

~~~powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
~~~

### VÉRIFICATION OPTIMISÉE

Toujours vérifier que le terminal affiche l'environnement virtuel avant
d'installer les dépendances.

### SIMULATION

Installation globale :

→ packages mélangés avec d'autres projets.

Virtualenv :

→ dépendances isolées.

**Virtualenv obligatoire.**



## Étape 4 — éventuelles dépendances Windows

La documentation Odoo mentionne des dépendances de compilation Windows et
notamment le support C++ de Visual Studio pour certaines installations.

Référence :

[R7]
https://www.odoo.com/documentation/19.0/administration/on_premise/source.html

### VÉRIFICATION OPTIMISÉE

Ne pas installer 15 outils préventivement.

Procédure :

1. lancer `pip install -r requirements.txt` ;
2. observer ;
3. si une dépendance demande compilation/C++, installer les Build Tools
   nécessaires.

### SIMULATION

Préinstaller un environnement gigantesque :

→ temps perdu.

Installer uniquement lorsqu'une dépendance le requiert :

→ environnement minimal.



# 8. PREMIER LANCEMENT ODOO

Créer par exemple le dossier :

~~~text
C:\dev\odoo-custom-addons
~~~

Lancer :

~~~powershell
cd C:\dev\odoo
.\.venv\Scripts\Activate.ps1

python odoo-bin ^
  --addons-path=addons,C:\dev\odoo-custom-addons ^
  -d webkit_dev
~~~

Selon ta configuration PostgreSQL, il pourra être nécessaire d'ajouter les
paramètres utilisateur/mot de passe DB.

### VÉRIFICATION OPTIMISÉE

Le test de réussite n'est pas :

> "Le terminal ne montre pas d'erreur."

Le test est :

1. `http://localhost:8069` s'ouvre ;
2. la base `webkit_dev` existe ;
3. le backend fonctionne ;
4. Website peut être installé ;
5. une page Website peut être éditée.

### SIMULATION

Si Odoo démarre mais Website ne fonctionne pas :

→ environnement non validé.

Si Homepage + Edit fonctionnent :

→ environnement validé.

Ne commencer le plugin qu'après cela.



# 9. MODE DÉVELOPPEUR ODOO

Activer le Developer Mode.

Pour le debug frontend, Odoo possède également un mode avec assets.

Référence :

[R10]
https://www.odoo.com/documentation/19.0/applications/general/developer_mode.html

### VÉRIFICATION OPTIMISÉE

Pendant le développement frontend :

- utiliser le mode assets/debug quand nécessaire ;
- recharger proprement les assets ;
- vérifier console navigateur ;
- vérifier logs Odoo.

### SIMULATION

CSS modifié mais navigateur montre encore ancienne version :

avant de modifier encore le SCSS :

1. vérifier cache/assets ;
2. vérifier que le fichier est dans le bundle ;
3. vérifier que le module a été mis à jour.

Cela évite de "réparer" du code qui était déjà correct.



# 10. CRÉATION DU REPOSITORY

Créer :

~~~text
odoo-web-kit/
└── website_webkit/
~~~

Structure proposée :

~~~text
odoo-web-kit/
│
├── README.md
├── LICENSE
├── screenshots/
│
└── website_webkit/
    ├── __init__.py
    ├── __manifest__.py
    │
    ├── views/
    │   └── snippets/
    │       ├── options.xml
    │       ├── s_webkit_hero.xml
    │       ├── s_webkit_features.xml
    │       ├── s_webkit_trust.xml
    │       └── s_webkit_cta.xml
    │
    └── static/
        └── src/
            ├── img/
            │   ├── wbuilder/
            │   └── demo/
            │
            ├── scss/
            │   ├── webkit.scss
            │   ├── _hero.scss
            │   ├── _features.scss
            │   ├── _trust.scss
            │   └── _cta.scss
            │
            └── js/
                └── webkit.js
~~~

### VÉRIFICATION OPTIMISÉE

Le dossier `js/` peut rester vide ou ne pas exister tant que JavaScript
n'apporte rien.

Pas de JavaScript "pour montrer qu'on sait faire du JavaScript".

### SIMULATION

Architecture complexe dès le départ :

15 dossiers vides.

→ impression d'architecture prématurée.

Architecture progressive :

ajouter les dossiers lorsqu'ils deviennent utiles.

→ repository plus clair.



# 11. MANIFEST ODOO

Chaque module Odoo possède un fichier :

`__manifest__.py`

Le manifest définit notamment :

- nom ;
- version ;
- dépendances ;
- données ;
- assets ;
- licence ;
- caractère application/module.

Référence :

[R11]
https://www.odoo.com/documentation/19.0/developer/reference/backend/module.html

## Base proposée

~~~python
{
    "name": "Web Kit",
    "summary": "Premium configurable building blocks for Odoo Website",
    "version": "19.0.1.0.0",
    "category": "Website",
    "author": "Mattéo Vanderheyden",
    "license": "LGPL-3",
    "depends": [
        "website",
    ],
    "data": [
        "views/snippets/options.xml",
        "views/snippets/s_webkit_hero.xml",
        "views/snippets/s_webkit_features.xml",
        "views/snippets/s_webkit_trust.xml",
        "views/snippets/s_webkit_cta.xml",
    ],
    "assets": {
        "web.assets_frontend": [
            "website_webkit/static/src/scss/**/*.scss",
        ],
    },
    "application": False,
    "installable": True,
}
~~~

### VÉRIFICATION OPTIMISÉE

`application: False`

est logique :

ce projet ne constitue pas un ERP/app autonome.

Il étend Website.

`depends: ["website"]`

permet de limiter les dépendances.

### SIMULATION

Ajouter CRM, Sales, eCommerce, Blog et Marketing comme dépendances "au cas où" :

→ installation plus lourde  
→ dépendances inutiles  
→ bugs potentiels supplémentaires.

Dépendance `website` uniquement pour le MVP :

→ addon plus isolé et clair.



# 12. ASSETS

Odoo gère CSS/SCSS/JS/XML avec des bundles d'assets.

Le bundle public Website principal est :

`web.assets_frontend`

Référence :

[R12]
https://www.odoo.com/documentation/19.0/developer/reference/frontend/assets.html

### VÉRIFICATION OPTIMISÉE

Le CSS destiné uniquement au site public doit aller dans le bundle frontend,
pas dans les assets backend.

### SIMULATION

Charger ton SCSS partout :

→ backend alourdi inutilement.

Charger uniquement dans `web.assets_frontend` :

→ meilleur découpage.



# 13. AJOUTER UNE CATÉGORIE "WEB KIT"

Le tutoriel officiel Airproof fournit un exemple Odoo 19 directement
réutilisable comme référence de structure.

Principe :

~~~xml
<template
    id="snippets"
    inherit_id="website.snippets"
    name="Web Kit - Custom Snippets"
>

    <!-- catégorie Web Kit -->
    <!-- snippets Web Kit -->

</template>
~~~

Exemple officiel complet :

[R13]
https://github.com/odoo/tutorials/blob/19.0/website_airproof/views/snippets/options.xml

### VÉRIFICATION OPTIMISÉE

Ne pas inventer la syntaxe du registre de snippets de mémoire.

Copier la structure conceptuelle du tutoriel **19.0 officiel**, puis adapter :

`airproof`

en :

`webkit`

### SIMULATION

Tutoriel random Odoo 15 trouvé sur Internet :

→ syntaxe potentiellement obsolète.

Tutoriel Odoo officiel branch 19.0 :

→ meilleure compatibilité.

**Source officielle 19.0 toujours prioritaire.**



# 14. STRUCTURE D'UN SNIPPET

Exemple conceptuel :

~~~xml
<?xml version="1.0" encoding="utf-8"?>

<odoo>

    <template id="s_webkit_hero" name="Web Kit Hero">

        <section class="s_webkit_hero pt96 pb96">

            <div class="container">

                <div class="row align-items-center">

                    <div class="col-lg-6">
                        <h1>Build better experiences.</h1>

                        <p class="lead">
                            A clean and flexible hero section built for Odoo.
                        </p>

                        <a href="#" class="btn btn-primary btn-lg">
                            Get started
                        </a>
                    </div>

                    <div class="col-lg-6">
                        <!-- Image -->
                    </div>

                </div>

            </div>

        </section>

    </template>

</odoo>
~~~

### VÉRIFICATION OPTIMISÉE

Le code officiel Odoo utilise également :

- `<section>` ;
- `.container` ;
- `.row` ;
- colonnes Bootstrap ;
- classes Odoo/Bootstrap.

Référence :

[R14]
https://github.com/odoo/tutorials/blob/19.0/website_airproof/views/snippets/s_airproof_carousel.xml

### SIMULATION

HTML totalement custom :

→ davantage de CSS.

HTML compatible Bootstrap/Odoo :

→ davantage de comportements natifs gratuitement.



# 15. SCSS

Le projet utilise SCSS pour :

- identité visuelle ;
- effets spécifiques ;
- cartes ;
- gradients ;
- bordures ;
- espaces particuliers ;
- micro-interactions.

Mais pas pour recréer :

- grille ;
- display flex ;
- responsive de base ;
- boutons standards ;
- système complet de spacing.

### VÉRIFICATION OPTIMISÉE

Règle :

**Odoo/Bootstrap d'abord → SCSS ensuite.**

Odoo 19 utilise Bootstrap 5.3 dans le contexte de son tutoriel de thème.

Référence :

[R2]
https://www.odoo.com/documentation/19.0/developer/tutorials/website_theme.html

### SIMULATION

CSS custom :

~~~scss
display: grid;
grid-template-columns: repeat(2, 1fr);
gap: ...;
@media (...);
~~~

versus :

~~~html
<div class="row g-4">
    <div class="col-md-6">...</div>
</div>
~~~

Si les deux résultats sont équivalents :

**prendre Bootstrap.**



# 16. CONVENTION CSS

Préfixer toutes les classes spécifiques :

~~~text
s_webkit_
webkit_
~~~

Exemples :

~~~text
s_webkit_hero
s_webkit_features
s_webkit_trust
s_webkit_cta

webkit_card
webkit_badge
webkit_visual
~~~

### VÉRIFICATION OPTIMISÉE

Éviter :

~~~css
.card {}
.hero {}
.title {}
.button {}
~~~

Ces sélecteurs sont trop génériques.

### SIMULATION

`.card`

peut modifier des dizaines de composants Odoo.

`.s_webkit_features .webkit_card`

ne concerne que ton addon.

**Namespace strict retenu.**



# 17. DESIGN SYSTEM

Créer volontairement une identité sobre.

## Direction visuelle

- moderne ;
- SaaS ;
- professionnelle ;
- légèrement premium ;
- pas futuriste ;
- pas de glassmorphism excessif ;
- pas d'effets "Dribbble pour Dribbble".

## Variables conceptuelles

- Primary
- Secondary
- Surface
- Text
- Muted
- Border
- Radius
- Shadow
- Spacing

### VÉRIFICATION OPTIMISÉE

Éviter autant que possible de hardcoder des dizaines de couleurs indépendantes.

Le Website Builder possède déjà des options de thème permettant notamment de
personnaliser couleurs, polices, boutons et autres éléments.

Référence :

[R15]
https://www.odoo.com/documentation/19.0/applications/websites/website/web_design/themes.html

### SIMULATION

20 couleurs hexadécimales spécifiques :

→ thème difficilement adaptable.

Utilisation des couleurs/styles existants + quelques éléments spécifiques :

→ composant compatible avec différents websites.



# 18. RESPONSIVE DESIGN

Chaque composant est développé dans cet ordre :

1. desktop ;
2. tablette ;
3. mobile ;
4. retest desktop.

Ta priorité absolue reste le rendu mobile.

## Largeurs de test manuelles

Tester au minimum autour de :

- 1440 px ;
- 1024 px ;
- 768 px ;
- 390 px ;
- 360 px.

Ces valeurs sont des **dimensions de test**, pas des breakpoints CSS à
hardcoder automatiquement.

### VÉRIFICATION OPTIMISÉE

Tester notamment :

- débordement horizontal ;
- titres ;
- images ;
- CTA ;
- colonnes ;
- espacement ;
- boutons ;
- zones cliquables.

### SIMULATION

Hero desktop :

texte | image.

Hero mobile :

texte
↓
CTA
↓
image

Si l'image apparaît avant le message principal ou prend 90 % de la hauteur :

→ revoir ordre/taille.



# 19. ACCESSIBILITÉ

Objectif raisonnable :

**WCAG 2.2 AA lorsque applicable.**

Vérifier :

- HTML sémantique ;
- hiérarchie H1/H2/H3 ;
- texte alternatif des images pertinentes ;
- boutons/liens correctement identifiés ;
- focus clavier ;
- contraste ;
- navigation clavier ;
- pas d'information transmise uniquement par couleur.

Référence :

[R16]
https://www.w3.org/WAI/WCAG22/quickref/

### VÉRIFICATION OPTIMISÉE

Test manuel :

1. ne pas utiliser la souris ;
2. appuyer sur TAB ;
3. parcourir tous les contrôles ;
4. vérifier que le focus reste identifiable.

### SIMULATION

Bouton visuellement magnifique mais focus invisible :

→ mauvais composant.

Bouton légèrement plus simple mais clavier parfaitement exploitable :

→ meilleur design produit.



# 20. PERFORMANCE

Pas de budget extrême nécessaire pour une candidature, mais garder :

- images raisonnables ;
- JS minimal ;
- pas de librairie externe pour une animation triviale ;
- CSS limité ;
- pas de grosse vidéo autoplay ;
- pas de polices supplémentaires inutiles.

### VÉRIFICATION OPTIMISÉE

Lancer Lighthouse après finalisation.

Lighthouse peut auditer :

- performance ;
- accessibilité ;
- SEO ;
- bonnes pratiques.

Référence :

[R17]
https://developer.chrome.com/docs/lighthouse/overview

### SIMULATION

Ajouter une bibliothèque JS de 150 kB pour un hover :

→ très mauvais rapport valeur/coût.

10 lignes CSS :

→ meilleur choix.



# 21. JAVASCRIPT

## MVP

**Aucun JavaScript custom obligatoire.**

C'est volontaire.

### VÉRIFICATION OPTIMISÉE

Ajouter du JS uniquement lorsqu'un comportement :

1. ne peut pas être réalisé avec Odoo/Bootstrap/CSS ;
2. améliore réellement le composant.

Odoo 19 prend en charge ses modules JavaScript et utilise Owl pour ses
composants frontend.

Références :

[R18]
https://www.odoo.com/documentation/19.0/developer/reference/frontend/javascript_modules.html

[R19]
https://www.odoo.com/documentation/19.0/developer/reference/frontend/owl_components.html

### SIMULATION

Feature nécessitant 4 h d'Owl pendant que deux composants sont cassés :

→ Owl supprimé.

Projet parfaitement fini sans Owl :

→ candidature toujours forte.

Projet incomplet avec Owl :

→ mauvais compromis.



# 22. OWL — STRETCH GOAL

Owl est le framework de composants utilisé dans le frontend Odoo.

Il est inspiré conceptuellement de frameworks déclaratifs comme React/Vue.

Mais :

**Owl n'est pas obligatoire pour ce projet.**

### Quand l'utiliser ?

Uniquement si samedi :

- 4 snippets fonctionnent ;
- mobile validé ;
- options fonctionnent ;
- pas de bug important.

Alors développer éventuellement un mini composant interactif.

### VÉRIFICATION OPTIMISÉE

Timebox :

**maximum 2 heures.**

Au bout de 2 h sans résultat démontrable :

**abandonner le bonus.**

### SIMULATION

Samedi 15:00 :
MVP terminé.

→ essayer Owl.

Samedi 17:00 :
fonctionnel.

→ conserver.

Samedi 17:00 :
toujours erreurs framework/assets.

→ supprimer branche bonus.

Aucune hésitation.



# 23. WORKFLOW GIT

Branches simples :

~~~text
main
develop
feature/hero
feature/features
feature/trust
feature/cta
~~~

Mais pour un projet solo de quatre jours, tu peux même simplifier :

~~~text
main
feature/*
~~~

### VÉRIFICATION OPTIMISÉE

Ne crée pas une architecture Git d'entreprise artificielle pour un projet
individuel de quatre jours.

Commit régulièrement.

Exemples :

~~~text
feat: add Web Kit snippet category
feat: add responsive hero snippet
feat: add feature cards snippet
feat: add trust block
feat: add CTA block
feat: add hero customization options
fix: improve hero mobile spacing
docs: add installation instructions
~~~

### SIMULATION

1 commit :

`final project`

→ impossible de voir ta progression.

8-15 commits propres :

→ progression et méthode visibles.



# 24. PREMIER TEST TECHNIQUE

Avant de dessiner le Hero complet :

créer un bloc minimal :

~~~text
WEB KIT TEST
~~~

et vérifier qu'il apparaît réellement dans le Website Builder.

### VÉRIFICATION OPTIMISÉE

Ordre recommandé :

1. manifest ;
2. snippet minimal ;
3. catégorie ;
4. installation ;
5. drag & drop ;
6. seulement ensuite design.

### SIMULATION

Construire le Hero complet avant installation :

3 h de code.

Puis découvrir que :

- manifest incorrect ;
- snippet non enregistré ;
- XML mal chargé.

Mauvaise stratégie.

Faire un "Hello Web Kit" en premier :

30 min.

Puis construire dessus.

**Approche verticale retenue.**



# 25. TEST D'INSTALLATION DU MODULE

Procédure :

1. démarrer Odoo ;
2. actualiser la liste des apps ;
3. trouver Web Kit ;
4. installer ;
5. ouvrir Website ;
6. Edit ;
7. trouver catégorie Web Kit ;
8. glisser un bloc ;
9. sauvegarder ;
10. recharger.

### VÉRIFICATION OPTIMISÉE

Le test final doit aussi inclure :

**désinstaller puis réinstaller le module dans une base propre.**

### SIMULATION

Le plugin fonctionne uniquement dans ta DB après 30 manipulations manuelles :

→ mauvais livrable.

Installation fraîche :

→ fonctionne immédiatement.

C'est ce deuxième scénario que le repository doit garantir.



# 26. TEST DE MODIFICATION

Pour CHAQUE snippet :

- modifier titre ;
- modifier paragraphe ;
- modifier lien ;
- changer image si présente ;
- déplacer bloc ;
- dupliquer ;
- sauvegarder ;
- recharger.

### VÉRIFICATION OPTIMISÉE

Un snippet beau mais non éditable correctement n'est pas réussi.

### SIMULATION

Recruteur :

drag & drop → change un titre → layout explose.

Résultat :
très mauvais.

Recruteur :

drag & drop → change tout immédiatement.

Résultat :
le plugin paraît natif.



# 27. TESTS AUTOMATISÉS

Odoo possède :

- tests Python ;
- tests JavaScript ;
- tours web.

Référence :

[R20]
https://www.odoo.com/documentation/19.0/developer/reference/backend/testing.html

### Choix MVP

Ne pas passer une journée à développer une suite complète de tests.

Au minimum :

- installation propre ;
- XML chargé ;
- pages fonctionnelles ;
- tests manuels rigoureux.

Si temps disponible :

ajouter un petit tour/test pertinent.

### VÉRIFICATION OPTIMISÉE

Tests automatiques seulement après les quatre snippets.

### SIMULATION

3 h de tests automatisés pour un seul Hero :

→ techniquement propre mais mauvais portfolio.

3 h pour finir responsive + QA des 4 composants :

→ plus pertinent dans ce contexte.



# 28. SIMULATION DE PRIORISATION DES FONCTIONNALITÉS

Évaluation heuristique :

| Fonction | Impact candidature | Pertinence Odoo | Risque | Temps |
||:|:|:|:|
| Hero configurable | 9/10 | 8/10 | 2/10 | ~3 h |
| Features | 7/10 | 7/10 | 1/10 | ~2,5 h |
| Trust | 6/10 | 6/10 | 1/10 | ~2 h |
| CTA | 9/10 | 9/10 | 3/10 | ~3,5 h |
| Before/After JS | 7/10 | 5/10 | 5/10 | ~4 h |
| Owl dynamique | 8/10 | 10/10 | 7/10 | ~6 h |
| Thème complet | 9/10 | 10/10 | 9/10 | ~14 h+ |

### Conclusion simulation

Les quatre premiers composants maximisent le ratio :

**valeur visible / temps / risque.**

Owl peut produire énormément de valeur mais uniquement lorsque le MVP est
sécurisé.



# 29. BUDGET TEMPS

Budget cible total :

**environ 25-28 heures maximum.**

Répartition :

| Partie | Budget |
||:|
| environnement Odoo | 2 h |
| compréhension snippets | 1 h |
| architecture addon | 1 h |
| Hero | 3 h |
| Features | 2,5 h |
| Trust | 2 h |
| CTA | 3,5 h |
| options Odoo | 2 h |
| responsive global | 3 h |
| QA/accessibilité | 2 h |
| page démo | 1,5 h |
| README | 1,5 h |
| vidéo/screenshots | 1,5 h |
| buffer bugs | 2,5 h |

Total cible :
~27,5 h.

### VÉRIFICATION OPTIMISÉE

Chaque tâche possède un timebox.

Si elle dépasse fortement :

**réduire le scope, pas repousser tout le planning.**



# 30. PLANNING — JEUDI 13 AOÛT 2026

## Objectif

**Faire fonctionner la chaîne Odoo complète.**

### Matin

- installer/vérifier Python ;
- installer/vérifier PostgreSQL ;
- cloner Odoo 19 ;
- virtualenv ;
- requirements ;
- démarrer Odoo ;
- installer Website.

### Fin de matinée

Créer :

`website_webkit`

avec :

- manifest ;
- init ;
- options XML ;
- snippet "Hello Web Kit".

### Après-midi

Faire apparaître :

**Web Kit**

dans le Website Builder.

Puis commencer le Hero.

### Condition de réussite de jeudi

Avant de terminer :

- Odoo fonctionne ;
- addon installé ;
- catégorie présente ;
- Hero peut être glissé dans une page.

### SIMULATION D'ÉCHEC

15:00 :
l'environnement n'est toujours pas opérationnel.

Action :

**ne pas développer de design.**

Finir l'environnement.

18:00 :
Odoo fonctionne enfin.

Action :

faire seulement le Hero minimal.

Le reste est reporté sans casser le projet.



# 31. PLANNING — VENDREDI 14 AOÛT

## Objectif

**MVP fonctionnel.**

Matin :

- terminer Hero ;
- Features.

Après-midi :

- Trust ;
- CTA.

Fin journée :

- test des quatre blocs ;
- Git propre.

### Condition de réussite

Les quatre blocs peuvent être :

- ajoutés ;
- édités ;
- sauvegardés ;
- rechargés.

Ils ne doivent pas encore être parfaits.

### SIMULATION

Si vendredi 16:00 CTA n'est pas terminé :

→ simplifier CTA.

Ne pas sacrifier les trois autres composants pour une intégration complexe.



# 32. PLANNING — SAMEDI 15 AOÛT

## Objectif

**Transformer un prototype en produit.**

Priorités :

1. responsive ;
2. spacing ;
3. typographie ;
4. couleurs ;
5. options Web Builder ;
6. accessibilité ;
7. bugs.

Ensuite seulement :

8. JavaScript/Owl bonus.

### Condition de réussite

À la fin de samedi, le projet doit pouvoir être montré à un recruteur sans
explication préalable.

### SIMULATION

Si samedi 14:00 le design est encore moyen :

→ abandonner Owl.

Si samedi 14:00 tout est impeccable :

→ essayer bonus Owl/options avancées.



# 33. PLANNING — DIMANCHE 16 AOÛT

## Objectif

**Candidature-ready.**

Matin :

- installation fraîche ;
- tests ;
- Lighthouse ;
- corrections ;
- screenshots.

Après-midi :

- README ;
- page de présentation ;
- vidéo démo ;
- repository public ;
- candidature.

### RÈGLE

**Aucune nouvelle feature dimanche.**

### SIMULATION

Idée brillante dimanche matin :

"Je pourrais ajouter un générateur IA."

Réponse :

**NON.**

Finaliser ce qui existe.



# 34. PAGE DÉMONSTRATEUR

Construire une seule homepage fictive utilisant exclusivement tes blocs.

## Client fictif proposé

### NORTHLINE

Petite société B2B belge fictive proposant des solutions digitales aux PME.

Pourquoi fictif ?

Parce que tu contrôles :

- branding ;
- images ;
- contenu ;
- CTA ;
- témoignages ;
- structure.

Homepage :

~~~text
HEADER ODOO
      ↓
WEB KIT HERO
      ↓
WEB KIT FEATURES
      ↓
WEB KIT TRUST
      ↓
WEB KIT CTA
      ↓
FOOTER ODOO
~~~

### VÉRIFICATION OPTIMISÉE

Une seule page parfaitement conçue vaut mieux que cinq pages moyennes.

### SIMULATION

Démo 5 pages :

le recruteur navigue et cherche ce qu'il doit regarder.

Démo 1 homepage :

il voit immédiatement les 4 composants.

**Une homepage retenue.**



# 35. CONTENU DE DÉMONSTRATION

Éviter Lorem Ipsum.

Exemple :

## Hero

Badge :

`Built for growing teams`

Titre :

`Your operations deserve a better digital experience.`

Texte :

`Northline helps growing businesses simplify their digital workflows and
turn complex processes into clear experiences.`

CTA :

`Start a project`

Secondaire :

`Discover our services`



## Features

### Design
Interfaces built around real business objectives.

### Integration
Connected workflows instead of isolated tools.

### Growth
Digital foundations designed to evolve with your company.



## Trust

> "Northline transformed a fragmented workflow into one clear experience."

— Sophie Lambert  
Operations Director



## CTA

`Ready to simplify the way your business works?`

Bouton :

`Let's talk`



# 36. POURQUOI UNE PME FICTIVE ?

### VÉRIFICATION OPTIMISÉE

Odoo cible fortement les entreprises ayant de nombreux besoins métiers
intégrés.

Une PME fictive permet de montrer que ton design n'est pas simplement une
landing page artistique mais un outil commercial.

### SIMULATION

Portfolio d'artiste fictif :

→ montre le design.

PME B2B :

→ montre design + compréhension business.

Pour Odoo :

**PME B2B légèrement préférable.**



# 37. README GITHUB

Structure :

~~~markdown
# Web Kit for Odoo 19

A collection of configurable website building blocks created as an
exploration of the Odoo Website ecosystem.

## Why I built this

## Features

## Components

### Hero
### Features
### Trust
### CTA

## Installation

## Usage

## Architecture

## Design decisions

## Technical decisions

## Accessibility

## Screenshots

## What I learned

## Possible next steps
~~~

### VÉRIFICATION OPTIMISÉE

Le README ne doit pas être un roman.

Un recruteur doit comprendre en 30-60 secondes :

- pourquoi ;
- quoi ;
- comment ;
- résultat.

### SIMULATION

README commençant par 40 lignes d'installation PostgreSQL :

→ intérêt perdu.

README :

image
→ objectif
→ résultat
→ composants
→ installation.

**Deuxième structure retenue.**



# 38. README — SECTION "WHY"

Exemple conceptuel :

> I built Web Kit while preparing my application to Odoo.
>
> Instead of creating another standalone portfolio project, I wanted to
> understand how Odoo Website actually works and build directly inside its
> ecosystem.
>
> The challenge was to learn enough of Odoo 19's website architecture to
> design, develop and integrate reusable building blocks within a few days.

### VÉRIFICATION OPTIMISÉE

Cette section est très importante.

Elle transforme le projet :

de :

"petit plugin"

en :

"preuve d'initiative et d'apprentissage".



# 39. SCREENSHOTS

Créer au minimum :

1. Homepage finale desktop.
2. Homepage mobile.
3. Website Builder ouvert.
4. Catégorie Web Kit.
5. Hero sélectionné avec ses options.
6. Vue des quatre composants.

### VÉRIFICATION OPTIMISÉE

Le screenshot le plus important n'est PAS la homepage.

C'est :

**le composant dans le Website Builder.**

Il prouve qu'il s'agit réellement d'une extension Odoo.

### SIMULATION

Screenshot homepage seule :

"Peut-être juste du HTML."

Screenshot Website Builder + catégorie Web Kit :

"Il a réellement intégré Odoo."



# 40. VIDÉO DE DÉMONSTRATION

Durée optimale visée :

**60 à 90 secondes.**

Storyboard :

### 0-10 sec

Homepage terminée.

### 10-20 sec

Passage en mode Edit.

### 20-35 sec

Ouverture de la catégorie Web Kit.

### 35-50 sec

Drag & drop Hero.

### 50-65 sec

Modification titre/style.

### 65-80 sec

Vue responsive/mobile.

### 80-90 sec

GitHub / logo du projet.

### VÉRIFICATION OPTIMISÉE

Pas de vidéo de 12 minutes.

Le recruteur ne doit pas devoir "apprendre le projet".

### SIMULATION

12 minutes :

probabilité importante qu'il ne regarde qu'une petite partie.

75 secondes :

facile à visionner entièrement.



# 41. TEST ACCESSIBILITÉ FINAL

Checklist :

- [ ] Un seul H1 principal sur la page démo.
- [ ] Sections suivantes utilisent H2.
- [ ] Images informatives ont un alt.
- [ ] Images décoratives ne polluent pas l'accessibilité.
- [ ] Tous les liens fonctionnent.
- [ ] Focus visible.
- [ ] Navigation TAB possible.
- [ ] Contraste correct.
- [ ] Aucun texte essentiel intégré dans une image.
- [ ] CTA compréhensibles hors contexte.
- [ ] Responsive zoom 200 % raisonnable.

### VÉRIFICATION OPTIMISÉE

Combiner :

- Lighthouse ;
- navigation clavier ;
- inspection visuelle.

Aucun outil automatisé ne remplace totalement le contrôle manuel.



# 42. TEST RESPONSIVE FINAL

Pour chaque bloc :

## Hero

- [ ] Pas de texte coupé.
- [ ] Image ne déborde pas.
- [ ] CTA restent accessibles.
- [ ] H1 n'occupe pas tout l'écran.

## Features

- [ ] Cartes passent correctement en colonnes.
- [ ] Hauteurs visuelles cohérentes.
- [ ] Texte lisible.

## Trust

- [ ] Avatar adapté.
- [ ] Citation lisible.
- [ ] Pas de layout écrasé.

## CTA

- [ ] Bouton suffisamment large.
- [ ] Padding mobile adapté.
- [ ] Formulaire éventuel utilisable.

### VÉRIFICATION OPTIMISÉE

Après chaque correction mobile :

**retester desktop.**

Un fix local peut créer une régression.



# 43. TEST ODOO FINAL

- [ ] Module visible dans Apps.
- [ ] Installation sans erreur.
- [ ] Désinstallation possible.
- [ ] Réinstallation possible.
- [ ] Category Web Kit présente.
- [ ] Hero drag & drop.
- [ ] Features drag & drop.
- [ ] Trust drag & drop.
- [ ] CTA drag & drop.
- [ ] Textes éditables.
- [ ] Images éditables.
- [ ] Sauvegarde.
- [ ] Reload.
- [ ] Duplication des blocs.
- [ ] Déplacement.
- [ ] Pas d'erreurs JS.
- [ ] Pas d'erreurs importantes logs serveur.



# 44. TEST PERFORMANCE FINAL

Lancer Lighthouse.

Ne pas chercher artificiellement :

`100 / 100 / 100 / 100`

L'objectif est plutôt d'identifier les erreurs grossières.

### VÉRIFICATION OPTIMISÉE

Priorités :

1. accessibilité critique ;
2. images gigantesques ;
3. erreurs HTML ;
4. JS inutile ;
5. problèmes évidents de performance.

### SIMULATION

Passer 3 h de plus pour passer :

96 → 100

alors que README n'existe pas :

mauvais investissement.



# 45. TEST "RECRUTEUR"

Faire une simulation extrêmement simple.

Imagine :

> Je suis recruteur Odoo.
> J'ai 90 secondes.

Peut-il comprendre :

1. que le projet fonctionne dans Odoo ?
2. que tu l'as conçu ?
3. ce qu'il ajoute ?
4. comment il s'utilise ?
5. pourquoi tu l'as fait ?
6. ce que tu sais faire ?

Si une de ces réponses est floue :

corriger la présentation.

### VÉRIFICATION OPTIMISÉE

Le projet n'est pas terminé lorsqu'il fonctionne.

Il est terminé lorsqu'il est :

**compréhensible.**



# 46. SIMULATION GLOBALE — SCÉNARIO VERT

Jeudi :

environnement OK + Hero.

Vendredi :

4 snippets.

Samedi :

design + options + mobile.

Dimanche :

QA + README + vidéo.

Résultat :

**candidature idéale.**

Ajouter éventuellement Owl si temps réel restant.



# 47. SIMULATION GLOBALE — SCÉNARIO ORANGE

Jeudi :

installation problématique.

Vendredi :

Hero + Features seulement.

Samedi matin :

Trust + CTA.

Samedi après-midi :

responsive.

Dimanche :

documentation.

Action :

- zéro Owl ;
- zéro animation bonus ;
- options limitées.

Résultat :

**toujours très bonne candidature.**



# 48. SIMULATION GLOBALE — SCÉNARIO ROUGE

Jeudi + vendredi :

gros problèmes techniques.

Samedi :

seulement Hero + Features stables.

Action :

ne PAS créer quatre composants médiocres.

Finaliser :

- Hero exceptionnel ;
- Features exceptionnel ;
- vraie intégration Website Builder ;
- README expliquant que le projet constitue une première collection ;
- roadmap documentée.

Résultat :

deux composants impeccables restent montrables.



# 49. RÈGLE DE DÉGRADATION DU SCOPE

Ordre de suppression si retard :

1. Owl.
2. JavaScript custom.
3. options avancées.
4. animations.
5. intégration formulaire complexe.
6. quatrième snippet si absolument nécessaire.

Ne jamais supprimer :

- intégration Website Builder ;
- responsive ;
- propreté ;
- README ;
- démonstration.



# 50. ERREURS À ÉVITER

## Erreur 1

Copier un vieux tutoriel Odoo sans vérifier la version.

### Correction

Toujours rechercher :

`Odoo 19.0`



## Erreur 2

Modifier directement les fichiers Odoo core.

### Correction

Tout changement doit vivre dans :

`website_webkit`.



## Erreur 3

Faire du CSS global.

### Correction

Namespace :

`webkit_*`



## Erreur 4

Utiliser JavaScript lorsqu'un comportement Bootstrap existe.

### Correction

Chercher solution native d'abord.



## Erreur 5

Hardcoder une page entière.

### Correction

Construire des blocs réutilisables.



## Erreur 6

Créer uniquement quelque chose de joli.

### Correction

Tester le workflow éditeur.



## Erreur 7

Passer trop de temps sur le branding fictif.

### Correction

Le produit important est Web Kit, pas Northline.



## Erreur 8

Oublier le mobile.

### Correction

QA responsive obligatoire samedi.



# 51. ARBRE DE DÉCISION À UTILISER PENDANT LE DÉVELOPPEMENT

À chaque nouvelle idée :

~~~text
Cette feature améliore-t-elle clairement la démonstration ?
             |
      +++
      |             |
     NON           OUI
      |             |
 abandon       < 2 heures ?
                    |
             +++
             |             |
            OUI           NON
             |             |
          faire      MVP terminé ?
                            |
                     +++
                     |             |
                    NON           OUI
                     |             |
                  abandon       timebox
~~~



# 52. DEFINITION OF DONE

Le projet est considéré terminé uniquement si :

## Produit

- [ ] Addon installé dans Odoo 19.
- [ ] Catégorie Web Kit présente.
- [ ] Minimum 4 blocs.
- [ ] Drag & drop fonctionnel.
- [ ] Contenu éditable.
- [ ] Responsive.
- [ ] Design cohérent.

## Technique

- [ ] Code séparé du core Odoo.
- [ ] Manifest propre.
- [ ] Assets correctement déclarés.
- [ ] SCSS namespacé.
- [ ] Pas d'erreurs console importantes.
- [ ] Pas de dépendances inutiles.
- [ ] Installation fraîche validée.

## Qualité

- [ ] Navigation clavier.
- [ ] Contraste raisonnable.
- [ ] Images optimisées.
- [ ] Lighthouse effectué.
- [ ] Desktop testé.
- [ ] Mobile testé.

## Présentation

- [ ] README.
- [ ] Screenshots.
- [ ] Homepage démo.
- [ ] Vidéo courte.
- [ ] Repository GitHub propre.
- [ ] Explication du challenge.



# 53. RESSOURCES OBLIGATOIRES

## Ressource 1 — Tutoriel Website Theme Odoo 19

https://www.odoo.com/documentation/19.0/developer/tutorials/website_theme.html

### Utilisation optimisée

Ne pas lire tout le tutoriel avant de coder.

Lire en priorité :

- Setup ;
- Theming ;
- Build your website ;
- Customisation.

Puis revenir à la documentation lorsqu'un besoin apparaît.

### Simulation

Lire 5 heures de documentation avant le premier test :

→ beaucoup d'informations oubliées.

Lire 45-60 min puis construire un snippet :

→ apprentissage contextualisé.



## Ressource 2 — Building Blocks

https://www.odoo.com/documentation/19.0/developer/howtos/website_themes/building_blocks.html

### Utilisation optimisée

Cette page est la **référence principale du projet**.

La garder ouverte pendant le développement.

### Simulation

Question :

"Comment enregistrer mon snippet ?"

→ consulter cette page AVANT Stack Overflow/blog.



## Ressource 3 — Tutoriel officiel Airproof

https://github.com/odoo/tutorials/tree/19.0/website_airproof

### Utilisation optimisée

Utiliser comme :

- référence d'architecture ;
- comparaison ;
- exemple de syntaxe.

Ne PAS copier tout le thème.

### Simulation

Ton fichier `options.xml` ne marche pas.

Comparer directement avec :

https://github.com/odoo/tutorials/blob/19.0/website_airproof/views/snippets/options.xml



## Ressource 4 — Snippet Airproof

https://github.com/odoo/tutorials/blob/19.0/website_airproof/views/snippets/s_airproof_carousel.xml

### Utilisation optimisée

Étudier :

- structure XML ;
- Bootstrap ;
- snippet options.



## Ressource 5 — Assets

https://www.odoo.com/documentation/19.0/developer/reference/frontend/assets.html

### Utilisation optimisée

Consulter si :

- SCSS ne se charge pas ;
- JS ne se charge pas ;
- fichier XML frontend absent ;
- ordre assets problématique.



## Ressource 6 — Manifest

https://www.odoo.com/documentation/19.0/developer/reference/backend/module.html

### Utilisation optimisée

Consulter pour :

- `depends` ;
- `data` ;
- `assets` ;
- `license` ;
- `application`.



## Ressource 7 — Source install

https://www.odoo.com/documentation/19.0/administration/on_premise/source.html

### Utilisation optimisée

Utiliser demain matin pour l'installation.



## Ressource 8 — Setup développeur

https://www.odoo.com/documentation/19.0/developer/tutorials/setup_guide.html

### Utilisation optimisée

Utiliser si tu veux comprendre :

- environnement ;
- PostgreSQL ;
- lancement ;
- addons path.



## Ressource 9 — Code source Odoo 19

https://github.com/odoo/odoo/tree/19.0

### Utilisation optimisée

Si tu veux savoir :

> "Comment Odoo lui-même implémente ce composant ?"

chercher directement dans `/addons/website`.

C'est souvent plus pertinent qu'un tutoriel tiers.



## Ressource 10 — Formulaire Website officiel

https://github.com/odoo/odoo/blob/19.0/addons/website/views/snippets/s_website_form.xml

### Utilisation optimisée

Étudier plutôt que recréer un formulaire from scratch.



## Ressource 11 — Owl

https://www.odoo.com/documentation/19.0/developer/reference/frontend/owl_components.html

### Utilisation optimisée

**Ne pas ouvrir avant que le MVP fonctionne**, sauf curiosité rapide.

Owl = bonus.



## Ressource 12 — JavaScript modules

https://www.odoo.com/documentation/19.0/developer/reference/frontend/javascript_modules.html

### Utilisation optimisée

Consulter uniquement lorsque du JS custom devient nécessaire.



## Ressource 13 — Testing Odoo

https://www.odoo.com/documentation/19.0/developer/reference/backend/testing.html

### Utilisation optimisée

Consulter après fonctionnement du plugin pour comprendre tests et tours.



## Ressource 14 — Coding Guidelines

https://www.odoo.com/documentation/19.0/contributing/development/coding_guidelines.html

### Utilisation optimisée

Relire vendredi/samedi lors du nettoyage du repository.



## Ressource 15 — Developer mode

https://www.odoo.com/documentation/19.0/applications/general/developer_mode.html

### Utilisation optimisée

Pour debug frontend/assets.



## Ressource 16 — Accessibilité WCAG 2.2

https://www.w3.org/WAI/WCAG22/quickref/

### Utilisation optimisée

Utiliser comme checklist de contrôle, pas comme nouveau projet parallèle.



## Ressource 17 — Lighthouse

https://developer.chrome.com/docs/lighthouse/overview

### Utilisation optimisée

Lancer dimanche lors de la QA finale.



# 54. ORDRE DE LECTURE DEMAIN

Ne lis PAS les 17 ressources intégralement.

Ordre optimal :

## Avant de coder

1. Setup guide Odoo.
2. Website Theme — introduction.
3. Building Blocks.

Temps maximum :

**~60-90 minutes.**

## Pendant création addon

4. Airproof `__manifest__.py`.
5. Airproof `options.xml`.
6. Airproof snippet.

## Lorsque nécessaire

7. Assets.
8. Manifest.
9. Code Odoo `/addons/website`.

## Après MVP

10. Coding guidelines.
11. Accessibility.
12. Lighthouse.
13. Testing.

## Bonus

14. JavaScript.
15. Owl.

### SIMULATION

Tout apprendre avant de commencer :

documentation → documentation → documentation → fatigue.

Méthode retenue :

documentation
→ code
→ erreur
→ documentation
→ correction
→ compréhension.



# 55. CHECKLIST DE DÉMARRAGE — JEUDI MATIN

## 08:30

- [ ] Créer `C:\dev`.
- [ ] Vérifier Git.
- [ ] Vérifier Python.
- [ ] Vérifier PostgreSQL.

## 09:00

- [ ] Clone Odoo 19.
- [ ] Virtualenv.
- [ ] Requirements.

## 10:00

- [ ] Lancer Odoo.
- [ ] Créer DB `webkit_dev`.
- [ ] Installer Website.

## 10:30

- [ ] Créer `odoo-web-kit`.
- [ ] Créer `website_webkit`.
- [ ] Manifest.
- [ ] `__init__.py`.

## 11:00

- [ ] Créer Hello Web Kit.
- [ ] Ajouter catégorie Web Kit.

## 12:00

OBJECTIF :

**voir ton propre snippet dans Odoo Website Builder.**

Si cet objectif est atteint avant midi :

le projet est bien engagé.



# 56. QUESTION DE CONTRÔLE À CHAQUE ÉTAPE

Avant de continuer :

> Est-ce que l'étape précédente fonctionne réellement dans Odoo ?

Pas :

> "Est-ce que le code semble correct ?"

Mais :

> "Est-ce que je peux le montrer à quelqu'un ?"



# 57. PHILOSOPHIE DU PROJET

Le message de la candidature doit être :

> Je n'avais jamais besoin de maîtriser tout Odoo pour commencer.
>
> J'ai étudié votre documentation, compris votre architecture Website,
> identifié une extension utile et construit quelque chose directement
> dans votre environnement en quelques jours.

Le projet prouve donc autant :

**ta capacité d'apprentissage**

que :

**ta capacité de développement.**



# 58. CRITÈRE FINAL DE RÉUSSITE

Dimanche, quelqu'un doit pouvoir :

1. cloner ton repository ;
2. placer le module dans ses addons ;
3. lancer Odoo 19 ;
4. installer Web Kit ;
5. ouvrir Website ;
6. trouver Web Kit ;
7. glisser ton Hero ;
8. modifier son contenu ;
9. obtenir immédiatement quelque chose de joli.

Si ces neuf opérations fonctionnent :

**le cœur du projet est réussi.**



# 59. PRIORITÉ ABSOLUE

Dans l'ordre :

1. INTÉGRATION ODOO
2. FIABILITÉ
3. DESIGN
4. RESPONSIVE
5. ÉDITABILITÉ
6. DOCUMENTATION
7. ACCESSIBILITÉ
8. OPTIONS
9. ANIMATIONS
10. OWL

Ne jamais inverser cette pyramide.



# 60. OBJECTIF DE CANDIDATURE

Le plugin n'a pas besoin d'impressionner parce qu'il est gigantesque.

Il doit impressionner parce qu'il donne l'impression suivante :

> "Il voulait travailler chez Odoo.
> Il n'a pas simplement envoyé son CV.
> Il a installé notre produit,
> étudié notre architecture,
> appris notre Website Builder,
> conçu une extension,
> développé cette extension,
> testé cette extension,
> documenté cette extension,
> puis nous l'a envoyée."

C'est exactement l'histoire que Odoo Web Kit doit raconter.



# FIN — VERSION 1.0

## Demain, première mission

Ne commence pas par le design.

Commence par obtenir ceci :

Odoo 19
→ Website
→ Edit
→ Web Kit
→ drag & drop
→ "Hello Web Kit"

Une fois ce pipeline validé :

**on construit le vrai Hero.**