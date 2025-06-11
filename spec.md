# Micro-Break Manager – Developer Specification

## Overview
A structured micro-break manager that rotates through multiple user-defined micro-break lists. The system selects the next item from the next list in a round-robin fashion to support balanced, consistent progress. Users manually trigger micro-breaks, and a timestamped log is maintained for each session.

---

## Feature Summary
- User-defined lists of micro-break items.
- Plain-text items, entered and edited via UI.
- Round-robin cycling through lists and items.
- Manual start and stop of micro-breaks.
- Timestamped logs of completed micro-breaks.
- Local tab-delimited text files for persistent storage.
- Mac-style native menubar and resizable main window.
- Modal overlays for editing and logs.

---

## Platform & Technology
- **Platform**: macOS desktop
- **Framework**: Flutter (macOS target)
- **Data Storage**: Local tab-delimited plain-text files in subdirectories
- **Offline**: 100%, no internet access required

---

## UI Structure

### Main Window
- Displays: current micro-break or a message like "Press Space to start next micro-break"
- User Actions:
  - `Space`: Start next micro-break (round-robin order)
  - `Space` again: End micro-break and log it
  - `Escape`: Cancel current micro-break selection (no log entry)

### Modal: Setup Micro-Breaks
- Sidebar of all list names (alphabetical)
  - Add, rename, delete lists (immediate action)
- Main panel: editable plain-text box (Return-separated items)
  - Save/Cancel buttons for editing

### Modal: View Logs
- Sidebar: list of available log files by date (last 30 days)
- Main panel: displays contents of selected log
- No search/filter or delete functionality

---

## Data Structure

### Directory Layout
```
/data/
  /lists/
    stretching.txt
    tai_chi.txt
    chinese.txt
  /logs/
    2025-06-12.txt
    2025-06-11.txt
```

### List Files (tab-delimited)
Each file contains one item per line:
```
Cat–Camel stretch
Standing Back Extension
Seated Pelvic Tilt
```

### Log Files (tab-delimited)
Each log file represents one day:
```
2025-06-12	10:35:12	10:40:05	stretching	Cat–Camel stretch
2025-06-12	14:03:20	14:05:00	tai_chi	Cloud Hands
```
Fields: `date`, `start_time`, `end_time`, `list_name`, `item_text`

---

## Functional Requirements
- Unlimited number of lists
- Unlimited items per list
- Plain text only (no formatting)
- Lists cycle in round-robin order
- Each list maintains its own position index
- Indices saved only after successful micro-break completion
- Logs stored as one file per day, rotated automatically
- On app launch or exit, delete logs older than 30 days
- Opening with no lists: main window displays instruction to set them up

---

## Error Handling
- On startup, validate file presence and format
  - Broken list files: ignore individual lines if malformed
  - Broken log files: skip file, display warning in log viewer
- Always run, even if data cannot be loaded
- Prevent duplicate list names in UI

---

## Keyboard Shortcuts
- `Space`: Start/finish micro-break
- `Escape`: Cancel micro-break selection
- No shortcuts for editing or logs

---

## Menu Bar Items (macOS Native)
- About
- Quit
- Setup Micro-Breaks
- View Logs

---

## State Management
- App starts with no micro-break selected
- Does not restore in-progress break across launches
- All windows/modal overlays open at default size
- Resizable main window

---

## Testing Plan

### Unit Tests
- List cycling logic
- Item cycling logic
- Parsing/saving of tab-delimited files
- Timestamp calculations

### UI Tests
- Keyboard input handling
- Modal overlays opening and closing correctly
- Editing workflow (save/cancel)
- Log rendering and switching

### Manual Testing
- No list scenario
- Micro-break selection and cancellation
- Log file rollover and deletion after 30 days
- File corruption scenarios

---

## Future Considerations (Out of Scope)
- Audio/visual notifications
- Dark mode
- Network sync or backups
- User profiles
- Data export
- Search or filter features

---

## End of Spec
