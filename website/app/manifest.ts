import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "TalkFit｜綠園練習簿",
    short_name: "TalkFit",
    description: "找出最值得改善的一小段，立即重練，清楚看見前後進步。",
    start_url: "/",
    display: "standalone",
    background_color: "#f4f0e5",
    theme_color: "#f4f0e5",
    lang: "zh-Hant",
    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
