import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = { title: "已加入測試名單", robots: { index: false, follow: false } };

export default function ThankYouPage() {
  return <main id="main-content" className="thank-you shell"><div className="thank-you-card"><Image src="/app-icon.png" alt="TalkFit App Icon" width={224} height={224} /><p className="section-kicker">已記進練習名單</p><h1>謝謝你，願意陪 TalkFit 長大。</h1><p>準備好 TestFlight 邀請時，我們會寄信通知你。如果沒有立刻收到確認信，不需要重複登記；正式寄信服務啟用後會再完成確認。</p><Link className="button-link" href="/">回到 TalkFit 首頁</Link></div></main>;
}
