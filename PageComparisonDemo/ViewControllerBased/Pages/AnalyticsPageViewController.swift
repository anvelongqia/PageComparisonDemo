//
//  AnalyticsPageViewController.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit

class AnalyticsPageViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var dataPoints: [ChartDataPoint] = []
    private var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎮 [Analytics VC] viewDidLoad")
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👀 [Analytics VC] viewWillAppear - Starting timer")
        startUpdating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("👋 [Analytics VC] viewWillDisappear - Stopping timer")
        stopUpdating()
    }
    
    deinit {
        print("💀 [Analytics VC] deinit")
        updateTimer?.invalidate()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.pinToSuperview()
        
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        refreshData()
    }
    
    // ✅ VC-based: Can use viewWillAppear/Disappear to control timer
    private func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    private func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func refreshData() {
        dataPoints = ChartDataPoint.generateRandom(count: 10)
        updateChartViews()
    }
    
    private func updateChartViews() {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let headerLabel = UILabel()
        headerLabel.text = "📊 Analytics (VC Lifecycle)\nTimer starts/stops with viewWillAppear/Disappear"
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        contentStack.addArrangedSubview(headerLabel)
        
        for dataPoint in dataPoints {
            let barView = createBarView(for: dataPoint)
            contentStack.addArrangedSubview(barView)
        }
        
        let infoLabel = UILabel()
        infoLabel.text = "ℹ️ Timer only runs when page is visible\n✅ Proper lifecycle management"
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        contentStack.addArrangedSubview(infoLabel)
    }
    
    private func createBarView(for dataPoint: ChartDataPoint) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = dataPoint.label
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        let barBackground = UIView()
        barBackground.backgroundColor = .systemGray5
        barBackground.layer.cornerRadius = 4
        barBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(barBackground)
        
        let bar = UIView()
        bar.backgroundColor = .systemPurple
        bar.layer.cornerRadius = 4
        bar.translatesAutoresizingMaskIntoConstraints = false
        barBackground.addSubview(bar)
        
        let valueLabel = UILabel()
        valueLabel.text = String(format: "%.1f", dataPoint.value)
        valueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 80),
            
            barBackground.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            barBackground.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
            barBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            barBackground.heightAnchor.constraint(equalToConstant: 20),
            
            bar.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor),
            bar.topAnchor.constraint(equalTo: barBackground.topAnchor),
            bar.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor),
            bar.widthAnchor.constraint(equalTo: barBackground.widthAnchor, multiplier: CGFloat(dataPoint.value / 100)),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.widthAnchor.constraint(equalToConstant: 50),
            
            container.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return container
    }
}
