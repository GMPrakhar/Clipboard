//
//  ClipboardStorage.swift
//  ClipboardManager
//
//  Storage interface and in-memory implementation for clipboard items
//

import Foundation
import Combine

/// Protocol defining the clipboard storage interface
/// This allows for easy extension to database storage in the future
protocol ClipboardStorageProtocol {
    var items: [ClipboardItem] { get }
    var itemsPublisher: Published<[ClipboardItem]>.Publisher { get }
    
    func addItem(_ item: ClipboardItem)
    func clear()
}

/// In-memory implementation of clipboard storage
/// Stores up to 10 most recent clipboard items
class InMemoryClipboardStorage: ClipboardStorageProtocol, ObservableObject {
    private let maxItems = 10
    
    @Published private(set) var items: [ClipboardItem] = []
    
    var itemsPublisher: Published<[ClipboardItem]>.Publisher { $items }
    
    func addItem(_ item: ClipboardItem) {
        // Check if the item already exists to avoid duplicates
        if let existingIndex = items.firstIndex(where: { $0.content == item.content }) {
            // Move existing item to the front
            let existingItem = items.remove(at: existingIndex)
            items.insert(existingItem, at: 0)
        } else {
            // Add new item to the front
            items.insert(item, at: 0)
            
            // Remove oldest items if we exceed the maximum
            if items.count > maxItems {
                items.removeLast()
            }
        }
    }
    
    func clear() {
        items.removeAll()
    }
}

