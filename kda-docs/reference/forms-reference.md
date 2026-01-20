# Forms Reference

## Overview

This document provides detailed specifications for all forms (`.frm` files) in the Kafra Desktop Assistant application. Forms are the visual windows that users interact with.

## Form Catalog

| Form Name | File | Purpose | Modal | Always On Top |
|-----------|------|---------|-------|---------------|
| **frmMain** | bg.frm (Original)<br>bg Sakura.frm (Sakura) | Main Kafra character window | No | Optional |
| **frmPopup** | frmPopup.frm | Memo and storage management | No | No |
| **frmTray** | frmTray.frm | System tray icon handler | No | No |
| **frmAbout** | frmAbout.frm (Original)<br>frmAbout Sakura.frm (Sakura) | About dialog | Yes | Yes |
| **frmBlurb** | frmBlurb.frm | Notification bubble | No | Yes |
| **frmMessage** | frmMessage.frm | Memo editor dialog | Yes | Yes |
| **frmNewTrunk** | frmNewTrunk.frm | New folder dialog | Yes | Yes |
| **frmCalendar** | frmCalendar.frm | Calendar/planner (unused) | No | No |
| **frmStorage** | frmStorage.frm | Storage browser (test form) | No | No |
| **mnuForm** | mnuForm.frm | Invisible menu container | No | No |
| **frmPopupCal** | frmPopupCal.frm | Calendar popup (unused) | No | No |
| **frmPopupTools** | frmPopupTools.frm | Tools popup (unused) | No | No |
| **frmRegionMain** | frmRegionMain.frm | Region creation tool | No | No |
| **frmRegionTest** | frmRegionTest.frm | Region testing tool | No | No |
| **frmProcessing** | frmProcessing.frm | Processing indicator (unused) | No | No |

---

## frmMain (Main Application Form)

**File:** `bg.frm` (Original) / `bg Sakura.frm` (Sakura Edition)

### Purpose

The primary UI element displaying the animated Kafra character on the desktop. This is the entry point form for the application.

### Properties

```vb
BorderStyle = 0  'None (no border, no caption)
ScaleMode = 3    'Pixel
ShowInTaskbar = 0  'False (hidden from taskbar)
OLEDropMode = 1  'Manual (handles drag-drop events)
MaxButton = 0    'False
MinButton = 0    'False
Icon = "bg.frx":0000  'Application icon
```

### Form Variables

```vb
Dim frameno As Integer        ' Current animation frame number
Dim dX As Integer             ' Animation direction
Dim Kafra As Long             ' Current Kafra character index (0-6)
Public Hidden As Boolean      ' Visibility state flag
Dim MovingMe As Boolean       ' Dragging/animation in progress flag

' DIB and Region objects
Dim myDIB As New cDIBSection
Dim myRGN As New cDIBSectionRegion

' Animation data for blink effects
Dim myKafraAniData(6) As KafraAniData
Dim mTrans As Integer

' Subclassing object
Dim MainSubClass As New cSubclass
Implements WinSubHook.iSubclass
```

### Type Definition

```vb
Private Type KafraAniData
    x As Long      ' X offset in sprite sheet
    y As Long      ' Y offset in sprite sheet
    W As Long      ' Width of frame
    H As Long      ' Height of frame
End Type
```

### Key Events

#### Form_Load

**Trigger:** Application startup

**Process:**
1. Check for previous instance (`App.PrevInstance`)
2. Detect OS version for transparency support
3. Load animation data from `ani.txt` (if present)
4. Get taskbar height via `SystemParametersInfo`
5. Create `\Storage` folder if missing
6. Load custom cursors from `\Cursors` folder
7. Initialize tray icon (`Load frmTray`)
8. Read registry settings:
   - Autorun state
   - Always On Top preference
   - Saved position
   - Last selected Kafra
9. Position form at bottom of screen
10. Initialize subclassing for window messages
11. Call `NewForm()` to render character
12. Show notification blurb

**Code Pattern:**
```vb
Private Sub Form_Load()
    CheckOSVersion  ' Detect Win2K/XP
    
    If App.PrevInstance Then End
    
    ' Read animation data
    If Dir(App.path & "\ani.txt") <> "" Then
        Open App.path & "\ani.txt" For Input As 1
        ' Parse animation frames...
        Close 1
    End If
    
    ' Get work area
    Dim myRect As RECT
    SystemParametersInfo 48&, 0&, myRect, 0&
    TaskBarHeight = Screen.Height - (myRect.Bottom * Screen.TwipsPerPixelY)
    
    ' Create storage folder
    If Dir(App.path & "\Storage", vbDirectory) = "" Then
        MkDir App.path & "\Storage"
    End If
    
    ' Load cursors
    LoadCursors
    
    ' Read saved settings
    Kafra = GetHexKey(HKEY_CURRENT_USER, _
                      "Software\EnderSoft\DesktopKafra\", _
                      "Current Kafra")
    
    ' Position at bottom right
    Me.Top = Screen.Height - Me.Height - TaskBarHeight
    Me.Left = IIf(formLeft = 0, Screen.Width - Me.Width, formLeft)
    
    ' Initialize subclassing
    MainSubClass.Subclass Me.hWnd, Me
    MainSubClass.AddMsg WM_MOVING, MSG_BEFORE
    MainSubClass.AddMsg WM_EXITSIZEMOVE, MSG_BEFORE
    
    NewForm
    frmBlurb.Show , Me
End Sub
```

#### NewForm

**Purpose:** Load and render the selected Kafra character.

**Process:**
1. Hide form temporarily
2. Update registry with current character
3. Update menu checkmarks
4. Disable layered window style
5. Load character name from string resource
6. Load character bitmap from resource
7. Create DIB section from bitmap
8. Resize form to match bitmap dimensions
9. Load pre-generated region from resource
10. Apply region to form
11. Re-enable layered window with full opacity
12. Show form

**Code Pattern:**
```vb
Private Sub NewForm()
    frmMain.Hide
    SetHexKey HKEY_CURRENT_USER, _
              "Software\EnderSoft\DesktopKafra\", _
              "Current Kafra", Kafra
    
    ' Update UI
    For i = 0 To mnuForm.mnuKafraSwitch.UBound
        mnuForm.mnuKafraSwitch(i).Checked = False
    Next
    mnuForm.mnuKafraSwitch(Kafra).Checked = True
    
    SetLayered Me.hWnd, False
    
    ' Load resources
    KafraName = LoadResString(Kafra + 101)
    frmMain.Picture = LoadResPicture(Kafra + 111, 0)
    
    ' Create shaped form
    myDIB.CreateFromPicture frmMain.Picture
    Me.Height = myDIB.Height * Screen.TwipsPerPixelY
    Me.Width = myDIB.Width * Screen.TwipsPerPixelX
    
    myRGN.LoadFromResource Kafra + 101
    myRGN.Applied(Me.hWnd) = True
    
    ' Apply transparency
    SetLayered Me.hWnd, True
    SetWindowEffects Me.hWnd, , 255
    
    frmMain.Show
    Me.Top = Screen.Height - Me.Height - TaskBarHeight
End Sub
```

#### Form_MouseDown

**Trigger:** User clicks on Kafra

**Parameters:**
- `Button` - 1 (left), 2 (right), 4 (middle)
- `Shift` - Modifier keys state
- `x`, `y` - Click coordinates

**Behavior:**
- **Left Click:** Initiate dragging
  - Change cursor to closed hand
  - Call `ReleaseCapture` API
  - Send `WM_SYSCOMMAND` with `SC_CLICKMOVE`
  - Windows handles drag until mouse release
- **Right Click:** Show context menu (`mnuForm.mnu1`)

**Code Pattern:**
```vb
Private Sub Form_MouseDown(Button As Integer, _
                           Shift As Integer, _
                           x As Single, _
                           y As Single)
    If Button = 1 Then
        SetRagCursor CUR_HANDCLOSE
        ReleaseCapture
        SendMessage Me.hWnd, WM_SYSCOMMAND, SC_CLICKMOVE, 0
    End If
    If Button = 2 Then
        PopupMenu mnuForm.mnu1
    End If
End Sub
```

#### Form_MouseMove

**Trigger:** Mouse moves over Kafra

**Behavior:**
- Exit if animation in progress (`MovingMe` flag)
- If no button pressed:
  - Set cursor to pointer
  - Check if form dragged below threshold (2/3 height)
  - If below threshold, auto-hide Kafra
  - Otherwise, snap back to bottom
- If button pressed:
  - Set cursor to open hand

**Auto-Hide Logic:**
```vb
If Me.Top > Screen.Height - Me.Height * 2 / 3 Then
    HideKafra
Else
    Me.Top = Screen.Height - Me.Height - TaskBarHeight
End If
```

#### Form_DblClick

**Trigger:** Double-click on Kafra

**Behavior:**
- Exit if dragging (`MovingMe` flag)
- Show memo/storage popup (`frmPopup.Show`)

#### Form_OLEDragDrop

**Trigger:** Files/folders dropped on Kafra

**Parameters:**
- `Data` - DataObject containing files
- `Effect` - Drop effect (copy, move, link)

**Behavior:**
1. Iterate through `Data.Files` collection
2. Determine if each item is file or folder (`GetAttr`)
3. Use `FileSystemObject` to move items:
   - `MoveFolder` for directories
   - `MoveFile` for files
4. Destination: `curPath\<filename>`
5. Refresh storage list view
6. Show error message box if operation fails

**Code Pattern:**
```vb
Private Sub Form_OLEDragDrop(Data As DataObject, _
                             Effect As Long, _
                             Button As Integer, _
                             Shift As Integer, _
                             x As Single, _
                             y As Single)
On Error GoTo errhandler
    Dim mFile As New FileSystemObject
    Dim i As Integer
    
    If MovingMe Then Exit Sub
    
    For i = 1 To Data.Files.Count
        If GetAttr(Data.Files(i)) = vbDirectory Then
            mFile.MoveFolder Data.Files(i), _
                             curPath & "\" & mFile.GetFileName(Data.Files(i))
        Else
            mFile.MoveFile Data.Files(i), _
                           curPath & "\" & mFile.GetFileName(Data.Files(i))
        End If
    Next
    
    frmPopup.ShowItems curPath
    Exit Sub

errhandler:
    MsgBox "One or more of the items could not be moved.", vbInformation
End Sub
```

#### Form_Unload

**Trigger:** Application exit

**Cleanup Process:**
1. Remove subclass messages
2. Call `UnSubclass` method
3. Destroy subclass object
4. Hide form
5. Clear DIB resources (`myDIB.ClearUp`)
6. Destroy region object (`myRGN.Destroy`)
7. Save final position to registry
8. Unload all child forms

⚠️ **Critical:** Improper cleanup causes IDE crashes. Always call `UnSubclass` before termination.

### Public Methods

#### SwitchKafra(Index As Integer)

Changes the displayed Kafra character.

```vb
Public Sub SwitchKafra(Index As Integer)
    Kafra = Index
    NewForm
End Sub
```

#### RandomKafra()

Switches to a random different character.

```vb
Public Sub RandomKafra()
    Dim oldKafra As Integer
    oldKafra = Kafra
    While Kafra = oldKafra
        Kafra = Int(Rnd(1) * 7)
    Wend
    NewForm
End Sub
```

#### HideKafra()

Animates Kafra sliding off screen.

**Animation:**
- **Windows 2000/XP:** Fade out (alpha 255 → 0 in steps of 5)
- **Windows 98/ME:** Slide down until off-screen

```vb
Public Sub HideKafra()
    SetAlwaysOnTop Me, HWND_NOTOPMOST
    If MovingMe Or Hidden Then Exit Sub
    MovingMe = True
    
    If OS_2000 Then
        For i = 255 To 0 Step -5
            SetWindowEffects Me.hWnd, , CByte(i)
            DoEvents
        Next
    Else
        While (Screen.Height - Me.Top) > 10
            Me.Top = Me.Top + spd
            DoEvents
            Sleep 10
            spd = (Screen.Height - Me.Top) / 12
        Wend
    End If
    
    Me.Hide
    MovingMe = False
    Hidden = True
End Sub
```

#### ShowKafra()

Animates Kafra sliding onto screen.

**Animation:**
- **Windows 2000/XP:** Fade in (alpha 0 → 255)
- **Windows 98/ME:** Slide up from bottom

```vb
Public Sub ShowKafra()
    If MovingMe Or Not Hidden Then Exit Sub
    MovingMe = True
    Me.Show
    
    If OS_2000 Then
        For i = 0 To 255 Step 5
            SetWindowEffects Me.hWnd, , CByte(i)
            DoEvents
        Next
    Else
        While Me.Top > Screen.Height - Me.Height - TaskBarHeight
            Me.Top = Me.Top - spd
            DoEvents
            Sleep 10
            spd = (Me.Top - (Screen.Height - Me.Height - TaskBarHeight)) / 12
        Wend
    End If
    
    MovingMe = False
    Hidden = False
    If mnuForm.mnuAlwaysOnTop.Checked Then
        SetAlwaysOnTop Me, HWND_TOPMOST
    End If
End Sub
```

### Subclass Interface Implementation

#### iSubclass_Before

Handles window messages before default processing.

**Messages Handled:**

**WM_MOVING (0x216):**
- Called while window is being moved
- Implements screen edge snapping
- Saves position during drag

**WM_EXITSIZEMOVE (0x232):**
- Called when dragging ends
- Saves final position to registry
- Clears `MovingMe` flag

```vb
Private Function iSubclass_Before(ByVal hWnd As Long, _
                                  ByVal uMsg As Long, _
                                  ByVal wParam As Long, _
                                  ByVal lParam As Long, _
                                  bHandled As Boolean) As Long
    Select Case uMsg
    Case WM_MOVING
        Dim r As RECT
        Dim snapped As Boolean
        
        CopyMemory r, ByVal lParam, Len(r)
        SnapToScreen r.Left, r.Top, r, snapped, 10
        CopyMemory ByVal lParam, r, Len(r)
        
        SetHexKey HKEY_CURRENT_USER, _
                  "Software\EnderSoft\DesktopKafra\", _
                  "Kafra X", r.Left
        MovingMe = True
        
    Case WM_EXITSIZEMOVE
        MovingMe = False
        Me.Top = Screen.Height - Me.Height - TaskBarHeight
    End Select
End Function
```

### Resource IDs

Character resources follow a pattern:

| Resource Type | ID Formula | Example (Kafra 0) |
|---------------|-----------|-------------------|
| String Name | 101 + index | 101 |
| Region Data | 101 + index | 101 |
| Bitmap Image | 111 + index | 111 |

**Kafra Character Indices:**
- 0 = Blossom
- 1 = Curly Sue
- 2 = Jasmine
- 3 = Leila
- 4 = Pavianne
- 5 = Roxie
- 6 = Sampaguita

---

## frmPopup (Memo/Storage Window)

**File:** `frmPopup.frm`

### Purpose

Multi-function popup window providing both memo management and file storage browsing capabilities.

### Properties

```vb
BorderStyle = 0  'None
ScaleMode = 3    'Pixel
Picture = "frmPopup.frx":000C  ' Background image
```

### Controls

#### RichTextBox (rtfMemo)

Displays memo content or allows editing.

**Properties:**
- `ScrollBars = 2` (Vertical)
- `BackColor = &HF7F7F7` (Light gray)
- `Locked = True` (initially read-only)

#### ListView1

Displays storage folder contents.

**Properties:**
- `View = 2` (Report/Details)
- `FullRowSelect = -1` (True)
- `OLEDropMode = 1` (Manual drag-drop)
- Linked to `ImageList3` for file type icons

**Columns:**
- "Item Name" - File/folder name

#### Custom Buttons

- `RagButtonPrev` - Previous memo ("<<")
- `RagButtonNext` - Next memo (">>")
- `RagButtonMemo` - Toggle mode ("storage"/"memo")
- `RagButtonClose` - Close window ("close")

#### PictureBox Buttons

- `picBtnAdd` - Write/save memo
- `picBtnDelete` - Delete memo/file
- `picBtnAbout` - Show about dialog
- `picBtnExit` - Close window
- `picBtnMini` - Minimize window

### Form Variables

```vb
Dim winstate As Integer          ' Window minimized state (0/1)
Dim writestate As Boolean        ' Memo edit mode flag
Dim delstate As Boolean          ' Item deletion confirm state
Dim curindex As Long             ' Current memo index
Dim MemoMode As Boolean          ' True=memo, False=storage
```

### Key Methods

#### Form_Load

**Initialization:**
1. Apply rounded corners (`CornerFormShape`)
2. Hide ListView, show RichTextBox
3. Set MemoMode = True
4. Load saved memos from registry
5. Display first memo or "No messages"

#### ShowItems(path As String)

Populates ListView with directory contents.

**Parameters:**
- `path` - Directory path to enumerate

**Process:**
1. Clear existing items
2. Save path to `curPath` global
3. Add ".." parent directory entry (if not root)
4. Enumerate files with `Dir$`
5. Determine icon based on file type:
   - Folders: "trunk" icon
   - Extensions map to specific icons
6. Add ListItem with icon key
7. Store full path in `.Tag` property

**Code Pattern:**
```vb
Public Sub ShowItems(path As String)
    ListView1.ListItems.Clear
    curPath = path
    
    ' Add parent directory
    If curPath <> App.path & "\Storage" Then
        Dim li As ListItem
        Set li = ListView1.ListItems.Add(, , "..")
        li.Icon = "trunk"
        li.SmallIcon = "trunk"
        li.Tag = GetParentPath(curPath)
    End If
    
    ' Enumerate files
    Dim filename As String
    filename = Dir$(path & "\*.*")
    Do While filename <> ""
        If filename <> "." And filename <> ".." Then
            Set li = ListView1.ListItems.Add(, , filename)
            li.Tag = path & "\" & filename
            
            ' Set icon based on type
            If GetAttr(li.Tag) = vbDirectory Then
                li.Icon = "trunk"
            Else
                li.Icon = GetIconForExtension(filename)
            End If
            li.SmallIcon = li.Icon
        End If
        filename = Dir$
    Loop
End Sub
```

#### SaveMemo()

Saves current memo to registry.

**Process:**
1. Read current memo count
2. Generate new index
3. Create memo string: `<date>|<time>|<content>`
4. Save to `HKCU\Software\EnderSoft\DesktopKafra\Memos\<index>`
5. Increment memo count
6. Save updated count

**Format:**
```
01/20/2026|14:35:00|This is the memo text content.
```

#### LoadMemo(index As Long)

Loads memo from registry and displays it.

**Process:**
1. Construct registry path
2. Read memo string value
3. Split on "|" delimiter
4. Parse date, time, content
5. Format for display in RichTextBox

**Display Format:**
```
Date: 01/20/2026
Time: 14:35:00

This is the memo text content.
```

#### DeleteMemo(index As Long)

Removes memo from registry.

**Process:**
1. Delete registry value at index
2. Shift higher-indexed memos down
3. Decrement memo count
4. Refresh display

#### RagButtonMemo_Click()

Toggles between memo and storage modes.

**Behavior:**
- If MemoMode:
  - Hide RichTextBox
  - Show ListView
  - Load storage contents
  - Change button caption to "memo"
  - Set MemoMode = False
- Else:
  - Hide ListView
  - Show RichTextBox
  - Load current memo
  - Change button caption to "storage"
  - Set MemoMode = True

#### ListView1_DblClick()

Opens selected file or navigates folder.

**Behavior:**
1. Get selected item's `.Tag` (full path)
2. Check if directory:
   - Yes: Call `ShowItems` with new path
   - No: Call `ShellExecute` to open file

**Code Pattern:**
```vb
Private Sub ListView1_DblClick()
    If ListView1.SelectedItem Is Nothing Then Exit Sub
    
    Dim itemPath As String
    itemPath = ListView1.SelectedItem.Tag
    
    If GetAttr(itemPath) And vbDirectory Then
        ShowItems itemPath
    Else
        ShellExecute 0, "open", itemPath, "", curPath, SW_NORMAL
    End If
End Sub
```

### Registry Structure

```
HKEY_CURRENT_USER\Software\EnderSoft\DesktopKafra\
  ├─ "Memo Count" (DWORD) - Total number of memos
  └─ Memos\
      ├─ "1" (STRING) - "01/20/2026|14:35:00|Memo text"
      ├─ "2" (STRING) - "01/21/2026|09:15:30|Another memo"
      └─ ...
```

---

## frmTray (System Tray Handler)

**File:** `frmTray.frm`

### Purpose

Invisible form that manages the system tray icon and handles tray notification messages.

### Properties

```vb
Visible = False  ' Never shown
ShowInTaskbar = False
BorderStyle = 0  'None
WindowState = 1  'Minimized (stays hidden)
```

### Form Variables

```vb
Private TrayData As NOTIFYICONDATA
```

### Key Methods

#### Form_Load

**Initialization:**
1. Configure NOTIFYICONDATA structure:
   - `cbSize` - Structure size
   - `hWnd` - This form's handle
   - `uID` - Icon ID (1)
   - `uFlags` - NIF_ICON | NIF_MESSAGE | NIF_TIP
   - `uCallbackMessage` - Custom message ID (PK_TRAYICON)
   - `hIcon` - Application icon handle
   - `szTip` - "Desktop Kafra"
2. Call `Shell_NotifyIcon(NIM_ADD, TrayData)`
3. Install custom window procedure via `SetWindowLong`

**Code Pattern:**
```vb
Private Sub Form_Load()
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
    pOldProc = SetWindowLong(Me.hWnd, GWL_WNDPROC, AddressOf WindowProc)
End Sub
```

#### Form_Unload

**Cleanup:**
1. Remove icon: `Shell_NotifyIcon(NIM_DELETE, TrayData)`
2. Restore original window procedure

**Code Pattern:**
```vb
Private Sub Form_Unload(Cancel As Integer)
    Shell_NotifyIcon NIM_DELETE, TrayData
    SetWindowLong Me.hWnd, GWL_WNDPROC, pOldProc
End Sub
```

### Window Procedure (modWndProc.bas)

Handles tray icon messages:

```vb
Public Function WindowProc(ByVal hWnd As Long, _
                           ByVal uMsg As Long, _
                           ByVal wParam As Long, _
                           ByVal lParam As Long) As Long
    Select Case uMsg
    Case PK_TRAYICON
        Select Case lParam
        Case WM_RBUTTONUP
            ' Show context menu
            mnuForm.PopupMenu mnuForm.mnu1
            
        Case WM_LBUTTONDBLCLK
            ' Toggle visibility
            If frmMain.Hidden Then
                frmMain.ShowKafra
            Else
                frmMain.HideKafra
            End If
        End Select
        WindowProc = 1
        
    Case Else
        ' Forward to original procedure
        WindowProc = CallWindowProc(pOldProc, hWnd, uMsg, wParam, lParam)
    End Select
End Function
```

---

## frmAbout (About Dialog)

**Files:** `frmAbout.frm` (Original) / `frmAbout Sakura.frm` (Sakura)

### Purpose

Displays application information, credits, and disclaimer.

### Properties

```vb
BorderStyle = 0  'None
ScaleMode = 3    'Pixel
```

### Controls

- Labels showing version, author, website
- Credits for contributors
- Disclaimer text
- Close button

### Behavior

- Modal dialog (`ShowDialog` or `vbModal`)
- Always on top
- Centered over frmPopup or screen
- Themed background and rounded corners

---

## frmBlurb (Notification Bubble)

**File:** `frmBlurb.frm`

### Purpose

Displays temporary notification messages to the user.

### Properties

```vb
BorderStyle = 0  'None
AlwaysOnTop = True
AutoRedraw = True
```

### Controls

- Label for message text
- Timer for auto-dismiss

### Key Methods

#### SetCaption(msg As String)

Sets the notification message and shows the form.

**Behavior:**
1. Update label text
2. Position near frmMain
3. Show form
4. Start timer (3-5 seconds)
5. Auto-hide on timer tick

---

## frmMessage (Memo Editor)

**File:** `frmMessage.frm`

### Purpose

Modal dialog for creating new memos.

### Controls

- `RichTextBox` or `TextBox` for memo content
- OK button (save and close)
- Cancel button (discard and close)
- Title bar buttons (minimize, close)

### Behavior

- Centered over frmPopup
- Always on top
- Returns memo text if OK clicked
- Returns empty string if cancelled

---

## frmNewTrunk (New Folder Dialog)

**File:** `frmNewTrunk.frm`

### Purpose

Modal dialog for creating new storage folders.

### Controls

- `txtPath` - TextBox for folder name input
- OK button (`RagButtonOK`)
- Cancel button (`RagButtonClose`)
- Label with instructions

### Key Methods

#### RagButtonOK_Click()

**Validation:**
1. Check if `txtPath` is empty
2. Check for invalid characters (`\/:*?"<>|`)
3. Check if folder already exists

**Creation:**
1. Construct full path: `curPath & "\" & txtPath.Text`
2. Call `MkDir` to create folder
3. Refresh parent folder display
4. Close dialog

**Error Handling:**
- Invalid name: Show message box
- Already exists: Show message box
- I/O error: Show error description

---

## mnuForm (Menu Container)

**File:** `mnuForm.frm`

### Purpose

Invisible form hosting the right-click context menu structure.

### Properties

```vb
Visible = False
```

### Menu Structure

```
mnu1 (root)
  ├─ mnuAutorun (checkbox)
  ├─ mnuAlwaysOnTop (checkbox)
  ├─ mnuKafraSwitch (array 0-6)
  │   ├─ mnuKafraSwitch(0) - Blossom
  │   ├─ mnuKafraSwitch(1) - Curly Sue
  │   ├─ mnuKafraSwitch(2) - Jasmine
  │   ├─ mnuKafraSwitch(3) - Leila
  │   ├─ mnuKafraSwitch(4) - Pavianne
  │   ├─ mnuKafraSwitch(5) - Roxie
  │   └─ mnuKafraSwitch(6) - Sampaguita
  ├─ mnuRandom
  ├─ mnuSeparator1 (-)
  ├─ mnuAbout
  ├─ mnuSeparator2 (-)
  └─ mnuClose
```

### Event Handlers

#### mnuAutorun_Click()

**Behavior:**
- Toggle checkbox state
- Call `SetAutoRun(mnuAutorun.Checked)`
- Updates `HKLM\...\Run` registry key

#### mnuAlwaysOnTop_Click()

**Behavior:**
- Toggle checkbox state
- Save preference to registry
- Call `SetAlwaysOnTop` with appropriate constant

#### mnuKafraSwitch_Click(Index As Integer)

**Behavior:**
- Call `frmMain.SwitchKafra(Index)`

#### mnuRandom_Click()

**Behavior:**
- Call `frmMain.RandomKafra()`

#### mnuAbout_Click()

**Behavior:**
- Show about dialog: `frmAbout.Show vbModal`

#### mnuClose_Click()

**Behavior:**
- Unload frmMain (triggers cleanup)

---

## Testing and Unused Forms

### frmStorage

Test form for the custom `RagListBox` control. Not used in production.

### frmCalendar, frmPopupCal, frmPopupTools

Planned features for calendar/planner functionality. UI designed but functionality not implemented.

### frmProcessing

Loading/progress indicator. Not used in current version.

### frmRegionMain, frmRegionTest

Development tools for creating and testing form regions. Used at design time only.

---

## Common Patterns

### Rounded Corner Form

Applied to most dialog windows:

```vb
Private Sub Form_Load()
    CornerFormShape Me  ' From modAFS.bas
End Sub
```

### Draggable Borderless Form

```vb
Private Sub Form_MouseDown(Button As Integer, ...)
    If Button = 1 Then
        ReleaseCapture
        SendMessage Me.hWnd, WM_SYSCOMMAND, SC_CLICKMOVE, 0
    End If
End Sub
```

### Custom Title Bar Buttons

```vb
Private Sub picBtnExit_Click()
    Unload Me
End Sub

Private Sub picBtnExit_MouseMove(Button As Integer, ...)
    ' Highlight button
    picBtnExit.Picture = ImageList1.ListImages("closeon").Picture
End Sub

Private Sub Form_MouseMove(Button As Integer, ...)
    ' Unhighlight all buttons
    picBtnExit.Picture = ImageList1.ListImages("closeoff").Picture
End Sub
```

### Minimize/Maximize Toggle

```vb
Private Sub picBtnMini_Click()
    winstate = winstate + 1
    If winstate > 1 Then winstate = 0
    
    If winstate = 0 Then
        Me.Height = 320 * Screen.TwipsPerPixelY  ' Expanded
    Else
        Me.Height = 17 * Screen.TwipsPerPixelY  ' Collapsed
    End If
End Sub
```

## Form Lifecycle Best Practices

1. **Load:** Initialize controls, load data, apply styling
2. **Activate:** Update always-on-top status if needed
3. **Unload:** Clean up resources, save state, remove API hooks
4. **Terminate:** Automatic cleanup of class-level objects

## Security Considerations

- Forms accept file drops without validation
- `ShellExecute` can launch any executable
- No privilege checks before registry writes
- Modal dialogs can be bypassed by killing process

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-20
