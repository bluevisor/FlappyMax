import SpriteKit

/// Manages scene transitions and provides common scene functionality
class SceneManager {
    static let shared = SceneManager()
    
    private init() {}
    
    // MARK: - Scene Transitions
    
    func transition(from currentScene: SKScene, to sceneType: SceneType, duration: TimeInterval = 0.3) {
        guard let view = currentScene.view else { return }
        
        let nextScene: SKScene = {
            switch sceneType {
            case .mainMenu:
                return MainMenuScene(size: currentScene.size)
            case .game:
                return GameScene(size: currentScene.size)
            case .gameOver(let score, let coins, let reason):
                let scene = GameOverScene(size: currentScene.size)
                scene.mainScore = score
                scene.coinScore = coins
                scene.gameOverReason = reason
                return scene
            case .highScores:
                return HighScoresScene(size: currentScene.size)
            case .nameEntry(let score, let coins, let reason):
                return NameEntryScene(size: currentScene.size, score: score, coins: coins, gameOverReason: reason)
            case .settings:
                return SettingsScene(size: currentScene.size)
            case .loading:
                return LoadingScene(size: currentScene.size)
            }
        }()
        
        nextScene.scaleMode = .aspectFill
        view.presentScene(nextScene, transition: SKTransition.fade(withDuration: duration))
    }
    
    // MARK: - Scene Types
    
    enum SceneType {
        case mainMenu
        case game
        case gameOver(score: Int, coins: Int, reason: GameOverReason)
        case highScores
        case nameEntry(score: Int, coins: Int, reason: GameOverReason)
        case settings
        case loading
    }
}

// MARK: - Scene Configuration

extension SceneManager {
    struct SceneConfig {
        static let defaultTransitionDuration: TimeInterval = 0.3
        static let quickTransitionDuration: TimeInterval = 0.15
    }
}
