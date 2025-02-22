;************************************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Contador Binario con Interrupciones
;
; Autor: Juan Chang
; Descripción: Implementa un contador binario de 4 bits con 2 botones
;              utilizando interrupciones on-change y pull-ups internos.
;
; Hardware: ATMega328P
;************************************************************************

.include "M328PDEF.inc"		

.org 0x0000
    RJMP START				; Salto al inicio del programa

.org 0x0006					; Vector de interrupción para PCINT0
    RJMP CHECK_PUSH			; Saltar a la rutina a la subrrutina 

.org 0x0020					; Vector de interrupción para TIMER0 OVF
	RJMP TIMER0				; Saltar a la rutina a la subrrutina 

START:
;Confifurar LEDs
    CLI                     ; Deshabilitar interrupciones mientras se configurax
    LDI R16, 0x1F
    OUT DDRC, R16           ; Configurar PC0-PC4 como salida (LEDs)

    LDI R16, 0x00
    OUT DDRB, R16           ; Configurar PB0 y PB1 como entrada

    LDI R16, 0x03
    OUT PORTB, R16          ; Habilitar pull-ups en PB0 y PB1

	LDI R16, (1 << PCIE0)   ;  Habilitar PCINT en PORTB
    STS PCICR, R16
    LDI R16, (1 << PCINT0) | (1 << PCINT1)		;Habilitar Interrupciones en PB0 y PB1
    STS PCMSK0, R16

;Configurar Display
	LDI R16, 0xFF
    OUT DDRD, R16			; Configura PD0-PD7 como salida (LEDs CONTADOR)

	LDI R16, 0x05			; Configurar Timer0 con prescaler de 1024
    OUT TCCR0B, R16

    LDI R16, (1 << TOIE0)	; Habilitar interrupción por desbordamiento de Timer0
    STS TIMSK0, R16

    CALL TABLE				; Cargar tabla de valores del display en SRAM

    SEI                     ; Habilitar interrupciones globales

	CLR R20					; Inicializar contador del display
    CLR R21					; Inicializar contador de overflow
    CLR R17					; Inicializar contador de LEDs
    RCALL UPDATE_LEDS       ; Actualizar LEDs con valor inicial

MAIN_LOOP:
    RJMP MAIN_LOOP        

;==========================================================================
; Rutina de interrupción LEDS
CHECK_PUSH:
    SBIC PINB, 0			; Si PB0 está en bajo, salta a incrementar
    RCALL CHECK_INC			; Llama a la subrutina de incremento si PB0 estaba presionado
    SBIC PINB, 1			; Si PB1 está en bajo, salta a decrementar
    RCALL CHECK_DEC			; Llama a la subrutina de decremento si PB1 estaba presionado
    RETI					; Regresa a interrupción
;==========================================================================

CHECK_INC:
    INC R17                 ; Incrementar el contador
    ANDI R17, 0x0F          ; Mantiene el contador en 4 bits (0-15)
    RCALL UPDATE_LEDS       ; Actualizar LEDs
	RET

CHECK_DEC:
    DEC R17                 ; Decrementar el contador
    ANDI R17, 0x0F          ; Mantiene el contador en 4 bits (0-15)
    RCALL UPDATE_LEDS       ; Actualizar LEDs
    RET						; Regresa a la interrupción

UPDATE_LEDS:
    MOV R16, R17			; Mueve el valor de R17 a R16
    OUT PORTC, R16          ; Mostrar el valor en los LEDs conectados a PC0-PC4
    RET						; Regresa a la interrupción

;==========================================================================
; Rutina de interrupción DISPLAY
TIMER0:
    PUSH R16				; Guardar R16 en la pila 
    IN R16, SREG			; Guardar el estado de los flags del procesador
    PUSH R16

	LDI R16, 100
    OUT TCNT0, R16

    INC R21					; Incrementar contador de 10ms
    CPI R21, 100			; ¿Llegó a 100 (1 segundo)?
    BRNE END_ISR

    CLR R21					; Reiniciar contador de 10ms
    INC R20					; Incrementar segundos
    CPI R20, 10				; Si R20 alcanza 10, reiniciarlo a 0
    BRNE UPDATE_DISPLAY
    CLR R20

UPDATE_DISPLAY:				
	LDI ZH, 0X01			; Cargar parte alta de la tabla
    LDI ZL, 0X00			; Cargar parte baja de la tabla
    ADD ZL, R20				; Calcular dirección de patrón en SRAM
    LD R16, Z				; Cargar patrón desde SRAM
    OUT PORTD, R16			; Mostrar en el display
   
END_ISR:
    POP R16					; Restaurar SREG
    OUT SREG, R16
    POP R16					; Restaurar R16
							; Retorno de la interrupción
	RETI
;==========================================================================

TABLE:
	LDI ZH, 0X01			; Cargar parte alta de la tabla
    LDI ZL, 0X00			; Cargar parte baja de la tabla

    LDI R16, 0b00111111		; 0 en el display
	ST Z+, R16

	LDI	R16, 0b00000110		;1 en el display
	ST Z+, R16

	LDI	R16, 0b01011011		;2 en el display
	ST Z+, R16

	LDI	R16, 0b01001111		;3 en el display
	ST Z+, R16

	LDI	R16, 0b01100110		;4 en el display
	ST Z+, R16

	LDI	R16, 0b01101101		;5 en el display
	ST Z+, R16

	LDI	R16, 0b01111101		;6 en el display
	ST Z+, R16

	LDI	R16, 0b00000111		;7 en el display
	ST Z+, R16

	LDI	R16, 0b01111111		;8 en el display
	ST Z+, R16

	LDI	R16, 0b01101111		;9 en el display
	ST Z+, R16

	LDI ZH, 0X01			; Cargar parte alta de la tabla
    LDI ZL, 0X00			; Cargar parte baja de la tabla
	RET
