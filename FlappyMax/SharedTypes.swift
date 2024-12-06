import Foundation

// Score and Leaderboard
struct ScoreEntry: Codable {
    let mainScore: Int
    let coins: Int
    let name: String?
    let date: Date
}

class LeaderboardManager {
    static let shared = LeaderboardManager()
    private let leaderboardKey = "Leaderboard"
    private let maxScores = 10
    
    private init() {}
    
    func getLeaderboard() -> [ScoreEntry] {
        if let data = UserDefaults.standard.data(forKey: leaderboardKey) {
            let decoder = JSONDecoder()
            return (try? decoder.decode([ScoreEntry].self, from: data)) ?? []
        }
        return []
    }
    
    func saveLeaderboard(_ leaderboard: [ScoreEntry]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(leaderboard) {
            UserDefaults.standard.set(data, forKey: leaderboardKey)
        }
    }
    
    func updateLeaderboard(with score: ScoreEntry) {
        var scores = getLeaderboard()
        scores.append(score)
        scores.sort { $0.mainScore > $1.mainScore }
        
        if scores.count > maxScores {
            scores = Array(scores.prefix(maxScores))
        }
        
        saveLeaderboard(scores)
    }
    
    func isHighScore(_ score: Int) -> Bool {
        let scores = getLeaderboard()
        if scores.count < maxScores {
            return true
        }
        return score > (scores.last?.mainScore ?? 0)
    }
} 