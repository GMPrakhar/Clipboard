//
//  Settings.swift
//  ClipboardManager
//
//  Application settings model and manager
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    private let retentionDaysKey = "retentionDays"
    private let maxItemsKey = "maxItems"
    
    @Published var retentionDays: Int {
        didSet {
            defaults.set(retentionDays, forKey: retentionDaysKey)
            // Notify that settings changed
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }
    
    @Published var maxItems: Int {
        didSet {
            defaults.set(maxItems, forKey: maxItemsKey)
            // Notify that settings changed
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }
    
    private init() {
        // Default to 30 days if not set
        self.retentionDays = defaults.object(forKey: retentionDaysKey) as? Int ?? 30
        // Default to 30 items if not set
        self.maxItems = defaults.object(forKey: maxItemsKey) as? Int ?? 30
    }
    
    func reset() {
        retentionDays = 30
        maxItems = 30
    }
}

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

