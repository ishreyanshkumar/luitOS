/* VIRTIO BLOCK DRIVER - qemu_virt HAL backend for hal_block_*.
 *
 * HOW THE DEVICE IS FOUND. The FDT lists eight virtio-mmio slots but cannot
 * say which one has a disk behind it - an empty slot is still a node. So we
 * probe: a live slot answers magic "virt" (0x74726976) and DeviceID 2 (block).
 * No address in this file is invented; every base came from the device tree.
 *
 * TWO REGISTER LAYOUTS. QEMU exposes virtio-mmio in a legacy (version 1) and
 * a modern (version 2) flavour, selected by -global virtio-mmio.force-legacy.
 * We negotiate either at runtime. The ring protocol afterwards is identical.
 *
 * THE RING PROTOCOL (one request = a 3-descriptor chain):
 *   desc[0]: struct virtio_blk_req header (type, sector)   device-readable
 *   desc[1]: 512-byte data buffer               readable(write) / writable(read)
 *   desc[2]: 1 status byte                                  device-writable
 * We put the chain head in the AVAIL ring, bump avail->idx, kick QueueNotify.
 * The device executes it, puts the head in the USED ring, raises the IRQ, and
 * hal_block_intr() wakes the sleeping requester.
 *
 * MEMORY ORDERING. The device reads our rings via DMA with no idea what the
 * hart has or has not flushed from its store buffer. Every __sync_synchronize
 * below is load-bearing; deleting one produces a driver that works until the
 * afternoon of the demo. (Kernel RAM is identity-mapped, so kernel virtual
 * addresses ARE DMA-safe physical addresses here - see vm.c.)
 *
 * LOCKING. vdisk.lock guards the rings and free list. Requests SLEEP waiting
 * for completion (b->disk as channel), so callers hold b->lock (a sleeplock),
 * never a spinlock. Serialization across harts is by vdisk.lock alone:
 * multiple requests may be in flight - the baseline is correct, not clever.
 *
 * INVARIANTS
 *   I1: a descriptor index is either on free[] or owned by exactly one
 *       in-flight request - never both (double-complete panics).
 *   I2: b->disk == 1  <=>  the device owns b->data.
 *   I3: info[i].b != 0 only while chain i is in flight.
 */
#include "types.h"
#include "defs.h"
#include "hal.h"

/* MMIO register offsets (virtio spec 4.2.2) */
#define VIRTIO_MMIO_MAGIC_VALUE       0x000   /* 0x74726976 */
#define VIRTIO_MMIO_VERSION           0x004   /* 1 = legacy, 2 = modern */
#define VIRTIO_MMIO_DEVICE_ID         0x008   /* 2 = block device */
#define VIRTIO_MMIO_DEVICE_FEATURES   0x010
#define VIRTIO_MMIO_DRIVER_FEATURES   0x020
#define VIRTIO_MMIO_GUEST_PAGE_SIZE   0x028   /* legacy only */
#define VIRTIO_MMIO_QUEUE_SEL         0x030
#define VIRTIO_MMIO_QUEUE_NUM_MAX     0x034
#define VIRTIO_MMIO_QUEUE_NUM         0x038
#define VIRTIO_MMIO_QUEUE_ALIGN       0x03c   /* legacy only */
#define VIRTIO_MMIO_QUEUE_PFN         0x040   /* legacy only */
#define VIRTIO_MMIO_QUEUE_READY       0x044   /* modern only */
#define VIRTIO_MMIO_QUEUE_NOTIFY      0x050
#define VIRTIO_MMIO_INTERRUPT_STATUS  0x060
#define VIRTIO_MMIO_INTERRUPT_ACK     0x064
#define VIRTIO_MMIO_STATUS            0x070
#define VIRTIO_MMIO_QUEUE_DESC_LOW    0x080   /* modern only */
#define VIRTIO_MMIO_QUEUE_DESC_HIGH   0x084
#define VIRTIO_MMIO_DRIVER_DESC_LOW   0x090
#define VIRTIO_MMIO_DRIVER_DESC_HIGH  0x094
#define VIRTIO_MMIO_DEVICE_DESC_LOW   0x0a0
#define VIRTIO_MMIO_DEVICE_DESC_HIGH  0x0a4

/* status bits */
#define VIRTIO_CONFIG_S_ACKNOWLEDGE  1
#define VIRTIO_CONFIG_S_DRIVER       2
#define VIRTIO_CONFIG_S_DRIVER_OK    4
#define VIRTIO_CONFIG_S_FEATURES_OK  8

/* device features we must REFUSE (we do not implement them) */
#define VIRTIO_BLK_F_RO              5
#define VIRTIO_BLK_F_SCSI            7
#define VIRTIO_BLK_F_CONFIG_WCE     11
#define VIRTIO_BLK_F_MQ             12
#define VIRTIO_F_ANY_LAYOUT         27
#define VIRTIO_RING_F_INDIRECT_DESC 28
#define VIRTIO_RING_F_EVENT_IDX     29

#define VNUM 8                        /* ring size: must be a power of two */

struct virtq_desc  { uint64 addr; uint32 len; uint16 flags; uint16 next; };
#define VRING_DESC_F_NEXT  1
#define VRING_DESC_F_WRITE 2          /* device WRITES this buffer */
struct virtq_avail { uint16 flags; uint16 idx; uint16 ring[VNUM]; };
struct virtq_used_elem { uint32 id; uint32 len; };
struct virtq_used  { uint16 flags; uint16 idx; struct virtq_used_elem ring[VNUM]; };

struct virtio_blk_req { uint32 type; uint32 reserved; uint64 sector; };
#define VIRTIO_BLK_T_IN  0            /* disk -> memory */
#define VIRTIO_BLK_T_OUT 1            /* memory -> disk */

static struct {
    uint64 base;                      /* MMIO base (virtual alias)      */
    int    irq;
    int    version;                   /* 1 = legacy, 2 = modern         */
    /* Ring memory: legacy demands one physically-contiguous region laid
     * out desc|avail|pad-to-page|used, published as a PFN. Two pages from
     * the page allocator, in the modern case simply pointed at piecewise. */
    struct virtq_desc  *desc;
    struct virtq_avail *avail;
    struct virtq_used  *used;
    char   free[VNUM];                /* is descriptor i free?          */
    uint16 used_idx;                  /* we have consumed up to here    */
    struct {
        struct buf *b;
        struct virtio_blk_req req;    /* header must stay live in DMA   */
        uint8 status;
    } info[VNUM];
    struct spinlock lock;
} vdisk;

#define R(r) ((volatile uint32 *)(vdisk.base + (r)))

int hal_block_irq(void) { return vdisk.base ? vdisk.irq : 0; }

int hal_block_init(void)
{
    initlock(&vdisk.lock, "virtio_blk");

    /* Probe every slot the device tree reported. */
    extern uint64 mmio_alias(uint64 pa);          /* vm.c: pa -> mapped va */
    for (int i = 0; i < fdt.nvirtio; i++) {
        uint64 va = mmio_alias(fdt.virtio_base[i]);
        volatile uint32 *magic = (volatile uint32 *)(va + VIRTIO_MMIO_MAGIC_VALUE);
        volatile uint32 *devid = (volatile uint32 *)(va + VIRTIO_MMIO_DEVICE_ID);
        volatile uint32 *vers  = (volatile uint32 *)(va + VIRTIO_MMIO_VERSION);
        if (*magic == 0x74726976 && *devid == 2 && (*vers == 1 || *vers == 2)) {
            vdisk.base    = va;
            vdisk.irq     = fdt.virtio_irq[i];
            vdisk.version = *vers;
            break;
        }
    }
    if (!vdisk.base) return -1;                   /* no disk on this board */

    /* Reset, then the standard status dance. */
    *R(VIRTIO_MMIO_STATUS) = 0;
    uint32 status = VIRTIO_CONFIG_S_ACKNOWLEDGE;
    *R(VIRTIO_MMIO_STATUS) = status;
    status |= VIRTIO_CONFIG_S_DRIVER;
    *R(VIRTIO_MMIO_STATUS) = status;

    /* Implementation note. */


    uint32 feats = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    feats &= ~(1u << VIRTIO_BLK_F_RO);
    feats &= ~(1u << VIRTIO_BLK_F_SCSI);
    feats &= ~(1u << VIRTIO_BLK_F_CONFIG_WCE);
    feats &= ~(1u << VIRTIO_BLK_F_MQ);
    feats &= ~(1u << VIRTIO_F_ANY_LAYOUT);
    feats &= ~(1u << VIRTIO_RING_F_INDIRECT_DESC);
    feats &= ~(1u << VIRTIO_RING_F_EVENT_IDX);
    *R(VIRTIO_MMIO_DRIVER_FEATURES) = feats;

    if (vdisk.version == 2) {
        status |= VIRTIO_CONFIG_S_FEATURES_OK;
        *R(VIRTIO_MMIO_STATUS) = status;
        if (!(*R(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
            panic("virtio_blk: device rejected our feature set");
    }

    /* Queue 0 setup. */
    *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    if (max == 0)  panic("virtio_blk: queue 0 does not exist");
    if (max < VNUM) panic("virtio_blk: queue too short");
    *R(VIRTIO_MMIO_QUEUE_NUM) = VNUM;

    /* Two zeroed, contiguous, page-aligned pages in the legacy layout -
     * which the modern registers can also point into piecewise. Ring memory
     * must be PHYSICAL for DMA; kernel RAM is identity-mapped, so the
     * pointer values are already physical addresses. */
    static char pages[2 * PGSIZE] __attribute__((aligned(PGSIZE)));
    memset(pages, 0, sizeof(pages));
    vdisk.desc  = (struct virtq_desc *)pages;
    vdisk.avail = (struct virtq_avail *)(pages + VNUM * sizeof(struct virtq_desc));
    vdisk.used  = (struct virtq_used *)(pages + PGSIZE);

    if (vdisk.version == 1) {
        *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
        *R(VIRTIO_MMIO_QUEUE_ALIGN)     = PGSIZE;
        *R(VIRTIO_MMIO_QUEUE_PFN)       = ((uint64)pages) >> 12;
    } else {
        *R(VIRTIO_MMIO_QUEUE_DESC_LOW)   = (uint64)vdisk.desc;
        *R(VIRTIO_MMIO_QUEUE_DESC_HIGH)  = (uint64)vdisk.desc >> 32;
        *R(VIRTIO_MMIO_DRIVER_DESC_LOW)  = (uint64)vdisk.avail;
        *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)vdisk.avail >> 32;
        *R(VIRTIO_MMIO_DEVICE_DESC_LOW)  = (uint64)vdisk.used;
        *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)vdisk.used >> 32;
        *R(VIRTIO_MMIO_QUEUE_READY) = 1;
    }

    for (int i = 0; i < VNUM; i++) vdisk.free[i] = 1;

    status |= VIRTIO_CONFIG_S_DRIVER_OK;
    *R(VIRTIO_MMIO_STATUS) = status;
    return 0;
}

/* --- descriptor bookkeeping: caller holds vdisk.lock --- */
static int alloc_desc(void)
{
    for (int i = 0; i < VNUM; i++)
        if (vdisk.free[i]) { vdisk.free[i] = 0; return i; }
    return -1;
}
static void free_desc(int i)
{
    if (i >= VNUM)      panic("virtio_blk: free_desc index");
    if (vdisk.free[i])  panic("virtio_blk: double free_desc");   /* I1 */
    vdisk.desc[i] = (struct virtq_desc){0};
    vdisk.free[i] = 1;
    wakeup(&vdisk.free[0]);
}
static int alloc3_desc(int *idx)
{
    for (int i = 0; i < 3; i++) {
        idx[i] = alloc_desc();
        if (idx[i] < 0) {
            for (int j = 0; j < i; j++) free_desc(idx[j]);
            return -1;
        }
    }
    return 0;
}

void hal_block_rw(struct buf *b, int write)
{
    /* LuitFS blocks are 1024 bytes = two 512-byte disk sectors. */
    uint64 sector = b->blockno * (BSIZE / 512);

    acquire(&vdisk.lock);

    int idx[3];
    while (alloc3_desc(idx) != 0)
        sleep(&vdisk.free[0], &vdisk.lock);       /* ring full: wait */

    struct virtio_blk_req *req = &vdisk.info[idx[0]].req;
    req->type     = write ? VIRTIO_BLK_T_OUT : VIRTIO_BLK_T_IN;
    req->reserved = 0;
    req->sector   = sector;

    vdisk.desc[idx[0]] = (struct virtq_desc){
        (uint64)req, sizeof(*req), VRING_DESC_F_NEXT, (uint16)idx[1] };
    vdisk.desc[idx[1]] = (struct virtq_desc){
        (uint64)b->data, BSIZE,
        (uint16)((write ? 0 : VRING_DESC_F_WRITE) | VRING_DESC_F_NEXT),
        (uint16)idx[2] };
    vdisk.info[idx[0]].status = 0xff;             /* device overwrites on success */
    vdisk.desc[idx[2]] = (struct virtq_desc){
        (uint64)&vdisk.info[idx[0]].status, 1, VRING_DESC_F_WRITE, 0 };

    b->disk = 1;                                  /* I2: device owns b->data */
    vdisk.info[idx[0]].b = b;                     /* I3 */

    vdisk.avail->ring[vdisk.avail->idx % VNUM] = idx[0];
    __sync_synchronize();          /* ring entry visible BEFORE idx bump */
    vdisk.avail->idx += 1;
    __sync_synchronize();          /* idx visible BEFORE the doorbell    */
    *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;

    while (b->disk == 1)
        sleep(b, &vdisk.lock);                    /* intr handler wakes us */

    vdisk.info[idx[0]].b = 0;
    free_desc(idx[0]); free_desc(idx[1]); free_desc(idx[2]);

    release(&vdisk.lock);
}

void hal_block_intr(void)
{
    acquire(&vdisk.lock);

    /* Ack FIRST: a completion that lands after this read re-raises the
     * interrupt instead of being lost. */
    *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    __sync_synchronize();

    while (vdisk.used_idx != vdisk.used->idx) {   /* may batch completions */
        __sync_synchronize();
        int id = vdisk.used->ring[vdisk.used_idx % VNUM].id;

        if (vdisk.info[id].status != 0)
            panic("virtio_blk: request failed (status byte nonzero)");

        struct buf *b = vdisk.info[id].b;
        if (!b || b->disk != 1) panic("virtio_blk: completion for idle buf");
        b->disk = 0;                              /* I2: hart owns data again */
        wakeup(b);

        vdisk.used_idx += 1;
    }
    release(&vdisk.lock);
}
