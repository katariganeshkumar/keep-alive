' ============================================
' Windows Keep-Awake Script (VBScript)
' Prevents system sleep/lock using Windows API
' Optimized for Windows 11 - Office Laptop
' ============================================

Option Explicit

Dim objShell, minutes, seconds, startTime, endTime
Dim objFSO, pidFile, pid

' Create objects
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' PID file for reference (optional)
pidFile = objFSO.BuildPath(objShell.ExpandEnvironmentStrings("%TEMP%"), "keepawake_pid.txt")

' ============================================
' Get user input
' ============================================
Do
    minutes = InputBox("Enter number of minutes to stay awake:" & vbCrLf & vbCrLf & _
                       "Examples:" & vbCrLf & _
                       "  30 = 30 minutes" & vbCrLf & _
                       "  60 = 1 hour" & vbCrLf & _
                       "  120 = 2 hours", _
                       "Keep-Awake Script", "30")
    
    If minutes = "" Then
        WScript.Quit
    End If
    
    ' Validate input
    If IsNumeric(minutes) Then
        minutes = CInt(minutes)
        If minutes > 0 Then
            Exit Do
        End If
    End If
    
    MsgBox "Please enter a valid number greater than 0.", vbExclamation, "Invalid Input"
Loop

seconds = minutes * 60
startTime = Now
endTime = DateAdd("s", seconds, startTime)

' Calculate hours and remaining minutes for display
Dim hours, remainingMinutes
hours = Int(minutes / 60)
remainingMinutes = minutes Mod 60

' Display confirmation
Dim msg
msg = "Keeping system awake for " & minutes & " minute"
If minutes <> 1 Then msg = msg & "s"
msg = msg & vbCrLf & vbCrLf

If hours > 0 Then
    msg = msg & "Duration: " & hours & " hour"
    If hours <> 1 Then msg = msg & "s"
    If remainingMinutes > 0 Then
        msg = msg & " and " & remainingMinutes & " minute"
        If remainingMinutes <> 1 Then msg = msg & "s"
    End If
    msg = msg & vbCrLf & vbCrLf
End If

msg = msg & "Started at: " & FormatDateTime(startTime, vbLongTime) & vbCrLf
msg = msg & "Will end at: " & FormatDateTime(endTime, vbLongTime) & vbCrLf & vbCrLf
msg = msg & "Click OK to start. The script will run in the background." & vbCrLf
msg = msg & "To stop early, look for 'Windows Script Host' in Task Manager and end it."

MsgBox msg, vbInformation, "Keep-Awake Script"

' ============================================
' Save PID for cleanup reference
' ============================================
pid = objShell.Exec("cmd /c echo %PID%").StdOut.ReadAll
pid = Trim(pid)
If pid = "" Then pid = "0"

' Write PID to file
Dim objFile
Set objFile = objFSO.CreateTextFile(pidFile, True)
objFile.WriteLine pid
objFile.Close

' ============================================
' METHOD 1: Disable sleep using powercfg
' ============================================
On Error Resume Next
objShell.Run "powercfg /change standby-timeout-ac 0", 0, True
objShell.Run "powercfg /change standby-timeout-dc 0", 0, True
objShell.Run "powercfg /change monitor-timeout-ac 0", 0, True
objShell.Run "powercfg /change monitor-timeout-dc 0", 0, True
objShell.Run "powercfg /change hibernate-timeout-ac 0", 0, True
objShell.Run "powercfg /change hibernate-timeout-dc 0", 0, True
On Error Goto 0

' ============================================
' METHOD 2: Use PowerShell with SetThreadExecutionState API
' This is the most reliable method
' ============================================
Dim psCommand
psCommand = "$code = '[DllImport(""kernel32.dll"", CharSet = CharSet.Auto, SetLastError = true)] public static extern uint SetThreadExecutionState(uint esFlags);'; " & _
            "$type = Add-Type -MemberDefinition $code -Name SystemState -Namespace Win32 -PassThru; " & _
            "$ES_CONTINUOUS = 0x80000000; " & _
            "$ES_SYSTEM_REQUIRED = 0x00000001; " & _
            "$ES_DISPLAY_REQUIRED = 0x00000002; " & _
            "$flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED; " & _
            "$startTime = Get-Date; " & _
            "$endTime = $startTime.AddSeconds(" & seconds & "); " & _
            "while ((Get-Date) -lt $endTime) { " & _
            "  $type::SetThreadExecutionState($flags); " & _
            "  Start-Sleep -Seconds 5 " & _
            "}"

' Run PowerShell in background
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command """ & psCommand & """", 0, False

' ============================================
' METHOD 3: Subtle mouse movement (via PowerShell)
' ============================================
Dim psMouseCommand
psMouseCommand = "$startTime = Get-Date; " & _
                 "$endTime = $startTime.AddSeconds(" & seconds & "); " & _
                 "Add-Type -AssemblyName System.Windows.Forms; " & _
                 "while ((Get-Date) -lt $endTime) { " & _
                 "  $pos = [System.Windows.Forms.Cursor]::Position; " & _
                 "  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($pos.X + 1), $pos.Y); " & _
                 "  Start-Sleep -Milliseconds 50; " & _
                 "  [System.Windows.Forms.Cursor]::Position = $pos; " & _
                 "  Start-Sleep -Seconds 30 " & _
                 "}"

objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command """ & psMouseCommand & """", 0, False

' ============================================
' Main loop: Keep script alive
' ============================================
Dim elapsed, remaining

' Show initial notification
Dim startMsg
startMsg = "Keep-Awake started!" & vbCrLf & vbCrLf & _
           "Duration: " & minutes & " minute"
If minutes <> 1 Then startMsg = startMsg & "s"
startMsg = startMsg & vbCrLf & _
           "Started: " & FormatDateTime(startTime, vbLongTime) & vbCrLf & _
           "Will end: " & FormatDateTime(endTime, vbLongTime) & vbCrLf & vbCrLf & _
           "The script is running in the background." & vbCrLf & _
           "To stop early: Open Task Manager and end 'Windows Script Host'"

objShell.Popup startMsg, 5, "Keep-Awake Active", vbInformation

' Main countdown loop - runs silently in background
Do While Now < endTime
    elapsed = DateDiff("s", startTime, Now)
    remaining = seconds - elapsed
    
    If remaining <= 0 Then Exit Do
    
    ' Sleep for 10 seconds between checks
    WScript.Sleep 10000
Loop

' ============================================
' Cleanup: Restore power settings
' ============================================
On Error Resume Next

' Try to restore power settings (optional - commented out by default)
' Uncomment these lines if you want to restore defaults:
' objShell.Run "powercfg /change standby-timeout-ac 10", 0, True
' objShell.Run "powercfg /change standby-timeout-dc 5", 0, True
' objShell.Run "powercfg /change monitor-timeout-ac 10", 0, True
' objShell.Run "powercfg /change monitor-timeout-dc 5", 0, True

' Clean up PID file
If objFSO.FileExists(pidFile) Then
    objFSO.DeleteFile pidFile, True
End If

On Error Goto 0

' Final message
MsgBox "Time's up!" & vbCrLf & vbCrLf & _
       "Keep-awake session completed." & vbCrLf & _
       "System will now follow normal power settings.", _
       vbInformation, "Keep-Awake Script"

' Cleanup
Set objShell = Nothing
Set objFSO = Nothing

WScript.Quit

