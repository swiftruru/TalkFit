import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const root = new URL("../", import.meta.url);

async function source(path) {
  return readFile(new URL(path, root), "utf8");
}

test("ships the TalkFit product promise and both waitlist calls to action", async () => {
  const [page, form, layout] = await Promise.all([
    source("app/page.tsx"),
    source("app/components/WaitlistForm.tsx"),
    source("app/layout.tsx"),
  ]);

  assert.match(page, /找出最值得改善/);
  assert.match(page, /立即重練/);
  assert.match(page, /location="hero"/);
  assert.match(page, /location="footer"/);
  assert.match(form, /加入 TalkFit 測試名單/);
  assert.match(form, /type="email"/);
  assert.match(form, /type="checkbox" required/);
  assert.match(layout, /lang="zh-Hant"/);
  assert.doesNotMatch(page, /SkeletonPreview|codex-preview/);
});

test("includes App Store support, policy, and privacy-choice routes", async () => {
  const routes = [
    "app/support/page.tsx",
    "app/privacy/page.tsx",
    "app/terms/page.tsx",
    "app/thank-you/page.tsx",
    "app/privacy-choices/page.tsx",
  ];

  await Promise.all(routes.map((route) => access(new URL(route, root))));
  const [support, privacy, terms] = await Promise.all(routes.slice(0, 3).map(source));
  assert.match(support, /GitHub Issues/);
  assert.match(privacy, /不保存錄音/);
  assert.match(privacy, /不保存逐字稿/);
  assert.match(terms, /非醫療聲明/);
});

test("keeps waitlist persistence server-side and rate limited", async () => {
  const [hosting, schema, route, runtime] = await Promise.all([
    source(".openai/hosting.json"),
    source("db/schema.ts"),
    source("app/api/waitlist/route.ts"),
    source("db/runtime.ts"),
  ]);

  assert.match(hosting, /"d1": "DB"/);
  assert.match(schema, /waitlist_entries/);
  assert.match(schema, /privacy_requests/);
  assert.match(route, /WAITLIST_WEBHOOK_URL/);
  assert.match(route, /confirmationTokenHash|confirmation_token_hash/);
  assert.match(runtime, /rate_limits/);
  assert.doesNotMatch(route, /localStorage|sessionStorage/);
});

test("bundles the real brand and product visuals", async () => {
  await Promise.all([
    access(new URL("public/app-icon.png", root)),
    access(new URL("public/favicon.ico", root)),
    access(new URL("public/favicon-16x16.png", root)),
    access(new URL("public/favicon-32x32.png", root)),
    access(new URL("public/favicon-48x48.png", root)),
    access(new URL("public/apple-touch-icon.png", root)),
    access(new URL("public/icon-192.png", root)),
    access(new URL("public/icon-512.png", root)),
    access(new URL("app/manifest.ts", root)),
    access(new URL("public/paper-background.png", root)),
    access(new URL("public/app/home.png", root)),
    access(new URL("public/app/report.png", root)),
    access(new URL("public/app/comparison.png", root)),
    access(new URL("public/og.png", root)),
  ]);
});

test("declares browser, Apple, manifest, and social icons", async () => {
  const [layout, manifest] = await Promise.all([
    source("app/layout.tsx"),
    source("app/manifest.ts"),
  ]);

  assert.match(layout, /favicon\.ico/);
  assert.match(layout, /apple-touch-icon\.png/);
  assert.match(layout, /manifest\.webmanifest/);
  assert.match(layout, /msapplication-TileImage/);
  assert.match(layout, /summary_large_image/);
  assert.match(manifest, /icon-192\.png/);
  assert.match(manifest, /icon-512\.png/);
  assert.match(manifest, /purpose: "maskable"/);
});
