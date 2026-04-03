//
//  CharacterSelectionViewController.swift
//  WUQUAN
//
//  Character selection screen — pick yourself and your opponent
//

import UIKit
import SpriteKit

protocol CharacterSelectionDelegate: AnyObject {
    func characterSelectionDidComplete(playerStyle: CharacterStyle, opponentStyle: CharacterStyle)
}

class CharacterSelectionViewController: UIViewController {

    weak var delegate: CharacterSelectionDelegate?

    private var backgroundView: UIView!
    private var containerView: UIView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var collectionView: UICollectionView!
    private var startButton: UIButton!
    private var previewScene: SKView!

    private enum SelectionPhase {
        case pickPlayer, pickOpponent
    }

    private var phase: SelectionPhase = .pickPlayer
    private var selectedPlayerStyle: CharacterStyle?
    private var selectedOpponentStyle: CharacterStyle?
    private var selectedPlayerIndex: Int?
    private var selectedOpponentIndex: Int?

    private let characters = CharacterStyle.all

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)

        // Title
        titleLabel = UILabel()
        titleLabel.text = "选择你的角色"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Subtitle
        subtitleLabel = UILabel()
        subtitleLabel.text = "你是谁？"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .cyan
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Preview area
        previewScene = SKView()
        previewScene.isUserInteractionEnabled = false
        previewScene.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1)
        previewScene.layer.cornerRadius = 15
        previewScene.layer.borderWidth = 2
        previewScene.layer.borderColor = UIColor.cyan.withAlphaComponent(0.5).cgColor
        previewScene.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewScene)

        // Collection view for character grid
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CharacterCell.self, forCellWithReuseIdentifier: "CharacterCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        // Start button (hidden until both selected)
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

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            previewScene.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 15),
            previewScene.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewScene.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            previewScene.heightAnchor.constraint(equalToConstant: 150),

            collectionView.topAnchor.constraint(equalTo: previewScene.bottomAnchor, constant: 15),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -15),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func updatePreview() {
        let scene = SKScene(size: previewScene.bounds.size)
        scene.backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1)

        let spriteHeight = scene.size.height * 0.6

        if let pStyle = selectedPlayerStyle {
            let textureName = "\(pStyle.id)_idle"
            if let image = UIImage(named: textureName) ?? loadBundleImage(named: textureName) {
                let texture = SKTexture(image: image)
                let sprite = SKSpriteNode(texture: texture)
                let aspect = texture.size().width / texture.size().height
                sprite.size = CGSize(width: spriteHeight * aspect, height: spriteHeight)
                sprite.position = CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.45)
                sprite.xScale = -abs(sprite.xScale) // mirror for player side
                scene.addChild(sprite)
            }

            let pLabel = SKLabelNode(text: pStyle.name)
            pLabel.fontSize = 12
            pLabel.fontColor = .cyan
            pLabel.position = CGPoint(x: scene.size.width * 0.25, y: scene.size.height * 0.08)
            scene.addChild(pLabel)
        }

        if let oStyle = selectedOpponentStyle {
            let textureName = "\(oStyle.id)_idle"
            if let image = UIImage(named: textureName) ?? loadBundleImage(named: textureName) {
                let texture = SKTexture(image: image)
                let sprite = SKSpriteNode(texture: texture)
                let aspect = texture.size().width / texture.size().height
                sprite.size = CGSize(width: spriteHeight * aspect, height: spriteHeight)
                sprite.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.45)
                scene.addChild(sprite)
            }

            let oLabel = SKLabelNode(text: oStyle.name)
            oLabel.fontSize = 12
            oLabel.fontColor = .red
            oLabel.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height * 0.08)
            scene.addChild(oLabel)
        }

        if selectedPlayerStyle != nil && selectedOpponentStyle != nil {
            let vsLabel = SKLabelNode(text: "VS")
            vsLabel.fontSize = 20
            vsLabel.fontColor = .yellow
            vsLabel.fontName = "Helvetica-Bold"
            vsLabel.position = CGPoint(x: scene.size.width * 0.5, y: scene.size.height * 0.45)
            scene.addChild(vsLabel)
        }

        previewScene.presentScene(scene)
    }

    /// Load a PNG image from the main bundle by filename (without extension)
    private func loadBundleImage(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    // MARK: - Actions

    @objc private func startTapped() {
        guard let pStyle = selectedPlayerStyle, let oStyle = selectedOpponentStyle else { return }
        delegate?.characterSelectionDidComplete(playerStyle: pStyle, opponentStyle: oStyle)
    }
}

// MARK: - UICollectionViewDataSource

extension CharacterSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CharacterCell", for: indexPath) as! CharacterCell
        let char = characters[indexPath.item]
        cell.configure(with: char)

        // Highlight selected cells
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

        switch phase {
        case .pickPlayer:
            selectedPlayerStyle = char
            selectedPlayerIndex = indexPath.item
            phase = .pickOpponent
            titleLabel.text = "选择你的对手"
            subtitleLabel.text = "谁是你的对手？"
            subtitleLabel.textColor = .red

        case .pickOpponent:
            if indexPath.item == selectedPlayerIndex {
                // Can't pick same as self — shake the cell
                if let cell = collectionView.cellForItem(at: indexPath) {
                    let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
                    shake.timingFunction = CAMediaTimingFunction(name: .linear)
                    shake.values = [-8, 8, -6, 6, -3, 3, 0]
                    shake.duration = 0.4
                    cell.layer.add(shake, forKey: "shake")
                }
                return
            }

            selectedOpponentStyle = char
            selectedOpponentIndex = indexPath.item
            titleLabel.text = "准备好了！"
            subtitleLabel.text = "\(selectedPlayerStyle!.name) VS \(char.name)"
            subtitleLabel.textColor = .yellow
            startButton.isHidden = false
            startButton.alpha = 1.0
        }

        collectionView.reloadData()
        updatePreview()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CharacterSelectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 3 * 8) / 4  // 4 columns
        return CGSize(width: width, height: width * 1.3)
    }
}

// MARK: - CharacterCell

class CharacterCell: UICollectionViewCell {

    enum SelectedRole {
        case player, opponent
    }

    private var spriteImageView: UIImageView!
    private var nameLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor(white: 0.3, alpha: 1).cgColor

        spriteImageView = UIImageView()
        spriteImageView.contentMode = .scaleAspectFit
        spriteImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spriteImageView)

        nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 10)
        nameLabel.textColor = .lightGray
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.7
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            spriteImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            spriteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            spriteImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            spriteImageView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -2),

            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    func configure(with style: CharacterStyle) {
        nameLabel.text = style.name
        // Load idle sprite for preview
        if let path = Bundle.main.path(forResource: "\(style.id)_idle", ofType: "png") {
            spriteImageView.image = UIImage(contentsOfFile: path)
        } else {
            // Fallback to emoji
            spriteImageView.image = nil
        }
    }

    func setSelected(role: SelectedRole?) {
        switch role {
        case .player:
            contentView.layer.borderColor = UIColor.cyan.cgColor
            contentView.layer.borderWidth = 3
            contentView.backgroundColor = UIColor.cyan.withAlphaComponent(0.15)
            nameLabel.textColor = .cyan
        case .opponent:
            contentView.layer.borderColor = UIColor.red.cgColor
            contentView.layer.borderWidth = 3
            contentView.backgroundColor = UIColor.red.withAlphaComponent(0.15)
            nameLabel.textColor = .red
        case nil:
            contentView.layer.borderColor = UIColor(white: 0.3, alpha: 1).cgColor
            contentView.layer.borderWidth = 2
            contentView.backgroundColor = UIColor(white: 0.15, alpha: 1)
            nameLabel.textColor = .lightGray
        }
    }
}
