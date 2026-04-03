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
        adjustForIPad()
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
            emailLabel.text = String(format: NSLocalizedString("profile_email_suffix", comment: "邮箱后缀"), savedUsername)
            loginButton.isHidden = true
            logoutButton.isHidden = false
            avatarImageView.tintColor = .systemBlue
        } else {
            nameLabel.text = NSLocalizedString("profile_logged_out", comment: "未登录")
            emailLabel.text = NSLocalizedString("profile_logged_out_subtitle", comment: "登录以体验完整功能")
            loginButton.isHidden = false
            logoutButton.isHidden = true
            avatarImageView.tintColor = .systemGray
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("profile_title", comment: "个人资料")
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
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel.text = String(format: NSLocalizedString("profile_version", comment: "版本"), version)
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = .secondaryLabel
        versionLabel.textAlignment = .center
        
        // Login Button
        loginButton.setTitle(NSLocalizedString("profile_login_button", comment: "立即登录"), for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // Logout Button
        logoutButton.setTitle(NSLocalizedString("profile_logout_button", comment: "退出登录"), for: .normal)
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
            NotificationCenter.default.post(name: NSNotification.Name("LoginStateChanged"), object: nil)
        }
        present(loginVC, animated: true)
    }
    
    @objc private func logoutTapped() {
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
            self?.updateUIForLoginState()
            
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
         super.traitCollectionDidChange(previousTraitCollection)
         if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
             adjustForIPad()
         }
     }
     
     private func adjustForIPad() {
         let isIPad = traitCollection.horizontalSizeClass == .regular
         let horizontalMargin: CGFloat = isIPad ? 80 : 20
         let cardWidth: CGFloat = isIPad ? 500 : UIScreen.main.bounds.width - 40
         
         cardView.snp.remakeConstraints { make in
             make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
             make.centerX.equalToSuperview()
             make.width.equalTo(cardWidth)
             make.bottom.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
         }
         
         nameLabel.snp.updateConstraints { make in
             make.left.right.equalToSuperview().inset(horizontalMargin)
         }
         
         emailLabel.snp.updateConstraints { make in
             make.left.right.equalToSuperview().inset(horizontalMargin)
         }
         
         versionLabel.snp.updateConstraints { make in
             make.left.right.equalToSuperview().inset(horizontalMargin)
         }
         
         loginButton.snp.updateConstraints { make in
             make.left.right.equalToSuperview().inset(horizontalMargin)
         }
         
         logoutButton.snp.updateConstraints { make in
             make.left.right.equalToSuperview().inset(horizontalMargin)
         }
     }
}
