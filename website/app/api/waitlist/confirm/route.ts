import { ensureDatabase, hashValue } from "../../../../db/runtime";

export async function GET(request: Request) {
  const token = new URL(request.url).searchParams.get("token") ?? "";
  if (token.length < 20) return Response.redirect(new URL("/thank-you?confirmation=invalid", request.url));
  const db = await ensureDatabase();
  const tokenHash = await hashValue(token);
  await db.prepare("UPDATE waitlist_entries SET status = 'confirmed', confirmation_token_hash = NULL, updated_at = ? WHERE confirmation_token_hash = ?").bind(Date.now(), tokenHash).run();
  return Response.redirect(new URL("/thank-you?confirmation=confirmed", request.url));
}
