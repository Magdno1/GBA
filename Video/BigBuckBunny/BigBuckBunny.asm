; GBA 'Bare Metal' GRB 12-Bit LZ Compressed IPS Video Decode 120x80 Demo by krom (Peter Lemon):

format binary as 'gba'
include 'LIB\FASMARM.INC'
include 'LIB\MEM.INC'
include 'LIB\LCD.INC'
include 'LIB\DMA.INC'
include 'LIB\SOUND.INC'
include 'LIB\TIMER.INC'
org $8000000
b copycode
times $80000C0-($-0) db 0

macro IPSDecode { ; Decode IPS Headerless & Footerless Data With 2 Byte (Word) Offsets, Little Endian Offset, Size, & RLE Size
  local .IPSLoop, .IPSData, .IPSRLE, .IPSRLELoop, .IPSEOF
  imm32 r0,WRAM + 6300 ; R0 = IPS Location
  mov r5,WRAM ; R5 = WRAM Offset
  ldr r6,[IPSOffset] ; R6 = IPS WRAM End Offset
  .IPSLoop: ; Decode IPS Offset
    ldrb r2,[r0],1 ; R2 = IPS Offset Word Lo Byte
    ldrb r4,[r0],1 ; R4 = IPS Offset Word Hi Byte
    orr r2,r4,lsl 8 ; R2 = IPS Offset Word
    add r1,r5,r2 ; R1 = WRAM Offset + IPS Offset
  ; Decode IPS Size
    ldrb r3,[r0],1 ; R3 = IPS Size Word Lo Byte
    ldrb r4,[r0],1 ; R4 = IPS Size Word Hi Byte
    orrs r3,r4,lsl 8 ; R3 = IPS Size Word
    beq .IPSRLE ; If (IPS Size == 0) Decode IPS RLE
  .IPSData: ; Decode IPS Data
    ldrb r4,[r0],1 ; R4 = Data Byte
    strb r4,[r1],1 ; Store Data Byte To WRAM
    subs r3,1 ; IPS Size--
    bne .IPSData ; IF (IPS Size != 0) Loop IPS Data
    beq .IPSEOF  ; ELSE GOTO IPS EOF
  .IPSRLE: ; Decode IPS RLE Data
    ldrb r3,[r0],1 ; R3 = IPS RLE Size Word Lo Byte
    ldrb r4,[r0],1 ; R4 = IPS RLE Size Word Hi Byte
    orr r3,r4,lsl 8 ; R3 = IPS RLE Size Word
    ldrb r4,[r0],1 ; R4 = RLE Repeat Byte
    .IPSRLELoop: ; IPS RLE Repeat Byte Data Loop
      strb r4,[r1],1 ; Store RLE Repeat Byte To WRAM
      subs r3,1 ; IPS RLE Size--
      bne .IPSRLELoop ; IF (IPS RLE Size != 0) Loop IPS RLE Byte Copy
  .IPSEOF: ; Decode IPS EOF
    cmp r0,r6 ; Compare WRAM Offset To IPS WRAM End Offset
    bne .IPSLoop ; IF (WRAM Offset != IPS WRAM End Offset) Loop IPS Decoding
}

macro GRBDecode { ; Decode GRB Frame
  local .GRBLoop
  mov r0,VRAM ; R0 = VRAM Offset
  mov r1,WRAM ; R1 = G Offset
  add r2,r1,120 * 80 / 2 ; R2 = R Offset
  add r3,r2,120 * 80 / 8 ; R3 = B Offset

  mov r4,120 * 80 / 32 ; R4 = Block Count
  mov r5,15 ; R5 = End Of Blue Scanline Counter (120 / 8 = 15)

  mov r9,239 ; R9 = 478
  lsl r9,1
  mov r10,237 ; R10 = 474
  lsl r10,1
  mov r11,1440 ; R11 = 1438
  sub r11,2

  .GRBLoop: ; Loop 4x4 Block (16 pixels)
  ; Hi 4-Bit
    ldrb r6,[r3],1 ; Load B Byte
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800

    ; 1st 2x2 Block (4 Pixels)
    ldrb r7,[r2] ; Load R Byte
    lsr r7,4
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],-59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],-r9 ; Store Decoded GRB Pixel Into VRAM

    ; 2nd 2x2 Block (4 Pixels)
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    ldrb r7,[r2],30 ; Load R Byte
    and r7,$F
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r10 ; Store Decoded GRB Pixel Into VRAM

    ; 3rd 2x2 Block (4 Pixels)
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    ldrb r7,[r2] ; Load R Byte
    lsr r7,4
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],-59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],-r9 ; Store Decoded GRB Pixel Into VRAM

    ; 4th 2x2 Block (4 Pixels)
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    ldrb r7,[r2],-29 ; Load R Byte
    and r7,$F
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],-179 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 7 ; Pack B Pixel
    and r12,$F800
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],-r11 ; Store Decoded GRB Pixel Into VRAM


  ; LO 4-Bit
    mov r12,r6,lsl 11 ; Pack B Pixel

    ; 1st 2x2 Block (4 Pixels)
    ldrb r7,[r2] ; Load R Byte
    lsr r7,4
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],-59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],-r9 ; Store Decoded GRB Pixel Into VRAM

    ; 2nd 2x2 Block (4 Pixels)
    mov r12,r6,lsl 11 ; Pack B Pixel
    ldrb r7,[r2],30 ; Load R Byte
    and r7,$F
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r10 ; Store Decoded GRB Pixel Into VRAM

    ; 3rd 2x2 Block (4 Pixels)
    mov r12,r6,lsl 11 ; Pack B Pixel
    ldrb r7,[r2] ; Load R Byte
    lsr r7,4
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrb r8,[r1],-59 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],-r9 ; Store Decoded GRB Pixel Into VRAM

    ; 4th 2x2 Block (4 Pixels)
    subs r5,1 ; Decrement End Of Blue Scanline Counter
    moveq r5,15 ; End Of Blue Scanline
    mov r12,r6,lsl 11 ; Pack B Pixel
    ldrbeq r7,[r2],1 ; Load R Byte End Of Blue Scanline
    ldrbne r7,[r2],-29 ; Load R Byte
    and r7,$F
    orr r12,r7,lsl 1 ; Pack R Pixel
    ; 1st Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 2nd Pixel
    ldrb r8,[r1],60 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],r9 ; Store Decoded GRB Pixel Into VRAM
    ; 3rd Pixel
    ldrb r8,[r1] ; Load G Byte
    lsr r8,4
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strh r12,[r0],2 ; Store Decoded GRB Pixel Into VRAM
    ; 4th Pixel
    ldrbeq r8,[r1],1 ; Load G Byte End Of Blue Scanline
    ldrbne r8,[r1],-179 ; Load G Byte
    and r8,$F
    mov r12,r6,lsl 11 ; Pack B Pixel
    orr r12,r7,lsl 1 ; Pack R Pixel
    orr r12,r8,lsl 6 ; Pack G Pixel
    strheq r12,[r0],242 ; Store Decoded GRB Pixel Into VRAM End Of Blue Scanline
    strhne r12,[r0],-r11 ; Store Decoded GRB Pixel Into VRAM

    subs r4,1 ; Block Count--
    bne .GRBLoop ; IF (Block Count != 0) Loop GRB Blocks
}

copycode:
  adr r1,startcode
  mov r2,start
  imm32 r3,endcopy
  clp:
    ldr r0,[r1],4
    str r0,[r2],4
    cmp r2,r3
    bmi clp
  mov r2,start
  bx r2
startcode:
org IWRAM

start:
  mov r0,IO
  mov r1,MODE_3
  orr r1,BG2_ENABLE
  str r1,[r0]

  ; Zoom 120x80 Screen To Fill Full Screen (200%)
  imm32 r0,BGAffineSource ; R0 = Address Of Parameter Table
  mov r1,IO ; GBA I/O Base Offset
  orr r1,BG2PA ; Update BG Parameters
  mov r2,1 ; (BIOS Call Requires R0 To Point To Parameter Table)
  swi $0E0000 ; Bios Call To Calculate All The Correct BG Parameters

  imm32 r0,VIDEO ; R0 = LZ Compressed Data Offset
  str r0,[LZOffset] ; Store LZ Compressed Data Offset Into LZ Offset

  PlaySoundA SOUND, 22050 ; Play Sound Channel A Data
LoopFrames:
  ldr r0,[LZOffset] ; R0 = LZ Offset
  imm32 r1,WRAM + 6300 ; R1 = LZ IPS File Output Offset
  ldr r2,[r0],4 ; R2 = Data Length & Header Info
  lsr r2,8 ; R2 = Data Length
  add r2,r1 ; R2 = Destination End Offset
  LZLoop:
    ldrb r3,[r0],1 ; R3 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
    mov r4,10000000b ; R4 = Flag Data Block Type Shifter
    LZBlockLoop:
      cmp r1,r2 ; IF (Destination Address == Destination End Offset) LZ End
      beq LZEnd
      cmp r4,0 ; IF (Flag Data Block Type Shifter == 0) LZ Loop
      beq LZLoop
      tst r3,r4 ; Test Block Type
      lsr r4,1 ; Shift R4 To Next Flag Data Block Type
      bne LZDecode ; IF (BlockType != 0) LZ Decode Bytes
      ldrb r5,[r0],1 ; ELSE Copy Uncompressed Byte
      strb r5,[r1],1 ; Store Uncompressed Byte To Destination
      b LZBlockLoop

      LZDecode:
	ldrb r5,[r0],1 ; R5 = Number Of Bytes To Copy & Disp MSB's
	ldrb r6,[r0],1 ; R6 = Disp LSB's
	add r6,r5,lsl 8
	lsr r5,4 ; R5 = Number Of Bytes To Copy (Minus 3)
	add r5,3 ; R5 = Number Of Bytes To Copy
	mov r7,$1000
	sub r7,1 ; R7 = $FFF
	and r6,r7 ; R6 = Disp
	add r6,1 ; R6 = Disp + 1
	rsb r6,r1 ; R6 = Destination - Disp - 1
	LZCopy:
	  ldrb r7,[r6],1 ; R7 = Byte To Copy
	  strb r7,[r1],1 ; Store Byte To WRAM
	  subs r5,1 ; Number Of Bytes To Copy -= 1
	  bne LZCopy ; IF (Number Of Bytes To Copy != 0) LZ Copy Bytes
	  b LZBlockLoop
    LZEnd:

  str r1,[IPSOffset] ; Store IPS WRAM End Offset

  ; Skip Zero's At End Of LZ Compressed File
  ands r1,r0,3 ; Compare LZ Offset To A Multiple Of 4
  subne r0,r1 ; IF (LZ Offset != Multiple Of 4) Add R1 To the LZ Offset
  addne r0,4 ; LZ Offset += 4

  str r0,[LZOffset] ; Store Last LZ IPS Frame End Offset To LZ Offset

  ; Start Timer
  mov r11,IO ; GBA I/O Base Offset
  orr r11,TM1CNT ; Timer Control Register
  mov r12,TM_ENABLE or TM_FREQ_1024 ; Timer Enable, Frequency/1024
  str r12,[r11] ; Start Timer

  IPSDecode ; Decode IPS Data To WRAM
  GRBDecode ; Decode GRB Data To VRAM

  ; Wait For Timer
  mov r11,IO ; GBA I/O Base Offset
  orr r11,TM1CNT ; Timer Control Register
  imm16 r10,$410 ; R10 = Time
  WaitTimer:
    ldrh r12,[r11] ; Current Timer Position
    cmp r12,r10 ; Compare Time
    blt WaitTimer
  mov r12,TM_DISABLE
  str r12,[r11] ; Reset Timer Control

  ldr r0,[LZOffset] ; Load Last LZ IPS Frame End Offset
  imm32 r1,SOUND ; Load Video End Offset
  cmp r0,r1 ; Check Video End Offset
  bne LoopFrames ; Decode Next Frame
  StopSoundA ; Stop Sound Channel A
  b start ; Restart Video

IPSOffset: ; IPS WRAM End Of File Offset
dw 0
LZOffset: ; LZ ROM End Of File Offset
dw 0

endcopy:

org $80000C0 + (endcopy - start) + (startcode - copycode)
align 4
BGAffineSource: ; Memory Area Used To Set BG Affine Transformations Using BIOS Call
  ; Center Of Rotation In Original Image (Last 8-Bits Fractional)
  dw $00000000 ; X
  dw $00000000 ; Y
  ; Center Of Rotation On Screen
  dh $0000 ; X
  dh $0000 ; Y
  ; Scaling Ratios (Last 8-Bits Fractional)
  dh $0080 ; X
  dh $0080 ; Y
  ; Angle Of Rotation ($0000..$FFFF Anti-Clockwise)
  dh $0000
  ; Mosaic Amount
  dh $0000

VIDEO:
file 'video.lz'
SOUND:
file 'audio.snd'

rept $20000 {db 00}