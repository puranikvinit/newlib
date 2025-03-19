/* Copyright (c) 2019  SiFive Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

#include <sys/asm.h>

.text
.global memcpy
.type	memcpy, @function
memcpy:
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__)
  mv a3, a0
  beqz a2, 2f

1:
  lbu a4, 0(a1)
  sb a4, 0(a3)
  add   a2, a2, -1
  add   a3, a3, 1
  add   a1, a1, 1
  bnez a2, 1b

2:
  ret

#else
    mv a3, a0
    li    a4, SZREG
    addi  sp, sp, -2 * SZREG
#if __riscv_xlen == 32
    sw    s0, 0(sp)
    sw    s1, 4(sp)
#else
    sd    s0, 0(sp)
    sd    s1, 8(sp)
#endif
    bleu  a2, a4, .Lcopy1


#if defined(__riscv_misaligned_avoid) || defined(__riscv_misaligned_slow)
    andi a4, a1, SZREG - 1
    andi a5, a3, SZREG - 1
    sub s0, a4, a5
    beqz s0, .Lalign
    li s0, SZREG
    sub s0, s0, a5

;# In the case where source and destination are not aligned, we align the
;# destination, load SZREG bytes, one at a time, from source, and then store them
;# to destination in one instruction.
.Lalign_dest:
    lbu a4, 0(a1)
    sb  a4, 0(a3)
    addi a1, a1, 1
    addi a3, a3, 1
    addi s0, s0, -1
    addi a2, a2, -1

    bnez s0, .Lalign_dest

.Ldest_aligned:
    li s0, SZREG
    bleu a2, s0, .Lcopy1

    lbu a4, 0(a1)
    lbu a5, 1(a1)
    lbu s0, 2(a1)
    lbu s1, 3(a1)

#if __riscv_xlen == 32

#ifdef __riscv_zbkb
    packh a4, a4, a5
    packh s0, s0, s1
    pack a4, a4, s0
#else
    slli  s1, s1, 24
    slli  s0, s0, 16
    slli  a5, a5, 8
    or    a4, a4, a5
    or    a4, a4, s0
    or    a4, a4, s1
#endif

    sw a4, 0(a3)

#else

#ifdef __riscv_zbkb
    packh a4, a4, a5
    packh s0, s0, s1
    packw a4, a4, s0
#else
    slli  s1, s1, 24
    slli  s0, s0, 16
    slli  a5, a5, 8
    or    a4, a4, a5
    or    a4, a4, s0
    or    a4, a4, s1
#endif

    mv t0, a4

    lbu a4, 4(a1)
    lbu a5, 5(a1)
    lbu s0, 6(a1)
    lbu s1, 7(a1)

#ifdef __riscv_zbkb
    packh a4, a4, a5
    packh s0, s0, s1
    packw a4, a4, s0
    pack t0, t0, a4
#else
    slli  s1, s1, 24
    slli  s0, s0, 16
    slli  a5, a5, 8
    or    a4, a4, a5
    or    a4, a4, s0
    or    a4, a4, s1

    slli  a4, a4, 32
    or    t0, t0, a4
#endif

    sd t0, 0(a3)
#endif

    addi a1, a1, SZREG
    addi a3, a3, SZREG
    addi a2, a2, -SZREG
    j .Ldest_aligned

#endif

.Lalign:
    andi a4, a3, SZREG - 1
    beqz   a4, .Laligned

    lbu    a4, 0(a1)
    sb     a4, 0(a3)
    addi   a3, a3, 1
    addi   a1, a1, 1
    addi   a2, a2, -1
    j      .Lalign

.Laligned:
.Lcopy64:
    li     s0, 64
    blt    a2, s0, .Lcopy32
#if __riscv_xlen == 32
    lw     a4, 0(a1)
    lw     a5, 4(a1)
    lw     s0, 8(a1)
    lw     s1, 12(a1)
    sw     a4, 0(a3)
    sw     a5, 4(a3)
    sw     s0, 8(a3)
    sw     s1, 12(a3)

    lw     a4, 16(a1)
    lw     a5, 20(a1)
    lw     s0, 24(a1)
    lw     s1, 28(a1)
    sw     a4, 16(a3)
    sw     a5, 20(a3)
    sw     s0, 24(a3)
    sw     s1, 28(a3)

    addi   a2, a2, -64

    lw     a4, 32(a1)
    lw     a5, 36(a1)
    lw     s0, 40(a1)
    lw     s1, 44(a1)
    sw     a4, 32(a3)
    sw     a5, 36(a3)
    sw     s0, 40(a3)
    sw     s1, 44(a3)

    lw     a4, 48(a1)
    lw     a5, 52(a1)
    lw     s0, 56(a1)
    lw     s1, 60(a1)
    addi   a1, a1, 64
    sw     a4, 48(a3)
    sw     a5, 52(a3)
    sw     s0, 56(a3)
    sw     s1, 60(a3)

#else

    ld     a4, 0(a1)
    ld     a5, 8(a1)
    ld    s0, 16(a1)
    ld    s1, 24(a1)

    sd     a4, 0(a3)
    sd     a5, 8(a3)
    sd    s0, 16(a3)
    sd    s1, 24(a3)

    ld     a4, 32(a1)
    ld     a5, 40(a1)
    ld    s0, 48(a1)
    ld    s1, 56(a1)

    addi   a1, a1, 64

    sd     a4, 32(a3)
    sd     a5, 40(a3)
    sd    s0, 48(a3)
    sd    s1, 56(a3)

#endif

    addi   a3, a3, 64
    j      .Lcopy64

.Lcopy32:
    li     s0, 32
    blt    a2, s0, .Lcopy1

#if __riscv_xlen == 32
    lw     a4, 0(a1)
    lw     a5, 4(a1)
    sw     a4, 0(a3)
    sw     a5, 4(a3)

    lw     a4, 8(a1)
    lw     a5, 12(a1)
    sw     a4, 8(a3)
    sw     a5, 12(a3)

    addi   a2, a2, -32

    lw     a4, 16(a1)
    lw     a5, 20(a1)
    sw     a4, 16(a3)
    sw     a5, 20(a3)

    lw     a4, 24(a1)
    lw     a5, 28(a1)
    addi   a1, a1, 32
    sw     a4, 24(a3)
    sw     a5, 28(a3)
#else
    ld     a4, 0(a1)
    ld     a5, 8(a1)
    sd     a4, 0(a3)
    sd     a5, 8(a3)

    addi   a2, a2, -32

    ld     a4, 16(a1)
    ld     a5, 24(a1)
    addi  a1, a1, 32
    sd     a4, 16(a3)
    sd     a5, 24(a3)

#endif
    addi   a3, a3, 32
    j     .Lcopy1

.Lcopy1:
    beqz a2, .done
    j .Lcopy1
    lbu a4, 0(a1)
    sb a4, 0(a3)
    addi a1, a1, 1
    addi a3, a3, 1
    addi a2, a2, -1
    j .Lcopy1

.done:

#if __riscv_xlen == 32
    lw s0, 0(sp)
    lw s1, 4(sp)
#else
    ld s0, 0(sp)
    ld s1, 8(sp)
#endif
    addi sp, sp, 2 * SZREG
    ret

#endif
  .size	memcpy, .-memcpy
