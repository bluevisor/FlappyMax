import SpriteKit
import UIKit

class NameEntryScene: SKScene {
    private var currentScore: ScoreEntry!
    private let leaderboardManager = LeaderboardManager.shared
    private var nameField: UITextField?
    private var contentNode: SKNode!
    
    convenience init(size: CGSize, score: ScoreEntry) {
        self.init(size: size)
        self.currentScore = score
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Add faded game title
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1 // Faded appearance
        titleNode.setScale(GameConfig.Scales.title)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1 // Behind other elements
        addChild(titleNode)
        
        contentNode = SKNode()
        
        // New High Score Title
        let highScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        highScoreLabel.text = "New High Score!"
        highScoreLabel.fontSize = GameConfig.adaptiveFontSize(36)
        highScoreLabel.fontColor = .white
        highScoreLabel.position = CGPoint(x: 0, y: GameConfig.scaled(40))
        contentNode.addChild(highScoreLabel)
        
        // Score display
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(currentScore.mainScore)"
        scoreLabel.fontSize = GameConfig.adaptiveFontSize(28)
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: GameConfig.scaled(0))
        contentNode.addChild(scoreLabel)
        
        // Enter Name Label
        let enterNameLabel = SKLabelNode(fontNamed: "Helvetica")
        enterNameLabel.text = "Enter Your Name:"
        enterNameLabel.fontSize = GameConfig.adaptiveFontSize(24)
        enterNameLabel.fontColor = .white
        enterNameLabel.position = CGPoint(x: 0, y: GameConfig.scaled(-50))
        contentNode.addChild(enterNameLabel)
        
        // Position the content higher to avoid keyboard
        contentNode.position = CGPoint(x: frame.midX, y: frame.height * 0.8)
        addChild(contentNode)
        
        // Add text field
        setupTextField()
        
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupTextField() {
        guard let view = view else { return }
        
        // Calculate text field width based on device
        let textFieldWidth = min(view.frame.width * 0.6, 300.0)
        
        let textField = UITextField(frame: CGRect(
            x: view.frame.midX - textFieldWidth/2,
            y: view.frame.height * 0.4, // Position higher in the screen
            width: textFieldWidth,
            height: 40
        ))
        
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.textAlignment = .center
        textField.font = UIFont(name: "Helvetica", size: 20)
        textField.placeholder = "Enter name (max 10)"
        textField.delegate = self
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.borderStyle = .roundedRect
        
        view.addSubview(textField)
        textField.becomeFirstResponder()
        
        self.nameField = textField
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let view = view,
              let textField = nameField else { return }
        
        let keyboardHeight = keyboardFrame.height
        let textFieldMaxY = textField.frame.maxY
        let availableSpace = view.frame.height - keyboardHeight
        
        if textFieldMaxY > availableSpace {
            UIView.animate(withDuration: 0.3) {
                textField.frame.origin.y = view.frame.height * 0.3 // Move higher when keyboard shows
                self.contentNode.position.y = self.frame.height * 0.9 // Move content higher
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let view = view,
              let textField = nameField else { return }
        
        UIView.animate(withDuration: 0.3) {
            textField.frame.origin.y = view.frame.height * 0.4 // Reset position
            self.contentNode.position.y = self.frame.height * 0.8 // Reset content position
        }
    }
    
    private func cleanupTextField() {
        // Force resign first responder on main thread
        DispatchQueue.main.async { [weak self] in
            self?.nameField?.resignFirstResponder()
        }
        
        // Ensure removal on main thread
        DispatchQueue.main.async { [weak self] in
            self?.nameField?.removeFromSuperview()
            self?.nameField = nil
        }
    }
    
    private func transitionToGameOver(with score: ScoreEntry) {
        // Clean up text field
        cleanupTextField()
        
        // Wait a brief moment to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Double check cleanup
            self.cleanupTextField()
            
            // Create and present game over scene
            let gameOverScene = GameOverScene(size: self.size)
            gameOverScene.currentScore = score
            gameOverScene.scaleMode = .aspectFill
            self.view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
    
    override func willMove(from view: SKView) {
        NotificationCenter.default.removeObserver(self)
        cleanupTextField()
    }
    
    override func removeFromParent() {
        cleanupTextField()
        super.removeFromParent()
    }
}

extension NameEntryScene: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 10
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Clean up text field immediately
        cleanupTextField()
        
        let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Create new score entry with name
        let finalScore = ScoreEntry(
            mainScore: currentScore.mainScore,
            coins: currentScore.coins,
            name: name.isEmpty ? "Unknown" : name,
            date: Date()
        )
        
        // Update leaderboard
        leaderboardManager.updateLeaderboard(with: finalScore)
        
        // Transition to game over scene with cleanup
        transitionToGameOver(with: finalScore)
        
        return true
    }
} 