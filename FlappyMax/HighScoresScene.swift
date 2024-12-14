import SpriteKit

class HighScoresScene: SKScene {
    private let leaderboardManager = LeaderboardManager.shared
    
    override func didMove(to view: SKView) {
        setupUI()
    }
    
    private func setupUI() {
        // Black background
        backgroundColor = .black
        
        // Calculate vertical spacing based on screen height
        let screenHeight = frame.height
        let spacing = screenHeight * 0.1
        
        // Add faded game title
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1
        titleNode.setScale(GameConfig.Scales.titleFaded)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1
        addChild(titleNode)
        
        let contentNode = SKNode()
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(contentNode)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "HIGH SCORES"
        titleLabel.fontSize = GameConfig.adaptiveFontSize(42)
        titleLabel.position = CGPoint(x: 0, y: spacing * 2.5)
        contentNode.addChild(titleLabel)
        
        // High Scores List
        let leaderboard = leaderboardManager.getLeaderboard()
        
        if leaderboard.isEmpty {
            // Show "No Data" message
            let noDataLabel = SKLabelNode(fontNamed: "Helvetica")
            noDataLabel.text = "No Data"
            noDataLabel.fontSize = GameConfig.adaptiveFontSize(28)
            noDataLabel.fontColor = .gray
            noDataLabel.position = CGPoint(x: 0, y: 0)
            contentNode.addChild(noDataLabel)
        } else {
            let scoresNode = SKNode()
            
            for (index, score) in leaderboard.prefix(5).enumerated() {
                let name = score.name ?? "Anonymous"
                let yPos = spacing * (0.2 - CGFloat(index) * 0.5)
                
                let scoreEntry = SKNode()
                
                // Rank
                let rankLabel = SKLabelNode(fontNamed: "Helvetica")
                rankLabel.text = "\(index + 1)."
                rankLabel.fontSize = GameConfig.adaptiveFontSize(18)
                rankLabel.horizontalAlignmentMode = .right
                rankLabel.position = CGPoint(x: -spacing * 3.6, y: yPos)
                scoreEntry.addChild(rankLabel)
                
                // Name
                let nameLabel = SKLabelNode(fontNamed: "Helvetica")
                nameLabel.text = name.count > 10 ? String(name.prefix(10)) + "..." : name
                nameLabel.fontSize = GameConfig.adaptiveFontSize(18)
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.position = CGPoint(x: -spacing * 3.3, y: yPos)
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
                coinIcon.position = CGPoint(x: spacing * 0.7, y: GameConfig.adaptiveFontSize(18) * 0.35)
                scoreContainer.addChild(coinIcon)
                
                scoreContainer.position = CGPoint(x: spacing * 3.0, y: yPos)
                scoreEntry.addChild(scoreContainer)
                
                scoresNode.addChild(scoreEntry)
            }
            
            contentNode.addChild(scoresNode)
        }
        
        // Back button at bottom
        let backButton = SKLabelNode(fontNamed: "Helvetica")
        backButton.text = "Back"
        backButton.fontSize = GameConfig.adaptiveFontSize(24)
        backButton.position = CGPoint(x: 0, y: -spacing * 3.5)
        backButton.name = "backButton"
        contentNode.addChild(backButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if touchedNodes.contains(where: { $0.name == "backButton" }) {
            let settingsScene = SettingsScene(size: self.size)
            settingsScene.scaleMode = .aspectFill
            view?.presentScene(settingsScene, transition: SKTransition.fade(withDuration: 0.3))
            #if DEBUG
            print("{ Transition } from HighScoresScene to SettingsScene")
            #endif
        }
    }
}
