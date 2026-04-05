//
//  SettingsViewController.swift
//  WUQUAN
//
//  Created by Claude on 7/20/25.
//

import UIKit
import AVFoundation

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsDidSelectMusic(url: URL)
    func settingsDidUpdateVolume(volume: Float)
    func settingsDidTogglePlayback(isPlaying: Bool)
    func settingsDidStopMusic()
    func settingsDidChangeDifficulty(difficulty: Difficulty)
    func settingsWillDismiss()
}

class SettingsViewController: UIViewController {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    // UI Elements
    private var backgroundView: UIView!
    private var settingsPanel: UIView!
    private var titleLabel: UILabel!
    private var closeButton: UIButton!
    
    // Music Section
    private var musicTitleLabel: UILabel!
    private var musicStatusLabel: UILabel!
    private var selectMusicButton: UIButton!
    private var playPauseButton: UIButton!
    private var stopButton: UIButton!
    
    // Volume Section
    private var volumeTitleLabel: UILabel!
    private var volumeSlider: UISlider!

    // Difficulty Section
    private var difficultyTitleLabel: UILabel!
    private var difficultySegment: UISegmentedControl!

    // Store anchor ref
    private var gameCenterAchievementsBtn: UIButton!

    // Music state
    private var selectedMusicURL: URL?
    private var isPlaying = false
    private var currentVolume: Float = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMusicControls()
        animateAppearance()
    }
    
    private func setupUI() {
        // Setup programmatically since we don't have XIB
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        createBackgroundView()
        createSettingsPanel()
        createTitleAndCloseButton()
        createMusicSection()
        createVolumeSection()
        createDifficultySection()
        createGameCenterSection()
        createStoreSection()
    }
    
    private func createBackgroundView() {
        backgroundView = UIView(frame: view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        
        // Add tap gesture to background
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    private func createSettingsPanel() {
        let panelWidth: CGFloat = min(view.bounds.width * 0.8, 400)
        let panelHeight: CGFloat = min(view.bounds.height * 0.90, 740)
        
        settingsPanel = UIView()
        settingsPanel.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 0.95)
        settingsPanel.layer.cornerRadius = 20
        settingsPanel.layer.borderWidth = 3
        settingsPanel.layer.borderColor = UIColor.cyan.cgColor
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(settingsPanel)
        
        NSLayoutConstraint.activate([
            settingsPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsPanel.widthAnchor.constraint(equalToConstant: panelWidth),
            settingsPanel.heightAnchor.constraint(equalToConstant: panelHeight)
        ])
    }
    
    private func createTitleAndCloseButton() {
        // Title
        titleLabel = UILabel()
        titleLabel.text = "设置"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(titleLabel)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        closeButton.setTitleColor(.lightGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: settingsPanel.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),
            
            closeButton.topAnchor.constraint(equalTo: settingsPanel.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createMusicSection() {
        // Music title
        musicTitleLabel = UILabel()
        musicTitleLabel.text = "🎵 音乐设置"
        musicTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        musicTitleLabel.textColor = .yellow
        musicTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(musicTitleLabel)
        
        // Music status
        musicStatusLabel = UILabel()
        musicStatusLabel.text = "未选择音乐"
        musicStatusLabel.font = UIFont.systemFont(ofSize: 14)
        musicStatusLabel.textColor = .gray
        musicStatusLabel.textAlignment = .center
        musicStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(musicStatusLabel)
        
        // Select music button
        selectMusicButton = UIButton(type: .system)
        selectMusicButton.setTitle("选择音乐", for: .normal)
        selectMusicButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        selectMusicButton.setTitleColor(.white, for: .normal)
        selectMusicButton.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.8)
        selectMusicButton.layer.cornerRadius = 10
        selectMusicButton.layer.borderWidth = 2
        selectMusicButton.layer.borderColor = UIColor.cyan.cgColor
        selectMusicButton.addTarget(self, action: #selector(selectMusicTapped), for: .touchUpInside)
        selectMusicButton.translatesAutoresizingMaskIntoConstraints = false
        selectMusicButton.isUserInteractionEnabled = true
        settingsPanel.addSubview(selectMusicButton)

        // Play/Pause button
        playPauseButton = UIButton(type: .system)
        playPauseButton.setTitle("▶️ 播放", for: .normal)
        playPauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        playPauseButton.setTitleColor(.white, for: .normal)
        playPauseButton.backgroundColor = UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.8)
        playPauseButton.layer.cornerRadius = 8
        playPauseButton.layer.borderWidth = 1
        playPauseButton.layer.borderColor = UIColor.green.cgColor
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(playPauseButton)
        
        // Stop button
        stopButton = UIButton(type: .system)
        stopButton.setTitle("⏹️ 停止", for: .normal)
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = UIColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 0.8)
        stopButton.layer.cornerRadius = 8
        stopButton.layer.borderWidth = 1
        stopButton.layer.borderColor = UIColor.red.cgColor
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(stopButton)
        
        NSLayoutConstraint.activate([
            musicTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            musicTitleLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),
            
            musicStatusLabel.topAnchor.constraint(equalTo: musicTitleLabel.bottomAnchor, constant: 20),
            musicStatusLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),
            
            selectMusicButton.topAnchor.constraint(equalTo: musicStatusLabel.bottomAnchor, constant: 20),
            selectMusicButton.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),
            selectMusicButton.widthAnchor.constraint(equalTo: settingsPanel.widthAnchor, multiplier: 0.6),
            selectMusicButton.heightAnchor.constraint(equalToConstant: 44),
            
            playPauseButton.topAnchor.constraint(equalTo: selectMusicButton.bottomAnchor, constant: 20),
            playPauseButton.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 40),
            playPauseButton.widthAnchor.constraint(equalTo: settingsPanel.widthAnchor, multiplier: 0.35),
            playPauseButton.heightAnchor.constraint(equalToConstant: 36),
            
            stopButton.topAnchor.constraint(equalTo: selectMusicButton.bottomAnchor, constant: 20),
            stopButton.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -40),
            stopButton.widthAnchor.constraint(equalTo: settingsPanel.widthAnchor, multiplier: 0.35),
            stopButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func createVolumeSection() {
        // Volume title
        volumeTitleLabel = UILabel()
        volumeTitleLabel.text = "🔊 音量"
        volumeTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        volumeTitleLabel.textColor = .cyan
        volumeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(volumeTitleLabel)
        
        // Volume slider
        volumeSlider = UISlider()
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 1.0
        volumeSlider.value = currentVolume
        volumeSlider.minimumTrackTintColor = .cyan
        volumeSlider.maximumTrackTintColor = .gray
        volumeSlider.thumbTintColor = .white
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(volumeSlider)
        
        NSLayoutConstraint.activate([
            volumeTitleLabel.topAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 40),
            volumeTitleLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),
            
            volumeSlider.topAnchor.constraint(equalTo: volumeTitleLabel.bottomAnchor, constant: 20),
            volumeSlider.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 40),
            volumeSlider.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -40)
        ])
    }
    private func createDifficultySection() {
        difficultyTitleLabel = UILabel()
        difficultyTitleLabel.text = "⚔️ 难度"
        difficultyTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        difficultyTitleLabel.textColor = .cyan
        difficultyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(difficultyTitleLabel)

        let items = Difficulty.allCases.map { $0.label }
        difficultySegment = UISegmentedControl(items: items)
        difficultySegment.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "difficulty")
        difficultySegment.selectedSegmentTintColor = UIColor.cyan.withAlphaComponent(0.6)
        difficultySegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        difficultySegment.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        difficultySegment.addTarget(self, action: #selector(difficultyChanged(_:)), for: .valueChanged)
        difficultySegment.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(difficultySegment)

        NSLayoutConstraint.activate([
            difficultyTitleLabel.topAnchor.constraint(equalTo: volumeSlider.bottomAnchor, constant: 30),
            difficultyTitleLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),

            difficultySegment.topAnchor.constraint(equalTo: difficultyTitleLabel.bottomAnchor, constant: 15),
            difficultySegment.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 40),
            difficultySegment.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -40)
        ])
    }

    @objc private func difficultyChanged(_ sender: UISegmentedControl) {
        guard let diff = Difficulty(rawValue: sender.selectedSegmentIndex) else { return }
        UserDefaults.standard.set(diff.rawValue, forKey: "difficulty")
        delegate?.settingsDidChangeDifficulty(difficulty: diff)
    }

    private func createGameCenterSection() {
        let sectionLabel = UILabel()
        sectionLabel.text = "🏆 Game Center"
        sectionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        sectionLabel.textColor = .yellow
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(sectionLabel)

        let leaderboardBtn = makeGameCenterButton(
            title: "排行榜",
            icon: "📊",
            color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85)
        )
        leaderboardBtn.addTarget(self, action: #selector(leaderboardTapped), for: .touchUpInside)
        settingsPanel.addSubview(leaderboardBtn)

        let achievementsBtn = makeGameCenterButton(
            title: "成就",
            icon: "🎖️",
            color: UIColor(red: 0.6, green: 0.35, blue: 0.85, alpha: 0.85)
        )
        achievementsBtn.addTarget(self, action: #selector(achievementsTapped), for: .touchUpInside)
        settingsPanel.addSubview(achievementsBtn)
        gameCenterAchievementsBtn = achievementsBtn

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: difficultySegment.bottomAnchor, constant: 28),
            sectionLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),

            leaderboardBtn.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 14),
            leaderboardBtn.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 24),
            leaderboardBtn.trailingAnchor.constraint(equalTo: settingsPanel.centerXAnchor, constant: -8),
            leaderboardBtn.heightAnchor.constraint(equalToConstant: 44),

            achievementsBtn.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 14),
            achievementsBtn.leadingAnchor.constraint(equalTo: settingsPanel.centerXAnchor, constant: 8),
            achievementsBtn.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -24),
            achievementsBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeGameCenterButton(title: String, icon: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("\(icon)  \(title)", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 10
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    @objc private func leaderboardTapped() {
        GameCenterManager.shared.showLeaderboard(from: self)
    }

    @objc private func achievementsTapped() {
        // Show local achievements screen; it has a link to native GC achievements inside
        let achVC = AchievementsViewController()
        achVC.modalPresentationStyle = .overFullScreen
        achVC.modalTransitionStyle = .crossDissolve
        present(achVC, animated: true)
    }

    private func createStoreSection() {
        let sectionLabel = UILabel()
        sectionLabel.text = "🛍️ 商店"
        sectionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        sectionLabel.textColor = UIColor(red: 0.5, green: 1.0, blue: 0.8, alpha: 1)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.addSubview(sectionLabel)

        let storeBtn = makeGameCenterButton(
            title: "打开商店  🪙\(AccessoryStore.shared.coinBalance)",
            icon: "🛍️",
            color: UIColor(red: 0.12, green: 0.45, blue: 0.35, alpha: 0.9)
        )
        storeBtn.addTarget(self, action: #selector(storeTapped), for: .touchUpInside)
        settingsPanel.addSubview(storeBtn)

        NSLayoutConstraint.activate([
            sectionLabel.topAnchor.constraint(equalTo: gameCenterAchievementsBtn.bottomAnchor, constant: 24),
            sectionLabel.centerXAnchor.constraint(equalTo: settingsPanel.centerXAnchor),

            storeBtn.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 12),
            storeBtn.leadingAnchor.constraint(equalTo: settingsPanel.leadingAnchor, constant: 24),
            storeBtn.trailingAnchor.constraint(equalTo: settingsPanel.trailingAnchor, constant: -24),
            storeBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func storeTapped() {
        let storeVC = StoreViewController()
        storeVC.modalPresentationStyle = .fullScreen
        present(storeVC, animated: true)
    }

    private func animateAppearance() {
        settingsPanel.alpha = 0.0
        settingsPanel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.settingsPanel.alpha = 1.0
            self.settingsPanel.transform = CGAffineTransform.identity
        }
    }
    
    private func animateDisappearance(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.settingsPanel.alpha = 0.0
            self.settingsPanel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.alpha = 0.0
        }) { _ in
            completion()
        }
    }
    
    // MARK: - Button Actions
    
    @objc private func closeButtonTapped() {
        closeSettings()
    }
    
    @objc private func backgroundTapped() {
        closeSettings()
    }
    
    @objc private func selectMusicTapped() {
        presentCustomMusicSelection()
    }
    
    private func presentCustomMusicSelection() {
        let musicSelectionVC = MusicSelectionViewController()
        musicSelectionVC.delegate = self
        musicSelectionVC.modalPresentationStyle = .overFullScreen
        musicSelectionVC.modalTransitionStyle = .crossDissolve
        
        present(musicSelectionVC, animated: true)
    }
    
    @objc private func playPauseTapped() {
        isPlaying.toggle()
        delegate?.settingsDidTogglePlayback(isPlaying: isPlaying)
        updateMusicControls()
    }
    
    @objc private func stopTapped() {
        selectedMusicURL = nil
        isPlaying = false
        delegate?.settingsDidStopMusic()
        updateMusicControls()
    }
    
    @objc private func volumeChanged(_ slider: UISlider) {
        currentVolume = slider.value
        delegate?.settingsDidUpdateVolume(volume: currentVolume)
    }
    
    private func closeSettings() {
        delegate?.settingsWillDismiss()
        animateDisappearance {
            self.dismiss(animated: false)
        }
    }
    
    private func updateMusicControls() {
        // Only update if view is loaded and UI elements exist
        guard isViewLoaded,
              let musicStatusLabel = musicStatusLabel,
              let playPauseButton = playPauseButton,
              let stopButton = stopButton else {
            return
        }
        
        if selectedMusicURL != nil {
            musicStatusLabel.text = "已选择音乐"
            musicStatusLabel.textColor = .green
            playPauseButton.isHidden = false
            stopButton.isHidden = false
            
            let playPauseTitle = isPlaying ? "⏸️ 暂停" : "▶️ 播放"
            playPauseButton.setTitle(playPauseTitle, for: .normal)
        } else {
            musicStatusLabel.text = "未选择音乐"
            musicStatusLabel.textColor = .gray
            playPauseButton.isHidden = true
            stopButton.isHidden = true
        }
    }
    
    // MARK: - Public Methods
    
    func updateMusicState(url: URL?, isPlaying: Bool, volume: Float) {
        self.selectedMusicURL = url

        self.currentVolume = volume
        
        // Only update UI elements if the view is loaded
        if isViewLoaded {
            self.volumeSlider.value = volume
            updateMusicControls()
        }
    }
}

// MARK: - MusicSelectionDelegate

extension SettingsViewController: MusicSelectionDelegate {
    func musicSelectionDidSelect(track: MusicTrack) {
        selectedMusicURL = track.url
        isPlaying = true
        delegate?.settingsDidSelectMusic(url: track.url)
        updateMusicControls()
    }
    
    func musicSelectionDidCancel() {
        // Nothing special to do on cancel
    }
}
