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

class GameScene: SKScene, SKPhysicsContactDelegate {
    // DEBUG
    private var isGravityEnabled: Bool = true
    private var isHeroCollisionEnabled: Bool = true
    private var hasRenderedFirstFrame: Bool = false

    // UI Container
    private var uiLayer: SKNode!

    // MARK: - Labels & Scores
    internal var mainScoreLabel: SKLabelNode!
    internal var coinCounterLabel: SKLabelNode!
    internal var mainScore = 0
    internal var coinScore = 0
    internal var burgerScore = 0

    // MARK: - Game State
    internal var isGameOver = false
    private let leaderboardManager = LeaderboardManager.self
    private var poleSetCount = 0  // Track number of pole sets spawned
    private var isGamePaused = false
    private var pauseManager: PauseManager!

    // MARK: - Background Configuration
    internal let numberOfBackgrounds = 3
    internal var backgroundSpeed: CGFloat { GameConfig.Physics.gameSpeed * 0.618 }
    internal var backgroundNodes: [SKSpriteNode] = []
    internal var parallaxLayers: [[SKSpriteNode]] = []
    internal let parallaxSpeeds: [CGFloat] = [0.6, 0.4, 0.2] // Different speeds for each layer

    // MARK: - Hero Configuration
    internal var hero: SKSpriteNode!

    // MARK: - Floor Configuration
    internal var floorSpeed: CGFloat { GameConfig.Physics.gameSpeed * 1.3 }  // 20% faster than game speed
    internal var floorNodes: [SKSpriteNode] = []

    // MARK: - Pole & Collectible Configuration
    internal var poleSpacing: CGFloat = GameConfig.scaled(GameConfig.Metrics.poleSpacing)  // Spacing between poles
    internal let numberOfPolePairs = 4
    internal var poleNodes: [SKNode] = []
    
    // Pools and Grids
    var currentIndex: Int = 0
    var heroBaseX: CGFloat = 0
    var baseSpawnX: CGFloat = 0 // where segments start spawning

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
    internal let staminaDecreaseRate: CGFloat = 3.0  // Points per flap
    internal var staminaBarWidth: CGFloat = 200.0
    internal let staminaBarHeight: CGFloat = 20.0
    internal var staminaFill: SKSpriteNode!

    // MARK: - Audio
    private var audioPlayers: [String: Any] = [:] // Can store either AVAudioPlayer or [AVAudioPlayer]
    private let maxCollectibleSounds = 4
    
    static func playSound(_ name: String) {
        let player = try? AVAudioPlayer(contentsOf: Bundle.main.url(forResource: name, withExtension: "m4a")!)
        player?.play()
    }
    
    private func loadSoundEffects() {
        // Pre-load and prepare all sound effects
        let sounds = [
            "flap",         // flap.m4a
            "coin",         // coin.m4a
            "burger",       // burger.m4a
            "game_over",    // game_over.m4a
            "game_start",   // game_start.m4a
            "swoosh",       // swoosh.m4a
            "click"         // click.m4a
        ]
        
        for sound in sounds {
            if sound == "coin" || sound == "burger" {
                // Create multiple players for collectible sounds
                var players: [AVAudioPlayer] = []
                for _ in 0..<maxCollectibleSounds {
                    if let player = createAudioPlayer(for: sound) {
                        players.append(player)
                    }
                }
                if !players.isEmpty {
                    audioPlayers[sound] = players
                    #if DEBUG
                    print("Successfully cached \(players.count) players for: \(sound)")
                    #endif
                }
            } else {
                // Single player for other sounds
                if let player = createAudioPlayer(for: sound) {
                    audioPlayers[sound] = player
                    #if DEBUG
                    print("Successfully cached sound: \(sound)")
                    #endif
                }
            }
        }
    }
    
    private func createAudioPlayer(for name: String) -> AVAudioPlayer? {
        // All sounds now use .m4a extension
        let fileExtension = "m4a"
        
        // Try to get the URL for the sound file
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            #if DEBUG
            print("Could not find sound file: \(name).\(fileExtension)")
            #endif
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            #if DEBUG
            print("Could not create audio player for \(name): \(error)")
            #endif
            return nil
        }
    }
    
    private func playSoundEffect(_ name: String) -> AVAudioPlayer? {
        if name == "coin" || name == "burger" {
            // Handle collectible sounds with multiple players
            if let players = audioPlayers[name] as? [AVAudioPlayer] {
                // Try to find a player that's not currently playing
                if let availablePlayer = players.first(where: { !$0.isPlaying }) {
                    availablePlayer.currentTime = 0
                    availablePlayer.play()
                    return availablePlayer
                }
                // If all players are busy, use the first one
                players[0].currentTime = 0
                players[0].play()
                return players[0]
            }
        } else {
            // Handle single-player sounds
            if let player = audioPlayers[name] as? AVAudioPlayer {
                if player.isPlaying {
                    player.currentTime = 0
                }
                player.play()
                return player
            }
        }
        
        return createAudioPlayer(for: name)
    }
    
    // MARK: - First Responder and Key Commands

    // Allow the scene to become the first responder to receive key events
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    #if targetEnvironment(macCatalyst)
    // Define key commands for macOS
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed), discoverabilityTitle: "Flap")
        ]
    }
    
    // Selector method for spacebar press
    @objc func spacePressed(_ sender: UIKeyCommand) {
        flap()
    }
    #endif

    private var pauseButton: SKSpriteNode!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        if isGameOver { return }  // Let GameOverScene handle restart
        
        // Check if pause button was tapped
        if pauseButton.contains(location) {
            togglePause()
            return
        }

        for node in touchedNodes {
            if node.name == "resumeButton" {
                togglePause()
                return
            } 
        }

        // Only handle game input if not paused
        if !isGamePaused {
            #if DEBUG
            print("Calling flap()")
            #endif
            flap()
        }
    }
    
    #if targetEnvironment(macCatalyst)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        #if DEBUG
        print("\n=== Keyboard Event in GameScene ===")
        for press in presses {
            if let key = press.key {
                print("Key pressed: \(key.charactersIgnoringModifiers ?? "")")
                print("Key code: \(key.keyCode)")
            }
        }
        print("Game over state: \(isGameOver)")
        #endif
        
        if isGameOver { return }  // Let GameOverScene handle restart
        
        for press in presses {
            guard let key = press.key else { continue }
            
            // Check for both space and return key
            if key.charactersIgnoringModifiers == " " || key.keyCode == 44 {  // Space key
                #if DEBUG
                print("Space pressed, calling flap()")
                #endif
                flap()
                return
            }
        }
        
        super.pressesBegan(presses, with: event)
    }
    #endif

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        self.name = "GameScene"
        super.didMove(to: view)
        
        // Enable keyboard input for external keyboards
        #if targetEnvironment(macCatalyst)
        view.isUserInteractionEnabled = true
        view.becomeFirstResponder()
        #endif
        
        // Log current volume and load sounds
        let currentVolume = UserDefaults.standard.float(forKey: "SFXVolume")
        #if DEBUG
        print("Current game volume: \(currentVolume * 100)%")
        #endif
        loadSoundEffects()
        
        // Play game start sound
        _ = playSoundEffect("game_start")
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gravity)
        self.physicsWorld.contactDelegate = self

        // Create UI Layer first
        setupUILayer()
        setupLabels()
        setupStaminaBar()
        setupPauseButton()
        setupPauseManager()

        cleanupScene()
        
        setupPhysicsWorld()
        setupBackground()
        setupHero()
        setupFloor()

        // Initialize Pools and spawn initial segments
        setupPools()
        heroBaseX = hero.position.x
        baseSpawnX = frame.width + 50
        
        // Reset current index
        currentIndex = 0
        
        // Initialize hero collision state
        updateHeroCollision()
    }

    private func setupUILayer() {
        uiLayer = SKNode()
        uiLayer.zPosition = 100 // Ensure UI is always on top
        addChild(uiLayer)
    }

    private func setupLabels() {
        // Main Score Label
        mainScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        mainScoreLabel.text = "0"
        mainScoreLabel.fontSize = GameConfig.Metrics.mainScoreLabelFontSize
        mainScoreLabel.fontColor = .white
        mainScoreLabel.verticalAlignmentMode = .top
        mainScoreLabel.position = CGPoint(
            x: frame.width / 2,
            y: frame.height - GameConfig.SafeMargin.top
        )
        mainScoreLabel.zPosition = 100
        uiLayer.addChild(mainScoreLabel)
        #if DEBUG
        print("UI setup ---------------------------------------------")
        print("UI setup - mainScoreLabel size: \(mainScoreLabel.frame.width) x \(mainScoreLabel.frame.height)")
        print("UI setup - mainScoreLabel position: \(mainScoreLabel.position)")
        print("UI setup ---------------------------------------------")
        #endif

        // Coin counter
        let coinAtlas = SKTextureAtlas(named: "coin")
        let coinTexture = coinAtlas.textureNamed("coin_12")
        coinTexture.filteringMode = .nearest
        
        // Create container node for counter
        let coinCounterNode = SKNode()
        coinCounterNode.position = CGPoint(
            x: frame.maxX - GameConfig.SafeMargin.right,
            y: frame.maxY - GameConfig.SafeMargin.top - GameConfig.Metrics.coinCounterIconHeight/2
        )
        coinCounterNode.zPosition = 100

        // Create coin counter label first to get its size
        coinCounterLabel = SKLabelNode(fontNamed: "Helvetica")
        coinCounterLabel.fontSize = GameConfig.Metrics.coinCounterLabelSize
        coinCounterLabel.fontColor = .white
        coinCounterLabel.text = "0"
        coinCounterLabel.horizontalAlignmentMode = .right
        coinCounterLabel.verticalAlignmentMode = .center
        coinCounterLabel.zPosition = 100
        
        // Create coin counter icon
        let coinCounterIcon = SKSpriteNode(texture: coinTexture)
        coinCounterIcon.size = CGSize(
            width: GameConfig.Metrics.coinCounterIconWidth,
            height: GameConfig.Metrics.coinCounterIconHeight
        )
        coinCounterIcon.anchorPoint = CGPoint(x: 1, y: 0.5)
        coinCounterIcon.zPosition = 100

        // Position label at origin (right-aligned)
        coinCounterLabel.position = CGPoint(x: 0, y: 0)
        coinCounterNode.addChild(coinCounterLabel)
        
        // Position icon to the left of the label
        coinCounterIcon.position = CGPoint(
            x: -GameConfig.Metrics.coinCounterSpacing,
            y: 0
        )
        coinCounterNode.addChild(coinCounterIcon)
        
        addChild(coinCounterNode)

        #if DEBUG
        print("UI setup ---------------------------------------------")
        print("UI setup - coinCounterLabel size: \(coinCounterLabel.frame.width) x \(coinCounterLabel.frame.height)")
        print("UI setup - coinCounterIcon size: \(coinCounterIcon.size)")
        print("UI setup - coinCounterNode position: \(coinCounterNode.position)")
        print("UI setup ---------------------------------------------")
        #endif
    }

    private func setupStaminaBar() {
        let barWidth = GameConfig.scaled(200)
        let barHeight = GameConfig.scaled(20)
        
        staminaBar = SKSpriteNode(color: .gray, size: CGSize(width: barWidth, height: barHeight))
        staminaBar.anchorPoint = CGPoint(x: 0, y: 0.5)  // Left center anchor
        staminaBar.position = CGPoint(x: frame.minX + GameConfig.SafeMargin.left, y: frame.maxY - GameConfig.SafeMargin.top - barHeight/2)
        staminaBar.zPosition = 100
        addChild(staminaBar)
        
        staminaFill = SKSpriteNode(color: .green, size: CGSize(width: barWidth, height: barHeight))
        staminaFill.anchorPoint = CGPoint(x: 0, y: 0.5)  // Left center anchor
        staminaFill.position = CGPoint.zero
        staminaFill.zPosition = 1
        staminaBar.addChild(staminaFill)
    }

    private func setupPauseButton() {
        pauseButton = SKSpriteNode(imageNamed: "pause")
        pauseButton.name = "pauseButton"
        pauseButton.setScale(0.25)
        
        // Position in bottom left corner with padding
        pauseButton.position = CGPoint(
            x: pauseButton.size.width/2 + GameConfig.SafeMargin.left,
            y: pauseButton.size.height/2 + GameConfig.SafeMargin.bottom
        )
        
        // Add to UI layer to prevent parallax effects
        uiLayer.addChild(pauseButton)
    }

    private func setupPauseManager() {
        pauseManager = PauseManager(scene: self, physicsWorld: physicsWorld)
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
        let mountainHeight = large ? height * 0.25 : height * 0.15
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        var x: CGFloat = 0
        while x < width {
            let mountainWidth = large ? CGFloat.random(in: 150...300) : CGFloat.random(in: 80...160)
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
        
        #if DEBUG
        print("Hero setup - Initial position: (\(initialX), \(initialY))")
        print("Hero setup - Hero size: \(hero.size)")
        print("Scene setup - Frame dimensions: \(frame.width) x \(frame.height)")
        print("Scene setup - Floor height: \(GameConfig.Metrics.floorHeight)")
        print("Scene setup - Pole width: \(GameConfig.Metrics.poleWidth), pole spacing: \(GameConfig.Metrics.poleSpacing)")
        #endif
        
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
            #if DEBUG
            self.hero.physicsBody?.isDynamic = true
            print("Hero physics enabled - Current position: \(String(describing: self.hero.position))")
            #endif
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
        
        #if DEBUG
        print("Scene setup - Frame height: \(frame.height), Floor height: \(GameConfig.Metrics.floorHeight)")
        #endif
        
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
            #if DEBUG
            print("Floor \(i) position - X: \(floor.position.x), Y: \(floor.position.y)")
            #endif
            
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
        Collectable.shared.initializeCollectiblePool(coinCount: 25, burgerCount: 3)

        // Reset pole count for initial spawning
        poleSetCount = 0
        
        // Spawn initial poles
        for _ in 0..<3 {
            spawnPoleSet()
        }
    }
    
    private func spawnPoleSet() {
        if let poleSet = Pole.shared.getPooledPoleSet() {
            let xPos = poleNodes.isEmpty ? 
                frame.width + 42 : // First pole starts further off screen to account for initial movement
                poleNodes.last!.position.x + poleSpacing // Use consistent pole spacing
            
            #if DEBUG
            print("🚀 Spawning pole set - isEmpty: \(poleNodes.isEmpty), xPos: \(xPos)")
            if !poleNodes.isEmpty {
                print("🚀 Last pole position: \(poleNodes.last!.position.x), spacing: \(poleSpacing)")
            }
            #endif
                
            positionPoleSet(poleSet, atX: xPos)
            addChild(poleSet)
            poleNodes.append(poleSet)
            poleSetCount += 1
            
            // Spawn collectibles between poles
            let collectibleX = xPos + poleSpacing/2 // Center between current and next pole
            let centerY = GameConfig.Metrics.floorHeight + (frame.height - GameConfig.Metrics.floorHeight)/2
            
            // First 2 poles have guaranteed coins
            if poleSetCount <= 2 {
                let patterns: [CollectiblePattern] = [.single, .triangle, .square, .cross, .star, .diagonal3, .diagonal5, .circle, .v2, .v3, .v4, .v5, .h2, .h3, .h4, .h5]
                let pattern = patterns[Int.random(in: 0..<patterns.count)]
                spawnCollectiblePattern(at: CGPoint(x: collectibleX, y: centerY), pattern: pattern, isBurger: false)
            }
            // Spawn burger after every 5 poles
            else if poleSetCount % 5 == 0 {
                spawnCollectiblePattern(at: CGPoint(x: collectibleX, y: centerY), pattern: .single, isBurger: true)
            } 
            // Regular coin patterns for other poles
            else {
                let patterns: [CollectiblePattern] = [.single, .triangle, .square, .cross]
                let pattern = patterns[Int.random(in: 0..<patterns.count)]
                spawnCollectiblePattern(at: CGPoint(x: collectibleX, y: centerY), pattern: pattern, isBurger: false)
            }
        }
    }
    
    private func recyclePoleSet(_ poleSet: SKNode) {
        if let index = poleNodes.firstIndex(of: poleSet) {
            poleNodes.remove(at: index)
            poleSet.removeFromParent()
            Pole.shared.recyclePoleSet(poleSet)  // Make sure to recycle back to the pool
        }
    }

    private func positionPoleSet(_ poleSet: SKNode, atX xPos: CGFloat) {
        #if DEBUG
        print("📍 Positioning pole set - Initial xPos: \(xPos)")
        #endif
        
        let gap = GameConfig.scaled(GameConfig.Metrics.polePairGap)
        let minY = gap/2 + GameConfig.Metrics.poleSetVerticalMargin + GameConfig.Metrics.floorHeight
        let maxY = frame.height - gap/2 - GameConfig.Metrics.poleSetVerticalMargin
        
        // Generate random Y position within safe bounds
        let yPos = CGFloat.random(in: minY...maxY)
        
        poleSet.position = CGPoint(x: xPos, y: yPos)
        poleSet.zPosition = 1
        
        #if DEBUG
        print("📍 Final pole position - x: \(xPos), y: \(yPos), minY: \(minY), maxY: \(maxY)")
        #endif
    }

    // MARK: - Movement Management
    private func moveGameObjects(deltaTime: TimeInterval) {
        let baseSpeed = GameConfig.Physics.gameSpeed * CGFloat(deltaTime)
        
        // Move floor faster (1.3x base speed)
        moveFloor(speed: baseSpeed * 1.3)
        
        // Move poles at base speed
        movePoles(speed: baseSpeed)
        
        // Move collectibles at base speed
        moveCollectibles(speed: baseSpeed)
        
        // Move background layers at different speeds for parallax effect
        moveBackgroundLayers(deltaTime: deltaTime)
    }
    
    private func moveBackgroundLayers(deltaTime: TimeInterval) {
        let baseSpeed = GameConfig.Physics.gameSpeed * CGFloat(deltaTime)
        
        // Move background layers at different speeds
        for (index, layerNodes) in parallaxLayers.enumerated() {
            let speedMultiplier = index < parallaxSpeeds.count ? parallaxSpeeds[index] : 0.1
            
            for node in layerNodes {
                node.position.x -= baseSpeed * speedMultiplier
                
                // Reset position if moved off screen
                if node.position.x <= -node.size.width {
                    node.position.x += node.size.width * CGFloat(numberOfBackgrounds)
                }
            }
        }
    }
    
    private func moveFloor(speed: CGFloat) {
        for floor in floorNodes {
            floor.position.x -= speed
            
            // Reset floor position if it moves off-screen
            if floor.position.x <= -floor.size.width {
                floor.position.x += floor.size.width * CGFloat(floorNodes.count)
            }
        }
    }
    
    private func movePoles(speed: CGFloat) {
        for pole in poleNodes {
            pole.position.x -= speed
            
            // Recycle poles that are off screen
            if pole.position.x < -frame.width {
                recyclePoleSet(pole)
            }
        }
        
        // Spawn new poles if needed
        if poleNodes.isEmpty || (poleNodes.last!.position.x < frame.width) {
            spawnPoleSet()
        }
    }
    
    private func moveCollectibles(speed: CGFloat) {
        // Move active coins
        for coin in Collectable.shared.activeCoins {
            coin.position.x -= speed
            if coin.position.x < -frame.width {
                Collectable.shared.recycleCollectible(coin)
            }
        }
        
        // Move active burgers
        for burger in Collectable.shared.activeBurgers {
            burger.position.x -= speed
            if burger.position.x < -frame.width {
                Collectable.shared.recycleCollectible(burger)
            }
        }
    }

    // MARK: - Input Handling
    
    #if targetEnvironment(macCatalyst) || os(iOS)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard !isGameOver else { return }
        
        for press in presses {
            if press.key?.keyCode == .keyboardSpacebar {
                flap()
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
    #endif
    
    #if targetEnvironment(macCatalyst)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        #if DEBUG
        print("\n=== Keyboard Event ===")
        for press in presses {
            if let key = press.key {
                print("Key pressed: \(key.charactersIgnoringModifiers ?? "")")
            }
        }
        print("Game over state: \(isGameOver)")
        #endif
        
        guard !isGameOver else {
            #if DEBUG
            print("Game is over, restarting...")
            #endif
            restartGame()
            return
        }
        
        for press in presses {
            if let key = press.key, key.charactersIgnoringModifiers == " " {
                #if DEBUG
                print("Spacebar pressed, calling flap()")
                #endif
                flap()
                return
            }
        }
        
        super.pressesBegan(presses, with: event)
    }
    #endif

    private func flap() {
        guard !isGameOver else { return }
        
        if currentStamina > 0 {
            hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: flapImpulse))
            currentStamina -= staminaDecreaseRate
            updateStaminaBar()
            _ = playSoundEffect("flap")
        }
    }

    private var lastUpdateTime: TimeInterval = 0

    private func updateStaminaBar() {
        let staminaRatio = max(0, currentStamina / maxStamina)
        staminaFill.size.width = staminaBar.size.width * staminaRatio
        
        // Update color based on stamina level
        if staminaRatio <= 0.2 {
            staminaFill.color = .red
        } else if staminaRatio <= 0.5 {
            staminaFill.color = .yellow
        } else {
            staminaFill.color = .green
        }
        
        // Game over if stamina is depleted
        if staminaRatio <= 0 {
            gameOver(reason: .outOfStamina)
        }
    }

    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which body is the hero
        let heroBody: SKPhysicsBody
        let otherBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask == PhysicsCategory.hero {
            heroBody = contact.bodyA
            otherBody = contact.bodyB
        } else {
            heroBody = contact.bodyB
            otherBody = contact.bodyA
        }
        
        // Handle collisions only if collision is enabled
        if (otherBody.categoryBitMask == PhysicsCategory.pole || otherBody.categoryBitMask == PhysicsCategory.floor) 
            && isHeroCollisionEnabled {
            gameOver(reason: .collision)
        } else if otherBody.categoryBitMask == PhysicsCategory.coin {
            if let coin = otherBody.node as? SKSpriteNode {
                handleCollectibleCollection(coin, type: .coin)
            }
        } else if otherBody.categoryBitMask == PhysicsCategory.burger {
            if let burger = otherBody.node as? SKSpriteNode {
                handleCollectibleCollection(burger, type: .burger)
            }
        } else if otherBody.categoryBitMask == PhysicsCategory.scoreZone {
            if let scoreDetector = otherBody.node {
                // Only increment score if we haven't already scored for this detector
                if let userData = scoreDetector.userData, userData["scored"] as? Bool == false {
                    mainScore += 1
                    mainScoreLabel.text = "\(mainScore)"
                    scoreDetector.userData?["scored"] = true
                }
            }
        }
    }
    
    private func handleCollectibleCollection(_ collectible: SKSpriteNode, type: CollectibleType) {
        // Immediately mark as collected and disable physics to prevent multiple collisions
        Collectable.shared.markAsCollected(collectible)
        // collectible.physicsBody = nil
        collectible.physicsBody?.categoryBitMask = 0
        collectible.physicsBody?.contactTestBitMask = 0
        
        switch type {
        case .coin:
            coinScore += 1
            coinCounterLabel.text = "\(coinScore)"
            _ = playSoundEffect("coin")
        case .burger:
            burgerScore += 1
            currentStamina = 100.0  // Full stamina restoration
            updateStaminaBar()
            _ = playSoundEffect("burger")
        }
        
        // Fade out and move up animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        fadeOut.timingMode = .easeOut
        let moveUp = SKAction.moveBy(x: 0, y: 80, duration: 0.5)
        moveUp.timingMode = .easeOut
        let recycle = SKAction.run {
            Collectable.shared.recycleCollectible(collectible)
        }
        let collectibleSequence = SKAction.sequence([
            SKAction.group([fadeOut, moveUp]),
            recycle
        ])
        collectible.run(collectibleSequence)
    }
    
    private func spawnPole(at position: CGPoint) {
        if let poleSet = Pole.shared.getPooledPoleSet() {
            poleSet.position = position
            addChild(poleSet)
            poleNodes.append(poleSet)
        }
    }
    
    private func getNextPolePosition() -> CGPoint {
        let gap = GameConfig.scaled(GameConfig.Metrics.polePairGap)
        let minY = gap/2 + GameConfig.Metrics.poleSetVerticalMargin + GameConfig.Metrics.floorHeight
        let maxY = frame.height - gap/2 - GameConfig.Metrics.poleSetVerticalMargin
        
        // Generate random Y position within safe bounds
        let yPos = CGFloat.random(in: minY...maxY)
        
        return CGPoint(x: size.width, y: yPos)
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
            // Original patterns
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
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver && !isGamePaused else { return }
        
        // Calculate delta time
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return  // Skip first frame to ensure proper initialization
        }
        
        if !hasRenderedFirstFrame {
            hasRenderedFirstFrame = true
            return  // Skip movement on first frame render
        }
        
        let deltaTime = min(currentTime - lastUpdateTime, 1.0/30.0) // Cap delta time to prevent large jumps
        lastUpdateTime = currentTime
        
        // Move game objects
        moveGameObjects(deltaTime: deltaTime)
    }
    
    // MARK: - Game Over
    private func gameOver(reason: GameOverReason) {
        if isGameOver { return }
        isGameOver = true
        
        // Play game over sound
        _ = playSoundEffect("game_over")
        
        let mainScore = mainScore
        let coinScore = coinScore
        
        // Check if score qualifies for leaderboard
        let leaderboard = LeaderboardManager.shared
        let qualifiesForLeaderboard = mainScore > 0 && leaderboard.scoreQualifiesForLeaderboard(mainScore)
        
        let nextScene: SKScene
        if qualifiesForLeaderboard {
            nextScene = NameEntryScene(size: self.size, score: mainScore, coins: coinScore, gameOverReason: reason)
        } else {
            let gameOver = GameOverScene(size: self.size)
            gameOver.mainScore = mainScore
            gameOver.coinScore = coinScore
            gameOver.gameOverReason = reason
            nextScene = gameOver
        }
        
        nextScene.scaleMode = .aspectFill
        view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.3))
    }
    
    // MARK: - Reset Game
    private func restartGame() {
        #if DEBUG
        print("Restarting game...")
        #endif
        
        // Reset all game state
        isGameOver = false
        isGamePaused = false
        currentStamina = maxStamina
        poleSetCount = 0
        mainScore = 0
        coinScore = 0
        burgerScore = 0
        lastUpdateTime = 0
        
        // Reset physics world
        physicsWorld.gravity = isGravityEnabled ? CGVector(dx: 0, dy: GameConfig.Physics.gravity) : .zero
        physicsWorld.speed = 1
        physicsWorld.contactDelegate = self
        self.speed = 1
        
        // Remove all nodes except permanent UI
        self.children.forEach { node in
            if node !== uiLayer {  // Keep UI layer
                node.removeFromParent()
            }
        }
        
        // Recycle all objects to pools
        poleNodes.forEach { Pole.shared.recyclePoleSet($0) }
        poleNodes.removeAll()
        
        self.children.forEach { node in
            if let collectible = node as? SKSpriteNode {
                if collectible.name == "coin" || collectible.name == "burger" {
                    Collectable.shared.recycleCollectible(collectible)
                }
            }
        }
        
        // Remove pause UI if present
        if let container = childNode(withName: "pauseContainer") {
            container.removeFromParent()
        }
        
        // Reset UI
        mainScoreLabel.text = "0"
        coinCounterLabel.text = "0"
        updateStaminaBar()
        
        // Re-setup game elements in the same order as didMove(to:)
        setupPhysicsWorld()
        setupBackground()
        setupFloor()
        setupHero()
        setupPools()  // This will spawn initial poles
        
        #if DEBUG
        print("Game restarted")
        #endif
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: GameConfig.Physics.gravity)
        physicsWorld.contactDelegate = self
    }
    
    // MARK: - Node Tracking
    private func createPoleSet(at position: CGPoint) -> (SKSpriteNode, SKSpriteNode) {
        let gapHeight = GameConfig.Metrics.polePairGap
        let poleTexture = SKTexture(imageNamed: "pole")
        let scaledSize = GameConfig.adaptiveSize(for: poleTexture, spriteType: .pole)
        
        // Create top pole
        let topPole = SKSpriteNode(texture: poleTexture)
        topPole.size = scaledSize
        topPole.position = CGPoint(x: position.x, y: position.y + gapHeight/2)
        topPole.zRotation = .pi
        
        // Create bottom pole
        let bottomPole = SKSpriteNode(texture: poleTexture)
        bottomPole.size = scaledSize
        bottomPole.position = CGPoint(x: position.x, y: position.y - gapHeight/2)
        
        // Setup physics for both poles
        for pole in [topPole, bottomPole] {
            pole.physicsBody = SKPhysicsBody(rectangleOf: pole.size)
            pole.physicsBody?.isDynamic = false
            pole.physicsBody?.categoryBitMask = PhysicsCategory.pole
            pole.physicsBody?.collisionBitMask = PhysicsCategory.hero
            pole.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        }
        
        return (topPole, bottomPole)
    }
    
    private func createScoreZone() -> SKNode {
        let scoreZone = SKNode()
        let size = CGSize(width: 1, height: GameConfig.Metrics.polePairGap)
        scoreZone.physicsBody = SKPhysicsBody(rectangleOf: size)
        scoreZone.physicsBody?.isDynamic = false
        scoreZone.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
        scoreZone.physicsBody?.collisionBitMask = 0
        scoreZone.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        return scoreZone
    }
    
    private func spawnCollectiblePattern(at basePosition: CGPoint, pattern: CollectiblePattern, isBurger: Bool) {
        let positions = pattern.getRelativePositions()
        
        for relativePos in positions {
            let collectible = Collectable.shared.createCollectible(type: isBurger ? .burger : .coin)
            let finalPos = CGPoint(
                x: basePosition.x + relativePos.x,
                y: basePosition.y + relativePos.y
            )
            collectible.position = finalPos
            addChild(collectible)
        }
    }
    
    private func toggleHeroCollision() {
        isHeroCollisionEnabled.toggle()
        updateHeroCollision()
    }

    private func updateHeroCollision() {

        hero.physicsBody?.isDynamic = !isGamePaused
        
        if let heroBody = hero.physicsBody {
            // Keep the hero's physics body dynamic and other properties unchanged
            heroBody.isDynamic = true
            heroBody.allowsRotation = false
            heroBody.categoryBitMask = PhysicsCategory.hero
            
            if isHeroCollisionEnabled {
                // Enable both collision and contact detection for poles and floor
                heroBody.collisionBitMask = PhysicsCategory.pole | PhysicsCategory.floor
                heroBody.contactTestBitMask = PhysicsCategory.pole | PhysicsCategory.coin | 
                                            PhysicsCategory.burger | PhysicsCategory.scoreZone | 
                                            PhysicsCategory.floor
            } else {
                // Disable collision but keep contact detection for all
                heroBody.collisionBitMask = 0
                heroBody.contactTestBitMask = PhysicsCategory.pole | PhysicsCategory.coin | 
                                            PhysicsCategory.burger | PhysicsCategory.scoreZone | 
                                            PhysicsCategory.floor
            }
        }
        
        #if DEBUG
        print("Hero collision updated - isEnabled: \(isHeroCollisionEnabled)")
        if let heroBody = hero.physicsBody {
            print("Hero physics - collision: \(heroBody.collisionBitMask), contact: \(heroBody.contactTestBitMask)")
        }
        #endif
    }

    private func togglePause() {
        isGamePaused.toggle()
        pauseManager.togglePause(isGamePaused: isGamePaused) { [weak self] in
            self?.updateHeroCollision()
        }
    }
    
    private func createPauseUI() {
        // Create a container node for all pause UI elements
        let pauseContainer = SKNode()
        pauseContainer.name = "pauseContainer"
        pauseContainer.zPosition = 1000
        
        // Paused Label 
        let pausedLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        pausedLabel.text = "Paused"
        pausedLabel.position = CGPoint(x: frame.midX, y: frame.maxY * 0.75)
        pausedLabel.fontSize = 40
        pausedLabel.fontColor = .white
        pausedLabel.name = "pausedLabel"
        pauseContainer.addChild(pausedLabel)
        
        // Resume Button
        let resumeButton = SKLabelNode(fontNamed: "Helvetica")
        resumeButton.text = "Resume"
        resumeButton.position = CGPoint(x: frame.midX, y: frame.midY - 300)
        resumeButton.fontSize = 30
        resumeButton.fontColor = .green
        resumeButton.name = "resumeButton"
        pauseContainer.addChild(resumeButton)
        
        // Restart Button
        let restartButton = SKLabelNode(fontNamed: "Helvetica")
        restartButton.text = "Restart"
        restartButton.position = CGPoint(x: frame.midX, y: frame.midY - 250)
        restartButton.fontSize = 30
        restartButton.fontColor = .yellow
        restartButton.name = "restartButton"
        pauseContainer.addChild(restartButton)
        
        // Gravity Toggle
        let gravityToggle = SKLabelNode(text: "Toggle Gravity: \(isGravityEnabled ? "ON" : "OFF")")
        gravityToggle.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        gravityToggle.name = "gravityToggle"
        pauseContainer.addChild(gravityToggle)
        
        // Hero Collision Toggle
        let heroCollisionToggle = SKLabelNode(text: "Toggle Hero Collision: \(isHeroCollisionEnabled ? "ON" : "OFF")")
        heroCollisionToggle.position = CGPoint(x: frame.midX, y: frame.midY - 150)
        heroCollisionToggle.name = "heroCollisionToggle"
        pauseContainer.addChild(heroCollisionToggle)
        
        #if DEBUG
        // Debug Information
        let debugInfo = SKNode()
        debugInfo.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        
        // Hero Position
        let heroYPos = SKLabelNode(text: "Hero Y: \(String(format: "%.2f", hero.position.y))")
        heroYPos.fontSize = 20
        heroYPos.position = CGPoint(x: 0, y: 0)
        debugInfo.addChild(heroYPos)
        
        // Pole Pool Info
        let polePoolCount = Pole.shared.polePool.count
        let activePoleCount = poleNodes.count
        let poleInfo = SKLabelNode(text: "Poles - Pool: \(polePoolCount), Active: \(activePoleCount)")
        poleInfo.fontSize = 20
        poleInfo.position = CGPoint(x: 0, y: -30)
        debugInfo.addChild(poleInfo)

        let poleCount = SKLabelNode(text: "Pole Count: \(poleSetCount)")
        poleCount.fontSize = 20
        poleCount.position = CGPoint(x: 0, y: -60)
        debugInfo.addChild(poleCount)

        // Collectible Pool Info
        let coinPoolCount = Collectable.shared.coinPool.count
        let activeCoinCount = Collectable.shared.activeCoins.count
        let burgerPoolCount = Collectable.shared.burgerPool.count
        let activeBurgerCount = Collectable.shared.activeBurgers.count
        
        let coinInfo = SKLabelNode(text: "Coins - Pool: \(coinPoolCount), Active: \(activeCoinCount)")
        coinInfo.fontSize = 20
        coinInfo.position = CGPoint(x: 0, y: -90)
        debugInfo.addChild(coinInfo)
        
        let burgerInfo = SKLabelNode(text: "Burgers - Pool: \(burgerPoolCount), Active: \(activeBurgerCount)")
        burgerInfo.fontSize = 20
        burgerInfo.position = CGPoint(x: 0, y: -120)
        debugInfo.addChild(burgerInfo)
        
        pauseContainer.addChild(debugInfo)
        #endif
        
        addChild(pauseContainer)
    }
    
    private func cleanupScene() {
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
        burgerScore = 0
        currentStamina = maxStamina
        isGameOver = false
        
        // Update UI
        mainScoreLabel.text = "0"
        coinCounterLabel.text = "0"
        updateStaminaBar()
        
        #if DEBUG
        print("Scene cleaned up")
        #endif
    }
}
