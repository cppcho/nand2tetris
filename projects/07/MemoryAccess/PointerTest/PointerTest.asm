// File: projects/07/MemoryAccess/PointerTest/PointerTest.vm
// push constant 3030
@3030
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop pointer 0
@SP
M=M-1
@SP
A=M
D=M
M=0
@THIS
M=D
// push constant 3040
@3040
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop pointer 1
@SP
M=M-1
@SP
A=M
D=M
M=0
@THAT
M=D
// push constant 32
@32
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop this 2
@SP
M=M-1
@THIS
D=M
@2
D=D+A
@R13
M=D
@SP
A=M
D=M
M=0
@R13
A=M
M=D
// push constant 46
@46
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop that 6
@SP
M=M-1
@THAT
D=M
@6
D=D+A
@R13
M=D
@SP
A=M
D=M
M=0
@R13
A=M
M=D
// push pointer 0
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
// push pointer 1
@THAT
D=M
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
// push this 2
@THIS
D=M
@2
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// sub
@SP
AM=M-1
D=M
M=0
@SP
AM=M-1
D=M-D
M=0
@SP
A=M
M=D
@SP
M=M+1
// push that 6
@THAT
D=M
@6
D=D+A
A=D
D=M
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
