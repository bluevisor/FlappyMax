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
        #if DEBUG
        print("[Collectable] - markAsCollected() called for node: \(node)")
        #endif
        objc_setAssociatedObject(node, collectedKey, true, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func isCollected(_ node: SKSpriteNode) -> Bool {
        #if DEBUG
        print("[Collectable] - isCollected() called for node: \(node)")
        #endif
        return (objc_getAssociatedObject(node, collectedKey) as? Bool) ?? false
    }
    
    func resetCollectedState(_ node: SKSpriteNode) {
        #if DEBUG
        print("[Collectable] - resetCollectedState() called for node: \(node)")
        #endif
        objc_setAssociatedObject(node, collectedKey, nil, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func initializeCollectiblePool(coinCount: Int = 30, burgerCount: Int = 5, pizzaCount: Int = 5, sushiCount: Int = 5, friesCount: Int = 5) {
        #if DEBUG
        print("[Collectable] - initializeCollectiblePool() called with counts: coin: \(coinCount), burger: \(burgerCount), pizza: \(pizzaCount), sushi: \(sushiCount), fries: \(friesCount)")
        #endif
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
        #if DEBUG
        print("[Collectable] - createCollectible() called with type: \(type)")
        #endif
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
                #if DEBUG
                print("[Collectable] - 🍔 Creating burger with texture: \(texture.description)")
                #endif
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
                #if DEBUG
                print("[Collectable] - 🍕 Creating pizza - Texture exists: \(texture.size().width > 0), Size: \(texture.size())")
                #endif
                if texture.size().width == 0 {
                    #if DEBUG
                    print("[Collectable] - ⚠️ Failed to load pizza texture!")
                    #endif
                    // Fallback to burger texture for debugging
                    let fallbackTexture = SKTexture(imageNamed: "burger")
                    collectible = createCollectable(texture: fallbackTexture, physicsCategory: PhysicsCategory.pizza)
                } else {
                    collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.pizza)
                }
                activePizzas.append(collectible)
            }
        case .sushi:
            if let sushi = sushiPool.first {
                sushiPool.removeFirst()
                collectible = sushi
                activeSushis.append(sushi)
            } else {
                let texture = SKTexture(imageNamed: "sushi")
                #if DEBUG
                print("[Collectable] - 🍣 Creating sushi - Texture exists: \(texture.size().width > 0), Size: \(texture.size())")
                #endif
                if texture.size().width == 0 {
                    #if DEBUG
                    print("[Collectable] - ⚠️ Failed to load sushi texture!")
                    #endif
                    // Fallback to burger texture for debugging
                    let fallbackTexture = SKTexture(imageNamed: "burger")
                    collectible = createCollectable(texture: fallbackTexture, physicsCategory: PhysicsCategory.sushi)
                } else {
                    collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.sushi)
                }
                activeSushis.append(collectible)
            }
        case .fries:
            if let fries = friesPool.first {
                friesPool.removeFirst()
                collectible = fries
                activeFries.append(fries)
            } else {
                let texture = SKTexture(imageNamed: "fries")
                #if DEBUG
                print("[Collectable] - 🍟 Creating fries - Texture exists: \(texture.size().width > 0), Size: \(texture.size())")
                #endif
                if texture.size().width == 0 {
                    #if DEBUG
                    print("[Collectable] - ⚠️ Failed to load fries texture!")
                    #endif
                    // Fallback to burger texture for debugging
                    let fallbackTexture = SKTexture(imageNamed: "burger")
                    collectible = createCollectable(texture: fallbackTexture, physicsCategory: PhysicsCategory.fries)
                } else {
                    collectible = createCollectable(texture: texture, physicsCategory: PhysicsCategory.fries)
                }
                activeFries.append(collectible)
            }
        }
        return collectible
    }
    
    func recycleCollectible(_ collectible: SKSpriteNode) {
        #if DEBUG
        print("[Collectable] - recycleCollectible() called with collectible: \(collectible)")
        #endif
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
        
        // Reset visual properties
        collectible.alpha = 1.0
        collectible.removeAllActions()
        
        if collectible.name == "coin" {
            // Restart coin animation
            setupCoinAnimation(for: collectible)
        }
    }

    private func createCollectable(texture: SKTexture, physicsCategory: UInt32) -> SKSpriteNode {
        #if DEBUG
        print("[Collectable] - createCollectable() called with texture: \(texture), physicsCategory: \(physicsCategory)")
        #endif
        let sprite = SKSpriteNode(texture: texture)
        
        // Set size based on type
        switch physicsCategory {
        case PhysicsCategory.coin:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .coin)
        case PhysicsCategory.burger:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .burger)
        case PhysicsCategory.pizza:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .pizza)
        case PhysicsCategory.sushi:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .sushi)
        case PhysicsCategory.fries:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .fries)
        default:
            sprite.size = GameConfig.adaptiveSize(for: texture, spriteType: .coin)
        }
        
        // Set up physics body AFTER setting the size
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.categoryBitMask = physicsCategory
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        sprite.physicsBody?.collisionBitMask = 0
        
        // Set name for identification
        sprite.name = physicsCategory == PhysicsCategory.coin ? "coin" : 
                     physicsCategory == PhysicsCategory.burger ? "burger" : 
                     physicsCategory == PhysicsCategory.pizza ? "pizza" : 
                     physicsCategory == PhysicsCategory.sushi ? "sushi" : "fries"
        
        // Set up coin animation if it's a coin
        if physicsCategory == PhysicsCategory.coin {
            setupCoinAnimation(for: sprite)
        }
        
        return sprite
    }
    
    private func setupCoinAnimation(for coin: SKSpriteNode) {
        #if DEBUG
        print("[Collectable] - setupCoinAnimation() called for coin: \(coin)")
        #endif
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
