//
// GameScene.swift
//
// Main game scene that handles the core gameplay mechanics of FlappyMax.
// Features:
// - Hero character control and physics
// - Obstacle generation and recycling
// - Coin and burger collectible system
// - Score tracking and stamina management
// - Collision detection and game over conditions
// - Background parallax scrolling
// - Sound effects management
//

//  GameScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Main gameplay scene for FlappyMax
 
 Responsibilities:
 - Core gameplay loop management
 - Physics simulation and collision handling
 - Player input processing
 - Game state management
 - Score and stamina tracking
 
 Features:
 - Hero character physics and controls
 - Dynamic obstacle generation
 - Collectible management (coins, burgers)
 - Parallax scrolling background
 - Score and stamina UI
 - Sound effect system
 - Collision detection and response
 - Game over condition handling
 - Performance optimization
 - Object pooling and recycling
 - Device-specific adaptations
 - Debug visualization options
 - State persistence
 - Smooth animations
 - Difficulty progression
 */

import SpriteKit
import GameplayKit
import AVFoundation

// MARK: - Physics Categories
struct PhysicsCategory {
    static let hero: UInt32 = 0x1 << 0
    static let pole: UInt32 = 0x1 << 1
    static let coin: UInt32 = 0x1 << 2
    static let burger: UInt32 = 0x1 << 3
    static let scoreZone: UInt32 = 0x1 << 4
    static let floor: UInt32 = 0x1 << 5
}

class GameScene: BaseGameScene, SKPhysicsContactDelegate {
    // MARK: - Labels & Scores
    internal var mainScoreLabel: SKLabelNode!
    internal var coinScoreLabel: SKLabelNode!
    internal var mainScore = 0
    internal var coinScore = 0
    internal var burgerScore = 0

    // MARK: - Game State
    internal var isGameOver = false
    private let leaderboardManager = LeaderboardManager.self
    private var poleCount = 0  // Track number of poles spawned

    // MARK: - Background Configuration
    internal let numberOfBackgrounds = 3
    internal var backgroundSpeed: CGFloat { GameConfig.Physics.gameSpeed * 0.618 }
    internal var backgroundNodes: [SKSpriteNode] = []
    internal var parallaxLayers: [[SKSpriteNode]] = []
    internal let parallaxSpeeds: [CGFloat] = [0.2, 0.4, 0.6] // Different speeds for each layer

    // MARK: - Hero Configuration
    internal var hero: SKSpriteNode!
    internal var stamina: CGFloat = 100.0
    internal let staminaDepletion: CGFloat = 1.0
    internal let staminaReplenishment: CGFloat = 25.0

    // MARK: - Floor Configuration
    internal var floorSpeed: CGFloat { GameConfig.Physics.gameSpeed * 1.2 }  // 20% faster than game speed
    internal var floorNodes: [SKSpriteNode] = []  // Add this line

    // MARK: - Pole & Collectible Configuration
    internal var polePairGap: CGFloat { GameConfig.scaled(GameConfig.Metrics.polePairGap) }
    internal var poleSpacing: CGFloat { GameConfig.scaled(GameConfig.Metrics.poleSpacing) }
    internal let numberOfPolePairs = 3
    internal var polePairs: [SKNode] = []
    
    // Pools and Grids
    var currentIndex: Int = 0
    var heroBaseX: CGFloat = 0
    var baseSpawnX: CGFloat = 0 // where segments start spawning

    // MARK: - Movement Speeds
    internal var objectSpeed: CGFloat { GameConfig.Physics.gameSpeed }

    // MARK: - Obstacles and Physics
    internal var obstacles: [SKSpriteNode] = []
    var gravity: CGFloat { GameConfig.Physics.gravity }
    var flapImpulse: CGFloat { GameConfig.Physics.flapImpulse }

    // Floor Height Computation
    var floorHeight: CGFloat {
        floorNodes.first?.size.height ?? GameConfig.Metrics.floorHeight
    }

    // MARK: - Stamina Bar
    internal var staminaBar: SKSpriteNode!
    internal let maxStamina: CGFloat = 100.0
    internal var currentStamina: CGFloat = 100.0
    internal let staminaDecreaseRate: CGFloat = 2.0  // Points per second
    internal var staminaBarWidth: CGFloat = 200.0
    internal let staminaBarHeight: CGFloat = 20.0
    internal var staminaFill: SKSpriteNode!

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Hide physics bodies
        view.showsPhysics = false
        
        // Log current volume and load sounds
        let currentVolume = UserDefaults.standard.float(forKey: "SFXVolume")
        print("Current game volume: \(currentVolume * 100)%")
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gravity)
        self.physicsWorld.contactDelegate = self

        // Create UI Layer first
        setupLabels()
        setupStaminaBar()

        cleanupScene()
        
        setupBackground()
        setupHero()
        setupFloor()

        // Initialize Pools and spawn initial segments
        setupPools()
        heroBaseX = hero.position.x
        baseSpawnX = frame.width + 50
        
        // Reset current index
        currentIndex = 0
    }

    private func setupLabels() {
        // Main Score Label
        mainScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        mainScoreLabel.text = "0"
        mainScoreLabel.fontSize = GameConfig.adaptiveFontSize(48)
        mainScoreLabel.fontColor = .white
        mainScoreLabel.position = CGPoint(
            x: frame.width / 2,
            y: frame.height - GameConfig.Metrics.topMargin - mainScoreLabel.frame.height / 2
        )
        mainScoreLabel.zPosition = 100
        uiLayer.addChild(mainScoreLabel)

        // Coin counter
        let coinAtlas = SKTextureAtlas(named: "coin")
        let coinTexture = coinAtlas.textureNamed("coin_12")
        coinTexture.filteringMode = .nearest
        let coinSprite = SKSpriteNode(texture: coinTexture)
        
        let coinSize = GameConfig.adaptiveSize(
            for: coinTexture,
            baseScale: GameConfig.Scales.coinIcon,
            spriteType: .coin
        )
        coinSprite.size = coinSize

        coinScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        coinScoreLabel.fontSize = GameConfig.adaptiveFontSize(24)
        coinScoreLabel.fontColor = .white
        coinScoreLabel.text = "0"
        coinScoreLabel.zPosition = 100

        let coinCounterNode = SKNode()
        coinCounterNode.position = CGPoint(x: frame.maxX - GameConfig.scaled(20), y: frame.maxY - GameConfig.scaled(30))
        coinCounterNode.zPosition = 100
        
        coinSprite.position = CGPoint(x: -coinSize.width - GameConfig.scaled(15), y: -1)
        coinCounterNode.addChild(coinSprite)
        
        coinScoreLabel.position = CGPoint(x: 0, y: 0)
        coinScoreLabel.horizontalAlignmentMode = .right
        coinScoreLabel.verticalAlignmentMode = .center
        coinCounterNode.addChild(coinScoreLabel)
        
        addChild(coinCounterNode)
    }

    private func setupStaminaBar() {
        let barWidth = GameConfig.scaled(200)
        let barHeight = GameConfig.scaled(20)
        
        staminaBar = SKSpriteNode(color: .gray, size: CGSize(width: barWidth, height: barHeight))
        staminaBar.anchorPoint = CGPoint(x: 0, y: 0.5)  // Left center anchor
        staminaBar.position = CGPoint(x: frame.minX + GameConfig.scaled(20), y: frame.maxY - GameConfig.scaled(30))
        staminaBar.zPosition = 100
        addChild(staminaBar)
        
        staminaFill = SKSpriteNode(color: .green, size: CGSize(width: barWidth, height: barHeight))
        staminaFill.anchorPoint = CGPoint(x: 0, y: 0.5)  // Left center anchor
        staminaFill.position = CGPoint.zero
        staminaFill.zPosition = 1
        staminaBar.addChild(staminaFill)
    }

    private func setupBackground() {
        // Create three parallax layers
        for layerIndex in 0..<3 {
            var layerNodes: [SKSpriteNode] = []
            let alpha = 1.0 - (CGFloat(layerIndex) * 0.2) // Decreasing opacity for back layers
            
            for i in 0..<numberOfBackgrounds {
                // Create gradient background
                let background = createBackgroundLayer(layerIndex: layerIndex, alpha: alpha)
                background.anchorPoint = CGPoint(x: 0, y: 0)
                background.position = CGPoint(x: CGFloat(i) * self.size.width, y: 0)
                background.zPosition = -10 + CGFloat(layerIndex)
                addChild(background)
                layerNodes.append(background)
            }
            parallaxLayers.append(layerNodes)
        }
    }
    
    private func createBackgroundLayer(layerIndex: Int, alpha: CGFloat) -> SKSpriteNode {
        // Create a gradient layer
        let gradientNode = SKSpriteNode(color: .clear, size: self.size)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: self.size)
        gradientLayer.colors = [
            UIColor(red: 16/255, green: 50/255, blue: 152/255, alpha: alpha).cgColor,  // Dark blue
            UIColor(red: 32/255, green: 83/255, blue: 203/255, alpha: alpha).cgColor  // Light blue
        ]
        gradientLayer.locations = [0.0, 1.0]
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            if let gradientImage = UIGraphicsGetImageFromCurrentImageContext() {
                gradientNode.texture = SKTexture(image: gradientImage)
            }
        }
        UIGraphicsEndImageContext()
        
        // Add visual elements based on layer
        switch layerIndex {
        case 0: // Back layer - distant mountains
            addMountains(to: gradientNode, large: false, color: .init(white: 1.0, alpha: 0.2))
        case 1: // Middle layer - medium mountains
            addMountains(to: gradientNode, large: true, color: .init(white: 1.0, alpha: 0.3))
        case 2: // Front layer - small decorative elements
            addClouds(to: gradientNode)
        default:
            break
        }
        
        return gradientNode
    }
    
    private func addMountains(to node: SKSpriteNode, large: Bool, color: SKColor) {
        let path = UIBezierPath()
        let width = node.size.width
        let height = node.size.height
        let mountainHeight = large ? height * 0.3 : height * 0.2
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        var x: CGFloat = 0
        while x < width {
            let mountainWidth = large ? CGFloat.random(in: 100...200) : CGFloat.random(in: 60...120)
            let peakHeight = CGFloat.random(in: mountainHeight/2...mountainHeight)
            
            path.addLine(to: CGPoint(x: x + mountainWidth/2, y: peakHeight))
            path.addLine(to: CGPoint(x: x + mountainWidth, y: 0))
            
            x += mountainWidth
        }
        
        path.close()
        
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = color
        shape.strokeColor = .clear
        shape.position = CGPoint(x: -width/2, y: height * 0.1)
        node.addChild(shape)
    }
    
    private func addClouds(to node: SKSpriteNode) {
        let numClouds = 5
        for _ in 0..<numClouds {
            let cloudWidth = CGFloat.random(in: 80...220)  // Set cloud width
            let cloudHeight = cloudWidth * 0.6
            
            let cloud = SKShapeNode(rectOf: CGSize(width: cloudWidth, height: cloudHeight), cornerRadius: cloudHeight/2)
            cloud.fillColor = .init(white: 1.0, alpha: 0.3)
            cloud.strokeColor = .clear
            
            let randomX = CGFloat.random(in: -node.size.width/2...node.size.width/2)
            let randomY = CGFloat.random(in: node.size.height * 0.4...node.size.height * 0.8)
            cloud.position = CGPoint(x: randomX, y: randomY)
            
            node.addChild(cloud)
        }
    }

    private func setupHero() {
        let heroTexture = SKTexture(imageNamed: "max")
        heroTexture.filteringMode = .nearest
        
        hero = SKSpriteNode(texture: heroTexture)
        hero.size = GameConfig.Metrics.heroBaseSize
        
        let initialX = frame.width * 0.3
        let initialY = frame.height * 0.6
        hero.position = CGPoint(x: initialX, y: initialY)
        
        print("Hero setup - Initial position: (\(initialX), \(initialY))")
        print("Hero setup - Frame dimensions: \(frame.width) x \(frame.height)")
        print("Hero setup - Hero size: \(hero.size)")
        print("Hero setup - Floor height: \(GameConfig.Metrics.floorHeight)")
        
        hero.zPosition = 3
        hero.name = "hero"
        
        // Create physics body with original texture for better mass distribution
        let heroBody = SKPhysicsBody(texture: heroTexture, size: hero.size)
        heroBody.isDynamic = false  // Start with physics disabled
        heroBody.allowsRotation = false
        heroBody.mass = 0.22  // Lower mass makes the hero more responsive to impulses
        heroBody.categoryBitMask = PhysicsCategory.hero
        heroBody.collisionBitMask = PhysicsCategory.floor | PhysicsCategory.pole
        heroBody.contactTestBitMask = PhysicsCategory.floor | PhysicsCategory.pole | PhysicsCategory.coin | PhysicsCategory.burger
        hero.physicsBody = heroBody
        
        addChild(hero)
        
        // Enable physics after a short delay
        let enablePhysicsAction = SKAction.run { [self] in
            self.hero.physicsBody?.isDynamic = true
            print("Hero physics enabled - Current position: \(String(describing: self.hero.position))")
        }
        
        hero.run(SKAction.sequence([
            SKAction.wait(forDuration: 1/30),
            enablePhysicsAction
        ]))
    }

    private func setupFloor() {
        let floorTexture = SKTexture(imageNamed: "floor")
        floorTexture.filteringMode = .nearest
        
        let floorSize = GameConfig.adaptiveSize(for: floorTexture, spriteType: .floor)
        let numberOfFloors = Int(ceil(frame.width / floorSize.width)) + 2
        
        print("Floor setup - Frame height: \(frame.height), Floor height: \(GameConfig.Metrics.floorHeight)")
        
        floorNodes = []  // Clear any existing floor nodes
        
        for i in 0..<numberOfFloors {
            let floor = SKSpriteNode(texture: floorTexture)
            floor.size = floorSize
            floor.name = "floor"
            floor.anchorPoint = CGPoint(x: 0, y: 0.5)  // Set anchor point to left edge
            
            // Position floors edge to edge
            let floorY = GameConfig.Metrics.floorHeight/2
            floor.position = CGPoint(
                x: floorSize.width * CGFloat(i),
                y: floorY
            )
            print("Floor \(i) position - X: \(floor.position.x), Y: \(floor.position.y)")
            
            floor.zPosition = 2
            
            let floorBody = SKPhysicsBody(rectangleOf: floor.size)
            floorBody.isDynamic = false
            floorBody.categoryBitMask = PhysicsCategory.floor
            floorBody.collisionBitMask = PhysicsCategory.hero
            floorBody.contactTestBitMask = PhysicsCategory.hero
            floor.physicsBody = floorBody
            
            addChild(floor)
            floorNodes.append(floor)  // Add to our array
        }
    }

    // MARK: - Pooling and Spawning
    func setupPools() {
        // Initialize pole pool
        Pole.shared.initializePolePool(count: 6)
        
        // Initialize collectible pool
        Collectable.shared.initializeCollectiblePool(coinCount: 20, burgerCount: 3)

        // Reset pole count for initial spawning
        poleCount = 0
        
        // Spawn initial segments with guaranteed coins in first 2 pole pairs
        var lastX = frame.width
        for i in 0..<3 {
            let xPos = lastX + (i > 0 ? poleSpacing : 0)
            spawnInitialSegment(at: xPos, segmentIndex: i)
            lastX = xPos
        }
    }
    
    private func positionPoleSet(_ poleSet: SKNode, atX xPos: CGFloat) {
        let gap = GameConfig.scaled(GameConfig.Metrics.polePairGap)
        let margin = GameConfig.scaled(GameConfig.Metrics.poleMargin)
        let floorHeight = GameConfig.Metrics.floorHeight
        
        // Calculate min and max Y positions
        let minY = floorHeight + gap/2 + margin
        let maxY = frame.height - gap/2 - margin
        
        // Generate random Y position within safe bounds
        let yPos = CGFloat.random(in: minY...maxY)
        
        poleSet.position = CGPoint(x: xPos, y: yPos)
        poleSet.zPosition = 1
    }

    func spawnInitialSegment(at xPosition: CGFloat, segmentIndex: Int) {
        // Always spawn a pole
        if let poleSet = Pole.shared.getPooledPoleSet() {
            positionPoleSet(poleSet, atX: xPosition)
            addChild(poleSet)
            
            poleCount += 1
            
            // Guaranteed coins in first 2 pole pairs
            if segmentIndex < 2 {
                let collectibleX = xPosition + poleSpacing/2
                let centerY = GameConfig.Metrics.floorHeight + (frame.height - GameConfig.Metrics.floorHeight)/2
                
                // Choose a random coin pattern for guaranteed spawns
                let patterns: [CollectiblePattern] = [.single, .triangle, .square, .cross, .star, .diagonal3, .diagonal5, .circle, .v2, .v3, .v4, .v5, .h2, .h3, .h4, .h5]
                let pattern = patterns[Int.random(in: 0..<patterns.count)]
                spawnCollectiblePattern(at: CGPoint(x: collectibleX, y: centerY), pattern: pattern, isBurger: false)
            }
        }
    }

    func spawnNextSegment(at xPosition: CGFloat) {
        // Always spawn a pole
        if let poleSet = Pole.shared.getPooledPoleSet() {
            positionPoleSet(poleSet, atX: xPosition)
            addChild(poleSet)
            
            poleCount += 1
            let collectibleX = xPosition + poleSpacing/2
            let centerY = GameConfig.Metrics.floorHeight + (frame.height - GameConfig.Metrics.floorHeight)/2
            
            // Every 5th pole spawns a single burger
            if poleCount % 5 == 0 {
                if let burger = Collectable.shared.getPooledBurger() {  // Get specifically a burger
                    burger.position = CGPoint(x: collectibleX, y: centerY)
                    addChild(burger)
                }
            } else {
                // Random pattern for coins only
                let rand = Int.random(in: 0...9)
                if rand < 9 {  // 90% chance to spawn a pattern
                    let patterns: [CollectiblePattern] = [
                        .single, .triangle, .square, .cross, .star,
                        .diagonal3, .diagonal5, .circle,
                        .v2,.v3, .v4, .v5,
                        .h2, .h3, .h4, .h5
                    ]
                    if let randomPattern = patterns.randomElement() {
                        spawnCollectiblePattern(at: CGPoint(x: collectibleX, y: centerY), pattern: randomPattern, isBurger: false)
                    }
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        if lastUpdateTime > 0 {
            let deltaTime = currentTime - lastUpdateTime
            
            // Update stamina
            currentStamina = max(0, currentStamina - (staminaDecreaseRate * CGFloat(deltaTime)))
            updateStaminaBar()
            
            // Game over if stamina reaches 0
            if currentStamina <= 0 {
                gameOver(reason: GameOverReason.outOfEnergy)
            }
            
            let gameSpeed = GameConfig.Physics.gameSpeed
            
            // Move background layers with parallax effect
            for (index, layer) in parallaxLayers.enumerated() {
                let layerSpeed = gameSpeed * parallaxSpeeds[index]
                for background in layer {
                    background.position.x -= layerSpeed
                    
                    // Reset background position when it moves off screen
                    if background.position.x <= -background.size.width {
                        background.position.x += background.size.width * CGFloat(numberOfBackgrounds)
                    }
                }
            }
            
            // Move floor
            moveFloor(speed: floorSpeed)  // Use floorSpeed (1.2x game speed)
            
            // Move poles
            enumerateChildNodes(withName: "poleSet") { node, _ in
                node.position.x -= gameSpeed
                if node.position.x < -self.frame.width/2 {
                    Pole.shared.recyclePoleSet(node)
                }
            }
            
            // Move collectibles (coins and burgers)
            enumerateChildNodes(withName: "coin") { node, _ in
                node.position.x -= gameSpeed
                // Only recycle if the coin is well past the left edge of the screen
                if node.position.x < -self.frame.width {
                    if let coin = node as? SKSpriteNode, !Collectable.shared.isCollected(coin) {
                        print("Recycling uncollected coin at x: \(node.position.x)")
                    }
                    Collectable.shared.recycleCollectible(node as! SKSpriteNode)
                }
            }
            
            enumerateChildNodes(withName: "burger") { node, _ in
                node.position.x -= gameSpeed
                // Only recycle if the burger is well past the left edge of the screen
                if node.position.x < -self.frame.width {
                    if let burger = node as? SKSpriteNode, !Collectable.shared.isCollected(burger) {
                        print("Recycling uncollected burger at x: \(node.position.x)")
                    }
                    Collectable.shared.recycleCollectible(node as! SKSpriteNode)
                }
            }
            
            // Spawn new segment if needed
            if let lastPole = children.filter({ $0.name == "poleSet" }).max(by: { $0.position.x < $1.position.x }) {
                let nextSpawnPosition = lastPole.position.x + poleSpacing
                if nextSpawnPosition < frame.width + poleSpacing {
                    spawnNextSegment(at: nextSpawnPosition)
                }
            }
        }
        lastUpdateTime = currentTime
    }
    
    private func moveFloor(speed: CGFloat) {
        guard !isGameOver else { return }
        for floor in floorNodes {
            floor.position.x -= speed

            // Reset floor position if it moves off-screen
            if floor.position.x <= -floor.size.width {
                floor.position.x += floor.size.width * CGFloat(floorNodes.count)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentStamina > 0 {
            hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: flapImpulse))
            currentStamina = max(currentStamina - staminaDepletion, 0)
            
            playSound("flap")
        }
    }

    private var lastUpdateTime: TimeInterval = 0

    private func updateStaminaBar() {
        let staminaRatio = max(0, currentStamina / maxStamina)
        staminaFill.size.width = staminaBar.size.width * staminaRatio
        staminaFill.color = staminaRatio > 0.2 ? .green : .yellow
    }

    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        
        // Determine which body is the hero and which is the other object
        let heroBody = contact.bodyA.categoryBitMask == PhysicsCategory.hero ? contact.bodyA : contact.bodyB
        let otherBody = heroBody == contact.bodyA ? contact.bodyB : contact.bodyA
        
        print("Collision detected - Hero position: \(hero.position.x), \(hero.position.y), Other body category: \(otherBody.categoryBitMask)")
        
        switch otherBody.categoryBitMask {
        case PhysicsCategory.scoreZone:
            // Only score if we haven't already scored for this zone
            if let scoreZone = otherBody.node,
               scoreZone.userData?["scored"] as? Bool != true {
                mainScore += 1
                mainScoreLabel.text = "\(mainScore)"
                scoreZone.userData = ["scored": true]
                print("Score increased: \(mainScore)")
            }
            
        case PhysicsCategory.coin:
            if let coin = otherBody.node as? SKSpriteNode,
               !Collectable.shared.isCollected(coin) {
                // Immediately disable physics to prevent multiple collisions
                coin.physicsBody = nil
                
                Collectable.shared.markAsCollected(coin)
                coinScore += 1
                coinScoreLabel.text = "\(coinScore)"
                playSound("coin")
                
                // Fade out and move up animation
                let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
                let recycle = SKAction.run {
                    Collectable.shared.recycleCollectible(coin)
                }
                coin.run(SKAction.sequence([SKAction.group([fadeOut, moveUp]), recycle]))
            }
            
        case PhysicsCategory.burger:
            if let burger = otherBody.node as? SKSpriteNode,
               !Collectable.shared.isCollected(burger) {
                // Immediately disable physics to prevent multiple collisions
                burger.physicsBody = nil
                
                Collectable.shared.markAsCollected(burger)
                burgerScore += 1
                currentStamina = maxStamina  // Full stamina restoration
                updateStaminaBar()
                playSound("burger")
                
                // Fade out and move up animation
                let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.3)
                let recycle = SKAction.run {
                    Collectable.shared.recycleCollectible(burger)
                }
                burger.run(SKAction.sequence([SKAction.group([fadeOut, moveUp]), recycle]))
            }
            
        case PhysicsCategory.pole, PhysicsCategory.floor:
            print("Game Over - Collision with \(otherBody.categoryBitMask == PhysicsCategory.pole ? "pole" : "floor") at Y: \(hero.position.y)")
            gameOver(reason: GameOverReason.collision)
            
        default:
            print("Unknown collision with category: \(otherBody.categoryBitMask)")
        }
    }
    
    override func cleanupScene() {
        // Remove and recycle all collectibles
        self.children.forEach { node in
            if let collectible = node as? SKSpriteNode {
                if collectible.name == "coin" || collectible.name == "burger" {
                    Collectable.shared.recycleCollectible(collectible)
                }
            }
        }
        
        // Reset scores and other game state
        mainScore = 0
        coinScore = 0
        currentStamina = maxStamina
        isGameOver = false
        
        // Update UI
        mainScoreLabel.text = "0"
        coinScoreLabel.text = "0"
        updateStaminaBar()
    }
    
    // MARK: - Grid System
    // Grid system constants
    private let gridSpacing: CGFloat = 900.0  // Distance between pole sets
    private let baseHeight: CGFloat = 0.0     // Center height for random variations
    private let heightVariation: CGFloat = 200.0  // Maximum height variation up/down
    private let initialX: CGFloat = 1000.0    // Starting X position for first pole

    private func spawnPoleSet() {
        // Calculate grid-based position
        let poleX = initialX + (CGFloat(poleCount - 1) * gridSpacing)
        let randomY = baseHeight + CGFloat.random(in: -heightVariation..<heightVariation)
        
        // Create and position pole set
        if let poleSet = Pole.shared.getPooledPoleSet() {
            poleSet.position = CGPoint(x: poleX, y: randomY)
            if poleSet.parent == nil {
                addChild(poleSet)
            }
            
            // Spawn collectibles at the same grid position
            let collectibleBasePosition = CGPoint(x: poleX, y: randomY)
            
            if poleCount % 5 == 0 {
                // Every 5th grid, spawn a single burger
                spawnCollectiblePattern(at: collectibleBasePosition, pattern: .single, isBurger: true)
            } else {
                // Otherwise spawn a random coin pattern
                let patterns: [CollectiblePattern] = [
                    .single, .triangle, .square, .cross, .star,
                    .diagonal3, .diagonal5, .circle,
                    .v2,.v3, .v4, .v5,
                    .h2, .h3, .h4, .h5
                ]
                if let randomPattern = patterns.randomElement() {
                    spawnCollectiblePattern(at: collectibleBasePosition, pattern: randomPattern, isBurger: false)
                }
            }
        }
        
        poleCount += 1
    }
    
    // MARK: - Collectible Patterns
    enum CollectiblePattern {
        case single
        case triangle
        case square
        case cross
        case star
        case diagonal3
        case diagonal5
        case circle
        case v2
        case v3
        case v4
        case v5
        case h2
        case h3
        case h4
        case h5
        
        // Get relative positions for each pattern
        func getRelativePositions() -> [(x: CGFloat, y: CGFloat)] {
            let unit: CGFloat = DeviceType.current == .iPhone ? 70.0 : 120.0  // Base unit for spacing
            
            switch self {
            case .single:
                return [(0, 0)]  // Center
            case .triangle:
                return [(0, unit),  // Top
                       (-unit, -unit), // Bottom left
                       (unit, -unit)]  // Bottom right
            case .square:
                return [(unit, unit),    // Top right
                       (-unit, unit),    // Top left
                       (-unit, -unit),   // Bottom left
                       (unit, -unit)]    // Bottom right
            case .cross:
                return [(0, unit),     // Top
                       (-unit, 0),     // Left
                       (0, 0),         // Center
                       (unit, 0),      // Right
                       (0, -unit)]     // Bottom
            case .star:
                return [(0, unit*1.5),           // Top
                       (unit, unit/2),           // Top right
                       (unit, -unit/2),          // Bottom right
                       (0, -unit*1.5),           // Bottom
                       (-unit, -unit/2),         // Bottom left
                       (-unit, unit/2)]          // Top left
            case .diagonal3:
                return [
                    (-unit, unit),
                    (0, 0),
                    (unit, -unit)
                ]
            case .diagonal5:
                return [
                    (-unit * 2, unit * 2),
                    (-unit, unit),
                    (0, 0),
                    (unit, -unit),
                    (unit * 2, -unit * 2)
                ]
            case .circle:
                let radius = unit
                let points = 8  // Number of points in the circle
                return (0..<points).map { i in
                    let angle = CGFloat(i) * 2 * .pi / CGFloat(points)
                    return (
                        radius * cos(angle),
                        radius * sin(angle)
                    )
                }
            case .v2:
                return [(0, unit), (0, -unit)]  // High and low
            case .v3:
                return [
                    (0, unit),
                    (0, 0),
                    (0, -unit)
                ]
            case .v4:
                return [
                    (0, unit * 1.5),
                    (0, unit * 0.5),
                    (0, -unit * 0.5),
                    (0, -unit * 1.5)
                ]
            case .v5:
                return [
                    (0, unit * 2),
                    (0, unit),
                    (0, 0),
                    (0, -unit),
                    (0, -unit * 2)
                ]
            case .h2:
                return [
                    (-unit * 0.5, 0),
                    (unit * 0.5, 0)
                ]
            case .h3:
                return [
                    (-unit, 0),
                    (0, 0),
                    (unit, 0)
                ]
            case .h4:
                return [
                    (-unit * 1.5, 0),
                    (-unit * 0.5, 0),
                    (unit * 0.5, 0),
                    (unit * 1.5, 0)
                ]
            case .h5:
                return [
                    (-unit * 2, 0),
                    (-unit, 0),
                    (0, 0),
                    (unit, 0),
                    (unit * 2, 0)
                ]
            }
        }
    }
    
    // MARK: - Collectible Spawning
    private func spawnCollectibles() {
        let spawnPosition = CGPoint(x: baseSpawnX, y: frame.midY)
        
        // Randomly select a pattern
        let patterns: [CollectiblePattern] = [
            .single, .triangle, .square, .cross, .star,
            .diagonal3, .diagonal5, .circle,
            .v2, .v3, .v4, .v5,
            .h2, .h3, .h4, .h5
        ]
        
        let pattern = patterns.randomElement() ?? .single
        let isBurger = Int.random(in: 1...100) <= 20 // 20% chance for burger
        
        spawnCollectiblePattern(at: spawnPosition, pattern: pattern, isBurger: isBurger)
    }
    
    private func spawnCollectiblePattern(at basePosition: CGPoint, pattern: CollectiblePattern, isBurger: Bool) {
        let positions = pattern.getRelativePositions()
        
        for relativePos in positions {
            let collectible: SKSpriteNode?
            if isBurger {
                collectible = Collectable.shared.getPooledBurger()
            } else {
                collectible = Collectable.shared.getPooledCoin()
            }
            
            if let collectible = collectible {
                let finalPos = CGPoint(
                    x: basePosition.x + relativePos.x,
                    y: basePosition.y + relativePos.y
                )
                
                collectible.position = finalPos
                if collectible.parent == nil {  // Only add if not already in scene
                    addChild(collectible)
                }
            }
        }
    }

    // MARK: - Game Over
    private func gameOver(reason: GameOverReason) {
        if isGameOver { return }
        isGameOver = true
        
        // Stop hero movement
        hero.physicsBody?.velocity = .zero
        hero.physicsBody?.angularVelocity = 0
        
        playSound("game_over")
        
        // Transition to game over scene
        SceneManager.shared.transition(from: self, to: .gameOver(score: mainScore, coins: coinScore, reason: reason))
    }
    
    // MARK: - Reset Game
}
