# Clipboard Manager for Mac

A native macOS menu bar application that stores and manages your clipboard history with support for text, images, search, and organization.

## Screenshots

<img width="509" height="571" alt="image" src="https://github.com/user-attachments/assets/8d8ef0c0-3c02-4954-b5e8-29efba404f6e" />

<img width="585" height="568" alt="image" src="https://github.com/user-attachments/assets/675da567-3e2b-4fdd-96a5-66cfe29d66bd" />


## Features

- **Background Monitoring**: Automatically captures everything you copy (text and images)
- **Image Support**: Copy and paste images with thumbnail previews
- **Persistent Storage**: SQLite database stores items across restarts (configurable: 10-100 items, default 30)
- **Menu Bar Access**: Click icon or press **Cmd+`** to show clipboard history
- **Quick Paste**: Click or use arrow keys + Enter to paste any item
- **Search**: Instant filtering by content or keywords
- **Pin to Top**: Keep frequently used items at the top
- **Sticky Items**: Mark items to never expire (don't count towards limit)
- **Keywords/Tags**: Add custom tags for organization
- **Keyboard Navigation**: Full keyboard support with arrow keys, Enter, Escape, Cmd+F
- **Configurable Retention**: Set how long items are kept (1-365 days, default 30)

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later (for building)

## Building & Running

1. Open the project in Xcode:
   ```bash
   cd /Users/plondhe/Projects/Clipboard
   open ClipboardManager.xcodeproj
   ```

2. Build and run (Cmd+R)

3. The app will appear in your menu bar (clipboard icon)

## Keyboard Shortcuts

### Global
- **Cmd+`**: Open/close clipboard history from anywhere

### In-App Navigation
- **Up/Down Arrow**: Navigate items
- **Enter**: Paste selected item
- **Escape**: Close window
- **Cmd+F**: Focus search field

## Usage

1. **Copy normally** (Cmd+C) - items are automatically stored
2. **Open clipboard** - Click menu bar icon or press Cmd+`
3. **Paste** - Click item or use arrow keys + Enter
4. **Search** - Type in search bar or press Cmd+F
5. **Organize** - Hover over items to pin, mark sticky, or add keywords
6. **Configure** - Click gear icon for settings (retention period, max items)

## Data Storage

Database location: `~/Library/Application Support/ClipboardManager/clipboard.db`

Logs location: `~/Library/Application Support/ClipboardManager/clipboard_manager.log`

## Permissions

- **Apple Events**: Required to send paste commands to other applications

## Notes

- Runs as menu bar utility (no Dock icon)
- Duplicate items move to the front
- Pinned items always appear first
- Sticky items never expire and don't count towards limit
- Images stored as TIFF format in SQLite
- Clipboard polled every 0.5 seconds for changes
