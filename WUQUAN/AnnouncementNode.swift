//
//  AnnouncementNode.swift
//  WUQUAN
//
//  Animated text announcements for phase transitions, combos, and round calls
//

import SpriteKit

class AnnouncementNode: SKNode {

    // MARK: - Round Announcement

    /// Shows "第N回合" or "最终决战!" with dramatic zoom-in effect
    static func showRoundAnnouncement(round: Int, maxRounds: Int, in scene: SKScene) {
        let text: String
        let color: SKColor

        if round == maxRounds {
            text = "最终决战!"
            color = SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 1.0)
        } else if round >= maxRounds - 2 {
            text = "第\(round)回合 ⚡️"
            color = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        } else {
            text = "第\(round)回合"
            color = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.9)
        }

        let label = SKLabelNode(text: text)
        label.fontSize = min(scene.size.width, scene.size.height) * 0.08
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        label.zPosition = 200
        label.setScale(0.1)
        label.alpha = 0
        scene.addChild(label)

        // Glow behind
        let glow = SKLabelNode(text: text)
        glow.fontSize = label.fontSize
        glow.fontColor = color.withAlphaComponent(0.3)
        glow.fontName = "Helvetica-Bold"
        glow.position = label.position
        glow.zPosition = 199
        glow.setScale(0.1)
        glow.alpha = 0
        scene.addChild(glow)

        // Zoom in
        let zoomIn = SKAction.group([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        ])
        zoomIn.timingMode = .easeOut

        // Hold
        let hold = SKAction.wait(forDuration: 0.6)

        // Zoom out and fade
        let zoomOut = SKAction.group([
            SKAction.scale(to: 1.8, duration: 0.3),
            SKAction.fadeAlpha(to: 0.0, duration: 0.3)
        ])
        zoomOut.timingMode = .easeIn

        let sequence = SKAction.sequence([zoomIn, hold, zoomOut, SKAction.removeFromParent()])
        label.run(sequence)
        glow.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.3),
                SKAction.fadeAlpha(to: 0.4, duration: 0.2)
            ]),
            hold,
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeAlpha(to: 0.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Combo Announcement

    /// Shows streak combo text with fire effect
    static func showCombo(streak: Int, in scene: SKScene) {
        guard streak >= 2 else { return }

        let fires = String(repeating: "🔥", count: min(streak, 5))
        let text = "连续\(streak)次! \(fires)"

        let label = SKLabelNode(text: text)
        label.fontSize = min(scene.size.width, scene.size.height) * 0.05
        label.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.65)
        label.zPosition = 200
        label.alpha = 0
        scene.addChild(label)

        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.2),
            SKAction.moveBy(x: 0, y: 20, duration: 0.3)
        ])
        let hold = SKAction.wait(forDuration: 1.0)
        let disappear = SKAction.group([
            SKAction.fadeAlpha(to: 0.0, duration: 0.4),
            SKAction.moveBy(x: 0, y: 15, duration: 0.4)
        ])

        label.run(SKAction.sequence([appear, hold, disappear, SKAction.removeFromParent()]))
    }

    // MARK: - Drink Announcement

    /// Shows "喝N杯!" with dramatic effect
    static func showDrinkCall(count: Int, isPlayer: Bool, in scene: SKScene) {
        let beers = String(repeating: "🍺", count: min(count, 5))
        let who = isPlayer ? "你" : "对手"
        let text = "\(who)喝\(count)杯! \(beers)"

        let label = SKLabelNode(text: text)
        label.fontSize = min(scene.size.width, scene.size.height) * 0.06
        label.fontColor = isPlayer ? SKColor.red : SKColor.green
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.55)
        label.zPosition = 200
        label.setScale(0.5)
        label.alpha = 0
        scene.addChild(label)

        // Slam in effect
        let slamIn = SKAction.group([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.group([
            SKAction.fadeAlpha(to: 0.0, duration: 0.5),
            SKAction.moveBy(x: 0, y: 20, duration: 0.5)
        ])

        label.run(SKAction.sequence([slamIn, settle, hold, fadeOut, SKAction.removeFromParent()]))
    }

    // MARK: - Phase Flash

    /// Brief screen flash for phase transitions
    static func flashScreen(color: SKColor, in scene: SKScene) {
        let flash = SKShapeNode(rect: CGRect(origin: .zero, size: scene.size))
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.alpha = 0.0
        flash.zPosition = 150
        scene.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.08),
            SKAction.fadeAlpha(to: 0.0, duration: 0.25),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Streak Border Glow

    /// Shows glowing border that intensifies with streak count
    static func updateStreakBorder(streak: Int, in scene: SKScene) {
        // Remove existing
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

        // Pulse
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        border.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Score Pop

    /// Animated score change — number pops and settles
    static func showScorePop(text: String, at position: CGPoint, color: SKColor, in scene: SKScene) {
        let label = SKLabelNode(text: text)
        label.fontSize = 24
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = position
        label.zPosition = 200
        scene.addChild(label)

        let popUp = SKAction.group([
            SKAction.moveBy(x: 0, y: 30, duration: 0.4),
            SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.25)
            ])
        ])
        let fade = SKAction.fadeAlpha(to: 0.0, duration: 0.4)

        label.run(SKAction.sequence([popUp, fade, SKAction.removeFromParent()]))
    }
}
