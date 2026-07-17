# TalkFit 官方網站

TalkFit 官方產品網站、TestFlight 測試名單，以及 App Store 所需的支援、隱私權政策與使用條款頁面。

## 本機開發

```bash
npm install
npm run dev
```

網站使用 vinext／Next.js、TypeScript 與 Cloudflare D1。`DB` 綁定保存 TestFlight 候補名單與隱私要求；不保存 App 錄音或逐字稿。

## 環境變數

- `WAITLIST_WEBHOOK_URL`（選填）：接收 `{ email, confirmUrl, template }` 的伺服器端寄信 webhook。未設定時，名單仍會以 `pending` 狀態保存在 D1，正式寄信服務啟用後再完成確認。
- `TALKFIT_D1_DATABASE_ID`（Cloudflare 直接部署必填）：同一個 Cloudflare account 內的 D1 database UUID。
- `TALKFIT_D1_DATABASE_NAME`（選填）：D1 database 名稱，預設為 `site-creator-d1`。

## Cloudflare Workers 部署

這是 vinext full-stack Worker，不應使用舊的 `@cloudflare/next-on-pages`。Cloudflare Workers Builds 請設定：

- Root directory：`website`
- Production branch：`main`
- Build command：留空
- Deploy command：`npx vinext deploy`

首次部署前，先在同一個 Cloudflare account 建立 D1：

```bash
npx wrangler d1 create site-creator-d1
```

將指令回傳的 `database_id` 存成 Workers Builds 的 `TALKFIT_D1_DATABASE_ID` 環境變數，然後套用初始 schema：

```bash
npx wrangler d1 execute site-creator-d1 --remote --file drizzle/0000_amazing_rocket_racer.sql
```

請勿把 Cloudflare API token 放進 repository。D1 database ID 不是密碼，但本專案仍以 build environment variable 管理，避免將部署 account 與原始碼綁死。

## 路由

- `/`：產品 Landing Page 與 Email CTA
- `/support`：支援中心
- `/privacy`：隱私權政策草案
- `/terms`：使用條款草案
- `/thank-you`：候補名單完成頁
- `/privacy-choices`：取消通知與資料請求

正式上架前，請設定自有網域、支援／隱私聯絡信箱、Email 供應商，並由法律專業人士確認政策內容。
