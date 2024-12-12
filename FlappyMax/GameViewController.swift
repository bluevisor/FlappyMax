//
//  GameViewController.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Main view controller for FlappyMax
 
 Responsibilities:
 - Game initialization
 - Scene management
 - View configuration
 - Device orientation
 - Loading coordination
 
 Features:
 - Scene setup and transitions
 - View configuration
 - Orientation handling
 - Loading screen management
 - Error handling
 - Memory management
 - State preservation
 - Performance monitoring
 - Debug options
 - Device adaptation
 */

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    private var loadingScene: LoadingScene?
    private var assetsLoaded = 0
    private let totalAssets = 11 // Total number of assets to load (textures + sounds)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Configure view
            view.ignoresSiblingOrder = true
            #if DEBUG
            view.showsPhysics = true
            view.showsFPS = true
            view.showsNodeCount = true
            #endif
            
            // Enable texture pre-loading
            view.preferredFramesPerSecond = 60
            
            // Start with loading scene
            loadingScene = LoadingScene(size: view.bounds.size)
            loadingScene?.scaleMode = .aspectFill
            view.presentScene(loadingScene)
            
            // Preload game assets in background
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.preloadGameAssets()
            }
        }
    }
    
    private func updateLoadingProgress() {
        assetsLoaded += 1
        let progress = CGFloat(assetsLoaded) / CGFloat(totalAssets)
        
        #if DEBUG
        print("Loading progress: \(Int(progress * 100))%") // Debug loading progress
        #endif
        
        DispatchQueue.main.async { [weak self] in
            self?.loadingScene?.updateProgress(to: progress)
            
            // If all assets are loaded, transition to main menu
            if progress >= 1.0 {
                self?.transitionToMainMenu()
            }
        }
    }
    
    private func transitionToMainMenu() {
        guard let view = self.view as? SKView else { return }
        
        loadingScene?.complete { [weak self] in
            // Create and present main menu scene
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            view.presentScene(scene, transition: .fade(withDuration: 0.3))
            self?.loadingScene = nil
        }
    }
    
    private func preloadGameAssets() {
        // Preload textures
        let textureNames = ["flappymax_title_white", "hero", "pole_top", "pole_bottom", "coin", "burger"]
        textureNames.forEach { textureName in
            let texture = SKTexture(imageNamed: textureName)
            texture.preload { [weak self] in
                self?.updateLoadingProgress()
            }
        }
        
        // Preload sound effects
        let soundNames = ["flap", "coin", "burger", "game_over", "game_start"]
        soundNames.forEach { name in
            if let url = Bundle.main.url(forResource: name, withExtension: name == "flap" ? "caf" : "mp3") {
                DispatchQueue.main.async { [weak self] in
                    let player = try? AVAudioPlayer(contentsOf: url)
                    player?.prepareToPlay()
                    self?.updateLoadingProgress()
                }
            } else {
                // If sound file is missing, still update progress to avoid getting stuck
                DispatchQueue.main.async { [weak self] in
                    self?.updateLoadingProgress()
                }
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
