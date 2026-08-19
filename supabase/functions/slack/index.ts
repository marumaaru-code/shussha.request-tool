// 出社管理ツール — Slack投稿用 Edge Function
// chat.postMessage でメッセージを送り、メッセージID(ts)を返す。thread_ts を渡すとスレッド返信になる。
// 必要な環境変数（Secrets）:
//   SLACK_BOT_TOKEN  … Slack Bot User OAuth Token（xoxb-… / スコープ chat:write）
//   SLACK_CHANNEL_ID … 投稿先チャンネルID（C… / Botを招待しておくこと）

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const { text, thread_ts } = await req.json();
    const token = Deno.env.get("SLACK_BOT_TOKEN");
    const channel = Deno.env.get("SLACK_CHANNEL_ID");
    if (!token || !channel) return json({ ok: false, error: "missing_config" }, 500);
    if (!text) return json({ ok: false, error: "no_text" }, 400);

    const body: Record<string, unknown> = { channel, text };
    if (thread_ts) body.thread_ts = thread_ts;

    const r = await fetch("https://slack.com/api/chat.postMessage", {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    });
    const data = await r.json();
    return json({ ok: data.ok, ts: data.ts, error: data.error });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
