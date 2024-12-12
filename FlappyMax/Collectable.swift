//
//  Collectable.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

/*
 Collectible items management for FlappyMax
 
 Responsibilities:
 - Collectible object creation and recycling
 - Collection state tracking and validation
 - Position management and randomization
 - Memory optimization through pooling
 - Collision state handling
 
 Features:
 - Efficient object pooling system
 - Persistent collection state tracking
 - Automatic sprite recycling
 - Random position generation
 - Collision detection setup
 - Memory usage optimization
 - Multiple collectible types (coins, burgers)
 - Collection validation logic
 - State reset on recycling
 - Device-specific positioning
 */

import SpriteKit
import GameplayKit

enum CollectibleType {
    case coin
    case burger
    case pizza
    case sushi
    case fries
    
    var staminaBoost: CGFloat {
        switch self {
        case .coin:
            return 0
        case .burger:
            return 100.0 // 100% stamina
        case .pizza:
            return 50.0 // 50% stamina
        case .sushi:
            return 25.0 // 25% stamina
        case .fries:
            return 10.0 // 10% stamina
        }
    }
}

class Collectable {
    static let shared = Collectable()
    
    // Make pools public for debug access
    var coinPool: [SKSpriteNode] = []
    var burgerPool: [SKSpriteNode] = []
    var pizzaPool: [SKSpriteNode] = []
    var sushiPool: [SKSpriteNode] = []
    var friesPool: [SKSpriteNode] = []
    
    var activeCoins: [SKSpriteNode] = []
    var activeBurgers: [SKSpriteNode] = []
    var activePizzas: [SKSpriteNode] = []
    var activeSushis: [SKSpriteNode] = []
    var activeFries: [SKSpriteNode] = []
    
    // Key for associated object to store collected state
    private let collectedKey = "CollectableCollectedState"
    
    private init() {}
    
    // Helper methods to manage collected state
    func markAsCollected(_ node: SKSpriteNode) {
        objc_setAssociatedObject(node, collectedKey, true, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func isCollected(_ node: SKSpriteNode) -> Bool {
        return (objc_getAssociatedObject(node, collectedKey) as? Bool) ?? false
    }
    
    func resetCollectedState(_ node: SKSpriteNode) {
        objc_setAssociatedObject(node, collectedKey, nil, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func initializeCollectiblePool(coinCount: Int = 30, burgerCount: Int = 5, pizzaCount: Int = 5, sushiCount: Int = 5, friesCount: Int = 5) {
        // Initialize coin pool
        for _ in 0..<coinCount {
            let coinAtlas = SKTextureAtlas(named: "coin")
            let coinTexture = coinAtlas.textureNamed("coin_01")
            let coin = createCollectable(texture: coinTexture, physicsCategory: PhysicsCategory.coin)
            coin.removeFromParent() // Ensure it's not in the scene
            coinPool.append(coin)
        }
        
        // Initialize burger pool
        for _ in 0..<burgerCount {
            let burger = createCollectable(texture: SKTexture(imageNamed: "burger.png"), physicsCategory: PhysicsCategory.burger)
            burger.name = "burger"
            burger.removeFromParent() // Ensure it's not in the scene
            burgerPool.append(burger)
        }
        
        // Initialize pizza pool
        for _ in 0..<pizzaCount {
            let pizza = createCollectable(texture: SKTexture(imageNamed: "pizza.png"), physicsCategory: PhysicsCategory.pizza)
            pizza.name = "pizza"
            pizza.removeFromParent() // Ensure it's not in the scene
            pizzaPool.append(pizza)
        }
        
        // Initialize sushi pool
        for _ in 0..<sushiCount {
            let sushi = createCollectable(texture: SKTexture(imageNamed: "sushi.png"), physicsCategory: PhysicsCategory.sushi)
            sushi.name = "sushi"
            sushi.removeFromParent() // Ensure it's not in the scene
            sushiPool.append(sushi)
        }
        
        // Initialize fries pool
        for _ in 0..<friesCount {
            let fries = createCollectable(texture: SKTexture(imageNamed: "fries.png"), physicsCategory: PhysicsCategory.fries)
            fries.name = "fries"
            fries.removeFromParent() // Ensure it's not in the scene
            friesPool.append(fries)
        }
    }
    
    func createCollectible(type: CollectibleType) -> SKSpriteNode {
        print("🎮 Creating collectible of type: \(type)")
        let collectible: SKSpriteNode
        switch type {
        case .coin:
            if let coin = coinPool.first {
                coinPool.removeFirst()
                collectible = coin
                activeCoins.append(coin)
            } else {
                let coinAtlas = SKTextureAtlas(named: "coin")
                let coinTexture = coinAtlas.textureNamed("coin_01")
                collectible = createCollectable(texture: coinTexture, physicsCategory: PhysicsCategory.coin)
                activeCoins.append(collectible)
            }
        case .burger:
            if let burger = burgerPool.first {
                burgerPool.removeFirst()
                collectible = burger
                activeBurgers.append(burger)
            } else {
                let texture = SKTexture(imageNamed: "burger")
                print("🍔 Creating burger with texture: \(texture.description)")
                collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.burger)
                activeBurgers.append(collectible)
            }
        case .pizza:
            if let pizza = pizzaPool.first {
                pizzaPool.removeFirst()
                collectible = pizza
                activePizzas.append(pizza)
            } else {
                let texture = SKTexture(imageNamed: "pizza")
                print("🍕 Creating pizza with texture: \(texture.description)")
                collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.pizza)
                activePizzas.append(collectible)
            }
        case .sushi:
            if let sushi = sushiPool.first {
                sushiPool.removeFirst()
                collectible = sushi
                activeSushis.append(sushi)
            } else {
                let texture = SKTexture(imageNamed: "sushi")
                print("🍣 Creating sushi with texture: \(texture.description)")
                collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.sushi)
                activeSushis.append(collectible)
            }
        case .fries:
            if let fries = friesPool.first {
                friesPool.removeFirst()
                collectible = fries
                activeFries.append(fries)
            } else {
                let texture = SKTexture(imageNamed: "fries")
                print("🍟 Creating fries with texture: \(texture.description)")
                collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.fries)
                activeFries.append(collectible)
            }
        }
        return collectible
    }
    
    func recycleCollectible(_ collectible: SKSpriteNode) {
        collectible.removeFromParent()
        resetCollectedState(collectible)
        
        if collectible.name == "burger" {
            if let index = activeBurgers.firstIndex(of: collectible) {
                activeBurgers.remove(at: index)
            }
            burgerPool.append(collectible)
        } else if collectible.name == "pizza" {
            if let index = activePizzas.firstIndex(of: collectible) {
                activePizzas.remove(at: index)
            }
            pizzaPool.append(collectible)
        } else if collectible.name == "sushi" {
            if let index = activeSushis.firstIndex(of: collectible) {
                activeSushis.remove(at: index)
            }
            sushiPool.append(collectible)
        } else if collectible.name == "fries" {
            if let index = activeFries.firstIndex(of: collectible) {
                activeFries.remove(at: index)
            }
            friesPool.append(collectible)
        } else {
            if let index = activeCoins.firstIndex(of: collectible) {
                activeCoins.remove(at: index)
            }
            coinPool.append(collectible)
        }
        
        // Reset physics body
        let radius = collectible.size.width/2
        collectible.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        collectible.physicsBody?.isDynamic = false
        collectible.physicsBody?.categoryBitMask = collectible.name == "burger" ? PhysicsCategory.burger : collectible.name == "pizza" ? PhysicsCategory.pizza : collectible.name == "sushi" ? PhysicsCategory.sushi : collectible.name == "fries" ? PhysicsCategory.fries : PhysicsCategory.coin
        collectible.physicsBody?.collisionBitMask = 0
        collectible.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        
        // Reset visual properties
        collectible.alpha = 1.0
        collectible.removeAllActions()
        
        if collectible.name == "coin" {
            // Restart coin animation
            setupCoinAnimation(for: collectible)
        }
    }

    private func createCollectable(
        texture: SKTexture,
        physicsCategory: UInt32
    ) -> SKSpriteNode {
        texture.filteringMode = .nearest
        print("🎨 Creating collectible with texture size: \(texture.size())")
        
        // Use GameConfig's adaptive sizing for consistent scaling
        let scaledSize = GameConfig.adaptiveSize(
            for: texture,
            baseSize: texture.size()
        )
        print("📏 Scaled size: \(scaledSize)")
        
        let sprite = SKSpriteNode(texture: texture, size: scaledSize)
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: scaledSize.width / 2)
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.categoryBitMask = physicsCategory
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        
        sprite.name = physicsCategory == PhysicsCategory.coin ? "coin" : physicsCategory == PhysicsCategory.burger ? "burger" : physicsCategory == PhysicsCategory.pizza ? "pizza" : physicsCategory == PhysicsCategory.sushi ? "sushi" : "fries"
        
        if physicsCategory == PhysicsCategory.coin {
            setupCoinAnimation(for: sprite)
        }
        
        return sprite
    }
    
    private func setupCoinAnimation(for coin: SKSpriteNode) {
        let coinAtlas = SKTextureAtlas(named: "coin")
        var frames: [SKTexture] = []
        
        // Load all frames from the coin atlas
        for i in 1...15 {
            let textureName = String(format: "coin_%02d", i)
            let texture = coinAtlas.textureNamed(textureName)
            texture.filteringMode = .nearest
            frames.append(texture)
        }
        
        // Create animation action at 30fps
        let spinAction = SKAction.animate(with: frames, timePerFrame: 1.0/30.0)
        let repeatSpin = SKAction.repeatForever(spinAction)
        coin.run(repeatSpin)
    }
}
