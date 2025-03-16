/* Copyright (c) 2017  SiFive Inc. All rights reserved.

   This copyrighted material is made available to anyone wishing to use,
   modify, copy, or redistribute it subject to the terms and conditions
   of the FreeBSD License.   This program is distributed in the hope that
   it will be useful, but WITHOUT ANY WARRANTY expressed or implied,
   including the implied warranties of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  A copy of this license is available at
   http://www.opensource.org/licenses.
*/

#ifndef _SYS_STRING_H
#define _SYS_STRING_H

#include <stdint.h>

#if __riscv_zbb
  #include <riscv_bitmanip.h>

  // Determine which intrinsics to use based on word size and endianness
  #if __riscv_xlen == 64
    #define __LIBC_RISCV_ZBB_ORC_B       __riscv_orc_b_64

    #if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
      #define __LIBC_RISCV_ZBB_CNT_Z     __riscv_ctz_64
    #else
      #define __LIBC_RISCV_ZBB_CNT_Z     __riscv_clz_64
    #endif
  #else
    #define __LIBC_RISCV_ZBB_ORC_B       __riscv_orc_b_32

    #if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
      #define __LIBC_RISCV_ZBB_CNT_Z     __riscv_ctz_32
    #else
      #define __LIBC_RISCV_ZBB_CNT_Z     __riscv_clz_32
    #endif
  #endif
#endif

static __inline unsigned long __libc_detect_null(unsigned long w)
{
#if __riscv_zbb
  /*
    If there are any zeros in each byte of the register, all bits will
    be unset for that byte value, otherwise, all bits will be set.
    If the value is -1, all bits are set, meaning no null byte was found.
  */
  return __LIBC_RISCV_ZBB_ORC_B(w) != -1;
#else
  unsigned long mask = 0x7f7f7f7f;
  if (sizeof (long) == 8)
    mask = ((mask << 16) << 16) | mask;
  return ~(((w & mask) + mask) | w | mask);
#endif
}

static __inline char *__libc_strcpy(char *dst, const char *src, int rs)
{
  char *dst0 = dst;

#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
#if !(__riscv_misaligned_slow || __riscv_misaligned_fast)
  int misaligned = ((uintptr_t)dst | (uintptr_t)src) & (sizeof (uintptr_t) - 1);
  if (__builtin_expect(!misaligned, 1))
#endif
    {
      uintptr_t *pdst = (uintptr_t *)dst;
      const uintptr_t *psrc = (const uintptr_t *)src;

      while (!__libc_detect_null(*psrc))
        *pdst++ = *psrc++;

      dst = (char *)pdst;
      src = (const char *)psrc;

      // Check whether we return the start or the end of the string
      if (rs)
        {
          if (!(*dst++ = src[0])) return dst0;
          if (!(*dst++ = src[1])) return dst0;
          if (!(*dst++ = src[2])) return dst0;
          if (!(*dst++ = src[3])) return dst0;
          if (!(*dst++ = src[4])) return dst0;
          if (!(*dst++ = src[5])) return dst0;
          if (!(*dst++ = src[6])) return dst0;
        }
      else
        {
          if (!(*dst++ = src[0])) return dst - 1;
          if (!(*dst++ = src[1])) return dst - 1;
          if (!(*dst++ = src[2])) return dst - 1;
          if (!(*dst++ = src[3])) return dst - 1;
          if (!(*dst++ = src[4])) return dst - 1;
          if (!(*dst++ = src[5])) return dst - 1;
          if (!(*dst++ = src[6])) return dst - 1;
          dst0 = dst;
        }

out:
      *dst = 0;
      return dst0;
    }
#endif /* not PREFER_SIZE_OVER_SPEED */

  char ch;
  do
    {
      ch = *src;
      src++;
      dst++;
      *(dst - 1) = ch;
    } while (ch);

  return rs ? dst0 : dst - 1;
}

#endif
