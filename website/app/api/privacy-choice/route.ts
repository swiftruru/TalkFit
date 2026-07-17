const actions = new Set(["unsubscribe", "access", "correct", "delete"]);
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: Request) {
  const body = await request.json() as { email?: unknown; action?: unknown; company?: unknown };
  if (typeof body.company === "string" && body.company.trim()) return Response.json({ ok: true, demo: true });
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const action = typeof body.action === "string" ? body.action : "";
  if (!emailPattern.test(email) || email.length > 254) return Response.json({ error: "請輸入有效的 Email。" }, { status: 400 });
  if (!actions.has(action)) return Response.json({ error: "請選擇有效的隱私要求。" }, { status: 400 });
  return Response.json({ ok: true, demo: true, message: "展示完成；請求未傳送或儲存。" });
}
