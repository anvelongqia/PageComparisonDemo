//
//  JXOrthogonalPagingViewController.swift
//  PageComparisonDemo
//
//  展示 JXOrthogonalPagingView 的实际应用
//  使用 Compositional Layout 实现横向正交滚动
//

import UIKit

/// 主容器：使用 JXOrthogonalPagingView 实现横向分页
class JXOrthogonalPagingViewController: UIViewController {
    
    // MARK: - Properties
    
    private var pagingView: JXOrthogonalPagingView!
    private var topBannerView: TopBannerView!
    private var segmentControl: UISegmentedControl!
    
    private lazy var pageViewControllers: [JXPagingListViewDelegate] = {
        return [
            OrthogonalPage1ViewController(),
            OrthogonalPage2ViewController(),
            OrthogonalPage3ViewController()
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
        title = "正交滚动用例"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupSegmentControl() {
        segmentControl = UISegmentedControl(items: ["推荐", "关注", "热门"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupPagingView() {
        pagingView = JXOrthogonalPagingView()
        pagingView.dataSource = self
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
        // 通过滚动到指定位置来切换页面
        let targetX = CGFloat(sender.selectedSegmentIndex) * pagingView.bounds.width
        pagingView.mainCollectionView.setContentOffset(CGPoint(x: 0, y: pagingView.bounds.height + targetX), animated: true)
    }
}

// MARK: - JXOrthogonalPagingDataSource

extension JXOrthogonalPagingViewController: JXOrthogonalPagingDataSource {
    
    func heightForHeader(in pagingView: JXOrthogonalPagingView) -> CGFloat {
        return 180 // 顶部 Banner 高度
    }
    
    func viewForHeader(in pagingView: JXOrthogonalPagingView) -> UIView {
        if topBannerView == nil {
            topBannerView = TopBannerView()
        }
        return topBannerView
    }
    
    func heightForPinHeader(in pagingView: JXOrthogonalPagingView) -> CGFloat {
        return 44
    }
    
    func viewForPinHeader(in pagingView: JXOrthogonalPagingView) -> UIView {
        return segmentControl
    }
    
    func numberOfLists(in pagingView: JXOrthogonalPagingView) -> Int {
        return pageViewControllers.count
    }
    
    func pagingView(_ pagingView: JXOrthogonalPagingView, initListAtIndex index: Int) -> JXPagingListViewDelegate {
        return pageViewControllers[index]
    }
}

// MARK: - JXOrthogonalPagingDelegate

extension JXOrthogonalPagingViewController: JXOrthogonalPagingDelegate {
    
    func pagingView(_ pagingView: JXOrthogonalPagingView, didSwitchToListAt index: Int) {
        segmentControl.selectedSegmentIndex = index
        print("📱 正交滚动: 切换到页面 \(index)")
    }
    
    func pagingView(_ pagingView: JXOrthogonalPagingView, mainScrollViewDidScroll scrollView: UIScrollView) {
        // 可以在这里实现导航栏渐变等效果
        let offsetY = scrollView.contentOffset.y
        let alpha = min(1.0, max(0.0, offsetY / 100.0))
        navigationController?.navigationBar.alpha = alpha
    }
}

// MARK: - TopBannerView (顶部 Banner)

class TopBannerView: UIView {
    
    private var gradientLayer: CAGradientLayer!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 渐变背景
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemPurple.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 标题
        titleLabel = UILabel()
        titleLabel.text = "正交滚动演示"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10)
        ])
        
        // 副标题
        subtitleLabel = UILabel()
        subtitleLabel.text = "横向滑动切换页面"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .white.withAlphaComponent(0.9)
        subtitleLabel.textAlignment = .center
        addSubview(subtitleLabel)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - OrthogonalPage1ViewController (推荐页面)

class OrthogonalPage1ViewController: UIViewController, JXPagingListViewDelegate {
    
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - JXPagingListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return tableView
    }
    
    func listDidAppear() {
        print("📱 推荐页面出现")
    }
    
    func listDidDisappear() {
        print("📱 推荐页面消失")
    }
}

extension OrthogonalPage1ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "🔥 推荐内容 \(indexPath.row + 1)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("点击了推荐项 \(indexPath.row + 1)")
    }
}

// MARK: - OrthogonalPage2ViewController (关注页面)

class OrthogonalPage2ViewController: UIViewController, JXPagingListViewDelegate {
    
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (UIScreen.main.bounds.width - 36) / 2, height: 120)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - JXPagingListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return collectionView
    }
    
    func listDidAppear() {
        print("📱 关注页面出现")
    }
    
    func listDidDisappear() {
        print("📱 关注页面消失")
    }
}

extension OrthogonalPage2ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPink, .systemPurple]
        cell.configure(color: colors[indexPath.item % colors.count], title: "关注 \(indexPath.item + 1)")
        return cell
    }
}

// MARK: - ColorCell

class ColorCell: UICollectionViewCell {
    
    private var containerView: UIView!
    private var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        containerView = UIView()
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        contentView.addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(color: UIColor, title: String) {
        containerView.backgroundColor = color
        titleLabel.text = title
    }
}

// MARK: - OrthogonalPage3ViewController (热门页面)

class OrthogonalPage3ViewController: UIViewController, JXPagingListViewDelegate {
    
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        loadContent()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.backgroundColor = .systemGroupedBackground
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func loadContent() {
        for i in 1...15 {
            let card = createHotCard(title: "热门话题 #\(i)", subtitle: "\(i * 1234) 人参与讨论")
            stackView.addArrangedSubview(card)
        }
    }
    
    private func createHotCard(title: String, subtitle: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        container.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        container.addSubview(subtitleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return container
    }
    
    // MARK: - JXPagingListViewDelegate
    
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return scrollView
    }
    
    func listDidAppear() {
        print("📱 热门页面出现")
    }
    
    func listDidDisappear() {
        print("📱 热门页面消失")
    }
}
