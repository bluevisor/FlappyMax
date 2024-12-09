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
        let screenWidth = frame.width
        let ySpacing = screenHeight * 0.1
        let xSpacing = screenWidth * 0.1
        
        // Add faded game title
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1 // Faded appearance
        titleNode.setScale(GameConfig.Scales.titleFaded)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1 // Behind other elements
        addChild(titleNode)
        
        let contentNode = SKNode()
        contentNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(contentNode)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "HIGH SCORES"
        titleLabel.fontSize = GameConfig.adaptiveFontSize(48)
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: ySpacing * 3)
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
            scoresNode.position = CGPoint(x: 0, y: ySpacing * 1.5)
            
            for (index, score) in leaderboard.prefix(5).enumerated() {
                let yPos = -ySpacing * CGFloat(index) * 0.5
                
                // Rank and name
                let rankNameLabel = SKLabelNode(fontNamed: "Helvetica")
                let name = score.name ?? "Unknown"
                rankNameLabel.text = "\(index + 1). \(name)"
                rankNameLabel.fontSize = GameConfig.adaptiveFontSize(20)
                rankNameLabel.horizontalAlignmentMode = .left
                rankNameLabel.position = CGPoint(x: -xSpacing * 2.4, y: yPos)
                scoresNode.addChild(rankNameLabel)
                
                // Main score
                let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
                scoreLabel.text = "\(score.mainScore)  |"
                scoreLabel.fontSize = GameConfig.adaptiveFontSize(20)
                scoreLabel.horizontalAlignmentMode = .right
                scoreLabel.position = CGPoint(x: xSpacing * 1.5, y: yPos)
                scoresNode.addChild(scoreLabel)
                
                // Coin score with icon
                let coinLabel = SKLabelNode(fontNamed: "Helvetica")
                coinLabel.text = "\(score.coinScore)"
                coinLabel.fontSize = GameConfig.adaptiveFontSize(20)
                coinLabel.horizontalAlignmentMode = .right
                coinLabel.position = CGPoint(x: xSpacing * 2, y: yPos)
                scoresNode.addChild(coinLabel)
                
                // Coin icon
                let coinAtlas = SKTextureAtlas(named: "coin")
                let coinTexture = coinAtlas.textureNamed("coin_12")
                let coinIcon = SKSpriteNode(texture: coinTexture)
                coinIcon.size = CGSize(width: GameConfig.adaptiveFontSize(18), height: GameConfig.adaptiveFontSize(18))
                coinIcon.position = CGPoint(x: xSpacing * 2.2, y: yPos + GameConfig.adaptiveFontSize(18) * 0.4)
                scoresNode.addChild(coinIcon)
            }
            
            contentNode.addChild(scoresNode)
        }
        
        // Back button at bottom
        let backButton = SKLabelNode(fontNamed: "Helvetica")
        backButton.text = "Back"
        backButton.fontSize = GameConfig.adaptiveFontSize(24)
        backButton.position = CGPoint(x: 0, y: -ySpacing * 3)
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
        }
    }
}
