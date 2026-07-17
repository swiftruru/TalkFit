import type { Metadata } from "next";
import { LegalHero } from "../components/LegalHero";

export const metadata: Metadata = { title: "使用條款", description: "TalkFit 官方網站、TestFlight 測試計畫與 App 使用條款。" };

export default function TermsPage() {
  return <main id="main-content">
    <LegalHero eyebrow="Terms" title="使用條款" description="這些條款說明 TalkFit 官方網站、表單展示與 Beta 測試計畫的使用範圍。" updated="2026 年 7 月 17 日" />
    <div className="shell content-layout">
      <aside className="side-nav"><b>條款目錄</b><a href="#scope">服務範圍</a><a href="#beta">Beta 測試</a><a href="#acceptable">可接受使用</a><a href="#health">非醫療聲明</a><a href="#liability">責任限制</a></aside>
      <article className="prose">
        <section><p className="notice">本頁是網站與 Beta 計畫的第一版條款草案，不取代 Apple 適用的標準 EULA。正式發布前應由法律專業人士依營運主體與上架地區確認。</p></section>
        <section id="scope"><h2>1. 服務範圍</h2><p>TalkFit 提供一般口說與表達練習工具、官方產品資訊、TestFlight 表單展示及支援內容。候補名單尚未正式開放；網站不是 Web 版 TalkFit，目前不提供會員帳號、雲端歷史同步或付費訂閱。</p></section>
        <section id="beta"><h2>2. TestFlight 與 Beta</h2><ul><li>目前表單為非持久化展示，輸入內容不會建立候補資格。</li><li>測試資格、功能、資料格式與可用性可能隨時變動、暫停或終止。</li><li>未來加入正式名單不保證一定取得邀請，也不代表正式服務承諾。</li><li>Beta 可能包含錯誤；請勿依賴它處理重要、緊急或不可替代的任務。</li></ul></section>
        <section id="acceptable"><h2>3. 可接受使用</h2><p>你不得濫用表單、繞過安全或頻率限制、干擾服務、嘗試未授權存取，或提交違法、侵權與惡意內容。違反時，TalkFit 可以停止處理請求或終止測試資格。</p></section>
        <section><h2>4. 智慧財產與回饋</h2><p>TalkFit 名稱、App、icon、網站視覺、文字與原始碼的權利，分別屬其權利人。你自願提供的產品回饋，可由 TalkFit 在不揭露你身分與私人內容的前提下，用於研究、改善與開發產品。</p></section>
        <section id="health"><h2>5. 非醫療聲明</h2><p>TalkFit 是一般口說與表達練習工具，不診斷、不治療任何疾病或狀況，不構成醫療建議，也不能取代語言治療師、醫師或其他專業人士。TalkFit 不是緊急服務。</p></section>
        <section><h2>6. Apple 與 TalkFit</h2><p>Apple 不是本網站或 TalkFit 測試計畫的營運者。TestFlight、App Store 與 Apple Speech 另受 Apple 條款與政策約束。TalkFit 對 Apple 服務的可用性或辨識結果不作保證。</p></section>
        <section id="liability"><h2>7. 可用性與責任限制</h2><p>在適用法律允許的最大範圍內，網站與 Beta 依現況提供，不保證不中斷、完全正確或適合特定目的。TalkFit 不對因使用或無法使用 Beta 造成的間接、附帶或衍生損失負責。</p></section>
        <section><h2>8. 終止、準據法與聯絡</h2><p>TalkFit 可以基於安全、法令、測試結束或條款違反而終止服務或資格。準據法與正式營運主體會在上架前補充。現階段可透過 <a href="https://github.com/swiftruru/TalkFit/issues" target="_blank" rel="noreferrer"><u>GitHub Issues</u></a> 聯絡。</p></section>
      </article>
    </div>
  </main>;
}
