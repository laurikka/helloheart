;# zeropage ###########################################################################
ch1_pos_1   = $02
ch1_pos_2   = $f5
ch2_pos     = ch1_pos_2+1
flipflop    = ch1_pos_2+2
wait        = ch1_pos_2+3
ch1pwl      = ch1_pos_2+4
ch1pwh      = ch1_pos_2+5
ch2pwl      = ch1_pos_2+6
ch2pwh      = ch1_pos_2+7
ch3pwl      = ch1_pos_2+8
ch3pwh      = ch1_pos_2+9

;# constants ##########################################################################
NOTEDELAY   = 15

;;---------->
;    org 2049                        ; start of basic programs in memory
;;---------->
;    byte $0c,$08,$0a,$00,$9e,$20,$32,$30,$36,$32,$00,$00,$00
;init:
;    jsr music_init
;
;main:
;    ldx $d012               ; load current raster line
;    cpx #$fd                ; compare to given number
;    bne main                ; wait until true
;
;    jsr music_play
;    jmp main


;# sid header file #####################################################################
    org $1000-$7c
    ascii "PSID"                            ; magicid PSID or RSID
    byte 0,2                                ; version 1 or 2
    byte 0,$7c                              ; dataoffset - $76 for v1, 7c for v2
    byte $10,$00                            ; load address if no header
    byte $10,$00                            ; init address
    byte $10,$03                            ; playaddress
    byte 0,1                                ; songs
    byte 0,1                                ; startsong
    byte 0,0,0,0                            ; speed bit per song, 0 vblank, 1 cia
    ascii "Helloheart                     " ; title,    31 characters
    byte 0
    ascii "Laurikka                       " ; author,   31 characters
    byte 0
    ascii "2026 Laurikka                  " ; released, 31 characters
    byte 0
    byte 0,%00010100                        ; v2 flags, bits 4-5: 01 MOS6581, 10 = MOS8580
    byte 0                                  ; v2 startpage
    byte 0                                  ; v2 pagelength
    byte 0,0                                ; reserved, leave at 0
    org $1000

    jmp music_init
    jmp music_play

music_init:
    lda #$f                 ; volume to max
    sta $d418
    lda #$19                ; attack, decay
    sta $d405               ; ch 1
    lda #$cd                ; attack, decay
    sta $d40c               ; ch 2
    sta $d413               ; ch 3
    lda #$3b                ; sustain, release
    sta $d406               ; ch 1
    lda #$27                ; sustain, release
    sta $d40d               ; ch 2
    sta $d414               ; ch 3
    lda #0
    sta ch1_pos_1
    sta ch1_pos_2
    sta ch2_pos
    sta flipflop
    lda #1
    sta wait                ; frames wait before next note on channel 1
    jsr bar

music_play:
    ldx #0
    ldy #0
:
    lda notes_highbyte+4,x  ; get values to add to pulsewidth from note frequency table
    adc ch1pwl,x
    sta ch1pwl,x
    sta $d402,y
    inx
    iny
    lda #0                  ; add carry bit
    adc ch1pwl,x            ; to pulse high byte
    sta ch1pwl,x
    sta $d402,y
    clc                     ; doesn't seem to be needed
    tya
    adc #6
    tay
    inx
    cpx #6
    bne :-

    dec wait
    beq :+
    rts
:
    lda #NOTEDELAY
    sta wait                ; frames wait before next note on channel 1

    clc
    lda #$40                ; turn note off
    sta $d404
    lda ch1_pos_2           ; repeat 8 position
    adc ch1_pos_1           ; pos in increments of 8 notes
    tay
    ldx ch1,y               ; get position 
    lda notes_lowbyte-1,x   ; pointer to frequency table
    sta $d400               ; store to ch1 frequency register
    lda notes_highbyte,x
    sta $d401
    lda #$41                ; note on
    sta $d404               ; ch1 control reg

    inc ch1_pos_1
    lda #8
    cmp ch1_pos_1
    beq :+
    rts
:
    lda #0
    sta ch1_pos_1
    lda #1
    eor flipflop
    sta flipflop
    beq :+
    rts
:
    inc ch2_pos
    lda ch1_pos_2
    clc
    adc #8
    sta ch1_pos_2

bar:                        ; after 8 notes on channel 1, jump here
    lda #40
    sta $d40b               ; ch2 control reg to release adsr
    sta $d412               ; ch3 control reg

    ldy ch2_pos             ; position for ch2 and ch3
    ldx ch3,y               ; get note value
    beq reset               ; if value is 0 start from the beginning
    lda notes_lowbyte-1,x   ; get frequency low byte
    sta $d40e               ; store to ch3
    lda notes_highbyte,x    ; get high byte
    sta $d40f

    ldx ch2,y

    lda notes_lowbyte-1,x   ; get frequency low byte
    sta $d407               ; write it to hardware
    lda notes_highbyte,x    ; same for high byte
    sta $d408

    lda #$41                ; trigger note on
    sta $d40b               ; ch2 control reg
    sta $d412               ; ch3 control reg
    rts

reset:                      ; after 8 bars jump here to start again
    stx ch1_pos_1
    stx ch1_pos_2
    stx ch2_pos
    jmp bar

; notes  d-2,e-2,f#2,g-2,a-2,b-2,c#3,d-3,e-3, 46 bytes
; first slot optimized out so pointer needs to point to notes_lowbyte-1
notes_lowbyte
    byte $DC,$74,$1F,$7C,$47,$2C,$2C
    byte $B7,$E8,$3E,$F8,$8F,$57,$58
    byte $6F,$D0,$7C,$F0,$1E,$AE,$AF,$DD

notes_highbyte
    byte $A0,$04,$05,$06,$06,$07,$08,$09
    byte $09,$0A,$0C,$0C,$0E,$10,$12
    byte $13,$15,$18,$19,$1D,$20,$24,$26,$2B

ch1:
    byte 18, 12, 16, 12, 15, 17, 12, 15, 19, 12, 19, 15, 16, 17, 12, 15, 16, 19, 15, 18, 16, 19, 20, 19, 22, 17, 13, 20, 15, 22, 17, 13, 14, 17, 21, 14, 19, 14, 20, 16, 20, 18, 15, 18, 13, 19, 18, 15, 21, 19, 16, 20, 14, 20, 16, 19, 22, 17, 13, 20, 15, 22, 17, 13, 16, 18, 12, 16, 19, 16, 12, 17, 15, 18, 13, 19, 16, 13, 20, 16, 20, 19, 15, 19, 13, 17, 20, 19, 23, 19, 15, 20, 17, 22, 20, 17, 21, 17, 19, 14, 16, 12, 19, 14, 20, 18, 15, 17, 13, 19, 17, 15, 21, 17, 16, 20, 14, 19, 17, 20, 22, 17, 13, 20, 15, 21, 19, 16

ch2:
    byte 9, 8, 9, 6, 5, 8, 6, 10, 9, 8, 6, 8, 5, 6, 7, 10

ch3:
    byte 5, 4, 5, 3, 1, 4, 2, 6, 5, 4, 2, 5, 1, 4, 3, 6, 0 ; <-0 restarts the patterns
