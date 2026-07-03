#pragma once
#ifndef HAVE_PRINTF_H
#include <stddef.h>

enum {
  PA_INT,
  PA_CHAR,
  PA_WCHAR,
  PA_STRING,
  PA_WSTRING,
  PA_POINTER,
  PA_FLOAT,
  PA_DOUBLE,
  PA_LAST
};

#define PA_FLAG_MASK            0xff00
#define PA_FLAG_LONG_LONG       (1 << 8)
#define PA_FLAG_LONG_DOUBLE     PA_FLAG_LONG_LONG
#define PA_FLAG_LONG            (1 << 9)
#define PA_FLAG_SHORT           (1 << 10)
#define PA_FLAG_PTR             (1 << 11)

size_t parse_printf_format(const char *fmt, size_t n, int *types);
#else
#include <printf.h>
#endif
