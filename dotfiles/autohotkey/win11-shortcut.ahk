app := "WindowsTerminal.exe"
chrome := "chrome.exe"
docker := "Docker Desktop.exe"
goland := "goland64.exe"
intellij := "idea64.exe"

^!t:: {
    if WinExist("ahk_exe " app) {
        if !WinActive("ahk_exe " app) {
            ; WinMaximize("ahk_exe " app)
            WinActivate("ahk_exe " app)
        } else {
            WinMinimize("ahk_exe " app)
        }
    } else {
        ; Run("wt.exe", , "Max")
        Run("wt.exe")
    }
}

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

; Disable PageUp and PageDown keys
PgUp::Return
PgDn::Return
