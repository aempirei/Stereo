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

  ' size of various structures in array size (not bytes)
  
  BUFFER_SZ = 2048
  WORD_SZ = 2
  HEADER_SZ = 22

  FORMAT_PCM = 1

VAR

  word buffer1[BUFFER_SZ]
  word buffer2[BUFFER_SZ]
  word pcm[BUFFER_SZ]
  word header[HEADER_SZ]
  word format
  word rate
  word channels
  word bits

OBJ

  SD          : "fsrw"
  stereo      : "stereo"

PRI memcmp(left,right,length) | n

  n := length

  repeat while n-- > 0
    if(BYTE[left][n] <> BYTE[right][n])
      return false

  return true

PRI ReadWAVHeader | j

  j := sd.pread(@header, HEADER_SZ * WORD_SZ)

  if j <> HEADER_SZ * WORD_SZ
    return false

  if(!memcmp(@header, @magic1, 4))
    return false

  if(!memcmp(@header + 8, @magic2, 8))
    return false
    
  if(!memcmp(@header + 36, @magic3, 4))
    return false

  format := header[10]
  channels := header[11]
  rate := header[12]
  bits := header[17]

  if(format <> FORMAT_PCM)
    return false

  if(channels <> 2)
    return false

  if(bits <> 16)
    return false

  return true

PUB Main| j

  sd.mount(12)

  sd.popen(string("audio.wav"), "r")

  'read WAV header

  if(!ReadWAVHeader)
    return
  
  stereo.start(8, rate, @buffer1, @buffer2, BUFFER_SZ)

  dira[7]~~
  outa[7] := true

  j := BUFFER_SZ * WORD_SZ

  repeat while (j == BUFFER_SZ * WORD_SZ)    'repeat until end of file

    j := sd.pread(@pcm, BUFFER_SZ * WORD_SZ)
    stereo.write(@pcm)

  sd.pclose

DAT
        magic1          byte    "RIFF", 0
        magic2          byte    "WAVEfmt ", 0
        magic3          byte    "data", 0