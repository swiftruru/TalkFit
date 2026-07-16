# TalkFit 全流程版面稽核

日期：2026-07-16

裝置：iPhone 17 Pro Simulator（iOS 26.5）

顯示方式：serve-sim in-app browser

## 根因與修正

- 原本的紙張背景使用 `scaledToFill`，但沒有被限制在容器尺寸內，會參與外層 `ZStack` 的理想尺寸計算；內容因此被撐寬後再由螢幕裁切，22pt 的程式邊距視覺上只剩很薄一圈。
- `PaperBackground` 現在由 `GeometryReader` 明確限制為可用畫面大小，並在該範圍內裁切。
- 全 App 統一使用 26pt 頁面 gutter、20pt 卡片內距、24pt 卡片圓角與共用底部操作列。
- 首頁、錄音、分析、報告、重練、重練錄音與比較畫面皆已逐頁檢查左右邊距、卡片內距、底部安全區與文字換行。

## 視覺證據

- `before-home.png`：修正前首頁
- `after-home.png`：修正後首頁
- `after-recording.png`：第一次錄音
- `after-analysis.png`：分析過場
- `after-report.png`：練習報告
- `after-retry.png`：重練準備
- `after-retry-recording.png`：重練錄音
- `after-comparison.png`：前後比較

## 結果

- 所有主要內容均落在一致的安全 gutter 內。
- 卡片內容與外框之間保有明確呼吸空間。
- 底部主要操作不再貼近螢幕邊緣，且與內容區由細分隔線及材質層區分。
- 長逐字稿與比較內容保留可捲動行為；固定 CTA 不遮斷核心資訊。
- 專案已在指定 Simulator 建置、安裝並完成示範 happy path。
