; SSG Custom Macro v1.2.0
; Author: Sheep
; Credits: logwet, xheb_, Peej, Specnr

; Guide:
; - Change the settings however you like, adjust your reset hotkeys (bottom of the script)
; - Double click the file to run
; - Enjoy


#NoEnv
#SingleInstance Force
#Include SSG_ClickCoords.txt
Process, Priority, , A
SetWorkingDir %A_ScriptDir%
SetDefaultMouseSpeed, 0
SetTitleMatchMode, 2
CoordMode, Mouse, Window

global version := 1.14 ; You can leave this empty if not using 1.15
global oldWorldsFolder := "C:\Users\Sophie\Desktop\MultiMC\instances\1.8.9unused\oldWorlds\"
global SavesDirectories := ["C:\Users\Sophie\Desktop\MultiMC\instances\1.14.41\.minecraft\saves\"]

global delay := 50 ; Delay between keypresses
global switchDelay := 250
global seed := 225874918561344128 ; This is where you put the seed
global countAttempts := True
global worldMoving := True

global currInst := -1
global PIDs := GetAllPIDs()
global instances := SavesDirectories.MaxIndex()

IfNotExist, %oldWorldsFolder%
  FileCreateDir %oldWorldsFolder%


CreateWorld(idx)
{
  WinGetPos, X, Y, W, H, Minecraft
  WaitMenuScreen(W, H)
  if (idx := GetActiveInstanceNum()) > 0
  {
    SetKeyDelay, -1
  	pid := PIDs[idx]
  	MouseClick, Left, coords[2][1], coords[2][2] ; Singleplayer
  	DllCall("Sleep",UInt,delay)
  	MouseClick, Left, coords[3][1], coords[3][2] ; World list
  	DllCall("Sleep",UInt,delay)
  	MouseClick, Left, coords[4][1], coords[4][2], ahk_pid %pid% ; World options
    DllCall("Sleep",UInt,delay)
    MouseClick, Left, coords[5][1], coords[5][2] %pid%
  	Send %seed% ; Seed
  	DllCall("Sleep",UInt,delay)
  	ControlSend, ahk_parent, {Enter}, ahk_pid %pid% ; Create New World
      sleep, 50
  	nextIdx := Mod(idx, instances) + 1
  	SwitchInstance(nextIdx)
    if (worldMoving)
  	  MoveWorlds(idx)

    if (countAttempts)
    {
      FileRead, WorldNumber, SSG_attempts.txt
      if (ErrorLevel)
        WorldNumber = 0
      else
        FileDelete, SSG_attempts.txt
      WorldNumber += 1
      FileAppend, %WorldNumber%, SSG_attempts.txt
    }
  }
}

ExitWorld()
{
  SetKeyDelay, 1
  pid := PIDs[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (GetActiveInstanceNum() == idx)
      return

  Send {Esc}
  DllCall("Sleep",UInt,10)
  MouseClick, Left, coords[1][1], coords[1][2]
	CreateWorld(idx)
return
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
  WinActivate, LiveSplit
  sleep, switchDelay
  WinActivate, ahk_pid %pid%
  send {Numpad%idx% down}
  sleep, 50
  send {Numpad%idx% up}
}

ReadCoords(){
  i = 1
  loop {
    IniRead, X%i%, SSG.ini, Coords%i%, X%i%
    IniRead, Y%i%, SSG.ini, Coords%i%, Y%i%
    i += 1
    if (i == 6){
        break
      }
  }
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
  WinGet, all, list
  Loop, %all%
  {
    WinGet, pid, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, "Minecraft 1.") || InStr(title, "Minecraft* 1.") || InStr(title, "Instance") && !InStr(title, "Not Responding"))
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
      IfWinActive, Minecraft
      {
        if (version == 1.15)
         PixelSearch, Px, Py, 0, 0, W, H, 0xFCFC00, 1, Fast RGB
        else
         PixelSearch, Px, Py, 0, 0, W, H, 0xFFFF00, 1, Fast RGB
         if (!ErrorLevel) {
            Sleep, 100
            IfWinActive, Minecraft
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

#IfWinActive, Minecraft
{
*CapsLock::
   ExitWorld()
return

*F12::
  SetTitles()
return

+F9::
  Run, SSG_ClickSetup.ahk
  ExitApp
return
}
