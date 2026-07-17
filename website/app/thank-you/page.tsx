import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = { title: "表單展示完成", robots: { index: false, follow: false } };

export default function ThankYouPage() {
  return <main id="main-content" className="thank-you shell"><div className="thank-you-card"><Image src="/app-icon.png" alt="TalkFit App Icon" width={224} height={224} unoptimized /><p className="section-kicker">表單展示完成</p><h1>謝謝你，願意陪 TalkFit 長大。</h1><p>目前候補名單尚未開放，這次輸入的 Email 沒有被傳送、儲存或用於寄信。</p><Link className="button-link" href="/">回到 TalkFit 首頁</Link></div></main>;
}
