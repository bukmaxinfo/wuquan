//
//  StoreViewController.swift
//  WUQUAN
//
//  In-game accessory store. Full-screen modal.
//  Layout (top→bottom):
//    • Header bar  — title, coin balance, close button
//    • Character preview — SKView showing character with live accessory preview
//    • Category tabs  — horizontal scrolling pill buttons (Hat/Glasses/Cape/Glove/Aura)
//    • Item grid  — UICollectionView 3-col, scrollable
//    • Action panel — slides up when an item is selected (price + buy/equip button)
//

import UIKit
import SpriteKit

class StoreViewController: UIViewController {

    // MARK: - Configuration

    /// Pass a CharacterStyle to display in the preview; defaults to first available.
    var previewStyle: CharacterStyle = CharacterStyle.all.first ?? CharacterStyle.all[0]

    // MARK: - State

    private var currentCategory: AccessoryCategory = .hats
    private var selectedItem: AccessoryItem?
    private var previewCharacter: SpriteCharacterNode?

    // MARK: - UI

    private var headerView: UIView!
    private var coinLabel: UILabel!
    private var previewSKView: SKView!
    private var previewScene: SKScene!
    private var categoryScrollView: UIScrollView!
    private var categoryButtons: [AccessoryCategory: UIButton] = [:]
    private var collectionView: UICollectionView!
    private var actionPanel: UIView!
    private var actionPanelBottom: NSLayoutConstraint!
    private var actionItemLabel: UILabel!
    private var actionPriceLabel: UILabel!
    private var actionButton: UIButton!

    // MARK: - Palette

    private let bg       = UIColor(red: 0.04, green: 0.02, blue: 0.10, alpha: 1)
    private let panel    = UIColor(red: 0.10, green: 0.05, blue: 0.18, alpha: 1)
    private let accent   = UIColor.cyan
    private let gold     = UIColor(red: 1.0,  green: 0.85, blue: 0.15, alpha: 1)
    private let textMid  = UIColor(white: 0.65, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bg
        buildUI()
        selectCategory(.hats, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshPreview(previewItem: nil)
    }

    // MARK: - UI Construction

    private func buildUI() {
        buildHeader()
        buildPreviewView()
        buildCategoryTabs()
        buildCollectionView()
        buildActionPanel()
    }

    // ── Header ────────────────────────────────────────────────────────────

    private func buildHeader() {
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "🛍️ 商店"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Coin balance
        coinLabel = UILabel()
        coinLabel.font = UIFont.boldSystemFont(ofSize: 16)
        coinLabel.textColor = gold
        coinLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(coinLabel)
        updateCoinLabel()

        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeBtn.setTitleColor(.lightGray, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeBtn)

        // Separator
        let sep = UIView()
        sep.backgroundColor = UIColor.cyan.withAlphaComponent(0.25)
        sep.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(sep)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            coinLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            coinLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),

            closeBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            sep.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // ── Preview ───────────────────────────────────────────────────────────

    private func buildPreviewView() {
        previewSKView = SKView()
        previewSKView.backgroundColor = UIColor(red: 0.06, green: 0.03, blue: 0.12, alpha: 1)
        previewSKView.translatesAutoresizingMaskIntoConstraints = false
        previewSKView.allowsTransparency = true
        previewSKView.layer.borderColor = UIColor.cyan.withAlphaComponent(0.2).cgColor
        previewSKView.layer.borderWidth = 1
        view.addSubview(previewSKView)

        NSLayoutConstraint.activate([
            previewSKView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            previewSKView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewSKView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewSKView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.26)
        ])
    }

    private func buildPreviewScene() {
        let size = previewSKView.bounds.size
        guard size.width > 0 else { return }

        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        scene.scaleMode = .aspectFill
        previewScene = scene

        // Subtle neon floor hint
        let floorLine = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        floorLine.fillColor = UIColor.cyan.withAlphaComponent(0.18).skColor
        floorLine.strokeColor = .clear
        floorLine.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        scene.addChild(floorLine)

        // Character
        let charHeight = size.height * 0.72
        let charNode = SpriteCharacterNode(height: charHeight, style: previewStyle, mirrored: false)
        charNode.position = CGPoint(x: size.width / 2, y: size.height * 0.48)
        charNode.animateIdle()
        scene.addChild(charNode)
        previewCharacter = charNode

        previewSKView.presentScene(scene)
    }

    private func refreshPreview(previewItem: AccessoryItem?) {
        if previewScene == nil { buildPreviewScene() }
        guard let char = previewCharacter else { return }
        let equipped = AccessoryStore.shared.equippedItems
        char.previewAccessories(equipped: equipped, preview: previewItem)
    }

    // ── Category Tabs ─────────────────────────────────────────────────────

    private func buildCategoryTabs() {
        categoryScrollView = UIScrollView()
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.backgroundColor = panel
        view.addSubview(categoryScrollView)

        NSLayoutConstraint.activate([
            categoryScrollView.topAnchor.constraint(equalTo: previewSKView.bottomAnchor),
            categoryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 50)
        ])

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: categoryScrollView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -12)
        ])

        for cat in AccessoryCategory.allCases {
            let btn = makeCategoryButton(cat)
            categoryButtons[cat] = btn
            stack.addArrangedSubview(btn)
        }
    }

    private func makeCategoryButton(_ cat: AccessoryCategory) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("\(cat.tabEmoji) \(cat.displayName)", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        btn.layer.cornerRadius = 16
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        btn.tag = AccessoryCategory.allCases.firstIndex(of: cat) ?? 0
        btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let cat = AccessoryCategory.allCases[sender.tag]
        AnimationKit.tapPulse(sender)
        UISelectionFeedbackGenerator().selectionChanged()
        selectCategory(cat, animated: true)
    }

    private func selectCategory(_ cat: AccessoryCategory, animated: Bool) {
        currentCategory = cat
        selectedItem = nil
        hideActionPanel(animated: animated)

        for (c, btn) in categoryButtons {
            let isSelected = c == cat
            UIView.animate(withDuration: animated ? 0.2 : 0) {
                btn.backgroundColor = isSelected
                    ? UIColor.cyan.withAlphaComponent(0.25)
                    : UIColor.white.withAlphaComponent(0.08)
                btn.layer.borderWidth = isSelected ? 1.5 : 0
                btn.layer.borderColor = UIColor.cyan.cgColor
            }
        }

        collectionView.reloadData()
        if collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                        at: .top, animated: false)
        }

        // Remove preview overlay
        refreshPreview(previewItem: nil)
    }

    // ── Item Grid ─────────────────────────────────────────────────────────

    private func buildCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 100, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = bg
        collectionView.register(AccessoryCell.self, forCellWithReuseIdentifier: "AccessoryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // ── Action Panel ──────────────────────────────────────────────────────

    private func buildActionPanel() {
        actionPanel = UIView()
        actionPanel.backgroundColor = UIColor(red: 0.10, green: 0.06, blue: 0.20, alpha: 0.98)
        actionPanel.layer.cornerRadius = 20
        actionPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        actionPanel.layer.borderColor = UIColor.cyan.withAlphaComponent(0.5).cgColor
        actionPanel.layer.borderWidth = 1.5
        actionPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionPanel)

        actionItemLabel = UILabel()
        actionItemLabel.font = UIFont.boldSystemFont(ofSize: 22)
        actionItemLabel.textColor = .white
        actionItemLabel.textAlignment = .center
        actionItemLabel.translatesAutoresizingMaskIntoConstraints = false
        actionPanel.addSubview(actionItemLabel)

        actionPriceLabel = UILabel()
        actionPriceLabel.font = UIFont.systemFont(ofSize: 15)
        actionPriceLabel.textColor = textMid
        actionPriceLabel.textAlignment = .center
        actionPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        actionPanel.addSubview(actionPriceLabel)

        actionButton = UIButton(type: .system)
        actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        actionButton.layer.cornerRadius = 12
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionPanel.addSubview(actionButton)

        actionPanelBottom = actionPanel.bottomAnchor.constraint(
            equalTo: view.bottomAnchor, constant: 140)

        NSLayoutConstraint.activate([
            actionPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionPanel.heightAnchor.constraint(equalToConstant: 130),
            actionPanelBottom,

            actionItemLabel.topAnchor.constraint(equalTo: actionPanel.topAnchor, constant: 16),
            actionItemLabel.centerXAnchor.constraint(equalTo: actionPanel.centerXAnchor),

            actionPriceLabel.topAnchor.constraint(equalTo: actionItemLabel.bottomAnchor, constant: 4),
            actionPriceLabel.centerXAnchor.constraint(equalTo: actionPanel.centerXAnchor),

            actionButton.topAnchor.constraint(equalTo: actionPriceLabel.bottomAnchor, constant: 12),
            actionButton.centerXAnchor.constraint(equalTo: actionPanel.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func showActionPanel(for item: AccessoryItem) {
        selectedItem = item
        actionItemLabel.text = "\(item.emoji)  \(item.name)"

        if item.isOwned {
            if item.isEquipped {
                actionPriceLabel.text = "已装备"
                actionPriceLabel.textColor = accent
                configureActionButton(title: "卸下", color: UIColor(white: 0.3, alpha: 1))
            } else {
                actionPriceLabel.text = "已拥有"
                actionPriceLabel.textColor = textMid
                configureActionButton(title: "装备", color: UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 1))
            }
        } else {
            let canAfford = AccessoryStore.shared.coinBalance >= item.price
            actionPriceLabel.text = "🪙 \(item.price)"
            actionPriceLabel.textColor = canAfford ? gold : UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
            let btnColor: UIColor = canAfford
                ? UIColor(red: 0.1, green: 0.55, blue: 0.15, alpha: 1)
                : UIColor(white: 0.2, alpha: 1)
            configureActionButton(title: canAfford ? "购买  🪙\(item.price)" : "金币不足", color: btnColor)
            actionButton.isEnabled = canAfford
        }

        // Slide up
        actionPanelBottom.constant = 0
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    private func hideActionPanel(animated: Bool) {
        selectedItem = nil
        actionPanelBottom.constant = 140
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseIn) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    private func configureActionButton(title: String, color: UIColor) {
        actionButton.setTitle(title, for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = color
        actionButton.isEnabled = true
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        AnimationKit.bounceOut(view) { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    @objc private func actionButtonTapped() {
        guard let item = selectedItem else { return }
        AnimationKit.tapPulse(actionButton)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if item.isOwned {
            if item.isEquipped {
                AccessoryStore.shared.unequip(item)
            } else {
                AccessoryStore.shared.equip(item)
            }
        } else {
            let success = AccessoryStore.shared.purchase(item)
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showPurchaseFlash()
                AccessoryStore.shared.equip(item)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
        }

        updateCoinLabel()
        collectionView.reloadData()
        refreshPreview(previewItem: nil)

        // Re-show panel with updated state
        if let fresh = AccessoryItem.all.first(where: { $0.id == item.id }) {
            showActionPanel(for: fresh)
        }
    }

    private func showPurchaseFlash() {
        let flash = UIView()
        flash.backgroundColor = UIColor.cyan.withAlphaComponent(0.25)
        flash.frame = view.bounds
        view.addSubview(flash)
        UIView.animate(withDuration: 0.4) { flash.alpha = 0 } completion: { _ in flash.removeFromSuperview() }
    }

    // MARK: - Helpers

    private func updateCoinLabel() {
        coinLabel.text = "🪙 \(AccessoryStore.shared.coinBalance)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Entrance animation
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.3, delay: 0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }
}

// MARK: - UICollectionViewDataSource

extension StoreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        AccessoryItem.items(in: currentCategory).count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "AccessoryCell", for: indexPath) as! AccessoryCell
        let items = AccessoryItem.items(in: currentCategory)
        let item = items[indexPath.item]
        cell.configure(with: item,
                       isSelected: selectedItem?.id == item.id,
                       coinBalance: AccessoryStore.shared.coinBalance)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StoreViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let item = AccessoryItem.items(in: currentCategory)[indexPath.item]
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Animate tap on cell
        if let cell = collectionView.cellForItem(at: indexPath) {
            AnimationKit.tapPulse(cell)
        }

        selectedItem = item
        collectionView.reloadData()
        showActionPanel(for: item)
        refreshPreview(previewItem: item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension StoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let insets: CGFloat = 12 + 12
        let spacing: CGFloat = 10 * 2
        let width = (collectionView.bounds.width - insets - spacing) / 3
        return CGSize(width: width, height: width * 1.25)
    }
}

// MARK: - AccessoryCell

private class AccessoryCell: UICollectionViewCell {

    private let emojiLabel  = UILabel()
    private let nameLabel   = UILabel()
    private let priceLabel  = UILabel()
    private let badgeLabel  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildCell() {
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1.5
        contentView.backgroundColor = UIColor(red: 0.10, green: 0.05, blue: 0.18, alpha: 1)

        emojiLabel.font = UIFont.systemFont(ofSize: 34)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = UIFont.systemFont(ofSize: 11)
        priceLabel.textAlignment = .center
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        badgeLabel.font = UIFont.boldSystemFont(ofSize: 9)
        badgeLabel.textColor = .black
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(emojiLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            badgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            badgeLabel.widthAnchor.constraint(equalToConstant: 36),
            badgeLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(with item: AccessoryItem, isSelected: Bool, coinBalance: Int) {
        emojiLabel.text = item.emoji

        nameLabel.text = item.name

        if item.isEquipped {
            badgeLabel.text = "已装备"
            badgeLabel.backgroundColor = .cyan
            badgeLabel.isHidden = false
            priceLabel.text = ""
        } else if item.isOwned {
            badgeLabel.text = "已拥有"
            badgeLabel.backgroundColor = UIColor(white: 0.5, alpha: 1)
            badgeLabel.isHidden = false
            priceLabel.text = ""
        } else {
            badgeLabel.isHidden = true
            let canAfford = coinBalance >= item.price
            priceLabel.text = "🪙 \(item.price)"
            priceLabel.textColor = canAfford
                ? UIColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 1)
                : UIColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1)
        }

        // Border glow when selected
        if isSelected {
            contentView.layer.borderColor = UIColor.cyan.cgColor
            contentView.backgroundColor = UIColor(red: 0.05, green: 0.18, blue: 0.22, alpha: 1)
        } else if item.isEquipped {
            contentView.layer.borderColor = UIColor.cyan.withAlphaComponent(0.6).cgColor
            contentView.backgroundColor = UIColor(red: 0.04, green: 0.14, blue: 0.18, alpha: 1)
        } else {
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
            contentView.backgroundColor = UIColor(red: 0.10, green: 0.05, blue: 0.18, alpha: 1)
        }
    }
}

// MARK: - SKColor helper

private extension UIColor {
    var skColor: SKColor { SKColor(cgColor: cgColor) }
}
