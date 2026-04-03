//
//  CharacterNode.swift
//  WUQUAN
//
//  Animated 2D character for player and AI opponent
//

import SpriteKit

class CharacterNode: SKNode {

    // Body parts
    private var head: SKShapeNode!
    private var bodyNode: SKShapeNode!
    private var leftArm: SKNode!
    private var rightArm: SKNode!
    private var leftHand: SKLabelNode!
    private var rightHand: SKLabelNode!
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var mouthLabel: SKLabelNode!

    // Accessories
    private var sunglasses: SKShapeNode?
    private var chain: SKShapeNode?

    // Config
    private let scale: CGFloat
    private let style: CharacterStyle
    let isMirrored: Bool

    init(height: CGFloat, style: CharacterStyle = .nightclubPrince, mirrored: Bool = false) {
        self.scale = height / 200.0
        self.style = style
        self.isMirrored = mirrored
        super.init()
        if mirrored { self.xScale = -1 }
        buildCharacter()
    }

    required init?(coder aDecoder: NSCoder) {
        self.scale = 1.0
        self.style = .nightclubPrince
        self.isMirrored = false
        super.init(coder: aDecoder)
    }

    // MARK: - Build Character

    private func buildCharacter() {
        buildBody()
        buildHead()
        buildArms()
        buildAccessories()
        setExpression(.neutral)
    }

    private func buildBody() {
        let bodyPath = UIBezierPath()
        let shoulderWidth = 40 * scale
        let bodyHeight = 60 * scale
        let waistWidth = 30 * scale

        bodyPath.move(to: CGPoint(x: -shoulderWidth, y: 0))
        bodyPath.addLine(to: CGPoint(x: -waistWidth, y: -bodyHeight))
        bodyPath.addLine(to: CGPoint(x: waistWidth, y: -bodyHeight))
        bodyPath.addLine(to: CGPoint(x: shoulderWidth, y: 0))
        bodyPath.close()

        bodyNode = SKShapeNode(path: bodyPath.cgPath)
        bodyNode.fillColor = style.jacketColor
        bodyNode.strokeColor = style.trimColor
        bodyNode.lineWidth = 2 * scale
        bodyNode.position = CGPoint(x: 0, y: 10 * scale)
        addChild(bodyNode)

        // Collar
        let collarPath = UIBezierPath()
        collarPath.move(to: CGPoint(x: -15 * scale, y: 0))
        collarPath.addLine(to: CGPoint(x: 0, y: -25 * scale))
        collarPath.addLine(to: CGPoint(x: 15 * scale, y: 0))
        let collar = SKShapeNode(path: collarPath.cgPath)
        collar.strokeColor = style.collarColor
        collar.lineWidth = 1.5 * scale
        collar.fillColor = .clear
        bodyNode.addChild(collar)
    }

    private func buildHead() {
        head = SKShapeNode(circleOfRadius: 28 * scale)
        head.fillColor = style.skinColor
        head.strokeColor = style.skinColor.withAlphaComponent(0.7)
        head.lineWidth = 1.5 * scale
        head.position = CGPoint(x: 0, y: 45 * scale)
        addChild(head)

        // Hair
        let r = 28 * scale
        let hairPath = UIBezierPath()
        hairPath.addArc(withCenter: .zero, radius: r + 3 * scale,
                        startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
        hairPath.addLine(to: CGPoint(x: -r * 0.9, y: r * 0.3))
        hairPath.close()
        let hair = SKShapeNode(path: hairPath.cgPath)
        hair.fillColor = style.hairColor
        hair.strokeColor = .clear
        hair.zPosition = 1
        head.addChild(hair)

        // Head accessories
        if style.hasHeadband {
            let bandPath = UIBezierPath()
            bandPath.addArc(withCenter: .zero, radius: r + 1 * scale,
                            startAngle: .pi * 0.2, endAngle: .pi * 0.8, clockwise: true)
            let band = SKShapeNode(path: bandPath.cgPath)
            band.strokeColor = style.trimColor
            band.lineWidth = 3 * scale
            band.fillColor = .clear
            band.zPosition = 2
            head.addChild(band)
        }

        if style.hasBow {
            let bow = SKLabelNode(text: "🎀")
            bow.fontSize = 16 * scale
            bow.position = CGPoint(x: 18 * scale, y: 22 * scale)
            bow.zPosition = 3
            if isMirrored { bow.xScale = -1 }
            head.addChild(bow)
        }

        if style.hasCap {
            let capPath = UIBezierPath()
            capPath.addArc(withCenter: .zero, radius: r + 4 * scale,
                           startAngle: .pi * 0.1, endAngle: .pi * 0.9, clockwise: true)
            capPath.addLine(to: CGPoint(x: -r * 1.3, y: r * 0.2))
            capPath.close()
            let cap = SKShapeNode(path: capPath.cgPath)
            cap.fillColor = style.trimColor
            cap.strokeColor = style.jacketColor
            cap.lineWidth = 1.5 * scale
            cap.zPosition = 3
            head.addChild(cap)
        }

        if style.hasHeadphones {
            let hpBand = UIBezierPath()
            hpBand.addArc(withCenter: .zero, radius: r + 5 * scale,
                          startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
            let band = SKShapeNode(path: hpBand.cgPath)
            band.strokeColor = style.trimColor
            band.lineWidth = 3 * scale
            band.fillColor = .clear
            band.zPosition = 3
            head.addChild(band)

            let leftCup = SKShapeNode(circleOfRadius: 6 * scale)
            leftCup.fillColor = style.jacketColor
            leftCup.strokeColor = style.trimColor
            leftCup.lineWidth = 1.5 * scale
            leftCup.position = CGPoint(x: -(r + 4 * scale), y: r * 0.3)
            leftCup.zPosition = 3
            head.addChild(leftCup)

            let rightCup = SKShapeNode(circleOfRadius: 6 * scale)
            rightCup.fillColor = style.jacketColor
            rightCup.strokeColor = style.trimColor
            rightCup.lineWidth = 1.5 * scale
            rightCup.position = CGPoint(x: r + 4 * scale, y: r * 0.3)
            rightCup.zPosition = 3
            head.addChild(rightCup)
        }

        if style.hasTiara {
            let tiara = SKLabelNode(text: "👑")
            tiara.fontSize = 18 * scale
            tiara.position = CGPoint(x: 0, y: 26 * scale)
            tiara.zPosition = 3
            if isMirrored { tiara.xScale = -1 }
            head.addChild(tiara)
        }

        if style.hasEarrings {
            let leftEarring = SKShapeNode(circleOfRadius: 3 * scale)
            leftEarring.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            leftEarring.strokeColor = .clear
            leftEarring.position = CGPoint(x: -(r + 2 * scale), y: -5 * scale)
            leftEarring.glowWidth = 0.5 * scale
            head.addChild(leftEarring)

            let rightEarring = SKShapeNode(circleOfRadius: 3 * scale)
            rightEarring.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            rightEarring.strokeColor = .clear
            rightEarring.position = CGPoint(x: r + 2 * scale, y: -5 * scale)
            rightEarring.glowWidth = 0.5 * scale
            head.addChild(rightEarring)
        }

        if style.hasBeard {
            let beardPath = UIBezierPath()
            beardPath.move(to: CGPoint(x: -12 * scale, y: -10 * scale))
            beardPath.addQuadCurve(to: CGPoint(x: 12 * scale, y: -10 * scale),
                                   controlPoint: CGPoint(x: 0, y: -25 * scale))
            let beard = SKShapeNode(path: beardPath.cgPath)
            beard.fillColor = style.hairColor.withAlphaComponent(0.7)
            beard.strokeColor = style.hairColor
            beard.lineWidth = 1 * scale
            head.addChild(beard)
        }

        // Eyes
        leftEye = SKShapeNode(ellipseOf: CGSize(width: 8 * scale, height: 10 * scale))
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 1 * scale
        leftEye.position = CGPoint(x: -10 * scale, y: 5 * scale)
        head.addChild(leftEye)

        let leftPupil = SKShapeNode(circleOfRadius: 3 * scale)
        leftPupil.fillColor = .black
        leftPupil.strokeColor = .clear
        leftPupil.name = "leftPupil"
        leftEye.addChild(leftPupil)

        rightEye = SKShapeNode(ellipseOf: CGSize(width: 8 * scale, height: 10 * scale))
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 1 * scale
        rightEye.position = CGPoint(x: 10 * scale, y: 5 * scale)
        head.addChild(rightEye)

        let rightPupil = SKShapeNode(circleOfRadius: 3 * scale)
        rightPupil.fillColor = .black
        rightPupil.strokeColor = .clear
        rightPupil.name = "rightPupil"
        rightEye.addChild(rightPupil)

        // Mouth
        mouthLabel = SKLabelNode(text: style.defaultMouth)
        mouthLabel.fontSize = 14 * scale
        mouthLabel.position = CGPoint(x: 0, y: -12 * scale)
        // Flip text back if character is mirrored so emoji reads correctly
        if isMirrored { mouthLabel.xScale = -1 }
        head.addChild(mouthLabel)

        // Eyebrows
        let browColor = style.browColor ?? style.hairColor
        let leftBrow = SKShapeNode(rectOf: CGSize(width: 12 * scale, height: 2 * scale))
        leftBrow.fillColor = browColor
        leftBrow.strokeColor = .clear
        leftBrow.position = CGPoint(x: -10 * scale, y: 14 * scale)
        leftBrow.zRotation = 0.15
        leftBrow.name = "leftBrow"
        head.addChild(leftBrow)

        let rightBrow = SKShapeNode(rectOf: CGSize(width: 12 * scale, height: 2 * scale))
        rightBrow.fillColor = browColor
        rightBrow.strokeColor = .clear
        rightBrow.position = CGPoint(x: 10 * scale, y: 14 * scale)
        rightBrow.zRotation = -0.15
        rightBrow.name = "rightBrow"
        head.addChild(rightBrow)
    }

    private func buildArms() {
        // Left arm
        leftArm = SKNode()
        leftArm.position = CGPoint(x: -40 * scale, y: 10 * scale)
        addChild(leftArm)

        let leftUpperArm = SKShapeNode(rectOf: CGSize(width: 8 * scale, height: 35 * scale), cornerRadius: 4 * scale)
        leftUpperArm.fillColor = style.armColor
        leftUpperArm.strokeColor = style.armTrimColor
        leftUpperArm.lineWidth = 1 * scale
        leftUpperArm.position = CGPoint(x: 0, y: -17 * scale)
        leftArm.addChild(leftUpperArm)

        leftHand = SKLabelNode(text: "✊")
        leftHand.fontSize = 22 * scale
        leftHand.position = CGPoint(x: 0, y: -40 * scale)
        if isMirrored { leftHand.xScale = -1 }
        leftArm.addChild(leftHand)

        // Right arm
        rightArm = SKNode()
        rightArm.position = CGPoint(x: 40 * scale, y: 10 * scale)
        addChild(rightArm)

        let rightUpperArm = SKShapeNode(rectOf: CGSize(width: 8 * scale, height: 35 * scale), cornerRadius: 4 * scale)
        rightUpperArm.fillColor = style.armColor
        rightUpperArm.strokeColor = style.armTrimColor
        rightUpperArm.lineWidth = 1 * scale
        rightUpperArm.position = CGPoint(x: 0, y: -17 * scale)
        rightArm.addChild(rightUpperArm)

        rightHand = SKLabelNode(text: "✊")
        rightHand.fontSize = 22 * scale
        rightHand.position = CGPoint(x: 0, y: -40 * scale)
        if isMirrored { rightHand.xScale = -1 }
        rightArm.addChild(rightHand)
    }

    private func buildAccessories() {
        if style.hasSunglasses {
            let glassesPath = UIBezierPath()
            let glassWidth: CGFloat = 12 * scale
            let glassHeight: CGFloat = 8 * scale

            glassesPath.append(UIBezierPath(roundedRect: CGRect(
                x: -22 * scale, y: 0, width: glassWidth, height: glassHeight), cornerRadius: 2 * scale))
            glassesPath.append(UIBezierPath(roundedRect: CGRect(
                x: 4 * scale, y: 0, width: glassWidth, height: glassHeight), cornerRadius: 2 * scale))
            glassesPath.move(to: CGPoint(x: -10 * scale, y: glassHeight * 0.5))
            glassesPath.addLine(to: CGPoint(x: 4 * scale, y: glassHeight * 0.5))

            sunglasses = SKShapeNode(path: glassesPath.cgPath)
            sunglasses?.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9)
            sunglasses?.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.8, alpha: 1.0)
            sunglasses?.lineWidth = 1.5 * scale
            sunglasses?.position = CGPoint(x: 3 * scale, y: 0)
            sunglasses?.zPosition = 2
            sunglasses?.isHidden = true
            head.addChild(sunglasses!)
        }

        if style.hasChain {
            let chainPath = UIBezierPath()
            chainPath.move(to: CGPoint(x: -12 * scale, y: -2 * scale))
            chainPath.addQuadCurve(to: CGPoint(x: 12 * scale, y: -2 * scale),
                                   controlPoint: CGPoint(x: 0, y: -15 * scale))
            chain = SKShapeNode(path: chainPath.cgPath)
            chain?.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.9)
            chain?.lineWidth = 2 * scale
            chain?.fillColor = .clear
            chain?.glowWidth = 1 * scale
            bodyNode.addChild(chain!)
        }
    }

    // MARK: - Expressions

    enum Expression {
        case neutral, smirk, surprised, angry, happy, sad
    }

    func setExpression(_ expression: Expression) {
        let leftBrow = head.childNode(withName: "leftBrow")
        let rightBrow = head.childNode(withName: "rightBrow")

        switch expression {
        case .neutral:
            mouthLabel.text = style.defaultMouth
            leftBrow?.zRotation = 0.15
            rightBrow?.zRotation = -0.15
            leftEye.setScale(1.0)
            rightEye.setScale(1.0)
        case .smirk:
            mouthLabel.text = "😏"
            leftBrow?.zRotation = 0.3
            rightBrow?.zRotation = 0
            sunglasses?.isHidden = false
        case .surprised:
            mouthLabel.text = "😮"
            leftEye.setScale(1.3)
            rightEye.setScale(1.3)
            leftBrow?.zRotation = 0.3
            rightBrow?.zRotation = -0.3
        case .angry:
            mouthLabel.text = "😤"
            leftBrow?.zRotation = -0.3
            rightBrow?.zRotation = 0.3
        case .happy:
            mouthLabel.text = "😄"
            leftBrow?.zRotation = 0.1
            rightBrow?.zRotation = -0.1
            sunglasses?.isHidden = false
        case .sad:
            mouthLabel.text = "😢"
            leftBrow?.zRotation = 0.3
            rightBrow?.zRotation = -0.3
        }
    }

    // MARK: - Gesture Display

    func showGesture(_ gesture: Gesture) {
        rightHand.text = gesture.emoji
        rightArm.run(SKAction.rotate(toAngle: 0.8, duration: 0.3))
    }

    func showDirection(_ direction: Direction) {
        leftHand.text = "👉"
        let angle: CGFloat
        switch direction {
        case .up: angle = .pi / 2
        case .down: angle = -.pi / 2
        case .left: angle = .pi
        case .right: angle = 0
        }
        leftArm.run(SKAction.rotate(toAngle: angle * 0.4 + 0.3, duration: 0.3))
    }

    func resetPose() {
        leftHand.text = "✊"
        rightHand.text = "✊"
        sunglasses?.isHidden = true
        setExpression(.neutral)
        leftArm.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        rightArm.run(SKAction.rotate(toAngle: 0, duration: 0.3))
    }

    // MARK: - Animations

    func animateHandshake(completion: @escaping () -> Void) {
        let extend = SKAction.rotate(toAngle: 0.5, duration: 0.2)
        let shakeUp = SKAction.rotate(byAngle: 0.15, duration: 0.1)
        let shakeDown = SKAction.rotate(byAngle: -0.15, duration: 0.1)
        let shake = SKAction.sequence([shakeUp, shakeDown])
        let shakeRepeat = SKAction.repeat(shake, count: 3)
        let retract = SKAction.rotate(toAngle: 0, duration: 0.2)

        rightArm.run(SKAction.sequence([extend, shakeRepeat, retract])) {
            completion()
        }

        let nodDown = SKAction.moveBy(x: 0, y: -3 * scale, duration: 0.15)
        let nodUp = SKAction.moveBy(x: 0, y: 3 * scale, duration: 0.15)
        head.run(SKAction.sequence([nodDown, nodUp]))
    }

    func animateFreeMovement(completion: @escaping () -> Void) {
        let duration: TimeInterval = 0.2

        let leftSwing1 = SKAction.rotate(toAngle: 0.6, duration: duration)
        let leftSwing2 = SKAction.rotate(toAngle: -0.4, duration: duration)
        let leftSwing3 = SKAction.rotate(toAngle: 0.3, duration: duration)
        let leftReturn = SKAction.rotate(toAngle: 0, duration: duration)

        let rightSwing1 = SKAction.rotate(toAngle: -0.5, duration: duration)
        let rightSwing2 = SKAction.rotate(toAngle: 0.7, duration: duration)
        let rightSwing3 = SKAction.rotate(toAngle: -0.2, duration: duration)
        let rightReturn = SKAction.rotate(toAngle: 0, duration: duration)

        leftArm.run(SKAction.sequence([leftSwing1, leftSwing2, leftSwing3, leftReturn]))
        rightArm.run(SKAction.sequence([rightSwing1, rightSwing2, rightSwing3, rightReturn])) {
            completion()
        }

        let bounceUp = SKAction.moveBy(x: 0, y: 5 * scale, duration: duration)
        let bounceDown = SKAction.moveBy(x: 0, y: -5 * scale, duration: duration)
        let bounce = SKAction.sequence([bounceUp, bounceDown])
        bodyNode.run(SKAction.repeat(bounce, count: 2))

        let swayLeft = SKAction.rotate(byAngle: 0.1, duration: duration)
        let swayRight = SKAction.rotate(byAngle: -0.2, duration: duration)
        let swayBack = SKAction.rotate(byAngle: 0.1, duration: duration)
        head.run(SKAction.sequence([swayLeft, swayRight, swayBack]))

        setExpression(.smirk)
    }

    func animateGestureReveal(_ gesture: Gesture) {
        let pullBack = SKAction.rotate(toAngle: -0.3, duration: 0.15)
        let thrust = SKAction.rotate(toAngle: 1.0, duration: 0.1)
        let settle = SKAction.rotate(toAngle: 0.7, duration: 0.2)

        rightArm.run(SKAction.sequence([pullBack, SKAction.run {
            self.rightHand.text = gesture.emoji
        }, thrust, settle]))

        head.run(SKAction.sequence([
            SKAction.rotate(byAngle: -0.1, duration: 0.1),
            SKAction.rotate(byAngle: 0.1, duration: 0.2)
        ]))
    }

    func animateDirectionPoint(_ direction: Direction) {
        let targetAngle: CGFloat

        switch direction {
        case .up:
            targetAngle = 1.2
            leftHand.text = "☝️"
        case .down:
            targetAngle = -0.8
            leftHand.text = "👇"
        case .left:
            targetAngle = 0.5
            leftHand.text = "👈"
        case .right:
            targetAngle = -0.3
            leftHand.text = "👉"
        }

        let point = SKAction.rotate(toAngle: targetAngle, duration: 0.25)
        point.timingMode = .easeOut
        leftArm.run(point)
    }

    func animateWin() {
        setExpression(.happy)
        sunglasses?.isHidden = false

        let armsUp = SKAction.rotate(toAngle: 1.5, duration: 0.3)
        leftArm.run(armsUp)
        rightArm.run(armsUp)

        let bounceUp = SKAction.moveBy(x: 0, y: 8 * scale, duration: 0.2)
        let bounceDown = SKAction.moveBy(x: 0, y: -8 * scale, duration: 0.2)
        let bounce = SKAction.sequence([bounceUp, bounceDown])
        self.run(SKAction.repeat(bounce, count: 3))

        leftHand.text = "🎉"
        rightHand.text = "🎉"
    }

    func animateLose() {
        setExpression(.sad)

        let armsDown = SKAction.rotate(toAngle: -0.3, duration: 0.5)
        leftArm.run(armsDown)
        rightArm.run(armsDown)

        let droop = SKAction.moveBy(x: 0, y: -5 * scale, duration: 0.3)
        head.run(droop)

        leftHand.text = "😞"
        rightHand.text = "😞"
    }

    func animateDrink() {
        setExpression(.surprised)

        // Raise right hand with drink
        rightHand.text = "🍺"
        let raiseArm = SKAction.rotate(toAngle: 1.3, duration: 0.3)
        let tilt = SKAction.rotate(byAngle: 0.3, duration: 0.4)
        let tiltBack = SKAction.rotate(byAngle: -0.3, duration: 0.3)
        rightArm.run(SKAction.sequence([raiseArm, tilt, tiltBack]))

        // Head tilts back to drink
        let headBack = SKAction.moveBy(x: 0, y: 3 * scale, duration: 0.3)
        let headReturn = SKAction.moveBy(x: 0, y: -3 * scale, duration: 0.4)
        head.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            headBack,
            SKAction.run { self.mouthLabel.text = "😵" },
            headReturn
        ]))
    }

    func animateIdle() {
        let breatheIn = SKAction.moveBy(x: 0, y: 2 * scale, duration: 1.5)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.moveBy(x: 0, y: -2 * scale, duration: 1.5)
        breatheOut.timingMode = .easeInEaseOut
        let breathe = SKAction.sequence([breatheIn, breatheOut])
        bodyNode.run(SKAction.repeatForever(breathe), withKey: "idle")

        let wait = SKAction.wait(forDuration: 3.0, withRange: 2.0)
        let blink = SKAction.sequence([
            SKAction.run { self.leftEye.setScale(0.1); self.rightEye.setScale(0.1) },
            SKAction.wait(forDuration: 0.1),
            SKAction.run { self.leftEye.setScale(1.0); self.rightEye.setScale(1.0) }
        ])
        let blinkLoop = SKAction.sequence([wait, blink])
        head.run(SKAction.repeatForever(blinkLoop), withKey: "blink")
    }

    func stopIdle() {
        bodyNode.removeAction(forKey: "idle")
        head.removeAction(forKey: "blink")
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
    }
}
