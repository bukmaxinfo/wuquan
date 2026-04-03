//
//  MusicSelectionViewController.swift
//  WUQUAN
//
//  Created by Claude on 7/21/25.
//

import UIKit
import AVFoundation

protocol MusicSelectionDelegate: AnyObject {
    func musicSelectionDidSelect(track: MusicTrack)
    func musicSelectionDidCancel()
}

class MusicSelectionViewController: UIViewController {
    
    weak var delegate: MusicSelectionDelegate?
    
    // UI Elements
    private var backgroundView: UIView!
    private var containerView: UIView!
    private var titleLabel: UILabel!
    private var closeButton: UIButton!
    private var refreshButton: UIButton!
    private var tableView: UITableView!
    private var noMusicLabel: UILabel!
    
    // Data
    private var tracks: [MusicTrack] = []
    private var previewPlayer: AVAudioPlayer?
    private var currentlyPlayingIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMusic()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPreview()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        createBackgroundView()
        createContainerView()
        createTitleAndCloseButton()
        createTableView()
        createNoMusicLabel()
        
        animateAppearance()
    }
    
    private func createBackgroundView() {
        backgroundView = UIView(frame: view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    private func createContainerView() {
        let containerWidth: CGFloat = min(view.bounds.width * 0.85, 400)
        let containerHeight: CGFloat = min(view.bounds.height * 0.8, 600)
        
        containerView = UIView()
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 3
        containerView.layer.borderColor = UIColor.cyan.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: containerWidth),
            containerView.heightAnchor.constraint(equalToConstant: containerHeight)
        ])
    }
    
    private func createTitleAndCloseButton() {
        // Title
        titleLabel = UILabel()
        titleLabel.text = "🎵 选择背景音乐"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Refresh button
        refreshButton = UIButton(type: .system)
        refreshButton.setTitle("🔄", for: .normal)
        refreshButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        refreshButton.setTitleColor(.cyan, for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(refreshButton)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.setTitleColor(.lightGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            refreshButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            refreshButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.heightAnchor.constraint(equalToConstant: 30),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createTableView() {
        tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.cyan.withAlphaComponent(0.3)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MusicTrackCell.self, forCellReuseIdentifier: "MusicTrackCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createNoMusicLabel() {
        noMusicLabel = UILabel()
        noMusicLabel.text = "暂无音乐文件\n请联系开发者添加音乐"
        noMusicLabel.font = UIFont.systemFont(ofSize: 16)
        noMusicLabel.textColor = .gray
        noMusicLabel.textAlignment = .center
        noMusicLabel.numberOfLines = 0
        noMusicLabel.isHidden = true
        noMusicLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(noMusicLabel)
        
        NSLayoutConstraint.activate([
            noMusicLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            noMusicLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadMusic() {
        tracks = MusicStore.shared.getAllTracks()
        
        if tracks.isEmpty {
            tableView.isHidden = true
            noMusicLabel.isHidden = false
        } else {
            tableView.isHidden = false
            noMusicLabel.isHidden = true
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        closeSelection()
    }
    
    @objc private func closeButtonTapped() {
        closeSelection()
    }
    
    @objc private func refreshButtonTapped() {
        MusicStore.shared.refreshMusicLibrary()
        loadMusic()
        
        // Give user feedback
        refreshButton.setTitle("✅", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshButton.setTitle("🔄", for: .normal)
        }
    }
    
    private func closeSelection() {
        stopPreview()
        animateDisappearance {
            self.delegate?.musicSelectionDidCancel()
            self.dismiss(animated: false)
        }
    }
    
    // MARK: - Preview Playback
    
    private func playPreview(for track: MusicTrack, at indexPath: IndexPath) {
        stopPreview()
        
        do {
            previewPlayer = try AVAudioPlayer(contentsOf: track.url)
            previewPlayer?.volume = 0.3 // Lower volume for preview
            previewPlayer?.play()
            currentlyPlayingIndexPath = indexPath
            
            // Stop preview after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if self.currentlyPlayingIndexPath == indexPath {
                    self.stopPreview()
                }
            }
            
            // Update cell appearance
            if let cell = tableView.cellForRow(at: indexPath) as? MusicTrackCell {
                cell.setPlaying(true)
            }
            
        } catch {
            print("ERROR: Could not play preview for \(track.title): \(error)")
        }
    }
    
    private func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        
        if let playingIndexPath = currentlyPlayingIndexPath,
           let cell = tableView.cellForRow(at: playingIndexPath) as? MusicTrackCell {
            cell.setPlaying(false)
        }
        
        currentlyPlayingIndexPath = nil
    }
    
    // MARK: - Animations
    
    private func animateAppearance() {
        containerView.alpha = 0.0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.containerView.alpha = 1.0
            self.containerView.transform = CGAffineTransform.identity
        }
    }
    
    private func animateDisappearance(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.containerView.alpha = 0.0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.alpha = 0.0
        }) { _ in
            completion()
        }
    }
}

// MARK: - UITableViewDataSource

extension MusicSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicTrackCell", for: indexPath) as! MusicTrackCell
        let track = tracks[indexPath.row]
        cell.configure(with: track)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MusicSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let track = tracks[indexPath.row]
        
        // Check if file actually exists before selecting
        if FileManager.default.fileExists(atPath: track.url.path) {
            stopPreview()
            delegate?.musicSelectionDidSelect(track: track)
            dismiss(animated: true)
        } else {
            // File doesn't exist, show preview or error
            playPreview(for: track, at: indexPath)
        }
    }
}

// MARK: - Custom Table View Cell

class MusicTrackCell: UITableViewCell {
    
    private var titleLabel: UILabel!
    private var artistLabel: UILabel!
    private var durationLabel: UILabel!
    private var playingIndicator: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Title label
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Artist label
        artistLabel = UILabel()
        artistLabel.font = UIFont.systemFont(ofSize: 14)
        artistLabel.textColor = .lightGray
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artistLabel)
        
        // Duration label
        durationLabel = UILabel()
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.textColor = .cyan
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)
        
        // Playing indicator
        playingIndicator = UILabel()
        playingIndicator.text = "🎵"
        playingIndicator.font = UIFont.systemFont(ofSize: 16)
        playingIndicator.isHidden = true
        playingIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playingIndicator)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -10),
            
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: playingIndicator.leadingAnchor, constant: -10),
            durationLabel.widthAnchor.constraint(equalToConstant: 50),
            
            playingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playingIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            playingIndicator.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with track: MusicTrack) {
        titleLabel.text = track.title
        artistLabel.text = track.artist
        durationLabel.text = MusicStore.shared.formatDuration(track.duration)
        playingIndicator.isHidden = true
    }
    
    func setPlaying(_ isPlaying: Bool) {
        playingIndicator.isHidden = !isPlaying
    }
}