//
//  JXPagingExampleViewController.swift
//  PageComparisonDemo
//
//  Created on 2026-01-22.
//

import UIKit

class JXPagingExampleViewController: UIViewController {
    
    private var pagingView: JXPagingSmoothView!
    private let performanceFooter = PerformanceFooterView()
    private var segmentControl: SegmentHeaderView!
    private var currentPageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JXPaging Example"
        view.backgroundColor = .systemBackground
        
        setupPagingView()
        setupPerformanceFooter()
        
        PerformanceMonitor.shared.startMonitoring()
    }
    
    deinit {
        PerformanceMonitor.shared.stopMonitoring()
    }
    
    private func setupPagingView() {
        pagingView = JXPagingSmoothView(dataSource: self)
        pagingView.delegate = self
        pagingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pagingView)
        
        NSLayoutConstraint.activate([
            pagingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        pagingView.reloadData()
    }
    
    private func setupPerformanceFooter() {
        performanceFooter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(performanceFooter)
        
        NSLayoutConstraint.activate([
            performanceFooter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            performanceFooter.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            performanceFooter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            performanceFooter.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}

// MARK: - JXPagingSmoothViewDataSource
extension JXPagingExampleViewController: JXPagingSmoothViewDataSource {
    
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat {
        return 200
    }
    
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView {
        let headerView = StaticHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))
        headerView.backgroundColor = .red
        return headerView
    }
    
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat {
        return 44
    }
    
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView {
//        segmentControl = SegmentHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
//        segmentControl.backgroundColor = .red
//        segmentControl.onSegmentChanged = { [weak self] index in
//            guard let self = self else { return }
//            self.currentPageIndex = index
//            
//            // Scroll to selected page
//            let offsetX = CGFloat(index) * self.pagingView.listCollectionView.bounds.width
//            self.pagingView.listCollectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
//        }
//        return segmentControl
        let headerView = StaticHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 200))
        headerView.backgroundColor = .red
        return headerView

    }
    
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int {
        return 3
    }
    
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> JXPagingSmoothViewListViewDelegate {
        switch index {
        case 0:
            return JXOverviewPageViewController()
        case 1:
            return JXDetailsPageViewController()
        case 2:
            return JXAnalyticsPageViewController()
        default:
            fatalError("Invalid page index")
        }
    }
}

// MARK: - JXPagingSmoothViewDelegate
extension JXPagingExampleViewController: JXPagingSmoothViewDelegate {
    func pagingSmoothViewDidScroll(_ scrollView: UIScrollView) {
        // Update segment control based on scroll position
        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        if currentPage != currentPageIndex && currentPage >= 0 && currentPage < 3 {
            currentPageIndex = currentPage
            segmentControl?.setSelectedSegment(currentPage, animated: false)
        }
    }
}
