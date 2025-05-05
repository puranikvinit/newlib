/*
FUNCTION
	<<memchr>>---find character in memory

INDEX
	memchr

SYNOPSIS
	#include <string.h>
	void *memchr(const void *<[src]>, int <[c]>, size_t <[length]>);

DESCRIPTION
	This function searches memory starting at <<*<[src]>>> for the
	character <[c]>.  The search only ends with the first
	occurrence of <[c]>, or after <[length]> characters; in
	particular, <<NUL>> does not terminate the search.

RETURNS
	If the character <[c]> is found within <[length]> characters
	of <<*<[src]>>>, a pointer to the character is returned. If
	<[c]> is not found, then <<NULL>> is returned.

PORTABILITY
<<memchr>> is ANSI C.

<<memchr>> requires no supporting OS subroutines.

QUICKREF
	memchr ansi pure
*/

#include <sys/asm.h>
#include <stddef.h>
#include "rv_string.h"

#if __riscv_zilsd
#undef  SZREG
#define SZREG           8
#endif


void *
memchr (const void *src_void,
	int c,
	size_t length)
{
  const unsigned char *src = (const unsigned char *) src_void;
  unsigned char d = c;

#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
  size_t align = (uintptr_t) src & (SZREG - 1);

  if (align)
    {
      align = SZREG - align;

      if (length < align) align = length;

      switch (align)
        {
#if SZREG == 8
          case 7:
            if (*src++ == d) return (void *) (src - 1);
          case 6:
            if (*src++ == d) return (void *) (src - 1);
          case 5:
            if (*src++ == d) return (void *) (src - 1);
          case 4:
            if (*src++ == d) return (void *) (src - 1);
#endif /* SZREG == 8 */
          case 3:
            if (*src++ == d) return (void *) (src - 1);
          case 2:
            if (*src++ == d) return (void *) (src - 1);
          case 1:
            if (*src++ == d) return (void *) (src - 1);
        }

      length -= align;
    }

  const unsigned char *end_addr = src + (length & ~(SZREG - 1));

  if (src < end_addr)
    {
      uintxlen_t mask = __libc_splat_byte(d);
      uintlslen_t val;

      do
        {
#if __riscv_zilsd
          asm volatile ("ld %0, 0(%1)"
                        : "=R" (val)
                        : "r" (src)
          );
#else /* not riscv_zilsd */
          val = *(uintxlen_t*) src;
#endif /* __riscv_zilsd */
          uintxlen_t word1 = val ^ mask;

          if (__libc_detect_null(word1))
            {
#if __riscv_zbb
              word1 = ~__LIBC_RISCV_ZBB_ORC_B(word1);
              word1 = __LIBC_RISCV_ZBB_CNT_Z(word1);

              return (void *) (src + (word1 >> 3));
#else /* not __riscv_zbb */
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
#if __riscv_xlen == 64
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
#endif /* __riscv_xlen == 64 */
              return (void *) src;
#endif /* __riscv_zbb */
            }
#if __riscv_zilsd
          uintxlen_t word2 = (val >> 32);
          word2 ^= mask;

          if (__libc_detect_null(word2))
            {
              src += SZREG / 2;
#if __riscv_zbb
              word2 = ~__LIBC_RISCV_ZBB_ORC_B(word2);
              word2 = __LIBC_RISCV_ZBB_CNT_Z(word2);

              return (void *) (src + (word2 >> 3));
#else /* not __riscv_zbb */
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
              if (*src++ == d) return (void *) (src - 1);
              return (void *) src;
#endif /* __riscv_zbb */
            }
#endif /* __riscv_zilsd */

          src += SZREG;
        } while (src < end_addr);

      length &= SZREG - 1;
    }

#endif /* not PREFER_SIZE_OVER_SPEED */

  while (length--)
    {
      if (*src == d)
        return (void *) src;
      src++;
    }

  return NULL;
}
