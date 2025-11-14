; ==============================================================================
; AutoHotkey v2 Script - Windows Shortcuts & Caps Lock Navigation
; ==============================================================================
; Requires AutoHotkey v2.0+
#Requires AutoHotkey v2.0

; App executable names
app := "WindowsTerminal.exe"
chrome := "chrome.exe"
docker := "Docker Desktop.exe"
goland := "goland64.exe"
intellij := "idea64.exe"

; ==============================================================================
; Application Launcher Shortcuts (Ctrl+Alt+Key)
; ==============================================================================

; Ctrl+Alt+T: Windows Terminal
^!t:: {
    if WinExist("ahk_exe " app) {
        if !WinActive("ahk_exe " app) {
            WinActivate("ahk_exe " app)
        } else {
            WinMinimize("ahk_exe " app)
        }
    } else {
        Run("wt.exe")
    }
}

; Ctrl+Alt+C: Chrome
^!c:: {
    if WinExist("ahk_exe " chrome) {
        if !WinActive("ahk_exe " chrome) {
            WinActivate("ahk_exe " chrome)
        } else {
            WinMinimize("ahk_exe " chrome)
        }
    } else {
        Run("chrome.exe")
    }
}

; Ctrl+Alt+D: Docker Desktop
^!d:: {
    if WinExist("ahk_exe " docker) {
        if !WinActive("ahk_exe " docker) {
            WinActivate("ahk_exe " docker)
        } else {
            WinMinimize("ahk_exe " docker)
        }
    } else {
        Run("Docker Desktop.exe")
    }
}

; Ctrl+Alt+G: GoLand
^!g:: {
    if WinExist("ahk_exe " goland) {
        if !WinActive("ahk_exe " goland) {
            WinActivate("ahk_exe " goland)
        } else {
            WinMinimize("ahk_exe " goland)
        }
    } else {
        Run("goland64.exe")
    }
}

; Ctrl+Alt+I: IntelliJ IDEA
^!i:: {
    if WinExist("ahk_exe " intellij) {
        if !WinActive("ahk_exe " intellij) {
            WinActivate("ahk_exe " intellij)
        } else {
            WinMinimize("ahk_exe " intellij)
        }
    } else {
        Run("idea64.exe")
    }
}

; ==============================================================================
; Disable Unwanted Keys
; ==============================================================================
; Disable PageUp, PageDown, and NumLock keys
PgUp::return
PgDn::return
NumLock::return


; ==============================================================================
; Caps Lock as Arrow Navigation Layer (Vim-style)
; ==============================================================================
; CapsLock 키를 누르고 있는 동안만 다음 핫키들을 활성화합니다.
#HotIf GetKeyState("CapsLock", "P")

; Caps Lock + J = Left Arrow
j::Send("{Left}")

; Caps Lock + Shift + J = Select left
+j::Send("+{Left}") ; Shift가 눌렸는지 여부는 자동으로 인식됩니다.

; Caps Lock + K = Down Arrow
k::Send("{Down}")

; Caps Lock + Shift + K = Select down
+k::Send("+{Down}")

; Caps Lock + L = Up Arrow
l::Send("{Up}")

; Caps Lock + Shift + L = Select up
+l::Send("+{Up}")

; Caps Lock + ; = Right Arrow
SC027::Send("{Right}")

; Caps Lock + Shift + ; = Select right
+SC027::Send("+{Right}")

#HotIf ; #HotIf 영역을 종료합니다 (다음 핫키는 조건 없이 적용됨).

; 아래 코드는 Caps Lock을 단독으로 눌렀을 때 아무것도 하지 않도록 막아줍니다.
; 이 코드가 없으면, CapsLock을 짧게 누르면 여전히 CapsLock 상태를 토글하려고 시도할 수 있습니다.
*CapsLock::Return
