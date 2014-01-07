DATA SEGMENT
MESG     DB 'Exit with Esc',0ah,0dh,'$'
LEDDATA  DB 81H,0EDH,43H,49H,2DH,19H,11H,0CDH,01H,09H
VEYELIUP DB 036H,12H,036H,12H,036H,12H,036H,12H ,036H,12H 
HOYELIUP DB 036H,12H,036H,12H,036H,12H,036H,12H ,036H,12H 
COUNT DB 9
TIME_STATUS DB 1;1表示1s，0表示0.5s
YELLOWTIME DB 9
YELLOW_STATUS DB 1
LSTATUS DB 1;设置灯的状态，1表示竖直方向的灯亮，0表示水平方向的灯亮
INT0A_OFF DW ?
INT0A_SEG DW ?        
DATA ENDS
CODE SEGMENT
     ASSUME CS:CODE,DS:DATA

DELAY PROC
	 PUSH CX
    PUSH BX
    MOV BX,0FFFH
LOOP2:MOV CX,0FFFFH
LOOP1:LOOP LOOP1
    DEC BX
    JNZ LOOP2
	 POP BX 
	 POP CX
	 RET 
DELAY ENDP

START:
     MOV AX,DATA
     MOV DS,AX     
     MOV AH,09H
 	 MOV DX,OFFSET MESG
	  INT 21h    ;显示提示信息 
  ;对计数器进行初始化编程
  ;对数码管对应计数器的初始化，选用计数器0和1，分别初始值为1000,500（周期为0.5s）
  MOV DX,307H;控制端口地址给dx
  MOV AL,00110110B;计数器0用16位计数方式3，二进制计数
  OUT DX,AL
  MOV AX,1000
  MOV DX,304H
  OUT DX,AL;先送低8位
  MOV AL,AH
  OUT DX,AL;后送高8位
  MOV DX,307H
  MOV AL,01110110B;计数器1用16位计数方式3，二进制计数
  OUT DX,AL
  MOV AX,500
  MOV DX,305H
  OUT DX,AL;先送低8位
  MOV AL,AH
  OUT DX,AL;后送高8位  
   
   ;初始化8255 
  MOV DX,303H        
  MOV AL,80H  ; A,B,C三个口均作为输出口
  OUT DX,AL
  
  ;路口的初始化状态
    MOV DX,300H
    MOV AX,09H  ;a口红灯亮，黄灯和绿灯灭
    OUT DX,AX
    
    MOV DX,301H
    MOV AX,12H  ;b口绿灯亮，红灯和黄灯灭
    OUT DX,AX
    CALL LIGHT
          
     MOV AX,3572H         ;获取原中断向量
     INT 21H
     MOV INT0A_OFF,BX     ;保存原中断向量
     MOV BX,ES
     MOV INT0A_SEG,BX
     CLI            ;关中断 
            
     MOV AX,2572H
     MOV DX,SEG LEDLIGHT    ;设置新的中断向量
     PUSH DS
     MOV DS,DX
     MOV DX,OFFSET LEDLIGHT
     INT 21H
     POP DS
     STI                       ;开中断
     IN  AL,0A1H              ;打开IRQ10
     AND AL,0FBH
     OUT 0A1H,AL
     IN  AL,21H                ;打开IRQ2
     AND AL,0FBH
     OUT 21H,AL
L1:  
	MOV AH,0BH            ;检查是否有Esc键按下
     INT 21H
     INC AL
     JNZ NEXT0              ; 若无键按下，则程序往下执行     
     MOV AH,08H             ;如有Esc键按下，则程序退出
     INT 21H
     CMP AL,27
     JZ  EXIT  
NEXT0:  
	call delay  
    JMP L1 
EXIT:
    MOV AX,2572H         ;恢复中断向量
    MOV DX,INT0A_SEG
    PUSH DS
    MOV DS,DX
    MOV DX,INT0A_OFF
    INT 21H
    POP DS
    IN  AL,0A1H         ;屏蔽IRQ10
    OR  AL,04H
    OUT 0A1H,AL
    IN  AL,21H         ;屏蔽IRQ2
    OR  AL,04H
    OUT 21H,AL
    MOV AX,4C00H       ;程序退出
    INT 21H  
            
LEDLIGHT PROC FAR      ;中断服务程序
    PUSH SI
    PUSH AX
    PUSH DX  
    CLI           ;关中断
    MOV AX,0
    MOV AL,COUNT
    sub AL,5
    Js YELLOWLIGHT;倒计时达到4时，黄灯开始闪烁
    JNs STATUS_CHANGE

STATUS_CHANGE:
     MOV AX,0
     MOV AL,TIME_STATUS
     CMP AL,0
     JZ CHANGE_TIME1;数码管值改变
     dec time_status
     JMP OVER
     
CHANGE_TIME1:
      mov time_status,1
      DEC COUNT;倒计时未到第4s，时间状态为1，继续递减
      JMP OVER 
             
YELLOWLIGHT:
     CALL LIGHT_UP
		mov ax,0
		mov al,count
		cmp al,9
		jz over
	;	mov ax,0
	;	mov al,count
	;	cmp al,0
	;	jz over
		mov ax,0
		mov al,time_status
		cmp al,0
		jnz change
		dec count
   ;  MOV AX,0
   ;  MOV AL,COUNT
   ;  CMP AL,9
    ; JZ TiTatus
TiTatus:
    MOV TIME_STATUS,1
	jmp over
 
change:
	dec time_status
     
OVER:
   MOV AX,0;显示中断
	MOV AL,COUNT
	ADD AL,30H
	MOV DL,AL
	MOV AH,2
	INT 21H
    
    MOV AL,62H       ;发中断结束命令
    MOV DX,0A0H
    OUT DX,AL        ;向从片8259发EOI命令
    OUT 020H,AL      ;向主片8259发EOI命令
    STI                ;开中断

    POP DX
    POP AX
    POP SI 
    call light    
    IRET
LEDLIGHT ENDP    

LIGHT_UP PROC
		PUSH AX
		PUSH SI
		PUSH DX
     MOV AX,0
     MOV AL,LSTATUS
     CMP AL,1
     JZ HORIZONAL_YELLOW
     JNZ VERTICAL_YELLOW
     
VERTICAL_YELLOW:
      MOV SI,OFFSET VEYELIUP
      MOV AX,0
      MOV AL,YELLOWTIME
      ADD SI,AX
      MOV AL,[SI]
      MOV DX,300H
      OUT DX,AL
      JMP CHANGE_TIME2

HORIZONAL_YELLOW:
      MOV SI,OFFSET HOYELIUP
      MOV AX,0
      MOV AL,YELLOWTIME
      ADD SI,AX
      MOV AL,[SI]
      MOV DX,301H
      OUT DX,AL
      JMP CHANGE_TIME2

CHANGE_TIME2:
       MOV AX,0
       MOV AL,YELLOWTIME
       CMP AL,0
       JNZ YELLOWTIME_DEC;黄灯闪烁直到倒计时到0
       MOV YELLOWTIME,9
       MOV COUNT,9
       ;改变灯的状态
       MOV AX,0
       MOV AL,LSTATUS
       CMP AL,1
       JZ VERTICAL  ;竖直方向
       JNZ HORIZONTAL;水平方向
YELLOWTIME_DEC:
       DEC YELLOWTIME
     ;  	mov ax,0
      ; mov al,time_status
     	; cmp al,0
      JMP go
       ;dec count
       
VERTICAL:
    MOV DX,300H
    MOV AX,12H  ;a口红灯亮，黄灯和绿灯灭
    OUT DX,AX 
    
    MOV DX,301H
    MOV AX,09H  ;b口绿灯亮，红灯和黄灯灭
    OUT DX,AX
    MOV LSTATUS,0
	mov time_status,1
    JMP GO
    
HORIZONTAL:
    MOV DX,300H
    MOV AX,09H ; a口绿灯亮，黄灯和红灯灭
    OUT DX,AX
    
    MOV DX,301H
    MOV AX,12H ; b口红灯亮，黄灯和绿灯灭
    OUT DX,AX
    MOV LSTATUS,1
	mov time_status,1
    JMP GO
GO:
    POP DX
    POP SI
    POP AX
    RET
LIGHT_UP ENDP
     
LIGHT PROC  ;数码管服务程序
    PUSH BX
    PUSH AX
    PUSH DX
    MOV SI,OFFSET LEDDATA
	MOV AX,0
	MOV AL,COUNT
	ADD SI,AX
	MOV AL,[SI]
    MOV DX,302H      ;数码管
    OUT DX,AL 
    POP DX
    POP AX
    POP BX
    RET
LIGHT ENDP
CODE ENDS
     END START





