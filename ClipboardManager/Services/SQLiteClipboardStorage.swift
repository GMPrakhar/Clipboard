//
//  SQLiteClipboardStorage.swift
//  ClipboardManager
//
//  SQLite-based persistent storage for clipboard items
//

import Foundation
import Combine
import SQLite3

class SQLiteClipboardStorage: ClipboardStorageProtocol, ObservableObject {
    private var db: OpaquePointer?
    private let dbPath: String
    
    @Published private(set) var items: [ClipboardItem] = []
    
    var itemsPublisher: Published<[ClipboardItem]>.Publisher { $items }
    
    init() {
        // Get the Application Support directory
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportURL.appendingPathComponent("ClipboardManager", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        // Set database path
        dbPath = appDirectory.appendingPathComponent("clipboard.db").path
        
        // Initialize database
        openDatabase()
        createTableIfNeeded()
        cleanupExpiredItems()
        loadItems()
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsChange),
            name: .settingsDidChange,
            object: nil
        )
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            Logger.shared.error("Error opening database at \(dbPath)")
            return
        }
    }
    
    private func createTableIfNeeded() {
        // First, create the base table structure
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            timestamp REAL NOT NULL
        );
        """
        
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTableQuery, nil, nil, &error) != SQLITE_OK {
            let errorMessage = String(cString: error!)
            Logger.shared.error("Error creating table: \(errorMessage)")
            sqlite3_free(error)
        }
        
        // Add new columns if they don't exist (for migration from old schema)
        migrateSchema()
        
        // Create indexes after columns are guaranteed to exist
        createIndexes()
    }
    
    private func migrateSchema() {
        let migrations = [
            "ALTER TABLE clipboard_items ADD COLUMN is_pinned INTEGER DEFAULT 0",
            "ALTER TABLE clipboard_items ADD COLUMN is_sticky INTEGER DEFAULT 0",
            "ALTER TABLE clipboard_items ADD COLUMN keywords TEXT DEFAULT ''",
            "ALTER TABLE clipboard_items ADD COLUMN type TEXT DEFAULT 'text'",
            "ALTER TABLE clipboard_items ADD COLUMN image_data BLOB"
        ]
        
        for migration in migrations {
            var error: UnsafeMutablePointer<CChar>?
            sqlite3_exec(db, migration, nil, nil, &error)
            // Ignore errors as they occur if column already exists
            if error != nil {
                sqlite3_free(error)
            }
        }
    }
    
    private func createIndexes() {
        let indexes = [
            "CREATE INDEX IF NOT EXISTS idx_timestamp ON clipboard_items(timestamp DESC)",
            "CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_items(is_pinned DESC, timestamp DESC)"
        ]
        
        for indexQuery in indexes {
            var error: UnsafeMutablePointer<CChar>?
            sqlite3_exec(db, indexQuery, nil, nil, &error)
            if error != nil {
                let errorMessage = String(cString: error!)
                Logger.shared.error("Error creating index: \(errorMessage)")
                sqlite3_free(error)
            }
        }
    }
    
    private func loadItems() {
        items.removeAll()
        
        // Get settings
        let retentionDays = SettingsManager.shared.retentionDays
        let maxItems = SettingsManager.shared.maxItems
        let cutoffDate = Date().addingTimeInterval(-Double(retentionDays) * 24 * 60 * 60)
        
        let query = """
        SELECT id, type, content, image_data, timestamp, is_pinned, is_sticky, keywords FROM clipboard_items
        WHERE is_sticky = 1 OR timestamp >= ?
        ORDER BY is_pinned DESC, timestamp DESC
        """
        
        var statement: OpaquePointer?
        var loadedItems: [ClipboardItem] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, cutoffDate.timeIntervalSince1970)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let typeString = String(cString: sqlite3_column_text(statement, 1))
                let content = String(cString: sqlite3_column_text(statement, 2))
                
                // Get image data if present
                var imageData: Data? = nil
                if sqlite3_column_type(statement, 3) == SQLITE_BLOB {
                    let blobPointer = sqlite3_column_blob(statement, 3)
                    let blobSize = sqlite3_column_bytes(statement, 3)
                    if let pointer = blobPointer {
                        imageData = Data(bytes: pointer, count: Int(blobSize))
                    }
                }
                
                let timestamp = sqlite3_column_double(statement, 4)
                let isPinned = sqlite3_column_int(statement, 5) == 1
                let isSticky = sqlite3_column_int(statement, 6) == 1
                let keywordsString = String(cString: sqlite3_column_text(statement, 7))
                let keywords = keywordsString.isEmpty ? [] : keywordsString.components(separatedBy: ",")
                
                if let uuid = UUID(uuidString: idString),
                   let type = ClipboardItemType(rawValue: typeString) {
                    let item = ClipboardItem(
                        id: uuid,
                        type: type,
                        content: content,
                        imageData: imageData,
                        timestamp: Date(timeIntervalSince1970: timestamp),
                        isPinned: isPinned,
                        isSticky: isSticky,
                        keywords: keywords
                    )
                    loadedItems.append(item)
                }
            }
        }
        
        sqlite3_finalize(statement)
        
        // Sort: pinned first, then by timestamp
        let sortedItems = loadedItems.sorted { item1, item2 in
            if item1.isPinned != item2.isPinned {
                return item1.isPinned
            }
            return item1.timestamp > item2.timestamp
        }
        
        // Separate pinned/sticky items from regular items
        let pinnedOrSticky = sortedItems.filter { $0.isPinned || $0.isSticky }
        let regular = sortedItems.filter { !$0.isPinned && !$0.isSticky }
        
        // Take maxItems from regular items, but include all pinned/sticky
        items = pinnedOrSticky + Array(regular.prefix(maxItems))
    }
    
    private func cleanupExpiredItems() {
        let retentionDays = SettingsManager.shared.retentionDays
        let cutoffDate = Date().addingTimeInterval(-Double(retentionDays) * 24 * 60 * 60)
        
        // Don't delete sticky items
        let deleteQuery = "DELETE FROM clipboard_items WHERE is_sticky = 0 AND timestamp < ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, cutoffDate.timeIntervalSince1970)
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
    }
    
    @objc private func handleSettingsChange() {
        // Reload items when settings change
        DispatchQueue.main.async { [weak self] in
            self?.cleanupExpiredItems()
            self?.loadItems()
        }
    }
    
    func addItem(_ item: ClipboardItem) {
        // Check if item with same content/image already exists
        var checkQuery: String
        if item.type == .image {
            checkQuery = "SELECT id FROM clipboard_items WHERE type = 'image' AND image_data = ? LIMIT 1"
        } else {
            checkQuery = "SELECT id FROM clipboard_items WHERE type = 'text' AND content = ? LIMIT 1"
        }
        
        var checkStatement: OpaquePointer?
        var existingId: String?
        
        if sqlite3_prepare_v2(db, checkQuery, -1, &checkStatement, nil) == SQLITE_OK {
            if item.type == .image, let imageData = item.imageData {
                imageData.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(checkStatement, 1, bytes.baseAddress, Int32(imageData.count), nil)
                }
            } else {
                sqlite3_bind_text(checkStatement, 1, (item.content as NSString).utf8String, -1, nil)
            }
            
            if sqlite3_step(checkStatement) == SQLITE_ROW {
                existingId = String(cString: sqlite3_column_text(checkStatement, 0))
            }
        }
        sqlite3_finalize(checkStatement)
        
        if let existingId = existingId {
            // Update timestamp of existing item to move it to the front
            let updateQuery = "UPDATE clipboard_items SET timestamp = ? WHERE id = ?"
            var updateStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, updateQuery, -1, &updateStatement, nil) == SQLITE_OK {
                sqlite3_bind_double(updateStatement, 1, item.timestamp.timeIntervalSince1970)
                sqlite3_bind_text(updateStatement, 2, (existingId as NSString).utf8String, -1, nil)
                sqlite3_step(updateStatement)
            }
            sqlite3_finalize(updateStatement)
        } else {
            // Insert new item
            let insertQuery = """
            INSERT INTO clipboard_items (id, type, content, image_data, timestamp, is_pinned, is_sticky, keywords)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                let idString = item.id.uuidString
                let keywordsString = item.keywords.joined(separator: ",")
                sqlite3_bind_text(statement, 1, (idString as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (item.type.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (item.content as NSString).utf8String, -1, nil)
                
                // Bind image data as BLOB if present
                if let imageData = item.imageData {
                    imageData.withUnsafeBytes { bytes in
                        sqlite3_bind_blob(statement, 4, bytes.baseAddress, Int32(imageData.count), nil)
                    }
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                
                sqlite3_bind_double(statement, 5, item.timestamp.timeIntervalSince1970)
                sqlite3_bind_int(statement, 6, item.isPinned ? 1 : 0)
                sqlite3_bind_int(statement, 7, item.isSticky ? 1 : 0)
                sqlite3_bind_text(statement, 8, (keywordsString as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    Logger.shared.error("Error inserting item")
                }
            }
            
            sqlite3_finalize(statement)
        }
        
        // Remove old items beyond maxItems (excluding pinned/sticky)
        let maxItems = SettingsManager.shared.maxItems
        let deleteQuery = """
        DELETE FROM clipboard_items
        WHERE is_pinned = 0 AND is_sticky = 0 AND id NOT IN (
            SELECT id FROM clipboard_items
            WHERE is_pinned = 0 AND is_sticky = 0
            ORDER BY timestamp DESC
            LIMIT \(maxItems)
        )
        """
        
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteQuery, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_step(deleteStatement)
        }
        sqlite3_finalize(deleteStatement)
        
        // Reload items to update the UI
        loadItems()
    }
    
    func updateItem(id: UUID, isPinned: Bool? = nil, isSticky: Bool? = nil, keywords: [String]? = nil) {
        var updates: [String] = []
        
        if let isPinned = isPinned {
            updates.append("is_pinned = \(isPinned ? 1 : 0)")
        }
        if let isSticky = isSticky {
            updates.append("is_sticky = \(isSticky ? 1 : 0)")
        }
        if let keywords = keywords {
            let keywordsString = keywords.joined(separator: ",")
            updates.append("keywords = '\(keywordsString)'")
        }
        
        guard !updates.isEmpty else { return }
        
        let updateQuery = "UPDATE clipboard_items SET \(updates.joined(separator: ", ")) WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
        loadItems()
    }
    
    func clear() {
        let deleteQuery = "DELETE FROM clipboard_items"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        
        sqlite3_finalize(statement)
        items.removeAll()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if db != nil {
            sqlite3_close(db)
        }
    }
}

