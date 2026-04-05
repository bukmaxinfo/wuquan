//
//  AccessoryNode.swift
//  WUQUAN
//
//  SpriteKit node that renders a single accessory as an overlay on a character sprite.
//  Add as a child of SpriteCharacterNode (or any SKNode whose local (0,0) is the
//  character's center and whose height equals characterHeight).
//
//  Hats / glasses / capes / gloves → emoji SKLabelNode positioned by anchorY/X.
//  Auras → procedural SKShapeNode rings with pulsing glow animations.
//  Gloves → two labels (right + left sides of character) are placed symmetrically.
//

import SpriteKit

class AccessoryNode: SKNode {

    let item: AccessoryItem

    // Keep refs so applyMirrorCompensation can flip text orientation
    private var emojiLabels: [SKLabelNode] = []

    // MARK: - Init

    init(item: AccessoryItem, characterHeight: CGFloat) {
        self.item = item
        super.init()
        build(characterHeight: characterHeight)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func build(characterHeight: CGFloat) {
        let halfH = characterHeight * 0.5

        if item.category == .auras {
            buildAura(halfH: halfH)
        } else {
            addEmojiLabel(halfH: halfH, mirrorX: false)
            // Gloves: add a symmetric label on the opposite side
            if item.category == .gloves {
                addEmojiLabel(halfH: halfH, mirrorX: true)
            }
        }
    }

    // MARK: - Emoji Labels

    private func addEmojiLabel(halfH: CGFloat, mirrorX: Bool) {
        guard item.displayScale > 0 else { return }
        let fs = halfH * 2 * item.displayScale   // characterHeight * displayScale
        guard fs > 2 else { return }

        let label = SKLabelNode(text: item.emoji)
        label.fontSize = fs
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let xSign: CGFloat = mirrorX ? -1 : 1
        label.position = CGPoint(
            x: halfH * item.anchorX * xSign,
            y: halfH * item.anchorY
        )
        label.zPosition = item.zOffset
        addChild(label)
        emojiLabels.append(label)
    }

    // MARK: - Aura

    private func buildAura(halfH: CGFloat) {
        let outerRadius = halfH * 0.90
        let innerRadius = outerRadius * 0.78
        let color = auraColor(for: item.id)

        // Outer ring
        let outer = SKShapeNode(circleOfRadius: outerRadius)
        outer.fillColor = .clear
        outer.strokeColor = color
        outer.lineWidth = 4
        outer.glowWidth = 12
        outer.zPosition = item.zOffset
        outer.alpha = 0.80
        addChild(outer)

        // Inner ring (subtler)
        let inner = SKShapeNode(circleOfRadius: innerRadius)
        inner.fillColor = color.withAlphaComponent(0.08)
        inner.strokeColor = color.withAlphaComponent(0.35)
        inner.lineWidth = 2
        inner.glowWidth = 5
        inner.zPosition = item.zOffset
        inner.alpha = 0.60
        addChild(inner)

        // Breathing pulse on outer ring
        let outerPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 0.45, duration: 0.85),
                SKAction.scale(to: 1.06, duration: 0.85)
            ]),
            SKAction.group([
                SKAction.fadeAlpha(to: 0.85, duration: 0.85),
                SKAction.scale(to: 0.96, duration: 0.85)
            ])
        ]))
        outer.run(outerPulse)

        let innerPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 1.05),
            SKAction.scale(to: 0.93, duration: 1.05)
        ]))
        inner.run(innerPulse)

        // Orbiting sparkles for star / rainbow auras
        if item.id == "aura_star" || item.id == "aura_rainbow" {
            buildOrbitParticles(radius: outerRadius, count: 6, color: color)
        }

        // Fire aura: add a second, offset ring that rotates
        if item.id == "aura_fire" {
            let fireRing = SKShapeNode(circleOfRadius: outerRadius * 0.60)
            fireRing.fillColor = .clear
            fireRing.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.5)
            fireRing.lineWidth = 3
            fireRing.glowWidth = 8
            fireRing.zPosition = item.zOffset + 0.3
            fireRing.position = CGPoint(x: 0, y: -halfH * 0.15)
            addChild(fireRing)
            fireRing.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 2.5)))
        }

        // Lightning aura: rotating dashed ring effect
        if item.id == "aura_zap" {
            buildZapRing(radius: outerRadius * 1.05, color: color)
        }
    }

    private func buildOrbitParticles(radius: CGFloat, count: Int, color: SKColor) {
        for i in 0..<count {
            let orbit = SKNode()
            orbit.zPosition = item.zOffset + 0.5
            addChild(orbit)

            let spark = SKShapeNode(circleOfRadius: 3.5)
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.glowWidth = 5
            spark.position = CGPoint(x: radius, y: 0)
            orbit.addChild(spark)

            let startAngle = CGFloat(i) / CGFloat(count) * .pi * 2
            orbit.zRotation = startAngle

            let dur = Double.random(in: 2.8...4.5)
            orbit.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: dur)))
        }
    }

    private func buildZapRing(radius: CGFloat, color: SKColor) {
        // Simulate dashes by rotating a segmented arc-like ring
        let zapOrbit = SKNode()
        zapOrbit.zPosition = item.zOffset + 0.3
        addChild(zapOrbit)

        for i in 0..<8 {
            let angle = CGFloat(i) / 8.0 * .pi * 2
            let spark = SKShapeNode(rectOf: CGSize(width: 6, height: 3))
            spark.fillColor = color
            spark.strokeColor = .clear
            spark.glowWidth = 4
            spark.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            spark.zRotation = angle + .pi / 2
            zapOrbit.addChild(spark)
        }
        zapOrbit.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 1.8)))
    }

    private func auraColor(for id: String) -> SKColor {
        switch id {
        case "aura_star":    return SKColor(red: 1.0, green: 0.95, blue: 0.40, alpha: 1)
        case "aura_fire":    return SKColor(red: 1.0, green: 0.35, blue: 0.00, alpha: 1)
        case "aura_zap":     return SKColor(red: 0.65, green: 0.90, blue: 1.00, alpha: 1)
        case "aura_rainbow": return SKColor(red: 0.80, green: 0.30, blue: 1.00, alpha: 1)
        default:             return SKColor.cyan
        }
    }

    // MARK: - Mirror Compensation

    /// Call when the parent SpriteCharacterNode has xScale = -1 (facing right).
    /// Counter-flips emoji text so it reads correctly despite the parent flip.
    func applyMirrorCompensation() {
        for label in emojiLabels {
            label.xScale = -1
        }
        // Aura rings are circles — no text flip needed.
    }
}

