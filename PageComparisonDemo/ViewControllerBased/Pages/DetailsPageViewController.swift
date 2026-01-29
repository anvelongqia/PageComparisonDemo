//
//  DetailsPageViewController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class DetailsPageViewController: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎮 [Details VC] viewDidLoad")
        setupUI()
        loadImages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👀 [Details VC] viewWillAppear")
    }
    
    deinit {
        print("💀 [Details VC] deinit")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(collectionView)
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

extension DetailsPageViewController: UICollectionViewDataSource {
    
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

extension DetailsPageViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // ✅ VC-based: Can push detail VC
        let detailVC = DetailViewController()
        detailVC.itemTitle = "Image #\(indexPath.item + 1)"
        detailVC.detailImage = images[indexPath.item]
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
