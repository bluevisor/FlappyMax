//
//  UtilityFunctions.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

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

    static func placeCollectableOnCurve(collectable: SKSpriteNode, curvePath: CGPath, deviation: CGFloat = 0.0) {
        // Randomly select a point along the curve path
        let randomT = CGFloat.random(in: 0.1...0.9)
        var position = positionOnPath(path: curvePath, at: randomT)

        // Apply deviation if specified
        if deviation != 0.0 {
            let deviationX = CGFloat.random(in: -deviation...deviation)
            let deviationY = CGFloat.random(in: -deviation...deviation)
            position.x += deviationX
            position.y += deviationY
        }

        collectable.position = position
    }

    static func positionOnPath(path: CGPath, at t: CGFloat) -> CGPoint {
        // Extract path points and calculate position based on t (0.0 to 1.0)
        let pathInfo = path.copy(dashingWithPhase: 0, lengths: [path.boundingBox.width])
        let pathLength = pathInfo.boundingBox.width
        let point = CGPoint(x: path.boundingBox.origin.x + pathLength * t, y: path.boundingBox.origin.y)
        return point
    }
}
