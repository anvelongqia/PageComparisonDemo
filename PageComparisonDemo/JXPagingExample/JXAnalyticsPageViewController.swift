//
//  JXAnalyticsPageViewController.swift
//  PageComparisonDemo
//
//  Created on 2026-01-22.
//

import UIKit

class JXAnalyticsPageViewController: UIViewController {
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.backgroundColor = .systemBackground
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let chartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private var timer: Timer?
    private var secondsElapsed = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(chartView)
        contentView.addSubview(statsLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            chartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chartView.heightAnchor.constraint(equalToConstant: 300),
            
            statsLabel.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 20),
            statsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        updateStats()
        
        // Add chart bars
        addChartBars()
        
        // Make content taller to enable scrolling
        statsLabel.text = generateLongStats()
    }
    
    private func addChartBars() {
        let barCount = 7
        let barWidth: CGFloat = 30
        let spacing: CGFloat = 10
        let totalWidth = CGFloat(barCount) * (barWidth + spacing) - spacing
        let startX = (UIScreen.main.bounds.width - 40 - totalWidth) / 2
        
        for i in 0..<barCount {
            let height = CGFloat.random(in: 50...250)
            let bar = UIView()
            bar.backgroundColor = .systemBlue
            bar.layer.cornerRadius = 4
            bar.frame = CGRect(
                x: startX + CGFloat(i) * (barWidth + spacing),
                y: 300 - height - 20,
                width: barWidth,
                height: height
            )
            chartView.addSubview(bar)
        }
    }
    
    private func generateLongStats() -> String {
        return """
        📊 Analytics Summary
        
        Total Views: 12,345
        Unique Visitors: 8,901
        Bounce Rate: 32.5%
        Avg Session: 5m 23s
        
        Top Pages:
        1. Home - 3,421 views
        2. Products - 2,876 views
        3. About - 1,234 views
        4. Contact - 987 views
        5. Blog - 876 views
        
        Traffic Sources:
        • Direct: 45%
        • Search: 30%
        • Social: 15%
        • Referral: 10%
        
        Device Breakdown:
        📱 Mobile: 60%
        💻 Desktop: 35%
        📟 Tablet: 5%
        """
    }
    
    private func updateStats() {
        secondsElapsed += 1
        // Update periodically (we'll start timer in listDidAppear)
    }
}

// MARK: - JXPagingSmoothViewListViewDelegate
extension JXAnalyticsPageViewController: JXPagingSmoothViewListViewDelegate {
    func listView() -> UIView {
        return view
    }
    
    func listScrollView() -> UIScrollView {
        return scrollView
    }
    
    func listDidAppear() {
        print("📈 Analytics page appeared")
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func listDidDisappear() {
        print("📈 Analytics page disappeared")
        timer?.invalidate()
        timer = nil
    }
}
