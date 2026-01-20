# Data Structures and Storage

## Overview

This document catalogs all data types, structures, storage mechanisms, and data flow patterns used in Kafra Desktop Assistant.

## Type Definitions

### Application Types (modAPI.bas)

#### POINT_TYPE

Represents a 2D coordinate point.

```vb
Public Type POINT_TYPE
    x As Long
    y As Long
End Type
```

**Usage:**
- Cursor position tracking
- Click coordinate handling
- Geometric calculations

**Example:**
```vb
Dim pt As POINT_TYPE
GetCursorPos pt
Debug.Print "Cursor at: " & pt.x & ", " & pt.y
```

---

#### RECT

Represents a rectangle by corner coordinates.

```vb
Public Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
```

**Usage:**
- Window positioning during drag operations
- Screen snapping calculations
- Work area detection

**Coordinate System:**
- `Left` - X coordinate of left edge
- `Top` - Y coordinate of top edge
- `Right` - X coordinate of right edge (exclusive)
- `Bottom` - Y coordinate of bottom edge (exclusive)

**Width Calculation:**
```vb
Width = rect.Right - rect.Left
```

**Height Calculation:**
```vb
Height = rect.Bottom - rect.Top
```

---

#### NOTIFYICONDATA

System tray icon configuration structure.

```vb
Type NOTIFYICONDATA
    cbSize As Long              ' Size of structure
    hWnd As Long                ' Window to receive notifications
    uID As Long                 ' Icon identifier
    uFlags As Long              ' Flags for valid fields
    uCallbackMessage As Long    ' Message ID for notifications
    hIcon As Long               ' Icon handle
    szTip As String * 64        ' Tooltip text (null-terminated)
End Type
```

**Field Details:**

**cbSize:**
- Must be set to `Len(NOTIFYICONDATA)`
- Allows Windows to handle different structure versions

**hWnd:**
- Window that receives tray icon messages
- Typically frmTray.hWnd

**uID:**
- Application-defined icon identifier
- Use unique ID if multiple tray icons

**uFlags:**
- `NIF_ICON = &H2` - hIcon is valid
- `NIF_MESSAGE = &H1` - uCallbackMessage is valid
- `NIF_TIP = &H4` - szTip is valid
- Combined with `Or`

**uCallbackMessage:**
- Custom message ID for icon events
- KDA uses `PK_TRAYICON = &H401`

**hIcon:**
- Handle to icon image
- Obtain from `.Icon` property or `LoadIcon` API

**szTip:**
- Fixed-length string (64 bytes)
- Must be null-terminated
- Windows 2000+ supports 128 bytes

**Usage Example:**
```vb
With TrayData
    .cbSize = Len(TrayData)
    .hWnd = Me.hWnd
    .uID = 1
    .uFlags = NIF_ICON Or NIF_MESSAGE Or NIF_TIP
    .uCallbackMessage = PK_TRAYICON
    .hIcon = Me.Icon
    .szTip = "Desktop Kafra" & vbNullChar
End With
Shell_NotifyIcon NIM_ADD, TrayData
```

---

### Registry Types (modReg.bas)

#### SECURITY_ATTRIBUTES

Security descriptor for registry key creation.

```vb
Public Type SECURITY_ATTRIBUTES
    nLength As Long
    lpSecurityDescriptor As Long
    bInheritHandle As Long
End Type
```

**Usage:**
- Passed to `RegCreateKeyEx`
- Usually left uninitialized (defaults apply)

---

#### FILETIME

64-bit timestamp for file/registry times.

```vb
Public Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
```

**Usage:**
- Registry key modification times
- Not actively used in KDA

---

### Graphics Types (cDIBSection.cls)

#### SAFEARRAYBOUND

Describes the bounds of one dimension of an array.

```vb
Private Type SAFEARRAYBOUND
    cElements As Long
    lLbound As Long
End Type
```

---

#### SAFEARRAY2D

Descriptor for a two-dimensional safe array.

```vb
Private Type SAFEARRAY2D
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    Bounds(0 To 1) As SAFEARRAYBOUND
End Type
```

**Usage:**
- Direct memory access to DIB section bits
- Pointer manipulation for pixel-level operations

**Example:**
```vb
Dim bDib() As Byte
Dim tSA As SAFEARRAY2D

With tSA
    .cbElements = 1
    .cDims = 2
    .Bounds(0).lLbound = 0
    .Bounds(0).cElements = Height
    .Bounds(1).lLbound = 0
    .Bounds(1).cElements = BytesPerScanLine
    .pvData = m_lPtr  ' Pointer to DIB bits
End With

' Map byte array to DIB memory
CopyMemory ByVal VarPtrArray(bDib()), VarPtr(tSA), 4

' Access pixels
bDib(x, y) = 255

' Unmap array
CopyMemory ByVal VarPtrArray(bDib), 0&, 4
```

---

#### RGBQUAD

Represents a color with reserved byte.

```vb
Private Type RGBQUAD
    rgbBlue As Byte
    rgbGreen As Byte
    rgbRed As Byte
    rgbReserved As Byte
End Type
```

**Color Order:** BGR (not RGB)

---

#### BITMAPINFOHEADER

Describes dimensions and format of a DIB.

```vb
Private Type BITMAPINFOHEADER
    biSize As Long              ' 40 bytes
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer       ' Bits per pixel
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type
```

---

#### BITMAPINFO

Combined header and color palette.

```vb
Private Type BITMAPINFO
    bmiHeader As BITMAPINFOHEADER
    bmiColors As RGBQUAD
End Type
```

---

### Application-Specific Types

#### KafraAniData (frmMain)

Stores animation frame data for character blink effects.

```vb
Private Type KafraAniData
    x As Long      ' X offset in sprite sheet
    y As Long      ' Y offset in sprite sheet
    W As Long      ' Width of animation frame
    H As Long      ' Height of animation frame
End Type
```

**Array Declaration:**
```vb
Dim myKafraAniData(6) As KafraAniData  ' One per character
```

**Data Source:**
- Loaded from `ani.txt` file (if present)
- Format: `CharacterIndex,Width,Height,X,Y`

**Example `ani.txt`:**
```
1,160,190,0,0
2,160,190,160,0
3,160,190,320,0
```

**Usage:**
```vb
With myKafraAniData(Kafra)
    BitBlt destDC, 0, 0, .W, .H, srcDC, .x, .y, SRCCOPY
End With
```

---

## Storage Mechanisms

### Registry Storage

#### Application Settings

**Location:** `HKEY_CURRENT_USER\Software\EnderSoft\DesktopKafra\`

| Value Name | Type | Purpose | Example |
|------------|------|---------|---------|
| `"Current Kafra"` | DWORD | Selected character index | `0` (Blossom) |
| `"Kafra X"` | DWORD | Horizontal position in pixels | `1024` |
| `"Always On Top"` | STRING | Window z-order preference | `"Yes"` or empty |

**Access Pattern:**
```vb
' Write
SetHexKey HKEY_CURRENT_USER, _
          "Software\EnderSoft\DesktopKafra\", _
          "Kafra X", xPosition

' Read
xPosition = GetHexKey(HKEY_CURRENT_USER, _
                      "Software\EnderSoft\DesktopKafra\", _
                      "Kafra X")
```

---

#### Memo Storage

**Location:** `HKEY_CURRENT_USER\Software\EnderSoft\DesktopKafra\Memos\`

| Value Name | Type | Format |
|------------|------|--------|
| `"Memo Count"` | DWORD | Total number of saved memos |
| `"1"`, `"2"`, ... | STRING | `<date>|<time>|<content>` |

**Format Specification:**

```
<date>|<time>|<content>
MM/DD/YYYY|HH:MM:SS|Memo text content
```

**Example Values:**
```
"Memo Count" = 3

"1" = "01/20/2026|14:35:00|Remember to backup files"
"2" = "01/21/2026|09:15:30|Meeting at 3pm"
"3" = "01/22/2026|17:45:10|Check email"
```

**Code Pattern:**

**Writing a Memo:**
```vb
Dim memoCount As Long
Dim memoIndex As Long
Dim memoData As String

memoCount = GetHexKey(HKEY_CURRENT_USER, _
                      "Software\EnderSoft\DesktopKafra\Memos\", _
                      "Memo Count")

memoIndex = memoCount + 1
memoData = Date$ & "|" & Time$ & "|" & txtMemo.Text

SetStringKey HKEY_CURRENT_USER, _
             "Software\EnderSoft\DesktopKafra\Memos\", _
             CStr(memoIndex), _
             memoData

SetHexKey HKEY_CURRENT_USER, _
          "Software\EnderSoft\DesktopKafra\Memos\", _
          "Memo Count", _
          memoIndex
```

**Reading a Memo:**
```vb
Dim memoData As String
Dim parts() As String

memoData = GetStringKey(HKEY_CURRENT_USER, _
                        "Software\EnderSoft\DesktopKafra\Memos\", _
                        CStr(memoIndex))

If memoData <> "" Then
    parts = Split(memoData, "|")
    If UBound(parts) >= 2 Then
        memoDate = parts(0)
        memoTime = parts(1)
        memoContent = parts(2)
    End If
End If
```

---

#### Autorun Configuration

**Location:** `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\`

| Value Name | Type | Content |
|------------|------|---------|
| `"Desktop Kafra"` | STRING | Full path to executable |

**Example:**
```
"Desktop Kafra" = "C:\Program Files\KafraDesk\KafraDesk.exe"
```

**Security Note:** Requires administrator privileges to write to HKLM.

---

### File System Storage

#### Storage Directory

**Location:** `<Application Path>\Storage\`

**Purpose:**
- User-organized file storage
- Drag-and-drop destination
- Browsable via ListView in frmPopup

**Structure:**
```
<App.Path>\
  ├─ KafraDesk.exe
  ├─ Cursors\
  │   └─ [cursor files]
  └─ Storage\
      ├─ [user files]
      └─ [user folders]
```

**Creation:**
```vb
If Dir(App.path & "\Storage", vbDirectory) = "" Then
    MkDir App.path & "\Storage"
End If
```

**File Operations:**
```vb
Dim fso As New FileSystemObject

' Move file
fso.MoveFile sourceFile, curPath & "\" & fso.GetFileName(sourceFile)

' Move folder
fso.MoveFolder sourceFolder, curPath & "\" & fso.GetFolderName(sourceFolder)
```

---

#### Cursor Files

**Location:** `<Application Path>\Cursors\`

**Required Files:**

| File | Type | Purpose |
|------|------|---------|
| `rag_cur.ani` | Animated | Default pointer |
| `handopen.cur` | Static | Open hand (hover) |
| `handclosed.cur` | Static | Closed hand (drag) |
| `rag_target.ani` | Animated | Target cursor (drop) |

**Optional Files:**
- `rag_attack.cur`
- `rag_click.cur`
- `rag_deny.cur`
- `rag_door.ani`
- `hand.ico`
- `kafra.ico`

**Loading:**
```vb
hcurPointer = LoadCursorFromFile(App.path & "\Cursors\rag_cur.ani")
```

---

#### Animation Data File

**Location:** `<Application Path>\ani.txt`

**Purpose:** Defines blink animation frame coordinates for each character.

**Format:**
```
<CharacterIndex>,<Width>,<Height>,<X>,<Y>
```

**Example:**
```
1,160,190,0,0
2,160,190,160,0
3,160,190,320,0
4,160,190,480,0
5,160,190,640,0
6,160,190,800,0
7,160,190,960,0
```

**Parsing Code:**
```vb
If Dir(App.path & "\ani.txt") <> "" Then
    Open App.path & "\ani.txt" For Input As 1
    While Not EOF(1)
        Line Input #1, tempstr
        With myKafraAniData(Split(tempstr, ",")(0) - 1)
            .W = Split(tempstr, ",")(1)
            .H = Split(tempstr, ",")(2)
            .x = Split(tempstr, ",")(3)
            .y = Split(tempstr, ",")(4)
        End With
    Wend
    Close 1
End If
```

---

### Resource File Storage

#### Resource Structure

**Files:**
- `orig.res` - Original edition resources
- `sakura.res` - Sakura edition resources

**Resource Types:**

| Type | ID Range | Content |
|------|----------|---------|
| **String Table** | 101-107 | Kafra character names |
| **Bitmap** | 111-117 | Character images (24-bit BMP) |
| **RCDATA** | 101-107 | Pre-compiled region data (.rgn) |
| **Icon** | Various | Application icons |

**Resource ID Formula:**

For character index `i` (0-6):
- **Name String:** `101 + i`
- **Image Bitmap:** `111 + i`
- **Region Data:** `101 + i`

**Loading Resources:**

**String:**
```vb
KafraName = LoadResString(Kafra + 101)
```

**Bitmap:**
```vb
Set picKafra = LoadResPicture(Kafra + 111, vbResBitmap)
```

**Region Data:**
```vb
myRGN.LoadFromResource Kafra + 101
```

---

#### Region File Format

**File Extension:** `.rgn`

**Format:** Binary region data as returned by `GetRegionData` API.

**Structure:**
```
RGNDATAHEADER
  ├─ dwSize (32 bytes)
  ├─ iType (RDH_RECTANGLES = 1)
  ├─ nCount (number of rectangles)
  ├─ nRgnSize (size of rectangle buffer)
  └─ rcBound (bounding rectangle)

RECT array [nCount]
  ├─ RECT 1
  ├─ RECT 2
  └─ ...
```

**Creation Process:**
1. Load character bitmap
2. Create DIB section
3. Scan pixels for transparency color
4. Build region by combining rectangles
5. Call `GetRegionData` to serialize
6. Save binary data to `.rgn` file
7. Compile into resource file

**Loading:**
```vb
Public Function LoadFromResource(ByVal vID As Variant, _
                                Optional ByVal sDLL As String = "") As Boolean
    Dim b() As Byte
    
    If sDLL = "" Then
        b = LoadResData(vID, 10)  ' RT_RCDATA
        LoadFromResource = pbLoadFromByteArray(b())
    End If
End Function

Private Function pbLoadFromByteArray(ByRef b() As Byte) As Boolean
    Dim dwCount As Long
    
    dwCount = UBound(b) - LBound(b) + 1
    m_hRgn = ExtCreateRegion(ByVal 0&, dwCount, b(0))
    pbLoadFromByteArray = Not (m_hRgn = 0)
End Function
```

---

## Data Flow Diagrams

### Application Startup Data Flow

```
[Registry] ──────────────────┐
  ├─ Position               │
  ├─ Selected Kafra         │
  └─ Preferences            │
                            ▼
[Form_Load] ────────> [Read Settings]
                            │
[Resource File] ────────────┼──> [Load Character Data]
  ├─ Bitmap                 │      ├─ Name string
  ├─ Region                 │      ├─ Bitmap image
  └─ Strings                │      └─ Region shape
                            ▼
                      [Render Form]
                            │
                            ▼
                      [Show Application]
```

### Memo Save Data Flow

```
[User Input] ──> [RichTextBox]
                       │
                       ▼
                 [Generate Memo]
                   Date & Time
                       │
                       ▼
                 [Format String]
              "MM/DD/YYYY|HH:MM:SS|Content"
                       │
                       ▼
                [Get Memo Count] <─── [Registry]
                       │
                       ▼
               [Increment Index]
                       │
                       ▼
              [Write to Registry]
       "Memos\<index>" = formatted string
                       │
                       ▼
           [Update Memo Count] ──> [Registry]
```

### File Drop Data Flow

```
[User Drags Files] ──> [OLE Drag Over]
                            │
                            ▼
                   [Change Cursor to Target]
                            │
                            ▼
                      [User Drops]
                            │
                            ▼
                  [Form_OLEDragDrop Event]
                            │
                            ▼
                 [Enumerate Data.Files]
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
          [Is Directory?]          [Is File?]
                │                       │
                ▼                       ▼
         [MoveFolder]            [MoveFile]
                │                       │
                └───────────┬───────────┘
                            ▼
                   [Update ListView]
                            │
                            ▼
                  [File System Storage]
```

---

## Memory Management

### DIB Section Lifecycle

```vb
' 1. Creation
Dim myDIB As New cDIBSection
myDIB.Create lWidth, lHeight

' 2. Usage
myDIB.LoadPictureBlt hDC
myDIB.PaintPicture destDC

' 3. Cleanup
myDIB.ClearUp
Set myDIB = Nothing  ' Implicit cleanup in Class_Terminate
```

### Region Lifecycle

```vb
' 1. Creation
Dim myRGN As New cDIBSectionRegion
myRGN.LoadFromResource resID

' 2. Application
myRGN.Applied(Form.hWnd) = True

' 3. Cleanup
myRGN.Destroy  ' Removes region from windows
Set myRGN = Nothing
```

### Handle Management

⚠️ **Critical:** Windows handles must be explicitly freed.

**GDI Objects:**
```vb
hBrush = CreateSolidBrush(RGB(255, 0, 0))
' ... use brush ...
DeleteObject hBrush  ' Must delete
```

**Region Handles:**
```vb
hRgn = CreateRectRgn(0, 0, 100, 100)
SetWindowRgn hWnd, hRgn, True  ' System takes ownership
' Do NOT call DeleteObject(hRgn)
```

**Cursor Handles:**
```vb
hCursor = LoadCursorFromFile(path)
' ... use cursor ...
' Do NOT call DestroyCursor for cursors loaded from file
```

---

## Data Validation

### Registry Data

⚠️ **No validation** is performed on registry reads. Potential issues:

**Missing Values:**
```vb
xPos = GetHexKey(...)  ' Returns 0 if missing
If xPos = 0 Then xPos = Screen.Width - Form.Width
```

**Corrupted Memo Format:**
```vb
memoData = GetStringKey(...)
parts = Split(memoData, "|")
If UBound(parts) < 2 Then
    ' Handle invalid format
End If
```

**Invalid Paths:**
```vb
Dim path As String
path = GetStringKey(..., "Some Path")
If Dir$(path) = "" Then
    ' Path doesn't exist
End If
```

### File System Data

**File Type Validation:**
```vb
' Check if file before attempting file operation
If (GetAttr(path) And vbDirectory) = 0 Then
    ' It's a file
Else
    ' It's a directory
End If
```

**Path Validation:**
```vb
' No validation - ShellExecute will fail safely
ShellExecute 0, "open", filePath, "", "", SW_NORMAL
```

---

## Data Persistence Guarantees

### When Data is Saved

| Event | Data Saved | Location |
|-------|------------|----------|
| **Form Unload** | Final window position | Registry |
| **Dragging End** | Current position | Registry |
| **Character Switch** | Selected character | Registry |
| **Memo Save** | Memo content + metadata | Registry |
| **Always On Top Toggle** | Preference | Registry |
| **Autorun Toggle** | Executable path | Registry (HKLM) |

### When Data is Lost

⚠️ **Scenarios:**

1. **Crash during memo write:** Incomplete memo may be written
2. **Power loss:** In-memory changes not yet saved
3. **Registry access denied:** Settings not persisted
4. **Drag without release:** Position not saved until WM_EXITSIZEMOVE

### Data Recovery

**No automatic recovery mechanisms.** Recommendations:

- Implement periodic auto-save for memos
- Use transaction-based registry writes
- Add backup/export functionality
- Validate data on read

---

## Storage Limitations

### Registry

- **Value size limit:** ~1 MB (Windows varies)
- **Key depth limit:** 512 levels
- **String length:** Practical limit ~16,000 characters
- **Performance:** Slow for large datasets

### File System

- **Path length:** 260 characters (MAX_PATH)
- **Filename characters:** Cannot contain `\ / : * ? " < > |`
- **Storage space:** Limited by disk

### Memory

- **VB6 string limit:** ~2 GB (theoretical), practical limit much lower
- **DIB section size:** Limited by available GDI resources
- **Control count:** ~256 per form (VB6 limitation)

---

## Cross-Platform Considerations

### Windows-Specific Structures

All storage mechanisms are Windows-specific:

- **Registry:** No equivalent on Linux/macOS
- **Resource files:** PE format, Windows-only
- **GDI structures:** Direct mapping to Windows APIs

### Migration Strategy

For cross-platform ports, replace with:

| Windows Component | Linux Alternative | macOS Alternative |
|-------------------|-------------------|-------------------|
| Registry | INI files, SQLite, JSON | plist files, JSON |
| .res files | Embedded resources | Asset catalog |
| GDI bitmaps | Cairo, Pixbuf | CoreGraphics |
| System tray | StatusNotifierItem | NSStatusItem |

See [Migration Guide](../migration/overview.md) for detailed porting strategies.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
