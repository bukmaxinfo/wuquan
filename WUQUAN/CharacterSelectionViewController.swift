//
//  CharacterSelectionViewController.swift
//  WUQUAN
//
//  Character + theme selection screen
//

import UIKit
import SpriteKit

// MARK: - Delegate Protocol

protocol CharacterSelectionDelegate: AnyObject {
    func characterSelectionDidComplete(
        playerStyle: CharacterStyle, playerVariant: CharacterColorVariant,
        opponentStyle: CharacterStyle, opponentVariant: CharacterColorVariant,
        gameMode: GameMode, theme: GameTheme
    )
}

// MARK: - View Controller

class CharacterSelectionViewController: UIViewController {

    weak var delegate: CharacterSelectionDelegate?

    // MARK: - Phase

    private enum SelectionPhase {
        case pickMode
        case pickPlayer        // pick character
        case pickPlayerColor   // pick color variant for player
        case pickOpponent      // pick character
        case pickOpponentColor // pick color variant for opponent
        case pickTheme         // pick arena theme
    }

    private var phase: SelectionPhase = .pickMode
    private var selectedGameMode: GameMode = .vsAI
    private var selectedPlayerStyle: CharacterStyle?
    private var selectedPlayerVariant: CharacterColorVariant = CharacterColorVariant.all[0]
    private var selectedOpponentStyle: CharacterStyle?
    private var selectedOpponentVariant: CharacterColorVariant = CharacterColorVariant.all[0]
    private var selectedPlayerIndex: Int?
    private var selectedOpponentIndex: Int?
    private var selectedTheme: GameTheme = .neon
    private var selectedThemeIndex: Int = 0

    private let characters = CharacterStyle.all
    private let themes = GameTheme.all
    private let colorVariants = CharacterColorVariant.all

    // MARK: - UI

    private var modeSelectionView: UIView!
    private var stepBar: UIView!
    private var stepDots: [UIView] = []
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var previewScene: SKView!
    private var collectionView: UICollectionView!
    private var colorVariantView: UIView!         // horizontal color strip
    private var colorVariantScroll: UIScrollView!
    private var themeSelectionView: UIView!
    private var startButton: UIButton!
    private var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupModeSelection()
    }

    // MARK: - Mode Selection Overlay

    private func setupModeSelection() {
        modeSelectionView = UIView()
        modeSelectionView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.97)
        modeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeSelectionView)

        NSLayoutConstraint.activate([
            modeSelectionView.topAnchor.constraint(equalTo: view.topAnchor),
            modeSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modeSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modeSelectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "舞 拳"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 40)
        titleLabel.textColor = UIColor(red: 1.0, green: 0.0, blue: 0.8, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        modeSelectionView.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "选择游戏模式"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18)
        subtitleLabel.textColor = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        modeSelectionView.addSubview(subtitleLabel)

        // Coin balance (top-right)
        let coinBalanceLabel = UILabel()
        coinBalanceLabel.text = "🪙 \(AccessoryStore.shared.coinBalance)"
        coinBalanceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        coinBalanceLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 0.9)
        coinBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        modeSelectionView.addSubview(coinBalanceLabel)

        let vsAIButton = makeModeButton(
            title: "VS 电脑", subtitle: "单人挑战 AI", emoji: "🤖",
            color: UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        )
        vsAIButton.tag = 0
        vsAIButton.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        modeSelectionView.addSubview(vsAIButton)

        let localButton = makeModeButton(
            title: "本地双人", subtitle: "两人同机对战", emoji: "👥",
            color: UIColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 1.0)
        )
        localButton.tag = 1
        localButton.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
        modeSelectionView.addSubview(localButton)

        // Store button — gold pill below mode buttons
        let storeButton = UIButton(type: .system)
        storeButton.setTitle("🛍️ 道具商店", for: .normal)
        storeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        storeButton.setTitleColor(UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 1.0), for: .normal)
        storeButton.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 0.12)
        storeButton.layer.cornerRadius = 20
        storeButton.layer.borderWidth = 1.5
        storeButton.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 0.5).cgColor
        storeButton.addTarget(self, action: #selector(storeTapped), for: .touchUpInside)
        storeButton.translatesAutoresizingMaskIntoConstraints = false
        modeSelectionView.addSubview(storeButton)

        NSLayoutConstraint.activate([
            coinBalanceLabel.trailingAnchor.constraint(equalTo: modeSelectionView.trailingAnchor, constant: -20),
            coinBalanceLabel.topAnchor.constraint(equalTo: modeSelectionView.safeAreaLayoutGuide.topAnchor, constant: 18),

            titleLabel.centerXAnchor.constraint(equalTo: modeSelectionView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: modeSelectionView.safeAreaLayoutGuide.topAnchor, constant: 60),

            subtitleLabel.centerXAnchor.constraint(equalTo: modeSelectionView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            vsAIButton.centerXAnchor.constraint(equalTo: modeSelectionView.centerXAnchor),
            vsAIButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            vsAIButton.widthAnchor.constraint(equalTo: modeSelectionView.widthAnchor, multiplier: 0.75),
            vsAIButton.heightAnchor.constraint(equalToConstant: 90),

            localButton.centerXAnchor.constraint(equalTo: modeSelectionView.centerXAnchor),
            localButton.topAnchor.constraint(equalTo: vsAIButton.bottomAnchor, constant: 24),
            localButton.widthAnchor.constraint(equalTo: modeSelectionView.widthAnchor, multiplier: 0.75),
            localButton.heightAnchor.constraint(equalToConstant: 90),

            storeButton.centerXAnchor.constraint(equalTo: modeSelectionView.centerXAnchor),
            storeButton.topAnchor.constraint(equalTo: localButton.bottomAnchor, constant: 32),
            storeButton.widthAnchor.constraint(equalToConstant: 180),
            storeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func makeModeButton(title: String, subtitle: String, emoji: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color.withAlphaComponent(0.15)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 2
        button.layer.borderColor = color.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 30)
        stack.addArrangedSubview(emojiLabel)

        let titleL = UILabel()
        titleL.text = title
        titleL.font = UIFont.boldSystemFont(ofSize: 20)
        titleL.textColor = color
        stack.addArrangedSubview(titleL)

        let subL = UILabel()
        subL.text = subtitle
        subL.font = UIFont.systemFont(ofSize: 13)
        subL.textColor = UIColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(subL)

        return button
    }

    @objc private func modeTapped(_ sender: UIButton) {
        selectedGameMode = sender.tag == 0 ? .vsAI : .localMultiplayer
        UIView.animate(withDuration: 0.3, animations: {
            self.modeSelectionView.alpha = 0
        }, completion: { _ in
            self.modeSelectionView.removeFromSuperview()
            self.transitionToPhase(.pickPlayer)
        })
    }

    @objc private func storeTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let storeVC = StoreViewController()
        storeVC.modalPresentationStyle = .fullScreen
        present(storeVC, animated: false)
    }

    // MARK: - Main UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)

        // Step indicator bar
        stepBar = UIView()
        stepBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepBar)

        // Title / Subtitle
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        subtitleLabel = UILabel()
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = .cyan
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Preview SKView
        previewScene = SKView()
        previewScene.isUserInteractionEnabled = false
        previewScene.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1)
        previewScene.layer.cornerRadius = 14
        previewScene.layer.borderWidth = 1.5
        previewScene.layer.borderColor = UIColor.cyan.withAlphaComponent(0.4).cgColor
        previewScene.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewScene)

        // Character grid collection view
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CharacterCell.self, forCellWithReuseIdentifier: "CharacterCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        // Color variant strip (hidden by default)
        setupColorVariantView()

        // Theme selection view (hidden by default)
        setupThemeSelectionView()

        // Start button
        startButton = UIButton(type: .system)
        startButton.setTitle("开始游戏！", for: .normal)
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        startButton.setTitleColor(.black, for: .normal)
        startButton.backgroundColor = .cyan
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.isHidden = true
        view.addSubview(startButton)

        // Back button
        backButton = UIButton(type: .system)
        backButton.setTitle("← 返回", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        backButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isHidden = true
        view.addSubview(backButton)

        // Step dots
        buildStepDots()

        NSLayoutConstraint.activate([
            stepBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stepBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            stepBar.heightAnchor.constraint(equalToConstant: 20),

            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: stepBar.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: stepBar.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            previewScene.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            previewScene.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewScene.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            previewScene.heightAnchor.constraint(equalToConstant: 130),

            colorVariantView.topAnchor.constraint(equalTo: previewScene.bottomAnchor, constant: 8),
            colorVariantView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            colorVariantView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            colorVariantView.heightAnchor.constraint(equalToConstant: 54),

            collectionView.topAnchor.constraint(equalTo: colorVariantView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -10),

            themeSelectionView.topAnchor.constraint(equalTo: previewScene.bottomAnchor, constant: 12),
            themeSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            themeSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            themeSelectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -10),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Step Dots

    private func buildStepDots() {
        let stepCount = 4  // player, playerColor, opponent, opponentColor / theme combined
        let dotSize: CGFloat = 10
        let spacing: CGFloat = 14
        let totalW = CGFloat(stepCount) * dotSize + CGFloat(stepCount - 1) * spacing

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        stepBar.addSubview(container)
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: stepBar.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: stepBar.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: totalW),
            container.heightAnchor.constraint(equalToConstant: dotSize)
        ])

        for i in 0..<stepCount {
            let dot = UIView()
            dot.layer.cornerRadius = dotSize / 2
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            dot.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize),
                dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                dot.leadingAnchor.constraint(equalTo: container.leadingAnchor,
                                              constant: CGFloat(i) * (dotSize + spacing))
            ])
            stepDots.append(dot)
        }
    }

    private func updateStepDots(activeIndex: Int) {
        for (i, dot) in stepDots.enumerated() {
            dot.backgroundColor = i == activeIndex
                ? UIColor.cyan
                : (i < activeIndex ? UIColor.cyan.withAlphaComponent(0.4)
                                   : UIColor.white.withAlphaComponent(0.2))
            dot.transform = i == activeIndex ? CGAffineTransform(scaleX: 1.3, y: 1.3) : .identity
        }
    }

    // MARK: - Color Variant Strip

    private func setupColorVariantView() {
        colorVariantView = UIView()
        colorVariantView.translatesAutoresizingMaskIntoConstraints = false
        colorVariantView.isHidden = true
        view.addSubview(colorVariantView)

        let label = UILabel()
        label.text = "选择颜色"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.translatesAutoresizingMaskIntoConstraints = false
        colorVariantView.addSubview(label)

        colorVariantScroll = UIScrollView()
        colorVariantScroll.showsHorizontalScrollIndicator = false
        colorVariantScroll.translatesAutoresizingMaskIntoConstraints = false
        colorVariantView.addSubview(colorVariantScroll)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: colorVariantView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: colorVariantView.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 48),

            colorVariantScroll.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            colorVariantScroll.trailingAnchor.constraint(equalTo: colorVariantView.trailingAnchor),
            colorVariantScroll.topAnchor.constraint(equalTo: colorVariantView.topAnchor, constant: 6),
            colorVariantScroll.bottomAnchor.constraint(equalTo: colorVariantView.bottomAnchor, constant: -6),
        ])

        rebuildColorButtons(selectedIndex: 0)
    }

    private func rebuildColorButtons(selectedIndex: Int) {
        colorVariantScroll.subviews.forEach { $0.removeFromSuperview() }

        let size: CGFloat = 36
        let gap: CGFloat = 10
        let padding: CGFloat = 8

        for (i, variant) in colorVariants.enumerated() {
            let btn = UIButton(type: .custom)
            btn.tag = i
            btn.layer.cornerRadius = size / 2
            btn.backgroundColor = variant.tint
            btn.layer.borderWidth = i == selectedIndex ? 3 : 1.5
            btn.layer.borderColor = i == selectedIndex
                ? UIColor.white.cgColor
                : UIColor.white.withAlphaComponent(0.3).cgColor
            btn.addTarget(self, action: #selector(colorVariantTapped(_:)), for: .touchUpInside)

            let x = padding + CGFloat(i) * (size + gap)
            btn.frame = CGRect(x: x, y: 0, width: size, height: size)
            colorVariantScroll.addSubview(btn)
        }

        let totalW = padding * 2 + CGFloat(colorVariants.count) * size + CGFloat(colorVariants.count - 1) * gap
        colorVariantScroll.contentSize = CGSize(width: totalW, height: size)
    }

    @objc private func colorVariantTapped(_ sender: UIButton) {
        AnimationKit.tapPulse(sender)
        UISelectionFeedbackGenerator().selectionChanged()
        let index = sender.tag
        let variant = colorVariants[index]

        switch phase {
        case .pickPlayerColor:
            selectedPlayerVariant = variant
        case .pickOpponentColor:
            selectedOpponentVariant = variant
        default:
            break
        }

        rebuildColorButtons(selectedIndex: index)
        updatePreview()
    }

    // MARK: - Theme Selection View

    private func setupThemeSelectionView() {
        themeSelectionView = UIView()
        themeSelectionView.translatesAutoresizingMaskIntoConstraints = false
        themeSelectionView.isHidden = true
        view.addSubview(themeSelectionView)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        themeSelectionView.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: themeSelectionView.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: themeSelectionView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: themeSelectionView.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: themeSelectionView.bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -8),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        for (i, theme) in themes.enumerated() {
            let card = makeThemeCard(theme: theme, index: i, selected: i == selectedThemeIndex)
            stack.addArrangedSubview(card)
        }
    }

    private func makeThemeCard(theme: GameTheme, index: Int, selected: Bool) -> UIView {
        let card = UIButton(type: .custom)
        card.tag = index
        card.layer.cornerRadius = 14
        card.layer.borderWidth = selected ? 2.5 : 1
        card.layer.borderColor = selected ? theme.accentColor.cgColor : UIColor.white.withAlphaComponent(0.15).cgColor
        card.backgroundColor = UIColor(cgColor: theme.accentColor.cgColor).withAlphaComponent(0.08)
        card.addTarget(self, action: #selector(themeTapped(_:)), for: .touchUpInside)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 64).isActive = true

        // Color swatch strip at left
        let swatch = UIView()
        swatch.isUserInteractionEnabled = false
        swatch.layer.cornerRadius = 8
        swatch.backgroundColor = theme.accentColor
        swatch.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(swatch)

        let secondarySwatch = UIView()
        secondarySwatch.isUserInteractionEnabled = false
        secondarySwatch.layer.cornerRadius = 8
        secondarySwatch.backgroundColor = theme.secondaryColor
        secondarySwatch.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(secondarySwatch)

        let emojiLabel = UILabel()
        emojiLabel.text = theme.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 26)
        emojiLabel.isUserInteractionEnabled = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emojiLabel)

        let nameLabel = UILabel()
        nameLabel.text = theme.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 17)
        nameLabel.textColor = selected ? theme.accentColor : .white
        nameLabel.isUserInteractionEnabled = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        let checkmark = UILabel()
        checkmark.text = selected ? "✓" : ""
        checkmark.font = UIFont.boldSystemFont(ofSize: 18)
        checkmark.textColor = theme.accentColor
        checkmark.isUserInteractionEnabled = false
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(checkmark)

        NSLayoutConstraint.activate([
            swatch.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            swatch.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: -6),
            swatch.widthAnchor.constraint(equalToConstant: 16),
            swatch.heightAnchor.constraint(equalToConstant: 16),

            secondarySwatch.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            secondarySwatch.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 6),
            secondarySwatch.widthAnchor.constraint(equalToConstant: 16),
            secondarySwatch.heightAnchor.constraint(equalToConstant: 16),

            emojiLabel.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 12),
            emojiLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            checkmark.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            checkmark.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        return card
    }

    @objc private func themeTapped(_ sender: UIButton) {
        AnimationKit.tapPulse(sender)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedThemeIndex = sender.tag
        selectedTheme = themes[sender.tag]
        // Rebuild theme cards with new selection
        rebuildThemeCards()
        updatePreview()
        // Show start button now with bounce-in if first selection
        let wasHidden = startButton.isHidden
        startButton.isHidden = false
        startButton.backgroundColor = selectedTheme.accentColor
        startButton.setTitleColor(.black, for: .normal)
        if wasHidden { AnimationKit.bounceIn(startButton, delay: 0.05) }
    }

    private func rebuildThemeCards() {
        guard let scroll = themeSelectionView.subviews.first as? UIScrollView,
              let stack = scroll.subviews.first as? UIStackView else { return }

        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        for (i, theme) in themes.enumerated() {
            stack.addArrangedSubview(makeThemeCard(theme: theme, index: i, selected: i == selectedThemeIndex))
        }
    }

    // MARK: - Phase Transitions

    private func transitionToPhase(_ newPhase: SelectionPhase) {
        phase = newPhase

        let animate = {
            switch newPhase {
            case .pickPlayer:
                self.titleLabel.text = "选择玩家 1 角色"
                self.subtitleLabel.text = "你是谁？"
                self.subtitleLabel.textColor = .cyan
                self.collectionView.isHidden = false
                self.colorVariantView.isHidden = true
                self.themeSelectionView.isHidden = true
                self.startButton.isHidden = true
                self.backButton.isHidden = true
                self.collectionView.reloadData()
                self.updateStepDots(activeIndex: 0)

            case .pickPlayerColor:
                self.titleLabel.text = "选择颜色"
                self.subtitleLabel.text = "\(self.selectedPlayerStyle?.name ?? "") 的专属配色"
                self.subtitleLabel.textColor = .cyan
                self.colorVariantView.isHidden = false
                self.collectionView.isHidden = true
                self.themeSelectionView.isHidden = true
                self.startButton.isHidden = false
                self.startButton.setTitle("下一步 →", for: .normal)
                self.startButton.backgroundColor = .cyan
                self.startButton.setTitleColor(.black, for: .normal)
                self.backButton.isHidden = false
                self.rebuildColorButtons(selectedIndex: 0)
                self.updateStepDots(activeIndex: 0)
                self.updatePreview()

            case .pickOpponent:
                if self.selectedGameMode == .localMultiplayer {
                    self.titleLabel.text = "选择玩家 2 角色"
                    self.subtitleLabel.text = "玩家 2 是谁？"
                } else {
                    self.titleLabel.text = "选择对手角色"
                    self.subtitleLabel.text = "谁是你的对手？"
                }
                self.subtitleLabel.textColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
                self.collectionView.isHidden = false
                self.colorVariantView.isHidden = true
                self.themeSelectionView.isHidden = true
                self.startButton.isHidden = true
                self.backButton.isHidden = false
                self.collectionView.reloadData()
                self.updateStepDots(activeIndex: 1)

            case .pickOpponentColor:
                let p2Name = self.selectedGameMode == .localMultiplayer ? "玩家 2" : "对手"
                self.titleLabel.text = "选择颜色"
                self.subtitleLabel.text = "\(p2Name) \(self.selectedOpponentStyle?.name ?? "") 的配色"
                self.subtitleLabel.textColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
                self.colorVariantView.isHidden = false
                self.collectionView.isHidden = true
                self.themeSelectionView.isHidden = true
                self.startButton.isHidden = false
                self.startButton.setTitle("下一步 →", for: .normal)
                self.startButton.backgroundColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
                self.startButton.setTitleColor(.white, for: .normal)
                self.backButton.isHidden = false
                self.rebuildColorButtons(selectedIndex: 0)
                self.updateStepDots(activeIndex: 2)
                self.updatePreview()

            case .pickTheme:
                self.titleLabel.text = "选择舞台主题"
                self.subtitleLabel.text = "为你们的对决设置氛围"
                self.subtitleLabel.textColor = .yellow
                self.collectionView.isHidden = true
                self.colorVariantView.isHidden = true
                self.themeSelectionView.isHidden = false
                self.startButton.isHidden = true
                self.backButton.isHidden = false
                self.updateStepDots(activeIndex: 3)
                self.rebuildThemeCards()
                self.updatePreview()

            case .pickMode:
                break
            }
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve,
                          animations: animate, completion: { [weak self] _ in
            // Slide-up the start button on phases where it appears fresh
            guard let self else { return }
            if !self.startButton.isHidden {
                AnimationKit.slideUp(self.startButton, delay: 0.05)
            }
        })
    }

    // MARK: - Preview

    private func updatePreview() {
        guard previewScene.bounds.width > 0 else { return }
        let scene = SKScene(size: previewScene.bounds.size)
        scene.backgroundColor = SKColor(cgColor: selectedTheme.backgroundColor.cgColor)

        let spriteHeight = scene.size.height * 0.6

        func addCharacter(style: CharacterStyle, variant: CharacterColorVariant,
                          xFraction: CGFloat, labelColor: SKColor, mirrored: Bool) {
            let textureName = "\(style.id)_idle"
            if let path = Bundle.main.path(forResource: textureName, ofType: "png"),
               let uiImage = UIImage(contentsOfFile: path) {
                let texture = SKTexture(image: uiImage)
                let sprite = SKSpriteNode(texture: texture)
                let aspect = texture.size().width / texture.size().height
                sprite.size = CGSize(width: spriteHeight * aspect, height: spriteHeight)
                sprite.position = CGPoint(x: scene.size.width * xFraction, y: scene.size.height * 0.48)
                if mirrored { sprite.xScale = -abs(sprite.xScale) }
                // Apply color tint
                if variant.blendFactor > 0 {
                    sprite.color = variant.skTint
                    sprite.colorBlendFactor = variant.blendFactor
                }
                scene.addChild(sprite)

                // Overlay equipped accessories onto the preview sprite
                for item in AccessoryStore.shared.equippedItems {
                    let accNode = AccessoryNode(item: item, characterHeight: spriteHeight)
                    if mirrored { accNode.applyMirrorCompensation() }
                    sprite.addChild(accNode)
                }
            }

            let lbl = SKLabelNode(text: style.name)
            lbl.fontSize = 11
            lbl.fontColor = labelColor
            lbl.position = CGPoint(x: scene.size.width * xFraction, y: scene.size.height * 0.06)
            scene.addChild(lbl)
        }

        if let pStyle = selectedPlayerStyle {
            addCharacter(style: pStyle, variant: selectedPlayerVariant,
                         xFraction: 0.25, labelColor: .cyan, mirrored: true)
        }
        if let oStyle = selectedOpponentStyle {
            addCharacter(style: oStyle, variant: selectedOpponentVariant,
                         xFraction: 0.75, labelColor: SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1), mirrored: false)
        }
        if selectedPlayerStyle != nil && selectedOpponentStyle != nil {
            let vs = SKLabelNode(text: "VS")
            vs.fontSize = 22
            vs.fontColor = .yellow
            vs.fontName = "Helvetica-Bold"
            vs.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.45)
            scene.addChild(vs)
        }

        previewScene.presentScene(scene)
        // Update preview border to theme accent
        previewScene.layer.borderColor = selectedTheme.accentColor.withAlphaComponent(0.5).cgColor
    }

    // MARK: - Actions

    @objc private func backTapped() {
        AnimationKit.tapPulse(backButton)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch phase {
        case .pickPlayerColor: transitionToPhase(.pickPlayer)
        case .pickOpponent:    transitionToPhase(.pickPlayerColor)
        case .pickOpponentColor: transitionToPhase(.pickOpponent)
        case .pickTheme:       transitionToPhase(.pickOpponentColor)
        default: break
        }
    }

    @objc private func startTapped() {
        AnimationKit.tapPulse(startButton)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch phase {
        case .pickPlayerColor:
            transitionToPhase(.pickOpponent)
        case .pickOpponentColor:
            transitionToPhase(.pickTheme)
        case .pickTheme:
            guard let pStyle = selectedPlayerStyle, let oStyle = selectedOpponentStyle else { return }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            delegate?.characterSelectionDidComplete(
                playerStyle: pStyle, playerVariant: selectedPlayerVariant,
                opponentStyle: oStyle, opponentVariant: selectedOpponentVariant,
                gameMode: selectedGameMode, theme: selectedTheme
            )
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CharacterSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
        let char = characters[indexPath.item]
        cell.configure(with: char)

        if indexPath.item == selectedPlayerIndex {
            cell.setSelected(role: .player)
        } else if indexPath.item == selectedOpponentIndex {
            cell.setSelected(role: .opponent)
        } else {
            cell.setSelected(role: nil)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CharacterSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let char = characters[indexPath.item]

        // Spring bounce on the tapped cell
        if let cell = collectionView.cellForItem(at: indexPath) {
            AnimationKit.tapPulse(cell)
        }

        switch phase {
        case .pickPlayer:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedPlayerStyle = char
            selectedPlayerIndex = indexPath.item
            selectedPlayerVariant = CharacterColorVariant.all[0]
            collectionView.reloadData()
            updatePreview()
            transitionToPhase(.pickPlayerColor)

        case .pickOpponent:
            if indexPath.item == selectedPlayerIndex {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                shakeCellAt(indexPath)
                return
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedOpponentStyle = char
            selectedOpponentIndex = indexPath.item
            selectedOpponentVariant = CharacterColorVariant.all[0]
            collectionView.reloadData()
            updatePreview()
            transitionToPhase(.pickOpponentColor)

        default:
            break
        }
    }

    private func shakeCellAt(_ indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: .linear)
        shake.values = [-8, 8, -6, 6, -3, 3, 0]
        shake.duration = 0.4
        cell.layer.add(shake, forKey: "shake")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CharacterSelectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 3 * 8) / 4
        return CGSize(width: width, height: width * 1.3)
    }
}

// MARK: - CharacterCell

class CharacterCell: UICollectionViewCell {

    enum SelectedRole { case player, opponent }

    private var spriteImageView: UIImageView!
    private var nameLabel: UILabel!
    private var emojiLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor(white: 0.25, alpha: 1).cgColor

        // Emoji fallback (behind sprite)
        emojiLabel = UILabel()
        emojiLabel.font = UIFont.systemFont(ofSize: 28)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiLabel)

        spriteImageView = UIImageView()
        spriteImageView.contentMode = .scaleAspectFit
        spriteImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spriteImageView)

        nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 9)
        nameLabel.textColor = .lightGray
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),

            spriteImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            spriteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            spriteImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            spriteImageView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -2),

            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            nameLabel.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    func configure(with style: CharacterStyle) {
        nameLabel.text = style.name
        emojiLabel.text = style.emoji

        if let path = Bundle.main.path(forResource: "\(style.id)_idle", ofType: "png") {
            spriteImageView.image = UIImage(contentsOfFile: path)
            emojiLabel.isHidden = true
        } else {
            spriteImageView.image = nil
            emojiLabel.isHidden = false
        }
    }

    func setSelected(role: SelectedRole?) {
        switch role {
        case .player:
            contentView.layer.borderColor = UIColor.cyan.cgColor
            contentView.layer.borderWidth = 3
            contentView.backgroundColor = UIColor.cyan.withAlphaComponent(0.12)
            nameLabel.textColor = .cyan
        case .opponent:
            contentView.layer.borderColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1).cgColor
            contentView.layer.borderWidth = 3
            contentView.backgroundColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.12)
            nameLabel.textColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
        case nil:
            contentView.layer.borderColor = UIColor(white: 0.25, alpha: 1).cgColor
            contentView.layer.borderWidth = 2
            contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
            nameLabel.textColor = .lightGray
        }
    }
}
