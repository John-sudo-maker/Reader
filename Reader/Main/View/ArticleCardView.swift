//
//  ArticleCardView.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class ArticleCardView: UIView {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let starLabel = UILabel()
    private let starIcon = UIImageView()
    private let authorLabel = UILabel()
    private let languageLabel = UILabel()
    private let separatorLine = UIView()
    
    private var articleUrl: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // card
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2
        
        // Description
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3
        
        // Author
        authorLabel.font = UIFont.systemFont(ofSize: 11)
        authorLabel.textColor = .systemGray
        
        // Language
        languageLabel.font = UIFont.systemFont(ofSize: 11)
        languageLabel.textColor = .systemGreen
        languageLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        languageLabel.layer.cornerRadius = 4
        languageLabel.clipsToBounds = true
        languageLabel.textAlignment = .center
        
        // Star icon
        starIcon.image = UIImage(systemName: "star.fill")
        starIcon.tintColor = .systemOrange
        starIcon.contentMode = .scaleAspectFit
        
        // Star label
        starLabel.font = UIFont.systemFont(ofSize: 12)
        starLabel.textColor = .systemOrange
        
        // Separator
        separatorLine.backgroundColor = .separator
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(authorLabel)
        containerView.addSubview(languageLabel)
        containerView.addSubview(starIcon)
        containerView.addSubview(starLabel)
        containerView.addSubview(separatorLine)
        
        setupConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        languageLabel.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.left.equalTo(authorLabel.snp.right).offset(12)
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(18)
        }
        
        starIcon.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.right.equalTo(starLabel.snp.left).offset(-4)
            make.width.height.equalTo(12)
        }
        
        starLabel.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.right.equalToSuperview().offset(-16)
        }
        
        separatorLine.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func configure(with article: NewsArticle) {
        titleLabel.text = article.title
        descriptionLabel.text = article.description
        starLabel.text = formatStarCount(article.stars)
        articleUrl = article.url
        
        if let author = article.author {
            authorLabel.text = "@\(author)"
        } else {
            authorLabel.text = "Unknown"
        }
        
        if let language = article.language, !language.isEmpty {
            languageLabel.text = "  \(language)  "
            languageLabel.isHidden = false
        } else {
            languageLabel.isHidden = true
        }
    }
    
    private func formatStarCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    @objc private func cardTapped() {
        guard let urlString = articleUrl, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
