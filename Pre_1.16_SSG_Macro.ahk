; SSG Custom Macro Pre1.16 v1.5.1
; Author: Sheep
; Credits: logwet, xheb_, Peej, Specnr

; Guide:
; - Change the settings however you like, adjust your reset hotkeys (bottom of the script)
; - Double click the file to run
; - Enjoy


#NoEnv
#SingleInstance Force
#Include SSG_ClickCoords.txt
#MaxThreadsPerHotkey 100
Process, Priority, , A
SetWorkingDir %A_ScriptDir%
SetDefaultMouseSpeed, 0
SetTitleMatchMode, 2
CoordMode, Mouse, Window

global version := 1.14 ; You can leave this empty if not using 1.15
global oldWorldsFolder := "C:\Users\Sophie\Desktop\MultiMC\instances\1.8.9unused\oldWorlds\"
global SavesDirectories := ["C:\Users\Sophie\Desktop\MultiMC\instances\1.8.91\.minecraft\saves\"]

global delayType := "Accurate" ; Accurate or Standard
global delay := 60 ; Delay between keypresses
global switchDelay := 0
global seedDelay := 60 ; Delay before typing the seed 
global seed := 225874918561344128 ; Leave blank if not running SSG
global countAttempts := True
global worldMoving := True
global attemptsFile := "Macro_Attempts_Pre1.16.txt" ; Name of the attempts file

global currInst := -1
global PIDs := GetAllPIDs()
global instances := SavesDirectories.MaxIndex()

IfNotExist, %oldWorldsFolder%
  FileCreateDir %oldWorldsFolder%

for i, dir in SavesDirectories {
  if (SubStr(dir, 0)) != "\"
    SavesDirectories[i] := dir . "\"
}


CreateWorld(idx)
{
  if (idx := GetActiveInstanceNum()) > 0
  {
  	pid := PIDs[idx]
    WinGetPos, X, Y, W, H, ahk_exe javaw.exe
    WaitMenuScreen(W, H)
    
    Reset()
    if (instances > 1) {
      nextIdx := Mod(idx, instances) + 1
      SwitchInstance(nextIdx)
    }
      sleep, 50
    if (worldMoving)
  	  MoveWorlds(idx)

    if (countAttempts)
      CountAttempts()
  }
}

Reset()
{
  SetKeyDelay, -1
  Sleep(delay)
  n = 2
  loop
  {
    MouseClick, Left, coords[n][1], coords[n][2]
    n += 1
    if (n > coords.MaxIndex())
      break
    Sleep(delay)
  }
  if (seed) {
    Sleep(seedDelay)
    Send {Blind}{Text}%seed%
    Sleep(delay)
  }
  Send {Blind}{Enter} ; Create New World
}

ExitWorld()
{
  SetKeyDelay, 1
  pid := PIDs[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (GetActiveInstanceNum() == idx)
      return

  Send {Blind}{Esc}
  sleep, 10
  MouseClick, Left, coords[1][1], coords[1][2]
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

  tFile := FileOpen("attempts_time_" . attemptsFile, "rw")
  tOutput := tFile.Read()
  if tOutput is not integer
  {
    tOutput := A_Now
    tFile.Write(tOutput)
  }
  tFile.Close()

  tOutput += 24, hours
  if (A_Now >= tOutput) {
    tFile := FileOpen("attempts_time_" . attemptsFile, "w")
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

WaitMenuScreen(W, H)
{
   start := A_TickCount
   Loop {
      IfWinActive, ahk_exe javaw.exe
      {
        if (version == 1.15)
         PixelSearch, Px, Py, 0, 0, W, H, 0xFCFC00, 1, Fast RGB
        else
         PixelSearch, Px, Py, 0, 0, W, H, 0xFFFF00, 1, Fast RGB
         if (!ErrorLevel) {
            Sleep(100)
            IfWinActive, ahk_exe javaw.exe
            {
               return
            }
         }
      }
      now := A_TickCount-start
      if (now > 15000) {
         ; Reload
         Sleep 1000
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

*+F9::
  Run, SSG_ClickSetup.ahk
  ExitApp
return

*!End::
  MsgBox, Script terminated by user
  ExitApp
return
}
