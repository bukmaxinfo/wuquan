//
//  AchievementsManager.swift
//  WUQUAN
//
//  Tracks local achievement progress and syncs unlocks to Game Center.
//

import Foundation
import GameKit

// MARK: - Achievement Definition

struct Achievement {
    let id: String
    let localizedKey: String   // Key in Localizable.strings
    let emoji: String
    let description: String    // English fallback description
    let maxProgress: Int       // 1 for one-time, N for cumulative
    let gameCenterID: String   // Must match App Store Connect achievement ID

    var isUnlocked: Bool { progress >= maxProgress }

    var progress: Int {
        get { UserDefaults.standard.integer(forKey: "achievement_\(id)") }
        set {
            let clamped = min(newValue, maxProgress)
            UserDefaults.standard.set(clamped, forKey: "achievement_\(id)")
        }
    }

    var percentComplete: Double {
        guard maxProgress > 0 else { return 0 }
        return Double(min(progress, maxProgress)) / Double(maxProgress) * 100.0
    }
}

// MARK: - All Achievements

extension Achievement {
    static let all: [Achievement] = [
        Achievement(
            id: "first_win",
            localizedKey: "achievement.firstWin",
            emoji: "🩸",
            description: "Win your first game",
            maxProgress: 1,
            gameCenterID: "wuquan.achievement.first_win"
        ),
        Achievement(
            id: "streak_3",
            localizedKey: "achievement.streak3",
            emoji: "🔥",
            description: "Win 3 rounds in a row",
            maxProgress: 3,
            gameCenterID: "wuquan.achievement.streak_3"
        ),
        Achievement(
            id: "streak_5",
            localizedKey: "achievement.streak5",
            emoji: "⚡️",
            description: "Win 5 rounds in a row",
            maxProgress: 5,
            gameCenterID: "wuquan.achievement.streak_5"
        ),
        Achievement(
            id: "wins_10",
            localizedKey: "achievement.wins10",
            emoji: "🏅",
            description: "Win 10 games total",
            maxProgress: 10,
            gameCenterID: "wuquan.achievement.wins_10"
        ),
        Achievement(
            id: "wins_50",
            localizedKey: "achievement.wins50",
            emoji: "🏆",
            description: "Win 50 games total",
            maxProgress: 50,
            gameCenterID: "wuquan.achievement.wins_50"
        ),
        Achievement(
            id: "wins_vs_ai_10",
            localizedKey: "achievement.winsVsAI10",
            emoji: "🤖",
            description: "Beat the AI 10 times",
            maxProgress: 10,
            gameCenterID: "wuquan.achievement.wins_vs_ai_10"
        ),
        Achievement(
            id: "local_games_5",
            localizedKey: "achievement.localGames5",
            emoji: "🎉",
            description: "Play 5 local multiplayer games",
            maxProgress: 5,
            gameCenterID: "wuquan.achievement.local_games_5"
        ),
        Achievement(
            id: "all_chars",
            localizedKey: "achievement.allChars",
            emoji: "🎭",
            description: "Play as every character",
            maxProgress: CharacterStyle.all.count,
            gameCenterID: "wuquan.achievement.all_chars"
        ),
    ]
}

// MARK: - Manager

final class AchievementsManager {

    static let shared = AchievementsManager()
    private init() {}

    // Track which character IDs have been used (played as)
    private var usedCharacterIDs: Set<String> {
        get {
            let arr = UserDefaults.standard.stringArray(forKey: "usedCharacterIDs") ?? []
            return Set(arr)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "usedCharacterIDs")
        }
    }

    // MARK: - Event Hooks

    /// Call after a game (round) is won by the player.
    func recordPlayerWin(gameMode: GameMode, characterID: String, currentStreak: Int) {
        // First win
        increment(id: "first_win", by: 1)

        // Total wins
        increment(id: "wins_10", by: 1)
        increment(id: "wins_50", by: 1)

        // VS AI wins
        if gameMode == .vsAI {
            increment(id: "wins_vs_ai_10", by: 1)
        }

        // Streak achievements
        setIfHigher(id: "streak_3", value: currentStreak, cap: 3)
        setIfHigher(id: "streak_5", value: currentStreak, cap: 5)

        // Character collector
        var used = usedCharacterIDs
        used.insert(characterID)
        usedCharacterIDs = used
        if let ach = Achievement.all.first(where: { $0.id == "all_chars" }) {
            setRaw(id: "all_chars", value: used.count, cap: ach.maxProgress)
        }

        syncAll()
    }

    /// Call each time a local multiplayer game completes.
    func recordLocalGame() {
        increment(id: "local_games_5", by: 1)
        syncAll()
    }

    // MARK: - Helpers

    private func increment(id: String, by amount: Int) {
        guard let ach = Achievement.all.first(where: { $0.id == id }) else { return }
        var a = ach
        a.progress = min(ach.progress + amount, ach.maxProgress)
    }

    private func setIfHigher(id: String, value: Int, cap: Int) {
        guard let ach = Achievement.all.first(where: { $0.id == id }) else { return }
        var a = ach
        if value > a.progress {
            a.progress = min(value, cap)
        }
    }

    private func setRaw(id: String, value: Int, cap: Int) {
        guard let ach = Achievement.all.first(where: { $0.id == id }) else { return }
        var a = ach
        a.progress = min(value, cap)
    }

    /// Sync all achievements to Game Center.
    func syncAll() {
        guard GameCenterManager.shared.isAuthenticated else { return }
        for ach in Achievement.all where ach.percentComplete > 0 {
            GameCenterManager.shared.reportAchievement(id: ach.gameCenterID,
                                                       percentComplete: ach.percentComplete)
        }
    }

    // MARK: - Read

    var all: [Achievement] { Achievement.all }
}
