//
//  JXPagingSmoothView.swift
//  JXPagingView
//
//  Created by jiaxin on 2019/11/20.
//  Copyright © 2019 jiaxin. All rights reserved.
//

import UIKit

@objc public protocol JXPagingSmoothViewListViewDelegate {
    /// 返回listView。如果是vc包裹的就是vc.view；如果是自定义view包裹的，就是自定义view自己。
    func listView() -> UIView
    /// 返回JXPagerSmoothViewListViewDelegate内部持有的UIScrollView或UITableView或UICollectionView
    func listScrollView() -> UIScrollView
    @objc optional func listDidAppear()
    @objc optional func listDidDisappear()
}

@objc
public protocol JXPagingSmoothViewDataSource {
    /// 返回页面header的高度
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat
    /// 返回页面header视图
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView
    /// 返回悬浮视图的高度
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat
    /// 返回悬浮视图
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView
    /// 返回列表的数量
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int
    /// 根据index初始化一个对应列表实例，需要是遵从`JXPagingSmoothViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`JXPagingSmoothViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`JXPagingSmoothViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> JXPagingSmoothViewListViewDelegate
}

@objc
public protocol JXPagingSmoothViewDelegate {
    @objc optional func pagingSmoothViewDidScroll(_ scrollView: UIScrollView)
}


open class JXPagingSmoothView: UIView {
    public private(set) var listDict = [Int : JXPagingSmoothViewListViewDelegate]()
    public let listCollectionView: JXPagingSmoothCollectionView
    public var defaultSelectedIndex: Int = 0
    public weak var delegate: JXPagingSmoothViewDelegate?

    weak var dataSource: JXPagingSmoothViewDataSource?
    var listHeaderDict = [Int : UIView]()
    var isSyncListContentOffsetEnabled: Bool = false
    let pagingHeaderContainerView: UIView
    var currentPagingHeaderContainerViewY: CGFloat = 0
    var currentIndex: Int = 0
    var currentListScrollView: UIScrollView?
    var heightForPagingHeader: CGFloat = 0
    var heightForPinHeader: CGFloat = 0
    var heightForPagingHeaderContainerView: CGFloat = 0
    let cellIdentifier = "cell"
    var currentListInitializeContentOffsetY: CGFloat = 0
    var singleScrollView: UIScrollView?

    deinit {
        listDict.values.forEach {
            $0.listScrollView().removeObserver(self, forKeyPath: "contentOffset")
            $0.listScrollView().removeObserver(self, forKeyPath: "contentSize")
        }
    }

    public init(dataSource: JXPagingSmoothViewDataSource) {
        self.dataSource = dataSource
        pagingHeaderContainerView = UIView()
        let layout = JXRTLFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        listCollectionView = JXPagingSmoothCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        super.init(frame: CGRect.zero)

        listCollectionView.dataSource = self
        listCollectionView.delegate = self
        listCollectionView.isPagingEnabled = true
        listCollectionView.bounces = false
        listCollectionView.showsHorizontalScrollIndicator = false
        listCollectionView.scrollsToTop = false
        listCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        if #available(iOS 10.0, *) {
            listCollectionView.isPrefetchingEnabled = false
        }
        if #available(iOS 11.0, *) {
            listCollectionView.contentInsetAdjustmentBehavior = .never
        }
        listCollectionView.pagingHeaderContainerView = pagingHeaderContainerView
        addSubview(listCollectionView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadData() {
        guard let dataSource = dataSource else { return }
        currentListScrollView = nil
        currentIndex = defaultSelectedIndex
        currentPagingHeaderContainerViewY = 0
        isSyncListContentOffsetEnabled = false

        listHeaderDict.values.forEach { $0.removeFromSuperview() }
        listHeaderDict.removeAll()
        listDict.values.forEach { (list) in
            list.listScrollView().removeObserver(self, forKeyPath: "contentOffset")
            list.listScrollView().removeObserver(self, forKeyPath: "contentSize")
            list.listView().removeFromSuperview()
        }
        listDict.removeAll()

        heightForPagingHeader = dataSource.heightForPagingHeader(in: self)
        heightForPinHeader = dataSource.heightForPinHeader(in: self)
        heightForPagingHeaderContainerView = heightForPagingHeader + heightForPinHeader

        let pagingHeader = dataSource.viewForPagingHeader(in: self)
        let pinHeader = dataSource.viewForPinHeader(in: self)
        pagingHeaderContainerView.addSubview(pagingHeader)
        pagingHeaderContainerView.addSubview(pinHeader)

        pagingHeaderContainerView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: heightForPagingHeaderContainerView)
        pagingHeader.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: heightForPagingHeader)
        pinHeader.frame = CGRect(x: 0, y: heightForPagingHeader, width: bounds.size.width, height: heightForPinHeader)
        listCollectionView.setContentOffset(CGPoint(x: listCollectionView.bounds.size.width*CGFloat(defaultSelectedIndex), y: 0), animated: false)
        listCollectionView.reloadData()

        if dataSource.numberOfLists(in: self) == 0 {
            singleScrollView = UIScrollView()
            addSubview(singleScrollView!)
            singleScrollView?.addSubview(pagingHeader)
            singleScrollView?.contentSize = CGSize(width: bounds.size.width, height: heightForPagingHeader)
        }else if singleScrollView != nil {
            singleScrollView?.removeFromSuperview()
            singleScrollView = nil
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        listCollectionView.frame = bounds
        if pagingHeaderContainerView.frame == CGRect.zero {
            reloadData()
        }
        if singleScrollView != nil {
            singleScrollView?.frame = bounds
        }
    }

    func listDidScroll(scrollView: UIScrollView) {
        if listCollectionView.isDragging || listCollectionView.isDecelerating {
            return
        }
        let index = listIndex(for: scrollView)
        if index != currentIndex {
            return
        }
        currentListScrollView = scrollView
        let contentOffsetY = scrollView.contentOffset.y + heightForPagingHeaderContainerView
        if contentOffsetY < heightForPagingHeader {
            isSyncListContentOffsetEnabled = true
            currentPagingHeaderContainerViewY = -contentOffsetY
            for list in listDict.values {
                if list.listScrollView() != currentListScrollView {
                    list.listScrollView().setContentOffset(scrollView.contentOffset, animated: false)
                }
            }
            let header = listHeader(for: scrollView)
            if pagingHeaderContainerView.superview != header {
                pagingHeaderContainerView.frame.origin.y = 0
                header?.addSubview(pagingHeaderContainerView)
            }
        }else {
            if pagingHeaderContainerView.superview != self {
                pagingHeaderContainerView.frame.origin.y = -heightForPagingHeader
                addSubview(pagingHeaderContainerView)
            }
            if isSyncListContentOffsetEnabled {
                isSyncListContentOffsetEnabled = false
                currentPagingHeaderContainerViewY = -heightForPagingHeader
                for list in listDict.values {
                    if list.listScrollView() != currentListScrollView {
                        list.listScrollView().setContentOffset(CGPoint(x: 0, y: -heightForPinHeader), animated: false)
                    }
                }
            }
        }
    }

    //MARK: - KVO

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            if let scrollView = object as? UIScrollView {
                listDidScroll(scrollView: scrollView)
            }
        }else if keyPath == "contentSize" {
            if let scrollView = object as? UIScrollView {
                let minContentSizeHeight = bounds.size.height - heightForPinHeader
                if minContentSizeHeight > scrollView.contentSize.height {
                    scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: minContentSizeHeight)
                    //新的scrollView第一次加载的时候重置contentOffset
                    if currentListScrollView != nil, scrollView != currentListScrollView! {
                        scrollView.contentOffset = CGPoint(x: 0, y: currentListInitializeContentOffsetY)
                    }
                }
            }
        }else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    //MARK: - Private
    func listHeader(for listScrollView: UIScrollView) -> UIView? {
        for (index, list) in listDict {
            if list.listScrollView() == listScrollView {
                return listHeaderDict[index]
            }
        }
        return nil
    }

    func listIndex(for listScrollView: UIScrollView) -> Int {
        for (index, list) in listDict {
            if list.listScrollView() == listScrollView {
                return index
            }
        }
        return 0
    }

    func listDidAppear(at index: Int) {
        guard let dataSource = dataSource else { return }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        listDict[index]?.listDidAppear?()
    }

    func listDidDisappear(at index: Int) {
        guard let dataSource = dataSource else { return }
        let count = dataSource.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        listDict[index]?.listDidDisappear?()
    }

    /// 列表左右切换滚动结束之后，需要把pagerHeaderContainerView添加到当前index的列表上面
    func horizontalScrollDidEnd(at index: Int) {
        currentIndex = index
        guard let listHeader = listHeaderDict[index], let listScrollView = listDict[index]?.listScrollView() else {
            return
        }
        listDict.values.forEach { $0.listScrollView().scrollsToTop = ($0.listScrollView() === listScrollView) }
        if listScrollView.contentOffset.y <= -heightForPinHeader {
            pagingHeaderContainerView.frame.origin.y = 0
            listHeader.addSubview(pagingHeaderContainerView)
        }
    }
}

extension JXPagingSmoothView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bounds.size
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.numberOfLists(in: self)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let dataSource = dataSource else { return UICollectionViewCell(frame: CGRect.zero) }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        var list = listDict[indexPath.item]
        if list == nil {
            list = dataSource.pagingView(self, initListAtIndex: indexPath.item)
            listDict[indexPath.item] = list!
            list?.listView().setNeedsLayout()
            list?.listView().layoutIfNeeded()
            if list?.listScrollView().isKind(of: UITableView.self) == true {
                (list?.listScrollView() as? UITableView)?.estimatedRowHeight = 0
                (list?.listScrollView() as? UITableView)?.estimatedSectionHeaderHeight = 0
                (list?.listScrollView() as? UITableView)?.estimatedSectionFooterHeight = 0
            }
            if #available(iOS 11.0, *) {
                list?.listScrollView().contentInsetAdjustmentBehavior = .never
            }
            list?.listScrollView().contentInset = UIEdgeInsets(top: heightForPagingHeaderContainerView, left: 0, bottom: 0, right: 0)
            currentListInitializeContentOffsetY = -heightForPagingHeaderContainerView + min(-currentPagingHeaderContainerViewY, heightForPagingHeader)
            list?.listScrollView().contentOffset = CGPoint(x: 0, y: currentListInitializeContentOffsetY)
            let listHeader = UIView(frame: CGRect(x: 0, y: -heightForPagingHeaderContainerView, width: bounds.size.width, height: heightForPagingHeaderContainerView))
            list?.listScrollView().addSubview(listHeader)
            if pagingHeaderContainerView.superview == nil {
                listHeader.addSubview(pagingHeaderContainerView)
            }
            listHeaderDict[indexPath.item] = listHeader
            list?.listScrollView().addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
            list?.listScrollView().addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        }
        listDict.values.forEach { $0.listScrollView().scrollsToTop = ($0 === list) }
        if let listView = list?.listView(), listView.superview != cell.contentView {
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            listView.frame = cell.contentView.bounds
            cell.contentView.addSubview(listView)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        listDidAppear(at: indexPath.item)
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        listDidDisappear(at: indexPath.item)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagingSmoothViewDidScroll?(scrollView)
        let indexPercent = scrollView.contentOffset.x/scrollView.bounds.size.width
        let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
        let listScrollView = listDict[index]?.listScrollView()
        if (indexPercent - CGFloat(index) == 0) && index != currentIndex && !(scrollView.isDragging || scrollView.isDecelerating) && listScrollView?.contentOffset.y ?? 0 <= -heightForPinHeader {
            horizontalScrollDidEnd(at: index)
        }else {
            //左右滚动的时候，就把listHeaderContainerView添加到self，达到悬浮在顶部的效果
            if pagingHeaderContainerView.superview != self {
                pagingHeaderContainerView.frame.origin.y = currentPagingHeaderContainerViewY
                addSubview(pagingHeaderContainerView)
            }
        }
        if index != currentIndex {
            currentIndex = index
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
            horizontalScrollDidEnd(at: index)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x/scrollView.bounds.size.width)
        horizontalScrollDidEnd(at: index)
    }
}

public class JXPagingSmoothCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    var pagingHeaderContainerView: UIView?
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: pagingHeaderContainerView)
        if pagingHeaderContainerView?.bounds.contains(point) == true {
            return false
        }
        return true
    }
}


import UIKit
import Combine

// MARK: - 1. 协议定义

@objc public protocol JXPagingListViewDelegate {
    /// 返回列表的主视图 (通常是 self)
    func listView() -> UIView
    /// 返回列表内部的 ScrollView (TableView/CollectionView)
    func listScrollView() -> UIScrollView
    /// 生命周期回调
    @objc optional func listDidAppear()
    @objc optional func listDidDisappear()
}

@objc public protocol JXOrthogonalPagingDataSource: AnyObject {
    /// 顶部大图 Header 的高度
    func heightForHeader(in pagingView: JXOrthogonalPagingView) -> CGFloat
    /// 顶部大图 Header 的视图
    func viewForHeader(in pagingView: JXOrthogonalPagingView) -> UIView
    
    /// 吸顶悬浮 Header (Tab栏) 的高度
    func heightForPinHeader(in pagingView: JXOrthogonalPagingView) -> CGFloat
    /// 吸顶悬浮 Header (Tab栏) 的视图
    func viewForPinHeader(in pagingView: JXOrthogonalPagingView) -> UIView
    
    /// 列表数量
    func numberOfLists(in pagingView: JXOrthogonalPagingView) -> Int
    /// 初始化对应 Index 的列表
    func pagingView(_ pagingView: JXOrthogonalPagingView, initListAtIndex index: Int) -> JXPagingListViewDelegate
}

@objc public protocol JXOrthogonalPagingDelegate: AnyObject {
    /// 监听纵向滚动 (用于导航栏渐变等)
    @objc optional func pagingView(_ pagingView: JXOrthogonalPagingView, mainScrollViewDidScroll scrollView: UIScrollView)
    /// 监听横向切换
    @objc optional func pagingView(_ pagingView: JXOrthogonalPagingView, didSwitchToListAt index: Int)
}

// MARK: - 2. 主视图类

open class JXOrthogonalPagingView: UIView {
    
    // MARK: - Properties
    public weak var dataSource: JXOrthogonalPagingDataSource?
    public weak var delegate: JXOrthogonalPagingDelegate?
    
    public private(set) lazy var mainCollectionView: UICollectionView = {
        let cv = JXGesturePassingCollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.delegate = self
        cv.dataSource = self
        // 注册 Cell 和 SupplementaryView
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "HeaderContainerCell")
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ListContainerCell")
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
    
    /// 标记是否允许主视图滚动
    private var isMainScrollEnabled: Bool = true
    
    // KVO 观察者集合
    private var observers: [NSKeyValueObservation] = []
    
    // 追踪已添加 observer 的列表索引
    private var observedIndices = Set<Int>()
    
    // 🔥 记录内层滚动的最后速度（用于惯性传递）
    private var lastListScrollVelocity: CGFloat = 0
    
    // 🔥 记录最后一次滚动的时间戳（用于更准确的速度计算）
    private var lastScrollTimestamp: TimeInterval = 0
    private var lastScrollOffset: CGFloat = 0
    
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
        // 重置状态
        listDict.removeAll()
        observers.removeAll() // 移除旧的 KVO
        observedIndices.removeAll() // 清空追踪记录
        currentIndex = 0
        isMainScrollEnabled = true
        
        // 重新获取 Header
        headerView = dataSource?.viewForHeader(in: self)
        pinHeaderView = dataSource?.viewForPinHeader(in: self)
        
        // 刷新布局（因为高度可能变了）
        mainCollectionView.collectionViewLayout = makeLayout()
        mainCollectionView.reloadData()
    }
    
    // MARK: - Compositional Layout
    
    private func makeLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self, let dataSource = self.dataSource else { return nil }
            
            if sectionIndex == 0 {
                // --- Section 0: Paging Header (顶部大图) ---
                let headerHeight = dataSource.heightForHeader(in: self)
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(headerHeight))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                
                return NSCollectionLayoutSection(group: group)
                
            } else {
                // --- Section 1: Pin Header + Lists ---
                let pinHeight = dataSource.heightForPinHeader(in: self)
                // 列表高度 = 整个视图高度 - 吸顶Header高度
                let contentHeight = self.bounds.height - pinHeight
                
                // 1. Item (列表页)
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                // 2. Group (横向排列的组)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(contentHeight))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                
                // 3. 🔥 核心：开启正交滚动 (横向翻页)
                section.orthogonalScrollingBehavior = .groupPaging
                
                // 4. 🔥 监听横向滚动索引变化
                section.visibleItemsInvalidationHandler = { [weak self] (visibleItems, point, environment) in
                    self?.handleHorizontalScroll(point: point, environment: environment)
                }
                
                // 5. Pin Header (吸顶 Header)
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(pinHeight))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                sectionHeader.pinToVisibleBounds = true // 开启吸顶
                sectionHeader.zIndex = 100 // 确保在列表之上
                
                section.boundarySupplementaryItems = [sectionHeader]
                
                return section
            }
        }
    }
    
    // MARK: - Logic: Horizontal Scroll Tracking
    
    private func handleHorizontalScroll(point: CGPoint, environment: NSCollectionLayoutEnvironment) {
        // 计算当前页码
        let width = environment.container.contentSize.width
        guard width > 0 else { return }
        
        // 正交滚动的 point.x 是相对于 Section 内容的
        let index = Int(round(point.x / width))
        
        if index != currentIndex {
            let oldIndex = currentIndex
            currentIndex = index
            
            // 触发出现/消失回调
            listDict[oldIndex]?.listDidDisappear?()
            listDict[index]?.listDidAppear?()
            
            delegate?.pagingView?(self, didSwitchToListAt: index)
        }
    }
}

// MARK: - 3. DataSource & Delegate

extension JXOrthogonalPagingView: UICollectionViewDataSource, UICollectionViewDelegate {
    
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderContainerCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            if let view = headerView {
                view.frame = cell.contentView.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(view)
            }
            return cell
        } else {
            // List Cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListContainerCell", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            guard let dataSource = dataSource else { return cell }
            
            // 获取或初始化 List
            var list = listDict[indexPath.item]
            if list == nil {
                list = dataSource.pagingView(self, initListAtIndex: indexPath.item)
                listDict[indexPath.item] = list
            }
            
            if let listView = list?.listView() {
                listView.frame = cell.contentView.bounds
                listView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(listView)
                
                // 🔥 只在第一次添加 observer（确保 viewDidLoad 已调用）
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
    
    // MARK: - Scroll Delegate (Outer Scroll)
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.pagingView?(self, mainScrollViewDidScroll: scrollView)
        
        // 🔥 滚动控制完全由 handleListScroll() 管理
        // 这里只需要通知 delegate
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print(velocity)
    }
}

// MARK: - 4. 核心联动逻辑 (Nested Scrolling Logic)

extension JXOrthogonalPagingView {
    
    private func setupScrollObserver(for list: JXPagingListViewDelegate) {
        let scrollView = list.listScrollView()
        
        // 使用 iOS 11+ 新版 KVO API
        let observer = scrollView.observe(\.contentOffset, options: [.new, .old]) { [weak self] (scrollView, change) in
            guard let self = self else { return }
            self.handleListScroll(scrollView: scrollView, change: change)
        }
        observers.append(observer)
    }
    
    private func handleListScroll(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        // 如果当前滚动的不是屏幕上显示的这个列表（正交滚动会有预加载），忽略
        if scrollView.window == nil { return }
        
        let headerHeight = dataSource?.heightForHeader(in: self) ?? 0
        let mainOffsetY = mainCollectionView.contentOffset.y
        let listOffsetY = scrollView.contentOffset.y
        
        // 🔥 更准确的速度计算（基于真实时间间隔）
        let currentTime = CACurrentMediaTime()
        if lastScrollTimestamp > 0 {
            let deltaTime = currentTime - lastScrollTimestamp
            if deltaTime > 0 {
                let deltaOffset = listOffsetY - lastScrollOffset
                // 计算实时速度（points per second）
                let instantVelocity = deltaOffset / CGFloat(deltaTime)
                
                // 🔥 只在内层有内容滚动时记录速度（避免越界时的干扰）
                if listOffsetY > 0 {
                    lastListScrollVelocity = instantVelocity
                }
            }
        }
        lastScrollTimestamp = currentTime
        lastScrollOffset = listOffsetY
        
        // 🔥 核心逻辑：简单清晰的优先级控制
        
        if mainOffsetY < headerHeight {
            // 场景 1: 外层未吸顶
            if listOffsetY > 0 {
                scrollView.contentOffset = .zero
            }
            (mainCollectionView as? JXGesturePassingCollectionView)?.canScroll = true
            
        } else {
            // 场景 2: 外层已吸顶
            if listOffsetY > 0 {
                // 内层正在滚动内容，锁定外层
                (mainCollectionView as? JXGesturePassingCollectionView)?.canScroll = false
                
            } else if listOffsetY <= 0 {
                // 内层在顶部或越界
                
                // 检查是否刚从有偏移到达顶部
                if let oldOffset = change.oldValue?.y, oldOffset > 0 && listOffsetY <= 0 {
                    // 🎯 惯性传递：内层刚滚动到顶
                    
                    // 🔥 使用之前记录的速度（因为到顶时 panGestureRecognizer.velocity 已经是 0）
                    let velocity = lastListScrollVelocity
                    
                    if abs(velocity) > 50 {  // 降低阈值，让更多滑动都能传递
                        print("🔥 惯性传递: velocity = \(velocity) pt/s")
                        
                        // 使用物理公式计算减速距离
                        // s = v² / (2 * a)
                        // UIScrollView 的减速度约 2000-3000 pt/s²
                        let deceleration: CGFloat = 2500.0
                        let distance = (velocity * velocity) / (2.0 * deceleration)
                        let targetY = max(0, mainOffsetY - distance)
                        
                        print("   📐 distance = \(distance) pt, targetY = \(targetY)")
                        
                        // 允许外层滚动
                        (mainCollectionView as? JXGesturePassingCollectionView)?.canScroll = true
                        
                        // 🔥 使用原生 ScrollView 动画（比 UIView.animate 更自然）
                        mainCollectionView.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
                        
                        lastListScrollVelocity = 0  // 重置速度
                    } else {
                        (mainCollectionView as? JXGesturePassingCollectionView)?.canScroll = true
                    }
                } else {
                    // 内层已在顶部，允许外层
                    (mainCollectionView as? JXGesturePassingCollectionView)?.canScroll = true
                }
            }
        }
    }
}

// MARK: - 5. 辅助类

/// 允许手势穿透的 CollectionView
class JXGesturePassingCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    
    /// 外部控制是否允许主视图滚动（避免和父类的 isScrollEnabled 冲突）
    var canScroll: Bool = true
    
    /// 关键：允许多手势同时识别
    /// 这让用户手指在 Inner List 滑动时，Outer CollectionView 也能收到事件
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view is UICollectionView || otherGestureRecognizer.view is UICollectionView || otherGestureRecognizer.view is UIScrollView
    }
    
    /// 🔥 重写此方法来控制是否响应滚动手势
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 如果是 pan 手势（滚动手势）
        if gestureRecognizer == self.panGestureRecognizer {
            return canScroll
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

/// Pin Header 的容器 ReusableView
class JXPinHeaderWrapperView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white // 避免透视
        layer.zPosition = 100    // 提高层级
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
