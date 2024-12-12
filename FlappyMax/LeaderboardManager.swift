import Foundation

class LeaderboardManager {
    static let shared = LeaderboardManager()
    private let userDefaults = UserDefaults.standard
    private let highScoresKey = "HighScores"
    
    private init() {}
    
    struct ScoreEntry: Codable {
        let name: String?
        let mainScore: Int
        let coinScore: Int
        let date: Date
    }
    
    func addScore(_ score: Int, name: String?, coins: Int = 0) {
        var leaderboard = getLeaderboard()
        let newEntry = ScoreEntry(name: name, mainScore: score, coinScore: coins, date: Date())
        leaderboard.append(newEntry)
        
        // Sort by main score (descending) and coins (descending) when scores are equal
        leaderboard.sort { 
            if $0.mainScore != $1.mainScore {
                return $0.mainScore > $1.mainScore
            }
            return $0.coinScore > $1.coinScore
        }
        if leaderboard.count > 5 {
            leaderboard = Array(leaderboard.prefix(5))
        }
        
        saveLeaderboard(leaderboard)
    }
    
    func scoreQualifiesForLeaderboard(_ score: Int) -> Bool {
        let leaderboard = getLeaderboard()
        if leaderboard.count < 5 { return true }
        return score > leaderboard.last?.mainScore ?? 0
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
