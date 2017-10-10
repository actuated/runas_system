# runas_system
Batch file that uses WinDbg's remote.exe to start a command prompt as SYSTEM.

# Setup
* You are on a system with an elevated command prompt.
* Have this batch file in a folder.
* Place the 32- and 64-bit copies of the Windows Debugger `remote.exe` in `remote\x86\` and `remote\x64\` subdirectories of that folder, respectively.
  - Windows Debugger SDK: https://developer.microsoft.com/en-us/windows/hardware/download-windbg
  - `remote.exe` should install to `C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\` and `x64\`, respectively.
* Note: This has been tested on Windows 10.

# Usage
* Run from an elevated command prompt.
* Running `runas_system.bat` should not require any options or arguments.
* The script will:
  - Check for `remote.exe` in `remote\x86\` and `remote\x64\`, relative to the file location of the batch file (`%~dp0`).
  - Check if you're running it elevated by looking for an error from `net sessions`. Override this if you want with the option **-skipelevationcheck**.
  - Use the `%PROCESSOR_ARCHITECTURE%` environment variable to select 32- or 64-bit. To interactively select this, use the option **-selectarch**.
  - Check for `temp\` (again, relative to the file location of the batch file) and create it if necessary.
  - Build a scheduled task XML file in `temp\`, using a random eight-digit string as the file name.
  - Use `schtasks` to create a task using the XML file, named with the same eight-digit string.
  - Start the task, which starts a listening `remote.exe` sessions using the eight-digit string as its ID.
  - Use `remote.exe` to connect to the session.
  - You should then have a prompt as SYSTEM, at the file location of the batch file.
  - Exit the `remote.exe` session by entering the command `exit`.
  - You'll be prompted (y/n) about deleting the task.
  - The script will delete the XML file from `temp\`.
* If the batch file closes unexpectedly, run `runas_system.bat` with the option **-cleanup** to check for XML files in `temp\`, and delete tasks using those IDs.
* The **-h** and **-help** options will display usage information.

# Example Output
```
d:\test>whoami
desktop\ted

d:\test>runas_system.bat

============[ runas_system.bat - Ted R (github: actuated) ]============

Checking for REMOTE.EXE in d:\test\REMOTE\X86\ and X64\...

Checking privileges...

Checking if this is a 32- or 64-bit system...
64-bit identified.

Creating SCHTASKS XML file at d:\test\TEMP\72506206.xml...

Creating task 72506206 to run d:\test\remote\x64\remote.exe...
SUCCESS: The scheduled task "72506206" has successfully been created.

Running task to start REMOTE.EXE listening with session 72506206...
SUCCESS: Attempted to run the scheduled task "72506206".

Connecting to REMOTE.EXE session 72506206...
Run the command "exit" to exit.

**************************************
***********     REMOTE    ************
***********     CLIENT    ************
**************************************
Connected...

Microsoft Windows [Version 10.0.15063]
(c) 2017 Microsoft Corporation. All rights reserved.

d:\test>
**Remote: Connected to DESKTOP Ted [Sun 12:29 AM]
whoami /user
whoami /user

USER INFORMATION
----------------

User Name           SID
=================== ========
nt authority\system S-1-5-18

d:\test>exit
exit
*** SESSION OVER ***

Ready to clean up the 72506206 task and XML file.
Press any key to continue . . .
WARNING: Are you sure you want to remove the task "72506206" (Y/N)? Y
SUCCESS: The scheduled task "72506206" was successfully deleted.

================================[ fin ]================================
```
