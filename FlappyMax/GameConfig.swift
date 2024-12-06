//
//  GameConfig.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
// Configuration for different devices and game parameters

import Foundation
import UIKit
import SpriteKit

// MARK: - Device Detection
enum DeviceType {
    case iPhone      // iPhone Pro Max (6.7-inch: 932 points height)
    case iPad        // iPad Air (10.9-inch: 1180 points height)
    case other
    
    static var current: DeviceType {
        let screen = UIScreen.main.bounds
        let maxDimension = max(screen.width, screen.height)
        
        switch maxDimension {
        case 0..<1024:  return .iPhone    // iPhone Pro Max and smaller
        case 1024...:   return .iPad      // iPad Air and larger
        default:        return .other
        }
    }
}

// MARK: - Game Configuration
enum GameConfig {
    // Base sizes are for iPhone Pro Max
    static let baseScreenWidth: CGFloat = 430   // iPhone Pro Max width
    static let baseScreenHeight: CGFloat = 932  // iPhone Pro Max height
    
    // MARK: - Sprite Scales
    struct Scales {
        // Get device-specific sprite scales
        static var hero: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.2
            case .iPad: return 1.25
            case .other: return 1.25 * deviceScaleFactor
            }
        }
        
        // Scale factor for pole sprites based on device type
        static var pole: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 3.2
            case .iPad: return 3.8
            case .other: return 3.8 * deviceScaleFactor
            }
        }
        
        static var floor: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 4.0
            case .iPad: return 5.5
            case .other: return 4.0 * deviceScaleFactor
            }
        }
        
        static var coin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.8
            case .other: return 0.4 * deviceScaleFactor
            }
        }
        
        static var burger: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.6
            case .iPad: return 2.8
            case .other: return 1.6 * deviceScaleFactor
            }
        }
        
        // UI Elements
        static var label: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.0
            case .iPad: return 1.4
            case .other: return 1.0 * deviceScaleFactor
            }
        }
        
        static var title: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            case .other: return 0.5 * deviceScaleFactor
            }
        }
        
        static var titleFaded: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .other: return 0.4 * deviceScaleFactor
            }
        }
        
        static var coinCounter: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            case .other: return 0.5 * deviceScaleFactor
            }
        }
        
        static var highScoreCoin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .other: return 0.4 * deviceScaleFactor
            }
        }
    }
    
    // MARK: - Game Metrics
    struct Metrics {
        // Base Hero Size (used for relative measurements)
        static var heroBaseSize: CGSize {
            let heroTexture = SKTexture(imageNamed: "max")
            return CGSize(
                width: heroTexture.size().width * Scales.hero,
                height: heroTexture.size().height * Scales.hero
            )
        }
        
        // Collectible Y Position Limits
        static var collectibleMinY: CGFloat {
            let floorHeight = GameConfig.Metrics.floorHeight
            let coinTexture = SKTexture(imageNamed: "coin_01.png")
            let coinHeight = coinTexture.size().height * Scales.coin * deviceScaleFactor
            return floorHeight + (coinHeight / 2) + 20  // 20pt extra padding from floor
        }
        
        static var collectibleMaxY: CGFloat {
            let coinTexture = SKTexture(imageNamed: "coin_01.png")
            let coinHeight = coinTexture.size().height * Scales.coin * deviceScaleFactor
            return screenSize.height - (coinHeight / 2) - topMargin  // Keep below top margin
        }
        
        // Screen dimensions
        static var screenSize: CGSize {
            let screen = UIScreen.main.bounds
            return CGSize(width: screen.width, height: screen.height)
        }
        
        // UI Layout
        static var topMargin: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.top ?? 0
            switch DeviceType.current {
            case .iPhone: return max(safeAreaInset + 20, screenSize.height * 0.1)
            case .iPad: return max(safeAreaInset + 40, screenSize.height * 0.08)
            case .other: return max(safeAreaInset + 20, screenSize.height * 0.1)
            }
        }
        
        static var bottomMargin: CGFloat {
            let floorTexture = SKTexture(imageNamed: "floor")
            let bottomMargin = floorTexture.size().height * Scales.floor * deviceScaleFactor * 1.5
            return bottomMargin
        }
        
        // Game Layout - All relative to hero size and screen
        static var polePairGap: CGFloat {
            switch DeviceType.current {
            case .iPhone: return heroBaseSize.height * 3.2
            case .iPad: return heroBaseSize.height * 3.5
            case .other: return heroBaseSize.height * 3.5 * deviceScaleFactor
            }
        }
        
        static var poleSpacing: CGFloat {
            switch DeviceType.current {
            case .iPhone: return screenSize.width * 0.5
            case .iPad: return screenSize.width * 0.4
            case .other: return screenSize.width * 0.5
            }
        }
        
        static var scoreZoneWidth: CGFloat {
            // Score zone is 20% of hero width
            return heroBaseSize.width * 0.2
        }
        
        // Pole Positioning
        static var polePairMinY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return heroBaseSize.height * 3.0
            case .iPad: return heroBaseSize.height * 5
            case .other: return heroBaseSize.height * 3.0 * deviceScaleFactor
            }
        }
        
        static var polePairMaxY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return screenSize.height - (heroBaseSize.height * 3.0)
            case .iPad: return screenSize.height - (heroBaseSize.height * 3.5)
            case .other: return screenSize.height - (heroBaseSize.height * 3.0 * deviceScaleFactor)
            }
        }
        
        // Pole Width
        static var poleWidth: CGFloat {
            let poleTexture = SKTexture(imageNamed: "pole")
            return poleTexture.size().width * Scales.pole
        }
        
        // Floor Configuration
        static var floorHeight: CGFloat {
            let floorTexture = SKTexture(imageNamed: "floor")
            return floorTexture.size().height * Scales.floor * deviceScaleFactor
        }
        
        static var coinLabelOffset: CGFloat {
            return heroBaseSize.width * 0.1  // 10% of hero width
        }
        
        static var screenMargin: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.left ?? 0
            switch DeviceType.current {
            case .iPhone: return max(safeAreaInset + 20, screenSize.width * 0.1)
            case .iPad: return max(safeAreaInset + 40, screenSize.width * 0.08)
            case .other: return max(safeAreaInset + 20, screenSize.width * 0.1)
            }
        }
        
        // Animation
        static let coinAnimationSpeed: TimeInterval = 1/30
        
        // Collectible Positioning
        static var minRandomXPosition: CGFloat {
            return screenSize.width * 0.25  // 25% of screen width
        }
        
        static var maxRandomXPosition: CGFloat {
            return screenSize.width * 0.75  // 75% of screen width
        }
    }
    
    // MARK: - Physics Parameters
    struct Physics {
        // Device-specific physics adjustments
        static var gravity: CGFloat {
            switch DeviceType.current {
            case .iPhone: return -7.5
            case .iPad: return -9.5
            case .other: return -9.0 * deviceScaleFactor
            }
        }
        
        static var flapImpulse: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 42.0
            case .iPad: return 142.0
            case .other: return 42.0 * deviceScaleFactor
            }
        }
        
        static var gameSpeed: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 7.0
            case .iPad: return 10.0
            case .other: return 7.0 * deviceScaleFactor
            }
        }
    }
    
    // MARK: - Device Scaling
    static var deviceScaleFactor: CGFloat {
        switch DeviceType.current {
        case .iPhone:  return 1.0
        case .iPad:    return 1.5
        case .other:
            let currentScreen = UIScreen.main.bounds
            let widthRatio = currentScreen.width / baseScreenWidth
            let heightRatio = currentScreen.height / baseScreenHeight
            return min(widthRatio, heightRatio)
        }
    }
    
    static func scaled(_ size: CGFloat) -> CGFloat {
        return size * deviceScaleFactor
    }
    
    static func adaptiveSize(for texture: SKTexture, 
                           baseScale: CGFloat = 1.0,
                           spriteType: SpriteType) -> CGSize {
        let defaultScale = getDefaultScale(for: spriteType)
        let scaleFactor = deviceScaleFactor * baseScale * defaultScale
        
        return CGSize(
            width: texture.size().width * scaleFactor,
            height: texture.size().height * scaleFactor
        )
    }
    
    static func adaptiveFontSize(_ baseSize: CGFloat) -> CGFloat {
        return baseSize * deviceScaleFactor * Scales.label
    }
    
    private static func getDefaultScale(for spriteType: SpriteType) -> CGFloat {
        switch spriteType {
        case .hero: return Scales.hero
        case .pole: return Scales.pole
        case .floor: return Scales.floor
        case .coin: return Scales.coin
        case .burger: return Scales.burger
        case .label: return Scales.label
        case .custom(let scale): return scale
        }
    }
}

// MARK: - Sprite Types
enum SpriteType {
    case hero
    case pole
    case floor
    case coin
    case burger
    case label
    case custom(scale: CGFloat)
} 
