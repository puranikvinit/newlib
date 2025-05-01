#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
#include <string.h>
#include <_ansi.h>
#include <stddef.h>
#include <limits.h>
#include "xlenint.h"
#include "sys/asm.h"
#include "../../string/local.h"

static inline uint8_t __libc_aligned_xlen(void *dst, const void *src) {
#if defined(__riscv_misaligned_fast)
	return 1;
#else
	return !(((uintxlen_t)src & (SZREG-1)) | ((uintxlen_t)dst & (SZREG-1)));
#endif
}

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

		if (length >= SZREG && __libc_aligned_xlen(dst, src)) {

			aligned_dst = (uintxlen_t*)dst;
			aligned_src = (uintxlen_t*)src;

			/* Copy 9X SZREG bytes at a time if possible.  */
			while (length >= (SZREG*9)) {
				uintxlen_t dst0 = *--aligned_src;
				uintxlen_t dst1 = *--aligned_src;
				uintxlen_t dst2 = *--aligned_src;
				uintxlen_t dst3 = *--aligned_src;
				uintxlen_t dst4 = *--aligned_src;
				uintxlen_t dst5 = *--aligned_src;
				uintxlen_t dst6 = *--aligned_src;
				uintxlen_t dst7 = *--aligned_src;
				uintxlen_t dst8 = *--aligned_src;

				*--aligned_dst = dst0;
				*--aligned_dst = dst1;
				*--aligned_dst = dst2;
				*--aligned_dst = dst3;
				*--aligned_dst = dst4;
				*--aligned_dst = dst5;
				*--aligned_dst = dst6;
				*--aligned_dst = dst7;
				*--aligned_dst = dst8;

				length -= SZREG*9;
			}

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
		if (length >= SZREG && __libc_aligned_xlen(dst, src)) {

			aligned_dst = (uintxlen_t*)dst;
			aligned_src = (uintxlen_t*)src;

			/* Copy 9X SZREG bytes at a time if possible.  */
			while (length >= (SZREG*9)) {
				uintxlen_t dst0 = *aligned_src++;
				uintxlen_t dst1 = *aligned_src++;
				uintxlen_t dst2 = *aligned_src++;
				uintxlen_t dst3 = *aligned_src++;
				uintxlen_t dst4 = *aligned_src++;
				uintxlen_t dst5 = *aligned_src++;
				uintxlen_t dst6 = *aligned_src++;
				uintxlen_t dst7 = *aligned_src++;
				uintxlen_t dst8 = *aligned_src++;

				*aligned_dst++ = dst0;
				*aligned_dst++ = dst1;
				*aligned_dst++ = dst2;
				*aligned_dst++ = dst3;
				*aligned_dst++ = dst4;
				*aligned_dst++ = dst5;
				*aligned_dst++ = dst6;
				*aligned_dst++ = dst7;
				*aligned_dst++ = dst8;

				length -= SZREG*9;
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
