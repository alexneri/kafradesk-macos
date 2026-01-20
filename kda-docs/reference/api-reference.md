# Windows API Reference

## Overview

This document catalogs all Windows API functions used by Kafra Desktop Assistant, organized by functional area. These declarations are primarily located in `modAPI.bas`.

## Graphics Device Interface (GDI32.DLL)

### GetPixel

Retrieves the RGB color value of a pixel at specified coordinates.

```vb
Public Declare Function GetPixel Lib "gdi32" ( _
    ByVal hdc As Long, _
    ByVal x As Long, _
    ByVal y As Long _
) As Long
```

**Parameters:**
- `hdc` - Handle to device context
- `x` - X-coordinate in logical units
- `y` - Y-coordinate in logical units

**Returns:** RGB color value

**Usage:** Used in region creation to detect transparent pixels.

---

### CreateRectRgn

Creates a rectangular region.

```vb
Public Declare Function CreateRectRgn Lib "gdi32" ( _
    ByVal X1 As Long, _
    ByVal Y1 As Long, _
    ByVal X2 As Long, _
    ByVal Y2 As Long _
) As Long
```

**Parameters:**
- `X1`, `Y1` - Upper-left corner coordinates
- `X2`, `Y2` - Lower-right corner coordinates

**Returns:** Handle to region (HRGN) or 0 on failure

**Usage:** Creates base region for form shaping and removal of transparent areas.

---

### CombineRgn

Combines two regions using specified mode.

```vb
Public Declare Function CombineRgn Lib "gdi32" ( _
    ByVal hDestRgn As Long, _
    ByVal hSrcRgn1 As Long, _
    ByVal hSrcRgn2 As Long, _
    ByVal nCombineMode As Long _
) As Long
```

**Parameters:**
- `hDestRgn` - Handle to destination region
- `hSrcRgn1` - Handle to first source region
- `hSrcRgn2` - Handle to second source region
- `nCombineMode` - Combination mode:
  - `RGN_AND = 1` - Intersection
  - `RGN_OR = 2` - Union
  - `RGN_XOR = 3` - Exclusive OR
  - `RGN_DIFF = 4` - Difference (src1 - src2)
  - `RGN_COPY = 5` - Copy src1 to destination

**Returns:** Result type (ERROR, NULLREGION, SIMPLEREGION, COMPLEXREGION)

**Usage:** Build complex form shapes by combining/subtracting regions.

---

### DeleteObject

Deletes a logical GDI object.

```vb
Public Declare Function DeleteObject Lib "gdi32" ( _
    ByVal hObject As Long _
) As Long
```

**Parameters:**
- `hObject` - Handle to object (pen, brush, font, bitmap, region, palette)

**Returns:** Non-zero on success

⚠️ **Critical:** Must be called to prevent resource leaks. Do not delete objects currently selected into a DC.

---

### BitBlt

Performs bit-block transfer of color data.

```vb
Public Declare Function BitBlt Lib "gdi32" ( _
    ByVal hDestDC As Long, _
    ByVal x As Long, _
    ByVal y As Long, _
    ByVal nWidth As Long, _
    ByVal nHeight As Long, _
    ByVal hSrcDC As Long, _
    ByVal xSrc As Long, _
    ByVal ySrc As Long, _
    ByVal dwRop As Long _
) As Long
```

**Parameters:**
- `hDestDC` - Destination device context
- `x`, `y` - Destination upper-left corner
- `nWidth`, `nHeight` - Rectangle dimensions
- `hSrcDC` - Source device context
- `xSrc`, `ySrc` - Source upper-left corner
- `dwRop` - Raster operation code

**Common Raster Operations:**
- `SRCCOPY = &HCC0020` - Copy source to destination
- `SRCPAINT = &HEE0086` - OR source with destination
- `SRCAND = &H8800C6` - AND source with destination

**Usage:** Fast bitmap copying and blitting operations.

---

### GetRegionData

Retrieves data describing a region.

```vb
Private Declare Function GetRegionData Lib "gdi32" ( _
    ByVal hRgn As Long, _
    ByVal dwCount As Long, _
    lpRgnData As Any _
) As Long
```

**Returns:** Size of data in bytes, or 0 on error

**Usage:** Serialize region for saving to .rgn files.

---

### ExtCreateRegion

Creates region from region data.

```vb
Private Declare Function ExtCreateRegion Lib "gdi32" ( _
    lpXform As Any, _
    ByVal nCount As Long, _
    lpRgnData As Any _
) As Long
```

**Usage:** Deserialize region from .rgn resource files.

---

## User Interface (USER32.DLL)

### SetWindowRgn

Sets the window region for non-rectangular windows.

```vb
Public Declare Function SetWindowRgn Lib "user32" ( _
    ByVal hWnd As Long, _
    ByVal hRgn As Long, _
    ByVal bRedraw As Boolean _
) As Long
```

**Parameters:**
- `hWnd` - Window handle
- `hRgn` - Region handle (system takes ownership)
- `bRedraw` - TRUE to redraw immediately

**Returns:** Non-zero on success

⚠️ **Important:** System takes ownership of region handle; do not delete it afterward.

**Usage:** Apply shaped form appearance to windows.

---

### ReleaseCapture

Releases mouse capture.

```vb
Public Declare Sub ReleaseCapture Lib "user32" ()
```

**Usage:** Called before `WM_SYSCOMMAND`/`SC_CLICKMOVE` to enable form dragging.

---

### SendMessage

Sends a message to a window procedure.

```vb
Public Declare Function SendMessage Lib "user32" Alias "SendMessageA" ( _
    ByVal hWnd As Long, _
    ByVal wMsg As Long, _
    ByVal wParam As Long, _
    lParam As Any _
) As Long
```

**Parameters:**
- `hWnd` - Target window handle
- `wMsg` - Message identifier
- `wParam` - First message parameter
- `lParam` - Second message parameter

**Returns:** Result depends on message sent

**Usage:** Direct window communication, form dragging, custom control operations.

---

### CallWindowProc

Passes message to previous window procedure.

```vb
Public Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" ( _
    ByVal lpPrevWndFunc As Long, _
    ByVal hWnd As Long, _
    ByVal Msg As Long, _
    ByVal wParam As Long, _
    ByVal lParam As Long _
) As Long
```

**Usage:** Forward messages to original WndProc during subclassing.

---

### SetWindowLong

Changes window attribute.

```vb
Public Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" ( _
    ByVal hWnd As Long, _
    ByVal nIndex As Long, _
    ByVal dwNewLong As Long _
) As Long
```

**Parameters:**
- `hWnd` - Window handle
- `nIndex` - Index of value to change:
  - `GWL_WNDPROC = -4` - Window procedure address
  - `GWL_STYLE = -16` - Window style
  - `GWL_EXSTYLE = -20` - Extended window style
- `dwNewLong` - New value

**Returns:** Previous value

**Usage:** Install subclass window procedure, modify window styles.

⚠️ **Critical:** Changing `GWL_WNDPROC` requires careful cleanup to avoid crashes.

---

### SetClassLong

Changes class attribute.

```vb
Public Declare Function SetClassLong Lib "user32" Alias "SetClassLongA" ( _
    ByVal hWnd As Long, _
    ByVal nIndex As Long, _
    ByVal dwNewLong As Long _
) As Long
```

**Parameters:**
- `nIndex` constants:
  - `GCL_HCURSOR = -12` - Cursor handle

**Usage:** Change window class cursor.

---

### SetWindowPos

Changes window size, position, and Z-order.

```vb
Public Declare Sub SetWindowPos Lib "user32" ( _
    ByVal hWnd As Long, _
    ByVal hWndInsertAfter As Long, _
    ByVal x As Long, _
    ByVal y As Long, _
    ByVal cx As Long, _
    ByVal cy As Long, _
    ByVal wFlags As Long _
)
```

**Parameters:**
- `hWndInsertAfter`:
  - `HWND_TOPMOST = -1` - Always on top
  - `HWND_NOTOPMOST = -2` - Normal Z-order
- `wFlags`:
  - `SWP_NOACTIVATE = &H10` - Don't activate window
  - `SWP_SHOWWINDOW = &H40` - Display window

**Usage:** Implement "Always On Top" feature.

---

### LoadCursorFromFile

Loads cursor from .cur or .ani file.

```vb
Public Declare Function LoadCursorFromFile Lib "user32.dll" Alias "LoadCursorFromFileA" ( _
    ByVal lpFileName As String _
) As Long
```

**Returns:** Cursor handle or 0 on failure

**Usage:** Load custom Ragnarok cursors from `\Cursors` folder.

---

### SetCursor

Sets the cursor shape.

```vb
Public Declare Function SetCursor Lib "user32.dll" ( _
    ByVal hCursor As Long _
) As Long
```

**Returns:** Previous cursor handle

**Usage:** Change cursor during mouse hover events.

---

### SystemParametersInfo

Retrieves or sets system-wide parameters.

```vb
Public Declare Function SystemParametersInfo Lib "user32.dll" Alias "SystemParametersInfoA" ( _
    ByVal uAction As Long, _
    ByVal uiParam As Long, _
    pvParam As Any, _
    ByVal fWinIni As Long _
) As Long
```

**Parameters:**
- `uAction = 48` (SPI_GETWORKAREA) - Get work area rect

**Usage:** Determine taskbar height for form positioning.

---

### GetCursorPos

Retrieves cursor position in screen coordinates.

```vb
Public Declare Function GetCursorPos Lib "user32.dll" ( _
    lpPoint As POINT_TYPE _
) As Long
```

**Usage:** Track mouse position during dragging operations.

---

### SetLayeredWindowAttributes

Sets transparency and color key for layered windows (Windows 2000+).

```vb
Private Declare Function SetLayeredWindowAttributes Lib "user32" ( _
    ByVal hWnd As Long, _
    ByVal crKey As Long, _
    ByVal bAlpha As Byte, _
    ByVal dwFlags As Long _
) As Long
```

**Parameters:**
- `crKey` - Color key for transparency (RGB value)
- `bAlpha` - Alpha blend value (0-255)
- `dwFlags`:
  - `LWA_COLORKEY = &H1` - Use color key
  - `LWA_ALPHA = &H2` - Use alpha value

**Requires:** `WS_EX_LAYERED` extended window style.

**Usage:** Implement fade in/out effects, semi-transparency.

---

## Kernel Services (KERNEL32.DLL)

### Sleep

Suspends execution for specified milliseconds.

```vb
Public Declare Sub Sleep Lib "kernel32" ( _
    ByVal dwMilliseconds As Long _
)
```

**Usage:** Animation delays, throttling.

⚠️ **Note:** Blocks UI thread; use sparingly.

---

### GetVersionEx

Retrieves OS version information.

```vb
Private Declare Function GetVersionEx Lib "kernel32.dll" Alias "GetVersionExA" ( _
    lpVersionInformation As OSVERSIONINFO _
) As Long
```

**Type:**
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

**Usage:** Detect Windows 2000/XP for transparency features.

---

### LoadLibraryEx

Loads a module with specified flags.

```vb
Private Declare Function LoadLibraryEx Lib "kernel32" Alias "LoadLibraryExA" ( _
    ByVal lpLibFileName As String, _
    ByVal hFile As Long, _
    ByVal dwFlags As Long _
) As Long
```

**Flags:**
- `LOAD_LIBRARY_AS_DATAFILE = &H2` - Load for resource access only

**Usage:** Load resources from external DLLs/RES files.

---

### CopyMemory (RtlMoveMemory)

Copies block of memory.

```vb
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
    lpvDest As Any, _
    lpvSource As Any, _
    ByVal cbCopy As Long _
)
```

**Usage:** Low-level memory operations, array manipulation, thunk patching.

⚠️ **Danger:** Can cause crashes if misused. Verify buffer sizes carefully.

---

## Shell Integration (SHELL32.DLL)

### ShellExecute

Executes an operation on a file.

```vb
Public Declare Function ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" ( _
    ByVal hWnd As Long, _
    ByVal lpOperation As String, _
    ByVal lpFile As String, _
    ByVal lpParameters As String, _
    ByVal lpDirectory As String, _
    ByVal nShowCmd As Long _
) As Long
```

**Parameters:**
- `lpOperation` - "open", "edit", "print", "explore"
- `lpFile` - File or URL to execute
- `nShowCmd` - Show window flags (SW_NORMAL, SW_HIDE, etc.)

**Returns:** > 32 on success, error code otherwise

**Usage:** Open files from storage folder, launch associated applications.

---

### Shell_NotifyIcon

Adds, modifies, or deletes system tray icon.

```vb
Public Declare Function Shell_NotifyIcon Lib "shell32.dll" Alias "Shell_NotifyIconA" ( _
    ByVal dwMessage As Long, _
    lpData As NOTIFYICONDATA _
) As Long
```

**Messages:**
- `NIM_ADD = &H0` - Add icon
- `NIM_MODIFY = &H1` - Modify icon
- `NIM_DELETE = &H2` - Remove icon

**Type:**
```vb
Type NOTIFYICONDATA
    cbSize As Long
    hWnd As Long
    uID As Long
    uFlags As Long
    uCallbackMessage As Long
    hIcon As Long
    szTip As String * 64
End Type
```

**Flags:**
- `NIF_ICON = &H2` - Icon is valid
- `NIF_MESSAGE = &H1` - Message is valid
- `NIF_TIP = &H4` - Tooltip is valid

**Usage:** Create Kafra tray icon, handle tray notifications.

---

## Registry Access (ADVAPI32.DLL)

### RegCreateKeyEx

Creates or opens a registry key.

```vb
Public Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias "RegCreateKeyExA" ( _
    ByVal hkey As Long, _
    ByVal lpSubKey As String, _
    ByVal Reserved As Long, _
    ByVal lpClass As String, _
    ByVal dwOptions As Long, _
    ByVal samDesired As Long, _
    lpSecurityAttributes As SECURITY_ATTRIBUTES, _
    phkResult As Long, _
    lpdwDisposition As Long _
) As Long
```

**Root Keys:**
- `HKEY_CURRENT_USER = &H80000001`
- `HKEY_LOCAL_MACHINE = &H80000002`

**Access Rights:**
- `KEY_READ = &H20019`
- `KEY_WRITE = &H20006`
- `KEY_ALL_ACCESS = &HF003F`

**Usage:** Create application registry keys for settings.

---

### RegSetValueEx

Sets registry value data.

```vb
Public Declare Function RegSetValueEx Lib "advapi32.dll" Alias "RegSetValueExA" ( _
    ByVal hkey As Long, _
    ByVal lpValueName As String, _
    ByVal Reserved As Long, _
    ByVal dwType As Long, _
    lpData As Any, _
    ByVal cbData As Long _
) As Long
```

**Value Types:**
- `REG_SZ = 1` - String
- `REG_DWORD = 4` - 32-bit number
- `REG_BINARY = 3` - Binary data

**Usage:** Save application settings (position, preferences).

---

### RegQueryValueEx

Retrieves registry value data.

```vb
Public Declare Function RegQueryValueEx Lib "advapi32.dll" Alias "RegQueryValueExA" ( _
    ByVal hkey As Long, _
    ByVal lpValueName As String, _
    ByVal lpReserved As Long, _
    lpType As Long, _
    lpData As Any, _
    lpcbData As Long _
) As Long
```

**Usage:** Read saved settings on startup.

---

### RegCloseKey

Closes registry key handle.

```vb
Public Declare Function RegCloseKey Lib "advapi32.dll" ( _
    ByVal hkey As Long _
) As Long
```

⚠️ **Critical:** Always close registry handles to prevent leaks.

---

### RegDeleteValue

Removes a value from registry key.

```vb
Public Declare Function RegDeleteValue Lib "advapi32.dll" Alias "RegDeleteValueA" ( _
    ByVal hkey As Long, _
    ByVal lpValueName As String _
) As Long
```

**Usage:** Remove autorun entry when disabled.

---

## Window Messages

### System Commands

```vb
Public Const WM_SYSCOMMAND = &H112
Public Const SC_CLICKMOVE = &HF012  ' Drag window with mouse
```

**Usage:**
```vb
ReleaseCapture
SendMessage Me.hWnd, WM_SYSCOMMAND, SC_CLICKMOVE, 0
```

### Mouse Messages

```vb
Public Const WM_LBUTTONDOWN = &H201
Public Const WM_LBUTTONUP = &H202
Public Const WM_LBUTTONDBLCLK = &H203
Public Const WM_RBUTTONDOWN = &H204
Public Const WM_RBUTTONUP = &H205
Public Const WM_RBUTTONDBLCLK = &H206
```

### Window State Messages

```vb
Public Const WM_WINDOWPOSCHANGING = &H46
Public Const WM_WINDOWPOSCHANGED = &H47
Public Const WM_CLOSE = &H10
```

### Custom Messages

```vb
Public Const PK_TRAYICON = &H401  ' Tray icon callback message
```

**Handler in `modWndProc.bas`:**
```vb
Case PK_TRAYICON
    Select Case lParam
        Case WM_RBUTTONUP
            ' Show context menu
        Case WM_LBUTTONDBLCLK
            ' Toggle visibility
    End Select
```

## Types and Structures

### POINT_TYPE

```vb
Public Type POINT_TYPE
    x As Long
    y As Long
End Type
```

### RECT

```vb
Public Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
```

### NOTIFYICONDATA

```vb
Type NOTIFYICONDATA
    cbSize As Long              ' Structure size
    hWnd As Long                ' Window handle for notifications
    uID As Long                 ' Application-defined icon ID
    uFlags As Long              ' Valid fields mask
    uCallbackMessage As Long    ' Message for icon events
    hIcon As Long               ' Icon handle
    szTip As String * 64        ' Tooltip text
End Type
```

## Error Handling

Most API functions return:
- **Non-zero** on success
- **Zero** on failure

Always check return values:

```vb
Dim hRgn As Long
hRgn = CreateRectRgn(0, 0, 100, 100)
If hRgn = 0 Then
    ' Handle error
    Exit Function
End If
' Use hRgn...
DeleteObject hRgn
```

## Common API Patterns

### Resource Management Pattern

```vb
' Create resource
Dim hObj As Long
hObj = CreateResource(...)
If hObj = 0 Then Exit Function

' Use resource
DoSomethingWith hObj

' Cleanup (even on error)
DeleteObject hObj
```

### Subclassing Pattern

```vb
' Save original procedure
pOldProc = SetWindowLong(hWnd, GWL_WNDPROC, AddressOf NewProc)

' In NewProc, forward unhandled messages
WindowProc = CallWindowProc(pOldProc, hWnd, uMsg, wParam, lParam)

' Restore on cleanup
SetWindowLong hWnd, GWL_WNDPROC, pOldProc
```

### Registry Access Pattern

```vb
Dim hKey As Long
Dim retval As Long

' Open/create key
retval = RegCreateKeyEx(HKEY_CURRENT_USER, "Software\MyApp", ...)
If retval <> 0 Then Exit Function

' Read/write values
retval = RegSetValueEx(hKey, "Setting", 0, REG_SZ, value, Len(value))

' Always close
RegCloseKey hKey
```

## Platform Compatibility Notes

| API Function | Win 95/98/ME | Win NT/2000/XP | Notes |
|--------------|--------------|----------------|-------|
| SetWindowRgn | ✅ | ✅ | Full support |
| SetLayeredWindowAttributes | ❌ | ✅ | Windows 2000+ only |
| Shell_NotifyIcon | ✅ | ✅ | Tooltip limited to 64 chars on Win9x |
| Registry APIs | ✅ | ✅ | UNICODE variants preferred on NT |

## Security Considerations

### API Risks

1. **Buffer Overflows:** Fixed-size string buffers in registry operations
2. **Code Injection:** `SetWindowLong(GWL_WNDPROC)` allows arbitrary code execution
3. **Resource Exhaustion:** GDI object leaks can crash system
4. **Privilege Escalation:** HKLM writes require admin rights

### Mitigation Strategies

- Validate all string lengths before API calls
- Always pair Create/Delete operations
- Use structured error handling (`On Error GoTo`)
- Check return values for all API calls
- Implement proper cleanup in `Class_Terminate` and `Form_Unload`

## References

- Microsoft Platform SDK Documentation
- [vbAccelerator](http://vbaccelerator.com/) - Advanced VB6 API techniques
- MSDN Archive - Visual Basic 6.0 API documentation

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
