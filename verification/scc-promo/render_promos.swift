import AppKit
import Foundation

struct Promo {
    let index: Int
    let slug: String
    let headline: String
    let subhead: String
}

let promos = [
    Promo(index: 1, slug: "home", headline: "把下一次重要的開口，\n先練一次", subhead: "中文、英文與四種情境，從 30 秒開始"),
    Promo(index: 2, slug: "recording", headline: "開口時，就知道\n自己的節奏", subhead: "即時逐字稿、音量與逐句語速一起陪你"),
    Promo(index: 3, slug: "report", headline: "不用改整篇，先找出\n最關鍵的一段", subhead: "看見贅字、語速、停頓與優先改善片段"),
    Promo(index: 4, slug: "retry", headline: "只重練最值得改善的\n一小段", subhead: "帶著一個具體提醒，立刻再說一次"),
    Promo(index: 5, slug: "comparison", headline: "進步不是感覺，\n前後清楚看見", subhead: "比較贅字、語速與穩定度的真實改變")
]

let canvasSize = NSSize(width: 1290, height: 2796)
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let promoRoot = root.appendingPathComponent("verification/scc-promo")
let rawRoot = promoRoot.appendingPathComponent("raw")
let finalRoot = promoRoot.appendingPathComponent("final")
let paperURL = root.appendingPathComponent("TalkFit/Assets.xcassets/PaperBackground.imageset/paper-background.png")
let iconURL = root.appendingPathComponent("TalkFit/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

guard let paper = NSImage(contentsOf: paperURL), let icon = NSImage(contentsOf: iconURL) else {
    fatalError("Missing TalkFit brand assets")
}

try FileManager.default.createDirectory(at: finalRoot, withIntermediateDirectories: true)

func topRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasSize.height - y - height, width: width, height: height)
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

func drawText(_ text: String, rect: NSRect, font: NSFont, textColor: NSColor, lineSpacing: CGFloat = 0) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    paragraph.lineSpacing = lineSpacing
    paragraph.lineBreakMode = .byWordWrapping
    NSAttributedString(
        string: text,
        attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
    ).draw(in: rect)
}

func drawRoundedImage(_ image: NSImage, in rect: NSRect, radius: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}

for promo in promos {
    let rawURL = rawRoot.appendingPathComponent(String(format: "%02d-%@.jpg", promo.index, promo.slug))
    guard let screenshot = NSImage(contentsOf: rawURL) else {
        fatalError("Missing screenshot: \(rawURL.path)")
    }

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create output bitmap")
    }

    bitmap.size = canvasSize
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    paper.draw(in: NSRect(origin: .zero, size: canvasSize), from: .zero, operation: .copy, fraction: 1)
    color(0xFFF9EC, alpha: 0.20).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

    // Quiet botanical color fields: deliberately subtle so the real UI stays primary.
    color(0x9DBA74, alpha: 0.11).setFill()
    NSBezierPath(ovalIn: topRect(910, -105, 520, 520)).fill()
    color(0xB65B32, alpha: 0.06).setFill()
    NSBezierPath(ovalIn: topRect(-170, 430, 520, 520)).fill()

    let iconRect = topRect(94, 100, 82, 82)
    drawRoundedImage(icon, in: iconRect, radius: 19)
    drawText(
        String(format: "TalkFit  ·  練習 %02d / 05", promo.index),
        rect: topRect(202, 119, 700, 48),
        font: NSFont.systemFont(ofSize: 31, weight: .medium),
        textColor: color(0x55744B)
    )

    let headlineFont = NSFont(name: "PingFangTC-Semibold", size: 78) ?? NSFont.systemFont(ofSize: 78, weight: .semibold)
    let subheadFont = NSFont(name: "PingFangTC-Regular", size: 38) ?? NSFont.systemFont(ofSize: 38, weight: .regular)
    drawText(promo.headline, rect: topRect(94, 245, 1102, 230), font: headlineFont, textColor: color(0x174C35), lineSpacing: 10)
    drawText(promo.subhead, rect: topRect(98, 515, 1094, 78), font: subheadFont, textColor: color(0x5B7567), lineSpacing: 5)

    color(0xB65B32).setFill()
    NSBezierPath(roundedRect: topRect(98, 637, 112, 8), xRadius: 4, yRadius: 4).fill()
    color(0x7A9562, alpha: 0.35).setFill()
    NSBezierPath(roundedRect: topRect(222, 637, 62, 8), xRadius: 4, yRadius: 4).fill()

    let frameRect = topRect(179, 735, 932, 1986)
    let shadow = NSShadow()
    shadow.shadowColor = color(0x173526, alpha: 0.28)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.set()
    color(0x161B18).setFill()
    NSBezierPath(roundedRect: frameRect, xRadius: 112, yRadius: 112).fill()
    NSShadow().set()

    let frameBorder = NSBezierPath(roundedRect: frameRect, xRadius: 112, yRadius: 112)
    color(0x6F746F, alpha: 0.65).setStroke()
    frameBorder.lineWidth = 4
    frameBorder.stroke()

    let screenRect = topRect(213, 769, 864, 1878)
    drawRoundedImage(screenshot, in: screenRect, radius: 79)
    let screenBorder = NSBezierPath(roundedRect: screenRect, xRadius: 79, yRadius: 79)
    color(0xFFFFFF, alpha: 0.16).setStroke()
    screenBorder.lineWidth = 3
    screenBorder.stroke()

    // A grounded clay marker links the marketing frame to in-app annotations.
    color(0xB65B32).setFill()
    NSBezierPath(roundedRect: topRect(575, 2671, 140, 9), xRadius: 5, yRadius: 5).fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.82]) else {
        fatalError("Could not encode PNG")
    }
    let outputURL = finalRoot.appendingPathComponent(String(format: "%02d-%@.png", promo.index, promo.slug))
    try png.write(to: outputURL)
    print(outputURL.path)
}
