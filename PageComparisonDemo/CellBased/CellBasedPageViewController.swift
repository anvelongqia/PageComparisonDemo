//
//  CellBasedPageViewController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class CellBasedPageViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Int>!
    private let performanceFooter = PerformanceFooterView()
    
    private var currentPageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cell-Based Approach"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
        setupPerformanceFooter()
        configureDataSource()
        applySnapshot()
        
        PerformanceMonitor.shared.startMonitoring()
    }
    
    deinit {
        PerformanceMonitor.shared.stopMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.register(CellBasedStaticHeaderCell.self)
        collectionView.register(CellBasedPageCell.self)
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
            case 0: // Static header section
                return self.createStaticHeaderSection()
            case 1: // Paging section
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
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(44)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top)
                // ⭐ 关键：设置为 true，实现吸顶效果
                header.pinToVisibleBounds = true
                header.zIndex = 2
                section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    // MARK: - Data Source
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            print("🔍 [CellBased DataSource] section: \(indexPath.section), item: \(indexPath.item)")
            
            switch indexPath.section {
            case 0:
                print("✅ [CellBased] Creating static header cell")
                let cell = collectionView.dequeueReusableCell(CellBasedStaticHeaderCell.self, for: indexPath)
                return cell
            case 1:
                print("✅ [CellBased] Creating page cell for item: \(item)")
                let cell = collectionView.dequeueReusableCell(CellBasedPageCell.self, for: indexPath)
                let pageType = PageType.allCases[item]
                cell.configure(with: pageType, parentVC: self)
                return cell
            default:
                print("⚠️ [CellBased] Unknown section: \(indexPath.section)")
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
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1])
        
        // ⚠️ 重要：Item 必须全局唯一！
        snapshot.appendItems([-1], toSection: 0)     // Section 0: 静态头部
        snapshot.appendItems([0, 1, 2], toSection: 1) // Section 1: 三个页面
        
        print("📊 [CellBased] Applying snapshot - Sections: \(snapshot.numberOfSections), Items in section 0: \(snapshot.numberOfItems(inSection: 0)), Items in section 1: \(snapshot.numberOfItems(inSection: 1))")
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func scrollToPage(_ index: Int) {
        PerformanceMonitor.shared.startPageSwitchTiming()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 1), at: .centeredHorizontally, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension CellBasedPageViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let duration = PerformanceMonitor.shared.endPageSwitchTiming()
        print("📱 [Cell-Based] Page switch duration: \(String(format: "%.3f", duration))s")
    }
}

// MARK: - Static Header Cell

class CellBasedStaticHeaderCell: UICollectionViewCell {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "📊 Cell-Based Implementation\nPages are UIView subclasses"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(label)
        label.centerInSuperview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
