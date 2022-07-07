PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005

SR = $600A
ACR = $600B

IFR = $600D
IER = $600E


LCD_COMMAND = $0000    ;1 byte
LCD_CONTROL = $0001    ;1 byte
T1_DELAY = $0002       ;2 bytes from $0002 to $0003
PRINT_BUFFER = $0004   ;many bytes



  .org $8000
  message: .asciiz "Hello World"

t1_sleep:             ;Precondition: time delay in us is 2 bytes at T1_DELAY
  pha
  lda T1_DELAY
  sta T1CL
  lda T1_DELAY + 1
  sta T1CH 
t1_sleep_loop
  lda IFR
  and #%01000000
  beq t1_sleep_loop
  pla
  rts



lcd_init:

  lda #%00000011
  sta PORTB
  jsr lcd_enable

  lda #$68
  sta T1_DELAY
  lda #$10
  sta T1_DELAY + 1
  jsr t1_sleep
  
  lda #%00000011
  sta PORTB
  jsr lcd_enable

  lda #$6e
  sta T1_DELAY
  lda #$00
  sta T1_DELAY + 1
  jsr t1_sleep

  lda #%00000011
  sta PORTB
  jsr lcd_enable

  lda #%00000010
  sta PORTB
  jsr lcd_enable
  rts

lcd_send_command:   ;Precondition: lcd command in LCD_COMMAND; lcd RW/RS in LCD_CONTROL
  
  ;LCD Layout #% N/C E RW RS D7 D6 D5 D4

  pha ;Save a for return

  ;wait for lcd_busy flag

  lda #%11110111        ;enable input on D7
  sta DDRB              

  

lcd_busy_loop:

  lda #%00100000        ;lcd clk low
  sta PORTB

  lda #%01100000        ;lcd clk high
  sta PORTB
  
  lda PORTB             ;check lcd_busy pin             
  pha                   ;put busy flag on stack

  lda #%00100000        ;lcd clk low
  sta PORTB

  lda #%01100000        ;lcd clk high
  sta PORTB             
  lda PORTB             ;read addr low nibble
  pla                   ;Pull busy flag off stack
  and #%00001000        ;check busy flag
  bne lcd_busy_loop

  lda #%00000000        ;lcd clk low
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

  lda #%00010000
  sta LCD_CONTROL

  jsr lcd_send_command

  rts

lcd_print_string:
  pha                   ;store registers for return
  txa
  pha

  ldx #$00              ;initialize counter
  lda #%000000001       ;Send clear command
  sta LCD_COMMAND
  lda #%000000000
  sta LCD_CONTROL
  jsr lcd_send_command

lcd_print_loop:
  lda message,x         ;fetch xth char from rom
  beq lcd_print_return  ;check for null terminator 
  jsr lcd_print_char    ;print char
  inx                   
  jmp lcd_print_loop

lcd_print_return:
  pla                   ;return registers
  tax
  pla
  rts

seg_write:
  pha                   ;push output val onto stack

seg_busy:
  lda IFR               ;check if 7segment done writing
  and #%00000100
  beq seg_busy
  
  pla                   ;get output val off stack
  sta SR                ;write output val to shift register
  rts

reset:
  ldx #$ff
  txs
  stx IFR

  lda #%11000000
  sta IER

  lda #%11111111        ;Set I/O pins
  sta DDRA
  lda #%11111111
  sta DDRB

  lda #$00
  sta PORTA
  sta PORTB

  lda #%00010100        ;Set ACR
  sta ACR

  lda #$88              ;init 7segs
  sta SR

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

  lda #$00
  jsr seg_write
  

halt:
  jmp halt

  .org $fffc
  .word reset
  .word $0000