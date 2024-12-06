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
                textureScale: coinTextureScale,
                physicsCategory: PhysicsCategory.coin,
                animationFrames: 15,
                animationPrefix: "coin_",
                animationSpeed: coinAnimationSpeed
            )
            UtilityFunctions.placeCollectableOnCurve(collectable: coin, curvePath: curvePath, deviation: 20.0)
            if !isOverlapping(collectable: coin) {
                coinNodes.append(coin)
                obstacles.append(coin)
            }

            // Position a burger along this curve
            let burger = BurgerCollectable(staminaReplenishment: 25.0)
            addChild(burger)  // Add burger to scene
            UtilityFunctions.placeCollectableOnCurve(collectable: burger, curvePath: curvePath, deviation: 20.0)
            if !isOverlapping(collectable: burger) {
                burgerNodes.append(burger)
                obstacles.append(burger)
            } else {
                burger.removeFromParent()  // Remove if overlapping
            }
        }
    }

    func createCollectable(
        textureName: String, 
        textureScale: CGFloat,
        physicsCategory: UInt32,
        animationFrames: Int = 0, 
        animationPrefix: String = "", 
        animationSpeed: TimeInterval = 0
    ) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: textureName)
        texture.filteringMode = .nearest
        let collectable = SKSpriteNode(texture: texture)
        collectable.size = CGSize(width: texture.size().width * textureScale, height: texture.size().height * textureScale)

        collectable.zPosition = 0
        collectable.physicsBody = SKPhysicsBody(circleOfRadius: collectable.size.width / 2)
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
            let animation = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: animationSpeed))
            collectable.run(animation)
        }

        addChild(collectable)
        placeCollectable(collectable: collectable)
        return collectable
    }

    func moveCollectibles(speed: CGFloat) {
        guard !gameOver else { return }
        for collectable in coinNodes + burgerNodes {
            // Move the collectable if it's in the scene
            if collectable.parent != nil {
                collectable.position.x -= speed
            }

            // Check if we need to reset the collectable
            if collectable.position.x < -collectable.size.width || collectable.parent == nil {
                // Reset position and add back to scene
                collectable.name = nil  // Clear collected state
                placeCollectable(collectable: collectable)
                
                if collectable.parent == nil {
                    addChild(collectable)
                }
                
                if !obstacles.contains(collectable) {
                    obstacles.append(collectable)
                }

                // Recreate physics body if needed
                if collectable.physicsBody == nil {
                    collectable.physicsBody = SKPhysicsBody(circleOfRadius: collectable.size.width / 2)
                    collectable.physicsBody?.isDynamic = false
                    
                    if coinNodes.contains(collectable) {
                        collectable.physicsBody?.categoryBitMask = PhysicsCategory.coin
                    } else if burgerNodes.contains(collectable) {
                        collectable.physicsBody?.categoryBitMask = PhysicsCategory.burger
                    }

                    collectable.physicsBody?.contactTestBitMask = PhysicsCategory.hero
                    collectable.physicsBody?.collisionBitMask = 0
                }
            }
        }
    }

    func placeCollectable(collectable: SKSpriteNode) {
        var positionFound = false
        let minY = floorNodes.first!.size.height + collectable.size.height / 2
        let maxY = frame.size.height - collectable.size.height / 2
        let collectableYRange = minY...maxY

        repeat {
            let xPosition = frame.width + CGFloat.random(in: minRandomXPosition...maxRandomXPosition)
            let yPosition = CGFloat.random(in: collectableYRange)
            collectable.position = CGPoint(x: xPosition, y: yPosition)

            var overlap = false

            for polePair in polePairs {
                let poleX = polePair.position.x
                if abs(collectable.position.x - poleX) < minDistanceFromPole {
                    overlap = true
                    break
                }
            }

            for existingCollectable in coinNodes + burgerNodes {
                if collectable != existingCollectable && collectable.frame.intersects(existingCollectable.frame) {
                    overlap = true
                    break
                }
            }

            if !overlap {
                positionFound = true
            }
        } while !positionFound
    }

    func isOverlapping(collectable: SKSpriteNode) -> Bool {
        for existingCollectable in coinNodes + burgerNodes {
            if collectable.frame.intersects(existingCollectable.frame) {
                return true
            }
        }
        return false
    }

    private func addDebugPoint(at position: CGPoint, color: UIColor) {
        let debugNode = SKShapeNode(circleOfRadius: 5)
        debugNode.position = position
        debugNode.fillColor = color
        debugNode.strokeColor = color
        debugNode.zPosition = 1001 // Place above the curve line for visibility
        addChild(debugNode)
    }
}

class BurgerCollectable: SKSpriteNode {
    let staminaReplenishment: CGFloat

    init(staminaReplenishment: CGFloat = 25.0) {
        self.staminaReplenishment = staminaReplenishment
        let texture = SKTexture(imageNamed: "burger")
        texture.filteringMode = .nearest  // Use nearest neighbor filtering
        // Make burger 4x bigger
        let size = CGSize(width: 80, height: 80)
        super.init(texture: texture, color: .clear, size: size)
        self.zPosition = 1  // Same as hero to be visible
        self.setupPhysics()
    }

    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.burger
        self.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        self.physicsBody?.collisionBitMask = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
