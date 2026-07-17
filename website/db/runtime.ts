import { env } from "cloudflare:workers";

type DatabaseBinding = {
  prepare(query: string): {
    bind(...values: unknown[]): ReturnType<DatabaseBinding["prepare"]>;
    run(): Promise<unknown>;
    first<T>(): Promise<T | null>;
  };
  batch(statements: unknown[]): Promise<unknown>;
};

export function getDatabase() {
  const db = (env as unknown as { DB?: DatabaseBinding }).DB;
  if (!db) throw new Error("D1 binding DB is unavailable");
  return db;
}

export async function ensureDatabase() {
  const db = getDatabase();
  await db.batch([
    db.prepare(`CREATE TABLE IF NOT EXISTS waitlist_entries (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL DEFAULT 'pending',
      source TEXT NOT NULL DEFAULT 'website',
      consent_at INTEGER NOT NULL,
      confirmation_token_hash TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS privacy_requests (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      action TEXT NOT NULL,
      note TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at INTEGER NOT NULL
    )`),
    db.prepare(`CREATE TABLE IF NOT EXISTS rate_limits (
      fingerprint TEXT NOT NULL,
      window_start INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 1,
      UNIQUE(fingerprint, window_start)
    )`),
  ]);
  return db;
}

export async function hashValue(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function enforceRateLimit(request: Request, scope: string, limit = 5) {
  const db = await ensureDatabase();
  const address = request.headers.get("cf-connecting-ip") ?? request.headers.get("x-forwarded-for")?.split(",")[0] ?? "local";
  const fingerprint = await hashValue(`${scope}:${address}`);
  const windowStart = Math.floor(Date.now() / 3_600_000) * 3_600_000;
  await db.prepare("INSERT INTO rate_limits (fingerprint, window_start, attempts) VALUES (?, ?, 1) ON CONFLICT(fingerprint, window_start) DO UPDATE SET attempts = attempts + 1").bind(fingerprint, windowStart).run();
  const row = await db.prepare("SELECT attempts FROM rate_limits WHERE fingerprint = ? AND window_start = ?").bind(fingerprint, windowStart).first<{ attempts: number }>();
  if ((row?.attempts ?? 0) > limit) throw new Error("RATE_LIMITED");
  return db;
}
