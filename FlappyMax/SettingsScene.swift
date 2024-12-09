//
//  SettingsScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Settings management scene for FlappyMax
 
 Responsibilities:
 - Sound volume control
 - Data management options
 - Settings persistence
 - User interface layout
 - Scene transitions
 
 Features:
 - Volume slider control
 - Volume percentage display
 - Scoreboard reset option
 - Settings persistence
 - Visual feedback system
 - Device-specific layouts
 - Smooth animations
 - Data validation
 - Error handling
 - Clean UI design
 - Responsive controls
 - User confirmation
 - State management
 - Easy navigation
 */

import SpriteKit
import UIKit

class SettingsScene: SKScene {
    private var volumeSlider: UISlider?
    private var volumeLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        let contentNode = SKNode()
        addChild(contentNode)
        
        // Calculate vertical spacing based on screen height
        let screenHeight = frame.height
        let spacing = screenHeight * 0.1  // Increased to 12% of screen height
        
        // Title at top
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "Settings"
        titleLabel.fontSize = GameConfig.adaptiveFontSize(42)
        titleLabel.position = CGPoint(x: 0, y: spacing * 3)
        contentNode.addChild(titleLabel)
        
        // Volume label
        let volumeTextLabel = SKLabelNode(fontNamed: "Helvetica")
        volumeTextLabel.text = "Volume"
        volumeTextLabel.fontSize = GameConfig.adaptiveFontSize(20)
        volumeTextLabel.position = CGPoint(x: -80, y: spacing * 1.5)
        contentNode.addChild(volumeTextLabel)
        
        // Volume percentage label
        volumeLabel = SKLabelNode(fontNamed: "Helvetica")
        volumeLabel.fontSize = GameConfig.adaptiveFontSize(20)
        volumeLabel.position = CGPoint(x: 100, y: spacing * 1.5)
        volumeLabel.name = "volumePercent"
        contentNode.addChild(volumeLabel)
        
        // Scoreboard button
        let scoreboardButton = SKLabelNode(fontNamed: "Helvetica")
        scoreboardButton.text = "Scoreboard"
        scoreboardButton.fontSize = GameConfig.adaptiveFontSize(20)
        scoreboardButton.position = CGPoint(x: 0, y: -spacing)
        scoreboardButton.name = "scoreboardButton"
        contentNode.addChild(scoreboardButton)
        
        // Clear Scoreboard button
        let resetButton = SKLabelNode(fontNamed: "Helvetica")
        resetButton.text = "Clear Scoreboard"
        resetButton.fontSize = GameConfig.adaptiveFontSize(20)
        resetButton.position = CGPoint(x: 0, y: -spacing * 2)
        resetButton.name = "resetButton"
        contentNode.addChild(resetButton)
        
        // Back button at bottom
        let backButton = SKLabelNode(fontNamed: "Helvetica")
        backButton.text = "Back"
        backButton.fontSize = GameConfig.adaptiveFontSize(20)
        backButton.position = CGPoint(x: 0, y: -spacing * 3)
        backButton.name = "backButton"
        contentNode.addChild(backButton)
        
        // Center the content node
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Setup volume slider
        setupVolumeSlider()
        updateVolumeLabel()
    }
    
    // Setup volume slider
    private func setupVolumeSlider() {
        volumeSlider?.removeFromSuperview()
        
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = UserDefaults.standard.float(forKey: "SoundEffectsVolume")

        // Decide on slider width
        let sliderWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 260 : 300
        let sliderOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -35 : -70
        
        // Position the slider at the center of the view
        if let view = self.view {
            // Place the slider horizontally centered, and higher up
            slider.frame = CGRect(
                x: view.bounds.midX - sliderWidth / 2,
                y: view.bounds.midY + sliderOffset,
                width: sliderWidth,
                height: 30
            )
        }

        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        view?.addSubview(slider)
        volumeSlider = slider
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "SoundEffectsVolume")
        updateVolumeLabel()
    }
    
    private func updateVolumeLabel() {
        let volume = Int((volumeSlider?.value ?? 0) * 100)
        volumeLabel.text = "\(volume)%"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        if nodesAtLocation.contains(where: { $0.name == "resetButton" }) {
            // Clear the high scores
            UserDefaults.standard.removeObject(forKey: "HighScores")
            UserDefaults.standard.synchronize()
            
            // Clear the LeaderboardManager
            LeaderboardManager.shared.clearLeaderboard()
            
            // Show feedback
            let feedback = SKLabelNode(fontNamed: "Helvetica")
            feedback.text = "Scoreboard Cleared!"
            feedback.fontSize = GameConfig.adaptiveFontSize(20)
            feedback.fontColor = .green
            feedback.position = CGPoint(x: frame.midX, y: frame.midY - 150)
            feedback.alpha = 0
            addChild(feedback)
            
            // Animate feedback
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let wait = SKAction.wait(forDuration: 1.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
            feedback.run(sequence)
            
        } else if nodesAtLocation.contains(where: { $0.name == "backButton" }) {
            volumeSlider?.removeFromSuperview()
            let menuScene = MainMenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            view?.presentScene(menuScene, transition: SKTransition.fade(withDuration: 0.3))
        } else if nodesAtLocation.contains(where: { $0.name == "scoreboardButton" }) {
            volumeSlider?.removeFromSuperview()
            let highScoresScene = HighScoresScene(size: self.size)
            highScoresScene.scaleMode = .aspectFill
            view?.presentScene(highScoresScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }
    
    override func willMove(from view: SKView) {
        volumeSlider?.removeFromSuperview()
    }
}
