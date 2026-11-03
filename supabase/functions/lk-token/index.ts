import { AccessToken } from "npm:livekit-server-sdk@2.9.2";
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: Record<string, unknown>, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" },
});

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (request.method !== "POST") return json({ error: "Use POST para entrar na sala." }, 405);

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return json({ error: "Entre na sua conta para usar a voz." }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !supabaseKey) return json({ error: "A função de voz está sem a configuração do Supabase." }, 503);

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) return json({ error: "Sua sessão expirou. Entre novamente." }, 401);

    let body: { channel_id?: unknown; peer_id?: unknown };
    try { body = await request.json(); }
    catch { return json({ error: "Envie um pedido válido." }, 400); }

    let roomName = "";
    if (typeof body.channel_id === "string" && uuid.test(body.channel_id)) {
      const { data: channel, error } = await supabase.from("channels").select("id,kind").eq("id", body.channel_id).single();
      if (error || !channel || channel.kind !== "voice") return json({ error: "Você não tem acesso a este canal de voz." }, 403);
      roomName = channel.id;
    } else if (typeof body.peer_id === "string" && uuid.test(body.peer_id) && body.peer_id !== user.id) {
      const peerId = body.peer_id;
      const { data: friendship, error } = await supabase.from("friendships").select("id")
        .eq("status", "accepted")
        .or(`and(sender_id.eq.${user.id},recipient_id.eq.${peerId}),and(sender_id.eq.${peerId},recipient_id.eq.${user.id})`)
        .maybeSingle();
      if (error || !friendship) return json({ error: "A chamada privada está disponível apenas entre amigos." }, 403);
      roomName = `dm-${[user.id, peerId].sort().join("-")}`;
    } else {
      return json({ error: "Selecione uma chamada válida." }, 400);
    }

    let key = Deno.env.get("LK_KEY");
    let secret = Deno.env.get("LK_SECRET");
    let url = Deno.env.get("LK_URL");

    // O Vault mantém a voz funcionando quando os segredos de ambiente ainda
    // não foram configurados no painel. Somente service_role pode ler a RPC.
    if (!key || !secret || !url) {
      const legacyServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
      let serviceKey = legacyServiceKey;
      if (!serviceKey) {
        try {
          serviceKey = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") || "{}").default;
        } catch { /* configuração padrão ausente */ }
      }
      if (serviceKey) {
        const admin = createClient(supabaseUrl, serviceKey, {
          auth: { persistSession: false, autoRefreshToken: false },
        });
        const { data: config } = await admin.rpc("roda_voice_config").single();
        key ||= config?.lk_key;
        secret ||= config?.lk_secret;
        url ||= config?.lk_url;
      }
    }
    if (!key || !secret || !url) return json({ error: "O servidor de voz ainda não foi configurado." }, 503);
    try { if (new URL(url).protocol !== "wss:") throw new Error(); }
    catch { return json({ error: "O endereço seguro do servidor de voz é inválido." }, 503); }

    const { data: profile } = await supabase.from("profiles").select("username").eq("id", user.id).single();
    const token = new AccessToken(key, secret, {
      identity: user.id,
      name: profile?.username || "Participante",
      ttl: "2h",
    });
    token.addGrant({ roomJoin: true, room: roomName, canPublish: true, canSubscribe: true });
    return json({ token: await token.toJwt(), url });
  } catch {
    return json({ error: "Não foi possível preparar a chamada. Tente novamente em instantes." }, 500);
  }
});
