# 舞拳 (WUQUAN) - Project Tracker
Last updated: 2026-04-03

## Current Milestone: Content & Polish
Progress: 1/4 tasks complete

### P1 - Should Have
- [x] Add local multiplayer support (two players on same device) - 2026-04-03
- [ ] Add custom character/theme selection

### P2 - Nice to Have
- [ ] Add leaderboard via Game Center
- [ ] Add localization for English and other languages

## Backlog
- [ ] Add achievements system
- [ ] Add accessibility support (VoiceOver, Dynamic Type)
- [ ] Add App Store assets (screenshots, description, privacy policy)
- [ ] Add app icon and launch screen design
- [ ] Investigate replacing Timer-based handshake animation with pure SKAction sequences
- [ ] Refactor GameScene.swift (~2100 lines) into smaller components

## Completed Milestones
### Content & Polish (partial) - 2026-04-03
- [x] Add local multiplayer support (two players on same device)

### Gameplay Polish - 2026-04-02
- [x] Fix AI direction selection to use strategic weighted choices based on gesture match state
- [x] Add unit tests for GameRules, Gesture, Direction, and MusicStore
- [x] Extract GameRules struct for testable result evaluation
- [x] Add score persistence across sessions via UserDefaults
- [x] Remove all debug print statements and disable showsFPS/showsNodeCount
- [x] Add haptic feedback for gesture selection, direction selection, and results
- [x] Add sound effects for game events (select, handshake, win, lose)
- [x] Improve AI strategy to track player gesture history and adapt counter-picks
- [x] Add game pause/resume when app enters background
- [x] Add difficulty levels (easy/medium/hard) with settings UI
- [x] Add 10-round game mode with game-over screen and restart
- [x] Add player statistics tracking (total games, wins) via UserDefaults
- [x] Add onboarding tutorial for first-time players

### Core Game Loop - 2025-07-21
- [x] Implement 5-phase game flow (handshake → free movement → gesture → direction → result)
- [x] Implement rock-paper-scissors gesture selection with AI opponent
- [x] Implement direction pointing mechanic with rule evaluation
- [x] Add visual effects (sparkles, fireworks, screen shake)
- [x] Add score tracking and display
- [x] Add shake gesture detection via accelerometer
- [x] Add phase-specific shake interactions

### Music & Settings - 2025-07-21
- [x] Implement settings overlay with music controls
- [x] Implement MusicStore for bundled audio file discovery
- [x] Implement music selection UI with track preview
- [x] Add volume slider and play/pause/stop controls
- [x] Implement game rules viewer accessible from title tap
- [x] Add auto-play for first available music track

### UI & Layout - 2025-07-21
- [x] Build responsive layout system with safe area support
- [x] Create player vs AI arena display
- [x] Build programmatic UI for all overlay view controllers
- [x] Add animated panel appearance/disappearance transitions
