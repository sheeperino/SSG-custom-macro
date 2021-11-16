﻿; Press Left Control + Left Mouse Button to setup coordinates

#NoEnv
#SingleInstance Force
CoordMode, Mouse, Window


global X :=
global Y :=
global n = 1
global screens = 5 ; SSG no hardcore = 5, RSG no hardcore = 3
                   ; SSG hardcore    = 6, RSG hardcore    = 4
                   ; add or remove extra ones if needed
FileDelete, SSG_ClickCoords.txt
FileAppend, global coords := [, SSG_ClickCoords.txt

ClickCoords() {
    MouseGetPos, X, Y
    FileAppend, [%X%`, %Y%], SSG_ClickCoords.txt
    if (n < screens)
        FileAppend, `,  , SSG_ClickCoords.txt
    else
    {
		FileAppend,] , SSG_ClickCoords.txt
        MsgBox, All Done!
        Run, Pre_1.16_SSG_Macro.ahk
        ExitApp
    }
    n += 1 
}


~^LButton::
    ClickCoords()
return