{

 SPIN PCM audio device driver
 Copyright(c) 2007-2011 Christopher Abad
 20 GOTO 10 | aempirei@gmail.com

 variable sample rate stable up to 44.1KHz
 u8 s16 s24 and s32 PCM sample sizes
 2 channel (stereo)

}

CON

PUB start(_basepin, _rate, _channels, _bits, _b1, _b2, _bs) | status

  bs := _bs
  b1 := _b1
  b2 := _b2

  bytefill(b1, 0, bs)
  bytefill(b2, 0, bs)

  pin1 := _basepin
  pin2 := _basepin + 1

  pinmask1 := |< pin1
  pinmask2 := |< pin2

  rate := _rate
  channels := _channels
  bits := _bits

  delta := clkfreq / rate

  cognew(@entry, 0)

  status := 0

PUB write(_ptr)

  repeat

    if long[b1 + bs][-1] == zero
      longmove(b1, _ptr, bs >> 2)
      return

    elseif long[b2 + bs][-1] == zero
      longmove(b2, _ptr, bs >> 2)
      return

DAT

entry   org

:init_ports

        or dira, pinmask1
        or dira, pinmask2

        mov ctra, counter
        add ctra, pin1

        mov ctrb, counter
        add ctrb, pin2

        mov nexttime, cnt
        add nexttime, delay

        xor idxj, idxj

:branch_table

        cmp bits, #8 wz
   if_e jmp #:entry8

        cmp bits, #16 wz
   if_e jmp #:entry16

        cmp bits, #24 wz
   if_e jmp #:entry24

        cmp bits, #32 wz
   if_e jmp #:entry32

        ret

:entry8

:loop1_8

        mov idxi, #0
        xor idxj, neg1

:loop2_8

        waitcnt nexttime, delta

        mov ptr, idxi           ' idxi is the relative byte offset to the current sample pair

        cmp idxj, neg1 wz       ' select the current frame (b1 or b2)

   if_e add ptr, b1
  if_ne add ptr, b2

        rdbyte val, ptr         ' get new channel 1 frequency
        wrbyte zero, ptr

        shl val, #22

        cmp val, zero wz
   if_e add val, nominal

        mov frqa, val

        add ptr, #1             ' increment to channel 2

        rdbyte val, ptr         ' get new channel 2 frequency
        wrbyte zero, ptr

        shl val, #22

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqb, val

        add idxi, #2            ' increment the idx by 2 (2 channels 8 bits at once)
        cmp idxi, bs wz
'
  if_ne jmp #:loop2_8

        jmp #:loop1_8

:entry16

:loop1_16

        mov idxi, #0
        xor idxj, neg1

:loop2_16

        waitcnt nexttime, delta

        mov ptr, idxi           ' idxi is the relative byte offset to the current sample pair

        cmp idxj, neg1 wz       ' select the current frame (b1 or b2)

   if_e add ptr, b1
  if_ne add ptr, b2

        rdword val, ptr         ' get new channel 1 frequency
        wrword zero, ptr

        shl val, #16
        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqa, val

        add ptr, #2             ' increment to channel 2

        rdword val, ptr         ' get new channel 2 frequency
        wrword zero, ptr

        shl val, #16
        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqb, val

        add idxi, #4            ' increment the idx by 4 (2 channels 2 bytes at once)
        cmp idxi, bs wz
'
  if_ne jmp #:loop2_16

        jmp #:loop1_16

:entry24

:loop1_24

        mov idxi, #0
        xor idxj, neg1

:loop2_24

        waitcnt nexttime, delta

        mov ptr, idxi           ' idxi is the relative byte offset to the current sample pair

        cmp idxj, neg1 wz       ' select the current frame (b1 or b2)

   if_e add ptr, b1
  if_ne add ptr, b2

        rdbyte val, ptr
        wrbyte zero, ptr
        add    ptr, #1

        rdbyte val2, ptr
        shl    val2, #8
        or     val, val2
        wrbyte zero, ptr
        add    ptr, #1

        rdbyte val2, ptr
        shl    val2, #16
        or     val, val2
        wrbyte zero, ptr
        add    ptr, #1

        shl val, #8
        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqa, val

        rdbyte val, ptr
        wrbyte zero, ptr
        add    ptr, #1

        rdbyte val2, ptr
        shl    val2, #8
        or     val, val2
        wrbyte zero, ptr
        add    ptr, #1

        rdbyte val2, ptr
        shl    val2, #16
        or     val, val2
        wrbyte zero, ptr
        add    ptr, #1

        shl val, #8
        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqb, val

        add idxi, #6            ' increment the idx by 4 (2 channels 24 bits at once)
        cmp idxi, bs wz
'
  if_ne jmp #:loop2_24

        jmp #:loop1_24

:entry32

:loop1_32

        mov idxi, #0
        xor idxj, neg1

:loop2_32

        waitcnt nexttime, delta

        mov ptr, idxi           ' idxi is the relative byte offset to the current sample pair

        cmp idxj, neg1 wz       ' select the current frame (b1 or b2)

   if_e add ptr, b1
  if_ne add ptr, b2

        rdlong val, ptr         ' get new channel 1 frequency
        wrlong zero, ptr

        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqa, val

        add ptr, #4             ' increment to channel 2

        rdlong val, ptr         ' get new channel 2 frequency
        wrlong zero, ptr

        sar val, #2

        cmp val, zero wz
   if_e add val, nominal

        adds val, unsign

        mov frqb, val

        add idxi, #8            ' increment the idx by 8 (2 channels 32 bits at once)
        cmp idxi, bs wz
'
  if_ne jmp #:loop2_32

        jmp #:loop1_32

counter   long %00110 << 26

delay     long 1_000_000

nominal   long $0000_0001
unsign    long $2000_0000 ' fix this so there is no shift

neg1      long -1
zero      long 0

rate      long 0
channels  long 0
bits      long 0

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
val2      res 1
