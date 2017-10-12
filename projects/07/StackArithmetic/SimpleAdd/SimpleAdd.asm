// Initialize SP (RAM[0]) to 256 (Initial stack pointer)
@256
D=A
@SP
M=D
// File: projects/07/StackArithmetic/SimpleAdd/SimpleAdd.vm
// push constant ${index}
@7
D=A
@SP
A=M
M=D
@SP
M=M+1
// push constant ${index}
@8
D=A
@SP
A=M
M=D
@SP
M=M+1
// add
@SP
AM=M-1
D=M
M=0
@SP
AM=M-1
D=D+M
M=0
@SP
A=M
M=D
@SP
M=M+1
