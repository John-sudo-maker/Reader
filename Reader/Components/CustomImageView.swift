//
//  CustomImageView.swift
//  Reader
//
//  Created by John on 2026/4/2.
//

import UIKit
import SnapKit

class CustomImageView: UIView {
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = .systemGray6
        
        // Setup gradient border
        gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 16
        layer.addSublayer(gradientLayer)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        
        addSubview(imageView)
        addSubview(activityIndicator)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func loadImage(from url: URL) {
        activityIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if let data = data, let image = UIImage(data: data) {
                    self?.imageView.image = image
                } else {
                    self?.imageView.image = UIImage(systemName: "photo.fill")
                    self?.imageView.tintColor = .systemGray
                    self?.imageView.contentMode = .center
                }
            }
        }.resume()
    }
}
