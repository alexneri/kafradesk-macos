# Cross-Platform Migration Guide

## Overview

This guide provides comprehensive instructions for recreating Kafra Desktop Assistant on non-Windows platforms (Linux, macOS). It maps Windows-specific technologies to cross-platform alternatives and outlines architectural adaptations needed for each platform.

## Executive Summary

**Complexity:** 🔴 **HIGH** - Significant re-architecture required

**Effort Estimate:**
- **Linux:** 400-600 hours
- **macOS:** 350-500 hours
- **Shared Components:** 200-300 hours

**Key Challenges:**
1. No direct equivalent to Windows regions (non-rectangular windows)
2. Form subclassing has different paradigms
3. Registry replacement architecture
4. Platform-specific UI guidelines

---

## Technology Mapping

### Language and Runtime

**Windows (Original):**
- Visual Basic 6.0
- VB6 Runtime (MSVBVM60.DLL)
- COM/ActiveX

**Recommended Alternatives:**

| Platform | Primary Choice | Alternative |
|----------|---------------|-------------|
| **Linux** | Python 3.9+ with PyQt5/6 | C++ with Qt |
| **macOS** | Swift 5.0+ with Cocoa | Python with PyQt |
| **Cross-Platform** | Electron + TypeScript | Flutter |

**Rationale:**

**Python + PyQt:**
- ✅ Rapid development
- ✅ Excellent bindings to native APIs
- ✅ Good performance for desktop apps
- ✅ Large ecosystem
- ❌ Distribution complexity

**Swift + Cocoa (macOS):**
- ✅ Native performance
- ✅ Perfect macOS integration
- ✅ Modern language
- ❌ macOS-only

**Electron:**
- ✅ True cross-platform
- ✅ Web technologies (familiar to many developers)
- ❌ High memory usage
- ❌ Limited shaped window support

---

### UI Framework Mapping

#### Windows GDI → Modern Graphics

| Windows Component | Linux (Qt) | macOS | Electron |
|-------------------|------------|-------|----------|
| **Forms** | QWidget | NSWindow | BrowserWindow |
| **GDI Drawing** | QPainter | CoreGraphics | Canvas API |
| **BitBlt** | QPainter::drawPixmap | CGContextDrawImage | Canvas drawImage |
| **Regions** | QRegion | NSBezierPath | CSS clip-path |
| **Transparency** | setWindowOpacity | alphaValue | opacity property |

---

### Form Shaping

#### Windows Approach

```vb
' Load bitmap
' Scan pixels for transparency color
' Build region from non-transparent areas
SetWindowRgn hWnd, hRgn, True
```

#### Linux (Qt) Approach

```python
from PyQt5.QtWidgets import QWidget
from PyQt5.QtGui import QRegion, QBitmap, QPixmap
from PyQt5.QtCore import Qt

class ShapedWindow(QWidget):
    def __init__(self):
        super().__init__()
        
        # Load character image
        pixmap = QPixmap("kafra.png")
        
        # Create mask from alpha channel
        mask = pixmap.mask()
        
        # Apply as window mask
        self.setMask(mask)
        
        # Make frameless
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        
        # Set transparency
        self.setAttribute(Qt.WA_TranslucentBackground)
```

#### macOS (Swift) Approach

```swift
import Cocoa

class ShapedWindow: NSWindow {
    override init(contentRect: NSRect, 
                  styleMask style: NSWindow.StyleMask, 
                  backing backingStoreType: NSWindow.BackingStoreType, 
                  defer flag: Bool) {
        
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: backingStoreType,
                   defer: flag)
        
        // Transparent background
        self.isOpaque = false
        self.backgroundColor = .clear
        
        // Always on top
        self.level = .floating
        
        // Create shaped content view
        let imageView = NSImageView(image: NSImage(named: "kafra")!)
        imageView.frame = contentRect
        self.contentView = imageView
        
        // Mask from image
        if let image = imageView.image {
            let mask = createMask(from: image)
            imageView.layer?.mask = mask
        }
    }
    
    func createMask(from image: NSImage) -> CALayer {
        // Convert image to mask based on alpha channel
        // Implementation details...
    }
}
```

#### Electron Approach

```typescript
import { BrowserWindow } from 'electron';

function createShapedWindow() {
  const win = new BrowserWindow({
    width: 200,
    height: 300,
    transparent: true,
    frame: false,
    alwaysOnTop: true,
    webPreferences: {
      nodeIntegration: true
    }
  });
  
  win.loadFile('kafra.html');
  
  // Use CSS for shaping
  // In kafra.html:
  // <div style="
  //   -webkit-mask-image: url(kafra-mask.png);
  //   mask-image: url(kafra-mask.png);
  // ">
  //   <img src="kafra.png">
  // </div>
}
```

---

### System Tray Integration

#### Windows

```vb
Shell_NotifyIcon NIM_ADD, TrayData
```

#### Linux (Qt)

```python
from PyQt5.QtWidgets import QSystemTrayIcon, QMenu
from PyQt5.QtGui import QIcon

class KafraTray:
    def __init__(self):
        self.tray_icon = QSystemTrayIcon()
        self.tray_icon.setIcon(QIcon("kafra_icon.png"))
        
        # Create context menu
        menu = QMenu()
        menu.addAction("Show", self.show_window)
        menu.addAction("Hide", self.hide_window)
        menu.addSeparator()
        menu.addAction("Exit", self.quit)
        
        self.tray_icon.setContextMenu(menu)
        self.tray_icon.show()
        
        # Handle clicks
        self.tray_icon.activated.connect(self.on_tray_activated)
    
    def on_tray_activated(self, reason):
        if reason == QSystemTrayIcon.DoubleClick:
            self.toggle_visibility()
```

#### macOS (Swift)

```swift
class KafraTray {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    func setupTray() {
        if let button = statusItem.button {
            button.image = NSImage(named: "kafra_icon")
            button.action = #selector(toggleWindow)
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show", 
                                action: #selector(showWindow), 
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Hide", 
                                action: #selector(hideWindow), 
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", 
                                action: #selector(quit), 
                                keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
}
```

---

### Persistent Storage

#### Windows Registry → Alternatives

| Data Type | Linux Solution | macOS Solution | Cross-Platform |
|-----------|----------------|----------------|----------------|
| **Settings** | JSON/INI file | UserDefaults/plist | SQLite |
| **Memos** | SQLite database | Core Data | SQLite |
| **Position** | XDG config dir | UserDefaults | JSON |

#### Linux Implementation

```python
import json
import os
from pathlib import Path

class Settings:
    def __init__(self):
        # XDG Base Directory specification
        config_home = os.getenv('XDG_CONFIG_HOME', 
                                os.path.expanduser('~/.config'))
        self.config_dir = Path(config_home) / 'kafra-desktop'
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.config_file = self.config_dir / 'settings.json'
        self.load()
    
    def load(self):
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                self.data = json.load(f)
        else:
            self.data = {
                'current_kafra': 0,
                'position_x': 0,
                'position_y': 0,
                'always_on_top': False
            }
    
    def save(self):
        with open(self.config_file, 'w') as f:
            json.dump(self.data, f, indent=2)
    
    def get(self, key, default=None):
        return self.data.get(key, default)
    
    def set(self, key, value):
        self.data[key] = value
        self.save()
```

#### macOS Implementation

```swift
class Settings {
    static let shared = Settings()
    private let defaults = UserDefaults.standard
    
    var currentKafra: Int {
        get { defaults.integer(forKey: "currentKafra") }
        set { defaults.set(newValue, forKey: "currentKafra") }
    }
    
    var positionX: Int {
        get { defaults.integer(forKey: "positionX") }
        set { defaults.set(newValue, forKey: "positionX") }
    }
    
    var positionY: Int {
        get { defaults.integer(forKey: "positionY") }
        set { defaults.set(newValue, forKey: "positionY") }
    }
    
    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: "alwaysOnTop") }
        set { defaults.set(newValue, forKey: "alwaysOnTop") }
    }
}
```

#### Memo Database (SQLite - Cross-Platform)

```python
import sqlite3
from datetime import datetime

class MemoDatabase:
    def __init__(self, db_path):
        self.conn = sqlite3.connect(db_path)
        self.create_tables()
    
    def create_tables(self):
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS memos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_date TEXT NOT NULL,
                created_time TEXT NOT NULL,
                content TEXT NOT NULL,
                modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        self.conn.commit()
    
    def add_memo(self, content):
        now = datetime.now()
        self.conn.execute('''
            INSERT INTO memos (created_date, created_time, content)
            VALUES (?, ?, ?)
        ''', (now.strftime('%m/%d/%Y'),
              now.strftime('%H:%M:%S'),
              content))
        self.conn.commit()
    
    def get_all_memos(self):
        cursor = self.conn.execute('''
            SELECT id, created_date, created_time, content
            FROM memos
            ORDER BY id ASC
        ''')
        return cursor.fetchall()
    
    def delete_memo(self, memo_id):
        self.conn.execute('DELETE FROM memos WHERE id = ?', (memo_id,))
        self.conn.commit()
```

---

### File Operations

#### Drag and Drop

**Linux (Qt):**

```python
class KafraWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setAcceptDrops(True)
    
    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
    
    def dropEvent(self, event):
        for url in event.mimeData().urls():
            file_path = url.toLocalFile()
            self.handle_dropped_file(file_path)
    
    def handle_dropped_file(self, file_path):
        import shutil
        storage_path = os.path.join(self.app_dir, 'Storage')
        os.makedirs(storage_path, exist_ok=True)
        
        dest_path = os.path.join(storage_path, os.path.basename(file_path))
        shutil.move(file_path, dest_path)
```

**macOS (Swift):**

```swift
class KafraView: NSView {
    override func awakeFromNib() {
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .move
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return false
        }
        
        for url in urls {
            handleDroppedFile(url)
        }
        
        return true
    }
    
    func handleDroppedFile(_ url: URL) {
        let fileManager = FileManager.default
        let storageURL = getStorageDirectory()
        
        let destURL = storageURL.appendingPathComponent(url.lastPathComponent)
        
        do {
            try fileManager.moveItem(at: url, to: destURL)
        } catch {
            print("Error moving file: \(error)")
        }
    }
}
```

---

### Auto-Start Configuration

#### Windows

```vb
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
```

#### Linux (systemd user service)

Create `~/.config/systemd/user/kafra-desktop.service`:

```ini
[Unit]
Description=Kafra Desktop Assistant
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/kafra-desktop
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable:
```bash
systemctl --user enable kafra-desktop.service
systemctl --user start kafra-desktop.service
```

#### Linux (XDG Autostart)

Create `~/.config/autostart/kafra-desktop.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Kafra Desktop Assistant
Exec=/usr/bin/kafra-desktop
Icon=kafra-desktop
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

#### macOS (Launch Agent)

Create `~/Library/LaunchAgents/moe.sei.kafra.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>moe.sei.kafra</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/Kafra Desktop.app/Contents/MacOS/Kafra Desktop</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

Enable:
```bash
launchctl load ~/Library/LaunchAgents/moe.sei.kafra.plist
```

---

## Architecture Adaptation

### Component Re-architecture

#### Original Windows Architecture

```
frmMain (Kafra character)
  ├─ Subclassing for message handling
  ├─ GDI for rendering
  ├─ Registry for storage
  └─ Win32 API for system integration

frmPopup (Memo/Storage)
  ├─ RichTextBox for memos
  ├─ ListView for files
  └─ FileSystemObject for operations

frmTray (System tray)
  ├─ Shell_NotifyIcon
  └─ Custom WndProc
```

#### Recommended Cross-Platform Architecture

```
Application Layer
  ├─ Main Window Manager
  │   ├─ Character Renderer
  │   ├─ Animation Controller
  │   └─ Interaction Handler
  │
  ├─ Memo Manager
  │   ├─ Database Layer (SQLite)
  │   ├─ UI Components
  │   └─ Search/Filter
  │
  ├─ Storage Manager
  │   ├─ File Browser
  │   ├─ Drag-Drop Handler
  │   └─ File Operations
  │
  └─ System Integration
      ├─ Tray Icon
      ├─ Auto-start
      └─ Settings

Platform Abstraction Layer
  ├─ Window Management
  ├─ Storage Backend
  ├─ System Notifications
  └─ File System Operations
```

---

## Implementation Roadmap

### Phase 1: Core Framework (4-6 weeks)

**Tasks:**
1. Set up development environment
2. Implement basic window with transparency
3. Create shaped window from character image
4. Implement dragging and positioning
5. Set up settings storage

**Deliverable:** Movable shaped character window

---

### Phase 2: Character System (3-4 weeks)

**Tasks:**
1. Load all character images
2. Implement character switching
3. Add animations (if desired)
4. Create character selection menu
5. Persist selected character

**Deliverable:** Multi-character support with animations

---

### Phase 3: Memo System (4-5 weeks)

**Tasks:**
1. Design memo database schema
2. Implement memo CRUD operations
3. Create memo UI (list, editor, viewer)
4. Add pagination/navigation
5. Implement search functionality

**Deliverable:** Functional memo management

---

### Phase 4: Storage System (3-4 weeks)

**Tasks:**
1. Implement file browser UI
2. Add drag-and-drop support
3. Implement file operations (move, delete, open)
4. Add folder navigation
5. Integrate with system file manager

**Deliverable:** Functional storage browser

---

### Phase 5: System Integration (2-3 weeks)

**Tasks:**
1. Implement system tray icon
2. Add context menu
3. Configure auto-start
4. Handle show/hide transitions
5. Implement always-on-top

**Deliverable:** Full system integration

---

### Phase 6: Polish & Testing (3-4 weeks)

**Tasks:**
1. Add error handling
2. Implement logging
3. Create installer/package
4. Write user documentation
5. Perform extensive testing

**Deliverable:** Production-ready application

---

## Platform-Specific Considerations

### Linux

**Desktop Environments:**
- **GNOME:** Good support for shaped windows, system tray deprecated (use app indicator)
- **KDE Plasma:** Excellent support for all features
- **XFCE:** Good compatibility
- **i3/Sway:** Limited shaped window support

**Distribution:**
- Create `.deb` package (Debian/Ubuntu)
- Create `.rpm` package (Fedora/RedHat)
- Create AppImage (universal)
- Publish to Flathub (Flatpak)
- Publish to Snap Store

**Dependencies:**
```
python3 (>= 3.9)
python3-pyqt5
python3-pyqt5.qtmultimedia
python3-pil
libsqlite3-0
```

---

### macOS

**Considerations:**
- **Notarization:** Required for distribution (Xcode 10+)
- **Sandboxing:** App Store requires sandbox, limits file access
- **Gatekeeper:** Code signing required
- **Permissions:** Request permissions for file access

**Distribution:**
- Create `.app` bundle
- Create `.dmg` installer
- Optional: Submit to Mac App Store
- Notarize for distribution outside App Store

**Entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <false/>
</dict>
</plist>
```

---

## Testing Strategy

### Cross-Platform Testing Matrix

| Feature | Windows | Linux (GNOME) | Linux (KDE) | macOS |
|---------|---------|---------------|-------------|-------|
| Shaped window | ✅ Original | ⚠️ Test | ⚠️ Test | ⚠️ Test |
| Transparency | ✅ Original | ⚠️ Test | ⚠️ Test | ⚠️ Test |
| Drag-and-drop | ✅ Original | ⚠️ Test | ⚠️ Test | ⚠️ Test |
| System tray | ✅ Original | ⚠️ App Indicator | ⚠️ Test | ⚠️ Test |
| Auto-start | ✅ Original | ⚠️ systemd | ⚠️ Test | ⚠️ Launch Agent |
| File operations | ✅ Original | ⚠️ Test | ⚠️ Test | ⚠️ Sandbox |

### Test Cases

1. **Window Shaping**
   - Load each character
   - Verify transparency
   - Test click-through on transparent areas

2. **Positioning**
   - Drag to each screen edge
   - Test snap behavior
   - Verify position persistence

3. **Memos**
   - Create, read, update, delete
   - Test pagination
   - Verify persistence
   - Test special characters

4. **Storage**
   - Drop files of various types
   - Drop folders
   - Navigate directories
   - Open files

5. **System Integration**
   - Tray icon appearance
   - Context menu functionality
   - Auto-start configuration
   - Show/hide toggling

---

## Performance Optimization

### Original Performance Characteristics

- **Memory:** ~7-8 MB (VB6 runtime + application)
- **CPU:** Minimal (event-driven)
- **Startup:** < 1 second

### Target Performance (Modern)

- **Memory:** < 50 MB (acceptable for modern systems)
- **CPU:** < 1% idle, < 10% during animations
- **Startup:** < 2 seconds

### Optimization Strategies

1. **Lazy Loading**
   ```python
   # Load character images on demand
   def get_character_pixmap(self, index):
       if index not in self.pixmap_cache:
           self.pixmap_cache[index] = QPixmap(f"kafra_{index}.png")
       return self.pixmap_cache[index]
   ```

2. **Efficient Rendering**
   ```python
   # Use hardware acceleration
   widget.setAttribute(Qt.WA_OpaquePaintEvent)
   widget.setAttribute(Qt.WA_NoSystemBackground)
   ```

3. **Database Optimization**
   ```sql
   -- Index for fast memo retrieval
   CREATE INDEX idx_memos_created ON memos(created_date, created_time);
   ```

---

## Security Improvements

When porting, implement modern security practices:

1. **Sandboxing**
   - Limit file system access
   - Use OS sandboxing (macOS App Sandbox, Flatpak)

2. **Input Validation**
   ```python
   def is_safe_filename(filename):
       # Reject path traversal
       if '..' in filename or '/' in filename or '\\' in filename:
           return False
       
       # Validate characters
       import re
       if not re.match(r'^[\w\-. ]+$', filename):
           return False
       
       return True
   ```

3. **Safe File Execution**
   ```python
   import mimetypes
   
   SAFE_TYPES = ['text/plain', 'image/png', 'image/jpeg', 'application/pdf']
   
   def open_file(path):
       mime_type, _ = mimetypes.guess_type(path)
       
       if mime_type not in SAFE_TYPES:
           # Show warning dialog
           response = show_warning_dialog(
               "This file type may be dangerous. Continue?"
           )
           if not response:
               return
       
       # Open with default application
       QDesktopServices.openUrl(QUrl.fromLocalFile(path))
   ```

---

## Conclusion

Recreating Kafra Desktop Assistant on Linux or macOS is a substantial undertaking requiring:

1. **Complete rewrite** in a modern language
2. **Platform-specific APIs** for shaped windows and system integration
3. **Redesigned storage** replacing Windows Registry
4. **Security hardening** with modern best practices

**Recommended Approach:**

1. Start with Python + PyQt5 for rapid prototyping
2. Implement core features first (shaped window, character switching)
3. Add system integration features
4. Test extensively on target platforms
5. Consider native ports (Swift for macOS) after proving concept

**Estimated Total Effort:** 800-1200 hours for full-featured, polished ports on both Linux and macOS.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
