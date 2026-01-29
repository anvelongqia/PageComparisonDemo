//
//  JXOrthogonalPagingViewControllerV2.swift
//  PageComparisonDemo
//
//  Created on 2026-01-27
//  Version 2: ContentOffset 控制方案
//

import UIKit

class JXOrthogonalPagingViewControllerV2: UIViewController {
    
    // MARK: - Properties
    
    private var pagingView: JXOrthogonalPagingViewV2!  // 🔥 使用新的 V2 类
    private var segmentControl: UISegmentedControl!
    
    // 🔥 缓存视图，避免重复创建
    private var headerView: GradientBackgroundViewV2?
    private var pinHeaderView: UIView?
    
    private lazy var pageViewControllers: [JXPagingListViewDelegate] = {
        return [
            ListPageViewControllerV2(title: "推荐", index: 0),
            ListPageViewControllerV2(title: "热门", index: 1),
            ListPageViewControllerV2(title: "关注", index: 2)
        ]
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "V2: ContentOffset控制"
        view.backgroundColor = .white
        
        setupSegmentControl()
        setupPagingView()
    }
    
    private func setupSegmentControl() {
        let items = ["推荐", "热门", "关注"]
        segmentControl = UISegmentedControl(items: items)
        segmentControl.selectedSegmentIndex = 0
        if #available(iOS 13.0, *) {
            segmentControl.selectedSegmentTintColor = .systemBlue
            segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        } else {
            segmentControl.tintColor = .systemBlue
        }
    }
    
    private func setupPagingView() {
        pagingView = JXOrthogonalPagingViewV2()
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
}

// MARK: - JXOrthogonalPagingDataSourceV2

extension JXOrthogonalPagingViewControllerV2: JXOrthogonalPagingDataSourceV2 {
    
    func heightForHeader(in pagingView: JXOrthogonalPagingViewV2) -> CGFloat {
        return 200
    }
    
    func viewForHeader(in pagingView: JXOrthogonalPagingViewV2) -> UIView {
        if headerView == nil {
            headerView = GradientBackgroundViewV2()
        }
        return headerView!
    }
    
    func heightForPinHeader(in pagingView: JXOrthogonalPagingViewV2) -> CGFloat {
        return 80
    }
    
    func viewForPinHeader(in pagingView: JXOrthogonalPagingViewV2) -> UIView {
        if pinHeaderView == nil {
            let container = UIView()
            container.backgroundColor = .white
            
            segmentControl.removeFromSuperview()
            container.addSubview(segmentControl)
            segmentControl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                segmentControl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                segmentControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                segmentControl.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 20),
                segmentControl.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20)
            ])
            
            let separator = UIView()
            separator.backgroundColor = UIColor.separator
            container.addSubview(separator)
            separator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            
            pinHeaderView = container
        }
        return pinHeaderView!
    }
    
    func numberOfLists(in pagingView: JXOrthogonalPagingViewV2) -> Int {
        return pageViewControllers.count
    }
    
    func pagingView(_ pagingView: JXOrthogonalPagingViewV2, initListAtIndex index: Int) -> JXPagingListViewDelegate {
        return pageViewControllers[index]
    }
}

// MARK: - Delegate

extension JXOrthogonalPagingViewControllerV2: JXOrthogonalPagingDelegateV2 {
    
    func pagingView(_ pagingView: JXOrthogonalPagingViewV2, didSwitchToListAt index: Int) {
        segmentControl.selectedSegmentIndex = index
        print("📱 V2: 切换到页面 \(index)")
    }
}

// MARK: - Views

class GradientBackgroundViewV2: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gradientLayer.colors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
        backgroundColor = .systemPurple
        
        titleLabel.text = "V2 版本"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        
        subtitleLabel.text = "ContentOffset控制 - 不禁用手势"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.textAlignment = .center
        addSubview(subtitleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        titleLabel.frame = CGRect(x: 20, y: 60, width: bounds.width - 40, height: 40)
        subtitleLabel.frame = CGRect(x: 20, y: titleLabel.frame.maxY + 8, width: bounds.width - 40, height: 24)
    }
}

class ListPageViewControllerV2: UIViewController, JXPagingListViewDelegate {
    
    var pageIndex: Int = 0
    private lazy var tableView = UITableView(frame: .zero, style: .plain)
    
    init(title: String, index: Int) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.pageIndex = index
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = 80
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func listView() -> UIView { return view }
    func listScrollView() -> UIScrollView { return tableView }
    func listDidAppear() { print("📱 V2: [\(title ?? "Page")] 页面出现") }
    func listDidDisappear() { print("📱 V2: [\(title ?? "Page")] 页面消失") }
}

extension ListPageViewControllerV2: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "[\(title ?? "Page")] 第 \(indexPath.row + 1) 行"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: "V2 版本", message: "点击了 [\(title ?? "Page")] 的第 \(indexPath.row + 1) 行", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
