這個網站的第一版應定位成「TalkFit 官方產品網站＋TestFlight 測試名單＋App Store 必備支援頁面」，不是 Web 版 TalkFit，也暫時不需要會員系統。

## 1. 目標使用者

主要使用者：

- 需要準備課堂報告、自我介紹或面試回答的學生。
- 經常簡報、提案或公開發言的上班族與講者。
- 想改善贅字、語速、停頓與表達清晰度的人。
- 希望練習中文或英文口說的 iPhone 使用者。
- 願意加入 TestFlight、提供真機辨識回饋的早期測試者。

次要使用者：

- 教師、口語教練與簡報教練。
- 語言治療、正音治療相關專業人士。

醫療／語言治療目前只能作為未來研究方向，網站不可宣稱 TalkFit 能診斷、治療或取代專業醫療服務。第一版應定位為「一般口說與表達練習工具」。

為降低 Email 蒐集與未成年人同意的複雜度，第一階段測試名單建議限定 18 歲以上；若日後正式進入校園或未成年市場，再另行設計家長同意與兒少隱私規則。

## 2. 網站目的

網站需要在約 10 秒內讓訪客理解：

> TalkFit 會找出最值得改善的一小段，讓你立即重練，並看見前後真的進步了。

具體目的：

1. 清楚展示 TalkFit 的核心價值與差異。
2. 呈現「錄音 → 找出重點 → 立即重練 → 前後比較」的完整體驗。
3. 建立對麥克風、逐字稿與隱私處理的信任。
4. 收集有意願參與 TestFlight 的 Email。
5. 上架後作為 App Store 的 Marketing URL。
6. 提供穩定的 Support、Privacy Policy 與 Terms 網址。
7. 未來加入正式的 App Store 下載按鈕與版本公告。

暫時不做：

- 網頁版錄音分析
- 登入與會員中心
- 雲端歷史同步
- 付費訂閱
- 部落格或大型內容平台
- 醫療功能宣稱

## 3. 主要 CTA：收集測試名單 Email

主要 CTA 建議統一使用：

> 加入 TalkFit 測試名單

輔助說明：

> 搶先參與 iPhone TestFlight 測試，幫助 TalkFit 在不同聲音、口音與環境中變得更可靠。

首頁第一屏與頁尾各放一次相同 CTA。

表單第一階段只需要：

- Email：必填
- 同意聲明：必填
- 使用情境、中文／英文、學生／工作者等問卷：提交成功後再選填

建議同意文字：

> 我同意 TalkFit 使用我的 Email 寄送 TestFlight 邀請與測試相關通知。我可以隨時取消，詳情請見隱私權政策。

送出後顯示：

> 已經把你記進練習名單。準備好邀請時，我們會寄信通知你。

需要具備：

- Email 格式驗證
- Double opt-in 或確認信
- 防機器人與頻率限制
- 取消訂閱方式
- 刪除 Email 的聯絡入口
- 不在前端暴露寄信服務或資料庫金鑰
- 不預設勾選額外行銷信件

## 4. 首頁內容架構

建議依序呈現：

1. Hero  
   App Icon、產品名稱、核心承諾、Email CTA，以及一張最有代表性的 App 畫面。

2. 真正的問題  
   「知道自己講得不夠清楚，卻不知道先改哪裡。」

3. TalkFit 如何協助  
   錄下短講、找出最重要片段、立即重練、比較前後。

4. 最有記憶點的 Demo  
   以前後對照呈現贅字下降、語速更穩、停頓改善。

5. 適合誰  
   學生、面試者、簡報者、雙語口說練習者。

6. 隱私與安心感  
   本機優先、不保存錄音與逐字稿、Apple 原生語音辨識、歷史摘要由使用者選擇是否保存。

7. FAQ  
   支援語言、需要什麼權限、為什麼可能辨識不到「嗯」、資料是否上傳、如何加入測試。

8. 最終 CTA  
   再次收集 Email。

9. Footer  
   Support、Privacy Policy、Terms、GitHub、聯絡方式與版權資訊。

## 5. 網站需要的頁面

| 網址 | 用途 | App Store 對應 |
|---|---|---|
| `/` | 品牌 Landing Page、產品介紹、Email CTA | Marketing URL |
| `/support` | FAQ、版本資訊、聯絡方式與問題回報 | Support URL |
| `/privacy` | App 與網站的完整隱私權政策 | Privacy Policy URL |
| `/terms` | 網站、測試計畫與 App 使用條款 | 公開 Terms 頁面 |
| `/thank-you` | Email 登記成功與選填問卷 | 不需填入 App Store |
| `/privacy-choices` | 取消訂閱、查詢或刪除 Email | 可作為 User Privacy Choices URL |

Apple 要求 App Store 的 Support URL 提供容易找到的聯絡方式，也要求所有 App 提供 Privacy Policy URL；隱私政策連結還必須在 App 內容易存取。[Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)、[App Store Connect：Manage App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)

因此網站完成後，TalkFit App 內也需要在適當位置加入「隱私權政策」「使用條款」「取得協助」連結，只有網站存在還不夠。

## 6. 應使用的現有資訊與檔案

品牌主素材：

- [正式 App Icon](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/TalkFit/Assets.xcassets/AppIcon.appiconset/AppIcon.png)
- [纖維紙張背景](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/TalkFit/Assets.xcassets/PaperBackground.imageset/paper-background.png)
- [產品與品牌說明](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/README.md)
- [後續產品規劃](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/TODO.md)

推薦公開展示的畫面：

- [首頁](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/verification/padding-audit/after-home.png)
- [錄音畫面](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/verification/padding-audit/after-recording.png)
- [練習報告](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/verification/padding-audit/after-report.png)
- [立即重練](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/verification/padding-audit/after-retry.png)
- [前後比較](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/verification/padding-audit/after-comparison.png)

設計參考：

- [綠園 moodboard](/Users/ruru/Documents/RuData/Devs/AppDevs/TalkFit/design%20reference/Generated%20image%203.png)

Moodboard 應作為色彩、紙張、植物與排版參考，不建議整張直接放上網站。網站應延續米白纖維紙、松綠、苔綠、嫩芽與少量陶土橘，但版面仍要保持清楚、快速且符合 Web 無障礙需求。

## 7. Support 頁面

Support 頁面至少包含：

- 支援信箱，例如未來的 `support@自有網域`
- 目前 App 版本與最低 iOS 需求
- 麥克風及 Speech 權限設定方式
- 語音辨識失敗時如何重新錄音
- 為什麼「嗯」「呃」可能未出現在 Apple 最終逐字稿
- 如何管理贅字庫
- 如何開啟、刪除或關閉本機歷史
- App 是否保存錄音與逐字稿
- TestFlight 問題回報格式
- 預計回覆時間，例如 3–5 個工作天
- Privacy Policy 與 Terms 連結

建議問題回報時只要求：

- iPhone 型號
- iOS 版本
- TalkFit 版本
- 練習語言
- 問題發生步驟
- 是否願意提供截圖

不要要求使用者寄送私人錄音或完整逐字稿。

## 8. Privacy Policy

隱私權政策要分成「TalkFit App」與「TalkFit 網站」兩部分。

App 部分應如實說明：

- 麥克風只用於當次練習。
- Apple Speech 用於產生逐字稿。
- 是否在裝置端辨識取決於裝置與 Apple Speech 能力。
- TalkFit 不保存錄音。
- TalkFit 不保存逐字稿。
- 使用者選擇開啟歷史時，只在裝置保存日期、語言與前後指標摘要。
- 自訂贅字庫保存在裝置。
- App 目前沒有 TalkFit 自有後端。
- 權限如何撤回。
- 本機紀錄如何刪除。

網站部分應說明：

- 收集 Email 的目的：TestFlight 邀請與測試通知。
- 選填問卷會收集哪些資訊。
- Vercel、Email 服務、資料庫與防垃圾服務等供應商。
- 伺服器可能產生的 IP、時間與安全日誌。
- 是否使用 Analytics、Cookie 或追蹤技術。
- 保存期限。
- 取消訂閱、查詢、更正與刪除方式。
- 聯絡信箱。
- 政策生效日與最後更新日。

Apple 也要求 App Store Connect 的 App Privacy 回答必須包含 App 與整合的第三方 SDK 實際資料處理情況，且需持續保持正確。[Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

## 9. Terms 頁面

Terms 建議包含：

- TalkFit 與網站服務範圍
- TestFlight／Beta 功能可能變動或中止
- 使用者需具備的年齡與同意資格
- 禁止濫用、干擾服務與未授權內容
- 品牌、icon、網站與 App 的智慧財產權
- 使用者回饋的使用授權
- 服務可用性不保證
- 帳號與測試資格終止
- 責任限制
- 準據法與聯絡方式
- 非醫療診斷、治療或緊急服務聲明
- Apple 與 TalkFit 的責任界線

Apple 已提供適用於所有地區的標準 EULA；若沒有在 App Store Connect 提交自訂 EULA，就會套用 Apple 標準版本。因此網站 Terms 可先處理網站與 Beta 關係，不必立刻取代 Apple EULA。[Apple：Provide a Custom License Agreement](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement)

正式發布前，Privacy Policy 與 Terms 仍應由熟悉實際上架地區的法律專業人士確認。

## 10. Vercel 部署規劃

之後建議採用：

- Next.js＋TypeScript
- GitHub Repo 自動部署至 Vercel
- Pull Request 使用 Preview Deployment
- `main` 對應 Production
- 正式自有網域
- 穩定且不可任意更換的 `/support`、`/privacy`、`/terms`
- Email、資料庫與防垃圾服務金鑰放在 Vercel Environment Variables
- Production 與 Preview 使用不同資料來源，避免測試 Email 污染正式名單
- 自動產生 sitemap、robots.txt、Open Graph 圖片與網站 icon
- HTTPS、表單頻率限制與基本安全標頭

Vercel 本身區分 Local、Preview 與 Production 環境，各環境可以有不同的變數與部署流程。[Vercel Environments](https://vercel.com/docs/deployments/environments)

## 開始設計前還需要決定

- 正式網域
- 開發者／營運主體名稱
- Support 與 Privacy 聯絡信箱
- Email 名單服務或資料庫
- 是否寄送產品行銷更新，或只寄 TestFlight 通知
- 是否使用網站 Analytics
- 測試者最低年齡與開放地區
- 中文網站是否同步提供英文版本
- TestFlight Public Link 或人工分批邀請
- Email 與候補名單的保存期限

推薦第一版採「繁體中文主站＋預留英文版」，先專注台灣的學生、簡報者與雙語口說練習者。網站的真正成功標準不是內容很多，而是讓訪客理解 TalkFit、信任隱私設計，並願意留下 Email。
