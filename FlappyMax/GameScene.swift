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
let screenMargin: CGFloat = 100.0
let backgroundColorValue = SKColor(red: 50/255, green: 150/255, blue: 250/255, alpha: 1.0)
let poleSpacing: CGFloat = 900.0

struct PhysicsCategory {
    static let hero: UInt32 = 0x1 << 0
    static let pole: UInt32 = 0x1 << 1
    static let coin: UInt32 = 0x1 << 2
    static let burger: UInt32 = 0x1 << 3
    static let scoreZone: UInt32 = 0x1 << 4
    static let floor: UInt32 = 0x1 << 5
}

struct ScoreEntry: Codable {
    var name: String
    var mainScore: Int
    var coins: Int
    var burgers: Int
    var date: Date
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Labels
    internal var mainScoreLabel: SKLabelNode!
    internal var coinScoreLabel: SKLabelNode!
    internal var burgerScoreLabel: SKLabelNode!
    internal var mainScore = 0
    internal var coinScore = 0
    internal var burgerScore = 0

    // MARK: - Background Configuration
    internal let numberOfBackgrounds = 3
    internal let backgroundSpeed: CGFloat = 5.0
    internal var backgroundNodes: [SKSpriteNode] = []
    internal var gameOver = false

    let leaderboardKey = "Leaderboard"

    // MARK: - Hero Configuration
    internal let heroTextureScale: CGFloat = 2.0
    internal let flapImpulse: CGFloat = 150.0
    internal var hero: SKSpriteNode!
    internal var stamina: CGFloat = 100.0
    internal let staminaDepletion: CGFloat = 1.0
    internal let staminaReplenishment: CGFloat = 25.0

    // MARK: - Floor Configuration
    internal let floorSpeed: CGFloat = 8.0
    internal let floorTextureScale: CGFloat = 8.0
    internal var floorNodes: [SKSpriteNode] = []

    // MARK: - Pole Configuration
    internal let numberOfPolePairs = 4
    internal var polePairGap: CGFloat = 300.0
    internal let poleTextureScale: CGFloat = 6.0
    internal let minDistanceFromPole: CGFloat = 50.0
    internal var poleSectionLength: CGFloat = 0.0
    internal var polePairs: [SKNode] = []

    // MARK: - Collectable Configuration
    internal let numberOfCoins = 10
    internal let numberOfBurgers = 1
    internal let coinAnimationSpeed: TimeInterval = 1/30
    internal let coinTextureScale: CGFloat = 0.8
    internal let burgerTextureScale: CGFloat = 3.0
    internal let minRandomXPosition: CGFloat = 200.0
    internal let maxRandomXPosition: CGFloat = 400.0
    internal var collectableSectionLength: CGFloat = 0.0
    internal var coinNodes: [SKSpriteNode] = []
    internal var burgerNodes: [SKSpriteNode] = []
    internal var staminaBar: SKSpriteNode!
    internal let maxStamina: CGFloat = 100.0
    internal var currentStamina: CGFloat = 100.0
    internal let staminaDepletionRate: CGFloat = 0.01
    internal let staminaBarWidth: CGFloat = 200.0
    internal let staminaBarHeight: CGFloat = 20.0

    // MARK: - Movement Speeds
    internal let objectSpeed: CGFloat = 8.0

    // MARK: - Obstacles
    internal var obstacles: [SKSpriteNode] = []

    // MARK: - Sound Effects
    var coinSoundEffects: [AVAudioPlayer] = []
    var burgerSoundEffects: [AVAudioPlayer] = []
    var gameOverSoundEffects: [AVAudioPlayer] = []
    var flapSoundEffects: [AVAudioPlayer] = []
    let soundEffectPoolSize = 3

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
            case PhysicsCategory.coin:
                if let collectableNode = otherBody.node as? SKSpriteNode {
                    collect(collectableNode)
                }

            case PhysicsCategory.burger:
                currentStamina = min(currentStamina + staminaReplenishment, maxStamina)
                updateStaminaBar()

            case PhysicsCategory.pole, PhysicsCategory.floor: // Game over
                gameOver = true
                handleGameOver()

            default:
                break
        }
    }
        
    func handleGameOver() {
        stopAllSoundEffects()
        playSoundEffect(from: gameOverSoundEffects)
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.scaleMode = .aspectFill
        gameOverScene.currentScore = ScoreEntry(name: "", mainScore: mainScore, coins: coinScore, burgers: burgerScore, date: Date())
        view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
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
            coinScoreLabel.text = "Coins: \(coinScore)"
            coinNodes.removeAll { $0 == collectableNode }
            playSoundEffect(from: coinSoundEffects)
        } else if burgerNodes.contains(collectableNode) {
            stamina = min(stamina + staminaReplenishment, 100.0)
            burgerNodes.removeAll { $0 == collectableNode }
            playSoundEffect(from: burgerSoundEffects)
        }

        obstacles.removeAll { $0 == collectableNode }
        collectableNode.removeFromParent()
    }

    private func setupLabels() {
        // Setup the main score label
        mainScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        mainScoreLabel.position = CGPoint(
            x: frame.midX,
            y: frame.height - screenMargin * 1.2
        )
        mainScoreLabel.fontSize = 100
        mainScoreLabel.fontColor = .white
        mainScoreLabel.text = "0"
        mainScoreLabel.zPosition = 100
        addChild(mainScoreLabel)

        // Setup the coin score label
        coinScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        coinScoreLabel.position = CGPoint(
            x: frame.width - screenMargin * 1.0,
            y: frame.height - screenMargin * 0.7
        )
        coinScoreLabel.fontSize = 32
        coinScoreLabel.fontColor = .white
        coinScoreLabel.text = "Coins: 0"
        coinScoreLabel.zPosition = 100
        addChild(coinScoreLabel)

        // // Setup the burger score label
        // burgerScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        // burgerScoreLabel.position = CGPoint(
        //     x: screenMargin * 1.5,
        //     y: frame.height - screenMargin
        // )
        // burgerScoreLabel.fontSize = 32
        // burgerScoreLabel.fontColor = .white
        // burgerScoreLabel.text = "Burgers: 0"
        // burgerScoreLabel.zPosition = 100
        // addChild(burgerScoreLabel)
    }

    func setupStaminaBar() {
        let barBackground = SKSpriteNode(color: .gray, size: CGSize(width: staminaBarWidth, height: staminaBarHeight))
        barBackground.position = CGPoint(
            x: frame.minX + staminaBarWidth / 2 + 30,
            y: frame.height - screenMargin * 0.5
        )
        barBackground.zPosition = 100
        addChild(barBackground)
        
        staminaBar = SKSpriteNode(color: .green, size: CGSize(width: staminaBarWidth, height: staminaBarHeight))
        staminaBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        staminaBar.position = CGPoint(
            x: frame.minX + 30,  // Align left side with barBackground
            y: frame.height - screenMargin * 0.5
        )
        staminaBar.zPosition = 101
        addChild(staminaBar)
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
        hero = SKSpriteNode(texture: heroTexture)
        hero.position = CGPoint(x: frame.midX / 2, y: frame.midY)
        hero.zPosition = 1
        hero.size = CGSize(width: heroTexture.size().width * heroTextureScale, height: heroTexture.size().height * heroTextureScale)
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
        let floorWidth = floorTexture.size().width * floorTextureScale
        let numberOfFloors = Int(ceil(frame.size.width / floorWidth)) + 1
        for i in 0..<numberOfFloors {
            let floor = SKSpriteNode(texture: floorTexture)
            floor.size = CGSize(width: floorWidth, height: floorTexture.size().height * floorTextureScale)
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

    // Function to retrieve the top 10 scores from UserDefaults
    func getLeaderboard() -> [ScoreEntry] {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey) {
            let decoder = JSONDecoder()
            return (try? decoder.decode([ScoreEntry].self, from: data)) ?? []
        }
        return []
    }

    // Function to save the top 10 scores to UserDefaults
    func saveLeaderboard(_ leaderboard: [ScoreEntry]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(leaderboard) {
            UserDefaults.standard.set(data, forKey: leaderboardKey)
        }
    }

    // Function to add a new score if it's in the top 10
    func updateLeaderboard(with newEntry: ScoreEntry) {
        var leaderboard = getLeaderboard()
        leaderboard.append(newEntry)

        leaderboard.sort { $0.mainScore > $1.mainScore }

        if leaderboard.count > 10 {
            leaderboard.removeLast() // Keep only top 10
        }
        saveLeaderboard(leaderboard)
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
