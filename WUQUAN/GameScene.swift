//
//  GameScene.swift
//  WUQUAN
//
//  Created by shuming li on 7/19/25.
//

import SpriteKit
import GameplayKit
import AVFoundation
import MediaPlayer
import AudioToolbox

enum GamePhase {
    case handshake(step: Int)
    case freeMovement(step: Int)
    case gestureSelection
    case directionPointing
    case result
}

enum Gesture: CaseIterable, Equatable {
    case rock, paper, scissors

    var emoji: String {
        switch self {
        case .rock: return "✊"
        case .paper: return "✋"
        case .scissors: return "✌️"
        }
    }
}

enum Direction: CaseIterable, Equatable {
    case up, down, left, right

    var emoji: String {
        switch self {
        case .up: return "⬆️"
        case .down: return "⬇️"
        case .left: return "⬅️"
        case .right: return "➡️"
        }
    }
}

enum RoundResult: Equatable {
    case continueGame   // Rule followed correctly
    case playerLoses    // Player violated the rule
    case aiLoses        // AI violated the rule
}

enum Difficulty: Int, CaseIterable {
    case easy = 0, medium, hard

    var label: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "普通"
        case .hard: return "困难"
        }
    }

    var adaptThreshold: Int {
        switch self {
        case .easy: return 999   // Never adapts
        case .medium: return 3
        case .hard: return 2
        }
    }

    var counterWeight: Double {
        switch self {
        case .easy: return 0.35
        case .medium: return 0.5
        case .hard: return 0.7
        }
    }
}

struct GameRules {
    static func evaluateRound(playerGesture: Gesture, aiGesture: Gesture,
                              playerDirection: Direction, aiDirection: Direction) -> RoundResult {
        let sameGesture = playerGesture == aiGesture
        let sameDirection = playerDirection == aiDirection

        if sameGesture && sameDirection {
            return .continueGame
        } else if !sameGesture && !sameDirection {
            return .continueGame
        } else if sameGesture && !sameDirection {
            return .playerLoses
        } else {
            return .aiLoses
        }
    }
}

struct DeviceInfo {
    let screenSize: CGSize
    let deviceType: String
    let safeArea: UIEdgeInsets
}

class GameScene: SKScene, SettingsViewControllerDelegate, GameRulesDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()

    // Character styles (set before scene is presented)
    var playerStyle: CharacterStyle = .sportyGuy
    var opponentStyle: CharacterStyle = .nightclubPrince
    
    private var lastUpdateTime : TimeInterval = 0
    private var gamePhase: GamePhase = .handshake(step: 1)
    
    // UI Elements
    private var phaseLabel: SKLabelNode?
    private var playerGestureLabel: SKLabelNode?
    private var aiGestureLabel: SKLabelNode?
    private var instructionLabel: SKLabelNode?
    private var playerHandNode: SKShapeNode?
    private var aiHandNode: SKShapeNode?
    
    // Game State
    private var playerGesture: Gesture?
    private var aiGesture: Gesture?
    private var playerDirection: Direction?
    private var aiDirection: Direction?
    private var currentStreak: Int = 0
    private var selectionTimer: Timer?
    private var timerLabel: SKLabelNode?
    private var selectionDeadline: Date?
    private var playerGestureHistory: [Gesture] = []
    private var difficulty: Difficulty = Difficulty(rawValue: UserDefaults.standard.integer(forKey: "difficulty")) ?? .medium
    private var roundCount = 0
    private let maxRounds = 10
    private var totalDrinksThisGame = 0
    private var bestStreakThisGame = 0
    private var gestureCountsThisGame: [Gesture: Int] = [.rock: 0, .paper: 0, .scissors: 0]
    private var isDismissingTutorial = false
    private var totalGamesPlayed: Int {
        get { UserDefaults.standard.integer(forKey: "totalGamesPlayed") }
        set { UserDefaults.standard.set(newValue, forKey: "totalGamesPlayed") }
    }
    private var totalWins: Int {
        get { UserDefaults.standard.integer(forKey: "totalWins") }
        set { UserDefaults.standard.set(newValue, forKey: "totalWins") }
    }
    private var gameScore: (player: Int, ai: Int) = (
        player: UserDefaults.standard.integer(forKey: "playerScore"),
        ai: UserDefaults.standard.integer(forKey: "aiScore")
    )
    
    // Music System
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var selectedMusicURL: URL?
    private var musicButton: SKLabelNode?
    
    // Characters
    private var playerCharacter: SpriteCharacterNode?
    private var characterNode: SpriteCharacterNode?

    // Settings System
    private var settingsOverlay: SKNode?
    private var isSettingsVisible = false
    private var gameWasPaused = false
    private var hiddenGameButtons: [SKNode] = []
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        // Remove all template nodes from the .sks file (including any "Hello" labels)
        removeAllChildren()
    }
    
    override func didMove(to view: SKView) {
        setupUI()
        setupAutoMusic()

        if !UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
            showTutorial()
        } else {
            startHandshakePhase()
        }
    }

    private func showTutorial() {
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.9)
        overlay.zPosition = 100
        overlay.name = "tutorialOverlay"
        addChild(overlay)

        let lines = [
            "欢迎来到舞拳！",
            "",
            "🤝 先与对手握手热身",
            "✊✋✌️ 选择石头、布或剪刀",
            "⬆️⬇️⬅️➡️ 然后选择方向",
            "",
            "规则：",
            "手势相同 → 方向必须相同",
            "手势不同 → 方向必须不同",
            "",
            "📱 摇动手机可快速随机选择！",
            "",
            "点击任意位置开始"
        ]

        let text = lines.joined(separator: "\n")
        let tutorialLabel = SKLabelNode()
        tutorialLabel.text = text
        tutorialLabel.numberOfLines = 0
        tutorialLabel.fontSize = min(size.width, size.height) * 0.035
        tutorialLabel.fontColor = .white
        tutorialLabel.preferredMaxLayoutWidth = size.width * 0.8
        tutorialLabel.horizontalAlignmentMode = .center
        tutorialLabel.verticalAlignmentMode = .center
        tutorialLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tutorialLabel.zPosition = 101
        tutorialLabel.name = "tutorialOverlay"
        addChild(tutorialLabel)
    }

    private func dismissTutorial() {
        guard !isDismissingTutorial else { return }
        isDismissingTutorial = true
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        children.filter { $0.name == "tutorialOverlay" }.forEach { node in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startHandshakePhase()
        }
    }
    
    private func setupUI() {
        backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.1, alpha: 1.0)

        // Neon grid floor background
        let neonFloor = NeonFloorNode(size: size)
        neonFloor.zPosition = -10
        addChild(neonFloor)

        // Create dynamic safe area visualization
        createSafeAreaVisualization()

        setupAudioSession()
    }
    
    private func createSafeAreaVisualization() {
        let deviceInfo = getDeviceInfo()
        
        // Create safe area content zone for game content
        createContentArea(deviceInfo: deviceInfo)
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let screenSize = size
        let deviceType = getDeviceTypeString(width: screenSize.width, height: screenSize.height)
        
        // Get real safe area from the view
        let safeArea: UIEdgeInsets
        if let view = self.view {
            let rawInsets = view.safeAreaInsets
            
            if rawInsets.top == 0 && rawInsets.bottom == 0 {
                // Fallback based on screen dimensions
                if screenSize.height >= 812 {
                    safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
                } else if screenSize.height >= 736 {
                    safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
                } else {
                    safeArea = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
                }
            } else {
                safeArea = rawInsets
            }
        } else {
            safeArea = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        }
        
        return DeviceInfo(
            screenSize: screenSize,
            deviceType: deviceType,
            safeArea: safeArea
        )
    }
    
    
    private func createContentArea(deviceInfo: DeviceInfo) {
        let safeArea = deviceInfo.safeArea
        let screenSize = deviceInfo.screenSize
        
        // Content area (the usable space)
        let contentRect = CGRect(
            x: safeArea.left,
            y: safeArea.bottom,
            width: screenSize.width - safeArea.left - safeArea.right,
            height: screenSize.height - safeArea.top - safeArea.bottom
        )
        
        // Add game content within safe area
        createGameContent(in: contentRect)
    }
    
    private func createGameContent(in contentRect: CGRect) {
        // Layout game elements within the safe content area
        let contentWidth = contentRect.width
        let contentHeight = contentRect.height
        let contentCenterX = contentRect.midX
        let contentMinY = contentRect.minY
        let contentMaxY = contentRect.maxY
        
        // Define layout zones within content area
        let headerZone = CGRect(x: contentRect.minX, y: contentMaxY - contentHeight * 0.2, width: contentWidth, height: contentHeight * 0.2)
        let gameZone = CGRect(x: contentRect.minX, y: contentMinY + contentHeight * 0.3, width: contentWidth, height: contentHeight * 0.4)
        let controlZone = CGRect(x: contentRect.minX, y: contentMinY, width: contentWidth, height: contentHeight * 0.3)
        
        // Create game header (title, phase, score)
        createGameHeader(in: headerZone)
        
        // Create main game area (player vs AI)
        createGameArena(in: gameZone)
        
        // Create control area (instructions, buttons)
        createControlArea(in: controlZone)
        
        // Create music button in top-right corner of content area
        createMusicControl(contentRect: contentRect)
    }
    
    private func createGameHeader(in headerZone: CGRect) {
        let centerX = headerZone.midX
        let centerY = headerZone.midY

        // Game title — neon "DANCE FIST" style
        let titleLabel = SKLabelNode(text: "DANCE FIST")
        titleLabel.fontSize = min(headerZone.width, headerZone.height) * 0.28
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1.0)
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.position = CGPoint(x: centerX, y: centerY + headerZone.height * 0.2)
        titleLabel.name = "gameTitle"
        addChild(titleLabel)

        // Neon glow behind title
        let glowEffect = SKLabelNode(text: "DANCE FIST")
        glowEffect.fontSize = titleLabel.fontSize
        glowEffect.fontColor = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.25)
        glowEffect.fontName = "Helvetica-Bold"
        glowEffect.position = titleLabel.position
        glowEffect.zPosition = titleLabel.zPosition - 1
        addChild(glowEffect)

        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 1.2),
            SKAction.fadeAlpha(to: 0.35, duration: 1.2)
        ])
        glowEffect.run(SKAction.repeatForever(pulseAction))

        // Subtitle — 舞拳
        let subTitle = SKLabelNode(text: "舞 拳")
        subTitle.fontSize = min(headerZone.width, headerZone.height) * 0.12
        subTitle.fontColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.7)
        subTitle.position = CGPoint(x: centerX, y: centerY + headerZone.height * 0.02)
        addChild(subTitle)

        // Phase indicator
        phaseLabel = SKLabelNode(text: "握手阶段")
        phaseLabel?.fontSize = min(headerZone.width, headerZone.height) * 0.14
        phaseLabel?.fontColor = .yellow
        phaseLabel?.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.15)
        addChild(phaseLabel!)

        // Score bar — neon styled
        let scoreBarWidth = headerZone.width * 0.55
        let scoreBarHeight = headerZone.height * 0.2
        let scoreBackground = SKShapeNode(rectOf: CGSize(width: scoreBarWidth, height: scoreBarHeight), cornerRadius: scoreBarHeight * 0.4)
        scoreBackground.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 0.8)
        scoreBackground.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.5)
        scoreBackground.lineWidth = 1.5
        scoreBackground.glowWidth = 2
        scoreBackground.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.38)
        addChild(scoreBackground)

        let scoreLabel = SKLabelNode(text: "玩家 0 : 0 对手")
        scoreLabel.fontSize = min(headerZone.width, headerZone.height) * 0.1
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.42)
        scoreLabel.name = "scoreLabel"
        addChild(scoreLabel)
    }
    
    private func createGameArena(in gameZone: CGRect) {
        let centerX = gameZone.midX
        let centerY = gameZone.midY
        let charHeight = gameZone.height * 0.85

        // Positions — characters spread apart in open arena
        let playerX = gameZone.minX + gameZone.width * 0.25
        let aiX = gameZone.maxX - gameZone.width * 0.25

        // Player name tag — neon cyan
        let playerLabel = SKLabelNode(text: "Player 1")
        playerLabel.fontSize = 14
        playerLabel.fontColor = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.9)
        playerLabel.fontName = "Helvetica-Bold"
        playerLabel.position = CGPoint(x: playerX, y: centerY + charHeight * 0.55)
        addChild(playerLabel)

        // Player animated character (mirrored to face AI)
        let pChar = SpriteCharacterNode(height: charHeight, style: playerStyle, mirrored: true)
        pChar.position = CGPoint(x: playerX, y: centerY - charHeight * 0.1)
        addChild(pChar)
        playerCharacter = pChar
        pChar.animateIdle()

        // Player gesture display
        playerGestureLabel = SKLabelNode(text: "")
        playerGestureLabel?.fontSize = 28
        playerGestureLabel?.position = CGPoint(x: playerX, y: centerY - charHeight * 0.5)
        addChild(playerGestureLabel!)

        // VS label — neon styled
        let vsLabel = SKLabelNode(text: "VS")
        vsLabel.fontSize = gameZone.width * 0.07
        vsLabel.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.9)
        vsLabel.fontName = "Helvetica-Bold"
        vsLabel.position = CGPoint(x: centerX, y: centerY + charHeight * 0.1)
        addChild(vsLabel)

        // VS glow
        let vsGlow = SKLabelNode(text: "VS")
        vsGlow.fontSize = vsLabel.fontSize
        vsGlow.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.2)
        vsGlow.fontName = "Helvetica-Bold"
        vsGlow.position = vsLabel.position
        vsGlow.zPosition = vsLabel.zPosition - 1
        addChild(vsGlow)
        vsGlow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.8),
            SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        ])))

        // Opponent name tag — neon red/magenta
        let aiLabel = SKLabelNode(text: opponentStyle.name)
        aiLabel.fontSize = 14
        aiLabel.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.5, alpha: 0.9)
        aiLabel.fontName = "Helvetica-Bold"
        aiLabel.position = CGPoint(x: aiX, y: centerY + charHeight * 0.55)
        addChild(aiLabel)

        // AI animated character
        let character = SpriteCharacterNode(height: charHeight, style: opponentStyle)
        character.position = CGPoint(x: aiX, y: centerY - charHeight * 0.1)
        addChild(character)
        characterNode = character
        character.animateIdle()

        // AI gesture display
        aiGestureLabel = SKLabelNode(text: "")
        aiGestureLabel?.fontSize = 28
        aiGestureLabel?.position = CGPoint(x: aiX, y: centerY - charHeight * 0.5)
        addChild(aiGestureLabel!)

        // Hidden hand nodes (compatibility with shake handlers)
        playerHandNode = SKShapeNode(circleOfRadius: 1)
        playerHandNode?.position = CGPoint(x: playerX, y: centerY)
        playerHandNode?.isHidden = true
        addChild(playerHandNode!)

        aiHandNode = SKShapeNode(circleOfRadius: 1)
        aiHandNode?.position = CGPoint(x: aiX, y: centerY)
        aiHandNode?.isHidden = true
        addChild(aiHandNode!)
    }
    
    private func createControlArea(in controlZone: CGRect) {
        let centerX = controlZone.midX
        let centerY = controlZone.midY

        // Instruction bar — neon styled
        let instructionWidth = controlZone.width * 0.85
        let instructionHeight = controlZone.height * 0.3
        let instructionBg = SKShapeNode(rectOf: CGSize(width: instructionWidth, height: instructionHeight), cornerRadius: instructionHeight * 0.3)
        instructionBg.fillColor = SKColor(red: 0.08, green: 0.03, blue: 0.12, alpha: 0.85)
        instructionBg.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.4)
        instructionBg.lineWidth = 1.5
        instructionBg.glowWidth = 2
        instructionBg.position = CGPoint(x: centerX, y: centerY + controlZone.height * 0.2)
        addChild(instructionBg)

        instructionLabel = SKLabelNode(text: "准备开始舞拳...")
        instructionLabel?.fontSize = min(controlZone.width, controlZone.height) * 0.11
        instructionLabel?.fontColor = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        instructionLabel?.position = CGPoint(x: centerX, y: centerY + controlZone.height * 0.16)
        instructionLabel?.numberOfLines = 2
        addChild(instructionLabel!)
    }
    
    private func createMusicControl(contentRect: CGRect) {
        let musicSize = min(contentRect.width, contentRect.height) * 0.06
        
        // Settings button (gear icon)
        let settingsButton = SKLabelNode(text: "⚙️")
        settingsButton.fontSize = musicSize
        settingsButton.position = CGPoint(x: contentRect.maxX - musicSize, y: contentRect.maxY - musicSize)
        settingsButton.name = "settingsButton"
        addChild(settingsButton)
        
        // Music status indicator
        musicButton = SKLabelNode(text: "🎵")
        musicButton?.fontSize = musicSize * 0.8
        musicButton?.position = CGPoint(x: contentRect.maxX - musicSize * 2.5, y: contentRect.maxY - musicSize)
        musicButton?.name = "musicStatus"
        musicButton?.alpha = 0.5 // Dimmed when no music
        addChild(musicButton!)
    }
    
    private func presentSettingsViewController() {
        guard !isSettingsVisible else { return }
        
        // Try multiple methods to get the view controller
        var viewController: UIViewController?
        
        // Method 1: Try to get from view's next responder
        if let vc = self.view?.next as? UIViewController {
            viewController = vc
        }
        // Method 2: Try to traverse responder chain
        else if let view = self.view {
            var responder = view.next
            while responder != nil {
                if let vc = responder as? UIViewController {
                    viewController = vc
                    break
                }
                responder = responder?.next
            }
        }
        // Method 3: Get from scene's parent view controller (fallback)
        else if let view = self.view,
                let window = view.window,
                let rootVC = window.rootViewController {
            viewController = rootVC
        }
        
        guard let presentingVC = viewController else {
            print("ERROR: Could not find view controller to present settings")
            return
        }
        
        // Pause game and hide game buttons
        pauseGameForSettings()
        
        // Create and present settings view controller
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        settingsVC.modalPresentationStyle = .overFullScreen
        settingsVC.modalTransitionStyle = .crossDissolve
        
        // Update settings with current music state
        let isPlaying = backgroundMusicPlayer?.isPlaying ?? false
        let volume = backgroundMusicPlayer?.volume ?? 0.5
        settingsVC.updateMusicState(url: selectedMusicURL, isPlaying: isPlaying, volume: volume)
        
        isSettingsVisible = true
        presentingVC.present(settingsVC, animated: true)
    }
    
    private func showGameRules() {
        guard !isSettingsVisible else { return }
        
        // Try multiple methods to get the view controller
        var viewController: UIViewController?
        
        if let vc = self.view?.next as? UIViewController {
            viewController = vc
        } else if let view = self.view {
            var responder = view.next
            while responder != nil {
                if let vc = responder as? UIViewController {
                    viewController = vc
                    break
                }
                responder = responder?.next
            }
        } else if let view = self.view,
                let window = view.window,
                let rootVC = window.rootViewController {
            viewController = rootVC
        }
        
        guard let presentingVC = viewController else {
            print("ERROR: Could not find view controller to present rules")
            return
        }
        
        // Pause game and hide game buttons
        pauseGameForSettings()
        
        // Create and present rules view controller
        let rulesVC = GameRulesViewController()
        rulesVC.delegate = self
        rulesVC.modalPresentationStyle = .overFullScreen
        rulesVC.modalTransitionStyle = .crossDissolve
        
        isSettingsVisible = true // Reuse this flag for rules too
        presentingVC.present(rulesVC, animated: true)
    }
    
    
    private func dismissSettingsViewController() {
        guard isSettingsVisible else { return }
        
        // Find the presented settings view controller and dismiss it
        if let presentingVC = view?.window?.rootViewController?.presentedViewController {
            presentingVC.dismiss(animated: true) {
                self.isSettingsVisible = false
                // Resume game and show game buttons
                self.resumeGameFromSettings()
            }
        } else {
            // Fallback if we can't find the presented view controller
            isSettingsVisible = false
            resumeGameFromSettings()
        }
    }
    
    private func pauseGameForSettings() {
        // Don't pause the entire scene - just pause game logic
        // Keep settings overlay functional
        
        // Hide all interactive game buttons and elements
        hideGameButtons()
        
        // Pause any ongoing animations
        pauseGameAnimations()
    }
    
    private func resumeGameFromSettings() {
        // Show game buttons again
        showGameButtons()
        
        // Resume game animations
        resumeGameAnimations()
    }
    
    private func hideGameButtons() {
        hiddenGameButtons.removeAll()
        
        // Hide gesture buttons if they exist
        let gestureButtons = children.filter { $0.name?.hasPrefix("gesture_") == true }
        for button in gestureButtons {
            button.alpha = 0.0
            button.isHidden = true
            hiddenGameButtons.append(button)
        }
        
        // Hide direction buttons if they exist
        let directionButtons = children.filter { $0.name?.hasPrefix("direction_") == true }
        for button in directionButtons {
            button.alpha = 0.0
            button.isHidden = true
            hiddenGameButtons.append(button)
        }
        
        // Dim game instruction area
        if let instructionLabel = instructionLabel {
            instructionLabel.alpha = 0.3
            hiddenGameButtons.append(instructionLabel)
        }
        
        // Dim button area
        if let buttonArea = childNode(withName: "buttonArea") {
            buttonArea.alpha = 0.3
            hiddenGameButtons.append(buttonArea)
        }
    }

    private func showGameButtons() {
        // Restore all hidden game buttons
        for button in hiddenGameButtons {
            button.isHidden = false
            button.alpha = 1.0
        }
        
        // Special handling for instruction label (should be visible but may have different alpha)
        if let instructionLabel = instructionLabel {
            instructionLabel.alpha = 1.0
        }
        
        // Special handling for button area
        if let buttonArea = childNode(withName: "buttonArea") {
            buttonArea.alpha = 1.0
        }
        
        hiddenGameButtons.removeAll()
    }

    private func pauseGameAnimations() {
        // Pause hand animations
        playerHandNode?.removeAllActions()
        aiHandNode?.removeAllActions()
        
        // Pause any timer-based animations
        // Pause any gesture or direction selection timers if they exist
        removeAction(forKey: "gamePhaseTimer")
    }
    
    private func resumeGameAnimations() {
        // Resume appropriate animations based on current game phase
        switch gamePhase {
        case .handshake:
            // Resume handshake if it was in progress
            if playerHandNode?.hasActions() == false {
                // Restart handshake animation if needed
                startHandshakePhase()
            }
        case .freeMovement:
            // Resume free movement if it was in progress
            if playerHandNode?.hasActions() == false {
                // Restart free movement animation if needed
                startFreeMovementPhase()
            }
        case .gestureSelection:
            // Show gesture buttons if they should be visible
            if children.filter({ $0.name?.hasPrefix("gesture_") == true }).isEmpty {
                showGestureButtons()
            }
        case .directionPointing:
            // Show direction buttons if they should be visible
            if children.filter({ $0.name?.hasPrefix("direction_") == true }).isEmpty {
                showDirectionButtons()
            }
        case .result:
            // Result phase doesn't need special animation resume
            break
        }
    }
    
    
    
    private func toggleMusicPlayback() {
        guard let player = backgroundMusicPlayer else { return }
        
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        updateMusicStatusIndicator()
    }
    
    private func setupAutoMusic() {
        // Auto-select first available track if no music is currently selected
        if selectedMusicURL == nil {
            let availableTracks = MusicStore.shared.getAllTracks()
            if let firstTrack = availableTracks.first {
                selectedMusicURL = firstTrack.url

                // Auto-start playing if the file actually exists
                if FileManager.default.fileExists(atPath: firstTrack.url.path) {
                    playBackgroundMusic()
                }

                // Update music button to show current status
                updateMusicStatusIndicator()
            }
        }
    }
    
    private func updateMusicStatusIndicator() {
        if backgroundMusicPlayer?.isPlaying == true {
            musicButton?.alpha = 1.0
            if let currentTrack = getCurrentTrack() {
                musicButton?.text = "🎵 \(currentTrack.title)"
            } else {
                musicButton?.text = "🎵 播放中"
            }
        } else if selectedMusicURL != nil {
            musicButton?.alpha = 0.7
            if let currentTrack = getCurrentTrack() {
                musicButton?.text = "🎵 \(currentTrack.title)"
            } else {
                musicButton?.text = "🎵 已选择"
            }
        } else {
            musicButton?.alpha = 0.5
            musicButton?.text = "🎵 选择音乐"
        }
    }
    
    private func getCurrentTrack() -> MusicTrack? {
        guard let selectedURL = selectedMusicURL else { return nil }
        return MusicStore.shared.getTrack(by: selectedURL)
    }
    
    private func getDeviceTypeString(width: CGFloat, height: CGFloat) -> String {
        let maxDimension = max(width, height)
        let minDimension = min(width, height)

        // Check for exact matches first - organized by unique dimensions
        switch (minDimension, maxDimension) {
        // Simulator scaled dimensions (check first to avoid confusion)
        case (640, 960): return "iPhone 4 Simulator (@2x)"
        case (640, 1136): return "iPhone 5 Simulator (@2x)"
        case (750, 1334): return "iPhone 6/7/8 Simulator (@2x)"
        case (828, 1472): return "iPhone 6 Plus Simulator (@2x)"
        case (1125, 2436): return "iPhone X Simulator (@3x)"
        case (1170, 2532): return "iPhone 12/13/14 Simulator (@3x)"
        case (1179, 2556): return "iPhone Pro Simulator (@3x)"
        case (1284, 2778): return "iPhone Pro Max Simulator (@3x)"
        case (1290, 2796): return "iPhone 15/16 Pro Max Simulator (@3x)"
        
        // iPad dimensions
        case (768, 1024): return "iPad (9.7-inch)"
        case (810, 1080): return "iPad (10.2-inch)"
        case (820, 1180): return "iPad Air (10.9-inch)"
        case (834, 1194): return "iPad Pro (11-inch)"
        case (1024, 1366): return "iPad Pro (12.9-inch)"
        
        // iPhone device dimensions (physical devices)
        case (320, 480): return "iPhone 4/4s"
        case (320, 568): return "iPhone 5/5s/5c/SE 1st"
        case (375, 667): return "iPhone 6/6s/7/8/SE 2nd/3rd"
        case (414, 736): return "iPhone 6/7/8 Plus"
        case (375, 812): return "iPhone X/XS/11 Pro"
        case (414, 896): return "iPhone XR/XS Max/11/11 Pro Max"
        case (390, 844): return "iPhone 12/12 mini/13/13 mini/14"
        case (393, 852): return "iPhone 14 Pro/15/15 Pro/16/16 Pro"
        case (428, 926): return "iPhone 12/13/14 Plus"
        case (430, 932): return "iPhone 14/15/16 Pro Max"
        
        default:
            // Fallback logic with range detection and exact dimensions
            let dimensionString = "(\(Int(minDimension))×\(Int(maxDimension)))"
            
            if maxDimension >= 1334 && minDimension >= 640 {
                return "Simulator scaled \(dimensionString)"
            } else if minDimension >= 768 {
                return "iPad \(dimensionString)"
            } else if minDimension <= 320 {
                return "iPhone 4 era or older \(dimensionString)"
            } else if minDimension <= 375 && maxDimension <= 812 {
                return "iPhone 6-11 era \(dimensionString)"
            } else if minDimension <= 393 && maxDimension <= 852 {
                return "iPhone 12-16 era \(dimensionString)"
            } else if minDimension <= 430 && maxDimension <= 932 {
                return "iPhone Plus/Pro Max era \(dimensionString)"
            } else {
                return "Unknown device \(dimensionString)"
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playBackgroundMusic() {
        guard let musicURL = selectedMusicURL else { return }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
            backgroundMusicPlayer?.numberOfLoops = -1  // Loop indefinitely
            backgroundMusicPlayer?.volume = 0.5
            backgroundMusicPlayer?.enableRate = true   // Enable tempo control
            backgroundMusicPlayer?.rate = 1.0          // Default rate
            backgroundMusicPlayer?.play()
            musicButton?.text = "🎵 音乐播放中"
        } catch {
            print("Failed to play music: \(error)")
        }
    }
    
    private func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        musicButton?.text = "🎵 选择音乐"
    }
    
    private func adjustMusicTempo(_ rate: Float) {
        guard let player = backgroundMusicPlayer, player.isPlaying else { return }
        player.rate = rate
        player.enableRate = true
    }
    
    private func startHandshakePhase() {
        playerCharacter?.stopIdle()
        characterNode?.stopIdle()
        gamePhase = .handshake(step: 1)
        phaseLabel?.text = "握手阶段 (1/2)"
        instructionLabel?.text = "与对手握手..."

        // Round announcement (skip round 0 — first round after reset)
        if roundCount > 0 {
            AnnouncementNode.showRoundAnnouncement(round: roundCount + 1, maxRounds: maxRounds, in: self)
        }

        // Phase flash
        AnnouncementNode.flashScreen(color: SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), in: self)

        adjustMusicTempo(0.8)
        animateHandshake()
    }
    
    private func animateHandshake() {
        guard case .handshake(_) = gamePhase else { return }

        // Both characters do handshake animation
        playerCharacter?.animateHandshake {}
        characterNode?.animateHandshake {
            self.completeHandshakeStep()
        }
    }
    
    private func completeHandshakeStep() {
        guard case .handshake(let step) = gamePhase else { return }
        playHandshakeSound()

        if step < 2 {
            gamePhase = .handshake(step: step + 1)
            phaseLabel?.text = "握手阶段 (\(step + 1)/2)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateHandshake()
            }
        } else {
            startFreeMovementPhase()
        }
    }
    
    private func startFreeMovementPhase() {
        gamePhase = .freeMovement(step: 1)
        phaseLabel?.text = "自由晃动 (1/2)"
        instructionLabel?.text = "疯狂晃动手腕！"
        
        // Speed up music for free movement phase
        adjustMusicTempo(1.2)
        
        animateFreeMovement()
    }
    
    private func animateFreeMovement() {
        guard case .freeMovement(let step) = gamePhase else { return }
        
        // Both characters dance
        playerCharacter?.animateFreeMovement {}
        characterNode?.animateFreeMovement {
            self.completeFreeMovementStep()
        }
    }
    
    private func completeFreeMovementStep() {
        guard case .freeMovement(let step) = gamePhase else { return }
        
        if step < 2 {
            gamePhase = .freeMovement(step: step + 1)
            phaseLabel?.text = "自由晃动 (\(step + 1)/2)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.animateFreeMovement()
            }
        } else {
            startGestureSelectionPhase()
        }
    }
    
    private func startGestureSelectionPhase() {
        gamePhase = .gestureSelection
        phaseLabel?.text = "选择手势"
        instructionLabel?.text = "点击选择你的手势"
        
        // Return to normal tempo for decision phase
        adjustMusicTempo(1.0)
        
        // Show gesture options
        showGestureButtons()

        // Enhanced AI logic with strategy
        aiGesture = chooseAIGesture()

        // Character enters thinking pose
        characterNode?.setExpression(.smirk)

        // AI tell — character briefly hints at chosen gesture
        if let aiG = aiGesture {
            let tellDelay: TimeInterval
            let tellDuration: TimeInterval
            switch difficulty {
            case .easy:
                tellDelay = 0.5
                tellDuration = 0.8  // Obvious tell
            case .medium:
                tellDelay = 0.3
                tellDuration = 0.4  // Subtle tell
            case .hard:
                // 50% chance of bluff on hard
                tellDelay = 0.2
                tellDuration = 0.3
            }
            let gestureToShow = (difficulty == .hard && Bool.random()) ? Gesture.allCases.randomElement() ?? .rock : aiG
            characterNode?.animateTell(gestureToShow, delay: tellDelay, duration: tellDuration)
        }
    }
    
    private func showGestureButtons() {
        let gestures: [Gesture] = [.rock, .paper, .scissors]
        // Dynamic button positioning
        let screenHeight = size.height
        let screenWidth = size.width
        let buttonAreaY = screenHeight * 0.3  // 30% from bottom
        let buttonSize = min(screenWidth, screenHeight) * 0.08
        let spacing = screenWidth * 0.2
        let startX = screenWidth/2 - CGFloat(gestures.count - 1) * spacing / 2
        
        for (index, gesture) in gestures.enumerated() {
            // Neon button background
            let buttonBg = SKShapeNode(circleOfRadius: buttonSize*0.7)
            buttonBg.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 0.85)
            buttonBg.strokeColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.8)
            buttonBg.lineWidth = 2
            buttonBg.glowWidth = 3
            buttonBg.position = CGPoint(x: startX + CGFloat(index) * spacing, y: buttonAreaY)
            buttonBg.name = "gesture_\(gesture)"
            addChild(buttonBg)
            
            // Dynamic emoji label
            let button = SKLabelNode(text: gesture.emoji)
            button.fontSize = buttonSize
            button.position = CGPoint(x: startX + CGFloat(index) * spacing, y: buttonAreaY - buttonSize*0.25)
            button.name = "gesture_\(gesture)"
            addChild(button)
        }

        // Start selection timer
        startSelectionTimer(buttonAreaY: buttonAreaY + buttonSize * 1.5) {
            let randomGesture = Gesture.allCases.randomElement() ?? .rock
            self.selectGesture(randomGesture)
            self.instructionLabel?.text = "超时！随机选择：\(randomGesture.emoji)"
        }
    }

    private func selectGesture(_ gesture: Gesture) {
        cancelSelectionTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        playSelectSound()
        playerGesture = gesture
        playerGestureHistory.append(gesture)
        gestureCountsThisGame[gesture, default: 0] += 1
        playerGestureLabel?.text = gesture.emoji
        aiGestureLabel?.text = aiGesture?.emoji ?? ""

        // Remove gesture buttons
        children.filter { $0.name?.hasPrefix("gesture_") == true }.forEach { $0.removeFromParent() }

        // Dramatic pause — dim screen, then reveal both gestures
        let dimOverlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        dimOverlay.fillColor = .black
        dimOverlay.alpha = 0
        dimOverlay.zPosition = 80
        dimOverlay.name = "revealDim"
        addChild(dimOverlay)

        // Dim
        dimOverlay.run(SKAction.fadeAlpha(to: 0.3, duration: 0.2))

        // After pause, reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.playerCharacter?.animateGestureReveal(gesture)
            if let aiG = self.aiGesture {
                self.characterNode?.animateGestureReveal(aiG)
            }
            AnnouncementNode.flashScreen(color: .white, in: self)

            // Undim and continue
            dimOverlay.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.8),
                SKAction.fadeAlpha(to: 0, duration: 0.3),
                SKAction.removeFromParent()
            ]))
        }

        // Continue to direction phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.startDirectionPointingPhase()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Dismiss tutorial on any tap
        if childNode(withName: "tutorialOverlay") != nil {
            dismissTutorial()
            return
        }

        // Skip game interactions if settings are visible
        if isSettingsVisible {
            return
        }

        // Handle settings button tap
        if touchedNode.name == "settingsButton" {
            presentSettingsViewController()
            return
        }
        
        // Handle game title tap (show rules)
        if touchedNode.name == "gameTitle" {
            showGameRules()
            return
        }
        
        // Handle old music button tap (now just status indicator)
        if touchedNode.name == "musicButton" || touchedNode.name == "musicStatus" {
            presentSettingsViewController()
            return
        }

        // Handle game over buttons
        if touchedNode.name == "playAgainButton" {
            childNode(withName: "gameOverNode")?.removeFromParent()
            resetFullGame()
            return
        }
        if touchedNode.name == "changeCharacterButton" {
            // Go back to character selection
            childNode(withName: "gameOverNode")?.removeFromParent()
            if let vc = self.view?.next as? UIViewController {
                let selectionVC = CharacterSelectionViewController()
                selectionVC.delegate = vc as? CharacterSelectionDelegate
                selectionVC.modalPresentationStyle = .fullScreen
                vc.present(selectionVC, animated: true)
            }
            return
        }

        if case .gestureSelection = gamePhase,
           let nodeName = touchedNode.name,
           nodeName.hasPrefix("gesture_") {
            let gestureString = String(nodeName.dropFirst(8))
            
            switch gestureString {
            case "rock":
                selectGesture(.rock)
            case "paper":
                selectGesture(.paper)
            case "scissors":
                selectGesture(.scissors)
            default:
                break
            }
        } else if case .directionPointing = gamePhase,
                  let nodeName = touchedNode.name,
                  nodeName.hasPrefix("direction_") {
            let directionString = String(nodeName.dropFirst(10))
            
            switch directionString {
            case "up":
                selectDirection(.up)
            case "down":
                selectDirection(.down)
            case "left":
                selectDirection(.left)
            case "right":
                selectDirection(.right)
            default:
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    
    private func startDirectionPointingPhase() {
        gamePhase = .directionPointing
        phaseLabel?.text = "指向选择"

        // AI chooses direction strategically based on gesture match state
        let sameGesture = playerGesture == aiGesture
        if sameGesture {
            instructionLabel?.text = "手势相同，选择相同方向"
            // Same gesture: AI wants to match player's direction
            // Favor up/right as humans tend to pick these more often
            aiDirection = chooseAIDirection(favoredDirections: [.up, .right])
        } else {
            instructionLabel?.text = "手势不同，选择不同方向"
            // Different gesture: AI wants to differ from player's direction
            // Spread evenly since we want to avoid matching
            aiDirection = Direction.allCases.randomElement() ?? .up
        }

        showDirectionButtons()
    }

    private func chooseAIDirection(favoredDirections: [Direction]) -> Direction {
        let allDirections = Direction.allCases
        let random = Double.random(in: 0...1)
        var cumulative = 0.0

        for direction in allDirections {
            let weight = favoredDirections.contains(direction) ? 0.35 : 0.15
            cumulative += weight
            if random <= cumulative {
                return direction
            }
        }
        return allDirections.randomElement() ?? .up
    }
    
    private func showDirectionButtons() {
        let directions: [Direction] = [.up, .down, .left, .right]
        // Dynamic direction button positioning
        let screenHeight = size.height
        let screenWidth = size.width
        let centerX = screenWidth/2
        let centerY = screenHeight * 0.3  // 30% from bottom
        let buttonSize = min(screenWidth, screenHeight) * 0.06
        let offset = screenWidth * 0.15
        
        let positions = [
            CGPoint(x: centerX, y: centerY + offset),      // up
            CGPoint(x: centerX, y: centerY - offset),      // down
            CGPoint(x: centerX - offset, y: centerY),      // left
            CGPoint(x: centerX + offset, y: centerY)       // right
        ]
        
        for (index, direction) in directions.enumerated() {
            // Neon button background
            let buttonBg = SKShapeNode(circleOfRadius: buttonSize*0.8)
            buttonBg.fillColor = SKColor(red: 0.15, green: 0.05, blue: 0.1, alpha: 0.85)
            buttonBg.strokeColor = SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.8)
            buttonBg.lineWidth = 2
            buttonBg.glowWidth = 3
            buttonBg.position = positions[index]
            buttonBg.name = "direction_\(direction)"
            addChild(buttonBg)
            
            // Dynamic arrow label
            let button = SKLabelNode(text: direction.emoji)
            button.fontSize = buttonSize
            button.position = CGPoint(x: positions[index].x, y: positions[index].y - buttonSize*0.2)
            button.name = "direction_\(direction)"
            addChild(button)
        }

        // Start selection timer
        startSelectionTimer(buttonAreaY: centerY + offset + buttonSize * 1.5) {
            let randomDirection = Direction.allCases.randomElement() ?? .up
            self.selectDirection(randomDirection)
            self.instructionLabel?.text = "超时！随机选择：\(randomDirection.emoji)"
        }
    }

    private func selectDirection(_ direction: Direction) {
        cancelSelectionTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        playSelectSound()
        playerDirection = direction

        // Both characters point in their chosen directions
        playerCharacter?.animateDirectionPoint(direction)
        if let aiDir = aiDirection {
            characterNode?.animateDirectionPoint(aiDir)
        }

        // Remove direction buttons
        children.filter { $0.name?.hasPrefix("direction_") == true }.forEach { $0.removeFromParent() }

        showResult()
    }
    
    private func showResult() {
        guard let playerGesture = playerGesture,
              let aiGesture = aiGesture,
              let playerDirection = playerDirection,
              let aiDirection = aiDirection else { return }
        
        gamePhase = .result

        let result = GameRules.evaluateRound(
            playerGesture: playerGesture, aiGesture: aiGesture,
            playerDirection: playerDirection, aiDirection: aiDirection)

        var resultText: String
        var winner: String

        switch result {
        case .continueGame:
            currentStreak += 1
            bestStreakThisGame = max(bestStreakThisGame, currentStreak)
            let sameGesture = playerGesture == aiGesture
            resultText = sameGesture ? "正确! 手势相同，方向相同" : "正确! 手势不同，方向不同"
            winner = "继续游戏"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            playSuccessSound()
            showSuccessEffect()
            playerCharacter?.setExpression(.neutral)
            characterNode?.setExpression(.neutral)
            // Combo announcement
            AnnouncementNode.showCombo(streak: currentStreak, in: self)
            AnnouncementNode.updateStreakBorder(streak: currentStreak, in: self)
        case .playerLoses:
            let multiplier = max(1, currentStreak)
            totalDrinksThisGame += multiplier
            resultText = "违反规则!"
            winner = "玩家失败 😢"
            currentStreak = 0
            gameScore.ai += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            playFailureSound()
            showFailureEffect()
            playerCharacter?.animateDrink()
            characterNode?.animateWin()
            AnnouncementNode.showDrinkCall(count: multiplier, isPlayer: true, in: self)
            AnnouncementNode.updateStreakBorder(streak: 0, in: self)
        case .aiLoses:
            let multiplier = max(1, currentStreak)
            totalDrinksThisGame += multiplier
            resultText = "违反规则!"
            winner = "对手失败 🎉"
            currentStreak = 0
            gameScore.player += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            playSuccessSound()
            showVictoryEffect()
            playerCharacter?.animateWin()
            characterNode?.animateDrink()
            AnnouncementNode.showDrinkCall(count: multiplier, isPlayer: false, in: self)
            AnnouncementNode.updateStreakBorder(streak: 0, in: self)
        }
        
        roundCount += 1

        // Round escalation effects
        if roundCount >= 8 {
            // Sudden death feel — dark vignette
            if childNode(withName: "vignette") == nil {
                let vignette = SKShapeNode(rect: CGRect(origin: .zero, size: size))
                vignette.fillColor = .black
                vignette.alpha = 0.0
                vignette.zPosition = 50
                vignette.name = "vignette"
                vignette.isUserInteractionEnabled = false
                addChild(vignette)
            }
            let targetAlpha: CGFloat = CGFloat(roundCount - 7) * 0.08
            childNode(withName: "vignette")?.run(SKAction.fadeAlpha(to: targetAlpha, duration: 0.5))
        }

        // Speed up music based on round
        if roundCount <= 3 {
            adjustMusicTempo(0.9)
        } else if roundCount <= 7 {
            adjustMusicTempo(1.1)
        } else {
            adjustMusicTempo(1.3)
        }

        phaseLabel?.text = winner
        instructionLabel?.text = resultText
        updateScoreDisplay()

        if roundCount >= maxRounds {
            let gameOverAction = SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.run { self.showGameOver() }
            ])
            self.run(gameOverAction, withKey: "nextRoundDelay")
        } else {
            let nextRoundAction = SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.run { self.resetGame() }
            ])
            self.run(nextRoundAction, withKey: "nextRoundDelay")
        }
    }

    private func showGameOver() {
        gamePhase = .result
        let playerWon = gameScore.player > gameScore.ai

        totalGamesPlayed += 1
        if playerWon { totalWins += 1 }

        // Find favorite gesture
        let favorite = gestureCountsThisGame.max(by: { $0.value < $1.value })?.key ?? .rock

        // Show game over overlay
        let gameOver = GameOverNode(
            size: size,
            playerScore: gameScore.player,
            aiScore: gameScore.ai,
            playerName: playerStyle.name,
            opponentName: opponentStyle.name,
            totalDrinks: totalDrinksThisGame,
            bestStreak: bestStreakThisGame,
            favoriteGesture: favorite.emoji,
            roundsPlayed: roundCount
        )
        gameOver.name = "gameOverNode"
        gameOver.zPosition = 300
        addChild(gameOver)

        if playerWon {
            showVictoryEffect()
            playerCharacter?.animateWin()
            characterNode?.animateLose()
        } else if gameScore.ai > gameScore.player {
            showFailureEffect()
            playerCharacter?.animateLose()
            characterNode?.animateWin()
        }
    }

    private func resetGame() {
        playerGesture = nil
        aiGesture = nil
        playerDirection = nil
        aiDirection = nil
        playerGestureLabel?.text = ""
        aiGestureLabel?.text = ""
        cancelSelectionTimer()

        playerCharacter?.resetPose()
        playerCharacter?.animateIdle()
        characterNode?.resetPose()
        characterNode?.animateIdle()

        startHandshakePhase()
    }

    private func resetFullGame() {
        roundCount = 0
        gameScore = (player: 0, ai: 0)
        currentStreak = 0
        totalDrinksThisGame = 0
        bestStreakThisGame = 0
        gestureCountsThisGame = [.rock: 0, .paper: 0, .scissors: 0]
        playerGestureHistory.removeAll()
        cancelSelectionTimer()
        updateScoreDisplay()
        childNode(withName: "restartButton")?.removeFromParent()
        childNode(withName: "gameOverNode")?.removeFromParent()
        childNode(withName: "vignette")?.removeFromParent()
        childNode(withName: "streakBorder")?.removeFromParent()
        resetGame()
    }

    private func updateScoreDisplay() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            var text = "玩家 \(gameScore.player) : \(gameScore.ai) 对手  (\(roundCount)/\(maxRounds))"
            if currentStreak > 0 {
                text += " 🔥x\(currentStreak)"
            }
            scoreLabel.text = text
        }
        UserDefaults.standard.set(gameScore.player, forKey: "playerScore")
        UserDefaults.standard.set(gameScore.ai, forKey: "aiScore")
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        let dt = currentTime - self.lastUpdateTime
        
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
    
    private func chooseAIGesture() -> Gesture {
        // 夜店小王子的策略：分析玩家历史模式并做出反制
        let recentHistory = playerGestureHistory.suffix(5)

        // Need enough history to adapt (depends on difficulty)
        guard recentHistory.count >= difficulty.adaptThreshold else {
            // Default weights: favor paper to counter common rock
            return weightedRandomGesture(weights: [.rock: 0.3, .paper: 0.4, .scissors: 0.3])
        }

        // Count player's recent gesture frequencies
        var counts: [Gesture: Int] = [.rock: 0, .paper: 0, .scissors: 0]
        for g in recentHistory { counts[g, default: 0] += 1 }

        // Find most frequent gesture and counter it
        let mostFrequent = counts.max(by: { $0.value < $1.value })?.key ?? .rock
        let counter: Gesture
        switch mostFrequent {
        case .rock: counter = .paper
        case .paper: counter = .scissors
        case .scissors: counter = .rock
        }

        // Counter weight depends on difficulty
        let remaining = (1.0 - difficulty.counterWeight) / 2.0
        var weights: [Gesture: Double] = [.rock: remaining, .paper: remaining, .scissors: remaining]
        weights[counter] = difficulty.counterWeight
        return weightedRandomGesture(weights: weights)
    }

    private func weightedRandomGesture(weights: [Gesture: Double]) -> Gesture {
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        for gesture in Gesture.allCases {
            cumulative += weights[gesture] ?? 0.33
            if random <= cumulative {
                return gesture
            }
        }
        return .rock
    }

    // MARK: - Sound Effects

    private func playSelectSound() {
        AudioServicesPlaySystemSound(1104) // Key press tick
    }

    private func playSuccessSound() {
        AudioServicesPlaySystemSound(1025) // Positive tone
    }

    private func playFailureSound() {
        AudioServicesPlaySystemSound(1073) // Negative tone
    }

    private func playHandshakeSound() {
        AudioServicesPlaySystemSound(1100) // Short tap
    }

    private func showSuccessEffect() {
        // Create sparkle effect for correct moves
        let sparkleCount = 20
        for _ in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = .yellow
            sparkle.strokeColor = .white
            sparkle.alpha = 1.0
            
            let randomX = CGFloat.random(in: 0...size.width)
            let randomY = CGFloat.random(in: 0...size.height)
            sparkle.position = CGPoint(x: randomX, y: randomY)
            addChild(sparkle)
            
            let fadeOut = SKAction.fadeOut(withDuration: 1.5)
            let scale = SKAction.scale(to: 0.1, duration: 1.5)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([SKAction.group([fadeOut, scale]), remove])
            
            sparkle.run(sequence)
        }
        
        // Add screen flash effect
        let flash = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: size))
        flash.fillColor = .yellow
        flash.alpha = 0.3
        addChild(flash)
        
        let flashSequence = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        flash.run(flashSequence)
    }
    
    private func showVictoryEffect() {
        // Create fireworks effect for player victory
        let fireworkCount = 15
        for _ in 0..<fireworkCount {
            let firework = SKShapeNode(circleOfRadius: 4)
            firework.fillColor = .green
            firework.strokeColor = .white
            firework.alpha = 1.0
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            firework.position = CGPoint(x: centerX, y: centerY)
            addChild(firework)
            
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 100...200)
            let endX = centerX + cos(randomAngle) * distance
            let endY = centerY + sin(randomAngle) * distance
            
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 1.0)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 1.0)
            let scale = SKAction.scale(to: 2.0, duration: 1.0)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([SKAction.group([move, fadeOut, scale]), remove])
            firework.run(sequence)
        }
        
        // Add celebration text
        let celebrationLabel = SKLabelNode(text: "🎉 胜利! 🎉")
        celebrationLabel.fontSize = 40
        celebrationLabel.fontColor = .green
        celebrationLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        addChild(celebrationLabel)
        
        let bounceUp = SKAction.moveBy(x: 0, y: 20, duration: 0.3)
        bounceUp.timingMode = .easeOut
        let bounceDown = SKAction.moveBy(x: 0, y: -20, duration: 0.3)
        bounceDown.timingMode = .easeIn
        let bounce = SKAction.sequence([bounceUp, bounceDown])
        let repeatBounce = SKAction.repeat(bounce, count: 3)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        
        celebrationLabel.run(SKAction.sequence([repeatBounce, fade, remove]))
    }
    
    private func showFailureEffect() {
        // Create screen shake effect for player failure
        let originalPosition = position
        let shakeDistance: CGFloat = 10
        let shakeDuration: TimeInterval = 0.1
        
        let shakeLeft = SKAction.moveBy(x: -shakeDistance, y: 0, duration: shakeDuration)
        let shakeRight = SKAction.moveBy(x: shakeDistance * 2, y: 0, duration: shakeDuration)
        let shakeReturn = SKAction.moveBy(x: -shakeDistance, y: 0, duration: shakeDuration)
        
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeReturn])
        let repeatShake = SKAction.repeat(shakeSequence, count: 3)
        
        run(repeatShake)
        
        // Add red overlay effect
        let overlay = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: size))
        overlay.fillColor = .red
        overlay.alpha = 0.4
        addChild(overlay)
        
        let overlaySequence = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        overlay.run(overlaySequence)
        
        // Add failure text
        let failureLabel = SKLabelNode(text: "😞 失败了...")
        failureLabel.fontSize = 30
        failureLabel.fontColor = .red
        failureLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 50)
        addChild(failureLabel)
        
        let slideDown = SKAction.moveBy(x: 0, y: -30, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        
        failureLabel.run(SKAction.sequence([SKAction.group([slideDown, fade]), remove]))
    }

    func handleShakeGesture() {
        guard !isSettingsVisible else { return }
        
        switch gamePhase {
        case .handshake:
            handleShakeInHandshakePhase()
        case .freeMovement:
            handleShakeInFreeMovementPhase()
        case .gestureSelection:
            handleShakeInGestureSelectionPhase()
        case .directionPointing:
            handleShakeInDirectionPointingPhase()
        case .result:
            handleShakeInResultPhase()
        }
    }
    
    private func handleShakeInHandshakePhase() {
        // Add extra visual effects to the handshake
        createShakeSparkles(at: playerHandNode?.position ?? CGPoint.zero)
        createShakeSparkles(at: aiHandNode?.position ?? CGPoint.zero)
        
        // Speed up the current handshake animation
        if let playerHand = playerHandNode, let aiHand = aiHandNode {
            // Add shake effect to hands
            let shakeAction = createShakeAnimation()
            playerHand.run(shakeAction)
            aiHand.run(shakeAction)
        }
        
        // Update instruction to acknowledge shake
        instructionLabel?.text = "用力握手！继续摇动增加威力..."
    }
    
    private func handleShakeInFreeMovementPhase() {
        // Create enhanced movement effects
        createShakeSparkles(at: playerHandNode?.position ?? CGPoint.zero)
        
        // Add screen flash effect
        let flash = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: size))
        flash.fillColor = .yellow
        flash.alpha = 0.2
        addChild(flash)
        
        let flashSequence = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        flash.run(flashSequence)
        
        // Update instruction
        instructionLabel?.text = "太棒了！继续疯狂晃动！"
        
        // Add extra swing animation
        if let playerHand = playerHandNode {
            let extraSwing = createEnhancedSwingAnimation()
            playerHand.run(extraSwing)
        }
    }
    
    private func handleShakeInGestureSelectionPhase() {
        // Randomly select a gesture when shaken
        let randomGesture = Gesture.allCases.randomElement() ?? .rock
        selectGesture(randomGesture)
        
        // Visual feedback for shake selection
        createShakeSelectionEffect()
        
        // Update instruction
        instructionLabel?.text = "摇动选择：\(randomGesture.emoji) - 好选择！"
    }
    
    private func handleShakeInDirectionPointingPhase() {
        // Randomly select a direction when shaken
        let randomDirection = Direction.allCases.randomElement() ?? .up
        selectDirection(randomDirection)
        
        // Visual feedback for shake selection
        createShakeSelectionEffect()
        
        // Update instruction
        instructionLabel?.text = "摇动选择：\(randomDirection.emoji) - 让我们看看结果！"
    }
    
    private func handleShakeInResultPhase() {
        // Skip the waiting period and immediately start next round
        removeAction(forKey: "nextRoundDelay")
        
        // Visual feedback
        createShakeSparkles(at: CGPoint(x: size.width/2, y: size.height/2))
        
        // Update instruction
        instructionLabel?.text = "急不可待！立即开始下一回合..."
        
        // Start next round immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetGame()
        }
    }
    
    // MARK: - Shake Animation Helpers
    
    private func createShakeAnimation() -> SKAction {
        let shakeDistance: CGFloat = 8
        let shakeDuration: TimeInterval = 0.05
        
        let shakeLeft = SKAction.moveBy(x: -shakeDistance, y: 0, duration: shakeDuration)
        let shakeRight = SKAction.moveBy(x: shakeDistance * 2, y: 0, duration: shakeDuration)
        let shakeReturn = SKAction.moveBy(x: -shakeDistance, y: 0, duration: shakeDuration)
        
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeReturn])
        return SKAction.repeat(shakeSequence, count: 2)
    }
    
    private func createEnhancedSwingAnimation() -> SKAction {
        let swingRange: CGFloat = 30
        let randomX = CGFloat.random(in: -swingRange...swingRange)
        let randomY = CGFloat.random(in: -swingRange*0.5...swingRange*0.5)
        
        let swing = SKAction.moveBy(x: randomX, y: randomY, duration: 0.15)
        swing.timingMode = .easeOut
        
        let swingBack = SKAction.moveBy(x: -randomX, y: -randomY, duration: 0.15)
        swingBack.timingMode = .easeIn
        
        return SKAction.sequence([swing, swingBack])
    }
    
    private func createShakeSparkles(at position: CGPoint) {
        for _ in 0..<8 {
            let sparkle = SKShapeNode(circleOfRadius: 2)
            sparkle.fillColor = .yellow
            sparkle.strokeColor = .white
            sparkle.alpha = 1.0
            sparkle.position = position
            addChild(sparkle)
            
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...50)
            let endX = position.x + cos(randomAngle) * distance
            let endY = position.y + sin(randomAngle) * distance
            
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.5)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.1, duration: 0.5)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([SKAction.group([move, fadeOut, scale]), remove])
            sparkle.run(sequence)
        }
    }
    
    private func createShakeSelectionEffect() {
        // Create a burst effect at the center of the screen
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        for _ in 0..<12 {
            let burst = SKShapeNode(circleOfRadius: 4)
            burst.fillColor = .orange
            burst.strokeColor = .yellow
            burst.alpha = 1.0
            burst.position = center
            addChild(burst)
            
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...150)
            let endX = center.x + cos(randomAngle) * distance
            let endY = center.y + sin(randomAngle) * distance
            
            let move = SKAction.move(to: CGPoint(x: endX, y: endY), duration: 0.8)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let scale = SKAction.scale(to: 2.0, duration: 0.8)
            let remove = SKAction.removeFromParent()
            
            let sequence = SKAction.sequence([SKAction.group([move, fadeOut, scale]), remove])
            burst.run(sequence)
        }
        
        // Add screen pulse effect
        let overlay = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: size))
        overlay.fillColor = .orange
        overlay.alpha = 0.3
        addChild(overlay)
        
        let pulseSequence = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        overlay.run(pulseSequence)
    }
    
    // MARK: - Selection Timer

    private func selectionTimeout() -> TimeInterval {
        switch roundCount {
        case 0...2: return 4.0
        case 3...6: return 3.0
        default:    return 2.0
        }
    }

    private func startSelectionTimer(buttonAreaY: CGFloat, onTimeout: @escaping () -> Void) {
        cancelSelectionTimer()

        let timeout = selectionTimeout()
        selectionDeadline = Date().addingTimeInterval(timeout)

        // Create timer label
        let label = SKLabelNode(text: "\(Int(timeout))")
        label.fontSize = min(size.width, size.height) * 0.08
        label.fontColor = .white
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: size.width / 2, y: buttonAreaY)
        label.zPosition = 50
        label.name = "selectionTimerLabel"
        addChild(label)
        timerLabel = label

        selectionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let deadline = self.selectionDeadline else {
                timer.invalidate()
                return
            }
            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 {
                timer.invalidate()
                self.selectionTimer = nil
                self.selectionDeadline = nil
                self.timerLabel?.removeFromParent()
                self.timerLabel = nil
                onTimeout()
            } else {
                let displaySeconds = Int(ceil(remaining))
                self.timerLabel?.text = "\(displaySeconds)"
                if remaining <= 1.0 {
                    self.timerLabel?.fontColor = .red
                    // Flash effect
                    let flash = SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.3, duration: 0.05),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.05)
                    ])
                    if self.timerLabel?.hasActions() == false {
                        self.timerLabel?.run(SKAction.repeatForever(flash), withKey: "timerFlash")
                    }
                } else {
                    self.timerLabel?.fontColor = .white
                    self.timerLabel?.removeAction(forKey: "timerFlash")
                    self.timerLabel?.alpha = 1.0
                }
            }
        }
    }

    private func cancelSelectionTimer() {
        selectionTimer?.invalidate()
        selectionTimer = nil
        selectionDeadline = nil
        timerLabel?.removeFromParent()
        timerLabel = nil
    }

    deinit {
        selectionTimer?.invalidate()
        backgroundMusicPlayer?.stop()
    }
}

// MARK: - SettingsViewControllerDelegate
extension GameScene {
    func settingsDidSelectMusic(url: URL) {
        selectedMusicURL = url
        playBackgroundMusic()
    }
    
    func settingsDidUpdateVolume(volume: Float) {
        backgroundMusicPlayer?.volume = volume
    }
    
    func settingsDidTogglePlayback(isPlaying: Bool) {
        guard let player = backgroundMusicPlayer else { return }
        
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
    }
    
    func settingsDidStopMusic() {
        stopBackgroundMusic()
        selectedMusicURL = nil
    }

    func settingsDidChangeDifficulty(difficulty: Difficulty) {
        self.difficulty = difficulty
    }

    func settingsWillDismiss() {
        isSettingsVisible = false
        resumeGameFromSettings()
    }
    
    func rulesWillDismiss() {
        isSettingsVisible = false
        resumeGameFromSettings()
    }
    
}

// MARK: - MPMediaPickerControllerDelegate
extension GameScene: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true)
        
        guard let mediaItem = mediaItemCollection.items.first,
              let assetURL = mediaItem.assetURL else {
            return
        }
        
        selectedMusicURL = assetURL
        
        // Automatically start playing the selected music
        playBackgroundMusic()
        
        // Update UI indicators
        updateMusicStatusIndicator()
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
}
