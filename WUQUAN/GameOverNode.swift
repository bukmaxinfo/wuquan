//
//  GameOverNode.swift
//  WUQUAN
//
//  Created by Claude Code on 4/2/26.
//

import SpriteKit

class GameOverNode: SKNode {

    // MARK: - Properties

    private let overlaySize: CGSize
    private let playerScore: Int
    private let aiScore: Int
    private let playerName: String
    private let opponentName: String
    private let totalDrinks: Int
    private let bestStreak: Int
    private let favoriteGesture: String
    private let roundsPlayed: Int

    // MARK: - Neon Colors

    private let cyanNeon = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
    private let magentaNeon = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1.0)
    private let yellowNeon = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
    private let darkPurple = SKColor(red: 0.05, green: 0.02, blue: 0.1, alpha: 0.85)
    private let panelFill = SKColor(red: 0.08, green: 0.03, blue: 0.12, alpha: 0.95)

    // MARK: - Init

    init(size: CGSize, playerScore: Int, aiScore: Int, playerName: String, opponentName: String, totalDrinks: Int, bestStreak: Int, favoriteGesture: String, roundsPlayed: Int) {
        self.overlaySize = size
        self.playerScore = playerScore
        self.aiScore = aiScore
        self.playerName = playerName
        self.opponentName = opponentName
        self.totalDrinks = totalDrinks
        self.bestStreak = bestStreak
        self.favoriteGesture = favoriteGesture
        self.roundsPlayed = roundsPlayed
        super.init()
        self.isUserInteractionEnabled = true
        self.zPosition = 1000
        buildOverlay()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Build

    private func buildOverlay() {
        // Full-screen semi-transparent background
        let background = SKShapeNode(rect: CGRect(origin: CGPoint(x: -overlaySize.width / 2, y: -overlaySize.height / 2), size: overlaySize))
        background.fillColor = darkPurple
        background.strokeColor = .clear
        background.zPosition = 0
        background.name = "gameOverBackground"
        addChild(background)

        // Center panel
        let panelWidth = overlaySize.width * 0.85
        let panelHeight = overlaySize.height * 0.72
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 20)
        panel.fillColor = panelFill
        panel.strokeColor = cyanNeon.withAlphaComponent(0.6)
        panel.lineWidth = 2.5
        panel.glowWidth = 4
        panel.zPosition = 1
        panel.name = "gameOverPanel"
        addChild(panel)

        // Start panel off-screen (below) for slide-in animation
        let panelFinalY: CGFloat = 0
        panel.position = CGPoint(x: 0, y: -overlaySize.height)

        // Slide in with spring effect
        let slideUp = SKAction.move(to: CGPoint(x: 0, y: panelFinalY), duration: 0.5)
        slideUp.timingMode = .easeOut
        let overshoot = SKAction.moveBy(x: 0, y: 20, duration: 0.1)
        overshoot.timingMode = .easeOut
        let settleBack = SKAction.moveBy(x: 0, y: -20, duration: 0.15)
        settleBack.timingMode = .easeInEaseOut
        panel.run(SKAction.sequence([slideUp, overshoot, settleBack]))

        // Layout positions (relative to panel center)
        let topY = panelHeight / 2
        var currentY = topY - panelHeight * 0.08

        // --- Result Title ---
        let resultText: String
        let resultColor: SKColor
        if playerScore > aiScore {
            resultText = "你赢了! 🏆"
            resultColor = yellowNeon
        } else if playerScore < aiScore {
            resultText = "你输了..."
            resultColor = SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1.0)
        } else {
            resultText = "平局！"
            resultColor = cyanNeon
        }

        let titleLabel = SKLabelNode(text: resultText)
        titleLabel.fontSize = min(panelWidth * 0.1, 42)
        titleLabel.fontColor = resultColor
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.verticalAlignmentMode = .top
        titleLabel.position = CGPoint(x: 0, y: currentY)
        titleLabel.zPosition = 2
        panel.addChild(titleLabel)

        // Title glow
        let titleGlow = SKLabelNode(text: resultText)
        titleGlow.fontSize = titleLabel.fontSize
        titleGlow.fontColor = resultColor.withAlphaComponent(0.2)
        titleGlow.fontName = "Helvetica-Bold"
        titleGlow.verticalAlignmentMode = .top
        titleGlow.position = titleLabel.position
        titleGlow.zPosition = 1
        panel.addChild(titleGlow)

        // Pulse animation for winner text
        let pulseGlow = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.8),
            SKAction.fadeAlpha(to: 0.35, duration: 0.8)
        ]))
        titleGlow.run(pulseGlow)

        let pulseScale = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9)
        ]))
        titleLabel.run(pulseScale)

        currentY -= panelHeight * 0.12

        // --- Score Section ---
        let scoreContainer = SKNode()
        scoreContainer.position = CGPoint(x: 0, y: currentY)
        scoreContainer.zPosition = 2
        panel.addChild(scoreContainer)

        let scoreFontSize = min(panelWidth * 0.065, 28)

        // Player name
        let playerNameLabel = SKLabelNode(text: playerName)
        playerNameLabel.fontSize = scoreFontSize * 0.8
        playerNameLabel.fontColor = cyanNeon
        playerNameLabel.fontName = "Helvetica-Bold"
        playerNameLabel.horizontalAlignmentMode = .right
        playerNameLabel.position = CGPoint(x: -panelWidth * 0.08, y: 0)
        scoreContainer.addChild(playerNameLabel)

        // Player score (count-up)
        let playerScoreLabel = SKLabelNode(text: "0")
        playerScoreLabel.fontSize = scoreFontSize * 1.4
        playerScoreLabel.fontColor = .white
        playerScoreLabel.fontName = "Helvetica-Bold"
        playerScoreLabel.horizontalAlignmentMode = .right
        playerScoreLabel.position = CGPoint(x: -panelWidth * 0.02, y: -scoreFontSize * 0.2)
        scoreContainer.addChild(playerScoreLabel)

        // Colon
        let colonLabel = SKLabelNode(text: ":")
        colonLabel.fontSize = scoreFontSize * 1.4
        colonLabel.fontColor = .white
        colonLabel.fontName = "Helvetica-Bold"
        colonLabel.position = CGPoint(x: 0, y: -scoreFontSize * 0.2)
        scoreContainer.addChild(colonLabel)

        // AI score (count-up)
        let aiScoreLabel = SKLabelNode(text: "0")
        aiScoreLabel.fontSize = scoreFontSize * 1.4
        aiScoreLabel.fontColor = .white
        aiScoreLabel.fontName = "Helvetica-Bold"
        aiScoreLabel.horizontalAlignmentMode = .left
        aiScoreLabel.position = CGPoint(x: panelWidth * 0.02, y: -scoreFontSize * 0.2)
        scoreContainer.addChild(aiScoreLabel)

        // Opponent name
        let opponentNameLabel = SKLabelNode(text: opponentName)
        opponentNameLabel.fontSize = scoreFontSize * 0.8
        opponentNameLabel.fontColor = magentaNeon
        opponentNameLabel.fontName = "Helvetica-Bold"
        opponentNameLabel.horizontalAlignmentMode = .left
        opponentNameLabel.position = CGPoint(x: panelWidth * 0.08, y: 0)
        scoreContainer.addChild(opponentNameLabel)

        // Animate score count-up
        animateCountUp(label: playerScoreLabel, to: playerScore, duration: 1.0, delay: 0.6)
        animateCountUp(label: aiScoreLabel, to: aiScore, duration: 1.0, delay: 0.6)

        currentY -= panelHeight * 0.1

        // --- Divider ---
        let dividerWidth = panelWidth * 0.7
        let divider = SKShapeNode(rectOf: CGSize(width: dividerWidth, height: 1.5))
        divider.fillColor = cyanNeon.withAlphaComponent(0.3)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: currentY)
        divider.zPosition = 2
        panel.addChild(divider)

        currentY -= panelHeight * 0.06

        // --- Stats Section ---
        let statFontSize = min(panelWidth * 0.05, 20)
        let statSpacing = panelHeight * 0.07

        let stats: [(icon: String, label: String, value: String)] = [
            ("🍺", "Total drinks", "\(totalDrinks)"),
            ("🔥", "Best streak", "\(bestStreak)"),
            (favoriteGesture, "Favorite gesture", favoriteGesture),
            ("📊", "Rounds", "\(roundsPlayed)")
        ]

        for (index, stat) in stats.enumerated() {
            let statNode = createStatRow(
                icon: stat.icon,
                label: stat.label,
                value: stat.value,
                fontSize: statFontSize,
                width: panelWidth * 0.7,
                yPosition: currentY - CGFloat(index) * statSpacing
            )
            statNode.zPosition = 2
            statNode.alpha = 0

            panel.addChild(statNode)

            // Staggered fade-in
            let delay = 0.8 + Double(index) * 0.3
            statNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 1.0, duration: 0.3)
            ]))
        }

        currentY -= statSpacing * CGFloat(stats.count) + panelHeight * 0.04

        // --- Buttons ---
        let buttonWidth = panelWidth * 0.38
        let buttonHeight = panelHeight * 0.08
        let buttonFontSize = min(panelWidth * 0.05, 20)
        let buttonY = -topY + panelHeight * 0.1

        // Play Again button — cyan neon
        let playAgainButton = createNeonButton(
            text: "再来一局",
            name: "playAgainButton",
            width: buttonWidth,
            height: buttonHeight,
            fontSize: buttonFontSize,
            borderColor: cyanNeon,
            position: CGPoint(x: -panelWidth * 0.22, y: buttonY)
        )
        playAgainButton.zPosition = 2
        panel.addChild(playAgainButton)

        // Change Character button — magenta neon
        let changeButton = createNeonButton(
            text: "换角色",
            name: "changeCharacterButton",
            width: buttonWidth,
            height: buttonHeight,
            fontSize: buttonFontSize,
            borderColor: magentaNeon,
            position: CGPoint(x: panelWidth * 0.22, y: buttonY)
        )
        changeButton.zPosition = 2
        panel.addChild(changeButton)
    }

    // MARK: - Helpers

    private func createStatRow(icon: String, label: String, value: String, fontSize: CGFloat, width: CGFloat, yPosition: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: yPosition)

        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = fontSize * 1.2
        iconLabel.horizontalAlignmentMode = .left
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: -width / 2, y: 0)
        container.addChild(iconLabel)

        let textLabel = SKLabelNode(text: label)
        textLabel.fontSize = fontSize
        textLabel.fontColor = SKColor(white: 0.75, alpha: 1.0)
        textLabel.fontName = "Helvetica-Bold"
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .center
        textLabel.position = CGPoint(x: -width / 2 + fontSize * 2, y: 0)
        container.addChild(textLabel)

        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontSize = fontSize * 1.1
        valueLabel.fontColor = yellowNeon
        valueLabel.fontName = "Helvetica-Bold"
        valueLabel.horizontalAlignmentMode = .right
        valueLabel.verticalAlignmentMode = .center
        valueLabel.position = CGPoint(x: width / 2, y: 0)
        container.addChild(valueLabel)

        return container
    }

    private func createNeonButton(text: String, name: String, width: CGFloat, height: CGFloat, fontSize: CGFloat, borderColor: SKColor, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height * 0.35)
        bg.fillColor = SKColor(red: 0.08, green: 0.03, blue: 0.12, alpha: 0.9)
        bg.strokeColor = borderColor.withAlphaComponent(0.7)
        bg.lineWidth = 2.0
        bg.glowWidth = 3
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontColor = .white
        label.fontName = "Helvetica-Bold"
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    private func animateCountUp(label: SKLabelNode, to targetValue: Int, duration: TimeInterval, delay: TimeInterval) {
        guard targetValue > 0 else { return }

        let steps = min(targetValue, 30)
        let stepDuration = duration / Double(steps)

        var actions: [SKAction] = [SKAction.wait(forDuration: delay)]

        for i in 1...steps {
            let value = Int(round(Double(i) / Double(steps) * Double(targetValue)))
            actions.append(SKAction.run { [weak label] in
                label?.text = "\(value)"
            })
            actions.append(SKAction.wait(forDuration: stepDuration))
        }

        label.run(SKAction.sequence(actions))
    }
}
