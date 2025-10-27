//
//  AppDelegate.swift
//  ClipboardManager
//
//  Manages the menu bar app and window
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var storage: SQLiteClipboardStorage?
    var monitor: ClipboardMonitor?
    var settingsWindow: NSWindow?
    var hotkeyManager: HotkeyManager?
    var previousActiveApp: NSRunningApplication?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Rotate log file if needed
        Logger.shared.rotateLogIfNeeded()
        Logger.shared.info("Application started")
        
        // Initialize storage and monitor with SQLite persistence
        storage = SQLiteClipboardStorage()
        monitor = ClipboardMonitor(storage: storage!)
        monitor?.startMonitoring()
        
        // Register global hotkey (Cmd+`)
        hotkeyManager = HotkeyManager()
        hotkeyManager?.appDelegate = self
        hotkeyManager?.registerGlobalHotkey()
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 450, height: 550)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ContentView(storage: storage!, appDelegate: self)
        )
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                // Store the currently active application before opening popover
                previousActiveApp = NSWorkspace.shared.frontmostApplication
                
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate the app to receive keyboard events
                NSApp.activate(ignoringOtherApps: true)
                // Notify the content view to focus
                NotificationCenter.default.post(name: .popoverDidOpen, object: nil)
            }
        }
    }
    
    func restorePreviousApp() {
        // Restore focus to the previously active application
        if let prevApp = previousActiveApp, prevApp.isTerminated == false {
            prevApp.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Settings"
            window.styleMask = [.titled, .closable]
            window.center()
            window.setFrameAutosaveName("SettingsWindow")
            window.isReleasedWhenClosed = false
            window.level = .floating
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("Application terminating")
        monitor?.stopMonitoring()
        hotkeyManager?.unregisterGlobalHotkey()
    }
}

extension Notification.Name {
    static let popoverDidOpen = Notification.Name("popoverDidOpen")
}

