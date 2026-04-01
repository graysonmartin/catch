// demo-session/index.ts
// Supabase Edge Function: generates a fresh session for the App Store review demo account.
// Part of MBA-215: demo test account for App Store review.
//
// Required secrets (set via `supabase secrets set`):
//   DEMO_USER_EMAIL    — email of the pre-created demo user
//   DEMO_USER_PASSWORD — password of the pre-created demo user

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const demoEmail = Deno.env.get("DEMO_USER_EMAIL");
  const demoPassword = Deno.env.get("DEMO_USER_PASSWORD");

  if (!supabaseUrl || !serviceRoleKey || !demoEmail || !demoPassword) {
    return new Response(
      JSON.stringify({ error: "Missing required environment variables" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    // Use the anon client for signInWithPassword — service role can't generate
    // user-scoped JWTs via password auth. The anon key is embedded in the URL
    // config, so we use it from the request's Authorization header.
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
