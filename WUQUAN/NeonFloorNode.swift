import SpriteKit

class NeonFloorNode: SKNode {

    private let floorSize: CGSize

    init(size: CGSize) {
        self.floorSize = size
        super.init()
        buildBackground()
        buildGrid()
        buildHorizonLine()
        animateGrid()
    }

    required init?(coder aDecoder: NSCoder) {
        self.floorSize = .zero
        super.init(coder: aDecoder)
    }

    private func buildBackground() {
        // Dark gradient background - bottom portion is dark purple, top is near-black
        let bgNode = SKSpriteNode(color: SKColor(red: 0.05, green: 0.02, blue: 0.1, alpha: 1.0), size: floorSize)
        bgNode.position = CGPoint(x: floorSize.width / 2, y: floorSize.height / 2)
        bgNode.zPosition = -10
        addChild(bgNode)

        // Floor gradient overlay (bottom 40%)
        let floorHeight = floorSize.height * 0.4
        let floorBg = SKShapeNode(rect: CGRect(x: 0, y: 0, width: floorSize.width, height: floorHeight))
        floorBg.fillColor = SKColor(red: 0.08, green: 0.02, blue: 0.15, alpha: 1.0)
        floorBg.strokeColor = .clear
        floorBg.zPosition = -9
        addChild(floorBg)
    }

    private func buildGrid() {
        let floorHeight = floorSize.height * 0.4
        let horizonY = floorHeight
        let vanishX = floorSize.width / 2
        let lineCount = 12

        // Vertical perspective lines (converging to vanishing point)
        let spreadAtBottom = floorSize.width * 1.2
        for i in 0...lineCount {
            let fraction = CGFloat(i) / CGFloat(lineCount)
            let bottomX = (floorSize.width - spreadAtBottom) / 2 + fraction * spreadAtBottom

            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: bottomX, y: 0))
            path.addLine(to: CGPoint(x: vanishX, y: horizonY))
            line.path = path
            line.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3)
            line.lineWidth = 1.0
            line.glowWidth = 1.5
            line.zPosition = -8
            line.name = "gridLine"
            addChild(line)
        }

        // Horizontal lines (spaced with perspective — closer together near horizon)
        let hLineCount = 8
        for i in 1...hLineCount {
            // Perspective spacing: lines bunch up near horizon
            let t = CGFloat(i) / CGFloat(hLineCount)
            let y = pow(t, 0.5) * floorHeight  // Square root for perspective

            let line = SKShapeNode()
            let path = CGMutablePath()

            // Calculate width at this y (narrower near horizon)
            let widthFraction = 1.0 - (y / floorHeight) * 0.6
            let halfWidth = (floorSize.width * widthFraction) / 2
            let centerX = floorSize.width / 2

            path.move(to: CGPoint(x: centerX - halfWidth, y: y))
            path.addLine(to: CGPoint(x: centerX + halfWidth, y: y))
            line.path = path
            line.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 0.25)
            line.lineWidth = 1.0
            line.glowWidth = 1.0
            line.zPosition = -8
            line.name = "hGridLine_\(i)"
            addChild(line)
        }
    }

    private func buildHorizonLine() {
        let horizonY = floorSize.height * 0.4

        let horizon = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: horizonY))
        path.addLine(to: CGPoint(x: floorSize.width, y: horizonY))
        horizon.path = path
        horizon.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.8)
        horizon.lineWidth = 2.0
        horizon.glowWidth = 4.0
        horizon.zPosition = -7
        addChild(horizon)

        // Horizon glow
        let glowLine = horizon.copy() as! SKShapeNode
        glowLine.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.9, alpha: 0.3)
        glowLine.lineWidth = 6.0
        glowLine.glowWidth = 8.0
        glowLine.zPosition = -7.5
        addChild(glowLine)
    }

    private func animateGrid() {
        // Pulse the grid lines
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 2.0),
            SKAction.fadeAlpha(to: 0.35, duration: 2.0)
        ])
        let repeatPulse = SKAction.repeatForever(pulse)

        children.filter { $0.name == "gridLine" }.forEach { node in
            node.run(repeatPulse)
        }

        // Scroll horizontal lines downward for motion effect
        for child in children {
            guard let name = child.name, name.hasPrefix("hGridLine_") else { continue }
            let shift = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -3, duration: 1.0),
                SKAction.moveBy(x: 0, y: 3, duration: 1.0)
            ])
            child.run(SKAction.repeatForever(shift))
        }
    }
}
