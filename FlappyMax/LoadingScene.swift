//
//  LoadingScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
//  LoadingScene.swift
//
//  This file defines the `LoadingScene` class, which is responsible for displaying a loading screen while the game assets are being preloaded. The loading scene provides visual feedback to the player, indicating that the game is preparing to start. It includes a progress bar that updates as assets are loaded, ensuring that players have a smooth transition into the main game scene.
//
//  Responsibilities:
//  - Display a loading screen with a progress bar and loading text.
//  - Manage the loading of game assets, including textures and sound effects.
//  - Update the loading progress visually and programmatically.
//  - Transition to the main menu or game scene once all assets are loaded.
//
//  Key Components:
//  - `progressBar`: A visual representation of the loading progress.
//  - `progressFill`: The portion of the progress bar that indicates the current loading progress.
//  - `currentProgress`: The current loading progress, represented as a value between 0 and 1.
//  - Methods to handle the loading process and update the UI accordingly.
//
//  Usage:
//  The `LoadingScene` is presented at the start of the game to preload necessary assets in the background. Once all assets are loaded, the scene transitions to the main menu or the game scene, providing a seamless experience for the player.

import SpriteKit

class LoadingScene: SKScene {
    private var progressBar: SKShapeNode!
    private var progressFill: SKShapeNode!
    
    private let progressBarWidth: CGFloat = 420
    private let progressBarHeight: CGFloat = 5
    private let cornerRadius: CGFloat = 2
    
    private var currentProgress: CGFloat = 0.0 {
        didSet {
            updateProgressBar()
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupLoadingUI()
    }
    
    private func setupLoadingUI() {
        // Progress bar background (outline)
        progressBar = SKShapeNode()
        let barRect = CGRect(
            x: -progressBarWidth/2,
            y: -progressBarHeight/2,
            width: progressBarWidth,
            height: progressBarHeight
        )
        progressBar.path = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius).cgPath
        progressBar.strokeColor = .white
        progressBar.lineWidth = 1
        progressBar.fillColor = .clear
        progressBar.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(progressBar)
        
        // Progress bar fill
        progressFill = SKShapeNode()
        progressFill.fillColor = .white
        progressFill.strokeColor = .clear
        progressFill.position = progressBar.position
        addChild(progressFill)
        
        // Initial progress update
        updateProgress(to: 0)
    }
    
    private func updateProgressBar() {
        let fillWidth = progressBarWidth * currentProgress
        let fillRect = CGRect(
            x: -progressBarWidth/2,
            y: -progressBarHeight/2,
            width: fillWidth,
            height: progressBarHeight
        )
        progressFill.path = UIBezierPath(roundedRect: fillRect, cornerRadius: cornerRadius).cgPath
    }
    
    func updateProgress(to progress: CGFloat) {
        // Ensure progress is between 0 and 1
        currentProgress = min(1, max(0, progress))
    }
    
    func complete(completion: @escaping () -> Void) {
        // Ensure we're at 100%
        updateProgress(to: 1.0)
        
        // Add a small delay before transitioning
        let wait = SKAction.wait(forDuration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        run(SKAction.sequence([wait, fadeOut]), completion: completion)
    }
}
