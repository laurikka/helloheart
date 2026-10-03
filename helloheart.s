;# zeropage ###########################################################################
ch1_pos_1   = $02
ch1_pos_2   = $fb
ch2_pos     = $fc
flipflop    = $fd
wait        = $fe
ch1pwl      = $50                   ; $52 has a value after reset but it's ok
ch1pwh      = ch1pwl+1
ch2pwl      = ch1pwl+2
ch2pwh      = ch1pwl+3
ch3pwl      = ch1pwl+4
ch3pwh      = ch1pwl+5

;# constants ##########################################################################
NOTEDELAY   = 15

;---------->
    org 2049                        ; start of basic programs in memory
;---------->

    byte $0c,$08,$0a,$00,$9e,$20    ; "$c,$8" pointer to next line ,"$a" line number 10, "$9e,$20" sys 
    byte $32,$32,$38,$39            ; ascii string "2289" to jump to init routine
    byte 0,0,0                      ; end of line 0, end of basic program 00

reset                               ; after 8 bars jump here to start again
;    lda #0                         ; lda not needed as a should already be 0
    sta ch1_pos_1
    sta ch1_pos_2
    sta ch2_pos
    lda #2                          ; little surprise for those who watch until the loop
    sta $d800+13+43
    jmp bar

; notes  d-2,e-2,f#2,g-2,a-2,b-2,c#3,d-3,e-3, 46 bytes
; first slot optimized out so pointer needs to point to notes_lowbyte-1

notes_lowbyte
    byte $DC,$74,$1F,$7C,$47,$2C,$2C
    byte $B7,$E8,$3E,$F8,$8F,$57,$58
    byte $6F,$D0,$7C,$F0,$1E,$AE,$AF,$DD,$A0

    byte $8,$5,$c,$c,$f;,$53         ; hello-text

notes_highbyte
    byte $53,$04,$05,$06,$06,$07,$08,$09
    byte $09,$0A,$0C,$0C,$0E,$10,$12
    byte $13,$15,$18,$19,$1D,$20,$24,$26,$2B

ch1:
    byte 18, 12, 16, 12, 15, 17, 12, 15, 19, 12, 19, 15, 16, 17, 12, 15, 16, 19, 15, 18, 16, 19, 20, 19, 22, 17, 13, 20, 15, 22, 17, 13, 14, 17, 21, 14, 19, 14, 20, 16, 20, 18, 15, 18, 13, 19, 18, 15, 21, 19, 16, 20, 14, 20, 16, 19, 22, 17, 13, 20, 15, 22, 17, 13, 16, 18, 12, 16, 19, 16, 12, 17, 15, 18, 13, 19, 16, 13, 20, 16, 20, 19, 15, 19, 13, 17, 20, 19, 23, 19, 15, 20, 17, 22, 20, 17, 21, 17, 19, 14, 16, 12, 19, 14, 20, 18, 15, 17, 13, 19, 17, 15, 21, 17, 16, 20, 14, 19, 17, 20, 22, 17, 13, 20, 15, 21, 19, 16

ch2:
    byte 9, 8, 9, 6, 5, 8, 6, 10, 9, 8, 6, 8, 5, 6, 7, 10

ch3:
    byte 5, 4, 5, 3, 1, 4, 2, 6, 5, 4, 2, 5, 1, 4, 3, 6, 0 ; <-0 restarts the patterns

;----------------------->
    org 2049+13+14+46+167   ; basic upstart + resetroutine + frequencies + notedata
;----------------------->

init:                       ; jump to here from the basic program
    lda #$24                ; character screen pointer to 2048
    sta $d018

    lax #0                  ; init a and x to 0 with illegal opcode
    sta $d020               ; bg and border to black
    sta $d021
:
    sta $d700+13+14+24,x    ; mask out screen with black color
    sta $d800+13+14+46+167,x
    sta $d900+13+14+46+167,x
    sta $da00+13+14+46+167,x
    dex
    bne :-

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

bar:                        ; after 8 notes on channel 1, jump here
    lda #0
    sta $d40b               ; ch2 control reg to release adsr
    sta $d412               ; ch3 control reg

    ldy ch2_pos             ; position for ch2 and ch3
    lda ch3,y               ; get note value
    bne :+
    jmp reset               ; if $0, song is over
:
    eor #$80                ; flip filled character
    sta ch3,y               ; store flipped
    and #%00011111          ; mask out high bits
    tax                     ; transfer to x

    lda notes_lowbyte-1,x   ; get frequency low byte
    sta $d40e               ; store to ch3
    lda notes_highbyte,x    ; get high byte
    sta $d40f

    lda ch2,y
    eor #$80
    sta ch2,y
    and #%00011111
    tax

    lda notes_lowbyte-1,x   ; get frequency low byte
    sta $d407               ; write it to hardware
    lda notes_highbyte,x    ; same for high byte
    sta $d408

    lda #$41                ; trigger note on
    sta $d40b               ; ch2 control reg
    sta $d412               ; ch3 control reg

play:
    clc
    lda #$40                ; turn note off
    sta $d404
    lda ch1_pos_2           ; repeat 8 position
    adc ch1_pos_1           ; pos in increments of 8 notes
    tay
    lda ch1,y               ; get position 
    eor #$80                ; flip white background character
    sta ch1,y               ; store flipped
    and #%00011111          ; leave only low bits
    tax                     ; transfer to x
    lda notes_lowbyte-1,x   ; pointer to frequency table
    sta $d400               ; store to ch1 frequency register
    lda notes_highbyte,x
    sta $d401
    lda #$41                ; note on
    sta $d404               ; ch1 control reg

    lda #NOTEDELAY
    sta wait                ; frames wait before next note on channel 1
.loop
    ldx $d012               ; load current raster line
    cpx #$fd                ; compare to given number
    bne .loop               ; wait until true

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
;    clc                    ; doesn't seem to be needed
    tya
    adc #6
    tay
    inx
    cpx #6
    bne :-

    dec wait
    bne .loop

    inc ch1_pos_1
    lda #8
    cmp ch1_pos_1
    bne play

    lda #0
    sta ch1_pos_1
    lda #1
    eor flipflop
    sta flipflop
    bne play

    ldy ch2_pos
    lda ch2,y
    eor #$80
    sta ch2,y
    lda ch3,y
    eor #$80
    sta ch3,y

    inc ch2_pos
    lda ch1_pos_2
    clc                 ; not strictly needed but I had one byte to spare
    adc #8              ; if clc is taken out, the adc needs to be 7 instead of 8
    sta ch1_pos_2
    jmp bar

