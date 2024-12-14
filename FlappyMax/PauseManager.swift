import SpriteKit

class PauseManager {
    private weak var scene: SKScene?
    private weak var physicsWorld: SKPhysicsWorld?
    private var isGravityEnabled: Bool = true
    private var lastUpdateTime: TimeInterval = 0
    
    init(scene: SKScene, physicsWorld: SKPhysicsWorld) {
        self.scene = scene
        self.physicsWorld = physicsWorld
    }
    
    func createPauseUI() -> SKNode {
        guard let scene = scene else { return SKNode() }
        
        // Create a container node for all pause UI elements
        let pauseContainer = SKNode()
        pauseContainer.name = "pauseContainer"
        pauseContainer.zPosition = 1000
        
        // Calculate layout metrics
        let screenHeight = scene.frame.height
        let bottomMargin = GameConfig.SafeMargin.bottom
        let vSpacing = screenHeight * 0.05
        
        // Paused Label (at the top)
        let pausedLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        pausedLabel.text = "Paused"
        pausedLabel.fontSize = DeviceType.current == .iPhone ? 40 : 60
        pausedLabel.fontColor = .white
        pausedLabel.name = "pausedLabel"
        pausedLabel.position = CGPoint(
            x: scene.frame.midX,
            y: scene.frame.maxY * (DeviceType.current == .iPhone ? 0.7 : 0.8)
        )
        pauseContainer.addChild(pausedLabel)
        
        // Calculate vertical spacing for middle content
        let middleY = scene.frame.midY
        
        // Define score multiplier labels in a fixed order
        let scoreMultiplierLabels = ["100": "🍔", "50": "🍕", "25": "🍣", "10": "🍟"]

        // Specify the fixed order for the keys
        let fixedOrder = ["10", "25", "50", "100"]

        // Map the labels into the fixed order
        let orderedLabels = fixedOrder.map { key -> String in
            if let symbol = scoreMultiplierLabels[key] {
                return "\(symbol) = \(key)"
            } else {
                return ""
            }
        }.filter { !$0.isEmpty } // Remove any empty entries (in case of missing keys)

        // Combine the labels into a single string
        let label = SKLabelNode(fontNamed: "Helvetica")
        label.text = orderedLabels.joined(separator: "    ")
        label.fontSize = DeviceType.current == .iPhone ? 32 : 48
        label.fontColor = .white
        label.position = CGPoint(x: scene.frame.midX, y: middleY - vSpacing)
        pauseContainer.addChild(label)


        #if DEBUG
        // Debug Info (in the middle)
        let debugInfo = SKNode()
        debugInfo.position = CGPoint(x: scene.frame.midX, y: middleY)
        
        // Add debug info to pause container
        pauseContainer.addChild(debugInfo)
        #endif
        
        // Restart Button (bottom)
        let restartButton = SKLabelNode(fontNamed: "Helvetica")
        restartButton.text = "Restart"
        restartButton.fontSize = DeviceType.current == .iPhone ? 30 : 40
        restartButton.fontColor = .yellow
        restartButton.name = "restartButton"
        restartButton.position = CGPoint(
            x: scene.frame.midX,
            y: bottomMargin + scene.frame.maxY * (DeviceType.current == .iPhone ? 0.05 : 0.1) + restartButton.frame.height + vSpacing
        )
        // pauseContainer.addChild(restartButton)
        
        // Resume Button (bottom)
        let resumeButton = SKLabelNode(fontNamed: "Helvetica")
        resumeButton.text = "Resume"
        resumeButton.fontSize = DeviceType.current == .iPhone ? 30 : 40
        resumeButton.fontColor = .green
        resumeButton.name = "resumeButton"
        resumeButton.position = CGPoint(
            x: scene.frame.midX,
            y: bottomMargin + scene.frame.maxY * (DeviceType.current == .iPhone ? 0.05 : 0.1)
        )
        pauseContainer.addChild(resumeButton)
        
        return pauseContainer
    }
    
    func togglePause(isGamePaused: Bool, updateHeroCollision: () -> Void) {
        guard let scene = scene, let physicsWorld = physicsWorld else { return }
        
        if isGamePaused {
            // Pause the game by setting speeds to 0
            physicsWorld.speed = 0
            scene.speed = 0
            
            // Create and add pause UI
            let pauseUI = createPauseUI()
            scene.addChild(pauseUI)
        } else {
            // Remove pause UI first
            if let container = scene.childNode(withName: "pauseContainer") {
                container.removeFromParent()
            }
            
            // Reset the last update time to prevent large delta on resume
            lastUpdateTime = 0
            
            // Resume the game by restoring speeds to 1
            physicsWorld.speed = 1
            scene.speed = 1
            
            // Update physics state based on current toggle settings
            updateHeroCollision()
            physicsWorld.gravity = isGravityEnabled ? CGVector(dx: 0, dy: GameConfig.Physics.gravity) : .zero
        }
    }
}


    // private func createPauseUI() {
    //     // Create a container node for all pause UI elements
    //     let pauseContainer = SKNode()
    //     pauseContainer.name = "pauseContainer"
    //     pauseContainer.zPosition = 1000
        
    //     // Paused Label 
    //     let pausedLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
    //     pausedLabel.text = "Paused"
    //     pausedLabel.position = CGPoint(x: frame.midX, y: frame.maxY * 0.75)
    //     pausedLabel.fontSize = 40
    //     pausedLabel.fontColor = .white
    //     pausedLabel.name = "pausedLabel"
    //     pauseContainer.addChild(pausedLabel)
        
    //     // Resume Button
    //     let resumeButton = SKLabelNode(fontNamed: "Helvetica")
    //     resumeButton.text = "Resume"
    //     resumeButton.position = CGPoint(x: frame.midX, y: frame.midY - 300)
    //     resumeButton.fontSize = 30
    //     resumeButton.fontColor = .green
    //     resumeButton.name = "resumeButton"
    //     pauseContainer.addChild(resumeButton)
        
    //     // Restart Button
    //     let restartButton = SKLabelNode(fontNamed: "Helvetica")
    //     restartButton.text = "Restart"
    //     restartButton.position = CGPoint(x: frame.midX, y: frame.midY - 250)
    //     restartButton.fontSize = 30
    //     restartButton.fontColor = .yellow
    //     restartButton.name = "restartButton"
    //     pauseContainer.addChild(restartButton)
        
    //     // Gravity Toggle
    //     let gravityToggle = SKLabelNode(text: "Toggle Gravity: \(isGravityEnabled ? "ON" : "OFF")")
    //     gravityToggle.position = CGPoint(x: frame.midX, y: frame.midY - 100)
    //     gravityToggle.name = "gravityToggle"
    //     pauseContainer.addChild(gravityToggle)
        
    //     // Hero Collision Toggle
    //     let heroCollisionToggle = SKLabelNode(text: "Toggle Hero Collision: \(isHeroCollisionEnabled ? "ON" : "OFF")")
    //     heroCollisionToggle.position = CGPoint(x: frame.midX, y: frame.midY - 150)
    //     heroCollisionToggle.name = "heroCollisionToggle"
    //     pauseContainer.addChild(heroCollisionToggle)
        
    //     #if DEBUG
    //     // Debug Information
    //     let debugInfo = SKNode()
    //     debugInfo.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        
    //     // Hero Position
    //     let heroYPos = SKLabelNode(text: "Hero Y: \(String(format: "%.2f", hero.position.y))")
    //     heroYPos.fontSize = 20
    //     heroYPos.position = CGPoint(x: 0, y: 0)
    //     debugInfo.addChild(heroYPos)
        
    //     // Pole Pool Info
    //     let polePoolCount = Pole.shared.polePool.count
    //     let activePoleCount = poleNodes.count
    //     let poleInfo = SKLabelNode(text: "Poles - Pool: \(polePoolCount), Active: \(activePoleCount)")
    //     poleInfo.fontSize = 20
    //     poleInfo.position = CGPoint(x: 0, y: -30)
    //     debugInfo.addChild(poleInfo)

    //     let poleCount = SKLabelNode(text: "Pole Count: \(poleSetCount)")
    //     poleCount.fontSize = 20
    //     poleCount.position = CGPoint(x: 0, y: -60)
    //     debugInfo.addChild(poleCount)

    //     // Collectible Pool Info
    //     let coinPoolCount = Collectable.shared.coinPool.count
    //     let activeCoinCount = Collectable.shared.activeCoins.count
    //     let burgerPoolCount = Collectable.shared.burgerPool.count
    //     let activeBurgerCount = Collectable.shared.activeBurgers.count
        
    //     let coinInfo = SKLabelNode(text: "Coins - Pool: \(coinPoolCount), Active: \(activeCoinCount)")
    //     coinInfo.fontSize = 20
    //     coinInfo.position = CGPoint(x: 0, y: -90)
    //     debugInfo.addChild(coinInfo)
        
    //     let burgerInfo = SKLabelNode(text: "Burgers - Pool: \(burgerPoolCount), Active: \(activeBurgerCount)")
    //     burgerInfo.fontSize = 20
    //     burgerInfo.position = CGPoint(x: 0, y: -120)
    //     debugInfo.addChild(burgerInfo)
        
    //     pauseContainer.addChild(debugInfo)
    //     #endif
        
    //     addChild(pauseContainer)
    // }