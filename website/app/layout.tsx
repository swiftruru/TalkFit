import type { Metadata, Viewport } from "next";
import { SiteFooter } from "./components/SiteFooter";
import { SiteHeader } from "./components/SiteHeader";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://talkfit-garden.swiftruru.chatgpt.site"),
  title: {
    default: "TalkFit｜讓每一次開口，都成為看得見的成長",
    template: "%s｜TalkFit",
  },
  description:
    "TalkFit 會找出最值得改善的一小段，讓你立即重練，並清楚看見前後真的進步了。查看 iPhone TestFlight 表單展示。",
  applicationName: "TalkFit",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: [
      { url: "/favicon.ico", type: "image/x-icon" },
      { url: "/favicon-16x16.png", sizes: "16x16", type: "image/png" },
      { url: "/favicon-32x32.png", sizes: "32x32", type: "image/png" },
      { url: "/favicon-48x48.png", sizes: "48x48", type: "image/png" },
    ],
    shortcut: "/favicon.ico",
    apple: [{ url: "/apple-touch-icon.png", sizes: "180x180", type: "image/png" }],
  },
  appleWebApp: {
    capable: true,
    title: "TalkFit",
    statusBarStyle: "default",
  },
  openGraph: {
    title: "TalkFit｜找出最值得改善的一小段，立即重練",
    description: "一位安靜陪你開口的私人表達教練。",
    type: "website",
    locale: "zh_TW",
    images: [{ url: "/og.png", width: 1200, height: 630 }],
  },
  twitter: {
    card: "summary_large_image",
    title: "TalkFit｜找出最值得改善的一小段，立即重練",
    description: "一位安靜陪你開口的私人表達教練。",
    images: ["/og.png"],
  },
  other: {
    "msapplication-TileColor": "#f4f0e5",
    "msapplication-TileImage": "/mstile-150x150.png",
  },
};

export const viewport: Viewport = {
  themeColor: "#f4f0e5",
  colorScheme: "light",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-Hant">
      <body>
        <a className="skip-link" href="#main-content">跳到主要內容</a>
        <SiteHeader />
        {children}
        <SiteFooter />
      </body>
    </html>
  );
}
