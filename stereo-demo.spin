{

 SPIN PCM audio device driver
 Copyright(c) 2007-2011 Christopher Abad
 20 GOTO 10 | aempirei@gmail.com

 variable sample rate stable up to 44.1KHz
 u8 s16 s24 and s32 PCM sample sizes
 2 channel (stereo)

 this demo code has full WAV file support for various bit sizes and sample rates
 
}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000       '80 MHz

  ' size of various structures in array size (not bytes)
  
  BUFFER_SZ = 256 * 4 * 3
  HEADER_SZ = 44
  EXT_SZ    = 24
  FACT_SZ   = 12 

  FORMAT_PCM = $0001
  FORMAT_EXT = $FFFE

  DATA_OFFSET_PCM = 36
  FACT_OFFSET_EXT = 60

VAR

  byte buffer1[BUFFER_SZ]
  byte buffer2[BUFFER_SZ]
  byte pcm[BUFFER_SZ]
  byte header[HEADER_SZ + EXT_SZ + FACT_SZ]
  
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

PRI ReadWAVHeader

  'verify basic WAV information--first two magic values
  
  if sd.pread(@header, HEADER_SZ) <> HEADER_SZ
    return false

  if !memcmp(@header, @magic1, 4)
    return false

  if !memcmp(@header + 8, @magic2, 8)
    return false

  'get WAV configuration information
  
  format := WORD[@header][10]
  channels := WORD[@header][11]
  rate := WORD[@header][12]
  bits := WORD[@header][17]

  'verify WAV format
  
  if format <> FORMAT_PCM and format <> FORMAT_EXT
    return false

  if channels <> 1 and channels <> 2
    return false

  if bits <> 8 and bits <> 16 and bits <> 24 and bits <> 32
    return false

  'if WAV has a simple extension seen in 24-bit and 32-bit WAV files, validate
  
  if format == FORMAT_PCM

    if !memcmp(@header + DATA_OFFSET_PCM, @magic3, 4)
      return false

  elseif format == FORMAT_EXT

    if sd.pread(@header + HEADER_SZ, EXT_SZ + FACT_SZ) <> EXT_SZ + FACT_SZ
      return false

    if !memcmp(@header + FACT_OFFSET_EXT, @magic4, 4)
      return false

    if !memcmp(@header + EXT_SZ + FACT_SZ + DATA_OFFSET_PCM, @magic3, 4)
      return false

  return true

PUB Main | j

  sd.mount(12)

  sd.popen(string("audio.wav"), "r")

  'read WAV header

  if(!ReadWAVHeader)
    return
  
  stereo.start(8, rate, channels, bits, @buffer1, @buffer2, BUFFER_SZ)

  dira[7]~~
  outa[7] := true
  
  repeat ' repeat until end of file
    j := sd.pread(@pcm, BUFFER_SZ)
    stereo.write(@pcm)
  while j == BUFFER_SZ

  sd.pclose

DAT
        magic1          byte    "RIFF", 0
        magic2          byte    "WAVEfmt ", 0
        magic3          byte    "data", 0
        magic4          byte    "fact", 0