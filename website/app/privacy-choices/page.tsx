"use client";

import { FormEvent, useState } from "react";
import { LegalHero } from "../components/LegalHero";

export default function PrivacyChoicesPage() {
  const [state, setState] = useState<"idle" | "sending" | "done" | "error">("idle");
  const [message, setMessage] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setState("sending");
    const form = new FormData(event.currentTarget);
    const response = await fetch("/api/privacy-choice", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ email: form.get("email"), action: form.get("action"), note: form.get("note"), company: form.get("company") }) });
    const data = await response.json().catch(() => ({}));
    if (response.ok) { setState("done"); setMessage("已收到你的要求。我們會先確認 Email 關係，再完成處理。"); event.currentTarget.reset(); }
    else { setState("error"); setMessage(data.error ?? "目前無法送出，請稍後再試。"); }
  }

  return <main id="main-content">
    <LegalHero eyebrow="Privacy choices" title="管理你的隱私選擇" description="取消 TestFlight 通知，或提出查詢、更正與刪除候補名單 Email 的要求。" />
    <div className="shell content-layout">
      <aside className="side-nav"><b>資料選擇</b><a href="#request">提出要求</a><a href="#process">處理方式</a></aside>
      <div className="prose">
        <section id="request"><h2>提出要求</h2><p>請使用當初登記候補名單的 Email。我們不會透過這個表單要求密碼、錄音、逐字稿或醫療資料。</p>
          <form className="choices-form" onSubmit={submit}>
            <div className="field"><label htmlFor="choice-email">Email</label><input id="choice-email" name="email" type="email" autoComplete="email" required /></div>
            <div className="field"><label htmlFor="choice-action">我想要</label><select id="choice-action" name="action" required defaultValue="unsubscribe"><option value="unsubscribe">取消測試通知</option><option value="access">查詢我的候補名單資料</option><option value="correct">更正 Email</option><option value="delete">刪除候補名單 Email</option></select></div>
            <div className="field"><label htmlFor="choice-note">補充說明（選填）</label><textarea id="choice-note" name="note" maxLength={500} /></div>
            <input className="honeypot" name="company" tabIndex={-1} autoComplete="off" aria-hidden="true" />
            <button type="submit" disabled={state === "sending"}>{state === "sending" ? "正在送出…" : "送出隱私要求"}</button>
            {(state === "done" || state === "error") && <p className={state === "done" ? "success-box" : "form-error"} role="status">{message}</p>}
          </form>
        </section>
        <section id="process"><h2>處理方式</h2><p>為避免他人冒用你的 Email 提出刪除，我們會先驗證請求，再處理不可逆變更。正式隱私聯絡信箱與驗證郵件會在 App Store 上架前啟用。</p></section>
      </div>
    </div>
  </main>;
}
