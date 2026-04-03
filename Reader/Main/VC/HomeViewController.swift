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
    private let loginPromptButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        updateLoginState()
        
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
            welcomeLabel.text = String(format: NSLocalizedString("home_welcome_logged_in", comment: "欢迎回来，用户名"), savedUsername)
            welcomeLabel.textColor = .label
            loginPromptButton.isHidden = true
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("logout_button", comment: "退出"),
                style: .plain,
                target: self,
                action: #selector(logout)
            )
        } else {
            welcomeLabel.text = NSLocalizedString("home_welcome_logged_out", comment: "发现精彩开源项目")
            welcomeLabel.textColor = .label
            loginPromptButton.isHidden = false
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("login_button", comment: "登录"),
                style: .plain,
                target: self,
                action: #selector(showLogin)
            )
        }
        
        navigationController?.navigationBar.setNeedsLayout()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("home_title", comment: "热门仓库")
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationController?.navigationBar.tintColor = .systemBlue
        
        if let url = URL(string: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png") {
            customImageView.loadImage(from: url)
        }
        
        welcomeLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0
        
        loginPromptButton.setTitle(NSLocalizedString("home_login_prompt", comment: "点击登录，解锁更多功能"), for: .normal)
        loginPromptButton.setTitleColor(.systemBlue, for: .normal)
        loginPromptButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loginPromptButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        loginPromptButton.layer.cornerRadius = 12
        loginPromptButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
        loginPromptButton.isHidden = true
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.distribution = .equalSpacing
        
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
                        showEmptyState()
                    }
                }
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                    
                    showNetworkErrorToast(error)
                    loadMockDataAsFallback()
                }
            }
        }
    }
    
    @objc private func refreshData() {
        loadData()
    }
    
    private func updateStackView() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for article in articles {
            let cardView = ArticleCardView()
            cardView.configure(with: article)
            contentStackView.addArrangedSubview(cardView)
            
            cardView.snp.makeConstraints { make in
                make.height.equalTo(130)
            }
        }
    }
    
    @objc private func showLogin() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            self?.updateLoginState()
        }
        present(loginVC, animated: true)
    }
    
    @objc private func logout() {
        let alert = UIAlertController(
            title: NSLocalizedString("logout_confirm_title", comment: "确认退出"),
            message: NSLocalizedString("logout_confirm_message", comment: "确定要退出登录吗？"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("cancel", comment: "取消"),
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: "确定"),
            style: .destructive
        ) { [weak self] _ in
            AuthenticationService().logout()
            self?.updateLoginState()
            
            NotificationCenter.default.post(name: NSNotification.Name("LoginStateChanged"), object: nil)
            
            let successAlert = UIAlertController(
                title: NSLocalizedString("logout_success_title", comment: "已退出"),
                message: NSLocalizedString("logout_success_message", comment: "您已成功退出登录"),
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: "确定"),
                style: .default
            ))
            self?.present(successAlert, animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showNetworkErrorToast(_ error: Error) {
        let toast = UILabel()
        toast.text = NSLocalizedString("home_network_error", comment: "网络请求失败，使用示例数据")
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
        emptyLabel.text = NSLocalizedString("home_empty_state", comment: "暂无数据\n下拉刷新重试")
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
