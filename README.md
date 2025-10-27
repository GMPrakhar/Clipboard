# Clipboard Manager for Mac

A native macOS menu bar application that stores and manages your clipboard history.

## Features

- **Background Monitoring**: Automatically captures everything you copy (text and images)
- **Image Support**: Copy and paste images with thumbnail previews
- **Persistent Storage**: Stores clipboard items in SQLite database (default: 30 items)
- **Configurable Limits**: Set your own maximum items (10-100) and retention period (1-365 days)
- **Menu Bar Access**: Lives in your menu bar - click to show clipboard history
- **Quick Paste**: Click any item to paste it immediately
- **Session Persistence**: Your clipboard history persists across app restarts
- **Search Functionality**: Search through clipboard content and keywords instantly
- **Pin to Top**: Pin frequently used items to keep them at the top
- **Sticky Items**: Mark items as sticky so they never expire (don't count towards limit)
- **Keyword Tags**: Add custom keywords to items for easy organization and search
- **Extensible Storage**: Built with a storage interface that can be easily swapped (currently using SQLite)

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later (for building)

## Building the Application

1. Open the project in Xcode:
   ```bash
   cd /Users/plondhe/Projects/Clipboard
   open ClipboardManager.xcodeproj
   ```

2. Select the target "ClipboardManager" in Xcode

3. Build and run the application (Cmd+R)

## Keyboard Shortcuts

### Global Shortcut
- **Cmd+`** (Command + Tilde/Grave): Open/close clipboard history from anywhere

### Navigation (when clipboard window is open)
- **Up Arrow**: Move selection up
- **Down Arrow**: Move selection down
- **Enter/Return**: Paste selected item
- **Escape**: Close clipboard window
- **Cmd+F**: Focus search field

## Usage

1. **Starting the App**: 
   - Run the application from Xcode or from the built app bundle
   - The app will appear in your menu bar (look for the clipboard icon)
   - The app runs in the background and doesn't appear in the Dock
   - Press **Cmd+`** from anywhere to open the clipboard history

2. **Copying Items**:
   - Copy text or images as you normally would (Cmd+C)
   - The app automatically stores each copied item
   - Images are captured with full quality
   - Screenshots and image files are both supported

3. **Viewing History**:
   - Click the clipboard icon in the menu bar OR press **Cmd+`** 
   - You'll see your clipboard history (default: 30 items, configurable)
   - Text items show content preview
   - Image items show 40×40 thumbnails
   - Each item shows how long ago it was copied
   - Your history persists across app restarts
   - The first item is automatically selected

4. **Pasting**:
   - Click any item in the list OR use arrow keys + Enter
   - Press **Up/Down arrows** to navigate through items
   - Press **Enter** to paste the selected item
   - The item will be copied to your clipboard and pasted automatically
   - The window closes after pasting

5. **Search**:
   - Use the search bar at the top to filter items
   - Press **Cmd+F** to focus the search field
   - Search works on both content and keywords
   - Results update instantly as you type
   - Use arrow keys to navigate filtered results

6. **Pin to Top**:
   - Hover over an item and click the pin icon
   - Pinned items stay at the top of the list
   - Click again to unpin

7. **Sticky Items** (Never Expire):
   - Hover over an item and click the clock icon
   - Sticky items are marked with a green checkmark badge
   - These items are never deleted, regardless of retention period
   - Click again to remove sticky status

8. **Keywords/Tags**:
   - Hover over an item and click the tag icon
   - Add custom keywords to organize your clipboard items
   - Keywords appear as colored badges below the item
   - Use keywords in search to quickly find items

9. **Settings**:
   - Click the gear icon in the top-right corner of the clipboard window
   - **Retention Period**: Configure how long clipboard items are kept (1-365 days)
   - **Maximum Items**: Set how many items to keep in history (10-100)
   - Note: Sticky and pinned items don't count towards the maximum limit

10. **Clearing History**:
    - Click the trash icon in the top-right corner to clear all items

## Architecture

The application is structured with clean separation of concerns:

### Models
- **ClipboardItem**: Represents a single clipboard entry (text or image) with metadata
- **ClipboardItemType**: Enum for text vs image types
- **SettingsManager**: Manages user preferences and application settings

### Services
- **ClipboardStorageProtocol**: Interface defining storage operations
- **SQLiteClipboardStorage**: SQLite-based persistent storage implementation (max 10 items)
- **InMemoryClipboardStorage**: Alternative in-memory storage (available but not currently used)
- **ClipboardMonitor**: Service that monitors the system clipboard for changes

### Views
- **ContentView**: Main UI showing the list of clipboard items
- **ClipboardItemRow**: Individual row component for each clipboard item
- **SettingsView**: Settings interface for configuring retention period and preferences

### App Components
- **ClipboardApp**: Main app entry point
- **AppDelegate**: Manages the menu bar item and p opover window



## Data Storage

The application uses SQLite for persistent storage. The database file is stored at:
```
~/Library/Application Support/ClipboardManager/clipboard.db
```

Your clipboard history will persist across app restarts and system reboots.

### Retention Period

By default, clipboard items are kept for **30 days**. You can configure this in Settings:
- Minimum: 1 day
- Maximum: 365 days (1 year)
- Quick presets: 7, 30, 90, or 365 days

Items older than the retention period are automatically removed from the database when:
- The app starts
- Settings are changed
- New items are added

**Note**: Items marked as "sticky" are never deleted, regardless of the retention period.

## Settings

Access settings by clicking the gear icon in the top-right corner of the clipboard window.

### Available Settings

**Retention Period**
- Control how long clipboard items are stored
- Range: 1 to 365 days
- Default: 30 days
- Quick preset buttons for common durations (7d, 30d, 90d, 365d)
- Sticky items are never deleted regardless of this setting

**Maximum Items**
- Control how many items to keep in history
- Range: 10 to 100 items
- Default: 30 items
- Quick preset buttons: 10, 30, 50, 100
- **Pinned and sticky items don't count towards this limit**

Settings are saved automatically and persisted in UserDefaults.

## Features in Detail

### Pin to Top
Pin frequently used items to keep them at the top of your clipboard history. Pinned items:
- Always appear first in the list
- Show a filled pin icon
- Can still be searched and filtered
- Remain pinned across sessions

### Sticky Items
Make items "sticky" to keep them permanently in your clipboard:
- Never expire, regardless of retention period
- Marked with a green clock checkmark badge
- Perfect for frequently used snippets, passwords, or templates
- Can be unpinned or deleted manually

### Keywords/Tags
Organize your clipboard with custom keywords:
- Add multiple keywords to any item
- Keywords appear as colored badges
- Searchable along with content
- Great for categorizing similar items (e.g., "code", "email", "important")
- Persisted in the database

### Search
Powerful search functionality:
- Real-time filtering as you type
- Searches both content and keywords
- Case-insensitive matching
- Clear button to reset search instantly

## Future Extensions

The application is designed for easy extension:
- Core Data integration
- iCloud sync for cross-device clipboard history
- Configurable item limit (currently fixed at 10)
- Support for files and URLs
- Rich text formatting support
- Image compression options
- Export/import clipboard history
- Clipboard history analytics
- OCR for images (text extraction)

## Logging

The application includes comprehensive logging:
- All logs are written to both console and a log file
- Log file location: `~/Library/Application Support/ClipboardManager/clipboard_manager.log`
- Logs include timestamps and log levels (INFO, WARNING, ERROR, DEBUG)
- Automatic log rotation when file exceeds 10MB (old logs backed up to `.old.log`)
- Useful for debugging issues and monitoring application behavior

To view logs in real-time:
```bash
tail -f ~/Library/Application\ Support/ClipboardManager/clipboard_manager.log
```

## Permissions

The app requires:
- **Apple Events**: To send paste commands to other applications
- No additional permissions needed for reading the clipboard

## Notes

- The app runs as a menu bar utility (LSUIElement = true) - no Dock icon
- Duplicate items are moved to the front rather than creating duplicates
- Supports both text and image clipboard content
- Images are stored as BLOB data in SQLite (TIFF format)
- Image thumbnails are generated on-the-fly from stored data
- The clipboard is polled every 0.5 seconds for changes
- Clipboard history persists in SQLite database between sessions
- The database maintains up to your configured maximum items (default 30)
- Pinned items appear first, then items sorted by timestamp
- Pinned and sticky items don't count towards the maximum items limit
- Sticky items never expire and are always kept
- Keywords are stored as comma-separated values in the database
- Search is performed in real-time on both content and keywords
- Images can be searched by dimensions (e.g., "1920×1080")

