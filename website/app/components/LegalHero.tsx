export function LegalHero({ eyebrow, title, description, updated }: { eyebrow: string; title: string; description: string; updated?: string }) {
  return (
    <section className="legal-hero shell">
      <p className="eyebrow"><span /> {eyebrow}</p>
      <h1>{title}</h1>
      <p>{description}</p>
      {updated && <div className="legal-meta"><span>生效日：2026 年 7 月 17 日</span><span>最後更新：{updated}</span></div>}
    </section>
  );
}
