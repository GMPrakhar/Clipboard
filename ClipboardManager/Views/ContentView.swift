//
//  ContentView.swift
//  ClipboardManager
//
//  Main UI view showing the list of clipboard items
//

import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var storage: SQLiteClipboardStorage
    weak var appDelegate: AppDelegate?
    
    @State private var hoveredItemId: UUID?
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var showingKeywordSheet = false
    @FocusState private var searchFieldFocused: Bool
    
    var filteredItems: [ClipboardItem] {
        storage.items.filter { $0.matches(searchText: searchText) }
    }
    
    var selectedIndex: Int? {
        guard let selectedItemId = selectedItemId else { return nil }
        return filteredItems.firstIndex { $0.id == selectedItemId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and settings
            VStack(spacing: 8) {
                HStack {
                    Text("Clipboard History")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        appDelegate?.openSettings()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    
                    if !storage.items.isEmpty {
                        Button(action: {
                            storage.clear()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Clear all items")
                    }
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Quit App")
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search content or keywords...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($searchFieldFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // List of clipboard items
            if storage.items.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No clipboard items yet")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Text("Copy something to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No matching items")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            ClipboardItemRow(
                                item: item,
                                isHovered: hoveredItemId == item.id,
                                isSelected: selectedItemId == item.id,
                                onPaste: { pasteItem(item) },
                                onPin: { togglePin(item) },
                                onSticky: { toggleSticky(item) },
                                onKeywords: {
                                    selectedItemId = item.id
                                    showingKeywordSheet = true
                                }
                            )
                            .onHover { hovering in
                                hoveredItemId = hovering ? item.id : nil
                            }
                            
                            if item.id != filteredItems.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 450, height: 550)
        .sheet(isPresented: $showingKeywordSheet) {
            if let itemId = selectedItemId,
               let item = storage.items.first(where: { $0.id == itemId }) {
                KeywordEditorView(item: item, storage: storage)
            }
        }
        .onAppear {
            // Select first item when view appears
            if !filteredItems.isEmpty {
                selectedItemId = filteredItems.first?.id
            }
        }
        .onChange(of: filteredItems) { _ in
            // Update selection when filtered items change
            if let selectedId = selectedItemId, !filteredItems.contains(where: { $0.id == selectedId }) {
                selectedItemId = filteredItems.first?.id
            } else if selectedItemId == nil && !filteredItems.isEmpty {
                selectedItemId = filteredItems.first?.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidOpen)) { _ in
            // Reset selection and focus when popover opens
            if !filteredItems.isEmpty {
                selectedItemId = filteredItems.first?.id
            }
            searchFieldFocused = false
        }
        .background(KeyboardHandler(
            onUpArrow: { moveSelectionUp() },
            onDownArrow: { moveSelectionDown() },
            onEnter: { pasteSelectedItem() },
            onEscape: { closePopover() },
            onCmdF: { searchFieldFocused = true }
        ))
    }
    
    private func pasteItem(_ item: ClipboardItem) {
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let image = item.image {
                pasteboard.writeObjects([image])
            }
        }
        
        // Close the popover first
        appDelegate?.popover?.performClose(nil)

        // Wait 200ms for the app to fully activate, then trigger paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Use AppleScript to simulate Cmd+V
            let script = """
            tell application "System Events"
                keystroke "v" using {command down}
            end tell
            """
            
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    Logger.shared.error("AppleScript error: \(error)")
                }
            }
        }

        Logger.shared.debug("Paste item: \(item.preview)")
        // Restore focus to the previous app
        appDelegate?.restorePreviousApp()
        
        
    }
    
    private func togglePin(_ item: ClipboardItem) {
        storage.updateItem(id: item.id, isPinned: !item.isPinned)
    }
    
    private func toggleSticky(_ item: ClipboardItem) {
        storage.updateItem(id: item.id, isSticky: !item.isSticky)
    }
    
    private func moveSelectionUp() {
        guard !filteredItems.isEmpty else { return }
        guard let currentIndex = selectedIndex else {
            selectedItemId = filteredItems.first?.id
            return
        }
        
        let newIndex = max(0, currentIndex - 1)
        selectedItemId = filteredItems[newIndex].id
    }
    
    private func moveSelectionDown() {
        guard !filteredItems.isEmpty else { return }
        guard let currentIndex = selectedIndex else {
            selectedItemId = filteredItems.first?.id
            return
        }
        
        let newIndex = min(filteredItems.count - 1, currentIndex + 1)
        selectedItemId = filteredItems[newIndex].id
    }
    
    private func pasteSelectedItem() {
        guard let selectedItemId = selectedItemId,
              let item = filteredItems.first(where: { $0.id == selectedItemId }) else { return }
        pasteItem(item)
    }
    
    private func closePopover() {
        appDelegate?.popover?.performClose(nil)
    }
}

// Keyboard event handler
struct KeyboardHandler: NSViewRepresentable {
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onEnter: () -> Void
    let onEscape: () -> Void
    let onCmdF: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardEventView()
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        view.onEnter = onEnter
        view.onEscape = onEscape
        view.onCmdF = onCmdF
        
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyboardEventView: NSView {
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onEnter: (() -> Void)?
    var onEscape: (() -> Void)?
    var onCmdF: (() -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126: // Up arrow
            onUpArrow?()
        case 125: // Down arrow
            onDownArrow?()
        case 36: // Enter/Return
            onEnter?()
        case 53: // Escape
            onEscape?()
        case 3 where event.modifierFlags.contains(.command): // Cmd+F
            onCmdF?()
        default:
            super.keyDown(with: event)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let isSelected: Bool
    let onPaste: () -> Void
    let onPin: () -> Void
    let onSticky: () -> Void
    let onKeywords: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon/Thumbnail column
            VStack(spacing: 4) {
                if item.type == .image, let image = item.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Image(systemName: item.isPinned ? "pin.fill" : "doc.text")
                        .foregroundColor(item.isPinned ? .accentColor : .secondary)
                        .font(.system(size: 16))
                        .frame(width: 40, height: 40)
                }
                
                if item.isSticky {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                }
            }
            
            // Content column
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(3)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(item.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if !item.keywords.isEmpty {
                        ForEach(item.keywords.prefix(3), id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                        }
                        
                        if item.keywords.count > 3 {
                            Text("+\(item.keywords.count - 3)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action buttons (show on hover)
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onKeywords) {
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help("Edit keywords")
                    
                    Button(action: onPin) {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin to top")
                    
                    Button(action: onSticky) {
                        Image(systemName: item.isSticky ? "clock.badge.xmark" : "clock.badge.checkmark")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .help(item.isSticky ? "Remove sticky" : "Make sticky (never expires)")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) :
            isHovered ? Color.accentColor.opacity(0.1) : Color.clear
        )
        .overlay(
            isSelected ? Rectangle()
                .stroke(Color.accentColor, lineWidth: 2)
                .cornerRadius(4) : nil
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onPaste()
        }
        .cursor(.pointingHand)
    }
}

struct KeywordEditorView: View {
    let item: ClipboardItem
    let storage: SQLiteClipboardStorage
    
    @Environment(\.dismiss) private var dismiss
    @State private var keywords: [String]
    @State private var newKeyword = ""
    
    init(item: ClipboardItem, storage: SQLiteClipboardStorage) {
        self.item = item
        self.storage = storage
        _keywords = State(initialValue: item.keywords)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.accentColor)
                Text("Edit Keywords")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Content:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.preview)
                    .font(.system(size: 12))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
            }
            .padding()
            
            Divider()
            
            // Keywords
            VStack(alignment: .leading, spacing: 12) {
                Text("Keywords:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Add new keyword
                HStack {
                    TextField("Add keyword...", text: $newKeyword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addKeyword()
                        }
                    
                    Button(action: addKeyword) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                
                // Existing keywords
                if keywords.isEmpty {
                    Text("No keywords yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(keywords, id: \.self) { keyword in
                            HStack(spacing: 4) {
                                Text(keyword)
                                    .font(.system(size: 12))
                                
                                Button(action: {
                                    removeKeyword(keyword)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Footer
            Divider()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveKeywords()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
    }
    
    private func addKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !keywords.contains(trimmed) else { return }
        keywords.append(trimmed)
        newKeyword = ""
    }
    
    private func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
    }
    
    private func saveKeywords() {
        storage.updateItem(id: item.id, keywords: keywords)
        dismiss()
    }
}

// Flow layout for keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// Custom cursor modifier
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    ContentView(storage: SQLiteClipboardStorage(), appDelegate: nil)
}
