#ifndef __YOLOV4_H__
#define __YOLOV4_H__

#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define IOE ({ ioe_init();  })
#define CTE(h) ({ Context *h(Event, Context *); cte_init(h); })
#define VME(f1, f2) ({ void *f1(int); void f2(void *); vme_init(f1, f2); })
#define MPE ({ mpe_init(entry); })

#endif
