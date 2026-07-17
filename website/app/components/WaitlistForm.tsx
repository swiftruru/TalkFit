"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";

export function WaitlistForm({ location, compact = false }: { location: string; compact?: boolean }) {
  const [status, setStatus] = useState<"idle" | "submitting" | "error">("idle");
  const [message, setMessage] = useState("");

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus("submitting");
    setMessage("");
    const form = new FormData(event.currentTarget);
    const response = await fetch("/api/waitlist", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        email: form.get("email"),
        consent: form.get("consent") === "on",
        company: form.get("company"),
        source: location,
      }),
    });
    if (response.ok) {
      window.location.assign("/thank-you");
      return;
    }
    const data = await response.json().catch(() => ({}));
    setStatus("error");
    setMessage(data.error ?? "目前無法送出，請稍後再試一次。");
  }

  return (
    <form className={`waitlist-form ${compact ? "compact" : ""}`} id={`waitlist-${location}`} onSubmit={submit}>
      <div className="form-line">
        <label className="sr-only" htmlFor={`email-${location}`}>Email</label>
        <input id={`email-${location}`} name="email" type="email" inputMode="email" autoComplete="email" placeholder="你的 Email" required />
        <input className="honeypot" name="company" tabIndex={-1} autoComplete="off" aria-hidden="true" />
        <button type="submit" disabled={status === "submitting"}>{status === "submitting" ? "正在記下…" : "加入 TalkFit 測試名單"}</button>
      </div>
      <label className="consent"><input name="consent" type="checkbox" required /><span>我已滿 18 歲，並同意 TalkFit 使用我的 Email 寄送 TestFlight 邀請與測試相關通知。我可以隨時取消，詳情請見 <Link href="/privacy">隱私權政策</Link>。</span></label>
      {status === "error" && <p className="form-error" role="alert">{message}</p>}
    </form>
  );
}
