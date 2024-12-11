//
//  Pole.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Pole obstacle management for FlappyMax
 
 Responsibilities:
 - Obstacle generation and positioning
 - Gap size and placement calculation
 - Physics body configuration
 - Memory management through recycling
 
 Features:
 - Dynamic pole pair generation
 - Configurable gap sizes and positions
 - Physics collision detection setup
 - Object pooling for performance
 - Position randomization algorithms
 - Smooth movement patterns
 - Screen boundary handling
 - Difficulty scaling support
 - Memory-efficient sprite recycling
 - Device-specific scaling
 */

import SpriteKit
import GameplayKit

class Pole {
    static let shared = Pole()
    private var polePool: [SKNode] = []
    
    private init() {}
    
    func initializePolePool(count: Int = 4) {
        // Initialize the pole pool with a set number of pole pairs
        for _ in 0..<count {
            let poleSet = createPoleSet()
            polePool.append(poleSet)
        }
    }
    
    func getPooledPoleSet() -> SKNode? {
        return polePool.isEmpty ? nil : polePool.removeFirst()
    }

    func recyclePoleSet(_ poleSet: SKNode) {
        poleSet.removeFromParent()
        // Reset score detector state and physics
        if let scoreDetector = poleSet.childNode(withName: "scoreDetector") {
            scoreDetector.userData = NSMutableDictionary()
            scoreDetector.userData?.setValue(false, forKey: "scored")
            
            // Recreate physics body
            let gap = GameConfig.scaled(GameConfig.Metrics.polePairGap)
            scoreDetector.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 5, height: gap), center: .zero)
            scoreDetector.physicsBody?.isDynamic = false
            scoreDetector.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
            scoreDetector.physicsBody?.contactTestBitMask = PhysicsCategory.hero
            scoreDetector.physicsBody?.collisionBitMask = 0
        }
        polePool.append(poleSet)
    }

    private func createPoleSet() -> SKNode {
        let poleSet = SKNode()
        poleSet.name = "poleSet"
        
        let poleTexture = SKTexture(imageNamed: "pole")
        poleTexture.filteringMode = .nearest
        
        // Use adaptive sizing for poles with type-specific scaling
        let scaledSize = GameConfig.adaptiveSize(
            for: poleTexture,
            spriteType: .pole
        )
        
        let topPole = SKSpriteNode(texture: poleTexture)
        topPole.size = scaledSize
        topPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        topPole.zRotation = CGFloat.pi
        topPole.xScale = -1.0
        topPole.name = "pole"
        
        let bottomPole = SKSpriteNode(texture: poleTexture)
        bottomPole.size = scaledSize
        bottomPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bottomPole.name = "pole"
        
        // Create physics bodies
        topPole.physicsBody = SKPhysicsBody(texture: poleTexture, size: scaledSize)
        topPole.physicsBody?.isDynamic = false
        topPole.physicsBody?.categoryBitMask = PhysicsCategory.pole
        topPole.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        topPole.physicsBody?.collisionBitMask = PhysicsCategory.hero
        
        bottomPole.physicsBody = SKPhysicsBody(texture: poleTexture, size: scaledSize)
        bottomPole.physicsBody?.isDynamic = false
        bottomPole.physicsBody?.categoryBitMask = PhysicsCategory.pole
        bottomPole.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        bottomPole.physicsBody?.collisionBitMask = PhysicsCategory.hero
        
        // Position poles
        let gap = GameConfig.scaled(GameConfig.Metrics.polePairGap)
        topPole.position = CGPoint(x: 0, y: gap/2 + topPole.size.height/2)
        bottomPole.position = CGPoint(x: 0, y: -gap/2 - bottomPole.size.height/2)
        
        // Setup score detector in the middle of the gap
        let scoreDetector = SKNode()
        scoreDetector.name = "scoreDetector"
        // Make the score detector tall enough to catch the hero
        let scoreDetectorWidth = CGFloat(5)
        scoreDetector.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: scoreDetectorWidth, height: gap), center: .zero)
        scoreDetector.physicsBody?.isDynamic = false
        scoreDetector.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
        scoreDetector.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        scoreDetector.physicsBody?.collisionBitMask = 0
        scoreDetector.userData = NSMutableDictionary()
        scoreDetector.userData?.setValue(false, forKey: "scored")
        
        // Position score detector in the gap
        scoreDetector.position = CGPoint(
            x: topPole.size.width/2,
            y: 0
        )
        
        poleSet.addChild(topPole)
        poleSet.addChild(bottomPole)
        poleSet.addChild(scoreDetector)
        
        return poleSet
    }
}
