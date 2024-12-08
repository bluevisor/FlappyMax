//
//  GameConfig.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Configuration manager for FlappyMax game
 
 This file manages all device-specific and gameplay configurations including:
 
 Device Detection:
 - Detects device type (iPhone/iPad/other)
 - Provides device-specific scaling factors
 
 Sprite Scaling:
 - Manages sprite sizes for different devices
 - Handles scaling for: hero, poles, floor, coins, burgers, UI elements
 
 Game Metrics:
 - Screen layout and margins
 - Collision boundaries
 - UI positioning
 - Gameplay element spacing
 
 Physics Parameters:
 - Gravity settings
 - Jump impulse force
 - Game speed
 - Movement parameters
 
 Adaptive Sizing:
 - Dynamic texture scaling
 - Font size adaptation
 - Screen-size based adjustments
 
 Usage:
 Access configurations through GameConfig.{Category}.{parameter}
 Example: GameConfig.Physics.gravity
 */

import Foundation
import UIKit
import SpriteKit

enum DeviceType {
    case iPhone
    case iPad
    case other

    static var current: DeviceType {
        let screen = UIScreen.main.bounds
        let maxDimension = max(screen.width, screen.height)
        
        switch maxDimension {
        case 0..<1024:  return .iPhone
        case 1024...:   return .iPad
        default:        return .other
        }
    }
}

enum GameConfig {
    static let baseScreenWidth: CGFloat = 430
    static let baseScreenHeight: CGFloat = 932
    
    // Introduce a global scale that applies on top of all other scaling factors
    static let globalGameScale: CGFloat = 1.0 // Adjust this as needed globally

    struct Scales {
        static var hero: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.2
            case .iPad: return 1.25
            case .other: return 1.25
            }
        }
        
        static var pole: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 3.2
            case .iPad: return 3.8
            case .other: return 3.8
            }
        }
        
        static var floor: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 4.0
            case .iPad: return 5.5
            case .other: return 4.0
            }
        }
        
        static var coin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.8
            case .other: return 0.4
            }
        }
        
        static var burger: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.6
            case .iPad: return 2.8
            case .other: return 1.6
            }
        }

        static var label: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.0
            case .iPad: return 1.4
            case .other: return 1.0
            }
        }
        
        static var title: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            case .other: return 0.5
            }
        }
        
        static var titleFaded: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .other: return 0.4
            }
        }
        
        static var coinCounter: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            case .other: return 0.5
            }
        }
        
        static var highScoreCoin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .other: return 0.4
            }
        }
        
        static var coinIcon: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.8
            case .iPad: return 0.4
            case .other: return 1.0
            }
        }
    }

    struct Metrics {
        static var heroBaseSize: CGSize {
            let heroTexture = SKTexture(imageNamed: "max")
            return CGSize(
                width: heroTexture.size().width * finalScale(for: .hero),
                height: heroTexture.size().height * finalScale(for: .hero)
            )
        }

        static var collectibleMinY: CGFloat {
            let floorHeight = GameConfig.Metrics.floorHeight
            let coinTexture = SKTexture(imageNamed: "coin_01.png")
            let coinHeight = coinTexture.size().height * finalScale(for: .coin)
            return floorHeight + (coinHeight / 2) + 20
        }

        static var collectibleMaxY: CGFloat {
            let coinTexture = SKTexture(imageNamed: "coin_01.png")
            let coinHeight = coinTexture.size().height * finalScale(for: .coin)
            return screenSize.height - (coinHeight / 2) - topMargin
        }

        static var screenSize: CGSize {
            let screen = UIScreen.main.bounds
            return CGSize(width: screen.width, height: screen.height)
        }

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
            let bottomMargin = floorTexture.size().height * finalScale(for: .floor) * 1.5
            return bottomMargin
        }

        static var polePairGap: CGFloat {
            switch DeviceType.current {
            case .iPhone: return heroBaseSize.height * 3.2
            case .iPad: return heroBaseSize.height * 3.5
            case .other: return heroBaseSize.height * 3.5
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
            return heroBaseSize.width * 0.2
        }

        static var polePairMinY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return heroBaseSize.height * 3.0
            case .iPad: return heroBaseSize.height * 5.0
            case .other: return heroBaseSize.height * 3.0
            }
        }

        static var polePairMaxY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return screenSize.height - (heroBaseSize.height * 3.0)
            case .iPad: return screenSize.height - (heroBaseSize.height * 3.5)
            case .other: return screenSize.height - (heroBaseSize.height * 3.0)
            }
        }

        static var poleWidth: CGFloat {
            let poleTexture = SKTexture(imageNamed: "pole")
            return poleTexture.size().width * finalScale(for: .pole)
        }

        static var floorHeight: CGFloat {
            let floorTexture = SKTexture(imageNamed: "floor")
            return floorTexture.size().height * finalScale(for: .floor)
        }

        static var coinLabelOffset: CGFloat {
            return heroBaseSize.width * 0.1
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

        static let coinAnimationSpeed: TimeInterval = 1/30

        static var minRandomXPosition: CGFloat {
            return screenSize.width * 0.25
        }

        static var maxRandomXPosition: CGFloat {
            return screenSize.width * 0.75
        }
    }

    struct Physics {
        static var gravity: CGFloat {
            switch DeviceType.current {
            case .iPhone: return -7.5
            case .iPad: return -9.5
            case .other: return -9.0
            }
        }

        static var flapImpulse: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 42.0
            case .iPad: return 142.0
            case .other: return 42.0
            }
        }

        static var gameSpeed: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 7.0
            case .iPad: return 10.0
            case .other: return 7.0
            }
        }
    }
    
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
        return size * deviceScaleFactor * globalGameScale
    }

    // Calculate final scale for a given sprite type
    static func finalScale(for spriteType: SpriteType) -> CGFloat {
        return globalGameScale * deviceScaleFactor * getDefaultScale(for: spriteType)
    }
    
    static func adaptiveSize(for texture: SKTexture, 
                             baseScale: CGFloat = 1.0,
                             spriteType: SpriteType) -> CGSize {
        let defaultScale = getDefaultScale(for: spriteType)
        let scaleFactor = globalGameScale * deviceScaleFactor * baseScale * defaultScale
        return CGSize(
            width: texture.size().width * scaleFactor,
            height: texture.size().height * scaleFactor
        )
    }
    
    static func adaptiveFontSize(_ baseSize: CGFloat) -> CGFloat {
        // Incorporate global scaling into font sizes as well
        return baseSize * deviceScaleFactor * globalGameScale * Scales.label
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

enum SpriteType {
    case hero
    case pole
    case floor
    case coin
    case burger
    case label
    case custom(scale: CGFloat)
}