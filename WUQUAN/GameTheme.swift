//
//  GameTheme.swift
//  WUQUAN
//
//  Visual theme definitions — controls arena background, grid colors, and UI accents.
//

import SpriteKit
import UIKit

struct GameTheme {
    let id: String
    let name: String
    let emoji: String

    // Scene background
    let backgroundColor: SKColor

    // Neon floor grid colors
    let gridLineColor: SKColor      // Perspective converging lines
    let gridHLineColor: SKColor     // Horizontal lines
    let horizonColor: SKColor       // Horizon glow line
    let floorBgColor: SKColor       // Floor area fill color

    // UIKit accent colors used in selection UI
    let accentColor: UIColor
    let secondaryColor: UIColor

    // SpriteKit HUD/label color
    let hudColor: SKColor

    // MARK: - All Themes

    static let all: [GameTheme] = [neon, cyber, retro, nature, fire, ice]

    // 1. 霓虹夜店 — Neon Nightclub (default)
    static let neon = GameTheme(
        id: "neon", name: "霓虹夜店", emoji: "🌃",
        backgroundColor: SKColor(red: 0.05, green: 0.02, blue: 0.1, alpha: 1),
        gridLineColor: SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3),
        gridHLineColor: SKColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 0.25),
        horizonColor: SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.8),
        floorBgColor: SKColor(red: 0.08, green: 0.02, blue: 0.15, alpha: 1),
        accentColor: UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1),
        secondaryColor: UIColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1),
        hudColor: SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1)
    )

    // 2. 赛博朋克 — Cyberpunk
    static let cyber = GameTheme(
        id: "cyber", name: "赛博朋克", emoji: "🤖",
        backgroundColor: SKColor(red: 0.02, green: 0.08, blue: 0.04, alpha: 1),
        gridLineColor: SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.3),
        gridHLineColor: SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.25),
        horizonColor: SKColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.8),
        floorBgColor: SKColor(red: 0.02, green: 0.1, blue: 0.05, alpha: 1),
        accentColor: UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1),
        secondaryColor: UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1),
        hudColor: SKColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 1)
    )

    // 3. 复古街机 — Retro Arcade
    static let retro = GameTheme(
        id: "retro", name: "复古街机", emoji: "🕹️",
        backgroundColor: SKColor(red: 0.08, green: 0.0, blue: 0.15, alpha: 1),
        gridLineColor: SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 0.3),
        gridHLineColor: SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.25),
        horizonColor: SKColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.8),
        floorBgColor: SKColor(red: 0.1, green: 0.0, blue: 0.18, alpha: 1),
        accentColor: UIColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1),
        secondaryColor: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1),
        hudColor: SKColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1)
    )

    // 4. 森林秘境 — Nature
    static let nature = GameTheme(
        id: "nature", name: "森林秘境", emoji: "🌿",
        backgroundColor: SKColor(red: 0.03, green: 0.1, blue: 0.03, alpha: 1),
        gridLineColor: SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 0.3),
        gridHLineColor: SKColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 0.25),
        horizonColor: SKColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 0.8),
        floorBgColor: SKColor(red: 0.04, green: 0.12, blue: 0.04, alpha: 1),
        accentColor: UIColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1),
        secondaryColor: UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1),
        hudColor: SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1)
    )

    // 5. 地狱之火 — Fire
    static let fire = GameTheme(
        id: "fire", name: "地狱之火", emoji: "🔥",
        backgroundColor: SKColor(red: 0.12, green: 0.02, blue: 0.0, alpha: 1),
        gridLineColor: SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.3),
        gridHLineColor: SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.25),
        horizonColor: SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.8),
        floorBgColor: SKColor(red: 0.15, green: 0.03, blue: 0.0, alpha: 1),
        accentColor: UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1),
        secondaryColor: UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1),
        hudColor: SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1)
    )

    // 6. 极地冰原 — Ice
    static let ice = GameTheme(
        id: "ice", name: "极地冰原", emoji: "❄️",
        backgroundColor: SKColor(red: 0.0, green: 0.05, blue: 0.15, alpha: 1),
        gridLineColor: SKColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.3),
        gridHLineColor: SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.25),
        horizonColor: SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.8),
        floorBgColor: SKColor(red: 0.02, green: 0.08, blue: 0.18, alpha: 1),
        accentColor: UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1),
        secondaryColor: UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1),
        hudColor: SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1)
    )
}

// MARK: - Character Color Variants

struct CharacterColorVariant {
    let name: String
    let tint: UIColor         // UIKit color for selection UI
    let skTint: SKColor       // SpriteKit tint applied in-game
    let blendFactor: CGFloat  // 0 = original color, 1 = full tint

    static let all: [CharacterColorVariant] = [
        CharacterColorVariant(name: "原色", tint: .white,
                              skTint: .white, blendFactor: 0),
        CharacterColorVariant(name: "赤红", tint: UIColor(red: 1, green: 0.25, blue: 0.25, alpha: 1),
                              skTint: SKColor(red: 1, green: 0.25, blue: 0.25, alpha: 1), blendFactor: 0.4),
        CharacterColorVariant(name: "橙焰", tint: UIColor(red: 1, green: 0.55, blue: 0.0, alpha: 1),
                              skTint: SKColor(red: 1, green: 0.55, blue: 0.0, alpha: 1), blendFactor: 0.4),
        CharacterColorVariant(name: "金光", tint: UIColor(red: 1, green: 0.88, blue: 0.0, alpha: 1),
                              skTint: SKColor(red: 1, green: 0.88, blue: 0.0, alpha: 1), blendFactor: 0.35),
        CharacterColorVariant(name: "翠绿", tint: UIColor(red: 0.1, green: 0.9, blue: 0.3, alpha: 1),
                              skTint: SKColor(red: 0.1, green: 0.9, blue: 0.3, alpha: 1), blendFactor: 0.4),
        CharacterColorVariant(name: "天蓝", tint: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1),
                              skTint: SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1), blendFactor: 0.4),
        CharacterColorVariant(name: "幻紫", tint: UIColor(red: 0.7, green: 0.2, blue: 1.0, alpha: 1),
                              skTint: SKColor(red: 0.7, green: 0.2, blue: 1.0, alpha: 1), blendFactor: 0.4),
        CharacterColorVariant(name: "玫瑰", tint: UIColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1),
                              skTint: SKColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1), blendFactor: 0.4),
    ]
}
