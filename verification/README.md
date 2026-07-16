# TalkFit MVP Verification Evidence

Environment: iPhone 17 Pro Simulator, iOS 26.5, Xcode 26.6. The app was built and launched with XcodeBuildMCP. Every visual listed below was captured from the live Simulator stream in the Codex in-app browser through `serve-sim`.

## Major states

1. `01-home-browser.png` — fixed prompt, growth summary, lightweight history, primary and demo actions.
2. `02-recording-browser.png` — first-practice timer, waveform, prompt, and stop action.
3. `03-analysis-browser.png` — polished analysis transition.
4. `04-report-browser.png` — priority-first report, highlighted transcript, pace, filler count, and stability.
5. `05-retry-browser.png` — selected excerpt and one concrete coaching cue.
6. `06-retry-recording-browser.png` — focused second recording.
7. `07-comparison-browser.png` — visible before/after improvement.
8. `08-fallback-recording-browser.png` — denied/unavailable recognition automatically switches to a coherent sample result without removing the stop action.
9. `09-real-route-browser.png` — microphone and Speech permissions were requested and accepted; the iOS Simulator still reported recognition unavailable and the app correctly used its fallback.

## Interaction run

`首頁 → 示範練習 → 首次錄音 → 分析 → 回饋 → 選取最重要片段 → 重練提示 → 第二次錄音 → 前後比較 → 回到首頁`

Observed deterministic comparison:

- 贅字：4 個 → 0 個
- 語速：130 → 131 字／分鐘
- 穩定度：49% → 81%

The microphone and Apple Speech permission prompts both appeared and were accepted. Because speech recognition remained unavailable in this Simulator runtime, real Traditional Chinese transcription could not be validated here; the implementation contains the real AVAudioEngine + SFSpeechRecognizer path and is intended for final confirmation on physical hardware.
