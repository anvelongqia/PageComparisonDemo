//
//  UICollectionView+Register.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

extension UICollectionView {
    
    func register<T: UICollectionViewCell>(_ cellType: T.Type) {
        register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(_ cellType: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: cellType), for: indexPath) as? T else {
            fatalError("Unable to dequeue \(cellType)")
        }
        return cell
    }
    
    func registerHeader<T: UICollectionReusableView>(_ viewType: T.Type) {
        register(viewType, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: viewType))
    }
    
    func dequeueHeader<T: UICollectionReusableView>(_ viewType: T.Type, for indexPath: IndexPath) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: viewType), for: indexPath) as? T else {
            fatalError("Unable to dequeue \(viewType)")
        }
        return view
    }
}
