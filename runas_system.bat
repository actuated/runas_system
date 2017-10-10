@ECHO OFF
REM runas_system.bat (v1.0)
REM 10/7/2017 by Ted R (http://github.com/actuated)
REM
REM Batch file to start a command prompt as SYSTEM.
REM Must be run from an elevated command prompt.
REM
REM 10/8/2017 - Added check for REMOTE.EXE, -cleanup option, and pause at end in case batch is not kicked off from a command prompt window.
REM 10/9/2017 - Added quotes and tested with spaces in the root folder path.

ECHO.
ECHO ============[ runas_system.bat - Ted R (github: actuated) ]============
ECHO.

REM Defaults for options
SET SKIPELEVCHECK=N
SET SELECTARCH=N
SET THISPATH=%~dp0
SET THISRANDOMID=%random:~-1%%random:~-1%%random:~-1%%random:~-1%%random:~-1%%random:~-1%%random:~-1%%random:~-1%

REM Read options
:STARTOPTIONS
SET OPTIONWASSET=N
IF "%~1"=="" GOTO ENDOPTIONS
IF "%~1"=="-skipelevationcheck" (SET SKIPELEVCHECK=Y) && (SET OPTIONWASSET=Y)
IF "%~1"=="-selectarch" (SET SELECTARCH=Y) && (SET OPTIONWASSET=Y)
IF "%~1"=="-cleanup" GOTO CLEANUP && SET OPTIONWASSET=Y
IF "%~1"=="-h" GOTO HELP && SET OPTIONWASSET=Y
IF "%~1"=="-help" GOTO HELP && SET OPTIONWASSET=Y
SHIFT
IF %OPTIONWASSET%==N GOTO INVALIDOPTION
GOTO STARTOPTIONS
:ENDOPTIONS

REM Check for REMOTE.EXE
SET EXEMISSING=N
ECHO Checking for REMOTE.EXE in %THISPATH%REMOTE\X86\ and X64\...
IF NOT EXIST "%THISPATH%REMOTE\X86\REMOTE.EXE" (ECHO Error: x86 REMOTE.EXE not found in %THISPATH%\REMOTE\X86\.) && (SET EXEMISSING=Y)
IF NOT EXIST "%THISPATH%REMOTE\X64\REMOTE.EXE" (ECHO Error: x64 REMOTE.EXE not found in %THISPATH%\REMOTE\X64\.) && (SET EXEMISSING=Y)
IF %EXEMISSING%==Y (
  ECHO.
  ECHO Download the 32- and 64-bit versions of REMOTE.EXE from the
  ECHO Windows Debugger SDK:
  ECHO https://developer.microsoft.com/en-us/windows/hardware/download-windbg
  ECHO.
  ECHO By default, they will install in the X64\ and X86\ folders
  ECHO under C:\PROGRAM FILES^(86^)\WINDOWS KITS\10\DEBUGGERS\.
  ECHO.
  ECHO Place them in %THISPATH%REMOTE\X64\ and X86\, respectively.
  ECHO.
  GOTO DONE
)
ECHO.

REM Check to make sure prompt is elevated
IF %SKIPELEVCHECK%==Y GOTO SKIPELEVATIONCHECK
ECHO Checking privileges...
NET SESSION > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (ECHO Error: Not running from an elevated command prompt.) && (ECHO.) &&  GOTO DONE
ECHO.
:SKIPELEVATIONCHECK

REM Check if PROCESSOR_ARCHITECTURE is x86 or AMD64
IF %SELECTARCH%==Y GOTO SKIPARCHCHECK
ECHO Checking if this is a 32- or 64-bit system...
SET REMOTEPATH=x
IF %PROCESSOR_ARCHITECTURE%==x86 (SET REMOTEPATH=remote\x86\remote.exe) && (ECHO 32-bit identified.)
IF %PROCESSOR_ARCHITECTURE%==AMD64 (SET REMOTEPATH=remote\x64\remote.exe) && (ECHO 64-bit identified.)
IF %REMOTEPATH%==x (ECHO Error: Unexpected value from PROCESSOR_ARCHITECTURE environment variable.) && (ECHO.) && GOTO DONE
ECHO.
GOTO CREATETASK

REM Prompt to select architecture if -selectarch option was provided
:SKIPARCHCHECK
SET /P ARCHANSWER="Enter 32 for 32-bit, or 64 for 64-bit: "
SET REMOTEPATH=x
IF %ARCHANSWER%==32 (SET REMOTEPATH=remote\x86\remote.exe) && (ECHO 32-bit selected.)
IF %ARCHANSWER%==64 (SET REMOTEPATH=remote\x64\remote.exe) && (ECHO 64-bit selected.)
IF %REMOTEPATH%==x (ECHO Error: Answer not "32" or "64".) && (ECHO.) && GOTO DONE
ECHO.

REM Create an XML file for SCHTASKS.EXE to load
:CREATETASK
IF NOT EXIST "%THISPATH%TEMP" MKDIR "%THISPATH%TEMP"
IF NOT EXIST "%THISPATH%TEMP" (ECHO Error: %THISPATH%TEMP doesn't exist and couldn't be created.) && (ECHO.) && GOTO DONE
SET OUTFILE=%THISPATH%TEMP\%THISRANDOMID%.xml
ECHO Creating SCHTASKS XML file at %OUTFILE%...
ECHO ^<?xml version="1.0" encoding="UTF-16"?^> > "%OUTFILE%"
ECHO ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> "%OUTFILE%"
ECHO   ^<RegistrationInfo^> >> "%OUTFILE%"
ECHO     ^<Date^>2000-01-01T00:00:01^</Date^> >> "%OUTFILE%"
ECHO     ^<Author^>Administrator^</Author^> >> "%OUTFILE%"
ECHO   ^</RegistrationInfo^> >> "%OUTFILE%"
ECHO   ^<Triggers /^> >> "%OUTFILE%"
ECHO   ^<Principals^> >> "%OUTFILE%"
ECHO     ^<Principal id="Author"^> >> "%OUTFILE%"
ECHO       ^<UserId^>SYSTEM^</UserId^> >> "%OUTFILE%"
ECHO       ^<RunLevel^>HighestAvailable^</RunLevel^> >> "%OUTFILE%"
ECHO     ^</Principal^> >> "%OUTFILE%"
ECHO   ^</Principals^> >> "%OUTFILE%"
ECHO   ^<Settings^> >> "%OUTFILE%"
ECHO     ^<IdleSettings^> >> "%OUTFILE%"
ECHO       ^<Duration^>PT10M^</Duration^> >> "%OUTFILE%"
ECHO       ^<WaitTimeout^>PT1H^</WaitTimeout^> >> "%OUTFILE%"
ECHO       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> "%OUTFILE%"
ECHO       ^<RestartOnIdle^>false^</RestartOnIdle^> >> "%OUTFILE%"
ECHO     ^</IdleSettings^> >> "%OUTFILE%"
ECHO     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> "%OUTFILE%"
ECHO     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> "%OUTFILE%"
ECHO     ^<StopIfGoingOnBatteries^>true^</StopIfGoingOnBatteries^> >> "%OUTFILE%"
ECHO     ^<AllowHardTerminate^>false^</AllowHardTerminate^> >> "%OUTFILE%"
ECHO     ^<StartWhenAvailable^>false^</StartWhenAvailable^> >> "%OUTFILE%"
ECHO     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> "%OUTFILE%"
ECHO     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> "%OUTFILE%"
ECHO     ^<Enabled^>true^</Enabled^> >> "%OUTFILE%"
ECHO     ^<Hidden^>false^</Hidden^> >> "%OUTFILE%"
ECHO     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> "%OUTFILE%"
ECHO     ^<WakeToRun^>false^</WakeToRun^> >> "%OUTFILE%"
ECHO     ^<ExecutionTimeLimit^>PT0S^</ExecutionTimeLimit^> >> "%OUTFILE%"
ECHO     ^<Priority^>7^</Priority^> >> "%OUTFILE%"
ECHO   ^</Settings^> >> "%OUTFILE%"
ECHO   ^<Actions Context="Author"^> >> "%OUTFILE%"
ECHO     ^<Exec^> >> "%OUTFILE%"
ECHO       ^<Command^>"%THISPATH%%REMOTEPATH%"^</Command^> >> "%OUTFILE%"
ECHO       ^<Arguments^>/s cmd %THISRANDOMID%^</Arguments^> >> "%OUTFILE%"
ECHO       ^<WorkingDirectory^>%THISPATH%^</WorkingDirectory^> >> "%OUTFILE%"
ECHO     ^</Exec^> >> "%OUTFILE%"
ECHO   ^</Actions^> >> "%OUTFILE%"
ECHO ^</Task^> >> "%OUTFILE%"
ECHO.

REM Create and start task
ECHO Creating task %THISRANDOMID% to run %THISPATH%%REMOTEPATH%...
SCHTASKS /create /tn %THISRANDOMID% /xml "%OUTFILE%"
ECHO.
ECHO Running task to start REMOTE.EXE listening with session %THISRANDOMID%...
SCHTASKS /run /tn %THISRANDOMID%
ECHO.

REM Connect to the REMOTE session
ECHO Connecting to REMOTE.EXE session %THISRANDOMID%...
ECHO Run the command "exit" to exit.
ECHO.
"%THISPATH%%REMOTEPATH%" /c %COMPUTERNAME% %THISRANDOMID%
ECHO.

REM Clean up task and XML file at the end of proper execution
ECHO Ready to clean up the %THISRANDOMID% task and XML file.
PAUSE
SCHTASKS /delete /tn %THISRANDOMID%
DEL "%THISPATH%TEMP\%THISRANDOMID%.xml"
ECHO.

GOTO DONE

REM Clean up task and XML file matching the ID of any XML file in TEMP\
REM Should only be needed if batch ended unexpectedly
:CLEANUP
IF EXIST TEMP\*.XML (
  ECHO Removing any scheduled tasks with IDs from TEMP\ XML files:
  dir /b "%THISPATH%TEMP\*.XML"

  ECHO.
  for /f %%f in ('dir /b "%THISPATH%TEMP\*.XML"') DO (
    SCHTASKS /delete /tn %%~nf
    DEL "%THISPATH%TEMP\%%~nf.xml"
  )
  ECHO.
) ELSE (
  ECHO No XML files in %THISPATH%TEMP\ to check.
  ECHO To manually remove a task: SCHTASKS /delete /tn [id]
  ECHO.
)
GOTO DONE

REM Error message for invalid arguments
:INVALIDOPTION
ECHO Error: Unknown argument provided.
ECHO.

REM Usage information
:HELP
ECHO ===============================[ usage ]===============================
ECHO.
ECHO Batch file to start a command prompt as SYSTEM.
ECHO Must be run from an elevated command prompt.
ECHO.
ECHO Uses SCHTASKS to create and run a scheduled task that starts a
ECHO listening session with the Windows Debugger REMOTE.EXE tool, then
ECHO connects to it.
ECHO.
ECHO https://developer.microsoft.com/en-us/windows/hardware/download-windbg
ECHO.
ECHO Created: 10/7/2017    Last Modified: 10/9/2017
ECHO.
ECHO ==============================[ options ]==============================
ECHO.
ECHO -skipelevationcheck   Bypass checking if your prompt is elevated.
ECHO.
ECHO -selectarch           Interactively select 32- or 64-bit.
ECHO.
ECHO -cleanup              Remove task and XML file for any XML file in
ECHO                       TEMP\. Should only be needed if you close the
ECHO                       batch unexpectedly or say N to deleting the task.
ECHO.
ECHO -h / -help            Display this usage information.
ECHO.
ECHO Options are case-sensitive.
ECHO.

:DONE
ECHO Batch file is exiting.
PAUSE
ECHO.
ECHO ================================[ fin ]================================
ECHO.