import type { Metadata } from "next";
import Link from "next/link";
import { LegalHero } from "../components/LegalHero";

export const metadata: Metadata = { title: "支援中心", description: "TalkFit 權限、語音辨識、贅字庫、本機歷史與 TestFlight 問題排解。" };

const faqs = [
  ["如何開啟麥克風與語音辨識權限？", "前往 iPhone「設定」→「隱私權與安全性」→「麥克風」或「語音辨識」，確認 TalkFit 已開啟。撤回權限後，App 仍會提供示範練習，不會卡住核心流程。"],
  ["辨識失敗時該怎麼做？", "先確認網路與權限，再回到首頁重新錄音。若 Apple Speech 暫時不可用，可主動選擇示範練習；TalkFit 不會把示範逐字稿冒充成你的真實內容。"],
  ["為什麼「嗯」「呃」可能沒有顯示？", "Apple 的最終逐字稿會偏向可讀性，有時省略短語氣聲。TalkFit 會分開保留 partial results、候選辨識與 segment 證據；捕捉到但未出現在正文的贅字，會列在聲音證據中。"],
  ["如何管理自己的贅字庫？", "在首頁的今日練習卡片中開啟贅字庫。中文與英文各有獨立預設，你可以新增口頭習慣、刪除不需要的詞，或還原預設。"],
  ["如何開啟或刪除本機歷史？", "完成真實練習並收下進步時，TalkFit 才會詢問是否開啟。之後可從首頁進入本機練習紀錄，停止新增、刪除單筆或清除全部。"],
  ["App 會保存錄音或逐字稿嗎？", "不會。TalkFit 目前沒有自有 App 後端，也不保存錄音與逐字稿。你主動開啟歷史時，只在裝置保留日期、語言與前後指標摘要。"],
];

export default function SupportPage() {
  return <main id="main-content">
    <LegalHero eyebrow="Support" title="取得協助" description="先從權限、語音辨識與本機紀錄開始排解。若仍有問題，可以帶著最少必要資訊到 GitHub 回報。" />
    <div className="shell content-layout">
      <aside className="side-nav"><b>支援目錄</b><a href="#quick">快速入口</a><a href="#requirements">系統需求</a><a href="#faq-support">常見問題</a><a href="#report">問題回報</a></aside>
      <div className="prose">
        <section id="quick"><h2>快速入口</h2><div className="support-grid">
          <article className="support-card"><h3>回報 TestFlight 問題</h3><p>請在 GitHub Issues 描述重現步驟，不要附上私人錄音或完整逐字稿。</p><a href="https://github.com/swiftruru/TalkFit/issues" target="_blank" rel="noreferrer">前往 GitHub Issues →</a></article>
          <article className="support-card"><h3>管理 Email</h3><p>候補名單尚未開放，網站目前不會傳送或儲存表單 Email。</p><Link href="/privacy-choices">查看隱私選擇展示 →</Link></article>
        </div><p className="notice">正式支援信箱會在 App Store 上架前啟用並公布。測試期間以 GitHub Issues 為主要聯絡入口；一般問題預計於 3–5 個工作天內回覆。</p></section>
        <section id="requirements"><h2>版本與系統需求</h2><ul><li>TalkFit 目前為 TestFlight 前的 iOS prototype。</li><li>基準裝置：iPhone 17 Pro。</li><li>最低需求：iOS 26.5 或更新版本。</li><li>真實練習需要可用的麥克風與 Apple Speech 服務。</li></ul></section>
        <section id="faq-support"><h2>常見問題</h2>{faqs.map(([q,a]) => <div key={q}><h3>{q}</h3><p>{a}</p></div>)}</section>
        <section id="report"><h2>回報問題時，請提供</h2><ul><li>iPhone 型號、iOS 版本與 TalkFit 版本。</li><li>練習語言：中文或英文。</li><li>問題發生前的操作步驟，以及能否穩定重現。</li><li>是否願意提供不含私人內容的畫面截圖。</li></ul><p className="notice">請不要寄送私人錄音、完整逐字稿、醫療資訊、密碼或其他敏感資料。</p></section>
        <p><Link className="text-link" href="/privacy">隱私權政策 →</Link>　<Link className="text-link" href="/terms">使用條款 →</Link></p>
      </div>
    </div>
  </main>;
}
