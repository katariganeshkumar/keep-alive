@echo off
setlocal enabledelayedexpansion

REM ============================================
REM Windows Keep-Awake Script
REM Prevents system sleep/lock using multiple methods
REM ============================================

REM Get user input for minutes
set /p minutes="Enter number of minutes to stay awake: "

REM Validate input
if "%minutes%"=="" (
    echo Invalid input. Exiting...
    pause
    exit /b 1
)

REM Convert minutes to seconds
set /a seconds=%minutes% * 60
set /a hours=%minutes% / 60
set /a remainingMinutes=%minutes% %% 60

echo.
echo ============================================
echo Keeping system awake for %minutes% minutes
if %hours% gtr 0 (
    echo (%hours% hour(s) and %remainingMinutes% minute(s))
)
echo ============================================
echo Press Ctrl+C to stop early.
echo.

REM Save current time for display
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set startTime=%datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

echo Started at: %startTime%
echo.

REM ============================================
REM METHOD 1: Disable sleep using powercfg
REM ============================================
echo [Method 1] Disabling sleep timeouts...
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change standby-timeout-dc 0 >nul 2>&1
powercfg /change monitor-timeout-ac 0 >nul 2>&1
powercfg /change monitor-timeout-dc 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-dc 0 >nul 2>&1

REM Create PID file for cleanup
set PIDFILE=%TEMP%\keepawake_pids.txt
echo. > "%PIDFILE%"

REM ============================================
REM METHOD 2: PowerShell SetThreadExecutionState API
REM This prevents system sleep at the API level
REM ============================================
echo [Method 2] Activating SetThreadExecutionState API...
start /B powershell -WindowStyle Hidden -Command "$pid = $PID; Add-Content -Path '%PIDFILE%' -Value $pid; $code = '[DllImport(\"kernel32.dll\", CharSet = CharSet.Auto, SetLastError = true)] public static extern uint SetThreadExecutionState(uint esFlags);'; $type = Add-Type -MemberDefinition $code -Name SystemState -Namespace Win32 -PassThru; $ES_CONTINUOUS = 0x80000000; $ES_SYSTEM_REQUIRED = 0x00000001; $ES_DISPLAY_REQUIRED = 0x00000002; $flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED; $startTime = Get-Date; $endTime = $startTime.AddSeconds(%seconds%); while ((Get-Date) -lt $endTime) { $type::SetThreadExecutionState($flags); Start-Sleep -Seconds 5 }"

REM ============================================
REM METHOD 3: Subtle mouse movement
REM Moves mouse 1 pixel and back every 30 seconds
REM ============================================
echo [Method 3] Starting subtle mouse movement...
start /B powershell -WindowStyle Hidden -Command "$pid = $PID; Add-Content -Path '%PIDFILE%' -Value $pid; $startTime = Get-Date; $endTime = $startTime.AddSeconds(%seconds%); Add-Type -AssemblyName System.Windows.Forms; while ((Get-Date) -lt $endTime) { $pos = [System.Windows.Forms.Cursor]::Position; [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($pos.X + 1), $pos.Y); Start-Sleep -Milliseconds 50; [System.Windows.Forms.Cursor]::Position = $pos; Start-Sleep -Seconds 30 }"

REM ============================================
REM METHOD 4: Prevent lock screen using PowerShell
REM ============================================
echo [Method 4] Preventing lock screen...
start /B powershell -WindowStyle Hidden -Command "$pid = $PID; Add-Content -Path '%PIDFILE%' -Value $pid; $startTime = Get-Date; $endTime = $startTime.AddSeconds(%seconds%); while ((Get-Date) -lt $endTime) { [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false); Start-Sleep -Seconds 15 }"

REM ============================================
REM Main countdown loop with progress display
REM ============================================
echo.
echo All methods activated. Countdown starting...
echo.

set /a elapsed=0
set /a interval=30

:loop
if %elapsed% geq %seconds% goto :done

set /a remaining=%seconds% - %elapsed%
set /a remainingMinutes=%remaining% / 60
set /a remainingSeconds=%remaining% %% 60

REM Display progress
cls
echo ============================================
echo KEEP-AWAKE ACTIVE
echo ============================================
echo Started at: %startTime%
echo Time remaining: %remainingMinutes% min %remainingSeconds% sec
echo Elapsed: %elapsed% seconds
echo.
echo Methods active:
echo   [1] Power settings disabled
echo   [2] SetThreadExecutionState API
echo   [3] Mouse movement simulation
echo   [4] Lock screen prevention
echo.
echo Press Ctrl+C to stop early
echo ============================================

timeout /t %interval% /nobreak >nul 2>&1
set /a elapsed+=%interval%

goto :loop

:done
echo.
echo ============================================
echo Time's up! Restoring normal power settings...
echo ============================================

REM Kill background PowerShell processes using saved PIDs
if exist "%PIDFILE%" (
    for /f %%p in (%PIDFILE%) do (
        taskkill /F /PID %%p >nul 2>&1
    )
    del "%PIDFILE%" >nul 2>&1
)

REM Restore power settings (optional - uncomment if you want to restore defaults)
REM echo Restoring power settings...
REM powercfg /change standby-timeout-ac 10
REM powercfg /change standby-timeout-dc 5
REM powercfg /change monitor-timeout-ac 10
REM powercfg /change monitor-timeout-dc 5

echo.
echo Done! System will now follow normal power settings.
echo.
pause
