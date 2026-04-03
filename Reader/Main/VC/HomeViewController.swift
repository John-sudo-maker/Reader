//
//  HomeViewController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    private let apiService = APIService()
    private var articles: [NewsArticle] = []
    
    private let customImageView = CustomImageView()
    private let welcomeLabel = UILabel()
    private let loginPromptButton = UIButton(type: .system)  // 添加一个明显的登录按钮
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        updateLoginState()
        
        // 监听登录状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLoginState),
            name: NSNotification.Name("LoginStateChanged"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLoginState()
    }
    
    @objc private func updateLoginState() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedUsername = UserDefaults.standard.string(forKey: "savedUsername") ?? ""
        
        if isLoggedIn && !savedUsername.isEmpty {
            // 已登录状态
            welcomeLabel.text = "欢迎回来，\(savedUsername)！"
            welcomeLabel.textColor = .label
            loginPromptButton.isHidden = true
            
            // 设置导航栏右侧按钮为退出
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "退出", style: .plain, target: self, action: #selector(logout))
        } else {
            // 未登录状态
            welcomeLabel.text = "发现精彩开源项目"
            welcomeLabel.textColor = .label
            loginPromptButton.isHidden = false
            
            // 设置导航栏右侧按钮为登录
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登录", style: .plain, target: self, action: #selector(showLogin))
        }
        
        // 强制刷新导航栏
        navigationController?.navigationBar.setNeedsLayout()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "热门仓库"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 确保导航栏按钮显示
        navigationController?.navigationBar.tintColor = .systemBlue
        
        // Custom image widget
        if let url = URL(string: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png") {
            customImageView.loadImage(from: url)
        }
        
        // Welcome label
        welcomeLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0
        
        // 登录提示按钮 - 这是一个明显的按钮，放在欢迎语下方
        loginPromptButton.setTitle("🔐 点击登录，解锁更多功能", for: .normal)
        loginPromptButton.setTitleColor(.systemBlue, for: .normal)
        loginPromptButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loginPromptButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        loginPromptButton.layer.cornerRadius = 12
        loginPromptButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
        loginPromptButton.isHidden = true  // 初始隐藏，在 updateLoginState 中控制
        
        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        // Content StackView
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.distribution = .equalSpacing
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        view.addSubview(customImageView)
        view.addSubview(welcomeLabel)
        view.addSubview(loginPromptButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        customImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(160)
        }
        
        welcomeLabel.snp.makeConstraints { make in
            make.top.equalTo(customImageView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        loginPromptButton.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(loginPromptButton.snp.bottom).offset(16)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func loadData() {
        loadingIndicator.startAnimating()
        Task {
            do {
                articles = try await apiService.fetchNews()
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                    updateStackView()
                    
                    if articles.isEmpty {
                        // 显示空状态
                        showEmptyState()
                    }
                }
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                    
                    // 显示友好错误提示，而不是全屏错误页
                    showNetworkErrorToast(error)
                    // 使用 Mock 数据作为备用
                    loadMockDataAsFallback()
                }
            }
        }
    }
    
    @objc private func refreshData() {
        loadData()
    }
    
    private func updateStackView() {
        // 清除旧的视图
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的卡片
        for article in articles {
            let cardView = ArticleCardView()
            cardView.configure(with: article)
            contentStackView.addArrangedSubview(cardView)
            
            // 修改这里：不要设置 left.right 约束，让 StackView 自动管理
            // 只需要设置固定高度即可
            cardView.snp.makeConstraints { make in
                make.height.equalTo(130)  // 设置固定高度
            }
        }
    }
    
    @objc private func showLogin() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            self?.updateLoginState()
            // 刷新数据（可选）
            // self?.loadData()
        }
        present(loginVC, animated: true)
    }
    
    @objc private func logout() {
        let alert = UIAlertController(title: "确认退出", message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            AuthenticationService().logout()
            self?.updateLoginState()
            
            // 发送通知，让其他页面也更新
            NotificationCenter.default.post(name: NSNotification.Name("LoginStateChanged"), object: nil)
        })
        present(alert, animated: true)
    }
    
    private func showNetworkErrorToast(_ error: Error) {
        let toast = UILabel()
        toast.text = "网络请求失败，使用示例数据"
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 14)
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        
        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(40)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseOut, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    private func loadMockDataAsFallback() {
        // 使用模拟数据作为备用
        articles = [
            NewsArticle(
                title: "SnapKit - 自动布局简化工具",
                description: "SnapKit 让 iOS 自动布局代码更简洁易读",
                stars: 18900,
                url: "https://github.com/SnapKit/SnapKit",
                author: "SnapKit",
                language: "Swift"
            ),
            NewsArticle(
                title: "Alamofire - 网络请求库",
                description: "优雅的 Swift 网络请求库",
                stars: 39800,
                url: "https://github.com/Alamofire/Alamofire",
                author: "Alamofire",
                language: "Swift"
            )
        ]
        updateStackView()
    }

    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无数据\n下拉刷新重试"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        
        contentStackView.addArrangedSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }
    }
}
