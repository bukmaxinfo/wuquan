import SpriteKit

class NeonFloorNode: SKNode {

    private let floorSize: CGSize
    private let theme: GameTheme

    init(size: CGSize, theme: GameTheme = .neon) {
        self.floorSize = size
        self.theme = theme
        super.init()
        buildBackground()
        buildGrid()
        buildHorizonLine()
        animateGrid()
    }

    required init?(coder aDecoder: NSCoder) {
        self.floorSize = .zero
        self.theme = .neon
        super.init(coder: aDecoder)
    }

    private func buildBackground() {
        let bgNode = SKSpriteNode(color: theme.backgroundColor, size: floorSize)
        bgNode.position = CGPoint(x: floorSize.width / 2, y: floorSize.height / 2)
        bgNode.zPosition = -10
        addChild(bgNode)

        let floorHeight = floorSize.height * 0.4
        let floorBg = SKShapeNode(rect: CGRect(x: 0, y: 0, width: floorSize.width, height: floorHeight))
        floorBg.fillColor = theme.floorBgColor
        floorBg.strokeColor = .clear
        floorBg.zPosition = -9
        addChild(floorBg)
    }

    private func buildGrid() {
        let floorHeight = floorSize.height * 0.4
        let horizonY = floorHeight
        let vanishX = floorSize.width / 2
        let lineCount = 12
        let spreadAtBottom = floorSize.width * 1.2

        for i in 0...lineCount {
            let fraction = CGFloat(i) / CGFloat(lineCount)
            let bottomX = (floorSize.width - spreadAtBottom) / 2 + fraction * spreadAtBottom

            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: bottomX, y: 0))
            path.addLine(to: CGPoint(x: vanishX, y: horizonY))
            line.path = path
            line.strokeColor = theme.gridLineColor
            line.lineWidth = 1.0
            line.glowWidth = 1.5
            line.zPosition = -8
            line.name = "gridLine"
            addChild(line)
        }

        let hLineCount = 8
        for i in 1...hLineCount {
            let t = CGFloat(i) / CGFloat(hLineCount)
            let y = pow(t, 0.5) * floorHeight

            let line = SKShapeNode()
            let path = CGMutablePath()
            let widthFraction = 1.0 - (y / floorHeight) * 0.6
            let halfWidth = (floorSize.width * widthFraction) / 2
            let centerX = floorSize.width / 2
            path.move(to: CGPoint(x: centerX - halfWidth, y: y))
            path.addLine(to: CGPoint(x: centerX + halfWidth, y: y))
            line.path = path
            line.strokeColor = theme.gridHLineColor
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
        horizon.strokeColor = theme.horizonColor
        horizon.lineWidth = 2.0
        horizon.glowWidth = 4.0
        horizon.zPosition = -7
        addChild(horizon)

        // Glow copy
        let glowLine = horizon.copy() as! SKShapeNode
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        theme.horizonColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        glowLine.strokeColor = SKColor(red: r, green: g, blue: b, alpha: 0.3)
        glowLine.lineWidth = 6.0
        glowLine.glowWidth = 8.0
        glowLine.zPosition = -7.5
        addChild(glowLine)
    }

    private func animateGrid() {
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 2.0),
            SKAction.fadeAlpha(to: 0.35, duration: 2.0)
        ])
        children.filter { $0.name == "gridLine" }.forEach {
            $0.run(SKAction.repeatForever(pulse))
        }

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
