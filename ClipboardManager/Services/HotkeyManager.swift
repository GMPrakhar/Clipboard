//
//  HotkeyManager.swift
//  ClipboardManager
//
//  Manages global keyboard shortcuts
//

import AppKit
import Carbon

class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    weak var appDelegate: AppDelegate?
    
    func registerGlobalHotkey() {
        // Register Cmd+` (Command + Grave/Tilde)
        let keyCode: UInt32 = 50 // ` key
        let modifiers: UInt32 = UInt32(cmdKey)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(("CBMG" as NSString).utf8String!.pointee)
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotkey()
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
        
        // Register the hotkey
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    private func handleHotkey() {
        DispatchQueue.main.async { [weak self] in
            self?.appDelegate?.togglePopover()
        }
    }
    
    func unregisterGlobalHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
        unregisterGlobalHotkey()
    }
}

