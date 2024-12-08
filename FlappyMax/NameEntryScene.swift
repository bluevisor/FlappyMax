import SpriteKit
import UIKit

class NameEntryScene: SKScene {
    // MARK: - Properties
    private var currentScore: ScoreEntry!
    private let leaderboardManager = LeaderboardManager.shared
    private var nameField: UITextField?
    
    // MARK: - UI Elements
    private var backgroundNode: SKSpriteNode!
    private var titleLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var contentNode: SKNode!
    
    // MARK: - Initialization
    convenience init(size: CGSize, score: ScoreEntry) {
        self.init(size: size)
        self.currentScore = score
    }
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        setupNameField()
        setupKeyboardObservers()
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
        scoreLabel.text = "Score: \(currentScore.mainScore)"
        scoreLabel.fontSize = isIPhone ? 24 : 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.width * 0.35, y: frame.height * (isIPhone ? 0.72 : 0.69))
        scoreLabel.zPosition = 1
        contentNode.addChild(scoreLabel)
        
        // Coins Label
        coinsLabel = SKLabelNode(fontNamed: "Helvetica")
        coinsLabel.text = "Coins: \(currentScore.coins)"
        coinsLabel.fontSize = isIPhone ? 24 : 32
        coinsLabel.fontColor = .white
        coinsLabel.position = CGPoint(x: frame.width * 0.65, y: frame.height * (isIPhone ? 0.72 : 0.69))
        coinsLabel.zPosition = 1
        contentNode.addChild(coinsLabel)
    }
    
    private func setupNameField() {
        guard let view = view else { return }
        
        let isIPhone = DeviceType.current == .iPhone
        let textField = UITextField()
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: isIPhone ? 20 : 24)
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter your name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        
        // Calculate text field position and size
        let fieldWidth = min(view.bounds.width * (isIPhone ? 0.7 : 0.6), 300)
        let fieldHeight: CGFloat = isIPhone ? 36 : 42
        
        // Convert from bottom-up percentage to top-down position
        let desiredHeightFromBottom = isIPhone ? 0.66 : 0.62  // This represents how high we want it from bottom
        let fieldY = view.bounds.height * (1 - desiredHeightFromBottom)  // Convert to UIKit coordinates
        
        textField.frame = CGRect(
            x: (view.bounds.width - fieldWidth) / 2,
            y: fieldY,
            width: fieldWidth,
            height: fieldHeight
        )
        
        view.addSubview(textField)
        textField.becomeFirstResponder()
        self.nameField = textField
    }
    
    private func setupKeyboardObservers() {
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
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let view = view,
              let textField = nameField else { return }
        
        let keyboardHeight = keyboardFrame.height
        let textFieldMaxY = textField.frame.maxY
        let availableSpace = view.frame.height - keyboardHeight
        
        // Only move if text field would be covered
        if textFieldMaxY > availableSpace {
            let overlap = textFieldMaxY - availableSpace
            let offset = overlap + (DeviceType.current == .iPhone ? 20 : 30)
            
            print("Keyboard height: \(keyboardHeight)")
            print("Text field maxY: \(textFieldMaxY)")
            print("Available space: \(availableSpace)")
            print("Moving content by: \(offset)")
            
            UIView.animate(withDuration: 0.3) {
                self.contentNode.position.y = offset
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.contentNode.position.y = 0
        }
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        
        // Ensure text field is removed when leaving the scene
        nameField?.resignFirstResponder()
        nameField?.removeFromSuperview()
        nameField = nil
        
        // Remove keyboard observers
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension NameEntryScene: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let name = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Create a new score entry with the entered name or "Anonymous" if empty
        let finalScore = ScoreEntry(
            mainScore: currentScore.mainScore,
            coins: currentScore.coins,
            name: name.isEmpty ? "Anonymous" : name,
            date: Date()
        )
        
        // Update leaderboard
        leaderboardManager.updateLeaderboard(with: finalScore)
        
        // Remove the text field from the view hierarchy
        textField.resignFirstResponder()
        textField.removeFromSuperview()
        nameField = nil
        
        // Transition to game over scene
        let gameOverScene = GameOverScene(size: size)
        gameOverScene.currentScore = finalScore
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(gameOverScene, transition: transition)
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength <= 15
    }
}
