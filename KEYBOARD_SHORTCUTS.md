# Keyboard Shortcuts Guide

## Global Hotkey

### Open/Close Clipboard Manager
- **Cmd+`** (Command + Grave/Tilde key, left of 1)
  - Works from anywhere in macOS
  - Opens clipboard history window
  - If already open, closes the window
  - Automatically focuses the window for keyboard navigation

## Navigation Shortcuts (when clipboard window is open)

### List Navigation
- **↑ (Up Arrow)**: Move selection up one item
- **↓ (Down Arrow)**: Move selection down one item
- **Enter/Return**: Paste the currently selected item and close window

### Window Control
- **Escape**: Close the clipboard window
- **Cmd+F**: Focus the search field to start typing

### Visual Feedback
- Selected item highlighted with blue background and border
- Arrow keys cycle through filtered results if search is active
- First item auto-selected when window opens

## Implementation Details

### HotkeyManager Service
- Uses Carbon API for global hotkey registration
- Registered on app launch
- Unregistered on app termination
- Hotkey works even when app is not frontmost

### KeyboardHandler
- Custom NSView that captures keyboard events
- Integrated into SwiftUI view hierarchy
- Handles arrow keys, Enter, Escape, and Cmd+F
- Automatically becomes first responder when window opens

### Focus Management
- Search field can be focused with Cmd+F
- When search is focused, typing goes to search
- When search is not focused, arrow keys navigate list
- Enter always pastes selected item regardless of focus

## User Workflows

### Quick Paste Workflow
1. Press Cmd+` to open
2. Press ↓ to navigate (if needed)
3. Press Enter to paste
4. Window auto-closes

### Search & Paste Workflow
1. Press Cmd+` to open
2. Press Cmd+F to focus search
3. Type to filter
4. Press ↓ to select filtered item
5. Press Enter to paste

### Mouse + Keyboard Hybrid
- Can use mouse to hover/select
- Can use keyboard to navigate
- Can click OR press Enter to paste
- Flexible for user preference

## Technical Notes

### Key Codes Used
- 50: ` (grave/tilde) key
- 126: Up arrow
- 125: Down arrow
- 36: Return/Enter
- 53: Escape
- 3: F key (with Cmd modifier)

### Event Handling Order
1. Global hotkey (Carbon) → AppDelegate
2. Local keys (NSView) → KeyboardHandler
3. SwiftUI updates selection state
4. Visual feedback rendered

### State Management
- `selectedItemId`: Tracks current selection
- `searchFieldFocused`: Controls search focus
- `filteredItems`: Computed from storage + search
- Auto-updated when items change or search updates

## Accessibility
- All keyboard shortcuts follow macOS conventions
- Visual selection indicator for keyboard navigation
- Works with VoiceOver (selected item announced)
- No mouse required for full functionality

