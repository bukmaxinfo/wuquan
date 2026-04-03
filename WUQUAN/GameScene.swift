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

enum GamePhase {
    case handshake(step: Int)
    case freeMovement(step: Int)
    case gestureSelection
    case directionPointing
    case result
}

enum Gesture: CaseIterable {
    case rock, paper, scissors
    
    var emoji: String {
        switch self {
        case .rock: return "✊"
        case .paper: return "✋"
        case .scissors: return "✌️"
        }
    }
}

enum Direction: CaseIterable {
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

struct DeviceInfo {
    let screenSize: CGSize
    let deviceType: String
    let safeArea: UIEdgeInsets
}

class GameScene: SKScene, SettingsViewControllerDelegate, GameRulesDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
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
    private var handshakeAnimationTimer: Timer?
    private var gameScore = (player: 0, ai: 0)
    
    // Music System
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var selectedMusicURL: URL?
    private var musicButton: SKLabelNode?
    
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
        // This is called when the scene is presented to a view
        // Now we have access to the actual view and its safe area
        setupUI()
        setupAutoMusic()
        startHandshakePhase()
    }
    
    private func setupUI() {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
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
        
        // Game title (interactive - tap to show rules)
        let titleLabel = SKLabelNode(text: "舞拳")
        titleLabel.fontSize = min(headerZone.width, headerZone.height) * 0.3
        titleLabel.fontColor = .white
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.position = CGPoint(x: centerX, y: centerY + headerZone.height * 0.15)
        titleLabel.name = "gameTitle"
        
        // Add subtle glow effect to indicate interactivity
        let glowEffect = SKLabelNode(text: "舞拳")
        glowEffect.fontSize = titleLabel.fontSize
        glowEffect.fontColor = UIColor.yellow.withAlphaComponent(0.3)
        glowEffect.fontName = "Helvetica-Bold"
        glowEffect.position = titleLabel.position
        glowEffect.zPosition = titleLabel.zPosition - 1
        addChild(glowEffect)
        
        // Add pulsing animation to the glow
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 1.5),
            SKAction.fadeAlpha(to: 0.4, duration: 1.5)
        ])
        let repeatPulse = SKAction.repeatForever(pulseAction)
        glowEffect.run(repeatPulse)
        
        addChild(titleLabel)
        
        // Phase indicator
        phaseLabel = SKLabelNode(text: "握手阶段")
        phaseLabel?.fontSize = min(headerZone.width, headerZone.height) * 0.15
        phaseLabel?.fontColor = .yellow
        phaseLabel?.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.1)
        addChild(phaseLabel!)
        
        // Score background
        let scoreSize = CGSize(width: headerZone.width * 0.4, height: headerZone.height * 0.25)
        let scoreBackground = SKShapeNode(rectOf: scoreSize, cornerRadius: scoreSize.height * 0.3)
        scoreBackground.fillColor = SKColor(white: 0.2, alpha: 0.8)
        scoreBackground.strokeColor = .gray
        scoreBackground.lineWidth = 1
        scoreBackground.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.35)
        addChild(scoreBackground)
        
        // Score label
        let scoreLabel = SKLabelNode(text: "玩家 0 : 0 夜店小王子")
        scoreLabel.fontSize = min(headerZone.width, headerZone.height) * 0.12
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: centerX, y: centerY - headerZone.height * 0.4)
        scoreLabel.name = "scoreLabel"
        addChild(scoreLabel)
    }
    
    private func createGameArena(in gameZone: CGRect) {
        let centerX = gameZone.midX
        let centerY = gameZone.midY
        
        // Player area (left side)
        let areaWidth = gameZone.width * 0.35
        let areaHeight = gameZone.height * 0.8
        let playerX = gameZone.minX + gameZone.width * 0.2
        let aiX = gameZone.maxX - gameZone.width * 0.2
        
        // Player area background
        let playerArea = SKShapeNode(rectOf: CGSize(width: areaWidth, height: areaHeight), cornerRadius: areaWidth * 0.1)
        playerArea.fillColor = SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.3)
        playerArea.strokeColor = .cyan
        playerArea.lineWidth = 2
        playerArea.position = CGPoint(x: playerX, y: centerY)
        addChild(playerArea)
        
        // Player label
        let playerLabel = SKLabelNode(text: "你")
        playerLabel.fontSize = areaWidth * 0.2
        playerLabel.fontColor = .cyan
        playerLabel.fontName = "Helvetica-Bold"
        playerLabel.position = CGPoint(x: playerX, y: centerY + areaHeight * 0.25)
        addChild(playerLabel)
        
        // Player gesture display
        playerGestureLabel = SKLabelNode(text: "")
        playerGestureLabel?.fontSize = areaWidth * 0.4
        playerGestureLabel?.position = CGPoint(x: playerX, y: centerY - areaHeight * 0.1)
        addChild(playerGestureLabel!)
        
        // VS label in center
        let vsLabel = SKLabelNode(text: "VS")
        vsLabel.fontSize = gameZone.width * 0.08
        vsLabel.fontColor = .white
        vsLabel.fontName = "Helvetica-Bold"
        vsLabel.position = CGPoint(x: centerX, y: centerY)
        addChild(vsLabel)
        
        // AI area background
        let aiArea = SKShapeNode(rectOf: CGSize(width: areaWidth, height: areaHeight), cornerRadius: areaWidth * 0.1)
        aiArea.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 0.3)
        aiArea.strokeColor = .red
        aiArea.lineWidth = 2
        aiArea.position = CGPoint(x: aiX, y: centerY)
        addChild(aiArea)
        
        // AI label
        let aiLabel = SKLabelNode(text: "夜店小王子")
        aiLabel.fontSize = areaWidth * 0.2
        aiLabel.fontColor = .red
        aiLabel.fontName = "Helvetica-Bold"
        aiLabel.position = CGPoint(x: aiX, y: centerY + areaHeight * 0.25)
        addChild(aiLabel)
        
        // AI gesture display
        aiGestureLabel = SKLabelNode(text: "")
        aiGestureLabel?.fontSize = areaWidth * 0.4
        aiGestureLabel?.position = CGPoint(x: aiX, y: centerY - areaHeight * 0.1)
        addChild(aiGestureLabel!)
        
        // Hand animation nodes
        let handRadius = min(areaWidth, areaHeight) * 0.08
        
        playerHandNode = SKShapeNode(circleOfRadius: handRadius)
        playerHandNode?.fillColor = .cyan
        playerHandNode?.strokeColor = .white
        playerHandNode?.lineWidth = 2
        playerHandNode?.position = CGPoint(x: playerX, y: centerY - areaHeight * 0.35)
        addChild(playerHandNode!)
        
        aiHandNode = SKShapeNode(circleOfRadius: handRadius)
        aiHandNode?.fillColor = .red
        aiHandNode?.strokeColor = .white
        aiHandNode?.lineWidth = 2
        aiHandNode?.position = CGPoint(x: aiX, y: centerY - areaHeight * 0.35)
        addChild(aiHandNode!)
    }
    
    private func createControlArea(in controlZone: CGRect) {
        let centerX = controlZone.midX
        let centerY = controlZone.midY
        
        // Instructions background
        let instructionWidth = controlZone.width * 0.9
        let instructionHeight = controlZone.height * 0.4
        let instructionBackground = SKShapeNode(rectOf: CGSize(width: instructionWidth, height: instructionHeight), cornerRadius: instructionHeight * 0.2)
        instructionBackground.fillColor = SKColor(white: 0.1, alpha: 0.8)
        instructionBackground.strokeColor = .gray
        instructionBackground.lineWidth = 1
        instructionBackground.position = CGPoint(x: centerX, y: centerY + controlZone.height * 0.15)
        addChild(instructionBackground)
        
        // Instruction label
        instructionLabel = SKLabelNode(text: "准备开始舞拳...")
        instructionLabel?.fontSize = min(controlZone.width, controlZone.height) * 0.12
        instructionLabel?.fontColor = .yellow
        instructionLabel?.position = CGPoint(x: centerX, y: centerY + controlZone.height * 0.1)
        instructionLabel?.numberOfLines = 2
        addChild(instructionLabel!)
        
        // Interactive area for buttons (will be used during gameplay)
        let buttonArea = SKShapeNode(rectOf: CGSize(width: controlZone.width * 0.8, height: controlZone.height * 0.4))
        buttonArea.fillColor = .clear
        buttonArea.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        buttonArea.lineWidth = 1
        buttonArea.position = CGPoint(x: centerX, y: centerY - controlZone.height * 0.2)
        buttonArea.name = "buttonArea"
        addChild(buttonArea)
        
        let buttonAreaLabel = SKLabelNode(text: "游戏按钮区域")
        buttonAreaLabel.fontSize = controlZone.height * 0.08
        buttonAreaLabel.fontColor = SKColor(white: 0.6, alpha: 0.8)
        buttonAreaLabel.position = CGPoint(x: centerX, y: centerY - controlZone.height * 0.25)
        addChild(buttonAreaLabel)
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
        
        print("DEBUG: Game paused for settings")
    }
    
    private func resumeGameFromSettings() {
        // Show game buttons again
        showGameButtons()
        
        // Resume game animations
        resumeGameAnimations()
        
        print("DEBUG: Game resumed from settings")
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
        
        print("DEBUG: Hidden \(hiddenGameButtons.count) game buttons/elements")
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
        print("DEBUG: Restored all game buttons/elements")
    }
    
    private func pauseGameAnimations() {
        // Pause hand animations
        playerHandNode?.removeAllActions()
        aiHandNode?.removeAllActions()
        
        // Pause any timer-based animations
        handshakeAnimationTimer?.invalidate()
        
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
                print("DEBUG: Auto-selecting first music track: \(firstTrack.displayName)")
                selectedMusicURL = firstTrack.url
                
                // Auto-start playing if the file actually exists
                if FileManager.default.fileExists(atPath: firstTrack.url.path) {
                    playBackgroundMusic()
                    print("DEBUG: Auto-started background music: \(firstTrack.title)")
                } else {
                    print("DEBUG: Music file not found, will show in UI but won't play: \(firstTrack.filename)")
                }
                
                // Update music button to show current status
                updateMusicStatusIndicator()
            } else {
                print("DEBUG: No music tracks available for auto-selection")
            }
        } else {
            print("DEBUG: Music already selected, not auto-selecting")
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
    
    private func createDashedBorder(rect: CGRect) {
        let dashLength: CGFloat = 10
        let gapLength: CGFloat = 5
        let lineWidth: CGFloat = 4
        
        // Top border
        createDashedLine(
            start: CGPoint(x: rect.minX, y: rect.maxY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            dashLength: dashLength,
            gapLength: gapLength,
            lineWidth: lineWidth
        )
        
        // Bottom border
        createDashedLine(
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.minY),
            dashLength: dashLength,
            gapLength: gapLength,
            lineWidth: lineWidth
        )
        
        // Left border
        createDashedLine(
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.minX, y: rect.maxY),
            dashLength: dashLength,
            gapLength: gapLength,
            lineWidth: lineWidth
        )
        
        // Right border
        createDashedLine(
            start: CGPoint(x: rect.maxX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            dashLength: dashLength,
            gapLength: gapLength,
            lineWidth: lineWidth
        )
    }
    
    private func createDashedLine(start: CGPoint, end: CGPoint, dashLength: CGFloat, gapLength: CGFloat, lineWidth: CGFloat) {
        let totalLength = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        let segmentLength = dashLength + gapLength
        let numSegments = Int(totalLength / segmentLength)
        
        let dx = (end.x - start.x) / totalLength
        let dy = (end.y - start.y) / totalLength
        
        for i in 0..<numSegments {
            let segmentStart = CGFloat(i) * segmentLength
            let segmentEnd = min(segmentStart + dashLength, totalLength)
            
            if segmentEnd > segmentStart {
                let dashStart = CGPoint(
                    x: start.x + dx * segmentStart,
                    y: start.y + dy * segmentStart
                )
                let dashEnd = CGPoint(
                    x: start.x + dx * segmentEnd,
                    y: start.y + dy * segmentEnd
                )
                
                let dashRect: CGRect
                if abs(dx) > abs(dy) { // Horizontal line
                    dashRect = CGRect(
                        x: dashStart.x,
                        y: dashStart.y - lineWidth/2,
                        width: dashEnd.x - dashStart.x,
                        height: lineWidth
                    )
                } else { // Vertical line
                    dashRect = CGRect(
                        x: dashStart.x - lineWidth/2,
                        y: dashStart.y,
                        width: lineWidth,
                        height: dashEnd.y - dashStart.y
                    )
                }
                
                let dash = SKShapeNode(rect: dashRect)
                dash.fillColor = .white
                dash.strokeColor = .clear
                addChild(dash)
            }
        }
    }
    
    private func createCornerMarkers(rect: CGRect) {
        let markerSize: CGFloat = 20
        let markerThickness: CGFloat = 3
        
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY), // Bottom-left
            CGPoint(x: rect.maxX, y: rect.minY), // Bottom-right
            CGPoint(x: rect.minX, y: rect.maxY), // Top-left
            CGPoint(x: rect.maxX, y: rect.maxY)  // Top-right
        ]
        
        for corner in corners {
            // Horizontal line
            let hLine = SKShapeNode(rect: CGRect(x: -markerSize/2, y: -markerThickness/2, width: markerSize, height: markerThickness))
            hLine.fillColor = .yellow
            hLine.position = corner
            addChild(hLine)
            
            // Vertical line
            let vLine = SKShapeNode(rect: CGRect(x: -markerThickness/2, y: -markerSize/2, width: markerThickness, height: markerSize))
            vLine.fillColor = .yellow
            vLine.position = corner
            addChild(vLine)
        }
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
    
    private func presentMusicPicker() {
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
            print("ERROR: Could not find view controller to present music picker")
            return
        }
        
        print("DEBUG: Presenting music picker from view controller: \(presentingVC)")
        
        // Check if the presenting view controller can present
        if presentingVC.presentedViewController != nil {
            print("ERROR: Presenting view controller already has a presented view controller")
            return
        }
        
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.prompt = "选择背景音乐"
        mediaPicker.modalPresentationStyle = .formSheet
        
        print("DEBUG: About to present media picker")
        presentingVC.present(mediaPicker, animated: true) {
            print("DEBUG: Media picker presentation completed successfully")
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
    
    private func toggleMusic() {
        if backgroundMusicPlayer?.isPlaying == true {
            stopBackgroundMusic()
        } else if selectedMusicURL != nil {
            playBackgroundMusic()
        } else {
            presentMusicPicker()
        }
    }
    
    private func adjustMusicTempo(_ rate: Float) {
        guard let player = backgroundMusicPlayer, player.isPlaying else { return }
        player.rate = rate
        player.enableRate = true
    }
    
    private func startHandshakePhase() {
        gamePhase = .handshake(step: 1)
        phaseLabel?.text = "握手阶段 (1/4)"
        instructionLabel?.text = "与夜店小王子握手四次..."
        
        // Slow down music for handshake phase
        adjustMusicTempo(0.8)
        
        animateHandshake()
    }
    
    private func animateHandshake() {
        guard case .handshake(let step) = gamePhase else { return }
        
        // Animate hands moving together
        let moveToCenter = SKAction.moveTo(x: size.width/2 - 50, duration: 0.5)
        let moveToCenter2 = SKAction.moveTo(x: size.width/2 + 50, duration: 0.5)
        let moveBack = SKAction.moveTo(x: size.width/4, duration: 0.5)
        let moveBack2 = SKAction.moveTo(x: 3*size.width/4, duration: 0.5)
        
        let sequence = SKAction.sequence([moveToCenter, moveBack])
        let sequence2 = SKAction.sequence([moveToCenter2, moveBack2])
        
        playerHandNode?.run(sequence)
        aiHandNode?.run(sequence2) {
            self.completeHandshakeStep()
        }
    }
    
    private func completeHandshakeStep() {
        guard case .handshake(let step) = gamePhase else { return }
        
        if step < 4 {
            gamePhase = .handshake(step: step + 1)
            phaseLabel?.text = "握手阶段 (\(step + 1)/4)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateHandshake()
            }
        } else {
            startFreeMovementPhase()
        }
    }
    
    private func startFreeMovementPhase() {
        gamePhase = .freeMovement(step: 1)
        phaseLabel?.text = "自由晃动 (1/4)"
        instructionLabel?.text = "疯狂晃动手腕！"
        
        // Speed up music for free movement phase
        adjustMusicTempo(1.2)
        
        animateFreeMovement()
    }
    
    private func animateFreeMovement() {
        guard case .freeMovement(let step) = gamePhase else { return }
        
        // Enhanced visual feedback with particle effects
        let screenSize = min(size.width, size.height)
        let swingRange = screenSize * 0.08
        
        // Create swing trail effect
        let trail = SKShapeNode(circleOfRadius: 3)
        trail.fillColor = .yellow
        trail.alpha = 0.7
        trail.position = playerHandNode?.position ?? CGPoint.zero
        addChild(trail)
        
        // Fade out trail
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        trail.run(fadeOut)
        
        // Enhanced swinging animation with bounce
        let randomX = CGFloat.random(in: -swingRange...swingRange)
        let randomY = CGFloat.random(in: -swingRange*0.6...swingRange*0.6)
        
        let swing = SKAction.moveBy(x: randomX, y: randomY, duration: 0.25)
        swing.timingMode = .easeOut
        
        let swingBack = SKAction.moveBy(x: -randomX, y: -randomY, duration: 0.25)
        swingBack.timingMode = .easeIn
        
        let bounce = SKAction.sequence([swing, swingBack])
        let sequence = SKAction.sequence([bounce])
        
        // Scale effect for impact
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        
        playerHandNode?.run(sequence)
        playerHandNode?.run(scaleSequence)
        aiHandNode?.run(sequence) {
            self.completeFreeMovementStep()
        }
        aiHandNode?.run(scaleSequence)
    }
    
    private func completeFreeMovementStep() {
        guard case .freeMovement(let step) = gamePhase else { return }
        
        if step < 4 {
            gamePhase = .freeMovement(step: step + 1)
            phaseLabel?.text = "自由晃动 (\(step + 1)/4)"
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
            // Dynamic button background
            let buttonBg = SKShapeNode(circleOfRadius: buttonSize*0.7)
            buttonBg.fillColor = SKColor(white: 0.3, alpha: 0.8)
            buttonBg.strokeColor = .white
            buttonBg.lineWidth = 2
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
    }
    
    private func selectGesture(_ gesture: Gesture) {
        playerGesture = gesture
        playerGestureLabel?.text = gesture.emoji
        aiGestureLabel?.text = aiGesture?.emoji ?? ""
        
        // Remove gesture buttons
        children.filter { $0.name?.hasPrefix("gesture_") == true }.forEach { $0.removeFromParent() }
        
        // Show gestures twice as per rules
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startDirectionPointingPhase()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
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
        
        // Determine AI direction based on rules
        let sameGesture = playerGesture == aiGesture
        if sameGesture {
            instructionLabel?.text = "手势相同，选择相同方向"
            aiDirection = Direction.allCases.randomElement()
        } else {
            instructionLabel?.text = "手势不同，选择不同方向"
            aiDirection = Direction.allCases.randomElement()
        }
        
        showDirectionButtons()
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
            // Dynamic button background
            let buttonBg = SKShapeNode(circleOfRadius: buttonSize*0.8)
            buttonBg.fillColor = SKColor(white: 0.3, alpha: 0.8)
            buttonBg.strokeColor = .yellow
            buttonBg.lineWidth = 2
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
    }
    
    private func selectDirection(_ direction: Direction) {
        playerDirection = direction
        
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
        
        let sameGesture = playerGesture == aiGesture
        let sameDirection = playerDirection == aiDirection
        
        var resultText: String
        var winner: String
        
        // Enhanced win/loss detection with visual feedback
        if sameGesture && sameDirection {
            resultText = "正确! 手势相同，方向相同"
            winner = "继续游戏"
            showSuccessEffect()
        } else if !sameGesture && !sameDirection {
            resultText = "正确! 手势不同，方向不同"
            winner = "继续游戏"
            showSuccessEffect()
        } else {
            resultText = "错误! 违反规则"
            if sameGesture && !sameDirection {
                winner = "玩家失败 😢"
                gameScore.ai += 1
                showFailureEffect()
            } else {
                winner = "夜店小王子失败 🎉"
                gameScore.player += 1
                showVictoryEffect()
            }
        }
        
        phaseLabel?.text = winner
        instructionLabel?.text = resultText
        updateScoreDisplay()
        
        // Reset for next round
        let nextRoundAction = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run { self.resetGame() }
        ])
        self.run(nextRoundAction, withKey: "nextRoundDelay")
    }
    
    private func resetGame() {
        playerGesture = nil
        aiGesture = nil
        playerDirection = nil
        aiDirection = nil
        playerGestureLabel?.text = ""
        aiGestureLabel?.text = ""
        
        startHandshakePhase()
    }
    
    private func updateScoreDisplay() {
        if let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode {
            scoreLabel.text = "玩家 \(gameScore.player) : \(gameScore.ai) 夜店小王子"
        }
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
        // 夜店小王子的策略：聪明而狡猾的选择模式
        let allGestures = Gesture.allCases
        
        // 夜店小王子具有基本策略：倾向于对抗常见的人类模式
        // 人类通常首选石头，所以夜店小王子稍微偏爱布
        let weights: [Gesture: Double] = [
            .rock: 0.3,
            .paper: 0.4,  // Slightly higher chance to counter rock
            .scissors: 0.3
        ]
        
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for gesture in allGestures {
            cumulative += weights[gesture] ?? 0.33
            if random <= cumulative {
                return gesture
            }
        }
        
        return .rock // Fallback
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
    
    private func addDebugOverlays() {
        let screenWidth = size.width
        let screenHeight = size.height
        var safeAreaTop: CGFloat = 44
        var safeAreaBottom: CGFloat = 34
        
        // Get real safe area from the view
        if let view = self.view {
            let rawSafeAreaTop = view.safeAreaInsets.top
            let rawSafeAreaBottom = view.safeAreaInsets.bottom
            
            print("DEBUG: Scene size - width: \(screenWidth), height: \(screenHeight)")
            print("DEBUG: View bounds - \(view.bounds)")
            print("DEBUG: View frame - \(view.frame)")
            print("DEBUG: Raw safe area insets - top: \(rawSafeAreaTop), bottom: \(rawSafeAreaBottom)")
            
            // Handle case where safe area is 0 (common in simulator or older devices)
            if rawSafeAreaTop == 0 && rawSafeAreaBottom == 0 {
                // Use device-specific fallbacks based on screen size
                if screenHeight >= 812 { // iPhone X and newer
                    safeAreaTop = 47  // Notch/Dynamic Island
                    safeAreaBottom = 34  // Home indicator
                } else if screenHeight >= 736 { // iPhone Plus models
                    safeAreaTop = 20  // Status bar
                    safeAreaBottom = 0
                } else { // Older iPhones
                    safeAreaTop = 20  // Status bar
                    safeAreaBottom = 0
                }
                print("DEBUG: Using fallback safe areas - top: \(safeAreaTop), bottom: \(safeAreaBottom)")
            } else {
                safeAreaTop = rawSafeAreaTop
                safeAreaBottom = rawSafeAreaBottom
                print("DEBUG: Using real safe areas - top: \(safeAreaTop), bottom: \(safeAreaBottom)")
            }
        }
        
        // FULL SCREEN DEBUG OVERLAYS to identify coordinate system and edges
        
        // 1. Create a border around the entire screen to show the actual boundaries
        let fullScreenBorder = SKShapeNode(rect: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        fullScreenBorder.fillColor = .clear
        fullScreenBorder.strokeColor = .white
        fullScreenBorder.lineWidth = 5
        fullScreenBorder.position = CGPoint.zero
        addChild(fullScreenBorder)
        
        // 2. Create corner markers at all four corners to verify coordinate system
        let cornerRadius: CGFloat = 15
        let corners = [
            CGPoint(x: cornerRadius, y: cornerRadius),                           // Bottom-left (origin)
            CGPoint(x: screenWidth - cornerRadius, y: cornerRadius),             // Bottom-right
            CGPoint(x: cornerRadius, y: screenHeight - cornerRadius),            // Top-left
            CGPoint(x: screenWidth - cornerRadius, y: screenHeight - cornerRadius) // Top-right
        ]
        
        let cornerColors: [SKColor] = [.yellow, .red, .green, .blue]
        for (index, corner) in corners.enumerated() {
            let marker = SKShapeNode(circleOfRadius: cornerRadius)
            marker.fillColor = cornerColors[index]
            marker.strokeColor = .white
            marker.lineWidth = 3
            marker.position = corner
            addChild(marker)
        }
        
        // 3. Red safe area zones
        let contentSafeAreaTop = screenHeight * 0.12
        let contentSafeAreaBottom = screenHeight * 0.10
        
        // Top safe area (RED) - should appear at the very top
        let safeTopOverlay = SKShapeNode(rect: CGRect(x: 0, y: screenHeight - contentSafeAreaTop, width: screenWidth, height: contentSafeAreaTop))
        safeTopOverlay.fillColor = SKColor.red
        safeTopOverlay.alpha = 0.7
        safeTopOverlay.strokeColor = .red
        safeTopOverlay.lineWidth = 5
        safeTopOverlay.position = CGPoint.zero
        addChild(safeTopOverlay)
        print("DEBUG: Top safe area overlay - rect: (0, \(screenHeight - contentSafeAreaTop), \(screenWidth), \(contentSafeAreaTop))")
        
        // Bottom safe area (RED) - should appear at the very bottom
        let safeBottomOverlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: screenWidth, height: contentSafeAreaBottom))
        safeBottomOverlay.fillColor = SKColor.red
        safeBottomOverlay.alpha = 0.7
        safeBottomOverlay.strokeColor = .red
        safeBottomOverlay.lineWidth = 5
        safeBottomOverlay.position = CGPoint.zero
        addChild(safeBottomOverlay)
        print("DEBUG: Bottom safe area overlay - rect: (0, 0, \(screenWidth), \(contentSafeAreaBottom))")
        
        // 4. Layout zones with different colors
        let headerHeight = screenHeight * 0.15
        let gameAreaHeight = screenHeight * 0.4
        let buttonAreaHeight = screenHeight * 0.25
        let footerHeight = screenHeight * 0.12
        
        // Header area (BLUE)
        let headerY = screenHeight - contentSafeAreaTop - headerHeight
        let headerOverlay = SKShapeNode(rect: CGRect(x: 0, y: headerY, width: screenWidth, height: headerHeight))
        headerOverlay.fillColor = SKColor.blue
        headerOverlay.alpha = 0.3
        headerOverlay.strokeColor = .blue
        headerOverlay.lineWidth = 3
        headerOverlay.position = CGPoint.zero
        addChild(headerOverlay)
        
        // Game area (GREEN)
        let gameAreaY = headerY - gameAreaHeight
        let gameOverlay = SKShapeNode(rect: CGRect(x: 0, y: gameAreaY, width: screenWidth, height: gameAreaHeight))
        gameOverlay.fillColor = SKColor.green
        gameOverlay.alpha = 0.3
        gameOverlay.strokeColor = .green
        gameOverlay.lineWidth = 3
        gameOverlay.position = CGPoint.zero
        addChild(gameOverlay)
        
        // Button area (PURPLE)
        let buttonAreaY = contentSafeAreaBottom + footerHeight
        let buttonOverlay = SKShapeNode(rect: CGRect(x: 0, y: buttonAreaY, width: screenWidth, height: buttonAreaHeight))
        buttonOverlay.fillColor = SKColor.purple
        buttonOverlay.alpha = 0.3
        buttonOverlay.strokeColor = .purple
        buttonOverlay.lineWidth = 3
        buttonOverlay.position = CGPoint.zero
        addChild(buttonOverlay)
        
        // Footer area (ORANGE)
        let footerOverlay = SKShapeNode(rect: CGRect(x: 0, y: contentSafeAreaBottom, width: screenWidth, height: footerHeight))
        footerOverlay.fillColor = SKColor.orange
        footerOverlay.alpha = 0.3
        footerOverlay.strokeColor = .orange
        footerOverlay.lineWidth = 3
        footerOverlay.position = CGPoint.zero
        addChild(footerOverlay)
        
        // 5. Add coordinate labels
        let coordinateLabels = [
            ("(0,0)", CGPoint(x: 40, y: 30), SKColor.yellow),
            ("(\(Int(screenWidth)),0)", CGPoint(x: screenWidth - 80, y: 30), SKColor.red),
            ("(0,\(Int(screenHeight)))", CGPoint(x: 80, y: screenHeight - 30), SKColor.green),
            ("(\(Int(screenWidth)),\(Int(screenHeight)))", CGPoint(x: screenWidth - 120, y: screenHeight - 30), SKColor.blue)
        ]
        
        for (text, position, color) in coordinateLabels {
            let label = SKLabelNode(text: text)
            label.fontSize = 18
            label.fontColor = color
            label.fontName = "Helvetica-Bold"
            label.position = position
            addChild(label)
        }
        
        // 6. Add device info and scaling detection
        let deviceInfo = SKLabelNode(text: "Device: \(getDeviceTypeString(width: screenWidth, height: screenHeight))")
        deviceInfo.fontSize = 16
        deviceInfo.fontColor = .white
        deviceInfo.fontName = "Helvetica-Bold"
        deviceInfo.position = CGPoint(x: screenWidth/2, y: screenHeight/2 + 40)
        addChild(deviceInfo)
        
        let scaleInfo = SKLabelNode(text: "Screen: \(Int(screenWidth))x\(Int(screenHeight))")
        scaleInfo.fontSize = 16
        scaleInfo.fontColor = .white
        scaleInfo.fontName = "Helvetica-Bold"
        scaleInfo.position = CGPoint(x: screenWidth/2, y: screenHeight/2)
        addChild(scaleInfo)
        
        let simulatorWarning = SKLabelNode(text: "SIMULATOR IN SCALED MODE!")
        simulatorWarning.fontSize = 18
        simulatorWarning.fontColor = .cyan
        simulatorWarning.fontName = "Helvetica-Bold"
        simulatorWarning.position = CGPoint(x: screenWidth/2, y: screenHeight/2 - 40)
        addChild(simulatorWarning)
        
        // 7. Add zone labels
        let zoneLabels = [
            ("TOP SAFE (RED)", CGPoint(x: screenWidth/2, y: screenHeight - contentSafeAreaTop/2), SKColor.white),
            ("BOTTOM SAFE (RED)", CGPoint(x: screenWidth/2, y: contentSafeAreaBottom/2), SKColor.white),
            ("HEADER (BLUE)", CGPoint(x: screenWidth/2, y: headerY + headerHeight/2), SKColor.white),
            ("GAME (GREEN)", CGPoint(x: screenWidth/2, y: gameAreaY + gameAreaHeight/2), SKColor.white),
            ("BUTTONS (PURPLE)", CGPoint(x: screenWidth/2, y: buttonAreaY + buttonAreaHeight/2), SKColor.white),
            ("FOOTER (ORANGE)", CGPoint(x: screenWidth/2, y: contentSafeAreaBottom + footerHeight/2), SKColor.white)
        ]
        
        for (text, position, color) in zoneLabels {
            let label = SKLabelNode(text: text)
            label.fontSize = 14
            label.fontColor = color
            label.fontName = "Helvetica-Bold"
            label.position = position
            addChild(label)
        }
    }
    
    func handleShakeGesture() {
        guard !isSettingsVisible else { return }
        
        print("DEBUG: GameScene received shake gesture, current phase: \(gamePhase)")
        
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
        print("DEBUG: Shake during handshake phase - adding intensity")
        
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
        print("DEBUG: Shake during free movement phase - enhancing movement")
        
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
        print("DEBUG: Shake during gesture selection - quick random selection")
        
        // Randomly select a gesture when shaken
        let randomGesture = Gesture.allCases.randomElement() ?? .rock
        selectGesture(randomGesture)
        
        // Visual feedback for shake selection
        createShakeSelectionEffect()
        
        // Update instruction
        instructionLabel?.text = "摇动选择：\(randomGesture.emoji) - 好选择！"
    }
    
    private func handleShakeInDirectionPointingPhase() {
        print("DEBUG: Shake during direction pointing - quick random selection")
        
        // Randomly select a direction when shaken
        let randomDirection = Direction.allCases.randomElement() ?? .up
        selectDirection(randomDirection)
        
        // Visual feedback for shake selection
        createShakeSelectionEffect()
        
        // Update instruction
        instructionLabel?.text = "摇动选择：\(randomDirection.emoji) - 让我们看看结果！"
    }
    
    private func handleShakeInResultPhase() {
        print("DEBUG: Shake during result phase - skip to next round")
        
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
    
    deinit {
        handshakeAnimationTimer?.invalidate()
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
            print("No valid media item selected")
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
