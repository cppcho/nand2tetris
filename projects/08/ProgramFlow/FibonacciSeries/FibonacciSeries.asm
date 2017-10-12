// Bootstrap
// SP=256
// call Sys.init
// File: FibonacciSeries
// push argument 1
@ARG
D=M
@1
D=D+A
A=D
D=M
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
// push constant 0
@0
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop that 0
@SP
M=M-1
@THAT
D=M
@0
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
// push constant 1
@1
D=A
@SP
A=M
M=D
@SP
M=M+1
// pop that 1
@SP
M=M-1
@THAT
D=M
@1
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
// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 2
@2
D=A
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
// pop argument 0
@SP
M=M-1
@ARG
D=M
@0
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
// label MAIN_LOOP_START
(functionName.MAIN_LOOP_START)
// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// if-goto COMPUTE_ELEMENT
@SP
M=M-1
A=M
D=M
@functionName.COMPUTE_ELEMENT
D;JGT
// goto END_PROGRAM
@functionName.END_PROGRAM
0;JMP
// label COMPUTE_ELEMENT
(functionName.COMPUTE_ELEMENT)
// push that 0
@THAT
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push that 1
@THAT
D=M
@1
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
// pop that 2
@SP
M=M-1
@THAT
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
// push pointer 1
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 1
@1
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
// pop pointer 1
@SP
M=M-1
@SP
A=M
D=M
M=0
@THAT
M=D
// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 1
@1
D=A
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
// pop argument 0
@SP
M=M-1
@ARG
D=M
@0
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
// goto MAIN_LOOP_START
@functionName.MAIN_LOOP_START
0;JMP
// label END_PROGRAM
(functionName.END_PROGRAM)
