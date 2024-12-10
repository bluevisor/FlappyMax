import Foundation
import SpriteKit

class GameStateManager {
    static let shared = GameStateManager()
    
    // MARK: - Game States
    enum GameState {
        case playing
        case paused
        case gameOver
    }
    
    // MARK: - Properties
    private(set) var currentState: GameState = .playing
    private(set) var mainScore: Int = 0
    private(set) var coinScore: Int = 0
    
    // Callback closures
    var onStateChanged: ((GameState) -> Void)?
    var onScoreChanged: ((Int) -> Void)?
    var onCoinScoreChanged: ((Int) -> Void)?
    
    private init() {}
    
    // MARK: - State Management
    func setState(_ newState: GameState) {
        currentState = newState
        onStateChanged?(newState)
    }
    
    func togglePause() {
        switch currentState {
        case .playing:
            setState(.paused)
        case .paused:
            setState(.playing)
        case .gameOver:
            break // Can't pause in game over state
        }
    }
    
    // MARK: - Score Management
    func updateMainScore(_ score: Int) {
        mainScore = score
        onScoreChanged?(score)
    }
    
    func updateCoinScore(_ score: Int) {
        coinScore = score
        onCoinScoreChanged?(score)
    }
    
    // MARK: - Game Over
    func triggerGameOver() {
        setState(.gameOver)
    }
    
    // MARK: - Reset
    func resetGame() {
        mainScore = 0
        coinScore = 0
        setState(.playing)
    }
}
