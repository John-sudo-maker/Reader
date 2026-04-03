//
//  ErrorViewController.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class ErrorViewController: UIViewController {
    private let error: Error
    private let imageView = UIImageView()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    
    init(error: Error) {
        self.error = error
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        imageView.image = UIImage(systemName: "exclamationmark.triangle")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        
        errorLabel.text = error.localizedDescription
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.textColor = .secondaryLabel
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        
        retryButton.setTitle("重试", for: .normal)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        retryButton.layer.cornerRadius = 12
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        
        view.addSubview(imageView)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(80)
        }
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(32)
        }
        
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
    }
    
    @objc private func retryTapped() {
        dismiss(animated: true)
    }
    
    private func adjustForIPad() {
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass == .regular {
            // iPad 布局调整
            adjustForIPad()
        }
    }
}
