app := "WindowsTerminal.exe"
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