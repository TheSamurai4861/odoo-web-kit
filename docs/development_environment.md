# Environnement de développement Odoo Web Kit

## État validé

L'environnement local de l'étape 1 est opérationnel sur Windows 11 :

- Odoo Community 19.0 exécuté depuis les sources officielles ;
- Python 3.12.10 dans un environnement virtuel dédié ;
- PostgreSQL 16.10 dans un cluster local dédié ;
- base `webkit_dev` en UTF-8 ;
- module Website installé ;
- homepage, backend, mode `debug=assets` et route d'édition validés.

## Arborescence locale

~~~text
C:\Famille\Venom\DEV\odoo\
├── odoo-19\                 # sources officielles, branche 19.0
├── .venv-odoo19\           # environnement Python 3.12
├── .runtime\               # données locales et secrets non versionnés
│   ├── odoo-dev.conf
│   ├── odoo-data\
│   ├── odoo.log
│   ├── postgresql-16-webkit\
│   └── secrets\
└── web-kit\                 # dépôt de l'addon et documentation
~~~

Le code custom reste ainsi séparé du dépôt officiel Odoo.

## Endpoints et accès

- Website : `http://127.0.0.1:8069/`
- Backend : `http://127.0.0.1:8069/odoo`
- Backend avec assets non groupés : `http://127.0.0.1:8069/odoo?debug=assets`
- Éditeur Website : `http://127.0.0.1:8069/@/?enable_editor=1&debug=assets`
- Login Odoo : `admin`
- Mot de passe Odoo : `.runtime\secrets\odoo-admin-password`
- PostgreSQL applicatif : `odoo_webkit@127.0.0.1:5433/webkit_dev`

Les valeurs secrètes ne doivent jamais être copiées dans le dépôt, un ticket,
une capture ou un log partagé.

## Commandes courantes

Depuis `web-kit` :

~~~powershell
.\scripts\start-dev.ps1
.\scripts\verify-dev.ps1
.\scripts\stop-dev.ps1
~~~

Pour arrêter également le cluster PostgreSQL dédié :

~~~powershell
.\scripts\stop-dev.ps1 -IncludePostgreSQL
~~~

Le script de démarrage relance PostgreSQL si nécessaire. Il ne touche pas au
service PostgreSQL existant sur le port 5432.

## Vérifications réalisées

- Branche et remote Git officiels contrôlés.
- Commit Odoo contrôlé : `c2a39085ba0fbcf8a0e6a55228191e764499caea`.
- Présence de `odoo-bin`, `requirements.txt` et `addons\website` contrôlée.
- Toutes les dépendances Python installées depuis le `requirements.txt` Odoo.
- `pip check` sans dépendance cassée.
- Import d'Odoo et connexion PostgreSQL réussis.
- Rendu PNG ReportLab exécuté avec succès.
- Initialisation Odoo terminée avec code retour 0.
- Installation Website terminée avec code retour 0.
- Homepage HTTP 200.
- Authentification backend réussie.
- Backend `debug=assets` HTTP 200.
- Route éditeur authentifiée HTTP 200 vers `website_preview`.
- Recette navigateur headless : interface en mode édition, sidebar des blocs,
  preview Website et racine `#wrapwrap` présentes, sans erreur JavaScript.
- Capture de preuve locale : `.runtime\website-editor-validation.png`.
- Aucun `ERROR`, `CRITICAL` ou traceback dans le journal Odoo après validation.

## Décision Python

Python 3.13.2 respecte le minimum Odoo, mais `rl-renderPM==4.0.3` ne fournit pas
de wheel Windows pour CPython 3.13 et son archive source ne se compile pas telle
quelle. Python 3.12.10 a donc été retenu conformément au choix conservateur du
cahier. Le wheel officiel CPython 3.12 fonctionne et un rendu PNG réel a été
validé.

## PostgreSQL dédié

Le service PostgreSQL 16 existant occupe déjà le port 5432 et exige des
identifiants non disponibles. Pour ne pas modifier cette installation, un
cluster PostgreSQL 16 indépendant a été initialisé sur `127.0.0.1:5433` avec :

- authentification `scram-sha-256` ;
- rôle applicatif non-superutilisateur `odoo_webkit` ;
- base `webkit_dev` appartenant au rôle applicatif ;
- secrets aléatoires stockés localement avec des ACL restreintes.

## Passage à l'étape 2

L'interface du Website Builder est chargée et son panneau de blocs est visible.
Le prochain jalon consiste à créer la structure minimale de l'addon, faire
apparaître la catégorie `Web Kit`, puis glisser et sauvegarder le premier snippet
`Hello Web Kit`.
