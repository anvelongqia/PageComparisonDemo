//
//  DetailsPageView.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class DetailsPageView: UIView {
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 150, height: 150)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemGroupedBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private var images: [UIImage] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        loadImages()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGroupedBackground
        
        addSubview(collectionView)
        collectionView.pinToSuperview()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
    }
    
    private func loadImages() {
        NetworkSimulator.fetchImages(count: 20) { [weak self] images in
            self?.images = images
            self?.collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension DetailsPageView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.configure(with: images[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DetailsPageView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if let window = window {
            let alert = UIAlertController(
                title: "Image Selected",
                message: "Index: \(indexPath.item)\n\n⚠️ Cell-based: Cannot push detail VC",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            window.rootViewController?.present(alert, animated: true)
        }
    }
}
