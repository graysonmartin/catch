// send-push-notification/index.ts
// Supabase Edge Function: processes pending notifications and delivers via APNs
// Part of MBA-205: notification delivery pipeline

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ---------------------------------------------------------------------------
// APNs JWT generation
// ---------------------------------------------------------------------------

/**
 * Base64url-encode a Uint8Array.
 */
function base64url(data: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...data));
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/**
 * Base64url-encode a string (UTF-8).
 */
function base64urlString(str: string): string {
  return base64url(new TextEncoder().encode(str));
}

/**
 * Import a PKCS#8 private key (.p8) for ES256 signing.
 */
async function importP8Key(p8Base64: string): Promise<CryptoKey> {
  const raw = Uint8Array.from(atob(p8Base64), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    raw,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

/**
 * Build a signed JWT for APNs authentication (ES256, 1-hour expiry).
 */
async function buildApnsJwt(
  keyId: string,
  teamId: string,
  privateKey: CryptoKey,
): Promise<string> {
  const header = base64urlString(
    JSON.stringify({ alg: "ES256", kid: keyId }),
  );
  const now = Math.floor(Date.now() / 1000);
  const claims = base64urlString(
    JSON.stringify({ iss: teamId, iat: now }),
  );

  const signingInput = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );

  // Convert DER signature to raw r||s for JWT
  const sig = base64url(new Uint8Array(signature));
  return `${header}.${claims}.${sig}`;
}

// ---------------------------------------------------------------------------
// APNs delivery
// ---------------------------------------------------------------------------

interface NotificationRow {
  id: string;
  recipient_user_id: string;
  notification_type: string;
  entity_type: string;
  entity_id: string;
  actor_id: string | null;
  payload: Record<string, unknown>;
}

interface DeviceTokenRow {
  token: string;
  environment: string;
}

/**
 * Build the APNs JSON payload from a notification row.
 */
function buildApnsPayload(notification: NotificationRow): Record<string, unknown> {
  const actorName = (notification.payload.actor_display_name as string) || "someone";
  const catName = (notification.payload.cat_name as string) || "a cat";

  let title: string;
  let body: string;

  switch (notification.notification_type) {
    case "encounter_liked":
      title = "new like";
      body = `${actorName} liked your encounter with ${catName}`;
      break;
    case "encounter_commented":
      title = "new comment";
      body = `${actorName} commented on your encounter with ${catName}`;
      break;
    default:
      title = "catch";
      body = "you have a new notification";
  }

  return {
    aps: {
      alert: { title, body },
      sound: "default",
      "thread-id": notification.entity_id,
    },
    notification_id: notification.id,
    notification_type: notification.notification_type,
    entity_type: notification.entity_type,
    entity_id: notification.entity_id,
    actor_id: notification.actor_id,
  };
}

/**
 * Send a single push notification to one device token via APNs HTTP/2.
 * Returns the HTTP status code from APNs.
 */
async function sendToApns(
  token: string,
  environment: string,
  apnsPayload: Record<string, unknown>,
  jwt: string,
  topic: string,
): Promise<{ status: number; body: string }> {
  const host =
    environment === "production"
      ? "https://api.push.apple.com"
      : "https://api.sandbox.push.apple.com";

  const url = `${host}/3/device/${token}`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `bearer ${jwt}`,
      "apns-topic": topic,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(apnsPayload),
  });

  const body = await response.text();
  return { status: response.status, body };
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req: Request) => {
  try {
    // Verify authorization (service role key or webhook secret)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "missing authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const apnsKeyId = Deno.env.get("APNS_KEY_ID");
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID");
    const apnsKeyP8 = Deno.env.get("APNS_KEY_P8"); // base64-encoded .p8 file
    const apnsTopic = Deno.env.get("APNS_TOPIC"); // bundle ID

    if (!apnsKeyId || !apnsTeamId || !apnsKeyP8 || !apnsTopic) {
      console.error("Missing APNs configuration environment variables");
      return new Response(
        JSON.stringify({ error: "APNs not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Initialize Supabase client with service role (bypasses RLS)
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Fetch pending notifications (batch of 50)
    const { data: pendingNotifications, error: fetchError } = await supabase
      .from("notifications")
      .select("*")
      .eq("delivery_status", "pending")
      .order("created_at", { ascending: true })
      .limit(50);

    if (fetchError) {
      console.error("Failed to fetch pending notifications:", fetchError);
      return new Response(
        JSON.stringify({ error: "failed to fetch notifications", detail: fetchError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!pendingNotifications || pendingNotifications.length === 0) {
      return new Response(
        JSON.stringify({ processed: 0, message: "no pending notifications" }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    console.log(`Processing ${pendingNotifications.length} pending notifications`);

    // Import the signing key once for the batch
    const privateKey = await importP8Key(apnsKeyP8);
    const jwt = await buildApnsJwt(apnsKeyId, apnsTeamId, privateKey);

    // Process each notification
    const results: Array<{
      notification_id: string;
      status: string;
      tokens_attempted: number;
      tokens_succeeded: number;
    }> = [];

    for (const notification of pendingNotifications as NotificationRow[]) {
      // Look up device tokens for the recipient
      const { data: deviceTokens, error: tokenError } = await supabase
        .from("device_tokens")
        .select("token, environment")
        .eq("user_id", notification.recipient_user_id);

      if (tokenError) {
        console.error(
          `Failed to fetch tokens for user ${notification.recipient_user_id}:`,
          tokenError,
        );
        await supabase
          .from("notifications")
          .update({ delivery_status: "failed" })
          .eq("id", notification.id);

        results.push({
          notification_id: notification.id,
          status: "failed",
          tokens_attempted: 0,
          tokens_succeeded: 0,
        });
        continue;
      }

      if (!deviceTokens || deviceTokens.length === 0) {
        // No device tokens registered — mark as failed (no device)
        console.log(
          `No device tokens for user ${notification.recipient_user_id}, skipping`,
        );
        await supabase
          .from("notifications")
          .update({ delivery_status: "failed" })
          .eq("id", notification.id);

        results.push({
          notification_id: notification.id,
          status: "failed",
          tokens_attempted: 0,
          tokens_succeeded: 0,
        });
        continue;
      }

      const apnsPayload = buildApnsPayload(notification);
      let anySucceeded = false;
      const tokensAttempted = deviceTokens.length;
      let tokensSucceeded = 0;

      // Send to each device token
      for (const deviceToken of deviceTokens as DeviceTokenRow[]) {
        try {
          const { status, body } = await sendToApns(
            deviceToken.token,
            deviceToken.environment,
            apnsPayload,
            jwt,
            apnsTopic,
          );

          if (status === 200) {
            anySucceeded = true;
            tokensSucceeded++;
            console.log(
              `Sent notification ${notification.id} to token ${deviceToken.token.slice(0, 8)}...`,
            );
          } else if (status === 410) {
            // 410 Gone — token is no longer valid, clean it up
            console.log(
              `Token ${deviceToken.token.slice(0, 8)}... is invalid (410 Gone), deleting`,
            );
            await supabase
              .from("device_tokens")
              .delete()
              .eq("token", deviceToken.token);
          } else {
            console.error(
              `APNs error for token ${deviceToken.token.slice(0, 8)}...: status=${status} body=${body}`,
            );
          }
        } catch (err) {
          console.error(
            `Network error sending to token ${deviceToken.token.slice(0, 8)}...:`,
            err,
          );
        }
      }

      // Update notification delivery status
      const newStatus = anySucceeded ? "sent" : "failed";
      await supabase
        .from("notifications")
        .update({
          delivery_status: newStatus,
          delivered_at: anySucceeded ? new Date().toISOString() : null,
        })
        .eq("id", notification.id);

      results.push({
        notification_id: notification.id,
        status: newStatus,
        tokens_attempted: tokensAttempted,
        tokens_succeeded: tokensSucceeded,
      });
    }

    const sent = results.filter((r) => r.status === "sent").length;
    const failed = results.filter((r) => r.status === "failed").length;
    console.log(`Batch complete: ${sent} sent, ${failed} failed`);

    return new Response(
      JSON.stringify({
        processed: results.length,
        sent,
        failed,
        results,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Unhandled error in send-push-notification:", err);
    return new Response(
      JSON.stringify({ error: "internal error", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
