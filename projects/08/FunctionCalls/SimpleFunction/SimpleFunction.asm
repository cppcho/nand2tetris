// Bootstrap
// SP=256
// call Sys.init
// File: SimpleFunction
// function SimpleFunction.test 2
// push constant 0
@0
D=A
@SP
A=M
M=D
@SP
M=M+1
// push constant 0
@0
D=A
@SP
A=M
M=D
@SP
M=M+1
// push local 0
@LCL
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
// push local 1
@LCL
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
// not
@SP
AM=M-1
D=M
M=0
D=!D
@SP
A=M
M=D
@SP
M=M+1
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
// return
@LCL
D=M
@R13
M=D
@5
D=D-A
A=D
D=M
@R14
M=D
@SP
AM=M-1
D=M
M=0
@ARG
A=M
M=D
@ARG
D=M+1
@SP
M=D
@R13
A=M-1
D=M
@THAT
M=D
@R13
D=M
@2
D=D-A
A=D
D=M
@THIS
M=D
@R13
D=M
@3
D=D-A
A=D
D=M
@ARG
M=D
@R13
D=M
@4
D=D-A
A=D
D=M
@LCL
M=D
@R14
A=M
0;JMP
