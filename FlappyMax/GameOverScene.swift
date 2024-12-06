//
//  GameOverScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import Foundation

class GameOverScene: SKScene {
    var currentScore: ScoreEntry!
    private let leaderboardManager = LeaderboardManager.shared
    
    override func didMove(to view: SKView) {
        // Black background
        backgroundColor = .black
        
        // Add faded game title
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1 // Faded appearance
        titleNode.setScale(GameConfig.Scales.titleFaded)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1 // Behind other elements
        addChild(titleNode)
        
        let contentNode = SKNode()
        
        // Game Over Title
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = GameConfig.adaptiveFontSize(48)
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: 0, y: GameConfig.scaled(60))
        contentNode.addChild(gameOverLabel)
        
        // Create a score container node
        let scoreContainer = SKNode()
        
        // Score Label
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(currentScore.mainScore)"
        scoreLabel.fontSize = GameConfig.adaptiveFontSize(24)
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: -GameConfig.scaled(10), y: 0)
        scoreContainer.addChild(scoreLabel)
        
        // Coin Counter
        let coinTexture = SKTexture(imageNamed: "coin_13.png")
        coinTexture.filteringMode = .nearest
        let coinSprite = SKSpriteNode(texture: coinTexture)
        let coinSize = GameConfig.adaptiveSize(
            for: coinTexture,
            baseScale: GameConfig.Scales.highScoreCoin,
            spriteType: .coin
        )
        coinSprite.size = coinSize
        
        let coinLabel = SKLabelNode(fontNamed: "Helvetica")
        coinLabel.text = "\(currentScore.coins)"
        coinLabel.fontSize = GameConfig.adaptiveFontSize(24)
        coinLabel.fontColor = .white
        coinLabel.horizontalAlignmentMode = .left
        
        let coinCounter = SKNode()
        coinSprite.position = CGPoint(x: GameConfig.scaled(20), y: coinSize.height/4 + GameConfig.scaled(4))
        coinLabel.position = CGPoint(x: GameConfig.scaled(10) + coinSize.width + GameConfig.scaled(5), y: 0)
        
        coinCounter.addChild(coinSprite)
        coinCounter.addChild(coinLabel)
        scoreContainer.addChild(coinCounter)
        
        scoreContainer.position = CGPoint(x: 0, y: GameConfig.scaled(20))
        contentNode.addChild(scoreContainer)
        
        // High Scores Title
        let highScoresTitle = SKLabelNode(fontNamed: "Helvetica-Bold")
        highScoresTitle.text = "High Scores"
        highScoresTitle.fontSize = GameConfig.adaptiveFontSize(28)
        highScoresTitle.fontColor = .white
        highScoresTitle.position = CGPoint(x: 0, y: GameConfig.scaled(-20))
        contentNode.addChild(highScoresTitle)
        
        // High Scores List - Two columns
        let leaderboard = leaderboardManager.getLeaderboard()
        let entriesPerColumn = 5
        
        for (index, score) in leaderboard.prefix(10).enumerated() {
            let column = index / entriesPerColumn
            let row = index % entriesPerColumn
            let xOffset = column == 0 ? -GameConfig.scaled(140) : GameConfig.scaled(140)
            let yPos = GameConfig.scaled(-50 - CGFloat(row * 25))
            
            // Score entry
            let entryNode = SKNode()
            
            // Rank
            let rankLabel = SKLabelNode(fontNamed: "Helvetica")
            rankLabel.text = "\(index + 1)."
            rankLabel.fontSize = GameConfig.adaptiveFontSize(16)
            rankLabel.fontColor = .white
            rankLabel.horizontalAlignmentMode = .right
            rankLabel.position = CGPoint(x: -GameConfig.scaled(80), y: 0)
            entryNode.addChild(rankLabel)
            
            // Name (truncate if too long)
            let nameLabel = SKLabelNode(fontNamed: "Helvetica")
            let name = score.name ?? "Unknown"
            nameLabel.text = name.count > 10 ? String(name.prefix(10)) + "..." : name
            nameLabel.fontSize = GameConfig.adaptiveFontSize(16)
            nameLabel.fontColor = .white
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -GameConfig.scaled(70), y: 0)
            entryNode.addChild(nameLabel)
            
            // Score with coins
            let scoreText = SKLabelNode(fontNamed: "Helvetica")
            scoreText.text = "\(score.mainScore) (\(score.coins)🪙)"
            scoreText.fontSize = GameConfig.adaptiveFontSize(16)
            scoreText.fontColor = .white
            scoreText.horizontalAlignmentMode = .right
            scoreText.position = CGPoint(x: GameConfig.scaled(120), y: 0)
            entryNode.addChild(scoreText)
            
            entryNode.position = CGPoint(x: xOffset, y: yPos)
            contentNode.addChild(entryNode)
        }
        
        // Center the entire content node
        contentNode.position = CGPoint(x: frame.midX, y: frame.height * 0.65)
        addChild(contentNode)
        
        // Add buttons at the bottom of the screen
        let buttonsContainer = SKNode()
        buttonsContainer.position = CGPoint(x: frame.midX, y: frame.height * 0.12)
        
        // Restart Button
        let restartButton = SKLabelNode(fontNamed: "Helvetica")
        restartButton.text = "Restart Game"
        restartButton.fontSize = GameConfig.adaptiveFontSize(24)
        restartButton.fontColor = .white
        restartButton.position = CGPoint(x: -GameConfig.scaled(120), y: 0)
        restartButton.name = "restartButton"
        
        // Main Menu Button
        let menuButton = SKLabelNode(fontNamed: "Helvetica")
        menuButton.text = "Main Menu"
        menuButton.fontSize = GameConfig.adaptiveFontSize(24)
        menuButton.fontColor = .white
        menuButton.position = CGPoint(x: GameConfig.scaled(120), y: 0)
        menuButton.name = "menuButton"
        
        buttonsContainer.addChild(restartButton)
        buttonsContainer.addChild(menuButton)
        addChild(buttonsContainer)
        
        // Update leaderboard with current score
        leaderboardManager.updateLeaderboard(with: currentScore)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            switch node.name {
            case "restartButton":
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .aspectFill
                view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 0.5))
                return
                
            case "menuButton":
                let menuScene = MainMenuScene(size: self.size)
                menuScene.scaleMode = .aspectFill
                view?.presentScene(menuScene, transition: SKTransition.fade(withDuration: 0.5))
                return
                
            default:
                continue
            }
        }
    }
}
