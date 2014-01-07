DATA SEGMENT
MESG     DB 'Exit with Esc',0ah,0dh,'$'
LEDDATA  DB 81H,0EDH,43H,49H,2DH,19H,11H,0CDH,01H,09H
VEYELIUP DB 036H,12H,036H,12H,036H,12H,036H,12H ,036H,12H 
HOYELIUP DB 036H,12H,036H,12H,036H,12H,036H,12H ,036H,12H 
COUNT DB 9
TIME_STATUS DB 1;1��ʾ1s��0��ʾ0.5s
YELLOWTIME DB 9
YELLOW_STATUS DB 1
LSTATUS DB 1;���õƵ�״̬��1��ʾ��ֱ����ĵ�����0��ʾˮƽ����ĵ���
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
	  INT 21h    ;��ʾ��ʾ��Ϣ 
  ;�Լ��������г�ʼ�����
  ;������ܶ�Ӧ�������ĳ�ʼ����ѡ�ü�����0��1���ֱ��ʼֵΪ1000,500������Ϊ0.5s��
  MOV DX,307H;���ƶ˿ڵ�ַ��dx
  MOV AL,00110110B;������0��16λ������ʽ3�������Ƽ���
  OUT DX,AL
  MOV AX,1000
  MOV DX,304H
  OUT DX,AL;���͵�8λ
  MOV AL,AH
  OUT DX,AL;���͸�8λ
  MOV DX,307H
  MOV AL,01110110B;������1��16λ������ʽ3�������Ƽ���
  OUT DX,AL
  MOV AX,500
  MOV DX,305H
  OUT DX,AL;���͵�8λ
  MOV AL,AH
  OUT DX,AL;���͸�8λ  
   
   ;��ʼ��8255 
  MOV DX,303H        
  MOV AL,80H  ; A,B,C�����ھ���Ϊ�����
  OUT DX,AL
  
  ;·�ڵĳ�ʼ��״̬
    MOV DX,300H
    MOV AX,09H  ;a�ں�������Ƶƺ��̵���
    OUT DX,AX
    
    MOV DX,301H
    MOV AX,12H  ;b���̵�������ƺͻƵ���
    OUT DX,AX
    CALL LIGHT
          
     MOV AX,3572H         ;��ȡԭ�ж�����
     INT 21H
     MOV INT0A_OFF,BX     ;����ԭ�ж�����
     MOV BX,ES
     MOV INT0A_SEG,BX
     CLI            ;���ж� 
            
     MOV AX,2572H
     MOV DX,SEG LEDLIGHT    ;�����µ��ж�����
     PUSH DS
     MOV DS,DX
     MOV DX,OFFSET LEDLIGHT
     INT 21H
     POP DS
     STI                       ;���ж�
     IN  AL,0A1H              ;��IRQ10
     AND AL,0FBH
     OUT 0A1H,AL
     IN  AL,21H                ;��IRQ2
     AND AL,0FBH
     OUT 21H,AL
L1:  
	MOV AH,0BH            ;����Ƿ���Esc������
     INT 21H
     INC AL
     JNZ NEXT0              ; ���޼����£����������ִ��     
     MOV AH,08H             ;����Esc�����£�������˳�
     INT 21H
     CMP AL,27
     JZ  EXIT  
NEXT0:  
	call delay  
    JMP L1 
EXIT:
    MOV AX,2572H         ;�ָ��ж�����
    MOV DX,INT0A_SEG
    PUSH DS
    MOV DS,DX
    MOV DX,INT0A_OFF
    INT 21H
    POP DS
    IN  AL,0A1H         ;����IRQ10
    OR  AL,04H
    OUT 0A1H,AL
    IN  AL,21H         ;����IRQ2
    OR  AL,04H
    OUT 21H,AL
    MOV AX,4C00H       ;�����˳�
    INT 21H  
            
LEDLIGHT PROC FAR      ;�жϷ������
    PUSH SI
    PUSH AX
    PUSH DX  
    CLI           ;���ж�
    MOV AX,0
    MOV AL,COUNT
    sub AL,5
    Js YELLOWLIGHT;����ʱ�ﵽ4ʱ���Ƶƿ�ʼ��˸
    JNs STATUS_CHANGE

STATUS_CHANGE:
     MOV AX,0
     MOV AL,TIME_STATUS
     CMP AL,0
     JZ CHANGE_TIME1;�����ֵ�ı�
     dec time_status
     JMP OVER
     
CHANGE_TIME1:
      mov time_status,1
      DEC COUNT;����ʱδ����4s��ʱ��״̬Ϊ1�������ݼ�
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
   MOV AX,0;��ʾ�ж�
	MOV AL,COUNT
	ADD AL,30H
	MOV DL,AL
	MOV AH,2
	INT 21H
    
    MOV AL,62H       ;���жϽ�������
    MOV DX,0A0H
    OUT DX,AL        ;���Ƭ8259��EOI����
    OUT 020H,AL      ;����Ƭ8259��EOI����
    STI                ;���ж�

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
       JNZ YELLOWTIME_DEC;�Ƶ���˸ֱ������ʱ��0
       MOV YELLOWTIME,9
       MOV COUNT,9
       ;�ı�Ƶ�״̬
       MOV AX,0
       MOV AL,LSTATUS
       CMP AL,1
       JZ VERTICAL  ;��ֱ����
       JNZ HORIZONTAL;ˮƽ����
YELLOWTIME_DEC:
       DEC YELLOWTIME
     ;  	mov ax,0
      ; mov al,time_status
     	; cmp al,0
      JMP go
       ;dec count
       
VERTICAL:
    MOV DX,300H
    MOV AX,12H  ;a�ں�������Ƶƺ��̵���
    OUT DX,AX 
    
    MOV DX,301H
    MOV AX,09H  ;b���̵�������ƺͻƵ���
    OUT DX,AX
    MOV LSTATUS,0
	mov time_status,1
    JMP GO
    
HORIZONTAL:
    MOV DX,300H
    MOV AX,09H ; a���̵������Ƶƺͺ����
    OUT DX,AX
    
    MOV DX,301H
    MOV AX,12H ; b�ں�������Ƶƺ��̵���
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
     
LIGHT PROC  ;����ܷ������
    PUSH BX
    PUSH AX
    PUSH DX
    MOV SI,OFFSET LEDDATA
	MOV AX,0
	MOV AL,COUNT
	ADD SI,AX
	MOV AL,[SI]
    MOV DX,302H      ;�����
    OUT DX,AL 
    POP DX
    POP AX
    POP BX
    RET
LIGHT ENDP
CODE ENDS
     END START





