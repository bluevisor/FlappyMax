//
//  MainMenuScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Main menu scene for FlappyMax
 
 Responsibilities:
 - Game entry point management
 - Menu navigation control
 - Scene transition handling
 - UI layout management
 - Game initialization
 
 Features:
 - Start game button
 - Settings access
 - Animated title
 - Version display
 - Copyright info
 - Device-specific layouts
 - Smooth transitions
 - Sound initialization
 - Clean UI design
 - Responsive controls
 - Visual feedback
 - Error handling
 - State management
 - Easy navigation
 */

import SpriteKit
import AVFoundation
import UIKit

class MainMenuScene: SKScene {

    var audioPlayer: AVAudioPlayer?
    var swooshSoundEffect: AVAudioPlayer?

    override func didMove(to view: SKView) {
        print("\n=== Device Configuration ===")
        print("- Current Device: \(DeviceType.current)")
        print("- Screen Size: \(UIScreen.main.bounds.size)")
        print("- Scale Factor: \(GameConfig.deviceScaleFactor)")
        
        // Setup audio first
        preloadAudio()
        
        // Get safe area insets using the modern API
        let safeAreaInsets: UIEdgeInsets
        if let windowScene = view.window?.windowScene {
            safeAreaInsets = windowScene.windows.first?.safeAreaInsets ?? .zero
        } else {
            safeAreaInsets = .zero
        }
        print("- Safe Area Insets: \(safeAreaInsets)")
        print("=========================\n")
        
        // Create background first to avoid frame drops
        let background = BackgroundManager.shared.createBackground(size: self.size)
        addChild(background)
        
        // Cache common values
        let ifIphone = DeviceType.current == .iPhone
        let titleScale: CGFloat = ifIphone ? 0.4 : 0.6
        let titlePositionOffset: CGFloat = ifIphone ? 69 : 130
        let titleOutScale: CGFloat = ifIphone ? 0.6 : 0.75
        let titlePosition = CGPoint(x: frame.midX, y: frame.midY + titlePositionOffset)
        let versionLabelFontSize: CGFloat = ifIphone ? 16 : 20
        let versionLabelPositionOffset: CGFloat = ifIphone ? -36 : -40
        let startButtonPositionOffset: CGFloat = ifIphone ? -90 : -200
        let settingsButtonPositionOffset: CGFloat = ifIphone ? -130 : -300
        let startButtonFontSize: CGFloat = ifIphone ? 32 : 64
        let settingsLabelFontSize: CGFloat = ifIphone ? 24 : 42
        let copyrightLabelFontSize: CGFloat = ifIphone ? 10 : 12
        
        // Create and cache textures
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        
        // First title node for the initial animation
        let titleIn = SKSpriteNode(texture: titleTexture)
        titleIn.position = titlePosition
        titleIn.setScale(5.0)
        titleIn.alpha = 0.0
        addChild(titleIn)

        // Second title node for the exit animation (reuse texture)
        let titleOut = SKSpriteNode(texture: titleTexture)
        titleOut.position = titlePosition
        titleOut.setScale(titleScale)
        titleOut.alpha = 0.0
        addChild(titleOut)
        
        // Cache animations
        let fadeIn = SKAction.fadeIn(withDuration: 1.5)
        let scaleDown = SKAction.scale(to: titleScale, duration: 1.5)
        let titleInAnimation = SKAction.group([fadeIn, scaleDown])
        titleInAnimation.timingMode = .easeIn

        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        let scaleUp = SKAction.scale(to: titleOutScale, duration: 0.6)
        let titleOutAnimation = SKAction.group([fadeOut, scaleUp])
        titleOutAnimation.timingMode = .easeOut

        // Run titleIn animation, then titleOut animation
        self.swooshSoundEffect?.play()  // Play sound effect when titleIn starts
        titleIn.run(SKAction.sequence([
            titleInAnimation,
            SKAction.run {
                titleOut.alpha = 1.0
                titleOut.run(titleOutAnimation)
            }
        ]))

        // Version label
        let versionLabel = SKLabelNode(fontNamed: "Helvetica-UltraLight")
        versionLabel.text = "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
        versionLabel.fontColor = UIColor(hex: "#bababa")
        versionLabel.fontSize = versionLabelFontSize
        versionLabel.position = CGPoint(x: frame.midX, y: frame.midY + versionLabelPositionOffset)
        versionLabel.alpha = 0.0
        addChild(versionLabel)

        // Start button
        let startButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        startButton.text = "Start Game"
        startButton.name = "StartButton"
        startButton.fontSize = startButtonFontSize
        startButton.position = CGPoint(x: frame.midX, y: frame.midY + startButtonPositionOffset)
        startButton.alpha = 0.0
        addChild(startButton)

        // Settings button
        let settingsButton = SKLabelNode(fontNamed: "Helvetica-bold")
        settingsButton.text = "Settings"
        settingsButton.fontSize = settingsLabelFontSize
        settingsButton.fontColor = .white
        settingsButton.position = CGPoint(x: frame.midX, y: frame.midY + settingsButtonPositionOffset)
        settingsButton.name = "SettingsButton"
        settingsButton.alpha = 0.0
        addChild(settingsButton)

        // Copyright label
        let copyrightLabel = SKLabelNode(fontNamed: "Helvetica-UltraLight")
        copyrightLabel.text = "Copyright 2024 Bucaa Studio. All Rights Reserved."
        copyrightLabel.fontColor = UIColor(hex: "#666666")
        copyrightLabel.fontSize = copyrightLabelFontSize
        copyrightLabel.position = CGPoint(
            x: frame.midX,
            y: view.safeAreaInsets.bottom + 5
        )
        copyrightLabel.alpha = 0.0
        addChild(copyrightLabel)

        // Fade in all labels
        let delay = SKAction.wait(forDuration: 1.5)
        let labelsFadeIn = SKAction.fadeIn(withDuration: 1.5)
        labelsFadeIn.timingMode = .easeOut
        let labelsFadeInSequence = SKAction.sequence([delay, labelsFadeIn])
        versionLabel.run(labelsFadeInSequence)
        startButton.run(labelsFadeInSequence)
        settingsButton.run(labelsFadeInSequence)
        copyrightLabel.run(labelsFadeInSequence)

        // Breathing effect for start button
        let breatheIn = SKAction.group([
            SKAction.scale(to: 1.03, duration: 2.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.3, duration: 3.0)
        ])
        breatheIn.timingMode = .easeInEaseOut
        
        let breatheOut = SKAction.group([
            SKAction.scale(to: 1.0, duration: 2.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 3.0)
        ])
        breatheOut.timingMode = .easeInEaseOut
        
        let breatheAction = SKAction.sequence([breatheIn, breatheOut])
        startButton.run(SKAction.repeatForever(breatheAction))
        
        // Play swoosh sound after setup
        //swooshSoundEffect?.play()
    }

    private func preloadAudio() {
        if let swooshSoundURL = Bundle.main.url(forResource: "swoosh", withExtension: "mp3") {
            swooshSoundEffect = try? AVAudioPlayer(contentsOf: swooshSoundURL)
            swooshSoundEffect?.prepareToPlay()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        if nodesAtLocation.contains(where: { $0.name == "StartButton" }) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
        } else if nodesAtLocation.contains(where: { $0.name == "SettingsButton" }) {
            let settingsScene = SettingsScene(size: self.size)
            settingsScene.scaleMode = .aspectFill
            view?.presentScene(settingsScene, transition: SKTransition.fade(withDuration: 0.3))
        }
    }

    func createGradientTexture(startColor: UIColor, endColor: UIColor, size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let colors = [startColor.cgColor, endColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [1.0, 0.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: colorLocations)!
        
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
