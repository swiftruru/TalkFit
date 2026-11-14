// README 的小徽章：小綠綠配色（制服綠、薄荷、粉紅、奶油黃、金髮色，深褐描邊）的 SVG，
// 放在 repo 裡，不連外部的徽章服務。
// 改了文字或數字後手動重產：node docs/readme/make-badges.mjs（輸出到 docs/readme/badges/）。
// 文字寬度用估的（widthOf），再用 textLength 釘住，各平台的字型不同也不會跑出框。
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = join(dirname(fileURLToPath(import.meta.url)), 'badges');
const INK = '#5A3A2A';
const PAPER = '#FFFBF2';
const THEMES = {
  uniform: { fill: '#1F6B45', text: '#FFF7E6' }, // 制服的綠
  mint: { fill: '#BFEFD6', text: '#1F6E52' }, // 髮梢的薄荷
  pink: { fill: '#FBD3D6', text: '#A8463A' }, // 髮梢的粉紅
  cream: { fill: '#FBE7A8', text: '#7A5A12' }, // 音符與星星的黃
  blonde: { fill: '#F6DDB0', text: '#7A4E1E' }, // 馬尾的金
};
// 12x12 的小圖示，原點在左上
const ICONS = {
  heart: (c) => `<path d="M6 10.6 1.9 6.6a2.6 2.6 0 0 1 3.7-3.7L6 3.3l.4-.4a2.6 2.6 0 0 1 3.7 3.7Z" fill="${c}"/>`,
  sparkle: (c) => `<path d="M6 .6 7.4 4.6 11.4 6 7.4 7.4 6 11.4 4.6 7.4.6 6 4.6 4.6Z" fill="${c}"/>`,
  sprout: (c) => `<path d="M6 11V6.2M6 6.4C6 3.8 4.2 2.4 1.6 2.6 1.6 5 3.4 6.6 6 6.4ZM6 5.2c0-2 1.6-3.4 4.4-3.2 0 2.2-1.8 3.6-4.4 3.2Z" fill="none" stroke="${c}" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>`,
  note: (c) => `<path d="M4.6 9V2.6l5-1.2v6" fill="none" stroke="${c}" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/><ellipse cx="3.2" cy="9.2" rx="1.9" ry="1.5" fill="${c}"/><ellipse cx="8.2" cy="7.6" rx="1.9" ry="1.5" fill="${c}"/>`,
  mic: (c) => `<rect x="4.2" y="1" width="3.6" height="6.2" rx="1.8" fill="${c}"/><path d="M2.4 5.8a3.6 3.6 0 0 0 7.2 0M6 9.4V11M4.2 11h3.6" fill="none" stroke="${c}" stroke-width="1.2" stroke-linecap="round"/>`,
  wave: (c) => `<path d="M1.4 5v2M3.7 3v6M6 1.4v9.2M8.3 3.4v5.2M10.6 5v2" fill="none" stroke="${c}" stroke-width="1.4" stroke-linecap="round"/>`,
  lock: (c) => `<path d="M3.8 5.4V4a2.2 2.2 0 0 1 4.4 0v1.4" fill="none" stroke="${c}" stroke-width="1.3" stroke-linecap="round"/><rect x="2.4" y="5.4" width="7.2" height="5.4" rx="1.4" fill="${c}"/>`,
  // 小綠綠：金色的頭髮、側邊的馬尾、瞇起來笑的眼睛
  girl: (c) => `<circle cx="9.9" cy="4" r="2" fill="#F2C766" stroke="${c}" stroke-width=".9"/><circle cx="5.6" cy="6.4" r="4.6" fill="#F2C766" stroke="${c}" stroke-width=".9"/><path d="M2.6 6.6a3 3.4 0 0 0 6 0c0-.5-.1-1-.3-1.4-1.9.3-3.7-.1-5.3-1.2-.3.8-.4 1.6-.4 2.6Z" fill="#FFE9D6"/><path d="M3.5 6.9q.7-.8 1.4 0M6.3 6.9q.7-.8 1.4 0" fill="none" stroke="${c}" stroke-width=".7" stroke-linecap="round"/><circle cx="3.6" cy="8" r=".55" fill="#F6A6A6"/><circle cx="7.6" cy="8" r=".55" fill="#F6A6A6"/>`,
};

/** 估字寬：中日韓字與全形符號 12px；拉丁字母與數字一般約 6.8px、大寫約 7.8px，粗體（標籤）各加 0.9px */
const CJK = /[⺀-鿿＀-￯]/;
const widthOf = (s, bold = false) =>
  [...s].reduce((w, ch) => {
    if (CJK.test(ch)) return w + 12;
    if (ch === ' ') return w + 3.8;
    if (ch === '・' || ch === '·') return w + 6;
    return w + (/[A-Z]/.test(ch) ? 7.8 : 6.8) + (bold ? 0.9 : 0);
  }, 0);
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

function badge({ icon, theme, label, value }) {
  const t = THEMES[theme];
  const lw = Math.round(widthOf(label, true));
  const vw = Math.round(widthOf(value));
  const left = 10 + 12 + 5 + lw + 8;
  const W = left + 9 + vw + 12;
  const H = 26;
  const font = `font-family="Verdana,'PingFang TC','Noto Sans TC','Microsoft JhengHei',sans-serif" font-size="12"`;
  const title = `${esc(label)}：${esc(value)}`;
  // girl 圖示自帶顏色，描邊一律用深褐
  const iconColor = icon === 'girl' ? INK : t.text;
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-label="${title}"><title>${title}</title>` +
    `<clipPath id="p"><rect x="1" y="1" width="${W - 2}" height="${H - 2}" rx="12"/></clipPath>` +
    `<g clip-path="url(#p)"><rect width="${W}" height="${H}" fill="${PAPER}"/><rect width="${left}" height="${H}" fill="${t.fill}"/></g>` +
    `<rect x="1" y="1" width="${W - 2}" height="${H - 2}" rx="12" fill="none" stroke="${INK}" stroke-width="1.4"/>` +
    `<g transform="translate(10 7)">${ICONS[icon](iconColor)}</g>` +
    `<text x="27" y="17.2" ${font} font-weight="700" fill="${t.text}" textLength="${lw}" lengthAdjust="spacingAndGlyphs">${esc(label)}</text>` +
    `<text x="${left + 9}" y="17.2" ${font} fill="${INK}" textLength="${vw}" lengthAdjust="spacingAndGlyphs">${esc(value)}</text>` +
    `</svg>`
  );
}

// 檔名相同的一組中文、一組英文（README.md 用 zh-*，README.en.md 用 en-*）
const BADGES = [
  ['site', 'sprout', 'uniform', ['綠園練習簿', '開放中'], ['TalkFit', 'open']],
  ['ios', 'sparkle', 'cream', ['iOS', '26.5+'], ['iOS', '26.5+']],
  ['bilingual', 'heart', 'pink', ['口說', '中文 + English'], ['Speak in', '中文 + English']],
  ['privacy', 'lock', 'mint', ['隱私', '只留在這台 iPhone'], ['Privacy', 'stays on this iPhone']],
  ['contexts', 'note', 'cream', ['情境', '4 種 + 自己的講稿'], ['Scenes', '4 + your own script']],
  ['fillers', 'wave', 'pink', ['贅字', '文字與語氣聲'], ['Fillers', 'words and sounds']],
  ['pace', 'sparkle', 'mint', ['語速', '逐句與即時'], ['Pace', 'per sentence, live']],
  ['retry', 'mic', 'uniform', ['重練', '只練一小段'], ['Retry', 'one small part']],
  ['tests', 'sparkle', 'blonde', ['測試', '61 個通過'], ['Tests', '61 passing']],
  ['swift', 'sparkle', 'blonde', ['Swift', '5'], ['Swift', '5']],
  ['swiftui', 'sparkle', 'blonde', ['SwiftUI', 'Observation'], ['SwiftUI', 'Observation']],
  ['speech', 'mic', 'blonde', ['Apple Speech', '裝置端優先'], ['Apple Speech', 'on-device first']],
  ['swiftdata', 'sparkle', 'blonde', ['SwiftData', '本機紀錄'], ['SwiftData', 'local records']],
  ['charts', 'sparkle', 'blonde', ['Swift Charts', '成長趨勢'], ['Swift Charts', 'growth trends']],
  ['workers', 'sparkle', 'blonde', ['Cloudflare', 'Workers'], ['Cloudflare', 'Workers']],
  ['love', 'heart', 'pink', ['用心手作', '在台灣'], ['Made with care', 'in Taiwan']],
  ['authors', 'girl', 'mint', ['作者', '潘昱如・蔡宜潔・白謹瑜'], ['Authors', '潘昱如・蔡宜潔・白謹瑜']],
];

mkdirSync(OUT, { recursive: true });
for (const [name, icon, theme, zh, en] of BADGES) {
  writeFileSync(join(OUT, `zh-${name}.svg`), badge({ icon, theme, label: zh[0], value: zh[1] }));
  writeFileSync(join(OUT, `en-${name}.svg`), badge({ icon, theme, label: en[0], value: en[1] }));
}
console.log(`${BADGES.length * 2} 個徽章寫到 ${OUT}`);
