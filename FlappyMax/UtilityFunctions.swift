//
//  UtilityFunctions.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Utility functions for FlappyMax
 
 Responsibilities:
 - Common calculations
 - Random number generation
 - Device-specific utilities
 - Math helper functions
 - Resource management
 
 Features:
 - Random number generators
 - Device detection
 - Math utilities
 - Asset loading
 - String formatting
 - Date handling
 - Error checking
 - Type conversion
 - Path management
 - Performance optimization
 */

import SpriteKit

// Utility class for common game functions
class UtilityFunctions {
    static func createCurvePath(between firstPolePair: SKNode, and secondPolePair: SKNode) -> CGPath {
        let path = CGMutablePath()

        // Get the score zone positions which represent the gap between poles
        let firstScoreZone = firstPolePair.childNode(withName: "scoreZone")
        let secondScoreZone = secondPolePair.childNode(withName: "scoreZone")
        
        // Define starting and ending points for the curve using score zone positions
        let startPoint = CGPoint(
            x: firstPolePair.position.x,
            y: firstScoreZone?.position.y ?? firstPolePair.position.y
        )
        let endPoint = CGPoint(
            x: secondPolePair.position.x,
            y: secondScoreZone?.position.y ?? secondPolePair.position.y
        )

        // Calculate control points for the Bezier curve
        let controlPoint1 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: startPoint.y + 100)
        let controlPoint2 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: endPoint.y - 100)

        // Create the Bezier curve path
        path.move(to: startPoint)
        path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)

        return path
    }

    // Helper function to check if a point is too close to poles
    static func isTooCloseToObstacles(point: CGPoint, polePair: SKNode, minDistance: CGFloat) -> Bool {
        // Check distance from top and bottom poles
        if let topPole = polePair.children.first(where: { $0 is SKSpriteNode }) as? SKSpriteNode,
           let bottomPole = polePair.children.dropFirst().first(where: { $0 is SKSpriteNode }) as? SKSpriteNode {
            let topPoleBottom = topPole.position.y - topPole.size.height/2
            let bottomPoleTop = bottomPole.position.y + bottomPole.size.height/2
            
            // Check vertical distance from poles
            if point.y > topPoleBottom - minDistance || point.y < bottomPoleTop + minDistance {
                return true
            }
            
            // Check horizontal distance from poles
            let poleX = polePair.position.x
            if abs(point.x - poleX) < minDistance {
                return true
            }
        }
        return false
    }
    
    // Helper function to check if a point is too close to other collectibles
    static func isTooCloseToCollectibles(point: CGPoint, collectibles: [SKSpriteNode], minDistance: CGFloat) -> Bool {
        for collectible in collectibles {
            if collectible.name == "collected" { continue }  // Skip collected items
            let distance = hypot(point.x - collectible.position.x, point.y - collectible.position.y)
            if distance < minDistance {
                return true
            }
        }
        return false
    }
    
    static func findSafePosition(
        curvePath: CGPath,
        polePairs: [SKNode],
        collectibles: [SKSpriteNode],
        collectibleSize: CGSize,
        minDistanceFromPoles: CGFloat = 100,
        minDistanceBetweenCollectibles: CGFloat = 80
    ) -> CGPoint? {
        // Try multiple positions along the curve
        let attempts = 20  // Number of attempts to find a safe position
        let safeYRange = (GameConfig.Metrics.collectibleMinY...GameConfig.Metrics.collectibleMaxY)
        
        for _ in 0..<attempts {
            // Get random position along curve
            let randomT = CGFloat.random(in: 0.1...0.9)
            let basePosition = positionOnPath(path: curvePath, at: randomT)
            
            // Get random Y within safe range
            let randomY = CGFloat.random(in: safeYRange)
            let testPosition = CGPoint(x: basePosition.x, y: randomY)
            
            // Check if position is safe
            var isSafe = true
            
            // Check distance from nearby pole pairs
            for polePair in polePairs {
                if isTooCloseToObstacles(point: testPosition, polePair: polePair, minDistance: minDistanceFromPoles) {
                    isSafe = false
                    break
                }
            }
            
            // Check distance from other collectibles
            if isSafe && isTooCloseToCollectibles(point: testPosition, collectibles: collectibles, minDistance: minDistanceBetweenCollectibles) {
                isSafe = false
            }
            
            // If position is safe, return it
            if isSafe {
                return testPosition
            }
        }
        
        return nil  // No safe position found
    }
    
    static func placeCollectableOnCurve(collectable: SKSpriteNode, curvePath: CGPath, polePairs: [SKNode], collectibles: [SKSpriteNode]) {
        // Try to find a safe position
        if let safePosition = findSafePosition(
            curvePath: curvePath,
            polePairs: polePairs,
            collectibles: collectibles,
            collectibleSize: collectable.size
        ) {
            collectable.position = safePosition
        } else {
            // If no safe position found, don't place the collectible
            collectable.removeFromParent()
        }
    }

    static func positionOnPath(path: CGPath, at t: CGFloat) -> CGPoint {
        // Extract path points and calculate position based on t (0.0 to 1.0)
        let pathInfo = path.copy(dashingWithPhase: 0, lengths: [path.boundingBox.width])
        let pathLength = pathInfo.boundingBox.width
        let point = CGPoint(x: path.boundingBox.origin.x + pathLength * t, y: path.boundingBox.origin.y)
        return point
    }
}
