/* Copyright (c) 2019  SiFive Inc. All rights reserved.
   Copyright (c) 2025 Mahmoud Abumandour <ma.mandourr@gmail.com>

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

#include <sys/asm.h>



#ifdef __riscv_zbkb

    #if __riscv_xlen == 32
        /* 32-bit + zbkb */
        #define PACK4(r1, r2, r3, r4) \
            packh r1, r1, r2;         \
            packh r3, r3, r4;         \
            pack r1, r1, r3
    #else
        /* 64-bit + zbkb */
        #define PACK4(r1, r2, r3, r4) \
            packh r1, r1, r2;         \
            packh r3, r3, r4;         \
            packw r1, r1, r3
    #endif
#else
    #define PACK4(a4, a5, s0, s1) \
        slli  s1, s1, 24;        \
        slli  s0, s0, 16;        \
        slli  a5, a5, 8;         \
        or    a4, a4, a5;        \
        or    a4, a4, s0;        \
        or    a4, a4, s1
#endif


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
    REG_S s0, 0(sp)
    REG_S s1, SZREG(sp)
    bleu  a2, a4, .Lcopy1

#if defined(__riscv_misaligned_avoid) || defined(__riscv_misaligned_slow)
    andi a4, a1, SZREG - 1
    andi a5, a3, SZREG - 1
    beq a4, a5, .Lalign
    li s0, SZREG
    sub s0, s0, a4
    sub a2, a2, s0

;# In the case where source and destination are not aligned, we align the
;# destination, load SZREG bytes, one at a time, from source, and then store them
;# to destination in one instruction.
.Lalign_dest:
    lbu a4, 0(a1)
    sb  a4, 0(a3)
    addi a1, a1, 1
    addi a3, a3, 1
    addi s0, s0, -1

    bnez s0, .Lalign_dest

.Ldest_aligned:
    li s0, SZREG
    bleu a2, s0, .Lcopy1

    lbu a4, 0(a1)
    lbu a5, 1(a1)
    lbu s0, 2(a1)
    lbu s1, 3(a1)

    PACK4(a4, a5, s0, s1)
#if __riscv_xlen == 64

    lbu t0, 4(a1)
    lbu a5, 5(a1)
    lbu s0, 6(a1)
    lbu s1, 7(a1)

    PACK4(t0, a5, s0, s1)
    pack a4, a4, t0
#endif

    REG_S a4, 0(a3)

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
    li     s0, 16 * SZREG
    blt    a2, s0, .Lcopy32

    REG_L a4, 0(a1)
    REG_L a5, SZREG(a1)
    REG_L s0, 2 * SZREG(a1)
    REG_L s1, 3 * SZREG(a1)
    REG_L t0, 4 * SZREG(a1)
    REG_L t1, 5 * SZREG(a1)
    REG_L t2, 6 * SZREG(a1)
#ifndef __riscv_e
    REG_L t3, 7 * SZREG(a1)
    REG_L t4, 8 * SZREG(a1)
    REG_L t5, 9 * SZREG(a1)
    REG_L t6, 10 * SZREG(a1)
#endif
    addi  a2, a2, -16 * SZREG

    REG_S a4, 0(a3)
    REG_S a5, SZREG(a3)
    REG_S s0, 2 * SZREG(a3)
    REG_S s1, 3 * SZREG(a3)
    REG_S t0, 4 * SZREG(a3)
    REG_S t1, 5 * SZREG(a3)
    REG_S t2, 6 * SZREG(a3)
#ifndef __riscv_e
    REG_S t3, 7 * SZREG(a3)
    REG_S t4, 8 * SZREG(a3)
    REG_S t5, 9 * SZREG(a3)
    REG_S t6, 10 * SZREG(a3)
#endif

#ifdef __riscv_e
    REG_L a4, 7 * SZREG(a1)
    REG_L a5, 8 * SZREG(a1)
    REG_L s0, 9 * SZREG(a1)
    REG_L s1, 10 * SZREG(a1)

    REG_S a4, 7 * SZREG(a3)
    REG_S a5, 8 * SZREG(a3)
    REG_S s0, 9 * SZREG(a3)
    REG_S s1, 10 * SZREG(a3)
#endif

    REG_L a4, 11 * SZREG(a1)
    REG_L a5, 12 * SZREG(a1)
    REG_L s0, 13 * SZREG(a1)
    REG_L s1, 14 * SZREG(a1)
    REG_L t0, 15 * SZREG(a1)

    REG_S a4, 11 * SZREG(a3)
    REG_S a5, 12 * SZREG(a3)
    REG_S s0, 13 * SZREG(a3)
    REG_S s1, 14 * SZREG(a3)
    REG_S t0, 15 * SZREG(a3)

    addi   a1, a1, 16 * SZREG
    addi   a3, a3, 16 * SZREG
    j      .Lcopy64

.Lcopy32:
    li     s0, 8 * SZREG
    blt    a2, s0, .Lcopy1

    REG_L a4, 0(a1)
    REG_L a5, SZREG(a1)
    REG_L s0, 2 * SZREG(a1)
    REG_L s1, 3 * SZREG(a1)
    REG_L t0, 4 * SZREG(a1)
    REG_L t1, 5 * SZREG(a1)
    REG_L t2, 6 * SZREG(a1)
#ifndef __riscv_e
    REG_L t3, 7 * SZREG(a1)
#endif

    REG_S a4, 0(a3)
    REG_S a5, SZREG(a3)
    REG_S s0, 2 * SZREG(a3)
    REG_S s1, 3 * SZREG(a3)
    REG_S t0, 4 * SZREG(a3)
    REG_S t1, 5 * SZREG(a3)
    REG_S t2, 6 * SZREG(a3)
#ifndef __riscv_e
    REG_S t3, 7 * SZREG(a3)
#endif

#ifdef __riscv_e
    REG_L a4, 7 * SZREG(a1)
    REG_S a4, 7 * SZREG(a3)
#endif

    addi   a1, a1, 8 * SZREG
    addi   a3, a3, 8 * SZREG
    addi   a2, a2, -8 * SZREG

    j      .Lcopy32

.Lcopy1:
    beqz a2, .done
    lbu a4, 0(a1)
    sb a4, 0(a3)
    addi a1, a1, 1
    addi a3, a3, 1
    addi a2, a2, -1
    j .Lcopy1

.done:

    REG_L s0, 0(sp)
    REG_L s1, SZREG(sp)
    addi sp, sp, 2 * SZREG
    ret

#endif
  .size	memcpy, .-memcpy
