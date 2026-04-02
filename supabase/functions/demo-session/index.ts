// demo-session/index.ts
// Supabase Edge Function: generates a fresh session for the App Store review demo account.
// Part of MBA-215: demo test account for App Store review.
// Updated in MBA-227: requires a secret key validated via SHA-256 hash comparison.
//
// Required secrets (set via `supabase secrets set`):
//   DEMO_USER_EMAIL       — email of the pre-created demo user
//   DEMO_USER_PASSWORD    — password of the pre-created demo user
//   DEMO_ACCESS_KEY_HASH  — SHA-256 hex digest of the access key

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const demoEmail = Deno.env.get("DEMO_USER_EMAIL");
  const demoPassword = Deno.env.get("DEMO_USER_PASSWORD");
  const expectedKeyHash = Deno.env.get("DEMO_ACCESS_KEY_HASH");

  if (!supabaseUrl || !demoEmail || !demoPassword || !expectedKeyHash) {
    return new Response(
      JSON.stringify({ error: "Missing required environment variables" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    const body = await req.json().catch(() => ({}));
    const key: string = body.key ?? "";

    const keyHash = await sha256Hex(key);
    if (keyHash !== expectedKeyHash) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const anonKey =
      req.headers.get("apikey") ??
      Deno.env.get("SUPABASE_ANON_KEY") ??
      "";

    const anonClient = createClient(supabaseUrl, anonKey);

    const { data, error } = await anonClient.auth.signInWithPassword({
      email: demoEmail,
      password: demoPassword,
    });

    if (error) {
      return new Response(
        JSON.stringify({ error: "Demo sign-in failed", detail: error.message }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
