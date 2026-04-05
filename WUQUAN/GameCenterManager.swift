//
//  GameCenterManager.swift
//  WUQUAN
//
//  Manages Game Center authentication, leaderboards, and achievement reporting.
//

import GameKit
import UIKit

final class GameCenterManager: NSObject {

    static let shared = GameCenterManager()
    private override init() {}

    private(set) var isAuthenticated = false
    private weak var presentingVC: UIViewController?

    // MARK: - Leaderboard IDs

    enum LeaderboardID {
        static let winStreak  = "wuquan.leaderboard.win_streak"
        static let totalWins  = "wuquan.leaderboard.total_wins"
        static let roundsPlayed = "wuquan.leaderboard.rounds_played"
    }

    // MARK: - Authentication

    func authenticatePlayer(from viewController: UIViewController) {
        presentingVC = viewController
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] authVC, error in
            guard let self else { return }

            if let vc = authVC {
                // Game Center needs the user to log in — show its own VC
                viewController.present(vc, animated: true)
                return
            }

            if let error {
                print("[GameCenter] Auth error: \(error.localizedDescription)")
                self.isAuthenticated = false
                return
            }

            self.isAuthenticated = localPlayer.isAuthenticated
            if self.isAuthenticated {
                print("[GameCenter] Authenticated as: \(localPlayer.displayName)")
                GKAccessPoint.shared.location = .topLeading
                GKAccessPoint.shared.isActive = true
            }
        }
    }

    // MARK: - Submit Scores

    /// Call after each game ends.
    func submitWinStreak(_ streak: Int) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(streak, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [LeaderboardID.winStreak]) { error in
            if let error { print("[GameCenter] Streak submit error: \(error)") }
        }
    }

    func submitTotalWins(_ wins: Int) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(wins, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [LeaderboardID.totalWins]) { error in
            if let error { print("[GameCenter] Wins submit error: \(error)") }
        }
    }

    func submitRoundsPlayed(_ rounds: Int) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(rounds, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [LeaderboardID.roundsPlayed]) { error in
            if let error { print("[GameCenter] Rounds submit error: \(error)") }
        }
    }

    // MARK: - Report Achievements

    func reportAchievement(id: String, percentComplete: Double) {
        guard isAuthenticated else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        GKAchievement.report([achievement]) { error in
            if let error { print("[GameCenter] Achievement error: \(error)") }
        }
    }

    // MARK: - Show Leaderboard UI

    func showLeaderboard(from viewController: UIViewController,
                         leaderboardID: String = LeaderboardID.winStreak) {
        guard isAuthenticated else {
            showNotAuthenticatedAlert(from: viewController)
            return
        }
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID,
                                              playerScope: .global,
                                              timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }

    func showAchievements(from viewController: UIViewController) {
        guard isAuthenticated else {
            showNotAuthenticatedAlert(from: viewController)
            return
        }
        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }

    private func showNotAuthenticatedAlert(from vc: UIViewController) {
        let alert = UIAlertController(
            title: "未登录 Game Center",
            message: "请在系统设置中登录 Game Center 以查看排行榜和成就。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        vc.present(alert, animated: true)
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
