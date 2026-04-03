//
//  CharacterNode.swift
//  WUQUAN
//
//  Full-body animated 2D character with legs, neon glow, and dance-battle animations
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

    // Legs
    private var leftLeg: SKNode!
    private var rightLeg: SKNode!
    private var leftLowerLeg: SKNode!
    private var rightLowerLeg: SKNode!
    private var leftFoot: SKShapeNode!
    private var rightFoot: SKShapeNode!

    // Glow outline
    private var glowNode: SKNode!

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

    // MARK: - Helpers

    private func darkerColor(_ color: SKColor, factor: CGFloat = 0.5) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: r * factor, green: g * factor, blue: b * factor, alpha: a)
    }

    // MARK: - Build Character

    private func buildCharacter() {
        buildGlow()
        buildLegs()
        buildBody()
        buildHead()
        buildArms()
        buildAccessories()
        setExpression(.neutral)
    }

    // MARK: - Neon Glow Outline

    private func buildGlow() {
        glowNode = SKNode()
        glowNode.zPosition = -1
        addChild(glowNode)

        // Glow body silhouette (torso)
        let shoulderWidth: CGFloat = 38 * scale
        let bodyHeight: CGFloat = 45 * scale
        let waistWidth: CGFloat = 28 * scale

        let glowBodyPath = UIBezierPath()
        let glowPad: CGFloat = 3 * scale
        glowBodyPath.move(to: CGPoint(x: -(shoulderWidth + glowPad), y: glowPad))
        glowBodyPath.addLine(to: CGPoint(x: -(waistWidth + glowPad), y: -(bodyHeight + glowPad)))
        glowBodyPath.addLine(to: CGPoint(x: waistWidth + glowPad, y: -(bodyHeight + glowPad)))
        glowBodyPath.addLine(to: CGPoint(x: shoulderWidth + glowPad, y: glowPad))
        glowBodyPath.close()

        let glowBody = SKShapeNode(path: glowBodyPath.cgPath)
        glowBody.fillColor = style.trimColor.withAlphaComponent(0.08)
        glowBody.strokeColor = style.trimColor.withAlphaComponent(0.25)
        glowBody.lineWidth = 2 * scale
        glowBody.glowWidth = 4 * scale
        glowBody.position = CGPoint(x: 0, y: 20 * scale)
        glowNode.addChild(glowBody)

        // Glow head silhouette
        let glowHead = SKShapeNode(circleOfRadius: 24 * scale)
        glowHead.fillColor = style.trimColor.withAlphaComponent(0.06)
        glowHead.strokeColor = style.trimColor.withAlphaComponent(0.2)
        glowHead.lineWidth = 2 * scale
        glowHead.glowWidth = 4 * scale
        glowHead.position = CGPoint(x: 0, y: 52 * scale)
        glowNode.addChild(glowHead)

        // Glow legs silhouette
        for xSide in [-1.0, 1.0] as [CGFloat] {
            let legGlow = SKShapeNode(rectOf: CGSize(width: 12 * scale, height: 55 * scale), cornerRadius: 4 * scale)
            legGlow.fillColor = style.trimColor.withAlphaComponent(0.05)
            legGlow.strokeColor = style.trimColor.withAlphaComponent(0.15)
            legGlow.lineWidth = 1.5 * scale
            legGlow.glowWidth = 3 * scale
            legGlow.position = CGPoint(x: xSide * 14 * scale, y: -50 * scale)
            glowNode.addChild(legGlow)
        }

        // Pulsing glow animation
        let glowUp = SKAction.fadeAlpha(to: 0.9, duration: 1.2)
        glowUp.timingMode = .easeInEaseOut
        let glowDown = SKAction.fadeAlpha(to: 0.5, duration: 1.2)
        glowDown.timingMode = .easeInEaseOut
        glowNode.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])))
    }

    // MARK: - Build Legs

    private func buildLegs() {
        let legYStart: CGFloat = -25 * scale  // below torso
        let hipSpread: CGFloat = 14 * scale
        let upperLegHeight: CGFloat = 28 * scale
        let lowerLegHeight: CGFloat = 22 * scale
        let footWidth: CGFloat = 14 * scale
        let footHeight: CGFloat = 5 * scale
        let pantsColor = style.jacketColor
        let shoeColor = darkerColor(style.jacketColor, factor: 0.35)

        // Left leg
        leftLeg = SKNode()
        leftLeg.position = CGPoint(x: -hipSpread, y: legYStart)
        leftLeg.zPosition = -0.5
        addChild(leftLeg)

        let leftUpperLeg = SKShapeNode(rectOf: CGSize(width: 10 * scale, height: upperLegHeight), cornerRadius: 4 * scale)
        leftUpperLeg.fillColor = pantsColor
        leftUpperLeg.strokeColor = style.trimColor.withAlphaComponent(0.4)
        leftUpperLeg.lineWidth = 1 * scale
        leftUpperLeg.position = CGPoint(x: 0, y: -upperLegHeight / 2)
        leftLeg.addChild(leftUpperLeg)

        leftLowerLeg = SKNode()
        leftLowerLeg.position = CGPoint(x: 0, y: -upperLegHeight)
        leftLeg.addChild(leftLowerLeg)

        let leftShin = SKShapeNode(rectOf: CGSize(width: 9 * scale, height: lowerLegHeight), cornerRadius: 3 * scale)
        leftShin.fillColor = pantsColor
        leftShin.strokeColor = style.trimColor.withAlphaComponent(0.3)
        leftShin.lineWidth = 1 * scale
        leftShin.position = CGPoint(x: 0, y: -lowerLegHeight / 2)
        leftLowerLeg.addChild(leftShin)

        leftFoot = SKShapeNode(rectOf: CGSize(width: footWidth, height: footHeight), cornerRadius: 2 * scale)
        leftFoot.fillColor = shoeColor
        leftFoot.strokeColor = style.trimColor.withAlphaComponent(0.3)
        leftFoot.lineWidth = 1 * scale
        leftFoot.position = CGPoint(x: 2 * scale, y: -lowerLegHeight - footHeight / 2)
        leftLowerLeg.addChild(leftFoot)

        // Right leg
        rightLeg = SKNode()
        rightLeg.position = CGPoint(x: hipSpread, y: legYStart)
        rightLeg.zPosition = -0.5
        addChild(rightLeg)

        let rightUpperLeg = SKShapeNode(rectOf: CGSize(width: 10 * scale, height: upperLegHeight), cornerRadius: 4 * scale)
        rightUpperLeg.fillColor = pantsColor
        rightUpperLeg.strokeColor = style.trimColor.withAlphaComponent(0.4)
        rightUpperLeg.lineWidth = 1 * scale
        rightUpperLeg.position = CGPoint(x: 0, y: -upperLegHeight / 2)
        rightLeg.addChild(rightUpperLeg)

        rightLowerLeg = SKNode()
        rightLowerLeg.position = CGPoint(x: 0, y: -upperLegHeight)
        rightLeg.addChild(rightLowerLeg)

        let rightShin = SKShapeNode(rectOf: CGSize(width: 9 * scale, height: lowerLegHeight), cornerRadius: 3 * scale)
        rightShin.fillColor = pantsColor
        rightShin.strokeColor = style.trimColor.withAlphaComponent(0.3)
        rightShin.lineWidth = 1 * scale
        rightShin.position = CGPoint(x: 0, y: -lowerLegHeight / 2)
        rightLowerLeg.addChild(rightShin)

        rightFoot = SKShapeNode(rectOf: CGSize(width: footWidth, height: footHeight), cornerRadius: 2 * scale)
        rightFoot.fillColor = shoeColor
        rightFoot.strokeColor = style.trimColor.withAlphaComponent(0.3)
        rightFoot.lineWidth = 1 * scale
        rightFoot.position = CGPoint(x: -2 * scale, y: -lowerLegHeight - footHeight / 2)
        rightLowerLeg.addChild(rightFoot)

        // Slight stance: legs angled slightly outward
        leftLeg.zRotation = 0.05
        rightLeg.zRotation = -0.05
    }

    // MARK: - Build Body (Torso)

    private func buildBody() {
        let bodyPath = UIBezierPath()
        let shoulderWidth: CGFloat = 38 * scale
        let bodyHeight: CGFloat = 45 * scale
        let waistWidth: CGFloat = 28 * scale

        bodyPath.move(to: CGPoint(x: -shoulderWidth, y: 0))
        bodyPath.addLine(to: CGPoint(x: -waistWidth, y: -bodyHeight))
        bodyPath.addLine(to: CGPoint(x: waistWidth, y: -bodyHeight))
        bodyPath.addLine(to: CGPoint(x: shoulderWidth, y: 0))
        bodyPath.close()

        bodyNode = SKShapeNode(path: bodyPath.cgPath)
        bodyNode.fillColor = style.jacketColor
        bodyNode.strokeColor = style.trimColor
        bodyNode.lineWidth = 2 * scale
        bodyNode.position = CGPoint(x: 0, y: 20 * scale)
        addChild(bodyNode)

        // Belt line at waist
        let beltPath = UIBezierPath()
        beltPath.move(to: CGPoint(x: -(waistWidth + 1 * scale), y: -bodyHeight + 2 * scale))
        beltPath.addLine(to: CGPoint(x: waistWidth + 1 * scale, y: -bodyHeight + 2 * scale))
        let belt = SKShapeNode(path: beltPath.cgPath)
        belt.strokeColor = style.trimColor
        belt.lineWidth = 2.5 * scale
        belt.fillColor = .clear
        bodyNode.addChild(belt)

        // Collar
        let collarPath = UIBezierPath()
        collarPath.move(to: CGPoint(x: -14 * scale, y: 0))
        collarPath.addLine(to: CGPoint(x: 0, y: -20 * scale))
        collarPath.addLine(to: CGPoint(x: 14 * scale, y: 0))
        let collar = SKShapeNode(path: collarPath.cgPath)
        collar.strokeColor = style.collarColor
        collar.lineWidth = 1.5 * scale
        collar.fillColor = .clear
        bodyNode.addChild(collar)
    }

    // MARK: - Build Head

    private func buildHead() {
        head = SKShapeNode(circleOfRadius: 22 * scale)
        head.fillColor = style.skinColor
        head.strokeColor = style.skinColor.withAlphaComponent(0.7)
        head.lineWidth = 1.5 * scale
        head.position = CGPoint(x: 0, y: 52 * scale)
        addChild(head)

        // Hair
        let r: CGFloat = 22 * scale
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
            bow.fontSize = 14 * scale
            bow.position = CGPoint(x: 14 * scale, y: 18 * scale)
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

            let leftCup = SKShapeNode(circleOfRadius: 5 * scale)
            leftCup.fillColor = style.jacketColor
            leftCup.strokeColor = style.trimColor
            leftCup.lineWidth = 1.5 * scale
            leftCup.position = CGPoint(x: -(r + 4 * scale), y: r * 0.3)
            leftCup.zPosition = 3
            head.addChild(leftCup)

            let rightCup = SKShapeNode(circleOfRadius: 5 * scale)
            rightCup.fillColor = style.jacketColor
            rightCup.strokeColor = style.trimColor
            rightCup.lineWidth = 1.5 * scale
            rightCup.position = CGPoint(x: r + 4 * scale, y: r * 0.3)
            rightCup.zPosition = 3
            head.addChild(rightCup)
        }

        if style.hasTiara {
            let tiara = SKLabelNode(text: "👑")
            tiara.fontSize = 15 * scale
            tiara.position = CGPoint(x: 0, y: 20 * scale)
            tiara.zPosition = 3
            if isMirrored { tiara.xScale = -1 }
            head.addChild(tiara)
        }

        if style.hasEarrings {
            let leftEarring = SKShapeNode(circleOfRadius: 2.5 * scale)
            leftEarring.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            leftEarring.strokeColor = .clear
            leftEarring.position = CGPoint(x: -(r + 2 * scale), y: -4 * scale)
            leftEarring.glowWidth = 0.5 * scale
            head.addChild(leftEarring)

            let rightEarring = SKShapeNode(circleOfRadius: 2.5 * scale)
            rightEarring.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            rightEarring.strokeColor = .clear
            rightEarring.position = CGPoint(x: r + 2 * scale, y: -4 * scale)
            rightEarring.glowWidth = 0.5 * scale
            head.addChild(rightEarring)
        }

        if style.hasBeard {
            let beardPath = UIBezierPath()
            beardPath.move(to: CGPoint(x: -10 * scale, y: -8 * scale))
            beardPath.addQuadCurve(to: CGPoint(x: 10 * scale, y: -8 * scale),
                                   controlPoint: CGPoint(x: 0, y: -20 * scale))
            let beard = SKShapeNode(path: beardPath.cgPath)
            beard.fillColor = style.hairColor.withAlphaComponent(0.7)
            beard.strokeColor = style.hairColor
            beard.lineWidth = 1 * scale
            head.addChild(beard)
        }

        // Eyes
        leftEye = SKShapeNode(ellipseOf: CGSize(width: 7 * scale, height: 9 * scale))
        leftEye.fillColor = .white
        leftEye.strokeColor = .black
        leftEye.lineWidth = 1 * scale
        leftEye.position = CGPoint(x: -8 * scale, y: 4 * scale)
        head.addChild(leftEye)

        let leftPupil = SKShapeNode(circleOfRadius: 2.5 * scale)
        leftPupil.fillColor = .black
        leftPupil.strokeColor = .clear
        leftPupil.name = "leftPupil"
        leftEye.addChild(leftPupil)

        rightEye = SKShapeNode(ellipseOf: CGSize(width: 7 * scale, height: 9 * scale))
        rightEye.fillColor = .white
        rightEye.strokeColor = .black
        rightEye.lineWidth = 1 * scale
        rightEye.position = CGPoint(x: 8 * scale, y: 4 * scale)
        head.addChild(rightEye)

        let rightPupil = SKShapeNode(circleOfRadius: 2.5 * scale)
        rightPupil.fillColor = .black
        rightPupil.strokeColor = .clear
        rightPupil.name = "rightPupil"
        rightEye.addChild(rightPupil)

        // Mouth
        mouthLabel = SKLabelNode(text: style.defaultMouth)
        mouthLabel.fontSize = 12 * scale
        mouthLabel.position = CGPoint(x: 0, y: -10 * scale)
        if isMirrored { mouthLabel.xScale = -1 }
        head.addChild(mouthLabel)

        // Eyebrows
        let browColor = style.browColor ?? style.hairColor
        let leftBrow = SKShapeNode(rectOf: CGSize(width: 10 * scale, height: 2 * scale))
        leftBrow.fillColor = browColor
        leftBrow.strokeColor = .clear
        leftBrow.position = CGPoint(x: -8 * scale, y: 12 * scale)
        leftBrow.zRotation = 0.15
        leftBrow.name = "leftBrow"
        head.addChild(leftBrow)

        let rightBrow = SKShapeNode(rectOf: CGSize(width: 10 * scale, height: 2 * scale))
        rightBrow.fillColor = browColor
        rightBrow.strokeColor = .clear
        rightBrow.position = CGPoint(x: 8 * scale, y: 12 * scale)
        rightBrow.zRotation = -0.15
        rightBrow.name = "rightBrow"
        head.addChild(rightBrow)
    }

    // MARK: - Build Arms

    private func buildArms() {
        // Left arm
        leftArm = SKNode()
        leftArm.position = CGPoint(x: -38 * scale, y: 18 * scale)
        addChild(leftArm)

        let leftUpperArm = SKShapeNode(rectOf: CGSize(width: 7 * scale, height: 28 * scale), cornerRadius: 3 * scale)
        leftUpperArm.fillColor = style.armColor
        leftUpperArm.strokeColor = style.armTrimColor
        leftUpperArm.lineWidth = 1 * scale
        leftUpperArm.position = CGPoint(x: 0, y: -14 * scale)
        leftArm.addChild(leftUpperArm)

        leftHand = SKLabelNode(text: "✊")
        leftHand.fontSize = 20 * scale
        leftHand.position = CGPoint(x: 0, y: -32 * scale)
        if isMirrored { leftHand.xScale = -1 }
        leftArm.addChild(leftHand)

        // Right arm
        rightArm = SKNode()
        rightArm.position = CGPoint(x: 38 * scale, y: 18 * scale)
        addChild(rightArm)

        let rightUpperArm = SKShapeNode(rectOf: CGSize(width: 7 * scale, height: 28 * scale), cornerRadius: 3 * scale)
        rightUpperArm.fillColor = style.armColor
        rightUpperArm.strokeColor = style.armTrimColor
        rightUpperArm.lineWidth = 1 * scale
        rightUpperArm.position = CGPoint(x: 0, y: -14 * scale)
        rightArm.addChild(rightUpperArm)

        rightHand = SKLabelNode(text: "✊")
        rightHand.fontSize = 20 * scale
        rightHand.position = CGPoint(x: 0, y: -32 * scale)
        if isMirrored { rightHand.xScale = -1 }
        rightArm.addChild(rightHand)
    }

    // MARK: - Build Accessories

    private func buildAccessories() {
        if style.hasSunglasses {
            let glassesPath = UIBezierPath()
            let glassWidth: CGFloat = 10 * scale
            let glassHeight: CGFloat = 7 * scale

            glassesPath.append(UIBezierPath(roundedRect: CGRect(
                x: -18 * scale, y: 0, width: glassWidth, height: glassHeight), cornerRadius: 2 * scale))
            glassesPath.append(UIBezierPath(roundedRect: CGRect(
                x: 3 * scale, y: 0, width: glassWidth, height: glassHeight), cornerRadius: 2 * scale))
            glassesPath.move(to: CGPoint(x: -8 * scale, y: glassHeight * 0.5))
            glassesPath.addLine(to: CGPoint(x: 3 * scale, y: glassHeight * 0.5))

            sunglasses = SKShapeNode(path: glassesPath.cgPath)
            sunglasses?.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9)
            sunglasses?.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.8, alpha: 1.0)
            sunglasses?.lineWidth = 1.5 * scale
            sunglasses?.position = CGPoint(x: 2 * scale, y: -1 * scale)
            sunglasses?.zPosition = 2
            sunglasses?.isHidden = true
            head.addChild(sunglasses!)
        }

        if style.hasChain {
            let chainPath = UIBezierPath()
            chainPath.move(to: CGPoint(x: -11 * scale, y: -2 * scale))
            chainPath.addQuadCurve(to: CGPoint(x: 11 * scale, y: -2 * scale),
                                   controlPoint: CGPoint(x: 0, y: -12 * scale))
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
        // Reset legs to default stance
        leftLeg.run(SKAction.rotate(toAngle: 0.05, duration: 0.3))
        rightLeg.run(SKAction.rotate(toAngle: -0.05, duration: 0.3))
        leftLowerLeg.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        rightLowerLeg.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        // Reset body position
        self.run(SKAction.move(to: self.position, duration: 0.3))
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

        // Head nod
        let nodDown = SKAction.moveBy(x: 0, y: -3 * scale, duration: 0.15)
        let nodUp = SKAction.moveBy(x: 0, y: 3 * scale, duration: 0.15)
        head.run(SKAction.sequence([nodDown, nodUp]))

        // Subtle weight shift on legs during handshake
        let shiftLeft = SKAction.rotate(toAngle: 0.1, duration: 0.3)
        let shiftRight = SKAction.rotate(toAngle: -0.05, duration: 0.3)
        let shiftBack = SKAction.rotate(toAngle: 0.05, duration: 0.2)
        leftLeg.run(SKAction.sequence([shiftLeft, shiftBack]))
        rightLeg.run(SKAction.sequence([shiftRight, SKAction.rotate(toAngle: -0.05, duration: 0.2)]))
    }

    func animateFreeMovement(completion: @escaping () -> Void) {
        let d: TimeInterval = 0.18

        // Arms swing wider — dance style
        let leftSwing1 = SKAction.rotate(toAngle: 0.9, duration: d)
        let leftSwing2 = SKAction.rotate(toAngle: -0.6, duration: d)
        let leftSwing3 = SKAction.rotate(toAngle: 0.7, duration: d)
        let leftSwing4 = SKAction.rotate(toAngle: -0.3, duration: d)
        let leftReturn = SKAction.rotate(toAngle: 0, duration: d)

        let rightSwing1 = SKAction.rotate(toAngle: -0.8, duration: d)
        let rightSwing2 = SKAction.rotate(toAngle: 0.9, duration: d)
        let rightSwing3 = SKAction.rotate(toAngle: -0.5, duration: d)
        let rightSwing4 = SKAction.rotate(toAngle: 0.4, duration: d)
        let rightReturn = SKAction.rotate(toAngle: 0, duration: d)

        leftArm.run(SKAction.sequence([leftSwing1, leftSwing2, leftSwing3, leftSwing4, leftReturn]))
        rightArm.run(SKAction.sequence([rightSwing1, rightSwing2, rightSwing3, rightSwing4, rightReturn])) {
            completion()
        }

        // Body bounces more energetically
        let bounceUp = SKAction.moveBy(x: 0, y: 6 * scale, duration: d)
        bounceUp.timingMode = .easeOut
        let bounceDown = SKAction.moveBy(x: 0, y: -6 * scale, duration: d)
        bounceDown.timingMode = .easeIn
        let bounce = SKAction.sequence([bounceUp, bounceDown])
        bodyNode.run(SKAction.repeat(bounce, count: 3))

        // Body rotates slightly side to side
        let rotL = SKAction.rotate(byAngle: 0.08, duration: d)
        let rotR = SKAction.rotate(byAngle: -0.16, duration: d)
        let rotBack = SKAction.rotate(byAngle: 0.08, duration: d)
        bodyNode.run(SKAction.sequence([rotL, rotR, rotBack, rotL, rotR, rotBack]))

        // Head sways
        let swayLeft = SKAction.rotate(byAngle: 0.12, duration: d)
        let swayRight = SKAction.rotate(byAngle: -0.24, duration: d)
        let swayBack = SKAction.rotate(byAngle: 0.12, duration: d)
        head.run(SKAction.sequence([swayLeft, swayRight, swayBack, swayLeft, swayRight, swayBack]))

        // Legs kick and step
        let legKickOut = SKAction.rotate(toAngle: 0.3, duration: d)
        let legKickIn = SKAction.rotate(toAngle: -0.15, duration: d)
        let legReset = SKAction.rotate(toAngle: 0.05, duration: d)
        let legKickOutR = SKAction.rotate(toAngle: -0.3, duration: d)
        let legKickInR = SKAction.rotate(toAngle: 0.15, duration: d)
        let legResetR = SKAction.rotate(toAngle: -0.05, duration: d)

        leftLeg.run(SKAction.sequence([
            legKickOut, legReset, legKickIn, legReset, legKickOut, legReset
        ]))
        rightLeg.run(SKAction.sequence([
            legKickOutR, legResetR, legKickInR, legResetR, legKickOutR, legResetR
        ]))

        // Lower legs bend for stepping effect
        let kneeBend = SKAction.rotate(toAngle: -0.25, duration: d)
        let kneeStr = SKAction.rotate(toAngle: 0, duration: d)
        leftLowerLeg.run(SKAction.sequence([kneeBend, kneeStr, kneeStr, kneeBend, kneeBend, kneeStr]))
        rightLowerLeg.run(SKAction.sequence([kneeStr, kneeBend, kneeBend, kneeStr, kneeStr, kneeBend]))

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

        // Arms pump up
        let armsUp = SKAction.rotate(toAngle: 1.5, duration: 0.3)
        leftArm.run(armsUp)
        rightArm.run(armsUp)

        // Whole body jumps up then down (victory jump)
        let jumpUp = SKAction.moveBy(x: 0, y: 15 * scale, duration: 0.2)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.moveBy(x: 0, y: -15 * scale, duration: 0.2)
        jumpDown.timingMode = .easeIn
        let jump = SKAction.sequence([jumpUp, jumpDown])
        self.run(SKAction.repeat(jump, count: 3))

        // Legs spread apart on jump
        let spreadL = SKAction.rotate(toAngle: 0.35, duration: 0.2)
        let closeL = SKAction.rotate(toAngle: 0.05, duration: 0.2)
        let spreadR = SKAction.rotate(toAngle: -0.35, duration: 0.2)
        let closeR = SKAction.rotate(toAngle: -0.05, duration: 0.2)
        leftLeg.run(SKAction.repeat(SKAction.sequence([spreadL, closeL]), count: 3))
        rightLeg.run(SKAction.repeat(SKAction.sequence([spreadR, closeR]), count: 3))

        // Lower legs kick out during jump
        let kickOut = SKAction.rotate(toAngle: 0.3, duration: 0.2)
        let kickBack = SKAction.rotate(toAngle: 0, duration: 0.2)
        leftLowerLeg.run(SKAction.repeat(SKAction.sequence([kickOut, kickBack]), count: 3))
        rightLowerLeg.run(SKAction.repeat(SKAction.sequence([kickOut, kickBack]), count: 3))

        leftHand.text = "🎉"
        rightHand.text = "🎉"
    }

    func animateLose() {
        setExpression(.sad)

        // Arms droop down
        let armsDown = SKAction.rotate(toAngle: -0.3, duration: 0.5)
        leftArm.run(armsDown)
        rightArm.run(armsDown)

        // Head droops further
        let headDroop = SKAction.moveBy(x: 0, y: -6 * scale, duration: 0.4)
        headDroop.timingMode = .easeIn
        head.run(headDroop)

        // Whole body sinks down
        let sink = SKAction.moveBy(x: 0, y: -8 * scale, duration: 0.5)
        sink.timingMode = .easeIn
        self.run(sink)

        // Knees bend inward — legs rotate toward center
        let leftKneeBend = SKAction.rotate(toAngle: -0.2, duration: 0.5)
        let rightKneeBend = SKAction.rotate(toAngle: 0.2, duration: 0.5)
        leftLeg.run(leftKneeBend)
        rightLeg.run(rightKneeBend)

        // Lower legs bend (knees buckling)
        let lowerBend = SKAction.rotate(toAngle: -0.35, duration: 0.5)
        leftLowerLeg.run(lowerBend)
        rightLowerLeg.run(lowerBend)

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

        // Stagger side to side (whole node sways)
        let staggerRight = SKAction.moveBy(x: 6 * scale, y: 0, duration: 0.3)
        staggerRight.timingMode = .easeInEaseOut
        let staggerLeft = SKAction.moveBy(x: -12 * scale, y: 0, duration: 0.5)
        staggerLeft.timingMode = .easeInEaseOut
        let staggerBack = SKAction.moveBy(x: 6 * scale, y: 0, duration: 0.3)
        staggerBack.timingMode = .easeInEaseOut
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            staggerRight, staggerLeft, staggerBack
        ]))

        // Legs wobble
        let wobbleL1 = SKAction.rotate(toAngle: 0.15, duration: 0.25)
        let wobbleL2 = SKAction.rotate(toAngle: -0.1, duration: 0.3)
        let wobbleL3 = SKAction.rotate(toAngle: 0.05, duration: 0.25)
        let wobbleR1 = SKAction.rotate(toAngle: -0.15, duration: 0.25)
        let wobbleR2 = SKAction.rotate(toAngle: 0.1, duration: 0.3)
        let wobbleR3 = SKAction.rotate(toAngle: -0.05, duration: 0.25)

        leftLeg.run(SKAction.sequence([wobbleL1, wobbleL2, wobbleL3]))
        rightLeg.run(SKAction.sequence([wobbleR1, wobbleR2, wobbleR3]))

        // Lower legs buckle slightly
        let kneeWobble1 = SKAction.rotate(toAngle: -0.15, duration: 0.3)
        let kneeWobble2 = SKAction.rotate(toAngle: 0.05, duration: 0.25)
        let kneeWobble3 = SKAction.rotate(toAngle: 0, duration: 0.2)
        leftLowerLeg.run(SKAction.sequence([kneeWobble1, kneeWobble2, kneeWobble3]))
        rightLowerLeg.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            kneeWobble1, kneeWobble2, kneeWobble3
        ]))
    }

    func animateTell(_ gesture: Gesture, delay: TimeInterval, duration: TimeInterval) {
        let showTell = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { self.rightHand.text = gesture.emoji },
            SKAction.run {
                let raise = SKAction.rotate(toAngle: 0.3, duration: 0.15)
                self.rightArm.run(raise)
            },
            SKAction.wait(forDuration: duration),
            SKAction.run { self.rightHand.text = "✊" },
            SKAction.run {
                let lower = SKAction.rotate(toAngle: 0, duration: 0.15)
                self.rightArm.run(lower)
            }
        ])
        self.run(showTell)
    }

    func animateIdle() {
        // Body bobs up/down 3pt
        let bobUp = SKAction.moveBy(x: 0, y: 3 * scale, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -3 * scale, duration: 1.0)
        bobDown.timingMode = .easeInEaseOut
        let bob = SKAction.sequence([bobUp, bobDown])
        bodyNode.run(SKAction.repeatForever(bob), withKey: "idle")

        // Arms swing slightly in opposite directions
        let leftSwingOut = SKAction.rotate(toAngle: 0.08, duration: 1.2)
        leftSwingOut.timingMode = .easeInEaseOut
        let leftSwingIn = SKAction.rotate(toAngle: -0.06, duration: 1.2)
        leftSwingIn.timingMode = .easeInEaseOut
        leftArm.run(SKAction.repeatForever(SKAction.sequence([leftSwingOut, leftSwingIn])), withKey: "idleLeftArm")

        let rightSwingOut = SKAction.rotate(toAngle: -0.08, duration: 1.2)
        rightSwingOut.timingMode = .easeInEaseOut
        let rightSwingIn = SKAction.rotate(toAngle: 0.06, duration: 1.2)
        rightSwingIn.timingMode = .easeInEaseOut
        rightArm.run(SKAction.repeatForever(SKAction.sequence([rightSwingOut, rightSwingIn])), withKey: "idleRightArm")

        // Head tilts slightly side to side
        let tiltLeft = SKAction.rotate(toAngle: 0.04, duration: 1.5)
        tiltLeft.timingMode = .easeInEaseOut
        let tiltRight = SKAction.rotate(toAngle: -0.04, duration: 1.5)
        tiltRight.timingMode = .easeInEaseOut
        head.run(SKAction.repeatForever(SKAction.sequence([tiltLeft, tiltRight])), withKey: "idleHead")

        // Legs do subtle weight-shift
        let leftShift = SKAction.rotate(toAngle: 0.08, duration: 1.3)
        leftShift.timingMode = .easeInEaseOut
        let leftReturn = SKAction.rotate(toAngle: 0.05, duration: 1.3)
        leftReturn.timingMode = .easeInEaseOut
        leftLeg.run(SKAction.repeatForever(SKAction.sequence([leftShift, leftReturn])), withKey: "idleLeftLeg")

        let rightShift = SKAction.rotate(toAngle: -0.08, duration: 1.3)
        rightShift.timingMode = .easeInEaseOut
        let rightReturn = SKAction.rotate(toAngle: -0.05, duration: 1.3)
        rightReturn.timingMode = .easeInEaseOut
        rightLeg.run(SKAction.repeatForever(SKAction.sequence([rightShift, rightReturn])), withKey: "idleRightLeg")

        // Blinking
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
        head.removeAction(forKey: "idleHead")
        leftArm.removeAction(forKey: "idleLeftArm")
        rightArm.removeAction(forKey: "idleRightArm")
        leftLeg.removeAction(forKey: "idleLeftLeg")
        rightLeg.removeAction(forKey: "idleRightLeg")
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        // Reset rotations from idle
        head.run(SKAction.rotate(toAngle: 0, duration: 0.15))
        leftArm.run(SKAction.rotate(toAngle: 0, duration: 0.15))
        rightArm.run(SKAction.rotate(toAngle: 0, duration: 0.15))
        leftLeg.run(SKAction.rotate(toAngle: 0.05, duration: 0.15))
        rightLeg.run(SKAction.rotate(toAngle: -0.05, duration: 0.15))
    }
}
