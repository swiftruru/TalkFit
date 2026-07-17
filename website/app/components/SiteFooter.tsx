import Image from "next/image";
import Link from "next/link";

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="shell footer-top">
        <div className="footer-brand"><Image src="/app-icon.png" alt="" width={56} height={56} unoptimized /><div><strong>TalkFit</strong><p>讓每一次開口，都成為看得見的成長。</p></div></div>
        <div className="footer-links">
          <div><b>產品</b><Link href="/#how-it-works">如何運作</Link><Link href="/#faq">常見問題</Link><Link href="/support">取得協助</Link></div>
          <div><b>政策</b><Link href="/privacy">隱私權政策</Link><Link href="/terms">使用條款</Link><Link href="/privacy-choices">隱私選擇</Link></div>
          <div><b>關注</b><a href="https://github.com/swiftruru/TalkFit" target="_blank" rel="noreferrer">GitHub</a><Link href="/#waitlist-hero">TestFlight 表單展示</Link></div>
        </div>
      </div>
      <div className="shell footer-bottom"><span>© 2026 TalkFit. All rights reserved.</span><span>為 iPhone 打造的一般口說練習工具</span></div>
    </footer>
  );
}
