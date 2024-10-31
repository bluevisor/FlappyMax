//
//  GameScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var background1: SKSpriteNode!
    private var background2: SKSpriteNode!

    override func didMove(to view: SKView) {
        setupBackground()
    }

    private func setupBackground() {
        // Setting up two background nodes to create a continuous looping effect
        let colorTexture = SKColor(red: 50/255, green: 150/255, blue: 250/255, alpha: 1.0)

        background1 = SKSpriteNode(color: colorTexture, size: self.size)
        background1.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background1.position = CGPoint(x: frame.midX, y: frame.midY)
        background1.zPosition = -10
        addChild(background1)

        background2 = SKSpriteNode(color: colorTexture, size: self.size)
        background2.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background2.position = CGPoint(x: background1.size.width + frame.midX, y: frame.midY)
        background2.zPosition = -10
        addChild(background2)
    }

    override func update(_ currentTime: TimeInterval) {
        // Move both background layers to create a seamless scrolling effect
        moveLayer(layer: background1, speed: 10.0)
        moveLayer(layer: background2, speed: 10.0)
    }

    private func moveLayer(layer: SKSpriteNode, speed: CGFloat) {
        layer.position = CGPoint(x: layer.position.x - speed, y: layer.position.y)
        
        // Reset the layer position if it moves completely off-screen
        if layer.position.x <= -layer.size.width / 2 {
            layer.position.x += layer.size.width * 2
        }
    }
}


