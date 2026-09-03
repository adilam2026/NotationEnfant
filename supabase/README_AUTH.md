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

Sur ce projet (plan Free), le template **Magic link or OTP**
(Authentication → Emails) ne peut **pas** être édité directement — le
bouton "Save changes" reste grisé tant qu'un SMTP personnalisé n'est pas
configuré, ce que Supabase gate derrière deux options (confirmé sur le
Dashboard du projet) : passer sur le plan Pro, ou configurer un **Send
Email Hook**. C'est la seconde option (gratuite) qui a été mise en place.

**Principe** : ce hook remplace entièrement l'envoi natif de Supabase —
à chaque email d'auth (OTP inclus), Supabase appelle une URL HTTPS que
vous fournissez, avec le code dans le payload ; c'est cette Edge Function
qui construit et envoie l'email elle-même via Resend.

Le code est dans `supabase/functions/send-otp-email/index.ts` de ce
dépôt. Étapes de déploiement :

1. **Compte Resend** : créez un compte gratuit sur [resend.com](https://resend.com),
   générez une API key (Dashboard Resend → API Keys). L'expéditeur
   `onboarding@resend.dev` (domaine de test Resend) est utilisé par
   défaut dans le code — fonctionne sans configuration DNS pour démarrer.
2. **Déployer l'Edge Function** — Dashboard Supabase → **Edge Functions**
   → **New Function**, nommez-la `send-otp-email`, collez le contenu de
   `supabase/functions/send-otp-email/index.ts`, **Deploy**.
   (Alternative en ligne de commande, si la CLI Supabase est installée :
   `supabase functions deploy send-otp-email --no-verify-jwt`.)
3. **Secrets de la fonction** — Dashboard Supabase → **Edge Functions**
   → **Manage secrets** (ou `supabase secrets set NOM=valeur`), ajoutez :
   - `RESEND_API_KEY` = la clé générée à l'étape 1
   - `SEND_EMAIL_HOOK_SECRET` = le champ **Secret** de l'écran "Add Send
     Email hook" (cliquez **Generate secret** s'il est vide) — collez la
     valeur telle quelle, avec son préfixe `v1,whsec_...`.
4. **Créer le hook** — retournez sur l'écran "Add Send Email hook"
   (Authentication → Emails → Magic link or OTP → Set up SMTP →
   Configure Send Email hook) :
   - Hook type : **HTTPS**
   - URL : l'URL de la fonction déployée à l'étape 2, de la forme
     `https://<project-ref>.supabase.co/functions/v1/send-otp-email`
   - Secret : la même valeur qu'à l'étape 3
   - **Create hook**

Points importants :
- Le code Deno n'a **pas pu être testé de bout en bout** depuis
  l'environnement où il a été écrit (pas d'accès réseau à
  `supabase.com`, donc impossible de vérifier le payload exact envoyé
  par Supabase ou de déployer/appeler la fonction moi-même). La
  vérification de signature (spec Standard Webhooks, confirmée par le
  format `whsec_` du secret) suit le pattern documenté par Supabase pour
  ce hook, mais si les logs de la fonction (Dashboard → Edge Functions →
  `send-otp-email` → Logs) montrent un échec systématique de
  vérification de signature après un test réel, voir le commentaire en
  tête du fichier `index.ts` pour la piste de correction la plus
  probable.
- Pour tester : dans l'app, lancez un envoi de code (écran "Continuer"),
  puis regardez immédiatement les **Logs** de la fonction dans le
  Dashboard — erreurs Resend ou de signature y apparaîtront clairement
  plutôt que de simplement ne pas recevoir l'email.
- Ne mettez **aucun bouton "Se connecter"** ni lien cliquable dans
  l'email — l'app n'attend jamais que l'utilisateur clique sur quoi que
  ce soit, seulement qu'il recopie le code à 6 chiffres.

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
