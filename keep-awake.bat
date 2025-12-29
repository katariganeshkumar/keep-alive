Set objShell = CreateObject("WScript.Shell")
minutes = objShell.InputBox("Enter how many minutes you want the PC to stay awake", "Wake Up Timer", "")
If IsNumeric(minutes) Then
    totalMsec = CInt(minutes) * 60 * 1000
    currentMsec = 0
    
    Do While currentMsec < totalMsec
        objShell.WakeUp
        objShell.Sleep 10000
        currentMsec = currentMsec + 10000
    Loop
End If
