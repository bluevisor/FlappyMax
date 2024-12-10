import SpriteKit
import AVFoundation

class BaseGameScene: SKScene {
    // MARK: - Audio Management
    
    private var audioPlayers: [String: [AVAudioPlayer]] = [:]
    private let maxSimultaneousSounds = 4
    
    // MARK: - UI Layer
    
    internal var uiLayer: SKNode!
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupUILayer()
        loadSoundEffects()
    }
    
    private func setupUILayer() {
        uiLayer = SKNode()
        uiLayer.zPosition = 100 // Ensure UI is always on top
        addChild(uiLayer)
    }
    
    // MARK: - Audio Methods
    
    private func loadSoundEffects() {
        let soundNames = ["jump", "coin", "burger", "game_over"]
        for name in soundNames {
            if let path = Bundle.main.path(forResource: name, ofType: "wav") {
                var players: [AVAudioPlayer] = []
                for _ in 0..<maxSimultaneousSounds {
                    if let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) {
                        player.prepareToPlay()
                        players.append(player)
                    }
                }
                audioPlayers[name] = players
            }
        }
    }
    
    func playSound(_ name: String) {
        guard let players = audioPlayers[name] else { return }
        
        // Get current volume setting
        let volume = UserDefaults.standard.float(forKey: "SFXVolume")
        
        // Find an available player
        if let player = players.first(where: { !$0.isPlaying }) {
            player.volume = volume
            player.play()
        } else {
            // If all players are busy, use the one that started playing the longest ago
            if let oldestPlayer = players.min(by: { $0.currentTime > $1.currentTime }) {
                oldestPlayer.volume = volume
                oldestPlayer.currentTime = 0
                oldestPlayer.play()
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanupScene() {
        // Override in subclasses to provide specific cleanup
    }
    
    // MARK: - Scene Transitions
    
    func transitionToScene(_ sceneType: SceneManager.SceneType, duration: TimeInterval = SceneManager.SceneConfig.defaultTransitionDuration) {
        SceneManager.shared.transition(from: self, to: sceneType, duration: duration)
    }
}
