//
//  GameScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

//
//  GameScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // Game Configuration Constants
    private let gravity: CGFloat = -5.0
    private let backgroundColorValue = SKColor(red: 50/255, green: 150/255, blue: 250/255, alpha: 1.0)
    private let backgroundSpeed: CGFloat = 5.0
    private let floorSpeed: CGFloat = 8.0
    private let poleSpeed: CGFloat = 8.0
    private let heroScale: CGFloat = 2.0
    private let floorScale: CGFloat = 8.0
    private let numberOfPolePairs = 2
    private let poleScale: CGFloat = 6.0
    private let poleSpacing: CGFloat = 800.0 // Adjust this value as needed
    private var polePairGap: CGFloat = 250.0
    private let coinScale: CGFloat = 0.8
    private let burgerScale: CGFloat = 3.0
    private let numberOfCoins = 5
    private let numberOfBurgers = 2
    private let flapImpulse: CGFloat = 100.0
    private let coinAnimationSpeed: TimeInterval = 1/30

    // Game Nodes
    private var background1: SKSpriteNode!
    private var background2: SKSpriteNode!
    private var hero: SKSpriteNode!
    private var coinNodes: [SKSpriteNode] = []
    private var burgerNodes: [SKSpriteNode] = []
    private var floorNodes: [SKSpriteNode] = []
    private var polePairs: [SKNode] = []
    private var obstacles: [SKSpriteNode] = []

    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gravity)

        setupBackground()
        setupHero()
        setupFloor()
        setupPoles()
        setupCollectibles()
    }

    private func setupBackground() {
        // Setting up two background nodes to create a continuous looping effect
        background1 = SKSpriteNode(color: backgroundColorValue, size: self.size)
        background1.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background1.position = CGPoint(x: frame.midX, y: frame.midY)
        background1.zPosition = -10
        addChild(background1)

        background2 = SKSpriteNode(color: backgroundColorValue, size: self.size)
        background2.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background2.position = CGPoint(x: background1.size.width + frame.midX, y: frame.midY)
        background2.zPosition = -10
        addChild(background2)
    }

    private func setupHero() {
        let heroTexture = SKTexture(imageNamed: "max")
        heroTexture.filteringMode = .nearest
        hero = SKSpriteNode(texture: heroTexture)
        hero.position = CGPoint(x: frame.midX / 2, y: frame.midY)
        hero.zPosition = 1
        hero.size = CGSize(width: heroTexture.size().width * heroScale, height: heroTexture.size().height * heroScale)
        hero.physicsBody = SKPhysicsBody(texture: heroTexture, size: hero.size)
        hero.physicsBody?.isDynamic = true
        hero.physicsBody?.affectedByGravity = true
        addChild(hero)
    }

    private func setupFloor() {
        let floorTexture = SKTexture(imageNamed: "floor")
        floorTexture.filteringMode = .nearest
        let numberOfFloors = Int(ceil(frame.size.width / (floorTexture.size().width * floorScale))) + 1
        for i in 0..<numberOfFloors {
            let floor = SKSpriteNode(texture: floorTexture)
            floor.size = CGSize(width: floorTexture.size().width * floorScale, height: floorTexture.size().height * floorScale)
            floor.anchorPoint = CGPoint(x: 0, y: 0)
            floor.position = CGPoint(x: CGFloat(i) * floor.size.width, y: frame.minY)
            floor.zPosition = 0
            floor.physicsBody = SKPhysicsBody(rectangleOf: floor.size, center: CGPoint(x: floor.size.width / 2, y: floor.size.height / 2))
            floor.physicsBody?.isDynamic = false
            addChild(floor)
            floorNodes.append(floor)
            obstacles.append(floor)
        }
    }

    private func setupPoles() {
        for i in 0..<numberOfPolePairs {
            let polePair = SKNode()

            let topPoleTexture = SKTexture(imageNamed: "pole")
            topPoleTexture.filteringMode = .nearest

            let bottomPoleTexture = SKTexture(imageNamed: "pole")
            bottomPoleTexture.filteringMode = .nearest

            // Set up poles to mirror each other
            let scaledSize = CGSize(
                width: topPoleTexture.size().width * poleScale,
                height: topPoleTexture.size().height * poleScale
            )

            let topPole = SKSpriteNode(texture: topPoleTexture)
            topPole.size = scaledSize
            topPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            topPole.zRotation = CGFloat.pi

            let bottomPole = SKSpriteNode(texture: bottomPoleTexture)
            bottomPole.size = scaledSize
            bottomPole.anchorPoint = CGPoint(x: 0.5, y: 0.5)

            let maxY = frame.height / 2 + polePairGap
            let minY = frame.height / 2 - polePairGap
            let yPosition = CGFloat.random(in: minY...maxY)

            topPole.position = CGPoint(x: 0, y: yPosition + polePairGap / 2 + scaledSize.height / 2)
            bottomPole.position = CGPoint(x: 0, y: yPosition - polePairGap / 2 - scaledSize.height / 2)

            topPole.zPosition = 0
            bottomPole.zPosition = 0

            // Create physics bodies with the scaled size
            topPole.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
            topPole.physicsBody?.isDynamic = false
            topPole.physicsBody?.affectedByGravity = false

            bottomPole.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
            bottomPole.physicsBody?.isDynamic = false
            bottomPole.physicsBody?.affectedByGravity = false

            polePair.addChild(topPole)
            polePair.addChild(bottomPole)

            // Position each pole pair with equal spacing
            let xPosition = frame.maxX + CGFloat(i) * poleSpacing
            polePair.position = CGPoint(x: xPosition, y: 0)
            polePair.zPosition = 0

            addChild(polePair)
            polePairs.append(polePair)

            obstacles.append(topPole)
            obstacles.append(bottomPole)
        }
    }

    private func setupCollectibles() {
        for _ in 1...numberOfCoins {
            let coinTexture = SKTexture(imageNamed: "coin_01.png")
            coinTexture.filteringMode = .nearest
            let coin = SKSpriteNode(texture: coinTexture)
            coin.size = CGSize(width: coinTexture.size().width * coinScale, height: coinTexture.size().height * coinScale)

            var positionFound = false
            var coinPosition: CGPoint = .zero
            let minY = floorNodes.first!.size.height + coin.size.height / 2
            let maxY = frame.size.height - coin.size.height / 2
            let coinYRange = minY...maxY

            repeat {
                coinPosition = CGPoint(x: frame.maxX + CGFloat.random(in: 200...400), y: CGFloat.random(in: coinYRange))
                coin.position = coinPosition
                var overlap = false
                for obstacle in obstacles {
                    if coin.frame.intersects(obstacle.frame) {
                        overlap = true
                        break
                    }
                }
                if !overlap {
                    positionFound = true
                }
            } while !positionFound

            coin.zPosition = 0
            coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2 - 5)
            coin.physicsBody?.isDynamic = false

            // Create the coin animation using the atlas frames
            var coinFrames: [SKTexture] = []
            for i in 1...15 {
                let frameTexture = SKTexture(imageNamed: "coin_\(String(format: "%02d", i)).png")
                frameTexture.filteringMode = .nearest
                coinFrames.append(frameTexture)
            }
            let coinAnimation = SKAction.repeatForever(SKAction.animate(with: coinFrames, timePerFrame: coinAnimationSpeed))
            coin.run(coinAnimation)

            addChild(coin)
            coinNodes.append(coin)
            obstacles.append(coin)
        }

        for _ in 1...numberOfBurgers {
            let burgerTexture = SKTexture(imageNamed: "burger")
            burgerTexture.filteringMode = .nearest
            let burger = SKSpriteNode(texture: burgerTexture)
            burger.size = CGSize(width: burgerTexture.size().width * burgerScale, height: burgerTexture.size().height * burgerScale)

            var positionFound = false
            var burgerPosition: CGPoint = .zero
            let minY = floorNodes.first!.size.height + burger.size.height / 2
            let maxY = frame.size.height - burger.size.height / 2
            let burgerYRange = minY...maxY

            repeat {
                burgerPosition = CGPoint(x: frame.maxX + CGFloat.random(in: 200...600), y: CGFloat.random(in: burgerYRange))
                burger.position = burgerPosition
                var overlap = false
                for obstacle in obstacles {
                    if burger.frame.intersects(obstacle.frame) {
                        overlap = true
                        break
                    }
                }
                if !overlap {
                    positionFound = true
                }
            } while !positionFound

            burger.zPosition = 0
            burger.physicsBody = SKPhysicsBody(circleOfRadius: burger.size.width / 2)
            burger.physicsBody?.isDynamic = false

            addChild(burger)
            burgerNodes.append(burger)
            obstacles.append(burger)
        }
    }

    private func movePoles(speed: CGFloat) {
        for polePair in polePairs {
            polePair.position = CGPoint(x: polePair.position.x - speed, y: polePair.position.y)

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

                // Find the maximum x-position among all pole pairs
                let maxX = polePairs.map { $0.position.x }.max() ?? frame.maxX

                // Update positions of top and bottom poles
                let topPole = polePair.children[0] as! SKSpriteNode
                let bottomPole = polePair.children[1] as! SKSpriteNode

                let maxY = frame.height / 2 + polePairGap
                let minY = frame.height / 2 - polePairGap
                let yPosition = CGFloat.random(in: minY...maxY)

                topPole.position = CGPoint(x: 0, y: yPosition + polePairGap / 2 + topPole.size.height / 2)
                bottomPole.position = CGPoint(x: 0, y: yPosition - polePairGap / 2 - bottomPole.size.height / 2)

                // Set new x-position with spacing
                polePair.position.x = maxX + poleSpacing

                // Add back to obstacles
                obstacles.append(topPole)
                obstacles.append(bottomPole)
            }
        }

        // Move collectibles at the same speed as poles
        moveCollectibles(speed: speed)
    }

    private func moveCollectibles(speed: CGFloat) {
        for coin in coinNodes {
            coin.position = CGPoint(x: coin.position.x - speed, y: coin.position.y)

            // Reset coin position if it moves off-screen
            if coin.position.x < -coin.size.width {
                if let index = obstacles.firstIndex(of: coin) {
                    obstacles.remove(at: index)
                }

                var positionFound = false
                var coinPosition: CGPoint = .zero
                let minY = floorNodes.first!.size.height + coin.size.height / 2
                let maxY = frame.size.height - coin.size.height / 2
                let coinYRange = minY...maxY

                repeat {
                    coinPosition = CGPoint(x: frame.maxX + CGFloat.random(in: 200...400), y: CGFloat.random(in: coinYRange))
                    coin.position = coinPosition
                    var overlap = false
                    for obstacle in obstacles {
                        if coin.frame.intersects(obstacle.frame) {
                            overlap = true
                            break
                        }
                    }
                    if !overlap {
                        positionFound = true
                    }
                } while !positionFound

                obstacles.append(coin)
            }
        }

        for burger in burgerNodes {
            burger.position = CGPoint(x: burger.position.x - speed, y: burger.position.y)

            // Reset burger position if it moves off-screen
            if burger.position.x < -burger.size.width {
                if let index = obstacles.firstIndex(of: burger) {
                    obstacles.remove(at: index)
                }

                var positionFound = false
                var burgerPosition: CGPoint = .zero
                let minY = floorNodes.first!.size.height + burger.size.height / 2
                let maxY = frame.size.height - burger.size.height / 2
                let burgerYRange = minY...maxY

                repeat {
                    burgerPosition = CGPoint(x: frame.maxX + CGFloat.random(in: 200...600), y: CGFloat.random(in: burgerYRange))
                    burger.position = burgerPosition
                    var overlap = false
                    for obstacle in obstacles {
                        if burger.frame.intersects(obstacle.frame) {
                            overlap = true
                            break
                        }
                    }
                    if !overlap {
                        positionFound = true
                    }
                } while !positionFound

                obstacles.append(burger)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Move background layers
        moveLayer(layer: background1, speed: backgroundSpeed)
        moveLayer(layer: background2, speed: backgroundSpeed)
        // Move floor
        moveFloor(speed: floorSpeed)
        // Move poles
        movePoles(speed: poleSpeed)
    }

    private func moveLayer(layer: SKSpriteNode, speed: CGFloat) {
        layer.position = CGPoint(x: layer.position.x - speed, y: layer.position.y)

        // Reset the layer position if it moves completely off-screen
        if layer.position.x <= -layer.size.width / 2 {
            layer.position.x += layer.size.width * 2
        }
    }

    private func moveFloor(speed: CGFloat) {
        for floor in floorNodes {
            floor.position = CGPoint(x: floor.position.x - speed, y: floor.position.y)

            // Reset floor position if it moves off-screen
            if floor.position.x <= -floor.size.width {
                floor.position.x += floor.size.width * CGFloat(floorNodes.count)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: flapImpulse))
    }
}
