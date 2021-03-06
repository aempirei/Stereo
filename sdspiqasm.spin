'   sdspi:  SPI interface to a Secure Digital card.
'
'   You probably never want to call this; you want to use fsrw
'   instead (which calls this); this is only the lowest layer.
'
'   Assumes SD card is interfaced using four consecutive Propeller
'   pins, as follows (assuming the base pin is pin 0):
'                3.3v
'                   
'                    20k
'   p0 ────────┻─┼─┼─┼─┼─┼────── do
'   p1 ──────────┻─┼─┼─┼─┼────── clk
'   p2 ────────────┻─┼─┼─┼────── di
'   p3 ──────────────┻─┼─┼────── cs (dat3)
'         150          └─┼────── irq (dat1)
'                        └────── p9 (dat2)
'
'   spinneret SPI pin-out is as follows:
'
'       p16 - DO (data out)
'       p17 -
'       p18 -
'       p19 - CS (chip select)
'       p20 - DI (data in)
'       p21 - CLK (clock) 
'
'   The 20k resistors
'   are pullups, and should be there on all six lines (even
'   the ones we don't drive).
'
'   This code is not general-purpose SPI code; it's very specific
'   to reading SD cards, although it can be used as an example.
'
'   The code does not use CRC at the moment (this is the default).
'   With some additional effort we can probe the card to see if it
'   supports CRC, and if so, turn it on.   
'
'   All operations are guarded by a watchdog timer, just in case
'   no card is plugged in or something else is wrong.  If an
'   operation does not complete in one second it is aborted.
'
con
   sectorsize = 512
   sectorshift = 9
var
   long cog
   long command, param, blockno ' rendezvous between spin and assembly
pub stop
   if cog
      cogstop(cog~ - 1)      
pub start(basepin)
'
'   Initialize the card!  Send a whole bunch of
'   clocks (in case the previous program crashed
'   in the middle of a read command or something),
'   then a reset command, and then wait until the
'   card goes idle.
'
  if basepin == -1 ' if basepin is -1 then use "SPINNERETTE" layout
    do  := 16
    cs  := 19    
    di  := 20
    clk := 21
  else
    do  := basepin++
    clk := basepin++ 
    di  := basepin++
    cs  := basepin
   
  stop
  command := "I"
  cog := 1 + cognew(@entry, @command)
  repeat while command

  if param
    abort param

  return 0
  
pub readblock(n, b)
'
'   Read a single block.  The "n" passed in is the
'   block number (blocks are 512 bytes); the b passed
'   in is the address of 512 blocks to fill with the
'   data.
'                              \
   param := b
   blockno := n
   command := "R"
   repeat while command
   if param
      abort param
   return 0
pub writeblock(n, b)
'
'   Write a single block.  Mirrors the read above.
'
   param := b
   blockno := n
   command := "W"
   repeat while command
   if param
      abort param
   return 0
dat
        org
entry   mov comptr,par
        mov parptr,par
        add parptr,#4
        mov parptr2,parptr
        add parptr2,#4
' set up
        mov acca,#1
        shl acca,di
        or dira,acca
        mov acca,#1
        shl acca,clk
        or dira,acca
        mov acca,#1
        shl acca,do
        mov domask,acca
        mov acca,#1
        shl acca,cs
        or dira,acca
        mov csmask,acca
        neg phsb,#1
        mov frqb,#0
        mov acca,nco
        add acca,clk
        mov ctra,acca
        mov acca,nco
        add acca,di
        mov ctrb,acca
        mov ctr2,onek
oneloop
        call #sendiohi
        djnz ctr2,#oneloop
        mov starttime,cnt
        mov cmdo,#0
        mov cmdp,#0
        call #cmd
        or outa,csmask
        call #sendiohi
initloop
        mov cmdo,#55
        call #cmd
        mov cmdo,#41
        call #cmd
        or outa,csmask
        cmp accb,#1 wz
   if_z jmp #initloop
        wrlong accb,parptr           
' reset frqa and the clock
finished
        mov frqa,#0
        wrlong frqa,comptr
        or outa,csmask
        neg phsb,#1
        call #sendiohi
pause
        mov acca,#511
        add acca,cnt
        waitcnt acca,#0
waitloop
        mov starttime,cnt
        rdlong acca,comptr wz
   if_z jmp #pause
        cmp acca,#"B" wz
   if_z jmp #byteio
        mov ctr2,sector
        cmp acca,#"R" wz
   if_z jmp #rblock
wblock
        mov starttime,cnt
        mov cmdo,#24
        rdlong cmdp,parptr2
        call #cmd
        mov phsb,#$fe
        call #sendio
        rdlong accb,parptr
        neg frqa,#1
wbyte
        rdbyte phsb,accb
        shl phsb,#23
        add accb,#1
        mov ctr,#8
wbit    mov phsa,#8
        shl phsb,#1
        djnz ctr,#wbit
        djnz ctr2,#wbyte        
        neg phsb,#1
        call #sendiohi
        call #sendiohi
        call #readresp
        and accb,#$1f
        sub accb,#5
        wrlong accb,parptr
        call #busy
        jmp #finished
rblock
        mov starttime,cnt
        mov cmdo,#17
        rdlong cmdp,parptr2
        call #cmd
        call #readresp
        rdlong accb,parptr
        sub accb,#1
rbyte
        mov phsa,hifreq
        mov frqa,freq
        add accb,#1
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        mov frqa,#0
        test domask,ina wc
        addx acca,acca
        wrbyte acca,accb
        djnz ctr2,#rbyte        
        mov frqa,#0
        neg phsb,#1
        call #sendiohi
        call #sendiohi
        or outa,csmask
        wrlong ctr2,parptr
        jmp #finished
byteio     
        rdlong phsb,parptr
        call #sendio
        wrlong accb,parptr
        jmp #finished
sendio
        rol phsb,#24
sendiohi
        mov ctr,#8
        neg frqa,#1
        mov accb,#0
bit     mov phsa,#8
        test domask,ina wc
        addx accb,accb        
        rol phsb,#1
        djnz ctr,#bit
sendio_ret
sendiohi_ret
        ret
checktime
        mov duration,cnt
        sub duration,starttime
        cmp duration,clockfreq wc
checktime_ret
  if_c  ret
        neg duration,#13
        wrlong duration,parptr
        jmp #finished
cmd
        andn outa,csmask
        neg phsb,#1
        call #sendiohi
        mov phsb,cmdo
        add phsb,#$40
        call #sendio
        mov phsb,cmdp
        shl phsb,#9
        call #sendiohi
        call #sendiohi
        call #sendiohi
        call #sendiohi
        mov phsb,#$95
        call #sendio
readresp
        neg phsb,#1
        call #sendiohi
        call #checktime
        cmp accb,#$ff wz
   if_z jmp #readresp 
cmd_ret
readresp_ret
        ret
busy
        neg phsb,#1
        call #sendiohi
        call #checktime
        cmp accb,#$0 wz
   if_z jmp #busy
busy_ret
        ret

di      long 0
do      long 0
clk     long 0
cs      long 0
nco     long $1000_0000
hifreq  long $e0_00_00_00
freq    long $20_00_00_00
clockfreq long 80_000_000
onek    long 1000
sector  long 512
domask  res 1
csmask  res 1
acca    res 1
accb    res 1
cmdo    res 1
cmdp    res 1
comptr  res 1
parptr  res 1
parptr2 res 1
ctr     res 1
ctr2    res 1
starttime res 1
duration res 1