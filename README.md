# ⭐ Mes Étoiles

Application familiale Flutter + Supabase permettant aux parents d'attribuer
rapidement des étoiles à leurs enfants (−1 / +1 / +2), synchronisée entre les
téléphones des deux parents, avec récompenses et un mode enfant en lecture
seule.

## Structure du dépôt

```
app/                    Projet Flutter (Android prioritaire, architecture compatible iOS)
  lib/
    models/             Child, StarEvent, Reward, RedeemedReward, FamilyProfile
    data/                Avatars, motifs de notation, récompenses par défaut, messages
    services/            SupabaseService (auth + CRUD + RPC), LocalCacheService (offline)
    providers/            AuthProvider, FamilyProvider (realtime + cache), ChildModeProvider
    theme/                Palette pastel, thème Material 3, police Nunito
    screens/              Onboarding, auth, accueil, enfant, récompenses, historique, réglages, mode enfant
    widgets/              Composants réutilisables (cartes, barres de progression, célébrations, etc.)
  test/                  Tests unitaires (logique des étoiles, badges) + tests de widgets
supabase/
  migrations/
    0001_init.sql        Schéma, triggers de calcul des étoiles, RPC, RLS
    0002_realtime.sql     Active la réplication temps réel (children, star_events, rewards)
.github/workflows/
  build-apk.yml           Compile l'APK Android en CI (voir "Générer l'APK" ci-dessous)
```

## 1. Créer le projet Supabase

1. Créez un projet gratuit sur [supabase.com](https://supabase.com).
2. Dans l'éditeur SQL du projet, exécutez dans l'ordre :
   - `supabase/migrations/0001_init.sql`
   - `supabase/migrations/0002_realtime.sql`
3. Dans **Project Settings → API**, récupérez :
   - `Project URL` → `SUPABASE_URL`
   - `anon public` key → `SUPABASE_ANON_KEY`
4. Dans **Authentication → Providers**, l'authentification Email est activée
   par défaut — c'est la seule utilisée par l'application (pas de compte
   enfant, pas de rôles).
5. Suivez **`supabase/README_AUTH.md`** pour configurer le template email
   du code OTP à 6 chiffres — sans ça, l'email envoyé contiendra un lien
   au lieu d'un code.

La sécurité est assurée par des policies RLS : chaque famille (un compte =
une ligne `profiles`) ne peut lire/écrire que ses propres enfants,
événements et récompenses. Aucune clé `service_role` n'est utilisée côté
application.

## 2. Configurer l'application

```bash
cd app
cp .env.example .env
# éditez .env avec votre SUPABASE_URL et SUPABASE_ANON_KEY
```

## 3. Lancer en développement

```bash
cd app
flutter pub get
flutter run
```

## 4. Tests

```bash
cd app
flutter analyze
flutter test
```

13 tests couvrent la règle métier centrale (le solde d'étoiles ne descend
jamais sous zéro, même événement par événement — voir
`test/unit/star_logic_test.dart`), les badges automatiques et quelques
smoke tests de widgets.

## 5. Générer l'APK Android

**Important** : l'environnement Claude Code (sandbox) dans lequel ce projet a
été développé n'a pas accès à `dl.google.com`, l'hôte exclusif de
distribution du SDK Android (politique réseau de l'organisation). Il n'a
donc pas été possible d'installer le SDK Android ni de compiler l'APK
directement dans cette session.

Deux options pour obtenir l'APK :

### Option A — CI GitHub Actions (recommandé, déjà configuré)

Le workflow `.github/workflows/build-apk.yml` compile l'APK automatiquement
à chaque push sur la branche du projet, et le publie en tant que **Release
GitHub** (et en artifact de build). Pour utiliser vos vraies clés Supabase
dans cet APK plutôt que les valeurs de test de `.env.example`, ajoutez deux
secrets dans **Settings → Secrets and variables → Actions** du dépôt :
`SUPABASE_URL` et `SUPABASE_ANON_KEY`. Sans ces secrets, l'APK est quand
même généré mais utilise des identifiants Supabase factices (l'app
s'installe et s'affiche, mais ne pourra pas se connecter tant que vous ne
les aurez pas renseignés).

### Option B — Localement

```bash
cd app
flutter build apk --release
# APK généré dans : app/build/app/outputs/flutter-apk/app-release.apk
```

L'APK est signé avec la clé de debug Flutter (comportement par défaut du
template `flutter create`) : il s'installe directement sur un téléphone
Android (activer "Sources inconnues"/"Installer des applications inconnues"
pour l'app utilisée pour le transfert), mais n'est pas destiné à une
publication sur le Play Store en l'état — il faudrait alors configurer une
vraie clé de signature de release.

## Ce qui a été livré (V1)

- Authentification email + code OTP à 6 chiffres, sans mot de passe ni lien
  à cliquer (voir `supabase/README_AUTH.md` pour la configuration du
  template email côté Dashboard) — pas de compte enfant.
- Écran d'accueil avec cartes enfants (avatar, étoiles, progression vers la
  prochaine récompense), sans classement ni comparaison entre enfants.
- Ajout/modification/suppression d'enfant, ~20 avatars, couleur préférée.
- Attribution de notes en 2-3 clics (−1 / +1 / +2) avec motifs prédéfinis,
  animation courte (~1s), annulation rapide (snackbar "ANNULER").
- Règle "jamais sous zéro" appliquée événement par événement (testée), y
  compris pour la réparation d'une bêtise.
- Récompenses préchargées, gestion complète (ajout/modif/suppression),
  déblocage avec confirmation et déduction atomique des étoiles (RPC
  Postgres transactionnelle).
- Historique groupé par jour, modification/suppression d'un événement.
- Mode enfant en lecture seule (multi-enfants avec sélecteur), verrouillé
  par un code PIN parent à 4 chiffres.
- Petits badges automatiques optionnels (pas de niveaux, pas d'XP).
- Synchronisation Supabase Realtime sur les scores + rafraîchissement au
  lancement, au retour sur l'app et par pull-to-refresh.
- Cache local (lecture seule) pour rester consultable hors connexion.
- Gestion des erreurs et états vides sur tous les écrans (jamais d'erreur
  technique brute affichée au parent).
- RLS Supabase : isolation stricte par famille, aucune clé `service_role`
  dans l'app.

## Limites connues de cette V1

- **APK non généré dans cette session** (voir section 5 ci-dessus — bloqué
  par la politique réseau de l'environnement de développement, pas par le
  code de l'application). Le déclenchement du build CI est décrit
  ci-dessus.
- Le PIN parent est stocké en clair dans `profiles.parent_pin` : c'est un
  simple frein pour sortir du mode enfant, pas un mécanisme de sécurité
  fort (il n'y a rien de sensible derrière — mêmes données, même compte).
- Pas de tests end-to-end automatisés sur device/émulateur (aucun SDK
  Android disponible dans le sandbox) : la logique métier critique est
  couverte par des tests unitaires, et les écrans ont été relus mais pas
  exécutés sur un appareil réel — à valider manuellement à l'installation
  de l'APK.
- Architecture compatible iOS (aucune dépendance spécifique à Android dans
  le code Dart) mais aucune configuration ni build iOS n'a été faite, comme
  demandé.
