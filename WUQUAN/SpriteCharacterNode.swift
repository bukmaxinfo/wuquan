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

        // Bob forward and back
        let forward = SKAction.moveBy(x: isMirrored ? -8 : 8, y: 0, duration: 0.2)
        let back = SKAction.moveBy(x: isMirrored ? 8 : -8, y: 0, duration: 0.2)
        let shake = SKAction.sequence([forward, back])

        run(SKAction.sequence([shake, SKAction.repeat(shake, count: 2)])) {
            self.setPose("idle")
            completion()
        }
    }

    func animateFreeMovement(completion: @escaping () -> Void) {
        // Quick pose cycling to simulate dancing
        let duration: TimeInterval = 0.18

        let bounce1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: duration),
            SKAction.moveBy(x: 0, y: -8, duration: duration)
        ])
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: duration),
            SKAction.rotate(byAngle: -0.16, duration: duration),
            SKAction.rotate(byAngle: 0.08, duration: duration)
        ])

        // Cycle through poses quickly
        let poseSwap = SKAction.sequence([
            SKAction.run { self.setPose("rock", duration: 0) },
            SKAction.wait(forDuration: duration * 2),
            SKAction.run { self.setPose("handshake", duration: 0) },
            SKAction.wait(forDuration: duration * 2),
            SKAction.run { self.setPose("scissors", duration: 0) },
            SKAction.wait(forDuration: duration * 2),
            SKAction.run { self.setPose("idle", duration: 0) },
        ])

        run(SKAction.group([bounce1, bounce1, sway, poseSwap])) {
            self.setPose("idle")
            completion()
        }
    }

    func animateGestureReveal(_ gesture: Gesture) {
        // Pull back, then slam forward with gesture
        let pullBack = SKAction.moveBy(x: isMirrored ? 6 : -6, y: 0, duration: 0.12)
        let slam = SKAction.moveBy(x: isMirrored ? -12 : 12, y: 0, duration: 0.08)
        let settle = SKAction.moveBy(x: isMirrored ? 6 : -6, y: 0, duration: 0.15)

        run(SKAction.sequence([
            pullBack,
            SKAction.run { self.showGesture(gesture) },
            slam,
            settle
        ]))
    }

    func animateDirectionPoint(_ direction: Direction) {
        setPose("point")

        // Thrust in the pointed direction
        let dx: CGFloat
        let dy: CGFloat
        switch direction {
        case .up: dx = 0; dy = 10
        case .down: dx = 0; dy = -10
        case .left: dx = -10; dy = 0
        case .right: dx = 10; dy = 0
        }

        let thrust = SKAction.moveBy(x: dx, y: dy, duration: 0.15)
        let back = SKAction.moveBy(x: -dx, y: -dy, duration: 0.2)
        run(SKAction.sequence([thrust, back]))
    }

    func animateWin() {
        setPose("win")

        // Jump and bounce
        let jump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 20, duration: 0.2),
            SKAction.moveBy(x: 0, y: -20, duration: 0.15)
        ])
        run(SKAction.repeat(jump, count: 3))
    }

    func animateLose() {
        setPose("lose")

        // Sink down
        let sink = SKAction.moveBy(x: 0, y: -8, duration: 0.5)
        sink.timingMode = .easeOut
        run(sink)
    }

    func animateDrink() {
        setPose("lose")

        // Stagger side to side
        let stagger = SKAction.sequence([
            SKAction.moveBy(x: 8, y: 0, duration: 0.25),
            SKAction.moveBy(x: -16, y: 0, duration: 0.3),
            SKAction.moveBy(x: 8, y: 0, duration: 0.25)
        ])
        let sink = SKAction.moveBy(x: 0, y: -5, duration: 0.8)
        run(SKAction.group([stagger, sink]))
    }

    func animateTell(_ gesture: Gesture, delay: TimeInterval, duration: TimeInterval) {
        // Briefly flash the gesture pose then return to idle
        let tell = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { self.showGesture(gesture) },
            SKAction.wait(forDuration: duration),
            SKAction.run { self.setPose("idle", duration: 0.1) }
        ])
        run(tell)
    }

    func animateIdle() {
        // Gentle breathing/bob
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.5),
            SKAction.moveBy(x: 0, y: -3, duration: 1.5)
        ])
        run(SKAction.repeatForever(bob), withKey: "idle")

        // Subtle sway
        let sway = SKAction.sequence([
            SKAction.rotate(byAngle: 0.02, duration: 2.0),
            SKAction.rotate(byAngle: -0.02, duration: 2.0)
        ])
        run(SKAction.repeatForever(sway), withKey: "sway")
    }

    func stopIdle() {
        removeAction(forKey: "idle")
        removeAction(forKey: "sway")
    }
}
