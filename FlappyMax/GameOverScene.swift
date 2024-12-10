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

class GameOverScene: BaseGameScene {
    // MARK: - Properties
    private let leaderboardManager = LeaderboardManager.shared
    var mainScore: Int = 0
    var coinScore: Int = 0
    var gameOverReason: GameOverReason = .collision
    var skipHighScoreCheck: Bool = false
    
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
            let isHighScore = leaderboardManager.scoreQualifiesForLeaderboard(mainScore)
            
            if isHighScore {
                // Transition to name entry scene
                let nameEntryScene = NameEntryScene(size: self.size, score: mainScore, coins: coinScore, gameOverReason: gameOverReason)
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
        gameOverLabel.text = "GAME OVER!"
        gameOverLabel.fontSize = GameConfig.adaptiveFontSize(48)
        gameOverLabel.position = CGPoint(x: 0, y: spacing * 3.3)
        contentNode.addChild(gameOverLabel)
        
        // Game Over Reason
        let reasonLabel = SKLabelNode(fontNamed: "Helvetica")
        reasonLabel.text = gameOverReason == .collision ? "Crashed!" : "Out of Energy!"
        reasonLabel.fontSize = GameConfig.adaptiveFontSize(20)
        reasonLabel.position = CGPoint(x: 0, y: spacing * 2.6)
        contentNode.addChild(reasonLabel)
        
        // Score and Coins on same line
        let statsNode = SKNode()
        
        // Score Label
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(mainScore)"
        scoreLabel.fontSize = GameConfig.adaptiveFontSize(20)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: -spacing * 0.2, y: spacing * 2.0)
        statsNode.addChild(scoreLabel)
        
        // Coins Label
        let coinsLabel = SKLabelNode(fontNamed: "Helvetica")
        coinsLabel.text = "Coins: \(coinScore)"
        coinsLabel.fontSize = GameConfig.adaptiveFontSize(20)
        coinsLabel.horizontalAlignmentMode = .left
        coinsLabel.position = CGPoint(x: spacing * 0.2, y: spacing * 2.0)
        statsNode.addChild(coinsLabel)
        
        contentNode.addChild(statsNode)
        
        // High Scores
        let leaderboard = leaderboardManager.getLeaderboard()
        if !leaderboard.isEmpty {
            let scoresNode = SKNode()
            
            // High Scores Title
            let highScoresTitle = SKLabelNode(fontNamed: "Helvetica")
            highScoresTitle.text = "HIGH SCORES"
            highScoresTitle.fontSize = GameConfig.adaptiveFontSize(24)
            highScoresTitle.position = CGPoint(x: 0, y: spacing * 1.3)
            scoresNode.addChild(highScoresTitle)
            
            // Display top 5 scores
            let topScores = Array(leaderboard.prefix(5))
            for (index, score) in topScores.enumerated() {
                let name = score.name ?? "Anonymous"
                let yPos = spacing * (0.2 - CGFloat(index) * 0.5)
                
                let scoreEntry = SKNode()
                
                // Rank
                let rankLabel = SKLabelNode(fontNamed: "Helvetica")
                rankLabel.text = "\(index + 1)."
                rankLabel.fontSize = GameConfig.adaptiveFontSize(18)
                rankLabel.horizontalAlignmentMode = .right
                rankLabel.position = CGPoint(x: -spacing * 3.0, y: yPos)
                scoreEntry.addChild(rankLabel)
                
                // Name
                let nameLabel = SKLabelNode(fontNamed: "Helvetica")
                nameLabel.text = name.count > 10 ? String(name.prefix(10)) + "..." : name
                nameLabel.fontSize = GameConfig.adaptiveFontSize(18)
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.position = CGPoint(x: -spacing * 2.8, y: yPos)
                scoreEntry.addChild(nameLabel)
                
                // Score with Coin Icon
                let scoreContainer = SKNode()
                
                let scoreValueLabel = SKLabelNode(fontNamed: "Helvetica")
                scoreValueLabel.text = "\(score.mainScore)  |"
                scoreValueLabel.fontSize = GameConfig.adaptiveFontSize(18)
                scoreValueLabel.horizontalAlignmentMode = .right
                scoreValueLabel.position = CGPoint(x: -spacing * 0.5, y: 0)
                scoreContainer.addChild(scoreValueLabel)
                
                let coinScoreLabel = SKLabelNode(fontNamed: "Helvetica")
                coinScoreLabel.text = "\(score.coinScore)"
                coinScoreLabel.fontSize = GameConfig.adaptiveFontSize(18)
                coinScoreLabel.horizontalAlignmentMode = .right
                coinScoreLabel.position = CGPoint(x: spacing * 0.4, y: 0)
                scoreContainer.addChild(coinScoreLabel)
                
                let coinAtlas = SKTextureAtlas(named: "coin")
                let coinTexture = coinAtlas.textureNamed("coin_12")
                let coinIcon = SKSpriteNode(texture: coinTexture)
                coinIcon.size = CGSize(width: GameConfig.adaptiveFontSize(18), height: GameConfig.adaptiveFontSize(18))
                coinIcon.position = CGPoint(x: spacing * 0.7, y: GameConfig.adaptiveFontSize(18) * 0.3)
                scoreContainer.addChild(coinIcon)
                
                scoreContainer.position = CGPoint(x: spacing * 3.0, y: yPos)
                scoreEntry.addChild(scoreContainer)
                
                scoresNode.addChild(scoreEntry)
            }
            
            contentNode.addChild(scoresNode)
        }
        
        // Restart Button
        let restartButton = SKLabelNode(fontNamed: "Helvetica")
        restartButton.text = "Restart"
        restartButton.fontSize = GameConfig.adaptiveFontSize(24)
        restartButton.position = CGPoint(x: 0, y: -spacing * 3)
        restartButton.name = "restartButton"
        contentNode.addChild(restartButton)
        
        // Menu Button
        let menuButton = SKLabelNode(fontNamed: "Helvetica")
        menuButton.text = "Main Menu"
        menuButton.fontSize = GameConfig.adaptiveFontSize(24)
        menuButton.position = CGPoint(x: 0, y: -spacing * 4)
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