import Image from "next/image";
import Link from "next/link";
import { WaitlistForm } from "./components/WaitlistForm";

const audiences = [
  ["01", "學生與面試者", "準備自我介紹、課堂報告，或把答案說得更有條理。"],
  ["02", "簡報者與講者", "在提案與公開發言前，先練出穩定、清楚的節奏。"],
  ["03", "雙語口說練習者", "用中文或英文，留意自己的贅字、語速與停頓。"],
];

const faqs = [
  ["支援哪些語言？", "第一版支援繁體中文與英文口說辨識；網站介面目前以繁體中文為主。"],
  ["需要開啟哪些權限？", "練習時需要麥克風與 Apple 語音辨識權限。你可以隨時在 iPhone 設定中撤回。"],
  ["為什麼有時候看不到「嗯」？", "Apple 可能為了讓文字更好讀而省略語氣聲。TalkFit 會另外保留 partial results 與候選辨識，作為贅字證據。"],
  ["錄音和逐字稿會上傳嗎？", "目前 TalkFit 沒有自有後端，不保存錄音或逐字稿；是否由裝置端辨識，仍取決於裝置與 Apple Speech 能力。"],
];

export default function Home() {
  return (
    <main id="main-content">
      <section className="hero shell">
        <div className="hero-copy">
          <p className="eyebrow"><span /> 一位安靜陪你開口的私人表達教練</p>
          <h1>找出最值得改善的<br /><em>一小段</em>，立即重練。</h1>
          <p className="hero-lead">
            錄下短講，TalkFit 會整理逐字稿、贅字與語速，把注意力留給最關鍵的一段。練完一次，你會清楚看見前後真的進步了。
          </p>
          <WaitlistForm location="hero" />
          <div className="trust-row" aria-label="測試計畫摘要">
            <span>TestFlight 表單展示</span>
            <span>目前不傳送 Email</span>
            <span>目前不儲存資料</span>
          </div>
        </div>
        <div className="hero-visual" aria-label="TalkFit App 前後比較畫面">
          <div className="note-card note-priority">
            <small>今天最重要的一件事</small>
            <strong>先少說兩個<br />「然後」</strong>
          </div>
          <div className="phone-frame hero-phone">
            <Image src="/app/comparison.png" alt="TalkFit 重練前後比較畫面" width={736} height={727} priority unoptimized />
          </div>
          <div className="growth-stamp"><b>−2</b><span>個贅字</span></div>
        </div>
      </section>

      <section className="problem-band">
        <div className="shell problem-grid">
          <p className="section-kicker">真正卡住的地方</p>
          <h2>知道自己講得不夠清楚，<br />卻不知道該先改哪裡。</h2>
          <p>TalkFit 不把你丟進一整頁分數。它只指出當下最值得練的一小段，給你一個具體提醒，然後讓你馬上再說一次。</p>
        </div>
      </section>

      <section className="journey shell" id="how-it-works">
        <div className="section-heading">
          <div><p className="section-kicker">2–3 分鐘的小練習</p><h2>讓表達像嫩芽一樣，<br />練一次、長一點。</h2></div>
          <p>不是一次改很多，而是每次都知道下一步。</p>
        </div>
        <ol className="journey-steps">
          <li><b>1</b><h3>錄下短講</h3><p>從 30 秒自我介紹、面試回答或簡報開場開始。</p></li>
          <li><b>2</b><h3>看見重點</h3><p>整理逐字稿、贅字、逐句語速與停頓節奏。</p></li>
          <li><b>3</b><h3>立即重練</h3><p>只重說最需要改善的一小段，不必整篇重來。</p></li>
          <li className="active"><b>4</b><h3>看見成長</h3><p>用前後比較，確認贅字更少、語速與節奏更穩。</p></li>
        </ol>
      </section>

      <section className="demo-section" id="demo">
        <div className="shell demo-grid">
          <div className="demo-copy">
            <p className="section-kicker light">一次小調整</p>
            <h2>不必一次改很多。<br />先把這一段說得更直接。</h2>
            <div className="quote-card">
              <span>原本</span>
              <p>「嗯，我最近和同學一起做校園服務的專題，然後也開始練習把想法說得更清楚。」</p>
            </div>
            <div className="metric-row">
              <div><strong>3 → 1</strong><span>贅字</span></div>
              <div><strong>182 → 156</strong><span>字／分鐘</span></div>
              <div><strong>64 → 82</strong><span>穩定度</span></div>
            </div>
          </div>
          <div className="demo-screens">
            <div className="phone-frame back-phone"><Image src="/app/report.png" alt="TalkFit 練習報告畫面" width={736} height={727} unoptimized /></div>
            <div className="phone-frame front-phone"><Image src="/app/retry.png" alt="TalkFit 立即重練畫面" width={736} height={727} unoptimized /></div>
          </div>
        </div>
      </section>

      <section className="audience shell" id="for-who">
        <div className="section-heading compact">
          <div><p className="section-kicker">適合願意再說一次的人</p><h2>把下一次重要的開口，<br />先留在一個安心的地方練習。</h2></div>
        </div>
        <div className="audience-grid">
          {audiences.map(([number, title, copy]) => <article key={number}><span>{number}</span><h3>{title}</h3><p>{copy}</p></article>)}
        </div>
        <p className="medical-note">TalkFit 目前是一般口說與表達練習工具，不提供醫療診斷、治療，也不能取代專業醫療服務。</p>
      </section>

      <section className="privacy-section" id="privacy">
        <div className="shell privacy-grid">
          <div className="privacy-mark"><Image src="/app-icon.png" alt="TalkFit App Icon" width={240} height={240} unoptimized /></div>
          <div>
            <p className="section-kicker light">你的聲音，先屬於你</p>
            <h2>練習需要安心，<br />不是更多資料蒐集。</h2>
            <p>TalkFit 目前沒有自有 App 後端，不保存錄音與逐字稿。只有在你主動開啟歷史時，才會在裝置上保留日期、語言與前後指標摘要。</p>
            <ul className="plain-list"><li>麥克風只用於當次練習</li><li>逐字稿交由 Apple Speech 產生</li><li>自訂贅字庫與歷史摘要留在裝置</li></ul>
            <Link className="text-link light-link" href="/privacy">閱讀完整隱私權政策 <span>→</span></Link>
          </div>
        </div>
      </section>

      <section className="faq shell" id="faq">
        <div className="section-heading compact"><div><p className="section-kicker">常見問題</p><h2>開始之前，<br />你可能想先知道。</h2></div></div>
        <div className="faq-list">
          {faqs.map(([question, answer]) => <details key={question}><summary>{question}<span>＋</span></summary><p>{answer}</p></details>)}
        </div>
        <Link className="text-link" href="/support">查看完整支援中心 <span>→</span></Link>
      </section>

      <section className="final-cta shell">
        <div>
          <p className="section-kicker">TestFlight 搶先測試</p>
          <h2>準備好下一次開口時，<br />候補名單也會正式開放。</h2>
          <p>目前可以體驗表單流程，輸入內容不會被傳送或儲存。</p>
        </div>
        <WaitlistForm location="footer" compact />
      </section>
    </main>
  );
}
