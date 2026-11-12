import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const allowedOrigin = "https://honoriowork.github.io";
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function response(origin: string, status: number, body: Record<string, unknown>) {
  return new Response(status === 204 ? null : JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": origin,
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Vary": "Origin",
    },
  });
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((item) => item.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin") ?? "";
  if (req.method === "OPTIONS") {
    return origin === allowedOrigin
      ? response(origin, 204, {})
      : response(allowedOrigin, 403, { code: "origin_not_allowed" });
  }
  if (req.method !== "POST") return response(allowedOrigin, 405, { code: "method_not_allowed" });
  if (origin !== allowedOrigin) return response(allowedOrigin, 403, { code: "origin_not_allowed" });
  if (!supabaseUrl || !serviceKey) return response(origin, 503, { code: "service_unavailable" });

  let input: Record<string, unknown>;
  try {
    const raw = await req.text();
    if (raw.length > 4096) return response(origin, 413, { code: "request_too_large" });
    input = JSON.parse(raw);
  } catch {
    return response(origin, 400, { code: "invalid_request" });
  }

  const email = String(input.email ?? "").trim().toLowerCase();
  const password = String(input.password ?? "");
  const username = String(input.username ?? "").trim().normalize("NFC");
  const inviteCode = String(input.inviteCode ?? "").trim().toLowerCase();

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) {
    return response(origin, 400, { code: "invalid_email" });
  }
  const passwordBytes = new TextEncoder().encode(password).length;
  if (password.length < 8 || passwordBytes > 72) {
    return response(origin, 400, { code: "invalid_password" });
  }
  if (username.length < 1 || username.length > 40 || /[\u0000-\u001f\u007f]/.test(username)) {
    return response(origin, 400, { code: "invalid_username" });
  }
  if (!/^[a-z0-9]{10}$/.test(inviteCode)) {
    return response(origin, 403, { code: "invalid_invite" });
  }

  const adminHeaders = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
  };

  const serverUrl = new URL(`${supabaseUrl}/rest/v1/servers`);
  serverUrl.searchParams.set("select", "id");
  serverUrl.searchParams.set("invite_code", `eq.${inviteCode}`);
  serverUrl.searchParams.set("limit", "1");
  const serverResult = await fetch(serverUrl, { headers: adminHeaders });
  const servers = serverResult.ok ? await serverResult.json() : [];
  if (!Array.isArray(servers) || servers.length === 0) {
    return response(origin, 403, { code: "invalid_invite" });
  }

  const inviteHash = await sha256(inviteCode);
  const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const usageUrl = new URL(`${supabaseUrl}/rest/v1/signup_invite_usage`);
  usageUrl.searchParams.set("select", "id");
  usageUrl.searchParams.set("invite_hash", `eq.${inviteHash}`);
  usageUrl.searchParams.set("attempted_at", `gte.${since}`);
  usageUrl.searchParams.set("limit", "20");
  const usageResult = await fetch(usageUrl, { headers: adminHeaders });
  const recent = usageResult.ok ? await usageResult.json() : null;
  if (!Array.isArray(recent)) return response(origin, 503, { code: "service_unavailable" });
  if (recent.length >= 20) return response(origin, 429, { code: "invite_rate_limit" });

  const registerUsage = await fetch(`${supabaseUrl}/rest/v1/signup_invite_usage`, {
    method: "POST",
    headers: { ...adminHeaders, Prefer: "return=minimal" },
    body: JSON.stringify({ invite_hash: inviteHash }),
  });
  if (!registerUsage.ok) return response(origin, 503, { code: "service_unavailable" });

  const createResult = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
    method: "POST",
    headers: adminHeaders,
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        username,
        roda_signup_source: "server_invite",
        roda_email_verification_pending: true,
      },
    }),
  });
  const created = await createResult.json().catch(() => ({}));
  if (!createResult.ok) {
    const detail = String(created?.msg ?? created?.message ?? created?.error ?? "");
    if (/already|registered|exists/i.test(detail)) {
      return response(origin, 409, { code: "email_exists" });
    }
    return response(origin, 400, { code: "signup_failed" });
  }

  return response(origin, 201, { ok: true });
});
