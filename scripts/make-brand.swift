// Generates the website's brand images from code, so they are reproducible.
// Run: swift scripts/make-brand.swift   (from the repo root; needs macOS, no dependencies)
//
// The clam mark itself is the app icon (Clam/Resources/Assets.xcassets/.../AppIcon.png). This script
// scales it rather than redrawing it, so the site, the favicons and the app never drift apart.
// Outputs, all in docs/: og.png, favicon-32.png, apple-touch-icon.png, icon-192.png, icon-512.png,
// and the sized screenshot copies the landing page uses (docs/screenshots/web-*.png).
import AppKit
import CoreGraphics

/// CGColor(red:green:blue:alpha:) is Generic RGB, which renders lighter than the same hex in a
/// browser. Build colours in sRGB so #121217 here is #121217 on the site.
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r, g, b, a])!
}

// Tokens from Clam/Design/Theme.swift and docs/index.html.
let bg = rgb(0x12 / 255.0, 0x12 / 255.0, 0x17 / 255.0, 1)
let surface = rgb(0x1f / 255.0, 0x1f / 255.0, 0x26 / 255.0, 1)
let accent = rgb(0xfa / 255.0, 0xd1 / 255.0, 0x59 / 255.0, 1)
let white = rgb(1, 1, 1, 1)
let muted = rgb(1, 1, 1, 0.72)

let root = FileManager.default.currentDirectoryPath

func context(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    return ctx
}

func save(_ ctx: CGContext, _ path: String) {
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) (\(data.count / 1024) KB)")
}

func load(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("cannot read \(path)")
    }
    return image
}

func roundedRect(_ ctx: CGContext, _ rect: CGRect, _ radius: CGFloat, _ color: CGColor) {
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(color)
    ctx.fillPath()
}

func drawText(_ ctx: CGContext, _ text: String, at point: CGPoint, size: CGFloat, color: CGColor, weight: NSFont.Weight = .bold) {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color)!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    ctx.saveGState()
    ctx.textPosition = point
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func textWidth(_ text: String, size: CGFloat, weight: NSFont.Weight = .bold) -> CGFloat {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

/// Colour of one source pixel (top-left origin) as rendered into our sRGB contexts, so fills match
/// captures whose colour profile differs from the theme tokens.
func sample(_ image: CGImage, x: Int, y: Int) -> CGColor {
    let ctx = context(1, 1)
    ctx.draw(image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1))!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    let p = ctx.data!.assumingMemoryBound(to: UInt8.self)
    return rgb(CGFloat(p[0]) / 255, CGFloat(p[1]) / 255, CGFloat(p[2]) / 255, 1)
}

let icon = load("\(root)/Clam/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

/// The clam without the icon's empty margins: the mark occupies roughly x 160...864, y 230...730
/// of the 1024 icon (top-left origin). CGImage cropping uses the same top-left origin.
let mark = icon.cropping(to: CGRect(x: 150, y: 222, width: 724, height: 516))!
let markAspect: CGFloat = 724.0 / 516.0

// ---- Open Graph / Twitter card, 1200x630. Text sized to stay readable in a small link preview. ----
do {
    let ctx = context(1200, 630)
    ctx.setFillColor(bg)
    ctx.fill(CGRect(x: 0, y: 0, width: 1200, height: 630))
    // The mark's own background is `bg`, so it sits on a bg-coloured chip inside the surface card.
    roundedRect(ctx, CGRect(x: 40, y: 40, width: 1120, height: 550), 48, surface)
    roundedRect(ctx, CGRect(x: 92, y: 440, width: 132, height: 104), 26, sample(icon, x: 4, y: 4))
    let mh: CGFloat = 72
    ctx.draw(mark, in: CGRect(x: 158 - mh * markAspect / 2, y: 492 - mh / 2, width: mh * markAspect, height: mh))
    drawText(ctx, "Clam", at: CGPoint(x: 248, y: 466), size: 72, color: white)
    drawText(ctx, "App blocker for iPhone.", at: CGPoint(x: 94, y: 306), size: 92, color: white, weight: .heavy)
    drawText(ctx, "Your apps stay shut.", at: CGPoint(x: 94, y: 196), size: 92, color: accent, weight: .heavy)
    drawText(ctx, "One tap. Real blocking. Timer on your Lock Screen.", at: CGPoint(x: 98, y: 104), size: 40,
             color: muted, weight: .semibold)
    let domain = "getclam.app"
    drawText(ctx, domain, at: CGPoint(x: 1104 - textWidth(domain, size: 34, weight: .semibold), y: 478), size: 34,
             color: muted, weight: .semibold)
    save(ctx, "\(root)/docs/og.png")
}

// ---- Favicons and manifest icons. ----
// The 32px favicon uses the cropped mark on a rounded tile (the full icon's margins make it a speck);
// the larger ones are the app icon itself, square, because iOS and Android mask them.
do {
    let ctx = context(32, 32)
    roundedRect(ctx, CGRect(x: 0, y: 0, width: 32, height: 32), 7, sample(icon, x: 4, y: 4))
    let mw: CGFloat = 27
    ctx.draw(mark, in: CGRect(x: 16 - mw / 2, y: 16 - mw / markAspect / 2, width: mw, height: mw / markAspect))
    save(ctx, "\(root)/docs/favicon-32.png")
}
for (size, name) in [(180, "apple-touch-icon.png"), (192, "icon-192.png"), (512, "icon-512.png")] {
    let ctx = context(size, size)
    ctx.draw(icon, in: CGRect(x: 0, y: 0, width: size, height: size))
    save(ctx, "\(root)/docs/\(name)")
}

// ---- Sized screenshot copies for the landing page (540 px wide = 2x of the 270 px display size). ----
// Sources are the simulator captures in docs/screenshots/. `cover` paints over a strip (in source
// pixels, top-left origin) with the screen's background: the "apps" capture carries a simulator-only
// debug note that never appears on a real iPhone.
let shots: [(name: String, cover: CGRect?)] = [
    ("apps", CGRect(x: 0, y: 1010, width: 1320, height: 140)),
    ("permission", nil),
    ("hours", nil),
]
for shot in shots {
    let src = load("\(root)/docs/screenshots/\(shot.name).png")
    let w = 540
    let h = Int((CGFloat(src.height) * CGFloat(w) / CGFloat(src.width)).rounded())
    let ctx = context(w, h)
    ctx.draw(src, in: CGRect(x: 0, y: 0, width: w, height: h))
    if let c = shot.cover {
        let k = CGFloat(w) / CGFloat(src.width)
        ctx.setFillColor(sample(src, x: Int(c.minX) + 4, y: Int(c.maxY) + 4))
        ctx.fill(CGRect(x: c.minX * k, y: CGFloat(h) - (c.minY + c.height) * k, width: c.width * k, height: c.height * k))
    }
    save(ctx, "\(root)/docs/screenshots/web-\(shot.name).png")
}
