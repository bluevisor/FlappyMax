//
//  GameConfig.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Configuration manager for FlappyMax game
 
 Responsibilities:
 - Device-specific scaling and adaptation
 - Physics parameters and collision settings
 - Game balancing and difficulty settings
 - UI layout and positioning
 - Asset configuration and management
 
 Features:
 - Dynamic sprite scaling for different devices
 - Configurable physics parameters (gravity, impulse)
 - Adaptive font sizing and UI scaling
 - Game speed and difficulty controls
 - Screen layout and margin calculations
 - Collision boundary definitions
 - Movement and animation timing settings
 - Performance optimization settings
 - Resource path management
 - Debug configuration options
 
 Usage:
 Access through GameConfig.{parameter}
 Example: GameConfig.Physics.gravity
 */

import Foundation
import UIKit
import SpriteKit

// MARK: - Shared Enums
enum DeviceType {
    case iPhone
    case iPad
    
    static var current: DeviceType {
        let screen = UIScreen.main.bounds
        let maxDimension = max(screen.width, screen.height)
        
        if maxDimension < 1024 {
            return .iPhone
        } else {
            return .iPad
        }
    }
}

enum GameOverReason {
    case collision
    case outOfEnergy
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

// MARK: - Game Configuration
enum GameConfig {
    static let baseScreenWidth: CGFloat = 430
    static let baseScreenHeight: CGFloat = 932
    
    static let globalGameScale: CGFloat = 1.0 // Adjust this as needed globally

    struct Scales {
        static var hero: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.32
            case .iPad: return 0.32
            }
        }
        
        static var pole: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 2.9
            case .iPad: return 2.9
            }
        }
        
        static var floor: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 4.0
            case .iPad: return 4.8
            }
        }
        
        static var coin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.42
            case .iPad: return 0.48
            }
        }
        
        static var burger: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.8
            case .iPad: return 2.0
            }
        }

        static var label: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.0
            case .iPad: return 1.4
            }
        }
        
        static var title: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            }
        }
        
        static var titleFaded: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            }
        }
        
        static var coinCounter: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            }
        }
        
        static var highScoreCoin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            }
        }
        
        static var coinIcon: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.6
            case .iPad: return 0.6
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
            case .iPad: return max(safeAreaInset + 40, screenSize.height * 0.1)
            }
        }

        static var bottomMargin: CGFloat {
            let floorTexture = SKTexture(imageNamed: "floor")
            let bottomMargin = floorTexture.size().height * finalScale(for: .floor) * 1.5
            return bottomMargin
        }

        static var polePairGap: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 146.0
            case .iPad: return 168.0
            }
        }
        
        static let poleMargin: CGFloat = 50.0

        static var poleSpacing: CGFloat {
            switch DeviceType.current {
            case .iPhone: return poleWidth * 7.5
            case .iPad: return poleWidth * 6
            }
        }
        static let scoreZoneWidth: CGFloat = 10.0

        static var polePairMinY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return heroBaseSize.height * 1.0
            case .iPad: return heroBaseSize.height * 1.5
            }
        }

        static var polePairMaxY: CGFloat {
            switch DeviceType.current {
            case .iPhone: return screenSize.height - (heroBaseSize.height * 1.0)
            case .iPad: return screenSize.height - (heroBaseSize.height * 1.5)
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
            case .iPhone: return -8.0
            case .iPad: return -9.5
            }
        }

        static var flapImpulse: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 92.0
            case .iPad: return 142.0
            }
        }

        static var gameSpeed: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 380.0
            case .iPad: return 630.0
            }
        }
    }
    
    static var deviceScaleFactor: CGFloat {
        switch DeviceType.current {
        case .iPhone: return 0.95
        case .iPad: return 1.4
        }
    }

    static func scaled(_ size: CGFloat) -> CGFloat {
        return size * deviceScaleFactor * globalGameScale
    }

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
