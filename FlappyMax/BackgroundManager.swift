//
//  BackgroundManager.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit

class BackgroundManager {
    static let shared = BackgroundManager()

    // Store the background node here
    private(set) var backgroundNode: SKSpriteNode?

    private init() {}

    func createBackground(size: CGSize) -> SKSpriteNode {
        if let existingBackground = backgroundNode {
            existingBackground.removeFromParent()
            return existingBackground
        }

        // Generate the background gradient texture
        let gradientTexture = createGradientTexture(
            startColor: UIColor(hex: "#060606"),
            endColor: UIColor(hex: "#191919"),
            size: size
        )
        
        // Create and configure the background node
        let background = SKSpriteNode(texture: gradientTexture)
        background.size = size
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -10
        
        backgroundNode = background
        return background
    }

    private func createGradientTexture(startColor: UIColor, endColor: UIColor, size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let colors = [startColor.cgColor, endColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: colorLocations)!

        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
}
