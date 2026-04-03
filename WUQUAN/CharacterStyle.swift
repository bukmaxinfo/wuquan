//
//  CharacterStyle.swift
//  WUQUAN
//
//  Character style definitions — 12 unique looks
//

import SpriteKit

struct CharacterStyle {
    let id: String
    let name: String
    let emoji: String           // Preview icon
    let jacketColor: SKColor
    let trimColor: SKColor
    let collarColor: SKColor
    let hairColor: SKColor
    let skinColor: SKColor
    let hasSunglasses: Bool
    let hasChain: Bool
    let hasHeadband: Bool
    let hasEarrings: Bool
    let hasBow: Bool
    let hasBeard: Bool
    let hasCap: Bool
    let hasHeadphones: Bool
    let hasTiara: Bool
    let defaultMouth: String
    let browColor: SKColor?     // nil = use hairColor

    var armColor: SKColor { jacketColor }
    var armTrimColor: SKColor { trimColor.withAlphaComponent(0.6) }

    // MARK: - All Characters

    static let all: [CharacterStyle] = [
        nightclubPrince, partyQueen, coolDJ, businessWoman,
        punkRocker, cuteGirl, hipHopKing, elegantLady,
        sportyGuy, gothGirl, hipster, sweetGrandma
    ]

    // 1. 夜店小王子 — Nightclub Prince
    static let nightclubPrince = CharacterStyle(
        id: "nightclub_prince", name: "夜店小王子", emoji: "🕺",
        jacketColor: SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1),
        trimColor: SKColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1),
        collarColor: SKColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 0.8),
        hairColor: SKColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1),
        hasSunglasses: true, hasChain: true, hasHeadband: false,
        hasEarrings: false, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😏", browColor: nil
    )

    // 2. 派对女王 — Party Queen
    static let partyQueen = CharacterStyle(
        id: "party_queen", name: "派对女王", emoji: "💃",
        jacketColor: SKColor(red: 0.7, green: 0.1, blue: 0.3, alpha: 1),
        trimColor: SKColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1),
        collarColor: SKColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 0.8),
        hairColor: SKColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 1.0, green: 0.87, blue: 0.77, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: true, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😘", browColor: nil
    )

    // 3. DJ大师 — Cool DJ
    static let coolDJ = CharacterStyle(
        id: "cool_dj", name: "DJ大师", emoji: "🎧",
        jacketColor: SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        trimColor: SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1),
        collarColor: SKColor(red: 0.0, green: 0.8, blue: 0.4, alpha: 0.8),
        hairColor: SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 0.55, green: 0.35, blue: 0.25, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: false, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: true, hasTiara: false,
        defaultMouth: "😎", browColor: nil
    )

    // 4. 霸道女总裁 — Business Woman
    static let businessWoman = CharacterStyle(
        id: "business_woman", name: "霸道女总裁", emoji: "👩‍💼",
        jacketColor: SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1),
        trimColor: SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1),
        collarColor: SKColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 0.8),
        hairColor: SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 1),
        skinColor: SKColor(red: 0.95, green: 0.82, blue: 0.7, alpha: 1),
        hasSunglasses: true, hasChain: false, hasHeadband: false,
        hasEarrings: true, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😤", browColor: nil
    )

    // 5. 朋克摇滚 — Punk Rocker
    static let punkRocker = CharacterStyle(
        id: "punk_rocker", name: "朋克摇滚", emoji: "🤘",
        jacketColor: SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
        trimColor: SKColor(red: 1.0, green: 0.0, blue: 0.3, alpha: 1),
        collarColor: SKColor(red: 0.8, green: 0.0, blue: 0.2, alpha: 0.8),
        hairColor: SKColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1),
        skinColor: SKColor(red: 0.95, green: 0.85, blue: 0.75, alpha: 1),
        hasSunglasses: false, hasChain: true, hasHeadband: false,
        hasEarrings: true, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😝", browColor: nil
    )

    // 6. 甜美少女 — Cute Girl
    static let cuteGirl = CharacterStyle(
        id: "cute_girl", name: "甜美少女", emoji: "🎀",
        jacketColor: SKColor(red: 1.0, green: 0.75, blue: 0.8, alpha: 1),
        trimColor: SKColor(red: 1.0, green: 0.5, blue: 0.7, alpha: 1),
        collarColor: SKColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 0.8),
        hairColor: SKColor(red: 0.3, green: 0.15, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 1.0, green: 0.9, blue: 0.82, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: false, hasBow: true, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😊", browColor: nil
    )

    // 7. 嘻哈王 — Hip Hop King
    static let hipHopKing = CharacterStyle(
        id: "hiphop_king", name: "嘻哈王", emoji: "🧢",
        jacketColor: SKColor(red: 0.3, green: 0.15, blue: 0.0, alpha: 1),
        trimColor: SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
        collarColor: SKColor(red: 0.9, green: 0.75, blue: 0.0, alpha: 0.8),
        hairColor: SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1),
        hasSunglasses: true, hasChain: true, hasHeadband: false,
        hasEarrings: false, hasBow: false, hasBeard: false,
        hasCap: true, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😏", browColor: nil
    )

    // 8. 优雅公主 — Elegant Lady
    static let elegantLady = CharacterStyle(
        id: "elegant_lady", name: "优雅公主", emoji: "👑",
        jacketColor: SKColor(red: 0.3, green: 0.1, blue: 0.5, alpha: 1),
        trimColor: SKColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1),
        collarColor: SKColor(red: 0.8, green: 0.7, blue: 1.0, alpha: 0.8),
        hairColor: SKColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1),
        skinColor: SKColor(red: 1.0, green: 0.88, blue: 0.78, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: true, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: true,
        defaultMouth: "😌", browColor: nil
    )

    // 9. 运动达人 — Sporty Guy
    static let sportyGuy = CharacterStyle(
        id: "sporty_guy", name: "运动达人", emoji: "💪",
        jacketColor: SKColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1),
        trimColor: SKColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 1),
        collarColor: SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8),
        hairColor: SKColor(red: 0.25, green: 0.15, blue: 0.05, alpha: 1),
        skinColor: SKColor(red: 0.85, green: 0.65, blue: 0.45, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: true,
        hasEarrings: false, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😤", browColor: nil
    )

    // 10. 暗黑萝莉 — Goth Girl
    static let gothGirl = CharacterStyle(
        id: "goth_girl", name: "暗黑萝莉", emoji: "🖤",
        jacketColor: SKColor(red: 0.1, green: 0.05, blue: 0.1, alpha: 1),
        trimColor: SKColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1),
        collarColor: SKColor(red: 0.4, green: 0.0, blue: 0.4, alpha: 0.8),
        hairColor: SKColor(red: 0.05, green: 0.0, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 0.92, green: 0.88, blue: 0.88, alpha: 1),
        hasSunglasses: false, hasChain: true, hasHeadband: false,
        hasEarrings: true, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "🙃", browColor: SKColor(red: 0.3, green: 0.0, blue: 0.3, alpha: 1)
    )

    // 11. 文艺青年 — Hipster
    static let hipster = CharacterStyle(
        id: "hipster", name: "文艺青年", emoji: "🎨",
        jacketColor: SKColor(red: 0.35, green: 0.3, blue: 0.2, alpha: 1),
        trimColor: SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1),
        collarColor: SKColor(red: 0.7, green: 0.6, blue: 0.4, alpha: 0.8),
        hairColor: SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1),
        skinColor: SKColor(red: 0.98, green: 0.88, blue: 0.75, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: false, hasBow: false, hasBeard: true,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "🤔", browColor: nil
    )

    // 12. 快乐奶奶 — Sweet Grandma
    static let sweetGrandma = CharacterStyle(
        id: "sweet_grandma", name: "快乐奶奶", emoji: "🧶",
        jacketColor: SKColor(red: 0.6, green: 0.3, blue: 0.4, alpha: 1),
        trimColor: SKColor(red: 0.8, green: 0.5, blue: 0.6, alpha: 1),
        collarColor: SKColor(red: 0.9, green: 0.7, blue: 0.8, alpha: 0.8),
        hairColor: SKColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1),
        skinColor: SKColor(red: 0.95, green: 0.82, blue: 0.72, alpha: 1),
        hasSunglasses: false, hasChain: false, hasHeadband: false,
        hasEarrings: false, hasBow: false, hasBeard: false,
        hasCap: false, hasHeadphones: false, hasTiara: false,
        defaultMouth: "😊", browColor: SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1)
    )
}
