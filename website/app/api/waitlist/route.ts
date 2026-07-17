import { env } from "cloudflare:workers";
import { enforceRateLimit, hashValue } from "../../../db/runtime";

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: Request) {
  try {
    const body = await request.json() as { email?: unknown; consent?: unknown; company?: unknown; source?: unknown };
    if (typeof body.company === "string" && body.company.trim()) return Response.json({ ok: true });
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    if (!emailPattern.test(email) || email.length > 254) return Response.json({ error: "請輸入有效的 Email。" }, { status: 400 });
    if (body.consent !== true) return Response.json({ error: "請確認年齡與測試通知同意聲明。" }, { status: 400 });
    const db = await enforceRateLimit(request, "waitlist", 5);
    const now = Date.now();
    const token = crypto.randomUUID() + crypto.randomUUID();
    const tokenHash = await hashValue(token);
    const source = typeof body.source === "string" ? body.source.slice(0, 40) : "website";
    await db.prepare("INSERT INTO waitlist_entries (id, email, status, source, consent_at, confirmation_token_hash, created_at, updated_at) VALUES (?, ?, 'pending', ?, ?, ?, ?, ?) ON CONFLICT(email) DO UPDATE SET consent_at = excluded.consent_at, source = excluded.source, confirmation_token_hash = excluded.confirmation_token_hash, updated_at = excluded.updated_at").bind(crypto.randomUUID(), email, source, now, tokenHash, now, now).run();

    const webhook = (env as unknown as { WAITLIST_WEBHOOK_URL?: string }).WAITLIST_WEBHOOK_URL;
    if (webhook) {
      const confirmUrl = new URL(`/api/waitlist/confirm?token=${encodeURIComponent(token)}`, request.url).toString();
      await fetch(webhook, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ email, confirmUrl, template: "talkfit-waitlist-confirm" }) });
    }
    return Response.json({ ok: true });
  } catch (error) {
    if (error instanceof Error && error.message === "RATE_LIMITED") return Response.json({ error: "送出次數太多，請稍後再試。" }, { status: 429 });
    console.error("waitlist submission failed", error);
    return Response.json({ error: "目前無法送出，請稍後再試一次。" }, { status: 500 });
  }
}
