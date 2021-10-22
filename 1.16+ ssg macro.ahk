;
; Minecraft Reset Script v1.1
; Author:   onvo
; Modifications for SSG by:   logwet and xheb_
; Other stuff + Multi Adaptation by Sheep, hi
;

; Script Function:
;  The following only apply inside the Minecraft window:
;   1) When on the title screen, the "PgUp" key will create a world on Easy
;   2) After loading in the world, "PgUp" will exit the world and then auto create another world on Easy
;   3) To just exit the world and not auto create world, press "PgDn" on keyboard.
;   4) To change the "PgUp", "PgDn" keybinds, change the keys before the double colon "::" and reload the script


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
global countAttempts := True

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
	ControlSend, ahk_parent, {Tab}{Enter}, ahk_pid %pid%
	DllCall("Sleep",UInt,delay)
	ControlSend, ahk_parent, {Tab 3}{Enter}, ahk_pid %pid%
	DllCall("Sleep",UInt,delay)
	ControlSend, ahk_parent, {Tab 6}{Enter}, ahk_pid %pid%
	DllCall("Sleep",UInt,delay)
	ControlSend, ahk_parent, {Tab 3}%seed%, ahk_pid %pid%
	DllCall("Sleep",UInt,delay)
	ControlSend, ahk_parent, {Enter}, ahk_pid %pid%
        sleep, 50
	nextIdx := Mod(idx, instances) + 1
	SwitchInstance(nextIdx)
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
	DllCall("Sleep",UInt,delay)
    send +{Tab}{Enter} 
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

PgDn::
   ExitWorld()
return

*F12::
  SetTitles()
return
}

