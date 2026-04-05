//
//  AnnouncementNode.swift
//  WUQUAN
//
//  Animated text announcements for phase transitions, combos, and round calls
//

import SpriteKit

class AnnouncementNode: SKNode {

    // MARK: - Round Announcement

    /// Shows "第N回合" or "最终决战!" with dramatic zoom-in and screen flash.
    static func showRoundAnnouncement(round: Int, maxRounds: Int, in scene: SKScene) {
        let text: String
        let color: SKColor
        let isFinal = (round == maxRounds)

        if isFinal {
            text = "最终决战!"
            color = SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 1.0)
        } else if round >= maxRounds - 2 {
            text = "第\(round)回合 ⚡"
            color = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        } else {
            text = "第\(round)回合"
            color = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.9)
        }

        let cx = scene.size.width / 2
        let cy = scene.size.height / 2
        let fontSize = min(scene.size.width, scene.size.height) * 0.09

        // Glow shadow (slightly larger, behind)
        let glow = SKLabelNode(text: text)
        glow.fontSize = fontSize
        glow.fontColor = color
        glow.fontName = "Helvetica-Bold"
        glow.position = CGPoint(x: cx, y: cy)
        glow.zPosition = 199
        glow.alpha = 0
        glow.setScale(0.05)
        scene.addChild(glow)

        // Main label
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: cx, y: cy)
        label.zPosition = 200
        label.alpha = 0
        label.setScale(0.05)
        scene.addChild(label)

        // Slam in — overshoot then settle
        let slamIn = SKAction.group([
            SKAction.scale(to: 1.25, duration: 0.18),
            SKAction.fadeAlpha(to: 1.0, duration: 0.10)
        ])
        slamIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.14)
        settle.timingMode = .easeInEaseOut

        let hold = SKAction.wait(forDuration: isFinal ? 1.0 : 0.65)

        let zoomOut = SKAction.group([
            SKAction.scale(to: 2.0, duration: 0.30),
            SKAction.fadeAlpha(to: 0.0, duration: 0.30)
        ])
        zoomOut.timingMode = .easeIn

        label.run(SKAction.sequence([slamIn, settle, hold,
                                     isFinal ? AnimationKit.wobble(intensity: 0.12, steps: 5) : SKAction.wait(forDuration: 0),
                                     zoomOut, SKAction.removeFromParent()]))

        glow.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.55, duration: 0.18),
                            SKAction.fadeAlpha(to: 0.35, duration: 0.10)]),
            SKAction.scale(to: 1.3, duration: 0.14),
            hold,
            SKAction.group([SKAction.scale(to: 2.5, duration: 0.30),
                            SKAction.fadeAlpha(to: 0.0, duration: 0.30)]),
            SKAction.removeFromParent()
        ]))

        // Screen flash on entry
        AnimationKit.chromaFlash(color: color, intensity: isFinal ? 0.35 : 0.20, in: scene)

        // Extra particle burst on final round
        if isFinal {
            AnimationKit.particleBurst(
                at: CGPoint(x: cx, y: cy),
                colors: [color, .white, .orange],
                count: 20, radius: 4, spread: 110, zPosition: 195, in: scene
            )
        }
    }

    // MARK: - Combo Announcement

    /// Shows streak combo text with spring pop and fire particles for high streaks.
    static func showCombo(streak: Int, in scene: SKScene) {
        guard streak >= 2 else { return }

        let fires = String(repeating: "🔥", count: min(streak, 5))
        let text = "连续\(streak)次! \(fires)"
        let color = SKColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0)

        let label = SKLabelNode(text: text)
        label.fontSize = min(scene.size.width, scene.size.height) * 0.055
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.65)
        label.zPosition = 200
        scene.addChild(label)

        AnimationKit.springPopIn(label, delay: 0, fromScale: 0.3)

        let hold = SKAction.wait(forDuration: 1.0)
        let rise = SKAction.moveBy(x: 0, y: 20, duration: 0.5)
        rise.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.5)
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.38 + 1.0),   // pop-in duration + hold
            SKAction.group([rise, fade]),
            SKAction.removeFromParent()
        ]))

        // Wobble on very high streaks
        if streak >= 4 {
            label.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.38),
                AnimationKit.wobble(intensity: 0.14, steps: 5)
            ]))
        }

        // Burst from above for streaks ≥ 3
        if streak >= 3 {
            AnimationKit.particleBurst(
                at: CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.7),
                colors: [color, .yellow, .white],
                count: 12, radius: 2.5, spread: 60, zPosition: 195, in: scene
            )
        }
    }

    // MARK: - Drink Announcement

    /// Shows "喝N杯!" with slam-in, wobble, and chromatic flash.
    static func showDrinkCall(count: Int, isPlayer: Bool, in scene: SKScene) {
        let beers = String(repeating: "🍺", count: min(count, 5))
        let who = isPlayer ? "你" : "对手"
        let text = "\(who)喝\(count)杯! \(beers)"
        let color: SKColor = isPlayer
            ? SKColor(red: 1.0, green: 0.15, blue: 0.15, alpha: 1.0)
            : SKColor(red: 0.15, green: 1.0, blue: 0.4, alpha: 1.0)

        let label = SKLabelNode(text: text)
        label.fontSize = min(scene.size.width, scene.size.height) * 0.065
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.52)
        label.zPosition = 200
        label.setScale(0.05)
        label.alpha = 0
        scene.addChild(label)

        // Explosive slam-in — 0→1.45→1.0
        let slamIn = SKAction.group([
            SKAction.scale(to: 1.45, duration: 0.14),
            SKAction.fadeAlpha(to: 1.0, duration: 0.09)
        ])
        slamIn.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeInEaseOut

        let wobble = AnimationKit.wobble(intensity: 0.18, steps: 6)
        let hold = SKAction.wait(forDuration: 1.4)
        let fadeOut = SKAction.group([
            SKAction.fadeAlpha(to: 0.0, duration: 0.4),
            SKAction.moveBy(x: 0, y: 18, duration: 0.4)
        ])

        label.run(SKAction.sequence([slamIn, settle, wobble, hold, fadeOut, SKAction.removeFromParent()]))

        // Chromatic flash matching player/opponent
        AnimationKit.chromaFlash(color: color, intensity: 0.28, in: scene)

        // Bubble particles near label
        AnimationKit.particleBurst(
            at: CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.52),
            colors: [color, .white, SKColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1)],
            count: 10, radius: 2.5, spread: 50, zPosition: 195, in: scene
        )
    }

    // MARK: - Phase Flash

    /// Brief screen flash for phase transitions.
    static func flashScreen(color: SKColor, in scene: SKScene) {
        AnimationKit.chromaFlash(color: color, intensity: 0.22, in: scene)
    }

    // MARK: - Streak Border Glow

    /// Shows glowing border that intensifies with streak count.
    static func updateStreakBorder(streak: Int, in scene: SKScene) {
        scene.childNode(withName: "streakBorder")?.removeFromParent()
        guard streak >= 2 else { return }

        let intensity = min(CGFloat(streak) / 5.0, 1.0)
        let borderColor = SKColor(red: 1.0, green: 0.4 * (1 - intensity), blue: 0.0, alpha: 0.3 * intensity)

        let border = SKShapeNode(rect: CGRect(origin: .zero, size: scene.size))
        border.fillColor = .clear
        border.strokeColor = borderColor
        border.lineWidth = 4 + CGFloat(streak) * 2
        border.glowWidth = 5 + CGFloat(streak) * 3
        border.zPosition = 90
        border.name = "streakBorder"
        scene.addChild(border)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.45),
            SKAction.fadeAlpha(to: 1.0, duration: 0.45)
        ])
        border.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Score Pop

    /// Animated score change — number floats up and fades.
    static func showScorePop(text: String, at position: CGPoint, color: SKColor, in scene: SKScene) {
        AnimationKit.floatUp(text: text, at: position, color: color, fontSize: 26, in: scene)
    }
}
