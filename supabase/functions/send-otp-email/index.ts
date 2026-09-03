// Auth "Send Email" hook (HTTPS type). Supabase Auth calls this endpoint
// instead of using its built-in email templates whenever it needs to email
// an OTP code — for both a brand-new account and an existing one, since
// `signInWithOtp` treats them identically. We take over sending so the
// email shows a plain 6-digit code in French with no clickable link,
// matching the app's code-only auth flow (see supabase/README_AUTH.md).
//
// Deploy: paste this file into Supabase Dashboard → Edge Functions →
// New Function (name it "send-otp-email") → Deploy. (Or via CLI:
// `supabase functions deploy send-otp-email --no-verify-jwt`.)
//
// Required secrets (Dashboard → Edge Functions → Manage secrets, or
// `supabase secrets set NAME=value`):
//   RESEND_API_KEY          from resend.com → API Keys
//   SEND_EMAIL_HOOK_SECRET  the "Secret" value shown on the Supabase
//                           "Add Send Email hook" screen, pasted exactly
//                           as shown (format "v1,whsec_..." — the code
//                           below strips the "v1," prefix itself, see
//                           below).
//
// Signature verification: Supabase Auth Hooks are signed per the Standard
// Webhooks spec (https://www.standardwebhooks.com/) — confirmed by the
// "whsec_" secret format Supabase's own hook screen shows. We verify with
// the official `standardwebhooks` package. Supabase's displayed secret is
// prefixed "v1," (their own versioning marker, not part of the key
// material) — this was confirmed against a real deployment: passing the
// secret unstripped made every request fail verification with a 401, so
// the code below strips it before constructing the Webhook instance.

import { Webhook } from "npm:standardwebhooks@1.0.0";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const HOOK_SECRET = Deno.env.get("SEND_EMAIL_HOOK_SECRET");

interface HookPayload {
  user: { email: string };
  email_data: { token: string };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!RESEND_API_KEY || !HOOK_SECRET) {
    console.error("Missing RESEND_API_KEY or SEND_EMAIL_HOOK_SECRET secret");
    return new Response(
      JSON.stringify({ error: { http_code: 500, message: "Server misconfigured" } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const payload = await req.text();
  const headers = Object.fromEntries(req.headers);

  let data: HookPayload;
  try {
    // Supabase displays the secret as "v1,whsec_..." but the Standard
    // Webhooks reference library expects only the "whsec_..." part — the
    // "v1," is Supabase's own versioning prefix, not part of the key
    // material. Confirmed necessary: passing the raw "v1,whsec_..." value
    // made every real request fail verification with a 401.
    const wh = new Webhook(HOOK_SECRET.replace(/^v1,/, ""));
    data = wh.verify(payload, headers) as HookPayload;
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return new Response(
      JSON.stringify({ error: { http_code: 401, message: "Invalid signature" } }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }

  const email = data.user?.email;
  const token = data.email_data?.token;
  if (!email || !token) {
    console.error("Hook payload missing user.email or email_data.token:", data);
    return new Response(
      JSON.stringify({ error: { http_code: 400, message: "Missing email or token" } }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const resendResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Mes Étoiles <onboarding@resend.dev>",
      to: [email],
      subject: "Votre code Mes Étoiles ⭐",
      html: `
        <div style="font-family: sans-serif; text-align: center; padding: 24px;">
          <h2>Votre code de vérification</h2>
          <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px;">${token}</p>
          <p>Saisissez ce code dans l'application Mes Étoiles.</p>
        </div>
      `,
    }),
  });

  if (!resendResponse.ok) {
    const detail = await resendResponse.text();
    console.error("Resend API error:", resendResponse.status, detail);
    return new Response(
      JSON.stringify({ error: { http_code: 500, message: "Failed to send email" } }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
