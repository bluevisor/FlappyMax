//
//  GameOverScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Game over screen implementation for FlappyMax
 
 Responsibilities:
 - Final score display and animation
 - High score validation and processing
 - Game restart management
 - Scene transition handling
 - Score submission flow
 
 Features:
 - Animated score presentation
 - High score detection system
 - Transition protection mechanism
 - Score submission validation
 - Game over reason display
 - Restart game option
 - Return to menu option
 - Score persistence handling
 - Smooth scene transitions
 - Device-specific layouts
 - Score animation effects
 - Error state handling
 - User feedback display
 - Leaderboard integration
 */

import SpriteKit
import Foundation

class GameOverScene: SKScene {
    // MARK: - Properties
    private let leaderboardManager = LeaderboardManager.shared
    var mainScore: Int = 0
    var coinScore: Int = 0
    var gameOverReason: GameOverReason = .outOfEnergy
    private var skipHighScoreCheck: Bool = false
    
    // MARK: - Initialization
    init(size: CGSize, skipHighScoreCheck: Bool = false) {
        self.skipHighScoreCheck = skipHighScoreCheck
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        
        // Check for high score if not skipped and score is not 0
        if !skipHighScoreCheck && mainScore > 0 {
            let scores = leaderboardManager.getLeaderboard()
            let isHighScore = scores.count < 10 || mainScore > (scores.last?.mainScore ?? 0)
            
            if isHighScore {
                // Transition to name entry scene
                let nameEntryScene = NameEntryScene(size: self.size, score: mainScore, coins: coinScore)
                nameEntryScene.scaleMode = .aspectFill
                view.presentScene(nameEntryScene, transition: SKTransition.fade(withDuration: 0.3))
                return
            }
        }
        
        setupUI()
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        backgroundColor = .black
        
        // Add faded game title
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1 // Faded appearance
        titleNode.setScale(GameConfig.Scales.titleFaded)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1 // Behind other elements
        addChild(titleNode)
    }
    
    private func setupUI() {
        let contentNode = SKNode()
        addChild(contentNode)
        
        // Calculate vertical spacing based on screen height
        let screenHeight = frame.height
        let spacing = screenHeight * 0.1
        
        // Game Over Label
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = gameOverReason == .collision ? "CRASHED!" : "OUT OF ENERGY!"
        gameOverLabel.fontSize = GameConfig.adaptiveFontSize(48)
        gameOverLabel.position = CGPoint(x: 0, y: spacing * 3)
        contentNode.addChild(gameOverLabel)
        
        // Score Label
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(mainScore)"
        scoreLabel.fontSize = GameConfig.adaptiveFontSize(32)
        scoreLabel.position = CGPoint(x: 0, y: spacing * 1.5)
        contentNode.addChild(scoreLabel)
        
        // Coins Label
        let coinsLabel = SKLabelNode(fontNamed: "Helvetica")
        coinsLabel.text = "Coins: \(coinScore)"
        coinsLabel.fontSize = GameConfig.adaptiveFontSize(32)
        coinsLabel.position = CGPoint(x: 0, y: spacing * 0.5)
        contentNode.addChild(coinsLabel)
        
        // Restart Button
        let restartButton = SKLabelNode(fontNamed: "Helvetica")
        restartButton.text = "Restart"
        restartButton.fontSize = GameConfig.adaptiveFontSize(32)
        restartButton.position = CGPoint(x: 0, y: -spacing * 1.5)
        restartButton.name = "restartButton"
        contentNode.addChild(restartButton)
        
        // Menu Button
        let menuButton = SKLabelNode(fontNamed: "Helvetica")
        menuButton.text = "Menu"
        menuButton.fontSize = GameConfig.adaptiveFontSize(32)
        menuButton.position = CGPoint(x: 0, y: -spacing * 2.5)
        menuButton.name = "menuButton"
        contentNode.addChild(menuButton)
        
        // Center the content node
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if touchedNodes.contains(where: { $0.name == "restartButton" }) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.3))
        } else if touchedNodes.contains(where: { $0.name == "menuButton" }) {
            let menuScene = MainMenuScene(size: self.size)
            menuScene.scaleMode = .aspectFill
            view?.presentScene(menuScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }
}