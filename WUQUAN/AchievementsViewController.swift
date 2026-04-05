//
//  AchievementsViewController.swift
//  WUQUAN
//
//  Displays local achievement progress in a full-screen panel.
//  Accessible from the game's settings/pause menu.
//

import UIKit

class AchievementsViewController: UIViewController {

    private var tableView: UITableView!
    private var achievements: [Achievement] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        achievements = AchievementsManager.shared.all
        setupUI()
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.97)

        // Header
        let titleLabel = UILabel()
        titleLabel.text = "成就"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let progressLabel = UILabel()
        let unlocked = achievements.filter { $0.isUnlocked }.count
        progressLabel.text = "\(unlocked) / \(achievements.count) 已解锁"
        progressLabel.font = UIFont.systemFont(ofSize: 14)
        progressLabel.textColor = UIColor.cyan.withAlphaComponent(0.8)
        progressLabel.textAlignment = .center
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressLabel)

        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)

        // Game Center button
        let gcBtn = UIButton(type: .system)
        gcBtn.setTitle("Game Center 成就 →", for: .normal)
        gcBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        gcBtn.setTitleColor(.cyan, for: .normal)
        gcBtn.addTarget(self, action: #selector(openGameCenter), for: .touchUpInside)
        gcBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gcBtn)

        // Table
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.register(AchievementCell.self, forCellReuseIdentifier: "AchievementCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            gcBtn.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            gcBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: gcBtn.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func openGameCenter() {
        GameCenterManager.shared.showAchievements(from: self)
    }
}

// MARK: - UITableViewDataSource

extension AchievementsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        achievements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCell", for: indexPath) as! AchievementCell
        cell.configure(with: achievements[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AchievementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - AchievementCell

private class AchievementCell: UITableViewCell {

    private let emojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let progressBar = UIProgressView()
    private let progressLabel = UILabel()
    private let lockIcon = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupSubviews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupSubviews() {
        [emojiLabel, nameLabel, descLabel, progressBar, progressLabel, lockIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        emojiLabel.font = UIFont.systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center

        nameLabel.font = UIFont.boldSystemFont(ofSize: 15)
        nameLabel.textColor = .white

        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        descLabel.numberOfLines = 1

        progressBar.progressTintColor = .cyan
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.1)
        progressBar.layer.cornerRadius = 3
        progressBar.clipsToBounds = true

        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        progressLabel.textColor = UIColor.cyan.withAlphaComponent(0.8)
        progressLabel.textAlignment = .right

        lockIcon.font = UIFont.systemFont(ofSize: 18)
        lockIcon.textAlignment = .center

        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),

            lockIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lockIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 24),

            progressLabel.trailingAnchor.constraint(equalTo: lockIcon.leadingAnchor, constant: -8),
            progressLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressLabel.widthAnchor.constraint(equalToConstant: 52),

            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            progressBar.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -8),
            progressBar.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 6),
            progressBar.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    func configure(with achievement: Achievement) {
        emojiLabel.text = achievement.emoji
        nameLabel.text = NSLocalizedString(achievement.localizedKey, comment: "")
        descLabel.text = achievement.description

        let progress = min(Float(achievement.progress) / Float(achievement.maxProgress), 1.0)
        progressBar.progress = progress

        if achievement.maxProgress == 1 {
            progressLabel.text = achievement.isUnlocked ? "✓" : "0/1"
        } else {
            progressLabel.text = "\(achievement.progress)/\(achievement.maxProgress)"
        }

        lockIcon.text = achievement.isUnlocked ? "🔓" : "🔒"
        nameLabel.textColor = achievement.isUnlocked ? .white : UIColor.white.withAlphaComponent(0.4)
        emojiLabel.alpha = achievement.isUnlocked ? 1.0 : 0.35
        progressBar.progressTintColor = achievement.isUnlocked ? .yellow : .cyan
    }
}
