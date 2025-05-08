/* Copyright (c) 2017  SiFive Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

#include <sys/asm.h>


#define BYTE_TBL_SZ   31
#define WORD_TBL_SZ   32

#if __riscv_zilsd
#undef  SZREG
#define SZREG         8

#undef  REG_S
#define REG_S         sd

/* Zilsd and Zclsd require an even numbered register */
#define REG_SPLAT     a4
#else
#define REG_SPLAT     a1
#endif

/*
  Use an extended register for Zilsd and Zclsd if available
  since a5 is used for the odd numbered register, in order
  to eliminate an li instruction
*/
#if __riscv_zilsd && !__riscv_abi_rve
#define REG_TABLE     a6
#else
#define REG_TABLE     a5
#endif


.text
.global memset
.type  memset, @function

/* void *memset(void *s, int c, size_t n); */


memset:
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__)
  mv     a3, a0
  beqz   a2, .Ldone

.Lset:
  sb     a1, 0(a3)
  addi   a2, a2, -1
  addi   a3, a3, 1
  bnez   a2, .Lset

.Ldone:
  ret

#else
  li     REG_TABLE, BYTE_TBL_SZ
  mv     a3, a0

  /* If there aren't many bytes, copy them individually to reduce overhead */
  bleu   a2, REG_TABLE, .Lcopy_bytes

  and    a4, a3, SZREG - 1
  beqz   a4, .Lword_check

  /*
    Jump into the byte table depending on the number of bytes that need to be
    written
  */
1:
  auipc  t0, %pcrel_hi(.Ltable_misaligned)

  /*
    Instructions in the tables are forced to be four bytes, so scale count
    by 4
  */
#if __riscv_zba
  sh2add t0, a4, t0
#else
  sll    t1, a4, 2
  add    t0, t0, t1
#endif

  /* Save the return address because we aren't exiting the function yet */
  mv     t1, ra
  jalr   t0, %pcrel_lo(1b)

  /* Update pointer and count by what was written */
  mv     ra, t1
  add    a4, a4, -SZREG
  add    a2, a2, a4
  sub    a3, a3, a4

  /* Access is now aligned. Check we can copy words. */
  bleu   a2, REG_TABLE, .Lcopy_bytes

.Lword_check:
  /* Don't need to splat special case of zero */
  bnez   a1, .Lsplat_byte
#if __riscv_zilsd
  mv     REG_SPLAT, a1
#endif
  j      .Lcopy_words_init

/*
  Align labels to four bytes after unconditional jumps to avoid any
  penalties when jumping to 32-bit instructions that aren't 4-byte
  aligned
*/
.p2align 2
.Lsplat_byte:
#if __riscv_zbkb
  packh  REG_SPLAT, a1, a1
#if __riscv_xlen == 64
  packw  REG_SPLAT, REG_SPLAT, REG_SPLAT
#endif
  pack   REG_SPLAT, REG_SPLAT, REG_SPLAT
#else
  and    a1, a1, 0xFF
  sll    t0, a1, 8
  or     a1, a1, t0
  sll    t0, a1, 16
  or     REG_SPLAT, a1, t0
#if __riscv_xlen == 64
  sll    t0, REG_SPLAT, 32
  or     REG_SPLAT, REG_SPLAT, t0
#endif
#endif

.Lcopy_words_init:
#if __riscv_zilsd
  /* Odd register of even-odd pair */
  mv     a5, REG_SPLAT
#endif

  /* Calculate end address */
  and    t0, a2, ~(SZREG - 1)
  add    t1, a3, t0

  /*
    The idea behind the table of word copies is that first we calculate any
    remainder of bytes that need to be copied by the table that aren't an
    entire table length. That's copied first. After that, runs of the entire
    table are performed.
  */
  and    t0, t0, (WORD_TBL_SZ - 1) * SZREG

  /* Skip if there's no remainder */
  beqz   t0, .Ltable_bigly
  neg    t0, t0
  add    t0, t0, WORD_TBL_SZ * SZREG

  /* Adjust start address with offset */
  sub    a3, a3, t0

1:
  auipc  t2, %pcrel_hi(.Ltable_bigly)

#if SZREG == 8
  /*
    If eight bytes are being copied with each store, we need to divide
    the table offset in half
  */
  srl    t0, t0, 1
#endif

  add    t2, t2, t0
  jr     t2, %pcrel_lo(1b)

.p2align 2
.Ltable_bigly:
/*
  Force the instructions to be four bytes to avoid an extra instruction
  that would be needed to halve the offset for sw
*/
.option push
.option norvc
  REG_S  REG_SPLAT, SZREG*0(a3)
  REG_S  REG_SPLAT, SZREG*1(a3)
  REG_S  REG_SPLAT, SZREG*2(a3)
  REG_S  REG_SPLAT, SZREG*3(a3)
  REG_S  REG_SPLAT, SZREG*4(a3)
  REG_S  REG_SPLAT, SZREG*5(a3)
  REG_S  REG_SPLAT, SZREG*6(a3)
  REG_S  REG_SPLAT, SZREG*7(a3)
  REG_S  REG_SPLAT, SZREG*8(a3)
  REG_S  REG_SPLAT, SZREG*9(a3)
  REG_S  REG_SPLAT, SZREG*10(a3)
  REG_S  REG_SPLAT, SZREG*11(a3)
  REG_S  REG_SPLAT, SZREG*12(a3)
  REG_S  REG_SPLAT, SZREG*13(a3)
  REG_S  REG_SPLAT, SZREG*14(a3)
  REG_S  REG_SPLAT, SZREG*15(a3)
  REG_S  REG_SPLAT, SZREG*16(a3)
  REG_S  REG_SPLAT, SZREG*17(a3)
  REG_S  REG_SPLAT, SZREG*18(a3)
  REG_S  REG_SPLAT, SZREG*19(a3)
  REG_S  REG_SPLAT, SZREG*20(a3)
  REG_S  REG_SPLAT, SZREG*21(a3)
  REG_S  REG_SPLAT, SZREG*22(a3)
  REG_S  REG_SPLAT, SZREG*23(a3)
  REG_S  REG_SPLAT, SZREG*24(a3)
  REG_S  REG_SPLAT, SZREG*25(a3)
  REG_S  REG_SPLAT, SZREG*26(a3)
  REG_S  REG_SPLAT, SZREG*27(a3)
  REG_S  REG_SPLAT, SZREG*28(a3)
  REG_S  REG_SPLAT, SZREG*29(a3)
  REG_S  REG_SPLAT, SZREG*30(a3)
  REG_S  REG_SPLAT, SZREG*31(a3)
.option pop

  /* Update the pointer and copy data if needed */
  add    a3, a3, SZREG * WORD_TBL_SZ
  bltu   a3, t1, .Ltable_bigly

  /* Copy any remaining bytes */
  and    a2, a2, SZREG - 1
  beqz   a2, .Lexit

#if __riscv_zilsd && __riscv_abi_rve
  /* Restore table size if necessary */
  li     REG_TABLE, BYTE_TBL_SZ
#endif

.Lcopy_bytes:
  auipc  t0, %pcrel_hi(.Ltable_tiny)

  sub    a2, REG_TABLE, a2

  /*
    Instructions in the tables are forced to be four bytes, so scale count
    by 4
  */
#if __riscv_zba
  sh2add t0, a2, t0
#else
  sll    a2, a2, 2
  add    t0, t0, a2
#endif

  /* Don't save the return address because we're exiting after the jump */
  jr     t0, %pcrel_lo(.Lcopy_bytes)

.p2align 2
.Ltable_tiny:
/*
  norvc is needed because the immediate is only two bits in size for c.sb,
  and without it the table would have a mix of 2- and 4-byte instructions
  when Zcb is available
*/
.option push
.option norvc
  sb     a1, 30(a3)
  sb     a1, 29(a3)
  sb     a1, 28(a3)
  sb     a1, 27(a3)
  sb     a1, 26(a3)
  sb     a1, 25(a3)
  sb     a1, 24(a3)
  sb     a1, 23(a3)
  sb     a1, 22(a3)
  sb     a1, 21(a3)
  sb     a1, 20(a3)
  sb     a1, 19(a3)
  sb     a1, 18(a3)
  sb     a1, 17(a3)
  sb     a1, 16(a3)
  sb     a1, 15(a3)
  sb     a1, 14(a3)
  sb     a1, 13(a3)
  sb     a1, 12(a3)
  sb     a1, 11(a3)
  sb     a1, 10(a3)
  sb     a1, 9(a3)
  sb     a1, 8(a3)
#if SZREG == 8
.Ltable_misaligned:
#endif
  sb     a1, 7(a3)
  sb     a1, 6(a3)
  sb     a1, 5(a3)
  sb     a1, 4(a3)
#if SZREG == 4
.Ltable_misaligned:
#endif
  sb     a1, 3(a3)
  sb     a1, 2(a3)
  sb     a1, 1(a3)
  sb     a1, 0(a3)
.option pop
.Lexit:
  ret
#endif
.size  memset, .-memset
