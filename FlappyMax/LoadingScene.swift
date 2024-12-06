import SpriteKit

class LoadingScene: SKScene {
    private var progressBar: SKShapeNode!
    private var progressFill: SKShapeNode!
    private var progressLabel: SKLabelNode!
    private var loadingText: SKLabelNode!
    
    private let progressBarWidth: CGFloat = 300
    private let progressBarHeight: CGFloat = 4
    private let cornerRadius: CGFloat = 2
    
    private var currentProgress: CGFloat = 0.0 {
        didSet {
            updateProgressBar()
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupLoadingUI()
    }
    
    private func setupLoadingUI() {
        // Progress bar background (outline)
        progressBar = SKShapeNode()
        let barRect = CGRect(
            x: -progressBarWidth/2,
            y: -progressBarHeight/2,
            width: progressBarWidth,
            height: progressBarHeight
        )
        progressBar.path = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius).cgPath
        progressBar.strokeColor = .white
        progressBar.lineWidth = 1
        progressBar.fillColor = .clear
        progressBar.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(progressBar)
        
        // Progress bar fill
        progressFill = SKShapeNode()
        progressFill.fillColor = .white
        progressFill.strokeColor = .clear
        progressFill.position = progressBar.position
        addChild(progressFill)
        
        // Progress percentage label
        progressLabel = SKLabelNode(fontNamed: "Helvetica")
        progressLabel.fontSize = 14
        progressLabel.fontColor = .white
        progressLabel.position = CGPoint(
            x: frame.midX,
            y: progressBar.position.y - 20
        )
        progressLabel.verticalAlignmentMode = .top
        addChild(progressLabel)
        
        // Loading text
        loadingText = SKLabelNode(fontNamed: "Helvetica-Light")
        loadingText.text = "Loading FlappyMax"
        loadingText.fontSize = 18
        loadingText.fontColor = .white
        loadingText.position = CGPoint(
            x: frame.midX,
            y: progressBar.position.y + 30
        )
        loadingText.verticalAlignmentMode = .bottom
        addChild(loadingText)
        
        // Initial progress update
        updateProgress(to: 0)
    }
    
    private func updateProgressBar() {
        let fillWidth = progressBarWidth * currentProgress
        let fillRect = CGRect(
            x: -progressBarWidth/2,
            y: -progressBarHeight/2,
            width: fillWidth,
            height: progressBarHeight
        )
        progressFill.path = UIBezierPath(roundedRect: fillRect, cornerRadius: cornerRadius).cgPath
        progressLabel.text = "\(Int(currentProgress * 100))%"
    }
    
    func updateProgress(to progress: CGFloat) {
        // Ensure progress is between 0 and 1
        currentProgress = min(1, max(0, progress))
    }
    
    func complete(completion: @escaping () -> Void) {
        // Ensure we're at 100%
        updateProgress(to: 1.0)
        
        // Add a small delay before transitioning
        let wait = SKAction.wait(forDuration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        
        run(SKAction.sequence([wait, fadeOut]), completion: completion)
    }
}
