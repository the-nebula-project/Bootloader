#ifndef _DEFS_H
#define _DEFS_H

#define SECOND_STAGE            0x7e00
#define BOOT_SECTOR             0x7c00
#define SECOND_STAGE_SECTORS    0x10

#define SECTOR_SIZE             0x200
#define REALMODE_STACK          (SECOND_STAGE + SECOND_STAGE_SECTORS * SECTOR_SIZE)
#define STACK_SECTORS           0x4
#define STACK_SIZE              (STACK_SECTORS * SECTOR_SIZE)

#endif
