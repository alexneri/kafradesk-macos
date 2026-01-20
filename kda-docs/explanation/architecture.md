# System Architecture

## Overview

Kafra Desktop Assistant employs a modular architecture built on Visual Basic 6.0, leveraging Windows API capabilities for advanced UI features. The application is structured around a single main form with supporting popup windows, custom controls, and utility modules.

## Architectural Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        User Layer                            │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  frmMain    │  │  frmPopup    │  │  frmTray     │       │
│  │  (Kafra)    │  │  (Memo/Store)│  │ (Sys Tray)   │       │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘       │
└─────────┼─────────────────┼──────────────────┼──────────────┘
          │                 │                  │
┌─────────┼─────────────────┼──────────────────┼──────────────┐
│         │     Component Layer (Forms/Controls)│              │
│  ┌──────▼──────┐   ┌─────▼──────┐   ┌───────▼──────┐       │
│  │ frmAbout    │   │frmNewTrunk │   │ frmMessage   │       │
│  │ frmBlurb    │   │frmCalendar │   │ frmPopup*    │       │
│  │ mnuForm     │   │            │   │              │       │
│  └─────────────┘   └────────────┘   └──────────────┘       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │      Custom Controls (UserControls)                  │   │
│  │  • RagButton2 - Ragnarok-style buttons              │   │
│  │  • RagButtonResource - Shared button resources       │   │
│  │  • ucShadow - Drop shadow effects                    │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────┬────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────┐
│              Business Logic Layer (Modules)                   │
│  ┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   modAFS.bas    │  │  modReg.bas  │  │ modLayered.bas  │  │
│  │ (Core Logic)    │  │  (Registry)  │  │ (Transparency)  │  │
│  └─────────────────┘  └──────────────┘  └─────────────────┘  │
│  ┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  modRegion.bas  │  │ modWndProc   │  │   modAPI.bas    │  │
│  │ (Form Shaping)  │  │ (Tray Icon)  │  │ (API Declares)  │  │
│  └─────────────────┘  └──────────────┘  └─────────────────┘  │
└──────────────────────────────┬────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────┐
│            Class Layer (Helper Classes)                       │
│  ┌──────────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │  cDIBSection     │  │cDIBSection    │  │  cSubclass    │  │
│  │  (Bitmap Mgmt)   │  │Region         │  │  (Subclass)   │  │
│  │                  │  │(Form Shaping) │  │               │  │
│  └──────────────────┘  └───────────────┘  └───────────────┘  │
│  ┌──────────────────┐                                         │
│  │    cWindow       │                                         │
│  │  (API Windows)   │                                         │
│  └──────────────────┘                                         │
└──────────────────────────────┬────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────┐
│              Windows API / System Services                    │
│  • GDI32.dll  - Graphics Device Interface                     │
│  • USER32.dll - Window Management                             │
│  • KERNEL32   - Core OS Services                              │
│  • ADVAPI32   - Registry Access                               │
│  • SHELL32    - Shell Integration                             │
└───────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────▼────────────────────────────────┐
│              Data/Resource Layer                              │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐           │
│  │ orig.res / │  │  Registry   │  │  File System │           │
│  │ sakura.res │  │  (HKCU/HKLM)│  │  (\Storage)  │           │
│  │ (Bitmaps,  │  │             │  │              │           │
│  │  Regions,  │  │ • Position  │  │ • Memos      │           │
│  │  Strings)  │  │ • Settings  │  │ • Files      │           │
│  └────────────┘  └─────────────┘  └──────────────┘           │
└───────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Main Application Form (`frmMain`/`bg.frm`)

**Purpose:** Primary UI element displaying the animated Kafra character.

**Responsibilities:**
- Render shaped transparent form using region data
- Handle user interactions (click, drag, right-click menu)
- Process OLE drag-and-drop operations
- Manage form positioning and screen snapping
- Animate transparency effects (show/hide)
- Subclass windows messages for custom behavior

**Key Technologies:**
- `cDIBSection` for bitmap manipulation
- `cDIBSectionRegion` for non-rectangular form creation
- `cSubclass` for safe window message handling
- Windows layered window API for transparency (Win2K/XP)

### 2. Popup Window (`frmPopup.frm`)

**Purpose:** Multi-function window providing memo management and file storage interface.

**Responsibilities:**
- Display memo list with pagination
- Render memo content with timestamp
- Provide file browser for storage directory
- Handle file operations (open, delete, move)
- Manage window minimize/maximize states

**UI Features:**
- Dual-mode operation (Memo view / Storage view)
- Custom Ragnarok-themed buttons
- ListView control for file display
- Multi-line text display for memos

### 3. System Tray Integration (`frmTray.frm`)

**Purpose:** Background form managing system tray icon and notifications.

**Responsibilities:**
- Create and maintain tray icon
- Handle tray icon click events
- Display context menu
- Manage show/hide state
- Respond to double-click (toggle visibility)

**Implementation:**
- Uses `Shell_NotifyIcon` API
- Custom window procedure via `modWndProc`
- NOTIFYICONDATA structure for tray communication

### 4. Subclassing System (`cSubclass.cls`)

**Purpose:** IDE-safe window subclassing for custom message handling.

**Key Features:**
- Machine code thunk for callback routing
- Message filtering tables (before/after)
- Automatic cleanup on class destruction
- Safe for VB IDE debugging
- Breakpoint gate for IDE safety

**Critical Code Patterns:**
```vb
' Initialize subclass
MainSubClass.Subclass Me.hWnd, Me

' Add messages to monitor
MainSubClass.AddMsg WM_MOVING, MSG_BEFORE
MainSubClass.AddMsg WM_EXITSIZEMOVE, MSG_BEFORE

' Implement callback interface
Private Function iSubclass_Before(ByVal hWnd As Long, _
                                   ByVal uMsg As Long, _
                                   ByVal wParam As Long, _
                                   ByVal lParam As Long, _
                                   bHandled As Boolean) As Long
    ' Handle messages here
End Function
```

### 5. Form Shaping System

**Components:**
- `cDIBSection.cls` - Manages Device Independent Bitmaps
- `cDIBSectionRegion.cls` - Converts bitmaps to window regions
- `modRegion.bas` - Helper functions

**Process Flow:**
1. Load bitmap from resource (`LoadResPicture`)
2. Create DIB section from bitmap
3. Scan bitmap pixel-by-pixel for transparency color
4. Generate window region excluding transparent pixels
5. Apply region to form window handle

**Region Data:**
- Pre-compiled region files (`.rgn`) stored in resources
- Loaded via `LoadFromResource` method
- Applied with `SetWindowRgn` API

### 6. Registry Management (`modReg.bas`)

**Purpose:** Persistent storage of application settings.

**Registry Structure:**
```
HKEY_CURRENT_USER\Software\EnderSoft\DesktopKafra\
  ├─ "Current Kafra"  (DWORD)  - Selected character index
  ├─ "Kafra X"        (DWORD)  - X position in pixels
  ├─ "Always On Top"  (STRING) - "Yes" / empty

HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\
  └─ "Desktop Kafra"  (STRING) - Autorun path (if enabled)
```

**Key Functions:**
- `SetStringKey` / `GetStringKey` - String value operations
- `SetHexKey` / `GetHexKey` - DWORD value operations
- `RemoveKey` - Delete registry values
- `SetAutoRun` - Configure Windows startup

### 7. Transparency System (`modLayered.bas`)

**Purpose:** Windows 2000/XP layered window support.

**Features:**
- OS version detection (`CheckOSVersion`)
- Layered window attribute setting
- Alpha blending support
- Color key transparency

**API Usage:**
```vb
' Enable layered window style
SetLayered Me.hWnd, True

' Set transparency (255 = opaque, 0 = invisible)
SetWindowEffects Me.hWnd, , 255

' Fade effect
For i = 255 To 0 Step -5
    SetWindowEffects Me.hWnd, , CByte(i)
Next
```

## Data Flow

### Application Startup

1. **Form_Load (frmMain)**
   - Check for previous instance (exit if found)
   - Detect OS version for feature support
   - Create Storage folder if missing
   - Load custom cursors from files
   - Read registry settings (position, autorun, always-on-top)
   - Initialize subclassing
   - Load Kafra bitmap and region
   - Apply transparency effects
   - Show blurb notification

2. **Tray Icon Creation**
   - Load frmTray
   - Configure NOTIFYICONDATA structure
   - Call Shell_NotifyIcon with NIM_ADD
   - Set custom window procedure

3. **Resource Loading**
   - Load character bitmap from resource ID
   - Load pre-generated region data
   - Apply region to form for transparency

### User Interaction Flows

#### Drag Kafra Character

```
MouseDown (frmMain)
  └─> SetRagCursor(CUR_HANDCLOSE)
  └─> ReleaseCapture API
  └─> SendMessage(WM_SYSCOMMAND, SC_CLICKMOVE)
      └─> [Windows handles dragging]
      └─> WM_MOVING message intercepted
          └─> SnapToScreen() called
              └─> Adjust position to screen edges
      └─> WM_EXITSIZEMOVE message
          └─> Save position to registry
          └─> End dragging state
```

#### Drop File on Kafra

```
Form_OLEDragDrop
  └─> Iterate Data.Files collection
      └─> Determine if folder or file
          └─> Use FileSystemObject to move
              └─> Move to \Storage\<filename>
      └─> Refresh frmPopup ListView
```

#### Add New Memo

```
User clicks "Write" icon (frmPopup)
  └─> RichTextBox becomes editable
  └─> User types content
  └─> User clicks "Write" icon again
      └─> Generate timestamp
      └─> Save to registry key
          └─> HKCU\Software\EnderSoft\DesktopKafra\Memos\<index>
      └─> Refresh memo list
```

### Application Shutdown

1. **Form_Unload (frmMain)**
   - Remove subclass messages
   - Call UnSubclass
   - Clear DIB resources
   - Destroy region object
   - Save final position to registry
   - Unload all child forms
   - Remove tray icon

## Threading Model

**Single-Threaded:** VB6 applications are single-threaded with apartment threading for COM objects.

**Message Pump:** Standard Windows message loop handled by VB runtime.

**DoEvents:** Used during animations to yield processor and process messages.

⚠️ **Note:** Excessive DoEvents can cause re-entrancy issues. The application uses `MovingMe` flag to prevent re-entrant animation calls.

## Memory Management

### Resource Lifetime

- **DIB Sections:** Explicitly managed via `Create` and `ClearUp` methods
- **Regions:** Destroyed via `Destroy` method on class
- **GDI Objects:** Must be deleted with `DeleteObject` API
- **Subclass Thunks:** Automatically cleaned in `Class_Terminate`

### Memory Footprint

- Base application: ~7-8 MB RAM (reported in History.txt)
- Image resources loaded into memory from .res file
- ListView icon storage uses shared ImageList

## Security Model

### Privilege Requirements

- **User-level access:** Required for HKCU registry operations
- **Administrator access:** Required for:
  - HKLM autorun registration
  - System-wide settings

### Attack Surface

1. **Registry Injection:** No input validation on registry reads
2. **File System:** Unrestricted file moves in OLE drop
3. **Shell Execute:** Can launch arbitrary files from storage
4. **No Code Signing:** Executable not digitally signed

See [Security Considerations](security.md) for detailed analysis.

## Performance Characteristics

### Optimization Strategies

1. **Pre-generated Regions:** Bitmap-to-region conversion done at design time
2. **Resource Pooling:** `RagButtonResource` shares bitmaps across controls
3. **Conditional Transparency:** Effects disabled on Win98/ME
4. **Lazy Loading:** Forms loaded on-demand

### Bottlenecks

1. **Region Creation:** Pixel-by-pixel scanning is O(n²)
2. **Registry I/O:** Synchronous, blocks on each operation
3. **File Enumeration:** ListView population can lag with many files

## Extensibility Points

### Adding New Characters

1. Add bitmap to resource file with ID 111+index
2. Add region data with ID 101+index
3. Add name string with ID 101+index
4. Update menu array bounds in mnuForm

### Custom Controls

The `RagButton2` and `RagButtonResource` controls demonstrate the pattern for creating themed UI components:

- PropertyBag persistence for design-time properties
- Resource-based image sharing
- Manual hit testing and rendering

### Message Hooking

The `cSubclass` and `cWindow` classes provide extensible message filtering:

```vb
' Add custom window message handling
mySubclass.AddMsg WM_CUSTOMNESSAGE, MSG_BEFORE
```

## Platform Dependencies

| Feature | Windows 98/ME | Windows 2000/XP |
|---------|---------------|-----------------|
| **Form Shaping** | ✅ Supported | ✅ Supported |
| **Transparency** | ❌ Not Available | ✅ Layered Windows |
| **System Tray** | ✅ Supported | ✅ Supported |
| **Registry** | ✅ Supported | ✅ Supported |
| **OLE Drag-Drop** | ✅ Supported | ✅ Supported |
| **Subclassing** | ✅ Supported | ✅ Supported |

## Next Steps

- See [Forms Reference](../reference/forms-reference.md) for detailed form documentation
- See [Module Reference](../reference/modules-reference.md) for function-level details
- See [Migration Guide](../migration/overview.md) for cross-platform considerations

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
