"use client";

import { FormEvent, useState } from "react";
import { LegalHero } from "../components/LegalHero";

export default function PrivacyChoicesPage() {
  const [state, setState] = useState<"idle" | "done">("idle");
  const [message, setMessage] = useState("");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    event.currentTarget.reset();
    setState("done");
    setMessage("展示完成：這項要求沒有被傳送或儲存。");
  }

  return <main id="main-content">
    <LegalHero eyebrow="Privacy choices" title="管理你的隱私選擇" description="目前為展示頁面，不會傳送或儲存 Email 與隱私要求。" />
    <div className="shell content-layout">
      <aside className="side-nav"><b>資料選擇</b><a href="#request">提出要求</a><a href="#process">處理方式</a></aside>
      <div className="prose">
        <section id="request"><h2>提出要求</h2><p>這個表單目前只用於展示流程。輸入內容不會離開瀏覽器，也不會送到 TalkFit。</p>
          <form className="choices-form" onSubmit={submit}>
            <div className="field"><label htmlFor="choice-email">Email</label><input id="choice-email" name="email" type="email" autoComplete="email" required /></div>
            <div className="field"><label htmlFor="choice-action">我想要</label><select id="choice-action" name="action" required defaultValue="unsubscribe"><option value="unsubscribe">取消測試通知</option><option value="access">查詢我的候補名單資料</option><option value="correct">更正 Email</option><option value="delete">刪除候補名單 Email</option></select></div>
            <div className="field"><label htmlFor="choice-note">補充說明（選填）</label><textarea id="choice-note" name="note" maxLength={500} /></div>
            <input className="honeypot" name="company" tabIndex={-1} autoComplete="off" aria-hidden="true" />
            <button type="submit">模擬送出隱私要求</button>
            {state === "done" && <p className="success-box" role="status">{message}</p>}
          </form>
        </section>
        <section id="process"><h2>處理方式</h2><p>正式收集候補名單前，會先啟用隱私聯絡信箱、請求驗證與資料刪除流程。目前沒有網站候補名單資料可供查詢或刪除。</p></section>
      </div>
    </div>
  </main>;
}
