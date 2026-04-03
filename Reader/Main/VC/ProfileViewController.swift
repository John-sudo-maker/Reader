//
//  ProfileViewController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class ProfileViewController: UIViewController {
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let versionLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private let cardView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUIForLoginState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForLoginState()
    }
    
    func refreshUserInfo() {
        updateUIForLoginState()
    }
    
    private func updateUIForLoginState() {
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedUsername = UserDefaults.standard.string(forKey: "savedUsername") ?? ""
        
        if isLoggedIn {
            nameLabel.text = savedUsername
            emailLabel.text = "\(savedUsername)@example.com"
            loginButton.isHidden = true
            logoutButton.isHidden = false
            avatarImageView.tintColor = .systemBlue
        } else {
            nameLabel.text = "未登录"
            emailLabel.text = "登录以体验完整功能"
            loginButton.isHidden = false
            logoutButton.isHidden = true
            avatarImageView.tintColor = .systemGray
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "个人资料"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Card View
        cardView.backgroundColor = .systemGray6
        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 8
        
        // Avatar
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemBlue
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.clipsToBounds = true
        
        // Labels
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        
        emailLabel.font = UIFont.systemFont(ofSize: 14)
        emailLabel.textColor = .secondaryLabel
        emailLabel.textAlignment = .center
        
        versionLabel.text = "版本: 1.0.0"
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = .secondaryLabel
        versionLabel.textAlignment = .center
        
        // Login Button
        loginButton.setTitle("立即登录", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // Logout Button
        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        logoutButton.layer.cornerRadius = 12
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        view.addSubview(cardView)
        cardView.addSubview(avatarImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(emailLabel)
        cardView.addSubview(versionLabel)
        cardView.addSubview(loginButton)
        cardView.addSubview(logoutButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        cardView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-30)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    @objc private func loginTapped() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        loginVC.onLoginSuccess = { [weak self] in
            self?.updateUIForLoginState()
            // 通知首页也更新状态
            NotificationCenter.default.post(name: NSNotification.Name("LoginStateChanged"), object: nil)
        }
        present(loginVC, animated: true)
    }
    
    @objc private func logoutTapped() {
        AuthenticationService().logout()
        updateUIForLoginState()
        
        // 发送通知，让首页也更新
        NotificationCenter.default.post(name: NSNotification.Name("LoginStateChanged"), object: nil)
        
        let alert = UIAlertController(title: "已退出", message: "您已成功退出登录", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
