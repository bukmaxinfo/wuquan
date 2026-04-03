//
//  GameViewController.swift
//  WUQUAN
//
//  Created by shuming li on 7/19/25.
//

import UIKit
import SpriteKit
import GameplayKit
import MediaPlayer
import CoreMotion

class GameViewController: UIViewController {
    
    // Motion detection
    private let motionManager = CMMotionManager()
    private var gameScene: GameScene?
    private var lastShakeTime: TimeInterval = 0
    private let shakeThreshold: Double = 2.5
    private let shakeCooldown: TimeInterval = 0.5

    override func viewDidLoad() {
        super.viewDidLoad()
        requestMediaLibraryPermission()
        setupMotionDetection()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Show character selection on first appearance
        if gameScene == nil {
            showCharacterSelection()
        }
    }

    private func showCharacterSelection() {
        let selectionVC = CharacterSelectionViewController()
        selectionVC.delegate = self
        selectionVC.modalPresentationStyle = .fullScreen
        present(selectionVC, animated: true)
    }

    private func startGame(playerStyle: CharacterStyle, opponentStyle: CharacterStyle) {
        guard let view = self.view as? SKView else { return }

        let scene = GameScene(size: view.bounds.size)
        scene.playerStyle = playerStyle
        scene.opponentStyle = opponentStyle
        scene.scaleMode = .aspectFill
        self.gameScene = scene

        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func requestMediaLibraryPermission() {
        MPMediaLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("MediaPlayer access granted")
            case .denied, .restricted:
                print("MediaPlayer access denied")
            case .notDetermined:
                print("MediaPlayer access not determined")
            @unknown default:
                print("Unknown MediaPlayer access status")
            }
        }
    }
    
    // MARK: - Motion Detection
    
    private func setupMotionDetection() {
        guard motionManager.isAccelerometerAvailable else {
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let acceleration = data?.acceleration else { return }
            
            let magnitude = sqrt(acceleration.x * acceleration.x + 
                               acceleration.y * acceleration.y + 
                               acceleration.z * acceleration.z)
            
            let currentTime = CACurrentMediaTime()
            
            if magnitude > self.shakeThreshold && 
               currentTime - self.lastShakeTime > self.shakeCooldown {
                self.lastShakeTime = currentTime
                self.handleShakeGesture()
            }
        }
    }
    
    private func handleShakeGesture() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Forward shake event to game scene
        gameScene?.handleShakeGesture()
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - CharacterSelectionDelegate

extension GameViewController: CharacterSelectionDelegate {
    func characterSelectionDidComplete(playerStyle: CharacterStyle, opponentStyle: CharacterStyle) {
        startGame(playerStyle: playerStyle, opponentStyle: opponentStyle)
    }
}
