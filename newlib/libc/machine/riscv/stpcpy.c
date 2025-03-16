#include <string.h>

char *stpcpy(char *dst, const char *src)
{
  return __libc_strcpy(dst, src, 0);
}
