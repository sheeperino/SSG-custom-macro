; Press Left Control + Left Mouse Button to setup coordinates
; Press Left Control + Enter to finish setup

#NoEnv
#SingleInstance Force
CoordMode, Mouse, Window


global X :=
global Y :=

FileDelete, SSG_ClickCoords.txt
FileAppend, global coords := [, SSG_ClickCoords.txt

ClickCoords() {
    MouseGetPos, X, Y
    FileAppend, [%X%`, %Y%], SSG_ClickCoords.txt
    FileAppend, `,  , SSG_ClickCoords.txt
}

EndSetup() {
    FileRead, lines, SSG_ClickCoords.txt
    StringTrimRight, lines, lines, 1
    FileDelete, SSG_ClickCoords.txt
    FileAppend, %lines%, SSG_ClickCoords.txt
    FileAppend, ], SSG_ClickCoords.txt
    MsgBox, All Done!
    Run, Pre_1.16_SSG_Macro.ahk
    ExitApp
}


~^LButton::
    ClickCoords()
return

~^Enter::
    EndSetup()
return