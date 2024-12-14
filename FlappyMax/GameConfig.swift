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
    case iPadOnMac

    static var current: DeviceType {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            // iPad app running on macOS in "Designed for iPad" mode
            return .iPadOnMac
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // Native iPad
            return .iPad
        } else {
            // Native iPhone
            return .iPhone
        }
    }
}

enum GameOverReason {
    case collision
    case outOfStamina
    
    var description: String {
        switch self {
        case .collision:
            return "Collision!"
        case .outOfStamina:
            return "Out of Stamina!"
        }
    }
}

enum SpriteType {
    case hero
    case pole
    case floor
    case coin
    case coinIcon
    case burger
    case pizza
    case sushi
    case fries
    case label
    case custom(scale: CGFloat)
}

// MARK: - Game Configuration
enum GameConfig {
    static let baseScreenWidth: CGFloat = 430
    static let baseScreenHeight: CGFloat = 932
    
    static let globalGameScale: CGFloat = 1.0

    struct Scales {
        static var hero: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.32
            case .iPad: return 0.32
            case .iPadOnMac: return 0.32
            }
        }
        
        static var pole: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 2.9
            case .iPad: return 2.9
            case .iPadOnMac: return 2.9
            }
        }
        
        static var floor: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 4.0
            case .iPad: return 4.8
            case .iPadOnMac: return 4.8
            }
        }
        
        static var coin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.42
            case .iPad: return 0.48
            case .iPadOnMac: return 0.48
            }
        }
        
        static var coinIcon: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.3
            case .iPad: return 0.3
            case .iPadOnMac: return 0.3
            }
        }
        
        static var burger: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.8
            case .iPad: return 2.0
            case .iPadOnMac: return 2.0
            }
        }

        static var pizza: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.8
            case .iPad: return 2.0
            case .iPadOnMac: return 2.0
            }
        }

        static var sushi: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.8
            case .iPad: return 2.0
            case .iPadOnMac: return 2.0
            }
        }

        static var fries: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.8
            case .iPad: return 2.0
            case .iPadOnMac: return 2.0
            }
        }

        static var label: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 1.0
            case .iPad: return 1.4
            case .iPadOnMac: return 1.4
            }
        }
        
        static var title: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.5
            case .iPad: return 0.7
            case .iPadOnMac: return 0.7
            }
        }
        
        static var titleFaded: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .iPadOnMac: return 0.6
            }
        }
        
        static var highScoreCoin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 0.4
            case .iPad: return 0.6
            case .iPadOnMac: return 0.6
            }
        }
    }

    static var screenSize: CGSize {
        let screen = UIScreen.main.bounds
        return CGSize(width: screen.width, height: screen.height)
    }

    struct SafeMargin {
        static var top: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.top ?? 0
            switch DeviceType.current {
            case .iPhone: return (safeAreaInset + 20)
            case .iPad: return (safeAreaInset + 40)
            case .iPadOnMac: return (safeAreaInset + 40)
            }
        }

        static var bottom: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.bottom ?? 0
            switch DeviceType.current {
            case .iPhone: return (safeAreaInset + 20)
            case .iPad: return (safeAreaInset + 40)
            case .iPadOnMac: return (safeAreaInset + 40)
            }
        }

        static var left: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.left ?? 0
            switch DeviceType.current {
            case .iPhone: return (safeAreaInset + 20)
            case .iPad: return (safeAreaInset + 40)
            case .iPadOnMac: return (safeAreaInset + 40)
            }
        }

        static var right: CGFloat {
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let safeAreaInset = scene?.windows.first?.safeAreaInsets.right ?? 0
            switch DeviceType.current {
            case .iPhone: return (safeAreaInset + 20)
            case .iPad: return (safeAreaInset + 40)
            case .iPadOnMac: return (safeAreaInset + 40)
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

        static var mainScoreLabelFontSize: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 48
            case .iPad: return 72
            case .iPadOnMac: return 72
            }
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
            return screenSize.height - (coinHeight / 2) - SafeMargin.top
        }

        static var bottomMargin: CGFloat {
            let floorTexture = SKTexture(imageNamed: "floor")
            let bottomMargin = floorTexture.size().height * finalScale(for: .floor) * 1.5
            return bottomMargin
        }

        static var polePairGap: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 158.0
            case .iPad: return 168.0
            case .iPadOnMac: return 168.0
            }
        }
        
        static var poleSetVerticalMargin: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 30.0
            case .iPad: return 130.0
            case .iPadOnMac: return 130.0
            }
        }

        static var poleSpacing: CGFloat {
            switch DeviceType.current {
            case .iPhone: return poleWidth * 9.3
            case .iPad: return poleWidth * 6.5
            case .iPadOnMac: return poleWidth * 6.5
            }
        }
        static let scoreZoneWidth: CGFloat = 10.0

        static var polePairMinY: CGFloat {
            polePairGap / 2 + poleSetVerticalMargin + floorHeight
        }

        static var polePairMaxY: CGFloat {
            screenSize.height - polePairGap / 2 - poleSetVerticalMargin
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
            return SafeMargin.left
        }

        static let coinAnimationSpeed: TimeInterval = 1/30

        static var minRandomXPosition: CGFloat {
            return screenSize.width * 0.25
        }

        static var maxRandomXPosition: CGFloat {
            return screenSize.width * 0.75
        }

        static var coinCounterIconWidth: CGFloat {
            let coinTexture = SKTexture(imageNamed: "coin_12")
            return coinTexture.size().width * finalScale(for: .coinIcon)
        }

        static var coinCounterIconHeight: CGFloat {
            let coinTexture = SKTexture(imageNamed: "coin_12")
            return coinTexture.size().height * finalScale(for: .coinIcon)
        }

        static var coinCounterLabelSize: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 38.0
            case .iPad: return 48.0
            case .iPadOnMac: return 48.0
            }
        }

        static var coinCounterSpacing: CGFloat {
            let coinTexture = SKTexture(imageNamed: "coin_12")
            return coinTexture.size().width * finalScale(for: .coinIcon)
        }
    }

    struct Physics {
        static var gravity: CGFloat {
            switch DeviceType.current {
            case .iPhone: return -8.0
            case .iPad: return -9.8
            case .iPadOnMac: return -9.8
            }
        }

        static var flapImpulse: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 98.0
            case .iPad: return 128.0
            case .iPadOnMac: return 128.0
            }
        }

        static var gameSpeed: CGFloat {
            switch DeviceType.current {
            case .iPhone: return 420.0
            case .iPad: return 630.0
            case .iPadOnMac: return 630.0
            }
        }
    }
    
    static var deviceScaleFactor: CGFloat {
        switch DeviceType.current {
        case .iPhone: return 0.95
        case .iPad: return 1.4
        case .iPadOnMac: return 1.4
        }
    }

    static func scaled(_ size: CGFloat) -> CGFloat {
        return size * deviceScaleFactor * globalGameScale
    }

    static func finalScale(for spriteType: SpriteType) -> CGFloat {
        return globalGameScale * deviceScaleFactor * getDefaultScale(for: spriteType)
    }
    
    static func adaptiveSize(
        for texture: SKTexture,
        spriteType: SpriteType
    ) -> CGSize {
        #if DEBUG
        print("[GameConfig] - adaptiveSize() 🎯 Using sprite type: \(spriteType) for texture: \(texture.description)")
        #endif
        let scale = finalScale(for: spriteType)
        return CGSize(
            width: texture.size().width * scale,
            height: texture.size().height * scale
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
        case .coinIcon: return Scales.coinIcon
        case .burger: return Scales.burger
        case .pizza: return Scales.pizza
        case .sushi: return Scales.sushi
        case .fries: return Scales.fries
        case .label: return Scales.label
        case .custom(let scale): return scale
        }
    }
}
