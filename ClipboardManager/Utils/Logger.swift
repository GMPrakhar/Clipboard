//
//  Logger.swift
//  ClipboardManager
//
//  Logging utility that writes to both console and log file
//

import Foundation

class Logger {
    static let shared = Logger()
    
    private let logFileURL: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.clipboardmanager.logger", qos: .utility)
    
    private init() {
        // Set up log file location
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("ClipboardManager", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        logFileURL = appDir.appendingPathComponent("clipboard_manager.log")
        
        // Set up date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Log startup
        log("=== ClipboardManager Started ===", level: .info)
    }
    
    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case debug = "DEBUG"
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)"
        
        // Print to console
        print(logMessage)
        
        // Write to file asynchronously
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = (logMessage + "\n").data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: self.logFileURL)
                }
            }
        }
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    // Rotate log file if it gets too large (> 10MB)
    func rotateLogIfNeeded() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: self.logFileURL.path),
               let fileSize = attributes[.size] as? Int64,
               fileSize > 10_000_000 {
                
                let backupURL = self.logFileURL.deletingPathExtension().appendingPathExtension("old.log")
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.moveItem(at: self.logFileURL, to: backupURL)
                
                self.log("Log file rotated", level: .info)
            }
        }
    }
    
    func getLogFileURL() -> URL {
        return logFileURL
    }
}

