//
//  ClipboardMonitor.swift
//  ClipboardManager
//
//  Service to monitor clipboard changes
//

import AppKit
import Foundation

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private let storage: ClipboardStorageProtocol
    
    init(storage: ClipboardStorageProtocol) {
        self.storage = storage
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        // Poll the clipboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        // Check if clipboard content has changed
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Check for image first (higher priority)
            if let image = NSImage(pasteboard: pasteboard) {
                let item = ClipboardItem(image: image)
                storage.addItem(item)
            }
            // Fall back to string content
            else if let content = pasteboard.string(forType: .string), !content.isEmpty {
                let item = ClipboardItem(content: content)
                storage.addItem(item)
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

