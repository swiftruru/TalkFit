"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";

export function WaitlistForm({ location, compact = false }: { location: string; compact?: boolean }) {
  const [status, setStatus] = useState<"idle" | "done">("idle");

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    event.currentTarget.reset();
    setStatus("done");
  }

  return (
    <form className={`waitlist-form ${compact ? "compact" : ""}`} id={`waitlist-${location}`} onSubmit={submit}>
      <div className="form-line">
        <label className="sr-only" htmlFor={`email-${location}`}>Email</label>
        <input id={`email-${location}`} name="email" type="email" inputMode="email" autoComplete="email" placeholder="你的 Email" required />
        <input className="honeypot" name="company" tabIndex={-1} autoComplete="off" aria-hidden="true" />
        <button type="submit">模擬加入 TalkFit 測試名單</button>
      </div>
      <label className="consent"><input name="consent" type="checkbox" required /><span>我知道這是展示用表單，目前不會傳送、儲存 Email 或寄送 TestFlight 通知。詳情請見 <Link href="/privacy">隱私權政策</Link>。</span></label>
      {status === "done" && <p className="success-box" role="status">展示完成：這個 Email 沒有被傳送或儲存。</p>}
    </form>
  );
}
