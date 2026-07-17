import type { Metadata } from "next";
import Link from "next/link";
import { LegalHero } from "../components/LegalHero";

export const metadata: Metadata = { title: "隱私權政策", description: "TalkFit App 與官方網站的隱私權政策。" };

export default function PrivacyPage() {
  return <main id="main-content">
    <LegalHero eyebrow="Privacy" title="隱私權政策" description="TalkFit 以資料最小化為原則。本政策分別說明 iOS App 與官方網站會如何處理資料。" updated="2026 年 7 月 17 日" />
    <div className="shell content-layout">
      <aside className="side-nav"><b>政策目錄</b><a href="#app">TalkFit App</a><a href="#website">官方網站</a><a href="#rights">你的選擇</a><a href="#children">年齡</a><a href="#changes">政策更新</a></aside>
      <article className="prose">
        <section><p className="notice">這是第一版產品政策草案，用來如實對應目前的 App 與測試名單設計；正式公開上架前，仍應由熟悉實際營運地區的法律專業人士確認。</p></section>
        <section id="app"><h2>TalkFit App</h2><h3>麥克風與語音辨識</h3><p>麥克風只用於當次練習。TalkFit 使用 Apple Speech 產生逐字稿；是否完全在裝置端辨識，取決於裝置、語言與 Apple Speech 當下能力。你可以在 iPhone 設定中隨時撤回麥克風與語音辨識權限。</p><h3>TalkFit 不保存的內容</h3><ul><li>不保存錄音。</li><li>不保存逐字稿。</li><li>目前沒有 TalkFit 自有 App 後端。</li></ul><h3>選擇開啟的本機資料</h3><p>只有在你主動開啟歷史時，TalkFit 才會在裝置保存完成日期、練習語言、題目識別，以及重練前後的贅字、語速、穩定度與節奏提醒摘要。自訂贅字庫同樣保存在裝置。你可以在 App 內刪除單筆、清除全部或關閉後續紀錄。</p></section>
        <section id="website"><h2>TalkFit 官方網站</h2><h3>TestFlight 表單展示</h3><p>候補名單尚未正式開放。首頁與隱私選擇頁的表單只用於展示介面流程；輸入的 Email、選項與說明不會送出瀏覽器，也不會被 TalkFit 儲存或用於寄信。</p><h3>安全與技術資料</h3><p>網站託管供應商可能處理 IP 位址、請求時間與基本安全日誌。TalkFit 目前未啟用網站表單資料庫、Email 寄送服務或表單頻率識別。</p><h3>Cookie 與分析</h3><p>第一版不使用廣告追蹤、不建立跨網站個人輪廓，也不預設加入產品行銷郵件。目前不使用網站 Analytics；若未來啟用，會先更新本政策並採最小化設定。</p><h3>保存期間</h3><p>因目前不收集候補名單或隱私表單內容，TalkFit 沒有這些表單資料的保存期間。託管安全日誌仍依供應商的必要安全週期處理。</p></section>
        <section id="rights"><h2>你的選擇與權利</h2><p>目前沒有網站候補名單資料可供查詢、更正或刪除。正式收集前，TalkFit 會先公開聯絡與隱私請求流程。</p><Link className="text-link" href="/privacy-choices">查看隱私選擇展示 →</Link></section>
        <section id="children"><h2>年齡與未成年人</h2><p>目前網站表單不會收集任何年齡使用者的 Email。未來若正式進入校園或未成年市場，會另行設計家長同意與兒少隱私流程。</p></section>
        <section id="changes"><h2>政策更新與聯絡</h2><p>若資料處理、供應商或功能有實質變更，我們會更新頁首日期並以適當方式通知測試者。正式支援與隱私聯絡信箱會在 App Store 上架前啟用；目前可透過 <a href="https://github.com/swiftruru/TalkFit/issues" target="_blank" rel="noreferrer"><u>GitHub Issues</u></a> 聯絡。</p></section>
      </article>
    </div>
  </main>;
}
