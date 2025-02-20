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

.org PCI0addr				; Dirección de la interrupción PCINT0 (on-change)
    RJMP CHECK_PUSH			; Rutina de Interrupción 

START:
    CLI                     ; Deshabilitar interrupciones mientras se configura
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

    SEI                     ; Habilitar interrupciones globales

    CLR R17					; Inicializar contador en 0
    RCALL UPDATE_LEDS       ; Actualizar LEDs con valor inicial

MAIN_LOOP:
    RJMP MAIN_LOOP          ; Bucle infinito esperando interrupciones

;==========================================================================
; Rutina de interrupción
CHECK_PUSH:
    SBIC PINB, 0		; Si PB0 está en bajo, salta a incrementar
    RCALL CHECK_INC     ; Llama a la subrutina de incremento si PB0 estaba presionado
    SBIC PINB, 1        ; Si PB1 está en bajo, salta a decrementar
    RCALL CHECK_DEC     ; Llama a la subrutina de decremento si PB1 estaba presionado
    RETI                ; Regresa a interrupción
;==========================================================================

CHECK_INC:
	RCALL DELAY				; Antirrebote
    INC R17                 ; Incrementar el contador
    ANDI R17, 0x0F          ; Mantiene el contador en 4 bits (0-15)
    RCALL UPDATE_LEDS       ; Actualizar LEDs
	RET

CHECK_DEC:
	RCALL DELAY
    DEC R17                 ; Decrementar el contador
    ANDI R17, 0x0F          ; Mantiene el contador en 4 bits (0-15)
    RCALL UPDATE_LEDS       ; Actualizar LEDs
    RET						; Regresa a la interrupción

; Atualizar LEDS
UPDATE_LEDS:
    MOV R16, R17			; Mueve el valor de R17 a R16
    OUT PORTC, R16          ; Mostrar el valor en los LEDs conectados a PC0-PC4
    RET						; Regresa a la interrupción


;Antirrebote
DELAY:
    LDI     R18, 0xFF

SUB_DELAY1:
    DEC     R18
    CPI     R18, 0
    BRNE    SUB_DELAY2
	LDI     R18, 0xFF

SUB_DELAY2:
    DEC     R18
    CPI     R18, 0
    BRNE    SUB_DELAY2
    RET