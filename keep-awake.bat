' Microsoft Teams Keep Active Script
' This script keeps your Teams status active by simulating periodic keyboard input
' No admin privileges required
' Compatible with Windows 11

Option Explicit

Dim objShell, objFSO, WshShell
Dim minutes, seconds, totalSeconds
Dim intervalSeconds, elapsedSeconds
Dim startTime, currentTime
Dim response

' Create objects
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

' Prompt for minutes
Do
    response = InputBox("Enter the number of minutes you want to stay active in Teams:" & vbCrLf & vbCrLf & _
                       "(Enter 0 to run indefinitely until you stop it manually)", _
                       "Teams Keep Active", "30")
    
    If response = "" Then
        WScript.Quit
    End If
    
    minutes = CInt(response)
    
    If minutes < 0 Then
        MsgBox "Please enter a valid number (0 or greater).", vbExclamation, "Invalid Input"
    Else
        Exit Do
    End If
Loop

' Calculate total seconds
If minutes = 0 Then
    totalSeconds = 0 ' Run indefinitely
    MsgBox "Script will run indefinitely. Press Ctrl+C or close this window to stop.", vbInformation, "Teams Keep Active"
Else
    totalSeconds = minutes * 60
    MsgBox "Script will keep Teams active for " & minutes & " minute(s)." & vbCrLf & _
           "Press Ctrl+C or close this window to stop early.", vbInformation, "Teams Keep Active"
End If

' Set interval (send a key every 60 seconds to prevent screen lock)
intervalSeconds = 60
elapsedSeconds = 0

' Record start time
startTime = Now

' Main loop
Do
    ' Wait for interval
    WScript.Sleep intervalSeconds * 1000
    
    ' Send a harmless key press to prevent screen lock
    ' Using F15 key (usually doesn't exist on keyboards, so it's safe)
    ' This simulates user activity without interfering with your work
    On Error Resume Next
    objShell.SendKeys "{F15}"
    On Error GoTo 0
    
    ' Alternative: If F15 doesn't work, try Scroll Lock toggle
    ' objShell.SendKeys "{SCROLLLOCK}"
    ' objShell.SendKeys "{SCROLLLOCK}"
    
    ' Update elapsed time
    elapsedSeconds = elapsedSeconds + intervalSeconds
    
    ' Check if time limit reached
    If totalSeconds > 0 And elapsedSeconds >= totalSeconds Then
        MsgBox "Time limit reached (" & minutes & " minute(s)). Script stopped.", vbInformation, "Teams Keep Active"
        Exit Do
    End If
    
Loop

' Cleanup
Set objShell = Nothing
Set objFSO = Nothing
Set WshShell = Nothing

WScript.Quit
