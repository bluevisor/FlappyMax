//
//  Pole.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit

extension GameScene {
    func setupPoles() {
        for i in 0..<numberOfPolePairs {
            let polePair = SKNode()

            let poleTexture = SKTexture(imageNamed: "pole")
            poleTexture.filteringMode = .nearest

            // Set up poles to mirror each other
            let scaledSize = CGSize(
                width: poleTexture.size().width * poleTextureScale,
                height: poleTexture.size().height * poleTextureScale
            )

            let topPole = SKSpriteNode(texture: poleTexture)
            topPole.size = scaledSize
            topPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            topPole.zRotation = CGFloat.pi

            let bottomPole = SKSpriteNode(texture: poleTexture)
            bottomPole.size = scaledSize
            bottomPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bottomPole.physicsBody?.categoryBitMask = PhysicsCategory.pole
            let maxY = frame.height - polePairGap / 2
            let minY = (floorNodes.first?.size.height ?? 80) * 2 + (polePairGap / 2)
            let yPosition = CGFloat.random(in: minY...maxY)

            topPole.position = CGPoint(x: 0, y: yPosition + polePairGap / 2 + scaledSize.height / 2)
            bottomPole.position = CGPoint(x: 0, y: yPosition - polePairGap / 2 - scaledSize.height / 2)

            topPole.zPosition = 0
            bottomPole.zPosition = 0

            // Create physics bodies with the scaled size
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

            let scoreZone = SKNode()
            scoreZone.position = CGPoint(x: 0, y: yPosition)
            scoreZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: polePairGap))
            scoreZone.physicsBody?.isDynamic = false
            scoreZone.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
            scoreZone.physicsBody?.contactTestBitMask = PhysicsCategory.hero
            scoreZone.physicsBody?.collisionBitMask = 0
            
            polePair.addChild(topPole)
            polePair.addChild(bottomPole)
            polePair.addChild(scoreZone)

            // Position each pole pair with equal spacing
            let xPosition = frame.width + CGFloat(i) * poleSpacing
            polePair.position = CGPoint(x: xPosition, y: 0)
            polePair.zPosition = 0
            addChild(polePair)
            polePairs.append(polePair)

            obstacles.append(topPole)
            obstacles.append(bottomPole)
        }
    }

    func movePoles(speed: CGFloat) {
        guard !gameOver else { return }
        for polePair in polePairs {
            polePair.position.x -= speed

            // Reset pole position if it moves off-screen
            if polePair.position.x < -polePair.calculateAccumulatedFrame().width {
                // Remove old obstacles
                for node in polePair.children {
                    if let spriteNode = node as? SKSpriteNode {
                        if let index = obstacles.firstIndex(of: spriteNode) {
                            obstacles.remove(at: index)
                        }
                    }
                }

                // Update positions of top and bottom poles
                let topPole = polePair.children[0] as! SKSpriteNode
                let bottomPole = polePair.children[1] as! SKSpriteNode

                let maxY = frame.height - polePairGap / 2
                let minY = (floorNodes.first?.size.height ?? 80) * 2 + (polePairGap / 2)
                let yPosition = CGFloat.random(in: minY...maxY)

                topPole.position = CGPoint(x: 0, y: yPosition + polePairGap / 2 + topPole.size.height / 2)
                bottomPole.position = CGPoint(x: 0, y: yPosition - polePairGap / 2 - bottomPole.size.height / 2)

                // Recreate and update scoreZone position
                let scoreZone = SKNode()
                scoreZone.position = CGPoint(x: 0, y: yPosition)
                scoreZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: polePairGap))
                scoreZone.physicsBody?.isDynamic = false
                scoreZone.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
                scoreZone.physicsBody?.contactTestBitMask = PhysicsCategory.hero
                scoreZone.physicsBody?.collisionBitMask = 0

                // Remove any existing scoreZone and add the new one
                if let existingScoreZone = polePair.children.last {
                    existingScoreZone.removeFromParent()
                }
                polePair.addChild(scoreZone)

                // Set new x-position with spacing
                let maxXPosition = polePairs.max(by: { $0.position.x < $1.position.x })?.position.x ?? frame.width
                polePair.position.x = maxXPosition + poleSpacing

                // Add back to obstacles
                obstacles.append(topPole)
                obstacles.append(bottomPole)
            }
        }
    }
}
