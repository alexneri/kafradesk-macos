# Modules Reference

## Overview

This document details all VB6 standard modules (`.bas` files) in Kafra Desktop Assistant. Modules contain public functions, subroutines, API declarations, and global variables accessible throughout the application.

## Module Catalog

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **modAPI.bas** | Windows API declarations | API functions, constants, types |
| **modAFS.bas** | Application function suite | Screen snapping, form shaping, cursors |
| **modReg.bas** | Registry operations | Read/write registry values |
| **modLayered.bas** | Transparency effects | Layered window support |
| **modRegion.bas** | Form shaping helpers | Region object globals |
| **modWndProc.bas** | Window procedure | Tray icon message handler |

---

## modAPI.bas

### Purpose

Central repository for all Windows API function declarations, constants, and structures used throughout the application.

### Contents

See [API Reference](api-reference.md) for detailed documentation of each API function.

**Summary:**
- **GDI32** declarations (graphics operations)
- **USER32** declarations (window management)
- **KERNEL32** declarations (system services)
- **SHELL32** declarations (shell integration)
- **ADVAPI32** declarations (registry access)
- Window message constants
- Common structures (POINT_TYPE, RECT, NOTIFYICONDATA)

---

## modAFS.bas

**Module Name:** Application Function Suite

### Purpose

Core utility functions for form manipulation, cursor management, and screen positioning.

### Global Variables

```vb
Public TaskBarHeight As Long      ' Height of taskbar in twips
Public MovingMe As Boolean         ' Global animation lock flag
Public DraggingMe As Boolean       ' Drag operation in progress
Public DraggingPop As Boolean      ' Popup drag in progress

Public KafraName As String         ' Current Kafra character name
Public curPath As String           ' Current storage folder path

Dim hcurPointer As Long            ' Handle to pointer cursor
Dim hcurHandOpen As Long           ' Handle to open hand cursor
Dim hcurHandClose As Long          ' Handle to closed hand cursor
Dim hcurTarget As Long             ' Handle to target cursor

Public scrWidth As Long            ' Screen width in pixels
Public scrHeight As Long           ' Screen height in pixels
```

### Enumerations

#### RagCursors

```vb
Enum RagCursors
    CUR_POINT
    CUR_HANDOPEN
    CUR_HANDCLOSE
    CUR_TARGET
End Enum
```

### Public Functions

#### SnapToScreen

Snaps a window's position to screen edges.

**Signature:**
```vb
Public Sub SnapToScreen( _
    curx As Long, _
    cury As Long, _
    r As RECT, _
    snapped As Boolean, _
    Optional snapwidth As Long = 10 _
)
```

**Parameters:**
- `curx` - Current X position in pixels
- `cury` - Current Y position in pixels
- `r` - RECT structure (modified in place)
- `snapped` - Output flag indicating if snap occurred
- `snapwidth` - Snap threshold distance (default 10 pixels)

**Behavior:**
1. Calculate rectangle dimensions from `r`
2. Check if left edge within `snapwidth` of screen left → snap to 0
3. Check if right edge within `snapwidth` of screen right → snap to edge
4. Check if top edge within `snapwidth` of screen top → snap to 0
5. Check if bottom edge within `snapwidth` of screen bottom → snap to edge
6. Update `r.Left` and `r.Top` with snapped coordinates
7. Set `snapped = True` if any snap occurred

**Algorithm:**
```vb
lWidth = r.Right - r.Left
lHeight = r.Bottom - r.Top

If Abs(curx) < snapwidth Then
    r.Left = 0
    snapped = True
ElseIf Abs((scrWidth - lWidth) - curx) < snapwidth Then
    r.Left = scrWidth - lWidth
    snapped = True
Else
    r.Left = curx
    snapped = False
End If

' Similar logic for vertical snapping
```

**Usage Example:**
```vb
Dim r As RECT
Dim snapped As Boolean

' In WM_MOVING message handler
CopyMemory r, ByVal lParam, Len(r)
SnapToScreen r.Left, r.Top, r, snapped, 10
CopyMemory ByVal lParam, r, Len(r)
```

---

#### SnapToForm

Snaps a window to edges of another form.

**Signature:**
```vb
Public Sub SnapToForm( _
    curx As Long, _
    cury As Long, _
    dx As Long, _
    dy As Long, _
    r As RECT, _
    TargetForm As Form, _
    snapped As Boolean, _
    Optional snapwidth As Long = 10 _
)
```

**Parameters:**
- `curx`, `cury` - Current position
- `dx`, `dy` - Delta movement (unused in current implementation)
- `r` - RECT structure to modify
- `TargetForm` - Form to snap to
- `snapped` - Output snap flag
- `snapwidth` - Snap threshold (default 10 pixels)

**Snap Modes:**
1. **Left to right side** - Source left edge near target right edge
2. **Right to left side** - Source right edge near target left edge
3. **Top to bottom** - Source top near target bottom
4. **Bottom to top** - Source bottom near target top
5. **Top to top** - Align top edges
6. **Left to left** - Align left edges

**Limitations:**
- Does not support snapping to right and bottom edges when source is smaller
- Exits early if already snapped
- Target form must be visible

**Usage Example:**
```vb
SnapToForm curX, curY, 0, 0, r, frmPopupTools, snapped, 10
```

---

#### CornerFormShape

Applies rounded corners to a form by creating and applying a region.

**Signature:**
```vb
Public Function CornerFormShape(ByRef bG As Form)
```

**Parameters:**
- `bG` - Form to apply rounded corners to

**Behavior:**
1. Set form `ScaleMode` to pixels
2. Create base region covering entire form
3. Remove pixels at each corner:
   - Top-left: (0,0) to (2,1) and (0,1) to (1,2)
   - Top-right: mirror of top-left
   - Bottom-left: mirror of top-left
   - Bottom-right: mirror of top-left
4. Apply region with `SetWindowRgn`
5. Delete region handle (system owns it now)

**Corner Pattern:**
```
##XX...  (# = removed, X = visible)
#XXX...
XXXX...
```

**Code:**
```vb
CurRgn = CreateRectRgn(0, 0, W, H)
RemoveArea CurRgn, 0, 0, 2, 1
RemoveArea CurRgn, 0, 1, 1, 2
RemoveArea CurRgn, W - 2, 0, W, 1
RemoveArea CurRgn, W - 1, 1, W, 2
RemoveArea CurRgn, 0, H - 1, 2, H
RemoveArea CurRgn, 0, H - 2, 1, H - 1
RemoveArea CurRgn, W - 2, H - 1, W, H
RemoveArea CurRgn, W - 1, H - 2, W, H - 1
success = SetWindowRgn(bG.hWnd, CurRgn, True)
DeleteObject (CurRgn)
```

**Helper Function:**
```vb
Private Sub RemoveArea(ByRef CurRgn As Long, _
                       X1 As Long, Y1 As Long, _
                       X2 As Long, Y2 As Long)
    TempRgn = CreateRectRgn(X1, Y1, X2, Y2)
    CombineRgn CurRgn, CurRgn, TempRgn, RGN_DIFF
    DeleteObject (TempRgn)
End Sub
```

---

#### SetRagCursor

Changes the active cursor to a Ragnarok-themed cursor.

**Signature:**
```vb
Public Sub SetRagCursor(curtype As RagCursors)
```

**Parameters:**
- `curtype` - Cursor type from RagCursors enum

**Behavior:**
- Validates cursor handle is non-zero
- Calls `SetCursor` API with stored handle

**Code:**
```vb
Select Case curtype
Case RagCursors.CUR_POINT
    If hcurPointer <> 0 Then SetCursor hcurPointer
Case RagCursors.CUR_HANDOPEN
    If hcurHandOpen <> 0 Then SetCursor hcurHandOpen
Case RagCursors.CUR_HANDCLOSE
    If hcurHandClose <> 0 Then SetCursor hcurHandClose
Case RagCursors.CUR_TARGET
    If hcurTarget <> 0 Then SetCursor hcurTarget
End Select
```

**Usage Example:**
```vb
Private Sub Form_MouseMove(...)
    SetRagCursor CUR_POINT
End Sub
```

---

#### SetAlwaysOnTop

Sets or removes the "always on top" window style.

**Signature:**
```vb
Public Sub SetAlwaysOnTop(target As Form, mode As Long)
```

**Parameters:**
- `target` - Form to modify
- `mode` - `HWND_TOPMOST` (-1) or `HWND_NOTOPMOST` (-2)

**Behavior:**
- Calls `SetWindowPos` with SWP_NOACTIVATE and SWP_SHOWWINDOW flags
- Converts VB twips to screen coordinates (divide by 15)

**Note:** Magic number 15 is conversion factor from twips to pixels. Should use `Screen.TwipsPerPixelX/Y` for correctness.

**Code:**
```vb
SetWindowPos target.hWnd, mode, _
            target.Left / 15, target.Top / 15, _
            target.Width / 15, target.Height / 15, _
            SWP_NOACTIVATE Or SWP_SHOWWINDOW
```

---

#### LoadCursors

Loads custom cursor files from disk.

**Signature:**
```vb
Public Sub LoadCursors()
```

**Behavior:**
1. Load `rag_cur.ani` (animated pointer)
2. Load `handopen.cur` (open hand)
3. Load `handclosed.cur` (closed hand)
4. Load `rag_target.ani` (animated target)
5. Store handles in module-level variables

**Expected Files:**
```
<App.Path>\Cursors\
  ├─ rag_cur.ani
  ├─ handopen.cur
  ├─ handclosed.cur
  └─ rag_target.ani
```

**Error Handling:**
- If file missing, handle will be 0
- `SetRagCursor` checks for 0 before using

**Code:**
```vb
hcurPointer = LoadCursorFromFile(App.path & "\Cursors\rag_cur.ani")
hcurHandOpen = LoadCursorFromFile(App.path & "\Cursors\handopen.cur")
hcurHandClose = LoadCursorFromFile(App.path & "\Cursors\handclosed.cur")
hcurTarget = LoadCursorFromFile(App.path & "\Cursors\rag_target.ani")
```

---

### Compiler Directives

```vb
#Const XPFORMS = False
```

**Purpose:** Conditional compilation for Windows XP-specific features. Currently unused in the codebase.

---

## modReg.bas

### Purpose

Wrapper functions for Windows registry operations, simplifying read/write of string and DWORD values.

### Type Definitions

#### SECURITY_ATTRIBUTES

```vb
Public Type SECURITY_ATTRIBUTES
    nLength As Long
    lpSecurityDescriptor As Long
    bInheritHandle As Long
End Type
```

#### FILETIME

```vb
Public Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
```

### Constants

**Root Keys:**
```vb
Public Const HKEY_CLASSES_ROOT = &H80000000
Public Const HKEY_CURRENT_CONFIG = &H80000005
Public Const HKEY_CURRENT_USER = &H80000001
Public Const HKEY_DYN_DATA = &H80000006
Public Const HKEY_LOCAL_MACHINE = &H80000002
Public Const HKEY_PERFORMANCE_DATA = &H80000004
Public Const HKEY_USERS = &H80000003
```

**Access Rights:**
```vb
Public Const KEY_ALL_ACCESS = &HF003F
Public Const KEY_QUERY_VALUE = &H1
Public Const KEY_SET_VALUE = &H2
Public Const KEY_READ = &H20019
Public Const KEY_WRITE = &H20006
```

**Value Types:**
```vb
Public Const REG_SZ = 1              ' String
Public Const REG_DWORD = 4           ' 32-bit number
Public Const REG_BINARY = 3          ' Binary data
Public Const REG_EXPAND_SZ = 2       ' Expandable string
Public Const REG_MULTI_SZ = 7        ' Multi-string
```

### Public Functions

#### SetStringKey

Writes a string value to the registry.

**Signature:**
```vb
Public Function SetStringKey( _
    startkey As Long, _
    subkey As String, _
    key As String, _
    Value As String _
)
```

**Parameters:**
- `startkey` - Root key (e.g., `HKEY_CURRENT_USER`)
- `subkey` - Registry path (e.g., `"Software\EnderSoft\DesktopKafra\"`)
- `key` - Value name (e.g., `"Always On Top"`)
- `Value` - String to write

**Behavior:**
1. Append null terminator to value
2. Create or open registry key
3. Write string value
4. Close key handle

**Usage Example:**
```vb
SetStringKey HKEY_CURRENT_USER, _
             "Software\EnderSoft\DesktopKafra\", _
             "Always On Top", _
             "Yes"
```

---

#### GetStringKey

Reads a string value from the registry.

**Signature:**
```vb
Public Function GetStringKey( _
    startkey As Long, _
    subkey As String, _
    key As String _
) As String
```

**Parameters:**
- Same as `SetStringKey` (minus Value)

**Returns:**
- String value, or empty string on error

**Behavior:**
1. Allocate 255-character buffer
2. Create or open registry key
3. Query value into buffer
4. Trim to actual length (removing null terminator)
5. Return string
6. On error, return empty string

**Usage Example:**
```vb
Dim topMode As String
topMode = GetStringKey(HKEY_CURRENT_USER, _
                       "Software\EnderSoft\DesktopKafra\", _
                       "Always On Top")
If topMode = "Yes" Then
    ' Enable always on top
End If
```

---

#### SetHexKey

Writes a DWORD value to the registry.

**Signature:**
```vb
Public Function SetHexKey( _
    startkey As Long, _
    subkey As String, _
    key As String, _
    lBuffer As Long _
)
```

**Parameters:**
- `lBuffer` - 32-bit integer to write

**Usage Example:**
```vb
SetHexKey HKEY_CURRENT_USER, _
          "Software\EnderSoft\DesktopKafra\", _
          "Kafra X", _
          Me.Left \ Screen.TwipsPerPixelX
```

---

#### GetHexKey

Reads a DWORD value from the registry.

**Signature:**
```vb
Public Function GetHexKey( _
    startkey As Long, _
    subkey As String, _
    key As String _
) As Long
```

**Returns:**
- DWORD value, or 0 on error

**Usage Example:**
```vb
Dim xPos As Long
xPos = GetHexKey(HKEY_CURRENT_USER, _
                 "Software\EnderSoft\DesktopKafra\", _
                 "Kafra X")
```

---

#### RemoveKey

Deletes a registry value.

**Signature:**
```vb
Public Function RemoveKey( _
    startkey As Long, _
    subkey As String, _
    key As String _
)
```

**Behavior:**
1. Open existing key
2. Delete value with `RegDeleteValue`
3. Close key handle

**Usage Example:**
```vb
RemoveKey HKEY_LOCAL_MACHINE, _
          "Software\Microsoft\Windows\CurrentVersion\Run\", _
          "Desktop Kafra"
```

---

#### SetAutoRun

Configures Windows startup autorun.

**Signature:**
```vb
Public Sub SetAutoRun(mode As Boolean)
```

**Parameters:**
- `mode` - True to enable, False to disable

**Behavior:**
- **Enable:** Writes executable path to HKLM Run key
- **Disable:** Removes value from HKLM Run key

**Registry Location:**
```
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
  └─ "Desktop Kafra" = "<path>\KafraDesk.exe"
```

**Security Note:** Requires administrator privileges for HKLM writes. Will fail silently on Vista+ without elevation.

**Code:**
```vb
Public Sub SetAutoRun(mode As Boolean)
    If mode = True Then
        SetStringKey HKEY_LOCAL_MACHINE, _
                     "Software\Microsoft\Windows\CurrentVersion\Run", _
                     "Desktop Kafra", _
                     App.path & "\" & App.EXEName & ".exe"
    Else
        RemoveKey HKEY_LOCAL_MACHINE, _
                  "Software\Microsoft\Windows\CurrentVersion\Run\", _
                  "Desktop Kafra"
    End If
End Sub
```

---

## modLayered.bas

### Purpose

Windows 2000/XP layered window support for transparency and alpha blending effects.

### Type Definitions

#### OSVERSIONINFO

```vb
Private Type OSVERSIONINFO
    dwOSVersionInfoSize As Long
    dwMajorVersion As Long
    dwMinorVersion As Long
    dwBuildNumber As Long
    dwPlatformId As Long
    szCSDVersion As String * 128
End Type
```

### Global Variables

```vb
Public OS_2000 As Boolean  ' True if Windows 2000 or later
```

### Constants

```vb
Private Const GWL_EXSTYLE = (-20)
Private Const WS_EX_LAYERED = &H80000
Private Const LWA_COLORKEY = &H1
Private Const LWA_ALPHA = &H2
```

### Public Functions

#### CheckOSVersion

Detects if running on Windows 2000 or later.

**Signature:**
```vb
Public Sub CheckOSVersion()
```

**Behavior:**
1. Initialize OSVERSIONINFO structure
2. Call `GetVersionEx` API
3. Check `dwPlatformId` > 1 (NT platform)
4. Set `OS_2000` global variable

**Platform IDs:**
- `1` = Windows 95/98/ME
- `2` = Windows NT/2000/XP

**Code:**
```vb
Dim os As OSVERSIONINFO
Dim retval As Long

os.dwOSVersionInfoSize = Len(os)
retval = GetVersionEx(os)
        
If os.dwPlatformId > 1 Then OS_2000 = True
```

---

#### SetLayered

Enables or disables layered window style.

**Signature:**
```vb
Public Sub SetLayered( _
    ByVal hWnd As Long, _
    ByVal bState As Boolean _
)
```

**Parameters:**
- `hWnd` - Window handle
- `bState` - True to enable, False to disable

**Behavior:**
1. Exit if not Windows 2000+
2. Get current extended window style
3. Add or remove `WS_EX_LAYERED` bit
4. Set updated style

**Code:**
```vb
If Not OS_2000 Then Exit Sub

lStyle = GetWindowLong(hWnd, GWL_EXSTYLE)
If bState Then
    lStyle = lStyle Or WS_EX_LAYERED
Else
    lStyle = lStyle And Not WS_EX_LAYERED
End If
SetWindowLong hWnd, GWL_EXSTYLE, lStyle
```

---

#### SetWindowEffects

Sets transparency attributes for a layered window.

**Signature:**
```vb
Public Function SetWindowEffects( _
    ByVal lhWnd As Long, _
    Optional ByVal transparentColor As Long = -1, _
    Optional ByVal alpha As Byte = 255 _
)
```

**Parameters:**
- `lhWnd` - Window handle
- `transparentColor` - RGB color to make transparent (-1 for none)
- `alpha` - Alpha blend value (0 = invisible, 255 = opaque)

**Returns:** Nothing (Sub in actual implementation)

**Behavior:**
1. Exit if not Windows 2000+
2. Build flags:
   - If `transparentColor` specified, add `LWA_COLORKEY` flag
   - If `alpha` < 255, add `LWA_ALPHA` flag
3. Call `SetLayeredWindowAttributes` API

**Usage Examples:**

**Fade Effect:**
```vb
SetLayered Me.hWnd, True
For i = 0 To 255 Step 5
    SetWindowEffects Me.hWnd, , CByte(i)
    DoEvents
Next
```

**Color Key Transparency:**
```vb
SetWindowEffects Me.hWnd, RGB(255, 0, 255)  ' Make magenta transparent
```

**Semi-Transparent Window:**
```vb
SetWindowEffects Me.hWnd, , 128  ' 50% opacity
```

---

## modRegion.bas

### Purpose

Global declarations for form shaping objects.

### Global Variables

```vb
Public myDIBObj As cDIBSection
Public myRegion As cDIBSectionRegion
```

**Usage:**
- Shared DIB section object for temporary operations
- Shared region object for form shaping utilities

⚠️ **Note:** In actual implementation (frmMain), local `myDIB` and `myRGN` are used instead. These globals appear unused.

### API Declaration

```vb
Public Declare Function GetPixel Lib "gdi32" ( _
    ByVal hdc As Long, _
    ByVal x As Long, _
    ByVal y As Long _
) As Long
```

**Duplicate Declaration:** Also declared in modAPI.bas.

---

## modWndProc.bas

### Purpose

Custom window procedure for handling system tray icon messages.

### Global Variables

```vb
Public pOldProc As Long  ' Address of original window procedure
```

### Public Functions

#### WindowProc

Custom window procedure callback.

**Signature:**
```vb
Public Function WindowProc( _
    ByVal hWnd As Long, _
    ByVal uMsg As Long, _
    ByVal wParam As Long, _
    ByVal lParam As Long _
) As Long
```

**Parameters:**
- Standard window procedure parameters

**Returns:**
- Message-specific return value

**Messages Handled:**

**PK_TRAYICON (0x401):**

Custom message for tray icon events.

**lParam Values:**
- `WM_RBUTTONUP` - Right-click on tray icon
  - Action: Show context menu
  - Code: `mnuForm.PopupMenu mnuForm.mnu1`
  
- `WM_LBUTTONDBLCLK` - Double-click on tray icon
  - Action: Toggle visibility
  - Code:
    ```vb
    If frmMain.Hidden Then
        frmMain.ShowKafra
    Else
        frmMain.HideKafra
    End If
    ```

**All Other Messages:**
- Forwarded to original window procedure via `CallWindowProc`

**Full Implementation:**
```vb
Public Function WindowProc(...) As Long
    Select Case uMsg
    Case PK_TRAYICON
        Select Case lParam
        Case WM_RBUTTONUP
            mnuForm.PopupMenu mnuForm.mnu1
        
        Case WM_LBUTTONDBLCLK
            Debug.Print frmMain.Visible
        
            If frmMain.Hidden Then
                frmMain.ShowKafra
            Else
                frmMain.HideKafra
            End If
        Case Else
         
        End Select
        WindowProc = 1
    
    Case Else
        WindowProc = CallWindowProc(pOldProc, hWnd, uMsg, wParam, lParam)
    End Select
End Function
```

**Installation:**
```vb
' In frmTray.Form_Load
pOldProc = SetWindowLong(Me.hWnd, GWL_WNDPROC, AddressOf WindowProc)
```

**Restoration:**
```vb
' In frmTray.Form_Unload
SetWindowLong Me.hWnd, GWL_WNDPROC, pOldProc
```

---

## Common Patterns and Best Practices

### Error Handling

Registry functions use structured error handling:

```vb
Public Function GetStringKey(...) As String
On Error GoTo errhandler
    ' Normal operation
    Exit Function

errhandler:
    GetStringKey = ""  ' Return default value
End Function
```

### Resource Cleanup

API functions that allocate handles must be paired with cleanup:

```vb
hRgn = CreateRectRgn(0, 0, 100, 100)
' ... use region ...
DeleteObject hRgn  ' Clean up
```

### Null Terminators

String APIs require null-terminated strings:

```vb
Value = Value & vbNullChar
RegSetValueEx ..., ByVal Value, Len(Value)
```

### Buffer Size Management

Registry reads use pre-allocated buffers:

```vb
stringbuffer = Space(255)
slength = 255
RegQueryValueEx ..., ByVal stringbuffer, slength
GetStringKey = Left(stringbuffer, slength - 1)  ' Remove null terminator
```

### Global Flag Pattern

Use global flags to prevent re-entrancy:

```vb
If MovingMe Then Exit Sub
MovingMe = True
' ... perform operation ...
MovingMe = False
```

### Optional Parameters

Use optional parameters for common defaults:

```vb
Public Sub SnapToScreen(..., Optional snapwidth As Long = 10)
```

---

## Module Dependencies

```
modAPI.bas (no dependencies)
  ├─ Used by: All modules
  │
modReg.bas (depends on modAPI)
  ├─ Used by: frmMain, mnuForm
  │
modLayered.bas (depends on modAPI)
  ├─ Used by: frmMain
  │
modAFS.bas (depends on modAPI)
  ├─ Used by: frmMain, dialog forms
  │
modWndProc.bas (depends on modAPI)
  └─ Used by: frmTray
```

---

## Security Considerations

### Privilege Requirements

- **HKCU operations:** User-level access
- **HKLM operations:** Administrator rights (AutoRun)

### Input Validation

⚠️ **Missing:** No validation on registry key names or paths

### Buffer Overflows

⚠️ **Risk:** Fixed 255-character buffers in registry reads

**Mitigation:**
- Use `RegQueryValueEx` twice (first to get size, second to read)
- Allocate dynamic buffers based on actual size

### Injection Risks

⚠️ **Risk:** Registry values used directly in code without sanitization

**Example:**
```vb
Dim path As String
path = GetStringKey(..., "Some Path")
ShellExecute ..., path, ...  ' Could execute malicious path
```

**Mitigation:**
- Validate paths before use
- Check file existence
- Verify file extensions

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
