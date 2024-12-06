//
//  Collectable.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import GameplayKit

extension GameScene {
    // ::HELPER:: Returns polePairs sorted by their x position
    func sortedPolePairs() -> [SKNode] {
        return polePairs.sorted { $0.position.x < $1.position.x }
    }

    // ::HELPER:: Returns consecutive pairs of poles as tuples (leftPair, rightPair)
    func consecutivePolePairs() -> [(SKNode, SKNode)] {
        return cachedSortedPairs
    }
    
    // Updates the cached pairs - should be called once per frame
    func updateConsecutivePolePairs() {
        let sorted = sortedPolePairs()
        guard sorted.count >= 2 else {
            print("Warning: Not enough pole pairs to update cachedSortedPairs")
            cachedSortedPairs = []
            return
        }
        print("Updating cachedSortedPairs with sorted pole pairs: \(sorted)")
        
        var pairs = [(SKNode, SKNode)]()
        for i in 0..<(sorted.count - 1) {
            pairs.append((sorted[i], sorted[i+1]))
        }
        print("Updating cachedSortedPairs with \(pairs.count) pairs")
        cachedSortedPairs = pairs
        print("Cached sorted pairs updated: \(cachedSortedPairs)")
    }

    func setupCollectibles() {
        print("Collectables: Starting setup")
        updateConsecutivePolePairs()  // Update the cached pairs first
        let allPairs = consecutivePolePairs()
        print("Collectables: Found \(allPairs.count) pole pairs")
        
        if allPairs.isEmpty {
            print("Warning: No pole pairs found for collectible placement")
            return
        }
        
        for (i, pair) in allPairs.enumerated() {
            let (firstPolePair, secondPolePair) = pair
            print("Processing pair \(i): first pole at \(firstPolePair.position), second pole at \(secondPolePair.position)")
            
            // Calculate a position between the pole pairs
            let xPosition = (firstPolePair.position.x + secondPolePair.position.x) * 0.5
            let yRange = GameConfig.Metrics.polePairMinY...GameConfig.Metrics.polePairMaxY
            
            // Try multiple positions for coin placement to avoid overlap
            var coinPlaced = false
            var attempts = 0
            let maxAttempts = 5
            
            while !coinPlaced && attempts < maxAttempts {
                let yPosition = CGFloat.random(in: yRange)
                print("Attempting to place coin at: x: \(xPosition), y: \(yPosition)")
                
                let testPoint = CGPoint(x: xPosition, y: yPosition)
                let existingNodes = self.nodes(at: testPoint).filter { node in
                    node.physicsBody?.categoryBitMask == PhysicsCategory.coin ||
                    node.physicsBody?.categoryBitMask == PhysicsCategory.burger
                }
                
                if existingNodes.isEmpty {
                    // Create and position a coin
                    let coin = createCollectable(
                        textureName: "coin_01.png",
                        physicsCategory: PhysicsCategory.coin,
                        at: CGPoint(x: xPosition, y: yPosition)
                    )
                    coinNodes.append(coin)
                    obstacles.append(coin)
                    addChild(coin)
                    coinPlaced = true
                    print("Successfully placed coin at attempt \(attempts + 1)")
                } else {
                    attempts += 1
                    print("Collision detected at attempt \(attempts), trying new position")
                }
            }
            
            // Set burger spawn frequency: 50% chance every 3rd pole pair
            if i % 3 == 0 && Double.random(in: 0...1) < 0.5 {
                var burgerPlaced = false
                attempts = 0
                
                while !burgerPlaced && attempts < maxAttempts {
                    let burgerYPosition = CGFloat.random(in: yRange)
                    print("Attempting to place burger at: x: \(xPosition), y: \(burgerYPosition)")
                    
                    let testPoint = CGPoint(x: xPosition, y: burgerYPosition)
                    let existingNodes = self.nodes(at: testPoint).filter { node in
                        node.physicsBody?.categoryBitMask == PhysicsCategory.coin ||
                        node.physicsBody?.categoryBitMask == PhysicsCategory.burger
                    }
                    
                    if existingNodes.isEmpty {
                        let burger = createCollectable(
                            textureName: "burger",
                            physicsCategory: PhysicsCategory.burger,
                            at: CGPoint(x: xPosition, y: burgerYPosition)
                        )
                        burgerNodes.append(burger)
                        obstacles.append(burger)
                        addChild(burger)
                        burgerPlaced = true
                        print("Successfully placed burger at attempt \(attempts + 1)")
                    } else {
                        attempts += 1
                        print("Collision detected at attempt \(attempts), trying new position")
                    }
                }
            }
        }
        print("Collectables setup complete. Created \(coinNodes.count) coins and \(burgerNodes.count) burgers")
    }

    func createCollectable(
        textureName: String,
        physicsCategory: UInt32,
        at position: CGPoint
    ) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: textureName)
        texture.filteringMode = .nearest
        
        let scale = (physicsCategory == PhysicsCategory.coin) ? GameConfig.Scales.coin : GameConfig.Scales.burger
        let size = CGSize(
            width: texture.size().width * scale,
            height: texture.size().height * scale
        )

        let sprite = SKSpriteNode(texture: texture, size: size)
        sprite.position = position
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.categoryBitMask = physicsCategory
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.hero

        sprite.name = physicsCategory == PhysicsCategory.coin ? "coin" : "burger"
        
        if physicsCategory == PhysicsCategory.coin {
            var frames: [SKTexture] = []
            for i in 1...15 {
                let frameTexture = SKTexture(imageNamed: String(format: "coin_%02d.png", i))
                frameTexture.filteringMode = .nearest
                frames.append(frameTexture)
            }
            let animation = SKAction.repeatForever(
                SKAction.animate(with: frames, timePerFrame: GameConfig.Metrics.coinAnimationSpeed)
            )
            sprite.run(animation)
        }
        
        return sprite
    }

    func moveCollectibles(speed: CGFloat) {
        guard !gameOver else { return }

        // Move existing collectibles
        for collectable in coinNodes + burgerNodes {
            if collectable.parent != nil {
                collectable.position.x -= speed
                if collectable.position.x < (-collectable.size.width / 2) {
                    collectable.removeFromParent()
                }
            }
        }

        // Use the cached pairs
        let pairs = consecutivePolePairs()
        guard !pairs.isEmpty else { return }

        // Find the rightmost visible pair
        guard let visiblePair = pairs.last(where: { $0.1.position.x < frame.width * 2 }) else { return }

        let (leftPair, rightPair) = visiblePair
        
        // Calculate the exact center point between the pole pairs
        let gapCenterX = (leftPair.position.x + rightPair.position.x) / 2

        // Define a tolerance for what we consider "in the gap"
        let gapTolerance = poleSpacing * 0.1 // 10% of pole spacing

        // Check if there's any collectible in this gap, using a more precise tolerance
        let collectiblesInGap = (coinNodes + burgerNodes).filter { node in
            node.parent != nil &&
            abs(node.position.x - gapCenterX) < gapTolerance
        }

        if collectiblesInGap.isEmpty {
            // Place a coin if available, exactly at the center
            if let coin = coinNodes.first(where: { $0.parent == nil }) {
                coin.position = CGPoint(
                    x: gapCenterX,
                    y: CGFloat.random(in: GameConfig.Metrics.polePairMinY...GameConfig.Metrics.polePairMaxY)
                )
                addChild(coin)
            }

            // Place a burger every 5th pair, exactly at the center
            let sorted = sortedPolePairs()
            if let rightPairIndex = sorted.firstIndex(of: rightPair) {
                if rightPairIndex % 5 == 0 {
                    if let burger = burgerNodes.first(where: { $0.parent == nil }) {
                        burger.position = CGPoint(
                            x: gapCenterX,
                            y: CGFloat.random(in: GameConfig.Metrics.polePairMinY...GameConfig.Metrics.polePairMaxY)
                        )
                        addChild(burger)
                    }
                }
            }
        }
    }

    private func placeCollectable(_ collectable: SKSpriteNode) {
        let allPairs = consecutivePolePairs()
        guard !allPairs.isEmpty else { return }
        
        // Use the two rightmost pole pairs
        let (rightmostPair, secondRightmostPair) = (allPairs[allPairs.count - 1].1, allPairs[allPairs.count - 1].0)
        
        // Use the same positioning logic as initial setup
        let distance = abs(secondRightmostPair.position.x - rightmostPair.position.x)
        let xOffset = distance * 0.5 // Exactly halfway between poles
        let xPosition = rightmostPair.position.x + xOffset
        let yRange = GameConfig.Metrics.polePairMinY...GameConfig.Metrics.polePairMaxY
        let yPosition = CGFloat.random(in: yRange)
        
        collectable.position = CGPoint(x: xPosition, y: yPosition)
    }

    private func isOverlapping(collectable: SKSpriteNode) -> Bool {
        // Check overlap with poles
        for polePair in polePairs {
            if abs(collectable.position.x - polePair.position.x) < minDistanceFromPole {
                return true
            }
        }
        
        // Check overlap with other collectibles
        for other in coinNodes + burgerNodes {
            if other != collectable && collectable.frame.intersects(other.frame) {
                return true
            }
        }
        
        return false
    }
}
