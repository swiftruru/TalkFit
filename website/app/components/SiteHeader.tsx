import Image from "next/image";
import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="shell header-inner">
        <Link className="brand" href="/" aria-label="TalkFit 首頁">
          <Image src="/app-icon.png" alt="" width={44} height={44} unoptimized />
          <span><strong>TalkFit</strong><small>綠園練習簿</small></span>
        </Link>
        <nav aria-label="主要導覽">
          <Link href="/#how-it-works">如何運作</Link>
          <Link href="/#privacy">隱私</Link>
          <Link href="/support">支援</Link>
          <Link className="nav-cta" href="/#waitlist-hero">加入測試名單</Link>
        </nav>
      </div>
    </header>
  );
}
