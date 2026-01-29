//
//  SegmentHeaderView.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class SegmentHeaderView: UICollectionReusableView {
    
    static let reuseIdentifier = "SegmentHeaderView"
    
    var onSegmentChanged: ((Int) -> Void)?
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: PageType.allCases.map { $0.title })
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(segmentedControl)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
        
        // Shadow for depth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 2
    }
    
    @objc private func segmentChanged() {
        onSegmentChanged?(segmentedControl.selectedSegmentIndex)
    }
    
    func setSelectedSegment(_ index: Int, animated: Bool = false) {
        segmentedControl.selectedSegmentIndex = index
    }
}
