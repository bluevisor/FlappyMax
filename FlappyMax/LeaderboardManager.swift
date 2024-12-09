import Foundation

class LeaderboardManager {
    static let shared = LeaderboardManager()
    private let userDefaults = UserDefaults.standard
    private let highScoresKey = "HighScores"
    
    private init() {}
    
    struct ScoreEntry: Codable {
        let name: String?
        let mainScore: Int
        let date: Date
    }
    
    func addScore(_ score: Int, name: String?) {
        var leaderboard = getLeaderboard()
        let newEntry = ScoreEntry(name: name, mainScore: score, date: Date())
        leaderboard.append(newEntry)
        
        // Sort by score (descending) and keep top 10
        leaderboard.sort { $0.mainScore > $1.mainScore }
        if leaderboard.count > 10 {
            leaderboard = Array(leaderboard.prefix(10))
        }
        
        saveLeaderboard(leaderboard)
    }
    
    func getLeaderboard() -> [ScoreEntry] {
        guard let data = userDefaults.data(forKey: highScoresKey),
              let leaderboard = try? JSONDecoder().decode([ScoreEntry].self, from: data) else {
            return []
        }
        return leaderboard
    }
    
    private func saveLeaderboard(_ leaderboard: [ScoreEntry]) {
        if let encoded = try? JSONEncoder().encode(leaderboard) {
            userDefaults.set(encoded, forKey: highScoresKey)
            userDefaults.synchronize()
        }
    }
    
    func clearLeaderboard() {
        userDefaults.removeObject(forKey: highScoresKey)
        userDefaults.synchronize()
    }
}
