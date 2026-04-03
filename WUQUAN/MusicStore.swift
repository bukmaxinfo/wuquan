//
//  MusicStore.swift
//  WUQUAN
//
//  Created by Claude on 7/21/25.
//

import Foundation
import AVFoundation

struct MusicTrack {
    let id: String
    let title: String
    let artist: String
    let filename: String
    let duration: TimeInterval
    let url: URL
    
    var displayName: String {
        return "\(title) - \(artist)"
    }
}

class MusicStore {
    static let shared = MusicStore()
    
    private var tracks: [MusicTrack] = []
    
    private init() {
        loadBundledMusic()
    }
    
    // MARK: - Public Interface
    
    func getAllTracks() -> [MusicTrack] {
        return tracks
    }
    
    func getTrack(by id: String) -> MusicTrack? {
        return tracks.first { $0.id == id }
    }
    
    func getTrack(by url: URL) -> MusicTrack? {
        return tracks.first { $0.url == url }
    }
    
    // MARK: - Private Methods
    
    private func loadBundledMusic() {
        tracks.removeAll()
        
        // Try multiple approaches to find music files
        // Method 1: Look for Music folder
        if let musicBundle = Bundle.main.url(forResource: "Music", withExtension: nil) {
            loadMusicFromDirectory(musicBundle)
        } else {
            
            // Method 2: Look for individual music files in main bundle
            loadMusicFromMainBundle()
        }
        
        if tracks.isEmpty {
            createDefaultTracks()
        }
    }
    
    private func loadMusicFromDirectory(_ directory: URL) {
        do {
            let musicFiles = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

            for fileURL in musicFiles {
                if isValidMusicFile(fileURL) {
                    if let track = createTrack(from: fileURL) {
                        tracks.append(track)
                    }
                }
            }
        } catch {
            print("ERROR: Failed to load music files from directory: \(error)")
        }
    }
    
    private func loadMusicFromMainBundle() {
        let validExtensions = ["mp3", "m4a", "wav", "aac", "mp4"]
        
        for ext in validExtensions {
            if let musicURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Music") {
                for fileURL in musicURLs {
                    if let track = createTrack(from: fileURL) {
                        tracks.append(track)
                    }
                }
            }
        }
        
        // Also try without subdirectory in case files are in root
        for ext in validExtensions {
            if let musicURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for fileURL in musicURLs {
                    // Only add if not already added from Music subdirectory
                    if !tracks.contains(where: { $0.url == fileURL }) {
                        if let track = createTrack(from: fileURL) {
                            tracks.append(track)
                        }
                    }
                }
            }
        }
    }
    
    private func isValidMusicFile(_ url: URL) -> Bool {
        let validExtensions = ["mp3", "m4a", "wav", "aac", "mp4"]
        let pathExtension = url.pathExtension.lowercased()
        return validExtensions.contains(pathExtension)
    }
    
    private func createTrack(from url: URL) -> MusicTrack? {
        let filename = url.lastPathComponent
        let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
        
        // Try to parse title and artist from filename
        // Expected format: "Artist - Title.mp3" or just "Title.mp3"
        var title = nameWithoutExtension
        var artist = "未知艺术家"
        
        if nameWithoutExtension.contains(" - ") {
            let components = nameWithoutExtension.components(separatedBy: " - ")
            if components.count >= 2 {
                artist = components[0].trimmingCharacters(in: .whitespaces)
                title = components[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Get duration using AVAudioPlayer
        var duration: TimeInterval = 0
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer.duration
        } catch {
            // Could not get duration, defaulting to 0
        }
        
        let id = UUID().uuidString
        
        return MusicTrack(
            id: id,
            title: title,
            artist: artist,
            filename: filename,
            duration: duration,
            url: url
        )
    }
    
    private func createDefaultTracks() {
        // Create some placeholder tracks for testing
        // These won't actually play but will show the UI
        let defaultTracks = [
            ("游戏背景音乐 1", "舞拳工作室", "game_music_1.mp3"),
            ("游戏背景音乐 2", "舞拳工作室", "game_music_2.mp3"),
            ("战斗音乐", "舞拳工作室", "battle_music.mp3"),
            ("菜单音乐", "舞拳工作室", "menu_music.mp3")
        ]
        
        for (title, artist, filename) in defaultTracks {
            // Create a placeholder URL (won't work for actual playback)
            let placeholderURL = Bundle.main.bundleURL.appendingPathComponent("Music").appendingPathComponent(filename)
            
            let track = MusicTrack(
                id: UUID().uuidString,
                title: title,
                artist: artist,
                filename: filename,
                duration: 180.0, // 3 minutes placeholder
                url: placeholderURL
            )
            
            tracks.append(track)
        }
    }
    
    // MARK: - Utility Methods
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func refreshMusicLibrary() {
        loadBundledMusic()
    }
}