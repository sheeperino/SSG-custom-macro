; Press Left Control + Left Mouse Button to setup 1 coordinates

#NoEnv
#SingleInstance Force
CoordMode, Mouse, Window


global X :=
global Y :=
global n = 1
global screens = 5 ; Number of screens
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