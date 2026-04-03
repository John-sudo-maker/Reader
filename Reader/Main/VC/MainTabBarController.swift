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
        homeVC.tabBarItem = UITabBarItem(title: "首页", image: UIImage(systemName: "house.fill"), tag: 0)
        
        let searchVC = SearchViewController()
        searchVC.tabBarItem = UITabBarItem(title: "搜索", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        
        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "我的", image: UIImage(systemName: "person.fill"), tag: 2)
        
        // 确保每个 ViewController 都在 NavigationController 中
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
        // 获取选中的 tab 索引
        guard let index = viewControllers?.firstIndex(of: viewController) else { return true }
        
        // 首页（tab 0）不需要登录验证
        if index == 0 {
            return true
        }
        
        // 其他 tab（搜索、我的）需要验证登录状态
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if !isLoggedIn {
            // 未登录，弹出登录页面
            presentLoginViewController()
            return false
        }
        
        return true
    }
    
    private func presentLoginViewController() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            // 登录成功后的回调，刷新当前显示的页面
            self?.refreshCurrentViewController()
        }
        present(loginVC, animated: true)
    }
    
    private func refreshCurrentViewController() {
        // 刷新当前选中的 ViewController
        if let currentVC = selectedViewController {
            if let searchVC = currentVC as? SearchViewController {
                // 如果搜索页面有需要刷新的数据
                print("登录成功，搜索页面已就绪")
            } else if let profileVC = currentVC as? ProfileViewController {
                // 刷新个人资料页面
                profileVC.refreshUserInfo()
            }
        }
    }
}
