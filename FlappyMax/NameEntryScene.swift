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
        print("NameEntryScene did move to view")
        backgroundColor = .black
        
        // Print scene metrics
        print("Scene size: \(self.size)")
        print("Scene frame: \(self.frame)")
        
        contentNode = SKNode()
        contentNode.zPosition = 1
        
        let titleTexture = SKTexture(imageNamed: "flappymax_title_white")
        let titleNode = SKSpriteNode(texture: titleTexture)
        titleNode.alpha = 0.1
        titleNode.setScale(GameConfig.Scales.titleFaded)
        titleNode.position = CGPoint(x: frame.midX, y: frame.midY)
        titleNode.zPosition = -1
        addChild(titleNode)

        // Temporarily ignore iPad logic:
        let highScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        highScoreLabel.text = "NEW HIGH SCORE!"
        highScoreLabel.fontSize = 28
        highScoreLabel.fontColor = .yellow
        highScoreLabel.alpha = 1.0
        highScoreLabel.position = CGPoint(x: frame.midX, y: frame.midY + 50)
        highScoreLabel.zPosition = 2
        contentNode.addChild(highScoreLabel)

        // Just place score label at midY - 50 for testing
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.text = "Score: \(currentScore.mainScore)"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.alpha = 1.0
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        scoreLabel.zPosition = 2
        contentNode.addChild(scoreLabel)

        let coinsLabel = SKLabelNode(fontNamed: "Helvetica")
        coinsLabel.text = "Coins: \(currentScore.coins)"
        coinsLabel.fontSize = 24
        coinsLabel.fontColor = .white
        coinsLabel.alpha = 1.0
        coinsLabel.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        coinsLabel.zPosition = 2
        contentNode.addChild(coinsLabel)

        addChild(contentNode)
        
        createTextField()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
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
            y: DeviceType.current == .iPad ? view.frame.height * 0.45 : view.frame.height * 0.5,
            width: view.frame.width * 0.6,
            height: 40
        ))
        
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.textAlignment = .center
        textField.font = UIFont(name: "Helvetica", size: DeviceType.current == .iPad ? 24 : 20)
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
            self.contentNode.position.y = 0 // Reset content position
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
        
        // Delay the transition to game over scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.transitionToGameOver(with: finalScore)
        }
        
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
            print("Transitioned to game over scene")
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
