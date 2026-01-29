//
//  JXPagingTabBarViewController.swift
//  PageComparisonDemo
//
//  展示 JXPaging 在 TabBar 场景中的实际应用
//  用例：带图片轮播头部的商品详情页风格
//

import UIKit

class JXPagingTabBarViewController: UIViewController {
    
    // MARK: - Properties
    
    private var pagingView: JXPagingSmoothView!
    private var imageCarouselHeader: ImageCarouselHeaderView!
    private var tabSegmentControl: UISegmentedControl!
    
    private lazy var pageViewControllers: [JXPagingSmoothViewListViewDelegate] = {
        return [
            ProductDetailsPageViewController(),
            ProductReviewsPageViewController(),
            ProductSpecsPageViewController()
        ]
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupSegmentControl()
        setupPagingView()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = "TabBar 用例"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupSegmentControl() {
        tabSegmentControl = UISegmentedControl(items: ["商品详情", "用户评价", "规格参数"])
        tabSegmentControl.selectedSegmentIndex = 0
        tabSegmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupPagingView() {
        pagingView = JXPagingSmoothView(dataSource: self)
        pagingView.delegate = self
        view.addSubview(pagingView)
        
        pagingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        pagingView.reloadData()
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
//        pagingView.listView(didScrollToIndex: sender.selectedSegmentIndex)
    }
}

// MARK: - JXPagingSmoothViewDataSource

extension JXPagingTabBarViewController: JXPagingSmoothViewDataSource {
    
    func heightForPagingHeader(in pagingView: JXPagingSmoothView) -> CGFloat {
        return 280 // 图片轮播 + 商品标题区域
    }
    
    func viewForPagingHeader(in pagingView: JXPagingSmoothView) -> UIView {
        if imageCarouselHeader == nil {
            imageCarouselHeader = ImageCarouselHeaderView()
        }
        return imageCarouselHeader
    }
    
    func heightForPinHeader(in pagingView: JXPagingSmoothView) -> CGFloat {
        return 44
    }
    
    func viewForPinHeader(in pagingView: JXPagingSmoothView) -> UIView {
        return tabSegmentControl
    }
    
    func numberOfLists(in pagingView: JXPagingSmoothView) -> Int {
        return pageViewControllers.count
    }
    
    func pagingView(_ pagingView: JXPagingSmoothView, initListAtIndex index: Int) -> JXPagingSmoothViewListViewDelegate {
        return pageViewControllers[index]
    }
}

// MARK: - JXPagingSmoothViewDelegate

extension JXPagingTabBarViewController: JXPagingSmoothViewDelegate {
    
    func pagingView(_ pagingView: JXPagingSmoothView, didScrollToIndex index: Int) {
        tabSegmentControl.selectedSegmentIndex = index
        print("📱 TabBar用例: 切换到页面 \(index)")
    }
}

// MARK: - ImageCarouselHeaderView (图片轮播头部)

class ImageCarouselHeaderView: UIView {
    
    private var scrollView: UIScrollView!
    private var pageControl: UIPageControl!
    private var titleLabel: UILabel!
    private var priceLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // 图片轮播区域
        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // 添加模拟图片
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange]
        for (index, color) in colors.enumerated() {
            let imageView = UIView()
            imageView.backgroundColor = color
            scrollView.addSubview(imageView)
            
            imageView.frame = CGRect(
                x: CGFloat(index) * UIScreen.main.bounds.width,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 200
            )
            
            // 添加模拟图片标签
            let label = UILabel()
            label.text = "商品图片 \(index + 1)"
            label.textColor = .white
            label.font = .systemFont(ofSize: 24, weight: .bold)
            label.textAlignment = .center
            imageView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ])
        }
        
        scrollView.contentSize = CGSize(
            width: UIScreen.main.bounds.width * CGFloat(colors.count),
            height: 200
        )
        
        // PageControl
        pageControl = UIPageControl()
        pageControl.numberOfPages = colors.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .systemGray
        pageControl.currentPageIndicatorTintColor = .white
        addSubview(pageControl)
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8)
        ])
        
        // 商品标题
        titleLabel = UILabel()
        titleLabel.text = "苹果 iPhone 15 Pro Max 256GB 深空黑色"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
        
        // 价格
        priceLabel = UILabel()
        priceLabel.text = "¥9,999"
        priceLabel.textColor = .systemRed
        priceLabel.font = .systemFont(ofSize: 28, weight: .bold)
        addSubview(priceLabel)
        
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            priceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}

// MARK: - UIScrollViewDelegate

extension ImageCarouselHeaderView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = page
    }
}

// MARK: - ProductDetailsPageViewController (商品详情)

class ProductDetailsPageViewController: UIViewController, JXPagingSmoothViewListViewDelegate {
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - JXPagingSmoothViewListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return tableView
    }
    
    func listDidAppear() {
        print("📱 商品详情页面出现")
    }
    
    func listDidDisappear() {
        print("📱 商品详情页面消失")
    }
}

// MARK: - UITableViewDelegate & DataSource

extension ProductDetailsPageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 5 : (section == 1 ? 4 : 3)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "主要特性"
        case 1: return "技术规格"
        case 2: return "包装清单"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            let features = ["A17 Pro 芯片", "ProMotion 120Hz 显示屏", "钛金属边框", "4800万像素主摄", "全天候电池续航"]
            cell.textLabel?.text = features[indexPath.row]
        case 1:
            let specs = ["6.7 英寸 OLED 屏幕", "256GB 存储空间", "支持 5G 网络", "IP68 防水防尘"]
            cell.textLabel?.text = specs[indexPath.row]
        case 2:
            let items = ["iPhone 15 Pro Max", "USB-C 充电线", "说明书"]
            cell.textLabel?.text = items[indexPath.row]
        default:
            break
        }
        
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - ProductReviewsPageViewController (用户评价)

class ProductReviewsPageViewController: UIViewController, JXPagingSmoothViewListViewDelegate {
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReviewCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - JXPagingSmoothViewListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return tableView
    }
    
    func listDidAppear() {
        print("📱 用户评价页面出现")
    }
    
    func listDidDisappear() {
        print("📱 用户评价页面消失")
    }
}

extension ProductReviewsPageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        
        let reviews = [
            "⭐⭐⭐⭐⭐ 非常满意！钛金属质感很棒，拍照效果超出预期。",
            "⭐⭐⭐⭐ 性能强劲，就是价格有点贵...",
            "⭐⭐⭐⭐⭐ 升级后感觉很值，续航比上一代好很多！",
            "⭐⭐⭐ 外观不错，但没有充电头有点不方便。"
        ]
        
        cell.textLabel?.text = reviews[indexPath.row % reviews.count]
        cell.textLabel?.font = .systemFont(ofSize: 14)
        return cell
    }
}

// MARK: - ProductSpecsPageViewController (规格参数)

class ProductSpecsPageViewController: UIViewController, JXPagingSmoothViewListViewDelegate {
    
    private var scrollView: UIScrollView!
    private var contentStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        contentStackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStackView)
        
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        addSpecItems()
    }
    
    private func addSpecItems() {
        let specs = [
            ("屏幕", "6.7 英寸超视网膜 XDR 显示屏\nProMotion 自适应刷新率技术"),
            ("芯片", "A17 Pro 芯片\n新一代 6 核中央处理器\n新一代 6 核图形处理器"),
            ("摄像头", "4800 万像素主摄\n1200 万像素超广角\n1200 万像素长焦 (5 倍光学变焦)"),
            ("电池", "视频播放最长可达 29 小时\n支持 MagSafe 和 Qi 无线充电"),
            ("尺寸重量", "高度：159.9 毫米\n宽度：76.7 毫米\n厚度：8.25 毫米\n重量：221 克")
        ]
        
        for (title, content) in specs {
            let view = createSpecView(title: title, content: content)
            contentStackView.addArrangedSubview(view)
        }
    }
    
    private func createSpecView(title: String, content: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        containerView.addSubview(titleLabel)
        
        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = .systemFont(ofSize: 14)
        contentLabel.textColor = .secondaryLabel
        contentLabel.numberOfLines = 0
        containerView.addSubview(contentLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            contentLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    // MARK: - JXPagingSmoothViewListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return scrollView
    }
    
    func listDidAppear() {
        print("📱 规格参数页面出现")
    }
    
    func listDidDisappear() {
        print("📱 规格参数页面消失")
    }
}
