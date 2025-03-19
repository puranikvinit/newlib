/* Copyright (c) 2019  SiFive Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

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
    li    a4, 15
    bleu  a2, a4, .Lcopy4

.Lalign:
#if __riscv_xlen == 32
    andi a4, a3, 3
#elif __riscv_xlen == 64
    andi a4, a3, 7
#else
    andi a4, a3, 15
#endif
    beqz   a4, .Laligned

    lbu    a4, 0(a1)
    sb     a4, 0(a3)
    addi   a3, a3, 1
    addi   a1, a1, 1
    addi   a2, a2, -1
    j      .Lalign

.Laligned:
#ifdef __riscv_misaligned_avoid
    andi   a4, a1, 3
    bnez   a4, .Lcopy1
#endif

.Lcopy64:
    li     a6, 64
    blt    a2, a6, .Lcopy32

    lw     a4, 0(a1)
    lw     a5, 4(a1)
    lw     a6, 8(a1)
    lw     a7, 12(a1)
    sw     a4, 0(a3)
    sw     a5, 4(a3)
    sw     a6, 8(a3)
    sw     a7, 12(a3)

    lw     a4, 16(a1)
    lw     a5, 20(a1)
    lw     a6, 24(a1)
    lw     a7, 28(a1)
    sw     a4, 16(a3)
    sw     a5, 20(a3)
    sw     a6, 24(a3)
    sw     a7, 28(a3)

    addi   a2, a2, -64

    lw     a4, 32(a1)
    lw     a5, 36(a1)
    lw     a6, 40(a1)
    lw     a7, 44(a1)
    sw     a4, 32(a3)
    sw     a5, 36(a3)
    sw     a6, 40(a3)
    sw     a7, 44(a3)

    lw     a4, 48(a1)
    lw     a5, 52(a1)
    lw     a6, 56(a1)
    lw     a7, 60(a1)
    sw     a4, 48(a3)
    sw     a5, 52(a3)
    sw     a6, 56(a3)
    sw     a7, 60(a3)

    addi   a1, a1, 64
    addi   a3, a3, 64
    j      .Lcopy64

.Lcopy32:
    li     a6, 32
    blt    a2, a6, .Lcopy16

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
    sw     a4, 24(a3)
    sw     a5, 28(a3)

    addi   a1, a1, 32
    addi   a3, a3, 32

.Lcopy16:
    li     a4, 16
    blt    a2, a4, .Lcopy4
    lw     a4, 0(a1)
    lw     a5, 4(a1)
    lw     a6, 8(a1)
    lw     a7, 12(a1)

    addi   a1, a1, 16

    sw     a4, 0(a3)
    sw     a5, 4(a3)
    addi   a2, a2, -16
    sw     a6, 8(a3)
    sw     a7, 12(a3)

    addi   a3, a3, 16

.Lcopy4:
    li     a4, 4
.lcopy4_body:
    blt    a2, a4, .Lcopy1
    lw     a5, 0(a1)
    sw     a5, 0(a3)

    addi   a1, a1, 4
    addi   a2, a2, -4
    addi   a3, a3, 4
    j      .lcopy4_body

.Lcopy1:
    beqz   a2, .done
    lbu    a4, 0(a1)
    sb     a4, 0(a3)
    addi   a1, a1, 1
    addi   a3, a3, 1
    addi   a2, a2, -1
    j      .Lcopy1

.done:
    ret

#endif
  .size	memcpy, .-memcpy