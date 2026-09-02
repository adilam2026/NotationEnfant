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

Allez dans **Authentication → Emails → Magic link or OTP** (template
unique confirmé sur ce projet — pas de template "Email OTP" séparé).

1. Dans la section **Body**, cliquez **Source** (à côté de "Preview")
   pour éditer le HTML brut.
2. **Subject** :
   ```
   Votre code Mes Étoiles ⭐
   ```
3. **Body** (en mode Source) — remplacez le contenu par défaut (un bouton
   "Sign in" pointant vers `{{ .ConfirmationURL }}`) par :
   ```html
   <h2>Votre code de vérification</h2>
   <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px;">{{ .Token }}</p>
   <p>Saisissez ce code dans l'application Mes Étoiles.</p>
   ```
4. **Save changes**.

Points importants :
- Utilisez **`{{ .Token }}`** (le code à 6 chiffres), pas `{{ .ConfirmationURL }}`.
- Ne mettez **aucun bouton "Se connecter"** ni lien cliquable — l'app
  n'attend jamais que l'utilisateur clique sur quoi que ce soit dans cet
  email.
- Le contenu ci-dessus est un exemple minimal ; adaptez le style/HTML à
  votre goût, seul `{{ .Token }}` est indispensable.
- **Si "Save changes" reste grisé ou que la modification ne persiste
  pas** : Supabase bloque la personnalisation du Subject/Body tant qu'un
  SMTP personnalisé n'est pas configuré (le mailer partagé par défaut ne
  l'autorise pas). Il faut alors renseigner un SMTP dans
  **Authentication → Emails → SMTP Settings** (ex. Resend, SendGrid,
  Gmail) avant de pouvoir sauvegarder ce template.

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
