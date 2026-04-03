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
        
        // Request MediaPlayer permission
        requestMediaLibraryPermission()
        
        // Create GameScene programmatically
        if let view = self.view as? SKView {
            // Create the scene with the view's bounds
            let scene = GameScene(size: view.bounds.size)
            self.gameScene = scene
            
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
        
        // Setup motion detection
        setupMotionDetection()
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
            print("DEBUG: Accelerometer not available")
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
        
        print("DEBUG: Motion detection setup completed")
    }
    
    private func handleShakeGesture() {
        print("DEBUG: Shake detected!")
        
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
