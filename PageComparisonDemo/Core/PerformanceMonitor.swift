//
//  PerformanceMonitor.swift
//  PageComparisonDemo
//
//  Created by OpenCode
//

import UIKit
import QuartzCore

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private(set) var currentFPS: Int = 0
    
    private var monitoringStartTime: Date?
    private var pageSwitchStartTime: Date?
    
    // MARK: - Public Interface
    
    var currentMemoryMB: Float {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        return Float(info.resident_size) / 1024 / 1024
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        monitoringStartTime = Date()
        startFPSMonitoring()
    }
    
    func stopMonitoring() {
        stopFPSMonitoring()
        monitoringStartTime = nil
    }
    
    func startPageSwitchTiming() {
        pageSwitchStartTime = Date()
    }
    
    func endPageSwitchTiming() -> TimeInterval {
        guard let startTime = pageSwitchStartTime else { return 0 }
        let duration = Date().timeIntervalSince(startTime)
        pageSwitchStartTime = nil
        return duration
    }
    
    // MARK: - FPS Monitoring
    
    private func startFPSMonitoring() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = CACurrentMediaTime()
    }
    
    private func stopFPSMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        frameCount = 0
        currentFPS = 0
    }
    
    @objc private func displayLinkTick(_ link: CADisplayLink) {
        let currentTimestamp = link.timestamp
        frameCount += 1
        
        let elapsed = currentTimestamp - lastTimestamp
        if elapsed >= 1.0 {
            currentFPS = frameCount
            frameCount = 0
            lastTimestamp = currentTimestamp
        }
    }
    
    // MARK: - Report Generation
    
    func generateReport() -> PerformanceReport {
        PerformanceReport(
            averageFPS: currentFPS,
            currentMemoryMB: currentMemoryMB
        )
    }
}

// MARK: - Performance Report

struct PerformanceReport {
    let averageFPS: Int
    let currentMemoryMB: Float
    
    var description: String {
        String(format: "FPS: %d | Memory: %.1fMB", averageFPS, currentMemoryMB)
    }
}
