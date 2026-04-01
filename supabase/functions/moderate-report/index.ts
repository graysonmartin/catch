// moderate-report/index.ts
// Supabase Edge Function: admin moderation for encounter reports (MBA-218)
//
// Usage (from Supabase dashboard or curl):
//   POST /functions/v1/moderate-report
//   Authorization: Bearer <service_role_key>
//   Body: { "reportId": "<uuid>", "action": "dismiss|hide_content|warn_user|suspend_user", "adminNotes": "..." }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const VALID_ACTIONS = ["dismiss", "hide_content", "warn_user", "suspend_user"] as const;
type AdminAction = (typeof VALID_ACTIONS)[number];

interface ModerationRequest {
  reportId: string;
  action: AdminAction;
  adminNotes?: string;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let body: ModerationRequest;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const { reportId, action, adminNotes } = body;

  if (!reportId || !action) {
    return jsonError("reportId and action are required", 400);
  }

  if (!VALID_ACTIONS.includes(action)) {
    return jsonError(`Invalid action. Must be one of: ${VALID_ACTIONS.join(", ")}`, 400);
  }

  // Fetch the report
  const { data: report, error: fetchError } = await supabase
    .from("encounter_reports")
    .select("*")
    .eq("id", reportId)
    .single();

  if (fetchError || !report) {
    return jsonError("Report not found", 404);
  }

  // Determine new status
  const newStatus = action === "dismiss" ? "dismissed" : "resolved";

  // Update the report
  const { error: updateError } = await supabase
    .from("encounter_reports")
    .update({
      status: newStatus,
      admin_action: action,
      admin_notes: adminNotes ?? "",
      resolved_at: new Date().toISOString(),
    })
    .eq("id", reportId);

  if (updateError) {
    return jsonError(`Failed to update report: ${updateError.message}`, 500);
  }

  // Execute action-specific side effects
  switch (action) {
    case "hide_content": {
      // Hide the encounter from all users by inserting into hidden_encounters
      // for the reporter (already done client-side), but we can also mark it
      // in a way that the auto-hide trigger handles. For now, update all
      // pending reports for this encounter.
      await supabase
        .from("encounter_reports")
        .update({
          status: "resolved",
          admin_action: "hide_content",
          admin_notes: adminNotes ?? "content hidden by admin",
          resolved_at: new Date().toISOString(),
        })
        .eq("encounter_id", report.encounter_id)
        .eq("status", "pending");
      break;
    }

    case "suspend_user": {
      // Get the encounter owner and suspend them
      const { data: encounter } = await supabase
        .from("encounters")
        .select("owner_id")
        .eq("id", report.encounter_id)
        .single();

      if (encounter) {
        await supabase
          .from("profiles")
          .update({ is_suspended: true })
          .eq("id", encounter.owner_id);
      }
      break;
    }

    case "warn_user":
      // For v1, just resolving the report with the warn action is sufficient.
      // A future iteration could send a push notification to the warned user.
      break;

    case "dismiss":
      // No side effects — just marks the report as dismissed.
      break;
  }

  return new Response(
    JSON.stringify({
      success: true,
      reportId,
      action,
      newStatus,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
