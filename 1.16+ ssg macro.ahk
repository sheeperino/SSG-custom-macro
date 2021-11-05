; SSG Custom Macro v1.2.0
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
global SavesDirectories := ["C:\Users\Sophie\Desktop\MultiMC\instances\1.16.11\.minecraft\saves\"]

global delay := 50 ; Delay between keypresses
global switchDelay := 250
global seed := -5362871956303579298 ; This is where you put the seed
global difficulty := 0 ; Normal (0), Hard (1), Peaceful (2), Easy (3)
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
  	ControlSend, ahk_parent, {Tab}{Enter}, ahk_pid %pid% ; Singleplayer
  	DllCall("Sleep",UInt,delay)
  	ControlSend, ahk_parent, {Tab 3}{Enter}, ahk_pid %pid% ; World list
  	DllCall("Sleep",UInt,delay)
  	ControlSend, ahk_parent, {Tab 2}{Enter %difficulty%}, ahk_pid %pid% ; World options
    DllCall("Sleep",UInt,delay)
    ControlSend, ahk_parent, {Tab 4}{Enter}, ahk_pid %pid%
  	DllCall("Sleep",UInt,delay)
  	ControlSend, ahk_parent, {Tab 3}%seed%, ahk_pid %pid% ; Seed
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

<<<<<<< HEAD
  Send +{Tab}
  Send {Enter}
  Send {Esc}
  DllCall("Sleep",UInt,10)
  Send +{Tab}
  Send {Enter}
=======
	Send {Esc}
	DllCall("Sleep",UInt,delay)
    send +{Tab}{Enter}
>>>>>>> 21ec3ffe2d192a0a9ffb2059c5e0e12cdae91a82
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
    if (InStr(title, "Minecraft* ") || InStr(title, "Instance") && !InStr(title, "Not Responding"))
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
         PixelSearch, Px, Py, 0, 0, W, H, 0xFCFC00, 1, Fast RGB
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
}
