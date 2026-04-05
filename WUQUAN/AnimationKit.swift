//
//  AnimationKit.swift
//  WUQUAN
//
//  Shared animation helpers for SpriteKit and UIKit.
//  All static — call from anywhere.
//

import SpriteKit
import UIKit

enum AnimationKit {

    // MARK: - Screen Shake

    /// Shake the scene with decaying multi-directional motion.
    /// Operates on the scene's position, which offsets rendering within the SKView.
    static func screenShake(_ scene: SKScene, intensity: CGFloat = 14, duration: TimeInterval = 0.55) {
        scene.removeAction(forKey: "screenShake")
        let steps = 10
        let stepDuration = duration / Double(steps)
        var actions: [SKAction] = []
        for i in 0..<steps {
            let decay = pow(1.0 - CGFloat(i) / CGFloat(steps), 1.5)
            let dx = CGFloat.random(in: -intensity...intensity) * decay
            let dy = CGFloat.random(in: -intensity * 0.6...intensity * 0.6) * decay
            let move = SKAction.moveBy(x: dx, y: dy, duration: stepDuration)
            move.timingMode = .easeInEaseOut
            actions.append(move)
        }
        // Return to exact origin
        let restore = SKAction.move(to: .zero, duration: stepDuration * 0.4)
        restore.timingMode = .easeOut
        actions.append(restore)
        scene.run(SKAction.sequence(actions), withKey: "screenShake")
    }

    // MARK: - Particle Burst

    /// Burst colored particles outward from a point.
    static func particleBurst(
        at position: CGPoint,
        colors: [SKColor],
        count: Int = 22,
        radius: CGFloat = 3.5,
        spread: CGFloat = 120,
        zPosition: CGFloat = 180,
        in scene: SKScene
    ) {
        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * .pi * 2
                      + CGFloat.random(in: -0.25...0.25)
            let dist = CGFloat.random(in: spread * 0.4...spread)
            let color = colors[Int.random(in: 0..<colors.count)]
            let r = CGFloat.random(in: radius * 0.5...radius * 1.8)

            let shape: SKShapeNode
            let roll = Int.random(in: 0...2)
            if roll == 0 {
                shape = SKShapeNode(circleOfRadius: r)
            } else if roll == 1 {
                shape = SKShapeNode(rectOf: CGSize(width: r * 2.2, height: r * 0.9))
                shape.zRotation = CGFloat.random(in: 0...(.pi))
            } else {
                shape = makeStar(radius: r, color: color)
            }
            shape.fillColor = color
            shape.strokeColor = .clear
            shape.glowWidth = 1.5
            shape.position = position
            shape.zPosition = zPosition
            shape.alpha = 0.9
            scene.addChild(shape)

            let dest = CGPoint(x: position.x + cos(angle) * dist,
                               y: position.y + sin(angle) * dist)
            let tDur = TimeInterval.random(in: 0.5...0.9)

            let travel = SKAction.move(to: dest, duration: tDur)
            travel.timingMode = .easeOut
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: tDur * 0.45),
                SKAction.group([
                    SKAction.fadeOut(withDuration: tDur * 0.55),
                    SKAction.scale(to: 0.1, duration: tDur * 0.55)
                ])
            ])
            shape.run(SKAction.sequence([
                SKAction.group([travel, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Firework Burst

    /// Full firework: flash, burst particles, trails.
    static func fireworkBurst(
        at position: CGPoint,
        colors: [SKColor],
        in scene: SKScene,
        count: Int = 14
    ) {
        let primary = colors[Int.random(in: 0..<colors.count)]

        // Central flash
        let flash = SKShapeNode(circleOfRadius: 10)
        flash.fillColor = .white
        flash.strokeColor = primary
        flash.glowWidth = 12
        flash.position = position
        flash.zPosition = 185
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.0, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.25)
            ]),
            SKAction.removeFromParent()
        ]))

        // Burst particles
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
            let dist = CGFloat.random(in: 70...160)
            let isTracer = Bool.random()
            let particle = SKShapeNode(
                rectOf: isTracer
                    ? CGSize(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 8...14))
                    : CGSize(width: 5, height: 5)
            )
            particle.zRotation = angle + .pi / 2
            particle.fillColor = colors[Int.random(in: 0..<colors.count)]
            particle.strokeColor = .clear
            particle.glowWidth = isTracer ? 3 : 1
            particle.position = position
            particle.zPosition = 183
            scene.addChild(particle)

            let dest = CGPoint(x: position.x + cos(angle) * dist,
                               y: position.y + sin(angle) * dist)
            let dur = TimeInterval.random(in: 0.45...0.75)
            let travel = SKAction.move(to: dest, duration: dur)
            travel.timingMode = .easeOut

            particle.run(SKAction.sequence([
                SKAction.group([
                    travel,
                    SKAction.sequence([
                        SKAction.wait(forDuration: dur * 0.5),
                        SKAction.group([
                            SKAction.fadeOut(withDuration: dur * 0.5),
                            SKAction.scale(to: 0.2, duration: dur * 0.5)
                        ])
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Chromatic Flash

    /// Two-layer chromatic aberration flash.
    static func chromaFlash(color: SKColor, intensity: CGFloat = 0.45, in scene: SKScene) {
        let makeFlash: (SKColor, CGFloat, CGFloat, CGFloat, TimeInterval) -> Void = { col, dx, dy, alpha, dur in
            let r = CGRect(x: dx, y: dy, width: scene.size.width, height: scene.size.height)
            let node = SKShapeNode(rect: r)
            node.fillColor = col
            node.strokeColor = .clear
            node.alpha = 0
            node.zPosition = 160
            node.blendMode = .screen
            node.isUserInteractionEnabled = false
            scene.addChild(node)
            node.run(SKAction.sequence([
                SKAction.fadeAlpha(to: alpha, duration: 0.04),
                SKAction.fadeAlpha(to: 0, duration: dur),
                SKAction.removeFromParent()
            ]))
        }
        makeFlash(color,       0,  0, intensity,       0.22)
        makeFlash(color,      5,  -3, intensity * 0.3, 0.35)  // red ghost shifted
        makeFlash(.cyan,    -5,   3, intensity * 0.2, 0.30)  // cyan ghost
    }

    // MARK: - Squash & Stretch

    /// Horizontal impact — squash wide, bounce back.
    static func squashStretchX(_ node: SKNode, intensity: CGFloat = 1.35) -> SKAction {
        let squash = SKAction.scaleX(to: intensity, y: 1.0 / intensity, duration: 0.06)
        squash.timingMode = .easeOut
        let overshoot = SKAction.scaleX(to: 0.88, y: 1.10, duration: 0.08)
        let settle = SKAction.scale(to: 1.0, duration: 0.18)
        settle.timingMode = .easeOut
        return SKAction.sequence([squash, overshoot, settle])
    }

    /// Vertical impact — squash tall, bounce back.
    static func squashStretchY(_ node: SKNode, intensity: CGFloat = 1.35) -> SKAction {
        let squash = SKAction.scaleX(to: 1.0 / intensity, y: intensity, duration: 0.06)
        squash.timingMode = .easeOut
        let overshoot = SKAction.scaleX(to: 1.10, y: 0.88, duration: 0.08)
        let settle = SKAction.scale(to: 1.0, duration: 0.18)
        settle.timingMode = .easeOut
        return SKAction.sequence([squash, overshoot, settle])
    }

    // MARK: - Spring Pop-In

    /// Scale + fade entrance from 0 → overshoot → settle.
    @discardableResult
    static func springPopIn(_ node: SKNode, delay: TimeInterval = 0, fromScale: CGFloat = 0.01) -> SKAction {
        node.setScale(fromScale)
        node.alpha = 0
        let wait = delay > 0 ? SKAction.wait(forDuration: delay) : nil
        let enter = SKAction.group([
            SKAction.scale(to: 1.18, duration: 0.22),
            SKAction.fadeIn(withDuration: 0.12)
        ])
        enter.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.16)
        settle.timingMode = .easeInEaseOut

        var seq: [SKAction] = []
        if let w = wait { seq.append(w) }
        seq += [enter, settle]
        let action = SKAction.sequence(seq)
        node.run(action)
        return action
    }

    /// Slide in from below + spring settle.
    static func slideUpIn(_ node: SKNode, offset: CGFloat = 50, delay: TimeInterval = 0) {
        let originalY = node.position.y
        node.position.y -= offset
        node.alpha = 0
        let wait = delay > 0 ? SKAction.wait(forDuration: delay) : nil
        let rise = SKAction.group([
            SKAction.moveTo(y: originalY + 10, duration: 0.22),
            SKAction.fadeIn(withDuration: 0.18)
        ])
        rise.timingMode = .easeOut
        let settle = SKAction.moveTo(y: originalY, duration: 0.14)
        settle.timingMode = .easeInEaseOut

        var seq: [SKAction] = []
        if let w = wait { seq.append(w) }
        seq += [rise, settle]
        node.run(SKAction.sequence(seq))
    }

    // MARK: - Elastic Scale Pulse

    /// Quick scale-up pop, used for button taps and label emphasis.
    static func springPop(scale: CGFloat = 1.25, duration: TimeInterval = 0.35) -> SKAction {
        let up = SKAction.scale(to: scale, duration: duration * 0.28)
        up.timingMode = .easeOut
        let down = SKAction.scale(to: 0.94, duration: duration * 0.22)
        let settle = SKAction.scale(to: 1.0, duration: duration * 0.5)
        settle.timingMode = .easeOut
        return SKAction.sequence([up, down, settle])
    }

    // MARK: - Text Wobble

    /// Rotational wobble that decays — great for "drunk" or impact text.
    static func wobble(intensity: CGFloat = 0.18, steps: Int = 6) -> SKAction {
        var actions: [SKAction] = []
        for i in 0..<steps {
            let decay = 1.0 - CGFloat(i) / CGFloat(steps)
            let dir: CGFloat = i.isMultiple(of: 2) ? 1 : -1
            let a = SKAction.rotate(byAngle: dir * intensity * decay, duration: 0.055)
            a.timingMode = .easeInEaseOut
            actions.append(a)
        }
        let zero = SKAction.rotate(toAngle: 0, duration: 0.06)
        zero.timingMode = .easeOut
        actions.append(zero)
        return SKAction.sequence(actions)
    }

    // MARK: - Floaty Label

    /// Float a label upward and fade — score pops, drink count etc.
    static func floatUp(
        text: String,
        at position: CGPoint,
        color: SKColor,
        fontSize: CGFloat = 28,
        in scene: SKScene
    ) {
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontColor = color
        label.fontName = "Helvetica-Bold"
        label.position = position
        label.zPosition = 200
        label.alpha = 0
        label.setScale(0.5)
        scene.addChild(label)

        let pop = SKAction.group([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.fadeIn(withDuration: 0.1)
        ])
        pop.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let rise = SKAction.moveBy(x: 0, y: 55, duration: 1.0)
        rise.timingMode = .easeOut
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])
        label.run(SKAction.sequence([
            pop, settle,
            SKAction.group([rise, fade]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Private Helpers

    private static func makeStar(radius: CGFloat, color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        let points = 5
        let inner = radius * 0.45
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let r = i.isMultiple(of: 2) ? radius : inner
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        let star = SKShapeNode(path: path)
        star.fillColor = color
        star.strokeColor = .clear
        return star
    }

    // MARK: - UIKit Helpers

    /// Spring bounce-in from near-zero scale.
    static func bounceIn(_ view: UIView, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        view.alpha = 0
        UIView.animate(
            withDuration: 0.5,
            delay: delay,
            usingSpringWithDamping: 0.58,
            initialSpringVelocity: 0.9,
            options: .curveEaseOut
        ) {
            view.transform = .identity
            view.alpha = 1
        } completion: { _ in completion?() }
    }

    /// Dismissal: scale down + fade.
    static func bounceOut(_ view: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseIn) {
            view.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            view.alpha = 0
        } completion: { _ in completion?() }
    }

    /// Brief scale-down punch for button taps.
    static func tapPulse(_ view: UIView) {
        UIView.animate(withDuration: 0.09, animations: {
            view.transform = CGAffineTransform(scaleX: 0.91, y: 0.91)
        }) { _ in
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.45,
                initialSpringVelocity: 1.2,
                options: []
            ) {
                view.transform = .identity
            }
        }
    }

    /// Slide up from below + spring settle (UIKit).
    static func slideUp(_ view: UIView, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        view.transform = CGAffineTransform(translationX: 0, y: 60)
        view.alpha = 0
        UIView.animate(
            withDuration: 0.42,
            delay: delay,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            view.transform = .identity
            view.alpha = 1
        } completion: { _ in completion?() }
    }

    /// Glow pulse on a UIView layer — useful for selected states.
    static func glowPulse(_ view: UIView, color: UIColor) {
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = 0
        view.layer.shadowOpacity = 0.9
        view.layer.shadowOffset = .zero
        let anim = CABasicAnimation(keyPath: "shadowRadius")
        anim.fromValue = 0
        anim.toValue = 12
        anim.duration = 0.7
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(anim, forKey: "glowPulse")
    }

    static func stopGlowPulse(_ view: UIView) {
        view.layer.removeAnimation(forKey: "glowPulse")
        view.layer.shadowRadius = 0
        view.layer.shadowOpacity = 0
    }
}
