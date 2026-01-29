//
//  ViewControllerContainerCell.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//
//  This is the CORE component that demonstrates how to embed
//  a UIViewController inside a UICollectionViewCell

import UIKit

class ViewControllerContainerCell: UICollectionViewCell {
    
    private weak var childViewController: UIViewController?
    private weak var parentViewController: UIViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    func configure(viewController: UIViewController, parent: UIViewController) {
        // ⚠️ CRITICAL: Properly remove old child VC before adding new one
        removeChildViewController()
        
        // ✅ STEP 1: Notify child it's about to be added
        parent.addChild(viewController)
        
        // ✅ STEP 2: Add child's view to cell
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(viewController.view)
        viewController.view.pinToSuperview()
        
        // ✅ STEP 3: Notify child it was added
        viewController.didMove(toParent: parent)
        
        // Store references
        self.childViewController = viewController
        self.parentViewController = parent
        
        print("✅ [VC Container] Added child VC: \(type(of: viewController))")
    }
    
    // MARK: - Lifecycle Management
    
    override func prepareForReuse() {
        super.prepareForReuse()
        removeChildViewController()
    }
    
    private func removeChildViewController() {
        guard let childVC = childViewController else { return }
        
        print("🗑️ [VC Container] Removing child VC: \(type(of: childVC))")
        
        // ⚠️ CRITICAL: Properly remove child VC
        // STEP 1: Notify it will be removed
        childVC.willMove(toParent: nil)
        
        // STEP 2: Remove view from hierarchy
        childVC.view.removeFromSuperview()
        
        // STEP 3: Remove from parent
        childVC.removeFromParent()
        
        childViewController = nil
    }
    
    // MARK: - Manual Lifecycle Triggers
    
    func triggerViewWillAppear() {
        childViewController?.viewWillAppear(false)
        print("👀 [VC Container] viewWillAppear called on: \(type(of: childViewController))")
    }
    
    func triggerViewDidDisappear() {
        childViewController?.viewDidDisappear(false)
        print("👋 [VC Container] viewDidDisappear called on: \(type(of: childViewController))")
    }
    
    deinit {
        removeChildViewController()
        print("💀 [VC Container] Cell deallocated")
    }
}
