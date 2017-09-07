// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed.
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.


(LOOP)  // infinite loop

// Keyboard

@KBD
D=M   // Current key pressed, 0 if empty

@BLACK
D;JNE // Jump if any key is being pressed
D=0
@BLACKEND
0;JMP
(BLACK)
D=-1
(BLACKEND)
@pixel
M=D

// Set SCREEN

@i
M=0   // i = 0

(DRAWSCREEN)

// 8192 * 16bits
@i
D=M
@8192
D=D-A
@ENDDRAWSCREEN
D;JGE   // End if i < 8192

@SCREEN
D=A
@i
D=D+M
@screenpos
M=D
@pixel
D=M
@screenpos
A=M
M=D

@i
M=M+1   // i = i + 1

@DRAWSCREEN
0;JMP
(ENDDRAWSCREEN)

@LOOP
0;JMP // Jump to LOOP (infinite loop)
