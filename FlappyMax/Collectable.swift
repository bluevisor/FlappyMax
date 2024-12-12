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
}

class Collectable {
    static let shared = Collectable()
    
    // Make pools public for debug access
    var coinPool: [SKSpriteNode] = []
    var burgerPool: [SKSpriteNode] = []
    var activeCoins: [SKSpriteNode] = []
    var activeBurgers: [SKSpriteNode] = []
    
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
    
    func initializeCollectiblePool(coinCount: Int = 50, burgerCount: Int = 5) {
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
    }
    
    func createCollectible(type: CollectibleType) -> SKSpriteNode {
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
                collectible = createCollectable(texture: SKTexture(imageNamed: "burger.png"), physicsCategory: PhysicsCategory.burger)
                activeBurgers.append(collectible)
            }
        }
        return collectible
    }
    
    func recycleCollectible(_ collectible: SKSpriteNode) {
        collectible.removeFromParent()
        resetCollectedState(collectible)  // Reset the collected state
        
        if collectible.name == "burger" {
            if let index = activeBurgers.firstIndex(of: collectible) {
                activeBurgers.remove(at: index)
            }
            burgerPool.append(collectible)
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
        collectible.physicsBody?.categoryBitMask = collectible.name == "burger" ? PhysicsCategory.burger : PhysicsCategory.coin
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
        
        // Use GameConfig's adaptive sizing for consistent scaling
        let scaledSize = GameConfig.adaptiveSize(
            for: texture,
            spriteType: physicsCategory == PhysicsCategory.coin ? .coin : .burger
        )

        let sprite = SKSpriteNode(texture: texture, size: scaledSize)
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: scaledSize.width / 2)
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.categoryBitMask = physicsCategory
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        
        sprite.name = physicsCategory == PhysicsCategory.coin ? "coin" : "burger"
        
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
