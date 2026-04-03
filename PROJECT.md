# 舞拳 (WUQUAN) - Project Tracker
Last updated: 2026-04-02

## Current Milestone: Core Gameplay Polish
Progress: 0/8 tasks complete

### P0 - Must Have
- [ ] Add unit tests for game logic (chooseAIGesture, result evaluation, score tracking) — current tests are empty placeholder
- [ ] Fix AI direction selection to be strategic (currently random regardless of gesture match state)
- [ ] Add persistence for game scores across sessions (currently reset on app restart)
- [ ] Remove debug print statements and `showsFPS`/`showsNodeCount` from production builds

### P1 - Should Have
- [ ] Add haptic feedback for gesture/direction selection (only shake has haptics currently)
- [ ] Add sound effects for game events (gesture select, win, lose, handshake) — only background music exists
- [ ] Improve AI strategy beyond static weights (track player patterns, adapt over rounds)
- [ ] Add game pause/resume when app enters background

### P2 - Nice to Have
- [ ] Add difficulty levels (easy/medium/hard AI)
- [ ] Add round counter and best-of-N game mode
- [ ] Add player statistics tracking (win rate, favorite gesture, streaks)
- [ ] Add onboarding tutorial for first-time players

## Backlog
- [ ] Add multiplayer support (local or online)
- [ ] Add custom character/theme selection
- [ ] Add achievements system
- [ ] Add leaderboard via Game Center
- [ ] Add localization for English and other languages
- [ ] Add accessibility support (VoiceOver, Dynamic Type)
- [ ] Add App Store assets (screenshots, description, privacy policy)
- [ ] Add app icon and launch screen design
- [ ] Investigate replacing Timer-based handshake animation with pure SKAction sequences
- [ ] Refactor GameScene.swift (~1900 lines) into smaller components

## Completed Milestones
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
