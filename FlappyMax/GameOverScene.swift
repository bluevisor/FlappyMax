//
//  GameOverScene.swift
//  FlappyMax
//
//  Created by John Zheng on 10/31/24.
//

import SpriteKit

class GameOverScene: SKScene {
    var currentScore: ScoreEntry?
    private var hasPromptedForName = false
    private var leaderboardLabel: SKLabelNode?

    override func didMove(to view: SKView) {
        let background = BackgroundManager.shared.createBackground(size: self.size)
        addChild(background)
        
        let title = SKSpriteNode(texture: SKTexture(imageNamed: "flappymax_title_white"))
        title.position = CGPoint(x: frame.midX, y: frame.midY)
        title.setScale(CGFloat(0.65))
        title.alpha = 0.05
        title.zPosition = -1
        addChild(title)

        // Game over label
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 100
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 260)
        addChild(gameOverLabel)
        
        displayLeaderboard()

        if let score = currentScore, shouldPromptForName(score: score) {
            // Add a 1-second delay before prompting for name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.promptForName(for: score)
            }
        }

        // Return to menu button
        let returnToMenuButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        returnToMenuButton.text = "Return to Menu"
        returnToMenuButton.name = "ReturnToMenuButton"
        returnToMenuButton.fontSize = 40
        returnToMenuButton.position = CGPoint(x: frame.midX, y: frame.midY - 350)
        addChild(returnToMenuButton)

        // Retry button
        let retryButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        retryButton.text = "Retry"
        retryButton.name = "RetryButton"
        retryButton.fontSize = 40
        retryButton.position = CGPoint(x: frame.midX, y: frame.midY - 280)
        addChild(retryButton)
    }

    private func shouldPromptForName(score: ScoreEntry) -> Bool {
        guard score.mainScore > 0 else { return false }
        let leaderboard = GameScene().getLeaderboard()
        return leaderboard.count < 10 || score.mainScore > leaderboard.last!.mainScore
    }

    private func promptForName(for score: ScoreEntry) {
        var score = score

        guard !hasPromptedForName else { return }
        hasPromptedForName = true

        if view?.window?.rootViewController?.presentedViewController == nil {
            let alert = UIAlertController(title: "New High Score!", message: "Enter your name", preferredStyle: .alert)
            alert.addTextField { textField in textField.placeholder = "Your Name" }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                if let name = alert.textFields?.first?.text, !name.isEmpty {
                    score.name = name
                    self?.updateLeaderboard(with: score)

                    DispatchQueue.main.async {
                        self?.displayLeaderboard()
                    }
                }
            }))
            view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }

    private func updateLeaderboard(with score: ScoreEntry) {
        var leaderboard = GameScene().getLeaderboard()
        leaderboard.append(score)
        leaderboard.sort { $0.mainScore > $1.mainScore }
        // Keep only the top 10 entries
        if leaderboard.count > 10 {
            leaderboard.removeLast()
        }
        GameScene().saveLeaderboard(leaderboard)
    }

    private func displayLeaderboard() {
        // Remove existing leaderboard entries if any
        self.children.filter { $0.name == "LeaderboardEntry" }.forEach { $0.removeFromParent() }
        
        let leaderboard = GameScene().getLeaderboard()
        let maxEntriesToShow = 10
        let startY = frame.midY + 170
        let entrySpacing: CGFloat = 40

        // Display leaderboard entries
        for (index, entry) in leaderboard.prefix(maxEntriesToShow).enumerated() {
            let scoreLabel = SKLabelNode(fontNamed: "Helvetica")
            scoreLabel.name = "LeaderboardEntry"  // Name it for easy removal in future refreshes
            scoreLabel.fontSize = 26
            scoreLabel.position = CGPoint(x: frame.midX, y: startY - CGFloat(index) * entrySpacing)
            scoreLabel.text = "\(index + 1). \(entry.name): \(entry.mainScore) | Coins: \(entry.coins) | Burgers: \(entry.burgers)"
            addChild(scoreLabel)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        if nodesAtLocation.contains(where: { $0.name == "RetryButton" }) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            view?.presentScene(gameScene, transition: SKTransition.crossFade(withDuration: 1.0))
        }

        if nodesAtLocation.contains(where: { $0.name == "ReturnToMenuButton" }) {
            let mainMenuScene = MainMenuScene(size: self.size)
            mainMenuScene.scaleMode = .aspectFill
            view?.presentScene(mainMenuScene, transition: SKTransition.crossFade(withDuration: 1.0))
        }
    }
}

