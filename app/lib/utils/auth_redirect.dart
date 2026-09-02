/// Deep link that Supabase's confirmation / password-reset emails redirect
/// back to on this device. This exact string must be registered in three
/// places or the link opens to nothing (or "localhost is unreachable"):
///  1. The intent-filter scheme/host in android/app/src/main/AndroidManifest.xml
///  2. Supabase Dashboard → Authentication → URL Configuration →
///     Additional Redirect URLs
///  3. Every call site that triggers a confirmation/reset email
///     (signUp, resend, resetPasswordForEmail) below.
const String kAuthRedirectUrl = 'io.mesetoiles.app://login-callback';
