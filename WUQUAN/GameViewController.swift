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
import GameKit

class GameViewController: UIViewController {

    // Motion detection
    private let motionManager = CMMotionManager()
    private var gameScene: GameScene?
    private var lastShakeTime: TimeInterval = 0
    private let shakeThreshold: Double = 2.5
    private let shakeCooldown: TimeInterval = 0.5
    private var hasShownSelection = false

    override func viewDidLoad() {
        super.viewDidLoad()
        requestMediaLibraryPermission()
        setupMotionDetection()
        GameCenterManager.shared.authenticatePlayer(from: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasShownSelection {
            hasShownSelection = true
            showCharacterSelection()
        }
    }

    private func showCharacterSelection() {
        let selectionVC = CharacterSelectionViewController()
        selectionVC.delegate = self
        selectionVC.modalPresentationStyle = .fullScreen
        present(selectionVC, animated: true)
    }

    private func startGame(
        playerStyle: CharacterStyle, playerVariant: CharacterColorVariant,
        opponentStyle: CharacterStyle, opponentVariant: CharacterColorVariant,
        gameMode: GameMode, theme: GameTheme
    ) {
        guard let view = self.view as? SKView else { return }

        let scene = GameScene(size: view.bounds.size)
        scene.playerStyle = playerStyle
        scene.playerColorVariant = playerVariant
        scene.opponentStyle = opponentStyle
        scene.opponentColorVariant = opponentVariant
        scene.gameMode = gameMode
        scene.gameTheme = theme
        scene.scaleMode = .aspectFill
        self.gameScene = scene

        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }

    override var prefersStatusBarHidden: Bool { true }

    private func requestMediaLibraryPermission() {
        MPMediaLibrary.requestAuthorization { _ in }
    }

    // MARK: - Motion Detection

    private func setupMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let acc = data?.acceleration else { return }
            let mag = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
            let now = CACurrentMediaTime()
            if mag > self.shakeThreshold && now - self.lastShakeTime > self.shakeCooldown {
                self.lastShakeTime = now
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                self.gameScene?.handleShakeGesture()
            }
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - CharacterSelectionDelegate

extension GameViewController: CharacterSelectionDelegate {
    func characterSelectionDidComplete(
        playerStyle: CharacterStyle, playerVariant: CharacterColorVariant,
        opponentStyle: CharacterStyle, opponentVariant: CharacterColorVariant,
        gameMode: GameMode, theme: GameTheme
    ) {
        dismiss(animated: true) {
            self.startGame(
                playerStyle: playerStyle, playerVariant: playerVariant,
                opponentStyle: opponentStyle, opponentVariant: opponentVariant,
                gameMode: gameMode, theme: theme
            )
        }
    }
}
