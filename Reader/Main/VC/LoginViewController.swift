//
//  LoginViewController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit
import LocalAuthentication

class LoginViewController: UIViewController {
    private let authService = AuthenticationService()
    var onLoginSuccess: (() -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let usernameTextField = UITextField()
    private let passwordTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let biometryButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBiometryButton()
        setupKeyboardHandling()
        adjustForIPad()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        titleLabel.text = NSLocalizedString("login_title", comment: "登录标题")
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        
        subtitleLabel.text = NSLocalizedString("login_subtitle", comment: "登录副标题")
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        
        // Username field
        usernameTextField.placeholder = NSLocalizedString("username_placeholder", comment: "用户名占位符")
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.backgroundColor = .systemGray6
        usernameTextField.layer.cornerRadius = 12
        usernameTextField.font = UIFont.systemFont(ofSize: 16)
        
        // Password field
        passwordTextField.placeholder = NSLocalizedString("password_placeholder", comment: "密码占位符")
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.backgroundColor = .systemGray6
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.font = UIFont.systemFont(ofSize: 16)
        
        // Login button
        loginButton.setTitle(NSLocalizedString("login_button", comment: "登录按钮"), for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // Skip button
        skipButton.setTitle(NSLocalizedString("skip_button", comment: "跳过按钮"), for: .normal)
        skipButton.setTitleColor(.systemBlue, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(usernameTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(loginButton)
        contentView.addSubview(skipButton)
        view.addSubview(closeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.safeAreaLayoutGuide).offset(80)
            make.centerX.equalToSuperview()
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(60)
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.height.equalTo(50)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.height.equalTo(50)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.height.equalTo(50)
        }
        
        skipButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    private func setupBiometryButton() {
        let biometryType = authService.getBiometryType()
        guard biometryType != .none else { return }
        
        let buttonTitle = biometryType == .faceID ?
            NSLocalizedString("face_id_login", comment: "Face ID登录") :
            NSLocalizedString("touch_id_login", comment: "Touch ID登录")
        
        biometryButton.setTitle(buttonTitle, for: .normal)
        biometryButton.setImage(UIImage(systemName: biometryType == .faceID ? "faceid" : "touchid"), for: .normal)
        biometryButton.tintColor = .systemBlue
        biometryButton.addTarget(self, action: #selector(biometryTapped), for: .touchUpInside)
        
        contentView.addSubview(biometryButton)
        
        biometryButton.snp.makeConstraints { make in
            make.top.equalTo(skipButton.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = keyboardFrame.height
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func loginTapped() {
        Task {
            do {
                let success = try await authService.login(
                    username: usernameTextField.text ?? "",
                    password: passwordTextField.text ?? ""
                )
                if success {
                    await MainActor.run {
                        onLoginSuccess?()
                        dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }
    
    @objc private func biometryTapped() {
        Task {
            do {
                let success = try await authService.authenticateWithBiometry()
                if success {
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    await MainActor.run {
                        onLoginSuccess?()
                        dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }
    
    @objc private func skipTapped() {
        dismiss(animated: true)
    }
    
    private func showError(_ error: Error) {
        let errorMessage: String
        if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        let alert = UIAlertController(
            title: NSLocalizedString("error", comment: "错误"),
            message: errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: "确定"),
            style: .default
        ))
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
        let horizontalMargin: CGFloat = isIPad ? 80 : 32
        
        usernameTextField.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(horizontalMargin)
            make.right.equalToSuperview().offset(-horizontalMargin)
        }
        
        passwordTextField.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(horizontalMargin)
            make.right.equalToSuperview().offset(-horizontalMargin)
        }
        
        loginButton.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(horizontalMargin)
            make.right.equalToSuperview().offset(-horizontalMargin)
        }
        
        if isIPad {
            contentView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
                make.width.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        }
    }
}
