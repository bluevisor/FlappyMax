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
        
        // High Scores List - Two columns
        let leaderboard = leaderboardManager.getLeaderboard()
        let entriesPerColumn = 5
        let rowSpacing = ySpacing * 0.5
        
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
            scoresNode.position = CGPoint(x: 0, y: ySpacing * 1)
            
            for (index, score) in leaderboard.prefix(10).enumerated() {
                let column = index / entriesPerColumn
                let row = index % entriesPerColumn
                let columnWidth = xSpacing * 2  // Relative column width
                let xOffset = column == 0 ? -columnWidth : columnWidth
                let yPos = -rowSpacing * CGFloat(row)
                
                // Score entry
                let entryNode = SKNode()
                
                // Rank
                let rankLabel = SKLabelNode(fontNamed: "Helvetica")
                rankLabel.text = "\(index + 1)."
                rankLabel.fontSize = GameConfig.adaptiveFontSize(16)
                rankLabel.fontColor = .white
                rankLabel.horizontalAlignmentMode = .right
                rankLabel.position = CGPoint(x: -xSpacing * 2, y: 0)
                entryNode.addChild(rankLabel)
                
                // Name (truncate if too long)
                let nameLabel = SKLabelNode(fontNamed: "Helvetica")
                let name = score.name ?? "Unknown"
                nameLabel.text = name.count > 10 ? String(name.prefix(10)) + "..." : name
                nameLabel.fontSize = GameConfig.adaptiveFontSize(16)
                nameLabel.fontColor = .white
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.position = CGPoint(x: -xSpacing * 1.9, y: 0)
                entryNode.addChild(nameLabel)
                
                // Score
                let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
                scoreLabel.text = "\(score.mainScore)"
                scoreLabel.fontSize = GameConfig.adaptiveFontSize(16)
                scoreLabel.fontColor = .white
                scoreLabel.horizontalAlignmentMode = .right
                scoreLabel.position = CGPoint(x: xSpacing, y: 0)
                entryNode.addChild(scoreLabel)
                
                entryNode.position = CGPoint(x: xOffset, y: yPos)
                scoresNode.addChild(entryNode)
            }
            
            contentNode.addChild(scoresNode)
        }
        
        // Back button
        let backButton = SKLabelNode(fontNamed: "Helvetica")
        backButton.text = "Back"
        backButton.fontSize = GameConfig.adaptiveFontSize(24)
        backButton.fontColor = .white
        backButton.name = "BackButton"
        backButton.position = CGPoint(x: 0, y: -ySpacing * 3)
        contentNode.addChild(backButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if touchedNodes.contains(where: { $0.name == "BackButton" }) {
            let settingsScene = SettingsScene(size: self.size)
            settingsScene.scaleMode = .aspectFill
            view?.presentScene(settingsScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }
}
