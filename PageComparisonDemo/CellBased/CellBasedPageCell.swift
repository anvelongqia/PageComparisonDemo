//
//  CellBasedPageCell.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class CellBasedPageCell: UICollectionViewCell {
    
    private var currentPageView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with pageType: PageType, parentVC: UIViewController) {
        // Remove old page view
        currentPageView?.removeFromSuperview()
        
        // Create new page view based on type
        let pageView: UIView
        switch pageType {
        case .overview:
            pageView = OverviewPageView()
        case .details:
            pageView = DetailsPageView()
        case .analytics:
            pageView = AnalyticsPageView()
        }
        
        pageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageView)
        pageView.pinToSuperview()
        
        currentPageView = pageView
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentPageView?.removeFromSuperview()
        currentPageView = nil
    }
}
