{

 SPIN PCM audio driver demo
 Copyright(c) 2007 Christopher Abad
 20 GOTO 10 Gallery
 679 Geary St.
 San Francisco, CA 94102
 http://www.twentygoto10.com/

 variable sample rate stable up to 44.1Khz
 16 bit unsigned
 2 channel

 this is a PCM unsigned 16-bit 2 channel driver, NOT A WAV PLAYER

 if you want this to play unsigned 16-bit 2 channel WAV files just forward past the header.

 loosely based on SPIN WAV Player Ver. 1a  (Plays only mono WAV at 16ksps) by Raymond Allen

}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000       '80 MHz

  buffer_siz = 2048

  WORD_SIZ = 2

VAR

  word buffer1[buffer_siz]
  word buffer2[buffer_siz]
  word pcm[buffer_siz]

OBJ

  SD          : "fsrw"
  stereo      : "stereo"

PUB Main| j

  sd.mount(12)

  sd.popen(string("audio.bin"), "r")

  stereo.start(8, 44_100, @buffer1, @buffer2, buffer_siz)

  dira[7]~~
  outa[7] := true

  j := buffer_siz * WORD_SIZ

  repeat while (j == buffer_siz * WORD_SIZ)  'repeat until end of file

    j:= sd.pread(@pcm, buffer_siz * WORD_SIZ)
    stereo.write(@pcm)

  sd.pclose

