//
//  MainMenuScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit
import AVFoundation

class MainMenuScene: SKScene {

    var audioPlayer: AVAudioPlayer?
    var swooshSoundEffect: AVAudioPlayer?

    override func didMove(to view: SKView) {
        preloadAudio()
        let background = BackgroundManager.shared.createBackground(size: self.size)
        addChild(background)
        
        // First title node for the initial animation
        let titleIn = SKSpriteNode(texture: SKTexture(imageNamed: "flappymax_title_white"))
        titleIn.position = CGPoint(x: frame.midX, y: frame.midY + 130)
        titleIn.setScale(5.0)
        titleIn.alpha = 0.0
        addChild(titleIn)

        // Title in animation
        let fadeIn = SKAction.fadeIn(withDuration: 1.5)
        let scaleDown = SKAction.scale(to: 0.6, duration: 1.5)
        let titleInAnimation = SKAction.group([fadeIn, scaleDown])
        titleInAnimation.timingMode = .easeIn

        // Second title node for the exit animation
        let titleOut = SKSpriteNode(texture: SKTexture(imageNamed: "flappymax_title_white"))
        titleOut.position = titleIn.position
        titleOut.setScale(0.6)
        titleOut.alpha = 0.0
        addChild(titleOut)

        // Title out animation: fade out and scale up
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        let scaleUp = SKAction.scale(to: 0.75, duration: 0.6)
        let titleOutAnimation = SKAction.group([fadeOut, scaleUp])
        titleOutAnimation.timingMode = .easeOut

        // Run titleIn animation, then titleOut animation
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
        versionLabel.fontSize = 22
        versionLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        versionLabel.alpha = 0.0
        addChild(versionLabel)

        // Start button
        let startButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        startButton.text = "Start Game"
        startButton.name = "StartButton"
        startButton.fontSize = 52
        startButton.position = CGPoint(x: frame.midX, y: frame.midY - 220)
        startButton.alpha = 0.0
        addChild(startButton)

        // Copyright label
        let copyrightLabel = SKLabelNode(fontNamed: "Helvetica-UltraLight")
        copyrightLabel.text = "Copyright © 2024 Bucaa Studio. All Rights Reserved."
        copyrightLabel.fontColor = UIColor(hex: "#666666")
        copyrightLabel.fontSize = 14
        copyrightLabel.position = CGPoint(x: frame.midX, y: 24)
        copyrightLabel.alpha = 0.0
        addChild(copyrightLabel)

        // Fade in all labels
        let delay = SKAction.wait(forDuration: 1.5)
        let labelsFadeIn = SKAction.fadeIn(withDuration: 1.5)
        labelsFadeIn.timingMode = .easeOut
        let labelsFadeInSequence = SKAction.sequence([delay, labelsFadeIn])
        versionLabel.run(labelsFadeInSequence)
        startButton.run(labelsFadeInSequence)
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
        swooshSoundEffect?.play()
    }

    private func preloadAudio() {
        if let startSoundURL = Bundle.main.url(forResource: "game_start", withExtension: "mp3") {
            audioPlayer = try? AVAudioPlayer(contentsOf: startSoundURL)
            audioPlayer?.prepareToPlay()
        }

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
            audioPlayer?.play()

            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
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
