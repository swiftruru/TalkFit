const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: Request) {
  const body = await request.json() as { email?: unknown; consent?: unknown; company?: unknown };
  if (typeof body.company === "string" && body.company.trim()) return Response.json({ ok: true, demo: true });
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  if (!emailPattern.test(email) || email.length > 254) return Response.json({ error: "請輸入有效的 Email。" }, { status: 400 });
  if (body.consent !== true) return Response.json({ error: "請確認這是不會傳送或儲存資料的展示表單。" }, { status: 400 });
  return Response.json({ ok: true, demo: true, message: "展示完成；Email 未傳送或儲存。" });
}
