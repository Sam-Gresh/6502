PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
SR = $600A
ACR = $600B

LCD_COMMAND = $0000    ;1 byte
LCD_CONTROL = $0001    ;1 byte
PRINT_BUFFER = $0002   ;many bytes



  .org $8000
  message: .asciiz "Hello World"

lcd_init:
  lda #%00000010
  sta PORTB
  ora #%01000000
  sta PORTB
  and #%10111111
  sta PORTB
  rts

lcd_send_command:   ;Precondition: lcd command in LCD_COMMAND; lcd RW/RS in LCD_CONTROL
  
  ;LCD Layout #% N/C E RW RS D7 D6 D5 D4

  pha ;Save a for return

  ;wait for lcd_busy flag

  lda #%11110111        ;enable input on D7
  sta DDRB              

  

lcd_busy_loop:

  lda #%00100000        ;set lcd to read
  sta PORTB

  lda #%01100000        ;lcd clk high
  sta PORTB
  
  lda PORTB             ;check lcd_busy pin             
  pha

  lda #%00100000  
  sta PORTB

  lda #%01100000
  sta PORTB
  lda PORTB
  pla 
  and #%00001000
  bne lcd_busy_loop

  lda #%00100000
  sta PORTB
  
  lda #%11111111        ;enable output on D7
  sta DDRB  

  ;ready for command
  lda LCD_COMMAND       ;send high bits
  and #%11110000
  lsr
  lsr
  lsr
  lsr
  ora LCD_CONTROL
  sta PORTB

  jsr lcd_enable

  lda LCD_COMMAND       ;send low bits
  and #%00001111
  ora LCD_CONTROL
  sta PORTB
  jsr lcd_enable

  ;Return registers
  pla
  rts

lcd_enable:             ;Precondition: instruction is in accumulator
  ora #%01000000        ;lcd clk high
  sta PORTB
  
  and #%10111111        ;lcd clk low
  sta PORTB
  rts


lcd_print_char:

  sta LCD_COMMAND

  lda #%000100000
  sta LCD_CONTROL

  jsr lcd_send_command

  rts

lcd_print_string:
  pha
  txa
  pha

  ldx #$00
  lda #%000000001
  sta LCD_COMMAND
  lda #%000000000
  sta LCD_CONTROL
  jsr lcd_send_command

lcd_print_loop:
  lda message,x
  beq lcd_print_return
  jsr lcd_print_char
  inx
  jmp lcd_print_loop

lcd_print_return:
  pla
  tax
  pla
  rts



reset:
  ldx #$ff
  txs

  lda #%11111111        ;Set I/O pins
  sta DDRA
  lda #%11111111
  sta DDRB

  lda #$00
  sta PORTB
  
  lda #$88              ;Print to 7seg display
  sta PORTA

  jsr lcd_init

  ldx #$00
  stx LCD_CONTROL

  ldx #%00101000        ;Function Set
  stx LCD_COMMAND
  jsr lcd_send_command

  ldx #%00001110        ;Display/Cursor on/off
  stx LCD_COMMAND
  jsr lcd_send_command

  ldx #%00000110        ;Entry Mode Set
  stx LCD_COMMAND
  jsr lcd_send_command

  ldx #%00000010        ;Return Home Display
  stx LCD_COMMAND
  jsr lcd_send_command

  jsr lcd_print_string

halt:
  lda #$00
  sta PORTA
  jmp halt

  .org $fffc
  .word reset
  .word $0000