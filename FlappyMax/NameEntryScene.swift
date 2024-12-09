//
//  NameEntryScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//
/*
 Name entry scene for high score submissions
 
 Responsibilities:
 - Player name input handling
 - Input validation and formatting
 - Score submission processing
 - Scene transition management
 - Keyboard interaction
 
 Features:
 - Text field for name entry
 - Input validation rules
 - Keyboard management
 - Submission handling
 - Transition protection
 - Device-specific layouts
 - Error handling
 - User feedback
 - Data validation
 - Score persistence
 - Clean text formatting
 - Responsive UI
 - Smooth transitions
 - Input restrictions
 */

import SpriteKit
import UIKit

class NameEntryScene: SKScene {
    // MARK: - Properties
    private let leaderboardManager = LeaderboardManager.shared
    private var textField: UITextField?
    private var score: Int
    private var coins: Int
    private var gameOverReason: GameOverReason
    
    init(size: CGSize, score: Int, coins: Int, gameOverReason: GameOverReason) {
        self.score = score
        self.coins = coins
        self.gameOverReason = gameOverReason
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Elements
    private var backgroundNode: SKSpriteNode!
    private var titleLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var contentNode: SKNode!
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        
        // Create and configure text field
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.borderStyle = .roundedRect
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter your name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        textField.textAlignment = .center
        textField.delegate = self
        textField.returnKeyType = .done
        
        let ifIphone = UIDevice.current.userInterfaceIdiom == .phone
        let verticalOffset: CGFloat = ifIphone ? 45 : 60
        
        // Position the text field in the center of the screen
        if let viewSize = self.view?.bounds.size {
            textField.center = CGPoint(
                x: viewSize.width / 2,
                y: viewSize.height / 2 - verticalOffset
            )
        }
        
        self.view?.addSubview(textField)
        textField.becomeFirstResponder()
        self.textField = textField
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        backgroundColor = .black
        
        contentNode = SKNode()
        contentNode.position = CGPoint(x: 0, y: 0)
        addChild(contentNode)
        
        // Add faded title background
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        backgroundNode = SKSpriteNode(texture: titleTexture)
        backgroundNode.alpha = 0.1
        backgroundNode.setScale(GameConfig.Scales.titleFaded)
        backgroundNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode.zPosition = -1
        contentNode.addChild(backgroundNode)
    }
    
    private func setupUI() {
        let isIPhone = DeviceType.current == .iPhone
        
        // High Score Label
        titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "NEW HIGH SCORE!"
        titleLabel.fontSize = isIPhone ? 34 : 52
        titleLabel.fontColor = .yellow
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * (isIPhone ? 0.85 : 0.82))
        titleLabel.zPosition = 1
        contentNode.addChild(titleLabel)
        
        // Score Label
        scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = isIPhone ? 24 : 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.width * 0.35, y: frame.height * (isIPhone ? 0.72 : 0.69))
        scoreLabel.zPosition = 1
        contentNode.addChild(scoreLabel)
        
        // Coins Label
        coinsLabel = SKLabelNode(fontNamed: "Helvetica")
        coinsLabel.text = "Coins: \(coins)"
        coinsLabel.fontSize = isIPhone ? 24 : 32
        coinsLabel.fontColor = .white
        coinsLabel.position = CGPoint(x: frame.width * 0.65, y: frame.height * (isIPhone ? 0.72 : 0.69))
        coinsLabel.zPosition = 1
        contentNode.addChild(coinsLabel)
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Ensure text field is removed when leaving the scene
        textField?.resignFirstResponder()
        textField?.removeFromSuperview()
        textField = nil
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self)
    }
    
    private func submitName(_ name: String) {
        // Add to leaderboard
        LeaderboardManager.shared.addScore(score, name: name, coins: coins)
        
        // Transition to game over scene
        let gameOverScene = GameOverScene(size: self.size, skipHighScoreCheck: true)
        gameOverScene.mainScore = score
        gameOverScene.coinScore = coins
        gameOverScene.gameOverReason = gameOverReason
        gameOverScene.scaleMode = .aspectFill
        view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}

// MARK: - UITextFieldDelegate
extension NameEntryScene: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        
        let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("NameEntryScene: Name entered: \(name)")
        
        submitName(name.isEmpty ? "Anonymous" : name)
        
        // Remove the text field
        textField.resignFirstResponder()
        textField.removeFromSuperview()
        print("NameEntryScene: Removed text field")
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 15
    }
}
