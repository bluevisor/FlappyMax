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
        let topMargin = GameConfig.SafeMargin.top
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
    
    func toggleGravity() {
        guard let physicsWorld = physicsWorld else { return }
        isGravityEnabled.toggle()
        physicsWorld.gravity = isGravityEnabled ? CGVector(dx: 0, dy: GameConfig.Physics.gravity) : .zero
    }
}
