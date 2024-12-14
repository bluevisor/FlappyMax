//
// LoadingScene.swift
//
// Initial loading scene for FlappyMax.
// Features:
// - Asset preloading
// - Loading animation
// - Progress indication
// - Smooth transition to main menu
// - Resource initialization
//

//
//  LoadingScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Initial loading scene for FlappyMax
 
 Responsibilities:
 - Resource preloading
 - Loading state management
 - Progress tracking
 - Scene transition
 - Error handling
 
 Features:
 - Asset preloading
 - Loading animation
 - Progress display
 - Error handling
 - Smooth transitions
 - Resource management
 - State tracking
 - Memory optimization
 - Performance monitoring
 - User feedback
 */

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
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        run(SKAction.sequence([wait, fadeOut]), completion: completion)
    }
}
