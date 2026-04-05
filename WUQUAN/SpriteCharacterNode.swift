//
//  SpriteCharacterNode.swift
//  WUQUAN
//
//  Sprite-based character using pre-rendered art assets
//

import SpriteKit

class SpriteCharacterNode: SKNode {

    private var spriteNode: SKSpriteNode!
    private var glowNode: SKSpriteNode?
    private let characterId: String
    private let targetHeight: CGFloat
    let isMirrored: Bool

    // Cache loaded textures
    private var textures: [String: SKTexture] = [:]

    init(height: CGFloat, style: CharacterStyle, mirrored: Bool = false) {
        self.characterId = style.id
        self.targetHeight = height
        self.isMirrored = mirrored
        super.init()

        loadTextures()
        buildSprite()
        if mirrored { self.xScale = -1 }
    }

    required init?(coder aDecoder: NSCoder) {
        self.characterId = "nightclub_prince"
        self.targetHeight = 150
        self.isMirrored = false
        super.init(coder: aDecoder)
    }

    // MARK: - Setup

    private func loadTextures() {
        let poses = ["idle", "handshake", "rock", "paper", "scissors", "point", "win", "lose"]
        for pose in poses {
            let filename = "\(characterId)_\(pose)"
            // Files are in bundle root (Xcode flattens folder references)
            if let path = Bundle.main.path(forResource: filename, ofType: "png") {
                let url = URL(fileURLWithPath: path)
                if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                    textures[pose] = SKTexture(image: uiImage)
                }
            }
        }
    }

    private func buildSprite() {
        // Start with idle texture
        let idleTexture = textures["idle"] ?? SKTexture()
        spriteNode = SKSpriteNode(texture: idleTexture)

        // Scale to target height
        let textureSize = idleTexture.size()
        if textureSize.height > 0 {
            let scaleFactor = targetHeight / textureSize.height
            spriteNode.setScale(scaleFactor)
        }

        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(spriteNode)

        // Add neon glow behind sprite
        glowNode = SKSpriteNode(texture: idleTexture)
        glowNode?.setScale(spriteNode.xScale * 1.08)
        glowNode?.alpha = 0.15
        glowNode?.colorBlendFactor = 1.0
        glowNode?.color = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        glowNode?.zPosition = -1
        glowNode?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(glowNode!)

        // Pulse the glow
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.08, duration: 1.2),
            SKAction.fadeAlpha(to: 0.2, duration: 1.2)
        ])
        glowNode?.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Accessories

    private var accessoryNodes: [AccessoryNode] = []

    /// Equips all currently-equipped items from AccessoryStore.
    func equipAccessories() {
        previewAccessories(equipped: AccessoryStore.shared.equippedItems, preview: nil)
    }

    /// Shows `equipped` items plus optionally one preview item (replaces any same-category equipped).
    /// Used by the store to preview items before purchase/equip.
    func previewAccessories(equipped: [AccessoryItem], preview: AccessoryItem?) {
        accessoryNodes.forEach { $0.removeFromParent() }
        accessoryNodes = []

        var toShow = equipped
        if let p = preview {
            toShow.removeAll { $0.category == p.category }
            toShow.append(p)
        }

        for item in toShow {
            let node = AccessoryNode(item: item, characterHeight: targetHeight)
            if isMirrored { node.applyMirrorCompensation() }
            addChild(node)
            accessoryNodes.append(node)
            AnimationKit.springPopIn(node, delay: 0, fromScale: 0.3)
        }
    }

    // MARK: - Color Variant

    func applyColorVariant(_ variant: CharacterColorVariant) {
        guard variant.blendFactor > 0 else { return }
        spriteNode.color = variant.skTint
        spriteNode.colorBlendFactor = variant.blendFactor
        // Tint the glow to match
        glowNode?.color = variant.skTint
    }

    // MARK: - Pose Changes

    private func setPose(_ poseName: String, duration: TimeInterval = 0.15) {
        guard let texture = textures[poseName] else { return }

        if duration > 0 {
            // Crossfade transition
            let fadeOut = SKAction.fadeAlpha(to: 0.7, duration: duration * 0.4)
            let changeTexture = SKAction.setTexture(texture, resize: false)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: duration * 0.6)
            spriteNode.run(SKAction.sequence([fadeOut, changeTexture, fadeIn]))
        } else {
            spriteNode.texture = texture
        }
        glowNode?.texture = texture
    }

    // MARK: - Public Interface (matches CharacterNode)

    func setExpression(_ expression: CharacterNode.Expression) {
        // Expressions are baked into the sprite poses — no-op for minor expressions
    }

    func showGesture(_ gesture: Gesture) {
        switch gesture {
        case .rock: setPose("rock")
        case .paper: setPose("paper")
        case .scissors: setPose("scissors")
        }
    }

    func showDirection(_ direction: Direction) {
        setPose("point")
    }

    func resetPose() {
        setPose("idle", duration: 0.25)
    }

    // MARK: - Animations

    func animateHandshake(completion: @escaping () -> Void) {
        setPose("handshake")
        let dir: CGFloat = isMirrored ? -1 : 1

        // Anticipation lean back, then three sharp jabs with squash/stretch
        let leanBack = SKAction.moveBy(x: -dir * 10, y: 0, duration: 0.14)
        leanBack.timingMode = .easeOut

        let mirrorSign: CGFloat = isMirrored ? -1.0 : 1.0
        let jab = SKAction.sequence([
            SKAction.moveBy(x: dir * 18, y: 0, duration: 0.08),
            SKAction.scaleX(to: mirrorSign * 1.15, y: 0.88, duration: 0.06),
            SKAction.scaleX(to: mirrorSign * 1.0, y: 1.0, duration: 0.1),
            SKAction.moveBy(x: -dir * 8, y: 0, duration: 0.12)
        ])

        let bouncePause = SKAction.wait(forDuration: 0.08)

        run(SKAction.sequence([
            leanBack,
            jab, bouncePause,
            jab, bouncePause,
            jab
        ])) {
            self.setPose("idle")
            completion()
        }
    }

    func animateFreeMovement(completion: @escaping () -> Void) {
        let d: TimeInterval = 0.14

        // Bigger, snappier bounce with squash on landing
        let bounce = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 14, duration: d),
                SKAction.scaleX(to: 0.88, y: 1.12, duration: d)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -14, duration: d * 0.8),
                SKAction.scaleX(to: 1.1, y: 0.9, duration: d * 0.4)
            ]),
            SKAction.scale(to: 1.0, duration: d * 0.4)
        ])

        // Left/right sway between bounces
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.12, duration: d),
            SKAction.rotate(byAngle: -0.24, duration: d * 2),
            SKAction.rotate(byAngle: 0.12, duration: d)
        ])

        // Pose cycling — each holds for one bounce cycle
        let poses = ["rock", "handshake", "paper", "scissors", "idle"]
        var poseActions: [SKAction] = []
        for pose in poses {
            poseActions.append(SKAction.run { self.setPose(pose, duration: 0) })
            poseActions.append(SKAction.wait(forDuration: d * 2))
        }
        let poseSwap = SKAction.sequence(poseActions)

        let bounceTwice = SKAction.repeat(bounce, count: 4)
        let swayTwice = SKAction.repeat(sway, count: 2)

        run(SKAction.group([bounceTwice, swayTwice, poseSwap])) {
            self.setPose("idle", duration: 0.2)
            completion()
        }
    }

    func animateGestureReveal(_ gesture: Gesture) {
        let dir: CGFloat = isMirrored ? -1 : 1

        // Wind-up (lean back) → explosive slam → squash on impact → settle
        let windUp = SKAction.group([
            SKAction.moveBy(x: -dir * 14, y: -4, duration: 0.14),
            SKAction.scaleX(to: 0.9, y: 1.08, duration: 0.14)
        ])
        windUp.timingMode = .easeOut

        let slam = SKAction.group([
            SKAction.moveBy(x: dir * 22, y: 4, duration: 0.07),
            SKAction.scaleX(to: 1.18, y: 0.86, duration: 0.07)
        ])
        slam.timingMode = .easeIn

        let settle = SKAction.group([
            SKAction.moveBy(x: -dir * 8, y: 0, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.18)
        ])
        settle.timingMode = .easeOut

        run(SKAction.sequence([
            windUp,
            SKAction.run { self.showGesture(gesture) },
            slam,
            settle
        ]))
    }

    func animateDirectionPoint(_ direction: Direction) {
        setPose("point")

        // Snap in the direction with squash, then spring back
        let dx: CGFloat
        let dy: CGFloat
        switch direction {
        case .up:    dx = 0;   dy = 16
        case .down:  dx = 0;   dy = -16
        case .left:  dx = -16; dy = 0
        case .right: dx = 16;  dy = 0
        }

        let snapOut = SKAction.group([
            SKAction.moveBy(x: dx, y: dy, duration: 0.10),
            SKAction.scaleX(to: dx != 0 ? 1.18 : 0.9, y: dy != 0 ? 1.18 : 0.9, duration: 0.10)
        ])
        snapOut.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.12)
        let springBack = SKAction.group([
            SKAction.moveBy(x: -dx, y: -dy, duration: 0.22),
            SKAction.scale(to: 1.0, duration: 0.22)
        ])
        springBack.timingMode = .easeOut

        run(SKAction.sequence([snapOut, hold, springBack]))
    }

    func animateWin() {
        setPose("win")
        let dir: CGFloat = isMirrored ? -1 : 1

        // Jump 1 — big, with spin
        let jump1 = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 35, duration: 0.22),
                SKAction.scaleX(to: 0.85, y: 1.15, duration: 0.22),
                SKAction.rotate(byAngle: dir * 0.35, duration: 0.22)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -35, duration: 0.18),
                SKAction.scaleX(to: 1.12, y: 0.88, duration: 0.1),   // land squash
                SKAction.rotate(toAngle: 0, duration: 0.18)
            ]),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])

        // Jump 2 — medium, tilt other way
        let jump2 = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 22, duration: 0.18),
                SKAction.rotate(byAngle: -dir * 0.2, duration: 0.18)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -22, duration: 0.14),
                SKAction.scaleX(to: 1.08, y: 0.93, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.14)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        // Jump 3 — small happy hop
        let jump3 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 14, duration: 0.14),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -14, duration: 0.12),
                SKAction.scaleX(to: 1.05, y: 0.96, duration: 0.06)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        // Flash the glow bright on first jump
        glowNode?.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.1),
            SKAction.fadeAlpha(to: 0.2, duration: 0.6)
        ]))

        run(SKAction.sequence([jump1, jump2, jump3]))
    }

    func animateLose() {
        setPose("lose")
        let dir: CGFloat = isMirrored ? -1 : 1

        // Head-shake of disbelief, then heavy slump
        let shake = SKAction.sequence([
            SKAction.rotate(byAngle:  dir * 0.12, duration: 0.08),
            SKAction.rotate(byAngle: -dir * 0.24, duration: 0.1),
            SKAction.rotate(byAngle:  dir * 0.20, duration: 0.1),
            SKAction.rotate(byAngle: -dir * 0.16, duration: 0.1),
            SKAction.rotate(byAngle:  dir * 0.10, duration: 0.1),
            SKAction.rotate(toAngle: 0,           duration: 0.1)
        ])
        // Slump down with a final squash on landing
        let slump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -18, duration: 0.45),
            SKAction.group([
                SKAction.scaleX(to: 1.15, y: 0.88, duration: 0.08),
                SKAction.wait(forDuration: 0.08)
            ]),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        slump.timingMode = .easeOut

        // Dim the glow
        glowNode?.run(SKAction.fadeAlpha(to: 0.04, duration: 0.5))

        run(SKAction.group([shake, slump]))
    }

    func animateDrink() {
        setPose("lose")

        // Tipsy lean, multiple big staggers, end tilted
        let stagger = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 14, y: 4, duration: 0.2),
                SKAction.rotate(byAngle: 0.15, duration: 0.2)
            ]),
            SKAction.group([
                SKAction.moveBy(x: -26, y: -2, duration: 0.28),
                SKAction.rotate(byAngle: -0.28, duration: 0.28)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 20, y: 0, duration: 0.22),
                SKAction.rotate(byAngle: 0.18, duration: 0.22)
            ]),
            SKAction.group([
                SKAction.moveBy(x: -8, y: -6, duration: 0.3),
                SKAction.rotate(byAngle: -0.12, duration: 0.3)
            ])
        ])
        let slump = SKAction.moveBy(x: 0, y: -10, duration: 0.8)
        slump.timingMode = .easeOut

        glowNode?.run(SKAction.fadeAlpha(to: 0.06, duration: 0.4))
        run(SKAction.group([stagger, slump]))
    }

    func animateTell(_ gesture: Gesture, delay: TimeInterval, duration: TimeInterval) {
        // Flash pose with a quick scale emphasis
        let tell = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run {
                self.showGesture(gesture)
                self.run(AnimationKit.squashStretchX(self, intensity: 1.2))
            },
            SKAction.wait(forDuration: duration),
            SKAction.run { self.setPose("idle", duration: 0.12) }
        ])
        run(tell)
    }

    func animateIdle() {
        // Visible bob — 7pt so it reads on screen
        let bob = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 7, duration: 1.2),
                SKAction.scaleX(to: 0.97, y: 1.03, duration: 1.2)   // breathe in
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -7, duration: 1.2),
                SKAction.scaleX(to: 1.0, y: 1.0, duration: 1.2)      // breathe out
            ])
        ])
        bob.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(bob), withKey: "idle")

        // Gentle asymmetric sway — feels alive
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle:  0.035, duration: 1.8),
            SKAction.rotate(byAngle: -0.060, duration: 2.4),
            SKAction.rotate(byAngle:  0.025, duration: 1.8)
        ])
        run(SKAction.repeatForever(sway), withKey: "sway")

        // Occasional weight shift — random pause between
        let weightShift = SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval.random(in: 3.5...7.0)),
            SKAction.group([
                SKAction.moveBy(x: isMirrored ? 5 : -5, y: 0, duration: 0.3),
                SKAction.scaleX(to: 0.96, y: 1.02, duration: 0.3)
            ]),
            SKAction.group([
                SKAction.moveBy(x: isMirrored ? -5 : 5, y: 0, duration: 0.4),
                SKAction.scale(to: 1.0, duration: 0.4)
            ])
        ])
        run(SKAction.repeatForever(weightShift), withKey: "weightShift")
    }

    func stopIdle() {
        removeAction(forKey: "idle")
        removeAction(forKey: "sway")
        removeAction(forKey: "weightShift")
        // Snap back to neutral scale/rotation
        run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.rotate(toAngle: 0, duration: 0.15)
        ]))
    }
}
