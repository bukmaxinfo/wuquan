//
//  AppIconRenderer.swift
//  WUQUAN
//
//  Generates the WUQUAN app icon programmatically.
//
//  Usage (run once during development to produce icon PNGs):
//
//    let sizes: [CGFloat] = [1024]
//    for size in sizes {
//        if let data = AppIconRenderer.render(size: size)?.pngData() {
//            let url = FileManager.default.temporaryDirectory
//                .appendingPathComponent("AppIcon_\(Int(size)).png")
//            try? data.write(to: url)
//            print("Saved icon: \(url.path)")
//        }
//    }
//
//  Place the generated AppIcon_1024.png into:
//    Assets.xcassets/AppIcon.appiconset/
//  and update Contents.json to reference "filename": "AppIcon_1024.png".
//

import UIKit

enum AppIconRenderer {

    /// Renders a square WUQUAN icon at the given point size.
    static func render(size: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // --- Background gradient: deep purple → near-black ---
        let topColor    = UIColor(red: 0.08, green: 0.02, blue: 0.18, alpha: 1)
        let bottomColor = UIColor(red: 0.02, green: 0.01, blue: 0.06, alpha: 1)
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
            locations: [0.0, 1.0]
        )!
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: size / 2, y: 0),
                               end: CGPoint(x: size / 2, y: size),
                               options: [])

        // --- Neon grid lines (perspective, simplified) ---
        let gridAlpha: CGFloat = 0.25
        let gridColor = UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: gridAlpha)
        ctx.setStrokeColor(gridColor.cgColor)
        ctx.setLineWidth(size * 0.004)

        let vanishX = size / 2
        let vanishY = size * 0.52
        let floorY  = size * 0.72
        let lineCount = 8
        let spread = size * 0.9

        for i in 0...lineCount {
            let t = CGFloat(i) / CGFloat(lineCount)
            let bottomX = (size - spread) / 2 + t * spread
            ctx.move(to: CGPoint(x: bottomX, y: floorY))
            ctx.addLine(to: CGPoint(x: vanishX, y: vanishY))
        }
        ctx.strokePath()

        // Horizontal lines
        let hLineColor = UIColor(red: 1.0, green: 0.0, blue: 0.7, alpha: gridAlpha)
        ctx.setStrokeColor(hLineColor.cgColor)
        for i in 1...5 {
            let t = CGFloat(i) / 5.0
            let y = vanishY + (floorY - vanishY) * t
            let wFrac = 1.0 - t * 0.5
            let hw = size * wFrac * 0.45
            ctx.move(to: CGPoint(x: vanishX - hw, y: y))
            ctx.addLine(to: CGPoint(x: vanishX + hw, y: y))
        }
        ctx.strokePath()

        // Horizon glow line
        let horizonColor = UIColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.9)
        ctx.setStrokeColor(horizonColor.cgColor)
        ctx.setLineWidth(size * 0.008)
        ctx.setShadow(offset: .zero, blur: size * 0.025, color: horizonColor.cgColor)
        ctx.move(to: CGPoint(x: 0, y: vanishY))
        ctx.addLine(to: CGPoint(x: size, y: vanishY))
        ctx.strokePath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)  // reset shadow

        // --- Silhouette of two facing figures (simplified shapes) ---
        drawFigureSilhouette(ctx: ctx, iconSize: size, xFraction: 0.3, mirrored: false)
        drawFigureSilhouette(ctx: ctx, iconSize: size, xFraction: 0.7, mirrored: true)

        // --- Chinese characters "舞拳" ---
        let titleText = "舞拳"
        let titleFont = UIFont.boldSystemFont(ofSize: size * 0.22)
        let neonPink = UIColor(red: 1.0, green: 0.05, blue: 0.75, alpha: 1.0)

        // Glow layer
        let glowAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: neonPink.withAlphaComponent(0.3)
        ]
        let glowStr = NSAttributedString(string: titleText, attributes: glowAttrs)
        let glowSize = glowStr.size()
        let glowRect = CGRect(
            x: (size - glowSize.width) / 2 - size * 0.01,
            y: size * 0.1,
            width: glowSize.width + size * 0.02,
            height: glowSize.height
        )
        ctx.setShadow(offset: .zero, blur: size * 0.04, color: neonPink.cgColor)
        glowStr.draw(in: glowRect)

        // Main text
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleStr = NSAttributedString(string: titleText, attributes: titleAttrs)
        let titleSize = titleStr.size()
        let titleRect = CGRect(
            x: (size - titleSize.width) / 2,
            y: size * 0.1,
            width: titleSize.width,
            height: titleSize.height
        )
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        titleStr.draw(in: titleRect)

        // --- Subtitle "WUQUAN" small ---
        let subText = "WUQUAN"
        let subFont = UIFont.systemFont(ofSize: size * 0.065, weight: .light)
        let cyanColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.85)
        let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: cyanColor]
        let subStr = NSAttributedString(string: subText, attributes: subAttrs)
        let subSize = subStr.size()
        ctx.setShadow(offset: .zero, blur: size * 0.015, color: cyanColor.cgColor)
        subStr.draw(at: CGPoint(x: (size - subSize.width) / 2, y: size * 0.34))
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func drawFigureSilhouette(ctx: CGContext, iconSize s: CGFloat,
                                              xFraction: CGFloat, mirrored: Bool) {
        let x = s * xFraction
        let baseY = s * 0.72
        let headR = s * 0.038
        let bodyH = s * 0.12
        let legH  = s * 0.09
        let armL  = s * 0.075

        let figureColor = UIColor(red: 0.85, green: 0.6, blue: 1.0, alpha: 0.6)
        ctx.setFillColor(figureColor.cgColor)
        ctx.setStrokeColor(figureColor.cgColor)
        ctx.setShadow(offset: .zero, blur: s * 0.015, color: figureColor.cgColor)

        // Head
        ctx.addEllipse(in: CGRect(x: x - headR, y: baseY - bodyH - legH - headR * 2,
                                   width: headR * 2, height: headR * 2))
        ctx.fillPath()

        // Body
        ctx.move(to: CGPoint(x: x, y: baseY - bodyH - legH))
        ctx.addLine(to: CGPoint(x: x, y: baseY - legH))
        ctx.setLineWidth(s * 0.012)
        ctx.strokePath()

        // Legs
        let legSpread: CGFloat = mirrored ? -1 : 1
        ctx.move(to: CGPoint(x: x, y: baseY - legH))
        ctx.addLine(to: CGPoint(x: x - legSpread * s * 0.025, y: baseY))
        ctx.move(to: CGPoint(x: x, y: baseY - legH))
        ctx.addLine(to: CGPoint(x: x + legSpread * s * 0.025, y: baseY))
        ctx.strokePath()

        // Arms (raised as if in dance/fight pose)
        let dir: CGFloat = mirrored ? -1 : 1
        ctx.move(to: CGPoint(x: x, y: baseY - bodyH - legH * 0.4))
        ctx.addLine(to: CGPoint(x: x + dir * armL, y: baseY - bodyH - legH * 0.8))
        ctx.move(to: CGPoint(x: x, y: baseY - bodyH - legH * 0.4))
        ctx.addLine(to: CGPoint(x: x - dir * armL * 0.6, y: baseY - bodyH - legH * 0.1))
        ctx.strokePath()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)
    }
}
