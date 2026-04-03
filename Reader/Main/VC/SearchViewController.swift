//
//  SearchViewController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class SearchViewController: UIViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private let apiService = APIService()
    private var results: [NewsArticle] = []
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let emptyStateLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
        
        // 监听卡片点击
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCardTap),
            name: NSNotification.Name("ArticleCardTapped"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForLoginState()
    }
    
    private func updateUIForLoginState() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        if !isLoggedIn && results.isEmpty {
            emptyStateLabel.text = "🔐 登录后即可搜索 GitHub 仓库\n\n请先登录再使用搜索功能"
            emptyStateLabel.isHidden = false
            contentStackView.isHidden = true
        } else if results.isEmpty {
            emptyStateLabel.text = "🔍 输入关键词搜索开源项目\n\n例如: Swift, UIKit, Alamofire"
            emptyStateLabel.isHidden = false
            contentStackView.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            contentStackView.isHidden = false
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "搜索"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag  // 拖拽时隐藏键盘
        
        // Content StackView
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.alignment = .fill
        contentStackView.distribution = .equalSpacing
        contentStackView.isHidden = true
        
        // Empty state label
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(emptyStateLabel)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupSearchBar() {
        // 配置 SearchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "搜索 GitHub 仓库"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .systemBlue
        searchController.searchBar.barTintColor = .systemBackground
        
        // 设置搜索框的背景颜色
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .systemGray6
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        
        // 将搜索框添加到导航栏
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false  // 始终显示搜索框
        
        // 确保搜索框可见
        definesPresentationContext = true
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(32)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func search(query: String) {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        // 未登录时，提示登录
        guard isLoggedIn else {
            emptyStateLabel.text = "🔐 请先登录后再使用搜索功能\n\n点击右上角登录"
            emptyStateLabel.isHidden = false
            contentStackView.isHidden = true
            results = []
            return
        }
        
        guard !query.isEmpty else {
            results = []
            updateStackView()
            updateUIForLoginState()
            return
        }
        
        loadingIndicator.startAnimating()
        emptyStateLabel.isHidden = true
        contentStackView.isHidden = true
        
        Task {
            do {
                results = try await apiService.searchNews(query: query)
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    updateStackView()
                    if results.isEmpty {
                        emptyStateLabel.text = "😔 未找到相关项目\n\n试试其他关键词吧"
                        emptyStateLabel.isHidden = false
                        contentStackView.isHidden = true
                    } else {
                        emptyStateLabel.isHidden = true
                        contentStackView.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    emptyStateLabel.text = "❌ 搜索失败: \(error.localizedDescription)\n\n请检查网络连接"
                    emptyStateLabel.isHidden = false
                    contentStackView.isHidden = true
                }
            }
        }
    }
    
    private func updateStackView() {
        // 清除旧的视图
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的卡片
        for article in results {
            let cardView = ArticleCardView()
            cardView.configure(with: article)
            contentStackView.addArrangedSubview(cardView)
            
            cardView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
            }
        }
    }
    
    @objc private func handleCardTap(_ notification: Notification) {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        guard isLoggedIn else {
            presentLoginViewController()
            return
        }
        
        // 获取点击的卡片对应的文章
        if let userInfo = notification.userInfo,
           let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func presentLoginViewController() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            // 登录成功后，如果搜索框有内容，重新搜索
            if let query = self?.searchController.searchBar.text, !query.isEmpty {
                self?.search(query: query)
            } else {
                self?.updateUIForLoginState()
            }
        }
        present(loginVC, animated: true)
    }
}

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            results = []
            updateStackView()
            updateUIForLoginState()
            return
        }
        search(query: query)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()  // 点击搜索后隐藏键盘
    }
}
