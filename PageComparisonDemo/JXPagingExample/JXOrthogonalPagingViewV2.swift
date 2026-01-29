//
//  JXOrthogonalPagingViewV2.swift
//  PageComparisonDemo
//
//  V2 实现：基于 ContentOffset 控制，不禁用手势
//  策略：通过主动设置 contentOffset 来控制滚动行为，保持手势和惯性传递
//

import UIKit

// MARK: - Protocols

@objc public protocol JXOrthogonalPagingDataSourceV2: AnyObject {
    func heightForHeader(in pagingView: JXOrthogonalPagingViewV2) -> CGFloat
    func viewForHeader(in pagingView: JXOrthogonalPagingViewV2) -> UIView
    func heightForPinHeader(in pagingView: JXOrthogonalPagingViewV2) -> CGFloat
    func viewForPinHeader(in pagingView: JXOrthogonalPagingViewV2) -> UIView
    func numberOfLists(in pagingView: JXOrthogonalPagingViewV2) -> Int
    func pagingView(_ pagingView: JXOrthogonalPagingViewV2, initListAtIndex index: Int) -> JXPagingListViewDelegate
}

@objc public protocol JXOrthogonalPagingDelegateV2: AnyObject {
    @objc optional func pagingView(_ pagingView: JXOrthogonalPagingViewV2, didSwitchToListAt index: Int)
    @objc optional func pagingView(_ pagingView: JXOrthogonalPagingViewV2, mainScrollViewDidScroll scrollView: UIScrollView)
}

// MARK: - Main View

open class JXOrthogonalPagingViewV2: UIView {
    
    // MARK: - Properties
    
    public weak var dataSource: JXOrthogonalPagingDataSourceV2?
    public weak var delegate: JXOrthogonalPagingDelegateV2?
    
    public private(set) lazy var mainCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.delegate = self
        cv.dataSource = self
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "HeaderCell")
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ListCell")
        cv.register(JXPinHeaderWrapperView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "PinHeader")
        return cv
    }()
    
    /// 缓存已加载的列表
    private var listDict = [Int: JXPagingListViewDelegate]()
    /// 当前显示的列表索引
    public private(set) var currentIndex: Int = 0
    
    /// 缓存 Header 引用
    private weak var headerView: UIView?
    private weak var pinHeaderView: UIView?
    
    // KVO 观察者集合
    private var observers: [NSKeyValueObservation] = []
    
    // 追踪已添加 observer 的列表索引
    private var observedIndices = Set<Int>()
    
    // 🔥 V2 新增：标记是否正在程序化修改 offset（避免递归）
    private var isSettingContentOffset = false
    
    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(mainCollectionView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        mainCollectionView.frame = bounds
    }
    
    // MARK: - Public Methods
    
    public func reloadData() {
        listDict.removeAll()
        observers.removeAll()
        observedIndices.removeAll()
        currentIndex = 0
        
        headerView = dataSource?.viewForHeader(in: self)
        pinHeaderView = dataSource?.viewForPinHeader(in: self)
        
        mainCollectionView.collectionViewLayout = makeLayout()
        mainCollectionView.reloadData()
    }
    
    // MARK: - Compositional Layout
    
    private func makeLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self, let dataSource = self.dataSource else { return nil }
            
            if sectionIndex == 0 {
                // Section 0: Header（渐变背景）
                let headerHeight = dataSource.heightForHeader(in: self)
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(headerHeight))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                return NSCollectionLayoutSection(group: group)
                
            } else {
                // Section 1: Pin Header + Lists
                let pinHeight = dataSource.heightForPinHeader(in: self)
                let contentHeight = self.bounds.height - pinHeight
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(contentHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                
                section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, point, environment) in
                    self?.handleHorizontalScroll(point: point, environment: environment)
                }
                
                // Pin Header（吸顶）
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(pinHeight))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                sectionHeader.pinToVisibleBounds = true
                sectionHeader.zIndex = 100
                
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            }
        }
    }
    
    // MARK: - Horizontal Scroll Tracking
    
    private func handleHorizontalScroll(point: CGPoint, environment: NSCollectionLayoutEnvironment) {
        let width = environment.container.contentSize.width
        guard width > 0 else { return }
        
        let index = Int(round(point.x / width))
        
        if index != currentIndex {
            let oldIndex = currentIndex
            currentIndex = index
            
            listDict[oldIndex]?.listDidDisappear?()
            listDict[index]?.listDidAppear?()
            
            delegate?.pagingView?(self, didSwitchToListAt: index)
        }
    }
}

// MARK: - DataSource & Delegate

extension JXOrthogonalPagingViewV2: UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return dataSource?.numberOfLists(in: self) ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            // Header Cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            if let view = headerView {
                view.frame = cell.contentView.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(view)
            }
            return cell
        } else {
            // List Cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            guard let dataSource = dataSource else { return cell }
            
            var list = listDict[indexPath.item]
            if list == nil {
                list = dataSource.pagingView(self, initListAtIndex: indexPath.item)
                listDict[indexPath.item] = list
            }
            
            if let listView = list?.listView() {
                listView.frame = cell.contentView.bounds
                listView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(listView)
                
                if !observedIndices.contains(indexPath.item), let list = list {
                    setupScrollObserver(for: list)
                    observedIndices.insert(indexPath.item)
                }
            }
            
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let wrapper = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "PinHeader", for: indexPath) as! JXPinHeaderWrapperView
            wrapper.subviews.forEach { $0.removeFromSuperview() }
            if let view = pinHeaderView {
                view.frame = wrapper.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                wrapper.addSubview(view)
            }
            return wrapper
        }
        return UICollectionReusableView()
    }
    
    // MARK: - Scroll Delegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagingView?(self, mainScrollViewDidScroll: scrollView)
    }
}

// MARK: - 🔥 V2 核心：基于 ContentOffset 的联动控制

extension JXOrthogonalPagingViewV2 {
    
    private func setupScrollObserver(for list: JXPagingListViewDelegate) {
        let scrollView = list.listScrollView()
        
        let observer = scrollView.observe(\.contentOffset, options: [.new, .old]) { [weak self] (scrollView, change) in
            guard let self = self else { return }
            self.handleListScroll(scrollView: scrollView, change: change)
        }
        observers.append(observer)
    }
    
    private func handleListScroll(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        // 如果不是当前显示的列表，忽略
        if scrollView.window == nil { return }
        
        // 🔥 关键：如果正在程序化设置 offset，避免递归
        guard !isSettingContentOffset else { return }
        
        let headerHeight = dataSource?.heightForHeader(in: self) ?? 0
        let mainOffsetY = mainCollectionView.contentOffset.y
        let listOffsetY = scrollView.contentOffset.y
        
        guard let oldListOffsetY = change.oldValue?.y,
              let newListOffsetY = change.newValue?.y else { return }
        
        let delta = newListOffsetY - oldListOffsetY
        
        // 🔥 V2 核心策略：基于 delta 的 contentOffset 控制
        
        if mainOffsetY < headerHeight {
            // ═══ 场景 1: 外层未吸顶 ═══
            // 策略：内层的滚动增量应用到外层，保持内层为 0
            
            if delta != 0 {
                isSettingContentOffset = true
                
                // 重置内层
                scrollView.contentOffset = .zero
                
                // 将 delta 应用到外层
                // 🔥 关键：无论上拉还是下拉，都应用到外层
                // 下拉时如果外层已在顶部(offsetY=0)，系统会自动处理 bounce 效果
                let newMainOffsetY = max(0, min(headerHeight, mainOffsetY + delta))
                mainCollectionView.contentOffset = CGPoint(x: 0, y: newMainOffsetY)
                
                isSettingContentOffset = false
            }
            
        } else {
            // ═══ 场景 2: 外层已吸顶 ═══
            
            if listOffsetY > 0 {
                // 2.1 内层有内容 → 保持外层固定在吸顶位置
                if mainOffsetY != headerHeight {
                    isSettingContentOffset = true
                    mainCollectionView.contentOffset = CGPoint(x: 0, y: headerHeight)
                    isSettingContentOffset = false
                }
                
            } else if listOffsetY <= 0 {
                // 2.2 内层在顶部或负值（下拉）
                
                if delta < 0 {  // 下拉手势
                    // 将内层的下拉增量应用到外层
                    isSettingContentOffset = true
                    
                    // 重置内层
                    scrollView.contentOffset = .zero
                    
                    // 将 delta 应用到外层
                    let newMainOffsetY = max(0, mainOffsetY + delta)
                    mainCollectionView.contentOffset = CGPoint(x: 0, y: newMainOffsetY)
                    
                    isSettingContentOffset = false
                }
            }
        }
    }
}
