import AppKit
import Foundation

struct Promo {
    let index: Int
    let source: String
    let output: String
    let chapter: String
    let headline: String
    let subhead: String
}

let promos = [
    Promo(index: 1, source: "01-home.jpg", output: "01-home.png", chapter: "選一個情境",
          headline: "從一次重要的開口，\n開始練習", subhead: "中文、英文、面試、簡報與完整講稿都能練"),
    Promo(index: 2, source: "02-recording.jpg", output: "02-recording.png", chapter: "看見當下節奏",
          headline: "開口時，就知道\n自己的節奏", subhead: "即時逐字稿、贅字證據與逐句語速一起出現"),
    Promo(index: 3, source: "03-report.jpg", output: "03-report.png", chapter: "只改最關鍵處",
          headline: "不必重說整篇，\n先改最關鍵的一段", subhead: "TalkFit 找出可改善片段，給你一個具體提醒"),
    Promo(index: 4, source: "05-comparison.jpg", output: "04-comparison.png", chapter: "看見真的進步",
          headline: "進步不是感覺，\n前後清楚看見", subhead: "比較贅字、語速與穩定度的真實改變"),
    Promo(index: 5, source: "06-history.jpg", output: "05-history.png", chapter: "只留在這台 iPhone",
          headline: "想回聽的練習，\n由你決定保存", subhead: "短講與完整講稿分開整理，不保存逐字稿與講稿")
]

let size = NSSize(width: 1290, height: 2796)
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let promoRoot = root.appendingPathComponent("verification/scc-promo-v2")
let rawRoot = promoRoot.appendingPathComponent("raw")
let finalRoot = promoRoot.appendingPathComponent("final")
let paperURL = root.appendingPathComponent("TalkFit/Assets.xcassets/PaperBackground.imageset/paper-background.png")
let iconURL = root.appendingPathComponent("TalkFit/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

guard let paper = NSImage(contentsOf: paperURL), let icon = NSImage(contentsOf: iconURL) else {
    fatalError("TalkFit brand assets are missing")
}
try FileManager.default.createDirectory(at: finalRoot, withIntermediateDirectories: true)

func topRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: size.height - y - height, width: width, height: height)
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor, lineSpacing: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = lineSpacing
    NSAttributedString(string: text, attributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]).draw(in: rect)
}

func drawRoundedImage(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

let headlineFont = NSFont(name: "PingFangTC-Semibold", size: 78)
    ?? NSFont.systemFont(ofSize: 78, weight: .semibold)
let subheadFont = NSFont(name: "PingFangTC-Regular", size: 38)
    ?? NSFont.systemFont(ofSize: 38)

for promo in promos {
    guard let screenshot = NSImage(contentsOf: rawRoot.appendingPathComponent(promo.source)) else {
        fatalError("Missing source screenshot: \(promo.source)")
    }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fatalError("Could not create bitmap") }

    bitmap.size = size
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    paper.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
    color(0xFFF9EC, alpha: 0.18).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

    color(0x9DBA74, alpha: 0.11).setFill()
    NSBezierPath(ovalIn: topRect(915, -100, 510, 510)).fill()
    color(0xB65B32, alpha: 0.055).setFill()
    NSBezierPath(ovalIn: topRect(-180, 420, 520, 520)).fill()

    drawRoundedImage(icon, in: topRect(94, 98, 84, 84), radius: 20)
    drawText("TalkFit", in: topRect(205, 111, 240, 48),
             font: .systemFont(ofSize: 33, weight: .semibold), color: color(0x174C35))

    let chapterRect = topRect(820, 108, 376, 62)
    color(0xE8EAD6, alpha: 0.92).setFill()
    NSBezierPath(roundedRect: chapterRect, xRadius: 31, yRadius: 31).fill()
    drawText(String(format: "%02d · %@", promo.index, promo.chapter),
             in: topRect(850, 120, 330, 38), font: .systemFont(ofSize: 26, weight: .medium),
             color: color(0x55744B))

    drawText(promo.headline, in: topRect(94, 245, 1102, 235),
             font: headlineFont, color: color(0x174C35), lineSpacing: 10)
    drawText(promo.subhead, in: topRect(98, 520, 1094, 85),
             font: subheadFont, color: color(0x5B7567), lineSpacing: 5)

    color(0xB65B32).setFill()
    NSBezierPath(roundedRect: topRect(98, 642, 112, 8), xRadius: 4, yRadius: 4).fill()
    color(0x7A9562, alpha: 0.36).setFill()
    NSBezierPath(roundedRect: topRect(222, 642, 62, 8), xRadius: 4, yRadius: 4).fill()

    let frame = topRect(179, 735, 932, 1986)
    let shadow = NSShadow()
    shadow.shadowColor = color(0x173526, alpha: 0.28)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()
    color(0x161B18).setFill()
    NSBezierPath(roundedRect: frame, xRadius: 112, yRadius: 112).fill()
    NSShadow().set()

    let border = NSBezierPath(roundedRect: frame, xRadius: 112, yRadius: 112)
    color(0x6F746F, alpha: 0.65).setStroke()
    border.lineWidth = 4
    border.stroke()

    let screen = topRect(213, 769, 864, 1878)
    drawRoundedImage(screenshot, in: screen, radius: 79)
    let screenBorder = NSBezierPath(roundedRect: screen, xRadius: 79, yRadius: 79)
    color(0xFFFFFF, alpha: 0.16).setStroke()
    screenBorder.lineWidth = 3
    screenBorder.stroke()

    color(0xB65B32).setFill()
    NSBezierPath(roundedRect: topRect(575, 2671, 140, 9), xRadius: 5, yRadius: 5).fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.82]) else {
        fatalError("Could not encode PNG")
    }
    let outputURL = finalRoot.appendingPathComponent(promo.output)
    try png.write(to: outputURL)
    print(outputURL.path)
}
