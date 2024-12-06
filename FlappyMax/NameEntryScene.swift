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
        createTextField()
        
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
    
    private func createTextField() {
        // Clean up any existing text field first
        cleanupTextField()
        
        guard let view = view else { return }
        
        // Check for any existing text fields in the view and remove them
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                textField.resignFirstResponder()
                textField.removeFromSuperview()
            }
        }
        
        let textField = UITextField(frame: CGRect(
            x: view.frame.width * 0.2,
            y: view.frame.height * 0.5,
            width: view.frame.width * 0.6,
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
    
    private func cleanupTextField() {
        // Clean up the stored text field reference
        if let existingField = nameField {
            existingField.resignFirstResponder()
            existingField.removeFromSuperview()
            self.nameField = nil
        }
        
        // Also clean up any other text fields that might be in the view
        guard let view = view else { return }
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                textField.resignFirstResponder()
                textField.removeFromSuperview()
            }
        }
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
            textField.frame.origin.y = view.frame.height * 0.5 // Reset position
            self.contentNode.position.y = self.frame.height * 0.8 // Reset content position
        }
    }
    
    private func handleUserInput() {
        guard let textField = nameField else { return }
        
        let userName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Anonymous"
        let finalName = userName.isEmpty ? "Anonymous" : userName
        
        // Create new score entry
        let finalScore = ScoreEntry(
            mainScore: currentScore.mainScore,
            coins: currentScore.coins,
            name: finalName,
            date: Date()
        )
        
        // Update leaderboard
        leaderboardManager.updateLeaderboard(with: finalScore)
        
        // Transition to game over scene
        transitionToGameOver(with: finalScore)
        
        // Cleanup text field
        cleanupTextField()
    }

    private func transitionToGameOver(with score: ScoreEntry) {
        print("Starting transition to game over scene")
        
        // Clean up text field and observers before transitioning
        cleanupTextField()
        NotificationCenter.default.removeObserver(self)
        
        // Create and configure the game over scene
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.scaleMode = .aspectFill
        gameOverScene.currentScore = score
        
        // Ensure we're on the main thread for UI updates
        DispatchQueue.main.async {
            self.view?.presentScene(gameOverScene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        cleanupTextField()
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self)
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
        let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let finalName = name.isEmpty ? "Anonymous" : name
        
        // Create new score entry with the entered name
        let finalScore = ScoreEntry(
            mainScore: currentScore.mainScore,
            coins: currentScore.coins,
            name: finalName,
            date: Date()
        )
        
        // Update leaderboard with the new score
        leaderboardManager.updateLeaderboard(with: finalScore)
        
        // Transition to game over scene
        transitionToGameOver(with: finalScore)
        
        return true
    }
}