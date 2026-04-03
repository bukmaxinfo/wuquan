//
//  WUQUANTests.swift
//  WUQUANTests
//
//  Created by shuming li on 7/19/25.
//

import Testing
@testable import WUQUAN

struct WUQUANTests {

    // MARK: - GameRules.evaluateRound

    @Test func sameGestureSameDirection_continueGame() {
        let result = GameRules.evaluateRound(
            playerGesture: .rock, aiGesture: .rock,
            playerDirection: .up, aiDirection: .up)
        #expect(result == .continueGame)
    }

    @Test func differentGestureDifferentDirection_continueGame() {
        let result = GameRules.evaluateRound(
            playerGesture: .rock, aiGesture: .paper,
            playerDirection: .up, aiDirection: .down)
        #expect(result == .continueGame)
    }

    @Test func sameGestureDifferentDirection_playerLoses() {
        let result = GameRules.evaluateRound(
            playerGesture: .scissors, aiGesture: .scissors,
            playerDirection: .left, aiDirection: .right)
        #expect(result == .playerLoses)
    }

    @Test func differentGestureSameDirection_aiLoses() {
        let result = GameRules.evaluateRound(
            playerGesture: .rock, aiGesture: .paper,
            playerDirection: .up, aiDirection: .up)
        #expect(result == .aiLoses)
    }

    @Test func allGestureCombinations_rulesConsistent() {
        for pg in Gesture.allCases {
            for ag in Gesture.allCases {
                for pd in Direction.allCases {
                    for ad in Direction.allCases {
                        let result = GameRules.evaluateRound(
                            playerGesture: pg, aiGesture: ag,
                            playerDirection: pd, aiDirection: ad)
                        let sameGesture = pg == ag
                        let sameDirection = pd == ad

                        if sameGesture && sameDirection {
                            #expect(result == .continueGame)
                        } else if !sameGesture && !sameDirection {
                            #expect(result == .continueGame)
                        } else if sameGesture && !sameDirection {
                            #expect(result == .playerLoses)
                        } else {
                            #expect(result == .aiLoses)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Gesture emoji

    @Test func gestureEmojis() {
        #expect(Gesture.rock.emoji == "✊")
        #expect(Gesture.paper.emoji == "✋")
        #expect(Gesture.scissors.emoji == "✌️")
    }

    // MARK: - Direction emoji

    @Test func directionEmojis() {
        #expect(Direction.up.emoji == "⬆️")
        #expect(Direction.down.emoji == "⬇️")
        #expect(Direction.left.emoji == "⬅️")
        #expect(Direction.right.emoji == "➡️")
    }

    // MARK: - MusicStore

    @Test func musicStoreDurationFormat() {
        let store = MusicStore.shared
        #expect(store.formatDuration(0) == "0:00")
        #expect(store.formatDuration(65) == "1:05")
        #expect(store.formatDuration(180) == "3:00")
    }
}
