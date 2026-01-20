# Classes Reference

## Overview

This document provides detailed documentation for all VB6 class modules (`.cls` files) in Kafra Desktop Assistant. Classes encapsulate complex functionality with proper lifetime management.

## Class Catalog

| Class | Purpose | Cleanup Required |
|-------|---------|------------------|
| **cDIBSection** | Device Independent Bitmap management | Yes - `ClearUp` |
| **cDIBSectionRegion** | Form region creation from bitmaps | Yes - `Destroy` |
| **cSubclass** | IDE-safe window subclassing | Yes - `UnSubclass` |
| **cWindow** | API window creation and management | Automatic |

---

## cDIBSection

**File:** `cDIBSection.cls`  
**Author:** Steve McMahon (vbAccelerator.com)  
**Purpose:** Wrapper around Windows DIB Section for direct pixel manipulation

### Overview

A DIB (Device Independent Bitmap) Section provides direct memory access to bitmap data, enabling fast pixel-level operations. This class abstracts the complex API calls and memory management required.

### Class Variables

```vb
Private m_hDIb As Long          ' Handle to DIB section
Private m_hBmpOld As Long       ' Previous bitmap in DC
Private m_hDC As Long           ' Device context handle
Private m_lPtr As Long          ' Pointer to bitmap bits
Private m_tBI As BITMAPINFO     ' Bitmap information structure
```

### Properties

#### Width

Returns bitmap width in pixels.

```vb
Public Property Get Width() As Long
    Width = m_tBI.bmiHeader.biWidth
End Property
```

#### Height

Returns bitmap height in pixels.

```vb
Public Property Get Height() As Long
    Height = m_tBI.bmiHeader.biHeight
End Property
```

#### BytesPerScanLine

Returns bytes per horizontal scan line (aligned to DWORD boundary).

```vb
Public Property Get BytesPerScanLine() As Long
    BytesPerScanLine = (m_tBI.bmiHeader.biWidth * 3 + 3) And &HFFFFFFFC
End Property
```

**Note:** Scan lines must be DWORD-aligned (multiples of 4 bytes).

#### hdc

Returns device context handle for GDI operations.

```vb
Public Property Get hdc() As Long
    hdc = m_hDC
End Property
```

#### hDib

Returns DIB section handle.

```vb
Public Property Get hDib() As Long
    hDib = m_hDIb
End Property
```

#### DIBSectionBitsPtr

Returns pointer to bitmap bits in memory.

```vb
Public Property Get DIBSectionBitsPtr() As Long
    DIBSectionBitsPtr = m_lPtr
End Property
```

### Public Methods

#### Create

Creates a new DIB section with specified dimensions.

**Signature:**
```vb
Public Function Create( _
    ByVal lWidth As Long, _
    ByVal lHeight As Long _
) As Boolean
```

**Parameters:**
- `lWidth` - Bitmap width in pixels
- `lHeight` - Bitmap height in pixels

**Returns:** True on success, False on failure

**Process:**
1. Clear any existing DIB
2. Create compatible DC
3. Create DIB section (24-bit RGB)
4. Select DIB into DC
5. Store old bitmap handle for cleanup

**Usage:**
```vb
Dim myDIB As New cDIBSection
If myDIB.Create(200, 300) Then
    ' Use DIB
    myDIB.ClearUp
End If
```

---

#### CreateFromPicture

Creates DIB section from a VB Picture object.

**Signature:**
```vb
Public Function CreateFromPicture( _
    ByRef picThis As StdPicture _
)
```

**Parameters:**
- `picThis` - VB Picture object (from Image, PictureBox, or LoadResPicture)

**Process:**
1. Get bitmap dimensions using `GetObjectAPI`
2. Create DIB section of same size
3. Create temporary DC
4. Select source bitmap into temp DC
5. BitBlt from temp DC to DIB section
6. Cleanup temp DC

**Usage:**
```vb
Dim myDIB As New cDIBSection
myDIB.CreateFromPicture frmMain.Picture
```

---

#### LoadPictureBlt

Copies a bitmap into the DIB section using BitBlt.

**Signature:**
```vb
Public Sub LoadPictureBlt( _
    ByVal lhDC As Long, _
    Optional ByVal lSrcLeft As Long = 0, _
    Optional ByVal lSrcTop As Long = 0, _
    Optional ByVal lSrcWidth As Long = -1, _
    Optional ByVal lSrcHeight As Long = -1, _
    Optional ByVal eRop As RasterOpConstants = vbSrcCopy _
)
```

**Parameters:**
- `lhDC` - Source device context
- `lSrcLeft`, `lSrcTop` - Source position (default 0,0)
- `lSrcWidth`, `lSrcHeight` - Source dimensions (default full DIB)
- `eRop` - Raster operation (default SRCCOPY)

**Common Raster Operations:**
- `vbSrcCopy` - Direct copy
- `vbSrcAnd` - AND source with destination
- `vbSrcOr` - OR source with destination

---

#### PaintPicture

Paints the DIB section to a device context.

**Signature:**
```vb
Public Sub PaintPicture( _
    ByVal lhDC As Long, _
    Optional ByVal lDestLeft As Long = 0, _
    Optional ByVal lDestTop As Long = 0, _
    Optional ByVal lDestWidth As Long = -1, _
    Optional ByVal lDestHeight As Long = -1, _
    Optional ByVal lSrcLeft As Long = 0, _
    Optional ByVal lSrcTop As Long = 0, _
    Optional ByVal eRop As RasterOpConstants = vbSrcCopy _
)
```

**Usage:**
```vb
' Paint to form
myDIB.PaintPicture Me.hdc, 0, 0

' Paint scaled
myDIB.PaintPicture Me.hdc, 0, 0, 100, 100
```

---

#### RandomiseBits

Fills DIB with random pixels (for testing).

**Signature:**
```vb
Public Sub RandomiseBits( _
    Optional ByVal bGray As Boolean = False _
)
```

**Parameters:**
- `bGray` - If True, generates grayscale; if False, generates colored noise

---

#### Resample

Creates a resampled copy at new dimensions using bilinear interpolation.

**Signature:**
```vb
Public Function Resample( _
    ByVal lNewHeight As Long, _
    ByVal lNewWidth As Long _
) As cDIBSection
```

**Returns:** New cDIBSection object with resampled image

**Algorithm:** Bilinear interpolation for smooth scaling

**Usage:**
```vb
Dim smallerDIB As cDIBSection
Set smallerDIB = myDIB.Resample(100, 150)
```

---

#### CopyToClipboard

Copies DIB to Windows clipboard.

**Signature:**
```vb
Public Function CopyToClipboard( _
    Optional ByVal bAsDIB As Boolean = True _
) As Boolean
```

**Parameters:**
- `bAsDIB` - If True, copy as DIB; if False, copy as DDB (currently only DDB implemented)

**Note:** DIB clipboard format not yet implemented.

---

#### ClearUp

Releases all GDI resources.

**Signature:**
```vb
Public Sub ClearUp()
```

**Process:**
1. Restore old bitmap to DC
2. Delete DIB section handle
3. Delete device context
4. Zero all handles

⚠️ **Critical:** Must be called before destroying class to prevent resource leaks.

**Usage:**
```vb
myDIB.ClearUp
Set myDIB = Nothing
```

---

### Private Methods

#### CreateDIB

Internal method to create DIB section.

#### ResampleDib

Internal method implementing bilinear resampling algorithm.

---

### Lifecycle Management

```vb
' 1. Creation
Dim myDIB As New cDIBSection

' 2. Initialization
myDIB.Create 200, 300
' OR
myDIB.CreateFromPicture LoadResPicture(101, vbResBitmap)

' 3. Usage
myDIB.PaintPicture destDC

' 4. Cleanup
myDIB.ClearUp

' 5. Destruction
Set myDIB = Nothing  ' Class_Terminate calls ClearUp if not already called
```

---

### Direct Pixel Access

For advanced operations, access pixels directly via byte array:

```vb
Dim bDib() As Byte
Dim tSA As SAFEARRAY2D
Dim x As Long, y As Long

' Map byte array to DIB bits
With tSA
    .cbElements = 1
    .cDims = 2
    .Bounds(0).lLbound = 0
    .Bounds(0).cElements = myDIB.Height
    .Bounds(1).lLbound = 0
    .Bounds(1).cElements = myDIB.BytesPerScanLine
    .pvData = myDIB.DIBSectionBitsPtr
End With
CopyMemory ByVal VarPtrArray(bDib()), VarPtr(tSA), 4

' Access pixels (BGR order)
bDib(x * 3, y) = blueValue
bDib(x * 3 + 1, y) = greenValue
bDib(x * 3 + 2, y) = redValue

' Unmap array
CopyMemory ByVal VarPtrArray(bDib), 0&, 4
```

⚠️ **Warning:** Direct memory manipulation can cause crashes if done incorrectly.

---

## cDIBSectionRegion

**File:** `cDIBSectionRegion.cls`  
**Author:** Steve McMahon (vbAccelerator.com)  
**Purpose:** Converts DIB sections into window regions for form shaping

### Overview

This class analyzes a DIB section pixel-by-pixel, identifying transparent areas, and generates a Windows region that can be applied to a window to create non-rectangular forms.

### Class Variables

```vb
Private m_hRgn As Long          ' Handle to region
Private m_hWnd() As Long        ' Array of windows using this region
Private m_iCount As Long        ' Count of applied windows
```

### Properties

#### Applied

Gets or sets whether region is applied to a specific window.

**Signature:**
```vb
Public Property Get Applied(ByVal hWnd As Long) As Boolean
Public Property Let Applied(ByVal hWnd As Long, ByVal bState As Boolean)
```

**Usage:**
```vb
' Apply region to form
myRegion.Applied(Me.hWnd) = True

' Remove region from form
myRegion.Applied(Me.hWnd) = False

' Check if applied
If myRegion.Applied(Me.hWnd) Then
    ' Region is active
End If
```

---

#### AppliedToCount

Returns number of windows currently using this region.

```vb
Public Property Get AppliedToCount() As Long
```

---

#### hWndForIndex

Returns window handle at specified index.

```vb
Public Property Get hWndForIndex(ByVal lIndex As Long) As Long
```

---

### Public Methods

#### Create

Creates region from a DIB section, making specified color transparent.

**Signature:**
```vb
Public Sub Create( _
    ByRef cDib As cDIBSection, _
    Optional ByRef lTransColor As Long = 0 _
)
```

**Parameters:**
- `cDib` - DIB section to analyze
- `lTransColor` - RGB color to treat as transparent (default black)

**Algorithm:**
1. Destroy any existing region
2. Create base rectangular region
3. Scan DIB pixel-by-pixel (column-major order)
4. For each column, find runs of transparent pixels
5. Create small rectangles for transparent runs
6. XOR transparent rectangles with base region
7. Result: region excluding transparent areas

**Performance:** O(width × height) - can be slow for large images

**Optimization:** Pre-generate regions at design time and load from resource.

**Usage:**
```vb
Dim myDIB As New cDIBSection
Dim myRegion As New cDIBSectionRegion

myDIB.CreateFromPicture LoadResPicture(101, vbResBitmap)
myRegion.Create myDIB, RGB(255, 0, 255)  ' Magenta is transparent
myRegion.Applied(Me.hWnd) = True
```

---

#### Save

Saves region data to a file.

**Signature:**
```vb
Public Function Save(ByVal sPath As String) As Boolean
```

**File Format:** Binary region data from `GetRegionData` API

**Usage:**
```vb
myRegion.Save "C:\kafra_shape.rgn"
```

---

#### LoadFromFile

Loads region data from a file.

**Signature:**
```vb
Public Function LoadFromFile(ByVal sFileName As String) As Boolean
```

**Usage:**
```vb
myRegion.LoadFromFile "C:\kafra_shape.rgn"
myRegion.Applied(Me.hWnd) = True
```

---

#### LoadFromResource

Loads region data from application resource or external DLL.

**Signature:**
```vb
Public Function LoadFromResource( _
    ByVal vID As Variant, _
    Optional ByVal sDLL As String = "" _
) As Boolean
```

**Parameters:**
- `vID` - Resource ID (numeric or string)
- `sDLL` - External DLL path (empty for own resources)

**Resource Type:** RCDATA (10)

**Usage:**
```vb
' From own resources
myRegion.LoadFromResource 101

' From external DLL
myRegion.LoadFromResource 101, "shapes.dll"
```

---

#### Destroy

Removes region from all windows and frees region handle.

**Signature:**
```vb
Public Sub Destroy()
```

**Process:**
1. Un-apply region from all windows
2. Delete region handle
3. Reset internal state

⚠️ **Critical:** Must be called before destroying class if region is applied.

---

### Lifecycle Management

```vb
' 1. Creation
Dim myRegion As New cDIBSectionRegion

' 2. Load region (choose one)
myRegion.Create myDIB, RGB(255, 0, 255)
' OR
myRegion.LoadFromResource 101

' 3. Apply to window
myRegion.Applied(Me.hWnd) = True

' 4. Cleanup
myRegion.Destroy

' 5. Destruction
Set myRegion = Nothing
```

---

### Region File Generation Workflow

**Design Time (Region Maker tool):**

1. Load character bitmap
2. Create DIB section
3. Call `myRegion.Create(myDIB, transparentColor)`
4. Save region: `myRegion.Save("blossom.rgn")`
5. Compile `.rgn` files into resource with Resource Compiler

**Runtime (Application):**

1. Create region object
2. Load from resource: `myRegion.LoadFromResource(101)`
3. Apply to form: `myRegion.Applied(Me.hWnd) = True`

**Benefits:**
- Instant loading (no pixel scanning at runtime)
- Consistent results
- Smaller executable

---

## cSubclass

**File:** `cSubclass.cls`  
**Author:** Paul Caton  
**Purpose:** Module-less, IDE-safe window subclassing using machine code thunks

### Overview

This class provides a safe way to intercept Windows messages sent to VB forms. Traditional subclassing with `SetWindowLong` crashes the VB IDE if not properly cleaned up. This implementation uses machine code and breakpoint gates to detect IDE vs. compiled state and clean up automatically.

### Architecture

```
Windows Message
     │
     ▼
 [WndProc Thunk]
  (Machine Code)
     │
     ├──> Before Msg Table
     │         │
     │         ▼
     │    [Callback: iSubclass_Before]
     │         │
     │         ▼
     ├──> Original WndProc
     │    (Default Handling)
     │         │
     │         ▼
     └──> After Msg Table
               │
               ▼
          [Callback: iSubclass_After]
               │
               ▼
           Return Value
```

### Class Variables

```vb
Private CodeBuf As tCodeBuf         ' Machine code buffer
Private nBreakGate As Long          ' IDE breakpoint gate
Private nMsgCntB As Long            ' Before message count
Private nMsgCntA As Long            ' After message count
Private aMsgTblB() As WinSubHook.eMsg    ' Before message table
Private aMsgTblA() As WinSubHook.eMsg    ' After message table
Private hWndSubclass As Long        ' Subclassed window handle
Private nWndProcSubclass As Long    ' Our WndProc address
Private nWndProcOriginal As Long    ' Original WndProc address
```

### Public Methods

#### Subclass

Installs subclass on a window.

**Signature:**
```vb
Public Sub Subclass( _
    hwnd As Long, _
    Owner As WinSubHook.iSubclass _
)
```

**Parameters:**
- `hwnd` - Window handle to subclass
- `Owner` - Object implementing `iSubclass` interface

**Process:**
1. Validate window handle
2. Store window handle
3. Replace window procedure with our thunk
4. Patch thunk with runtime values
5. Store original WndProc address

**Usage:**
```vb
Dim subclass As New cSubclass
subclass.Subclass Me.hWnd, Me
```

**Requirements:**
- Form must implement `WinSubHook.iSubclass` interface
- Must call `UnSubclass` before form unloads

---

#### UnSubclass

Removes subclass from window.

**Signature:**
```vb
Public Sub UnSubclass()
```

**Process:**
1. Disable message callbacks (patch counts to 0)
2. Restore original window procedure
3. Clear internal state

⚠️ **Critical:** MUST be called in Form_Unload or Class_Terminate.

**Usage:**
```vb
Private Sub Form_Unload(Cancel As Integer)
    subclass.UnSubclass
    Set subclass = Nothing
End Sub
```

---

#### AddMsg

Adds a message to the callback table.

**Signature:**
```vb
Public Sub AddMsg( _
    uMsg As WinSubHook.eMsg, _
    When As WinSubHook.eMsgWhen _
)
```

**Parameters:**
- `uMsg` - Message to intercept (e.g., `WM_MOVING`)
- `When` - When to intercept:
  - `MSG_BEFORE` - Before default processing
  - `MSG_AFTER` - After default processing

**Usage:**
```vb
subclass.AddMsg WM_MOVING, MSG_BEFORE
subclass.AddMsg WM_PAINT, MSG_AFTER
subclass.AddMsg ALL_MESSAGES, MSG_BEFORE  ' Intercept all
```

---

#### DelMsg

Removes a message from the callback table.

**Signature:**
```vb
Public Sub DelMsg( _
    uMsg As WinSubHook.eMsg, _
    When As WinSubHook.eMsgWhen _
)
```

**Usage:**
```vb
subclass.DelMsg WM_MOVING, MSG_BEFORE
subclass.DelMsg ALL_MESSAGES, MSG_BEFORE  ' Remove all
```

---

#### CallOrigWndProc

Manually calls the original window procedure.

**Signature:**
```vb
Public Function CallOrigWndProc( _
    ByVal uMsg As WinSubHook.eMsg, _
    ByVal wParam As Long, _
    ByVal lParam As Long _
) As Long
```

**Usage:**
```vb
' In message handler, call default processing manually
result = subclass.CallOrigWndProc(uMsg, wParam, lParam)
```

---

### Interface Implementation

#### WinSubHook.iSubclass

Forms using subclassing must implement this interface:

```vb
Implements WinSubHook.iSubclass

Private Function iSubclass_Before( _
    ByVal hWnd As Long, _
    ByVal uMsg As Long, _
    ByVal wParam As Long, _
    ByVal lParam As Long, _
    bHandled As Boolean _
) As Long
    
    Select Case uMsg
    Case WM_MOVING
        ' Handle message
        ' Set bHandled = True to prevent default processing
        iSubclass_Before = 0
    End Select
End Function

Private Function iSubclass_After( _
    ByVal hWnd As Long, _
    ByVal uMsg As Long, _
    ByVal wParam As Long, _
    ByVal lParam As Long _
) As Long
    
    Select Case uMsg
    Case WM_PAINT
        ' Post-processing after default handling
        iSubclass_After = 0
    End Select
End Function
```

---

### Safety Mechanisms

#### IDE Detection

The class detects whether it's running in the IDE or compiled:

```vb
Private Function InIDE() As Long
Static Value As Long
  
    If Value = 0 Then
        Value = 1
        Debug.Assert True Or InIDE()  ' This line removed in compiled exe
        InIDE = Value - 1
    End If
  
    Value = 0
End Function
```

#### Breakpoint Gate

A variable checked before callbacks, prevents crashes when breakpoint hit in IDE.

#### Automatic Cleanup

`Class_Terminate` automatically calls `UnSubclass`:

```vb
Private Sub Class_Terminate()
    If hWndSubclass <> 0 Then
        Call UnSubclass
    End If
End Sub
```

---

### Complete Usage Example

```vb
' In form declarations
Private MainSubClass As New cSubclass
Implements WinSubHook.iSubclass

' In Form_Load
Private Sub Form_Load()
    MainSubClass.Subclass Me.hWnd, Me
    MainSubClass.AddMsg WM_MOVING, MSG_BEFORE
    MainSubClass.AddMsg WM_EXITSIZEMOVE, MSG_BEFORE
End Sub

' Interface implementation
Private Function iSubclass_Before(...) As Long
    Select Case uMsg
    Case WM_MOVING
        ' Implement screen snapping
        Dim r As RECT
        CopyMemory r, ByVal lParam, Len(r)
        SnapToScreen r.Left, r.Top, r, snapped
        CopyMemory ByVal lParam, r, Len(r)
        
    Case WM_EXITSIZEMOVE
        ' Save position
        SavePosition
    End Select
End Function

' In Form_Unload
Private Sub Form_Unload(Cancel As Integer)
    MainSubClass.DelMsg WM_EXITSIZEMOVE, MSG_BEFORE
    MainSubClass.DelMsg WM_MOVING, MSG_BEFORE
    MainSubClass.UnSubclass
    Set MainSubClass = Nothing
End Sub
```

---

## cWindow

**File:** `cWindow.cls`  
**Author:** Paul Caton  
**Purpose:** Module-less, IDE-safe creation and management of API windows

### Overview

Creates pure API windows (not VB forms) with custom window procedures. Useful for lightweight popup windows, child windows, or control implementations.

**Status in KDA:** Not actively used; included for completeness.

### Key Methods

- `WindowClassRegister` - Register custom window class
- `WindowCreate` - Create API window
- `WindowDestroy` - Destroy API window
- `AddMsg` / `DelMsg` - Message filtering

### Usage Scenario

```vb
Dim apiWin As New cWindow

' Register window class
apiWin.WindowClassRegister "MyWindowClass", vbWhite

' Set owner for callbacks
Set apiWin.Owner = Me

' Create window
hWnd = apiWin.WindowCreate( _
    dwExStyle:=0, _
    dwStyle:=WS_POPUP Or WS_VISIBLE, _
    Class:=AS_WINDOWCLASS, _
    x:=100, y:=100, _
    nWidth:=200, nHeight:=150, _
    sCaption:="Test Window" _
)

' Cleanup automatic in Class_Terminate
```

---

## Best Practices

### Resource Management

1. **Always pair Create/Destroy:**
   ```vb
   myObj.Create
   ' ... use object ...
   myObj.ClearUp  ' or Destroy
   ```

2. **Use Class_Terminate for cleanup:**
   ```vb
   Private Sub Class_Terminate()
       ClearUp
   End Sub
   ```

3. **Check return values:**
   ```vb
   If Not myDIB.Create(200, 300) Then
       MsgBox "Failed to create DIB"
       Exit Sub
   End If
   ```

### Subclassing Safety

1. **Always implement interface:**
   ```vb
   Implements WinSubHook.iSubclass
   ```

2. **Add messages after subclassing:**
   ```vb
   subclass.Subclass Me.hWnd, Me
   subclass.AddMsg WM_MOVING, MSG_BEFORE
   ```

3. **Remove before unloading:**
   ```vb
   subclass.DelMsg WM_MOVING, MSG_BEFORE
   subclass.UnSubclass
   ```

4. **Never stop IDE without unsubclassing:**
   - Use form's Close menu item
   - Don't click IDE Stop button
   - Implement proper cleanup

---

## Performance Considerations

### cDIBSection

- **Memory:** Width × Height × 3 bytes (24-bit RGB)
- **Creation:** Fast (<1ms for typical sizes)
- **Pixel Access:** Very fast (direct memory)
- **Resampling:** Slow (use sparingly)

### cDIBSectionRegion

- **Creation:** Slow (O(width × height))
- **Loading:** Fast (<1ms from resource)
- **Application:** Fast (single API call)
- **Memory:** Minimal (just region handle)

**Recommendation:** Pre-generate regions, store in resources.

### cSubclass

- **Overhead:** Minimal (<1% CPU)
- **Message Filtering:** Fast (table lookup)
- **IDE Safety:** Slight overhead for IDE detection

---

## Troubleshooting

### DIB Section Issues

**Symptom:** Blank or corrupted image  
**Causes:**
- Forgot to call `Create` before use
- Wrong dimensions
- DC not compatible

**Solution:** Verify `Create` returns True.

---

**Symptom:** Memory leak  
**Causes:**
- Forgot to call `ClearUp`
- Exception before cleanup

**Solution:** Always call in `Class_Terminate`.

---

### Region Issues

**Symptom:** Form not shaped correctly  
**Causes:**
- Wrong transparent color
- Region not applied
- Bitmap format incompatible

**Solution:** Verify transparency color matches bitmap.

---

**Symptom:** Form flickers during resize  
**Cause:** Region applied with `bRedraw = True`

**Solution:** Use `False` for intermediate operations.

---

### Subclassing Issues

**Symptom:** IDE crashes on stop  
**Cause:** Subclass not removed

**Solution:** Always unsubclass in Form_Unload.

---

**Symptom:** Messages not received  
**Causes:**
- Message not added to table
- Wrong `When` parameter
- Subclass not installed

**Solution:** Verify `AddMsg` called after `Subclass`.

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
