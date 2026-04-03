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
            emptyStateLabel.text = NSLocalizedString("search_empty_logged_out", comment: "未登录空状态提示")
            emptyStateLabel.isHidden = false
            contentStackView.isHidden = true
        } else if results.isEmpty {
            emptyStateLabel.text = NSLocalizedString("search_empty_logged_in", comment: "已登录空状态提示")
            emptyStateLabel.isHidden = false
            contentStackView.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            contentStackView.isHidden = false
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("search_title", comment: "搜索")
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // ScrollView
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        
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
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("search_placeholder", comment: "搜索框占位符")
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .systemBlue
        searchController.searchBar.barTintColor = .systemBackground
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .systemGray6
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
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
        
        guard isLoggedIn else {
            emptyStateLabel.text = NSLocalizedString("search_login_required", comment: "需要登录提示")
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
                        emptyStateLabel.text = NSLocalizedString("search_no_results", comment: "无搜索结果提示")
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
                    let message = String(format: NSLocalizedString("search_failed", comment: "搜索失败提示"), error.localizedDescription)
                    emptyStateLabel.text = message
                    emptyStateLabel.isHidden = false
                    contentStackView.isHidden = true
                }
            }
        }
    }
    
    private func updateStackView() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        searchBar.resignFirstResponder()
    }
}
