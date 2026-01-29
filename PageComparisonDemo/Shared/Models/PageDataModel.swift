//
//  PageDataModel.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import Foundation

enum PageType: Int, CaseIterable {
    case overview
    case details
    case analytics
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .details: return "Details"
        case .analytics: return "Analytics"
        }
    }
}

struct ChartDataPoint {
    let label: String
    let value: Double
    
    static func generateRandom(count: Int) -> [ChartDataPoint] {
        (0..<count).map { index in
            ChartDataPoint(
                label: "Point \(index + 1)",
                value: Double.random(in: 0...100)
            )
        }
    }
}
