//
//  Collectable.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit

extension GameScene {
    func setupCollectibles() {
        for i in 0..<(polePairs.count - 1) {
            let firstPolePair = polePairs[i]
            let secondPolePair = polePairs[i + 1]
            
            // Create a curved path between two adjacent pole pairs
            let curvePath = UtilityFunctions.createCurvePath(between: firstPolePair, and: secondPolePair)

            // Position a coin along this curve
            let coin = createCollectable(
                textureName: "coin_01.png",
                physicsCategory: PhysicsCategory.coin,
                animationFrames: 15,
                animationPrefix: "coin_",
                animationSpeed: GameConfig.Metrics.coinAnimationSpeed,
                spriteType: .coin
            )
            
            // Try multiple positions until we find a non-overlapping spot
            var attempts = 0
            var coinPlaced = false
            while attempts < 5 && !coinPlaced {
                UtilityFunctions.placeCollectableOnCurve(collectable: coin, curvePath: curvePath, deviation: 20.0)
                if !isOverlapping(collectable: coin) {
                    coinNodes.append(coin)
                    obstacles.append(coin)
                    addChild(coin)
                    coinPlaced = true
                }
                attempts += 1
            }

            // Set burger spawn frequency: every 5th pole pair
            if i % 5 == 0 {
                let burger = createCollectable(
                    textureName: "burger",
                    physicsCategory: PhysicsCategory.burger,
                    spriteType: .burger
                )
                
                attempts = 0
                var burgerPlaced = false
                
                while attempts < 5 && !burgerPlaced {
                    UtilityFunctions.placeCollectableOnCurve(collectable: burger, curvePath: curvePath, deviation: 30.0)
                    if !isOverlapping(collectable: burger) {
                        burgerNodes.append(burger)
                        obstacles.append(burger)
                        addChild(burger)
                        burgerPlaced = true
                    }
                    attempts += 1
                }
            }
        }
    }

    func createCollectable(
        textureName: String,
        physicsCategory: UInt32,
        animationFrames: Int = 0,
        animationPrefix: String = "",
        animationSpeed: TimeInterval = GameConfig.Metrics.coinAnimationSpeed,
        spriteType: SpriteType
    ) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: textureName)
        texture.filteringMode = .nearest
        
        let size = GameConfig.adaptiveSize(
            for: texture,
            spriteType: spriteType
        )
        
        let collectable = SKSpriteNode(texture: texture)
        collectable.size = size
        collectable.zPosition = 0
        
        collectable.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        collectable.physicsBody?.isDynamic = false
        collectable.physicsBody?.categoryBitMask = physicsCategory
        collectable.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        collectable.physicsBody?.collisionBitMask = 0

        if animationFrames > 0 {
            var frames: [SKTexture] = []
            for i in 1...animationFrames {
                let frameTexture = SKTexture(imageNamed: "\(animationPrefix)\(String(format: "%02d", i)).png")
                frameTexture.filteringMode = .nearest
                frames.append(frameTexture)
            }
            let animation = SKAction.repeatForever(
                SKAction.animate(with: frames, timePerFrame: animationSpeed)
            )
            collectable.run(animation)
        }

        return collectable
    }

    func moveCollectibles(speed: CGFloat) {
        guard !gameOver else { return }
        for collectable in coinNodes + burgerNodes {
            if collectable.parent != nil {
                collectable.position.x -= speed
            }

            if collectable.position.x < -collectable.size.width || collectable.parent == nil {
                resetCollectable(collectable)
            }
        }
    }

    private func resetCollectable(_ collectable: SKSpriteNode) {
        collectable.name = nil
        placeCollectable(collectable)
        
        if collectable.parent == nil {
            addChild(collectable)
        }
        
        if !obstacles.contains(collectable) {
            obstacles.append(collectable)
        }

        if collectable.physicsBody == nil {
            collectable.physicsBody = SKPhysicsBody(circleOfRadius: collectable.size.width / 2)
            collectable.physicsBody?.isDynamic = false
            collectable.physicsBody?.categoryBitMask = coinNodes.contains(collectable) ? PhysicsCategory.coin : PhysicsCategory.burger
            collectable.physicsBody?.contactTestBitMask = PhysicsCategory.hero
            collectable.physicsBody?.collisionBitMask = 0
        }
    }

    private func placeCollectable(_ collectable: SKSpriteNode) {
        var positionFound = false
        let minY = floorHeight + collectable.size.height / 2
        let maxY = frame.size.height - collectable.size.height / 2
        let collectableYRange = minY...maxY

        repeat {
            let xPosition = frame.width + CGFloat.random(
                in: GameConfig.Metrics.minRandomXPosition...GameConfig.Metrics.maxRandomXPosition
            )
            let yPosition = CGFloat.random(in: collectableYRange)
            collectable.position = CGPoint(x: xPosition, y: yPosition)

            positionFound = !isOverlapping(collectable: collectable)
        } while !positionFound
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
