# TalkFit 官方網站

TalkFit 官方產品網站、TestFlight 表單展示，以及 App Store 所需的支援、隱私權政策與使用條款頁面。

## 本機開發

```bash
npm install
npm run dev
```

網站使用 vinext／Next.js 與 TypeScript。目前所有表單都是非持久化展示，不傳送、儲存 Email 或隱私要求，因此不需要 Cloudflare D1。

## 環境變數

- 目前部署不需要任何表單、Email 或 D1 環境變數。
- `TALKFIT_D1_DATABASE_ID`（未來選填）：只有重新啟用真實表單後，才會將 `DB` 綁定到指定的 D1 UUID。
- `TALKFIT_D1_DATABASE_NAME`（未來選填）：D1 database 名稱，預設為 `site-creator-d1`。

## Cloudflare Workers 部署

這是 vinext full-stack Worker，不應使用舊的 `@cloudflare/next-on-pages`。Cloudflare Workers Builds 請設定：

- Root directory：`website`
- Production branch：`main`
- Build command：留空
- Deploy command：`npx vinext deploy`

不設定 `TALKFIT_D1_DATABASE_ID` 時，建置產物不會宣告 D1 binding，可直接部署。請勿把 Cloudflare API token 放進 repository。

## 路由

- `/`：產品 Landing Page 與非持久化表單展示
- `/support`：支援中心
- `/privacy`：隱私權政策草案
- `/terms`：使用條款草案
- `/thank-you`：表單展示完成頁
- `/privacy-choices`：隱私選擇表單展示

正式收集候補名單或上架前，請設定自有網域、支援／隱私聯絡信箱、資料儲存與 Email 供應商，並由法律專業人士確認政策內容。
