# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS SpriteKit game called "舞拳" (WUQUAN) - a rock-paper-scissors game with direction-pointing mechanics, shake gestures, music integration, and animated multi-phase gameplay.

## Build and Development Commands

```bash
# Build
xcodebuild -project WUQUAN.xcodeproj -scheme WUQUAN build

# Run unit tests
xcodebuild test -project WUQUAN.xcodeproj -scheme WUQUAN -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests only
xcodebuild test -project WUQUAN.xcodeproj -scheme WUQUAN -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:WUQUANUITests

# Open in Xcode
open WUQUAN.xcodeproj
```

## Architecture

### View Controller Hierarchy

`GameViewController` (UIKit) → presents `GameScene` (SpriteKit) as the main game surface. Modal overlays are presented as UIKit view controllers over the SKView:
- `SettingsViewController` — music selection, volume, playback controls
- `GameRulesViewController` — scrollable rules display
- `MusicSelectionViewController` — track picker with preview playback

All overlay VCs use delegate protocols to communicate back (not closures or notifications). They share a consistent UI pattern: dark semi-transparent background, animated panel with spring appearance/disappearance, close-on-background-tap.

### GameScene (~1900 lines)

The core game logic lives entirely in `GameScene.swift`. Key subsystems:

- **Phase State Machine** — `GamePhase` enum with associated values drives the game flow: `handshake(step:)` → `freeMovement(step:)` → `gestureSelection` → `directionPointing` → `result`. Phase transitions are method-driven (e.g., `startHandshakePhase()`, `startGestureSelectionPhase()`).
- **Touch Handling** — `touchesBegan` routes taps to different handlers based on current phase and node names. Button nodes are identified by `name` property (e.g., `"rock"`, `"paper"`, `"direction_up"`).
- **Shake Gesture System** — `GameViewController` uses `CMMotionManager` accelerometer data to detect shakes, forwarded to `GameScene.handleShakeGesture()`. Each phase has its own shake handler with phase-appropriate effects.
- **Music System** — `AVAudioPlayer`-based playback managed within GameScene. `MusicStore` (singleton) discovers bundled audio files from the `Music/` folder. Filename convention: `"Artist - Title.mp3"`.
- **Settings Integration** — GameScene conforms to `SettingsViewControllerDelegate` and `GameRulesDelegate`. When settings open, game animations pause and buttons hide; they restore on dismiss.
- **Visual Effects** — Success sparkles, victory fireworks (particle emitters), failure screen shake. Debug overlays available for layout visualization.

### Game Rules

- Gesture win/loss follows standard rock-paper-scissors
- If gestures match: directions must match to continue
- If gestures differ: directions must differ to continue
- AI favors paper (40%), rock (30%), scissors (30%)

### Music File Discovery

`MusicStore` searches for audio files (mp3/m4a/wav/aac/mp4) in the app bundle's `Music/` folder. If none found, it creates placeholder tracks for UI testing. Music files go in the `Music/` directory at project root.

## Testing

Uses Swift Testing framework (`@Test`, `#expect()`), not XCTest:
- Unit tests: `WUQUANTests/WUQUANTests.swift`
- UI tests: `WUQUANUITests/`

## Development Notes

- Bundle identifier: `BK.WUQUAN`
- Deployment target: iOS 18.2
- All UI is built programmatically (no storyboards/XIBs for game UI)
- Scene uses `.aspectFill` scale mode
- MediaPlayer permission required for music functionality
- CoreMotion required for shake detection
- Chinese (Simplified) is the primary UI language
