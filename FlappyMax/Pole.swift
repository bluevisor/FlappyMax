//
//  Pole.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import GameplayKit

extension GameScene {
    internal func setupPoles() {
        print("Poles: Starting setup")
        for i in 0..<numberOfPolePairs {
            print("Creating  pole pair \(i)")
            let poleNode = createPolePair()
            let xPosition = frame.width + CGFloat(i) * poleSpacing
            poleNode.position = CGPoint(x: xPosition, y: 0)
            addChild(poleNode)
            polePairs.append(poleNode)
            print("Pole pair \(i) created at x: \(xPosition)")
        }
        print("Poles: Created \(polePairs.count) pairs")
    }

    internal func movePoles(speed: CGFloat) {
        guard !gameOver else { return }
        
        // First, sort the pole pairs by x position to ensure proper ordering
        let sortedPairs = polePairs.sorted { $0.position.x < $1.position.x }
        
        for polePair in polePairs {
            polePair.position.x -= speed

            if polePair.position.x < -polePair.calculateAccumulatedFrame().width {
                // Remove old obstacles
                for node in polePair.children {
                    if let spriteNode = node as? SKSpriteNode {
                        if let index = obstacles.firstIndex(of: spriteNode) {
                            obstacles.remove(at: index)
                        }
                    }
                }

                let topPole = polePair.children[0] as! SKSpriteNode
                let bottomPole = polePair.children[1] as! SKSpriteNode

                // Calculate new valid position using same logic as setup
                let poleHeight = topPole.size.height
                let gap = polePairGap
                
                let minCenter = GameConfig.Metrics.polePairMinY
                let maxCenter = GameConfig.Metrics.polePairMaxY
                
                let yPosition = CGFloat.random(
                    in: min(minCenter, maxCenter)...max(minCenter, maxCenter)
                )

                let halfGap = gap / 2
                topPole.position = CGPoint(x: 0, y: yPosition + halfGap + poleHeight/2)
                bottomPole.position = CGPoint(x: 0, y: yPosition - halfGap - poleHeight/2)

                // Update score zone
                let scoreZone = SKNode()
                scoreZone.position = CGPoint(x: 0, y: yPosition)
                scoreZone.name = "scoreZone"
                scoreZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: GameConfig.Metrics.scoreZoneWidth, height: gap))
                scoreZone.physicsBody?.isDynamic = false
                scoreZone.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
                scoreZone.physicsBody?.contactTestBitMask = PhysicsCategory.hero
                scoreZone.physicsBody?.collisionBitMask = 0

                if let existingScoreZone = polePair.children.last {
                    existingScoreZone.removeFromParent()
                }
                polePair.addChild(scoreZone)

                // Find the rightmost pole pair's position
                if let rightmostPair = sortedPairs.last {
                    // Place the recycled pole pair exactly one poleSpacing distance from the rightmost pair
                    polePair.position.x = rightmostPair.position.x + poleSpacing
                } else {
                    // Fallback if no other poles exist
                    polePair.position.x = frame.width + poleSpacing
                }

                obstacles.append(topPole)
                obstacles.append(bottomPole)
            }
        }
    }

    internal func createPolePair() -> SKNode {
        let polePair = SKNode()
        
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
        
        let bottomPole = SKSpriteNode(texture: poleTexture)
        bottomPole.size = scaledSize
        bottomPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let poleHeight = scaledSize.height
        let gap = polePairGap
        
        // Use GameConfig values for valid Y range
        let minCenter = GameConfig.Metrics.polePairMinY
        let maxCenter = GameConfig.Metrics.polePairMaxY
        
        // Generate a random y-position within the valid range
        let yPosition = CGFloat.random(
            in: min(minCenter, maxCenter)...max(minCenter, maxCenter)
        )
        
        // Position poles relative to the gap center
        let halfGap = gap / 2
        topPole.position = CGPoint(x: 0, y: yPosition + halfGap + poleHeight/2)
        bottomPole.position = CGPoint(x: 0, y: yPosition - halfGap - poleHeight/2)
        
        // Rest of pole setup...
        topPole.zPosition = 0
        bottomPole.zPosition = 0
        
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
        
        // Setup score zone
        let scoreZone = SKNode()
        scoreZone.position = CGPoint(x: 0, y: yPosition)
        scoreZone.name = "scoreZone"
        scoreZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: GameConfig.Metrics.scoreZoneWidth, height: gap))
        scoreZone.physicsBody?.isDynamic = false
        scoreZone.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
        scoreZone.physicsBody?.contactTestBitMask = PhysicsCategory.hero
        scoreZone.physicsBody?.collisionBitMask = 0
        
        polePair.addChild(topPole)
        polePair.addChild(bottomPole)
        polePair.addChild(scoreZone)
        
        // Add poles to obstacles array
        obstacles.append(topPole)
        obstacles.append(bottomPole)
        
        return polePair
    }
}
