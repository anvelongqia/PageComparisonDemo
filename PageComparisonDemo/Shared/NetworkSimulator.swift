//
//  NetworkSimulator.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import Foundation

class NetworkSimulator {
    
    static func fetchData(page: Int = 0, completion: @escaping ([String]) -> Void) {
        // Simulate network delay
        let delay = Double.random(in: 0.3...0.8)
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let startIndex = page * 20
            let items = (startIndex..<startIndex+20).map { "Item \($0 + 1)" }
            
            DispatchQueue.main.async {
                completion(items)
            }
        }
    }
    
    static func fetchImages(count: Int, completion: @escaping ([UIImage]) -> Void) {
        let delay = Double.random(in: 0.5...1.2)
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            let images = (0..<count).map { _ in generatePlaceholderImage() }
            
            DispatchQueue.main.async {
                completion(images)
            }
        }
    }
    
    private static func generatePlaceholderImage() -> UIImage {
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let colors: [UIColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange, .systemPurple]
            let color = colors.randomElement() ?? .systemGray
            
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

import UIKit
