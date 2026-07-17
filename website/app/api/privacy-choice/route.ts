import { enforceRateLimit } from "../../../db/runtime";

const actions = new Set(["unsubscribe", "access", "correct", "delete"]);
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: Request) {
  try {
    const body = await request.json() as { email?: unknown; action?: unknown; note?: unknown; company?: unknown };
    if (typeof body.company === "string" && body.company.trim()) return Response.json({ ok: true });
    const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
    const action = typeof body.action === "string" ? body.action : "";
    const note = typeof body.note === "string" ? body.note.trim().slice(0, 500) : "";
    if (!emailPattern.test(email) || email.length > 254) return Response.json({ error: "請輸入有效的 Email。" }, { status: 400 });
    if (!actions.has(action)) return Response.json({ error: "請選擇有效的隱私要求。" }, { status: 400 });
    const db = await enforceRateLimit(request, "privacy-choice", 3);
    await db.prepare("INSERT INTO privacy_requests (id, email, action, note, status, created_at) VALUES (?, ?, ?, ?, 'pending', ?)").bind(crypto.randomUUID(), email, action, note || null, Date.now()).run();
    return Response.json({ ok: true });
  } catch (error) {
    if (error instanceof Error && error.message === "RATE_LIMITED") return Response.json({ error: "送出次數太多，請稍後再試。" }, { status: 429 });
    console.error("privacy request failed", error);
    return Response.json({ error: "目前無法送出，請稍後再試。" }, { status: 500 });
  }
}
