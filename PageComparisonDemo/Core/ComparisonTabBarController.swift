//
//  ComparisonTabBarController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class ComparisonTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewControllers()
        setupAppearance()
    }
    
    private func setupViewControllers() {
        let cellBasedVC = CellBasedPageViewController()
        cellBasedVC.tabBarItem = UITabBarItem(
            title: "Cell-Based",
            image: UIImage(systemName: "square.grid.2x2"),
            tag: 0
        )
        
        let vcBasedVC = VCBasedPageViewController()
        vcBasedVC.tabBarItem = UITabBarItem(
            title: "VC-Based",
            image: UIImage(systemName: "rectangle.3.group"),
            tag: 1
        )
        
        let jxPagingVC = JXPagingExampleViewController()
        jxPagingVC.tabBarItem = UITabBarItem(
            title: "JXPaging",
            image: UIImage(systemName: "star.fill"),
            tag: 2
        )
        
        let orthogonalVC = UINavigationController(rootViewController: JXOrthogonalPagingViewController())
        orthogonalVC.tabBarItem = UITabBarItem(
            title: "正交滚动 V1",
            image: UIImage(systemName: "arrow.left.arrow.right"),
            tag: 3
        )
        
        let orthogonalV2VC = UINavigationController(rootViewController: JXOrthogonalPagingViewControllerV2())
        orthogonalV2VC.tabBarItem = UITabBarItem(
            title: "正交滚动 V2",
            image: UIImage(systemName: "arrow.up.arrow.down"),
            tag: 4
        )
        
        viewControllers = [cellBasedVC, vcBasedVC, jxPagingVC, orthogonalVC, orthogonalV2VC]
    }
    
    private func setupAppearance() {
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .systemBlue
    }
}
