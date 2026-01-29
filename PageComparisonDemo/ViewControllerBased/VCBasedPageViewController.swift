//
//  VCBasedPageViewController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class VCBasedPageViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Int>!
    private let performanceFooter = PerformanceFooterView()
    
    private var currentPageIndex = 0
    private var pageViewControllers: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ViewController-Based Approach"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
        setupPerformanceFooter()
        configureDataSource()
        applySnapshot()
        
        PerformanceMonitor.shared.startMonitoring()
    }
    
    deinit {
        PerformanceMonitor.shared.stopMonitoring()
        
        // Clean up child view controllers
        pageViewControllers.forEach { vc in
            vc.willMove(toParent: nil)
            vc.removeFromParent()
        }
        pageViewControllers.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.register(VCBasedStaticHeaderCell.self)
        collectionView.register(ViewControllerContainerCell.self)
        collectionView.registerHeader(SegmentHeaderView.self)
        
        view.addSubview(collectionView)
    }
    
    private func setupPerformanceFooter() {
        performanceFooter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(performanceFooter)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: performanceFooter.topAnchor),
            
            performanceFooter.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            performanceFooter.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            performanceFooter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            performanceFooter.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            switch sectionIndex {
            case 0:
                return self.createStaticHeaderSection()
            case 1:
                return self.createPagingSection()
            default:
                return nil
            }
        }
    }
    
    private func createStaticHeaderSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200)),
            subitems: [item]
        )
        return NSCollectionLayoutSection(group: group)
    }
    
    private func createPagingSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(600)),
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        
        // ✅ Segment Header 配置
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        // ⭐ 关键：设置为 true，实现吸顶效果
        // 当 Section 0 滚出屏幕后，这个 header 会吸附在顶部
        header.pinToVisibleBounds = true
        
        // ⭐ 设置 zIndex，确保 header 在最上层
        header.zIndex = 2
        
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    // MARK: - Data Source
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }
            
            print("🔍 [VCBased DataSource] section: \(indexPath.section), item: \(indexPath.item)")
            
            switch indexPath.section {
            case 0:
                print("✅ [VCBased] Creating static header cell")
                let cell = collectionView.dequeueReusableCell(VCBasedStaticHeaderCell.self, for: indexPath)
                cell.backgroundColor = .red
                return cell
            case 1:
                print("✅ [VCBased] Creating page cell for item: \(item)")
                let cell = collectionView.dequeueReusableCell(ViewControllerContainerCell.self, for: indexPath)
                let pageType = PageType.allCases[item]
                let pageVC = self.createViewController(for: pageType)
                cell.configure(viewController: pageVC, parent: self)
                return cell
            default:
                print("⚠️ [VCBased] Unknown section: \(indexPath.section)")
                return UICollectionViewCell()
            }
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self else { return nil }
            let header = collectionView.dequeueHeader(SegmentHeaderView.self, for: indexPath)
            header.onSegmentChanged = { [weak self] index in
                self?.scrollToPage(index)
            }
            return header
        }
    }
    
    private func createViewController(for pageType: PageType) -> UIViewController {
        let vc: UIViewController
        switch pageType {
        case .overview:
            vc = OverviewPageViewController()
        case .details:
            vc = DetailsPageViewController()
        case .analytics:
            vc = AnalyticsPageViewController()
        }
        return vc
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1])
        
        // ⚠️ 重要：Item 必须全局唯一！
        // Section 0 使用负数，Section 1 使用正数
        snapshot.appendItems([-1], toSection: 0)     // Section 0: 静态头部
        snapshot.appendItems([0, 1, 2], toSection: 1) // Section 1: 三个页面
        
        print("📊 [VCBased] Applying snapshot - Sections: \(snapshot.numberOfSections), Items in section 0: \(snapshot.numberOfItems(inSection: 0)), Items in section 1: \(snapshot.numberOfItems(inSection: 1))")
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func scrollToPage(_ index: Int) {
        PerformanceMonitor.shared.startPageSwitchTiming()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 1), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension VCBasedPageViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let duration = PerformanceMonitor.shared.endPageSwitchTiming()
        print("🎮 [VC-Based] Page switch duration: \(String(format: "%.3f", duration))s")
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let containerCell = cell as? ViewControllerContainerCell {
            containerCell.triggerViewWillAppear()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let containerCell = cell as? ViewControllerContainerCell {
            containerCell.triggerViewDidDisappear()
        }
    }
}

// MARK: - Static Header Cell

class VCBasedStaticHeaderCell: UICollectionViewCell {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "🎮 ViewController-Based\nPages are UIViewController subclasses"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(label)
        label.centerInSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
