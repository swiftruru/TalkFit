import { integer, sqliteTable, text, uniqueIndex } from "drizzle-orm/sqlite-core";

export const waitlistEntries = sqliteTable("waitlist_entries", {
  id: text("id").primaryKey(),
  email: text("email").notNull(),
  status: text("status").notNull().default("pending"),
  source: text("source").notNull().default("website"),
  consentAt: integer("consent_at").notNull(),
  confirmationTokenHash: text("confirmation_token_hash"),
  createdAt: integer("created_at").notNull(),
  updatedAt: integer("updated_at").notNull(),
}, (table) => [uniqueIndex("waitlist_email_unique").on(table.email)]);

export const privacyRequests = sqliteTable("privacy_requests", {
  id: text("id").primaryKey(),
  email: text("email").notNull(),
  action: text("action").notNull(),
  note: text("note"),
  status: text("status").notNull().default("pending"),
  createdAt: integer("created_at").notNull(),
});

export const rateLimits = sqliteTable("rate_limits", {
  fingerprint: text("fingerprint").notNull(),
  windowStart: integer("window_start").notNull(),
  attempts: integer("attempts").notNull().default(1),
}, (table) => [uniqueIndex("rate_limit_window_unique").on(table.fingerprint, table.windowStart)]);
