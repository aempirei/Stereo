{

 SPIN PCM audio driver
 Copyright(c) 2007 Christopher Abad
 20 GOTO 10 Gallery
 679 Geary St.
 San Francisco, CA 94102
 http://www.twentygoto10.com/

 variable sample rate stable up to 44.1KHz
 16 bit unsigned
 2 channel

 this is a PCM unsigned 16-bit 2 channel driver, NOT A WAV PLAYER

 if you want this to play unsigned 16-bit 2 channel WAV files just forward past the header.

 loosely based on SPIN WAV Player Ver. 1a  (Plays only mono WAV at 16ksps) by Raymond Allen

}

CON

  CHANNELS = 2
  BITS     = 16
  
PUB start(_basepin, _rate, _b1, _b2, _bs) | status

  bs := _bs
  b1 := _b1
  b2 := _b2

  longfill(b1, 0, bs)
  longfill(b2, 0, bs)


  pin1 := _basepin
  pin2 := _basepin + 1

  pinmask1 := |< pin1
  pinmask2 := |< pin2

  rate := _rate
  delta := clkfreq / rate

  cognew(@entry, 0)

  status := 0

PUB write(wordptr) | n

  n := bs - 1

  repeat 

    if word[b1][n] == 0
      wordmove(b1, wordptr, bs)
      return
  
    elseif word[b2][n] == 0
      wordmove(b2, wordptr, bs)
      return

DAT

entry   org

        or dira, pinmask1
        or dira, pinmask2
        
        mov ctra, counter
        add ctra, pin1

        mov ctrb, counter
        add ctrb, pin2

        mov nexttime, cnt
        add nexttime, delay

        xor idxj, idxj

:loop1

        mov idxi, #0
        xor idxj, neg1

:loop2

        waitcnt nexttime, delta

        mov ptr, idxi           ' 2 * idxi is the relative byte offset to the current
        shl ptr, #1             ' WORD (which hopefully lands on a proper pair)

        cmp idxj, neg1 wz       ' select the current frame (b1 or b2)
        
   if_e add ptr, b1
  if_ne add ptr, b2

        rdword val, ptr         ' get new channel 1 frequency
        wrword zero, ptr

        shl val, #13
        add val, nominal  

        mov frqa, val

        add ptr, #2             ' increment to channel 2

        rdword val, ptr         ' get new channel 2 frequency
        wrword zero, ptr

        shl val, #13
        add val, nominal  

        mov frqb, val

        add idxi, #2            ' increment the idx by 2 (2 channels at once) 
        cmp idxi, bs wz
'
  if_ne jmp #:loop2

        jmp #:loop1 

counter   long %00110 << 26

delay     long 1_000_000

nominal   long $0001_0000
         
neg1      long -1
zero      long 0

rate      long 0

delta     long 0
         
pin1      long 0
pin2      long 0

pinmask1  long 0
pinmask2  long 0
         
bs        long 0
b1        long 0
b2        long 0

idxi      res 1
idxj      res 1

nexttime  res 1

ptr       res 1
val       res 1
 