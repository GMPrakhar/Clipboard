//
//  ClipboardItem.swift
//  ClipboardManager
//
//  Model representing a clipboard item
//

import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    let content: String // For text items, stores text. For images, stores a description
    let imageData: Data? // For image items, stores PNG data
    let timestamp: Date
    var isPinned: Bool
    var isSticky: Bool
    var keywords: [String]
    
    // Convenience initializer for new text items
    init(content: String) {
        self.id = UUID()
        self.type = .text
        self.content = content
        self.imageData = nil
        self.timestamp = Date()
        self.isPinned = false
        self.isSticky = false
        self.keywords = []
    }
    
    // Convenience initializer for new image items
    init(image: NSImage) {
        self.id = UUID()
        self.type = .image
        self.imageData = image.tiffRepresentation
        self.content = "Image \(Int(image.size.width))×\(Int(image.size.height))"
        self.timestamp = Date()
        self.isPinned = false
        self.isSticky = false
        self.keywords = []
    }
    
    // Full initializer for loading from storage
    init(id: UUID, type: ClipboardItemType, content: String, imageData: Data?, timestamp: Date, isPinned: Bool = false, isSticky: Bool = false, keywords: [String] = []) {
        self.id = id
        self.type = type
        self.content = content
        self.imageData = imageData
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.isSticky = isSticky
        self.keywords = keywords
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        if lhs.type != rhs.type {
            return false
        }
        
        switch lhs.type {
        case .text:
            return lhs.content == rhs.content
        case .image:
            return lhs.imageData == rhs.imageData
        }
    }
    
    var preview: String {
        switch type {
        case .text:
            let maxLength = 100
            if content.count > maxLength {
                return String(content.prefix(maxLength)) + "..."
            }
            return content
        case .image:
            return content // Returns "Image WxH"
        }
    }
    
    var image: NSImage? {
        guard type == .image, let data = imageData else { return nil }
        return NSImage(data: data)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    func matches(searchText: String) -> Bool {
        if searchText.isEmpty {
            return true
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        // Search in content (works for both text and image descriptions)
        if content.lowercased().contains(lowercasedSearch) {
            return true
        }
        
        // Search in keywords
        return keywords.contains { keyword in
            keyword.lowercased().contains(lowercasedSearch)
        }
    }
}

