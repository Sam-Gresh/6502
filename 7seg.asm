PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
SR = $600A
ACR = $600B
IFR = $600D
IER = $600E

  .org $8000

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


  lda #%11111111        ;Set I/O pins
  sta DDRA
  lda #%11111111
  sta DDRB

  lda #%00010100        ;Set ACR
  sta ACR

  lda #$00
  sta PORTB

  lda #$88
  sta SR

  lda #$22
  jsr seg_write
  

halt:
  jmp halt

  .org $fffc
  .word reset
  .word $0000