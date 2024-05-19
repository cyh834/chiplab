#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

double mypow(double base, int exponent) {
    if (exponent == 0) {
        return 1.0;
    }

    double result = 1.0;
    double current_power = base;
    int remaining_exponent = exponent > 0 ? exponent : -exponent;

    while (remaining_exponent > 0) {
        if (remaining_exponent % 2 == 1) {
            result *= current_power;
        }
        current_power *= current_power;
        remaining_exponent /= 2;
    }

    return exponent > 0 ? result : 1.0 / result;
}


double ldexp(double x, int exp) {
    // 检查特殊情况
    if (x == 0.0) return x; // x 为 0
    if (x != x) return x;   // x 是 NaN
    if (x == INFINITY || x == -INFINITY) return x; // x 是正负无穷

    // 提取浮点数的各个部分
    union {
        double d;
        uint64_t u;
    } value;

    value.d = x;

    // 提取指数部分（位移和掩码）
    int exp_part = (value.u >> 52) & 0x7FF;
    
    // 检查是否是非规格化数或零
    if (exp_part == 0) {
        // 非规格化数，需要特殊处理
        value.d *= mypow(2, exp);
    } else {
        exp_part += exp;

        // 检查是否溢出
        if (exp_part <= 0) {
            // 变成非规格化数或零
            value.u &= 0x800FFFFFFFFFFFFF; // 保留符号位，清除指数部分
            value.u |= (uint64_t)(exp_part + 1023) << 52; // 添加指数部分
        } else if (exp_part >= 0x7FF) {
            // 溢出为无穷
            value.u &= 0x800FFFFFFFFFFFFF; // 保留符号位，清除指数部分
            value.u |= 0x7FF << 20; // 设置指数部分为无穷
        } else {
            // 正常情况
            value.u &= 0x800FFFFFFFFFFFFF; // 保留符号位，清除指数部分
            value.u |= (uint64_t)exp_part << 52; // 添加指数部分
        }
    }

    return value.d;
}

// 判断一个值是否是NaN
static inline bool is_nan(double x) {
    return x != x;
}

// 判断一个值是否是正无穷
static inline bool is_pos_inf(double x) {
    return x == INFINITY;
}

// 判断一个值是否是负无穷
static inline bool is_neg_inf(double x) {
    return x == -INFINITY;
}

// 分段逼近和指数分解的改进实现
double exp(double x) {
    // 处理特殊值
    if (is_nan(x)) {
        return NAN;
    }
    if (is_pos_inf(x)) {
        return INFINITY;
    }
    if (is_neg_inf(x)) {
        return 0.0;
    }

    // 定义逼近多项式的系数
    const double p1 = 1.0 / 2.0;
    const double p2 = 1.0 / 6.0;
    const double p3 = 1.0 / 24.0;
    const double p4 = 1.0 / 120.0;
    const double p5 = 1.0 / 720.0;

    // 分解 x 为整数部分 n 和小数部分 f (x = n + f)
    int n = (int)x;
    double f = x - n;

    // 对小数部分进行多项式逼近
    double result = 1.0 + f + f * f * (p1 + f * (p2 + f * (p3 + f * (p4 + f * p5))));

    // 调整结果通过 2^n
    if (n >= 0) {
        return ldexp(result, n); // 2^n * result
    } else {
        return ldexp(result, n); // 2^n * result
    }
}


//float __ieee754_expf (float x);



float expf(float x) {
    float result = 1.0f + x * (1.0f/1.0f + x * (1.0f/2.0f + x * (1.0f/6.0f + x * (1.0f/24.0f + x * (1.0f/120.0f + x * (1.0f/720.0f + x * (1.0f/5040.0f + x * (1.0f/40320.0f + x * (1.0f/362880.0f + x * (1.0f/3628800.0f))))))))));
    return result;
}
//float expf(float x)	{
//	return __ieee754_expf(x);
//}

//float __addsf3(float a, float b) { const float r = a + b; return r; }
//float __subsf3(float a, float b) { const float r = a - b; return r; }
//float __mulsf3(float a, float b) { const float r = a * b; return r; }
//float __divsf3(float a, float b) { const float r = a / b; return r; }



//系统实现
//struct ieee754_double {
//  double d;
//};
//
//const float __exp_deltatable[ 178 ] = {
//  0.000000e+00,   1.436239e-11,  -1.851323e-11,   1.250434e-12,
//  -4.382040e-10,   4.014913e-13,   6.324634e-12,   1.473544e-12,
//  -4.987366e-11,  -1.752952e-12,   6.321584e-13,  -3.260980e-12,
//  2.777399e-12,  -3.787255e-11,  -2.182022e-13,  -9.047329e-13,
//  7.118903e-12,  -3.555871e-13,  -5.198906e-12,  -4.124305e-13,
//  1.940741e-12,   2.811727e-13,  -2.117377e-13,   2.782236e-14,
//  1.074722e-13,  -8.844783e-13,  -1.240327e-16,   7.052319e-13,
//  6.447490e-13,   4.011210e-13,   5.462592e-13,   1.843201e-12,
//  -2.028864e-12,  -2.931258e-13,   8.606021e-12,  -5.626610e-13,
//  1.295899e-13,  -2.330782e-12,  -5.478326e-13,   1.845989e-12,
//  -4.234531e-12,   1.735903e-12,   1.518525e-13,   2.535486e-12,
//  -4.674620e-13,  -1.051410e-12,  -1.666138e-12,  -9.372511e-13,
//  3.200735e-12,   2.292755e-12,   2.525703e-12,   5.823944e-13,
//  -9.789686e-13,   5.145901e-13,  -4.527062e-12,  -1.683974e-12,
//  9.547877e-12,   2.078277e-13,  -2.575768e-12,  -1.026653e-12,
//  8.179204e-13,   6.063405e-13,   3.908063e-13,  -2.855789e-13,
//  -6.295203e-12,  -2.709950e-13,   4.477842e-14,   4.821464e-13,
//  -5.566389e-13,   1.357999e-12,   7.670314e-13,  -9.506315e-12,
//  -1.738782e-12,  -8.637127e-13,  -1.933394e-12,  -1.267901e-13,
//  -4.426381e-13,   1.260695e-12,  -3.277632e-12,  -1.941204e-12,
//  -4.246588e-12,   2.948061e-12,  -2.192153e-13,   1.066989e-12,
//  3.009034e-13,   9.622095e-13,   2.332691e-13,  -2.541789e-12,
//  -8.988149e-13,  -1.005515e-12,   1.152009e-12,   2.547998e-12,
//  -8.128411e-12,  -5.987095e-12,  -1.230903e-12,   1.251520e-12,
//  -1.144099e-12,  -1.419784e-14,   6.041652e-13,  -2.428500e-13,
//  -6.869299e-12,   2.192179e-13,   3.987357e-13,  -1.482881e-12,
//  3.078380e-13,   5.226606e-12,  -3.655583e-13,  -7.399489e-13,
//  -2.937312e-13,   8.345330e-13,   8.291675e-13,   6.803750e-13,
//  -3.151692e-12,   1.975098e-12,  -1.964634e-09,   1.060808e-12,
//  5.123574e-12,   5.405112e-13,   4.460744e-12,   2.254359e-12,
//  1.053220e-12,   4.224363e-12,   5.146482e-13,  -5.005111e-14,
//  6.731776e-12,  -4.826085e-12,   1.779185e-12,   5.392274e-12,
//  4.069803e-12,   5.218838e-13,  -4.566578e-12,   9.349049e-13,
//  -2.780717e-12,   1.589945e-12,   1.805627e-12,  -8.564009e-13,
//  -9.103265e-13,   1.747946e-12,   7.582737e-13,   1.880665e-12,
//  -1.509317e-12,  -8.732831e-12,  -1.582241e-14,  -2.613867e-12,
//  5.035911e-13,  -2.209310e-12,  -4.646361e-13,   1.926250e-12,
//  1.114618e-12,   2.434626e-12,  -8.526912e-13,  -1.499753e-12,
//  -1.008729e-12,  -2.222098e-12,   6.956137e-13,   2.119407e-13,
//  1.250643e-12,  -6.520809e-12,   2.357324e-13,  -1.302915e-11,
//  -2.031004e-12,  -7.972772e-13,   1.424409e-12,   4.138852e-12,
//  -1.058267e-12,  -2.656184e-12,   5.452444e-13,   1.108587e-12,
//  1.134814e-11,  -9.126315e-12,   2.758479e-12,  -1.439219e-12,
//  3.073733e-12,   2.169448e-12,   3.600419e-15,  -2.955518e-13,
//  -1.982464e-12,   2.164243e-12
//};

//int __builtin_isless(float f, float g) { return f < g;}
//int __builtin_isgreater(float f, float g) { return f > g; }
//
//double __muldf3 (double a,double  b)
//{
//  return a * b;
//}
//double __floatunsidf(unsigned int a) {
//    return (double)a;
//}

//float __ieee754_expf (float x)
//{
//  static const float himark = 88.72283935546875;
//  static const float lomark = -103.972084045410;
//  if (__builtin_isless(x, himark) && __builtin_isgreater(x, lomark))
//    {
//      int tval;
//      double x22, t, result, dx;
//      float delta;
//      struct ieee754_double ex2_u;
//      dx -= t;
//      tval = (int) (t * 512.0);
//      if (t >= 0)
//	delta = - __exp_deltatable[tval];
//      else
//	delta = __exp_deltatable[-tval];
//      x22 = (0.5000000496709180453 * dx + 1.0000001192102037084) * dx + delta;
//      result = x22 * ex2_u.d + ex2_u.d;
//      return (float) result;
//    }
//  return x;
//}

#define swapcode(TYPE, parmi, parmj, n) \
  { \
    long i = (n) / sizeof (TYPE); \
    register TYPE *pi = (TYPE *)(parmi); \
    register TYPE *pj = (TYPE *)(parmj); \
    do { \
      register TYPE  t = *pi; \
      *pi++ = *pj; \
      *pj++ = t; \
    } while (--i > 0); \
  }

#define SWAPINIT(a, width) \
  swaptype = (uintptr_t)a % sizeof(long) || \
  width % sizeof(long) ? 2 : width == sizeof(long) ? 0 : 1;

#define swap(a, b) \
  if (swaptype == 0) \
    { \
      long t = *(long *)(a); \
      *(long *)(a) = *(long *)(b); \
      *(long *)(b) = t; \
    } \
  else \
    { \
      swapfunc(a, b, width, swaptype); \
    }

#define vecswap(a, b, n) if ((n) > 0) swapfunc(a, b, n, swaptype)


static inline void swapfunc(char *a, char *b, int n, int swaptype);
static inline char *med3(char *a, char *b, char *c,
                             int (*compar)(const void *,
                             const void *));


static inline void swapfunc(char *a, char *b, int n, int swaptype)
{
  if (swaptype <= 1)
    {
      swapcode(long, a, b, n)
    }
  else
    {
      swapcode(char, a, b, n)
    }
}

static inline char *med3(char *a, char *b, char *c,
                             int (*compar)(const void *,
                             const void *))
{
  return compar(a, b) < 0 ?
         (compar(b, c) < 0 ? b : (compar(a, c) < 0 ? c : a)) :
         (compar(b, c) > 0 ? b : (compar(a, c) < 0 ? a : c));
}

void qsort(void *base, size_t nel, size_t width,
           int(*compar)(const void *, const void *))
{
  char *pa;
  char *pb;
  char *pc;
  char *pd;
  char *pl;
  char *pm;
  char *pn;
  int swaptype;
  int swap_cnt;
  int d;
  int r;

loop:
  SWAPINIT(base, width);
  swap_cnt = 0;

  if (nel < 7)
    {
      for (pm = (char *)base + width;
           pm < (char *)base + nel * width;
           pm += width)
        {
          for (pl = pm;
               pl > (char *)base && compar(pl - width, pl) > 0;
               pl -= width)
            {
              swap(pl, pl - width);
            }
        }

      return;
    }

  pm = (char *)base + (nel / 2) * width;
  if (nel > 7)
    {
      pl = base;
      pn = (char *)base + (nel - 1) * width;
      if (nel > 40)
        {
          d  = (nel / 8) * width;
          pl = med3(pl, pl + d, pl + 2 * d, compar);
          pm = med3(pm - d, pm, pm + d, compar);
          pn = med3(pn - 2 * d, pn - d, pn, compar);
        }

      pm = med3(pl, pm, pn, compar);
    }

  swap(base, pm);
  pa = pb = (char *)base + width;

  pc = pd = (char *)base + (nel - 1) * width;
  for (; ; )
    {
      while (pb <= pc && (r = compar(pb, base)) <= 0)
        {
          if (r == 0)
            {
              swap_cnt = 1;
              swap(pa, pb);
              pa += width;
            }

          pb += width;
        }

      while (pb <= pc && (r = compar(pc, base)) >= 0)
        {
          if (r == 0)
            {
              swap_cnt = 1;
              swap(pc, pd);
              pd -= width;
            }

          pc -= width;
        }

      if (pb > pc)
        {
          break;
        }

      swap(pb, pc);
      swap_cnt = 1;
      pb      += width;
      pc      -= width;
    }

  if (swap_cnt == 0)
    {
      /* Switch to insertion sort */

      for (pm = (char *)base + width;
           pm < (char *)base + nel * width;
           pm += width)
        {
          for (pl = pm;
               pl > (char *)base && compar(pl - width, pl) > 0;
               pl -= width)
            {
              swap(pl, pl - width);
            }
        }

      return;
    }

  pn = (char *)base + nel * width;
  r  = MIN(pa - (char *)base, pb - pa);
  vecswap(base, pb - r, r);

  r  = MIN(pd - pc, pn - pd - width);
  vecswap(pb, pn - r, r);

  if ((r = pb - pa) > width)
    {
      qsort(base, r / width, width, compar);
    }

  if ((r = pd - pc) > width)
    {
      /* Iterate rather than recurse to save stack space */

      base = pn - r;
      nel = r / width;
      goto loop;
    }
}
#endif