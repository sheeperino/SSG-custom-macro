; SSG Custom Macro 1.16+ v1.4.1
; Author: Sheep
; Credits: logwet, xheb_, Peej, Specnr

; Guide:
; - Change the settings however you like, adjust your reset hotkeys (bottom of the script)
; - Double click the file to run
; - Enjoy 


#NoEnv
#SingleInstance Force
Process, Priority, , A
SetWorkingDir %A_ScriptDir%
SetDefaultMouseSpeed, 0
SetTitleMatchMode, 2
CoordMode, Mouse, Window

global oldWorldsFolder := "C:\Users\Sophie\Desktop\MultiMC\instances\1.12.2\.minecraft\oldWorlds\"
global SavesDirectories := ["C:\Users\Sophie\Desktop\MultiMC\instances\1.17.11\.minecraft\saves\"]

global delayType := "Accurate" ; Accurate or Standard
global delay := 60 ; Delay between keypresses
global switchDelay := 0
global seedDelay := 60 ; Delay before typing the seed
global seed := -5362871956303579298 ; This is where you put the seed
global difficulty := 0 ; Normal (0), Hard (1), Peaceful (2), Easy (3)
global countAttempts := True
global worldMoving := True
global attemptsFile := "Macro_Attempts_1.16+.txt" ; Name of the attempts file

global currInst := -1
global PIDs := GetAllPIDs()
global instances := SavesDirectories.MaxIndex()

IfNotExist, %oldWorldsFolder%
  FileCreateDir %oldWorldsFolder%


CreateWorld(idx)
{
  if (idx := GetActiveInstanceNum()) > 0
  {
    pid := PIDs[idx]  
    WaitMenuScreen(idx)
    if (instances > 1) {
      nextIdx := Mod(idx, instances) + 1
      SwitchInstance(nextIdx)
    }
  	
  	Reset(pid)
      sleep, 50
    if (worldMoving)
  	  MoveWorlds(idx)

    if (countAttempts)
      CountAttempts()
  }
}

Reset(pid)
{
    SetKeyDelay, -1
	Sleep(delay)
    	ControlSend, ahk_parent, {Blind}{Tab}{Enter}, ahk_pid %pid% ; Singleplayer
  	Sleep(delay)
  	ControlSend, ahk_parent, {Blind}{Tab 3}{Enter}, ahk_pid %pid% ; World list
  	Sleep(delay)
  	ControlSend, ahk_parent, {Blind}{Tab 2}, ahk_pid %pid% ; World options
    if (difficulty != 0) {
      ControlSend, ahk_parent, {Enter %difficulty%}, ahk_pid %pid% ; Change difficulty
      Sleep(delay)
    }
    ControlSend, ahk_parent, {Blind}{Tab 4}{Enter}, ahk_pid %pid% ; More World Options
  	Sleep(delay)
  	ControlSend, ahk_parent, {Blind}{Tab 3}, ahk_pid %pid%
  	Sleep(seedDelay)
    ControlSend, ahk_parent, %seed%, ahk_pid %pid% ; Seed
    Sleep(delay)
  	ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %pid% ; Create New World
}

ExitWorld()
{
  SetKeyDelay, -1
    WinGetTitle, title, ahk_pid %pid%
    if (GetActiveInstanceNum() == idx)
      return

  Send {Blind}{Shift Down}{Tab}{Shift Up}
  Send {Blind}{Enter}
  Send {Blind}{Esc}
  sleep, 10
  Send {Blind}{Shift Down}{Tab}{Shift Up}
  Send {Blind}{Enter}
	CreateWorld(idx)
return
}

Sleep(time) {
  if (delayType == "Accurate")
    DllCall("Sleep",UInt,time)
  else
    Sleep, time
}

MoveWorlds(idx)
{
  dir := savesDirectories[idx]
  OutputDebug, moving worlds of %dir%
  Loop, Files, %dir%*, D
  {
    If (InStr(A_LoopFileName, "New World"))
      FileMoveDir, %dir%%A_LoopFileName%, %oldWorldsFolder%%A_LoopFileName%%A_NowUTC%, R
  }
}

CountAttempts() {
  file := FileOpen(attemptsFile, "rw")

  t := SubStr(file.ReadLine(), 1, -1)     
  if t is not integer
      t := 0
  s := file.ReadLine()
  if s is not integer
      s := 0

  tFile := FileOpen("attempts_time.txt", "rw")
  tOutput := tFile.Read()
  if tOutput is not integer
  {
    tOutput := A_Now
    tFile.Write(tOutput)
  }
  tFile.Close()

  tOutput += 24, hours
  if (A_Now >= tOutput) {
    tFile := FileOpen("attempts_time.txt", "w")
    tFile.Write()
    tFile.Close()

    file := FileOpen(attemptsFile, "w")
    file.Seek(StrLen(t)+1)
    file.Write(s := 0)
  }
  file := FileOpen(attemptsFile, "w")
  file.WriteLine(t+1)
  file.Write(s+1)

  file.Close()
}

GetActiveInstanceNum() {
  WinGet, pid, PID, A
  WinGetTitle, title, ahk_pid %pid%
  for i, tmppid in PIDs {
    if (tmppid == pid)
      return i
  }
}

GetInstanceNum(pid)
{
  command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", pid)
  rawOut := RunHide(command)
  for i, savesDir in SavesDirectories {
    StringTrimRight, tmp, savesDir, 18
    subStr := StrReplace(tmp, "\", "/")
    if (InStr(rawOut, subStr))
      return i
  }
return -1
}

SwitchInstance(idx)
{
  currInst := idx
  pid := PIDs[idx]
  Sleep(switchDelay)
  WinSet, AlwaysOnTop, On, ahk_pid %pid%
  WinSet, AlwaysOnTop, Off, ahk_pid %pid%
  Send {Numpad%idx% down}
  sleep, 50
  Send {Numpad%idx% up}
  Send {Blind}{RButton}
}

RunHide(Command)
{
	OutputDebug, runhide
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  Run, %ComSpec%,, Hide, cPid
  WinWait, ahk_pid %cPid%
  DetectHiddenWindows, %dhw%
  DllCall("AttachConsole", "uint", cPid)

  Shell := ComObjCreate("WScript.Shell")
  Exec := Shell.Exec(Command)
  Result := Exec.StdOut.ReadAll()

  DllCall("FreeConsole")
  Process, Close, %cPid%
Return Result
}

GetAllPIDs()
{
  OutputDebug, getting all pids 
  orderedPIDs := []
  loop, %instances%
    orderedPIDs.Push(-1)
  WinGet, all, list, ahk_exe javaw.exe
  Loop, %all%
  {
    WinGet, pid, PID, % "ahk_id " all%A_Index%
      Output .= pid "`n"
  }
  tmpPids := StrSplit(Output, "`n")
  for i, pid in tmpPids {
    if (pid) {
      inst := GetInstanceNum(pid)
      OutputDebug, instance num: %inst%
      orderedPIDs[inst] := pid
	  OutputDebug, pid %pid%
    }
  }
return orderedPIDs
}

WaitMenuScreen(idx)
{
  rawLogFile := StrReplace(savesDirectories[idx], "saves", "logs\latest.log")
  StringTrimRight, logFile, rawLogFile, 1
  numLines := 0
  Loop, Read, %logFile%
  {
    numLines += 1
  }
  mainMenu := False
  While (!mainMenu)
  {
    startTime := A_TickCount
    Loop, Read, %logFile%
    { 
      if ((numLines - A_Index) < 1)
      {
        if (InStr(A_LoopReadLine, "Stopping worker threads")) {
          mainMenu := True
        }
      }
    }
  }
}

SetTitles() {
  for i, pid in PIDs {
    WinSetTitle, ahk_pid %pid%, , Minecraft - Instance %i%
  }
}

#IfWinActive, ahk_exe javaw.exe
{
*CapsLock::
   ExitWorld()
return

*F12::
  SetTitles()
return

*!End::
  MsgBox, Script terminated by user
  ExitApp
}