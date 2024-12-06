//
//  GameScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import GameplayKit
import AVFoundation

// MARK: - General Game Configuration
let gravity: CGFloat = -9.0
let backgroundColorValue = SKColor(red: 50/255, green: 150/255, blue: 250/255, alpha: 1.0)

struct PhysicsCategory {
    static let hero: UInt32 = 0x1 << 0
    static let pole: UInt32 = 0x1 << 1
    static let coin: UInt32 = 0x1 << 2
    static let burger: UInt32 = 0x1 << 3
    static let scoreZone: UInt32 = 0x1 << 4
    static let floor: UInt32 = 0x1 << 5
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Labels
    internal var mainScoreLabel: SKLabelNode!
    internal var coinScoreLabel: SKLabelNode!
    internal var mainScore = 0
    internal var coinScore = 0
    internal var burgerScore = 0

    // MARK: - Background Configuration
    internal let numberOfBackgrounds = 3
    internal var backgroundSpeed: CGFloat { GameConfig.Physics.gameSpeed * 0.625 } // 5/8 of base speed
    internal var backgroundNodes: [SKSpriteNode] = []
    internal var gameOver = false

    private let leaderboardManager = LeaderboardManager.shared

    // MARK: - Hero Configuration
    internal let heroTextureScale: CGFloat = GameConfig.Scales.hero
    internal var hero: SKSpriteNode!
    internal var stamina: CGFloat = 100.0
    internal let staminaDepletion: CGFloat = 1.0
    internal let staminaReplenishment: CGFloat = 25.0

    // MARK: - Floor Configuration
    internal var floorSpeed: CGFloat { GameConfig.Physics.gameSpeed }
    internal let floorTextureScale: CGFloat = 8.0
    internal var floorNodes: [SKSpriteNode] = []

    // MARK: - Pole Configuration
    internal let numberOfPolePairs = 4
    internal var polePairGap: CGFloat { GameConfig.scaled(GameConfig.Metrics.polePairGap) }
    internal var poleSpacing: CGFloat { GameConfig.scaled(GameConfig.Metrics.poleSpacing) }
    internal let poleTextureScale: CGFloat = 6.0
    internal let minDistanceFromPole: CGFloat = 50.0
    internal var poleSectionLength: CGFloat = 0.0
    internal var polePairs: [SKNode] = []

    // MARK: - Collectable Configuration
    internal let numberOfCoins = 10
    internal let coinAnimationSpeed: TimeInterval = 1/30
    internal let coinTextureScale: CGFloat = GameConfig.Scales.coin
    internal let burgerTextureScale: CGFloat = GameConfig.Scales.burger
    internal let minRandomXPosition: CGFloat = 200.0
    internal let maxRandomXPosition: CGFloat = 400.0
    internal var collectableSectionLength: CGFloat = 0.0
    internal var coinNodes: [SKSpriteNode] = []
    internal var burgerNodes: [SKSpriteNode] = []
    internal var staminaBar: SKSpriteNode!
    internal let maxStamina: CGFloat = 100.0
    internal var currentStamina: CGFloat = 100.0
    internal let staminaDepletionRate: CGFloat = 0.01
    internal var staminaBarWidth: CGFloat = 200.0
    internal let staminaBarHeight: CGFloat = 20.0

    // MARK: - Movement Speeds
    internal var objectSpeed: CGFloat { GameConfig.Physics.gameSpeed }

    // MARK: - Obstacles
    internal var obstacles: [SKSpriteNode] = []

    // MARK: - Sound Effects
    var coinSoundEffects: [AVAudioPlayer] = []
    var burgerSoundEffects: [AVAudioPlayer] = []
    var gameOverSoundEffects: [AVAudioPlayer] = []
    var flapSoundEffects: [AVAudioPlayer] = []
    let soundEffectPoolSize = 3

    var gravity: CGFloat { GameConfig.Physics.gravity }
    var flapImpulse: CGFloat { GameConfig.Physics.flapImpulse }

    // Add computed property for floor height
    var floorHeight: CGFloat {
        floorNodes.first?.size.height ?? GameConfig.Metrics.floorHeight
    }

    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gravity)
        self.physicsWorld.contactDelegate = self
        setupLabels()
        setupBackground()
        setupStaminaBar()
        setupHero()
        setupFloor()
        setupPoles()
        setupCollectibles()

        // Load and preload sound effects
        loadSoundEffects()
    }

    private func loadSoundEffects() {
        // Load flap sound effect into a pool
        if let flapSoundURL = Bundle.main.url(forResource: "flap", withExtension: "caf") {
            for _ in 0..<soundEffectPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: flapSoundURL) {
                    player.prepareToPlay()
                    flapSoundEffects.append(player)
                }
            }
        }

        if let coinSoundURL = Bundle.main.url(forResource: "coin", withExtension: "mp3") {
            for _ in 0..<soundEffectPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: coinSoundURL) {
                    player.volume = 0.5  // Set coin sound volume to 50%
                    player.prepareToPlay()
                    coinSoundEffects.append(player)
                }
            }
        }
        if let burgerSoundURL = Bundle.main.url(forResource: "eating", withExtension: "mp3") {
            for _ in 0..<soundEffectPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: burgerSoundURL) {
                    player.prepareToPlay()
                    burgerSoundEffects.append(player)
                }
            }
        }
        if let gameOverSoundURL = Bundle.main.url(forResource: "game_over", withExtension: "mp3") {
            for _ in 0..<soundEffectPoolSize {
                if let player = try? AVAudioPlayer(contentsOf: gameOverSoundURL) {
                    player.prepareToPlay()
                    gameOverSoundEffects.append(player)
                }
            }
        }
    }

    private func playSoundEffect(from pool: [AVAudioPlayer]) {
        for player in pool {
            if !player.isPlaying {
                player.play()
                break
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        let otherBody: SKPhysicsBody

        if contactA.categoryBitMask == PhysicsCategory.hero {
            otherBody = contactB
        } else if contactB.categoryBitMask == PhysicsCategory.hero {
            otherBody = contactA
        } else {
            return
        }

        switch otherBody.categoryBitMask {
            case PhysicsCategory.scoreZone:
                if let scoreZoneNode = otherBody.node {
                    mainScore += 1
                    mainScoreLabel.text = "\(mainScore)"
                    scoreZoneNode.physicsBody = nil
                }
            case PhysicsCategory.coin, PhysicsCategory.burger:
                if let collectableNode = otherBody.node as? SKSpriteNode {
                    collect(collectableNode)
                }
            case PhysicsCategory.pole, PhysicsCategory.floor: // Game over
                gameOver = true
                handleGameOver()
            default:
                break
        }
    }
        
    func handleGameOver() {
        // Play game over sound
        playSoundEffect(from: gameOverSoundEffects)
        
        // Create score entry
        let score = ScoreEntry(
            mainScore: mainScore,
            coins: coinScore,
            name: nil,
            date: Date()
        )
        
        // If score is 0, go directly to game over scene
        if mainScore == 0 {
            let gameOverScene = GameOverScene(size: self.size)
            gameOverScene.scaleMode = .aspectFill
            gameOverScene.currentScore = score
            view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
            return
        }
        
        // For non-zero scores, check if it's a high score
        if leaderboardManager.isHighScore(mainScore) {
            let nameEntryScene = NameEntryScene(size: self.size, score: score)
            nameEntryScene.scaleMode = .aspectFill
            view?.presentScene(nameEntryScene, transition: SKTransition.fade(withDuration: 0.5))
        } else {
            let gameOverScene = GameOverScene(size: self.size)
            gameOverScene.scaleMode = .aspectFill
            gameOverScene.currentScore = score
            view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }

    private func stopAllSoundEffects() {
        for player in coinSoundEffects + burgerSoundEffects +       flapSoundEffects + gameOverSoundEffects {
            player.stop()  // Stop each player in all pools
            player.currentTime = 0  // Reset to the beginning in case it's reused
        }
    }

    func collect(_ collectableNode: SKSpriteNode) {
        if coinNodes.contains(collectableNode) {
            coinScore += 1
            coinScoreLabel.text = "\(coinScore)"
            playSoundEffect(from: coinSoundEffects)
            collectableNode.name = "collected"
            // Reset and reuse the node instead of removing
            resetCollectable(collectableNode)
        } else if burgerNodes.contains(collectableNode) {
            burgerScore += 1
            currentStamina = min(maxStamina, currentStamina + staminaReplenishment)  // Replenish stamina
            updateStaminaBar()  // Update the stamina bar
            playSoundEffect(from: burgerSoundEffects)
            collectableNode.name = "collected"
            // Reset and reuse the node instead of removing
            resetCollectable(collectableNode)
        }
    }

    private func resetCollectable(_ collectable: SKSpriteNode) {
        // Reset properties and reposition for reuse
        collectable.position.x = frame.width + CGFloat.random(in: minRandomXPosition...maxRandomXPosition)
        collectable.removeFromParent()
        addChild(collectable)
    }

    private func setupLabels() {
        // Setup score label
        mainScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        mainScoreLabel.text = "0"
        mainScoreLabel.fontSize = GameConfig.adaptiveFontSize(48)
        mainScoreLabel.fontColor = .white
        mainScoreLabel.position = CGPoint(
            x: frame.width / 2,
            y: frame.height - GameConfig.Metrics.topMargin
        )
        mainScoreLabel.zPosition = 100
        addChild(mainScoreLabel)

        // Setup coin counter with sprite
        let coinTexture = SKTexture(imageNamed: "coin_01.png")
        coinTexture.filteringMode = .nearest
        let coinSprite = SKSpriteNode(texture: coinTexture)
        
        // Use smaller scale for coin counter
        let coinSize = GameConfig.adaptiveSize(
            for: coinTexture,
            baseScale: GameConfig.Scales.coinCounter,
            spriteType: .coin
        )
        coinSprite.size = coinSize
        
        coinScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        coinScoreLabel.fontSize = GameConfig.adaptiveFontSize(24)
        coinScoreLabel.fontColor = .white
        coinScoreLabel.text = "0"
        coinScoreLabel.zPosition = 100
        
        // Create a parent node to group coin sprite and label
        let coinCounter = SKNode()
        coinCounter.zPosition = 100
        
        // Position sprite and label within the counter
        coinSprite.position = CGPoint(x: -coinSize.width/2, y: 0)
        coinScoreLabel.position = CGPoint(
            x: coinSize.width/2 + GameConfig.scaled(5),
            y: -coinSize.height/4
        )
        
        coinCounter.addChild(coinSprite)
        coinCounter.addChild(coinScoreLabel)
        
        // Position the counter in the top-right corner with safe area consideration
        let rightMargin = GameConfig.Metrics.screenMargin
        coinCounter.position = CGPoint(
            x: frame.width - rightMargin,
            y: frame.height - GameConfig.Metrics.topMargin
        )
        
        addChild(coinCounter)
    }

    func setupStaminaBar() {
        let safeLeftMargin = GameConfig.Metrics.screenMargin
        let barWidth = min(staminaBarWidth, frame.width * 0.3)  // Limit width on smaller devices
        
        let barBackground = SKSpriteNode(color: .gray, size: CGSize(width: barWidth, height: staminaBarHeight))
        barBackground.position = CGPoint(
            x: safeLeftMargin + barWidth / 2,
            y: frame.height - GameConfig.Metrics.topMargin
        )
        barBackground.zPosition = 100
        addChild(barBackground)
        
        staminaBar = SKSpriteNode(color: .green, size: CGSize(width: barWidth, height: staminaBarHeight))
        staminaBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        staminaBar.position = CGPoint(
            x: safeLeftMargin,
            y: frame.height - GameConfig.Metrics.topMargin
        )
        staminaBar.zPosition = 101
        addChild(staminaBar)
        
        // Update the stored bar width for future reference
        staminaBarWidth = barWidth
    }

    private func updateStaminaBar() {
        let staminaRatio = max(0, currentStamina / maxStamina)
        staminaBar.size.width = staminaBarWidth * staminaRatio
        staminaBar.color = staminaRatio > 0.2 ? .green : .yellow
    }

    private func setupBackground() {
        for i in 0..<numberOfBackgrounds {
            let background = SKSpriteNode(color: backgroundColorValue, size: self.size)
            background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: frame.midY)
            background.zPosition = -10
            addChild(background)
            backgroundNodes.append(background)
        }
    }

    private func setupHero() {
        let heroTexture = SKTexture(imageNamed: "max")
        heroTexture.filteringMode = .nearest
        
        // Use the new scaling system
        let heroSize = GameConfig.adaptiveSize(
            for: heroTexture,
            spriteType: .hero  // Uses the default hero scale
        )
        
        hero = SKSpriteNode(texture: heroTexture)
        hero.position = CGPoint(x: frame.midX / 2, y: frame.midY)
        hero.zPosition = 1
        hero.size = heroSize
        hero.physicsBody = SKPhysicsBody(texture: heroTexture, size: hero.size)
        hero.physicsBody?.isDynamic = true
        hero.physicsBody?.affectedByGravity = true
        hero.physicsBody?.allowsRotation = false
        hero.physicsBody?.categoryBitMask = PhysicsCategory.hero
        hero.physicsBody?.contactTestBitMask = PhysicsCategory.pole | PhysicsCategory.coin | PhysicsCategory.burger
        hero.physicsBody?.collisionBitMask = PhysicsCategory.pole | PhysicsCategory.floor

        addChild(hero)
    }

    private func setupFloor() {
        let floorTexture = SKTexture(imageNamed: "floor")
        floorTexture.filteringMode = .nearest
        
        // Use the new scaling system
        let floorSize = GameConfig.adaptiveSize(
            for: floorTexture,
            spriteType: .floor  // Uses the default floor scale
        )
        
        let floorWidth = floorSize.width
        let numberOfFloors = Int(ceil(frame.size.width / floorWidth)) + 1
        
        for i in 0..<numberOfFloors {
            let floor = SKSpriteNode(texture: floorTexture)
            floor.size = floorSize
            floor.anchorPoint = CGPoint(x: 0, y: 0)
            floor.position = CGPoint(x: CGFloat(i) * floorWidth, y: frame.minY)
            floor.zPosition = 10
            floor.physicsBody = SKPhysicsBody(rectangleOf: floor.size, center: CGPoint(x: floorWidth / 2, y: floor.size.height / 2))
            floor.physicsBody?.isDynamic = false
            floor.physicsBody?.categoryBitMask = PhysicsCategory.floor
            floor.physicsBody?.contactTestBitMask = PhysicsCategory.hero
            floor.physicsBody?.collisionBitMask = PhysicsCategory.hero

            addChild(floor)
            floorNodes.append(floor)
            obstacles.append(floor)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        moveBackgrounds(speed: backgroundSpeed)
        moveFloor(speed: floorSpeed)
        movePoles(speed: objectSpeed)
        moveCollectibles(speed: objectSpeed)

        if currentStamina > 0 && !gameOver {
            currentStamina -= staminaDepletionRate
            if currentStamina < 0 {
                currentStamina = 0
            }
        }

        updateStaminaBar()
    }

    private func moveBackgrounds(speed: CGFloat) {
        guard !gameOver else { return }
        for background in backgroundNodes {
            background.position.x -= speed

            // Reset the background position if it moves completely off-screen
            if background.position.x <= -background.size.width {
                background.position.x += background.size.width * CGFloat(backgroundNodes.count)
            }
        }
    }

    private func moveFloor(speed: CGFloat) {
        guard !gameOver else { return }
        for floor in floorNodes {
            floor.position.x -= speed

            // Reset floor position if it moves off-screen
            if floor.position.x <= -floor.size.width {
                floor.position.x += floor.size.width * CGFloat(floorNodes.count)
            }
        }
    }

    func createCurvePath(between firstPolePair: SKNode, and secondPolePair: SKNode) -> CGPath {
        let path = CGMutablePath()

        // Define starting and ending points for the curve
        let startPoint = CGPoint(x: firstPolePair.position.x, y: firstPolePair.position.y)
        print("startPoint: \(startPoint)", firstPolePair.position)
        let endPoint = CGPoint(x: secondPolePair.position.x, y: secondPolePair.position.y)
        print("endPoint: \(endPoint)", secondPolePair.position)

        // Calculate control points for the Bezier curve
        let controlPoint1 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: startPoint.y + 200)
        let controlPoint2 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: endPoint.y - 200)

        // Create the Bezier curve path
        path.move(to: startPoint)
        path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
        print("Path bounding box: \(path.boundingBox)")

        return path
    }

    func placeCollectableOnCurve(collectable: SKSpriteNode, curvePath: CGPath) {
        // Randomly select a point along the curve path
        let randomT = CGFloat.random(in: 0.1...0.9)
        let position = positionOnPath(path: curvePath, at: randomT)
        collectable.position = position
    }

    // Helper function to calculate a position on the path
    func positionOnPath(path: CGPath, at t: CGFloat) -> CGPoint {
        // Extract path points and calculate position based on t (0.0 to 1.0)
        let pathInfo = path.copy(dashingWithPhase: 0, lengths: [path.boundingBox.width])
        let pathLength = pathInfo.boundingBox.width
        let point = CGPoint(x: path.boundingBox.origin.x + pathLength * t, y: path.boundingBox.origin.y)
        return point
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentStamina > 0 {
            hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: flapImpulse))
            currentStamina = max(currentStamina - staminaDepletionRate, 0)
            updateStaminaBar()

            // Play flap sound effect from the pool
            playSoundEffect(from: flapSoundEffects)
        }
    }
}
