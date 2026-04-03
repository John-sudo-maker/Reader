//
//  MainTabBarController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupTabBarAppearance()
        self.delegate = self
    }
    
    private func setupTabs() {
        let homeVC = HomeViewController()
        homeVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("home_title", comment: "首页"),
            image: UIImage(systemName: "house.fill"),
            tag: 0
        )
        
        let searchVC = SearchViewController()
        searchVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("search_title", comment: "搜索"),
            image: UIImage(systemName: "magnifyingglass"),
            tag: 1
        )
        
        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("profile_title", comment: "我的"),
            image: UIImage(systemName: "person.fill"),
            tag: 2
        )
        
        viewControllers = [
            UINavigationController(rootViewController: homeVC),
            UINavigationController(rootViewController: searchVC),
            UINavigationController(rootViewController: profileVC)
        ]
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = .systemBlue
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return true }
        
        if index == 0 {
            return true
        }
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if !isLoggedIn {
            presentLoginViewController()
            return false
        }
        
        return true
    }
    
    private func presentLoginViewController() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            self?.refreshCurrentViewController()
        }
        present(loginVC, animated: true)
    }
    
    private func refreshCurrentViewController() {
        if let currentVC = selectedViewController {
            if let searchVC = currentVC as? SearchViewController {
                print(NSLocalizedString("notification_login_success_search", comment: "登录成功，搜索页面已就绪"))
            } else if let profileVC = currentVC as? ProfileViewController {
                profileVC.refreshUserInfo()
            }
        }
    }
}
