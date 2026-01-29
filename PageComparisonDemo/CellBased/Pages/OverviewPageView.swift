//
//  OverviewPageView.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class OverviewPageView: UIView {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let refreshControl = UIRefreshControl()
    private var dataSource: [String] = []
    private var currentPage = 0
    private var isLoading = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        loadInitialData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGroupedBackground
        
        addSubview(tableView)
        tableView.pinToSuperview()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func loadInitialData() {
        isLoading = true
        NetworkSimulator.fetchData(page: 0) { [weak self] items in
            guard let self = self else { return }
            self.dataSource = items
            self.tableView.reloadData()
            self.isLoading = false
        }
    }
    
    @objc private func handleRefresh() {
        currentPage = 0
        NetworkSimulator.fetchData(page: 0) { [weak self] items in
            guard let self = self else { return }
            self.dataSource = items
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    private func loadMoreData() {
        guard !isLoading else { return }
        isLoading = true
        currentPage += 1
        
        NetworkSimulator.fetchData(page: currentPage) { [weak self] items in
            guard let self = self else { return }
            self.dataSource.append(contentsOf: items)
            self.tableView.reloadData()
            self.isLoading = false
        }
    }
}

// MARK: - UITableViewDataSource

extension OverviewPageView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OverviewPageView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Cell-based approach: Show alert instead of push
        if let window = window {
            let alert = UIAlertController(
                title: "Cell-Based Limitation",
                message: "Cannot push new ViewController from UIView.\nSelected: \(dataSource[indexPath.row])",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height - 100 {
            loadMoreData()
        }
    }
}
