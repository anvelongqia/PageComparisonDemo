//
//  DetailViewController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//
//  This demonstrates the KEY ADVANTAGE of ViewController-based approach:
//  The ability to push new view controllers onto the navigation stack

import UIKit

class DetailViewController: UIViewController {
    
    var itemTitle: String = ""
    var detailImage: UIImage?
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = itemTitle
        view.backgroundColor = .systemBackground
        
        setupUI()
        updateContent()
        
        print("✅ [Detail VC] Successfully pushed! This proves VC-based can use navigation stack")
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func updateContent() {
        if let image = detailImage {
            imageView.image = image
        }
        
        descriptionLabel.text = """
        ✅ This is a detail page
        
        🎮 ViewController-Based Advantage:
        • Can use UINavigationController
        • Full ViewController lifecycle
        • Easy to manage complex flows
        
        ⚠️ Cell-Based Limitation:
        • Cannot push from UIView
        • Need workarounds (delegates/closures)
        """
    }
}
