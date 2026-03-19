// supabase/functions/link-apple-signin/index.ts
// Edge Function: Link Apple Sign-In with pre-migrated accounts
// Part of MBA-160
//
// This function can be invoked via:
// 1. Supabase Auth Hook (after_sign_up webhook) — automatic on every new sign-up
// 2. Manual HTTP POST for remediation of already-signed-up users
//
// The primary mechanism is the database trigger (migration 006). This edge
// function serves as a secondary/manual invocation path.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

interface LinkResult {
  linked: boolean;
  old_id?: string;
  new_id: string;
  email: string;
  reason: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing environment configuration" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let body: { user_id?: string; email?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const newUserId = body.user_id;
  const email = body.email;

  if (!newUserId || !email) {
    return new Response(
      JSON.stringify({ error: "Missing required fields: user_id, email" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  try {
    const result = await linkPrecreatedAccount(supabase, newUserId, email);
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

async function linkPrecreatedAccount(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  newUserId: string,
  email: string,
): Promise<LinkResult> {
  // Call the database function to perform the linking.
  // This reuses the same SQL logic from migration 006, exposed as an RPC.
  const { data, error } = await supabase.rpc("link_precreated_account_rpc", {
    p_new_id: newUserId,
    p_email: email,
  });

  if (error) {
    throw new Error(`Database error: ${error.message}`);
  }

  return data as LinkResult;
}
