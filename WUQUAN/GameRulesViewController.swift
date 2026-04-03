//
//  GameRulesViewController.swift
//  WUQUAN
//
//  Created by Claude on 7/21/25.
//

import UIKit

protocol GameRulesDelegate: AnyObject {
    func rulesWillDismiss()
}

class GameRulesViewController: UIViewController {
    
    weak var delegate: GameRulesDelegate?
    
    // UI Elements
    private var backgroundView: UIView!
    private var rulesPanel: UIView!
    private var titleLabel: UILabel!
    private var closeButton: UIButton!
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateAppearance()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        createBackgroundView()
        createRulesPanel()
        createTitleAndCloseButton()
        createScrollView()
        createRulesContent()
    }
    
    private func createBackgroundView() {
        backgroundView = UIView(frame: view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    private func createRulesPanel() {
        let panelWidth: CGFloat = min(view.bounds.width * 0.9, 500)
        let panelHeight: CGFloat = min(view.bounds.height * 0.85, 700)
        
        rulesPanel = UIView()
        rulesPanel.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.95)
        rulesPanel.layer.cornerRadius = 20
        rulesPanel.layer.borderWidth = 3
        rulesPanel.layer.borderColor = UIColor.yellow.cgColor
        rulesPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rulesPanel)
        
        NSLayoutConstraint.activate([
            rulesPanel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rulesPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rulesPanel.widthAnchor.constraint(equalToConstant: panelWidth),
            rulesPanel.heightAnchor.constraint(equalToConstant: panelHeight)
        ])
    }
    
    private func createTitleAndCloseButton() {
        // Title
        titleLabel = UILabel()
        titleLabel.text = "🥊 舞拳 - 游戏规则"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .yellow
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        rulesPanel.addSubview(titleLabel)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        closeButton.setTitleColor(.lightGray, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        rulesPanel.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: rulesPanel.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: rulesPanel.centerXAnchor),
            
            closeButton.topAnchor.constraint(equalTo: rulesPanel.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: rulesPanel.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createScrollView() {
        scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        rulesPanel.addSubview(scrollView)
        
        contentView = UIView()
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: rulesPanel.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: rulesPanel.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: rulesPanel.bottomAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func createRulesContent() {
        let rulesText = """
        ## 🎯 游戏目标
        舞拳是基于石头剪刀布的策略对战游戏，但加入了方向指向的独特机制。
        
        ## 🤝 握手阶段
        • 游戏开始时，你和夜店小王子将进行4次握手
        • 握手建立游戏节奏，准备进入对战
        
        ## ✋ 手势选择阶段
        选择你的手势：
        • 🗿 **石头** - 击败剪刀，败给布
        • 📄 **布** - 击败石头，败给剪刀
        • ✂️ **剪刀** - 击败布，败给石头
        
        ## 👉 方向指向阶段
        选择你的指向方向：
        • ⬅️ **左** - 指向左侧
        • ➡️ **右** - 指向右侧
        • ⬆️ **上** - 指向上方
        • ⬇️ **下** - 指向下方
        
        ## 🏆 获胜条件
        **基础规则：**
        • 手势获胜者得到基础分数
        • 平局时无人得分
        
        **方向加成：**
        • 如果你的手势获胜 **且** 指向方向与对手相同
        • 你将获得额外加成分数！
        
        **特殊情况：**
        • 手势平局但方向相同：小额奖励分
        • 手势败北且方向相同：减分惩罚
        
        ## 🎮 操作说明
        • 点击手势图标选择你的手势
        • 点击方向箭头选择指向方向
        • 观察夜店小王子的选择和结果分析
        • 通过多轮对战累积分数
        
        ## 💡 策略提示
        • 观察夜店小王子的行为模式
        • 方向选择与手势选择同样重要
        • 尝试预测对手的方向指向
        • 平衡风险与收益
        
        ## 🎵 游戏体验
        • 背景音乐自动播放
        • 可通过设置调节音量或更换音乐
        • 支持暂停和恢复游戏
        
        祝你游戏愉快！🎉
        """
        
        let textView = UITextView()
        textView.text = rulesText
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .white
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textAlignment = .left
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        
        // Calculate content height after layout
        DispatchQueue.main.async {
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            textView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTapped() {
        closeRules()
    }
    
    @objc private func closeButtonTapped() {
        closeRules()
    }
    
    private func closeRules() {
        delegate?.rulesWillDismiss()
        animateDisappearance {
            self.dismiss(animated: false)
        }
    }
    
    // MARK: - Animations
    
    private func animateAppearance() {
        rulesPanel.alpha = 0.0
        rulesPanel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.rulesPanel.alpha = 1.0
            self.rulesPanel.transform = CGAffineTransform.identity
        }
    }
    
    private func animateDisappearance(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.rulesPanel.alpha = 0.0
            self.rulesPanel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.alpha = 0.0
        }) { _ in
            completion()
        }
    }
}