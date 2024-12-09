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

class Collectable {
    static let shared = Collectable()
    private var coinPool: [SKSpriteNode] = []
    private var burgerPool: [SKSpriteNode] = []
    
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
            let coin = createCollectable(textureName: "coin_01", physicsCategory: PhysicsCategory.coin)
            coin.removeFromParent() // Ensure it's not in the scene
            coinPool.append(coin)
        }
        
        // Initialize burger pool
        for _ in 0..<burgerCount {
            let burger = createCollectable(textureName: "burger.png", physicsCategory: PhysicsCategory.burger)
            burger.name = "burger"
            burger.removeFromParent() // Ensure it's not in the scene
            burgerPool.append(burger)
        }
    }
    
    func getPooledCoin() -> SKSpriteNode? {
        if let coin = coinPool.first {
            coinPool.removeFirst()
            // Ensure coin is removed from any parent before reuse
            if coin.parent != nil {
                coin.removeFromParent()
            }
            
            // Reset collected state
            resetCollectedState(coin)
            coin.userData = nil
            coin.alpha = 1.0  // Reset visibility
            
            // Restart spinning animation using atlas
            coin.removeAllActions()
            let coinAtlas = SKTextureAtlas(named: "coin")
            var textures: [SKTexture] = []
            for i in 1...15 {
                let textureName = String(format: "coin_%02d", i)
                let texture = coinAtlas.textureNamed(textureName)
                texture.filteringMode = .nearest
                textures.append(texture)
            }
            let spinAction = SKAction.animate(with: textures, timePerFrame: 0.05)
            let repeatSpin = SKAction.repeatForever(spinAction)
            coin.run(repeatSpin)
            
            return coin
        }
        return nil
    }
    
    func getPooledBurger() -> SKSpriteNode? {
        if let burger = burgerPool.first {
            burgerPool.removeFirst()
            // Ensure burger is removed from any parent before reuse
            if burger.parent != nil {
                burger.removeFromParent()
            }
            resetCollectedState(burger)
            burger.userData = nil
            burger.alpha = 1.0  // Reset visibility
            return burger
        }
        return nil
    }
    
    func recycleCollectible(_ collectible: SKSpriteNode) {
        collectible.removeFromParent()
        resetCollectedState(collectible)  // Reset the collected state instead of marking as collected
        
        if collectible.name == "coin" {
            coinPool.append(collectible)
        } else if collectible.name == "burger" {
            burgerPool.append(collectible)
        }
    }

    private func createCollectable(
        textureName: String,
        physicsCategory: UInt32
    ) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: textureName)
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
        for i in 1...15 {
            let textureName = String(format: "coin_%02d", i)
            let texture = coinAtlas.textureNamed(textureName)
            texture.filteringMode = .nearest
            frames.append(texture)
        }
        
        let spinAction = SKAction.animate(with: frames, timePerFrame: 0.05)
        let repeatSpin = SKAction.repeatForever(spinAction)
        coin.run(repeatSpin)
    }
}
