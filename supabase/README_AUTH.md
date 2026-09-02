# Authentification — email + code OTP à 6 chiffres

Ce document décrit le parcours d'authentification actuel de l'app (email →
code à 6 chiffres → session connectée, sans mot de passe ni lien à
cliquer) et les réglages **manuels** à faire dans le Dashboard Supabase
pour qu'il fonctionne. Rien de ceci n'est versionné automatiquement : le
code ci-dessous appelle l'API Supabase, mais le contenu de l'email envoyé
et les limites de fréquence sont configurés côté Dashboard uniquement.

## 1. Ce que fait le code (rien à faire ici)

- `SupabaseService.sendOtp(email)` → `supabase.auth.signInWithOtp(email: email)`
  Envoie un code à 6 chiffres. `shouldCreateUser` vaut `true` par défaut
  dans `supabase_flutter` : un email jamais vu crée silencieusement un
  compte, un email existant reçoit simplement un nouveau code. **Aucun
  `emailRedirectTo` n'est passé** — pas de lien, pas de deep link, pas de
  redirection.
- `SupabaseService.verifyOtp(email, token)` → `supabase.auth.verifyOTP(email: ..., token: ..., type: OtpType.email)`
  Vérifie le code et établit la session. `OtpType.email` est utilisé dans
  les deux cas (nouveau compte ou compte existant) — voir le commentaire
  dans `supabase_service.dart` pour la justification exacte (vérifiée dans
  le code source du package `gotrue` utilisé par l'app).

## 2. Réglages à faire dans le Dashboard Supabase

### 2.1 Le template d'email doit afficher le code, pas un bouton

Allez dans **Authentication → Email Templates**.

Le template utilisé par `signInWithOtp()` est habituellement celui nommé
**« Magic Link »** (certains projets Supabase plus récents affichent aussi
une entrée séparée **« Email OTP »** — si elle existe sur votre projet,
c'est celle-là qu'il faut modifier ; testez pour voir laquelle des deux
part réellement quand vous appelez `sendOtp`, je n'ai pas pu vérifier
l'intitulé exact affiché sur votre projet depuis mon environnement, qui
n'a pas accès à votre Dashboard).

Remplacez le contenu du template (par défaut un bouton `{{ .ConfirmationURL }}`)
par quelque chose comme :

```
Objet : Votre code Mes Étoiles ⭐

Corps :

Votre code de vérification

{{ .Token }}

Saisissez ce code dans l'application Mes Étoiles.
```

Points importants :
- Utilisez **`{{ .Token }}`** (le code à 6 chiffres), pas `{{ .ConfirmationURL }}`.
- Ne mettez **aucun bouton "Se connecter"** ni lien cliquable — l'app
  n'attend jamais que l'utilisateur clique sur quoi que ce soit dans cet
  email.
- Le contenu ci-dessus est un exemple minimal ; adaptez le style/HTML à
  votre goût, seul `{{ .Token }}` est indispensable.

### 2.2 Site URL / Additional Redirect URLs

**Plus nécessaire pour ce parcours.** Si vous aviez configuré
`io.mesetoiles.app://login-callback` suite à une précédente version de
l'app (parcours email + mot de passe avec confirmation par lien), vous
pouvez laisser cette entrée en place sans risque (elle ne sera plus
utilisée) ou la retirer — au choix, aucune conséquence sur le nouveau
parcours OTP.

### 2.3 Rate limits (Authentication → Rate Limits)

Supabase limite nativement le nombre d'emails OTP envoyés par adresse /
par IP dans une fenêtre de temps donnée. Le cooldown de 30 secondes du
bouton « Renvoyer le code » dans l'app est une protection **anti
double-clic côté interface uniquement** — elle ne remplace pas cette
limite serveur. Si vous testez beaucoup en un temps court et recevez un
message « Trop de tentatives », c'est cette limite Supabase (pas un bug
de l'app) ; attendez quelques minutes, ou ajustez la limite dans le
Dashboard si besoin pour vos tests.

### 2.4 Ce qui n'a plus besoin d'être configuré

Le réglage **Authentication → Providers → Email → « Confirm email »**
gouvernait l'ancien parcours email + mot de passe (confirmation par lien
avant de pouvoir se connecter). Il n'a plus aucun effet sur le parcours
actuel : l'app n'appelle plus jamais `signUp()` ni
`signInWithPassword()`. Vous pouvez laisser ce réglage tel quel, il est
simplement ignoré par le code actuel.

## 3. Sécurité

- Aucun secret serveur (`service_role`, mot de passe de base de données)
  n'est présent dans le code Flutter — uniquement `SUPABASE_URL` et la
  clé publique `anon` (voir `.env.example`).
- Les policies RLS existantes (`supabase/migrations/0001_init.sql`) sont
  inchangées : chaque famille (une ligne `profiles`, `id = auth.uid()`)
  ne peut lire/écrire que ses propres enfants, événements et récompenses,
  quel que soit le mécanisme d'authentification utilisé pour obtenir la
  session.
