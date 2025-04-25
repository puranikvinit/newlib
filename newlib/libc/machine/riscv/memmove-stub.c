#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
#include <string.h>
#include <_ansi.h>
#include <stddef.h>
#include <limits.h>
#include "xlenint.h"
#include "sys/asm.h"
#include "../../string/local.h"


#if !defined(__riscv_misaligned_avoid)
#define UNALIGNED_XLEN(X,Y) (0)
#else
/* Nonzero if either X or Y is not aligned to XLEN. (analogous to macro in ../../string/local.h)  */
#define UNALIGNED_XLEN(X,Y) (((uintxlen_t)X & (SZREG-1)) | ((uintxlen_t)Y & (SZREG-1)))
#endif


/*SUPPRESS 20*/
void *
__inhibit_loop_to_libcall memmove (void *dst_void, const void *src_void, size_t length) {

	unsigned char *dst = dst_void;
	const unsigned char *src = src_void;
	uintxlen_t *aligned_dst;
	const uintxlen_t *aligned_src;

	if (src < dst && dst < src + length) {
		/* Destructive overlap...have to copy backwards */
		src += length;
		dst += length;

		if (length >= SZREG && !UNALIGNED_XLEN(src, dst)) {

			aligned_dst = (uintxlen_t*)dst;
			aligned_src = (uintxlen_t*)src;

			/* Copy SZREG bytes at a time if possible.  */
			while (length >= SZREG) {
				*--aligned_dst = *--aligned_src;
				length -= SZREG;
			}

			/* Pick up any residual with a byte copier.  */
			dst = (unsigned char*)aligned_dst;
			src = (unsigned char*)aligned_src;
		}

		while (length--) { *--dst = *--src; }
	}
	else {
		/* Use optimizing algorithm for a non-destructive copy to closely
		   match memcpy. If the size is small or either SRC or DST is unaligned,
		   then punt into the byte copy loop.  This should be rare.  */
		if (length >= SZREG && !UNALIGNED_XLEN(src, dst)) {

			aligned_dst = (uintxlen_t*)dst;
			aligned_src = (uintxlen_t*)src;

			/* Copy 4X SZREG bytes at a time if possible.  */
			while (length >= (SZREG<<2)) {
				*aligned_dst++ = *aligned_src++;
				*aligned_dst++ = *aligned_src++;
				*aligned_dst++ = *aligned_src++;
				*aligned_dst++ = *aligned_src++;
				length -= (SZREG<<2);
			}


			/* Copy SZREG bytes at a time if possible.  */
			while (length >= SZREG) {
				*aligned_dst++ = *aligned_src++;
				length -= SZREG;
			}

			/* Pick up any residual with a byte copier.  */
			dst = (unsigned char*)aligned_dst;
			src = (unsigned char*)aligned_src;
		}

		while (length--) { *dst++ = *src++; }
	}

	return dst_void;
}
#endif /* not PREFER_SIZE_OVER_SPEED */
