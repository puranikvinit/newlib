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

#undef  PTRLOG
#define PTRLOG        3
#endif


.text
.global memset
.type  memset, @function

/* void *memset(void *s, int c, size_t n); */

memset:
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__)
  mv     a3, a0
  beqz   a2, 2f

1:
  sb     a1, 0(a3)
  add    a2, a2, -1
  add    a3, a3, 1
  bnez   a2, 1b

2:
  ret

#else
  mv     a3, a0
  li     t6, BYTE_TBL_SZ

  /* If there aren't many bytes, copy them individually to reduce overhead */
  bleu   a2, t6, .Lcopy_bytes

  /*
    Make sure access is word-aligned. Need separate values for determining
    table offsets for alignment vs. table entries
  */
  li     t5, SZREG

  and    a4, a3, SZREG - 1
  beqz   a4, .Lword_check

  /*
    Jump into the byte table depending on the number of bytes that need to be
    written
  */
1:
  auipc  t0, %pcrel_hi(.Ltable_tiny)

  /*
    At this point we know we have more than BYTE_TBL_SZ bytes to write, which
    is greater than SZREG - 1
  */
  sub    t1, t5, a4
  sub    t2, t6, t1

  /*
    Instructions in the tables are forced to be four bytes, so scale count
    by 4
  */
#if __riscv_zba
  sh2add t0, t2, t0
#else
  sll    a5, t2, 2
  add    t0, t0, a5
#endif

  /* Save the return address because we aren't exiting the function yet */
  mv     t3, ra
  jalr   t0, %pcrel_lo(1b)

  /* Update pointer and counts by what was written */
  mv     ra, t3
  sub    a2, a2, t1
  add    a3, a3, t1

  /* Access is now aligned. Check we can copy words. */
  bleu   a2, t6, .Lcopy_bytes

.Lword_check:
  /* Don't need to splat special case of zero */
  bnez   a1, .Lsplat_byte
  mv     a4, a1
  j      .Lcopy_words_init

.Lsplat_byte:
#if __riscv_zbkb
  packh  a4, a1, a1
#if __riscv_xlen == 64
  packw  a4, a4, a4
#endif
  pack   a4, a4, a4
#else
  and    a1, a1, 0xFF
  sll    a4, a1, 8
  or     a1, a1, a4
  sll    a4, a1, 16
  or     a4, a1, a4
#if __riscv_xlen == 64
  sll    a5, a4, 32
  or     a4, a4, a5
#endif
#endif

.Lcopy_words_init:
#if __riscv_zilsd
  mv     a5, a4
#endif

  /*
    It's possible that there are a number of bytes that need to be written
    that are less than a word. Save this quantity and write it out later.
  */
  li     t0, WORD_TBL_SZ
  and    t1, a2, SZREG - 1

  /* Track the number of words to be written */
  srl    a2, a2, PTRLOG
  j      .Lcopy_words

.Ltable_tiny:
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
  sb     a1, 7(a3)
  sb     a1, 6(a3)
  sb     a1, 5(a3)
  sb     a1, 4(a3)
  sb     a1, 3(a3)
  sb     a1, 2(a3)
  sb     a1, 1(a3)
  sb     a1, 0(a3)
.option pop
  ret

.Ltable_bigly:
.option push
.option norvc
  REG_S  a4, SZREG*31(a3)
  REG_S  a4, SZREG*30(a3)
  REG_S  a4, SZREG*29(a3)
  REG_S  a4, SZREG*28(a3)
  REG_S  a4, SZREG*27(a3)
  REG_S  a4, SZREG*26(a3)
  REG_S  a4, SZREG*25(a3)
  REG_S  a4, SZREG*24(a3)
  REG_S  a4, SZREG*23(a3)
  REG_S  a4, SZREG*22(a3)
  REG_S  a4, SZREG*21(a3)
  REG_S  a4, SZREG*20(a3)
  REG_S  a4, SZREG*19(a3)
  REG_S  a4, SZREG*18(a3)
  REG_S  a4, SZREG*17(a3)
  REG_S  a4, SZREG*16(a3)
  REG_S  a4, SZREG*15(a3)
  REG_S  a4, SZREG*14(a3)
  REG_S  a4, SZREG*13(a3)
  REG_S  a4, SZREG*12(a3)
  REG_S  a4, SZREG*11(a3)
  REG_S  a4, SZREG*10(a3)
  REG_S  a4, SZREG*9(a3)
  REG_S  a4, SZREG*8(a3)
  REG_S  a4, SZREG*7(a3)
  REG_S  a4, SZREG*6(a3)
  REG_S  a4, SZREG*5(a3)
  REG_S  a4, SZREG*4(a3)
  REG_S  a4, SZREG*3(a3)
  REG_S  a4, SZREG*2(a3)
  REG_S  a4, SZREG*1(a3)
  REG_S  a4, SZREG*0(a3)
  add    a3, a3, t3
.option pop

.Lcopy_words:
#if __riscv_zbb
  minu   t2, a2, t0
#else
  mv     t2, t0
  bgeu   a2, t0, 1f
  mv     t2, a2
#endif
1:
  /* Check if there are words still to be written */
  beqz   t2, .Lcopy_bytes_init
  sub    a2, a2, t2

  /* Added to the pointer after the table run */
  sll    t3, t2, PTRLOG

2:
  auipc  t4, %pcrel_hi(.Ltable_bigly)

  sub    t2, t0, t2
  /*
    Instructions in the tables are forced to be four bytes, so scale count
    by 4
  */
#if __riscv_zba
  sh2add t4, t2, t4
#else
  sll    t2, t2, 2
  add    t4, t4, t2
#endif

  jr     t4, %pcrel_lo(2b)

.Lcopy_bytes_init:
  /* Restore the original remaining non-word bytes */
  beqz   t1, .Lexit
  mv     a2, t1

.Lcopy_bytes:
  auipc  a5, %pcrel_hi(.Ltable_tiny)

  sub    a2, t6, a2
  /*
    Instructions in the tables are forced to be four bytes, so scale count
    by 4
  */
#if __riscv_zba
  sh2add a5, a2, a5
#else
  sll    a2, a2, 2
  add    a5, a5, a2
#endif

  /* Don't save the return address because we're exiting after the jump */
  jr     a5, %pcrel_lo(.Lcopy_bytes)

.Lexit:
  ret
#endif
.size  memset, .-memset
