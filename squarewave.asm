PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
T1CL = $6004
T1CH = $6005
T2CL = $6008
T2CH = $6009

SR = $600A
ACR = $600B

IFR = $600D
IER = $600E

PITCH_HIGH = $0000

  .org $8000


sing_note:                 ;precondition number of 64th notes (16 in 1 beat) to play for in A register; pitch low byte in y; pitch high byte in PITCH_HIGH
  sty T1CL
  ldy PITCH_HIGH
  sty T1CH
  tay

sing_note_counter_loop:
  lda #$d0
  sta T2CL
  lda #$84
  sta T2CH

sing_note_wait_loop:
  lda IFR
  and #%00100000
  beq sing_note_wait_loop
  dey
  bne sing_note_counter_loop
  rts


reset:
  ldx #$ff
  txs
  stx IFR

  lda #$00
  sta PORTA
  sta PORTB

  lda #%11010100        ;Set ACR
  sta ACR

  lda #$70
  sta T1CL
  lda #$04
  sta T1CH

  lda #%11111111
  sta PORTA

  halt:
    jmp halt


  .org $fffc
  .word reset
  .word $0000