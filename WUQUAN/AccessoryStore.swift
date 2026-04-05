//
//  AccessoryStore.swift
//  WUQUAN
//
//  Data model, catalog, and persistence for the in-game accessory store.
//  All persistence is via UserDefaults. No IAP — items are bought with
//  in-game coins earned from wins and rounds played.
//

import SpriteKit
import UIKit

// MARK: - AccessoryCategory

enum AccessoryCategory: String, CaseIterable {
    case hats, glasses, capes, gloves, auras

    var displayName: String {
        switch self {
        case .hats:    return "帽子"
        case .glasses: return "眼镜"
        case .capes:   return "斗篷"
        case .gloves:  return "手套"
        case .auras:   return "光环"
        }
    }

    var tabEmoji: String {
        switch self {
        case .hats:    return "🎩"
        case .glasses: return "🕶️"
        case .capes:   return "🦸"
        case .gloves:  return "🥊"
        case .auras:   return "✨"
        }
    }
}

// MARK: - AccessoryItem

struct AccessoryItem {
    let id: String
    let name: String
    let emoji: String               // used both in store grid and as in-game overlay
    let category: AccessoryCategory
    let price: Int

    // Layout in SpriteKit (relative to character center)
    // Unit = characterHeight * 0.5 (half-height of the character sprite)
    // anchorY:  1.0 = top of character,  0 = center,  -1.0 = bottom
    // anchorX:  0 = center,  0.5 = right side (glove position), negative = left
    let anchorY: CGFloat
    let anchorX: CGFloat
    let displayScale: CGFloat   // emoji font size = characterHeight * displayScale
    let zOffset: CGFloat        // relative zPosition (positive = in front, negative = behind)

    // MARK: Computed persistence (read from UserDefaults fresh each call)
    var isOwned: Bool   { UserDefaults.standard.bool(forKey: "acc_owned_\(id)") }
    var isEquipped: Bool { UserDefaults.standard.bool(forKey: "acc_equipped_\(id)") }

    // MARK: Catalog
    static let all: [AccessoryItem] = [
        // ── Hats ─────────────────────────────────────────────────────────
        AccessoryItem(id: "hat_top",      name: "礼帽",    emoji: "🎩", category: .hats,    price:  50,
                      anchorY: 1.10, anchorX:  0,    displayScale: 0.30, zOffset: 3),
        AccessoryItem(id: "hat_crown",    name: "王冠",    emoji: "👑", category: .hats,    price: 120,
                      anchorY: 1.15, anchorX:  0,    displayScale: 0.28, zOffset: 3),
        AccessoryItem(id: "hat_grad",     name: "学士帽",  emoji: "🎓", category: .hats,    price:  40,
                      anchorY: 1.08, anchorX:  0,    displayScale: 0.28, zOffset: 3),
        AccessoryItem(id: "hat_military", name: "军盔",    emoji: "🪖", category: .hats,    price:  70,
                      anchorY: 1.10, anchorX:  0,    displayScale: 0.30, zOffset: 3),
        AccessoryItem(id: "hat_santa",    name: "圣诞帽",  emoji: "🎅", category: .hats,    price:  80,
                      anchorY: 1.12, anchorX:  0,    displayScale: 0.30, zOffset: 3),

        // ── Glasses ──────────────────────────────────────────────────────
        AccessoryItem(id: "glass_sun",    name: "墨镜",    emoji: "🕶️", category: .glasses, price:  40,
                      anchorY: 0.65, anchorX:  0,    displayScale: 0.26, zOffset: 3),
        AccessoryItem(id: "glass_nerd",   name: "书呆眼镜",emoji: "🤓", category: .glasses, price:  35,
                      anchorY: 0.65, anchorX:  0,    displayScale: 0.26, zOffset: 3),
        AccessoryItem(id: "glass_goggle", name: "护目镜",  emoji: "🥽", category: .glasses, price:  65,
                      anchorY: 0.65, anchorX:  0,    displayScale: 0.26, zOffset: 3),
        AccessoryItem(id: "glass_mono",   name: "单片眼镜",emoji: "🧐", category: .glasses, price:  55,
                      anchorY: 0.65, anchorX:  0,    displayScale: 0.26, zOffset: 3),

        // ── Capes ────────────────────────────────────────────────────────
        AccessoryItem(id: "cape_hero",    name: "英雄斗篷",emoji: "🦸", category: .capes,   price: 100,
                      anchorY: 0.20, anchorX:  0,    displayScale: 0.55, zOffset: -2),
        AccessoryItem(id: "cape_bat",     name: "蝙蝠斗篷",emoji: "🦇", category: .capes,   price:  90,
                      anchorY: 0.10, anchorX:  0,    displayScale: 0.50, zOffset: -2),
        AccessoryItem(id: "cape_rainbow", name: "彩虹斗篷",emoji: "🌈", category: .capes,   price: 150,
                      anchorY: 0.00, anchorX:  0,    displayScale: 0.60, zOffset: -2),

        // ── Gloves ───────────────────────────────────────────────────────
        // anchorX = 0.55 → placed on the right side; AccessoryNode also mirrors to left side
        AccessoryItem(id: "glove_box",    name: "拳击手套",emoji: "🥊", category: .gloves,  price:  60,
                      anchorY: 0.10, anchorX: 0.55, displayScale: 0.22, zOffset: 3),
        AccessoryItem(id: "glove_fire",   name: "烈焰手套",emoji: "🔥", category: .gloves,  price:  80,
                      anchorY: 0.10, anchorX: 0.55, displayScale: 0.22, zOffset: 3),
        AccessoryItem(id: "glove_zap",    name: "闪电手套",emoji: "⚡",  category: .gloves,  price: 100,
                      anchorY: 0.10, anchorX: 0.55, displayScale: 0.22, zOffset: 3),

        // ── Auras ────────────────────────────────────────────────────────
        // displayScale = 0 → rendered as SKShapeNode rings, not emoji labels
        AccessoryItem(id: "aura_star",    name: "星光气场",emoji: "💫", category: .auras,   price:  80,
                      anchorY: 0, anchorX: 0, displayScale: 0, zOffset: -3),
        AccessoryItem(id: "aura_fire",    name: "烈焰气场",emoji: "🔥", category: .auras,   price: 120,
                      anchorY: 0, anchorX: 0, displayScale: 0, zOffset: -3),
        AccessoryItem(id: "aura_zap",     name: "雷电光环",emoji: "⚡",  category: .auras,   price: 160,
                      anchorY: 0, anchorX: 0, displayScale: 0, zOffset: -3),
        AccessoryItem(id: "aura_rainbow", name: "彩虹光晕",emoji: "🌈", category: .auras,   price: 200,
                      anchorY: 0, anchorX: 0, displayScale: 0, zOffset: -3),
    ]

    static func items(in category: AccessoryCategory) -> [AccessoryItem] {
        all.filter { $0.category == category }
    }
}

// MARK: - AccessoryStore

final class AccessoryStore {
    static let shared = AccessoryStore()
    private init() {}

    // MARK: - Coin Balance

    private let coinKey = "acc_coinBalance"

    var coinBalance: Int {
        get { UserDefaults.standard.integer(forKey: coinKey) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: coinKey) }
    }

    /// Awards coins after a game ends. Returns total coins earned.
    @discardableResult
    func awardCoinsForGame(playerWon: Bool, roundsPlayed: Int, bestStreak: Int) -> Int {
        var earned = roundsPlayed * 2                   // 2 coins per round, always
        if playerWon {
            earned += 15                                // flat win bonus
            earned += min(bestStreak, 8) * 3           // streak bonus, max +24
        }
        coinBalance += earned
        return earned
    }

    // MARK: - Purchase

    /// Returns true if purchase succeeded.
    @discardableResult
    func purchase(_ item: AccessoryItem) -> Bool {
        guard !item.isOwned, coinBalance >= item.price else { return false }
        coinBalance -= item.price
        UserDefaults.standard.set(true, forKey: "acc_owned_\(item.id)")
        return true
    }

    // MARK: - Equip / Unequip

    /// Equips item and unequips any other in the same category.
    func equip(_ item: AccessoryItem) {
        guard item.isOwned else { return }
        for other in AccessoryItem.items(in: item.category) where other.isEquipped {
            UserDefaults.standard.set(false, forKey: "acc_equipped_\(other.id)")
        }
        UserDefaults.standard.set(true, forKey: "acc_equipped_\(item.id)")
    }

    func unequip(_ item: AccessoryItem) {
        UserDefaults.standard.set(false, forKey: "acc_equipped_\(item.id)")
    }

    // MARK: - Queries

    var equippedItems: [AccessoryItem] {
        AccessoryItem.all.filter { $0.isEquipped }
    }

    func equippedItem(in category: AccessoryCategory) -> AccessoryItem? {
        AccessoryItem.items(in: category).first { $0.isEquipped }
    }
}
