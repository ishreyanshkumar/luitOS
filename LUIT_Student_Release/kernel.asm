
kernel.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <_entry>:
# Implementation note.
# a0 = hartid, a1 = physical address of the FDT blob. Both must survive to start().
.section .text.entry
.globl _entry
_entry:
        la      t0, boot_stacks
    80200000:	00009297          	auipc	t0,0x9
    80200004:	00028293          	mv	t0,t0
        li      t1, 16384
    80200008:	6311                	lui	t1,0x4
        addi    t2, a0, 1
    8020000a:	00150393          	addi	t2,a0,1
        mul     t1, t1, t2
    8020000e:	02730333          	mul	t1,t1,t2
        add     sp, t0, t1      # sp = boot_stacks + (hartid+1)*16384
    80200012:	00628133          	add	sp,t0,t1
        mv      tp, a0          # tp = hartid, for mycpu()
    80200016:	822a                	mv	tp,a0
        call    start
    80200018:	00000097          	auipc	ra,0x0
    8020001c:	00e080e7          	jalr	14(ra) # 80200026 <start>

0000000080200020 <spin>:
spin:   wfi
    80200020:	10500073          	wfi
        j       spin
    80200024:	bff5                	j	80200020 <spin>

0000000080200026 <start>:
    printf("hart %d: online\n", hal_hart_id());
    scheduler();            /* never returns */
}

void start(uint64 hartid, uint64 fdt_pa)
{
    80200026:	7179                	addi	sp,sp,-48
    80200028:	f406                	sd	ra,40(sp)
    8020002a:	f022                	sd	s0,32(sp)
    8020002c:	1800                	addi	s0,sp,48
        }

        scheduler();
    } else {
        /* --- secondary harts --- */
        while (started == 0)
    8020002e:	0013f717          	auipc	a4,0x13f
    80200032:	fd270713          	addi	a4,a4,-46 # 8033f000 <started>
    if (hartid == 0) {
    80200036:	c139                	beqz	a0,8020007c <start+0x56>
    80200038:	ec26                	sd	s1,24(sp)
    8020003a:	e84a                	sd	s2,16(sp)
    8020003c:	e44e                	sd	s3,8(sp)
    8020003e:	e052                	sd	s4,0(sp)
        while (started == 0)
    80200040:	431c                	lw	a5,0(a4)
    80200042:	2781                	sext.w	a5,a5
    80200044:	dff5                	beqz	a5,80200040 <start+0x1a>
            ;
        __sync_synchronize();
    80200046:	0330000f          	fence	rw,rw
    kvminithart();          /* same kernel page table */
    8020004a:	00003097          	auipc	ra,0x3
    8020004e:	c9c080e7          	jalr	-868(ra) # 80202ce6 <kvminithart>
    trapinit_hart();        /* own stvec, own timer, own PLIC context */
    80200052:	00002097          	auipc	ra,0x2
    80200056:	3a8080e7          	jalr	936(ra) # 802023fa <trapinit_hart>
    printf("hart %d: online\n", hal_hart_id());
    8020005a:	00006097          	auipc	ra,0x6
    8020005e:	042080e7          	jalr	66(ra) # 8020609c <hal_hart_id>
    80200062:	85aa                	mv	a1,a0
    80200064:	00007517          	auipc	a0,0x7
    80200068:	11c50513          	addi	a0,a0,284 # 80207180 <etext+0x180>
    8020006c:	00000097          	auipc	ra,0x0
    80200070:	2d4080e7          	jalr	724(ra) # 80200340 <printf>
    scheduler();            /* never returns */
    80200074:	00002097          	auipc	ra,0x2
    80200078:	ae8080e7          	jalr	-1304(ra) # 80201b5c <scheduler>
    8020007c:	ec26                	sd	s1,24(sp)
    8020007e:	e84a                	sd	s2,16(sp)
    80200080:	e44e                	sd	s3,8(sp)
        fdt_init(fdt_pa);
    80200082:	852e                	mv	a0,a1
    80200084:	00001097          	auipc	ra,0x1
    80200088:	856080e7          	jalr	-1962(ra) # 802008da <fdt_init>
        printf("\n");
    8020008c:	00007517          	auipc	a0,0x7
    80200090:	f7450513          	addi	a0,a0,-140 # 80207000 <etext>
    80200094:	00000097          	auipc	ra,0x0
    80200098:	2ac080e7          	jalr	684(ra) # 80200340 <printf>
        printf("=========================================\n");
    8020009c:	00007517          	auipc	a0,0x7
    802000a0:	f6c50513          	addi	a0,a0,-148 # 80207008 <etext+0x8>
    802000a4:	00000097          	auipc	ra,0x0
    802000a8:	29c080e7          	jalr	668(ra) # 80200340 <printf>
        printf("  BrahmaputraOS / kernel Luit\n");
    802000ac:	00007517          	auipc	a0,0x7
    802000b0:	f8c50513          	addi	a0,a0,-116 # 80207038 <etext+0x38>
    802000b4:	00000097          	auipc	ra,0x0
    802000b8:	28c080e7          	jalr	652(ra) # 80200340 <printf>
        printf("  IIT Guwahati - CS3106L\n");
    802000bc:	00007517          	auipc	a0,0x7
    802000c0:	f9c50513          	addi	a0,a0,-100 # 80207058 <etext+0x58>
    802000c4:	00000097          	auipc	ra,0x0
    802000c8:	27c080e7          	jalr	636(ra) # 80200340 <printf>
        printf("=========================================\n");
    802000cc:	00007517          	auipc	a0,0x7
    802000d0:	f3c50513          	addi	a0,a0,-196 # 80207008 <etext+0x8>
    802000d4:	00000097          	auipc	ra,0x0
    802000d8:	26c080e7          	jalr	620(ra) # 80200340 <printf>
        printf("fdt   : blob at %p (%d bytes)\n", fdt.blob, fdt.blob_size);
    802000dc:	00029497          	auipc	s1,0x29
    802000e0:	f3c48493          	addi	s1,s1,-196 # 80229018 <fdt>
    802000e4:	6490                	ld	a2,8(s1)
    802000e6:	608c                	ld	a1,0(s1)
    802000e8:	00007517          	auipc	a0,0x7
    802000ec:	f9050513          	addi	a0,a0,-112 # 80207078 <etext+0x78>
    802000f0:	00000097          	auipc	ra,0x0
    802000f4:	250080e7          	jalr	592(ra) # 80200340 <printf>
        printf("uart  : %p  (discovered, not hardcoded)\n", fdt.uart_base);
    802000f8:	688c                	ld	a1,16(s1)
    802000fa:	00007517          	auipc	a0,0x7
    802000fe:	f9e50513          	addi	a0,a0,-98 # 80207098 <etext+0x98>
    80200102:	00000097          	auipc	ra,0x0
    80200106:	23e080e7          	jalr	574(ra) # 80200340 <printf>
        printf("plic  : %p\n", fdt.plic_base);
    8020010a:	6c8c                	ld	a1,24(s1)
    8020010c:	00007517          	auipc	a0,0x7
    80200110:	fbc50513          	addi	a0,a0,-68 # 802070c8 <etext+0xc8>
    80200114:	00000097          	auipc	ra,0x0
    80200118:	22c080e7          	jalr	556(ra) # 80200340 <printf>
        printf("memory: %p + %d MiB\n", fdt.mem_base, fdt.mem_size >> 20);
    8020011c:	6cd0                	ld	a2,152(s1)
    8020011e:	8251                	srli	a2,a2,0x14
    80200120:	68cc                	ld	a1,144(s1)
    80200122:	00007517          	auipc	a0,0x7
    80200126:	fb650513          	addi	a0,a0,-74 # 802070d8 <etext+0xd8>
    8020012a:	00000097          	auipc	ra,0x0
    8020012e:	216080e7          	jalr	534(ra) # 80200340 <printf>
        printf("harts : %d\n", fdt.ncpu);
    80200132:	0a04a583          	lw	a1,160(s1)
    80200136:	00007517          	auipc	a0,0x7
    8020013a:	fba50513          	addi	a0,a0,-70 # 802070f0 <etext+0xf0>
    8020013e:	00000097          	auipc	ra,0x0
    80200142:	202080e7          	jalr	514(ra) # 80200340 <printf>
        hal_console_init(fdt.uart_base);
    80200146:	6888                	ld	a0,16(s1)
    80200148:	00006097          	auipc	ra,0x6
    8020014c:	016080e7          	jalr	22(ra) # 8020615e <hal_console_init>
        hal_intc_init(fdt.plic_base);
    80200150:	6c88                	ld	a0,24(s1)
    80200152:	00006097          	auipc	ra,0x6
    80200156:	e3e080e7          	jalr	-450(ra) # 80205f90 <hal_intc_init>
        console_ready = 1;
    8020015a:	0013f917          	auipc	s2,0x13f
    8020015e:	eaa90913          	addi	s2,s2,-342 # 8033f004 <console_ready>
    80200162:	4985                	li	s3,1
    80200164:	01392023          	sw	s3,0(s2)
        palloc_init();
    80200168:	00001097          	auipc	ra,0x1
    8020016c:	dea080e7          	jalr	-534(ra) # 80200f52 <palloc_init>
        printfinit();       /* locked printf, now that we have locks + memory */
    80200170:	00000097          	auipc	ra,0x0
    80200174:	40e080e7          	jalr	1038(ra) # 8020057e <printfinit>
        procinit();
    80200178:	00001097          	auipc	ra,0x1
    8020017c:	60e080e7          	jalr	1550(ra) # 80201786 <procinit>
        kvminit();
    80200180:	00003097          	auipc	ra,0x3
    80200184:	a46080e7          	jalr	-1466(ra) # 80202bc6 <kvminit>
        kvminithart();      /* paging ON for this hart */
    80200188:	00003097          	auipc	ra,0x3
    8020018c:	b5e080e7          	jalr	-1186(ra) # 80202ce6 <kvminithart>
        console_ready = 0;                    /* SBI console while we re-point */
    80200190:	00092023          	sw	zero,0(s2)
        hal_console_init(mmio_alias(fdt.uart_base));
    80200194:	6888                	ld	a0,16(s1)
    80200196:	00003097          	auipc	ra,0x3
    8020019a:	856080e7          	jalr	-1962(ra) # 802029ec <mmio_alias>
    8020019e:	00006097          	auipc	ra,0x6
    802001a2:	fc0080e7          	jalr	-64(ra) # 8020615e <hal_console_init>
        console_ready = 1;
    802001a6:	01392023          	sw	s3,0(s2)
        hal_intc_init(mmio_alias(fdt.plic_base));
    802001aa:	6c88                	ld	a0,24(s1)
    802001ac:	00003097          	auipc	ra,0x3
    802001b0:	840080e7          	jalr	-1984(ra) # 802029ec <mmio_alias>
    802001b4:	00006097          	auipc	ra,0x6
    802001b8:	ddc080e7          	jalr	-548(ra) # 80205f90 <hal_intc_init>
        consoleinit();      /* console device (major CONSOLE)         */
    802001bc:	00004097          	auipc	ra,0x4
    802001c0:	fb4080e7          	jalr	-76(ra) # 80204170 <consoleinit>
        binit();            /* buffer cache                           */
    802001c4:	00004097          	auipc	ra,0x4
    802001c8:	53a080e7          	jalr	1338(ra) # 802046fe <binit>
        iinit();            /* inode cache                            */
    802001cc:	00005097          	auipc	ra,0x5
    802001d0:	b66080e7          	jalr	-1178(ra) # 80204d32 <iinit>
        fileinit();         /* system-wide open-file table            */
    802001d4:	00005097          	auipc	ra,0x5
    802001d8:	692080e7          	jalr	1682(ra) # 80205866 <fileinit>
        if (hal_block_init() < 0)
    802001dc:	00006097          	auipc	ra,0x6
    802001e0:	0b0080e7          	jalr	176(ra) # 8020628c <hal_block_init>
    802001e4:	04054e63          	bltz	a0,80200240 <start+0x21a>
    802001e8:	e052                	sd	s4,0(sp)
        trapinit_hart();    /* traps, timer, PLIC (incl. the disk irq) */
    802001ea:	00002097          	auipc	ra,0x2
    802001ee:	210080e7          	jalr	528(ra) # 802023fa <trapinit_hart>
        userinit();         /* the first user process                 */
    802001f2:	00001097          	auipc	ra,0x1
    802001f6:	62c080e7          	jalr	1580(ra) # 8020181e <userinit>
        printf("hart 0: online\n");
    802001fa:	00007517          	auipc	a0,0x7
    802001fe:	f4e50513          	addi	a0,a0,-178 # 80207148 <etext+0x148>
    80200202:	00000097          	auipc	ra,0x0
    80200206:	13e080e7          	jalr	318(ra) # 80200340 <printf>
        __sync_synchronize();
    8020020a:	0330000f          	fence	rw,rw
        started = 1;
    8020020e:	4785                	li	a5,1
    80200210:	0013f717          	auipc	a4,0x13f
    80200214:	def72823          	sw	a5,-528(a4) # 8033f000 <started>
        for (int i = 1; i < fdt.ncpu; i++) {
    80200218:	00029717          	auipc	a4,0x29
    8020021c:	ea072703          	lw	a4,-352(a4) # 802290b8 <fdt+0xa0>
    80200220:	06e7d163          	bge	a5,a4,80200282 <start+0x25c>
    80200224:	84be                	mv	s1,a5
            long err = sbi_hart_start(i, (uint64)_entry, 0);
    80200226:	00000997          	auipc	s3,0x0
    8020022a:	dda98993          	addi	s3,s3,-550 # 80200000 <_entry>
            if (err) printf("hart %d: failed to start (sbi err %d)\n", i, err);
    8020022e:	00007a17          	auipc	s4,0x7
    80200232:	f2aa0a13          	addi	s4,s4,-214 # 80207158 <etext+0x158>
        for (int i = 1; i < fdt.ncpu; i++) {
    80200236:	00029917          	auipc	s2,0x29
    8020023a:	de290913          	addi	s2,s2,-542 # 80229018 <fdt>
    8020023e:	a00d                	j	80200260 <start+0x23a>
    80200240:	e052                	sd	s4,0(sp)
            panic("no block device: did you forget -drive/-device? (make qemu adds it)");
    80200242:	00007517          	auipc	a0,0x7
    80200246:	ebe50513          	addi	a0,a0,-322 # 80207100 <etext+0x100>
    8020024a:	00000097          	auipc	ra,0x0
    8020024e:	366080e7          	jalr	870(ra) # 802005b0 <panic>
        for (int i = 1; i < fdt.ncpu; i++) {
    80200252:	0485                	addi	s1,s1,1
    80200254:	0a092703          	lw	a4,160(s2)
    80200258:	0004879b          	sext.w	a5,s1
    8020025c:	02e7d363          	bge	a5,a4,80200282 <start+0x25c>
            long err = sbi_hart_start(i, (uint64)_entry, 0);
    80200260:	4601                	li	a2,0
    80200262:	85ce                	mv	a1,s3
    80200264:	8526                	mv	a0,s1
    80200266:	00000097          	auipc	ra,0x0
    8020026a:	58a080e7          	jalr	1418(ra) # 802007f0 <sbi_hart_start>
            if (err) printf("hart %d: failed to start (sbi err %d)\n", i, err);
    8020026e:	d175                	beqz	a0,80200252 <start+0x22c>
    80200270:	862a                	mv	a2,a0
    80200272:	0004859b          	sext.w	a1,s1
    80200276:	8552                	mv	a0,s4
    80200278:	00000097          	auipc	ra,0x0
    8020027c:	0c8080e7          	jalr	200(ra) # 80200340 <printf>
    80200280:	bfc9                	j	80200252 <start+0x22c>
        scheduler();
    80200282:	00002097          	auipc	ra,0x2
    80200286:	8da080e7          	jalr	-1830(ra) # 80201b5c <scheduler>

000000008020028a <putc>:

/* Before the UART driver exists (i.e. before the device tree has told us where
 * the UART is), fall back to OpenSBI's console. This is why a panic inside
 * fdt_init() is still visible - a silent early panic is a nightmare to debug. */
int console_ready = 0;
static void putc(char c) { if (console_ready) hal_console_putc(c); else sbi_putchar(c); }
    8020028a:	1141                	addi	sp,sp,-16
    8020028c:	e406                	sd	ra,8(sp)
    8020028e:	e022                	sd	s0,0(sp)
    80200290:	0800                	addi	s0,sp,16
    80200292:	0013f797          	auipc	a5,0x13f
    80200296:	d727a783          	lw	a5,-654(a5) # 8033f004 <console_ready>
    8020029a:	cb89                	beqz	a5,802002ac <putc+0x22>
    8020029c:	00006097          	auipc	ra,0x6
    802002a0:	f00080e7          	jalr	-256(ra) # 8020619c <hal_console_putc>
    802002a4:	60a2                	ld	ra,8(sp)
    802002a6:	6402                	ld	s0,0(sp)
    802002a8:	0141                	addi	sp,sp,16
    802002aa:	8082                	ret
    802002ac:	00000097          	auipc	ra,0x0
    802002b0:	4ea080e7          	jalr	1258(ra) # 80200796 <sbi_putchar>
    802002b4:	bfc5                	j	802002a4 <putc+0x1a>

00000000802002b6 <printint>:

static void printint(long long xx, int base, int sign)
{
    802002b6:	7139                	addi	sp,sp,-64
    802002b8:	fc06                	sd	ra,56(sp)
    802002ba:	f822                	sd	s0,48(sp)
    802002bc:	f426                	sd	s1,40(sp)
    802002be:	f04a                	sd	s2,32(sp)
    802002c0:	0080                	addi	s0,sp,64
    char buf[24];
    int i = 0;
    unsigned long long x;

    if (sign && xx < 0) { x = -xx; } else { sign = 0; x = xx; }
    802002c2:	c219                	beqz	a2,802002c8 <printint+0x12>
    802002c4:	06054b63          	bltz	a0,8020033a <printint+0x84>
    802002c8:	4601                	li	a2,0
    802002ca:	fc840e13          	addi	t3,s0,-56
    802002ce:	86f2                	mv	a3,t3
    802002d0:	4781                	li	a5,0
    do { buf[i++] = digits[x % base]; } while ((x /= base) != 0);
    802002d2:	00008897          	auipc	a7,0x8
    802002d6:	ae688893          	addi	a7,a7,-1306 # 80207db8 <digits>
    802002da:	833e                	mv	t1,a5
    802002dc:	0017881b          	addiw	a6,a5,1
    802002e0:	87c2                	mv	a5,a6
    802002e2:	02b57733          	remu	a4,a0,a1
    802002e6:	9746                	add	a4,a4,a7
    802002e8:	00074703          	lbu	a4,0(a4)
    802002ec:	00e68023          	sb	a4,0(a3)
    802002f0:	872a                	mv	a4,a0
    802002f2:	02b55533          	divu	a0,a0,a1
    802002f6:	0685                	addi	a3,a3,1
    802002f8:	feb771e3          	bgeu	a4,a1,802002da <printint+0x24>
    if (sign) buf[i++] = '-';
    802002fc:	ca19                	beqz	a2,80200312 <printint+0x5c>
    802002fe:	fe080793          	addi	a5,a6,-32
    80200302:	00878833          	add	a6,a5,s0
    80200306:	02d00793          	li	a5,45
    8020030a:	fef80423          	sb	a5,-24(a6)
    8020030e:	0023079b          	addiw	a5,t1,2 # 4002 <_entry-0x801fbffe>
    while (--i >= 0) putc(buf[i]);
    80200312:	fff7891b          	addiw	s2,a5,-1
    80200316:	01c784b3          	add	s1,a5,t3
    8020031a:	fff4c503          	lbu	a0,-1(s1)
    8020031e:	00000097          	auipc	ra,0x0
    80200322:	f6c080e7          	jalr	-148(ra) # 8020028a <putc>
    80200326:	397d                	addiw	s2,s2,-1
    80200328:	14fd                	addi	s1,s1,-1
    8020032a:	fe0958e3          	bgez	s2,8020031a <printint+0x64>
}
    8020032e:	70e2                	ld	ra,56(sp)
    80200330:	7442                	ld	s0,48(sp)
    80200332:	74a2                	ld	s1,40(sp)
    80200334:	7902                	ld	s2,32(sp)
    80200336:	6121                	addi	sp,sp,64
    80200338:	8082                	ret
    if (sign && xx < 0) { x = -xx; } else { sign = 0; x = xx; }
    8020033a:	40a00533          	neg	a0,a0
    8020033e:	b771                	j	802002ca <printint+0x14>

0000000080200340 <printf>:
    for (int i = 0; i < 16; i++, x <<= 4)
        putc(digits[x >> 60]);
}

void printf(const char *fmt, ...)
{
    80200340:	7171                	addi	sp,sp,-176
    80200342:	f486                	sd	ra,104(sp)
    80200344:	f0a2                	sd	s0,96(sp)
    80200346:	e4ce                	sd	s3,72(sp)
    80200348:	f45e                	sd	s7,40(sp)
    8020034a:	1880                	addi	s0,sp,112
    8020034c:	89aa                	mv	s3,a0
    8020034e:	e40c                	sd	a1,8(s0)
    80200350:	e810                	sd	a2,16(s0)
    80200352:	ec14                	sd	a3,24(s0)
    80200354:	f018                	sd	a4,32(s0)
    80200356:	f41c                	sd	a5,40(s0)
    80200358:	03043823          	sd	a6,48(s0)
    8020035c:	03143c23          	sd	a7,56(s0)
    va_list ap;
    int locking = pr_locking;
    80200360:	0013fb97          	auipc	s7,0x13f
    80200364:	ca8bab83          	lw	s7,-856(s7) # 8033f008 <pr_locking>
    if (locking) acquire(&pr_lock);
    80200368:	020b9863          	bnez	s7,80200398 <printf+0x58>

    va_start(ap, fmt);
    8020036c:	00840793          	addi	a5,s0,8
    80200370:	f8f43c23          	sd	a5,-104(s0)
    for (int i = 0; fmt[i]; i++) {
    80200374:	00054503          	lbu	a0,0(a0)
    80200378:	1c050f63          	beqz	a0,80200556 <printf+0x216>
    8020037c:	eca6                	sd	s1,88(sp)
    8020037e:	e8ca                	sd	s2,80(sp)
    80200380:	e0d2                	sd	s4,64(sp)
    80200382:	fc56                	sd	s5,56(sp)
    80200384:	f85a                	sd	s6,48(sp)
    80200386:	4901                	li	s2,0
        char c = fmt[i];
        if (c != '%') { putc(c); continue; }
    80200388:	02500a13          	li	s4,37
        c = fmt[++i];
        if (!c) break;
        switch (c) {
    8020038c:	4ad5                	li	s5,21
    8020038e:	00008b17          	auipc	s6,0x8
    80200392:	9d2b0b13          	addi	s6,s6,-1582 # 80207d60 <etext+0xd60>
    80200396:	a82d                	j	802003d0 <printf+0x90>
    if (locking) acquire(&pr_lock);
    80200398:	00029517          	auipc	a0,0x29
    8020039c:	c6850513          	addi	a0,a0,-920 # 80229000 <pr_lock>
    802003a0:	00001097          	auipc	ra,0x1
    802003a4:	f60080e7          	jalr	-160(ra) # 80201300 <acquire>
    va_start(ap, fmt);
    802003a8:	00840793          	addi	a5,s0,8
    802003ac:	f8f43c23          	sd	a5,-104(s0)
    for (int i = 0; fmt[i]; i++) {
    802003b0:	0009c503          	lbu	a0,0(s3)
    802003b4:	f561                	bnez	a0,8020037c <printf+0x3c>
    802003b6:	aa5d                	j	8020056c <printf+0x22c>
        if (c != '%') { putc(c); continue; }
    802003b8:	00000097          	auipc	ra,0x0
    802003bc:	ed2080e7          	jalr	-302(ra) # 8020028a <putc>
    for (int i = 0; fmt[i]; i++) {
    802003c0:	0019079b          	addiw	a5,s2,1
    802003c4:	893e                	mv	s2,a5
    802003c6:	97ce                	add	a5,a5,s3
    802003c8:	0007c503          	lbu	a0,0(a5)
    802003cc:	16050e63          	beqz	a0,80200548 <printf+0x208>
        if (c != '%') { putc(c); continue; }
    802003d0:	ff4514e3          	bne	a0,s4,802003b8 <printf+0x78>
        c = fmt[++i];
    802003d4:	0019079b          	addiw	a5,s2,1
    802003d8:	893e                	mv	s2,a5
    802003da:	97ce                	add	a5,a5,s3
    802003dc:	0007c483          	lbu	s1,0(a5)
        if (!c) break;
    802003e0:	16048463          	beqz	s1,80200548 <printf+0x208>
        switch (c) {
    802003e4:	13448f63          	beq	s1,s4,80200522 <printf+0x1e2>
    802003e8:	f9d4879b          	addiw	a5,s1,-99
    802003ec:	0ff7f793          	zext.b	a5,a5
    802003f0:	14fae063          	bltu	s5,a5,80200530 <printf+0x1f0>
    802003f4:	f9d4879b          	addiw	a5,s1,-99
    802003f8:	0ff7f713          	zext.b	a4,a5
    802003fc:	12eaea63          	bltu	s5,a4,80200530 <printf+0x1f0>
    80200400:	00271793          	slli	a5,a4,0x2
    80200404:	97da                	add	a5,a5,s6
    80200406:	439c                	lw	a5,0(a5)
    80200408:	97da                	add	a5,a5,s6
    8020040a:	8782                	jr	a5
        case 'd': printint(va_arg(ap, int), 10, 1); break;
    8020040c:	f9843783          	ld	a5,-104(s0)
    80200410:	00878713          	addi	a4,a5,8
    80200414:	f8e43c23          	sd	a4,-104(s0)
    80200418:	4605                	li	a2,1
    8020041a:	45a9                	li	a1,10
    8020041c:	4388                	lw	a0,0(a5)
    8020041e:	00000097          	auipc	ra,0x0
    80200422:	e98080e7          	jalr	-360(ra) # 802002b6 <printint>
    80200426:	bf69                	j	802003c0 <printf+0x80>
        case 'l': printint(va_arg(ap, uint64), 10, 0); break;
    80200428:	f9843783          	ld	a5,-104(s0)
    8020042c:	00878713          	addi	a4,a5,8
    80200430:	f8e43c23          	sd	a4,-104(s0)
    80200434:	4601                	li	a2,0
    80200436:	45a9                	li	a1,10
    80200438:	6388                	ld	a0,0(a5)
    8020043a:	00000097          	auipc	ra,0x0
    8020043e:	e7c080e7          	jalr	-388(ra) # 802002b6 <printint>
    80200442:	bfbd                	j	802003c0 <printf+0x80>
        case 'u': printint(va_arg(ap, uint64), 10, 0); break;
    80200444:	f9843783          	ld	a5,-104(s0)
    80200448:	00878713          	addi	a4,a5,8
    8020044c:	f8e43c23          	sd	a4,-104(s0)
    80200450:	4601                	li	a2,0
    80200452:	45a9                	li	a1,10
    80200454:	6388                	ld	a0,0(a5)
    80200456:	00000097          	auipc	ra,0x0
    8020045a:	e60080e7          	jalr	-416(ra) # 802002b6 <printint>
    8020045e:	b78d                	j	802003c0 <printf+0x80>
        case 'x': printint(va_arg(ap, uint64), 16, 0); break;
    80200460:	f9843783          	ld	a5,-104(s0)
    80200464:	00878713          	addi	a4,a5,8
    80200468:	f8e43c23          	sd	a4,-104(s0)
    8020046c:	4601                	li	a2,0
    8020046e:	45c1                	li	a1,16
    80200470:	6388                	ld	a0,0(a5)
    80200472:	00000097          	auipc	ra,0x0
    80200476:	e44080e7          	jalr	-444(ra) # 802002b6 <printint>
    8020047a:	b799                	j	802003c0 <printf+0x80>
    8020047c:	f062                	sd	s8,32(sp)
    8020047e:	ec66                	sd	s9,24(sp)
        case 'p': printptr(va_arg(ap, uint64)); break;
    80200480:	f9843783          	ld	a5,-104(s0)
    80200484:	00878713          	addi	a4,a5,8
    80200488:	f8e43c23          	sd	a4,-104(s0)
    8020048c:	0007bc03          	ld	s8,0(a5)
    putc('0'); putc('x');
    80200490:	03000513          	li	a0,48
    80200494:	00000097          	auipc	ra,0x0
    80200498:	df6080e7          	jalr	-522(ra) # 8020028a <putc>
    8020049c:	07800513          	li	a0,120
    802004a0:	00000097          	auipc	ra,0x0
    802004a4:	dea080e7          	jalr	-534(ra) # 8020028a <putc>
    802004a8:	44c1                	li	s1,16
        putc(digits[x >> 60]);
    802004aa:	00008c97          	auipc	s9,0x8
    802004ae:	90ec8c93          	addi	s9,s9,-1778 # 80207db8 <digits>
    802004b2:	03cc5793          	srli	a5,s8,0x3c
    802004b6:	97e6                	add	a5,a5,s9
    802004b8:	0007c503          	lbu	a0,0(a5)
    802004bc:	00000097          	auipc	ra,0x0
    802004c0:	dce080e7          	jalr	-562(ra) # 8020028a <putc>
    for (int i = 0; i < 16; i++, x <<= 4)
    802004c4:	0c12                	slli	s8,s8,0x4
    802004c6:	34fd                	addiw	s1,s1,-1
    802004c8:	f4ed                	bnez	s1,802004b2 <printf+0x172>
    802004ca:	7c02                	ld	s8,32(sp)
    802004cc:	6ce2                	ld	s9,24(sp)
    802004ce:	bdcd                	j	802003c0 <printf+0x80>
        case 'c': putc((char)va_arg(ap, int)); break;
    802004d0:	f9843783          	ld	a5,-104(s0)
    802004d4:	00878713          	addi	a4,a5,8
    802004d8:	f8e43c23          	sd	a4,-104(s0)
    802004dc:	0007c503          	lbu	a0,0(a5)
    802004e0:	00000097          	auipc	ra,0x0
    802004e4:	daa080e7          	jalr	-598(ra) # 8020028a <putc>
    802004e8:	bde1                	j	802003c0 <printf+0x80>
        case 's': {
            const char *s = va_arg(ap, const char *);
    802004ea:	f9843783          	ld	a5,-104(s0)
    802004ee:	00878713          	addi	a4,a5,8
    802004f2:	f8e43c23          	sd	a4,-104(s0)
    802004f6:	6384                	ld	s1,0(a5)
            if (!s) s = "(null)";
    802004f8:	cc91                	beqz	s1,80200514 <printf+0x1d4>
            while (*s) putc(*s++);
    802004fa:	0004c503          	lbu	a0,0(s1)
    802004fe:	ec0501e3          	beqz	a0,802003c0 <printf+0x80>
    80200502:	0485                	addi	s1,s1,1
    80200504:	00000097          	auipc	ra,0x0
    80200508:	d86080e7          	jalr	-634(ra) # 8020028a <putc>
    8020050c:	0004c503          	lbu	a0,0(s1)
    80200510:	f96d                	bnez	a0,80200502 <printf+0x1c2>
    80200512:	b57d                	j	802003c0 <printf+0x80>
            if (!s) s = "(null)";
    80200514:	00007497          	auipc	s1,0x7
    80200518:	c8448493          	addi	s1,s1,-892 # 80207198 <etext+0x198>
            while (*s) putc(*s++);
    8020051c:	02800513          	li	a0,40
    80200520:	b7cd                	j	80200502 <printf+0x1c2>
            break;
        }
        case '%': putc('%'); break;
    80200522:	02500513          	li	a0,37
    80200526:	00000097          	auipc	ra,0x0
    8020052a:	d64080e7          	jalr	-668(ra) # 8020028a <putc>
    8020052e:	bd49                	j	802003c0 <printf+0x80>
        default:  putc('%'); putc(c); break;
    80200530:	02500513          	li	a0,37
    80200534:	00000097          	auipc	ra,0x0
    80200538:	d56080e7          	jalr	-682(ra) # 8020028a <putc>
    8020053c:	8526                	mv	a0,s1
    8020053e:	00000097          	auipc	ra,0x0
    80200542:	d4c080e7          	jalr	-692(ra) # 8020028a <putc>
    80200546:	bdad                	j	802003c0 <printf+0x80>
        }
    }
    va_end(ap);
    if (locking) release(&pr_lock);
    80200548:	000b9d63          	bnez	s7,80200562 <printf+0x222>
    8020054c:	64e6                	ld	s1,88(sp)
    8020054e:	6946                	ld	s2,80(sp)
    80200550:	6a06                	ld	s4,64(sp)
    80200552:	7ae2                	ld	s5,56(sp)
    80200554:	7b42                	ld	s6,48(sp)
}
    80200556:	70a6                	ld	ra,104(sp)
    80200558:	7406                	ld	s0,96(sp)
    8020055a:	69a6                	ld	s3,72(sp)
    8020055c:	7ba2                	ld	s7,40(sp)
    8020055e:	614d                	addi	sp,sp,176
    80200560:	8082                	ret
    80200562:	64e6                	ld	s1,88(sp)
    80200564:	6946                	ld	s2,80(sp)
    80200566:	6a06                	ld	s4,64(sp)
    80200568:	7ae2                	ld	s5,56(sp)
    8020056a:	7b42                	ld	s6,48(sp)
    if (locking) release(&pr_lock);
    8020056c:	00029517          	auipc	a0,0x29
    80200570:	a9450513          	addi	a0,a0,-1388 # 80229000 <pr_lock>
    80200574:	00001097          	auipc	ra,0x1
    80200578:	e3c080e7          	jalr	-452(ra) # 802013b0 <release>
}
    8020057c:	bfe9                	j	80200556 <printf+0x216>

000000008020057e <printfinit>:

void printfinit(void) { initlock(&pr_lock, "pr"); pr_locking = 1; }
    8020057e:	1141                	addi	sp,sp,-16
    80200580:	e406                	sd	ra,8(sp)
    80200582:	e022                	sd	s0,0(sp)
    80200584:	0800                	addi	s0,sp,16
    80200586:	00007597          	auipc	a1,0x7
    8020058a:	c1a58593          	addi	a1,a1,-998 # 802071a0 <etext+0x1a0>
    8020058e:	00029517          	auipc	a0,0x29
    80200592:	a7250513          	addi	a0,a0,-1422 # 80229000 <pr_lock>
    80200596:	00001097          	auipc	ra,0x1
    8020059a:	cea080e7          	jalr	-790(ra) # 80201280 <initlock>
    8020059e:	4785                	li	a5,1
    802005a0:	0013f717          	auipc	a4,0x13f
    802005a4:	a6f72423          	sw	a5,-1432(a4) # 8033f008 <pr_locking>
    802005a8:	60a2                	ld	ra,8(sp)
    802005aa:	6402                	ld	s0,0(sp)
    802005ac:	0141                	addi	sp,sp,16
    802005ae:	8082                	ret

00000000802005b0 <panic>:

void panic(const char *s)
{
    802005b0:	1101                	addi	sp,sp,-32
    802005b2:	ec06                	sd	ra,24(sp)
    802005b4:	e822                	sd	s0,16(sp)
    802005b6:	e426                	sd	s1,8(sp)
    802005b8:	1000                	addi	s0,sp,32
    802005ba:	84aa                	mv	s1,a0
    pr_locking = 0;                       /* never deadlock inside a panic */
    802005bc:	0013f797          	auipc	a5,0x13f
    802005c0:	a407a623          	sw	zero,-1460(a5) # 8033f008 <pr_locking>
    printf("\n=== KERNEL PANIC (hart %d) ===\n", hal_hart_id());
    802005c4:	00006097          	auipc	ra,0x6
    802005c8:	ad8080e7          	jalr	-1320(ra) # 8020609c <hal_hart_id>
    802005cc:	85aa                	mv	a1,a0
    802005ce:	00007517          	auipc	a0,0x7
    802005d2:	bda50513          	addi	a0,a0,-1062 # 802071a8 <etext+0x1a8>
    802005d6:	00000097          	auipc	ra,0x0
    802005da:	d6a080e7          	jalr	-662(ra) # 80200340 <printf>
    printf("  %s\n", s);
    802005de:	85a6                	mv	a1,s1
    802005e0:	00007517          	auipc	a0,0x7
    802005e4:	bf050513          	addi	a0,a0,-1040 # 802071d0 <etext+0x1d0>
    802005e8:	00000097          	auipc	ra,0x0
    802005ec:	d58080e7          	jalr	-680(ra) # 80200340 <printf>
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
static inline uint64 r_sie(void){ uint64 x; asm volatile("csrr %0, sie":"=r"(x)); return x; }
static inline void   w_sie(uint64 x){ asm volatile("csrw sie, %0"::"r"(x)); }
static inline void   w_stvec(uint64 x){ asm volatile("csrw stvec, %0"::"r"(x)); }
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
static inline uint64 r_sepc(void){ uint64 x; asm volatile("csrr %0, sepc":"=r"(x)); return x; }
    802005f0:	141025f3          	csrr	a1,sepc
    printf("  sepc   = %p\n", r_sepc());
    802005f4:	00007517          	auipc	a0,0x7
    802005f8:	be450513          	addi	a0,a0,-1052 # 802071d8 <etext+0x1d8>
    802005fc:	00000097          	auipc	ra,0x0
    80200600:	d44080e7          	jalr	-700(ra) # 80200340 <printf>
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
    80200604:	142025f3          	csrr	a1,scause
    printf("  scause = %p\n", r_scause());
    80200608:	00007517          	auipc	a0,0x7
    8020060c:	be050513          	addi	a0,a0,-1056 # 802071e8 <etext+0x1e8>
    80200610:	00000097          	auipc	ra,0x0
    80200614:	d30080e7          	jalr	-720(ra) # 80200340 <printf>
static inline void   w_sepc(uint64 x){ asm volatile("csrw sepc, %0"::"r"(x)); }
static inline uint64 r_stval(void){ uint64 x; asm volatile("csrr %0, stval":"=r"(x)); return x; }
    80200618:	143025f3          	csrr	a1,stval
    printf("  stval  = %p\n", r_stval());
    8020061c:	00007517          	auipc	a0,0x7
    80200620:	bdc50513          	addi	a0,a0,-1060 # 802071f8 <etext+0x1f8>
    80200624:	00000097          	auipc	ra,0x0
    80200628:	d1c080e7          	jalr	-740(ra) # 80200340 <printf>
static inline void   w_sscratch(uint64 x){ asm volatile("csrw sscratch, %0"::"r"(x)); }
static inline uint64 r_satp(void){ uint64 x; asm volatile("csrr %0, satp":"=r"(x)); return x; }
    8020062c:	180025f3          	csrr	a1,satp
    printf("  satp   = %p\n", r_satp());
    80200630:	00007517          	auipc	a0,0x7
    80200634:	bd850513          	addi	a0,a0,-1064 # 80207208 <etext+0x208>
    80200638:	00000097          	auipc	ra,0x0
    8020063c:	d08080e7          	jalr	-760(ra) # 80200340 <printf>
    printf("=============================\n");
    80200640:	00007517          	auipc	a0,0x7
    80200644:	bd850513          	addi	a0,a0,-1064 # 80207218 <etext+0x218>
    80200648:	00000097          	auipc	ra,0x0
    8020064c:	cf8080e7          	jalr	-776(ra) # 80200340 <printf>
    for (;;) asm volatile("wfi");
    80200650:	10500073          	wfi
    80200654:	bff5                	j	80200650 <panic+0xa0>

0000000080200656 <memset>:
#include "types.h"
#include "defs.h"
void *memset(void *dst, int c, usize n){ char *d=dst; while(n--) *d++=(char)c; return dst; }
    80200656:	1141                	addi	sp,sp,-16
    80200658:	e406                	sd	ra,8(sp)
    8020065a:	e022                	sd	s0,0(sp)
    8020065c:	0800                	addi	s0,sp,16
    8020065e:	ca01                	beqz	a2,8020066e <memset+0x18>
    80200660:	962a                	add	a2,a2,a0
    80200662:	87aa                	mv	a5,a0
    80200664:	0785                	addi	a5,a5,1
    80200666:	feb78fa3          	sb	a1,-1(a5)
    8020066a:	fef61de3          	bne	a2,a5,80200664 <memset+0xe>
    8020066e:	60a2                	ld	ra,8(sp)
    80200670:	6402                	ld	s0,0(sp)
    80200672:	0141                	addi	sp,sp,16
    80200674:	8082                	ret

0000000080200676 <memmove>:
void *memmove(void *dst, const void *src, usize n){
    80200676:	1141                	addi	sp,sp,-16
    80200678:	e406                	sd	ra,8(sp)
    8020067a:	e022                	sd	s0,0(sp)
    8020067c:	0800                	addi	s0,sp,16
    char *d=dst; const char *s=src;
    if (d < s) { while(n--) *d++ = *s++; }
    8020067e:	02b57163          	bgeu	a0,a1,802006a0 <memmove+0x2a>
    80200682:	ca19                	beqz	a2,80200698 <memmove+0x22>
    80200684:	962a                	add	a2,a2,a0
    char *d=dst; const char *s=src;
    80200686:	87aa                	mv	a5,a0
    if (d < s) { while(n--) *d++ = *s++; }
    80200688:	0585                	addi	a1,a1,1
    8020068a:	0785                	addi	a5,a5,1
    8020068c:	fff5c703          	lbu	a4,-1(a1)
    80200690:	fee78fa3          	sb	a4,-1(a5)
    80200694:	fef61ae3          	bne	a2,a5,80200688 <memmove+0x12>
    else { d+=n; s+=n; while(n--) *--d = *--s; }
    return dst;
}
    80200698:	60a2                	ld	ra,8(sp)
    8020069a:	6402                	ld	s0,0(sp)
    8020069c:	0141                	addi	sp,sp,16
    8020069e:	8082                	ret
    else { d+=n; s+=n; while(n--) *--d = *--s; }
    802006a0:	00c507b3          	add	a5,a0,a2
    802006a4:	95b2                	add	a1,a1,a2
    802006a6:	da6d                	beqz	a2,80200698 <memmove+0x22>
    802006a8:	15fd                	addi	a1,a1,-1
    802006aa:	17fd                	addi	a5,a5,-1
    802006ac:	0005c703          	lbu	a4,0(a1)
    802006b0:	00e78023          	sb	a4,0(a5)
    802006b4:	fef51ae3          	bne	a0,a5,802006a8 <memmove+0x32>
    802006b8:	b7c5                	j	80200698 <memmove+0x22>

00000000802006ba <memcmp>:
int memcmp(const void *a, const void *b, usize n){
    802006ba:	1141                	addi	sp,sp,-16
    802006bc:	e406                	sd	ra,8(sp)
    802006be:	e022                	sd	s0,0(sp)
    802006c0:	0800                	addi	s0,sp,16
    const uint8 *x=a,*y=b;
    while(n--){ if(*x != *y) return *x - *y; x++; y++; }
    802006c2:	c605                	beqz	a2,802006ea <memcmp+0x30>
    802006c4:	962a                	add	a2,a2,a0
    802006c6:	00054783          	lbu	a5,0(a0)
    802006ca:	0005c703          	lbu	a4,0(a1)
    802006ce:	00e79863          	bne	a5,a4,802006de <memcmp+0x24>
    802006d2:	0505                	addi	a0,a0,1
    802006d4:	0585                	addi	a1,a1,1
    802006d6:	fea618e3          	bne	a2,a0,802006c6 <memcmp+0xc>
    return 0;
    802006da:	4501                	li	a0,0
    802006dc:	a019                	j	802006e2 <memcmp+0x28>
    while(n--){ if(*x != *y) return *x - *y; x++; y++; }
    802006de:	40e7853b          	subw	a0,a5,a4
}
    802006e2:	60a2                	ld	ra,8(sp)
    802006e4:	6402                	ld	s0,0(sp)
    802006e6:	0141                	addi	sp,sp,16
    802006e8:	8082                	ret
    return 0;
    802006ea:	4501                	li	a0,0
    802006ec:	bfdd                	j	802006e2 <memcmp+0x28>

00000000802006ee <strncmp>:
int strncmp(const char *a, const char *b, usize n){
    802006ee:	1141                	addi	sp,sp,-16
    802006f0:	e406                	sd	ra,8(sp)
    802006f2:	e022                	sd	s0,0(sp)
    802006f4:	0800                	addi	s0,sp,16
    while(n > 0 && *a && *a == *b){ a++; b++; n--; }
    802006f6:	ce11                	beqz	a2,80200712 <strncmp+0x24>
    802006f8:	00054783          	lbu	a5,0(a0)
    802006fc:	cf89                	beqz	a5,80200716 <strncmp+0x28>
    802006fe:	0005c703          	lbu	a4,0(a1)
    80200702:	00f71a63          	bne	a4,a5,80200716 <strncmp+0x28>
    80200706:	0505                	addi	a0,a0,1
    80200708:	0585                	addi	a1,a1,1
    8020070a:	167d                	addi	a2,a2,-1
    8020070c:	f675                	bnez	a2,802006f8 <strncmp+0xa>
    if(n == 0) return 0;
    8020070e:	4501                	li	a0,0
    80200710:	a801                	j	80200720 <strncmp+0x32>
    80200712:	4501                	li	a0,0
    80200714:	a031                	j	80200720 <strncmp+0x32>
    return (uint8)*a - (uint8)*b;
    80200716:	00054503          	lbu	a0,0(a0)
    8020071a:	0005c783          	lbu	a5,0(a1)
    8020071e:	9d1d                	subw	a0,a0,a5
}
    80200720:	60a2                	ld	ra,8(sp)
    80200722:	6402                	ld	s0,0(sp)
    80200724:	0141                	addi	sp,sp,16
    80200726:	8082                	ret

0000000080200728 <strncpy>:
char *strncpy(char *d, const char *s, int n){
    80200728:	1141                	addi	sp,sp,-16
    8020072a:	e406                	sd	ra,8(sp)
    8020072c:	e022                	sd	s0,0(sp)
    8020072e:	0800                	addi	s0,sp,16
    char *r=d;
    while(n-- > 0 && (*d++ = *s++) != 0) ;
    80200730:	87aa                	mv	a5,a0
    80200732:	86b2                	mv	a3,a2
    80200734:	367d                	addiw	a2,a2,-1
    80200736:	02d05563          	blez	a3,80200760 <strncpy+0x38>
    8020073a:	0785                	addi	a5,a5,1
    8020073c:	0005c703          	lbu	a4,0(a1)
    80200740:	fee78fa3          	sb	a4,-1(a5)
    80200744:	0585                	addi	a1,a1,1
    80200746:	f775                	bnez	a4,80200732 <strncpy+0xa>
    while(n-- > 0) *d++ = 0;
    80200748:	873e                	mv	a4,a5
    8020074a:	00c05b63          	blez	a2,80200760 <strncpy+0x38>
    8020074e:	9fb5                	addw	a5,a5,a3
    80200750:	37fd                	addiw	a5,a5,-1
    80200752:	0705                	addi	a4,a4,1
    80200754:	fe070fa3          	sb	zero,-1(a4)
    80200758:	40e786bb          	subw	a3,a5,a4
    8020075c:	fed04be3          	bgtz	a3,80200752 <strncpy+0x2a>
    return r;
}
    80200760:	60a2                	ld	ra,8(sp)
    80200762:	6402                	ld	s0,0(sp)
    80200764:	0141                	addi	sp,sp,16
    80200766:	8082                	ret

0000000080200768 <strlen>:
int strlen(const char *s){ int n=0; while(s[n]) n++; return n; }
    80200768:	1141                	addi	sp,sp,-16
    8020076a:	e406                	sd	ra,8(sp)
    8020076c:	e022                	sd	s0,0(sp)
    8020076e:	0800                	addi	s0,sp,16
    80200770:	00054783          	lbu	a5,0(a0)
    80200774:	cf99                	beqz	a5,80200792 <strlen+0x2a>
    80200776:	0505                	addi	a0,a0,1
    80200778:	87aa                	mv	a5,a0
    8020077a:	86be                	mv	a3,a5
    8020077c:	0785                	addi	a5,a5,1
    8020077e:	fff7c703          	lbu	a4,-1(a5)
    80200782:	ff65                	bnez	a4,8020077a <strlen+0x12>
    80200784:	40a6853b          	subw	a0,a3,a0
    80200788:	2505                	addiw	a0,a0,1
    8020078a:	60a2                	ld	ra,8(sp)
    8020078c:	6402                	ld	s0,0(sp)
    8020078e:	0141                	addi	sp,sp,16
    80200790:	8082                	ret
    80200792:	4501                	li	a0,0
    80200794:	bfdd                	j	8020078a <strlen+0x22>

0000000080200796 <sbi_putchar>:




void sbi_putchar(int c)
{
    80200796:	1141                	addi	sp,sp,-16
    80200798:	e406                	sd	ra,8(sp)
    8020079a:	e022                	sd	s0,0(sp)
    8020079c:	0800                	addi	s0,sp,16
    8020079e:	87aa                	mv	a5,a0
    unsigned char ch = (unsigned char)c;
    /* DBCN console_write_byte = EID 0x4442434E, FID 2 */
    struct sbiret r = sbi_call(0x4442434E, 2, ch, 0, 0);
    802007a0:	0ff57513          	zext.b	a0,a0
    register long r_a1 asm("a1") = a1;
    802007a4:	4581                	li	a1,0
    register long r_a2 asm("a2") = a2;
    802007a6:	4601                	li	a2,0
    register long r_a6 asm("a6") = fid;
    802007a8:	4809                	li	a6,2
    register long r_a7 asm("a7") = eid;
    802007aa:	444248b7          	lui	a7,0x44424
    802007ae:	34e88893          	addi	a7,a7,846 # 4442434e <_entry-0x3bddbcb2>
    asm volatile ("ecall"
    802007b2:	00000073          	ecall
    if (r.error != 0)
    802007b6:	e509                	bnez	a0,802007c0 <sbi_putchar+0x2a>
        sbi_call(0x01, 0, c, 0, 0);        /* legacy putchar */
}
    802007b8:	60a2                	ld	ra,8(sp)
    802007ba:	6402                	ld	s0,0(sp)
    802007bc:	0141                	addi	sp,sp,16
    802007be:	8082                	ret
        sbi_call(0x01, 0, c, 0, 0);        /* legacy putchar */
    802007c0:	853e                	mv	a0,a5
    register long r_a1 asm("a1") = a1;
    802007c2:	4581                	li	a1,0
    register long r_a6 asm("a6") = fid;
    802007c4:	4801                	li	a6,0
    register long r_a7 asm("a7") = eid;
    802007c6:	4885                	li	a7,1
    asm volatile ("ecall"
    802007c8:	00000073          	ecall
}
    802007cc:	b7f5                	j	802007b8 <sbi_putchar+0x22>

00000000802007ce <sbi_set_timer>:

/* TIME extension: set the next timer interrupt (absolute time). */
void sbi_set_timer(uint64 stime) { sbi_call(0x54494D45, 0, stime, 0, 0); }
    802007ce:	1141                	addi	sp,sp,-16
    802007d0:	e406                	sd	ra,8(sp)
    802007d2:	e022                	sd	s0,0(sp)
    802007d4:	0800                	addi	s0,sp,16
    register long r_a1 asm("a1") = a1;
    802007d6:	4581                	li	a1,0
    register long r_a2 asm("a2") = a2;
    802007d8:	4601                	li	a2,0
    register long r_a6 asm("a6") = fid;
    802007da:	4801                	li	a6,0
    register long r_a7 asm("a7") = eid;
    802007dc:	544958b7          	lui	a7,0x54495
    802007e0:	d4588893          	addi	a7,a7,-699 # 54494d45 <_entry-0x2bd6b2bb>
    asm volatile ("ecall"
    802007e4:	00000073          	ecall
void sbi_set_timer(uint64 stime) { sbi_call(0x54494D45, 0, stime, 0, 0); }
    802007e8:	60a2                	ld	ra,8(sp)
    802007ea:	6402                	ld	s0,0(sp)
    802007ec:	0141                	addi	sp,sp,16
    802007ee:	8082                	ret

00000000802007f0 <sbi_hart_start>:

/* Implementation note. */
long sbi_hart_start(uint64 hartid, uint64 addr, uint64 opaque)
{
    802007f0:	1141                	addi	sp,sp,-16
    802007f2:	e406                	sd	ra,8(sp)
    802007f4:	e022                	sd	s0,0(sp)
    802007f6:	0800                	addi	s0,sp,16
    register long r_a6 asm("a6") = fid;
    802007f8:	4801                	li	a6,0
    register long r_a7 asm("a7") = eid;
    802007fa:	004858b7          	lui	a7,0x485
    802007fe:	34d88893          	addi	a7,a7,845 # 48534d <_entry-0x7fd7acb3>
    asm volatile ("ecall"
    80200802:	00000073          	ecall
    return sbi_call(0x48534D, 0, hartid, addr, opaque).error;
}
    80200806:	60a2                	ld	ra,8(sp)
    80200808:	6402                	ld	s0,0(sp)
    8020080a:	0141                	addi	sp,sp,16
    8020080c:	8082                	ret

000000008020080e <be32>:
    uint32 off_mem_rsvmap, version, last_comp_version;
    uint32 boot_cpuid_phys, size_dt_strings, size_dt_struct;
};

/* The FDT is big-endian; RISC-V is little-endian. Swap on every read. */
static uint32 be32(uint32 x) {
    8020080e:	1141                	addi	sp,sp,-16
    80200810:	e406                	sd	ra,8(sp)
    80200812:	e022                	sd	s0,0(sp)
    80200814:	0800                	addi	s0,sp,16
    return ((x & 0xFF) << 24) | ((x & 0xFF00) << 8) |
    80200816:	0185179b          	slliw	a5,a0,0x18
           ((x >> 8) & 0xFF00) | ((x >> 24) & 0xFF);
    8020081a:	0185571b          	srliw	a4,a0,0x18
    8020081e:	8fd9                	or	a5,a5,a4
    return ((x & 0xFF) << 24) | ((x & 0xFF00) << 8) |
    80200820:	0085171b          	slliw	a4,a0,0x8
    80200824:	00ff06b7          	lui	a3,0xff0
    80200828:	8f75                	and	a4,a4,a3
           ((x >> 8) & 0xFF00) | ((x >> 24) & 0xFF);
    8020082a:	8fd9                	or	a5,a5,a4
    8020082c:	0085551b          	srliw	a0,a0,0x8
    80200830:	6741                	lui	a4,0x10
    80200832:	f0070713          	addi	a4,a4,-256 # ff00 <_entry-0x801f0100>
    80200836:	8d79                	and	a0,a0,a4
}
    80200838:	8d5d                	or	a0,a0,a5
    8020083a:	60a2                	ld	ra,8(sp)
    8020083c:	6402                	ld	s0,0(sp)
    8020083e:	0141                	addi	sp,sp,16
    80200840:	8082                	ret

0000000080200842 <streq>:
#define MAXDEPTH 16

struct fdt_info fdt;                 /* what we discovered about this board */
static const char *strings;          /* strings block base */

static int streq(const char *a, const char *b) {
    80200842:	1141                	addi	sp,sp,-16
    80200844:	e406                	sd	ra,8(sp)
    80200846:	e022                	sd	s0,0(sp)
    80200848:	0800                	addi	s0,sp,16
    while (*a && *a == *b) { a++; b++; }
    8020084a:	00054783          	lbu	a5,0(a0)
    8020084e:	cb91                	beqz	a5,80200862 <streq+0x20>
    80200850:	0005c703          	lbu	a4,0(a1)
    80200854:	00f71763          	bne	a4,a5,80200862 <streq+0x20>
    80200858:	0505                	addi	a0,a0,1
    8020085a:	0585                	addi	a1,a1,1
    8020085c:	00054783          	lbu	a5,0(a0)
    80200860:	fbe5                	bnez	a5,80200850 <streq+0xe>
    return *a == *b;
    80200862:	0005c503          	lbu	a0,0(a1)
    80200866:	8d1d                	sub	a0,a0,a5
}
    80200868:	00153513          	seqz	a0,a0
    8020086c:	60a2                	ld	ra,8(sp)
    8020086e:	6402                	ld	s0,0(sp)
    80200870:	0141                	addi	sp,sp,16
    80200872:	8082                	ret

0000000080200874 <strlist_has>:
/* does `list` (a NUL-separated string list of length len) contain `want`? */
static int strlist_has(const char *list, int len, const char *want) {
    int i = 0;
    while (i < len) {
    80200874:	04b05f63          	blez	a1,802008d2 <strlist_has+0x5e>
static int strlist_has(const char *list, int len, const char *want) {
    80200878:	7139                	addi	sp,sp,-64
    8020087a:	fc06                	sd	ra,56(sp)
    8020087c:	f822                	sd	s0,48(sp)
    8020087e:	f426                	sd	s1,40(sp)
    80200880:	f04a                	sd	s2,32(sp)
    80200882:	ec4e                	sd	s3,24(sp)
    80200884:	e852                	sd	s4,16(sp)
    80200886:	e456                	sd	s5,8(sp)
    80200888:	0080                	addi	s0,sp,64
    8020088a:	8a2a                	mv	s4,a0
    8020088c:	89ae                	mv	s3,a1
    8020088e:	8ab2                	mv	s5,a2
    int i = 0;
    80200890:	4481                	li	s1,0
    80200892:	a021                	j	8020089a <strlist_has+0x26>
        if (streq(&list[i], want)) return 1;
        while (i < len && list[i]) i++;
        i++;
    80200894:	2485                	addiw	s1,s1,1
    while (i < len) {
    80200896:	0334d563          	bge	s1,s3,802008c0 <strlist_has+0x4c>
        if (streq(&list[i], want)) return 1;
    8020089a:	009a0933          	add	s2,s4,s1
    8020089e:	85d6                	mv	a1,s5
    802008a0:	854a                	mv	a0,s2
    802008a2:	00000097          	auipc	ra,0x0
    802008a6:	fa0080e7          	jalr	-96(ra) # 80200842 <streq>
    802008aa:	e515                	bnez	a0,802008d6 <strlist_has+0x62>
        while (i < len && list[i]) i++;
    802008ac:	ff34d4e3          	bge	s1,s3,80200894 <strlist_has+0x20>
    802008b0:	87ca                	mv	a5,s2
    802008b2:	0007c703          	lbu	a4,0(a5)
    802008b6:	df79                	beqz	a4,80200894 <strlist_has+0x20>
    802008b8:	2485                	addiw	s1,s1,1
    802008ba:	0785                	addi	a5,a5,1
    802008bc:	fe999be3          	bne	s3,s1,802008b2 <strlist_has+0x3e>
    }
    return 0;
}
    802008c0:	70e2                	ld	ra,56(sp)
    802008c2:	7442                	ld	s0,48(sp)
    802008c4:	74a2                	ld	s1,40(sp)
    802008c6:	7902                	ld	s2,32(sp)
    802008c8:	69e2                	ld	s3,24(sp)
    802008ca:	6a42                	ld	s4,16(sp)
    802008cc:	6aa2                	ld	s5,8(sp)
    802008ce:	6121                	addi	sp,sp,64
    802008d0:	8082                	ret
    return 0;
    802008d2:	4501                	li	a0,0
}
    802008d4:	8082                	ret
        if (streq(&list[i], want)) return 1;
    802008d6:	4505                	li	a0,1
    802008d8:	b7e5                	j	802008c0 <strlist_has+0x4c>

00000000802008da <fdt_init>:




void fdt_init(uint64 fdt_pa)
{
    802008da:	712d                	addi	sp,sp,-288
    802008dc:	ee06                	sd	ra,280(sp)
    802008de:	ea22                	sd	s0,272(sp)
    802008e0:	fdce                	sd	s3,248(sp)
    802008e2:	1200                	addi	s0,sp,288
    802008e4:	89aa                	mv	s3,a0
    struct fdt_header *h = (struct fdt_header *)fdt_pa;

    if (be32(h->magic) != FDT_MAGIC)
    802008e6:	4108                	lw	a0,0(a0)
    802008e8:	00000097          	auipc	ra,0x0
    802008ec:	f26080e7          	jalr	-218(ra) # 8020080e <be32>
    802008f0:	d00e07b7          	lui	a5,0xd00e0
    802008f4:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <uart+0xffffffff4fda0ebd>
    802008f8:	0cf51163          	bne	a0,a5,802009ba <fdt_init+0xe0>
    802008fc:	e626                	sd	s1,264(sp)
    802008fe:	e24a                	sd	s2,256(sp)
    80200900:	f9d2                	sd	s4,240(sp)
    80200902:	f5d6                	sd	s5,232(sp)
    80200904:	f1da                	sd	s6,224(sp)
    80200906:	edde                	sd	s7,216(sp)
    80200908:	e9e2                	sd	s8,208(sp)
    8020090a:	e1ea                	sd	s10,192(sp)
        panic("fdt: bad magic - is a1 really the device tree?");

    strings = (const char *)(fdt_pa + be32(h->off_dt_strings));
    8020090c:	00c9a503          	lw	a0,12(s3)
    80200910:	00000097          	auipc	ra,0x0
    80200914:	efe080e7          	jalr	-258(ra) # 8020080e <be32>
    80200918:	02051b13          	slli	s6,a0,0x20
    8020091c:	020b5b13          	srli	s6,s6,0x20
    80200920:	9b4e                	add	s6,s6,s3
    const uint32 *p = (const uint32 *)(fdt_pa + be32(h->off_dt_struct));
    80200922:	0089a503          	lw	a0,8(s3)
    80200926:	00000097          	auipc	ra,0x0
    8020092a:	ee8080e7          	jalr	-280(ra) # 8020080e <be32>
    8020092e:	02051493          	slli	s1,a0,0x20
    80200932:	9081                	srli	s1,s1,0x20
    80200934:	94ce                	add	s1,s1,s3

    fdt.blob = fdt_pa;
    80200936:	00028917          	auipc	s2,0x28
    8020093a:	6e290913          	addi	s2,s2,1762 # 80229018 <fdt>
    8020093e:	01393023          	sd	s3,0(s2)
    fdt.blob_size = be32(h->totalsize);
    80200942:	0049a503          	lw	a0,4(s3)
    80200946:	00000097          	auipc	ra,0x0
    8020094a:	ec8080e7          	jalr	-312(ra) # 8020080e <be32>
    8020094e:	1502                	slli	a0,a0,0x20
    80200950:	9101                	srli	a0,a0,0x20
    80200952:	00a93423          	sd	a0,8(s2)
    fdt.ncpu = 0;
    80200956:	0a092023          	sw	zero,160(s2)
    fdt.uart_base = 0; fdt.plic_base = 0; fdt.uart_irq = 0;
    8020095a:	00093823          	sd	zero,16(s2)
    8020095e:	00093c23          	sd	zero,24(s2)
    80200962:	02092023          	sw	zero,32(s2)
    fdt.nvirtio = 0;
    80200966:	08092423          	sw	zero,136(s2)
    fdt.mem_base = 0;  fdt.mem_size = 0;
    8020096a:	08093823          	sd	zero,144(s2)
    8020096e:	08093c23          	sd	zero,152(s2)

    /* #address-cells / #size-cells, one slot per depth. Defaults per spec. */
    int ac[MAXDEPTH], sc[MAXDEPTH];
    ac[0] = 2; sc[0] = 2;
    80200972:	4789                	li	a5,2
    80200974:	f4f42823          	sw	a5,-176(s0)
    80200978:	f0f42823          	sw	a5,-240(s0)

    /* properties buffered for the node we are currently inside */
    int    kind = PEND_NONE;
    int    have_reg = 0;
    uint64 reg_base = 0, reg_size = 0;
    int    have_irq = 0, irq = 0;
    8020097c:	ee043423          	sd	zero,-280(s0)
    80200980:	ee043823          	sd	zero,-272(s0)
    uint64 reg_base = 0, reg_size = 0;
    80200984:	f0043023          	sd	zero,-256(s0)
    80200988:	f0043423          	sd	zero,-248(s0)
    int    have_reg = 0;
    8020098c:	4d01                	li	s10,0
    int    kind = PEND_NONE;
    8020098e:	4c01                	li	s8,0
    int cpus_depth = -1;
    80200990:	5bfd                	li	s7,-1
    int depth = 0;
    80200992:	4981                	li	s3,0
    80200994:	4aa5                	li	s5,9
    80200996:	00007917          	auipc	s2,0x7
    8020099a:	43690913          	addi	s2,s2,1078 # 80207dcc <digits+0x14>

    for (;;) {
        uint32 tok = be32(*p++);
    8020099e:	00448a13          	addi	s4,s1,4
    802009a2:	4088                	lw	a0,0(s1)
    802009a4:	00000097          	auipc	ra,0x0
    802009a8:	e6a080e7          	jalr	-406(ra) # 8020080e <be32>

        if (tok == FDT_END) break;
    802009ac:	4eaae663          	bltu	s5,a0,80200e98 <fdt_init+0x5be>
    802009b0:	050a                	slli	a0,a0,0x2
    802009b2:	954a                	add	a0,a0,s2
    802009b4:	411c                	lw	a5,0(a0)
    802009b6:	97ca                	add	a5,a5,s2
    802009b8:	8782                	jr	a5
    802009ba:	e626                	sd	s1,264(sp)
    802009bc:	e24a                	sd	s2,256(sp)
    802009be:	f9d2                	sd	s4,240(sp)
    802009c0:	f5d6                	sd	s5,232(sp)
    802009c2:	f1da                	sd	s6,224(sp)
    802009c4:	edde                	sd	s7,216(sp)
    802009c6:	e9e2                	sd	s8,208(sp)
    802009c8:	e5e6                	sd	s9,200(sp)
    802009ca:	e1ea                	sd	s10,192(sp)
    802009cc:	fd6e                	sd	s11,184(sp)
        panic("fdt: bad magic - is a1 really the device tree?");
    802009ce:	00007517          	auipc	a0,0x7
    802009d2:	87250513          	addi	a0,a0,-1934 # 80207240 <etext+0x240>
    802009d6:	00000097          	auipc	ra,0x0
    802009da:	bda080e7          	jalr	-1062(ra) # 802005b0 <panic>
        uint32 tok = be32(*p++);
    802009de:	84d2                	mv	s1,s4
    802009e0:	bf7d                	j	8020099e <fdt_init+0xc4>
        if (tok == FDT_BEGIN_NODE) {
            const char *name = (const char *)p;
            int len = 0; while (name[len]) len++;
            p += (len + 4) / 4;                 /* NUL-terminated, 4-byte padded */

            depth++;
    802009e2:	89e2                	mv	s3,s8
            ac[depth] = ac[depth - 1];          /* inherit until told otherwise */
            sc[depth] = sc[depth - 1];

            /* start a fresh property buffer for this node */
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
            have_irq = 0; irq = 0;
    802009e4:	ee043423          	sd	zero,-280(s0)
    802009e8:	ee043823          	sd	zero,-272(s0)
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
    802009ec:	f0043023          	sd	zero,-256(s0)
    802009f0:	f0043423          	sd	zero,-248(s0)
    802009f4:	4d01                	li	s10,0
    802009f6:	4c01                	li	s8,0
    802009f8:	b75d                	j	8020099e <fdt_init+0xc4>
        if (tok == FDT_PROP) {
            uint32 len     = be32(*p++);
            uint32 nameoff = be32(*p++);
            const char *pname = &strings[nameoff];
            const uint32 *val = p;
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    802009fa:	ef843483          	ld	s1,-264(s0)
                    kind = PEND_UART;
                else if (strlist_has(c, len, "riscv,plic0") ||
                         strlist_has(c, len, "sifive,plic-1.0.0"))
                    kind = PEND_PLIC;
                else if (strlist_has(c, len, "virtio,mmio"))
                    kind = PEND_VIRTIO;
    802009fe:	4c0d                	li	s8,3
    80200a00:	6cae                	ld	s9,200(sp)
    80200a02:	7dea                	ld	s11,184(sp)
    80200a04:	bf69                	j	8020099e <fdt_init+0xc4>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200a06:	ef843483          	ld	s1,-264(s0)
            } else if (streq(pname, "device_type")) {
                if (strlist_has((const char *)val, len, "memory"))
                    kind = PEND_MEM;
    80200a0a:	4c11                	li	s8,4
    80200a0c:	6cae                	ld	s9,200(sp)
    80200a0e:	7dea                	ld	s11,184(sp)
    80200a10:	b779                	j	8020099e <fdt_init+0xc4>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200a12:	ef843483          	ld	s1,-264(s0)
    80200a16:	6cae                	ld	s9,200(sp)
    80200a18:	7dea                	ld	s11,184(sp)
    80200a1a:	b751                	j	8020099e <fdt_init+0xc4>
    80200a1c:	ef843483          	ld	s1,-264(s0)
    80200a20:	6cae                	ld	s9,200(sp)
    80200a22:	7dea                	ld	s11,184(sp)
    80200a24:	bfad                	j	8020099e <fdt_init+0xc4>
            int len = 0; while (name[len]) len++;
    80200a26:	0044c783          	lbu	a5,4(s1)
    80200a2a:	c7c9                	beqz	a5,80200ab4 <fdt_init+0x1da>
    80200a2c:	0495                	addi	s1,s1,5
    80200a2e:	87a6                	mv	a5,s1
    80200a30:	86be                	mv	a3,a5
    80200a32:	0785                	addi	a5,a5,1
    80200a34:	fff7c703          	lbu	a4,-1(a5)
    80200a38:	ff65                	bnez	a4,80200a30 <fdt_init+0x156>
    80200a3a:	9e85                	subw	a3,a3,s1
    80200a3c:	2685                	addiw	a3,a3,1 # ff0001 <_entry-0x7f20ffff>
            p += (len + 4) / 4;                 /* NUL-terminated, 4-byte padded */
    80200a3e:	2691                	addiw	a3,a3,4
    80200a40:	41f6d49b          	sraiw	s1,a3,0x1f
    80200a44:	01e4d49b          	srliw	s1,s1,0x1e
    80200a48:	9cb5                	addw	s1,s1,a3
    80200a4a:	4024d49b          	sraiw	s1,s1,0x2
    80200a4e:	048a                	slli	s1,s1,0x2
    80200a50:	94d2                	add	s1,s1,s4
            depth++;
    80200a52:	00198c1b          	addiw	s8,s3,1
            if (depth >= MAXDEPTH) panic("fdt: tree too deep");
    80200a56:	47bd                	li	a5,15
    80200a58:	0787c063          	blt	a5,s8,80200ab8 <fdt_init+0x1de>
            ac[depth] = ac[depth - 1];          /* inherit until told otherwise */
    80200a5c:	f5040693          	addi	a3,s0,-176
    80200a60:	00299713          	slli	a4,s3,0x2
    80200a64:	00d707b3          	add	a5,a4,a3
    80200a68:	4390                	lw	a2,0(a5)
    80200a6a:	002c1793          	slli	a5,s8,0x2
    80200a6e:	96be                	add	a3,a3,a5
    80200a70:	c290                	sw	a2,0(a3)
            sc[depth] = sc[depth - 1];
    80200a72:	f1040693          	addi	a3,s0,-240
    80200a76:	9736                	add	a4,a4,a3
    80200a78:	4318                	lw	a4,0(a4)
    80200a7a:	97b6                	add	a5,a5,a3
    80200a7c:	c398                	sw	a4,0(a5)
            if (streq(name, "cpus")) cpus_depth = depth;
    80200a7e:	00007597          	auipc	a1,0x7
    80200a82:	80a58593          	addi	a1,a1,-2038 # 80207288 <etext+0x288>
    80200a86:	8552                	mv	a0,s4
    80200a88:	00000097          	auipc	ra,0x0
    80200a8c:	dba080e7          	jalr	-582(ra) # 80200842 <streq>
    80200a90:	c111                	beqz	a0,80200a94 <fdt_init+0x1ba>
    80200a92:	8be2                	mv	s7,s8
            if (cpus_depth > 0 && depth == cpus_depth + 1 && startswith(name, "cpu@"))
    80200a94:	f57057e3          	blez	s7,802009e2 <fdt_init+0x108>
    80200a98:	03798a63          	beq	s3,s7,80200acc <fdt_init+0x1f2>
            depth++;
    80200a9c:	89e2                	mv	s3,s8
            have_irq = 0; irq = 0;
    80200a9e:	ee043423          	sd	zero,-280(s0)
    80200aa2:	ee043823          	sd	zero,-272(s0)
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
    80200aa6:	f0043023          	sd	zero,-256(s0)
    80200aaa:	f0043423          	sd	zero,-248(s0)
    80200aae:	4d01                	li	s10,0
    80200ab0:	4c01                	li	s8,0
    80200ab2:	b5f5                	j	8020099e <fdt_init+0xc4>
            int len = 0; while (name[len]) len++;
    80200ab4:	4681                	li	a3,0
    80200ab6:	b761                	j	80200a3e <fdt_init+0x164>
    80200ab8:	e5e6                	sd	s9,200(sp)
    80200aba:	fd6e                	sd	s11,184(sp)
            if (depth >= MAXDEPTH) panic("fdt: tree too deep");
    80200abc:	00006517          	auipc	a0,0x6
    80200ac0:	7b450513          	addi	a0,a0,1972 # 80207270 <etext+0x270>
    80200ac4:	00000097          	auipc	ra,0x0
    80200ac8:	aec080e7          	jalr	-1300(ra) # 802005b0 <panic>
    80200acc:	00006797          	auipc	a5,0x6
    80200ad0:	76c78793          	addi	a5,a5,1900 # 80207238 <etext+0x238>
    while (*pre) { if (*s++ != *pre++) return 0; }
    80200ad4:	0007c703          	lbu	a4,0(a5)
    80200ad8:	44070863          	beqz	a4,80200f28 <fdt_init+0x64e>
    80200adc:	0a05                	addi	s4,s4,1
    80200ade:	0785                	addi	a5,a5,1
    80200ae0:	fffa4683          	lbu	a3,-1(s4)
    80200ae4:	fee688e3          	beq	a3,a4,80200ad4 <fdt_init+0x1fa>
            depth++;
    80200ae8:	89e2                	mv	s3,s8
            have_irq = 0; irq = 0;
    80200aea:	ee043423          	sd	zero,-280(s0)
    80200aee:	ee043823          	sd	zero,-272(s0)
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
    80200af2:	f0043023          	sd	zero,-256(s0)
    80200af6:	f0043423          	sd	zero,-248(s0)
    80200afa:	4d01                	li	s10,0
    80200afc:	4c01                	li	s8,0
    80200afe:	b545                	j	8020099e <fdt_init+0xc4>
            if (have_reg && kind != PEND_NONE) {
    80200b00:	040d0863          	beqz	s10,80200b50 <fdt_init+0x276>
    80200b04:	040c0663          	beqz	s8,80200b50 <fdt_init+0x276>
                switch (kind) {
    80200b08:	478d                	li	a5,3
    80200b0a:	06fc0f63          	beq	s8,a5,80200b88 <fdt_init+0x2ae>
    80200b0e:	0387c463          	blt	a5,s8,80200b36 <fdt_init+0x25c>
    80200b12:	4785                	li	a5,1
    80200b14:	04fc0563          	beq	s8,a5,80200b5e <fdt_init+0x284>
    80200b18:	4789                	li	a5,2
    80200b1a:	02fc1b63          	bne	s8,a5,80200b50 <fdt_init+0x276>
                case PEND_PLIC:   if (!fdt.plic_base) fdt.plic_base = reg_base; break;
    80200b1e:	00028797          	auipc	a5,0x28
    80200b22:	5127b783          	ld	a5,1298(a5) # 80229030 <fdt+0x18>
    80200b26:	e78d                	bnez	a5,80200b50 <fdt_init+0x276>
    80200b28:	f0843703          	ld	a4,-248(s0)
    80200b2c:	00028797          	auipc	a5,0x28
    80200b30:	50e7b223          	sd	a4,1284(a5) # 80229030 <fdt+0x18>
    80200b34:	a831                	j	80200b50 <fdt_init+0x276>
                switch (kind) {
    80200b36:	4791                	li	a5,4
    80200b38:	00fc1c63          	bne	s8,a5,80200b50 <fdt_init+0x276>
                case PEND_MEM:    fdt.mem_base = reg_base; fdt.mem_size = reg_size; break;
    80200b3c:	00028797          	auipc	a5,0x28
    80200b40:	4dc78793          	addi	a5,a5,1244 # 80229018 <fdt>
    80200b44:	f0843703          	ld	a4,-248(s0)
    80200b48:	ebd8                	sd	a4,144(a5)
    80200b4a:	f0043703          	ld	a4,-256(s0)
    80200b4e:	efd8                	sd	a4,152(a5)
            if (depth == cpus_depth) cpus_depth = -1;
    80200b50:	09798163          	beq	s3,s7,80200bd2 <fdt_init+0x2f8>
            depth--;
    80200b54:	39fd                	addiw	s3,s3,-1
        uint32 tok = be32(*p++);
    80200b56:	84d2                	mv	s1,s4
            kind = PEND_NONE; have_reg = 0;
    80200b58:	4d01                	li	s10,0
    80200b5a:	4c01                	li	s8,0
            continue;
    80200b5c:	b589                	j	8020099e <fdt_init+0xc4>
                    if (!fdt.uart_base) {
    80200b5e:	00028797          	auipc	a5,0x28
    80200b62:	4ca7b783          	ld	a5,1226(a5) # 80229028 <fdt+0x10>
    80200b66:	f7ed                	bnez	a5,80200b50 <fdt_init+0x276>
                        fdt.uart_base = reg_base;
    80200b68:	f0843703          	ld	a4,-248(s0)
    80200b6c:	00028797          	auipc	a5,0x28
    80200b70:	4ae7be23          	sd	a4,1212(a5) # 80229028 <fdt+0x10>
                        if (have_irq) fdt.uart_irq = irq;
    80200b74:	ef043783          	ld	a5,-272(s0)
    80200b78:	dfe1                	beqz	a5,80200b50 <fdt_init+0x276>
    80200b7a:	ee843703          	ld	a4,-280(s0)
    80200b7e:	00028797          	auipc	a5,0x28
    80200b82:	4ae7ad23          	sw	a4,1210(a5) # 80229038 <fdt+0x20>
    80200b86:	b7e9                	j	80200b50 <fdt_init+0x276>
                    if (fdt.nvirtio < FDT_MAX_VIRTIO) {
    80200b88:	00028797          	auipc	a5,0x28
    80200b8c:	5187a783          	lw	a5,1304(a5) # 802290a0 <fdt+0x88>
    80200b90:	471d                	li	a4,7
    80200b92:	faf74fe3          	blt	a4,a5,80200b50 <fdt_init+0x276>
                        fdt.virtio_base[fdt.nvirtio] = reg_base;
    80200b96:	00478693          	addi	a3,a5,4
    80200b9a:	068e                	slli	a3,a3,0x3
    80200b9c:	00028717          	auipc	a4,0x28
    80200ba0:	47c70713          	addi	a4,a4,1148 # 80229018 <fdt>
    80200ba4:	9736                	add	a4,a4,a3
    80200ba6:	f0843683          	ld	a3,-248(s0)
    80200baa:	e714                	sd	a3,8(a4)
                        fdt.virtio_irq[fdt.nvirtio]  = have_irq ? irq : 0;
    80200bac:	ef043703          	ld	a4,-272(s0)
    80200bb0:	863a                	mv	a2,a4
    80200bb2:	c319                	beqz	a4,80200bb8 <fdt_init+0x2de>
    80200bb4:	ee843603          	ld	a2,-280(s0)
    80200bb8:	00028697          	auipc	a3,0x28
    80200bbc:	46068693          	addi	a3,a3,1120 # 80229018 <fdt>
    80200bc0:	01878713          	addi	a4,a5,24
    80200bc4:	070a                	slli	a4,a4,0x2
    80200bc6:	9736                	add	a4,a4,a3
    80200bc8:	c710                	sw	a2,8(a4)
                        fdt.nvirtio++;
    80200bca:	2785                	addiw	a5,a5,1
    80200bcc:	08f6a423          	sw	a5,136(a3)
    80200bd0:	b741                	j	80200b50 <fdt_init+0x276>
            if (depth == cpus_depth) cpus_depth = -1;
    80200bd2:	5bfd                	li	s7,-1
    80200bd4:	b741                	j	80200b54 <fdt_init+0x27a>
    80200bd6:	e5e6                	sd	s9,200(sp)
    80200bd8:	fd6e                	sd	s11,184(sp)
            uint32 len     = be32(*p++);
    80200bda:	40c8                	lw	a0,4(s1)
    80200bdc:	00000097          	auipc	ra,0x0
    80200be0:	c32080e7          	jalr	-974(ra) # 8020080e <be32>
    80200be4:	8caa                	mv	s9,a0
            uint32 nameoff = be32(*p++);
    80200be6:	00c48d93          	addi	s11,s1,12
    80200bea:	4488                	lw	a0,8(s1)
    80200bec:	00000097          	auipc	ra,0x0
    80200bf0:	c22080e7          	jalr	-990(ra) # 8020080e <be32>
            const char *pname = &strings[nameoff];
    80200bf4:	02051a13          	slli	s4,a0,0x20
    80200bf8:	020a5a13          	srli	s4,s4,0x20
    80200bfc:	9a5a                	add	s4,s4,s6
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200bfe:	003c879b          	addiw	a5,s9,3
    80200c02:	0027d79b          	srliw	a5,a5,0x2
    80200c06:	078a                	slli	a5,a5,0x2
    80200c08:	97ee                	add	a5,a5,s11
    80200c0a:	eef43c23          	sd	a5,-264(s0)
            if (streq(pname, "#address-cells")) {
    80200c0e:	00006597          	auipc	a1,0x6
    80200c12:	68258593          	addi	a1,a1,1666 # 80207290 <etext+0x290>
    80200c16:	8552                	mv	a0,s4
    80200c18:	00000097          	auipc	ra,0x0
    80200c1c:	c2a080e7          	jalr	-982(ra) # 80200842 <streq>
    80200c20:	c11d                	beqz	a0,80200c46 <fdt_init+0x36c>
                ac[depth] = be32(val[0]);
    80200c22:	44c8                	lw	a0,12(s1)
    80200c24:	00000097          	auipc	ra,0x0
    80200c28:	bea080e7          	jalr	-1046(ra) # 8020080e <be32>
    80200c2c:	00299793          	slli	a5,s3,0x2
    80200c30:	f9078713          	addi	a4,a5,-112
    80200c34:	008707b3          	add	a5,a4,s0
    80200c38:	fca7a023          	sw	a0,-64(a5)
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200c3c:	ef843483          	ld	s1,-264(s0)
    80200c40:	6cae                	ld	s9,200(sp)
    80200c42:	7dea                	ld	s11,184(sp)
    80200c44:	bba9                	j	8020099e <fdt_init+0xc4>
            } else if (streq(pname, "#size-cells")) {
    80200c46:	00006597          	auipc	a1,0x6
    80200c4a:	65a58593          	addi	a1,a1,1626 # 802072a0 <etext+0x2a0>
    80200c4e:	8552                	mv	a0,s4
    80200c50:	00000097          	auipc	ra,0x0
    80200c54:	bf2080e7          	jalr	-1038(ra) # 80200842 <streq>
    80200c58:	c115                	beqz	a0,80200c7c <fdt_init+0x3a2>
                sc[depth] = be32(val[0]);
    80200c5a:	44c8                	lw	a0,12(s1)
    80200c5c:	00000097          	auipc	ra,0x0
    80200c60:	bb2080e7          	jalr	-1102(ra) # 8020080e <be32>
    80200c64:	00299793          	slli	a5,s3,0x2
    80200c68:	f9078793          	addi	a5,a5,-112
    80200c6c:	97a2                	add	a5,a5,s0
    80200c6e:	f8a7a023          	sw	a0,-128(a5)
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200c72:	ef843483          	ld	s1,-264(s0)
    80200c76:	6cae                	ld	s9,200(sp)
    80200c78:	7dea                	ld	s11,184(sp)
    80200c7a:	b315                	j	8020099e <fdt_init+0xc4>
            } else if (streq(pname, "compatible")) {
    80200c7c:	00006597          	auipc	a1,0x6
    80200c80:	63458593          	addi	a1,a1,1588 # 802072b0 <etext+0x2b0>
    80200c84:	8552                	mv	a0,s4
    80200c86:	00000097          	auipc	ra,0x0
    80200c8a:	bbc080e7          	jalr	-1092(ra) # 80200842 <streq>
    80200c8e:	c555                	beqz	a0,80200d3a <fdt_init+0x460>
                if (strlist_has(c, len, "ns16550a") || strlist_has(c, len, "ns16550"))
    80200c90:	00006617          	auipc	a2,0x6
    80200c94:	63060613          	addi	a2,a2,1584 # 802072c0 <etext+0x2c0>
    80200c98:	85e6                	mv	a1,s9
    80200c9a:	856e                	mv	a0,s11
    80200c9c:	00000097          	auipc	ra,0x0
    80200ca0:	bd8080e7          	jalr	-1064(ra) # 80200874 <strlist_has>
    80200ca4:	c519                	beqz	a0,80200cb2 <fdt_init+0x3d8>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200ca6:	ef843483          	ld	s1,-264(s0)
                    kind = PEND_UART;
    80200caa:	4c05                	li	s8,1
    80200cac:	6cae                	ld	s9,200(sp)
    80200cae:	7dea                	ld	s11,184(sp)
    80200cb0:	b1fd                	j	8020099e <fdt_init+0xc4>
                if (strlist_has(c, len, "ns16550a") || strlist_has(c, len, "ns16550"))
    80200cb2:	00006617          	auipc	a2,0x6
    80200cb6:	61e60613          	addi	a2,a2,1566 # 802072d0 <etext+0x2d0>
    80200cba:	85e6                	mv	a1,s9
    80200cbc:	856e                	mv	a0,s11
    80200cbe:	00000097          	auipc	ra,0x0
    80200cc2:	bb6080e7          	jalr	-1098(ra) # 80200874 <strlist_has>
    80200cc6:	c519                	beqz	a0,80200cd4 <fdt_init+0x3fa>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200cc8:	ef843483          	ld	s1,-264(s0)
                    kind = PEND_UART;
    80200ccc:	4c05                	li	s8,1
    80200cce:	6cae                	ld	s9,200(sp)
    80200cd0:	7dea                	ld	s11,184(sp)
    80200cd2:	b1f1                	j	8020099e <fdt_init+0xc4>
                else if (strlist_has(c, len, "riscv,plic0") ||
    80200cd4:	00006617          	auipc	a2,0x6
    80200cd8:	60460613          	addi	a2,a2,1540 # 802072d8 <etext+0x2d8>
    80200cdc:	85e6                	mv	a1,s9
    80200cde:	856e                	mv	a0,s11
    80200ce0:	00000097          	auipc	ra,0x0
    80200ce4:	b94080e7          	jalr	-1132(ra) # 80200874 <strlist_has>
    80200ce8:	c519                	beqz	a0,80200cf6 <fdt_init+0x41c>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200cea:	ef843483          	ld	s1,-264(s0)
                    kind = PEND_PLIC;
    80200cee:	4c09                	li	s8,2
    80200cf0:	6cae                	ld	s9,200(sp)
    80200cf2:	7dea                	ld	s11,184(sp)
    80200cf4:	b16d                	j	8020099e <fdt_init+0xc4>
                         strlist_has(c, len, "sifive,plic-1.0.0"))
    80200cf6:	00006617          	auipc	a2,0x6
    80200cfa:	5f260613          	addi	a2,a2,1522 # 802072e8 <etext+0x2e8>
    80200cfe:	85e6                	mv	a1,s9
    80200d00:	856e                	mv	a0,s11
    80200d02:	00000097          	auipc	ra,0x0
    80200d06:	b72080e7          	jalr	-1166(ra) # 80200874 <strlist_has>
                else if (strlist_has(c, len, "riscv,plic0") ||
    80200d0a:	c519                	beqz	a0,80200d18 <fdt_init+0x43e>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200d0c:	ef843483          	ld	s1,-264(s0)
                    kind = PEND_PLIC;
    80200d10:	4c09                	li	s8,2
    80200d12:	6cae                	ld	s9,200(sp)
    80200d14:	7dea                	ld	s11,184(sp)
    80200d16:	b161                	j	8020099e <fdt_init+0xc4>
                else if (strlist_has(c, len, "virtio,mmio"))
    80200d18:	00006617          	auipc	a2,0x6
    80200d1c:	5e860613          	addi	a2,a2,1512 # 80207300 <etext+0x300>
    80200d20:	85e6                	mv	a1,s9
    80200d22:	856e                	mv	a0,s11
    80200d24:	00000097          	auipc	ra,0x0
    80200d28:	b50080e7          	jalr	-1200(ra) # 80200874 <strlist_has>
    80200d2c:	cc0517e3          	bnez	a0,802009fa <fdt_init+0x120>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200d30:	ef843483          	ld	s1,-264(s0)
    80200d34:	6cae                	ld	s9,200(sp)
    80200d36:	7dea                	ld	s11,184(sp)
    80200d38:	b19d                	j	8020099e <fdt_init+0xc4>
            } else if (streq(pname, "device_type")) {
    80200d3a:	00006597          	auipc	a1,0x6
    80200d3e:	5d658593          	addi	a1,a1,1494 # 80207310 <etext+0x310>
    80200d42:	8552                	mv	a0,s4
    80200d44:	00000097          	auipc	ra,0x0
    80200d48:	afe080e7          	jalr	-1282(ra) # 80200842 <streq>
    80200d4c:	c115                	beqz	a0,80200d70 <fdt_init+0x496>
                if (strlist_has((const char *)val, len, "memory"))
    80200d4e:	00006617          	auipc	a2,0x6
    80200d52:	5d260613          	addi	a2,a2,1490 # 80207320 <etext+0x320>
    80200d56:	85e6                	mv	a1,s9
    80200d58:	856e                	mv	a0,s11
    80200d5a:	00000097          	auipc	ra,0x0
    80200d5e:	b1a080e7          	jalr	-1254(ra) # 80200874 <strlist_has>
    80200d62:	ca0512e3          	bnez	a0,80200a06 <fdt_init+0x12c>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200d66:	ef843483          	ld	s1,-264(s0)
    80200d6a:	6cae                	ld	s9,200(sp)
    80200d6c:	7dea                	ld	s11,184(sp)
    80200d6e:	b905                	j	8020099e <fdt_init+0xc4>
            } else if (streq(pname, "interrupts")) {
    80200d70:	00006597          	auipc	a1,0x6
    80200d74:	5b858593          	addi	a1,a1,1464 # 80207328 <etext+0x328>
    80200d78:	8552                	mv	a0,s4
    80200d7a:	00000097          	auipc	ra,0x0
    80200d7e:	ac8080e7          	jalr	-1336(ra) # 80200842 <streq>
    80200d82:	c11d                	beqz	a0,80200da8 <fdt_init+0x4ce>
                /* First cell = PLIC source number (qemu virt uses plain
                 * one-cell specifiers for uart and virtio). */
                if (len >= 4) { irq = be32(val[0]); have_irq = 1; }
    80200d84:	478d                	li	a5,3
    80200d86:	c997f6e3          	bgeu	a5,s9,80200a12 <fdt_init+0x138>
    80200d8a:	44c8                	lw	a0,12(s1)
    80200d8c:	00000097          	auipc	ra,0x0
    80200d90:	a82080e7          	jalr	-1406(ra) # 8020080e <be32>
    80200d94:	eea43423          	sd	a0,-280(s0)
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200d98:	ef843483          	ld	s1,-264(s0)
                if (len >= 4) { irq = be32(val[0]); have_irq = 1; }
    80200d9c:	4785                	li	a5,1
    80200d9e:	eef43823          	sd	a5,-272(s0)
    80200da2:	6cae                	ld	s9,200(sp)
    80200da4:	7dea                	ld	s11,184(sp)
    80200da6:	bee5                	j	8020099e <fdt_init+0xc4>
            } else if (streq(pname, "reg")) {
    80200da8:	00006597          	auipc	a1,0x6
    80200dac:	59058593          	addi	a1,a1,1424 # 80207338 <etext+0x338>
    80200db0:	8552                	mv	a0,s4
    80200db2:	00000097          	auipc	ra,0x0
    80200db6:	a90080e7          	jalr	-1392(ra) # 80200842 <streq>
    80200dba:	c60501e3          	beqz	a0,80200a1c <fdt_init+0x142>
                /* Decode with the PARENT's cell counts. */
                int pac = ac[depth - 1];
    80200dbe:	fff9879b          	addiw	a5,s3,-1
    80200dc2:	078a                	slli	a5,a5,0x2
    80200dc4:	f9078713          	addi	a4,a5,-112
    80200dc8:	9722                	add	a4,a4,s0
    80200dca:	fc072a03          	lw	s4,-64(a4)
                int psc = sc[depth - 1];
    80200dce:	f8072d03          	lw	s10,-128(a4)
                if (pac == 2)      reg_base = be64(val);
    80200dd2:	4789                	li	a5,2
    80200dd4:	02fa0563          	beq	s4,a5,80200dfe <fdt_init+0x524>
                else if (pac == 1) reg_base = be32(val[0]);
    80200dd8:	4785                	li	a5,1
                else               reg_base = 0;
    80200dda:	f0043423          	sd	zero,-248(s0)
                else if (pac == 1) reg_base = be32(val[0]);
    80200dde:	04fa0463          	beq	s4,a5,80200e26 <fdt_init+0x54c>

                if (psc == 2)      reg_size = be64(&val[pac]);
    80200de2:	4789                	li	a5,2
    80200de4:	04fd0c63          	beq	s10,a5,80200e3c <fdt_init+0x562>
                else if (psc == 1) reg_size = be32(val[pac]);
    80200de8:	4785                	li	a5,1
    80200dea:	08fd0563          	beq	s10,a5,80200e74 <fdt_init+0x59a>
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200dee:	ef843483          	ld	s1,-264(s0)
                else               reg_size = 0;
    80200df2:	f0043023          	sd	zero,-256(s0)
                have_reg = 1;
    80200df6:	4d05                	li	s10,1
    80200df8:	6cae                	ld	s9,200(sp)
    80200dfa:	7dea                	ld	s11,184(sp)
    80200dfc:	b64d                	j	8020099e <fdt_init+0xc4>
    return ((uint64)be32(p[0]) << 32) | be32(p[1]);
    80200dfe:	44c8                	lw	a0,12(s1)
    80200e00:	00000097          	auipc	ra,0x0
    80200e04:	a0e080e7          	jalr	-1522(ra) # 8020080e <be32>
    80200e08:	8caa                	mv	s9,a0
    80200e0a:	4888                	lw	a0,16(s1)
    80200e0c:	00000097          	auipc	ra,0x0
    80200e10:	a02080e7          	jalr	-1534(ra) # 8020080e <be32>
    80200e14:	1c82                	slli	s9,s9,0x20
    80200e16:	02051793          	slli	a5,a0,0x20
    80200e1a:	9381                	srli	a5,a5,0x20
    80200e1c:	00fce7b3          	or	a5,s9,a5
    80200e20:	f0f43423          	sd	a5,-248(s0)
    80200e24:	bf7d                	j	80200de2 <fdt_init+0x508>
                else if (pac == 1) reg_base = be32(val[0]);
    80200e26:	44c8                	lw	a0,12(s1)
    80200e28:	00000097          	auipc	ra,0x0
    80200e2c:	9e6080e7          	jalr	-1562(ra) # 8020080e <be32>
    80200e30:	02051793          	slli	a5,a0,0x20
    80200e34:	9381                	srli	a5,a5,0x20
    80200e36:	f0f43423          	sd	a5,-248(s0)
    80200e3a:	b765                	j	80200de2 <fdt_init+0x508>
                if (psc == 2)      reg_size = be64(&val[pac]);
    80200e3c:	002a1493          	slli	s1,s4,0x2
    80200e40:	94ee                	add	s1,s1,s11
    return ((uint64)be32(p[0]) << 32) | be32(p[1]);
    80200e42:	4088                	lw	a0,0(s1)
    80200e44:	00000097          	auipc	ra,0x0
    80200e48:	9ca080e7          	jalr	-1590(ra) # 8020080e <be32>
    80200e4c:	8a2a                	mv	s4,a0
    80200e4e:	40c8                	lw	a0,4(s1)
    80200e50:	00000097          	auipc	ra,0x0
    80200e54:	9be080e7          	jalr	-1602(ra) # 8020080e <be32>
    80200e58:	1a02                	slli	s4,s4,0x20
    80200e5a:	02051793          	slli	a5,a0,0x20
    80200e5e:	9381                	srli	a5,a5,0x20
    80200e60:	00fa67b3          	or	a5,s4,a5
    80200e64:	f0f43023          	sd	a5,-256(s0)
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200e68:	ef843483          	ld	s1,-264(s0)
                have_reg = 1;
    80200e6c:	4d05                	li	s10,1
    80200e6e:	6cae                	ld	s9,200(sp)
    80200e70:	7dea                	ld	s11,184(sp)
    80200e72:	b635                	j	8020099e <fdt_init+0xc4>
                else if (psc == 1) reg_size = be32(val[pac]);
    80200e74:	0a0a                	slli	s4,s4,0x2
    80200e76:	9dd2                	add	s11,s11,s4
    80200e78:	000da503          	lw	a0,0(s11)
    80200e7c:	00000097          	auipc	ra,0x0
    80200e80:	992080e7          	jalr	-1646(ra) # 8020080e <be32>
    80200e84:	02051793          	slli	a5,a0,0x20
    80200e88:	9381                	srli	a5,a5,0x20
    80200e8a:	f0f43023          	sd	a5,-256(s0)
            p += (len + 3) / 4;                 /* properties are 4-byte aligned */
    80200e8e:	ef843483          	ld	s1,-264(s0)
    80200e92:	6cae                	ld	s9,200(sp)
    80200e94:	7dea                	ld	s11,184(sp)
    80200e96:	b621                	j	8020099e <fdt_init+0xc4>
    80200e98:	e5e6                	sd	s9,200(sp)
    80200e9a:	fd6e                	sd	s11,184(sp)
            }
            continue;
        }
        panic("fdt: unknown token in structure block");
    80200e9c:	00006517          	auipc	a0,0x6
    80200ea0:	4a450513          	addi	a0,a0,1188 # 80207340 <etext+0x340>
    80200ea4:	fffff097          	auipc	ra,0xfffff
    80200ea8:	70c080e7          	jalr	1804(ra) # 802005b0 <panic>
    }

    if (fdt.ncpu == 0) fdt.ncpu = 1;
    80200eac:	00028797          	auipc	a5,0x28
    80200eb0:	20c7a783          	lw	a5,524(a5) # 802290b8 <fdt+0xa0>
    80200eb4:	ef8d                	bnez	a5,80200eee <fdt_init+0x614>
    80200eb6:	4785                	li	a5,1
    80200eb8:	00028717          	auipc	a4,0x28
    80200ebc:	20f72023          	sw	a5,512(a4) # 802290b8 <fdt+0xa0>
    if (fdt.ncpu > NCPU) fdt.ncpu = NCPU;
    if (!fdt.uart_base) panic("fdt: no console found on this board");
    80200ec0:	00028797          	auipc	a5,0x28
    80200ec4:	1687b783          	ld	a5,360(a5) # 80229028 <fdt+0x10>
    80200ec8:	cf85                	beqz	a5,80200f00 <fdt_init+0x626>
    if (!fdt.mem_size)  panic("fdt: no memory node");
    80200eca:	00028797          	auipc	a5,0x28
    80200ece:	1e67b783          	ld	a5,486(a5) # 802290b0 <fdt+0x98>
    80200ed2:	c3a9                	beqz	a5,80200f14 <fdt_init+0x63a>
    80200ed4:	64b2                	ld	s1,264(sp)
    80200ed6:	6912                	ld	s2,256(sp)
    80200ed8:	7a4e                	ld	s4,240(sp)
    80200eda:	7aae                	ld	s5,232(sp)
    80200edc:	7b0e                	ld	s6,224(sp)
    80200ede:	6bee                	ld	s7,216(sp)
    80200ee0:	6c4e                	ld	s8,208(sp)
    80200ee2:	6d0e                	ld	s10,192(sp)
}
    80200ee4:	60f2                	ld	ra,280(sp)
    80200ee6:	6452                	ld	s0,272(sp)
    80200ee8:	79ee                	ld	s3,248(sp)
    80200eea:	6115                	addi	sp,sp,288
    80200eec:	8082                	ret
    if (fdt.ncpu > NCPU) fdt.ncpu = NCPU;
    80200eee:	4721                	li	a4,8
    80200ef0:	fcf758e3          	bge	a4,a5,80200ec0 <fdt_init+0x5e6>
    80200ef4:	87ba                	mv	a5,a4
    80200ef6:	00028717          	auipc	a4,0x28
    80200efa:	1cf72123          	sw	a5,450(a4) # 802290b8 <fdt+0xa0>
    80200efe:	b7c9                	j	80200ec0 <fdt_init+0x5e6>
    80200f00:	e5e6                	sd	s9,200(sp)
    80200f02:	fd6e                	sd	s11,184(sp)
    if (!fdt.uart_base) panic("fdt: no console found on this board");
    80200f04:	00006517          	auipc	a0,0x6
    80200f08:	46450513          	addi	a0,a0,1124 # 80207368 <etext+0x368>
    80200f0c:	fffff097          	auipc	ra,0xfffff
    80200f10:	6a4080e7          	jalr	1700(ra) # 802005b0 <panic>
    80200f14:	e5e6                	sd	s9,200(sp)
    80200f16:	fd6e                	sd	s11,184(sp)
    if (!fdt.mem_size)  panic("fdt: no memory node");
    80200f18:	00006517          	auipc	a0,0x6
    80200f1c:	47850513          	addi	a0,a0,1144 # 80207390 <etext+0x390>
    80200f20:	fffff097          	auipc	ra,0xfffff
    80200f24:	690080e7          	jalr	1680(ra) # 802005b0 <panic>
                fdt.ncpu++;
    80200f28:	00028717          	auipc	a4,0x28
    80200f2c:	0f070713          	addi	a4,a4,240 # 80229018 <fdt>
    80200f30:	0a072783          	lw	a5,160(a4)
    80200f34:	2785                	addiw	a5,a5,1
    80200f36:	0af72023          	sw	a5,160(a4)
            depth++;
    80200f3a:	89e2                	mv	s3,s8
            have_irq = 0; irq = 0;
    80200f3c:	ee043423          	sd	zero,-280(s0)
    80200f40:	ee043823          	sd	zero,-272(s0)
            kind = PEND_NONE; have_reg = 0; reg_base = 0; reg_size = 0;
    80200f44:	f0043023          	sd	zero,-256(s0)
    80200f48:	f0043423          	sd	zero,-248(s0)
    80200f4c:	4d01                	li	s10,0
    80200f4e:	4c01                	li	s8,0
    80200f50:	b4b9                	j	8020099e <fdt_init+0xc4>

0000000080200f52 <palloc_init>:
} kmem;

#define PA2IDX(pa) (((uint64)(pa) - kmem.base) >> PGSHIFT)

void palloc_init(void)
{
    80200f52:	715d                	addi	sp,sp,-80
    80200f54:	e486                	sd	ra,72(sp)
    80200f56:	e0a2                	sd	s0,64(sp)
    80200f58:	fc26                	sd	s1,56(sp)
    80200f5a:	f84a                	sd	s2,48(sp)
    80200f5c:	f44e                	sd	s3,40(sp)
    80200f5e:	f052                	sd	s4,32(sp)
    80200f60:	ec56                	sd	s5,24(sp)
    80200f62:	e85a                	sd	s6,16(sp)
    80200f64:	e45e                	sd	s7,8(sp)
    80200f66:	e062                	sd	s8,0(sp)
    80200f68:	0880                	addi	s0,sp,80
    initlock(&kmem.lock, "kmem");
    80200f6a:	00028b97          	auipc	s7,0x28
    80200f6e:	156b8b93          	addi	s7,s7,342 # 802290c0 <kmem>
    80200f72:	00006597          	auipc	a1,0x6
    80200f76:	43658593          	addi	a1,a1,1078 # 802073a8 <etext+0x3a8>
    80200f7a:	855e                	mv	a0,s7
    80200f7c:	00000097          	auipc	ra,0x0
    80200f80:	304080e7          	jalr	772(ra) # 80201280 <initlock>

    uint64 mem_start = fdt.mem_base;
    80200f84:	00028717          	auipc	a4,0x28
    80200f88:	09470713          	addi	a4,a4,148 # 80229018 <fdt>
    80200f8c:	09073a83          	ld	s5,144(a4)
    uint64 mem_end   = fdt.mem_base + fdt.mem_size;
    80200f90:	09873a03          	ld	s4,152(a4)
    80200f94:	9a56                	add	s4,s4,s5





    uint64 free_start = PGROUNDUP((uint64)kernel_end);
    80200f96:	6c05                	lui	s8,0x1
    80200f98:	fffc0693          	addi	a3,s8,-1 # fff <_entry-0x801ff001>
    80200f9c:	77fd                	lui	a5,0xfffff
    80200f9e:	0013f617          	auipc	a2,0x13f
    80200fa2:	06160613          	addi	a2,a2,97 # 8033ffff <uart+0xfcf>
    80200fa6:	00f674b3          	and	s1,a2,a5
    uint64 fdt_lo = PGROUNDDOWN(fdt.blob);
    80200faa:	00073903          	ld	s2,0(a4)
    80200fae:	00f979b3          	and	s3,s2,a5
    uint64 fdt_hi = PGROUNDUP(fdt.blob + fdt.blob_size);
    80200fb2:	6718                	ld	a4,8(a4)
    80200fb4:	993a                	add	s2,s2,a4
    80200fb6:	9936                	add	s2,s2,a3
    80200fb8:	00f97933          	and	s2,s2,a5

    uint64 npages = (mem_end - free_start) >> PGSHIFT;
    80200fbc:	409a0b33          	sub	s6,s4,s1
    80200fc0:	00cb5b13          	srli	s6,s6,0xc

    /* Implementation note. */

    uint64 refbytes = PGROUNDUP(npages);
    80200fc4:	9b36                	add	s6,s6,a3
    80200fc6:	00fb7b33          	and	s6,s6,a5
    kmem.refcnt = (uint8 *)free_start;
    80200fca:	029bbc23          	sd	s1,56(s7)
    memset(kmem.refcnt, 0, refbytes);
    80200fce:	865a                	mv	a2,s6
    80200fd0:	4581                	li	a1,0
    80200fd2:	8526                	mv	a0,s1
    80200fd4:	fffff097          	auipc	ra,0xfffff
    80200fd8:	682080e7          	jalr	1666(ra) # 80200656 <memset>
    free_start += refbytes;
    80200fdc:	01648633          	add	a2,s1,s6

    kmem.base = free_start;
    80200fe0:	02cbb023          	sd	a2,32(s7)
    kmem.top  = mem_end;
    80200fe4:	034bb423          	sd	s4,40(s7)
    kmem.freelist = 0;
    80200fe8:	000bbc23          	sd	zero,24(s7)
    kmem.nfree = 0;
    80200fec:	020ba823          	sw	zero,48(s7)

    for (uint64 p = kmem.base; p + PGSIZE <= kmem.top; p += PGSIZE) {
    80200ff0:	9c32                	add	s8,s8,a2
    80200ff2:	058a6063          	bltu	s4,s8,80201032 <palloc_init+0xe0>
        if (p >= fdt_lo && p < fdt_hi)      /* the device tree lives here */
            continue;                       /* never hand this page out    */
        struct run *r = (struct run *)p;
        kmem.refcnt[PA2IDX(p)] = 0;
    80200ff6:	87de                	mv	a5,s7
    for (uint64 p = kmem.base; p + PGSIZE <= kmem.top; p += PGSIZE) {
    80200ff8:	6505                	lui	a0,0x1
    80200ffa:	6589                	lui	a1,0x2
    80200ffc:	a035                	j	80201028 <palloc_init+0xd6>
        kmem.refcnt[PA2IDX(p)] = 0;
    80200ffe:	7398                	ld	a4,32(a5)
    80201000:	40e60733          	sub	a4,a2,a4
    80201004:	8331                	srli	a4,a4,0xc
    80201006:	7f94                	ld	a3,56(a5)
    80201008:	9736                	add	a4,a4,a3
    8020100a:	00070023          	sb	zero,0(a4)
        r->next = kmem.freelist;
    8020100e:	6f98                	ld	a4,24(a5)
    80201010:	e218                	sd	a4,0(a2)
        kmem.freelist = r;
    80201012:	ef90                	sd	a2,24(a5)
        kmem.nfree++;
    80201014:	5b98                	lw	a4,48(a5)
    80201016:	2705                	addiw	a4,a4,1
    80201018:	db98                	sw	a4,48(a5)
    for (uint64 p = kmem.base; p + PGSIZE <= kmem.top; p += PGSIZE) {
    8020101a:	00a606b3          	add	a3,a2,a0
    8020101e:	962e                	add	a2,a2,a1
    80201020:	7798                	ld	a4,40(a5)
    80201022:	00c76863          	bltu	a4,a2,80201032 <palloc_init+0xe0>
    80201026:	8636                	mv	a2,a3
        if (p >= fdt_lo && p < fdt_hi)      /* the device tree lives here */
    80201028:	fd366be3          	bltu	a2,s3,80200ffe <palloc_init+0xac>
    8020102c:	fd2679e3          	bgeu	a2,s2,80200ffe <palloc_init+0xac>
    80201030:	b7ed                	j	8020101a <palloc_init+0xc8>
    }
    printf("palloc: RAM %p..%p, managing %d free pages (%d MiB)\n",
    80201032:	00028697          	auipc	a3,0x28
    80201036:	0be6a683          	lw	a3,190(a3) # 802290f0 <kmem+0x30>
           mem_start, mem_end, kmem.nfree, (kmem.nfree * PGSIZE) >> 20);
    8020103a:	00c6971b          	slliw	a4,a3,0xc
    printf("palloc: RAM %p..%p, managing %d free pages (%d MiB)\n",
    8020103e:	4147571b          	sraiw	a4,a4,0x14
    80201042:	8652                	mv	a2,s4
    80201044:	85d6                	mv	a1,s5
    80201046:	00006517          	auipc	a0,0x6
    8020104a:	36a50513          	addi	a0,a0,874 # 802073b0 <etext+0x3b0>
    8020104e:	fffff097          	auipc	ra,0xfffff
    80201052:	2f2080e7          	jalr	754(ra) # 80200340 <printf>
}
    80201056:	60a6                	ld	ra,72(sp)
    80201058:	6406                	ld	s0,64(sp)
    8020105a:	74e2                	ld	s1,56(sp)
    8020105c:	7942                	ld	s2,48(sp)
    8020105e:	79a2                	ld	s3,40(sp)
    80201060:	7a02                	ld	s4,32(sp)
    80201062:	6ae2                	ld	s5,24(sp)
    80201064:	6b42                	ld	s6,16(sp)
    80201066:	6ba2                	ld	s7,8(sp)
    80201068:	6c02                	ld	s8,0(sp)
    8020106a:	6161                	addi	sp,sp,80
    8020106c:	8082                	ret

000000008020106e <palloc>:

void *palloc(void)
{
    8020106e:	1101                	addi	sp,sp,-32
    80201070:	ec06                	sd	ra,24(sp)
    80201072:	e822                	sd	s0,16(sp)
    80201074:	e426                	sd	s1,8(sp)
    80201076:	1000                	addi	s0,sp,32
    acquire(&kmem.lock);
    80201078:	00028497          	auipc	s1,0x28
    8020107c:	04848493          	addi	s1,s1,72 # 802290c0 <kmem>
    80201080:	8526                	mv	a0,s1
    80201082:	00000097          	auipc	ra,0x0
    80201086:	27e080e7          	jalr	638(ra) # 80201300 <acquire>
    struct run *r = kmem.freelist;
    8020108a:	6c84                	ld	s1,24(s1)
    if (r) {
    8020108c:	c4a1                	beqz	s1,802010d4 <palloc+0x66>
        kmem.freelist = r->next;
    8020108e:	609c                	ld	a5,0(s1)
    80201090:	00028517          	auipc	a0,0x28
    80201094:	03050513          	addi	a0,a0,48 # 802290c0 <kmem>
    80201098:	ed1c                	sd	a5,24(a0)
        kmem.nfree--;
    8020109a:	591c                	lw	a5,48(a0)
    8020109c:	37fd                	addiw	a5,a5,-1 # ffffffffffffefff <uart+0xffffffff7fcbffcf>
    8020109e:	d91c                	sw	a5,48(a0)
        kmem.refcnt[PA2IDX(r)] = 1;
    802010a0:	711c                	ld	a5,32(a0)
    802010a2:	40f487b3          	sub	a5,s1,a5
    802010a6:	83b1                	srli	a5,a5,0xc
    802010a8:	7d18                	ld	a4,56(a0)
    802010aa:	97ba                	add	a5,a5,a4
    802010ac:	4705                	li	a4,1
    802010ae:	00e78023          	sb	a4,0(a5)
    }
    release(&kmem.lock);
    802010b2:	00000097          	auipc	ra,0x0
    802010b6:	2fe080e7          	jalr	766(ra) # 802013b0 <release>

    if (r)
        memset((void *)r, 5, PGSIZE);   /* poison: catch use-before-init */
    802010ba:	6605                	lui	a2,0x1
    802010bc:	4595                	li	a1,5
    802010be:	8526                	mv	a0,s1
    802010c0:	fffff097          	auipc	ra,0xfffff
    802010c4:	596080e7          	jalr	1430(ra) # 80200656 <memset>
    return (void *)r;
}
    802010c8:	8526                	mv	a0,s1
    802010ca:	60e2                	ld	ra,24(sp)
    802010cc:	6442                	ld	s0,16(sp)
    802010ce:	64a2                	ld	s1,8(sp)
    802010d0:	6105                	addi	sp,sp,32
    802010d2:	8082                	ret
    release(&kmem.lock);
    802010d4:	00028517          	auipc	a0,0x28
    802010d8:	fec50513          	addi	a0,a0,-20 # 802290c0 <kmem>
    802010dc:	00000097          	auipc	ra,0x0
    802010e0:	2d4080e7          	jalr	724(ra) # 802013b0 <release>
    if (r)
    802010e4:	b7d5                	j	802010c8 <palloc+0x5a>

00000000802010e6 <palloc_ref_inc>:

void palloc_ref_inc(void *pa)
{
    802010e6:	1101                	addi	sp,sp,-32
    802010e8:	ec06                	sd	ra,24(sp)
    802010ea:	e822                	sd	s0,16(sp)
    802010ec:	e426                	sd	s1,8(sp)
    802010ee:	e04a                	sd	s2,0(sp)
    802010f0:	1000                	addi	s0,sp,32
    802010f2:	84aa                	mv	s1,a0
    acquire(&kmem.lock);
    802010f4:	00028917          	auipc	s2,0x28
    802010f8:	fcc90913          	addi	s2,s2,-52 # 802290c0 <kmem>
    802010fc:	854a                	mv	a0,s2
    802010fe:	00000097          	auipc	ra,0x0
    80201102:	202080e7          	jalr	514(ra) # 80201300 <acquire>
    kmem.refcnt[PA2IDX(pa)]++;
    80201106:	02093783          	ld	a5,32(s2)
    8020110a:	8c9d                	sub	s1,s1,a5
    8020110c:	80b1                	srli	s1,s1,0xc
    8020110e:	03893783          	ld	a5,56(s2)
    80201112:	97a6                	add	a5,a5,s1
    80201114:	0007c703          	lbu	a4,0(a5)
    80201118:	2705                	addiw	a4,a4,1
    8020111a:	00e78023          	sb	a4,0(a5)
    release(&kmem.lock);
    8020111e:	854a                	mv	a0,s2
    80201120:	00000097          	auipc	ra,0x0
    80201124:	290080e7          	jalr	656(ra) # 802013b0 <release>
}
    80201128:	60e2                	ld	ra,24(sp)
    8020112a:	6442                	ld	s0,16(sp)
    8020112c:	64a2                	ld	s1,8(sp)
    8020112e:	6902                	ld	s2,0(sp)
    80201130:	6105                	addi	sp,sp,32
    80201132:	8082                	ret

0000000080201134 <palloc_ref_get>:

int palloc_ref_get(void *pa)
{
    80201134:	1101                	addi	sp,sp,-32
    80201136:	ec06                	sd	ra,24(sp)
    80201138:	e822                	sd	s0,16(sp)
    8020113a:	e426                	sd	s1,8(sp)
    8020113c:	e04a                	sd	s2,0(sp)
    8020113e:	1000                	addi	s0,sp,32
    80201140:	84aa                	mv	s1,a0
    acquire(&kmem.lock);
    80201142:	00028917          	auipc	s2,0x28
    80201146:	f7e90913          	addi	s2,s2,-130 # 802290c0 <kmem>
    8020114a:	854a                	mv	a0,s2
    8020114c:	00000097          	auipc	ra,0x0
    80201150:	1b4080e7          	jalr	436(ra) # 80201300 <acquire>
    int n = kmem.refcnt[PA2IDX(pa)];
    80201154:	02093783          	ld	a5,32(s2)
    80201158:	8c9d                	sub	s1,s1,a5
    8020115a:	80b1                	srli	s1,s1,0xc
    8020115c:	03893783          	ld	a5,56(s2)
    80201160:	97a6                	add	a5,a5,s1
    80201162:	0007c483          	lbu	s1,0(a5)
    release(&kmem.lock);
    80201166:	854a                	mv	a0,s2
    80201168:	00000097          	auipc	ra,0x0
    8020116c:	248080e7          	jalr	584(ra) # 802013b0 <release>
    return n;
}
    80201170:	8526                	mv	a0,s1
    80201172:	60e2                	ld	ra,24(sp)
    80201174:	6442                	ld	s0,16(sp)
    80201176:	64a2                	ld	s1,8(sp)
    80201178:	6902                	ld	s2,0(sp)
    8020117a:	6105                	addi	sp,sp,32
    8020117c:	8082                	ret

000000008020117e <pfree>:

void pfree(void *pa)
{
    8020117e:	1101                	addi	sp,sp,-32
    80201180:	ec06                	sd	ra,24(sp)
    80201182:	e822                	sd	s0,16(sp)
    80201184:	e426                	sd	s1,8(sp)
    80201186:	e04a                	sd	s2,0(sp)
    80201188:	1000                	addi	s0,sp,32
    if (((uint64)pa % PGSIZE) != 0 || (uint64)pa < kmem.base || (uint64)pa >= kmem.top)
    8020118a:	03451713          	slli	a4,a0,0x34
    8020118e:	e359                	bnez	a4,80201214 <pfree+0x96>
    80201190:	84aa                	mv	s1,a0
    80201192:	00028717          	auipc	a4,0x28
    80201196:	f4e73703          	ld	a4,-178(a4) # 802290e0 <kmem+0x20>
    8020119a:	06e56d63          	bltu	a0,a4,80201214 <pfree+0x96>
    8020119e:	00028717          	auipc	a4,0x28
    802011a2:	f4a73703          	ld	a4,-182(a4) # 802290e8 <kmem+0x28>
    802011a6:	06e57763          	bgeu	a0,a4,80201214 <pfree+0x96>
        panic("pfree: bad pointer");

    acquire(&kmem.lock);
    802011aa:	00028917          	auipc	s2,0x28
    802011ae:	f1690913          	addi	s2,s2,-234 # 802290c0 <kmem>
    802011b2:	854a                	mv	a0,s2
    802011b4:	00000097          	auipc	ra,0x0
    802011b8:	14c080e7          	jalr	332(ra) # 80201300 <acquire>
    uint64 i = PA2IDX(pa);
    802011bc:	02093783          	ld	a5,32(s2)
    802011c0:	40f487b3          	sub	a5,s1,a5
    802011c4:	83b1                	srli	a5,a5,0xc
    if (kmem.refcnt[i] < 1)
    802011c6:	03893703          	ld	a4,56(s2)
    802011ca:	973e                	add	a4,a4,a5
    802011cc:	00074783          	lbu	a5,0(a4)
    802011d0:	cbb1                	beqz	a5,80201224 <pfree+0xa6>
        panic("pfree: double free / refcount underflow");

    if (--kmem.refcnt[i] > 0) {          /* Implementation note. */
    802011d2:	37fd                	addiw	a5,a5,-1
    802011d4:	0ff7f793          	zext.b	a5,a5
    802011d8:	00f70023          	sb	a5,0(a4)
    802011dc:	efa1                	bnez	a5,80201234 <pfree+0xb6>
        release(&kmem.lock);
        return;
    }
    memset(pa, 1, PGSIZE);               /* poison: catch use-after-free */
    802011de:	6605                	lui	a2,0x1
    802011e0:	4585                	li	a1,1
    802011e2:	8526                	mv	a0,s1
    802011e4:	fffff097          	auipc	ra,0xfffff
    802011e8:	472080e7          	jalr	1138(ra) # 80200656 <memset>
    struct run *r = (struct run *)pa;
    r->next = kmem.freelist;
    802011ec:	00028517          	auipc	a0,0x28
    802011f0:	ed450513          	addi	a0,a0,-300 # 802290c0 <kmem>
    802011f4:	6d1c                	ld	a5,24(a0)
    802011f6:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    802011f8:	ed04                	sd	s1,24(a0)
    kmem.nfree++;
    802011fa:	591c                	lw	a5,48(a0)
    802011fc:	2785                	addiw	a5,a5,1
    802011fe:	d91c                	sw	a5,48(a0)
    release(&kmem.lock);
    80201200:	00000097          	auipc	ra,0x0
    80201204:	1b0080e7          	jalr	432(ra) # 802013b0 <release>
}
    80201208:	60e2                	ld	ra,24(sp)
    8020120a:	6442                	ld	s0,16(sp)
    8020120c:	64a2                	ld	s1,8(sp)
    8020120e:	6902                	ld	s2,0(sp)
    80201210:	6105                	addi	sp,sp,32
    80201212:	8082                	ret
        panic("pfree: bad pointer");
    80201214:	00006517          	auipc	a0,0x6
    80201218:	1d450513          	addi	a0,a0,468 # 802073e8 <etext+0x3e8>
    8020121c:	fffff097          	auipc	ra,0xfffff
    80201220:	394080e7          	jalr	916(ra) # 802005b0 <panic>
        panic("pfree: double free / refcount underflow");
    80201224:	00006517          	auipc	a0,0x6
    80201228:	1dc50513          	addi	a0,a0,476 # 80207400 <etext+0x400>
    8020122c:	fffff097          	auipc	ra,0xfffff
    80201230:	384080e7          	jalr	900(ra) # 802005b0 <panic>
        release(&kmem.lock);
    80201234:	00028517          	auipc	a0,0x28
    80201238:	e8c50513          	addi	a0,a0,-372 # 802290c0 <kmem>
    8020123c:	00000097          	auipc	ra,0x0
    80201240:	174080e7          	jalr	372(ra) # 802013b0 <release>
        return;
    80201244:	b7d1                	j	80201208 <pfree+0x8a>

0000000080201246 <palloc_free_count>:

int palloc_free_count(void)
{
    80201246:	1101                	addi	sp,sp,-32
    80201248:	ec06                	sd	ra,24(sp)
    8020124a:	e822                	sd	s0,16(sp)
    8020124c:	e426                	sd	s1,8(sp)
    8020124e:	e04a                	sd	s2,0(sp)
    80201250:	1000                	addi	s0,sp,32
    acquire(&kmem.lock);
    80201252:	00028497          	auipc	s1,0x28
    80201256:	e6e48493          	addi	s1,s1,-402 # 802290c0 <kmem>
    8020125a:	8526                	mv	a0,s1
    8020125c:	00000097          	auipc	ra,0x0
    80201260:	0a4080e7          	jalr	164(ra) # 80201300 <acquire>
    int n = kmem.nfree;
    80201264:	0304a903          	lw	s2,48(s1)
    release(&kmem.lock);
    80201268:	8526                	mv	a0,s1
    8020126a:	00000097          	auipc	ra,0x0
    8020126e:	146080e7          	jalr	326(ra) # 802013b0 <release>
    return n;
}
    80201272:	854a                	mv	a0,s2
    80201274:	60e2                	ld	ra,24(sp)
    80201276:	6442                	ld	s0,16(sp)
    80201278:	64a2                	ld	s1,8(sp)
    8020127a:	6902                	ld	s2,0(sp)
    8020127c:	6105                	addi	sp,sp,32
    8020127e:	8082                	ret

0000000080201280 <initlock>:
#include "types.h"
#include "defs.h"
#include "hal.h"

void initlock(struct spinlock *lk, const char *name)
{
    80201280:	1141                	addi	sp,sp,-16
    80201282:	e406                	sd	ra,8(sp)
    80201284:	e022                	sd	s0,0(sp)
    80201286:	0800                	addi	s0,sp,16
    lk->name = name; lk->locked = 0; lk->cpu = -1;
    80201288:	e50c                	sd	a1,8(a0)
    8020128a:	00052023          	sw	zero,0(a0)
    8020128e:	57fd                	li	a5,-1
    80201290:	c91c                	sw	a5,16(a0)
}
    80201292:	60a2                	ld	ra,8(sp)
    80201294:	6402                	ld	s0,0(sp)
    80201296:	0141                	addi	sp,sp,16
    80201298:	8082                	ret

000000008020129a <holding>:
    pop_off();
}

int holding(struct spinlock *lk)
{
    return lk->locked && lk->cpu == hal_hart_id();
    8020129a:	411c                	lw	a5,0(a0)
    8020129c:	e399                	bnez	a5,802012a2 <holding+0x8>
    8020129e:	4501                	li	a0,0
}
    802012a0:	8082                	ret
{
    802012a2:	1101                	addi	sp,sp,-32
    802012a4:	ec06                	sd	ra,24(sp)
    802012a6:	e822                	sd	s0,16(sp)
    802012a8:	e426                	sd	s1,8(sp)
    802012aa:	1000                	addi	s0,sp,32
    return lk->locked && lk->cpu == hal_hart_id();
    802012ac:	4904                	lw	s1,16(a0)
    802012ae:	00005097          	auipc	ra,0x5
    802012b2:	dee080e7          	jalr	-530(ra) # 8020609c <hal_hart_id>
    802012b6:	40a48533          	sub	a0,s1,a0
    802012ba:	00153513          	seqz	a0,a0
}
    802012be:	60e2                	ld	ra,24(sp)
    802012c0:	6442                	ld	s0,16(sp)
    802012c2:	64a2                	ld	s1,8(sp)
    802012c4:	6105                	addi	sp,sp,32
    802012c6:	8082                	ret

00000000802012c8 <push_off>:

void push_off(void)
{
    802012c8:	1101                	addi	sp,sp,-32
    802012ca:	ec06                	sd	ra,24(sp)
    802012cc:	e822                	sd	s0,16(sp)
    802012ce:	e426                	sd	s1,8(sp)
    802012d0:	1000                	addi	s0,sp,32
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    802012d2:	100024f3          	csrr	s1,sstatus
    802012d6:	100027f3          	csrr	a5,sstatus
#define SIE_SSIE (1L << 1)
#define SIE_STIE (1L << 5)       /* timer  */
#define SIE_SEIE (1L << 9)       /* external */

static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
static inline void intr_off(void){ w_sstatus(r_sstatus() & ~SSTATUS_SIE); }
    802012da:	9bf5                	andi	a5,a5,-3
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    802012dc:	10079073          	csrw	sstatus,a5
    int old = intr_get();
    intr_off();
    struct cpu *c = mycpu();
    802012e0:	00000097          	auipc	ra,0x0
    802012e4:	3da080e7          	jalr	986(ra) # 802016ba <mycpu>
    if (c->noff == 0) c->intena = old;   /* remember the ORIGINAL state */
    802012e8:	5d3c                	lw	a5,120(a0)
    802012ea:	e781                	bnez	a5,802012f2 <push_off+0x2a>
static inline int  intr_get(void){ return (r_sstatus() & SSTATUS_SIE) != 0; }
    802012ec:	8085                	srli	s1,s1,0x1
    802012ee:	8885                	andi	s1,s1,1
    802012f0:	dd64                	sw	s1,124(a0)
    c->noff++;
    802012f2:	2785                	addiw	a5,a5,1
    802012f4:	dd3c                	sw	a5,120(a0)
}
    802012f6:	60e2                	ld	ra,24(sp)
    802012f8:	6442                	ld	s0,16(sp)
    802012fa:	64a2                	ld	s1,8(sp)
    802012fc:	6105                	addi	sp,sp,32
    802012fe:	8082                	ret

0000000080201300 <acquire>:
{
    80201300:	1101                	addi	sp,sp,-32
    80201302:	ec06                	sd	ra,24(sp)
    80201304:	e822                	sd	s0,16(sp)
    80201306:	e426                	sd	s1,8(sp)
    80201308:	1000                	addi	s0,sp,32
    8020130a:	84aa                	mv	s1,a0
    push_off();
    8020130c:	00000097          	auipc	ra,0x0
    80201310:	fbc080e7          	jalr	-68(ra) # 802012c8 <push_off>
    if (holding(lk)) panic("acquire: already holding this lock");
    80201314:	8526                	mv	a0,s1
    80201316:	00000097          	auipc	ra,0x0
    8020131a:	f84080e7          	jalr	-124(ra) # 8020129a <holding>
    while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
    8020131e:	4705                	li	a4,1
    if (holding(lk)) panic("acquire: already holding this lock");
    80201320:	e115                	bnez	a0,80201344 <acquire+0x44>
    while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80201322:	87ba                	mv	a5,a4
    80201324:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80201328:	2781                	sext.w	a5,a5
    8020132a:	ffe5                	bnez	a5,80201322 <acquire+0x22>
    __sync_synchronize();          /* fence: nothing below moves above this */
    8020132c:	0330000f          	fence	rw,rw
    lk->cpu = hal_hart_id();
    80201330:	00005097          	auipc	ra,0x5
    80201334:	d6c080e7          	jalr	-660(ra) # 8020609c <hal_hart_id>
    80201338:	c888                	sw	a0,16(s1)
}
    8020133a:	60e2                	ld	ra,24(sp)
    8020133c:	6442                	ld	s0,16(sp)
    8020133e:	64a2                	ld	s1,8(sp)
    80201340:	6105                	addi	sp,sp,32
    80201342:	8082                	ret
    if (holding(lk)) panic("acquire: already holding this lock");
    80201344:	00006517          	auipc	a0,0x6
    80201348:	0e450513          	addi	a0,a0,228 # 80207428 <etext+0x428>
    8020134c:	fffff097          	auipc	ra,0xfffff
    80201350:	264080e7          	jalr	612(ra) # 802005b0 <panic>

0000000080201354 <pop_off>:

void pop_off(void)
{
    80201354:	1141                	addi	sp,sp,-16
    80201356:	e406                	sd	ra,8(sp)
    80201358:	e022                	sd	s0,0(sp)
    8020135a:	0800                	addi	s0,sp,16
    struct cpu *c = mycpu();
    8020135c:	00000097          	auipc	ra,0x0
    80201360:	35e080e7          	jalr	862(ra) # 802016ba <mycpu>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    80201364:	100027f3          	csrr	a5,sstatus
static inline int  intr_get(void){ return (r_sstatus() & SSTATUS_SIE) != 0; }
    80201368:	8b89                	andi	a5,a5,2
    if (intr_get()) panic("pop_off: interrupts already on");
    8020136a:	e39d                	bnez	a5,80201390 <pop_off+0x3c>
    if (c->noff < 1) panic("pop_off: unbalanced");
    8020136c:	5d3c                	lw	a5,120(a0)
    8020136e:	02f05963          	blez	a5,802013a0 <pop_off+0x4c>
    c->noff--;
    80201372:	37fd                	addiw	a5,a5,-1
    80201374:	dd3c                	sw	a5,120(a0)
    if (c->noff == 0 && c->intena) intr_on();
    80201376:	eb89                	bnez	a5,80201388 <pop_off+0x34>
    80201378:	5d7c                	lw	a5,124(a0)
    8020137a:	c799                	beqz	a5,80201388 <pop_off+0x34>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    8020137c:	100027f3          	csrr	a5,sstatus
static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
    80201380:	0027e793          	ori	a5,a5,2
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    80201384:	10079073          	csrw	sstatus,a5
}
    80201388:	60a2                	ld	ra,8(sp)
    8020138a:	6402                	ld	s0,0(sp)
    8020138c:	0141                	addi	sp,sp,16
    8020138e:	8082                	ret
    if (intr_get()) panic("pop_off: interrupts already on");
    80201390:	00006517          	auipc	a0,0x6
    80201394:	0c050513          	addi	a0,a0,192 # 80207450 <etext+0x450>
    80201398:	fffff097          	auipc	ra,0xfffff
    8020139c:	218080e7          	jalr	536(ra) # 802005b0 <panic>
    if (c->noff < 1) panic("pop_off: unbalanced");
    802013a0:	00006517          	auipc	a0,0x6
    802013a4:	0d050513          	addi	a0,a0,208 # 80207470 <etext+0x470>
    802013a8:	fffff097          	auipc	ra,0xfffff
    802013ac:	208080e7          	jalr	520(ra) # 802005b0 <panic>

00000000802013b0 <release>:
{
    802013b0:	1101                	addi	sp,sp,-32
    802013b2:	ec06                	sd	ra,24(sp)
    802013b4:	e822                	sd	s0,16(sp)
    802013b6:	e426                	sd	s1,8(sp)
    802013b8:	1000                	addi	s0,sp,32
    802013ba:	84aa                	mv	s1,a0
    if (!holding(lk)) panic("release: not holding this lock");
    802013bc:	00000097          	auipc	ra,0x0
    802013c0:	ede080e7          	jalr	-290(ra) # 8020129a <holding>
    802013c4:	c115                	beqz	a0,802013e8 <release+0x38>
    lk->cpu = -1;
    802013c6:	57fd                	li	a5,-1
    802013c8:	c89c                	sw	a5,16(s1)
    __sync_synchronize();          /* fence: nothing above moves below this */
    802013ca:	0330000f          	fence	rw,rw
    __sync_lock_release(&lk->locked);
    802013ce:	0310000f          	fence	rw,w
    802013d2:	0004a023          	sw	zero,0(s1)
    pop_off();
    802013d6:	00000097          	auipc	ra,0x0
    802013da:	f7e080e7          	jalr	-130(ra) # 80201354 <pop_off>
}
    802013de:	60e2                	ld	ra,24(sp)
    802013e0:	6442                	ld	s0,16(sp)
    802013e2:	64a2                	ld	s1,8(sp)
    802013e4:	6105                	addi	sp,sp,32
    802013e6:	8082                	ret
    if (!holding(lk)) panic("release: not holding this lock");
    802013e8:	00006517          	auipc	a0,0x6
    802013ec:	0a050513          	addi	a0,a0,160 # 80207488 <etext+0x488>
    802013f0:	fffff097          	auipc	ra,0xfffff
    802013f4:	1c0080e7          	jalr	448(ra) # 802005b0 <panic>

00000000802013f8 <initsleeplock>:
 */
#include "types.h"
#include "defs.h"

void initsleeplock(struct sleeplock *lk, const char *name)
{
    802013f8:	1101                	addi	sp,sp,-32
    802013fa:	ec06                	sd	ra,24(sp)
    802013fc:	e822                	sd	s0,16(sp)
    802013fe:	e426                	sd	s1,8(sp)
    80201400:	e04a                	sd	s2,0(sp)
    80201402:	1000                	addi	s0,sp,32
    80201404:	84aa                	mv	s1,a0
    80201406:	892e                	mv	s2,a1
    initlock(&lk->lk, "sleep lock");
    80201408:	00006597          	auipc	a1,0x6
    8020140c:	0a058593          	addi	a1,a1,160 # 802074a8 <etext+0x4a8>
    80201410:	0521                	addi	a0,a0,8
    80201412:	00000097          	auipc	ra,0x0
    80201416:	e6e080e7          	jalr	-402(ra) # 80201280 <initlock>
    lk->name = name;
    8020141a:	0324b023          	sd	s2,32(s1)
    lk->locked = 0;
    8020141e:	0004a023          	sw	zero,0(s1)
    lk->pid = 0;
    80201422:	0204a423          	sw	zero,40(s1)
}
    80201426:	60e2                	ld	ra,24(sp)
    80201428:	6442                	ld	s0,16(sp)
    8020142a:	64a2                	ld	s1,8(sp)
    8020142c:	6902                	ld	s2,0(sp)
    8020142e:	6105                	addi	sp,sp,32
    80201430:	8082                	ret

0000000080201432 <acquiresleep>:

void acquiresleep(struct sleeplock *lk)
{
    80201432:	1101                	addi	sp,sp,-32
    80201434:	ec06                	sd	ra,24(sp)
    80201436:	e822                	sd	s0,16(sp)
    80201438:	e426                	sd	s1,8(sp)
    8020143a:	e04a                	sd	s2,0(sp)
    8020143c:	1000                	addi	s0,sp,32
    8020143e:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    80201440:	00850913          	addi	s2,a0,8
    80201444:	854a                	mv	a0,s2
    80201446:	00000097          	auipc	ra,0x0
    8020144a:	eba080e7          	jalr	-326(ra) # 80201300 <acquire>
    while (lk->locked)
    8020144e:	409c                	lw	a5,0(s1)
    80201450:	cb89                	beqz	a5,80201462 <acquiresleep+0x30>
        sleep(lk, &lk->lk);       /* releases lk->lk while asleep */
    80201452:	85ca                	mv	a1,s2
    80201454:	8526                	mv	a0,s1
    80201456:	00001097          	auipc	ra,0x1
    8020145a:	8fa080e7          	jalr	-1798(ra) # 80201d50 <sleep>
    while (lk->locked)
    8020145e:	409c                	lw	a5,0(s1)
    80201460:	fbed                	bnez	a5,80201452 <acquiresleep+0x20>
    lk->locked = 1;
    80201462:	4785                	li	a5,1
    80201464:	c09c                	sw	a5,0(s1)
    lk->pid = myproc()->pid;
    80201466:	00000097          	auipc	ra,0x0
    8020146a:	278080e7          	jalr	632(ra) # 802016de <myproc>
    8020146e:	591c                	lw	a5,48(a0)
    80201470:	d49c                	sw	a5,40(s1)
    release(&lk->lk);
    80201472:	854a                	mv	a0,s2
    80201474:	00000097          	auipc	ra,0x0
    80201478:	f3c080e7          	jalr	-196(ra) # 802013b0 <release>
}
    8020147c:	60e2                	ld	ra,24(sp)
    8020147e:	6442                	ld	s0,16(sp)
    80201480:	64a2                	ld	s1,8(sp)
    80201482:	6902                	ld	s2,0(sp)
    80201484:	6105                	addi	sp,sp,32
    80201486:	8082                	ret

0000000080201488 <releasesleep>:

void releasesleep(struct sleeplock *lk)
{
    80201488:	1101                	addi	sp,sp,-32
    8020148a:	ec06                	sd	ra,24(sp)
    8020148c:	e822                	sd	s0,16(sp)
    8020148e:	e426                	sd	s1,8(sp)
    80201490:	e04a                	sd	s2,0(sp)
    80201492:	1000                	addi	s0,sp,32
    80201494:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    80201496:	00850913          	addi	s2,a0,8
    8020149a:	854a                	mv	a0,s2
    8020149c:	00000097          	auipc	ra,0x0
    802014a0:	e64080e7          	jalr	-412(ra) # 80201300 <acquire>
    lk->locked = 0;
    802014a4:	0004a023          	sw	zero,0(s1)
    lk->pid = 0;
    802014a8:	0204a423          	sw	zero,40(s1)
    wakeup(lk);
    802014ac:	8526                	mv	a0,s1
    802014ae:	00001097          	auipc	ra,0x1
    802014b2:	a22080e7          	jalr	-1502(ra) # 80201ed0 <wakeup>
    release(&lk->lk);
    802014b6:	854a                	mv	a0,s2
    802014b8:	00000097          	auipc	ra,0x0
    802014bc:	ef8080e7          	jalr	-264(ra) # 802013b0 <release>
}
    802014c0:	60e2                	ld	ra,24(sp)
    802014c2:	6442                	ld	s0,16(sp)
    802014c4:	64a2                	ld	s1,8(sp)
    802014c6:	6902                	ld	s2,0(sp)
    802014c8:	6105                	addi	sp,sp,32
    802014ca:	8082                	ret

00000000802014cc <holdingsleep>:

int holdingsleep(struct sleeplock *lk)
{
    802014cc:	7179                	addi	sp,sp,-48
    802014ce:	f406                	sd	ra,40(sp)
    802014d0:	f022                	sd	s0,32(sp)
    802014d2:	ec26                	sd	s1,24(sp)
    802014d4:	e84a                	sd	s2,16(sp)
    802014d6:	1800                	addi	s0,sp,48
    802014d8:	84aa                	mv	s1,a0
    acquire(&lk->lk);
    802014da:	00850913          	addi	s2,a0,8
    802014de:	854a                	mv	a0,s2
    802014e0:	00000097          	auipc	ra,0x0
    802014e4:	e20080e7          	jalr	-480(ra) # 80201300 <acquire>
    int r = lk->locked && (lk->pid == myproc()->pid);
    802014e8:	409c                	lw	a5,0(s1)
    802014ea:	ef91                	bnez	a5,80201506 <holdingsleep+0x3a>
    802014ec:	4481                	li	s1,0
    release(&lk->lk);
    802014ee:	854a                	mv	a0,s2
    802014f0:	00000097          	auipc	ra,0x0
    802014f4:	ec0080e7          	jalr	-320(ra) # 802013b0 <release>
    return r;
}
    802014f8:	8526                	mv	a0,s1
    802014fa:	70a2                	ld	ra,40(sp)
    802014fc:	7402                	ld	s0,32(sp)
    802014fe:	64e2                	ld	s1,24(sp)
    80201500:	6942                	ld	s2,16(sp)
    80201502:	6145                	addi	sp,sp,48
    80201504:	8082                	ret
    80201506:	e44e                	sd	s3,8(sp)
    int r = lk->locked && (lk->pid == myproc()->pid);
    80201508:	0284a983          	lw	s3,40(s1)
    8020150c:	00000097          	auipc	ra,0x0
    80201510:	1d2080e7          	jalr	466(ra) # 802016de <myproc>
    80201514:	5904                	lw	s1,48(a0)
    80201516:	413484b3          	sub	s1,s1,s3
    8020151a:	0014b493          	seqz	s1,s1
    8020151e:	69a2                	ld	s3,8(sp)
    80201520:	b7f9                	j	802014ee <holdingsleep+0x22>

0000000080201522 <freeproc>:
        p->kstack = 0;
    }
}

static void freeproc(struct proc *p)
{
    80201522:	1101                	addi	sp,sp,-32
    80201524:	ec06                	sd	ra,24(sp)
    80201526:	e822                	sd	s0,16(sp)
    80201528:	e426                	sd	s1,8(sp)
    8020152a:	1000                	addi	s0,sp,32
    8020152c:	84aa                	mv	s1,a0
    if (p->tf) pfree((void *)p->tf);
    8020152e:	6d28                	ld	a0,88(a0)
    80201530:	c509                	beqz	a0,8020153a <freeproc+0x18>
    80201532:	00000097          	auipc	ra,0x0
    80201536:	c4c080e7          	jalr	-948(ra) # 8020117e <pfree>
    p->tf = 0;
    8020153a:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable) uvmfree(p->pagetable, p->sz);
    8020153e:	68a8                	ld	a0,80(s1)
    80201540:	c511                	beqz	a0,8020154c <freeproc+0x2a>
    80201542:	64ac                	ld	a1,72(s1)
    80201544:	00002097          	auipc	ra,0x2
    80201548:	88e080e7          	jalr	-1906(ra) # 80202dd2 <uvmfree>
    p->pagetable = 0;
    8020154c:	0404b823          	sd	zero,80(s1)
    p->kstack = 0;              /* statically allocated - nothing to free */
    80201550:	0404b023          	sd	zero,64(s1)
    p->sz = 0; p->pid = 0; p->parent = 0;
    80201554:	0404b423          	sd	zero,72(s1)
    80201558:	0204a823          	sw	zero,48(s1)
    8020155c:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0; p->chan = 0; p->killed = 0; p->xstate = 0;
    80201560:	14048c23          	sb	zero,344(s1)
    80201564:	0204b023          	sd	zero,32(s1)
    80201568:	0204a423          	sw	zero,40(s1)
    8020156c:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80201570:	0004ac23          	sw	zero,24(s1)
}
    80201574:	60e2                	ld	ra,24(sp)
    80201576:	6442                	ld	s0,16(sp)
    80201578:	64a2                	ld	s1,8(sp)
    8020157a:	6105                	addi	sp,sp,32
    8020157c:	8082                	ret

000000008020157e <allocproc>:
    }
    usertrapret();
}

static struct proc *allocproc(void)
{
    8020157e:	7179                	addi	sp,sp,-48
    80201580:	f406                	sd	ra,40(sp)
    80201582:	f022                	sd	s0,32(sp)
    80201584:	ec26                	sd	s1,24(sp)
    80201586:	e84a                	sd	s2,16(sp)
    80201588:	1800                	addi	s0,sp,48
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
    8020158a:	0012a497          	auipc	s1,0x12a
    8020158e:	a7648493          	addi	s1,s1,-1418 # 8032b000 <proc>
    80201592:	0012f917          	auipc	s2,0x12f
    80201596:	46e90913          	addi	s2,s2,1134 # 80330a00 <tickslock>
        acquire(&p->lock);
    8020159a:	8526                	mv	a0,s1
    8020159c:	00000097          	auipc	ra,0x0
    802015a0:	d64080e7          	jalr	-668(ra) # 80201300 <acquire>
        if (p->state == UNUSED) goto found;
    802015a4:	4c9c                	lw	a5,24(s1)
    802015a6:	cf81                	beqz	a5,802015be <allocproc+0x40>
        release(&p->lock);
    802015a8:	8526                	mv	a0,s1
    802015aa:	00000097          	auipc	ra,0x0
    802015ae:	e06080e7          	jalr	-506(ra) # 802013b0 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    802015b2:	16848493          	addi	s1,s1,360
    802015b6:	ff2492e3          	bne	s1,s2,8020159a <allocproc+0x1c>
    }
    return 0;
    802015ba:	4481                	li	s1,0
    802015bc:	a875                	j	80201678 <allocproc+0xfa>
    802015be:	e44e                	sd	s3,8(sp)
    acquire(&pid_lock);
    802015c0:	00029997          	auipc	s3,0x29
    802015c4:	a4098993          	addi	s3,s3,-1472 # 8022a000 <pid_lock>
    802015c8:	854e                	mv	a0,s3
    802015ca:	00000097          	auipc	ra,0x0
    802015ce:	d36080e7          	jalr	-714(ra) # 80201300 <acquire>
    int pid = nextpid++;
    802015d2:	00007797          	auipc	a5,0x7
    802015d6:	a3278793          	addi	a5,a5,-1486 # 80208004 <nextpid>
    802015da:	0007a903          	lw	s2,0(a5)
    802015de:	0019071b          	addiw	a4,s2,1
    802015e2:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    802015e4:	854e                	mv	a0,s3
    802015e6:	00000097          	auipc	ra,0x0
    802015ea:	dca080e7          	jalr	-566(ra) # 802013b0 <release>

found:
    p->pid    = allocpid();
    802015ee:	0324a823          	sw	s2,48(s1)
    p->state  = USED;
    802015f2:	4785                	li	a5,1
    802015f4:	cc9c                	sw	a5,24(s1)
    p->killed = 0;
    802015f6:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    802015fa:	0204a623          	sw	zero,44(s1)
    p->chan   = 0;
    802015fe:	0204b023          	sd	zero,32(s1)

    if ((p->tf = (struct trapframe *)palloc()) == 0) { freeproc(p); release(&p->lock); return 0; }
    80201602:	00000097          	auipc	ra,0x0
    80201606:	a6c080e7          	jalr	-1428(ra) # 8020106e <palloc>
    8020160a:	892a                	mv	s2,a0
    8020160c:	eca8                	sd	a0,88(s1)
    8020160e:	cd25                	beqz	a0,80201686 <allocproc+0x108>

    /* Contiguous, statically reserved. See the note at the top of this file. */
    p->kstack = (uint64)kstacks[p - proc];
    80201610:	0012a797          	auipc	a5,0x12a
    80201614:	9f078793          	addi	a5,a5,-1552 # 8032b000 <proc>
    80201618:	40f487b3          	sub	a5,s1,a5
    8020161c:	878d                	srai	a5,a5,0x3
    8020161e:	a4fa56b7          	lui	a3,0xa4fa5
    80201622:	fa568693          	addi	a3,a3,-91 # ffffffffa4fa4fa5 <uart+0xffffffff24c65f75>
    80201626:	4fa50737          	lui	a4,0x4fa50
    8020162a:	a5070713          	addi	a4,a4,-1456 # 4fa4fa50 <_entry-0x307b05b0>
    8020162e:	1702                	slli	a4,a4,0x20
    80201630:	9736                	add	a4,a4,a3
    80201632:	02e787b3          	mul	a5,a5,a4
    80201636:	07ba                	slli	a5,a5,0xe
    80201638:	0002a717          	auipc	a4,0x2a
    8020163c:	9c870713          	addi	a4,a4,-1592 # 8022b000 <kstacks>
    80201640:	97ba                	add	a5,a5,a4
    80201642:	e0bc                	sd	a5,64(s1)

    p->pagetable = uvmcreate();
    80201644:	00001097          	auipc	ra,0x1
    80201648:	6ce080e7          	jalr	1742(ra) # 80202d12 <uvmcreate>
    8020164c:	892a                	mv	s2,a0
    8020164e:	e8a8                	sd	a0,80(s1)
    if (!p->pagetable) { freeproc(p); release(&p->lock); return 0; }
    80201650:	c921                	beqz	a0,802016a0 <allocproc+0x122>

    memset(&p->context, 0, sizeof(p->context));
    80201652:	07000613          	li	a2,112
    80201656:	4581                	li	a1,0
    80201658:	06048513          	addi	a0,s1,96
    8020165c:	fffff097          	auipc	ra,0xfffff
    80201660:	ffa080e7          	jalr	-6(ra) # 80200656 <memset>
    p->context.ra = (uint64)forkret;
    80201664:	00000797          	auipc	a5,0x0
    80201668:	0b678793          	addi	a5,a5,182 # 8020171a <forkret>
    8020166c:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + KSTACK_SIZE;
    8020166e:	60bc                	ld	a5,64(s1)
    80201670:	6711                	lui	a4,0x4
    80201672:	97ba                	add	a5,a5,a4
    80201674:	f4bc                	sd	a5,104(s1)
    80201676:	69a2                	ld	s3,8(sp)
    return p;
}
    80201678:	8526                	mv	a0,s1
    8020167a:	70a2                	ld	ra,40(sp)
    8020167c:	7402                	ld	s0,32(sp)
    8020167e:	64e2                	ld	s1,24(sp)
    80201680:	6942                	ld	s2,16(sp)
    80201682:	6145                	addi	sp,sp,48
    80201684:	8082                	ret
    if ((p->tf = (struct trapframe *)palloc()) == 0) { freeproc(p); release(&p->lock); return 0; }
    80201686:	8526                	mv	a0,s1
    80201688:	00000097          	auipc	ra,0x0
    8020168c:	e9a080e7          	jalr	-358(ra) # 80201522 <freeproc>
    80201690:	8526                	mv	a0,s1
    80201692:	00000097          	auipc	ra,0x0
    80201696:	d1e080e7          	jalr	-738(ra) # 802013b0 <release>
    8020169a:	84ca                	mv	s1,s2
    8020169c:	69a2                	ld	s3,8(sp)
    8020169e:	bfe9                	j	80201678 <allocproc+0xfa>
    if (!p->pagetable) { freeproc(p); release(&p->lock); return 0; }
    802016a0:	8526                	mv	a0,s1
    802016a2:	00000097          	auipc	ra,0x0
    802016a6:	e80080e7          	jalr	-384(ra) # 80201522 <freeproc>
    802016aa:	8526                	mv	a0,s1
    802016ac:	00000097          	auipc	ra,0x0
    802016b0:	d04080e7          	jalr	-764(ra) # 802013b0 <release>
    802016b4:	84ca                	mv	s1,s2
    802016b6:	69a2                	ld	s3,8(sp)
    802016b8:	b7c1                	j	80201678 <allocproc+0xfa>

00000000802016ba <mycpu>:
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    802016ba:	1141                	addi	sp,sp,-16
    802016bc:	e406                	sd	ra,8(sp)
    802016be:	e022                	sd	s0,0(sp)
    802016c0:	0800                	addi	s0,sp,16
    802016c2:	00005097          	auipc	ra,0x5
    802016c6:	9da080e7          	jalr	-1574(ra) # 8020609c <hal_hart_id>
    802016ca:	051e                	slli	a0,a0,0x7
    802016cc:	00029797          	auipc	a5,0x29
    802016d0:	94c78793          	addi	a5,a5,-1716 # 8022a018 <cpus>
    802016d4:	953e                	add	a0,a0,a5
    802016d6:	60a2                	ld	ra,8(sp)
    802016d8:	6402                	ld	s0,0(sp)
    802016da:	0141                	addi	sp,sp,16
    802016dc:	8082                	ret

00000000802016de <myproc>:
{
    802016de:	1101                	addi	sp,sp,-32
    802016e0:	ec06                	sd	ra,24(sp)
    802016e2:	e822                	sd	s0,16(sp)
    802016e4:	e426                	sd	s1,8(sp)
    802016e6:	1000                	addi	s0,sp,32
    push_off();
    802016e8:	00000097          	auipc	ra,0x0
    802016ec:	be0080e7          	jalr	-1056(ra) # 802012c8 <push_off>
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    802016f0:	00005097          	auipc	ra,0x5
    802016f4:	9ac080e7          	jalr	-1620(ra) # 8020609c <hal_hart_id>
    struct proc *p = mycpu()->proc;
    802016f8:	051e                	slli	a0,a0,0x7
    802016fa:	00029797          	auipc	a5,0x29
    802016fe:	90678793          	addi	a5,a5,-1786 # 8022a000 <pid_lock>
    80201702:	97aa                	add	a5,a5,a0
    80201704:	6f84                	ld	s1,24(a5)
    pop_off();
    80201706:	00000097          	auipc	ra,0x0
    8020170a:	c4e080e7          	jalr	-946(ra) # 80201354 <pop_off>
}
    8020170e:	8526                	mv	a0,s1
    80201710:	60e2                	ld	ra,24(sp)
    80201712:	6442                	ld	s0,16(sp)
    80201714:	64a2                	ld	s1,8(sp)
    80201716:	6105                	addi	sp,sp,32
    80201718:	8082                	ret

000000008020171a <forkret>:
{
    8020171a:	1101                	addi	sp,sp,-32
    8020171c:	ec06                	sd	ra,24(sp)
    8020171e:	e822                	sd	s0,16(sp)
    80201720:	1000                	addi	s0,sp,32
    release(&myproc()->lock);
    80201722:	00000097          	auipc	ra,0x0
    80201726:	fbc080e7          	jalr	-68(ra) # 802016de <myproc>
    8020172a:	00000097          	auipc	ra,0x0
    8020172e:	c86080e7          	jalr	-890(ra) # 802013b0 <release>
    if (first) {
    80201732:	00007797          	auipc	a5,0x7
    80201736:	8ce7a783          	lw	a5,-1842(a5) # 80208000 <first.1>
    8020173a:	eb89                	bnez	a5,8020174c <forkret+0x32>
    usertrapret();
    8020173c:	00001097          	auipc	ra,0x1
    80201740:	e34080e7          	jalr	-460(ra) # 80202570 <usertrapret>
}
    80201744:	60e2                	ld	ra,24(sp)
    80201746:	6442                	ld	s0,16(sp)
    80201748:	6105                	addi	sp,sp,32
    8020174a:	8082                	ret
    8020174c:	e426                	sd	s1,8(sp)
        first = 0;
    8020174e:	00007797          	auipc	a5,0x7
    80201752:	8a07a923          	sw	zero,-1870(a5) # 80208000 <first.1>
        fsinit(ROOTDEV);
    80201756:	4501                	li	a0,0
    80201758:	00003097          	auipc	ra,0x3
    8020175c:	536080e7          	jalr	1334(ra) # 80204c8e <fsinit>
        myproc()->cwd = namei("/");
    80201760:	00000097          	auipc	ra,0x0
    80201764:	f7e080e7          	jalr	-130(ra) # 802016de <myproc>
    80201768:	84aa                	mv	s1,a0
    8020176a:	00006517          	auipc	a0,0x6
    8020176e:	d4e50513          	addi	a0,a0,-690 # 802074b8 <etext+0x4b8>
    80201772:	00004097          	auipc	ra,0x4
    80201776:	0ba080e7          	jalr	186(ra) # 8020582c <namei>
    8020177a:	14a4b823          	sd	a0,336(s1)
        __sync_synchronize();
    8020177e:	0330000f          	fence	rw,rw
    80201782:	64a2                	ld	s1,8(sp)
    80201784:	bf65                	j	8020173c <forkret+0x22>

0000000080201786 <procinit>:
{
    80201786:	7179                	addi	sp,sp,-48
    80201788:	f406                	sd	ra,40(sp)
    8020178a:	f022                	sd	s0,32(sp)
    8020178c:	ec26                	sd	s1,24(sp)
    8020178e:	e84a                	sd	s2,16(sp)
    80201790:	e44e                	sd	s3,8(sp)
    80201792:	1800                	addi	s0,sp,48
    initlock(&pid_lock,  "nextpid");
    80201794:	00006597          	auipc	a1,0x6
    80201798:	d2c58593          	addi	a1,a1,-724 # 802074c0 <etext+0x4c0>
    8020179c:	00029517          	auipc	a0,0x29
    802017a0:	86450513          	addi	a0,a0,-1948 # 8022a000 <pid_lock>
    802017a4:	00000097          	auipc	ra,0x0
    802017a8:	adc080e7          	jalr	-1316(ra) # 80201280 <initlock>
    initlock(&wait_lock, "wait_lock");
    802017ac:	00006597          	auipc	a1,0x6
    802017b0:	d1c58593          	addi	a1,a1,-740 # 802074c8 <etext+0x4c8>
    802017b4:	00029517          	auipc	a0,0x29
    802017b8:	c6450513          	addi	a0,a0,-924 # 8022a418 <wait_lock>
    802017bc:	00000097          	auipc	ra,0x0
    802017c0:	ac4080e7          	jalr	-1340(ra) # 80201280 <initlock>
    initlock(&tickslock, "time");
    802017c4:	00006597          	auipc	a1,0x6
    802017c8:	d1458593          	addi	a1,a1,-748 # 802074d8 <etext+0x4d8>
    802017cc:	0012f517          	auipc	a0,0x12f
    802017d0:	23450513          	addi	a0,a0,564 # 80330a00 <tickslock>
    802017d4:	00000097          	auipc	ra,0x0
    802017d8:	aac080e7          	jalr	-1364(ra) # 80201280 <initlock>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802017dc:	0012a497          	auipc	s1,0x12a
    802017e0:	82448493          	addi	s1,s1,-2012 # 8032b000 <proc>
        initlock(&p->lock, "proc");
    802017e4:	00006997          	auipc	s3,0x6
    802017e8:	cfc98993          	addi	s3,s3,-772 # 802074e0 <etext+0x4e0>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802017ec:	0012f917          	auipc	s2,0x12f
    802017f0:	21490913          	addi	s2,s2,532 # 80330a00 <tickslock>
        initlock(&p->lock, "proc");
    802017f4:	85ce                	mv	a1,s3
    802017f6:	8526                	mv	a0,s1
    802017f8:	00000097          	auipc	ra,0x0
    802017fc:	a88080e7          	jalr	-1400(ra) # 80201280 <initlock>
        p->state  = UNUSED;
    80201800:	0004ac23          	sw	zero,24(s1)
        p->kstack = 0;
    80201804:	0404b023          	sd	zero,64(s1)
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201808:	16848493          	addi	s1,s1,360
    8020180c:	ff2494e3          	bne	s1,s2,802017f4 <procinit+0x6e>
}
    80201810:	70a2                	ld	ra,40(sp)
    80201812:	7402                	ld	s0,32(sp)
    80201814:	64e2                	ld	s1,24(sp)
    80201816:	6942                	ld	s2,16(sp)
    80201818:	69a2                	ld	s3,8(sp)
    8020181a:	6145                	addi	sp,sp,48
    8020181c:	8082                	ret

000000008020181e <userinit>:

/* --- the very first user process, built by hand --- */
extern char _binary_user_initcode_start[], _binary_user_initcode_end[];

void userinit(void)
{
    8020181e:	7179                	addi	sp,sp,-48
    80201820:	f406                	sd	ra,40(sp)
    80201822:	f022                	sd	s0,32(sp)
    80201824:	ec26                	sd	s1,24(sp)
    80201826:	e84a                	sd	s2,16(sp)
    80201828:	e44e                	sd	s3,8(sp)
    8020182a:	1800                	addi	s0,sp,48
    struct proc *p = allocproc();
    8020182c:	00000097          	auipc	ra,0x0
    80201830:	d52080e7          	jalr	-686(ra) # 8020157e <allocproc>
    if (!p) panic("userinit: allocproc failed");
    80201834:	c569                	beqz	a0,802018fe <userinit+0xe0>
    80201836:	84aa                	mv	s1,a0
    initproc = p;
    80201838:	0013d797          	auipc	a5,0x13d
    8020183c:	7ca7bc23          	sd	a0,2008(a5) # 8033f010 <initproc>

    uint64 sz = (uint64)(_binary_user_initcode_end - _binary_user_initcode_start);
    80201840:	00006997          	auipc	s3,0x6
    80201844:	73898993          	addi	s3,s3,1848 # 80207f78 <_binary_user_initcode_end>
    80201848:	00006797          	auipc	a5,0x6
    8020184c:	6f878793          	addi	a5,a5,1784 # 80207f40 <_binary_user_initcode_start>
    80201850:	40f989b3          	sub	s3,s3,a5
    if (sz > PGSIZE) panic("userinit: initcode too big");
    80201854:	6785                	lui	a5,0x1
    80201856:	0b37ec63          	bltu	a5,s3,8020190e <userinit+0xf0>

    char *mem = palloc();
    8020185a:	00000097          	auipc	ra,0x0
    8020185e:	814080e7          	jalr	-2028(ra) # 8020106e <palloc>
    80201862:	892a                	mv	s2,a0
    memset(mem, 0, PGSIZE);
    80201864:	6605                	lui	a2,0x1
    80201866:	4581                	li	a1,0
    80201868:	fffff097          	auipc	ra,0xfffff
    8020186c:	dee080e7          	jalr	-530(ra) # 80200656 <memset>
    memmove(mem, _binary_user_initcode_start, sz);
    80201870:	864e                	mv	a2,s3
    80201872:	00006597          	auipc	a1,0x6
    80201876:	6ce58593          	addi	a1,a1,1742 # 80207f40 <_binary_user_initcode_start>
    8020187a:	854a                	mv	a0,s2
    8020187c:	fffff097          	auipc	ra,0xfffff
    80201880:	dfa080e7          	jalr	-518(ra) # 80200676 <memmove>
    mappages(p->pagetable, 0, PGSIZE, (uint64)mem, PTE_R | PTE_W | PTE_X | PTE_U);
    80201884:	4779                	li	a4,30
    80201886:	86ca                	mv	a3,s2
    80201888:	6605                	lui	a2,0x1
    8020188a:	4581                	li	a1,0
    8020188c:	68a8                	ld	a0,80(s1)
    8020188e:	00001097          	auipc	ra,0x1
    80201892:	25a080e7          	jalr	602(ra) # 80202ae8 <mappages>

    char *stack = palloc();
    80201896:	fffff097          	auipc	ra,0xfffff
    8020189a:	7d8080e7          	jalr	2008(ra) # 8020106e <palloc>
    8020189e:	892a                	mv	s2,a0
    memset(stack, 0, PGSIZE);
    802018a0:	6605                	lui	a2,0x1
    802018a2:	4581                	li	a1,0
    802018a4:	fffff097          	auipc	ra,0xfffff
    802018a8:	db2080e7          	jalr	-590(ra) # 80200656 <memset>
    mappages(p->pagetable, PGSIZE, PGSIZE, (uint64)stack, PTE_R | PTE_W | PTE_U);
    802018ac:	4759                	li	a4,22
    802018ae:	86ca                	mv	a3,s2
    802018b0:	6605                	lui	a2,0x1
    802018b2:	85b2                	mv	a1,a2
    802018b4:	68a8                	ld	a0,80(s1)
    802018b6:	00001097          	auipc	ra,0x1
    802018ba:	232080e7          	jalr	562(ra) # 80202ae8 <mappages>

    p->sz       = 2 * PGSIZE;
    802018be:	6789                	lui	a5,0x2
    802018c0:	e4bc                	sd	a5,72(s1)
    p->tf->epc  = 0;                    /* start at the first byte of initcode */
    802018c2:	6cb8                	ld	a4,88(s1)
    802018c4:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x801fbfe8>
    p->tf->sp   = 2 * PGSIZE;           /* stack grows down from the top       */
    802018c8:	6cb8                	ld	a4,88(s1)
    802018ca:	fb1c                	sd	a5,48(a4)
    strncpy(p->name, "initcode", sizeof(p->name));
    802018cc:	4641                	li	a2,16
    802018ce:	00006597          	auipc	a1,0x6
    802018d2:	c5a58593          	addi	a1,a1,-934 # 80207528 <etext+0x528>
    802018d6:	15848513          	addi	a0,s1,344
    802018da:	fffff097          	auipc	ra,0xfffff
    802018de:	e4e080e7          	jalr	-434(ra) # 80200728 <strncpy>
    /* p->cwd is set by forkret once the filesystem is initialized. */
    p->state    = RUNNABLE;
    802018e2:	478d                	li	a5,3
    802018e4:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    802018e6:	8526                	mv	a0,s1
    802018e8:	00000097          	auipc	ra,0x0
    802018ec:	ac8080e7          	jalr	-1336(ra) # 802013b0 <release>
}
    802018f0:	70a2                	ld	ra,40(sp)
    802018f2:	7402                	ld	s0,32(sp)
    802018f4:	64e2                	ld	s1,24(sp)
    802018f6:	6942                	ld	s2,16(sp)
    802018f8:	69a2                	ld	s3,8(sp)
    802018fa:	6145                	addi	sp,sp,48
    802018fc:	8082                	ret
    if (!p) panic("userinit: allocproc failed");
    802018fe:	00006517          	auipc	a0,0x6
    80201902:	bea50513          	addi	a0,a0,-1046 # 802074e8 <etext+0x4e8>
    80201906:	fffff097          	auipc	ra,0xfffff
    8020190a:	caa080e7          	jalr	-854(ra) # 802005b0 <panic>
    if (sz > PGSIZE) panic("userinit: initcode too big");
    8020190e:	00006517          	auipc	a0,0x6
    80201912:	bfa50513          	addi	a0,a0,-1030 # 80207508 <etext+0x508>
    80201916:	fffff097          	auipc	ra,0xfffff
    8020191a:	c9a080e7          	jalr	-870(ra) # 802005b0 <panic>

000000008020191e <growproc>:

int growproc(int n)
{
    8020191e:	715d                	addi	sp,sp,-80
    80201920:	e486                	sd	ra,72(sp)
    80201922:	e0a2                	sd	s0,64(sp)
    80201924:	f052                	sd	s4,32(sp)
    80201926:	ec56                	sd	s5,24(sp)
    80201928:	e85a                	sd	s6,16(sp)
    8020192a:	0880                	addi	s0,sp,80
    8020192c:	8aaa                	mv	s5,a0
    struct proc *p = myproc();
    8020192e:	00000097          	auipc	ra,0x0
    80201932:	db0080e7          	jalr	-592(ra) # 802016de <myproc>
    80201936:	8a2a                	mv	s4,a0
    uint64 sz = p->sz;
    80201938:	04853b03          	ld	s6,72(a0)

    if (n > 0) {
    8020193c:	07505f63          	blez	s5,802019ba <growproc+0x9c>
    80201940:	f84a                	sd	s2,48(sp)
    80201942:	e45e                	sd	s7,8(sp)
        for (uint64 a = PGROUNDUP(sz); a < sz + n; a += PGSIZE) {
    80201944:	6905                	lui	s2,0x1
    80201946:	197d                	addi	s2,s2,-1 # fff <_entry-0x801ff001>
    80201948:	995a                	add	s2,s2,s6
    8020194a:	77fd                	lui	a5,0xfffff
    8020194c:	00f97933          	and	s2,s2,a5
    80201950:	016a8bb3          	add	s7,s5,s6
    80201954:	0b797963          	bgeu	s2,s7,80201a06 <growproc+0xe8>
    80201958:	fc26                	sd	s1,56(sp)
    8020195a:	f44e                	sd	s3,40(sp)
    8020195c:	e062                	sd	s8,0(sp)
            char *mem = palloc();
            if (!mem) return -1;
            memset(mem, 0, PGSIZE);
    8020195e:	6985                	lui	s3,0x1
            if (mappages(p->pagetable, a, PGSIZE, (uint64)mem,
    80201960:	4c59                	li	s8,22
            char *mem = palloc();
    80201962:	fffff097          	auipc	ra,0xfffff
    80201966:	70c080e7          	jalr	1804(ra) # 8020106e <palloc>
    8020196a:	84aa                	mv	s1,a0
            if (!mem) return -1;
    8020196c:	c145                	beqz	a0,80201a0c <growproc+0xee>
            memset(mem, 0, PGSIZE);
    8020196e:	864e                	mv	a2,s3
    80201970:	4581                	li	a1,0
    80201972:	fffff097          	auipc	ra,0xfffff
    80201976:	ce4080e7          	jalr	-796(ra) # 80200656 <memset>
            if (mappages(p->pagetable, a, PGSIZE, (uint64)mem,
    8020197a:	8762                	mv	a4,s8
    8020197c:	86a6                	mv	a3,s1
    8020197e:	864e                	mv	a2,s3
    80201980:	85ca                	mv	a1,s2
    80201982:	050a3503          	ld	a0,80(s4)
    80201986:	00001097          	auipc	ra,0x1
    8020198a:	162080e7          	jalr	354(ra) # 80202ae8 <mappages>
    8020198e:	e911                	bnez	a0,802019a2 <growproc+0x84>
        for (uint64 a = PGROUNDUP(sz); a < sz + n; a += PGSIZE) {
    80201990:	994e                	add	s2,s2,s3
    80201992:	fd7968e3          	bltu	s2,s7,80201962 <growproc+0x44>
    80201996:	74e2                	ld	s1,56(sp)
    80201998:	7942                	ld	s2,48(sp)
    8020199a:	79a2                	ld	s3,40(sp)
    8020199c:	6ba2                	ld	s7,8(sp)
    8020199e:	6c02                	ld	s8,0(sp)
    802019a0:	a839                	j	802019be <growproc+0xa0>
                         PTE_R | PTE_W | PTE_U) != 0) {
                pfree(mem);
    802019a2:	8526                	mv	a0,s1
    802019a4:	fffff097          	auipc	ra,0xfffff
    802019a8:	7da080e7          	jalr	2010(ra) # 8020117e <pfree>
                return -1;
    802019ac:	557d                	li	a0,-1
    802019ae:	74e2                	ld	s1,56(sp)
    802019b0:	7942                	ld	s2,48(sp)
    802019b2:	79a2                	ld	s3,40(sp)
    802019b4:	6ba2                	ld	s7,8(sp)
    802019b6:	6c02                	ld	s8,0(sp)
    802019b8:	a039                	j	802019c6 <growproc+0xa8>
            }
        }
    } else if (n < 0) {
    802019ba:	000acd63          	bltz	s5,802019d4 <growproc+0xb6>
                     (PGROUNDUP(sz) - PGROUNDUP(newsz)) / PGSIZE, 1);
        sz = newsz;
        p->sz = sz;
        return 0;
    }
    p->sz = sz + n;
    802019be:	9ada                	add	s5,s5,s6
    802019c0:	055a3423          	sd	s5,72(s4)
    return 0;
    802019c4:	4501                	li	a0,0
}
    802019c6:	60a6                	ld	ra,72(sp)
    802019c8:	6406                	ld	s0,64(sp)
    802019ca:	7a02                	ld	s4,32(sp)
    802019cc:	6ae2                	ld	s5,24(sp)
    802019ce:	6b42                	ld	s6,16(sp)
    802019d0:	6161                	addi	sp,sp,80
    802019d2:	8082                	ret
        uint64 newsz = sz + n;
    802019d4:	9ada                	add	s5,s5,s6
        if (PGROUNDUP(newsz) < PGROUNDUP(sz))
    802019d6:	6785                	lui	a5,0x1
    802019d8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x801ff001>
    802019da:	00fa85b3          	add	a1,s5,a5
    802019de:	777d                	lui	a4,0xfffff
    802019e0:	8df9                	and	a1,a1,a4
    802019e2:	97da                	add	a5,a5,s6
    802019e4:	8ff9                	and	a5,a5,a4
    802019e6:	00f5e663          	bltu	a1,a5,802019f2 <growproc+0xd4>
        p->sz = sz;
    802019ea:	055a3423          	sd	s5,72(s4)
        return 0;
    802019ee:	4501                	li	a0,0
    802019f0:	bfd9                	j	802019c6 <growproc+0xa8>
                     (PGROUNDUP(sz) - PGROUNDUP(newsz)) / PGSIZE, 1);
    802019f2:	8f8d                	sub	a5,a5,a1
            uvmunmap(p->pagetable, PGROUNDUP(newsz),
    802019f4:	4685                	li	a3,1
    802019f6:	00c7d613          	srli	a2,a5,0xc
    802019fa:	6928                	ld	a0,80(a0)
    802019fc:	00001097          	auipc	ra,0x1
    80201a00:	362080e7          	jalr	866(ra) # 80202d5e <uvmunmap>
    80201a04:	b7dd                	j	802019ea <growproc+0xcc>
    80201a06:	7942                	ld	s2,48(sp)
    80201a08:	6ba2                	ld	s7,8(sp)
    80201a0a:	bf55                	j	802019be <growproc+0xa0>
            if (!mem) return -1;
    80201a0c:	557d                	li	a0,-1
    80201a0e:	74e2                	ld	s1,56(sp)
    80201a10:	7942                	ld	s2,48(sp)
    80201a12:	79a2                	ld	s3,40(sp)
    80201a14:	6ba2                	ld	s7,8(sp)
    80201a16:	6c02                	ld	s8,0(sp)
    80201a18:	b77d                	j	802019c6 <growproc+0xa8>

0000000080201a1a <fork>:

int fork(void)
{
    80201a1a:	7139                	addi	sp,sp,-64
    80201a1c:	fc06                	sd	ra,56(sp)
    80201a1e:	f822                	sd	s0,48(sp)
    80201a20:	f04a                	sd	s2,32(sp)
    80201a22:	e456                	sd	s5,8(sp)
    80201a24:	0080                	addi	s0,sp,64
    struct proc *parent = myproc();
    80201a26:	00000097          	auipc	ra,0x0
    80201a2a:	cb8080e7          	jalr	-840(ra) # 802016de <myproc>
    80201a2e:	8aaa                	mv	s5,a0
    struct proc *np = allocproc();
    80201a30:	00000097          	auipc	ra,0x0
    80201a34:	b4e080e7          	jalr	-1202(ra) # 8020157e <allocproc>
    if (!np) return -1;
    80201a38:	12050063          	beqz	a0,80201b58 <fork+0x13e>
    80201a3c:	e852                	sd	s4,16(sp)
    80201a3e:	8a2a                	mv	s4,a0

    /* Implementation note. */


    if (uvmcopy(parent->pagetable, np->pagetable, parent->sz) < 0) {
    80201a40:	048ab603          	ld	a2,72(s5)
    80201a44:	692c                	ld	a1,80(a0)
    80201a46:	050ab503          	ld	a0,80(s5)
    80201a4a:	00001097          	auipc	ra,0x1
    80201a4e:	3c4080e7          	jalr	964(ra) # 80202e0e <uvmcopy>
    80201a52:	04054a63          	bltz	a0,80201aa6 <fork+0x8c>
    80201a56:	f426                	sd	s1,40(sp)
    80201a58:	ec4e                	sd	s3,24(sp)
        freeproc(np);
        release(&np->lock);
        return -1;
    }
    np->sz = parent->sz;
    80201a5a:	048ab783          	ld	a5,72(s5)
    80201a5e:	04fa3423          	sd	a5,72(s4)
    *(np->tf) = *(parent->tf);
    80201a62:	058ab683          	ld	a3,88(s5)
    80201a66:	87b6                	mv	a5,a3
    80201a68:	058a3703          	ld	a4,88(s4)
    80201a6c:	12068693          	addi	a3,a3,288
    80201a70:	0007b803          	ld	a6,0(a5)
    80201a74:	6788                	ld	a0,8(a5)
    80201a76:	6b8c                	ld	a1,16(a5)
    80201a78:	6f90                	ld	a2,24(a5)
    80201a7a:	01073023          	sd	a6,0(a4) # fffffffffffff000 <uart+0xffffffff7fcbffd0>
    80201a7e:	e708                	sd	a0,8(a4)
    80201a80:	eb0c                	sd	a1,16(a4)
    80201a82:	ef10                	sd	a2,24(a4)
    80201a84:	02078793          	addi	a5,a5,32
    80201a88:	02070713          	addi	a4,a4,32
    80201a8c:	fed792e3          	bne	a5,a3,80201a70 <fork+0x56>
    np->tf->a0 = 0;                 /* the child sees fork() return 0 */
    80201a90:	058a3783          	ld	a5,88(s4)
    80201a94:	0607b823          	sd	zero,112(a5)

    /* The child INHERITS the parent's open files and cwd - this is what makes
     * `cmd > file` work: the shell redirects, then forks, and the child keeps
     * the redirected descriptor. Same struct file, same offset. */
    for (int i = 0; i < NOFILE; i++)
    80201a98:	0d0a8493          	addi	s1,s5,208
    80201a9c:	0d0a0913          	addi	s2,s4,208
    80201aa0:	150a8993          	addi	s3,s5,336
    80201aa4:	a015                	j	80201ac8 <fork+0xae>
        freeproc(np);
    80201aa6:	8552                	mv	a0,s4
    80201aa8:	00000097          	auipc	ra,0x0
    80201aac:	a7a080e7          	jalr	-1414(ra) # 80201522 <freeproc>
        release(&np->lock);
    80201ab0:	8552                	mv	a0,s4
    80201ab2:	00000097          	auipc	ra,0x0
    80201ab6:	8fe080e7          	jalr	-1794(ra) # 802013b0 <release>
        return -1;
    80201aba:	597d                	li	s2,-1
    80201abc:	6a42                	ld	s4,16(sp)
    80201abe:	a071                	j	80201b4a <fork+0x130>
    for (int i = 0; i < NOFILE; i++)
    80201ac0:	04a1                	addi	s1,s1,8
    80201ac2:	0921                	addi	s2,s2,8
    80201ac4:	01348b63          	beq	s1,s3,80201ada <fork+0xc0>
        if (parent->ofile[i])
    80201ac8:	6088                	ld	a0,0(s1)
    80201aca:	d97d                	beqz	a0,80201ac0 <fork+0xa6>
            np->ofile[i] = filedup(parent->ofile[i]);
    80201acc:	00004097          	auipc	ra,0x4
    80201ad0:	e2c080e7          	jalr	-468(ra) # 802058f8 <filedup>
    80201ad4:	00a93023          	sd	a0,0(s2)
    80201ad8:	b7e5                	j	80201ac0 <fork+0xa6>
    np->cwd = idup(parent->cwd);
    80201ada:	150ab503          	ld	a0,336(s5)
    80201ade:	00003097          	auipc	ra,0x3
    80201ae2:	46e080e7          	jalr	1134(ra) # 80204f4c <idup>
    80201ae6:	14aa3823          	sd	a0,336(s4)

    strncpy(np->name, parent->name, sizeof(np->name));
    80201aea:	4641                	li	a2,16
    80201aec:	158a8593          	addi	a1,s5,344
    80201af0:	158a0513          	addi	a0,s4,344
    80201af4:	fffff097          	auipc	ra,0xfffff
    80201af8:	c34080e7          	jalr	-972(ra) # 80200728 <strncpy>
    int pid = np->pid;
    80201afc:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80201b00:	8552                	mv	a0,s4
    80201b02:	00000097          	auipc	ra,0x0
    80201b06:	8ae080e7          	jalr	-1874(ra) # 802013b0 <release>

    acquire(&wait_lock);
    80201b0a:	00029497          	auipc	s1,0x29
    80201b0e:	90e48493          	addi	s1,s1,-1778 # 8022a418 <wait_lock>
    80201b12:	8526                	mv	a0,s1
    80201b14:	fffff097          	auipc	ra,0xfffff
    80201b18:	7ec080e7          	jalr	2028(ra) # 80201300 <acquire>
    np->parent = parent;
    80201b1c:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80201b20:	8526                	mv	a0,s1
    80201b22:	00000097          	auipc	ra,0x0
    80201b26:	88e080e7          	jalr	-1906(ra) # 802013b0 <release>

    acquire(&np->lock);
    80201b2a:	8552                	mv	a0,s4
    80201b2c:	fffff097          	auipc	ra,0xfffff
    80201b30:	7d4080e7          	jalr	2004(ra) # 80201300 <acquire>
    np->state = RUNNABLE;
    80201b34:	478d                	li	a5,3
    80201b36:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80201b3a:	8552                	mv	a0,s4
    80201b3c:	00000097          	auipc	ra,0x0
    80201b40:	874080e7          	jalr	-1932(ra) # 802013b0 <release>
    return pid;
    80201b44:	74a2                	ld	s1,40(sp)
    80201b46:	69e2                	ld	s3,24(sp)
    80201b48:	6a42                	ld	s4,16(sp)
}
    80201b4a:	854a                	mv	a0,s2
    80201b4c:	70e2                	ld	ra,56(sp)
    80201b4e:	7442                	ld	s0,48(sp)
    80201b50:	7902                	ld	s2,32(sp)
    80201b52:	6aa2                	ld	s5,8(sp)
    80201b54:	6121                	addi	sp,sp,64
    80201b56:	8082                	ret
    if (!np) return -1;
    80201b58:	597d                	li	s2,-1
    80201b5a:	bfc5                	j	80201b4a <fork+0x130>

0000000080201b5c <scheduler>:
    }
}

/* Implementation note. */
void scheduler(void)
{
    80201b5c:	7139                	addi	sp,sp,-64
    80201b5e:	fc06                	sd	ra,56(sp)
    80201b60:	f822                	sd	s0,48(sp)
    80201b62:	f426                	sd	s1,40(sp)
    80201b64:	f04a                	sd	s2,32(sp)
    80201b66:	ec4e                	sd	s3,24(sp)
    80201b68:	e852                	sd	s4,16(sp)
    80201b6a:	e456                	sd	s5,8(sp)
    80201b6c:	e05a                	sd	s6,0(sp)
    80201b6e:	0080                	addi	s0,sp,64
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    80201b70:	00004097          	auipc	ra,0x4
    80201b74:	52c080e7          	jalr	1324(ra) # 8020609c <hal_hart_id>
    struct cpu *c = mycpu();
    c->proc = 0;
    80201b78:	00751b13          	slli	s6,a0,0x7
    80201b7c:	00028717          	auipc	a4,0x28
    80201b80:	48470713          	addi	a4,a4,1156 # 8022a000 <pid_lock>
    80201b84:	975a                	add	a4,a4,s6
    80201b86:	00073c23          	sd	zero,24(a4)
                p->state = RUNNING;
                c->proc  = p;
                w_satp(MAKE_SATP(p->pagetable));   /* into its address space */
                sfence_vma();

                swtch(&c->context, &p->context);
    80201b8a:	00028717          	auipc	a4,0x28
    80201b8e:	49670713          	addi	a4,a4,1174 # 8022a020 <cpus+0x8>
    80201b92:	9b3a                	add	s6,s6,a4
                c->proc  = p;
    80201b94:	00751793          	slli	a5,a0,0x7
    80201b98:	00028a17          	auipc	s4,0x28
    80201b9c:	468a0a13          	addi	s4,s4,1128 # 8022a000 <pid_lock>
    80201ba0:	9a3e                	add	s4,s4,a5
                w_satp(MAKE_SATP(p->pagetable));   /* into its address space */
    80201ba2:	59fd                	li	s3,-1
    80201ba4:	19fe                	slli	s3,s3,0x3f
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    80201ba6:	100027f3          	csrr	a5,sstatus
static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
    80201baa:	0027e793          	ori	a5,a5,2
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    80201bae:	10079073          	csrw	sstatus,a5
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201bb2:	00129497          	auipc	s1,0x129
    80201bb6:	44e48493          	addi	s1,s1,1102 # 8032b000 <proc>
            if (p->state == RUNNABLE) {
    80201bba:	490d                	li	s2,3
                p->state = RUNNING;
    80201bbc:	4a91                	li	s5,4
    80201bbe:	a831                	j	80201bda <scheduler+0x7e>

                w_satp(MAKE_SATP(kernel_pagetable));
                sfence_vma();
                c->proc = 0;
            }
            release(&p->lock);
    80201bc0:	8526                	mv	a0,s1
    80201bc2:	fffff097          	auipc	ra,0xfffff
    80201bc6:	7ee080e7          	jalr	2030(ra) # 802013b0 <release>
        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201bca:	16848493          	addi	s1,s1,360
    80201bce:	0012f797          	auipc	a5,0x12f
    80201bd2:	e3278793          	addi	a5,a5,-462 # 80330a00 <tickslock>
    80201bd6:	fcf488e3          	beq	s1,a5,80201ba6 <scheduler+0x4a>
            acquire(&p->lock);
    80201bda:	8526                	mv	a0,s1
    80201bdc:	fffff097          	auipc	ra,0xfffff
    80201be0:	724080e7          	jalr	1828(ra) # 80201300 <acquire>
            if (p->state == RUNNABLE) {
    80201be4:	4c9c                	lw	a5,24(s1)
    80201be6:	fd279de3          	bne	a5,s2,80201bc0 <scheduler+0x64>
                p->state = RUNNING;
    80201bea:	0154ac23          	sw	s5,24(s1)
                c->proc  = p;
    80201bee:	009a3c23          	sd	s1,24(s4)
                w_satp(MAKE_SATP(p->pagetable));   /* into its address space */
    80201bf2:	68bc                	ld	a5,80(s1)
    80201bf4:	83b1                	srli	a5,a5,0xc
    80201bf6:	0137e7b3          	or	a5,a5,s3
static inline void   w_satp(uint64 x){ asm volatile("csrw satp, %0"::"r"(x)); }
    80201bfa:	18079073          	csrw	satp,a5
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }
    80201bfe:	12000073          	sfence.vma
                swtch(&c->context, &p->context);
    80201c02:	06048593          	addi	a1,s1,96
    80201c06:	855a                	mv	a0,s6
    80201c08:	00000097          	auipc	ra,0x0
    80201c0c:	5f8080e7          	jalr	1528(ra) # 80202200 <swtch>
                w_satp(MAKE_SATP(kernel_pagetable));
    80201c10:	0013d797          	auipc	a5,0x13d
    80201c14:	4107b783          	ld	a5,1040(a5) # 8033f020 <kernel_pagetable>
    80201c18:	83b1                	srli	a5,a5,0xc
    80201c1a:	0137e7b3          	or	a5,a5,s3
static inline void   w_satp(uint64 x){ asm volatile("csrw satp, %0"::"r"(x)); }
    80201c1e:	18079073          	csrw	satp,a5
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }
    80201c22:	12000073          	sfence.vma
                c->proc = 0;
    80201c26:	000a3c23          	sd	zero,24(s4)
    80201c2a:	bf59                	j	80201bc0 <scheduler+0x64>

0000000080201c2c <sched>:
    }
}

/* Switch to the scheduler. Must hold p->lock and have changed p->state. */
void sched(void)
{
    80201c2c:	7179                	addi	sp,sp,-48
    80201c2e:	f406                	sd	ra,40(sp)
    80201c30:	f022                	sd	s0,32(sp)
    80201c32:	ec26                	sd	s1,24(sp)
    80201c34:	e84a                	sd	s2,16(sp)
    80201c36:	e44e                	sd	s3,8(sp)
    80201c38:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80201c3a:	00000097          	auipc	ra,0x0
    80201c3e:	aa4080e7          	jalr	-1372(ra) # 802016de <myproc>
    80201c42:	84aa                	mv	s1,a0
    if (!holding(&p->lock))   panic("sched: not holding p->lock");
    80201c44:	fffff097          	auipc	ra,0xfffff
    80201c48:	656080e7          	jalr	1622(ra) # 8020129a <holding>
    80201c4c:	c541                	beqz	a0,80201cd4 <sched+0xa8>
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    80201c4e:	00004097          	auipc	ra,0x4
    80201c52:	44e080e7          	jalr	1102(ra) # 8020609c <hal_hart_id>
    if (mycpu()->noff != 1)   panic("sched: holding another lock too");
    80201c56:	051e                	slli	a0,a0,0x7
    80201c58:	00028797          	auipc	a5,0x28
    80201c5c:	3a878793          	addi	a5,a5,936 # 8022a000 <pid_lock>
    80201c60:	97aa                	add	a5,a5,a0
    80201c62:	0907a703          	lw	a4,144(a5)
    80201c66:	4785                	li	a5,1
    80201c68:	06f71e63          	bne	a4,a5,80201ce4 <sched+0xb8>
    if (p->state == RUNNING)  panic("sched: process is still RUNNING");
    80201c6c:	4c98                	lw	a4,24(s1)
    80201c6e:	4791                	li	a5,4
    80201c70:	08f70263          	beq	a4,a5,80201cf4 <sched+0xc8>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    80201c74:	100027f3          	csrr	a5,sstatus
static inline int  intr_get(void){ return (r_sstatus() & SSTATUS_SIE) != 0; }
    80201c78:	8b89                	andi	a5,a5,2
    if (intr_get())           panic("sched: interrupts are on");
    80201c7a:	e7c9                	bnez	a5,80201d04 <sched+0xd8>
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    80201c7c:	00004097          	auipc	ra,0x4
    80201c80:	420080e7          	jalr	1056(ra) # 8020609c <hal_hart_id>

    int intena = mycpu()->intena;
    80201c84:	00028917          	auipc	s2,0x28
    80201c88:	37c90913          	addi	s2,s2,892 # 8022a000 <pid_lock>
    80201c8c:	00751793          	slli	a5,a0,0x7
    80201c90:	97ca                	add	a5,a5,s2
    80201c92:	0947a983          	lw	s3,148(a5)
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    80201c96:	00004097          	auipc	ra,0x4
    80201c9a:	406080e7          	jalr	1030(ra) # 8020609c <hal_hart_id>
    swtch(&p->context, &mycpu()->context);
    80201c9e:	051e                	slli	a0,a0,0x7
    80201ca0:	00028597          	auipc	a1,0x28
    80201ca4:	38058593          	addi	a1,a1,896 # 8022a020 <cpus+0x8>
    80201ca8:	95aa                	add	a1,a1,a0
    80201caa:	06048513          	addi	a0,s1,96
    80201cae:	00000097          	auipc	ra,0x0
    80201cb2:	552080e7          	jalr	1362(ra) # 80202200 <swtch>
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }
    80201cb6:	00004097          	auipc	ra,0x4
    80201cba:	3e6080e7          	jalr	998(ra) # 8020609c <hal_hart_id>
    mycpu()->intena = intena;
    80201cbe:	051e                	slli	a0,a0,0x7
    80201cc0:	992a                	add	s2,s2,a0
    80201cc2:	09392a23          	sw	s3,148(s2)
}
    80201cc6:	70a2                	ld	ra,40(sp)
    80201cc8:	7402                	ld	s0,32(sp)
    80201cca:	64e2                	ld	s1,24(sp)
    80201ccc:	6942                	ld	s2,16(sp)
    80201cce:	69a2                	ld	s3,8(sp)
    80201cd0:	6145                	addi	sp,sp,48
    80201cd2:	8082                	ret
    if (!holding(&p->lock))   panic("sched: not holding p->lock");
    80201cd4:	00006517          	auipc	a0,0x6
    80201cd8:	86450513          	addi	a0,a0,-1948 # 80207538 <etext+0x538>
    80201cdc:	fffff097          	auipc	ra,0xfffff
    80201ce0:	8d4080e7          	jalr	-1836(ra) # 802005b0 <panic>
    if (mycpu()->noff != 1)   panic("sched: holding another lock too");
    80201ce4:	00006517          	auipc	a0,0x6
    80201ce8:	87450513          	addi	a0,a0,-1932 # 80207558 <etext+0x558>
    80201cec:	fffff097          	auipc	ra,0xfffff
    80201cf0:	8c4080e7          	jalr	-1852(ra) # 802005b0 <panic>
    if (p->state == RUNNING)  panic("sched: process is still RUNNING");
    80201cf4:	00006517          	auipc	a0,0x6
    80201cf8:	88450513          	addi	a0,a0,-1916 # 80207578 <etext+0x578>
    80201cfc:	fffff097          	auipc	ra,0xfffff
    80201d00:	8b4080e7          	jalr	-1868(ra) # 802005b0 <panic>
    if (intr_get())           panic("sched: interrupts are on");
    80201d04:	00006517          	auipc	a0,0x6
    80201d08:	89450513          	addi	a0,a0,-1900 # 80207598 <etext+0x598>
    80201d0c:	fffff097          	auipc	ra,0xfffff
    80201d10:	8a4080e7          	jalr	-1884(ra) # 802005b0 <panic>

0000000080201d14 <yield>:

void yield(void)
{
    80201d14:	1101                	addi	sp,sp,-32
    80201d16:	ec06                	sd	ra,24(sp)
    80201d18:	e822                	sd	s0,16(sp)
    80201d1a:	e426                	sd	s1,8(sp)
    80201d1c:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80201d1e:	00000097          	auipc	ra,0x0
    80201d22:	9c0080e7          	jalr	-1600(ra) # 802016de <myproc>
    80201d26:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80201d28:	fffff097          	auipc	ra,0xfffff
    80201d2c:	5d8080e7          	jalr	1496(ra) # 80201300 <acquire>
    p->state = RUNNABLE;
    80201d30:	478d                	li	a5,3
    80201d32:	cc9c                	sw	a5,24(s1)
    sched();
    80201d34:	00000097          	auipc	ra,0x0
    80201d38:	ef8080e7          	jalr	-264(ra) # 80201c2c <sched>
    release(&p->lock);
    80201d3c:	8526                	mv	a0,s1
    80201d3e:	fffff097          	auipc	ra,0xfffff
    80201d42:	672080e7          	jalr	1650(ra) # 802013b0 <release>
}
    80201d46:	60e2                	ld	ra,24(sp)
    80201d48:	6442                	ld	s0,16(sp)
    80201d4a:	64a2                	ld	s1,8(sp)
    80201d4c:	6105                	addi	sp,sp,32
    80201d4e:	8082                	ret

0000000080201d50 <sleep>:

void sleep(void *chan, struct spinlock *lk)
{
    80201d50:	7179                	addi	sp,sp,-48
    80201d52:	f406                	sd	ra,40(sp)
    80201d54:	f022                	sd	s0,32(sp)
    80201d56:	ec26                	sd	s1,24(sp)
    80201d58:	e84a                	sd	s2,16(sp)
    80201d5a:	e44e                	sd	s3,8(sp)
    80201d5c:	1800                	addi	s0,sp,48
    80201d5e:	89aa                	mv	s3,a0
    80201d60:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80201d62:	00000097          	auipc	ra,0x0
    80201d66:	97c080e7          	jalr	-1668(ra) # 802016de <myproc>
    80201d6a:	84aa                	mv	s1,a0

    /* Acquire p->lock BEFORE releasing lk. If we did it the other way round, a
     * wakeup could slip in between and be lost - the classic missed-wakeup race. */
    acquire(&p->lock);
    80201d6c:	fffff097          	auipc	ra,0xfffff
    80201d70:	594080e7          	jalr	1428(ra) # 80201300 <acquire>
    release(lk);
    80201d74:	854a                	mv	a0,s2
    80201d76:	fffff097          	auipc	ra,0xfffff
    80201d7a:	63a080e7          	jalr	1594(ra) # 802013b0 <release>

    p->chan  = chan;
    80201d7e:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80201d82:	4789                	li	a5,2
    80201d84:	cc9c                	sw	a5,24(s1)
    sched();
    80201d86:	00000097          	auipc	ra,0x0
    80201d8a:	ea6080e7          	jalr	-346(ra) # 80201c2c <sched>

    p->chan = 0;
    80201d8e:	0204b023          	sd	zero,32(s1)
    release(&p->lock);
    80201d92:	8526                	mv	a0,s1
    80201d94:	fffff097          	auipc	ra,0xfffff
    80201d98:	61c080e7          	jalr	1564(ra) # 802013b0 <release>
    acquire(lk);
    80201d9c:	854a                	mv	a0,s2
    80201d9e:	fffff097          	auipc	ra,0xfffff
    80201da2:	562080e7          	jalr	1378(ra) # 80201300 <acquire>
}
    80201da6:	70a2                	ld	ra,40(sp)
    80201da8:	7402                	ld	s0,32(sp)
    80201daa:	64e2                	ld	s1,24(sp)
    80201dac:	6942                	ld	s2,16(sp)
    80201dae:	69a2                	ld	s3,8(sp)
    80201db0:	6145                	addi	sp,sp,48
    80201db2:	8082                	ret

0000000080201db4 <wait>:
{
    80201db4:	7139                	addi	sp,sp,-64
    80201db6:	fc06                	sd	ra,56(sp)
    80201db8:	f822                	sd	s0,48(sp)
    80201dba:	f426                	sd	s1,40(sp)
    80201dbc:	f04a                	sd	s2,32(sp)
    80201dbe:	ec4e                	sd	s3,24(sp)
    80201dc0:	e852                	sd	s4,16(sp)
    80201dc2:	e456                	sd	s5,8(sp)
    80201dc4:	e05a                	sd	s6,0(sp)
    80201dc6:	0080                	addi	s0,sp,64
    80201dc8:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80201dca:	00000097          	auipc	ra,0x0
    80201dce:	914080e7          	jalr	-1772(ra) # 802016de <myproc>
    80201dd2:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80201dd4:	00028517          	auipc	a0,0x28
    80201dd8:	64450513          	addi	a0,a0,1604 # 8022a418 <wait_lock>
    80201ddc:	fffff097          	auipc	ra,0xfffff
    80201de0:	524080e7          	jalr	1316(ra) # 80201300 <acquire>
            if (pp->state == ZOMBIE) {
    80201de4:	4a15                	li	s4,5
            havekids = 1;
    80201de6:	4a85                	li	s5,1
        for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80201de8:	0012f997          	auipc	s3,0x12f
    80201dec:	c1898993          	addi	s3,s3,-1000 # 80330a00 <tickslock>
    80201df0:	00129497          	auipc	s1,0x129
    80201df4:	21048493          	addi	s1,s1,528 # 8032b000 <proc>
        int havekids = 0;
    80201df8:	4701                	li	a4,0
    80201dfa:	a049                	j	80201e7c <wait+0xc8>
                int pid = pp->pid;
    80201dfc:	0304a983          	lw	s3,48(s1)
                if (addr && copyout(p->pagetable, addr,
    80201e00:	000b0e63          	beqz	s6,80201e1c <wait+0x68>
    80201e04:	4691                	li	a3,4
    80201e06:	02c48613          	addi	a2,s1,44
    80201e0a:	85da                	mv	a1,s6
    80201e0c:	05093503          	ld	a0,80(s2)
    80201e10:	00001097          	auipc	ra,0x1
    80201e14:	0ce080e7          	jalr	206(ra) # 80202ede <copyout>
    80201e18:	02054f63          	bltz	a0,80201e56 <wait+0xa2>
                freeproc(pp);
    80201e1c:	8526                	mv	a0,s1
    80201e1e:	fffff097          	auipc	ra,0xfffff
    80201e22:	704080e7          	jalr	1796(ra) # 80201522 <freeproc>
                release(&pp->lock);
    80201e26:	8526                	mv	a0,s1
    80201e28:	fffff097          	auipc	ra,0xfffff
    80201e2c:	588080e7          	jalr	1416(ra) # 802013b0 <release>
                release(&wait_lock);
    80201e30:	00028517          	auipc	a0,0x28
    80201e34:	5e850513          	addi	a0,a0,1512 # 8022a418 <wait_lock>
    80201e38:	fffff097          	auipc	ra,0xfffff
    80201e3c:	578080e7          	jalr	1400(ra) # 802013b0 <release>
}
    80201e40:	854e                	mv	a0,s3
    80201e42:	70e2                	ld	ra,56(sp)
    80201e44:	7442                	ld	s0,48(sp)
    80201e46:	74a2                	ld	s1,40(sp)
    80201e48:	7902                	ld	s2,32(sp)
    80201e4a:	69e2                	ld	s3,24(sp)
    80201e4c:	6a42                	ld	s4,16(sp)
    80201e4e:	6aa2                	ld	s5,8(sp)
    80201e50:	6b02                	ld	s6,0(sp)
    80201e52:	6121                	addi	sp,sp,64
    80201e54:	8082                	ret
                    release(&pp->lock);
    80201e56:	8526                	mv	a0,s1
    80201e58:	fffff097          	auipc	ra,0xfffff
    80201e5c:	558080e7          	jalr	1368(ra) # 802013b0 <release>
                    release(&wait_lock);
    80201e60:	00028517          	auipc	a0,0x28
    80201e64:	5b850513          	addi	a0,a0,1464 # 8022a418 <wait_lock>
    80201e68:	fffff097          	auipc	ra,0xfffff
    80201e6c:	548080e7          	jalr	1352(ra) # 802013b0 <release>
                    return -1;
    80201e70:	59fd                	li	s3,-1
    80201e72:	b7f9                	j	80201e40 <wait+0x8c>
        for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80201e74:	16848493          	addi	s1,s1,360
    80201e78:	03348463          	beq	s1,s3,80201ea0 <wait+0xec>
            if (pp->parent != p) continue;
    80201e7c:	7c9c                	ld	a5,56(s1)
    80201e7e:	ff279be3          	bne	a5,s2,80201e74 <wait+0xc0>
            acquire(&pp->lock);
    80201e82:	8526                	mv	a0,s1
    80201e84:	fffff097          	auipc	ra,0xfffff
    80201e88:	47c080e7          	jalr	1148(ra) # 80201300 <acquire>
            if (pp->state == ZOMBIE) {
    80201e8c:	4c9c                	lw	a5,24(s1)
    80201e8e:	f74787e3          	beq	a5,s4,80201dfc <wait+0x48>
            release(&pp->lock);
    80201e92:	8526                	mv	a0,s1
    80201e94:	fffff097          	auipc	ra,0xfffff
    80201e98:	51c080e7          	jalr	1308(ra) # 802013b0 <release>
            havekids = 1;
    80201e9c:	8756                	mv	a4,s5
    80201e9e:	bfd9                	j	80201e74 <wait+0xc0>
        if (!havekids || p->killed) {
    80201ea0:	cf11                	beqz	a4,80201ebc <wait+0x108>
    80201ea2:	02892783          	lw	a5,40(s2)
    80201ea6:	eb99                	bnez	a5,80201ebc <wait+0x108>
        sleep(p, &wait_lock);
    80201ea8:	00028597          	auipc	a1,0x28
    80201eac:	57058593          	addi	a1,a1,1392 # 8022a418 <wait_lock>
    80201eb0:	854a                	mv	a0,s2
    80201eb2:	00000097          	auipc	ra,0x0
    80201eb6:	e9e080e7          	jalr	-354(ra) # 80201d50 <sleep>
    for (;;) {
    80201eba:	bf1d                	j	80201df0 <wait+0x3c>
            release(&wait_lock);
    80201ebc:	00028517          	auipc	a0,0x28
    80201ec0:	55c50513          	addi	a0,a0,1372 # 8022a418 <wait_lock>
    80201ec4:	fffff097          	auipc	ra,0xfffff
    80201ec8:	4ec080e7          	jalr	1260(ra) # 802013b0 <release>
            return -1;
    80201ecc:	59fd                	li	s3,-1
    80201ece:	bf8d                	j	80201e40 <wait+0x8c>

0000000080201ed0 <wakeup>:

void wakeup(void *chan)
{
    80201ed0:	7139                	addi	sp,sp,-64
    80201ed2:	fc06                	sd	ra,56(sp)
    80201ed4:	f822                	sd	s0,48(sp)
    80201ed6:	f426                	sd	s1,40(sp)
    80201ed8:	f04a                	sd	s2,32(sp)
    80201eda:	ec4e                	sd	s3,24(sp)
    80201edc:	e852                	sd	s4,16(sp)
    80201ede:	e456                	sd	s5,8(sp)
    80201ee0:	0080                	addi	s0,sp,64
    80201ee2:	8a2a                	mv	s4,a0
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201ee4:	00129497          	auipc	s1,0x129
    80201ee8:	11c48493          	addi	s1,s1,284 # 8032b000 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80201eec:	4989                	li	s3,2
                p->state = RUNNABLE;
    80201eee:	4a8d                	li	s5,3
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201ef0:	0012f917          	auipc	s2,0x12f
    80201ef4:	b1090913          	addi	s2,s2,-1264 # 80330a00 <tickslock>
    80201ef8:	a811                	j	80201f0c <wakeup+0x3c>
            release(&p->lock);
    80201efa:	8526                	mv	a0,s1
    80201efc:	fffff097          	auipc	ra,0xfffff
    80201f00:	4b4080e7          	jalr	1204(ra) # 802013b0 <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80201f04:	16848493          	addi	s1,s1,360
    80201f08:	03248663          	beq	s1,s2,80201f34 <wakeup+0x64>
        if (p != myproc()) {
    80201f0c:	fffff097          	auipc	ra,0xfffff
    80201f10:	7d2080e7          	jalr	2002(ra) # 802016de <myproc>
    80201f14:	fea488e3          	beq	s1,a0,80201f04 <wakeup+0x34>
            acquire(&p->lock);
    80201f18:	8526                	mv	a0,s1
    80201f1a:	fffff097          	auipc	ra,0xfffff
    80201f1e:	3e6080e7          	jalr	998(ra) # 80201300 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80201f22:	4c9c                	lw	a5,24(s1)
    80201f24:	fd379be3          	bne	a5,s3,80201efa <wakeup+0x2a>
    80201f28:	709c                	ld	a5,32(s1)
    80201f2a:	fd4798e3          	bne	a5,s4,80201efa <wakeup+0x2a>
                p->state = RUNNABLE;
    80201f2e:	0154ac23          	sw	s5,24(s1)
    80201f32:	b7e1                	j	80201efa <wakeup+0x2a>
        }
    }
}
    80201f34:	70e2                	ld	ra,56(sp)
    80201f36:	7442                	ld	s0,48(sp)
    80201f38:	74a2                	ld	s1,40(sp)
    80201f3a:	7902                	ld	s2,32(sp)
    80201f3c:	69e2                	ld	s3,24(sp)
    80201f3e:	6a42                	ld	s4,16(sp)
    80201f40:	6aa2                	ld	s5,8(sp)
    80201f42:	6121                	addi	sp,sp,64
    80201f44:	8082                	ret

0000000080201f46 <exit>:
{
    80201f46:	7139                	addi	sp,sp,-64
    80201f48:	fc06                	sd	ra,56(sp)
    80201f4a:	f822                	sd	s0,48(sp)
    80201f4c:	f426                	sd	s1,40(sp)
    80201f4e:	f04a                	sd	s2,32(sp)
    80201f50:	ec4e                	sd	s3,24(sp)
    80201f52:	e456                	sd	s5,8(sp)
    80201f54:	0080                	addi	s0,sp,64
    80201f56:	8aaa                	mv	s5,a0
    struct proc *p = myproc();
    80201f58:	fffff097          	auipc	ra,0xfffff
    80201f5c:	786080e7          	jalr	1926(ra) # 802016de <myproc>
    80201f60:	892a                	mv	s2,a0
    if (p == initproc) panic("init exiting");
    80201f62:	0013d797          	auipc	a5,0x13d
    80201f66:	0ae7b783          	ld	a5,174(a5) # 8033f010 <initproc>
    80201f6a:	0d050493          	addi	s1,a0,208
    80201f6e:	15050993          	addi	s3,a0,336
    80201f72:	00a78463          	beq	a5,a0,80201f7a <exit+0x34>
    80201f76:	e852                	sd	s4,16(sp)
    80201f78:	a829                	j	80201f92 <exit+0x4c>
    80201f7a:	e852                	sd	s4,16(sp)
    80201f7c:	00005517          	auipc	a0,0x5
    80201f80:	63c50513          	addi	a0,a0,1596 # 802075b8 <etext+0x5b8>
    80201f84:	ffffe097          	auipc	ra,0xffffe
    80201f88:	62c080e7          	jalr	1580(ra) # 802005b0 <panic>
    for (int fd = 0; fd < NOFILE; fd++) {
    80201f8c:	04a1                	addi	s1,s1,8
    80201f8e:	01348b63          	beq	s1,s3,80201fa4 <exit+0x5e>
        if (p->ofile[fd]) {
    80201f92:	6088                	ld	a0,0(s1)
    80201f94:	dd65                	beqz	a0,80201f8c <exit+0x46>
            fileclose(p->ofile[fd]);
    80201f96:	00004097          	auipc	ra,0x4
    80201f9a:	9b4080e7          	jalr	-1612(ra) # 8020594a <fileclose>
            p->ofile[fd] = 0;
    80201f9e:	0004b023          	sd	zero,0(s1)
    80201fa2:	b7ed                	j	80201f8c <exit+0x46>
    iput(p->cwd);
    80201fa4:	15093503          	ld	a0,336(s2)
    80201fa8:	00003097          	auipc	ra,0x3
    80201fac:	1a0080e7          	jalr	416(ra) # 80205148 <iput>
    p->cwd = 0;
    80201fb0:	14093823          	sd	zero,336(s2)
    acquire(&wait_lock);
    80201fb4:	00028517          	auipc	a0,0x28
    80201fb8:	46450513          	addi	a0,a0,1124 # 8022a418 <wait_lock>
    80201fbc:	fffff097          	auipc	ra,0xfffff
    80201fc0:	344080e7          	jalr	836(ra) # 80201300 <acquire>
    for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80201fc4:	00129497          	auipc	s1,0x129
    80201fc8:	03c48493          	addi	s1,s1,60 # 8032b000 <proc>
            pp->parent = initproc;
    80201fcc:	0013da17          	auipc	s4,0x13d
    80201fd0:	044a0a13          	addi	s4,s4,68 # 8033f010 <initproc>
    for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80201fd4:	0012f997          	auipc	s3,0x12f
    80201fd8:	a2c98993          	addi	s3,s3,-1492 # 80330a00 <tickslock>
    80201fdc:	a821                	j	80201ff4 <exit+0xae>
            pp->parent = initproc;
    80201fde:	000a3503          	ld	a0,0(s4)
    80201fe2:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80201fe4:	00000097          	auipc	ra,0x0
    80201fe8:	eec080e7          	jalr	-276(ra) # 80201ed0 <wakeup>
    for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
    80201fec:	16848493          	addi	s1,s1,360
    80201ff0:	01348663          	beq	s1,s3,80201ffc <exit+0xb6>
        if (pp->parent == p) {
    80201ff4:	7c9c                	ld	a5,56(s1)
    80201ff6:	fef91be3          	bne	s2,a5,80201fec <exit+0xa6>
    80201ffa:	b7d5                	j	80201fde <exit+0x98>
    wakeup(p->parent);
    80201ffc:	03893503          	ld	a0,56(s2)
    80202000:	00000097          	auipc	ra,0x0
    80202004:	ed0080e7          	jalr	-304(ra) # 80201ed0 <wakeup>
    acquire(&p->lock);
    80202008:	854a                	mv	a0,s2
    8020200a:	fffff097          	auipc	ra,0xfffff
    8020200e:	2f6080e7          	jalr	758(ra) # 80201300 <acquire>
    p->xstate = status;
    80202012:	03592623          	sw	s5,44(s2)
    p->state  = ZOMBIE;
    80202016:	4795                	li	a5,5
    80202018:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    8020201c:	00028517          	auipc	a0,0x28
    80202020:	3fc50513          	addi	a0,a0,1020 # 8022a418 <wait_lock>
    80202024:	fffff097          	auipc	ra,0xfffff
    80202028:	38c080e7          	jalr	908(ra) # 802013b0 <release>
    sched();                        /* never returns */
    8020202c:	00000097          	auipc	ra,0x0
    80202030:	c00080e7          	jalr	-1024(ra) # 80201c2c <sched>
    panic("zombie exit");
    80202034:	00005517          	auipc	a0,0x5
    80202038:	59450513          	addi	a0,a0,1428 # 802075c8 <etext+0x5c8>
    8020203c:	ffffe097          	auipc	ra,0xffffe
    80202040:	574080e7          	jalr	1396(ra) # 802005b0 <panic>

0000000080202044 <kill>:

int kill(int pid)
{
    80202044:	7179                	addi	sp,sp,-48
    80202046:	f406                	sd	ra,40(sp)
    80202048:	f022                	sd	s0,32(sp)
    8020204a:	ec26                	sd	s1,24(sp)
    8020204c:	e84a                	sd	s2,16(sp)
    8020204e:	e44e                	sd	s3,8(sp)
    80202050:	1800                	addi	s0,sp,48
    80202052:	892a                	mv	s2,a0
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    80202054:	00129497          	auipc	s1,0x129
    80202058:	fac48493          	addi	s1,s1,-84 # 8032b000 <proc>
    8020205c:	0012f997          	auipc	s3,0x12f
    80202060:	9a498993          	addi	s3,s3,-1628 # 80330a00 <tickslock>
        acquire(&p->lock);
    80202064:	8526                	mv	a0,s1
    80202066:	fffff097          	auipc	ra,0xfffff
    8020206a:	29a080e7          	jalr	666(ra) # 80201300 <acquire>
        if (p->pid == pid) {
    8020206e:	589c                	lw	a5,48(s1)
    80202070:	01278d63          	beq	a5,s2,8020208a <kill+0x46>
            p->killed = 1;
            if (p->state == SLEEPING) p->state = RUNNABLE;
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80202074:	8526                	mv	a0,s1
    80202076:	fffff097          	auipc	ra,0xfffff
    8020207a:	33a080e7          	jalr	826(ra) # 802013b0 <release>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    8020207e:	16848493          	addi	s1,s1,360
    80202082:	ff3491e3          	bne	s1,s3,80202064 <kill+0x20>
    }
    return -1;
    80202086:	557d                	li	a0,-1
    80202088:	a829                	j	802020a2 <kill+0x5e>
            p->killed = 1;
    8020208a:	4785                	li	a5,1
    8020208c:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING) p->state = RUNNABLE;
    8020208e:	4c98                	lw	a4,24(s1)
    80202090:	4789                	li	a5,2
    80202092:	00f70f63          	beq	a4,a5,802020b0 <kill+0x6c>
            release(&p->lock);
    80202096:	8526                	mv	a0,s1
    80202098:	fffff097          	auipc	ra,0xfffff
    8020209c:	318080e7          	jalr	792(ra) # 802013b0 <release>
            return 0;
    802020a0:	4501                	li	a0,0
}
    802020a2:	70a2                	ld	ra,40(sp)
    802020a4:	7402                	ld	s0,32(sp)
    802020a6:	64e2                	ld	s1,24(sp)
    802020a8:	6942                	ld	s2,16(sp)
    802020aa:	69a2                	ld	s3,8(sp)
    802020ac:	6145                	addi	sp,sp,48
    802020ae:	8082                	ret
            if (p->state == SLEEPING) p->state = RUNNABLE;
    802020b0:	478d                	li	a5,3
    802020b2:	cc9c                	sw	a5,24(s1)
    802020b4:	b7cd                	j	80202096 <kill+0x52>

00000000802020b6 <procstat>:

/* Copy up to max process records to user space; returns the count. Backs the
 * procstat() syscall and the `ps` utility. Reads are racy-by-design (a
 * snapshot, not a transaction) but each slot is read under its own lock. */
int procstat(uint64 uaddr, int max)
{
    802020b6:	7119                	addi	sp,sp,-128
    802020b8:	fc86                	sd	ra,120(sp)
    802020ba:	f8a2                	sd	s0,112(sp)
    802020bc:	f4a6                	sd	s1,104(sp)
    802020be:	f0ca                	sd	s2,96(sp)
    802020c0:	ecce                	sd	s3,88(sp)
    802020c2:	e8d2                	sd	s4,80(sp)
    802020c4:	e4d6                	sd	s5,72(sp)
    802020c6:	e0da                	sd	s6,64(sp)
    802020c8:	fc5e                	sd	s7,56(sp)
    802020ca:	f862                	sd	s8,48(sp)
    802020cc:	f466                	sd	s9,40(sp)
    802020ce:	0100                	addi	s0,sp,128
    802020d0:	8aaa                	mv	s5,a0
    802020d2:	89ae                	mv	s3,a1
    struct pstat ps;
    int n = 0;
    for (struct proc *p = proc; p < &proc[NPROC] && n < max; p++) {
    802020d4:	00129497          	auipc	s1,0x129
    802020d8:	f2c48493          	addi	s1,s1,-212 # 8032b000 <proc>
    int n = 0;
    802020dc:	4901                	li	s2,0
        acquire(&p->lock);
        if (p->state == UNUSED) { release(&p->lock); continue; }
        ps.pid   = p->pid;
        ps.state = p->state;
        memmove(ps.name, p->name, sizeof(ps.name));
    802020de:	f8840c93          	addi	s9,s0,-120
    802020e2:	f9040c13          	addi	s8,s0,-112
    802020e6:	4bc1                	li	s7,16
        release(&p->lock);
        if (copyout(myproc()->pagetable, uaddr + n * sizeof(ps),
    802020e8:	4b61                	li	s6,24
    for (struct proc *p = proc; p < &proc[NPROC] && n < max; p++) {
    802020ea:	0012fa17          	auipc	s4,0x12f
    802020ee:	916a0a13          	addi	s4,s4,-1770 # 80330a00 <tickslock>
    802020f2:	a811                	j	80202106 <procstat+0x50>
        if (p->state == UNUSED) { release(&p->lock); continue; }
    802020f4:	8526                	mv	a0,s1
    802020f6:	fffff097          	auipc	ra,0xfffff
    802020fa:	2ba080e7          	jalr	698(ra) # 802013b0 <release>
    for (struct proc *p = proc; p < &proc[NPROC] && n < max; p++) {
    802020fe:	16848493          	addi	s1,s1,360
    80202102:	07448263          	beq	s1,s4,80202166 <procstat+0xb0>
    80202106:	07395063          	bge	s2,s3,80202166 <procstat+0xb0>
        acquire(&p->lock);
    8020210a:	8526                	mv	a0,s1
    8020210c:	fffff097          	auipc	ra,0xfffff
    80202110:	1f4080e7          	jalr	500(ra) # 80201300 <acquire>
        if (p->state == UNUSED) { release(&p->lock); continue; }
    80202114:	4c9c                	lw	a5,24(s1)
    80202116:	dff9                	beqz	a5,802020f4 <procstat+0x3e>
        ps.pid   = p->pid;
    80202118:	5898                	lw	a4,48(s1)
    8020211a:	f8e42423          	sw	a4,-120(s0)
        ps.state = p->state;
    8020211e:	f8f42623          	sw	a5,-116(s0)
        memmove(ps.name, p->name, sizeof(ps.name));
    80202122:	865e                	mv	a2,s7
    80202124:	15848593          	addi	a1,s1,344
    80202128:	8562                	mv	a0,s8
    8020212a:	ffffe097          	auipc	ra,0xffffe
    8020212e:	54c080e7          	jalr	1356(ra) # 80200676 <memmove>
        release(&p->lock);
    80202132:	8526                	mv	a0,s1
    80202134:	fffff097          	auipc	ra,0xfffff
    80202138:	27c080e7          	jalr	636(ra) # 802013b0 <release>
        if (copyout(myproc()->pagetable, uaddr + n * sizeof(ps),
    8020213c:	fffff097          	auipc	ra,0xfffff
    80202140:	5a2080e7          	jalr	1442(ra) # 802016de <myproc>
    80202144:	00191593          	slli	a1,s2,0x1
    80202148:	95ca                	add	a1,a1,s2
    8020214a:	058e                	slli	a1,a1,0x3
    8020214c:	86da                	mv	a3,s6
    8020214e:	8666                	mv	a2,s9
    80202150:	95d6                	add	a1,a1,s5
    80202152:	6928                	ld	a0,80(a0)
    80202154:	00001097          	auipc	ra,0x1
    80202158:	d8a080e7          	jalr	-630(ra) # 80202ede <copyout>
    8020215c:	00054463          	bltz	a0,80202164 <procstat+0xae>
                    (char *)&ps, sizeof(ps)) < 0)
            return -1;
        n++;
    80202160:	2905                	addiw	s2,s2,1
    80202162:	bf71                	j	802020fe <procstat+0x48>
            return -1;
    80202164:	597d                	li	s2,-1
    }
    return n;
}
    80202166:	854a                	mv	a0,s2
    80202168:	70e6                	ld	ra,120(sp)
    8020216a:	7446                	ld	s0,112(sp)
    8020216c:	74a6                	ld	s1,104(sp)
    8020216e:	7906                	ld	s2,96(sp)
    80202170:	69e6                	ld	s3,88(sp)
    80202172:	6a46                	ld	s4,80(sp)
    80202174:	6aa6                	ld	s5,72(sp)
    80202176:	6b06                	ld	s6,64(sp)
    80202178:	7be2                	ld	s7,56(sp)
    8020217a:	7c42                	ld	s8,48(sp)
    8020217c:	7ca2                	ld	s9,40(sp)
    8020217e:	6109                	addi	sp,sp,128
    80202180:	8082                	ret

0000000080202182 <procdump>:

void procdump(void)
{
    80202182:	7179                	addi	sp,sp,-48
    80202184:	f406                	sd	ra,40(sp)
    80202186:	f022                	sd	s0,32(sp)
    80202188:	ec26                	sd	s1,24(sp)
    8020218a:	e84a                	sd	s2,16(sp)
    8020218c:	e44e                	sd	s3,8(sp)
    8020218e:	e052                	sd	s4,0(sp)
    80202190:	1800                	addi	s0,sp,48
    static const char *st[] = {
        [UNUSED]"unused", [USED]"used", [SLEEPING]"sleep",
        [RUNNABLE]"runble", [RUNNING]"run", [ZOMBIE]"zombie"
    };
    printf("\n--- process table ---\n");
    80202192:	00005517          	auipc	a0,0x5
    80202196:	44650513          	addi	a0,a0,1094 # 802075d8 <etext+0x5d8>
    8020219a:	ffffe097          	auipc	ra,0xffffe
    8020219e:	1a6080e7          	jalr	422(ra) # 80200340 <printf>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802021a2:	00129497          	auipc	s1,0x129
    802021a6:	fb648493          	addi	s1,s1,-74 # 8032b158 <proc+0x158>
    802021aa:	0012f917          	auipc	s2,0x12f
    802021ae:	9ae90913          	addi	s2,s2,-1618 # 80330b58 <bcache+0x98>
        if (p->state == UNUSED) continue;
        printf("pid %d %s %s\n", p->pid, st[p->state], p->name);
    802021b2:	00006a17          	auipc	s4,0x6
    802021b6:	c46a0a13          	addi	s4,s4,-954 # 80207df8 <st.0>
    802021ba:	00005997          	auipc	s3,0x5
    802021be:	43698993          	addi	s3,s3,1078 # 802075f0 <etext+0x5f0>
    802021c2:	a029                	j	802021cc <procdump+0x4a>
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
    802021c4:	16848493          	addi	s1,s1,360
    802021c8:	03248463          	beq	s1,s2,802021f0 <procdump+0x6e>
        if (p->state == UNUSED) continue;
    802021cc:	ec04a783          	lw	a5,-320(s1)
    802021d0:	dbf5                	beqz	a5,802021c4 <procdump+0x42>
        printf("pid %d %s %s\n", p->pid, st[p->state], p->name);
    802021d2:	02079713          	slli	a4,a5,0x20
    802021d6:	01d75793          	srli	a5,a4,0x1d
    802021da:	97d2                	add	a5,a5,s4
    802021dc:	86a6                	mv	a3,s1
    802021de:	6390                	ld	a2,0(a5)
    802021e0:	ed84a583          	lw	a1,-296(s1)
    802021e4:	854e                	mv	a0,s3
    802021e6:	ffffe097          	auipc	ra,0xffffe
    802021ea:	15a080e7          	jalr	346(ra) # 80200340 <printf>
    802021ee:	bfd9                	j	802021c4 <procdump+0x42>
    }
}
    802021f0:	70a2                	ld	ra,40(sp)
    802021f2:	7402                	ld	s0,32(sp)
    802021f4:	64e2                	ld	s1,24(sp)
    802021f6:	6942                	ld	s2,16(sp)
    802021f8:	69a2                	ld	s3,8(sp)
    802021fa:	6a02                	ld	s4,0(sp)
    802021fc:	6145                	addi	sp,sp,48
    802021fe:	8082                	ret

0000000080202200 <swtch>:
# Implementation note.
# calling convention says the caller already spilled anything else it cared about.
# Nine loads, nine stores, one ret - and a process wakes up years later, unaware.
        .globl swtch
swtch:
        sd ra,  0(a0)
    80202200:	00153023          	sd	ra,0(a0)
        sd sp,  8(a0)
    80202204:	00253423          	sd	sp,8(a0)
        sd s0,  16(a0)
    80202208:	e900                	sd	s0,16(a0)
        sd s1,  24(a0)
    8020220a:	ed04                	sd	s1,24(a0)
        sd s2,  32(a0)
    8020220c:	03253023          	sd	s2,32(a0)
        sd s3,  40(a0)
    80202210:	03353423          	sd	s3,40(a0)
        sd s4,  48(a0)
    80202214:	03453823          	sd	s4,48(a0)
        sd s5,  56(a0)
    80202218:	03553c23          	sd	s5,56(a0)
        sd s6,  64(a0)
    8020221c:	05653023          	sd	s6,64(a0)
        sd s7,  72(a0)
    80202220:	05753423          	sd	s7,72(a0)
        sd s8,  80(a0)
    80202224:	05853823          	sd	s8,80(a0)
        sd s9,  88(a0)
    80202228:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    8020222c:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80202230:	07b53423          	sd	s11,104(a0)

        ld ra,  0(a1)
    80202234:	0005b083          	ld	ra,0(a1)
        ld sp,  8(a1)
    80202238:	0085b103          	ld	sp,8(a1)
        ld s0,  16(a1)
    8020223c:	6980                	ld	s0,16(a1)
        ld s1,  24(a1)
    8020223e:	6d84                	ld	s1,24(a1)
        ld s2,  32(a1)
    80202240:	0205b903          	ld	s2,32(a1)
        ld s3,  40(a1)
    80202244:	0285b983          	ld	s3,40(a1)
        ld s4,  48(a1)
    80202248:	0305ba03          	ld	s4,48(a1)
        ld s5,  56(a1)
    8020224c:	0385ba83          	ld	s5,56(a1)
        ld s6,  64(a1)
    80202250:	0405bb03          	ld	s6,64(a1)
        ld s7,  72(a1)
    80202254:	0485bb83          	ld	s7,72(a1)
        ld s8,  80(a1)
    80202258:	0505bc03          	ld	s8,80(a1)
        ld s9,  88(a1)
    8020225c:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80202260:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80202264:	0685bd83          	ld	s11,104(a1)
        ret
    80202268:	8082                	ret

000000008020226a <cause_str>:
    }
    return 0;
}

static const char *cause_str(uint64 c)
{
    8020226a:	1141                	addi	sp,sp,-16
    8020226c:	e406                	sd	ra,8(sp)
    8020226e:	e022                	sd	s0,0(sp)
    80202270:	0800                	addi	s0,sp,16
    switch (c) {
    80202272:	47bd                	li	a5,15
    80202274:	06a7eb63          	bltu	a5,a0,802022ea <cause_str+0x80>
    80202278:	050a                	slli	a0,a0,0x2
    8020227a:	00006717          	auipc	a4,0x6
    8020227e:	bae70713          	addi	a4,a4,-1106 # 80207e28 <st.0+0x30>
    80202282:	953a                	add	a0,a0,a4
    80202284:	411c                	lw	a5,0(a0)
    80202286:	97ba                	add	a5,a5,a4
    80202288:	8782                	jr	a5
    case 0:  return "instruction address misaligned";
    8020228a:	00005517          	auipc	a0,0x5
    8020228e:	3a650513          	addi	a0,a0,934 # 80207630 <etext+0x630>
    80202292:	a029                	j	8020229c <cause_str+0x32>
    case 1:  return "instruction access fault";
    case 2:  return "illegal instruction";
    80202294:	00005517          	auipc	a0,0x5
    80202298:	3dc50513          	addi	a0,a0,988 # 80207670 <etext+0x670>
    case 12: return "instruction page fault";
    case 13: return "load page fault";
    case 15: return "store page fault";
    default: return "unknown";
    }
}
    8020229c:	60a2                	ld	ra,8(sp)
    8020229e:	6402                	ld	s0,0(sp)
    802022a0:	0141                	addi	sp,sp,16
    802022a2:	8082                	ret
    case 3:  return "breakpoint";
    802022a4:	00005517          	auipc	a0,0x5
    802022a8:	3e450513          	addi	a0,a0,996 # 80207688 <etext+0x688>
    802022ac:	bfc5                	j	8020229c <cause_str+0x32>
    case 5:  return "load access fault";
    802022ae:	00005517          	auipc	a0,0x5
    802022b2:	3ea50513          	addi	a0,a0,1002 # 80207698 <etext+0x698>
    802022b6:	b7dd                	j	8020229c <cause_str+0x32>
    case 7:  return "store access fault";
    802022b8:	00005517          	auipc	a0,0x5
    802022bc:	3f850513          	addi	a0,a0,1016 # 802076b0 <etext+0x6b0>
    802022c0:	bff1                	j	8020229c <cause_str+0x32>
    case 8:  return "ecall from user";
    802022c2:	00005517          	auipc	a0,0x5
    802022c6:	40650513          	addi	a0,a0,1030 # 802076c8 <etext+0x6c8>
    802022ca:	bfc9                	j	8020229c <cause_str+0x32>
    case 12: return "instruction page fault";
    802022cc:	00005517          	auipc	a0,0x5
    802022d0:	40c50513          	addi	a0,a0,1036 # 802076d8 <etext+0x6d8>
    802022d4:	b7e1                	j	8020229c <cause_str+0x32>
    case 13: return "load page fault";
    802022d6:	00005517          	auipc	a0,0x5
    802022da:	41a50513          	addi	a0,a0,1050 # 802076f0 <etext+0x6f0>
    802022de:	bf7d                	j	8020229c <cause_str+0x32>
    case 15: return "store page fault";
    802022e0:	00005517          	auipc	a0,0x5
    802022e4:	42050513          	addi	a0,a0,1056 # 80207700 <etext+0x700>
    802022e8:	bf55                	j	8020229c <cause_str+0x32>
    default: return "unknown";
    802022ea:	00005517          	auipc	a0,0x5
    802022ee:	42e50513          	addi	a0,a0,1070 # 80207718 <etext+0x718>
    802022f2:	b76d                	j	8020229c <cause_str+0x32>
    switch (c) {
    802022f4:	00005517          	auipc	a0,0x5
    802022f8:	35c50513          	addi	a0,a0,860 # 80207650 <etext+0x650>
    802022fc:	b745                	j	8020229c <cause_str+0x32>

00000000802022fe <devintr>:
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
    802022fe:	142027f3          	csrr	a5,scause
    if (!(scause & 0x8000000000000000UL)) return 0;   /* top bit = interrupt */
    80202302:	4501                	li	a0,0
    80202304:	0e07da63          	bgez	a5,802023f8 <devintr+0xfa>
{
    80202308:	1101                	addi	sp,sp,-32
    8020230a:	ec06                	sd	ra,24(sp)
    8020230c:	e822                	sd	s0,16(sp)
    8020230e:	1000                	addi	s0,sp,32
    uint64 code = scause & 0xff;
    80202310:	0ff7f793          	zext.b	a5,a5
    if (code == 9) {                     /* supervisor external -> PLIC */
    80202314:	4725                	li	a4,9
    80202316:	00e78a63          	beq	a5,a4,8020232a <devintr+0x2c>
    if (code == 5) {
    8020231a:	4715                	li	a4,5
    return 0;
    8020231c:	4501                	li	a0,0
    if (code == 5) {
    8020231e:	08e78263          	beq	a5,a4,802023a2 <devintr+0xa4>
}
    80202322:	60e2                	ld	ra,24(sp)
    80202324:	6442                	ld	s0,16(sp)
    80202326:	6105                	addi	sp,sp,32
    80202328:	8082                	ret
    8020232a:	e426                	sd	s1,8(sp)
        int irq = hal_intc_claim();
    8020232c:	00004097          	auipc	ra,0x4
    80202330:	d10080e7          	jalr	-752(ra) # 8020603c <hal_intc_claim>
    80202334:	84aa                	mv	s1,a0
        if (irq == fdt.uart_irq) {
    80202336:	00027797          	auipc	a5,0x27
    8020233a:	d027a783          	lw	a5,-766(a5) # 80229038 <fdt+0x20>
    8020233e:	00a78663          	beq	a5,a0,8020234a <devintr+0x4c>
        return 1;
    80202342:	4505                	li	a0,1
        } else if (irq && irq == hal_block_irq()) {
    80202344:	e09d                	bnez	s1,8020236a <devintr+0x6c>
    80202346:	64a2                	ld	s1,8(sp)
    80202348:	bfe9                	j	80202322 <devintr+0x24>
            int c = hal_console_getc();
    8020234a:	00004097          	auipc	ra,0x4
    8020234e:	e7a080e7          	jalr	-390(ra) # 802061c4 <hal_console_getc>
            if (c != -1) consoleintr(c);
    80202352:	57fd                	li	a5,-1
    80202354:	00f51663          	bne	a0,a5,80202360 <devintr+0x62>
        return 1;
    80202358:	4505                	li	a0,1
        if (irq) hal_intc_complete(irq);
    8020235a:	e49d                	bnez	s1,80202388 <devintr+0x8a>
    8020235c:	64a2                	ld	s1,8(sp)
    8020235e:	b7d1                	j	80202322 <devintr+0x24>
            if (c != -1) consoleintr(c);
    80202360:	00002097          	auipc	ra,0x2
    80202364:	e54080e7          	jalr	-428(ra) # 802041b4 <consoleintr>
    80202368:	bfc5                	j	80202358 <devintr+0x5a>
        } else if (irq && irq == hal_block_irq()) {
    8020236a:	00004097          	auipc	ra,0x4
    8020236e:	efe080e7          	jalr	-258(ra) # 80206268 <hal_block_irq>
    80202372:	02950363          	beq	a0,s1,80202398 <devintr+0x9a>
            printf("devintr: unexpected PLIC irq %d\n", irq);
    80202376:	85a6                	mv	a1,s1
    80202378:	00005517          	auipc	a0,0x5
    8020237c:	3a850513          	addi	a0,a0,936 # 80207720 <etext+0x720>
    80202380:	ffffe097          	auipc	ra,0xffffe
    80202384:	fc0080e7          	jalr	-64(ra) # 80200340 <printf>
        if (irq) hal_intc_complete(irq);
    80202388:	8526                	mv	a0,s1
    8020238a:	00004097          	auipc	ra,0x4
    8020238e:	ce4080e7          	jalr	-796(ra) # 8020606e <hal_intc_complete>
        return 1;
    80202392:	4505                	li	a0,1
    80202394:	64a2                	ld	s1,8(sp)
    80202396:	b771                	j	80202322 <devintr+0x24>
            hal_block_intr();
    80202398:	00004097          	auipc	ra,0x4
    8020239c:	380080e7          	jalr	896(ra) # 80206718 <hal_block_intr>
    802023a0:	b7e5                	j	80202388 <devintr+0x8a>
        if (hal_hart_id() == 0) {        /* only hart 0 keeps the clock */
    802023a2:	00004097          	auipc	ra,0x4
    802023a6:	cfa080e7          	jalr	-774(ra) # 8020609c <hal_hart_id>
    802023aa:	c919                	beqz	a0,802023c0 <devintr+0xc2>
        hal_timer_next(1000000);
    802023ac:	000f4537          	lui	a0,0xf4
    802023b0:	24050513          	addi	a0,a0,576 # f4240 <_entry-0x8010bdc0>
    802023b4:	00004097          	auipc	ra,0x4
    802023b8:	d6c080e7          	jalr	-660(ra) # 80206120 <hal_timer_next>
        return 2;
    802023bc:	4509                	li	a0,2
    802023be:	b795                	j	80202322 <devintr+0x24>
    802023c0:	e426                	sd	s1,8(sp)
            acquire(&tickslock);
    802023c2:	0012e497          	auipc	s1,0x12e
    802023c6:	63e48493          	addi	s1,s1,1598 # 80330a00 <tickslock>
    802023ca:	8526                	mv	a0,s1
    802023cc:	fffff097          	auipc	ra,0xfffff
    802023d0:	f34080e7          	jalr	-204(ra) # 80201300 <acquire>
            ticks++;
    802023d4:	0013d517          	auipc	a0,0x13d
    802023d8:	c4450513          	addi	a0,a0,-956 # 8033f018 <ticks>
    802023dc:	611c                	ld	a5,0(a0)
    802023de:	0785                	addi	a5,a5,1
    802023e0:	e11c                	sd	a5,0(a0)
            wakeup(&ticks);
    802023e2:	00000097          	auipc	ra,0x0
    802023e6:	aee080e7          	jalr	-1298(ra) # 80201ed0 <wakeup>
            release(&tickslock);
    802023ea:	8526                	mv	a0,s1
    802023ec:	fffff097          	auipc	ra,0xfffff
    802023f0:	fc4080e7          	jalr	-60(ra) # 802013b0 <release>
    802023f4:	64a2                	ld	s1,8(sp)
    802023f6:	bf5d                	j	802023ac <devintr+0xae>
}
    802023f8:	8082                	ret

00000000802023fa <trapinit_hart>:
{
    802023fa:	1101                	addi	sp,sp,-32
    802023fc:	ec06                	sd	ra,24(sp)
    802023fe:	e822                	sd	s0,16(sp)
    80202400:	e426                	sd	s1,8(sp)
    80202402:	1000                	addi	s0,sp,32
static inline void   w_stvec(uint64 x){ asm volatile("csrw stvec, %0"::"r"(x)); }
    80202404:	00000797          	auipc	a5,0x0
    80202408:	32c78793          	addi	a5,a5,812 # 80202730 <kernelvec>
    8020240c:	10579073          	csrw	stvec,a5
    hal_intc_enable(fdt.uart_irq);              /* priority 1; 0 = never fires */
    80202410:	00027497          	auipc	s1,0x27
    80202414:	c0848493          	addi	s1,s1,-1016 # 80229018 <fdt>
    80202418:	5088                	lw	a0,32(s1)
    8020241a:	00004097          	auipc	ra,0x4
    8020241e:	b8e080e7          	jalr	-1138(ra) # 80205fa8 <hal_intc_enable>
    hal_intc_hart_init(hal_hart_id());
    80202422:	00004097          	auipc	ra,0x4
    80202426:	c7a080e7          	jalr	-902(ra) # 8020609c <hal_hart_id>
    8020242a:	00004097          	auipc	ra,0x4
    8020242e:	ba2080e7          	jalr	-1118(ra) # 80205fcc <hal_intc_hart_init>
    hal_intc_enable_hart(hal_hart_id(), fdt.uart_irq);
    80202432:	00004097          	auipc	ra,0x4
    80202436:	c6a080e7          	jalr	-918(ra) # 8020609c <hal_hart_id>
    8020243a:	508c                	lw	a1,32(s1)
    8020243c:	00004097          	auipc	ra,0x4
    80202440:	bba080e7          	jalr	-1094(ra) # 80205ff6 <hal_intc_enable_hart>
    if (hal_block_irq()) {
    80202444:	00004097          	auipc	ra,0x4
    80202448:	e24080e7          	jalr	-476(ra) # 80206268 <hal_block_irq>
    8020244c:	e915                	bnez	a0,80202480 <trapinit_hart+0x86>
static inline uint64 r_sie(void){ uint64 x; asm volatile("csrr %0, sie":"=r"(x)); return x; }
    8020244e:	104027f3          	csrr	a5,sie
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80202452:	2227e793          	ori	a5,a5,546
static inline void   w_sie(uint64 x){ asm volatile("csrw sie, %0"::"r"(x)); }
    80202456:	10479073          	csrw	sie,a5
    hal_timer_next(1000000);
    8020245a:	000f4537          	lui	a0,0xf4
    8020245e:	24050513          	addi	a0,a0,576 # f4240 <_entry-0x8010bdc0>
    80202462:	00004097          	auipc	ra,0x4
    80202466:	cbe080e7          	jalr	-834(ra) # 80206120 <hal_timer_next>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    8020246a:	100027f3          	csrr	a5,sstatus
static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
    8020246e:	0027e793          	ori	a5,a5,2
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    80202472:	10079073          	csrw	sstatus,a5
}
    80202476:	60e2                	ld	ra,24(sp)
    80202478:	6442                	ld	s0,16(sp)
    8020247a:	64a2                	ld	s1,8(sp)
    8020247c:	6105                	addi	sp,sp,32
    8020247e:	8082                	ret
        hal_intc_enable(hal_block_irq());
    80202480:	00004097          	auipc	ra,0x4
    80202484:	de8080e7          	jalr	-536(ra) # 80206268 <hal_block_irq>
    80202488:	00004097          	auipc	ra,0x4
    8020248c:	b20080e7          	jalr	-1248(ra) # 80205fa8 <hal_intc_enable>
        hal_intc_enable_hart(hal_hart_id(), hal_block_irq());
    80202490:	00004097          	auipc	ra,0x4
    80202494:	c0c080e7          	jalr	-1012(ra) # 8020609c <hal_hart_id>
    80202498:	84aa                	mv	s1,a0
    8020249a:	00004097          	auipc	ra,0x4
    8020249e:	dce080e7          	jalr	-562(ra) # 80206268 <hal_block_irq>
    802024a2:	85aa                	mv	a1,a0
    802024a4:	8526                	mv	a0,s1
    802024a6:	00004097          	auipc	ra,0x4
    802024aa:	b50080e7          	jalr	-1200(ra) # 80205ff6 <hal_intc_enable_hart>
    802024ae:	b745                	j	8020244e <trapinit_hart+0x54>

00000000802024b0 <kerneltrap>:

/* Trap while already in the kernel. */
void kerneltrap(void)
{
    802024b0:	7179                	addi	sp,sp,-48
    802024b2:	f406                	sd	ra,40(sp)
    802024b4:	f022                	sd	s0,32(sp)
    802024b6:	ec26                	sd	s1,24(sp)
    802024b8:	e84a                	sd	s2,16(sp)
    802024ba:	e44e                	sd	s3,8(sp)
    802024bc:	1800                	addi	s0,sp,48
static inline uint64 r_sepc(void){ uint64 x; asm volatile("csrr %0, sepc":"=r"(x)); return x; }
    802024be:	14102973          	csrr	s2,sepc
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    802024c2:	100024f3          	csrr	s1,sstatus
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
    802024c6:	142029f3          	csrr	s3,scause
    uint64 sepc     = r_sepc();
    uint64 sstatus  = r_sstatus();
    uint64 scause   = r_scause();

    if ((sstatus & SSTATUS_SPP) == 0) panic("kerneltrap: not from S-mode");
    802024ca:	1004f793          	andi	a5,s1,256
    802024ce:	cb85                	beqz	a5,802024fe <kerneltrap+0x4e>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    802024d0:	100027f3          	csrr	a5,sstatus
static inline int  intr_get(void){ return (r_sstatus() & SSTATUS_SIE) != 0; }
    802024d4:	8b89                	andi	a5,a5,2
    if (intr_get()) panic("kerneltrap: interrupts were enabled");
    802024d6:	ef85                	bnez	a5,8020250e <kerneltrap+0x5e>

    int which = devintr();
    802024d8:	00000097          	auipc	ra,0x0
    802024dc:	e26080e7          	jalr	-474(ra) # 802022fe <devintr>
    if (which == 0) {
    802024e0:	cd1d                	beqz	a0,8020251e <kerneltrap+0x6e>
        printf("\nkerneltrap: %s\n", cause_str(scause & 0xff));
        panic("kernel exception");
    }
    /* Timer: give up the CPU, but only if we are running a process. */
    if (which == 2 && myproc() && myproc()->state == RUNNING)
    802024e2:	4789                	li	a5,2
    802024e4:	06f50463          	beq	a0,a5,8020254c <kerneltrap+0x9c>
static inline void   w_sepc(uint64 x){ asm volatile("csrw sepc, %0"::"r"(x)); }
    802024e8:	14191073          	csrw	sepc,s2
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    802024ec:	10049073          	csrw	sstatus,s1
        yield();

    /* yield() may have run other code; restore what sret needs. */
    w_sepc(sepc);
    w_sstatus(sstatus);
}
    802024f0:	70a2                	ld	ra,40(sp)
    802024f2:	7402                	ld	s0,32(sp)
    802024f4:	64e2                	ld	s1,24(sp)
    802024f6:	6942                	ld	s2,16(sp)
    802024f8:	69a2                	ld	s3,8(sp)
    802024fa:	6145                	addi	sp,sp,48
    802024fc:	8082                	ret
    if ((sstatus & SSTATUS_SPP) == 0) panic("kerneltrap: not from S-mode");
    802024fe:	00005517          	auipc	a0,0x5
    80202502:	24a50513          	addi	a0,a0,586 # 80207748 <etext+0x748>
    80202506:	ffffe097          	auipc	ra,0xffffe
    8020250a:	0aa080e7          	jalr	170(ra) # 802005b0 <panic>
    if (intr_get()) panic("kerneltrap: interrupts were enabled");
    8020250e:	00005517          	auipc	a0,0x5
    80202512:	25a50513          	addi	a0,a0,602 # 80207768 <etext+0x768>
    80202516:	ffffe097          	auipc	ra,0xffffe
    8020251a:	09a080e7          	jalr	154(ra) # 802005b0 <panic>
        printf("\nkerneltrap: %s\n", cause_str(scause & 0xff));
    8020251e:	0ff9f513          	zext.b	a0,s3
    80202522:	00000097          	auipc	ra,0x0
    80202526:	d48080e7          	jalr	-696(ra) # 8020226a <cause_str>
    8020252a:	85aa                	mv	a1,a0
    8020252c:	00005517          	auipc	a0,0x5
    80202530:	26450513          	addi	a0,a0,612 # 80207790 <etext+0x790>
    80202534:	ffffe097          	auipc	ra,0xffffe
    80202538:	e0c080e7          	jalr	-500(ra) # 80200340 <printf>
        panic("kernel exception");
    8020253c:	00005517          	auipc	a0,0x5
    80202540:	26c50513          	addi	a0,a0,620 # 802077a8 <etext+0x7a8>
    80202544:	ffffe097          	auipc	ra,0xffffe
    80202548:	06c080e7          	jalr	108(ra) # 802005b0 <panic>
    if (which == 2 && myproc() && myproc()->state == RUNNING)
    8020254c:	fffff097          	auipc	ra,0xfffff
    80202550:	192080e7          	jalr	402(ra) # 802016de <myproc>
    80202554:	d951                	beqz	a0,802024e8 <kerneltrap+0x38>
    80202556:	fffff097          	auipc	ra,0xfffff
    8020255a:	188080e7          	jalr	392(ra) # 802016de <myproc>
    8020255e:	4d18                	lw	a4,24(a0)
    80202560:	4791                	li	a5,4
    80202562:	f8f713e3          	bne	a4,a5,802024e8 <kerneltrap+0x38>
        yield();
    80202566:	fffff097          	auipc	ra,0xfffff
    8020256a:	7ae080e7          	jalr	1966(ra) # 80201d14 <yield>
    8020256e:	bfad                	j	802024e8 <kerneltrap+0x38>

0000000080202570 <usertrapret>:
    if (p->killed) exit(-1);
    usertrapret();
}

void usertrapret(void)
{
    80202570:	1141                	addi	sp,sp,-16
    80202572:	e406                	sd	ra,8(sp)
    80202574:	e022                	sd	s0,0(sp)
    80202576:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80202578:	fffff097          	auipc	ra,0xfffff
    8020257c:	166080e7          	jalr	358(ra) # 802016de <myproc>
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    80202580:	100027f3          	csrr	a5,sstatus
static inline void intr_off(void){ w_sstatus(r_sstatus() & ~SSTATUS_SIE); }
    80202584:	9bf5                	andi	a5,a5,-3
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    80202586:	10079073          	csrw	sstatus,a5
static inline void   w_stvec(uint64 x){ asm volatile("csrw stvec, %0"::"r"(x)); }
    8020258a:	00000797          	auipc	a5,0x0
    8020258e:	20678793          	addi	a5,a5,518 # 80202790 <uservec>
    80202592:	10579073          	csrw	stvec,a5

    intr_off();                       /* no interrupts between stvec and sret */
    w_stvec((uint64)uservec);

    p->tf->kernel_satp   = r_satp();
    80202596:	6d3c                	ld	a5,88(a0)
static inline uint64 r_satp(void){ uint64 x; asm volatile("csrr %0, satp":"=r"(x)); return x; }
    80202598:	18002773          	csrr	a4,satp
    8020259c:	e398                	sd	a4,0(a5)
    p->tf->kernel_sp     = p->kstack + 4 * PGSIZE;   /* top of the kernel stack */
    8020259e:	6d38                	ld	a4,88(a0)
    802025a0:	613c                	ld	a5,64(a0)
    802025a2:	6691                	lui	a3,0x4
    802025a4:	97b6                	add	a5,a5,a3
    802025a6:	e71c                	sd	a5,8(a4)
    p->tf->kernel_trap   = (uint64)usertrap;
    802025a8:	6d3c                	ld	a5,88(a0)
    802025aa:	00000717          	auipc	a4,0x0
    802025ae:	03870713          	addi	a4,a4,56 # 802025e2 <usertrap>
    802025b2:	eb98                	sd	a4,16(a5)
    p->tf->kernel_hartid = r_tp();
    802025b4:	6d3c                	ld	a5,88(a0)
static inline uint64 r_tp(void){ uint64 x; asm volatile("mv %0, tp":"=r"(x)); return x; }
    802025b6:	8712                	mv	a4,tp
    802025b8:	f398                	sd	a4,32(a5)
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    802025ba:	100027f3          	csrr	a5,sstatus

    uint64 x = r_sstatus();
    x &= ~SSTATUS_SPP;                /* SPP=0 -> sret drops us to U-mode */
    802025be:	eff7f793          	andi	a5,a5,-257
    x |= SSTATUS_SPIE;                /* re-enable interrupts in user mode */
    802025c2:	0207e793          	ori	a5,a5,32
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    802025c6:	10079073          	csrw	sstatus,a5
    w_sstatus(x);
    w_sepc(p->tf->epc);
    802025ca:	6d28                	ld	a0,88(a0)
static inline void   w_sepc(uint64 x){ asm volatile("csrw sepc, %0"::"r"(x)); }
    802025cc:	6d1c                	ld	a5,24(a0)
    802025ce:	14179073          	csrw	sepc,a5

    userret(p->tf);
    802025d2:	00000097          	auipc	ra,0x0
    802025d6:	24a080e7          	jalr	586(ra) # 8020281c <userret>
}
    802025da:	60a2                	ld	ra,8(sp)
    802025dc:	6402                	ld	s0,0(sp)
    802025de:	0141                	addi	sp,sp,16
    802025e0:	8082                	ret

00000000802025e2 <usertrap>:
{
    802025e2:	7179                	addi	sp,sp,-48
    802025e4:	f406                	sd	ra,40(sp)
    802025e6:	f022                	sd	s0,32(sp)
    802025e8:	1800                	addi	s0,sp,48
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    802025ea:	100027f3          	csrr	a5,sstatus
    if (r_sstatus() & SSTATUS_SPP) panic("usertrap: came from S-mode");
    802025ee:	1007f793          	andi	a5,a5,256
    802025f2:	efa9                	bnez	a5,8020264c <usertrap+0x6a>
    802025f4:	ec26                	sd	s1,24(sp)
    802025f6:	e84a                	sd	s2,16(sp)
static inline void   w_stvec(uint64 x){ asm volatile("csrw stvec, %0"::"r"(x)); }
    802025f8:	00000797          	auipc	a5,0x0
    802025fc:	13878793          	addi	a5,a5,312 # 80202730 <kernelvec>
    80202600:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80202604:	fffff097          	auipc	ra,0xfffff
    80202608:	0da080e7          	jalr	218(ra) # 802016de <myproc>
    8020260c:	84aa                	mv	s1,a0
    p->tf->epc = r_sepc();
    8020260e:	6d3c                	ld	a5,88(a0)
static inline uint64 r_sepc(void){ uint64 x; asm volatile("csrr %0, sepc":"=r"(x)); return x; }
    80202610:	14102773          	csrr	a4,sepc
    80202614:	ef98                	sd	a4,24(a5)
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
    80202616:	14202973          	csrr	s2,scause
    if (scause == 8) {               /* ecall: a system call */
    8020261a:	47a1                	li	a5,8
    8020261c:	04f90463          	beq	s2,a5,80202664 <usertrap+0x82>
    } else if (scause == 15 || scause == 13) {   /* store / load page fault */
    80202620:	ffd97793          	andi	a5,s2,-3
    80202624:	4735                	li	a4,13
    80202626:	08e78263          	beq	a5,a4,802026aa <usertrap+0xc8>
        int which = devintr();
    8020262a:	00000097          	auipc	ra,0x0
    8020262e:	cd4080e7          	jalr	-812(ra) # 802022fe <devintr>
        if (which == 0) {
    80202632:	c95d                	beqz	a0,802026e8 <usertrap+0x106>
        if (which == 2 && p->state == RUNNING) yield();
    80202634:	4789                	li	a5,2
    80202636:	04f51763          	bne	a0,a5,80202684 <usertrap+0xa2>
    8020263a:	4c98                	lw	a4,24(s1)
    8020263c:	4791                	li	a5,4
    8020263e:	04f71363          	bne	a4,a5,80202684 <usertrap+0xa2>
    80202642:	fffff097          	auipc	ra,0xfffff
    80202646:	6d2080e7          	jalr	1746(ra) # 80201d14 <yield>
    8020264a:	a82d                	j	80202684 <usertrap+0xa2>
    8020264c:	ec26                	sd	s1,24(sp)
    8020264e:	e84a                	sd	s2,16(sp)
    80202650:	e44e                	sd	s3,8(sp)
    80202652:	e052                	sd	s4,0(sp)
    if (r_sstatus() & SSTATUS_SPP) panic("usertrap: came from S-mode");
    80202654:	00005517          	auipc	a0,0x5
    80202658:	16c50513          	addi	a0,a0,364 # 802077c0 <etext+0x7c0>
    8020265c:	ffffe097          	auipc	ra,0xffffe
    80202660:	f54080e7          	jalr	-172(ra) # 802005b0 <panic>
        if (p->killed) exit(-1);
    80202664:	551c                	lw	a5,40(a0)
    80202666:	eb9d                	bnez	a5,8020269c <usertrap+0xba>
        p->tf->epc += 4;             /* return AFTER the ecall, not onto it */
    80202668:	6d38                	ld	a4,88(a0)
    8020266a:	6f1c                	ld	a5,24(a4)
    8020266c:	0791                	addi	a5,a5,4
    8020266e:	ef1c                	sd	a5,24(a4)
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
    80202670:	100027f3          	csrr	a5,sstatus
static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
    80202674:	0027e793          	ori	a5,a5,2
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
    80202678:	10079073          	csrw	sstatus,a5
        syscall();
    8020267c:	00001097          	auipc	ra,0x1
    80202680:	dc8080e7          	jalr	-568(ra) # 80203444 <syscall>
    if (p->killed) exit(-1);
    80202684:	549c                	lw	a5,40(s1)
    80202686:	ebd9                	bnez	a5,8020271c <usertrap+0x13a>
    usertrapret();
    80202688:	00000097          	auipc	ra,0x0
    8020268c:	ee8080e7          	jalr	-280(ra) # 80202570 <usertrapret>
    80202690:	64e2                	ld	s1,24(sp)
    80202692:	6942                	ld	s2,16(sp)
}
    80202694:	70a2                	ld	ra,40(sp)
    80202696:	7402                	ld	s0,32(sp)
    80202698:	6145                	addi	sp,sp,48
    8020269a:	8082                	ret
    8020269c:	e44e                	sd	s3,8(sp)
    8020269e:	e052                	sd	s4,0(sp)
        if (p->killed) exit(-1);
    802026a0:	557d                	li	a0,-1
    802026a2:	00000097          	auipc	ra,0x0
    802026a6:	8a4080e7          	jalr	-1884(ra) # 80201f46 <exit>
    802026aa:	e44e                	sd	s3,8(sp)
    802026ac:	e052                	sd	s4,0(sp)
static inline uint64 r_stval(void){ uint64 x; asm volatile("csrr %0, stval":"=r"(x)); return x; }
    802026ae:	14302a73          	csrr	s4,stval
        printf("usertrap: pid %d %s at va %p (sepc %p) - killing\n",
    802026b2:	03052983          	lw	s3,48(a0)
    802026b6:	854a                	mv	a0,s2
    802026b8:	00000097          	auipc	ra,0x0
    802026bc:	bb2080e7          	jalr	-1102(ra) # 8020226a <cause_str>
    802026c0:	862a                	mv	a2,a0
    802026c2:	6cbc                	ld	a5,88(s1)
    802026c4:	6f98                	ld	a4,24(a5)
    802026c6:	86d2                	mv	a3,s4
    802026c8:	85ce                	mv	a1,s3
    802026ca:	00005517          	auipc	a0,0x5
    802026ce:	11650513          	addi	a0,a0,278 # 802077e0 <etext+0x7e0>
    802026d2:	ffffe097          	auipc	ra,0xffffe
    802026d6:	c6e080e7          	jalr	-914(ra) # 80200340 <printf>
        p->killed = 1;
    802026da:	4785                	li	a5,1
    802026dc:	d49c                	sw	a5,40(s1)
    if (p->killed) exit(-1);
    802026de:	557d                	li	a0,-1
    802026e0:	00000097          	auipc	ra,0x0
    802026e4:	866080e7          	jalr	-1946(ra) # 80201f46 <exit>
    802026e8:	e44e                	sd	s3,8(sp)
            printf("usertrap: pid %d unexpected %s (scause %p, stval %p) - killing\n",
    802026ea:	0304a983          	lw	s3,48(s1)
    802026ee:	0ff97513          	zext.b	a0,s2
    802026f2:	00000097          	auipc	ra,0x0
    802026f6:	b78080e7          	jalr	-1160(ra) # 8020226a <cause_str>
    802026fa:	862a                	mv	a2,a0
    802026fc:	14302773          	csrr	a4,stval
    80202700:	86ca                	mv	a3,s2
    80202702:	85ce                	mv	a1,s3
    80202704:	00005517          	auipc	a0,0x5
    80202708:	11450513          	addi	a0,a0,276 # 80207818 <etext+0x818>
    8020270c:	ffffe097          	auipc	ra,0xffffe
    80202710:	c34080e7          	jalr	-972(ra) # 80200340 <printf>
            p->killed = 1;
    80202714:	4785                	li	a5,1
    80202716:	d49c                	sw	a5,40(s1)
    if (p->killed) exit(-1);
    80202718:	e052                	sd	s4,0(sp)
    8020271a:	b7d1                	j	802026de <usertrap+0xfc>
    8020271c:	e44e                	sd	s3,8(sp)
    8020271e:	e052                	sd	s4,0(sp)
    80202720:	bf7d                	j	802026de <usertrap+0xfc>
	...

0000000080202730 <kernelvec>:
        .globl kernelvec
        .align 4
kernelvec:
        # We were already in the kernel: our sp is a valid kernel stack.
        # Save every caller-saved register - kerneltrap() is C and may clobber them.
        addi    sp, sp, -256
    80202730:	7111                	addi	sp,sp,-256
        sd      ra, 0(sp)
    80202732:	e006                	sd	ra,0(sp)
        sd      sp, 8(sp)
    80202734:	e40a                	sd	sp,8(sp)
        sd      gp, 16(sp)
    80202736:	e80e                	sd	gp,16(sp)
        sd      tp, 24(sp)
    80202738:	ec12                	sd	tp,24(sp)
        sd      t0, 32(sp)
    8020273a:	f016                	sd	t0,32(sp)
        sd      t1, 40(sp)
    8020273c:	f41a                	sd	t1,40(sp)
        sd      t2, 48(sp)
    8020273e:	f81e                	sd	t2,48(sp)
        sd      a0, 72(sp)
    80202740:	e4aa                	sd	a0,72(sp)
        sd      a1, 80(sp)
    80202742:	e8ae                	sd	a1,80(sp)
        sd      a2, 88(sp)
    80202744:	ecb2                	sd	a2,88(sp)
        sd      a3, 96(sp)
    80202746:	f0b6                	sd	a3,96(sp)
        sd      a4, 104(sp)
    80202748:	f4ba                	sd	a4,104(sp)
        sd      a5, 112(sp)
    8020274a:	f8be                	sd	a5,112(sp)
        sd      a6, 120(sp)
    8020274c:	fcc2                	sd	a6,120(sp)
        sd      a7, 128(sp)
    8020274e:	e146                	sd	a7,128(sp)
        sd      t3, 216(sp)
    80202750:	edf2                	sd	t3,216(sp)
        sd      t4, 224(sp)
    80202752:	f1f6                	sd	t4,224(sp)
        sd      t5, 232(sp)
    80202754:	f5fa                	sd	t5,232(sp)
        sd      t6, 240(sp)
    80202756:	f9fe                	sd	t6,240(sp)

        call    kerneltrap
    80202758:	00000097          	auipc	ra,0x0
    8020275c:	d58080e7          	jalr	-680(ra) # 802024b0 <kerneltrap>

        ld      ra, 0(sp)
    80202760:	6082                	ld	ra,0(sp)
        ld      gp, 16(sp)
    80202762:	61c2                	ld	gp,16(sp)
        # NOT tp - kerneltrap may have moved us to another hart's scheduler.
        ld      t0, 32(sp)
    80202764:	7282                	ld	t0,32(sp)
        ld      t1, 40(sp)
    80202766:	7322                	ld	t1,40(sp)
        ld      t2, 48(sp)
    80202768:	73c2                	ld	t2,48(sp)
        ld      a0, 72(sp)
    8020276a:	6526                	ld	a0,72(sp)
        ld      a1, 80(sp)
    8020276c:	65c6                	ld	a1,80(sp)
        ld      a2, 88(sp)
    8020276e:	6666                	ld	a2,88(sp)
        ld      a3, 96(sp)
    80202770:	7686                	ld	a3,96(sp)
        ld      a4, 104(sp)
    80202772:	7726                	ld	a4,104(sp)
        ld      a5, 112(sp)
    80202774:	77c6                	ld	a5,112(sp)
        ld      a6, 120(sp)
    80202776:	7866                	ld	a6,120(sp)
        ld      a7, 128(sp)
    80202778:	688a                	ld	a7,128(sp)
        ld      t3, 216(sp)
    8020277a:	6e6e                	ld	t3,216(sp)
        ld      t4, 224(sp)
    8020277c:	7e8e                	ld	t4,224(sp)
        ld      t5, 232(sp)
    8020277e:	7f2e                	ld	t5,232(sp)
        ld      t6, 240(sp)
    80202780:	7fce                	ld	t6,240(sp)
        addi    sp, sp, 256
    80202782:	6111                	addi	sp,sp,256
        # sepc/sstatus were saved+restored by kerneltrap() in C.
        sret
    80202784:	10200073          	sret
    80202788:	00000013          	nop
    8020278c:	00000013          	nop

0000000080202790 <uservec>:
        .globl uservec
        .globl userret
        .globl usertrap
        .align 4
uservec:
        csrrw   a0, sscratch, a0        # a0 = &tf ; sscratch = user's a0
    80202790:	14051573          	csrrw	a0,sscratch,a0

        sd ra,  40(a0)
    80202794:	02153423          	sd	ra,40(a0)
        sd sp,  48(a0)
    80202798:	02253823          	sd	sp,48(a0)
        sd gp,  56(a0)
    8020279c:	02353c23          	sd	gp,56(a0)
        sd tp,  64(a0)
    802027a0:	04453023          	sd	tp,64(a0)
        sd t0,  72(a0)
    802027a4:	04553423          	sd	t0,72(a0)
        sd t1,  80(a0)
    802027a8:	04653823          	sd	t1,80(a0)
        sd t2,  88(a0)
    802027ac:	04753c23          	sd	t2,88(a0)
        sd s0,  96(a0)
    802027b0:	f120                	sd	s0,96(a0)
        sd s1,  104(a0)
    802027b2:	f524                	sd	s1,104(a0)
        sd a1,  120(a0)
    802027b4:	fd2c                	sd	a1,120(a0)
        sd a2,  128(a0)
    802027b6:	e150                	sd	a2,128(a0)
        sd a3,  136(a0)
    802027b8:	e554                	sd	a3,136(a0)
        sd a4,  144(a0)
    802027ba:	e958                	sd	a4,144(a0)
        sd a5,  152(a0)
    802027bc:	ed5c                	sd	a5,152(a0)
        sd a6,  160(a0)
    802027be:	0b053023          	sd	a6,160(a0)
        sd a7,  168(a0)
    802027c2:	0b153423          	sd	a7,168(a0)
        sd s2,  176(a0)
    802027c6:	0b253823          	sd	s2,176(a0)
        sd s3,  184(a0)
    802027ca:	0b353c23          	sd	s3,184(a0)
        sd s4,  192(a0)
    802027ce:	0d453023          	sd	s4,192(a0)
        sd s5,  200(a0)
    802027d2:	0d553423          	sd	s5,200(a0)
        sd s6,  208(a0)
    802027d6:	0d653823          	sd	s6,208(a0)
        sd s7,  216(a0)
    802027da:	0d753c23          	sd	s7,216(a0)
        sd s8,  224(a0)
    802027de:	0f853023          	sd	s8,224(a0)
        sd s9,  232(a0)
    802027e2:	0f953423          	sd	s9,232(a0)
        sd s10, 240(a0)
    802027e6:	0fa53823          	sd	s10,240(a0)
        sd s11, 248(a0)
    802027ea:	0fb53c23          	sd	s11,248(a0)
        sd t3,  256(a0)
    802027ee:	11c53023          	sd	t3,256(a0)
        sd t4,  264(a0)
    802027f2:	11d53423          	sd	t4,264(a0)
        sd t5,  272(a0)
    802027f6:	11e53823          	sd	t5,272(a0)
        sd t6,  280(a0)
    802027fa:	11f53c23          	sd	t6,280(a0)

        csrr    t0, sscratch            # t0 = user's original a0
    802027fe:	140022f3          	csrr	t0,sscratch
        sd      t0, 112(a0)             # tf->a0
    80202802:	06553823          	sd	t0,112(a0)

        csrr    t1, sepc
    80202806:	14102373          	csrr	t1,sepc
        sd      t1, 24(a0)              # tf->epc = where user was
    8020280a:	00653c23          	sd	t1,24(a0)

        ld      tp, 32(a0)              # restore our hartid into tp
    8020280e:	02053203          	ld	tp,32(a0)
        ld      sp, 8(a0)               # switch to the kernel stack
    80202812:	00853103          	ld	sp,8(a0)
        ld      t1, 16(a0)              # tf->kernel_trap = &usertrap
    80202816:	01053303          	ld	t1,16(a0)
        jr      t1
    8020281a:	8302                	jr	t1

000000008020281c <userret>:

# void userret(struct trapframe *tf)  -- a0 = tf
userret:
        csrw    sscratch, a0            # so the next uservec can find it
    8020281c:	14051073          	csrw	sscratch,a0

        ld t0,  24(a0)
    80202820:	01853283          	ld	t0,24(a0)
        csrw    sepc, t0                # return to where the user left off
    80202824:	14129073          	csrw	sepc,t0

        ld ra,  40(a0)
    80202828:	02853083          	ld	ra,40(a0)
        ld sp,  48(a0)
    8020282c:	03053103          	ld	sp,48(a0)
        ld gp,  56(a0)
    80202830:	03853183          	ld	gp,56(a0)
        ld tp,  64(a0)
    80202834:	04053203          	ld	tp,64(a0)
        ld t0,  72(a0)
    80202838:	04853283          	ld	t0,72(a0)
        ld t1,  80(a0)
    8020283c:	05053303          	ld	t1,80(a0)
        ld t2,  88(a0)
    80202840:	05853383          	ld	t2,88(a0)
        ld s0,  96(a0)
    80202844:	7120                	ld	s0,96(a0)
        ld s1,  104(a0)
    80202846:	7524                	ld	s1,104(a0)
        ld a1,  120(a0)
    80202848:	7d2c                	ld	a1,120(a0)
        ld a2,  128(a0)
    8020284a:	6150                	ld	a2,128(a0)
        ld a3,  136(a0)
    8020284c:	6554                	ld	a3,136(a0)
        ld a4,  144(a0)
    8020284e:	6958                	ld	a4,144(a0)
        ld a5,  152(a0)
    80202850:	6d5c                	ld	a5,152(a0)
        ld a6,  160(a0)
    80202852:	0a053803          	ld	a6,160(a0)
        ld a7,  168(a0)
    80202856:	0a853883          	ld	a7,168(a0)
        ld s2,  176(a0)
    8020285a:	0b053903          	ld	s2,176(a0)
        ld s3,  184(a0)
    8020285e:	0b853983          	ld	s3,184(a0)
        ld s4,  192(a0)
    80202862:	0c053a03          	ld	s4,192(a0)
        ld s5,  200(a0)
    80202866:	0c853a83          	ld	s5,200(a0)
        ld s6,  208(a0)
    8020286a:	0d053b03          	ld	s6,208(a0)
        ld s7,  216(a0)
    8020286e:	0d853b83          	ld	s7,216(a0)
        ld s8,  224(a0)
    80202872:	0e053c03          	ld	s8,224(a0)
        ld s9,  232(a0)
    80202876:	0e853c83          	ld	s9,232(a0)
        ld s10, 240(a0)
    8020287a:	0f053d03          	ld	s10,240(a0)
        ld s11, 248(a0)
    8020287e:	0f853d83          	ld	s11,248(a0)
        ld t3,  256(a0)
    80202882:	10053e03          	ld	t3,256(a0)
        ld t4,  264(a0)
    80202886:	10853e83          	ld	t4,264(a0)
        ld t5,  272(a0)
    8020288a:	11053f03          	ld	t5,272(a0)
        ld t6,  280(a0)
    8020288e:	11853f83          	ld	t6,280(a0)

        ld a0,  112(a0)                 # finally, the user's a0 (syscall retval)
    80202892:	7928                	ld	a0,112(a0)
        sret
    80202894:	10200073          	sret
    80202898:	00000013          	nop
    8020289c:	00000013          	nop

00000000802028a0 <freewalk_user>:
}

/* Free ONLY the user half of the tree (indices 0..1). Kernel entries are
 * borrowed, not owned - freeing them would take down every other process. */
static void freewalk_user(pagetable_t pt, int level)
{
    802028a0:	7139                	addi	sp,sp,-64
    802028a2:	fc06                	sd	ra,56(sp)
    802028a4:	f822                	sd	s0,48(sp)
    802028a6:	f426                	sd	s1,40(sp)
    802028a8:	f04a                	sd	s2,32(sp)
    802028aa:	ec4e                	sd	s3,24(sp)
    802028ac:	e852                	sd	s4,16(sp)
    802028ae:	e456                	sd	s5,8(sp)
    802028b0:	0080                	addi	s0,sp,64
    802028b2:	89aa                	mv	s3,a0
    802028b4:	8a2e                	mv	s4,a1
    int limit = (level == 2) ? KERN_IDX_LO : 512;
    802028b6:	4789                	li	a5,2
    802028b8:	20000913          	li	s2,512
    802028bc:	02f58c63          	beq	a1,a5,802028f4 <freewalk_user+0x54>
    for (int i = 0; i < limit; i++) {
    802028c0:	84ce                	mv	s1,s3
    802028c2:	090e                	slli	s2,s2,0x3
    802028c4:	994e                	add	s2,s2,s3
        pte_t pte = pt[i];
        if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    802028c6:	4a85                	li	s5,1
        pte_t pte = pt[i];
    802028c8:	609c                	ld	a5,0(s1)
        if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0) {
    802028ca:	00f7f713          	andi	a4,a5,15
    802028ce:	03570563          	beq	a4,s5,802028f8 <freewalk_user+0x58>
    for (int i = 0; i < limit; i++) {
    802028d2:	04a1                	addi	s1,s1,8
    802028d4:	ff249ae3          	bne	s1,s2,802028c8 <freewalk_user+0x28>
            freewalk_user((pagetable_t)PTE2PA(pte), level - 1);
            pt[i] = 0;
        }
    }
    pfree((void *)pt);
    802028d8:	854e                	mv	a0,s3
    802028da:	fffff097          	auipc	ra,0xfffff
    802028de:	8a4080e7          	jalr	-1884(ra) # 8020117e <pfree>
}
    802028e2:	70e2                	ld	ra,56(sp)
    802028e4:	7442                	ld	s0,48(sp)
    802028e6:	74a2                	ld	s1,40(sp)
    802028e8:	7902                	ld	s2,32(sp)
    802028ea:	69e2                	ld	s3,24(sp)
    802028ec:	6a42                	ld	s4,16(sp)
    802028ee:	6aa2                	ld	s5,8(sp)
    802028f0:	6121                	addi	sp,sp,64
    802028f2:	8082                	ret
    int limit = (level == 2) ? KERN_IDX_LO : 512;
    802028f4:	892e                	mv	s2,a1
    802028f6:	b7e9                	j	802028c0 <freewalk_user+0x20>
            freewalk_user((pagetable_t)PTE2PA(pte), level - 1);
    802028f8:	83a9                	srli	a5,a5,0xa
    802028fa:	fffa059b          	addiw	a1,s4,-1
    802028fe:	00c79513          	slli	a0,a5,0xc
    80202902:	00000097          	auipc	ra,0x0
    80202906:	f9e080e7          	jalr	-98(ra) # 802028a0 <freewalk_user>
            pt[i] = 0;
    8020290a:	0004b023          	sd	zero,0(s1)
    8020290e:	b7d1                	j	802028d2 <freewalk_user+0x32>

0000000080202910 <vmprint_lvl>:
    return got_null ? 0 : -1;
}

/* Implementation note. */
static void vmprint_lvl(pagetable_t pt, int level)
{
    80202910:	711d                	addi	sp,sp,-96
    80202912:	ec86                	sd	ra,88(sp)
    80202914:	e8a2                	sd	s0,80(sp)
    80202916:	e4a6                	sd	s1,72(sp)
    80202918:	e0ca                	sd	s2,64(sp)
    8020291a:	fc4e                	sd	s3,56(sp)
    8020291c:	f852                	sd	s4,48(sp)
    8020291e:	f456                	sd	s5,40(sp)
    80202920:	f05a                	sd	s6,32(sp)
    80202922:	ec5e                	sd	s7,24(sp)
    80202924:	e862                	sd	s8,16(sp)
    80202926:	e466                	sd	s9,8(sp)
    80202928:	e06a                	sd	s10,0(sp)
    8020292a:	1080                	addi	s0,sp,96
    8020292c:	892e                	mv	s2,a1
    for (int i = 0; i < 512; i++) {
    8020292e:	8b2a                	mv	s6,a0
    80202930:	4a01                	li	s4,0
        pte_t pte = pt[i];
        if (!(pte & PTE_V)) continue;
        if (level == 2 && i >= KERN_IDX_LO) continue;   /* skip borrowed kernel */
    80202932:	4b89                	li	s7,2
        for (int d = 2; d >= level; d--) printf(" ..");
    80202934:	00005a97          	auipc	s5,0x5
    80202938:	f24a8a93          	addi	s5,s5,-220 # 80207858 <etext+0x858>
        printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    8020293c:	00005c97          	auipc	s9,0x5
    80202940:	f24c8c93          	addi	s9,s9,-220 # 80207860 <etext+0x860>
        if (level == 2 && i >= KERN_IDX_LO) continue;   /* skip borrowed kernel */
    80202944:	4d05                	li	s10,1
    for (int i = 0; i < 512; i++) {
    80202946:	20000c13          	li	s8,512
    8020294a:	a089                	j	8020298c <vmprint_lvl+0x7c>
        for (int d = 2; d >= level; d--) printf(" ..");
    8020294c:	84de                	mv	s1,s7
    8020294e:	052bca63          	blt	s7,s2,802029a2 <vmprint_lvl+0x92>
    80202952:	8556                	mv	a0,s5
    80202954:	ffffe097          	auipc	ra,0xffffe
    80202958:	9ec080e7          	jalr	-1556(ra) # 80200340 <printf>
    8020295c:	34fd                	addiw	s1,s1,-1
    8020295e:	ff24dae3          	bge	s1,s2,80202952 <vmprint_lvl+0x42>
        printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80202962:	00a9d493          	srli	s1,s3,0xa
    80202966:	04b2                	slli	s1,s1,0xc
    80202968:	86a6                	mv	a3,s1
    8020296a:	864e                	mv	a2,s3
    8020296c:	85d2                	mv	a1,s4
    8020296e:	8566                	mv	a0,s9
    80202970:	ffffe097          	auipc	ra,0xffffe
    80202974:	9d0080e7          	jalr	-1584(ra) # 80200340 <printf>
        if ((pte & (PTE_R | PTE_W | PTE_X)) == 0 && level > 0)
    80202978:	00e9f993          	andi	s3,s3,14
    8020297c:	00099463          	bnez	s3,80202984 <vmprint_lvl+0x74>
    80202980:	05204063          	bgtz	s2,802029c0 <vmprint_lvl+0xb0>
    for (int i = 0; i < 512; i++) {
    80202984:	2a05                	addiw	s4,s4,1
    80202986:	0b21                	addi	s6,s6,8
    80202988:	058a0463          	beq	s4,s8,802029d0 <vmprint_lvl+0xc0>
        pte_t pte = pt[i];
    8020298c:	000b3983          	ld	s3,0(s6)
        if (!(pte & PTE_V)) continue;
    80202990:	0019f793          	andi	a5,s3,1
    80202994:	dbe5                	beqz	a5,80202984 <vmprint_lvl+0x74>
        if (level == 2 && i >= KERN_IDX_LO) continue;   /* skip borrowed kernel */
    80202996:	fb791be3          	bne	s2,s7,8020294c <vmprint_lvl+0x3c>
    8020299a:	ff4d45e3          	blt	s10,s4,80202984 <vmprint_lvl+0x74>
    8020299e:	84ca                	mv	s1,s2
    802029a0:	bf4d                	j	80202952 <vmprint_lvl+0x42>
        printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    802029a2:	00a9d493          	srli	s1,s3,0xa
    802029a6:	04b2                	slli	s1,s1,0xc
    802029a8:	86a6                	mv	a3,s1
    802029aa:	864e                	mv	a2,s3
    802029ac:	85d2                	mv	a1,s4
    802029ae:	8566                	mv	a0,s9
    802029b0:	ffffe097          	auipc	ra,0xffffe
    802029b4:	990080e7          	jalr	-1648(ra) # 80200340 <printf>
        if ((pte & (PTE_R | PTE_W | PTE_X)) == 0 && level > 0)
    802029b8:	00e9f993          	andi	s3,s3,14
    802029bc:	fc0994e3          	bnez	s3,80202984 <vmprint_lvl+0x74>
            vmprint_lvl((pagetable_t)PTE2PA(pte), level - 1);
    802029c0:	fff9059b          	addiw	a1,s2,-1
    802029c4:	8526                	mv	a0,s1
    802029c6:	00000097          	auipc	ra,0x0
    802029ca:	f4a080e7          	jalr	-182(ra) # 80202910 <vmprint_lvl>
    802029ce:	bf5d                	j	80202984 <vmprint_lvl+0x74>
    }
}
    802029d0:	60e6                	ld	ra,88(sp)
    802029d2:	6446                	ld	s0,80(sp)
    802029d4:	64a6                	ld	s1,72(sp)
    802029d6:	6906                	ld	s2,64(sp)
    802029d8:	79e2                	ld	s3,56(sp)
    802029da:	7a42                	ld	s4,48(sp)
    802029dc:	7aa2                	ld	s5,40(sp)
    802029de:	7b02                	ld	s6,32(sp)
    802029e0:	6be2                	ld	s7,24(sp)
    802029e2:	6c42                	ld	s8,16(sp)
    802029e4:	6ca2                	ld	s9,8(sp)
    802029e6:	6d02                	ld	s10,0(sp)
    802029e8:	6125                	addi	sp,sp,96
    802029ea:	8082                	ret

00000000802029ec <mmio_alias>:
uint64 mmio_alias(uint64 pa) { return MMIO_VA(pa); }
    802029ec:	1141                	addi	sp,sp,-16
    802029ee:	e406                	sd	ra,8(sp)
    802029f0:	e022                	sd	s0,0(sp)
    802029f2:	0800                	addi	s0,sp,16
    802029f4:	4785                	li	a5,1
    802029f6:	1782                	slli	a5,a5,0x20
    802029f8:	953e                	add	a0,a0,a5
    802029fa:	60a2                	ld	ra,8(sp)
    802029fc:	6402                	ld	s0,0(sp)
    802029fe:	0141                	addi	sp,sp,16
    80202a00:	8082                	ret

0000000080202a02 <walk>:
{
    80202a02:	7139                	addi	sp,sp,-64
    80202a04:	fc06                	sd	ra,56(sp)
    80202a06:	f822                	sd	s0,48(sp)
    80202a08:	f426                	sd	s1,40(sp)
    80202a0a:	f04a                	sd	s2,32(sp)
    80202a0c:	ec4e                	sd	s3,24(sp)
    80202a0e:	e852                	sd	s4,16(sp)
    80202a10:	e456                	sd	s5,8(sp)
    80202a12:	e05a                	sd	s6,0(sp)
    80202a14:	0080                	addi	s0,sp,64
    80202a16:	84aa                	mv	s1,a0
    80202a18:	89ae                	mv	s3,a1
    80202a1a:	8ab2                	mv	s5,a2
    if (va >= MAXVA) panic("walk: va out of range");
    80202a1c:	57fd                	li	a5,-1
    80202a1e:	83e9                	srli	a5,a5,0x1a
    80202a20:	4a79                	li	s4,30
    for (int level = 2; level > 0; level--) {
    80202a22:	4b31                	li	s6,12
    if (va >= MAXVA) panic("walk: va out of range");
    80202a24:	04b7e263          	bltu	a5,a1,80202a68 <walk+0x66>
        pte_t *pte = &pt[PX(level, va)];
    80202a28:	0149d933          	srl	s2,s3,s4
    80202a2c:	1ff97913          	andi	s2,s2,511
    80202a30:	090e                	slli	s2,s2,0x3
    80202a32:	9926                	add	s2,s2,s1
        if (*pte & PTE_V) {
    80202a34:	00093483          	ld	s1,0(s2)
    80202a38:	0014f793          	andi	a5,s1,1
    80202a3c:	cf95                	beqz	a5,80202a78 <walk+0x76>
            pt = (pagetable_t)PTE2PA(*pte);
    80202a3e:	80a9                	srli	s1,s1,0xa
    80202a40:	04b2                	slli	s1,s1,0xc
    for (int level = 2; level > 0; level--) {
    80202a42:	3a5d                	addiw	s4,s4,-9
    80202a44:	ff6a12e3          	bne	s4,s6,80202a28 <walk+0x26>
    return &pt[PX(0, va)];
    80202a48:	00c9d513          	srli	a0,s3,0xc
    80202a4c:	1ff57513          	andi	a0,a0,511
    80202a50:	050e                	slli	a0,a0,0x3
    80202a52:	9526                	add	a0,a0,s1
}
    80202a54:	70e2                	ld	ra,56(sp)
    80202a56:	7442                	ld	s0,48(sp)
    80202a58:	74a2                	ld	s1,40(sp)
    80202a5a:	7902                	ld	s2,32(sp)
    80202a5c:	69e2                	ld	s3,24(sp)
    80202a5e:	6a42                	ld	s4,16(sp)
    80202a60:	6aa2                	ld	s5,8(sp)
    80202a62:	6b02                	ld	s6,0(sp)
    80202a64:	6121                	addi	sp,sp,64
    80202a66:	8082                	ret
    if (va >= MAXVA) panic("walk: va out of range");
    80202a68:	00005517          	auipc	a0,0x5
    80202a6c:	e1050513          	addi	a0,a0,-496 # 80207878 <etext+0x878>
    80202a70:	ffffe097          	auipc	ra,0xffffe
    80202a74:	b40080e7          	jalr	-1216(ra) # 802005b0 <panic>
            if (!alloc) return 0;
    80202a78:	020a8663          	beqz	s5,80202aa4 <walk+0xa2>
            pt = (pagetable_t)palloc();
    80202a7c:	ffffe097          	auipc	ra,0xffffe
    80202a80:	5f2080e7          	jalr	1522(ra) # 8020106e <palloc>
    80202a84:	84aa                	mv	s1,a0
            if (!pt) return 0;
    80202a86:	d579                	beqz	a0,80202a54 <walk+0x52>
            memset(pt, 0, PGSIZE);
    80202a88:	6605                	lui	a2,0x1
    80202a8a:	4581                	li	a1,0
    80202a8c:	ffffe097          	auipc	ra,0xffffe
    80202a90:	bca080e7          	jalr	-1078(ra) # 80200656 <memset>
            *pte = PA2PTE(pt) | PTE_V;
    80202a94:	00c4d793          	srli	a5,s1,0xc
    80202a98:	07aa                	slli	a5,a5,0xa
    80202a9a:	0017e793          	ori	a5,a5,1
    80202a9e:	00f93023          	sd	a5,0(s2)
    80202aa2:	b745                	j	80202a42 <walk+0x40>
            if (!alloc) return 0;
    80202aa4:	4501                	li	a0,0
    80202aa6:	b77d                	j	80202a54 <walk+0x52>

0000000080202aa8 <walkaddr>:
    if (va >= MAXVA) return 0;
    80202aa8:	57fd                	li	a5,-1
    80202aaa:	83e9                	srli	a5,a5,0x1a
    80202aac:	00b7f463          	bgeu	a5,a1,80202ab4 <walkaddr+0xc>
    80202ab0:	4501                	li	a0,0
}
    80202ab2:	8082                	ret
{
    80202ab4:	1141                	addi	sp,sp,-16
    80202ab6:	e406                	sd	ra,8(sp)
    80202ab8:	e022                	sd	s0,0(sp)
    80202aba:	0800                	addi	s0,sp,16
    pte_t *pte = walk(pt, va, 0);
    80202abc:	4601                	li	a2,0
    80202abe:	00000097          	auipc	ra,0x0
    80202ac2:	f44080e7          	jalr	-188(ra) # 80202a02 <walk>
    if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return 0;
    80202ac6:	cd19                	beqz	a0,80202ae4 <walkaddr+0x3c>
    80202ac8:	611c                	ld	a5,0(a0)
    80202aca:	0117f693          	andi	a3,a5,17
    80202ace:	4745                	li	a4,17
    80202ad0:	4501                	li	a0,0
    80202ad2:	00e69563          	bne	a3,a4,80202adc <walkaddr+0x34>
    return PTE2PA(*pte);
    80202ad6:	83a9                	srli	a5,a5,0xa
    80202ad8:	00c79513          	slli	a0,a5,0xc
}
    80202adc:	60a2                	ld	ra,8(sp)
    80202ade:	6402                	ld	s0,0(sp)
    80202ae0:	0141                	addi	sp,sp,16
    80202ae2:	8082                	ret
    if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return 0;
    80202ae4:	4501                	li	a0,0
    80202ae6:	bfdd                	j	80202adc <walkaddr+0x34>

0000000080202ae8 <mappages>:
{
    80202ae8:	715d                	addi	sp,sp,-80
    80202aea:	e486                	sd	ra,72(sp)
    80202aec:	e0a2                	sd	s0,64(sp)
    80202aee:	fc26                	sd	s1,56(sp)
    80202af0:	f84a                	sd	s2,48(sp)
    80202af2:	f44e                	sd	s3,40(sp)
    80202af4:	f052                	sd	s4,32(sp)
    80202af6:	ec56                	sd	s5,24(sp)
    80202af8:	e85a                	sd	s6,16(sp)
    80202afa:	e45e                	sd	s7,8(sp)
    80202afc:	e062                	sd	s8,0(sp)
    80202afe:	0880                	addi	s0,sp,80
    if (size == 0) panic("mappages: zero size");
    80202b00:	ca21                	beqz	a2,80202b50 <mappages+0x68>
    80202b02:	8aaa                	mv	s5,a0
    80202b04:	8b3a                	mv	s6,a4
    uint64 a    = PGROUNDDOWN(va);
    80202b06:	777d                	lui	a4,0xfffff
    80202b08:	00e5f7b3          	and	a5,a1,a4
    uint64 last = PGROUNDDOWN(va + size - 1);
    80202b0c:	fff58993          	addi	s3,a1,-1
    80202b10:	99b2                	add	s3,s3,a2
    80202b12:	00e9f9b3          	and	s3,s3,a4
    uint64 a    = PGROUNDDOWN(va);
    80202b16:	893e                	mv	s2,a5
    80202b18:	40f68a33          	sub	s4,a3,a5
        pte_t *pte = walk(pt, a, 1);
    80202b1c:	4b85                	li	s7,1
        a  += PGSIZE;
    80202b1e:	6c05                	lui	s8,0x1
    80202b20:	014904b3          	add	s1,s2,s4
        pte_t *pte = walk(pt, a, 1);
    80202b24:	865e                	mv	a2,s7
    80202b26:	85ca                	mv	a1,s2
    80202b28:	8556                	mv	a0,s5
    80202b2a:	00000097          	auipc	ra,0x0
    80202b2e:	ed8080e7          	jalr	-296(ra) # 80202a02 <walk>
        if (!pte) return -1;
    80202b32:	cd1d                	beqz	a0,80202b70 <mappages+0x88>
        if (*pte & PTE_V) panic("mappages: remap");
    80202b34:	611c                	ld	a5,0(a0)
    80202b36:	8b85                	andi	a5,a5,1
    80202b38:	e785                	bnez	a5,80202b60 <mappages+0x78>
        *pte = PA2PTE(pa) | perm | PTE_V;
    80202b3a:	80b1                	srli	s1,s1,0xc
    80202b3c:	04aa                	slli	s1,s1,0xa
    80202b3e:	0164e4b3          	or	s1,s1,s6
    80202b42:	0014e493          	ori	s1,s1,1
    80202b46:	e104                	sd	s1,0(a0)
        if (a == last) break;
    80202b48:	05390163          	beq	s2,s3,80202b8a <mappages+0xa2>
        a  += PGSIZE;
    80202b4c:	9962                	add	s2,s2,s8
    for (;;) {
    80202b4e:	bfc9                	j	80202b20 <mappages+0x38>
    if (size == 0) panic("mappages: zero size");
    80202b50:	00005517          	auipc	a0,0x5
    80202b54:	d4050513          	addi	a0,a0,-704 # 80207890 <etext+0x890>
    80202b58:	ffffe097          	auipc	ra,0xffffe
    80202b5c:	a58080e7          	jalr	-1448(ra) # 802005b0 <panic>
        if (*pte & PTE_V) panic("mappages: remap");
    80202b60:	00005517          	auipc	a0,0x5
    80202b64:	d4850513          	addi	a0,a0,-696 # 802078a8 <etext+0x8a8>
    80202b68:	ffffe097          	auipc	ra,0xffffe
    80202b6c:	a48080e7          	jalr	-1464(ra) # 802005b0 <panic>
        if (!pte) return -1;
    80202b70:	557d                	li	a0,-1
}
    80202b72:	60a6                	ld	ra,72(sp)
    80202b74:	6406                	ld	s0,64(sp)
    80202b76:	74e2                	ld	s1,56(sp)
    80202b78:	7942                	ld	s2,48(sp)
    80202b7a:	79a2                	ld	s3,40(sp)
    80202b7c:	7a02                	ld	s4,32(sp)
    80202b7e:	6ae2                	ld	s5,24(sp)
    80202b80:	6b42                	ld	s6,16(sp)
    80202b82:	6ba2                	ld	s7,8(sp)
    80202b84:	6c02                	ld	s8,0(sp)
    80202b86:	6161                	addi	sp,sp,80
    80202b88:	8082                	ret
    return 0;
    80202b8a:	4501                	li	a0,0
    80202b8c:	b7dd                	j	80202b72 <mappages+0x8a>

0000000080202b8e <kvmmap>:
{
    80202b8e:	1141                	addi	sp,sp,-16
    80202b90:	e406                	sd	ra,8(sp)
    80202b92:	e022                	sd	s0,0(sp)
    80202b94:	0800                	addi	s0,sp,16
    80202b96:	8736                	mv	a4,a3
    if (mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80202b98:	86ae                	mv	a3,a1
    80202b9a:	85aa                	mv	a1,a0
    80202b9c:	0013c517          	auipc	a0,0x13c
    80202ba0:	48453503          	ld	a0,1156(a0) # 8033f020 <kernel_pagetable>
    80202ba4:	00000097          	auipc	ra,0x0
    80202ba8:	f44080e7          	jalr	-188(ra) # 80202ae8 <mappages>
    80202bac:	e509                	bnez	a0,80202bb6 <kvmmap+0x28>
}
    80202bae:	60a2                	ld	ra,8(sp)
    80202bb0:	6402                	ld	s0,0(sp)
    80202bb2:	0141                	addi	sp,sp,16
    80202bb4:	8082                	ret
        panic("kvmmap");
    80202bb6:	00005517          	auipc	a0,0x5
    80202bba:	d0250513          	addi	a0,a0,-766 # 802078b8 <etext+0x8b8>
    80202bbe:	ffffe097          	auipc	ra,0xffffe
    80202bc2:	9f2080e7          	jalr	-1550(ra) # 802005b0 <panic>

0000000080202bc6 <kvminit>:
{
    80202bc6:	7139                	addi	sp,sp,-64
    80202bc8:	fc06                	sd	ra,56(sp)
    80202bca:	f822                	sd	s0,48(sp)
    80202bcc:	f426                	sd	s1,40(sp)
    80202bce:	f04a                	sd	s2,32(sp)
    80202bd0:	0080                	addi	s0,sp,64
    kernel_pagetable = (pagetable_t)palloc();
    80202bd2:	ffffe097          	auipc	ra,0xffffe
    80202bd6:	49c080e7          	jalr	1180(ra) # 8020106e <palloc>
    80202bda:	0013c717          	auipc	a4,0x13c
    80202bde:	44a73323          	sd	a0,1094(a4) # 8033f020 <kernel_pagetable>
    memset(kernel_pagetable, 0, PGSIZE);
    80202be2:	6605                	lui	a2,0x1
    80202be4:	4581                	li	a1,0
    80202be6:	ffffe097          	auipc	ra,0xffffe
    80202bea:	a70080e7          	jalr	-1424(ra) # 80200656 <memset>
    kvmmap(MMIO_VA(fdt.uart_base), fdt.uart_base, PGSIZE, PTE_R | PTE_W);
    80202bee:	00026497          	auipc	s1,0x26
    80202bf2:	42a48493          	addi	s1,s1,1066 # 80229018 <fdt>
    80202bf6:	688c                	ld	a1,16(s1)
    80202bf8:	4699                	li	a3,6
    80202bfa:	6605                	lui	a2,0x1
    80202bfc:	4785                	li	a5,1
    80202bfe:	1782                	slli	a5,a5,0x20
    80202c00:	00f58533          	add	a0,a1,a5
    80202c04:	00000097          	auipc	ra,0x0
    80202c08:	f8a080e7          	jalr	-118(ra) # 80202b8e <kvmmap>
    if (fdt.plic_base)
    80202c0c:	6c8c                	ld	a1,24(s1)
    80202c0e:	e9c5                	bnez	a1,80202cbe <kvminit+0xf8>
    for (int i = 0; i < fdt.nvirtio; i++)
    80202c10:	00026797          	auipc	a5,0x26
    80202c14:	4907a783          	lw	a5,1168(a5) # 802290a0 <fdt+0x88>
    80202c18:	04f05463          	blez	a5,80202c60 <kvminit+0x9a>
    80202c1c:	ec4e                	sd	s3,24(sp)
    80202c1e:	e852                	sd	s4,16(sp)
    80202c20:	e456                	sd	s5,8(sp)
    80202c22:	e05a                	sd	s6,0(sp)
    80202c24:	00026917          	auipc	s2,0x26
    80202c28:	3f490913          	addi	s2,s2,1012 # 80229018 <fdt>
    80202c2c:	4481                	li	s1,0
        kvmmap(MMIO_VA(fdt.virtio_base[i]), fdt.virtio_base[i], PGSIZE, PTE_R | PTE_W);
    80202c2e:	4985                	li	s3,1
    80202c30:	1982                	slli	s3,s3,0x20
    80202c32:	4b19                	li	s6,6
    80202c34:	6a85                	lui	s5,0x1
    for (int i = 0; i < fdt.nvirtio; i++)
    80202c36:	8a4a                	mv	s4,s2
        kvmmap(MMIO_VA(fdt.virtio_base[i]), fdt.virtio_base[i], PGSIZE, PTE_R | PTE_W);
    80202c38:	02893583          	ld	a1,40(s2)
    80202c3c:	86da                	mv	a3,s6
    80202c3e:	8656                	mv	a2,s5
    80202c40:	01358533          	add	a0,a1,s3
    80202c44:	00000097          	auipc	ra,0x0
    80202c48:	f4a080e7          	jalr	-182(ra) # 80202b8e <kvmmap>
    for (int i = 0; i < fdt.nvirtio; i++)
    80202c4c:	2485                	addiw	s1,s1,1
    80202c4e:	0921                	addi	s2,s2,8
    80202c50:	088a2783          	lw	a5,136(s4)
    80202c54:	fef4c2e3          	blt	s1,a5,80202c38 <kvminit+0x72>
    80202c58:	69e2                	ld	s3,24(sp)
    80202c5a:	6a42                	ld	s4,16(sp)
    80202c5c:	6aa2                	ld	s5,8(sp)
    80202c5e:	6b02                	ld	s6,0(sp)
    kvmmap(ktext, ktext, (uint64)etext - ktext, PTE_R | PTE_X);
    80202c60:	00004497          	auipc	s1,0x4
    80202c64:	3a048493          	addi	s1,s1,928 # 80207000 <etext>
    80202c68:	46a9                	li	a3,10
    80202c6a:	bff00613          	li	a2,-1025
    80202c6e:	0656                	slli	a2,a2,0x15
    80202c70:	9626                	add	a2,a2,s1
    80202c72:	40100593          	li	a1,1025
    80202c76:	05d6                	slli	a1,a1,0x15
    80202c78:	852e                	mv	a0,a1
    80202c7a:	00000097          	auipc	ra,0x0
    80202c7e:	f14080e7          	jalr	-236(ra) # 80202b8e <kvmmap>
    uint64 mem_end = fdt.mem_base + fdt.mem_size;
    80202c82:	00026917          	auipc	s2,0x26
    80202c86:	39690913          	addi	s2,s2,918 # 80229018 <fdt>
    80202c8a:	09093603          	ld	a2,144(s2)
    80202c8e:	09893783          	ld	a5,152(s2)
    80202c92:	963e                	add	a2,a2,a5
    kvmmap((uint64)etext, (uint64)etext, mem_end - (uint64)etext, PTE_R | PTE_W);
    80202c94:	4699                	li	a3,6
    80202c96:	8e05                	sub	a2,a2,s1
    80202c98:	85a6                	mv	a1,s1
    80202c9a:	8526                	mv	a0,s1
    80202c9c:	00000097          	auipc	ra,0x0
    80202ca0:	ef2080e7          	jalr	-270(ra) # 80202b8e <kvmmap>
    if (fdt.mem_base < ktext)
    80202ca4:	09093503          	ld	a0,144(s2)
    80202ca8:	40100793          	li	a5,1025
    80202cac:	07d6                	slli	a5,a5,0x15
    80202cae:	02f56363          	bltu	a0,a5,80202cd4 <kvminit+0x10e>
}
    80202cb2:	70e2                	ld	ra,56(sp)
    80202cb4:	7442                	ld	s0,48(sp)
    80202cb6:	74a2                	ld	s1,40(sp)
    80202cb8:	7902                	ld	s2,32(sp)
    80202cba:	6121                	addi	sp,sp,64
    80202cbc:	8082                	ret
        kvmmap(MMIO_VA(fdt.plic_base), fdt.plic_base, 0x400000, PTE_R | PTE_W);
    80202cbe:	4699                	li	a3,6
    80202cc0:	00400637          	lui	a2,0x400
    80202cc4:	4505                	li	a0,1
    80202cc6:	1502                	slli	a0,a0,0x20
    80202cc8:	952e                	add	a0,a0,a1
    80202cca:	00000097          	auipc	ra,0x0
    80202cce:	ec4080e7          	jalr	-316(ra) # 80202b8e <kvmmap>
    80202cd2:	bf3d                	j	80202c10 <kvminit+0x4a>
        kvmmap(fdt.mem_base, fdt.mem_base, ktext - fdt.mem_base, PTE_R | PTE_W);
    80202cd4:	4699                	li	a3,6
    80202cd6:	40a78633          	sub	a2,a5,a0
    80202cda:	85aa                	mv	a1,a0
    80202cdc:	00000097          	auipc	ra,0x0
    80202ce0:	eb2080e7          	jalr	-334(ra) # 80202b8e <kvmmap>
}
    80202ce4:	b7f9                	j	80202cb2 <kvminit+0xec>

0000000080202ce6 <kvminithart>:
{
    80202ce6:	1141                	addi	sp,sp,-16
    80202ce8:	e406                	sd	ra,8(sp)
    80202cea:	e022                	sd	s0,0(sp)
    80202cec:	0800                	addi	s0,sp,16
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }
    80202cee:	12000073          	sfence.vma
    w_satp(MAKE_SATP(kernel_pagetable));
    80202cf2:	0013c797          	auipc	a5,0x13c
    80202cf6:	32e7b783          	ld	a5,814(a5) # 8033f020 <kernel_pagetable>
    80202cfa:	83b1                	srli	a5,a5,0xc
    80202cfc:	577d                	li	a4,-1
    80202cfe:	177e                	slli	a4,a4,0x3f
    80202d00:	8fd9                	or	a5,a5,a4
static inline void   w_satp(uint64 x){ asm volatile("csrw satp, %0"::"r"(x)); }
    80202d02:	18079073          	csrw	satp,a5
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }
    80202d06:	12000073          	sfence.vma
}
    80202d0a:	60a2                	ld	ra,8(sp)
    80202d0c:	6402                	ld	s0,0(sp)
    80202d0e:	0141                	addi	sp,sp,16
    80202d10:	8082                	ret

0000000080202d12 <uvmcreate>:
{
    80202d12:	1101                	addi	sp,sp,-32
    80202d14:	ec06                	sd	ra,24(sp)
    80202d16:	e822                	sd	s0,16(sp)
    80202d18:	e426                	sd	s1,8(sp)
    80202d1a:	1000                	addi	s0,sp,32
    pagetable_t pt = (pagetable_t)palloc();
    80202d1c:	ffffe097          	auipc	ra,0xffffe
    80202d20:	352080e7          	jalr	850(ra) # 8020106e <palloc>
    80202d24:	84aa                	mv	s1,a0
    if (!pt) return 0;
    80202d26:	c515                	beqz	a0,80202d52 <uvmcreate+0x40>
    memset(pt, 0, PGSIZE);
    80202d28:	6605                	lui	a2,0x1
    80202d2a:	4581                	li	a1,0
    80202d2c:	ffffe097          	auipc	ra,0xffffe
    80202d30:	92a080e7          	jalr	-1750(ra) # 80200656 <memset>
    80202d34:	47c1                	li	a5,16
        pt[i] = kernel_pagetable[i];
    80202d36:	0013c597          	auipc	a1,0x13c
    80202d3a:	2ea58593          	addi	a1,a1,746 # 8033f020 <kernel_pagetable>
    for (int i = KERN_IDX_LO; i < 512; i++)
    80202d3e:	6605                	lui	a2,0x1
        pt[i] = kernel_pagetable[i];
    80202d40:	6198                	ld	a4,0(a1)
    80202d42:	973e                	add	a4,a4,a5
    80202d44:	6314                	ld	a3,0(a4)
    80202d46:	00f48733          	add	a4,s1,a5
    80202d4a:	e314                	sd	a3,0(a4)
    for (int i = KERN_IDX_LO; i < 512; i++)
    80202d4c:	07a1                	addi	a5,a5,8
    80202d4e:	fec799e3          	bne	a5,a2,80202d40 <uvmcreate+0x2e>
}
    80202d52:	8526                	mv	a0,s1
    80202d54:	60e2                	ld	ra,24(sp)
    80202d56:	6442                	ld	s0,16(sp)
    80202d58:	64a2                	ld	s1,8(sp)
    80202d5a:	6105                	addi	sp,sp,32
    80202d5c:	8082                	ret

0000000080202d5e <uvmunmap>:
{
    80202d5e:	7139                	addi	sp,sp,-64
    80202d60:	fc06                	sd	ra,56(sp)
    80202d62:	f822                	sd	s0,48(sp)
    80202d64:	ec4e                	sd	s3,24(sp)
    80202d66:	0080                	addi	s0,sp,64
    for (uint64 a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80202d68:	0632                	slli	a2,a2,0xc
    80202d6a:	00b609b3          	add	s3,a2,a1
    80202d6e:	0535fd63          	bgeu	a1,s3,80202dc8 <uvmunmap+0x6a>
    80202d72:	f426                	sd	s1,40(sp)
    80202d74:	f04a                	sd	s2,32(sp)
    80202d76:	e852                	sd	s4,16(sp)
    80202d78:	e456                	sd	s5,8(sp)
    80202d7a:	e05a                	sd	s6,0(sp)
    80202d7c:	8a2a                	mv	s4,a0
    80202d7e:	892e                	mv	s2,a1
    80202d80:	8ab6                	mv	s5,a3
    80202d82:	6b05                	lui	s6,0x1
    80202d84:	a031                	j	80202d90 <uvmunmap+0x32>
        *pte = 0;
    80202d86:	0004b023          	sd	zero,0(s1)
    for (uint64 a = va; a < va + npages * PGSIZE; a += PGSIZE) {
    80202d8a:	995a                	add	s2,s2,s6
    80202d8c:	03397963          	bgeu	s2,s3,80202dbe <uvmunmap+0x60>
        pte_t *pte = walk(pt, a, 0);
    80202d90:	4601                	li	a2,0
    80202d92:	85ca                	mv	a1,s2
    80202d94:	8552                	mv	a0,s4
    80202d96:	00000097          	auipc	ra,0x0
    80202d9a:	c6c080e7          	jalr	-916(ra) # 80202a02 <walk>
    80202d9e:	84aa                	mv	s1,a0
        if (!pte || !(*pte & PTE_V)) continue;     /* lazily-allocated: fine */
    80202da0:	d56d                	beqz	a0,80202d8a <uvmunmap+0x2c>
    80202da2:	611c                	ld	a5,0(a0)
    80202da4:	0017f713          	andi	a4,a5,1
    80202da8:	d36d                	beqz	a4,80202d8a <uvmunmap+0x2c>
        if (do_free) pfree((void *)PTE2PA(*pte));
    80202daa:	fc0a8ee3          	beqz	s5,80202d86 <uvmunmap+0x28>
    80202dae:	83a9                	srli	a5,a5,0xa
    80202db0:	00c79513          	slli	a0,a5,0xc
    80202db4:	ffffe097          	auipc	ra,0xffffe
    80202db8:	3ca080e7          	jalr	970(ra) # 8020117e <pfree>
    80202dbc:	b7e9                	j	80202d86 <uvmunmap+0x28>
    80202dbe:	74a2                	ld	s1,40(sp)
    80202dc0:	7902                	ld	s2,32(sp)
    80202dc2:	6a42                	ld	s4,16(sp)
    80202dc4:	6aa2                	ld	s5,8(sp)
    80202dc6:	6b02                	ld	s6,0(sp)
}
    80202dc8:	70e2                	ld	ra,56(sp)
    80202dca:	7442                	ld	s0,48(sp)
    80202dcc:	69e2                	ld	s3,24(sp)
    80202dce:	6121                	addi	sp,sp,64
    80202dd0:	8082                	ret

0000000080202dd2 <uvmfree>:
{
    80202dd2:	1101                	addi	sp,sp,-32
    80202dd4:	ec06                	sd	ra,24(sp)
    80202dd6:	e822                	sd	s0,16(sp)
    80202dd8:	e426                	sd	s1,8(sp)
    80202dda:	1000                	addi	s0,sp,32
    80202ddc:	84aa                	mv	s1,a0
    if (sz > 0) uvmunmap(pt, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80202dde:	ed81                	bnez	a1,80202df6 <uvmfree+0x24>
    freewalk_user(pt, 2);
    80202de0:	4589                	li	a1,2
    80202de2:	8526                	mv	a0,s1
    80202de4:	00000097          	auipc	ra,0x0
    80202de8:	abc080e7          	jalr	-1348(ra) # 802028a0 <freewalk_user>
}
    80202dec:	60e2                	ld	ra,24(sp)
    80202dee:	6442                	ld	s0,16(sp)
    80202df0:	64a2                	ld	s1,8(sp)
    80202df2:	6105                	addi	sp,sp,32
    80202df4:	8082                	ret
    if (sz > 0) uvmunmap(pt, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80202df6:	6785                	lui	a5,0x1
    80202df8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x801ff001>
    80202dfa:	95be                	add	a1,a1,a5
    80202dfc:	4685                	li	a3,1
    80202dfe:	00c5d613          	srli	a2,a1,0xc
    80202e02:	4581                	li	a1,0
    80202e04:	00000097          	auipc	ra,0x0
    80202e08:	f5a080e7          	jalr	-166(ra) # 80202d5e <uvmunmap>
    80202e0c:	bfd1                	j	80202de0 <uvmfree+0xe>

0000000080202e0e <uvmcopy>:
    for (uint64 i = 0; i < sz; i += PGSIZE) {
    80202e0e:	c671                	beqz	a2,80202eda <uvmcopy+0xcc>
{
    80202e10:	715d                	addi	sp,sp,-80
    80202e12:	e486                	sd	ra,72(sp)
    80202e14:	e0a2                	sd	s0,64(sp)
    80202e16:	fc26                	sd	s1,56(sp)
    80202e18:	f84a                	sd	s2,48(sp)
    80202e1a:	f44e                	sd	s3,40(sp)
    80202e1c:	f052                	sd	s4,32(sp)
    80202e1e:	ec56                	sd	s5,24(sp)
    80202e20:	e85a                	sd	s6,16(sp)
    80202e22:	e45e                	sd	s7,8(sp)
    80202e24:	e062                	sd	s8,0(sp)
    80202e26:	0880                	addi	s0,sp,80
    80202e28:	8b2a                	mv	s6,a0
    80202e2a:	8bae                	mv	s7,a1
    80202e2c:	8ab2                	mv	s5,a2
    for (uint64 i = 0; i < sz; i += PGSIZE) {
    80202e2e:	4481                	li	s1,0
        memmove(mem, (void *)pa, PGSIZE);
    80202e30:	6a05                	lui	s4,0x1
    80202e32:	a839                	j	80202e50 <uvmcopy+0x42>
        if (!mem) { uvmunmap(new, 0, i / PGSIZE, 1); return -1; }
    80202e34:	4685                	li	a3,1
    80202e36:	00c4d613          	srli	a2,s1,0xc
    80202e3a:	4581                	li	a1,0
    80202e3c:	855e                	mv	a0,s7
    80202e3e:	00000097          	auipc	ra,0x0
    80202e42:	f20080e7          	jalr	-224(ra) # 80202d5e <uvmunmap>
    80202e46:	557d                	li	a0,-1
    80202e48:	a8ad                	j	80202ec2 <uvmcopy+0xb4>
    for (uint64 i = 0; i < sz; i += PGSIZE) {
    80202e4a:	94d2                	add	s1,s1,s4
    80202e4c:	0754fa63          	bgeu	s1,s5,80202ec0 <uvmcopy+0xb2>
        pte_t *pte = walk(old, i, 0);
    80202e50:	4601                	li	a2,0
    80202e52:	85a6                	mv	a1,s1
    80202e54:	855a                	mv	a0,s6
    80202e56:	00000097          	auipc	ra,0x0
    80202e5a:	bac080e7          	jalr	-1108(ra) # 80202a02 <walk>
        if (!pte || !(*pte & PTE_V)) continue;
    80202e5e:	d575                	beqz	a0,80202e4a <uvmcopy+0x3c>
    80202e60:	6118                	ld	a4,0(a0)
    80202e62:	00177793          	andi	a5,a4,1
    80202e66:	d3f5                	beqz	a5,80202e4a <uvmcopy+0x3c>
        uint64 pa    = PTE2PA(*pte);
    80202e68:	00a75593          	srli	a1,a4,0xa
    80202e6c:	00c59c13          	slli	s8,a1,0xc
        uint64 flags = PTE_FLAGS(*pte);
    80202e70:	3ff77913          	andi	s2,a4,1023
        char *mem = palloc();
    80202e74:	ffffe097          	auipc	ra,0xffffe
    80202e78:	1fa080e7          	jalr	506(ra) # 8020106e <palloc>
    80202e7c:	89aa                	mv	s3,a0
        if (!mem) { uvmunmap(new, 0, i / PGSIZE, 1); return -1; }
    80202e7e:	d95d                	beqz	a0,80202e34 <uvmcopy+0x26>
        memmove(mem, (void *)pa, PGSIZE);
    80202e80:	8652                	mv	a2,s4
    80202e82:	85e2                	mv	a1,s8
    80202e84:	ffffd097          	auipc	ra,0xffffd
    80202e88:	7f2080e7          	jalr	2034(ra) # 80200676 <memmove>
        if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0) {
    80202e8c:	874a                	mv	a4,s2
    80202e8e:	86ce                	mv	a3,s3
    80202e90:	8652                	mv	a2,s4
    80202e92:	85a6                	mv	a1,s1
    80202e94:	855e                	mv	a0,s7
    80202e96:	00000097          	auipc	ra,0x0
    80202e9a:	c52080e7          	jalr	-942(ra) # 80202ae8 <mappages>
    80202e9e:	d555                	beqz	a0,80202e4a <uvmcopy+0x3c>
            pfree(mem);
    80202ea0:	854e                	mv	a0,s3
    80202ea2:	ffffe097          	auipc	ra,0xffffe
    80202ea6:	2dc080e7          	jalr	732(ra) # 8020117e <pfree>
            uvmunmap(new, 0, i / PGSIZE, 1);
    80202eaa:	4685                	li	a3,1
    80202eac:	00c4d613          	srli	a2,s1,0xc
    80202eb0:	4581                	li	a1,0
    80202eb2:	855e                	mv	a0,s7
    80202eb4:	00000097          	auipc	ra,0x0
    80202eb8:	eaa080e7          	jalr	-342(ra) # 80202d5e <uvmunmap>
            return -1;
    80202ebc:	557d                	li	a0,-1
    80202ebe:	a011                	j	80202ec2 <uvmcopy+0xb4>
    return 0;
    80202ec0:	4501                	li	a0,0
}
    80202ec2:	60a6                	ld	ra,72(sp)
    80202ec4:	6406                	ld	s0,64(sp)
    80202ec6:	74e2                	ld	s1,56(sp)
    80202ec8:	7942                	ld	s2,48(sp)
    80202eca:	79a2                	ld	s3,40(sp)
    80202ecc:	7a02                	ld	s4,32(sp)
    80202ece:	6ae2                	ld	s5,24(sp)
    80202ed0:	6b42                	ld	s6,16(sp)
    80202ed2:	6ba2                	ld	s7,8(sp)
    80202ed4:	6c02                	ld	s8,0(sp)
    80202ed6:	6161                	addi	sp,sp,80
    80202ed8:	8082                	ret
    return 0;
    80202eda:	4501                	li	a0,0
}
    80202edc:	8082                	ret

0000000080202ede <copyout>:
    while (len > 0) {
    80202ede:	cad1                	beqz	a3,80202f72 <copyout+0x94>
{
    80202ee0:	711d                	addi	sp,sp,-96
    80202ee2:	ec86                	sd	ra,88(sp)
    80202ee4:	e8a2                	sd	s0,80(sp)
    80202ee6:	e4a6                	sd	s1,72(sp)
    80202ee8:	e0ca                	sd	s2,64(sp)
    80202eea:	fc4e                	sd	s3,56(sp)
    80202eec:	f852                	sd	s4,48(sp)
    80202eee:	f456                	sd	s5,40(sp)
    80202ef0:	f05a                	sd	s6,32(sp)
    80202ef2:	ec5e                	sd	s7,24(sp)
    80202ef4:	e862                	sd	s8,16(sp)
    80202ef6:	e466                	sd	s9,8(sp)
    80202ef8:	e06a                	sd	s10,0(sp)
    80202efa:	1080                	addi	s0,sp,96
    80202efc:	8c2a                	mv	s8,a0
    80202efe:	892e                	mv	s2,a1
    80202f00:	8ab2                	mv	s5,a2
    80202f02:	8a36                	mv	s4,a3
        uint64 va0 = PGROUNDDOWN(dstva);
    80202f04:	7cfd                	lui	s9,0xfffff
        if (va0 >= USER_TOP) return -1;
    80202f06:	80000bb7          	lui	s7,0x80000
    80202f0a:	fffbcb93          	not	s7,s7
        if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return -1;
    80202f0e:	4d45                	li	s10,17
        uint64 n = PGSIZE - (dstva - va0);
    80202f10:	6b05                	lui	s6,0x1
    80202f12:	a01d                	j	80202f38 <copyout+0x5a>
        uint64 pa0 = PTE2PA(*pte);
    80202f14:	83a9                	srli	a5,a5,0xa
    80202f16:	07b2                	slli	a5,a5,0xc
        memmove((void *)(pa0 + (dstva - va0)), src, n);
    80202f18:	41390533          	sub	a0,s2,s3
    80202f1c:	8626                	mv	a2,s1
    80202f1e:	85d6                	mv	a1,s5
    80202f20:	953e                	add	a0,a0,a5
    80202f22:	ffffd097          	auipc	ra,0xffffd
    80202f26:	754080e7          	jalr	1876(ra) # 80200676 <memmove>
        len -= n; src += n; dstva = va0 + PGSIZE;
    80202f2a:	409a0a33          	sub	s4,s4,s1
    80202f2e:	9aa6                	add	s5,s5,s1
    80202f30:	01698933          	add	s2,s3,s6
    while (len > 0) {
    80202f34:	020a0d63          	beqz	s4,80202f6e <copyout+0x90>
        uint64 va0 = PGROUNDDOWN(dstva);
    80202f38:	019979b3          	and	s3,s2,s9
        if (va0 >= USER_TOP) return -1;
    80202f3c:	033bed63          	bltu	s7,s3,80202f76 <copyout+0x98>
        pte_t *pte = walk(pt, va0, 0);
    80202f40:	4601                	li	a2,0
    80202f42:	85ce                	mv	a1,s3
    80202f44:	8562                	mv	a0,s8
    80202f46:	00000097          	auipc	ra,0x0
    80202f4a:	abc080e7          	jalr	-1348(ra) # 80202a02 <walk>
        if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return -1;
    80202f4e:	c139                	beqz	a0,80202f94 <copyout+0xb6>
    80202f50:	611c                	ld	a5,0(a0)
    80202f52:	0117f713          	andi	a4,a5,17
    80202f56:	05a71163          	bne	a4,s10,80202f98 <copyout+0xba>
        if (!(*pte & PTE_W)) return -1;   /* Implementation note. */
    80202f5a:	0047f713          	andi	a4,a5,4
    80202f5e:	cf1d                	beqz	a4,80202f9c <copyout+0xbe>
        uint64 n = PGSIZE - (dstva - va0);
    80202f60:	412984b3          	sub	s1,s3,s2
    80202f64:	94da                	add	s1,s1,s6
        if (n > len) n = len;
    80202f66:	fa9a77e3          	bgeu	s4,s1,80202f14 <copyout+0x36>
    80202f6a:	84d2                	mv	s1,s4
    80202f6c:	b765                	j	80202f14 <copyout+0x36>
    return 0;
    80202f6e:	4501                	li	a0,0
    80202f70:	a021                	j	80202f78 <copyout+0x9a>
    80202f72:	4501                	li	a0,0
}
    80202f74:	8082                	ret
        if (va0 >= USER_TOP) return -1;
    80202f76:	557d                	li	a0,-1
}
    80202f78:	60e6                	ld	ra,88(sp)
    80202f7a:	6446                	ld	s0,80(sp)
    80202f7c:	64a6                	ld	s1,72(sp)
    80202f7e:	6906                	ld	s2,64(sp)
    80202f80:	79e2                	ld	s3,56(sp)
    80202f82:	7a42                	ld	s4,48(sp)
    80202f84:	7aa2                	ld	s5,40(sp)
    80202f86:	7b02                	ld	s6,32(sp)
    80202f88:	6be2                	ld	s7,24(sp)
    80202f8a:	6c42                	ld	s8,16(sp)
    80202f8c:	6ca2                	ld	s9,8(sp)
    80202f8e:	6d02                	ld	s10,0(sp)
    80202f90:	6125                	addi	sp,sp,96
    80202f92:	8082                	ret
        if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return -1;
    80202f94:	557d                	li	a0,-1
    80202f96:	b7cd                	j	80202f78 <copyout+0x9a>
    80202f98:	557d                	li	a0,-1
    80202f9a:	bff9                	j	80202f78 <copyout+0x9a>
        if (!(*pte & PTE_W)) return -1;   /* Implementation note. */
    80202f9c:	557d                	li	a0,-1
    80202f9e:	bfe9                	j	80202f78 <copyout+0x9a>

0000000080202fa0 <copyin>:
    while (len > 0) {
    80202fa0:	c6bd                	beqz	a3,8020300e <copyin+0x6e>
{
    80202fa2:	715d                	addi	sp,sp,-80
    80202fa4:	e486                	sd	ra,72(sp)
    80202fa6:	e0a2                	sd	s0,64(sp)
    80202fa8:	fc26                	sd	s1,56(sp)
    80202faa:	f84a                	sd	s2,48(sp)
    80202fac:	f44e                	sd	s3,40(sp)
    80202fae:	f052                	sd	s4,32(sp)
    80202fb0:	ec56                	sd	s5,24(sp)
    80202fb2:	e85a                	sd	s6,16(sp)
    80202fb4:	e45e                	sd	s7,8(sp)
    80202fb6:	e062                	sd	s8,0(sp)
    80202fb8:	0880                	addi	s0,sp,80
    80202fba:	8b2a                	mv	s6,a0
    80202fbc:	8a2e                	mv	s4,a1
    80202fbe:	8c32                	mv	s8,a2
    80202fc0:	89b6                	mv	s3,a3
        uint64 va0 = PGROUNDDOWN(srcva);
    80202fc2:	7bfd                	lui	s7,0xfffff
        uint64 n = PGSIZE - (srcva - va0);
    80202fc4:	6a85                	lui	s5,0x1
    80202fc6:	a015                	j	80202fea <copyin+0x4a>
        memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80202fc8:	018505b3          	add	a1,a0,s8
    80202fcc:	8626                	mv	a2,s1
    80202fce:	412585b3          	sub	a1,a1,s2
    80202fd2:	8552                	mv	a0,s4
    80202fd4:	ffffd097          	auipc	ra,0xffffd
    80202fd8:	6a2080e7          	jalr	1698(ra) # 80200676 <memmove>
        len -= n; dst += n; srcva = va0 + PGSIZE;
    80202fdc:	409989b3          	sub	s3,s3,s1
    80202fe0:	9a26                	add	s4,s4,s1
    80202fe2:	01590c33          	add	s8,s2,s5
    while (len > 0) {
    80202fe6:	02098263          	beqz	s3,8020300a <copyin+0x6a>
        uint64 va0 = PGROUNDDOWN(srcva);
    80202fea:	017c7933          	and	s2,s8,s7
        uint64 pa0 = walkaddr(pt, va0);
    80202fee:	85ca                	mv	a1,s2
    80202ff0:	855a                	mv	a0,s6
    80202ff2:	00000097          	auipc	ra,0x0
    80202ff6:	ab6080e7          	jalr	-1354(ra) # 80202aa8 <walkaddr>
        if (pa0 == 0) return -1;
    80202ffa:	cd01                	beqz	a0,80203012 <copyin+0x72>
        uint64 n = PGSIZE - (srcva - va0);
    80202ffc:	418904b3          	sub	s1,s2,s8
    80203000:	94d6                	add	s1,s1,s5
        if (n > len) n = len;
    80203002:	fc99f3e3          	bgeu	s3,s1,80202fc8 <copyin+0x28>
    80203006:	84ce                	mv	s1,s3
    80203008:	b7c1                	j	80202fc8 <copyin+0x28>
    return 0;
    8020300a:	4501                	li	a0,0
    8020300c:	a021                	j	80203014 <copyin+0x74>
    8020300e:	4501                	li	a0,0
}
    80203010:	8082                	ret
        if (pa0 == 0) return -1;
    80203012:	557d                	li	a0,-1
}
    80203014:	60a6                	ld	ra,72(sp)
    80203016:	6406                	ld	s0,64(sp)
    80203018:	74e2                	ld	s1,56(sp)
    8020301a:	7942                	ld	s2,48(sp)
    8020301c:	79a2                	ld	s3,40(sp)
    8020301e:	7a02                	ld	s4,32(sp)
    80203020:	6ae2                	ld	s5,24(sp)
    80203022:	6b42                	ld	s6,16(sp)
    80203024:	6ba2                	ld	s7,8(sp)
    80203026:	6c02                	ld	s8,0(sp)
    80203028:	6161                	addi	sp,sp,80
    8020302a:	8082                	ret

000000008020302c <copyinstr>:
{
    8020302c:	715d                	addi	sp,sp,-80
    8020302e:	e486                	sd	ra,72(sp)
    80203030:	e0a2                	sd	s0,64(sp)
    80203032:	fc26                	sd	s1,56(sp)
    80203034:	f84a                	sd	s2,48(sp)
    80203036:	f44e                	sd	s3,40(sp)
    80203038:	f052                	sd	s4,32(sp)
    8020303a:	ec56                	sd	s5,24(sp)
    8020303c:	e85a                	sd	s6,16(sp)
    8020303e:	e45e                	sd	s7,8(sp)
    80203040:	0880                	addi	s0,sp,80
    80203042:	8aaa                	mv	s5,a0
    80203044:	89ae                	mv	s3,a1
    80203046:	8bb2                	mv	s7,a2
    80203048:	8936                	mv	s2,a3
        uint64 va0 = PGROUNDDOWN(srcva);
    8020304a:	7b7d                	lui	s6,0xfffff
        uint64 n = PGSIZE - (srcva - va0);
    8020304c:	6a05                	lui	s4,0x1
    8020304e:	a019                	j	80203054 <copyinstr+0x28>
        srcva = va0 + PGSIZE;
    80203050:	01448bb3          	add	s7,s1,s4
    while (got_null == 0 && max > 0) {
    80203054:	04090863          	beqz	s2,802030a4 <copyinstr+0x78>
        uint64 va0 = PGROUNDDOWN(srcva);
    80203058:	016bf4b3          	and	s1,s7,s6
        uint64 pa0 = walkaddr(pt, va0);
    8020305c:	85a6                	mv	a1,s1
    8020305e:	8556                	mv	a0,s5
    80203060:	00000097          	auipc	ra,0x0
    80203064:	a48080e7          	jalr	-1464(ra) # 80202aa8 <walkaddr>
        if (pa0 == 0) return -1;
    80203068:	c125                	beqz	a0,802030c8 <copyinstr+0x9c>
        uint64 n = PGSIZE - (srcva - va0);
    8020306a:	41748633          	sub	a2,s1,s7
    8020306e:	9652                	add	a2,a2,s4
        if (n > max) n = max;
    80203070:	00c97363          	bgeu	s2,a2,80203076 <copyinstr+0x4a>
    80203074:	864a                	mv	a2,s2
        char *p = (char *)(pa0 + (srcva - va0));
    80203076:	409b8bb3          	sub	s7,s7,s1
    8020307a:	9baa                	add	s7,s7,a0
        while (n > 0) {
    8020307c:	da71                	beqz	a2,80203050 <copyinstr+0x24>
    8020307e:	87ce                	mv	a5,s3
            *dst = *p;
    80203080:	413b86b3          	sub	a3,s7,s3
        while (n > 0) {
    80203084:	964e                	add	a2,a2,s3
            *dst = *p;
    80203086:	00d78733          	add	a4,a5,a3
    8020308a:	00074703          	lbu	a4,0(a4)
    8020308e:	00e78023          	sb	a4,0(a5)
            if (*p == '\0') { got_null = 1; break; }
    80203092:	cb19                	beqz	a4,802030a8 <copyinstr+0x7c>
            dst++; p++; n--; max--;
    80203094:	0785                	addi	a5,a5,1
        while (n > 0) {
    80203096:	fef618e3          	bne	a2,a5,80203086 <copyinstr+0x5a>
    8020309a:	994e                	add	s2,s2,s3
            dst++; p++; n--; max--;
    8020309c:	40f90933          	sub	s2,s2,a5
    802030a0:	89be                	mv	s3,a5
    802030a2:	b77d                	j	80203050 <copyinstr+0x24>
    802030a4:	4781                	li	a5,0
    802030a6:	a011                	j	802030aa <copyinstr+0x7e>
    802030a8:	4785                	li	a5,1
    return got_null ? 0 : -1;
    802030aa:	0017c793          	xori	a5,a5,1
    802030ae:	40f0053b          	negw	a0,a5
}
    802030b2:	60a6                	ld	ra,72(sp)
    802030b4:	6406                	ld	s0,64(sp)
    802030b6:	74e2                	ld	s1,56(sp)
    802030b8:	7942                	ld	s2,48(sp)
    802030ba:	79a2                	ld	s3,40(sp)
    802030bc:	7a02                	ld	s4,32(sp)
    802030be:	6ae2                	ld	s5,24(sp)
    802030c0:	6b42                	ld	s6,16(sp)
    802030c2:	6ba2                	ld	s7,8(sp)
    802030c4:	6161                	addi	sp,sp,80
    802030c6:	8082                	ret
        if (pa0 == 0) return -1;
    802030c8:	557d                	li	a0,-1
    802030ca:	b7e5                	j	802030b2 <copyinstr+0x86>

00000000802030cc <vmprint>:
void vmprint(pagetable_t pt)
{
    802030cc:	1101                	addi	sp,sp,-32
    802030ce:	ec06                	sd	ra,24(sp)
    802030d0:	e822                	sd	s0,16(sp)
    802030d2:	e426                	sd	s1,8(sp)
    802030d4:	1000                	addi	s0,sp,32
    802030d6:	84aa                	mv	s1,a0
    printf("page table %p (user half)\n", pt);
    802030d8:	85aa                	mv	a1,a0
    802030da:	00004517          	auipc	a0,0x4
    802030de:	7e650513          	addi	a0,a0,2022 # 802078c0 <etext+0x8c0>
    802030e2:	ffffd097          	auipc	ra,0xffffd
    802030e6:	25e080e7          	jalr	606(ra) # 80200340 <printf>
    vmprint_lvl(pt, 2);
    802030ea:	4589                	li	a1,2
    802030ec:	8526                	mv	a0,s1
    802030ee:	00000097          	auipc	ra,0x0
    802030f2:	822080e7          	jalr	-2014(ra) # 80202910 <vmprint_lvl>
}
    802030f6:	60e2                	ld	ra,24(sp)
    802030f8:	6442                	ld	s0,16(sp)
    802030fa:	64a2                	ld	s1,8(sp)
    802030fc:	6105                	addi	sp,sp,32
    802030fe:	8082                	ret

0000000080203100 <sys_getpid>:
    int n; argint(0, &n);
    exit(n);
    return 0;
}

uint64 sys_getpid(void) { return myproc()->pid; }
    80203100:	1141                	addi	sp,sp,-16
    80203102:	e406                	sd	ra,8(sp)
    80203104:	e022                	sd	s0,0(sp)
    80203106:	0800                	addi	s0,sp,16
    80203108:	ffffe097          	auipc	ra,0xffffe
    8020310c:	5d6080e7          	jalr	1494(ra) # 802016de <myproc>
    80203110:	5908                	lw	a0,48(a0)
    80203112:	60a2                	ld	ra,8(sp)
    80203114:	6402                	ld	s0,0(sp)
    80203116:	0141                	addi	sp,sp,16
    80203118:	8082                	ret

000000008020311a <argraw>:
{
    8020311a:	1101                	addi	sp,sp,-32
    8020311c:	ec06                	sd	ra,24(sp)
    8020311e:	e822                	sd	s0,16(sp)
    80203120:	e426                	sd	s1,8(sp)
    80203122:	1000                	addi	s0,sp,32
    80203124:	84aa                	mv	s1,a0
    struct trapframe *tf = myproc()->tf;
    80203126:	ffffe097          	auipc	ra,0xffffe
    8020312a:	5b8080e7          	jalr	1464(ra) # 802016de <myproc>
    8020312e:	6d34                	ld	a3,88(a0)
    switch (n) {
    80203130:	4795                	li	a5,5
    80203132:	0297eb63          	bltu	a5,s1,80203168 <argraw+0x4e>
    80203136:	048a                	slli	s1,s1,0x2
    80203138:	00005717          	auipc	a4,0x5
    8020313c:	d3070713          	addi	a4,a4,-720 # 80207e68 <st.0+0x70>
    80203140:	94ba                	add	s1,s1,a4
    80203142:	409c                	lw	a5,0(s1)
    80203144:	97ba                	add	a5,a5,a4
    80203146:	8782                	jr	a5
    case 0: return tf->a0;
    80203148:	7aa8                	ld	a0,112(a3)
}
    8020314a:	60e2                	ld	ra,24(sp)
    8020314c:	6442                	ld	s0,16(sp)
    8020314e:	64a2                	ld	s1,8(sp)
    80203150:	6105                	addi	sp,sp,32
    80203152:	8082                	ret
    case 1: return tf->a1;
    80203154:	7ea8                	ld	a0,120(a3)
    80203156:	bfd5                	j	8020314a <argraw+0x30>
    case 2: return tf->a2;
    80203158:	62c8                	ld	a0,128(a3)
    8020315a:	bfc5                	j	8020314a <argraw+0x30>
    case 3: return tf->a3;
    8020315c:	66c8                	ld	a0,136(a3)
    8020315e:	b7f5                	j	8020314a <argraw+0x30>
    case 4: return tf->a4;
    80203160:	6ac8                	ld	a0,144(a3)
    80203162:	b7e5                	j	8020314a <argraw+0x30>
    case 5: return tf->a5;
    80203164:	6ec8                	ld	a0,152(a3)
    80203166:	b7d5                	j	8020314a <argraw+0x30>
    panic("argraw: bad arg index");
    80203168:	00004517          	auipc	a0,0x4
    8020316c:	77850513          	addi	a0,a0,1912 # 802078e0 <etext+0x8e0>
    80203170:	ffffd097          	auipc	ra,0xffffd
    80203174:	440080e7          	jalr	1088(ra) # 802005b0 <panic>

0000000080203178 <sys_fork>:

uint64 sys_fork(void)   { return fork(); }
    80203178:	1141                	addi	sp,sp,-16
    8020317a:	e406                	sd	ra,8(sp)
    8020317c:	e022                	sd	s0,0(sp)
    8020317e:	0800                	addi	s0,sp,16
    80203180:	fffff097          	auipc	ra,0xfffff
    80203184:	89a080e7          	jalr	-1894(ra) # 80201a1a <fork>
    80203188:	60a2                	ld	ra,8(sp)
    8020318a:	6402                	ld	s0,0(sp)
    8020318c:	0141                	addi	sp,sp,16
    8020318e:	8082                	ret

0000000080203190 <sys_uptime>:
    int pid; argint(0, &pid);
    return kill(pid);
}

uint64 sys_uptime(void)
{
    80203190:	1101                	addi	sp,sp,-32
    80203192:	ec06                	sd	ra,24(sp)
    80203194:	e822                	sd	s0,16(sp)
    80203196:	e426                	sd	s1,8(sp)
    80203198:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    8020319a:	0012e517          	auipc	a0,0x12e
    8020319e:	86650513          	addi	a0,a0,-1946 # 80330a00 <tickslock>
    802031a2:	ffffe097          	auipc	ra,0xffffe
    802031a6:	15e080e7          	jalr	350(ra) # 80201300 <acquire>
    uint64 t = ticks;
    802031aa:	0013c497          	auipc	s1,0x13c
    802031ae:	e6e4b483          	ld	s1,-402(s1) # 8033f018 <ticks>
    release(&tickslock);
    802031b2:	0012e517          	auipc	a0,0x12e
    802031b6:	84e50513          	addi	a0,a0,-1970 # 80330a00 <tickslock>
    802031ba:	ffffe097          	auipc	ra,0xffffe
    802031be:	1f6080e7          	jalr	502(ra) # 802013b0 <release>
    return t;
}
    802031c2:	8526                	mv	a0,s1
    802031c4:	60e2                	ld	ra,24(sp)
    802031c6:	6442                	ld	s0,16(sp)
    802031c8:	64a2                	ld	s1,8(sp)
    802031ca:	6105                	addi	sp,sp,32
    802031cc:	8082                	ret

00000000802031ce <sys_freepages>:

/* Luit extras: test hooks and observability (used by meminfo and ps). */
uint64 sys_freepages(void) { return palloc_free_count(); }
    802031ce:	1141                	addi	sp,sp,-16
    802031d0:	e406                	sd	ra,8(sp)
    802031d2:	e022                	sd	s0,0(sp)
    802031d4:	0800                	addi	s0,sp,16
    802031d6:	ffffe097          	auipc	ra,0xffffe
    802031da:	070080e7          	jalr	112(ra) # 80201246 <palloc_free_count>
    802031de:	60a2                	ld	ra,8(sp)
    802031e0:	6402                	ld	s0,0(sp)
    802031e2:	0141                	addi	sp,sp,16
    802031e4:	8082                	ret

00000000802031e6 <sys_wait>:
{
    802031e6:	1141                	addi	sp,sp,-16
    802031e8:	e406                	sd	ra,8(sp)
    802031ea:	e022                	sd	s0,0(sp)
    802031ec:	0800                	addi	s0,sp,16
int argaddr(int n, uint64 *ap) { *ap = argraw(n); return 0; }
    802031ee:	4501                	li	a0,0
    802031f0:	00000097          	auipc	ra,0x0
    802031f4:	f2a080e7          	jalr	-214(ra) # 8020311a <argraw>
    return wait(p);
    802031f8:	fffff097          	auipc	ra,0xfffff
    802031fc:	bbc080e7          	jalr	-1092(ra) # 80201db4 <wait>
}
    80203200:	60a2                	ld	ra,8(sp)
    80203202:	6402                	ld	s0,0(sp)
    80203204:	0141                	addi	sp,sp,16
    80203206:	8082                	ret

0000000080203208 <sys_procstat>:

uint64 sys_procstat(void)
{
    80203208:	1101                	addi	sp,sp,-32
    8020320a:	ec06                	sd	ra,24(sp)
    8020320c:	e822                	sd	s0,16(sp)
    8020320e:	e426                	sd	s1,8(sp)
    80203210:	1000                	addi	s0,sp,32
int argaddr(int n, uint64 *ap) { *ap = argraw(n); return 0; }
    80203212:	4501                	li	a0,0
    80203214:	00000097          	auipc	ra,0x0
    80203218:	f06080e7          	jalr	-250(ra) # 8020311a <argraw>
    8020321c:	84aa                	mv	s1,a0
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    8020321e:	4505                	li	a0,1
    80203220:	00000097          	auipc	ra,0x0
    80203224:	efa080e7          	jalr	-262(ra) # 8020311a <argraw>
    80203228:	0005079b          	sext.w	a5,a0
    uint64 uaddr;
    int max;
    argaddr(0, &uaddr);
    argint(1, &max);
    if (max <= 0) return -1;
    8020322c:	02f05463          	blez	a5,80203254 <sys_procstat+0x4c>
    if (max > NPROC) max = NPROC;
    80203230:	85be                	mv	a1,a5
    80203232:	04000713          	li	a4,64
    80203236:	00f75463          	bge	a4,a5,8020323e <sys_procstat+0x36>
    8020323a:	04000593          	li	a1,64
    return procstat(uaddr, max);
    8020323e:	2581                	sext.w	a1,a1
    80203240:	8526                	mv	a0,s1
    80203242:	fffff097          	auipc	ra,0xfffff
    80203246:	e74080e7          	jalr	-396(ra) # 802020b6 <procstat>
}
    8020324a:	60e2                	ld	ra,24(sp)
    8020324c:	6442                	ld	s0,16(sp)
    8020324e:	64a2                	ld	s1,8(sp)
    80203250:	6105                	addi	sp,sp,32
    80203252:	8082                	ret
    if (max <= 0) return -1;
    80203254:	557d                	li	a0,-1
    80203256:	bfd5                	j	8020324a <sys_procstat+0x42>

0000000080203258 <sys_kill>:
{
    80203258:	1141                	addi	sp,sp,-16
    8020325a:	e406                	sd	ra,8(sp)
    8020325c:	e022                	sd	s0,0(sp)
    8020325e:	0800                	addi	s0,sp,16
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    80203260:	4501                	li	a0,0
    80203262:	00000097          	auipc	ra,0x0
    80203266:	eb8080e7          	jalr	-328(ra) # 8020311a <argraw>
    return kill(pid);
    8020326a:	2501                	sext.w	a0,a0
    8020326c:	fffff097          	auipc	ra,0xfffff
    80203270:	dd8080e7          	jalr	-552(ra) # 80202044 <kill>
}
    80203274:	60a2                	ld	ra,8(sp)
    80203276:	6402                	ld	s0,0(sp)
    80203278:	0141                	addi	sp,sp,16
    8020327a:	8082                	ret

000000008020327c <sys_sleep>:
{
    8020327c:	7179                	addi	sp,sp,-48
    8020327e:	f406                	sd	ra,40(sp)
    80203280:	f022                	sd	s0,32(sp)
    80203282:	e84a                	sd	s2,16(sp)
    80203284:	e44e                	sd	s3,8(sp)
    80203286:	1800                	addi	s0,sp,48
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    80203288:	4501                	li	a0,0
    8020328a:	00000097          	auipc	ra,0x0
    8020328e:	e90080e7          	jalr	-368(ra) # 8020311a <argraw>
    80203292:	892a                	mv	s2,a0
    acquire(&tickslock);
    80203294:	0012d517          	auipc	a0,0x12d
    80203298:	76c50513          	addi	a0,a0,1900 # 80330a00 <tickslock>
    8020329c:	ffffe097          	auipc	ra,0xffffe
    802032a0:	064080e7          	jalr	100(ra) # 80201300 <acquire>
    uint64 t0 = ticks;
    802032a4:	0013c997          	auipc	s3,0x13c
    802032a8:	d749b983          	ld	s3,-652(s3) # 8033f018 <ticks>
    while (ticks - t0 < (uint64)n) {
    802032ac:	2901                	sext.w	s2,s2
    802032ae:	02090f63          	beqz	s2,802032ec <sys_sleep+0x70>
    802032b2:	ec26                	sd	s1,24(sp)
    802032b4:	e052                	sd	s4,0(sp)
        sleep(&ticks, &tickslock);
    802032b6:	0012da17          	auipc	s4,0x12d
    802032ba:	74aa0a13          	addi	s4,s4,1866 # 80330a00 <tickslock>
    802032be:	0013c497          	auipc	s1,0x13c
    802032c2:	d5a48493          	addi	s1,s1,-678 # 8033f018 <ticks>
        if (myproc()->killed) { release(&tickslock); return -1; }
    802032c6:	ffffe097          	auipc	ra,0xffffe
    802032ca:	418080e7          	jalr	1048(ra) # 802016de <myproc>
    802032ce:	551c                	lw	a5,40(a0)
    802032d0:	ef8d                	bnez	a5,8020330a <sys_sleep+0x8e>
        sleep(&ticks, &tickslock);
    802032d2:	85d2                	mv	a1,s4
    802032d4:	8526                	mv	a0,s1
    802032d6:	fffff097          	auipc	ra,0xfffff
    802032da:	a7a080e7          	jalr	-1414(ra) # 80201d50 <sleep>
    while (ticks - t0 < (uint64)n) {
    802032de:	609c                	ld	a5,0(s1)
    802032e0:	413787b3          	sub	a5,a5,s3
    802032e4:	ff27e1e3          	bltu	a5,s2,802032c6 <sys_sleep+0x4a>
    802032e8:	64e2                	ld	s1,24(sp)
    802032ea:	6a02                	ld	s4,0(sp)
    release(&tickslock);
    802032ec:	0012d517          	auipc	a0,0x12d
    802032f0:	71450513          	addi	a0,a0,1812 # 80330a00 <tickslock>
    802032f4:	ffffe097          	auipc	ra,0xffffe
    802032f8:	0bc080e7          	jalr	188(ra) # 802013b0 <release>
    return 0;
    802032fc:	4501                	li	a0,0
}
    802032fe:	70a2                	ld	ra,40(sp)
    80203300:	7402                	ld	s0,32(sp)
    80203302:	6942                	ld	s2,16(sp)
    80203304:	69a2                	ld	s3,8(sp)
    80203306:	6145                	addi	sp,sp,48
    80203308:	8082                	ret
        if (myproc()->killed) { release(&tickslock); return -1; }
    8020330a:	0012d517          	auipc	a0,0x12d
    8020330e:	6f650513          	addi	a0,a0,1782 # 80330a00 <tickslock>
    80203312:	ffffe097          	auipc	ra,0xffffe
    80203316:	09e080e7          	jalr	158(ra) # 802013b0 <release>
    8020331a:	557d                	li	a0,-1
    8020331c:	64e2                	ld	s1,24(sp)
    8020331e:	6a02                	ld	s4,0(sp)
    80203320:	bff9                	j	802032fe <sys_sleep+0x82>

0000000080203322 <sys_sbrk>:
{
    80203322:	1101                	addi	sp,sp,-32
    80203324:	ec06                	sd	ra,24(sp)
    80203326:	e822                	sd	s0,16(sp)
    80203328:	e426                	sd	s1,8(sp)
    8020332a:	e04a                	sd	s2,0(sp)
    8020332c:	1000                	addi	s0,sp,32
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    8020332e:	4501                	li	a0,0
    80203330:	00000097          	auipc	ra,0x0
    80203334:	dea080e7          	jalr	-534(ra) # 8020311a <argraw>
    80203338:	84aa                	mv	s1,a0
    uint64 addr = myproc()->sz;
    8020333a:	ffffe097          	auipc	ra,0xffffe
    8020333e:	3a4080e7          	jalr	932(ra) # 802016de <myproc>
    80203342:	04853903          	ld	s2,72(a0)
    if (growproc(n) < 0) return -1;
    80203346:	0004851b          	sext.w	a0,s1
    8020334a:	ffffe097          	auipc	ra,0xffffe
    8020334e:	5d4080e7          	jalr	1492(ra) # 8020191e <growproc>
    80203352:	00054963          	bltz	a0,80203364 <sys_sbrk+0x42>
}
    80203356:	854a                	mv	a0,s2
    80203358:	60e2                	ld	ra,24(sp)
    8020335a:	6442                	ld	s0,16(sp)
    8020335c:	64a2                	ld	s1,8(sp)
    8020335e:	6902                	ld	s2,0(sp)
    80203360:	6105                	addi	sp,sp,32
    80203362:	8082                	ret
    if (growproc(n) < 0) return -1;
    80203364:	597d                	li	s2,-1
    80203366:	bfc5                	j	80203356 <sys_sbrk+0x34>

0000000080203368 <sys_exit>:
{
    80203368:	1141                	addi	sp,sp,-16
    8020336a:	e406                	sd	ra,8(sp)
    8020336c:	e022                	sd	s0,0(sp)
    8020336e:	0800                	addi	s0,sp,16
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    80203370:	4501                	li	a0,0
    80203372:	00000097          	auipc	ra,0x0
    80203376:	da8080e7          	jalr	-600(ra) # 8020311a <argraw>
    exit(n);
    8020337a:	2501                	sext.w	a0,a0
    8020337c:	fffff097          	auipc	ra,0xfffff
    80203380:	bca080e7          	jalr	-1078(ra) # 80201f46 <exit>

0000000080203384 <argint>:
int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
    80203384:	1101                	addi	sp,sp,-32
    80203386:	ec06                	sd	ra,24(sp)
    80203388:	e822                	sd	s0,16(sp)
    8020338a:	e426                	sd	s1,8(sp)
    8020338c:	1000                	addi	s0,sp,32
    8020338e:	84ae                	mv	s1,a1
    80203390:	00000097          	auipc	ra,0x0
    80203394:	d8a080e7          	jalr	-630(ra) # 8020311a <argraw>
    80203398:	c088                	sw	a0,0(s1)
    8020339a:	4501                	li	a0,0
    8020339c:	60e2                	ld	ra,24(sp)
    8020339e:	6442                	ld	s0,16(sp)
    802033a0:	64a2                	ld	s1,8(sp)
    802033a2:	6105                	addi	sp,sp,32
    802033a4:	8082                	ret

00000000802033a6 <argaddr>:
int argaddr(int n, uint64 *ap) { *ap = argraw(n); return 0; }
    802033a6:	1101                	addi	sp,sp,-32
    802033a8:	ec06                	sd	ra,24(sp)
    802033aa:	e822                	sd	s0,16(sp)
    802033ac:	e426                	sd	s1,8(sp)
    802033ae:	1000                	addi	s0,sp,32
    802033b0:	84ae                	mv	s1,a1
    802033b2:	00000097          	auipc	ra,0x0
    802033b6:	d68080e7          	jalr	-664(ra) # 8020311a <argraw>
    802033ba:	e088                	sd	a0,0(s1)
    802033bc:	4501                	li	a0,0
    802033be:	60e2                	ld	ra,24(sp)
    802033c0:	6442                	ld	s0,16(sp)
    802033c2:	64a2                	ld	s1,8(sp)
    802033c4:	6105                	addi	sp,sp,32
    802033c6:	8082                	ret

00000000802033c8 <fetchstr>:
{
    802033c8:	7179                	addi	sp,sp,-48
    802033ca:	f406                	sd	ra,40(sp)
    802033cc:	f022                	sd	s0,32(sp)
    802033ce:	ec26                	sd	s1,24(sp)
    802033d0:	e84a                	sd	s2,16(sp)
    802033d2:	e44e                	sd	s3,8(sp)
    802033d4:	1800                	addi	s0,sp,48
    802033d6:	892a                	mv	s2,a0
    802033d8:	84ae                	mv	s1,a1
    802033da:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    802033dc:	ffffe097          	auipc	ra,0xffffe
    802033e0:	302080e7          	jalr	770(ra) # 802016de <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0) return -1;
    802033e4:	86ce                	mv	a3,s3
    802033e6:	864a                	mv	a2,s2
    802033e8:	85a6                	mv	a1,s1
    802033ea:	6928                	ld	a0,80(a0)
    802033ec:	00000097          	auipc	ra,0x0
    802033f0:	c40080e7          	jalr	-960(ra) # 8020302c <copyinstr>
    802033f4:	00054e63          	bltz	a0,80203410 <fetchstr+0x48>
    return strlen(buf);
    802033f8:	8526                	mv	a0,s1
    802033fa:	ffffd097          	auipc	ra,0xffffd
    802033fe:	36e080e7          	jalr	878(ra) # 80200768 <strlen>
}
    80203402:	70a2                	ld	ra,40(sp)
    80203404:	7402                	ld	s0,32(sp)
    80203406:	64e2                	ld	s1,24(sp)
    80203408:	6942                	ld	s2,16(sp)
    8020340a:	69a2                	ld	s3,8(sp)
    8020340c:	6145                	addi	sp,sp,48
    8020340e:	8082                	ret
    if (copyinstr(p->pagetable, buf, addr, max) < 0) return -1;
    80203410:	557d                	li	a0,-1
    80203412:	bfc5                	j	80203402 <fetchstr+0x3a>

0000000080203414 <argstr>:
{
    80203414:	1101                	addi	sp,sp,-32
    80203416:	ec06                	sd	ra,24(sp)
    80203418:	e822                	sd	s0,16(sp)
    8020341a:	e426                	sd	s1,8(sp)
    8020341c:	e04a                	sd	s2,0(sp)
    8020341e:	1000                	addi	s0,sp,32
    80203420:	84ae                	mv	s1,a1
    80203422:	8932                	mv	s2,a2
int argaddr(int n, uint64 *ap) { *ap = argraw(n); return 0; }
    80203424:	00000097          	auipc	ra,0x0
    80203428:	cf6080e7          	jalr	-778(ra) # 8020311a <argraw>
    return fetchstr(addr, buf, max);
    8020342c:	864a                	mv	a2,s2
    8020342e:	85a6                	mv	a1,s1
    80203430:	00000097          	auipc	ra,0x0
    80203434:	f98080e7          	jalr	-104(ra) # 802033c8 <fetchstr>
}
    80203438:	60e2                	ld	ra,24(sp)
    8020343a:	6442                	ld	s0,16(sp)
    8020343c:	64a2                	ld	s1,8(sp)
    8020343e:	6902                	ld	s2,0(sp)
    80203440:	6105                	addi	sp,sp,32
    80203442:	8082                	ret

0000000080203444 <syscall>:
/* ---- dispatch ---- */

#include "syscalltab.h"     /* GENERATED: syscalls[] and syscall_names[] */

void syscall(void)
{
    80203444:	1101                	addi	sp,sp,-32
    80203446:	ec06                	sd	ra,24(sp)
    80203448:	e822                	sd	s0,16(sp)
    8020344a:	e426                	sd	s1,8(sp)
    8020344c:	e04a                	sd	s2,0(sp)
    8020344e:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80203450:	ffffe097          	auipc	ra,0xffffe
    80203454:	28e080e7          	jalr	654(ra) # 802016de <myproc>
    80203458:	84aa                	mv	s1,a0
    uint64 num = p->tf->a7;
    8020345a:	05853903          	ld	s2,88(a0)
    8020345e:	0a893683          	ld	a3,168(s2)

    /* Implementation note. */


    if (num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
    80203462:	fff68713          	addi	a4,a3,-1 # 3fff <_entry-0x801fc001>
    80203466:	47d9                	li	a5,22
    80203468:	00e7ef63          	bltu	a5,a4,80203486 <syscall+0x42>
    8020346c:	00369713          	slli	a4,a3,0x3
    80203470:	00005797          	auipc	a5,0x5
    80203474:	a1078793          	addi	a5,a5,-1520 # 80207e80 <syscalls>
    80203478:	97ba                	add	a5,a5,a4
    8020347a:	639c                	ld	a5,0(a5)
    8020347c:	c789                	beqz	a5,80203486 <syscall+0x42>
        p->tf->a0 = syscalls[num]();
    8020347e:	9782                	jalr	a5
    80203480:	06a93823          	sd	a0,112(s2)
    80203484:	a839                	j	802034a2 <syscall+0x5e>
    } else {
        printf("pid %d (%s): unknown syscall %d\n", p->pid, p->name, num);
    80203486:	15848613          	addi	a2,s1,344
    8020348a:	588c                	lw	a1,48(s1)
    8020348c:	00004517          	auipc	a0,0x4
    80203490:	46c50513          	addi	a0,a0,1132 # 802078f8 <etext+0x8f8>
    80203494:	ffffd097          	auipc	ra,0xffffd
    80203498:	eac080e7          	jalr	-340(ra) # 80200340 <printf>
        p->tf->a0 = -1;
    8020349c:	6cbc                	ld	a5,88(s1)
    8020349e:	577d                	li	a4,-1
    802034a0:	fbb8                	sd	a4,112(a5)
    }
    (void)syscall_name;      /* Implementation note. */
}
    802034a2:	60e2                	ld	ra,24(sp)
    802034a4:	6442                	ld	s0,16(sp)
    802034a6:	64a2                	ld	s1,8(sp)
    802034a8:	6902                	ld	s2,0(sp)
    802034aa:	6105                	addi	sp,sp,32
    802034ac:	8082                	ret

00000000802034ae <argfd>:
#include "defs.h"
#include "fcntl.h"

/* Fetch the n'th arg as a file descriptor; return the struct file too. */
static int argfd(int n, int *pfd, struct file **pf)
{
    802034ae:	7179                	addi	sp,sp,-48
    802034b0:	f406                	sd	ra,40(sp)
    802034b2:	f022                	sd	s0,32(sp)
    802034b4:	ec26                	sd	s1,24(sp)
    802034b6:	e84a                	sd	s2,16(sp)
    802034b8:	1800                	addi	s0,sp,48
    802034ba:	892e                	mv	s2,a1
    802034bc:	84b2                	mv	s1,a2
    int fd;
    argint(n, &fd);
    802034be:	fdc40593          	addi	a1,s0,-36
    802034c2:	00000097          	auipc	ra,0x0
    802034c6:	ec2080e7          	jalr	-318(ra) # 80203384 <argint>
    if (fd < 0 || fd >= NOFILE) return -1;
    802034ca:	fdc42703          	lw	a4,-36(s0)
    802034ce:	47bd                	li	a5,15
    802034d0:	02e7eb63          	bltu	a5,a4,80203506 <argfd+0x58>
    struct file *f = myproc()->ofile[fd];
    802034d4:	ffffe097          	auipc	ra,0xffffe
    802034d8:	20a080e7          	jalr	522(ra) # 802016de <myproc>
    802034dc:	fdc42703          	lw	a4,-36(s0)
    802034e0:	01a70793          	addi	a5,a4,26
    802034e4:	078e                	slli	a5,a5,0x3
    802034e6:	953e                	add	a0,a0,a5
    802034e8:	611c                	ld	a5,0(a0)
    if (f == 0) return -1;
    802034ea:	c385                	beqz	a5,8020350a <argfd+0x5c>
    if (pfd) *pfd = fd;
    802034ec:	00090463          	beqz	s2,802034f4 <argfd+0x46>
    802034f0:	00e92023          	sw	a4,0(s2)
    if (pf)  *pf  = f;
    return 0;
    802034f4:	4501                	li	a0,0
    if (pf)  *pf  = f;
    802034f6:	c091                	beqz	s1,802034fa <argfd+0x4c>
    802034f8:	e09c                	sd	a5,0(s1)
}
    802034fa:	70a2                	ld	ra,40(sp)
    802034fc:	7402                	ld	s0,32(sp)
    802034fe:	64e2                	ld	s1,24(sp)
    80203500:	6942                	ld	s2,16(sp)
    80203502:	6145                	addi	sp,sp,48
    80203504:	8082                	ret
    if (fd < 0 || fd >= NOFILE) return -1;
    80203506:	557d                	li	a0,-1
    80203508:	bfcd                	j	802034fa <argfd+0x4c>
    if (f == 0) return -1;
    8020350a:	557d                	li	a0,-1
    8020350c:	b7fd                	j	802034fa <argfd+0x4c>

000000008020350e <fdalloc>:

/* Install f in the first free slot of the fd table. */
static int fdalloc(struct file *f)
{
    8020350e:	1101                	addi	sp,sp,-32
    80203510:	ec06                	sd	ra,24(sp)
    80203512:	e822                	sd	s0,16(sp)
    80203514:	e426                	sd	s1,8(sp)
    80203516:	1000                	addi	s0,sp,32
    80203518:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    8020351a:	ffffe097          	auipc	ra,0xffffe
    8020351e:	1c4080e7          	jalr	452(ra) # 802016de <myproc>
    80203522:	862a                	mv	a2,a0
    for (int fd = 0; fd < NOFILE; fd++) {
    80203524:	0d050793          	addi	a5,a0,208
    80203528:	4501                	li	a0,0
    8020352a:	46c1                	li	a3,16
        if (p->ofile[fd] == 0) {
    8020352c:	6398                	ld	a4,0(a5)
    8020352e:	cb19                	beqz	a4,80203544 <fdalloc+0x36>
    for (int fd = 0; fd < NOFILE; fd++) {
    80203530:	2505                	addiw	a0,a0,1
    80203532:	07a1                	addi	a5,a5,8
    80203534:	fed51ce3          	bne	a0,a3,8020352c <fdalloc+0x1e>
            p->ofile[fd] = f;
            return fd;
        }
    }
    return -1;
    80203538:	557d                	li	a0,-1
}
    8020353a:	60e2                	ld	ra,24(sp)
    8020353c:	6442                	ld	s0,16(sp)
    8020353e:	64a2                	ld	s1,8(sp)
    80203540:	6105                	addi	sp,sp,32
    80203542:	8082                	ret
            p->ofile[fd] = f;
    80203544:	01a50793          	addi	a5,a0,26
    80203548:	078e                	slli	a5,a5,0x3
    8020354a:	963e                	add	a2,a2,a5
    8020354c:	e204                	sd	s1,0(a2)
            return fd;
    8020354e:	b7f5                	j	8020353a <fdalloc+0x2c>

0000000080203550 <create>:
}

/* Create path as type. Returns LOCKED inode, or 0. Handles the T_DIR case
 * (".", "..", parent nlink) and open(O_CREATE) racing an existing file. */
static struct inode *create(char *path, uint16 type, uint16 major, uint16 minor)
{
    80203550:	711d                	addi	sp,sp,-96
    80203552:	ec86                	sd	ra,88(sp)
    80203554:	e8a2                	sd	s0,80(sp)
    80203556:	e4a6                	sd	s1,72(sp)
    80203558:	e0ca                	sd	s2,64(sp)
    8020355a:	fc4e                	sd	s3,56(sp)
    8020355c:	f456                	sd	s5,40(sp)
    8020355e:	f05a                	sd	s6,32(sp)
    80203560:	1080                	addi	s0,sp,96
    80203562:	8b2e                	mv	s6,a1
    80203564:	89b2                	mv	s3,a2
    80203566:	8936                	mv	s2,a3
    char name[DIRSIZ];
    struct inode *dp = nameiparent(path, name);
    80203568:	fa040593          	addi	a1,s0,-96
    8020356c:	00002097          	auipc	ra,0x2
    80203570:	2de080e7          	jalr	734(ra) # 8020584a <nameiparent>
    80203574:	84aa                	mv	s1,a0
    if (dp == 0) return 0;
    80203576:	16050263          	beqz	a0,802036da <create+0x18a>
    ilock(dp);
    8020357a:	00002097          	auipc	ra,0x2
    8020357e:	a10080e7          	jalr	-1520(ra) # 80204f8a <ilock>

    struct inode *ip = dirlookup(dp, name, 0);
    80203582:	4601                	li	a2,0
    80203584:	fa040593          	addi	a1,s0,-96
    80203588:	8526                	mv	a0,s1
    8020358a:	00002097          	auipc	ra,0x2
    8020358e:	fb6080e7          	jalr	-74(ra) # 80205540 <dirlookup>
    80203592:	8aaa                	mv	s5,a0
    if (ip != 0) {
    80203594:	c929                	beqz	a0,802035e6 <create+0x96>
        iunlockput(dp);
    80203596:	8526                	mv	a0,s1
    80203598:	00002097          	auipc	ra,0x2
    8020359c:	ccc080e7          	jalr	-820(ra) # 80205264 <iunlockput>
        ilock(ip);
    802035a0:	8556                	mv	a0,s5
    802035a2:	00002097          	auipc	ra,0x2
    802035a6:	9e8080e7          	jalr	-1560(ra) # 80204f8a <ilock>
        if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEV))
    802035aa:	000b059b          	sext.w	a1,s6
    802035ae:	4789                	li	a5,2
    802035b0:	02f59463          	bne	a1,a5,802035d8 <create+0x88>
    802035b4:	044ad783          	lhu	a5,68(s5) # 1044 <_entry-0x801fefbc>
    802035b8:	37f9                	addiw	a5,a5,-2
    802035ba:	17c2                	slli	a5,a5,0x30
    802035bc:	93c1                	srli	a5,a5,0x30
    802035be:	4705                	li	a4,1
    802035c0:	00f76c63          	bltu	a4,a5,802035d8 <create+0x88>
    ip->nlink = 0;
    iupdate(ip);
    iunlockput(ip);
    iunlockput(dp);
    return 0;
}
    802035c4:	8556                	mv	a0,s5
    802035c6:	60e6                	ld	ra,88(sp)
    802035c8:	6446                	ld	s0,80(sp)
    802035ca:	64a6                	ld	s1,72(sp)
    802035cc:	6906                	ld	s2,64(sp)
    802035ce:	79e2                	ld	s3,56(sp)
    802035d0:	7aa2                	ld	s5,40(sp)
    802035d2:	7b02                	ld	s6,32(sp)
    802035d4:	6125                	addi	sp,sp,96
    802035d6:	8082                	ret
        iunlockput(ip);
    802035d8:	8556                	mv	a0,s5
    802035da:	00002097          	auipc	ra,0x2
    802035de:	c8a080e7          	jalr	-886(ra) # 80205264 <iunlockput>
        return 0;
    802035e2:	4a81                	li	s5,0
    802035e4:	b7c5                	j	802035c4 <create+0x74>
    802035e6:	f852                	sd	s4,48(sp)
    if ((ip = ialloc(dp->dev, type)) == 0) { iunlockput(dp); return 0; }
    802035e8:	85da                	mv	a1,s6
    802035ea:	4088                	lw	a0,0(s1)
    802035ec:	00001097          	auipc	ra,0x1
    802035f0:	7a6080e7          	jalr	1958(ra) # 80204d92 <ialloc>
    802035f4:	8a2a                	mv	s4,a0
    802035f6:	c921                	beqz	a0,80203646 <create+0xf6>
    ilock(ip);
    802035f8:	00002097          	auipc	ra,0x2
    802035fc:	992080e7          	jalr	-1646(ra) # 80204f8a <ilock>
    ip->major = major;
    80203600:	053a1323          	sh	s3,70(s4)
    ip->minor = minor;
    80203604:	052a1423          	sh	s2,72(s4)
    ip->nlink = 1;
    80203608:	4905                	li	s2,1
    8020360a:	052a1523          	sh	s2,74(s4)
    iupdate(ip);
    8020360e:	8552                	mv	a0,s4
    80203610:	00002097          	auipc	ra,0x2
    80203614:	8ae080e7          	jalr	-1874(ra) # 80204ebe <iupdate>
    if (type == T_DIR) {
    80203618:	000b059b          	sext.w	a1,s6
    8020361c:	03258d63          	beq	a1,s2,80203656 <create+0x106>
    if (dirlink(dp, name, ip->inum) < 0) goto fail;
    80203620:	004a2603          	lw	a2,4(s4)
    80203624:	fa040593          	addi	a1,s0,-96
    80203628:	8526                	mv	a0,s1
    8020362a:	00002097          	auipc	ra,0x2
    8020362e:	13a080e7          	jalr	314(ra) # 80205764 <dirlink>
    80203632:	08054163          	bltz	a0,802036b4 <create+0x164>
    iunlockput(dp);
    80203636:	8526                	mv	a0,s1
    80203638:	00002097          	auipc	ra,0x2
    8020363c:	c2c080e7          	jalr	-980(ra) # 80205264 <iunlockput>
    return ip;
    80203640:	8ad2                	mv	s5,s4
    80203642:	7a42                	ld	s4,48(sp)
    80203644:	b741                	j	802035c4 <create+0x74>
    if ((ip = ialloc(dp->dev, type)) == 0) { iunlockput(dp); return 0; }
    80203646:	8526                	mv	a0,s1
    80203648:	00002097          	auipc	ra,0x2
    8020364c:	c1c080e7          	jalr	-996(ra) # 80205264 <iunlockput>
    80203650:	8ad2                	mv	s5,s4
    80203652:	7a42                	ld	s4,48(sp)
    80203654:	bf85                	j	802035c4 <create+0x74>
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80203656:	004a2603          	lw	a2,4(s4)
    8020365a:	00004597          	auipc	a1,0x4
    8020365e:	2c658593          	addi	a1,a1,710 # 80207920 <etext+0x920>
    80203662:	8552                	mv	a0,s4
    80203664:	00002097          	auipc	ra,0x2
    80203668:	100080e7          	jalr	256(ra) # 80205764 <dirlink>
    8020366c:	04054463          	bltz	a0,802036b4 <create+0x164>
    80203670:	40d0                	lw	a2,4(s1)
    80203672:	00004597          	auipc	a1,0x4
    80203676:	2b658593          	addi	a1,a1,694 # 80207928 <etext+0x928>
    8020367a:	8552                	mv	a0,s4
    8020367c:	00002097          	auipc	ra,0x2
    80203680:	0e8080e7          	jalr	232(ra) # 80205764 <dirlink>
    80203684:	02054863          	bltz	a0,802036b4 <create+0x164>
    if (dirlink(dp, name, ip->inum) < 0) goto fail;
    80203688:	004a2603          	lw	a2,4(s4)
    8020368c:	fa040593          	addi	a1,s0,-96
    80203690:	8526                	mv	a0,s1
    80203692:	00002097          	auipc	ra,0x2
    80203696:	0d2080e7          	jalr	210(ra) # 80205764 <dirlink>
    8020369a:	00054d63          	bltz	a0,802036b4 <create+0x164>
        dp->nlink++;
    8020369e:	04a4d783          	lhu	a5,74(s1)
    802036a2:	2785                	addiw	a5,a5,1
    802036a4:	04f49523          	sh	a5,74(s1)
        iupdate(dp);
    802036a8:	8526                	mv	a0,s1
    802036aa:	00002097          	auipc	ra,0x2
    802036ae:	814080e7          	jalr	-2028(ra) # 80204ebe <iupdate>
    802036b2:	b751                	j	80203636 <create+0xe6>
    ip->nlink = 0;
    802036b4:	040a1523          	sh	zero,74(s4)
    iupdate(ip);
    802036b8:	8552                	mv	a0,s4
    802036ba:	00002097          	auipc	ra,0x2
    802036be:	804080e7          	jalr	-2044(ra) # 80204ebe <iupdate>
    iunlockput(ip);
    802036c2:	8552                	mv	a0,s4
    802036c4:	00002097          	auipc	ra,0x2
    802036c8:	ba0080e7          	jalr	-1120(ra) # 80205264 <iunlockput>
    iunlockput(dp);
    802036cc:	8526                	mv	a0,s1
    802036ce:	00002097          	auipc	ra,0x2
    802036d2:	b96080e7          	jalr	-1130(ra) # 80205264 <iunlockput>
    return 0;
    802036d6:	7a42                	ld	s4,48(sp)
    802036d8:	b5f5                	j	802035c4 <create+0x74>
    if (dp == 0) return 0;
    802036da:	8aaa                	mv	s5,a0
    802036dc:	b5e5                	j	802035c4 <create+0x74>

00000000802036de <sys_dup>:
{
    802036de:	7179                	addi	sp,sp,-48
    802036e0:	f406                	sd	ra,40(sp)
    802036e2:	f022                	sd	s0,32(sp)
    802036e4:	1800                	addi	s0,sp,48
    if (argfd(0, 0, &f) < 0) return -1;
    802036e6:	fd840613          	addi	a2,s0,-40
    802036ea:	4581                	li	a1,0
    802036ec:	4501                	li	a0,0
    802036ee:	00000097          	auipc	ra,0x0
    802036f2:	dc0080e7          	jalr	-576(ra) # 802034ae <argfd>
    802036f6:	57fd                	li	a5,-1
    802036f8:	02054763          	bltz	a0,80203726 <sys_dup+0x48>
    802036fc:	ec26                	sd	s1,24(sp)
    802036fe:	e84a                	sd	s2,16(sp)
    int fd = fdalloc(f);
    80203700:	fd843903          	ld	s2,-40(s0)
    80203704:	854a                	mv	a0,s2
    80203706:	00000097          	auipc	ra,0x0
    8020370a:	e08080e7          	jalr	-504(ra) # 8020350e <fdalloc>
    8020370e:	84aa                	mv	s1,a0
    if (fd < 0) return -1;
    80203710:	57fd                	li	a5,-1
    80203712:	00054f63          	bltz	a0,80203730 <sys_dup+0x52>
    filedup(f);
    80203716:	854a                	mv	a0,s2
    80203718:	00002097          	auipc	ra,0x2
    8020371c:	1e0080e7          	jalr	480(ra) # 802058f8 <filedup>
    return fd;
    80203720:	87a6                	mv	a5,s1
    80203722:	64e2                	ld	s1,24(sp)
    80203724:	6942                	ld	s2,16(sp)
}
    80203726:	853e                	mv	a0,a5
    80203728:	70a2                	ld	ra,40(sp)
    8020372a:	7402                	ld	s0,32(sp)
    8020372c:	6145                	addi	sp,sp,48
    8020372e:	8082                	ret
    80203730:	64e2                	ld	s1,24(sp)
    80203732:	6942                	ld	s2,16(sp)
    80203734:	bfcd                	j	80203726 <sys_dup+0x48>

0000000080203736 <sys_read>:
{
    80203736:	7179                	addi	sp,sp,-48
    80203738:	f406                	sd	ra,40(sp)
    8020373a:	f022                	sd	s0,32(sp)
    8020373c:	1800                	addi	s0,sp,48
    argaddr(1, &p);
    8020373e:	fd840593          	addi	a1,s0,-40
    80203742:	4505                	li	a0,1
    80203744:	00000097          	auipc	ra,0x0
    80203748:	c62080e7          	jalr	-926(ra) # 802033a6 <argaddr>
    argint(2, &n);
    8020374c:	fe440593          	addi	a1,s0,-28
    80203750:	4509                	li	a0,2
    80203752:	00000097          	auipc	ra,0x0
    80203756:	c32080e7          	jalr	-974(ra) # 80203384 <argint>
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    8020375a:	fe840613          	addi	a2,s0,-24
    8020375e:	4581                	li	a1,0
    80203760:	4501                	li	a0,0
    80203762:	00000097          	auipc	ra,0x0
    80203766:	d4c080e7          	jalr	-692(ra) # 802034ae <argfd>
    8020376a:	02054363          	bltz	a0,80203790 <sys_read+0x5a>
    8020376e:	fe442603          	lw	a2,-28(s0)
    80203772:	557d                	li	a0,-1
    80203774:	00064a63          	bltz	a2,80203788 <sys_read+0x52>
    return fileread(f, p, n);
    80203778:	fd843583          	ld	a1,-40(s0)
    8020377c:	fe843503          	ld	a0,-24(s0)
    80203780:	00002097          	auipc	ra,0x2
    80203784:	306080e7          	jalr	774(ra) # 80205a86 <fileread>
}
    80203788:	70a2                	ld	ra,40(sp)
    8020378a:	7402                	ld	s0,32(sp)
    8020378c:	6145                	addi	sp,sp,48
    8020378e:	8082                	ret
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    80203790:	557d                	li	a0,-1
    80203792:	bfdd                	j	80203788 <sys_read+0x52>

0000000080203794 <sys_write>:
{
    80203794:	7179                	addi	sp,sp,-48
    80203796:	f406                	sd	ra,40(sp)
    80203798:	f022                	sd	s0,32(sp)
    8020379a:	1800                	addi	s0,sp,48
    argaddr(1, &p);
    8020379c:	fd840593          	addi	a1,s0,-40
    802037a0:	4505                	li	a0,1
    802037a2:	00000097          	auipc	ra,0x0
    802037a6:	c04080e7          	jalr	-1020(ra) # 802033a6 <argaddr>
    argint(2, &n);
    802037aa:	fe440593          	addi	a1,s0,-28
    802037ae:	4509                	li	a0,2
    802037b0:	00000097          	auipc	ra,0x0
    802037b4:	bd4080e7          	jalr	-1068(ra) # 80203384 <argint>
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    802037b8:	fe840613          	addi	a2,s0,-24
    802037bc:	4581                	li	a1,0
    802037be:	4501                	li	a0,0
    802037c0:	00000097          	auipc	ra,0x0
    802037c4:	cee080e7          	jalr	-786(ra) # 802034ae <argfd>
    802037c8:	02054363          	bltz	a0,802037ee <sys_write+0x5a>
    802037cc:	fe442603          	lw	a2,-28(s0)
    802037d0:	557d                	li	a0,-1
    802037d2:	00064a63          	bltz	a2,802037e6 <sys_write+0x52>
    return filewrite(f, p, n);
    802037d6:	fd843583          	ld	a1,-40(s0)
    802037da:	fe843503          	ld	a0,-24(s0)
    802037de:	00002097          	auipc	ra,0x2
    802037e2:	37c080e7          	jalr	892(ra) # 80205b5a <filewrite>
}
    802037e6:	70a2                	ld	ra,40(sp)
    802037e8:	7402                	ld	s0,32(sp)
    802037ea:	6145                	addi	sp,sp,48
    802037ec:	8082                	ret
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    802037ee:	557d                	li	a0,-1
    802037f0:	bfdd                	j	802037e6 <sys_write+0x52>

00000000802037f2 <sys_close>:
{
    802037f2:	1101                	addi	sp,sp,-32
    802037f4:	ec06                	sd	ra,24(sp)
    802037f6:	e822                	sd	s0,16(sp)
    802037f8:	1000                	addi	s0,sp,32
    if (argfd(0, &fd, &f) < 0) return -1;
    802037fa:	fe040613          	addi	a2,s0,-32
    802037fe:	fec40593          	addi	a1,s0,-20
    80203802:	4501                	li	a0,0
    80203804:	00000097          	auipc	ra,0x0
    80203808:	caa080e7          	jalr	-854(ra) # 802034ae <argfd>
    8020380c:	57fd                	li	a5,-1
    8020380e:	02054463          	bltz	a0,80203836 <sys_close+0x44>
    myproc()->ofile[fd] = 0;
    80203812:	ffffe097          	auipc	ra,0xffffe
    80203816:	ecc080e7          	jalr	-308(ra) # 802016de <myproc>
    8020381a:	fec42783          	lw	a5,-20(s0)
    8020381e:	07e9                	addi	a5,a5,26
    80203820:	078e                	slli	a5,a5,0x3
    80203822:	953e                	add	a0,a0,a5
    80203824:	00053023          	sd	zero,0(a0)
    fileclose(f);
    80203828:	fe043503          	ld	a0,-32(s0)
    8020382c:	00002097          	auipc	ra,0x2
    80203830:	11e080e7          	jalr	286(ra) # 8020594a <fileclose>
    return 0;
    80203834:	4781                	li	a5,0
}
    80203836:	853e                	mv	a0,a5
    80203838:	60e2                	ld	ra,24(sp)
    8020383a:	6442                	ld	s0,16(sp)
    8020383c:	6105                	addi	sp,sp,32
    8020383e:	8082                	ret

0000000080203840 <sys_fstat>:
{
    80203840:	1101                	addi	sp,sp,-32
    80203842:	ec06                	sd	ra,24(sp)
    80203844:	e822                	sd	s0,16(sp)
    80203846:	1000                	addi	s0,sp,32
    argaddr(1, &st);
    80203848:	fe040593          	addi	a1,s0,-32
    8020384c:	4505                	li	a0,1
    8020384e:	00000097          	auipc	ra,0x0
    80203852:	b58080e7          	jalr	-1192(ra) # 802033a6 <argaddr>
    if (argfd(0, 0, &f) < 0) return -1;
    80203856:	fe840613          	addi	a2,s0,-24
    8020385a:	4581                	li	a1,0
    8020385c:	4501                	li	a0,0
    8020385e:	00000097          	auipc	ra,0x0
    80203862:	c50080e7          	jalr	-944(ra) # 802034ae <argfd>
    80203866:	87aa                	mv	a5,a0
    80203868:	557d                	li	a0,-1
    8020386a:	0007ca63          	bltz	a5,8020387e <sys_fstat+0x3e>
    return filestat(f, st);
    8020386e:	fe043583          	ld	a1,-32(s0)
    80203872:	fe843503          	ld	a0,-24(s0)
    80203876:	00002097          	auipc	ra,0x2
    8020387a:	1a2080e7          	jalr	418(ra) # 80205a18 <filestat>
}
    8020387e:	60e2                	ld	ra,24(sp)
    80203880:	6442                	ld	s0,16(sp)
    80203882:	6105                	addi	sp,sp,32
    80203884:	8082                	ret

0000000080203886 <sys_link>:
{
    80203886:	7129                	addi	sp,sp,-320
    80203888:	fe06                	sd	ra,312(sp)
    8020388a:	fa22                	sd	s0,304(sp)
    8020388c:	0280                	addi	s0,sp,320
    if (argstr(0, oldp, MAXPATH) < 0 || argstr(1, newp, MAXPATH) < 0) return -1;
    8020388e:	08000613          	li	a2,128
    80203892:	ec040593          	addi	a1,s0,-320
    80203896:	4501                	li	a0,0
    80203898:	00000097          	auipc	ra,0x0
    8020389c:	b7c080e7          	jalr	-1156(ra) # 80203414 <argstr>
    802038a0:	57fd                	li	a5,-1
    802038a2:	0e054f63          	bltz	a0,802039a0 <sys_link+0x11a>
    802038a6:	08000613          	li	a2,128
    802038aa:	f4040593          	addi	a1,s0,-192
    802038ae:	4505                	li	a0,1
    802038b0:	00000097          	auipc	ra,0x0
    802038b4:	b64080e7          	jalr	-1180(ra) # 80203414 <argstr>
    802038b8:	57fd                	li	a5,-1
    802038ba:	0e054363          	bltz	a0,802039a0 <sys_link+0x11a>
    802038be:	f626                	sd	s1,296(sp)
    struct inode *ip = namei(oldp);
    802038c0:	ec040513          	addi	a0,s0,-320
    802038c4:	00002097          	auipc	ra,0x2
    802038c8:	f68080e7          	jalr	-152(ra) # 8020582c <namei>
    802038cc:	84aa                	mv	s1,a0
    if (ip == 0) return -1;
    802038ce:	cd71                	beqz	a0,802039aa <sys_link+0x124>
    ilock(ip);
    802038d0:	00001097          	auipc	ra,0x1
    802038d4:	6ba080e7          	jalr	1722(ra) # 80204f8a <ilock>
    if (ip->type == T_DIR) {          /* hard links to dirs make cycles */
    802038d8:	0444d703          	lhu	a4,68(s1)
    802038dc:	4785                	li	a5,1
    802038de:	06f70d63          	beq	a4,a5,80203958 <sys_link+0xd2>
    802038e2:	f24a                	sd	s2,288(sp)
    ip->nlink++;
    802038e4:	04a4d783          	lhu	a5,74(s1)
    802038e8:	2785                	addiw	a5,a5,1
    802038ea:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    802038ee:	8526                	mv	a0,s1
    802038f0:	00001097          	auipc	ra,0x1
    802038f4:	5ce080e7          	jalr	1486(ra) # 80204ebe <iupdate>
    iunlock(ip);
    802038f8:	8526                	mv	a0,s1
    802038fa:	00001097          	auipc	ra,0x1
    802038fe:	756080e7          	jalr	1878(ra) # 80205050 <iunlock>
    struct inode *dp = nameiparent(newp, name);
    80203902:	fc040593          	addi	a1,s0,-64
    80203906:	f4040513          	addi	a0,s0,-192
    8020390a:	00002097          	auipc	ra,0x2
    8020390e:	f40080e7          	jalr	-192(ra) # 8020584a <nameiparent>
    80203912:	892a                	mv	s2,a0
    if (dp == 0) goto bad;
    80203914:	cd39                	beqz	a0,80203972 <sys_link+0xec>
    ilock(dp);
    80203916:	00001097          	auipc	ra,0x1
    8020391a:	674080e7          	jalr	1652(ra) # 80204f8a <ilock>
    if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0) {
    8020391e:	00092703          	lw	a4,0(s2)
    80203922:	409c                	lw	a5,0(s1)
    80203924:	04f71263          	bne	a4,a5,80203968 <sys_link+0xe2>
    80203928:	40d0                	lw	a2,4(s1)
    8020392a:	fc040593          	addi	a1,s0,-64
    8020392e:	854a                	mv	a0,s2
    80203930:	00002097          	auipc	ra,0x2
    80203934:	e34080e7          	jalr	-460(ra) # 80205764 <dirlink>
    80203938:	02054863          	bltz	a0,80203968 <sys_link+0xe2>
    iunlockput(dp);
    8020393c:	854a                	mv	a0,s2
    8020393e:	00002097          	auipc	ra,0x2
    80203942:	926080e7          	jalr	-1754(ra) # 80205264 <iunlockput>
    iput(ip);
    80203946:	8526                	mv	a0,s1
    80203948:	00002097          	auipc	ra,0x2
    8020394c:	800080e7          	jalr	-2048(ra) # 80205148 <iput>
    return 0;
    80203950:	4781                	li	a5,0
    80203952:	74b2                	ld	s1,296(sp)
    80203954:	7912                	ld	s2,288(sp)
    80203956:	a0a9                	j	802039a0 <sys_link+0x11a>
        iunlockput(ip);
    80203958:	8526                	mv	a0,s1
    8020395a:	00002097          	auipc	ra,0x2
    8020395e:	90a080e7          	jalr	-1782(ra) # 80205264 <iunlockput>
        return -1;
    80203962:	57fd                	li	a5,-1
    80203964:	74b2                	ld	s1,296(sp)
    80203966:	a82d                	j	802039a0 <sys_link+0x11a>
        iunlockput(dp);
    80203968:	854a                	mv	a0,s2
    8020396a:	00002097          	auipc	ra,0x2
    8020396e:	8fa080e7          	jalr	-1798(ra) # 80205264 <iunlockput>
    ilock(ip);
    80203972:	8526                	mv	a0,s1
    80203974:	00001097          	auipc	ra,0x1
    80203978:	616080e7          	jalr	1558(ra) # 80204f8a <ilock>
    ip->nlink--;
    8020397c:	04a4d783          	lhu	a5,74(s1)
    80203980:	37fd                	addiw	a5,a5,-1
    80203982:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80203986:	8526                	mv	a0,s1
    80203988:	00001097          	auipc	ra,0x1
    8020398c:	536080e7          	jalr	1334(ra) # 80204ebe <iupdate>
    iunlockput(ip);
    80203990:	8526                	mv	a0,s1
    80203992:	00002097          	auipc	ra,0x2
    80203996:	8d2080e7          	jalr	-1838(ra) # 80205264 <iunlockput>
    return -1;
    8020399a:	57fd                	li	a5,-1
    8020399c:	74b2                	ld	s1,296(sp)
    8020399e:	7912                	ld	s2,288(sp)
}
    802039a0:	853e                	mv	a0,a5
    802039a2:	70f2                	ld	ra,312(sp)
    802039a4:	7452                	ld	s0,304(sp)
    802039a6:	6131                	addi	sp,sp,320
    802039a8:	8082                	ret
    if (ip == 0) return -1;
    802039aa:	57fd                	li	a5,-1
    802039ac:	74b2                	ld	s1,296(sp)
    802039ae:	bfcd                	j	802039a0 <sys_link+0x11a>

00000000802039b0 <sys_unlink>:
{
    802039b0:	7169                	addi	sp,sp,-304
    802039b2:	f606                	sd	ra,296(sp)
    802039b4:	f222                	sd	s0,288(sp)
    802039b6:	1a00                	addi	s0,sp,304
    if (argstr(0, path, MAXPATH) < 0) return -1;
    802039b8:	08000613          	li	a2,128
    802039bc:	f2040593          	addi	a1,s0,-224
    802039c0:	4501                	li	a0,0
    802039c2:	00000097          	auipc	ra,0x0
    802039c6:	a52080e7          	jalr	-1454(ra) # 80203414 <argstr>
    802039ca:	1a054363          	bltz	a0,80203b70 <sys_unlink+0x1c0>
    802039ce:	ee26                	sd	s1,280(sp)
    struct inode *dp = nameiparent(path, name);
    802039d0:	fa040593          	addi	a1,s0,-96
    802039d4:	f2040513          	addi	a0,s0,-224
    802039d8:	00002097          	auipc	ra,0x2
    802039dc:	e72080e7          	jalr	-398(ra) # 8020584a <nameiparent>
    802039e0:	84aa                	mv	s1,a0
    if (dp == 0) return -1;
    802039e2:	18050963          	beqz	a0,80203b74 <sys_unlink+0x1c4>
    ilock(dp);
    802039e6:	00001097          	auipc	ra,0x1
    802039ea:	5a4080e7          	jalr	1444(ra) # 80204f8a <ilock>
    if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0) goto bad;
    802039ee:	00004597          	auipc	a1,0x4
    802039f2:	f3258593          	addi	a1,a1,-206 # 80207920 <etext+0x920>
    802039f6:	fa040513          	addi	a0,s0,-96
    802039fa:	00002097          	auipc	ra,0x2
    802039fe:	b2c080e7          	jalr	-1236(ra) # 80205526 <namecmp>
    80203a02:	14050c63          	beqz	a0,80203b5a <sys_unlink+0x1aa>
    80203a06:	00004597          	auipc	a1,0x4
    80203a0a:	f2258593          	addi	a1,a1,-222 # 80207928 <etext+0x928>
    80203a0e:	fa040513          	addi	a0,s0,-96
    80203a12:	00002097          	auipc	ra,0x2
    80203a16:	b14080e7          	jalr	-1260(ra) # 80205526 <namecmp>
    80203a1a:	14050063          	beqz	a0,80203b5a <sys_unlink+0x1aa>
    80203a1e:	ea4a                	sd	s2,272(sp)
    struct inode *ip = dirlookup(dp, name, &off);
    80203a20:	f1c40613          	addi	a2,s0,-228
    80203a24:	fa040593          	addi	a1,s0,-96
    80203a28:	8526                	mv	a0,s1
    80203a2a:	00002097          	auipc	ra,0x2
    80203a2e:	b16080e7          	jalr	-1258(ra) # 80205540 <dirlookup>
    80203a32:	892a                	mv	s2,a0
    if (ip == 0) goto bad;
    80203a34:	12050263          	beqz	a0,80203b58 <sys_unlink+0x1a8>
    ilock(ip);                        /* lock order: parent, then child */
    80203a38:	00001097          	auipc	ra,0x1
    80203a3c:	552080e7          	jalr	1362(ra) # 80204f8a <ilock>
    if (ip->nlink < 1) panic("unlink: nlink < 1");
    80203a40:	04a95783          	lhu	a5,74(s2)
    80203a44:	cfb5                	beqz	a5,80203ac0 <sys_unlink+0x110>
    80203a46:	e64e                	sd	s3,264(sp)
    if (ip->type == T_DIR && !isdirempty(ip)) {
    80203a48:	04495703          	lhu	a4,68(s2)
    80203a4c:	4785                	li	a5,1
    80203a4e:	08f70463          	beq	a4,a5,80203ad6 <sys_unlink+0x126>
    memset(&de, 0, sizeof(de));
    80203a52:	ef840993          	addi	s3,s0,-264
    80203a56:	02000613          	li	a2,32
    80203a5a:	4581                	li	a1,0
    80203a5c:	854e                	mv	a0,s3
    80203a5e:	ffffd097          	auipc	ra,0xffffd
    80203a62:	bf8080e7          	jalr	-1032(ra) # 80200656 <memset>
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80203a66:	02000713          	li	a4,32
    80203a6a:	f1c42683          	lw	a3,-228(s0)
    80203a6e:	864e                	mv	a2,s3
    80203a70:	4581                	li	a1,0
    80203a72:	8526                	mv	a0,s1
    80203a74:	00002097          	auipc	ra,0x2
    80203a78:	96e080e7          	jalr	-1682(ra) # 802053e2 <writei>
    80203a7c:	02000793          	li	a5,32
    80203a80:	0af51763          	bne	a0,a5,80203b2e <sys_unlink+0x17e>
    if (ip->type == T_DIR) {
    80203a84:	04495703          	lhu	a4,68(s2)
    80203a88:	4785                	li	a5,1
    80203a8a:	0af70c63          	beq	a4,a5,80203b42 <sys_unlink+0x192>
    iunlockput(dp);
    80203a8e:	8526                	mv	a0,s1
    80203a90:	00001097          	auipc	ra,0x1
    80203a94:	7d4080e7          	jalr	2004(ra) # 80205264 <iunlockput>
    ip->nlink--;
    80203a98:	04a95783          	lhu	a5,74(s2)
    80203a9c:	37fd                	addiw	a5,a5,-1
    80203a9e:	04f91523          	sh	a5,74(s2)
    iupdate(ip);
    80203aa2:	854a                	mv	a0,s2
    80203aa4:	00001097          	auipc	ra,0x1
    80203aa8:	41a080e7          	jalr	1050(ra) # 80204ebe <iupdate>
    iunlockput(ip);                   /* data freed in iput if last ref+link */
    80203aac:	854a                	mv	a0,s2
    80203aae:	00001097          	auipc	ra,0x1
    80203ab2:	7b6080e7          	jalr	1974(ra) # 80205264 <iunlockput>
    return 0;
    80203ab6:	4501                	li	a0,0
    80203ab8:	64f2                	ld	s1,280(sp)
    80203aba:	6952                	ld	s2,272(sp)
    80203abc:	69b2                	ld	s3,264(sp)
    80203abe:	a06d                	j	80203b68 <sys_unlink+0x1b8>
    80203ac0:	e64e                	sd	s3,264(sp)
    80203ac2:	e252                	sd	s4,256(sp)
    80203ac4:	fdd6                	sd	s5,248(sp)
    if (ip->nlink < 1) panic("unlink: nlink < 1");
    80203ac6:	00004517          	auipc	a0,0x4
    80203aca:	e6a50513          	addi	a0,a0,-406 # 80207930 <etext+0x930>
    80203ace:	ffffd097          	auipc	ra,0xffffd
    80203ad2:	ae2080e7          	jalr	-1310(ra) # 802005b0 <panic>
    for (uint32 off = 2 * sizeof(de); off < dp->size; off += sizeof(de)) {
    80203ad6:	04c92703          	lw	a4,76(s2)
    80203ada:	04000793          	li	a5,64
    80203ade:	f6e7fae3          	bgeu	a5,a4,80203a52 <sys_unlink+0xa2>
    80203ae2:	e252                	sd	s4,256(sp)
    80203ae4:	fdd6                	sd	s5,248(sp)
    80203ae6:	89be                	mv	s3,a5
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80203ae8:	ed840a93          	addi	s5,s0,-296
    80203aec:	02000a13          	li	s4,32
    80203af0:	8752                	mv	a4,s4
    80203af2:	86ce                	mv	a3,s3
    80203af4:	8656                	mv	a2,s5
    80203af6:	4581                	li	a1,0
    80203af8:	854a                	mv	a0,s2
    80203afa:	00001097          	auipc	ra,0x1
    80203afe:	7c0080e7          	jalr	1984(ra) # 802052ba <readi>
    80203b02:	01451e63          	bne	a0,s4,80203b1e <sys_unlink+0x16e>
        if (de.inum != 0) return 0;
    80203b06:	ed842783          	lw	a5,-296(s0)
    80203b0a:	eba5                	bnez	a5,80203b7a <sys_unlink+0x1ca>
    for (uint32 off = 2 * sizeof(de); off < dp->size; off += sizeof(de)) {
    80203b0c:	0209899b          	addiw	s3,s3,32
    80203b10:	04c92783          	lw	a5,76(s2)
    80203b14:	fcf9eee3          	bltu	s3,a5,80203af0 <sys_unlink+0x140>
    80203b18:	6a12                	ld	s4,256(sp)
    80203b1a:	7aee                	ld	s5,248(sp)
    80203b1c:	bf1d                	j	80203a52 <sys_unlink+0xa2>
            panic("isdirempty: short read");
    80203b1e:	00004517          	auipc	a0,0x4
    80203b22:	e2a50513          	addi	a0,a0,-470 # 80207948 <etext+0x948>
    80203b26:	ffffd097          	auipc	ra,0xffffd
    80203b2a:	a8a080e7          	jalr	-1398(ra) # 802005b0 <panic>
    80203b2e:	e252                	sd	s4,256(sp)
    80203b30:	fdd6                	sd	s5,248(sp)
        panic("unlink: writei");
    80203b32:	00004517          	auipc	a0,0x4
    80203b36:	e2e50513          	addi	a0,a0,-466 # 80207960 <etext+0x960>
    80203b3a:	ffffd097          	auipc	ra,0xffffd
    80203b3e:	a76080e7          	jalr	-1418(ra) # 802005b0 <panic>
        dp->nlink--;                  /* the child's ".." no longer counts */
    80203b42:	04a4d783          	lhu	a5,74(s1)
    80203b46:	37fd                	addiw	a5,a5,-1
    80203b48:	04f49523          	sh	a5,74(s1)
        iupdate(dp);
    80203b4c:	8526                	mv	a0,s1
    80203b4e:	00001097          	auipc	ra,0x1
    80203b52:	370080e7          	jalr	880(ra) # 80204ebe <iupdate>
    80203b56:	bf25                	j	80203a8e <sys_unlink+0xde>
    80203b58:	6952                	ld	s2,272(sp)
    iunlockput(dp);
    80203b5a:	8526                	mv	a0,s1
    80203b5c:	00001097          	auipc	ra,0x1
    80203b60:	708080e7          	jalr	1800(ra) # 80205264 <iunlockput>
    return -1;
    80203b64:	557d                	li	a0,-1
    80203b66:	64f2                	ld	s1,280(sp)
}
    80203b68:	70b2                	ld	ra,296(sp)
    80203b6a:	7412                	ld	s0,288(sp)
    80203b6c:	6155                	addi	sp,sp,304
    80203b6e:	8082                	ret
    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203b70:	557d                	li	a0,-1
    80203b72:	bfdd                	j	80203b68 <sys_unlink+0x1b8>
    if (dp == 0) return -1;
    80203b74:	557d                	li	a0,-1
    80203b76:	64f2                	ld	s1,280(sp)
    80203b78:	bfc5                	j	80203b68 <sys_unlink+0x1b8>
        iunlockput(ip);
    80203b7a:	854a                	mv	a0,s2
    80203b7c:	00001097          	auipc	ra,0x1
    80203b80:	6e8080e7          	jalr	1768(ra) # 80205264 <iunlockput>
        goto bad;
    80203b84:	6952                	ld	s2,272(sp)
    80203b86:	69b2                	ld	s3,264(sp)
    80203b88:	6a12                	ld	s4,256(sp)
    80203b8a:	7aee                	ld	s5,248(sp)
    80203b8c:	b7f9                	j	80203b5a <sys_unlink+0x1aa>

0000000080203b8e <sys_open>:

uint64 sys_open(void)
{
    80203b8e:	7131                	addi	sp,sp,-192
    80203b90:	fd06                	sd	ra,184(sp)
    80203b92:	f922                	sd	s0,176(sp)
    80203b94:	0180                	addi	s0,sp,192
    char path[MAXPATH];
    int omode;
    argint(1, &omode);
    80203b96:	f4c40593          	addi	a1,s0,-180
    80203b9a:	4505                	li	a0,1
    80203b9c:	fffff097          	auipc	ra,0xfffff
    80203ba0:	7e8080e7          	jalr	2024(ra) # 80203384 <argint>
    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203ba4:	08000613          	li	a2,128
    80203ba8:	f5040593          	addi	a1,s0,-176
    80203bac:	4501                	li	a0,0
    80203bae:	00000097          	auipc	ra,0x0
    80203bb2:	866080e7          	jalr	-1946(ra) # 80203414 <argstr>
    80203bb6:	12054c63          	bltz	a0,80203cee <sys_open+0x160>
    80203bba:	f526                	sd	s1,168(sp)

    struct inode *ip;
    if (omode & O_CREATE) {
    80203bbc:	f4c42783          	lw	a5,-180(s0)
    80203bc0:	2007f793          	andi	a5,a5,512
    80203bc4:	c7cd                	beqz	a5,80203c6e <sys_open+0xe0>
        ip = create(path, T_FILE, 0, 0);
    80203bc6:	4681                	li	a3,0
    80203bc8:	4601                	li	a2,0
    80203bca:	4589                	li	a1,2
    80203bcc:	f5040513          	addi	a0,s0,-176
    80203bd0:	00000097          	auipc	ra,0x0
    80203bd4:	980080e7          	jalr	-1664(ra) # 80203550 <create>
    80203bd8:	84aa                	mv	s1,a0
        if (ip == 0) return -1;
    80203bda:	10050c63          	beqz	a0,80203cf2 <sys_open+0x164>
        if (ip->type == T_DIR && omode != O_RDONLY) {
            iunlockput(ip);
            return -1;
        }
    }
    if (ip->type == T_DEV && (ip->major < 0 || ip->major >= NDEV)) {
    80203bde:	0444d703          	lhu	a4,68(s1)
    80203be2:	478d                	li	a5,3
    80203be4:	00f71763          	bne	a4,a5,80203bf2 <sys_open+0x64>
    80203be8:	0464d703          	lhu	a4,70(s1)
    80203bec:	47a5                	li	a5,9
    80203bee:	0ae7ec63          	bltu	a5,a4,80203ca6 <sys_open+0x118>
    80203bf2:	f14a                	sd	s2,160(sp)
        iunlockput(ip);
        return -1;
    }

    struct file *f = filealloc();
    80203bf4:	00002097          	auipc	ra,0x2
    80203bf8:	c9a080e7          	jalr	-870(ra) # 8020588e <filealloc>
    80203bfc:	892a                	mv	s2,a0
    int fd;
    if (f == 0 || (fd = fdalloc(f)) < 0) {
    80203bfe:	c171                	beqz	a0,80203cc2 <sys_open+0x134>
    80203c00:	ed4e                	sd	s3,152(sp)
    80203c02:	00000097          	auipc	ra,0x0
    80203c06:	90c080e7          	jalr	-1780(ra) # 8020350e <fdalloc>
    80203c0a:	89aa                	mv	s3,a0
    80203c0c:	0a054563          	bltz	a0,80203cb6 <sys_open+0x128>
        if (f) fileclose(f);
        iunlockput(ip);
        return -1;
    }

    if (ip->type == T_DEV) {
    80203c10:	0444d703          	lhu	a4,68(s1)
    80203c14:	478d                	li	a5,3
    80203c16:	0af70f63          	beq	a4,a5,80203cd4 <sys_open+0x146>
        f->type  = FD_DEVICE;
        f->major = ip->major;
    } else {
        f->type = FD_INODE;
    80203c1a:	4789                	li	a5,2
    80203c1c:	00f92023          	sw	a5,0(s2)
        f->off  = 0;
    80203c20:	02092023          	sw	zero,32(s2)
    }
    f->ip       = ip;
    80203c24:	00993c23          	sd	s1,24(s2)
    f->readable = !(omode & O_WRONLY);
    80203c28:	f4c42783          	lw	a5,-180(s0)
    80203c2c:	0017f713          	andi	a4,a5,1
    80203c30:	00174713          	xori	a4,a4,1
    80203c34:	00e90423          	sb	a4,8(s2)
    f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80203c38:	0037f713          	andi	a4,a5,3
    80203c3c:	00e03733          	snez	a4,a4
    80203c40:	00e904a3          	sb	a4,9(s2)

    if ((omode & O_TRUNC) && ip->type == T_FILE)
    80203c44:	4007f793          	andi	a5,a5,1024
    80203c48:	c791                	beqz	a5,80203c54 <sys_open+0xc6>
    80203c4a:	0444d703          	lhu	a4,68(s1)
    80203c4e:	4789                	li	a5,2
    80203c50:	08f70963          	beq	a4,a5,80203ce2 <sys_open+0x154>
        itrunc(ip);

    iunlock(ip);
    80203c54:	8526                	mv	a0,s1
    80203c56:	00001097          	auipc	ra,0x1
    80203c5a:	3fa080e7          	jalr	1018(ra) # 80205050 <iunlock>
    return fd;
    80203c5e:	854e                	mv	a0,s3
    80203c60:	74aa                	ld	s1,168(sp)
    80203c62:	790a                	ld	s2,160(sp)
    80203c64:	69ea                	ld	s3,152(sp)
}
    80203c66:	70ea                	ld	ra,184(sp)
    80203c68:	744a                	ld	s0,176(sp)
    80203c6a:	6129                	addi	sp,sp,192
    80203c6c:	8082                	ret
        if ((ip = namei(path)) == 0) return -1;
    80203c6e:	f5040513          	addi	a0,s0,-176
    80203c72:	00002097          	auipc	ra,0x2
    80203c76:	bba080e7          	jalr	-1094(ra) # 8020582c <namei>
    80203c7a:	84aa                	mv	s1,a0
    80203c7c:	cd35                	beqz	a0,80203cf8 <sys_open+0x16a>
        ilock(ip);
    80203c7e:	00001097          	auipc	ra,0x1
    80203c82:	30c080e7          	jalr	780(ra) # 80204f8a <ilock>
        if (ip->type == T_DIR && omode != O_RDONLY) {
    80203c86:	0444d703          	lhu	a4,68(s1)
    80203c8a:	4785                	li	a5,1
    80203c8c:	f4f719e3          	bne	a4,a5,80203bde <sys_open+0x50>
    80203c90:	f4c42783          	lw	a5,-180(s0)
    80203c94:	dfb9                	beqz	a5,80203bf2 <sys_open+0x64>
            iunlockput(ip);
    80203c96:	8526                	mv	a0,s1
    80203c98:	00001097          	auipc	ra,0x1
    80203c9c:	5cc080e7          	jalr	1484(ra) # 80205264 <iunlockput>
            return -1;
    80203ca0:	557d                	li	a0,-1
    80203ca2:	74aa                	ld	s1,168(sp)
    80203ca4:	b7c9                	j	80203c66 <sys_open+0xd8>
        iunlockput(ip);
    80203ca6:	8526                	mv	a0,s1
    80203ca8:	00001097          	auipc	ra,0x1
    80203cac:	5bc080e7          	jalr	1468(ra) # 80205264 <iunlockput>
        return -1;
    80203cb0:	557d                	li	a0,-1
    80203cb2:	74aa                	ld	s1,168(sp)
    80203cb4:	bf4d                	j	80203c66 <sys_open+0xd8>
        if (f) fileclose(f);
    80203cb6:	854a                	mv	a0,s2
    80203cb8:	00002097          	auipc	ra,0x2
    80203cbc:	c92080e7          	jalr	-878(ra) # 8020594a <fileclose>
    80203cc0:	69ea                	ld	s3,152(sp)
        iunlockput(ip);
    80203cc2:	8526                	mv	a0,s1
    80203cc4:	00001097          	auipc	ra,0x1
    80203cc8:	5a0080e7          	jalr	1440(ra) # 80205264 <iunlockput>
        return -1;
    80203ccc:	557d                	li	a0,-1
    80203cce:	74aa                	ld	s1,168(sp)
    80203cd0:	790a                	ld	s2,160(sp)
    80203cd2:	bf51                	j	80203c66 <sys_open+0xd8>
        f->type  = FD_DEVICE;
    80203cd4:	00f92023          	sw	a5,0(s2)
        f->major = ip->major;
    80203cd8:	0464d783          	lhu	a5,70(s1)
    80203cdc:	02f91223          	sh	a5,36(s2)
    80203ce0:	b791                	j	80203c24 <sys_open+0x96>
        itrunc(ip);
    80203ce2:	8526                	mv	a0,s1
    80203ce4:	00001097          	auipc	ra,0x1
    80203ce8:	3b8080e7          	jalr	952(ra) # 8020509c <itrunc>
    80203cec:	b7a5                	j	80203c54 <sys_open+0xc6>
    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203cee:	557d                	li	a0,-1
    80203cf0:	bf9d                	j	80203c66 <sys_open+0xd8>
        if (ip == 0) return -1;
    80203cf2:	557d                	li	a0,-1
    80203cf4:	74aa                	ld	s1,168(sp)
    80203cf6:	bf85                	j	80203c66 <sys_open+0xd8>
        if ((ip = namei(path)) == 0) return -1;
    80203cf8:	557d                	li	a0,-1
    80203cfa:	74aa                	ld	s1,168(sp)
    80203cfc:	b7ad                	j	80203c66 <sys_open+0xd8>

0000000080203cfe <sys_mkdir>:

uint64 sys_mkdir(void)
{
    80203cfe:	7175                	addi	sp,sp,-144
    80203d00:	e506                	sd	ra,136(sp)
    80203d02:	e122                	sd	s0,128(sp)
    80203d04:	0900                	addi	s0,sp,144
    char path[MAXPATH];
    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203d06:	08000613          	li	a2,128
    80203d0a:	f7040593          	addi	a1,s0,-144
    80203d0e:	4501                	li	a0,0
    80203d10:	fffff097          	auipc	ra,0xfffff
    80203d14:	704080e7          	jalr	1796(ra) # 80203414 <argstr>
    80203d18:	57fd                	li	a5,-1
    80203d1a:	02054163          	bltz	a0,80203d3c <sys_mkdir+0x3e>
    struct inode *ip = create(path, T_DIR, 0, 0);
    80203d1e:	4681                	li	a3,0
    80203d20:	4601                	li	a2,0
    80203d22:	4585                	li	a1,1
    80203d24:	f7040513          	addi	a0,s0,-144
    80203d28:	00000097          	auipc	ra,0x0
    80203d2c:	828080e7          	jalr	-2008(ra) # 80203550 <create>
    if (ip == 0) return -1;
    80203d30:	c919                	beqz	a0,80203d46 <sys_mkdir+0x48>
    iunlockput(ip);
    80203d32:	00001097          	auipc	ra,0x1
    80203d36:	532080e7          	jalr	1330(ra) # 80205264 <iunlockput>
    return 0;
    80203d3a:	4781                	li	a5,0
}
    80203d3c:	853e                	mv	a0,a5
    80203d3e:	60aa                	ld	ra,136(sp)
    80203d40:	640a                	ld	s0,128(sp)
    80203d42:	6149                	addi	sp,sp,144
    80203d44:	8082                	ret
    if (ip == 0) return -1;
    80203d46:	57fd                	li	a5,-1
    80203d48:	bfd5                	j	80203d3c <sys_mkdir+0x3e>

0000000080203d4a <sys_chdir>:

uint64 sys_chdir(void)
{
    80203d4a:	7135                	addi	sp,sp,-160
    80203d4c:	ed06                	sd	ra,152(sp)
    80203d4e:	e922                	sd	s0,144(sp)
    80203d50:	e14a                	sd	s2,128(sp)
    80203d52:	1100                	addi	s0,sp,160
    char path[MAXPATH];
    struct proc *p = myproc();
    80203d54:	ffffe097          	auipc	ra,0xffffe
    80203d58:	98a080e7          	jalr	-1654(ra) # 802016de <myproc>
    80203d5c:	892a                	mv	s2,a0
    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203d5e:	08000613          	li	a2,128
    80203d62:	f6040593          	addi	a1,s0,-160
    80203d66:	4501                	li	a0,0
    80203d68:	fffff097          	auipc	ra,0xfffff
    80203d6c:	6ac080e7          	jalr	1708(ra) # 80203414 <argstr>
    80203d70:	57fd                	li	a5,-1
    80203d72:	04054363          	bltz	a0,80203db8 <sys_chdir+0x6e>
    80203d76:	e526                	sd	s1,136(sp)
    struct inode *ip = namei(path);
    80203d78:	f6040513          	addi	a0,s0,-160
    80203d7c:	00002097          	auipc	ra,0x2
    80203d80:	ab0080e7          	jalr	-1360(ra) # 8020582c <namei>
    80203d84:	84aa                	mv	s1,a0
    if (ip == 0) return -1;
    80203d86:	c539                	beqz	a0,80203dd4 <sys_chdir+0x8a>
    ilock(ip);
    80203d88:	00001097          	auipc	ra,0x1
    80203d8c:	202080e7          	jalr	514(ra) # 80204f8a <ilock>
    if (ip->type != T_DIR) { iunlockput(ip); return -1; }
    80203d90:	0444d703          	lhu	a4,68(s1)
    80203d94:	4785                	li	a5,1
    80203d96:	02f71763          	bne	a4,a5,80203dc4 <sys_chdir+0x7a>
    iunlock(ip);
    80203d9a:	8526                	mv	a0,s1
    80203d9c:	00001097          	auipc	ra,0x1
    80203da0:	2b4080e7          	jalr	692(ra) # 80205050 <iunlock>
    iput(p->cwd);
    80203da4:	15093503          	ld	a0,336(s2)
    80203da8:	00001097          	auipc	ra,0x1
    80203dac:	3a0080e7          	jalr	928(ra) # 80205148 <iput>
    p->cwd = ip;
    80203db0:	14993823          	sd	s1,336(s2)
    return 0;
    80203db4:	4781                	li	a5,0
    80203db6:	64aa                	ld	s1,136(sp)
}
    80203db8:	853e                	mv	a0,a5
    80203dba:	60ea                	ld	ra,152(sp)
    80203dbc:	644a                	ld	s0,144(sp)
    80203dbe:	690a                	ld	s2,128(sp)
    80203dc0:	610d                	addi	sp,sp,160
    80203dc2:	8082                	ret
    if (ip->type != T_DIR) { iunlockput(ip); return -1; }
    80203dc4:	8526                	mv	a0,s1
    80203dc6:	00001097          	auipc	ra,0x1
    80203dca:	49e080e7          	jalr	1182(ra) # 80205264 <iunlockput>
    80203dce:	57fd                	li	a5,-1
    80203dd0:	64aa                	ld	s1,136(sp)
    80203dd2:	b7dd                	j	80203db8 <sys_chdir+0x6e>
    if (ip == 0) return -1;
    80203dd4:	57fd                	li	a5,-1
    80203dd6:	64aa                	ld	s1,136(sp)
    80203dd8:	b7c5                	j	80203db8 <sys_chdir+0x6e>

0000000080203dda <sys_pipe>:

uint64 sys_pipe(void)
{
    80203dda:	7139                	addi	sp,sp,-64
    80203ddc:	fc06                	sd	ra,56(sp)
    80203dde:	f822                	sd	s0,48(sp)
    80203de0:	0080                	addi	s0,sp,64
    uint64 fdarray;                   /* user pointer to int[2] */
    argaddr(0, &fdarray);
    80203de2:	fd840593          	addi	a1,s0,-40
    80203de6:	4501                	li	a0,0
    80203de8:	fffff097          	auipc	ra,0xfffff
    80203dec:	5be080e7          	jalr	1470(ra) # 802033a6 <argaddr>

    struct file *rf, *wf;
    if (pipealloc(&rf, &wf) < 0) return -1;
    80203df0:	fc840593          	addi	a1,s0,-56
    80203df4:	fd040513          	addi	a0,s0,-48
    80203df8:	00002097          	auipc	ra,0x2
    80203dfc:	e42080e7          	jalr	-446(ra) # 80205c3a <pipealloc>
    80203e00:	57fd                	li	a5,-1
    80203e02:	0a054463          	bltz	a0,80203eaa <sys_pipe+0xd0>
    80203e06:	f426                	sd	s1,40(sp)

    struct proc *p = myproc();
    80203e08:	ffffe097          	auipc	ra,0xffffe
    80203e0c:	8d6080e7          	jalr	-1834(ra) # 802016de <myproc>
    80203e10:	84aa                	mv	s1,a0
    int fd0 = -1, fd1 = -1;
    80203e12:	57fd                	li	a5,-1
    80203e14:	fcf42223          	sw	a5,-60(s0)
    80203e18:	fcf42023          	sw	a5,-64(s0)
    if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0) {
    80203e1c:	fd043503          	ld	a0,-48(s0)
    80203e20:	fffff097          	auipc	ra,0xfffff
    80203e24:	6ee080e7          	jalr	1774(ra) # 8020350e <fdalloc>
    80203e28:	fca42223          	sw	a0,-60(s0)
    80203e2c:	06054163          	bltz	a0,80203e8e <sys_pipe+0xb4>
    80203e30:	fc843503          	ld	a0,-56(s0)
    80203e34:	fffff097          	auipc	ra,0xfffff
    80203e38:	6da080e7          	jalr	1754(ra) # 8020350e <fdalloc>
    80203e3c:	fca42023          	sw	a0,-64(s0)
    80203e40:	02054e63          	bltz	a0,80203e7c <sys_pipe+0xa2>
        if (fd0 >= 0) p->ofile[fd0] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80203e44:	4691                	li	a3,4
    80203e46:	fc440613          	addi	a2,s0,-60
    80203e4a:	fd843583          	ld	a1,-40(s0)
    80203e4e:	68a8                	ld	a0,80(s1)
    80203e50:	fffff097          	auipc	ra,0xfffff
    80203e54:	08e080e7          	jalr	142(ra) # 80202ede <copyout>
    80203e58:	04054e63          	bltz	a0,80203eb4 <sys_pipe+0xda>
        copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0) {
    80203e5c:	4691                	li	a3,4
    80203e5e:	fc040613          	addi	a2,s0,-64
    80203e62:	fd843583          	ld	a1,-40(s0)
    80203e66:	95b6                	add	a1,a1,a3
    80203e68:	68a8                	ld	a0,80(s1)
    80203e6a:	fffff097          	auipc	ra,0xfffff
    80203e6e:	074080e7          	jalr	116(ra) # 80202ede <copyout>
        p->ofile[fd1] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    return 0;
    80203e72:	4781                	li	a5,0
    if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80203e74:	04054063          	bltz	a0,80203eb4 <sys_pipe+0xda>
    80203e78:	74a2                	ld	s1,40(sp)
    80203e7a:	a805                	j	80203eaa <sys_pipe+0xd0>
        if (fd0 >= 0) p->ofile[fd0] = 0;
    80203e7c:	fc442783          	lw	a5,-60(s0)
    80203e80:	0007c763          	bltz	a5,80203e8e <sys_pipe+0xb4>
    80203e84:	07e9                	addi	a5,a5,26
    80203e86:	078e                	slli	a5,a5,0x3
    80203e88:	97a6                	add	a5,a5,s1
    80203e8a:	0007b023          	sd	zero,0(a5)
        fileclose(rf);
    80203e8e:	fd043503          	ld	a0,-48(s0)
    80203e92:	00002097          	auipc	ra,0x2
    80203e96:	ab8080e7          	jalr	-1352(ra) # 8020594a <fileclose>
        fileclose(wf);
    80203e9a:	fc843503          	ld	a0,-56(s0)
    80203e9e:	00002097          	auipc	ra,0x2
    80203ea2:	aac080e7          	jalr	-1364(ra) # 8020594a <fileclose>
        return -1;
    80203ea6:	57fd                	li	a5,-1
    80203ea8:	74a2                	ld	s1,40(sp)
}
    80203eaa:	853e                	mv	a0,a5
    80203eac:	70e2                	ld	ra,56(sp)
    80203eae:	7442                	ld	s0,48(sp)
    80203eb0:	6121                	addi	sp,sp,64
    80203eb2:	8082                	ret
        p->ofile[fd0] = 0;
    80203eb4:	fc442783          	lw	a5,-60(s0)
    80203eb8:	07e9                	addi	a5,a5,26
    80203eba:	078e                	slli	a5,a5,0x3
    80203ebc:	97a6                	add	a5,a5,s1
    80203ebe:	0007b023          	sd	zero,0(a5)
        p->ofile[fd1] = 0;
    80203ec2:	fc042783          	lw	a5,-64(s0)
    80203ec6:	07e9                	addi	a5,a5,26
    80203ec8:	078e                	slli	a5,a5,0x3
    80203eca:	94be                	add	s1,s1,a5
    80203ecc:	0004b023          	sd	zero,0(s1)
        fileclose(rf);
    80203ed0:	fd043503          	ld	a0,-48(s0)
    80203ed4:	00002097          	auipc	ra,0x2
    80203ed8:	a76080e7          	jalr	-1418(ra) # 8020594a <fileclose>
        fileclose(wf);
    80203edc:	fc843503          	ld	a0,-56(s0)
    80203ee0:	00002097          	auipc	ra,0x2
    80203ee4:	a6a080e7          	jalr	-1430(ra) # 8020594a <fileclose>
        return -1;
    80203ee8:	57fd                	li	a5,-1
    80203eea:	74a2                	ld	s1,40(sp)
    80203eec:	bf7d                	j	80203eaa <sys_pipe+0xd0>

0000000080203eee <sys_exec>:

uint64 sys_exec(void)
{
    80203eee:	710d                	addi	sp,sp,-352
    80203ef0:	ee86                	sd	ra,344(sp)
    80203ef2:	eaa2                	sd	s0,336(sp)
    80203ef4:	1280                	addi	s0,sp,352
    char path[MAXPATH];
    uint64 uargv, uarg;
    char *argv[MAXARG];

    if (argstr(0, path, MAXPATH) < 0) return -1;
    80203ef6:	08000613          	li	a2,128
    80203efa:	f3040593          	addi	a1,s0,-208
    80203efe:	4501                	li	a0,0
    80203f00:	fffff097          	auipc	ra,0xfffff
    80203f04:	514080e7          	jalr	1300(ra) # 80203414 <argstr>
    80203f08:	87aa                	mv	a5,a0
    80203f0a:	557d                	li	a0,-1
    80203f0c:	0c07c263          	bltz	a5,80203fd0 <sys_exec+0xe2>
    80203f10:	e6a6                	sd	s1,328(sp)
    80203f12:	e2ca                	sd	s2,320(sp)
    80203f14:	fe4e                	sd	s3,312(sp)
    80203f16:	fa52                	sd	s4,304(sp)
    80203f18:	f656                	sd	s5,296(sp)
    80203f1a:	f25a                	sd	s6,288(sp)
    80203f1c:	ee5e                	sd	s7,280(sp)
    80203f1e:	ea62                	sd	s8,272(sp)
    argaddr(1, &uargv);
    80203f20:	f2840593          	addi	a1,s0,-216
    80203f24:	4505                	li	a0,1
    80203f26:	fffff097          	auipc	ra,0xfffff
    80203f2a:	480080e7          	jalr	1152(ra) # 802033a6 <argaddr>
    memset(argv, 0, sizeof(argv));
    80203f2e:	ea040a13          	addi	s4,s0,-352
    80203f32:	08000613          	li	a2,128
    80203f36:	4581                	li	a1,0
    80203f38:	8552                	mv	a0,s4
    80203f3a:	ffffc097          	auipc	ra,0xffffc
    80203f3e:	71c080e7          	jalr	1820(ra) # 80200656 <memset>

    int ret = -1;
    for (int i = 0; ; i++) {
        if (i >= MAXARG) goto out;
    80203f42:	84d2                	mv	s1,s4
    memset(argv, 0, sizeof(argv));
    80203f44:	89d2                	mv	s3,s4
    80203f46:	4901                	li	s2,0
        if (copyin(myproc()->pagetable, (char *)&uarg,
    80203f48:	f2040b13          	addi	s6,s0,-224
    80203f4c:	4aa1                	li	s5,8
                   uargv + sizeof(uint64) * i, sizeof(uint64)) < 0) goto out;
        if (uarg == 0) { argv[i] = 0; break; }
        argv[i] = palloc();
        if (!argv[i]) goto out;
        if (fetchstr(uarg, argv[i], PGSIZE) < 0) goto out;
    80203f4e:	6b85                	lui	s7,0x1
        if (i >= MAXARG) goto out;
    80203f50:	4c41                	li	s8,16
        if (copyin(myproc()->pagetable, (char *)&uarg,
    80203f52:	ffffd097          	auipc	ra,0xffffd
    80203f56:	78c080e7          	jalr	1932(ra) # 802016de <myproc>
    80203f5a:	00391613          	slli	a2,s2,0x3
    80203f5e:	86d6                	mv	a3,s5
    80203f60:	f2843783          	ld	a5,-216(s0)
    80203f64:	963e                	add	a2,a2,a5
    80203f66:	85da                	mv	a1,s6
    80203f68:	6928                	ld	a0,80(a0)
    80203f6a:	fffff097          	auipc	ra,0xfffff
    80203f6e:	036080e7          	jalr	54(ra) # 80202fa0 <copyin>
    80203f72:	08054363          	bltz	a0,80203ff8 <sys_exec+0x10a>
        if (uarg == 0) { argv[i] = 0; break; }
    80203f76:	f2043783          	ld	a5,-224(s0)
    80203f7a:	cfb9                	beqz	a5,80203fd8 <sys_exec+0xea>
        argv[i] = palloc();
    80203f7c:	ffffd097          	auipc	ra,0xffffd
    80203f80:	0f2080e7          	jalr	242(ra) # 8020106e <palloc>
    80203f84:	85aa                	mv	a1,a0
    80203f86:	00a9b023          	sd	a0,0(s3)
        if (!argv[i]) goto out;
    80203f8a:	c92d                	beqz	a0,80203ffc <sys_exec+0x10e>
        if (fetchstr(uarg, argv[i], PGSIZE) < 0) goto out;
    80203f8c:	865e                	mv	a2,s7
    80203f8e:	f2043503          	ld	a0,-224(s0)
    80203f92:	fffff097          	auipc	ra,0xfffff
    80203f96:	436080e7          	jalr	1078(ra) # 802033c8 <fetchstr>
    80203f9a:	06054363          	bltz	a0,80204000 <sys_exec+0x112>
        if (i >= MAXARG) goto out;
    80203f9e:	0905                	addi	s2,s2,1
    80203fa0:	09a1                	addi	s3,s3,8
    80203fa2:	fb8918e3          	bne	s2,s8,80203f52 <sys_exec+0x64>
    int ret = -1;
    80203fa6:	597d                	li	s2,-1
    }
    ret = exec(path, argv);
out:
    /* Free EVERY page we allocated, on every path - the original version of
     * this function leaked argv pages on a bad pointer. Found in the audit. */
    for (int i = 0; i < MAXARG && argv[i]; i++) pfree(argv[i]);
    80203fa8:	080a0a13          	addi	s4,s4,128
    80203fac:	6088                	ld	a0,0(s1)
    80203fae:	c901                	beqz	a0,80203fbe <sys_exec+0xd0>
    80203fb0:	ffffd097          	auipc	ra,0xffffd
    80203fb4:	1ce080e7          	jalr	462(ra) # 8020117e <pfree>
    80203fb8:	04a1                	addi	s1,s1,8
    80203fba:	ff4499e3          	bne	s1,s4,80203fac <sys_exec+0xbe>
    return ret;
    80203fbe:	854a                	mv	a0,s2
    80203fc0:	64b6                	ld	s1,328(sp)
    80203fc2:	6916                	ld	s2,320(sp)
    80203fc4:	79f2                	ld	s3,312(sp)
    80203fc6:	7a52                	ld	s4,304(sp)
    80203fc8:	7ab2                	ld	s5,296(sp)
    80203fca:	7b12                	ld	s6,288(sp)
    80203fcc:	6bf2                	ld	s7,280(sp)
    80203fce:	6c52                	ld	s8,272(sp)
}
    80203fd0:	60f6                	ld	ra,344(sp)
    80203fd2:	6456                	ld	s0,336(sp)
    80203fd4:	6135                	addi	sp,sp,352
    80203fd6:	8082                	ret
        if (uarg == 0) { argv[i] = 0; break; }
    80203fd8:	0009079b          	sext.w	a5,s2
    80203fdc:	ea040593          	addi	a1,s0,-352
    80203fe0:	078e                	slli	a5,a5,0x3
    80203fe2:	97ae                	add	a5,a5,a1
    80203fe4:	0007b023          	sd	zero,0(a5)
    ret = exec(path, argv);
    80203fe8:	f3040513          	addi	a0,s0,-208
    80203fec:	00000097          	auipc	ra,0x0
    80203ff0:	320080e7          	jalr	800(ra) # 8020430c <exec>
    80203ff4:	892a                	mv	s2,a0
    80203ff6:	bf4d                	j	80203fa8 <sys_exec+0xba>
    int ret = -1;
    80203ff8:	597d                	li	s2,-1
    80203ffa:	b77d                	j	80203fa8 <sys_exec+0xba>
    80203ffc:	597d                	li	s2,-1
    80203ffe:	b76d                	j	80203fa8 <sys_exec+0xba>
    80204000:	597d                	li	s2,-1
    80204002:	b75d                	j	80203fa8 <sys_exec+0xba>

0000000080204004 <consolewrite>:
    devsw[CONSOLE].read  = consoleread;
    devsw[CONSOLE].write = consolewrite;
}

int consolewrite(uint64 src, int n)
{
    80204004:	715d                	addi	sp,sp,-80
    80204006:	e486                	sd	ra,72(sp)
    80204008:	e0a2                	sd	s0,64(sp)
    8020400a:	ec56                	sd	s5,24(sp)
    8020400c:	0880                	addi	s0,sp,80
    8020400e:	8aae                	mv	s5,a1
    for (int i = 0; i < n; i++) {
    80204010:	04b05d63          	blez	a1,8020406a <consolewrite+0x66>
    80204014:	fc26                	sd	s1,56(sp)
    80204016:	f84a                	sd	s2,48(sp)
    80204018:	f44e                	sd	s3,40(sp)
    8020401a:	f052                	sd	s4,32(sp)
    8020401c:	84aa                	mv	s1,a0
    8020401e:	00a58a33          	add	s4,a1,a0
        char c;
        /* copyin, not a direct dereference - src is a USER pointer. */
        if (copyin(myproc()->pagetable, &c, src + i, 1) < 0) return -1;
    80204022:	fbf40993          	addi	s3,s0,-65
    80204026:	4905                	li	s2,1
    80204028:	ffffd097          	auipc	ra,0xffffd
    8020402c:	6b6080e7          	jalr	1718(ra) # 802016de <myproc>
    80204030:	86ca                	mv	a3,s2
    80204032:	8626                	mv	a2,s1
    80204034:	85ce                	mv	a1,s3
    80204036:	6928                	ld	a0,80(a0)
    80204038:	fffff097          	auipc	ra,0xfffff
    8020403c:	f68080e7          	jalr	-152(ra) # 80202fa0 <copyin>
    80204040:	02054063          	bltz	a0,80204060 <consolewrite+0x5c>
        hal_console_putc(c);
    80204044:	fbf44503          	lbu	a0,-65(s0)
    80204048:	00002097          	auipc	ra,0x2
    8020404c:	154080e7          	jalr	340(ra) # 8020619c <hal_console_putc>
    for (int i = 0; i < n; i++) {
    80204050:	0485                	addi	s1,s1,1
    80204052:	fd449be3          	bne	s1,s4,80204028 <consolewrite+0x24>
    80204056:	74e2                	ld	s1,56(sp)
    80204058:	7942                	ld	s2,48(sp)
    8020405a:	79a2                	ld	s3,40(sp)
    8020405c:	7a02                	ld	s4,32(sp)
    8020405e:	a031                	j	8020406a <consolewrite+0x66>
        if (copyin(myproc()->pagetable, &c, src + i, 1) < 0) return -1;
    80204060:	5afd                	li	s5,-1
    80204062:	74e2                	ld	s1,56(sp)
    80204064:	7942                	ld	s2,48(sp)
    80204066:	79a2                	ld	s3,40(sp)
    80204068:	7a02                	ld	s4,32(sp)
    }
    return n;
}
    8020406a:	8556                	mv	a0,s5
    8020406c:	60a6                	ld	ra,72(sp)
    8020406e:	6406                	ld	s0,64(sp)
    80204070:	6ae2                	ld	s5,24(sp)
    80204072:	6161                	addi	sp,sp,80
    80204074:	8082                	ret

0000000080204076 <consoleread>:

int consoleread(uint64 dst, int n)
{
    80204076:	715d                	addi	sp,sp,-80
    80204078:	e486                	sd	ra,72(sp)
    8020407a:	e0a2                	sd	s0,64(sp)
    8020407c:	fc26                	sd	s1,56(sp)
    8020407e:	f84a                	sd	s2,48(sp)
    80204080:	f44e                	sd	s3,40(sp)
    80204082:	f052                	sd	s4,32(sp)
    80204084:	ec56                	sd	s5,24(sp)
    80204086:	0880                	addi	s0,sp,80
    80204088:	8a2a                	mv	s4,a0
    8020408a:	89ae                	mv	s3,a1
    int target = n;
    acquire(&cons.lock);
    8020408c:	0012d517          	auipc	a0,0x12d
    80204090:	98c50513          	addi	a0,a0,-1652 # 80330a18 <cons>
    80204094:	ffffd097          	auipc	ra,0xffffd
    80204098:	26c080e7          	jalr	620(ra) # 80201300 <acquire>
    while (n > 0) {
    8020409c:	8ace                	mv	s5,s3
        while (cons.r == cons.w) {
    8020409e:	0012d497          	auipc	s1,0x12d
    802040a2:	97a48493          	addi	s1,s1,-1670 # 80330a18 <cons>
            if (myproc()->killed) { release(&cons.lock); return -1; }
            sleep(&cons.r, &cons.lock);
    802040a6:	0012d917          	auipc	s2,0x12d
    802040aa:	a0a90913          	addi	s2,s2,-1526 # 80330ab0 <cons+0x98>
    while (n > 0) {
    802040ae:	09305463          	blez	s3,80204136 <consoleread+0xc0>
        while (cons.r == cons.w) {
    802040b2:	0984a783          	lw	a5,152(s1)
    802040b6:	09c4a703          	lw	a4,156(s1)
    802040ba:	02f71463          	bne	a4,a5,802040e2 <consoleread+0x6c>
            if (myproc()->killed) { release(&cons.lock); return -1; }
    802040be:	ffffd097          	auipc	ra,0xffffd
    802040c2:	620080e7          	jalr	1568(ra) # 802016de <myproc>
    802040c6:	551c                	lw	a5,40(a0)
    802040c8:	e3d1                	bnez	a5,8020414c <consoleread+0xd6>
            sleep(&cons.r, &cons.lock);
    802040ca:	85a6                	mv	a1,s1
    802040cc:	854a                	mv	a0,s2
    802040ce:	ffffe097          	auipc	ra,0xffffe
    802040d2:	c82080e7          	jalr	-894(ra) # 80201d50 <sleep>
        while (cons.r == cons.w) {
    802040d6:	0984a783          	lw	a5,152(s1)
    802040da:	09c4a703          	lw	a4,156(s1)
    802040de:	fef700e3          	beq	a4,a5,802040be <consoleread+0x48>
        }
        char c = cons.buf[cons.r++ % INBUF];
    802040e2:	0012d717          	auipc	a4,0x12d
    802040e6:	93670713          	addi	a4,a4,-1738 # 80330a18 <cons>
    802040ea:	0017869b          	addiw	a3,a5,1
    802040ee:	08d72c23          	sw	a3,152(a4)
    802040f2:	07f7f793          	andi	a5,a5,127
    802040f6:	973e                	add	a4,a4,a5
    802040f8:	01874783          	lbu	a5,24(a4)
    802040fc:	faf40fa3          	sb	a5,-65(s0)
        if (c == 4) break;                       /* Ctrl-D */
    80204100:	4711                	li	a4,4
    80204102:	02e78a63          	beq	a5,a4,80204136 <consoleread+0xc0>
        if (copyout(myproc()->pagetable, dst, &c, 1) < 0) break;
    80204106:	ffffd097          	auipc	ra,0xffffd
    8020410a:	5d8080e7          	jalr	1496(ra) # 802016de <myproc>
    8020410e:	4685                	li	a3,1
    80204110:	fbf40613          	addi	a2,s0,-65
    80204114:	85d2                	mv	a1,s4
    80204116:	6928                	ld	a0,80(a0)
    80204118:	fffff097          	auipc	ra,0xfffff
    8020411c:	dc6080e7          	jalr	-570(ra) # 80202ede <copyout>
    80204120:	00054b63          	bltz	a0,80204136 <consoleread+0xc0>
        dst++; n--;
    80204124:	0a05                	addi	s4,s4,1
    80204126:	3afd                	addiw	s5,s5,-1
        if (c == '\n') break;
    80204128:	fbf44703          	lbu	a4,-65(s0)
    8020412c:	47a9                	li	a5,10
    8020412e:	00f70463          	beq	a4,a5,80204136 <consoleread+0xc0>
    while (n > 0) {
    80204132:	f80a90e3          	bnez	s5,802040b2 <consoleread+0x3c>
    }
    release(&cons.lock);
    80204136:	0012d517          	auipc	a0,0x12d
    8020413a:	8e250513          	addi	a0,a0,-1822 # 80330a18 <cons>
    8020413e:	ffffd097          	auipc	ra,0xffffd
    80204142:	272080e7          	jalr	626(ra) # 802013b0 <release>
    return target - n;
    80204146:	4159853b          	subw	a0,s3,s5
    8020414a:	a811                	j	8020415e <consoleread+0xe8>
            if (myproc()->killed) { release(&cons.lock); return -1; }
    8020414c:	0012d517          	auipc	a0,0x12d
    80204150:	8cc50513          	addi	a0,a0,-1844 # 80330a18 <cons>
    80204154:	ffffd097          	auipc	ra,0xffffd
    80204158:	25c080e7          	jalr	604(ra) # 802013b0 <release>
    8020415c:	557d                	li	a0,-1
}
    8020415e:	60a6                	ld	ra,72(sp)
    80204160:	6406                	ld	s0,64(sp)
    80204162:	74e2                	ld	s1,56(sp)
    80204164:	7942                	ld	s2,48(sp)
    80204166:	79a2                	ld	s3,40(sp)
    80204168:	7a02                	ld	s4,32(sp)
    8020416a:	6ae2                	ld	s5,24(sp)
    8020416c:	6161                	addi	sp,sp,80
    8020416e:	8082                	ret

0000000080204170 <consoleinit>:
{
    80204170:	1141                	addi	sp,sp,-16
    80204172:	e406                	sd	ra,8(sp)
    80204174:	e022                	sd	s0,0(sp)
    80204176:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80204178:	00003597          	auipc	a1,0x3
    8020417c:	7f858593          	addi	a1,a1,2040 # 80207970 <etext+0x970>
    80204180:	0012d517          	auipc	a0,0x12d
    80204184:	89850513          	addi	a0,a0,-1896 # 80330a18 <cons>
    80204188:	ffffd097          	auipc	ra,0xffffd
    8020418c:	0f8080e7          	jalr	248(ra) # 80201280 <initlock>
    devsw[CONSOLE].read  = consoleread;
    80204190:	00137797          	auipc	a5,0x137
    80204194:	ac078793          	addi	a5,a5,-1344 # 8033ac50 <devsw>
    80204198:	00000717          	auipc	a4,0x0
    8020419c:	ede70713          	addi	a4,a4,-290 # 80204076 <consoleread>
    802041a0:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    802041a2:	00000717          	auipc	a4,0x0
    802041a6:	e6270713          	addi	a4,a4,-414 # 80204004 <consolewrite>
    802041aa:	ef98                	sd	a4,24(a5)
}
    802041ac:	60a2                	ld	ra,8(sp)
    802041ae:	6402                	ld	s0,0(sp)
    802041b0:	0141                	addi	sp,sp,16
    802041b2:	8082                	ret

00000000802041b4 <consoleintr>:

/* Called from the trap handler when the UART raises an interrupt. */
void consoleintr(int c)
{
    802041b4:	1101                	addi	sp,sp,-32
    802041b6:	ec06                	sd	ra,24(sp)
    802041b8:	e822                	sd	s0,16(sp)
    802041ba:	e426                	sd	s1,8(sp)
    802041bc:	1000                	addi	s0,sp,32
    802041be:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    802041c0:	0012d517          	auipc	a0,0x12d
    802041c4:	85850513          	addi	a0,a0,-1960 # 80330a18 <cons>
    802041c8:	ffffd097          	auipc	ra,0xffffd
    802041cc:	138080e7          	jalr	312(ra) # 80201300 <acquire>
    switch (c) {
    802041d0:	47c1                	li	a5,16
    802041d2:	08f48363          	beq	s1,a5,80204258 <consoleintr+0xa4>
    802041d6:	07f00793          	li	a5,127
    802041da:	0af48063          	beq	s1,a5,8020427a <consoleintr+0xc6>
    802041de:	47a1                	li	a5,8
    802041e0:	08f48d63          	beq	s1,a5,8020427a <consoleintr+0xc6>
            cons.e--;
            hal_console_putc('\b'); hal_console_putc(' '); hal_console_putc('\b');
        }
        break;
    default:
        if (c != 0 && cons.e - cons.r < INBUF) {
    802041e4:	ccb5                	beqz	s1,80204260 <consoleintr+0xac>
    802041e6:	0012d717          	auipc	a4,0x12d
    802041ea:	83270713          	addi	a4,a4,-1998 # 80330a18 <cons>
    802041ee:	0a072783          	lw	a5,160(a4)
    802041f2:	09872703          	lw	a4,152(a4)
    802041f6:	9f99                	subw	a5,a5,a4
    802041f8:	07f00713          	li	a4,127
    802041fc:	06f76263          	bltu	a4,a5,80204260 <consoleintr+0xac>
            c = (c == '\r') ? '\n' : c;
    80204200:	47b5                	li	a5,13
    80204202:	0cf48e63          	beq	s1,a5,802042de <consoleintr+0x12a>
    80204206:	e04a                	sd	s2,0(sp)
            hal_console_putc(c);                 /* echo */
    80204208:	0ff4f913          	zext.b	s2,s1
    8020420c:	854a                	mv	a0,s2
    8020420e:	00002097          	auipc	ra,0x2
    80204212:	f8e080e7          	jalr	-114(ra) # 8020619c <hal_console_putc>
            cons.buf[cons.e++ % INBUF] = c;
    80204216:	0012d797          	auipc	a5,0x12d
    8020421a:	80278793          	addi	a5,a5,-2046 # 80330a18 <cons>
    8020421e:	0a07a703          	lw	a4,160(a5)
    80204222:	0017069b          	addiw	a3,a4,1
    80204226:	8636                	mv	a2,a3
    80204228:	0ad7a023          	sw	a3,160(a5)
    8020422c:	07f77713          	andi	a4,a4,127
    80204230:	97ba                	add	a5,a5,a4
    80204232:	01278c23          	sb	s2,24(a5)
            if (c == '\n' || c == 4 || cons.e - cons.r == INBUF) {
    80204236:	47a9                	li	a5,10
    80204238:	08f48363          	beq	s1,a5,802042be <consoleintr+0x10a>
    8020423c:	4791                	li	a5,4
    8020423e:	08f48263          	beq	s1,a5,802042c2 <consoleintr+0x10e>
    80204242:	0012d797          	auipc	a5,0x12d
    80204246:	86e7a783          	lw	a5,-1938(a5) # 80330ab0 <cons+0x98>
    8020424a:	9e9d                	subw	a3,a3,a5
    8020424c:	08000793          	li	a5,128
    80204250:	06f68563          	beq	a3,a5,802042ba <consoleintr+0x106>
    80204254:	6902                	ld	s2,0(sp)
    80204256:	a029                	j	80204260 <consoleintr+0xac>
        procdump();
    80204258:	ffffe097          	auipc	ra,0xffffe
    8020425c:	f2a080e7          	jalr	-214(ra) # 80202182 <procdump>
                wakeup(&cons.r);
            }
        }
        break;
    }
    release(&cons.lock);
    80204260:	0012c517          	auipc	a0,0x12c
    80204264:	7b850513          	addi	a0,a0,1976 # 80330a18 <cons>
    80204268:	ffffd097          	auipc	ra,0xffffd
    8020426c:	148080e7          	jalr	328(ra) # 802013b0 <release>
}
    80204270:	60e2                	ld	ra,24(sp)
    80204272:	6442                	ld	s0,16(sp)
    80204274:	64a2                	ld	s1,8(sp)
    80204276:	6105                	addi	sp,sp,32
    80204278:	8082                	ret
        if (cons.e != cons.w) {
    8020427a:	0012c717          	auipc	a4,0x12c
    8020427e:	79e70713          	addi	a4,a4,1950 # 80330a18 <cons>
    80204282:	0a072783          	lw	a5,160(a4)
    80204286:	09c72703          	lw	a4,156(a4)
    8020428a:	fcf70be3          	beq	a4,a5,80204260 <consoleintr+0xac>
            cons.e--;
    8020428e:	37fd                	addiw	a5,a5,-1
    80204290:	0012d717          	auipc	a4,0x12d
    80204294:	82f72423          	sw	a5,-2008(a4) # 80330ab8 <cons+0xa0>
            hal_console_putc('\b'); hal_console_putc(' '); hal_console_putc('\b');
    80204298:	4521                	li	a0,8
    8020429a:	00002097          	auipc	ra,0x2
    8020429e:	f02080e7          	jalr	-254(ra) # 8020619c <hal_console_putc>
    802042a2:	02000513          	li	a0,32
    802042a6:	00002097          	auipc	ra,0x2
    802042aa:	ef6080e7          	jalr	-266(ra) # 8020619c <hal_console_putc>
    802042ae:	4521                	li	a0,8
    802042b0:	00002097          	auipc	ra,0x2
    802042b4:	eec080e7          	jalr	-276(ra) # 8020619c <hal_console_putc>
    802042b8:	b765                	j	80204260 <consoleintr+0xac>
    802042ba:	6902                	ld	s2,0(sp)
    802042bc:	a021                	j	802042c4 <consoleintr+0x110>
    802042be:	6902                	ld	s2,0(sp)
    802042c0:	a011                	j	802042c4 <consoleintr+0x110>
    802042c2:	6902                	ld	s2,0(sp)
                cons.w = cons.e;
    802042c4:	0012c797          	auipc	a5,0x12c
    802042c8:	7ec7a823          	sw	a2,2032(a5) # 80330ab4 <cons+0x9c>
                wakeup(&cons.r);
    802042cc:	0012c517          	auipc	a0,0x12c
    802042d0:	7e450513          	addi	a0,a0,2020 # 80330ab0 <cons+0x98>
    802042d4:	ffffe097          	auipc	ra,0xffffe
    802042d8:	bfc080e7          	jalr	-1028(ra) # 80201ed0 <wakeup>
    802042dc:	b751                	j	80204260 <consoleintr+0xac>
            hal_console_putc(c);                 /* echo */
    802042de:	4529                	li	a0,10
    802042e0:	00002097          	auipc	ra,0x2
    802042e4:	ebc080e7          	jalr	-324(ra) # 8020619c <hal_console_putc>
            cons.buf[cons.e++ % INBUF] = c;
    802042e8:	0012c797          	auipc	a5,0x12c
    802042ec:	73078793          	addi	a5,a5,1840 # 80330a18 <cons>
    802042f0:	0a07a703          	lw	a4,160(a5)
    802042f4:	0017069b          	addiw	a3,a4,1
    802042f8:	8636                	mv	a2,a3
    802042fa:	0ad7a023          	sw	a3,160(a5)
    802042fe:	07f77713          	andi	a4,a4,127
    80204302:	97ba                	add	a5,a5,a4
    80204304:	4729                	li	a4,10
    80204306:	00e78c23          	sb	a4,24(a5)
            if (c == '\n' || c == 4 || cons.e - cons.r == INBUF) {
    8020430a:	bf6d                	j	802042c4 <consoleintr+0x110>

000000008020430c <exec>:
    }
    return 0;
}

int exec(char *path, char **argv)
{
    8020430c:	7125                	addi	sp,sp,-416
    8020430e:	ef06                	sd	ra,408(sp)
    80204310:	eb22                	sd	s0,400(sp)
    80204312:	e726                	sd	s1,392(sp)
    80204314:	1300                	addi	s0,sp,416
    80204316:	e6a43c23          	sd	a0,-392(s0)
    8020431a:	e8b43423          	sd	a1,-376(s0)
    struct inode *ip = namei(path);
    8020431e:	00001097          	auipc	ra,0x1
    80204322:	50e080e7          	jalr	1294(ra) # 8020582c <namei>
    if (ip == 0) return -1;
    80204326:	3c050a63          	beqz	a0,802046fa <exec+0x3ee>
    8020432a:	f2da                	sd	s6,352(sp)
    8020432c:	8b2a                	mv	s6,a0
    ilock(ip);
    8020432e:	00001097          	auipc	ra,0x1
    80204332:	c5c080e7          	jalr	-932(ra) # 80204f8a <ilock>

    struct elfhdr eh;
    pagetable_t newpt = 0;
    uint64 sz = 0;

    if (readi(ip, 0, (uint64)&eh, 0, sizeof(eh)) != sizeof(eh)) goto bad;
    80204336:	04000713          	li	a4,64
    8020433a:	4681                	li	a3,0
    8020433c:	f5040613          	addi	a2,s0,-176
    80204340:	4581                	li	a1,0
    80204342:	855a                	mv	a0,s6
    80204344:	00001097          	auipc	ra,0x1
    80204348:	f76080e7          	jalr	-138(ra) # 802052ba <readi>
    8020434c:	04000793          	li	a5,64
    80204350:	02f51263          	bne	a0,a5,80204374 <exec+0x68>
    if (eh.magic != ELF_MAGIC) goto bad;              /* reject, do not run */
    80204354:	f5042703          	lw	a4,-176(s0)
    80204358:	464c47b7          	lui	a5,0x464c4
    8020435c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39d3ba81>
    80204360:	00f71a63          	bne	a4,a5,80204374 <exec+0x68>
    if (eh.phnum == 0 || eh.phnum > 16) goto bad;
    80204364:	f8845783          	lhu	a5,-120(s0)
    80204368:	37fd                	addiw	a5,a5,-1
    8020436a:	17c2                	slli	a5,a5,0x30
    8020436c:	93c1                	srli	a5,a5,0x30
    8020436e:	473d                	li	a4,15
    80204370:	00f77f63          	bgeu	a4,a5,8020438e <exec+0x82>
    uvmfree(oldpt, oldsz);
    return argc;

bad:
    if (newpt) uvmfree(newpt, sz);
    if (ip) iunlockput(ip);
    80204374:	855a                	mv	a0,s6
    80204376:	00001097          	auipc	ra,0x1
    8020437a:	eee080e7          	jalr	-274(ra) # 80205264 <iunlockput>
    return -1;
    8020437e:	54fd                	li	s1,-1
    80204380:	7b16                	ld	s6,352(sp)
}
    80204382:	8526                	mv	a0,s1
    80204384:	60fa                	ld	ra,408(sp)
    80204386:	645a                	ld	s0,400(sp)
    80204388:	64ba                	ld	s1,392(sp)
    8020438a:	611d                	addi	sp,sp,416
    8020438c:	8082                	ret
    8020438e:	eae2                	sd	s8,336(sp)
    if ((newpt = uvmcreate()) == 0) goto bad;
    80204390:	fffff097          	auipc	ra,0xfffff
    80204394:	982080e7          	jalr	-1662(ra) # 80202d12 <uvmcreate>
    80204398:	8c2a                	mv	s8,a0
    8020439a:	34050e63          	beqz	a0,802046f6 <exec+0x3ea>
    8020439e:	e34a                	sd	s2,384(sp)
    802043a0:	fece                	sd	s3,376(sp)
    802043a2:	fad2                	sd	s4,368(sp)
    802043a4:	f6d6                	sd	s5,360(sp)
    802043a6:	eede                	sd	s7,344(sp)
    802043a8:	e6e6                	sd	s9,328(sp)
    802043aa:	e2ea                	sd	s10,320(sp)
    for (int i = 0; i < eh.phnum; i++) {
    802043ac:	f8845783          	lhu	a5,-120(s0)
    802043b0:	24078363          	beqz	a5,802045f6 <exec+0x2ea>
    802043b4:	fe6e                	sd	s11,312(sp)
    802043b6:	4c81                	li	s9,0
    802043b8:	4d01                	li	s10,0
    uint64 sz = 0;
    802043ba:	e8043023          	sd	zero,-384(s0)
        if (readi(ip, 0, (uint64)&ph, eh.phoff + i * sizeof(ph),
    802043be:	03800d93          	li	s11,56
        if (ph.vaddr + ph.memsz >= 0x80000000UL) goto bad;  /* into kernel! */
    802043c2:	800007b7          	lui	a5,0x80000
    802043c6:	fff7c793          	not	a5,a5
    802043ca:	e6f43823          	sd	a5,-400(s0)
    uint64 end   = PGROUNDUP(ph->vaddr + ph->memsz);
    802043ce:	6a05                	lui	s4,0x1
    802043d0:	fffa0793          	addi	a5,s4,-1 # fff <_entry-0x801ff001>
    802043d4:	e6f43423          	sd	a5,-408(s0)
    802043d8:	a0cd                	j	802044ba <exec+0x1ae>
        uint64 dst_off = (va < ph->vaddr) ? (ph->vaddr - va) : 0;
    802043da:	00c4f563          	bgeu	s1,a2,802043e4 <exec+0xd8>
    802043de:	8e05                	sub	a2,a2,s1
    802043e0:	4781                	li	a5,0
    802043e2:	a095                	j	80204446 <exec+0x13a>
    802043e4:	4781                	li	a5,0
    802043e6:	4601                	li	a2,0
    802043e8:	a8b9                	j	80204446 <exec+0x13a>
            if (readi(ip, 0, (uint64)(mem + dst_off),
    802043ea:	2981                	sext.w	s3,s3
    802043ec:	874e                	mv	a4,s3
    802043ee:	e9843683          	ld	a3,-360(s0)
    802043f2:	9ebd                	addw	a3,a3,a5
    802043f4:	964a                	add	a2,a2,s2
    802043f6:	4581                	li	a1,0
    802043f8:	855a                	mv	a0,s6
    802043fa:	00001097          	auipc	ra,0x1
    802043fe:	ec0080e7          	jalr	-320(ra) # 802052ba <readi>
    80204402:	05351e63          	bne	a0,s3,8020445e <exec+0x152>
        if (mappages(pt, va, PGSIZE, (uint64)mem, perm) != 0) {
    80204406:	875e                	mv	a4,s7
    80204408:	86ca                	mv	a3,s2
    8020440a:	8652                	mv	a2,s4
    8020440c:	85a6                	mv	a1,s1
    8020440e:	8562                	mv	a0,s8
    80204410:	ffffe097          	auipc	ra,0xffffe
    80204414:	6d8080e7          	jalr	1752(ra) # 80202ae8 <mappages>
    80204418:	e929                	bnez	a0,8020446a <exec+0x15e>
    for (uint64 va = start; va < end; va += PGSIZE) {
    8020441a:	94d2                	add	s1,s1,s4
    8020441c:	0754fd63          	bgeu	s1,s5,80204496 <exec+0x18a>
        char *mem = palloc();
    80204420:	ffffd097          	auipc	ra,0xffffd
    80204424:	c4e080e7          	jalr	-946(ra) # 8020106e <palloc>
    80204428:	892a                	mv	s2,a0
        if (!mem) return -1;
    8020442a:	c529                	beqz	a0,80204474 <exec+0x168>
        memset(mem, 0, PGSIZE);                    /* zero first: this IS the .bss */
    8020442c:	8652                	mv	a2,s4
    8020442e:	4581                	li	a1,0
    80204430:	ffffc097          	auipc	ra,0xffffc
    80204434:	226080e7          	jalr	550(ra) # 80200656 <memset>
        uint64 seg_off = (va > ph->vaddr) ? (va - ph->vaddr) : 0;
    80204438:	ea043603          	ld	a2,-352(s0)
    8020443c:	f8967fe3          	bgeu	a2,s1,802043da <exec+0xce>
    80204440:	40c487b3          	sub	a5,s1,a2
        uint64 dst_off = (va < ph->vaddr) ? (ph->vaddr - va) : 0;
    80204444:	4601                	li	a2,0
        if (seg_off < ph->filesz) {
    80204446:	eb043983          	ld	s3,-336(s0)
    8020444a:	fb37fee3          	bgeu	a5,s3,80204406 <exec+0xfa>
            if (n > PGSIZE - dst_off) n = PGSIZE - dst_off;
    8020444e:	40ca0733          	sub	a4,s4,a2
    80204452:	40f989b3          	sub	s3,s3,a5
    80204456:	f9377ae3          	bgeu	a4,s3,802043ea <exec+0xde>
    8020445a:	89ba                	mv	s3,a4
    8020445c:	b779                	j	802043ea <exec+0xde>
                pfree(mem);
    8020445e:	854a                	mv	a0,s2
    80204460:	ffffd097          	auipc	ra,0xffffd
    80204464:	d1e080e7          	jalr	-738(ra) # 8020117e <pfree>
                return -1;
    80204468:	a031                	j	80204474 <exec+0x168>
            pfree(mem);
    8020446a:	854a                	mv	a0,s2
    8020446c:	ffffd097          	auipc	ra,0xffffd
    80204470:	d12080e7          	jalr	-750(ra) # 8020117e <pfree>
    if (newpt) uvmfree(newpt, sz);
    80204474:	e8043583          	ld	a1,-384(s0)
    80204478:	8562                	mv	a0,s8
    8020447a:	fffff097          	auipc	ra,0xfffff
    8020447e:	958080e7          	jalr	-1704(ra) # 80202dd2 <uvmfree>
    if (ip) iunlockput(ip);
    80204482:	691a                	ld	s2,384(sp)
    80204484:	79f6                	ld	s3,376(sp)
    80204486:	7a56                	ld	s4,368(sp)
    80204488:	7ab6                	ld	s5,360(sp)
    8020448a:	6bf6                	ld	s7,344(sp)
    8020448c:	6c56                	ld	s8,336(sp)
    8020448e:	6cb6                	ld	s9,328(sp)
    80204490:	6d16                	ld	s10,320(sp)
    80204492:	7df2                	ld	s11,312(sp)
    80204494:	b5c5                	j	80204374 <exec+0x68>
        if (ph.vaddr + ph.memsz > sz) sz = ph.vaddr + ph.memsz;
    80204496:	ea043783          	ld	a5,-352(s0)
    8020449a:	eb843703          	ld	a4,-328(s0)
    8020449e:	97ba                	add	a5,a5,a4
    802044a0:	e8043703          	ld	a4,-384(s0)
    802044a4:	00f77463          	bgeu	a4,a5,802044ac <exec+0x1a0>
    802044a8:	e8f43023          	sd	a5,-384(s0)
    for (int i = 0; i < eh.phnum; i++) {
    802044ac:	2d05                	addiw	s10,s10,1
    802044ae:	038c8c9b          	addiw	s9,s9,56 # fffffffffffff038 <uart+0xffffffff7fcc0008>
    802044b2:	f8845783          	lhu	a5,-120(s0)
    802044b6:	08fd5063          	bge	s10,a5,80204536 <exec+0x22a>
        if (readi(ip, 0, (uint64)&ph, eh.phoff + i * sizeof(ph),
    802044ba:	876e                	mv	a4,s11
    802044bc:	f7043683          	ld	a3,-144(s0)
    802044c0:	019686bb          	addw	a3,a3,s9
    802044c4:	e9040613          	addi	a2,s0,-368
    802044c8:	4581                	li	a1,0
    802044ca:	855a                	mv	a0,s6
    802044cc:	00001097          	auipc	ra,0x1
    802044d0:	dee080e7          	jalr	-530(ra) # 802052ba <readi>
    802044d4:	fbb510e3          	bne	a0,s11,80204474 <exec+0x168>
        if (ph.type != ELF_PROG_LOAD) continue;
    802044d8:	e9042783          	lw	a5,-368(s0)
    802044dc:	4705                	li	a4,1
    802044de:	fce797e3          	bne	a5,a4,802044ac <exec+0x1a0>
        if (ph.memsz < ph.filesz) goto bad;           /* malformed */
    802044e2:	eb843a83          	ld	s5,-328(s0)
    802044e6:	eb043783          	ld	a5,-336(s0)
    802044ea:	f8fae5e3          	bltu	s5,a5,80204474 <exec+0x168>
        if (ph.vaddr + ph.memsz < ph.vaddr) goto bad; /* overflow  */
    802044ee:	ea043483          	ld	s1,-352(s0)
    802044f2:	9aa6                	add	s5,s5,s1
    802044f4:	f89ae0e3          	bltu	s5,s1,80204474 <exec+0x168>
        if (ph.vaddr + ph.memsz >= 0x80000000UL) goto bad;  /* into kernel! */
    802044f8:	e7043783          	ld	a5,-400(s0)
    802044fc:	f757ece3          	bltu	a5,s5,80204474 <exec+0x168>
    if (ph->flags & ELF_PROG_FLAG_READ)  perm |= PTE_R;
    80204500:	e9442783          	lw	a5,-364(s0)
    80204504:	0047f713          	andi	a4,a5,4
    80204508:	4bc9                	li	s7,18
    8020450a:	e311                	bnez	a4,8020450e <exec+0x202>
    int perm = PTE_U;
    8020450c:	4bc1                	li	s7,16
    if (ph->flags & ELF_PROG_FLAG_WRITE) perm |= PTE_W;
    8020450e:	0027f713          	andi	a4,a5,2
    80204512:	c319                	beqz	a4,80204518 <exec+0x20c>
    80204514:	004beb93          	ori	s7,s7,4
    if (ph->flags & ELF_PROG_FLAG_EXEC)  perm |= PTE_X;
    80204518:	8b85                	andi	a5,a5,1
    8020451a:	0037979b          	slliw	a5,a5,0x3
    8020451e:	00fbebb3          	or	s7,s7,a5
    uint64 start = PGROUNDDOWN(ph->vaddr);
    80204522:	77fd                	lui	a5,0xfffff
    80204524:	8cfd                	and	s1,s1,a5
    uint64 end   = PGROUNDUP(ph->vaddr + ph->memsz);
    80204526:	e6843703          	ld	a4,-408(s0)
    8020452a:	9aba                	add	s5,s5,a4
    8020452c:	00fafab3          	and	s5,s5,a5
    for (uint64 va = start; va < end; va += PGSIZE) {
    80204530:	ef54e8e3          	bltu	s1,s5,80204420 <exec+0x114>
    80204534:	b78d                	j	80204496 <exec+0x18a>
    80204536:	7df2                	ld	s11,312(sp)
    iunlockput(ip);
    80204538:	855a                	mv	a0,s6
    8020453a:	00001097          	auipc	ra,0x1
    8020453e:	d2a080e7          	jalr	-726(ra) # 80205264 <iunlockput>
    sz = PGROUNDUP(sz);
    80204542:	6785                	lui	a5,0x1
    80204544:	17fd                	addi	a5,a5,-1 # fff <_entry-0x801ff001>
    80204546:	e8043703          	ld	a4,-384(s0)
    8020454a:	00f70933          	add	s2,a4,a5
    8020454e:	77fd                	lui	a5,0xfffff
    80204550:	00f97933          	and	s2,s2,a5
    char *stack = palloc();
    80204554:	ffffd097          	auipc	ra,0xffffd
    80204558:	b1a080e7          	jalr	-1254(ra) # 8020106e <palloc>
    8020455c:	89aa                	mv	s3,a0
    if (!stack) goto bad;
    8020455e:	c545                	beqz	a0,80204606 <exec+0x2fa>
    uint64 stackbase = guard + PGSIZE;
    80204560:	6485                	lui	s1,0x1
    80204562:	00990a33          	add	s4,s2,s1
    memset(stack, 0, PGSIZE);
    80204566:	8626                	mv	a2,s1
    80204568:	4581                	li	a1,0
    8020456a:	ffffc097          	auipc	ra,0xffffc
    8020456e:	0ec080e7          	jalr	236(ra) # 80200656 <memset>
    if (mappages(newpt, stackbase, PGSIZE, (uint64)stack,
    80204572:	4759                	li	a4,22
    80204574:	86ce                	mv	a3,s3
    80204576:	8626                	mv	a2,s1
    80204578:	85d2                	mv	a1,s4
    8020457a:	8562                	mv	a0,s8
    8020457c:	ffffe097          	auipc	ra,0xffffe
    80204580:	56c080e7          	jalr	1388(ra) # 80202ae8 <mappages>
    80204584:	84aa                	mv	s1,a0
    80204586:	e93d                	bnez	a0,802045fc <exec+0x2f0>
    uint64 sp    = stackbase + PGSIZE;
    80204588:	6b09                	lui	s6,0x2
    8020458a:	9b4a                	add	s6,s6,s2
    struct proc *pp = myproc();
    8020458c:	ffffd097          	auipc	ra,0xffffd
    80204590:	152080e7          	jalr	338(ra) # 802016de <myproc>
    80204594:	8aaa                	mv	s5,a0
    for (; argv && argv[argc]; argc++) {
    80204596:	e8843783          	ld	a5,-376(s0)
    8020459a:	c7d9                	beqz	a5,80204628 <exec+0x31c>
    8020459c:	6388                	ld	a0,0(a5)
    8020459e:	cd75                	beqz	a0,8020469a <exec+0x38e>
    802045a0:	ec840b93          	addi	s7,s0,-312
    802045a4:	f4840c93          	addi	s9,s0,-184
    uint64 sp    = stackbase + PGSIZE;
    802045a8:	89da                	mv	s3,s6
        uint64 len = strlen(argv[argc]) + 1;
    802045aa:	ffffc097          	auipc	ra,0xffffc
    802045ae:	1be080e7          	jalr	446(ra) # 80200768 <strlen>
    802045b2:	0015069b          	addiw	a3,a0,1
        sp -= len;
    802045b6:	40d989b3          	sub	s3,s3,a3
        sp &= ~7UL;                                   /* keep it 8-aligned */
    802045ba:	ff89f993          	andi	s3,s3,-8
        if (sp < stackbase) goto bad;
    802045be:	0549e463          	bltu	s3,s4,80204606 <exec+0x2fa>
        if (copyout(newpt, sp, argv[argc], len) < 0) goto bad;
    802045c2:	e8843d03          	ld	s10,-376(s0)
    802045c6:	000d3603          	ld	a2,0(s10)
    802045ca:	85ce                	mv	a1,s3
    802045cc:	8562                	mv	a0,s8
    802045ce:	fffff097          	auipc	ra,0xfffff
    802045d2:	910080e7          	jalr	-1776(ra) # 80202ede <copyout>
    802045d6:	02054863          	bltz	a0,80204606 <exec+0x2fa>
        ustack[argc] = sp;
    802045da:	013bb023          	sd	s3,0(s7) # 1000 <_entry-0x801ff000>
    for (; argv && argv[argc]; argc++) {
    802045de:	2485                	addiw	s1,s1,1 # 1001 <_entry-0x801fefff>
    802045e0:	008d0793          	addi	a5,s10,8
    802045e4:	e8f43423          	sd	a5,-376(s0)
    802045e8:	008d3503          	ld	a0,8(s10)
    802045ec:	cd1d                	beqz	a0,8020462a <exec+0x31e>
        if (argc >= MAXARG) goto bad;
    802045ee:	0ba1                	addi	s7,s7,8
    802045f0:	fb7c9de3          	bne	s9,s7,802045aa <exec+0x29e>
    802045f4:	a809                	j	80204606 <exec+0x2fa>
    uint64 sz = 0;
    802045f6:	e8043023          	sd	zero,-384(s0)
    802045fa:	bf3d                	j	80204538 <exec+0x22c>
                 PTE_R | PTE_W | PTE_U) != 0) { pfree(stack); goto bad; }
    802045fc:	854e                	mv	a0,s3
    802045fe:	ffffd097          	auipc	ra,0xffffd
    80204602:	b80080e7          	jalr	-1152(ra) # 8020117e <pfree>
    if (newpt) uvmfree(newpt, sz);
    80204606:	85ca                	mv	a1,s2
    80204608:	8562                	mv	a0,s8
    8020460a:	ffffe097          	auipc	ra,0xffffe
    8020460e:	7c8080e7          	jalr	1992(ra) # 80202dd2 <uvmfree>
    return -1;
    80204612:	54fd                	li	s1,-1
    80204614:	691a                	ld	s2,384(sp)
    80204616:	79f6                	ld	s3,376(sp)
    80204618:	7a56                	ld	s4,368(sp)
    8020461a:	7ab6                	ld	s5,360(sp)
    8020461c:	7b16                	ld	s6,352(sp)
    8020461e:	6bf6                	ld	s7,344(sp)
    80204620:	6c56                	ld	s8,336(sp)
    80204622:	6cb6                	ld	s9,328(sp)
    80204624:	6d16                	ld	s10,320(sp)
    80204626:	bbb1                	j	80204382 <exec+0x76>
    uint64 sp    = stackbase + PGSIZE;
    80204628:	89da                	mv	s3,s6
    ustack[argc] = 0;
    8020462a:	00349793          	slli	a5,s1,0x3
    8020462e:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <uart+0xffffffff7fcbff60>
    80204632:	97a2                	add	a5,a5,s0
    80204634:	f207bc23          	sd	zero,-200(a5)
    sp -= (argc + 1) * sizeof(uint64);
    80204638:	0014869b          	addiw	a3,s1,1
    8020463c:	068e                	slli	a3,a3,0x3
    8020463e:	40d989b3          	sub	s3,s3,a3
    sp &= ~15UL;                                      /* 16-byte ABI alignment */
    80204642:	ff09f993          	andi	s3,s3,-16
    if (sp < stackbase) goto bad;
    80204646:	fd49e0e3          	bltu	s3,s4,80204606 <exec+0x2fa>
    if (copyout(newpt, sp, (char *)ustack, (argc + 1) * sizeof(uint64)) < 0) goto bad;
    8020464a:	ec840613          	addi	a2,s0,-312
    8020464e:	85ce                	mv	a1,s3
    80204650:	8562                	mv	a0,s8
    80204652:	fffff097          	auipc	ra,0xfffff
    80204656:	88c080e7          	jalr	-1908(ra) # 80202ede <copyout>
    8020465a:	fa0546e3          	bltz	a0,80204606 <exec+0x2fa>
    pagetable_t oldpt = pp->pagetable;
    8020465e:	050ab903          	ld	s2,80(s5)
    uint64      oldsz = pp->sz;
    80204662:	048aba03          	ld	s4,72(s5)
    pp->pagetable = newpt;
    80204666:	058ab823          	sd	s8,80(s5)
    pp->sz        = newsz;
    8020466a:	056ab423          	sd	s6,72(s5)
    pp->tf->epc   = eh.entry;
    8020466e:	058ab783          	ld	a5,88(s5)
    80204672:	f6843703          	ld	a4,-152(s0)
    80204676:	ef98                	sd	a4,24(a5)
    pp->tf->sp    = sp;
    80204678:	058ab783          	ld	a5,88(s5)
    8020467c:	0337b823          	sd	s3,48(a5)
    pp->tf->a1    = sp;                               /* argv for main() */
    80204680:	058ab783          	ld	a5,88(s5)
    80204684:	0737bc23          	sd	s3,120(a5)
    for (const char *s = path; *s; s++) if (*s == '/') last = s + 1;
    80204688:	e7843783          	ld	a5,-392(s0)
    8020468c:	0007c703          	lbu	a4,0(a5)
    80204690:	c305                	beqz	a4,802046b0 <exec+0x3a4>
    80204692:	0785                	addi	a5,a5,1
    80204694:	02f00693          	li	a3,47
    80204698:	a039                	j	802046a6 <exec+0x39a>
    uint64 sp    = stackbase + PGSIZE;
    8020469a:	89da                	mv	s3,s6
    8020469c:	b779                	j	8020462a <exec+0x31e>
    for (const char *s = path; *s; s++) if (*s == '/') last = s + 1;
    8020469e:	0785                	addi	a5,a5,1
    802046a0:	fff7c703          	lbu	a4,-1(a5)
    802046a4:	c711                	beqz	a4,802046b0 <exec+0x3a4>
    802046a6:	fed71ce3          	bne	a4,a3,8020469e <exec+0x392>
    802046aa:	e6f43c23          	sd	a5,-392(s0)
    802046ae:	bfc5                	j	8020469e <exec+0x392>
    strncpy(pp->name, last, sizeof(pp->name));
    802046b0:	4641                	li	a2,16
    802046b2:	e7843583          	ld	a1,-392(s0)
    802046b6:	158a8513          	addi	a0,s5,344
    802046ba:	ffffc097          	auipc	ra,0xffffc
    802046be:	06e080e7          	jalr	110(ra) # 80200728 <strncpy>
    w_satp(MAKE_SATP(pp->pagetable));                 /* we are running on it now */
    802046c2:	050ab783          	ld	a5,80(s5)
    802046c6:	83b1                	srli	a5,a5,0xc
    802046c8:	577d                	li	a4,-1
    802046ca:	177e                	slli	a4,a4,0x3f
    802046cc:	8fd9                	or	a5,a5,a4
static inline void   w_satp(uint64 x){ asm volatile("csrw satp, %0"::"r"(x)); }
    802046ce:	18079073          	csrw	satp,a5
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }
    802046d2:	12000073          	sfence.vma
    uvmfree(oldpt, oldsz);
    802046d6:	85d2                	mv	a1,s4
    802046d8:	854a                	mv	a0,s2
    802046da:	ffffe097          	auipc	ra,0xffffe
    802046de:	6f8080e7          	jalr	1784(ra) # 80202dd2 <uvmfree>
    return argc;
    802046e2:	691a                	ld	s2,384(sp)
    802046e4:	79f6                	ld	s3,376(sp)
    802046e6:	7a56                	ld	s4,368(sp)
    802046e8:	7ab6                	ld	s5,360(sp)
    802046ea:	7b16                	ld	s6,352(sp)
    802046ec:	6bf6                	ld	s7,344(sp)
    802046ee:	6c56                	ld	s8,336(sp)
    802046f0:	6cb6                	ld	s9,328(sp)
    802046f2:	6d16                	ld	s10,320(sp)
    802046f4:	b179                	j	80204382 <exec+0x76>
    802046f6:	6c56                	ld	s8,336(sp)
    802046f8:	b9b5                	j	80204374 <exec+0x68>
    if (ip == 0) return -1;
    802046fa:	54fd                	li	s1,-1
    802046fc:	b159                	j	80204382 <exec+0x76>

00000000802046fe <binit>:
    struct buf buf[NBUF];
    struct buf head;          /* LRU list: head.next = most recent */
} bcache;

void binit(void)
{
    802046fe:	7179                	addi	sp,sp,-48
    80204700:	f406                	sd	ra,40(sp)
    80204702:	f022                	sd	s0,32(sp)
    80204704:	ec26                	sd	s1,24(sp)
    80204706:	e84a                	sd	s2,16(sp)
    80204708:	e44e                	sd	s3,8(sp)
    8020470a:	e052                	sd	s4,0(sp)
    8020470c:	1800                	addi	s0,sp,48
    initlock(&bcache.lock, "bcache");
    8020470e:	00003597          	auipc	a1,0x3
    80204712:	26a58593          	addi	a1,a1,618 # 80207978 <etext+0x978>
    80204716:	0012c517          	auipc	a0,0x12c
    8020471a:	3aa50513          	addi	a0,a0,938 # 80330ac0 <bcache>
    8020471e:	ffffd097          	auipc	ra,0xffffd
    80204722:	b62080e7          	jalr	-1182(ra) # 80201280 <initlock>
    bcache.head.prev = &bcache.head;
    80204726:	00134797          	auipc	a5,0x134
    8020472a:	39a78793          	addi	a5,a5,922 # 80338ac0 <bcache+0x8000>
    8020472e:	00134717          	auipc	a4,0x134
    80204732:	5fa70713          	addi	a4,a4,1530 # 80338d28 <bcache+0x8268>
    80204736:	2ae7b823          	sd	a4,688(a5)
    bcache.head.next = &bcache.head;
    8020473a:	2ae7bc23          	sd	a4,696(a5)
    for (struct buf *b = bcache.buf; b < bcache.buf + NBUF; b++) {
    8020473e:	0012c497          	auipc	s1,0x12c
    80204742:	39a48493          	addi	s1,s1,922 # 80330ad8 <bcache+0x18>
        b->next = bcache.head.next;
    80204746:	893e                	mv	s2,a5
        b->prev = &bcache.head;
    80204748:	89ba                	mv	s3,a4
        initsleeplock(&b->lock, "buffer");
    8020474a:	00003a17          	auipc	s4,0x3
    8020474e:	236a0a13          	addi	s4,s4,566 # 80207980 <etext+0x980>
        b->next = bcache.head.next;
    80204752:	2b893783          	ld	a5,696(s2)
    80204756:	e8bc                	sd	a5,80(s1)
        b->prev = &bcache.head;
    80204758:	0534b423          	sd	s3,72(s1)
        initsleeplock(&b->lock, "buffer");
    8020475c:	85d2                	mv	a1,s4
    8020475e:	01048513          	addi	a0,s1,16
    80204762:	ffffd097          	auipc	ra,0xffffd
    80204766:	c96080e7          	jalr	-874(ra) # 802013f8 <initsleeplock>
        bcache.head.next->prev = b;
    8020476a:	2b893783          	ld	a5,696(s2)
    8020476e:	e7a4                	sd	s1,72(a5)
        bcache.head.next = b;
    80204770:	2a993c23          	sd	s1,696(s2)
    for (struct buf *b = bcache.buf; b < bcache.buf + NBUF; b++) {
    80204774:	45848493          	addi	s1,s1,1112
    80204778:	fd349de3          	bne	s1,s3,80204752 <binit+0x54>
    }
}
    8020477c:	70a2                	ld	ra,40(sp)
    8020477e:	7402                	ld	s0,32(sp)
    80204780:	64e2                	ld	s1,24(sp)
    80204782:	6942                	ld	s2,16(sp)
    80204784:	69a2                	ld	s3,8(sp)
    80204786:	6a02                	ld	s4,0(sp)
    80204788:	6145                	addi	sp,sp,48
    8020478a:	8082                	ret

000000008020478c <bread>:
    }
    panic("bget: no buffers - raise NBUF or find the brelse you forgot");
}

struct buf *bread(uint32 dev, uint32 blockno)
{
    8020478c:	7179                	addi	sp,sp,-48
    8020478e:	f406                	sd	ra,40(sp)
    80204790:	f022                	sd	s0,32(sp)
    80204792:	ec26                	sd	s1,24(sp)
    80204794:	e84a                	sd	s2,16(sp)
    80204796:	e44e                	sd	s3,8(sp)
    80204798:	1800                	addi	s0,sp,48
    8020479a:	892a                	mv	s2,a0
    8020479c:	89ae                	mv	s3,a1
    acquire(&bcache.lock);
    8020479e:	0012c517          	auipc	a0,0x12c
    802047a2:	32250513          	addi	a0,a0,802 # 80330ac0 <bcache>
    802047a6:	ffffd097          	auipc	ra,0xffffd
    802047aa:	b5a080e7          	jalr	-1190(ra) # 80201300 <acquire>
    for (struct buf *b = bcache.head.next; b != &bcache.head; b = b->next) {
    802047ae:	00134497          	auipc	s1,0x134
    802047b2:	5ca4b483          	ld	s1,1482(s1) # 80338d78 <bcache+0x82b8>
    802047b6:	00134797          	auipc	a5,0x134
    802047ba:	57278793          	addi	a5,a5,1394 # 80338d28 <bcache+0x8268>
    802047be:	02f48f63          	beq	s1,a5,802047fc <bread+0x70>
    802047c2:	873e                	mv	a4,a5
    802047c4:	a021                	j	802047cc <bread+0x40>
    802047c6:	68a4                	ld	s1,80(s1)
    802047c8:	02e48a63          	beq	s1,a4,802047fc <bread+0x70>
        if (b->dev == dev && b->blockno == blockno) {
    802047cc:	449c                	lw	a5,8(s1)
    802047ce:	ff279ce3          	bne	a5,s2,802047c6 <bread+0x3a>
    802047d2:	44dc                	lw	a5,12(s1)
    802047d4:	ff3799e3          	bne	a5,s3,802047c6 <bread+0x3a>
            b->refcnt++;
    802047d8:	40bc                	lw	a5,64(s1)
    802047da:	2785                	addiw	a5,a5,1
    802047dc:	c0bc                	sw	a5,64(s1)
            release(&bcache.lock);
    802047de:	0012c517          	auipc	a0,0x12c
    802047e2:	2e250513          	addi	a0,a0,738 # 80330ac0 <bcache>
    802047e6:	ffffd097          	auipc	ra,0xffffd
    802047ea:	bca080e7          	jalr	-1078(ra) # 802013b0 <release>
            acquiresleep(&b->lock);
    802047ee:	01048513          	addi	a0,s1,16
    802047f2:	ffffd097          	auipc	ra,0xffffd
    802047f6:	c40080e7          	jalr	-960(ra) # 80201432 <acquiresleep>
            return b;
    802047fa:	a8b9                	j	80204858 <bread+0xcc>
    for (struct buf *b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    802047fc:	00134497          	auipc	s1,0x134
    80204800:	5744b483          	ld	s1,1396(s1) # 80338d70 <bcache+0x82b0>
    80204804:	00134797          	auipc	a5,0x134
    80204808:	52478793          	addi	a5,a5,1316 # 80338d28 <bcache+0x8268>
    8020480c:	00f48863          	beq	s1,a5,8020481c <bread+0x90>
    80204810:	873e                	mv	a4,a5
        if (b->refcnt == 0) {
    80204812:	40bc                	lw	a5,64(s1)
    80204814:	cf81                	beqz	a5,8020482c <bread+0xa0>
    for (struct buf *b = bcache.head.prev; b != &bcache.head; b = b->prev) {
    80204816:	64a4                	ld	s1,72(s1)
    80204818:	fee49de3          	bne	s1,a4,80204812 <bread+0x86>
    panic("bget: no buffers - raise NBUF or find the brelse you forgot");
    8020481c:	00003517          	auipc	a0,0x3
    80204820:	16c50513          	addi	a0,a0,364 # 80207988 <etext+0x988>
    80204824:	ffffc097          	auipc	ra,0xffffc
    80204828:	d8c080e7          	jalr	-628(ra) # 802005b0 <panic>
            b->dev = dev;
    8020482c:	0124a423          	sw	s2,8(s1)
            b->blockno = blockno;
    80204830:	0134a623          	sw	s3,12(s1)
            b->valid = 0;
    80204834:	0004a023          	sw	zero,0(s1)
            b->refcnt = 1;
    80204838:	4785                	li	a5,1
    8020483a:	c0bc                	sw	a5,64(s1)
            release(&bcache.lock);
    8020483c:	0012c517          	auipc	a0,0x12c
    80204840:	28450513          	addi	a0,a0,644 # 80330ac0 <bcache>
    80204844:	ffffd097          	auipc	ra,0xffffd
    80204848:	b6c080e7          	jalr	-1172(ra) # 802013b0 <release>
            acquiresleep(&b->lock);
    8020484c:	01048513          	addi	a0,s1,16
    80204850:	ffffd097          	auipc	ra,0xffffd
    80204854:	be2080e7          	jalr	-1054(ra) # 80201432 <acquiresleep>
    struct buf *b = bget(dev, blockno);
    if (!b->valid) {
    80204858:	409c                	lw	a5,0(s1)
    8020485a:	cb89                	beqz	a5,8020486c <bread+0xe0>
        hal_block_rw(b, 0);
        b->valid = 1;
    }
    return b;
}
    8020485c:	8526                	mv	a0,s1
    8020485e:	70a2                	ld	ra,40(sp)
    80204860:	7402                	ld	s0,32(sp)
    80204862:	64e2                	ld	s1,24(sp)
    80204864:	6942                	ld	s2,16(sp)
    80204866:	69a2                	ld	s3,8(sp)
    80204868:	6145                	addi	sp,sp,48
    8020486a:	8082                	ret
        hal_block_rw(b, 0);
    8020486c:	4581                	li	a1,0
    8020486e:	8526                	mv	a0,s1
    80204870:	00002097          	auipc	ra,0x2
    80204874:	c90080e7          	jalr	-880(ra) # 80206500 <hal_block_rw>
        b->valid = 1;
    80204878:	4785                	li	a5,1
    8020487a:	c09c                	sw	a5,0(s1)
    return b;
    8020487c:	b7c5                	j	8020485c <bread+0xd0>

000000008020487e <bwrite>:

/* Caller must hold b->lock (i.e. this buf came from bread). */
void bwrite(struct buf *b)
{
    8020487e:	1101                	addi	sp,sp,-32
    80204880:	ec06                	sd	ra,24(sp)
    80204882:	e822                	sd	s0,16(sp)
    80204884:	e426                	sd	s1,8(sp)
    80204886:	1000                	addi	s0,sp,32
    80204888:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) panic("bwrite: buf not locked");
    8020488a:	0541                	addi	a0,a0,16
    8020488c:	ffffd097          	auipc	ra,0xffffd
    80204890:	c40080e7          	jalr	-960(ra) # 802014cc <holdingsleep>
    80204894:	cd01                	beqz	a0,802048ac <bwrite+0x2e>
    hal_block_rw(b, 1);
    80204896:	4585                	li	a1,1
    80204898:	8526                	mv	a0,s1
    8020489a:	00002097          	auipc	ra,0x2
    8020489e:	c66080e7          	jalr	-922(ra) # 80206500 <hal_block_rw>
}
    802048a2:	60e2                	ld	ra,24(sp)
    802048a4:	6442                	ld	s0,16(sp)
    802048a6:	64a2                	ld	s1,8(sp)
    802048a8:	6105                	addi	sp,sp,32
    802048aa:	8082                	ret
    if (!holdingsleep(&b->lock)) panic("bwrite: buf not locked");
    802048ac:	00003517          	auipc	a0,0x3
    802048b0:	11c50513          	addi	a0,a0,284 # 802079c8 <etext+0x9c8>
    802048b4:	ffffc097          	auipc	ra,0xffffc
    802048b8:	cfc080e7          	jalr	-772(ra) # 802005b0 <panic>

00000000802048bc <brelse>:

void brelse(struct buf *b)
{
    802048bc:	1101                	addi	sp,sp,-32
    802048be:	ec06                	sd	ra,24(sp)
    802048c0:	e822                	sd	s0,16(sp)
    802048c2:	e426                	sd	s1,8(sp)
    802048c4:	e04a                	sd	s2,0(sp)
    802048c6:	1000                	addi	s0,sp,32
    802048c8:	84aa                	mv	s1,a0
    if (!holdingsleep(&b->lock)) panic("brelse: buf not locked");
    802048ca:	01050913          	addi	s2,a0,16
    802048ce:	854a                	mv	a0,s2
    802048d0:	ffffd097          	auipc	ra,0xffffd
    802048d4:	bfc080e7          	jalr	-1028(ra) # 802014cc <holdingsleep>
    802048d8:	c535                	beqz	a0,80204944 <brelse+0x88>
    releasesleep(&b->lock);
    802048da:	854a                	mv	a0,s2
    802048dc:	ffffd097          	auipc	ra,0xffffd
    802048e0:	bac080e7          	jalr	-1108(ra) # 80201488 <releasesleep>

    acquire(&bcache.lock);
    802048e4:	0012c517          	auipc	a0,0x12c
    802048e8:	1dc50513          	addi	a0,a0,476 # 80330ac0 <bcache>
    802048ec:	ffffd097          	auipc	ra,0xffffd
    802048f0:	a14080e7          	jalr	-1516(ra) # 80201300 <acquire>
    b->refcnt--;
    802048f4:	40bc                	lw	a5,64(s1)
    802048f6:	37fd                	addiw	a5,a5,-1
    802048f8:	c0bc                	sw	a5,64(s1)
    if (b->refcnt == 0) {
    802048fa:	e79d                	bnez	a5,80204928 <brelse+0x6c>
        /* Move to the front: most recently used. */
        b->next->prev = b->prev;
    802048fc:	68b8                	ld	a4,80(s1)
    802048fe:	64bc                	ld	a5,72(s1)
    80204900:	e73c                	sd	a5,72(a4)
        b->prev->next = b->next;
    80204902:	68b8                	ld	a4,80(s1)
    80204904:	ebb8                	sd	a4,80(a5)
        b->next = bcache.head.next;
    80204906:	00134797          	auipc	a5,0x134
    8020490a:	1ba78793          	addi	a5,a5,442 # 80338ac0 <bcache+0x8000>
    8020490e:	2b87b703          	ld	a4,696(a5)
    80204912:	e8b8                	sd	a4,80(s1)
        b->prev = &bcache.head;
    80204914:	00134717          	auipc	a4,0x134
    80204918:	41470713          	addi	a4,a4,1044 # 80338d28 <bcache+0x8268>
    8020491c:	e4b8                	sd	a4,72(s1)
        bcache.head.next->prev = b;
    8020491e:	2b87b703          	ld	a4,696(a5)
    80204922:	e724                	sd	s1,72(a4)
        bcache.head.next = b;
    80204924:	2a97bc23          	sd	s1,696(a5)
    }
    release(&bcache.lock);
    80204928:	0012c517          	auipc	a0,0x12c
    8020492c:	19850513          	addi	a0,a0,408 # 80330ac0 <bcache>
    80204930:	ffffd097          	auipc	ra,0xffffd
    80204934:	a80080e7          	jalr	-1408(ra) # 802013b0 <release>
}
    80204938:	60e2                	ld	ra,24(sp)
    8020493a:	6442                	ld	s0,16(sp)
    8020493c:	64a2                	ld	s1,8(sp)
    8020493e:	6902                	ld	s2,0(sp)
    80204940:	6105                	addi	sp,sp,32
    80204942:	8082                	ret
    if (!holdingsleep(&b->lock)) panic("brelse: buf not locked");
    80204944:	00003517          	auipc	a0,0x3
    80204948:	09c50513          	addi	a0,a0,156 # 802079e0 <etext+0x9e0>
    8020494c:	ffffc097          	auipc	ra,0xffffc
    80204950:	c64080e7          	jalr	-924(ra) # 802005b0 <panic>

0000000080204954 <bfree>:
    printf("luitfs: out of data blocks\n");
    return 0;
}

static void bfree(int dev, uint32 b)
{
    80204954:	1101                	addi	sp,sp,-32
    80204956:	ec06                	sd	ra,24(sp)
    80204958:	e822                	sd	s0,16(sp)
    8020495a:	e426                	sd	s1,8(sp)
    8020495c:	e04a                	sd	s2,0(sp)
    8020495e:	1000                	addi	s0,sp,32
    80204960:	84ae                	mv	s1,a1
    struct buf *bp = bread(dev, DBBLOCK(b, sb));
    80204962:	00d5d79b          	srliw	a5,a1,0xd
    80204966:	00135597          	auipc	a1,0x135
    8020496a:	8325a583          	lw	a1,-1998(a1) # 80339198 <sb+0x18>
    8020496e:	9dbd                	addw	a1,a1,a5
    80204970:	00000097          	auipc	ra,0x0
    80204974:	e1c080e7          	jalr	-484(ra) # 8020478c <bread>
    uint32 bi = b % BPB;
    int m = 1 << (bi % 8);
    80204978:	0074f713          	andi	a4,s1,7
    8020497c:	4785                	li	a5,1
    8020497e:	00e797bb          	sllw	a5,a5,a4
    uint32 bi = b % BPB;
    80204982:	14ce                	slli	s1,s1,0x33
    80204984:	0334d713          	srli	a4,s1,0x33
    if ((bp->data[bi / 8] & m) == 0) panic("bfree: freeing a free block");
    80204988:	90d9                	srli	s1,s1,0x36
    8020498a:	94aa                	add	s1,s1,a0
    8020498c:	0584c683          	lbu	a3,88(s1)
    80204990:	00d7f633          	and	a2,a5,a3
    80204994:	ca0d                	beqz	a2,802049c6 <bfree+0x72>
    80204996:	892a                	mv	s2,a0
    bp->data[bi / 8] &= ~m;
    80204998:	0037571b          	srliw	a4,a4,0x3
    8020499c:	972a                	add	a4,a4,a0
    8020499e:	fff7c793          	not	a5,a5
    802049a2:	8efd                	and	a3,a3,a5
    802049a4:	04d70c23          	sb	a3,88(a4)
    bwrite(bp);
    802049a8:	00000097          	auipc	ra,0x0
    802049ac:	ed6080e7          	jalr	-298(ra) # 8020487e <bwrite>
    brelse(bp);
    802049b0:	854a                	mv	a0,s2
    802049b2:	00000097          	auipc	ra,0x0
    802049b6:	f0a080e7          	jalr	-246(ra) # 802048bc <brelse>
}
    802049ba:	60e2                	ld	ra,24(sp)
    802049bc:	6442                	ld	s0,16(sp)
    802049be:	64a2                	ld	s1,8(sp)
    802049c0:	6902                	ld	s2,0(sp)
    802049c2:	6105                	addi	sp,sp,32
    802049c4:	8082                	ret
    if ((bp->data[bi / 8] & m) == 0) panic("bfree: freeing a free block");
    802049c6:	00003517          	auipc	a0,0x3
    802049ca:	03250513          	addi	a0,a0,50 # 802079f8 <etext+0x9f8>
    802049ce:	ffffc097          	auipc	ra,0xffffc
    802049d2:	be2080e7          	jalr	-1054(ra) # 802005b0 <panic>

00000000802049d6 <balloc>:
{
    802049d6:	715d                	addi	sp,sp,-80
    802049d8:	e486                	sd	ra,72(sp)
    802049da:	e0a2                	sd	s0,64(sp)
    802049dc:	fc26                	sd	s1,56(sp)
    802049de:	0880                	addi	s0,sp,80
    for (uint32 b = 0; b < sb.size; b += BPB) {
    802049e0:	00134797          	auipc	a5,0x134
    802049e4:	7a87a783          	lw	a5,1960(a5) # 80339188 <sb+0x8>
    802049e8:	cfed                	beqz	a5,80204ae2 <balloc+0x10c>
    802049ea:	f84a                	sd	s2,48(sp)
    802049ec:	f44e                	sd	s3,40(sp)
    802049ee:	f052                	sd	s4,32(sp)
    802049f0:	ec56                	sd	s5,24(sp)
    802049f2:	e85a                	sd	s6,16(sp)
    802049f4:	e45e                	sd	s7,8(sp)
    802049f6:	e062                	sd	s8,0(sp)
    802049f8:	8b2a                	mv	s6,a0
    802049fa:	4a81                	li	s5,0
        struct buf *bp = bread(dev, DBBLOCK(b, sb));
    802049fc:	00134b97          	auipc	s7,0x134
    80204a00:	784b8b93          	addi	s7,s7,1924 # 80339180 <sb>
            int m = 1 << (bi % 8);
    80204a04:	4985                	li	s3,1
        for (uint32 bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80204a06:	6a09                	lui	s4,0x2
    for (uint32 b = 0; b < sb.size; b += BPB) {
    80204a08:	6c09                	lui	s8,0x2
    80204a0a:	a059                	j	80204a90 <balloc+0xba>
                bp->data[bi / 8] |= m;              /* claim it... */
    80204a0c:	0037d79b          	srliw	a5,a5,0x3
    80204a10:	97ca                	add	a5,a5,s2
    80204a12:	8ed9                	or	a3,a3,a4
    80204a14:	04d78c23          	sb	a3,88(a5)
                bwrite(bp);                         /* ...ON DISK, before use */
    80204a18:	854a                	mv	a0,s2
    80204a1a:	00000097          	auipc	ra,0x0
    80204a1e:	e64080e7          	jalr	-412(ra) # 8020487e <bwrite>
                brelse(bp);
    80204a22:	854a                	mv	a0,s2
    80204a24:	00000097          	auipc	ra,0x0
    80204a28:	e98080e7          	jalr	-360(ra) # 802048bc <brelse>
    struct buf *bp = bread(dev, bno);
    80204a2c:	85a6                	mv	a1,s1
    80204a2e:	855a                	mv	a0,s6
    80204a30:	00000097          	auipc	ra,0x0
    80204a34:	d5c080e7          	jalr	-676(ra) # 8020478c <bread>
    80204a38:	892a                	mv	s2,a0
    memset(bp->data, 0, BSIZE);
    80204a3a:	40000613          	li	a2,1024
    80204a3e:	4581                	li	a1,0
    80204a40:	05850513          	addi	a0,a0,88
    80204a44:	ffffc097          	auipc	ra,0xffffc
    80204a48:	c12080e7          	jalr	-1006(ra) # 80200656 <memset>
    bwrite(bp);
    80204a4c:	854a                	mv	a0,s2
    80204a4e:	00000097          	auipc	ra,0x0
    80204a52:	e30080e7          	jalr	-464(ra) # 8020487e <bwrite>
    brelse(bp);
    80204a56:	854a                	mv	a0,s2
    80204a58:	00000097          	auipc	ra,0x0
    80204a5c:	e64080e7          	jalr	-412(ra) # 802048bc <brelse>
}
    80204a60:	7942                	ld	s2,48(sp)
    80204a62:	79a2                	ld	s3,40(sp)
    80204a64:	7a02                	ld	s4,32(sp)
    80204a66:	6ae2                	ld	s5,24(sp)
    80204a68:	6b42                	ld	s6,16(sp)
    80204a6a:	6ba2                	ld	s7,8(sp)
    80204a6c:	6c02                	ld	s8,0(sp)
}
    80204a6e:	8526                	mv	a0,s1
    80204a70:	60a6                	ld	ra,72(sp)
    80204a72:	6406                	ld	s0,64(sp)
    80204a74:	74e2                	ld	s1,56(sp)
    80204a76:	6161                	addi	sp,sp,80
    80204a78:	8082                	ret
        brelse(bp);
    80204a7a:	854a                	mv	a0,s2
    80204a7c:	00000097          	auipc	ra,0x0
    80204a80:	e40080e7          	jalr	-448(ra) # 802048bc <brelse>
    for (uint32 b = 0; b < sb.size; b += BPB) {
    80204a84:	015c0abb          	addw	s5,s8,s5
    80204a88:	008ba783          	lw	a5,8(s7)
    80204a8c:	04faf463          	bgeu	s5,a5,80204ad4 <balloc+0xfe>
        struct buf *bp = bread(dev, DBBLOCK(b, sb));
    80204a90:	00dad59b          	srliw	a1,s5,0xd
    80204a94:	018ba783          	lw	a5,24(s7)
    80204a98:	9dbd                	addw	a1,a1,a5
    80204a9a:	855a                	mv	a0,s6
    80204a9c:	00000097          	auipc	ra,0x0
    80204aa0:	cf0080e7          	jalr	-784(ra) # 8020478c <bread>
    80204aa4:	892a                	mv	s2,a0
        for (uint32 bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80204aa6:	008ba583          	lw	a1,8(s7)
    80204aaa:	84d6                	mv	s1,s5
    80204aac:	4781                	li	a5,0
    80204aae:	fcb4f6e3          	bgeu	s1,a1,80204a7a <balloc+0xa4>
            int m = 1 << (bi % 8);
    80204ab2:	0077f713          	andi	a4,a5,7
    80204ab6:	00e9973b          	sllw	a4,s3,a4
            if ((bp->data[bi / 8] & m) == 0) {
    80204aba:	0037d69b          	srliw	a3,a5,0x3
    80204abe:	96ca                	add	a3,a3,s2
    80204ac0:	0586c683          	lbu	a3,88(a3)
    80204ac4:	00d77633          	and	a2,a4,a3
    80204ac8:	d231                	beqz	a2,80204a0c <balloc+0x36>
        for (uint32 bi = 0; bi < BPB && b + bi < sb.size; bi++) {
    80204aca:	2785                	addiw	a5,a5,1
    80204acc:	2485                	addiw	s1,s1,1
    80204ace:	ff4790e3          	bne	a5,s4,80204aae <balloc+0xd8>
    80204ad2:	b765                	j	80204a7a <balloc+0xa4>
    80204ad4:	7942                	ld	s2,48(sp)
    80204ad6:	79a2                	ld	s3,40(sp)
    80204ad8:	7a02                	ld	s4,32(sp)
    80204ada:	6ae2                	ld	s5,24(sp)
    80204adc:	6b42                	ld	s6,16(sp)
    80204ade:	6ba2                	ld	s7,8(sp)
    80204ae0:	6c02                	ld	s8,0(sp)
    printf("luitfs: out of data blocks\n");
    80204ae2:	00003517          	auipc	a0,0x3
    80204ae6:	f3650513          	addi	a0,a0,-202 # 80207a18 <etext+0xa18>
    80204aea:	ffffc097          	auipc	ra,0xffffc
    80204aee:	856080e7          	jalr	-1962(ra) # 80200340 <printf>
    return 0;
    80204af2:	4481                	li	s1,0
    80204af4:	bfad                	j	80204a6e <balloc+0x98>

0000000080204af6 <bmap>:
/* ---------- block mapping ---------- */

/* Return the disk block holding byte-offset block `bn` of ip, allocating it
 * (and the indirect block) on demand. 0 = out of space. Caller holds ip->lock. */
static uint32 bmap(struct inode *ip, uint32 bn)
{
    80204af6:	7179                	addi	sp,sp,-48
    80204af8:	f406                	sd	ra,40(sp)
    80204afa:	f022                	sd	s0,32(sp)
    80204afc:	ec26                	sd	s1,24(sp)
    80204afe:	e84a                	sd	s2,16(sp)
    80204b00:	e44e                	sd	s3,8(sp)
    80204b02:	1800                	addi	s0,sp,48
    80204b04:	89aa                	mv	s3,a0
    if (bn < NDIRECT) {
    80204b06:	47ad                	li	a5,11
    80204b08:	02b7e563          	bltu	a5,a1,80204b32 <bmap+0x3c>
        uint32 addr = ip->addrs[bn];
    80204b0c:	02059793          	slli	a5,a1,0x20
    80204b10:	01e7d593          	srli	a1,a5,0x1e
    80204b14:	00b504b3          	add	s1,a0,a1
    80204b18:	0504a903          	lw	s2,80(s1)
        if (addr == 0) {
    80204b1c:	06091b63          	bnez	s2,80204b92 <bmap+0x9c>
            addr = balloc(ip->dev);
    80204b20:	4108                	lw	a0,0(a0)
    80204b22:	00000097          	auipc	ra,0x0
    80204b26:	eb4080e7          	jalr	-332(ra) # 802049d6 <balloc>
    80204b2a:	892a                	mv	s2,a0
            if (addr == 0) return 0;
    80204b2c:	c13d                	beqz	a0,80204b92 <bmap+0x9c>
            ip->addrs[bn] = addr;
    80204b2e:	c8a8                	sw	a0,80(s1)
    80204b30:	a08d                	j	80204b92 <bmap+0x9c>
        }
        return addr;
    }
    bn -= NDIRECT;
    80204b32:	ff45849b          	addiw	s1,a1,-12
    if (bn < NINDIRECT) {
    80204b36:	0ff00793          	li	a5,255
    80204b3a:	0897e363          	bltu	a5,s1,80204bc0 <bmap+0xca>
        /* Implementation note. */
        uint32 addr = ip->addrs[NDIRECT];
    80204b3e:	08052903          	lw	s2,128(a0)
        if (addr == 0) {
    80204b42:	00091d63          	bnez	s2,80204b5c <bmap+0x66>
            addr = balloc(ip->dev);
    80204b46:	4108                	lw	a0,0(a0)
    80204b48:	00000097          	auipc	ra,0x0
    80204b4c:	e8e080e7          	jalr	-370(ra) # 802049d6 <balloc>
    80204b50:	892a                	mv	s2,a0
            if (addr == 0) return 0;
    80204b52:	c121                	beqz	a0,80204b92 <bmap+0x9c>
    80204b54:	e052                	sd	s4,0(sp)
            ip->addrs[NDIRECT] = addr;
    80204b56:	08a9a023          	sw	a0,128(s3)
    80204b5a:	a011                	j	80204b5e <bmap+0x68>
    80204b5c:	e052                	sd	s4,0(sp)
        }
        struct buf *bp = bread(ip->dev, addr);
    80204b5e:	85ca                	mv	a1,s2
    80204b60:	0009a503          	lw	a0,0(s3)
    80204b64:	00000097          	auipc	ra,0x0
    80204b68:	c28080e7          	jalr	-984(ra) # 8020478c <bread>
    80204b6c:	8a2a                	mv	s4,a0
        uint32 *a = (uint32 *)bp->data;
    80204b6e:	05850793          	addi	a5,a0,88
        if ((addr = a[bn]) == 0) {
    80204b72:	02049713          	slli	a4,s1,0x20
    80204b76:	01e75593          	srli	a1,a4,0x1e
    80204b7a:	00b784b3          	add	s1,a5,a1
    80204b7e:	0004a903          	lw	s2,0(s1)
    80204b82:	02090063          	beqz	s2,80204ba2 <bmap+0xac>
            addr = balloc(ip->dev);
            if (addr) { a[bn] = addr; bwrite(bp); }
        }
        brelse(bp);
    80204b86:	8552                	mv	a0,s4
    80204b88:	00000097          	auipc	ra,0x0
    80204b8c:	d34080e7          	jalr	-716(ra) # 802048bc <brelse>
        return addr;
    80204b90:	6a02                	ld	s4,0(sp)
    }
    panic("bmap: block number beyond MAXFILE");
}
    80204b92:	854a                	mv	a0,s2
    80204b94:	70a2                	ld	ra,40(sp)
    80204b96:	7402                	ld	s0,32(sp)
    80204b98:	64e2                	ld	s1,24(sp)
    80204b9a:	6942                	ld	s2,16(sp)
    80204b9c:	69a2                	ld	s3,8(sp)
    80204b9e:	6145                	addi	sp,sp,48
    80204ba0:	8082                	ret
            addr = balloc(ip->dev);
    80204ba2:	0009a503          	lw	a0,0(s3)
    80204ba6:	00000097          	auipc	ra,0x0
    80204baa:	e30080e7          	jalr	-464(ra) # 802049d6 <balloc>
    80204bae:	892a                	mv	s2,a0
            if (addr) { a[bn] = addr; bwrite(bp); }
    80204bb0:	d979                	beqz	a0,80204b86 <bmap+0x90>
    80204bb2:	c088                	sw	a0,0(s1)
    80204bb4:	8552                	mv	a0,s4
    80204bb6:	00000097          	auipc	ra,0x0
    80204bba:	cc8080e7          	jalr	-824(ra) # 8020487e <bwrite>
    80204bbe:	b7e1                	j	80204b86 <bmap+0x90>
    80204bc0:	e052                	sd	s4,0(sp)
    panic("bmap: block number beyond MAXFILE");
    80204bc2:	00003517          	auipc	a0,0x3
    80204bc6:	e7650513          	addi	a0,a0,-394 # 80207a38 <etext+0xa38>
    80204bca:	ffffc097          	auipc	ra,0xffffc
    80204bce:	9e6080e7          	jalr	-1562(ra) # 802005b0 <panic>

0000000080204bd2 <iget>:
{
    80204bd2:	7179                	addi	sp,sp,-48
    80204bd4:	f406                	sd	ra,40(sp)
    80204bd6:	f022                	sd	s0,32(sp)
    80204bd8:	ec26                	sd	s1,24(sp)
    80204bda:	e84a                	sd	s2,16(sp)
    80204bdc:	e44e                	sd	s3,8(sp)
    80204bde:	e052                	sd	s4,0(sp)
    80204be0:	1800                	addi	s0,sp,48
    80204be2:	89aa                	mv	s3,a0
    80204be4:	8a2e                	mv	s4,a1
    acquire(&icache.lock);
    80204be6:	00134517          	auipc	a0,0x134
    80204bea:	5c250513          	addi	a0,a0,1474 # 803391a8 <icache>
    80204bee:	ffffc097          	auipc	ra,0xffffc
    80204bf2:	712080e7          	jalr	1810(ra) # 80201300 <acquire>
    for (struct inode *ip = icache.inode; ip < icache.inode + NINODE; ip++) {
    80204bf6:	00134497          	auipc	s1,0x134
    80204bfa:	5ca48493          	addi	s1,s1,1482 # 803391c0 <icache+0x18>
    struct inode *empty = 0;
    80204bfe:	4901                	li	s2,0
    for (struct inode *ip = icache.inode; ip < icache.inode + NINODE; ip++) {
    80204c00:	00136697          	auipc	a3,0x136
    80204c04:	05068693          	addi	a3,a3,80 # 8033ac50 <devsw>
    80204c08:	a039                	j	80204c16 <iget+0x44>
        if (empty == 0 && ip->ref == 0)
    80204c0a:	02090b63          	beqz	s2,80204c40 <iget+0x6e>
    for (struct inode *ip = icache.inode; ip < icache.inode + NINODE; ip++) {
    80204c0e:	08848493          	addi	s1,s1,136
    80204c12:	02d48a63          	beq	s1,a3,80204c46 <iget+0x74>
        if (ip->ref > 0 && ip->dev == dev && ip->inum == inum) {
    80204c16:	449c                	lw	a5,8(s1)
    80204c18:	fef059e3          	blez	a5,80204c0a <iget+0x38>
    80204c1c:	4098                	lw	a4,0(s1)
    80204c1e:	ff3716e3          	bne	a4,s3,80204c0a <iget+0x38>
    80204c22:	40d8                	lw	a4,4(s1)
    80204c24:	ff4713e3          	bne	a4,s4,80204c0a <iget+0x38>
            ip->ref++;
    80204c28:	2785                	addiw	a5,a5,1
    80204c2a:	c49c                	sw	a5,8(s1)
            release(&icache.lock);
    80204c2c:	00134517          	auipc	a0,0x134
    80204c30:	57c50513          	addi	a0,a0,1404 # 803391a8 <icache>
    80204c34:	ffffc097          	auipc	ra,0xffffc
    80204c38:	77c080e7          	jalr	1916(ra) # 802013b0 <release>
            return ip;
    80204c3c:	8926                	mv	s2,s1
    80204c3e:	a03d                	j	80204c6c <iget+0x9a>
        if (empty == 0 && ip->ref == 0)
    80204c40:	f7f9                	bnez	a5,80204c0e <iget+0x3c>
            empty = ip;
    80204c42:	8926                	mv	s2,s1
    80204c44:	b7e9                	j	80204c0e <iget+0x3c>
    if (empty == 0) panic("iget: inode cache full - raise NINODE");
    80204c46:	02090c63          	beqz	s2,80204c7e <iget+0xac>
    ip->dev = dev; ip->inum = inum; ip->ref = 1; ip->valid = 0;
    80204c4a:	01392023          	sw	s3,0(s2)
    80204c4e:	01492223          	sw	s4,4(s2)
    80204c52:	4785                	li	a5,1
    80204c54:	00f92423          	sw	a5,8(s2)
    80204c58:	04092023          	sw	zero,64(s2)
    release(&icache.lock);
    80204c5c:	00134517          	auipc	a0,0x134
    80204c60:	54c50513          	addi	a0,a0,1356 # 803391a8 <icache>
    80204c64:	ffffc097          	auipc	ra,0xffffc
    80204c68:	74c080e7          	jalr	1868(ra) # 802013b0 <release>
}
    80204c6c:	854a                	mv	a0,s2
    80204c6e:	70a2                	ld	ra,40(sp)
    80204c70:	7402                	ld	s0,32(sp)
    80204c72:	64e2                	ld	s1,24(sp)
    80204c74:	6942                	ld	s2,16(sp)
    80204c76:	69a2                	ld	s3,8(sp)
    80204c78:	6a02                	ld	s4,0(sp)
    80204c7a:	6145                	addi	sp,sp,48
    80204c7c:	8082                	ret
    if (empty == 0) panic("iget: inode cache full - raise NINODE");
    80204c7e:	00003517          	auipc	a0,0x3
    80204c82:	de250513          	addi	a0,a0,-542 # 80207a60 <etext+0xa60>
    80204c86:	ffffc097          	auipc	ra,0xffffc
    80204c8a:	92a080e7          	jalr	-1750(ra) # 802005b0 <panic>

0000000080204c8e <fsinit>:
{
    80204c8e:	1101                	addi	sp,sp,-32
    80204c90:	ec06                	sd	ra,24(sp)
    80204c92:	e822                	sd	s0,16(sp)
    80204c94:	e426                	sd	s1,8(sp)
    80204c96:	e04a                	sd	s2,0(sp)
    80204c98:	1000                	addi	s0,sp,32
    struct buf *bp = bread(dev, 1);
    80204c9a:	4585                	li	a1,1
    80204c9c:	00000097          	auipc	ra,0x0
    80204ca0:	af0080e7          	jalr	-1296(ra) # 8020478c <bread>
    80204ca4:	84aa                	mv	s1,a0
    memmove(&sb, bp->data, sizeof(sb));
    80204ca6:	00134917          	auipc	s2,0x134
    80204caa:	4da90913          	addi	s2,s2,1242 # 80339180 <sb>
    80204cae:	02800613          	li	a2,40
    80204cb2:	05850593          	addi	a1,a0,88
    80204cb6:	854a                	mv	a0,s2
    80204cb8:	ffffc097          	auipc	ra,0xffffc
    80204cbc:	9be080e7          	jalr	-1602(ra) # 80200676 <memmove>
    brelse(bp);
    80204cc0:	8526                	mv	a0,s1
    80204cc2:	00000097          	auipc	ra,0x0
    80204cc6:	bfa080e7          	jalr	-1030(ra) # 802048bc <brelse>
    if (sb.magic != LUITFS_MAGIC) panic("fsinit: not a LuitFS disk (bad magic)");
    80204cca:	00092703          	lw	a4,0(s2)
    80204cce:	4c5557b7          	lui	a5,0x4c555
    80204cd2:	95478793          	addi	a5,a5,-1708 # 4c554954 <_entry-0x33cab6ac>
    80204cd6:	02f71e63          	bne	a4,a5,80204d12 <fsinit+0x84>
    if (sb.version != LUITFS_VERSION) panic("fsinit: LuitFS version mismatch");
    80204cda:	00134717          	auipc	a4,0x134
    80204cde:	4aa72703          	lw	a4,1194(a4) # 80339184 <sb+0x4>
    80204ce2:	4785                	li	a5,1
    80204ce4:	02f71f63          	bne	a4,a5,80204d22 <fsinit+0x94>
    printf("luitfs: %d blocks, %d inodes, data at block %d\n",
    80204ce8:	00134797          	auipc	a5,0x134
    80204cec:	49878793          	addi	a5,a5,1176 # 80339180 <sb>
    80204cf0:	5394                	lw	a3,32(a5)
    80204cf2:	47d0                	lw	a2,12(a5)
    80204cf4:	478c                	lw	a1,8(a5)
    80204cf6:	00003517          	auipc	a0,0x3
    80204cfa:	dda50513          	addi	a0,a0,-550 # 80207ad0 <etext+0xad0>
    80204cfe:	ffffb097          	auipc	ra,0xffffb
    80204d02:	642080e7          	jalr	1602(ra) # 80200340 <printf>
}
    80204d06:	60e2                	ld	ra,24(sp)
    80204d08:	6442                	ld	s0,16(sp)
    80204d0a:	64a2                	ld	s1,8(sp)
    80204d0c:	6902                	ld	s2,0(sp)
    80204d0e:	6105                	addi	sp,sp,32
    80204d10:	8082                	ret
    if (sb.magic != LUITFS_MAGIC) panic("fsinit: not a LuitFS disk (bad magic)");
    80204d12:	00003517          	auipc	a0,0x3
    80204d16:	d7650513          	addi	a0,a0,-650 # 80207a88 <etext+0xa88>
    80204d1a:	ffffc097          	auipc	ra,0xffffc
    80204d1e:	896080e7          	jalr	-1898(ra) # 802005b0 <panic>
    if (sb.version != LUITFS_VERSION) panic("fsinit: LuitFS version mismatch");
    80204d22:	00003517          	auipc	a0,0x3
    80204d26:	d8e50513          	addi	a0,a0,-626 # 80207ab0 <etext+0xab0>
    80204d2a:	ffffc097          	auipc	ra,0xffffc
    80204d2e:	886080e7          	jalr	-1914(ra) # 802005b0 <panic>

0000000080204d32 <iinit>:
{
    80204d32:	7179                	addi	sp,sp,-48
    80204d34:	f406                	sd	ra,40(sp)
    80204d36:	f022                	sd	s0,32(sp)
    80204d38:	ec26                	sd	s1,24(sp)
    80204d3a:	e84a                	sd	s2,16(sp)
    80204d3c:	e44e                	sd	s3,8(sp)
    80204d3e:	1800                	addi	s0,sp,48
    initlock(&icache.lock, "icache");
    80204d40:	00003597          	auipc	a1,0x3
    80204d44:	dc058593          	addi	a1,a1,-576 # 80207b00 <etext+0xb00>
    80204d48:	00134517          	auipc	a0,0x134
    80204d4c:	46050513          	addi	a0,a0,1120 # 803391a8 <icache>
    80204d50:	ffffc097          	auipc	ra,0xffffc
    80204d54:	530080e7          	jalr	1328(ra) # 80201280 <initlock>
    for (int i = 0; i < NINODE; i++)
    80204d58:	00134497          	auipc	s1,0x134
    80204d5c:	47848493          	addi	s1,s1,1144 # 803391d0 <icache+0x28>
    80204d60:	00136997          	auipc	s3,0x136
    80204d64:	f0098993          	addi	s3,s3,-256 # 8033ac60 <devsw+0x10>
        initsleeplock(&icache.inode[i].lock, "inode");
    80204d68:	00003917          	auipc	s2,0x3
    80204d6c:	da090913          	addi	s2,s2,-608 # 80207b08 <etext+0xb08>
    80204d70:	85ca                	mv	a1,s2
    80204d72:	8526                	mv	a0,s1
    80204d74:	ffffc097          	auipc	ra,0xffffc
    80204d78:	684080e7          	jalr	1668(ra) # 802013f8 <initsleeplock>
    for (int i = 0; i < NINODE; i++)
    80204d7c:	08848493          	addi	s1,s1,136
    80204d80:	ff3498e3          	bne	s1,s3,80204d70 <iinit+0x3e>
}
    80204d84:	70a2                	ld	ra,40(sp)
    80204d86:	7402                	ld	s0,32(sp)
    80204d88:	64e2                	ld	s1,24(sp)
    80204d8a:	6942                	ld	s2,16(sp)
    80204d8c:	69a2                	ld	s3,8(sp)
    80204d8e:	6145                	addi	sp,sp,48
    80204d90:	8082                	ret

0000000080204d92 <ialloc>:
{
    80204d92:	715d                	addi	sp,sp,-80
    80204d94:	e486                	sd	ra,72(sp)
    80204d96:	e0a2                	sd	s0,64(sp)
    80204d98:	0880                	addi	s0,sp,80
    for (uint32 i = ROOTINO; i < sb.ninodes; i += 1) {
    80204d9a:	00134717          	auipc	a4,0x134
    80204d9e:	3f272703          	lw	a4,1010(a4) # 8033918c <sb+0xc>
    80204da2:	4785                	li	a5,1
    80204da4:	06e7fc63          	bgeu	a5,a4,80204e1c <ialloc+0x8a>
    80204da8:	fc26                	sd	s1,56(sp)
    80204daa:	f84a                	sd	s2,48(sp)
    80204dac:	f44e                	sd	s3,40(sp)
    80204dae:	f052                	sd	s4,32(sp)
    80204db0:	ec56                	sd	s5,24(sp)
    80204db2:	e85a                	sd	s6,16(sp)
    80204db4:	e45e                	sd	s7,8(sp)
    80204db6:	8a2a                	mv	s4,a0
    80204db8:	8bae                	mv	s7,a1
    80204dba:	84be                	mv	s1,a5
        struct buf *bp = bread(dev, IBBLOCK(i, sb));
    80204dbc:	00134997          	auipc	s3,0x134
    80204dc0:	3c498993          	addi	s3,s3,964 # 80339180 <sb>
        int m = 1 << (bi % 8);
    80204dc4:	4b05                	li	s6,1
        uint32 bi = i % BPB;
    80204dc6:	6a89                	lui	s5,0x2
    80204dc8:	1afd                	addi	s5,s5,-1 # 1fff <_entry-0x801fe001>
        struct buf *bp = bread(dev, IBBLOCK(i, sb));
    80204dca:	00d4d59b          	srliw	a1,s1,0xd
    80204dce:	0149a783          	lw	a5,20(s3)
    80204dd2:	9dbd                	addw	a1,a1,a5
    80204dd4:	8552                	mv	a0,s4
    80204dd6:	00000097          	auipc	ra,0x0
    80204dda:	9b6080e7          	jalr	-1610(ra) # 8020478c <bread>
    80204dde:	892a                	mv	s2,a0
        int m = 1 << (bi % 8);
    80204de0:	0074f793          	andi	a5,s1,7
    80204de4:	00fb17bb          	sllw	a5,s6,a5
        uint32 bi = i % BPB;
    80204de8:	0154f6b3          	and	a3,s1,s5
        if ((bp->data[bi / 8] & m) == 0) {
    80204dec:	0036d71b          	srliw	a4,a3,0x3
    80204df0:	972a                	add	a4,a4,a0
    80204df2:	05874703          	lbu	a4,88(a4)
    80204df6:	00e7f633          	and	a2,a5,a4
    80204dfa:	ce15                	beqz	a2,80204e36 <ialloc+0xa4>
        brelse(bp);
    80204dfc:	00000097          	auipc	ra,0x0
    80204e00:	ac0080e7          	jalr	-1344(ra) # 802048bc <brelse>
    for (uint32 i = ROOTINO; i < sb.ninodes; i += 1) {
    80204e04:	2485                	addiw	s1,s1,1
    80204e06:	00c9a783          	lw	a5,12(s3)
    80204e0a:	fcf4e0e3          	bltu	s1,a5,80204dca <ialloc+0x38>
    80204e0e:	74e2                	ld	s1,56(sp)
    80204e10:	7942                	ld	s2,48(sp)
    80204e12:	79a2                	ld	s3,40(sp)
    80204e14:	7a02                	ld	s4,32(sp)
    80204e16:	6ae2                	ld	s5,24(sp)
    80204e18:	6b42                	ld	s6,16(sp)
    80204e1a:	6ba2                	ld	s7,8(sp)
    printf("luitfs: out of inodes\n");
    80204e1c:	00003517          	auipc	a0,0x3
    80204e20:	cf450513          	addi	a0,a0,-780 # 80207b10 <etext+0xb10>
    80204e24:	ffffb097          	auipc	ra,0xffffb
    80204e28:	51c080e7          	jalr	1308(ra) # 80200340 <printf>
    return 0;
    80204e2c:	4501                	li	a0,0
}
    80204e2e:	60a6                	ld	ra,72(sp)
    80204e30:	6406                	ld	s0,64(sp)
    80204e32:	6161                	addi	sp,sp,80
    80204e34:	8082                	ret
            bp->data[bi / 8] |= m;
    80204e36:	0036d69b          	srliw	a3,a3,0x3
    80204e3a:	96aa                	add	a3,a3,a0
    80204e3c:	8f5d                	or	a4,a4,a5
    80204e3e:	04e68c23          	sb	a4,88(a3)
            bwrite(bp);
    80204e42:	00000097          	auipc	ra,0x0
    80204e46:	a3c080e7          	jalr	-1476(ra) # 8020487e <bwrite>
            brelse(bp);
    80204e4a:	854a                	mv	a0,s2
    80204e4c:	00000097          	auipc	ra,0x0
    80204e50:	a70080e7          	jalr	-1424(ra) # 802048bc <brelse>
            bp = bread(dev, IBLOCK(i, sb));
    80204e54:	0044d79b          	srliw	a5,s1,0x4
    80204e58:	00134597          	auipc	a1,0x134
    80204e5c:	3445a583          	lw	a1,836(a1) # 8033919c <sb+0x1c>
    80204e60:	9dbd                	addw	a1,a1,a5
    80204e62:	8552                	mv	a0,s4
    80204e64:	00000097          	auipc	ra,0x0
    80204e68:	928080e7          	jalr	-1752(ra) # 8020478c <bread>
    80204e6c:	892a                	mv	s2,a0
            struct dinode *dip = (struct dinode *)bp->data + i % IPB;
    80204e6e:	05850993          	addi	s3,a0,88
    80204e72:	00f4f793          	andi	a5,s1,15
    80204e76:	079a                	slli	a5,a5,0x6
    80204e78:	99be                	add	s3,s3,a5
            memset(dip, 0, sizeof(*dip));
    80204e7a:	04000613          	li	a2,64
    80204e7e:	4581                	li	a1,0
    80204e80:	854e                	mv	a0,s3
    80204e82:	ffffb097          	auipc	ra,0xffffb
    80204e86:	7d4080e7          	jalr	2004(ra) # 80200656 <memset>
            dip->type = type;
    80204e8a:	01799023          	sh	s7,0(s3)
            bwrite(bp);
    80204e8e:	854a                	mv	a0,s2
    80204e90:	00000097          	auipc	ra,0x0
    80204e94:	9ee080e7          	jalr	-1554(ra) # 8020487e <bwrite>
            brelse(bp);
    80204e98:	854a                	mv	a0,s2
    80204e9a:	00000097          	auipc	ra,0x0
    80204e9e:	a22080e7          	jalr	-1502(ra) # 802048bc <brelse>
            return iget(dev, i);
    80204ea2:	85a6                	mv	a1,s1
    80204ea4:	8552                	mv	a0,s4
    80204ea6:	00000097          	auipc	ra,0x0
    80204eaa:	d2c080e7          	jalr	-724(ra) # 80204bd2 <iget>
    80204eae:	74e2                	ld	s1,56(sp)
    80204eb0:	7942                	ld	s2,48(sp)
    80204eb2:	79a2                	ld	s3,40(sp)
    80204eb4:	7a02                	ld	s4,32(sp)
    80204eb6:	6ae2                	ld	s5,24(sp)
    80204eb8:	6b42                	ld	s6,16(sp)
    80204eba:	6ba2                	ld	s7,8(sp)
    80204ebc:	bf8d                	j	80204e2e <ialloc+0x9c>

0000000080204ebe <iupdate>:
{
    80204ebe:	1101                	addi	sp,sp,-32
    80204ec0:	ec06                	sd	ra,24(sp)
    80204ec2:	e822                	sd	s0,16(sp)
    80204ec4:	e426                	sd	s1,8(sp)
    80204ec6:	e04a                	sd	s2,0(sp)
    80204ec8:	1000                	addi	s0,sp,32
    80204eca:	84aa                	mv	s1,a0
    struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80204ecc:	415c                	lw	a5,4(a0)
    80204ece:	0047d79b          	srliw	a5,a5,0x4
    80204ed2:	00134597          	auipc	a1,0x134
    80204ed6:	2ca5a583          	lw	a1,714(a1) # 8033919c <sb+0x1c>
    80204eda:	9dbd                	addw	a1,a1,a5
    80204edc:	4108                	lw	a0,0(a0)
    80204ede:	00000097          	auipc	ra,0x0
    80204ee2:	8ae080e7          	jalr	-1874(ra) # 8020478c <bread>
    80204ee6:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + ip->inum % IPB;
    80204ee8:	05850793          	addi	a5,a0,88
    80204eec:	40d8                	lw	a4,4(s1)
    80204eee:	8b3d                	andi	a4,a4,15
    80204ef0:	071a                	slli	a4,a4,0x6
    80204ef2:	97ba                	add	a5,a5,a4
    dip->type  = ip->type;
    80204ef4:	0444d703          	lhu	a4,68(s1)
    80204ef8:	00e79023          	sh	a4,0(a5)
    dip->major = ip->major;
    80204efc:	0464d703          	lhu	a4,70(s1)
    80204f00:	00e79123          	sh	a4,2(a5)
    dip->minor = ip->minor;
    80204f04:	0484d703          	lhu	a4,72(s1)
    80204f08:	00e79223          	sh	a4,4(a5)
    dip->nlink = ip->nlink;
    80204f0c:	04a4d703          	lhu	a4,74(s1)
    80204f10:	00e79323          	sh	a4,6(a5)
    dip->size  = ip->size;
    80204f14:	44f8                	lw	a4,76(s1)
    80204f16:	c798                	sw	a4,8(a5)
    memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80204f18:	03400613          	li	a2,52
    80204f1c:	05048593          	addi	a1,s1,80
    80204f20:	00c78513          	addi	a0,a5,12
    80204f24:	ffffb097          	auipc	ra,0xffffb
    80204f28:	752080e7          	jalr	1874(ra) # 80200676 <memmove>
    bwrite(bp);
    80204f2c:	854a                	mv	a0,s2
    80204f2e:	00000097          	auipc	ra,0x0
    80204f32:	950080e7          	jalr	-1712(ra) # 8020487e <bwrite>
    brelse(bp);
    80204f36:	854a                	mv	a0,s2
    80204f38:	00000097          	auipc	ra,0x0
    80204f3c:	984080e7          	jalr	-1660(ra) # 802048bc <brelse>
}
    80204f40:	60e2                	ld	ra,24(sp)
    80204f42:	6442                	ld	s0,16(sp)
    80204f44:	64a2                	ld	s1,8(sp)
    80204f46:	6902                	ld	s2,0(sp)
    80204f48:	6105                	addi	sp,sp,32
    80204f4a:	8082                	ret

0000000080204f4c <idup>:
{
    80204f4c:	1101                	addi	sp,sp,-32
    80204f4e:	ec06                	sd	ra,24(sp)
    80204f50:	e822                	sd	s0,16(sp)
    80204f52:	e426                	sd	s1,8(sp)
    80204f54:	1000                	addi	s0,sp,32
    80204f56:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    80204f58:	00134517          	auipc	a0,0x134
    80204f5c:	25050513          	addi	a0,a0,592 # 803391a8 <icache>
    80204f60:	ffffc097          	auipc	ra,0xffffc
    80204f64:	3a0080e7          	jalr	928(ra) # 80201300 <acquire>
    ip->ref++;
    80204f68:	449c                	lw	a5,8(s1)
    80204f6a:	2785                	addiw	a5,a5,1
    80204f6c:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    80204f6e:	00134517          	auipc	a0,0x134
    80204f72:	23a50513          	addi	a0,a0,570 # 803391a8 <icache>
    80204f76:	ffffc097          	auipc	ra,0xffffc
    80204f7a:	43a080e7          	jalr	1082(ra) # 802013b0 <release>
}
    80204f7e:	8526                	mv	a0,s1
    80204f80:	60e2                	ld	ra,24(sp)
    80204f82:	6442                	ld	s0,16(sp)
    80204f84:	64a2                	ld	s1,8(sp)
    80204f86:	6105                	addi	sp,sp,32
    80204f88:	8082                	ret

0000000080204f8a <ilock>:
{
    80204f8a:	1101                	addi	sp,sp,-32
    80204f8c:	ec06                	sd	ra,24(sp)
    80204f8e:	e822                	sd	s0,16(sp)
    80204f90:	e426                	sd	s1,8(sp)
    80204f92:	1000                	addi	s0,sp,32
    if (ip == 0 || ip->ref < 1) panic("ilock");
    80204f94:	c10d                	beqz	a0,80204fb6 <ilock+0x2c>
    80204f96:	84aa                	mv	s1,a0
    80204f98:	451c                	lw	a5,8(a0)
    80204f9a:	00f05e63          	blez	a5,80204fb6 <ilock+0x2c>
    acquiresleep(&ip->lock);
    80204f9e:	0541                	addi	a0,a0,16
    80204fa0:	ffffc097          	auipc	ra,0xffffc
    80204fa4:	492080e7          	jalr	1170(ra) # 80201432 <acquiresleep>
    if (!ip->valid) {
    80204fa8:	40bc                	lw	a5,64(s1)
    80204faa:	cf99                	beqz	a5,80204fc8 <ilock+0x3e>
}
    80204fac:	60e2                	ld	ra,24(sp)
    80204fae:	6442                	ld	s0,16(sp)
    80204fb0:	64a2                	ld	s1,8(sp)
    80204fb2:	6105                	addi	sp,sp,32
    80204fb4:	8082                	ret
    80204fb6:	e04a                	sd	s2,0(sp)
    if (ip == 0 || ip->ref < 1) panic("ilock");
    80204fb8:	00003517          	auipc	a0,0x3
    80204fbc:	b7050513          	addi	a0,a0,-1168 # 80207b28 <etext+0xb28>
    80204fc0:	ffffb097          	auipc	ra,0xffffb
    80204fc4:	5f0080e7          	jalr	1520(ra) # 802005b0 <panic>
    80204fc8:	e04a                	sd	s2,0(sp)
        struct buf *bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80204fca:	40dc                	lw	a5,4(s1)
    80204fcc:	0047d79b          	srliw	a5,a5,0x4
    80204fd0:	00134597          	auipc	a1,0x134
    80204fd4:	1cc5a583          	lw	a1,460(a1) # 8033919c <sb+0x1c>
    80204fd8:	9dbd                	addw	a1,a1,a5
    80204fda:	4088                	lw	a0,0(s1)
    80204fdc:	fffff097          	auipc	ra,0xfffff
    80204fe0:	7b0080e7          	jalr	1968(ra) # 8020478c <bread>
    80204fe4:	892a                	mv	s2,a0
        struct dinode *dip = (struct dinode *)bp->data + ip->inum % IPB;
    80204fe6:	05850593          	addi	a1,a0,88
    80204fea:	40dc                	lw	a5,4(s1)
    80204fec:	8bbd                	andi	a5,a5,15
    80204fee:	079a                	slli	a5,a5,0x6
    80204ff0:	95be                	add	a1,a1,a5
        ip->type  = dip->type;
    80204ff2:	0005d783          	lhu	a5,0(a1)
    80204ff6:	04f49223          	sh	a5,68(s1)
        ip->major = dip->major;
    80204ffa:	0025d783          	lhu	a5,2(a1)
    80204ffe:	04f49323          	sh	a5,70(s1)
        ip->minor = dip->minor;
    80205002:	0045d783          	lhu	a5,4(a1)
    80205006:	04f49423          	sh	a5,72(s1)
        ip->nlink = dip->nlink;
    8020500a:	0065d783          	lhu	a5,6(a1)
    8020500e:	04f49523          	sh	a5,74(s1)
        ip->size  = dip->size;
    80205012:	459c                	lw	a5,8(a1)
    80205014:	c4fc                	sw	a5,76(s1)
        memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80205016:	03400613          	li	a2,52
    8020501a:	05b1                	addi	a1,a1,12
    8020501c:	05048513          	addi	a0,s1,80
    80205020:	ffffb097          	auipc	ra,0xffffb
    80205024:	656080e7          	jalr	1622(ra) # 80200676 <memmove>
        brelse(bp);
    80205028:	854a                	mv	a0,s2
    8020502a:	00000097          	auipc	ra,0x0
    8020502e:	892080e7          	jalr	-1902(ra) # 802048bc <brelse>
        ip->valid = 1;
    80205032:	4785                	li	a5,1
    80205034:	c0bc                	sw	a5,64(s1)
        if (ip->type == 0) panic("ilock: inode has no type (bitmap out of sync)");
    80205036:	0444d783          	lhu	a5,68(s1)
    8020503a:	c399                	beqz	a5,80205040 <ilock+0xb6>
    8020503c:	6902                	ld	s2,0(sp)
    8020503e:	b7bd                	j	80204fac <ilock+0x22>
    80205040:	00003517          	auipc	a0,0x3
    80205044:	af050513          	addi	a0,a0,-1296 # 80207b30 <etext+0xb30>
    80205048:	ffffb097          	auipc	ra,0xffffb
    8020504c:	568080e7          	jalr	1384(ra) # 802005b0 <panic>

0000000080205050 <iunlock>:
{
    80205050:	1101                	addi	sp,sp,-32
    80205052:	ec06                	sd	ra,24(sp)
    80205054:	e822                	sd	s0,16(sp)
    80205056:	e426                	sd	s1,8(sp)
    80205058:	e04a                	sd	s2,0(sp)
    8020505a:	1000                	addi	s0,sp,32
    if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1) panic("iunlock");
    8020505c:	c905                	beqz	a0,8020508c <iunlock+0x3c>
    8020505e:	84aa                	mv	s1,a0
    80205060:	01050913          	addi	s2,a0,16
    80205064:	854a                	mv	a0,s2
    80205066:	ffffc097          	auipc	ra,0xffffc
    8020506a:	466080e7          	jalr	1126(ra) # 802014cc <holdingsleep>
    8020506e:	cd19                	beqz	a0,8020508c <iunlock+0x3c>
    80205070:	449c                	lw	a5,8(s1)
    80205072:	00f05d63          	blez	a5,8020508c <iunlock+0x3c>
    releasesleep(&ip->lock);
    80205076:	854a                	mv	a0,s2
    80205078:	ffffc097          	auipc	ra,0xffffc
    8020507c:	410080e7          	jalr	1040(ra) # 80201488 <releasesleep>
}
    80205080:	60e2                	ld	ra,24(sp)
    80205082:	6442                	ld	s0,16(sp)
    80205084:	64a2                	ld	s1,8(sp)
    80205086:	6902                	ld	s2,0(sp)
    80205088:	6105                	addi	sp,sp,32
    8020508a:	8082                	ret
    if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1) panic("iunlock");
    8020508c:	00003517          	auipc	a0,0x3
    80205090:	ad450513          	addi	a0,a0,-1324 # 80207b60 <etext+0xb60>
    80205094:	ffffb097          	auipc	ra,0xffffb
    80205098:	51c080e7          	jalr	1308(ra) # 802005b0 <panic>

000000008020509c <itrunc>:

/* Free all data blocks of ip and set size 0. Caller holds ip->lock. */
void itrunc(struct inode *ip)
{
    8020509c:	7179                	addi	sp,sp,-48
    8020509e:	f406                	sd	ra,40(sp)
    802050a0:	f022                	sd	s0,32(sp)
    802050a2:	ec26                	sd	s1,24(sp)
    802050a4:	e84a                	sd	s2,16(sp)
    802050a6:	e44e                	sd	s3,8(sp)
    802050a8:	1800                	addi	s0,sp,48
    802050aa:	89aa                	mv	s3,a0
    for (int i = 0; i < NDIRECT; i++) {
    802050ac:	05050493          	addi	s1,a0,80
    802050b0:	08050913          	addi	s2,a0,128
    802050b4:	a021                	j	802050bc <itrunc+0x20>
    802050b6:	0491                	addi	s1,s1,4
    802050b8:	01248d63          	beq	s1,s2,802050d2 <itrunc+0x36>
        if (ip->addrs[i]) { bfree(ip->dev, ip->addrs[i]); ip->addrs[i] = 0; }
    802050bc:	408c                	lw	a1,0(s1)
    802050be:	dde5                	beqz	a1,802050b6 <itrunc+0x1a>
    802050c0:	0009a503          	lw	a0,0(s3)
    802050c4:	00000097          	auipc	ra,0x0
    802050c8:	890080e7          	jalr	-1904(ra) # 80204954 <bfree>
    802050cc:	0004a023          	sw	zero,0(s1)
    802050d0:	b7dd                	j	802050b6 <itrunc+0x1a>
    }
    if (ip->addrs[NDIRECT]) {
    802050d2:	0809a583          	lw	a1,128(s3)
    802050d6:	ed99                	bnez	a1,802050f4 <itrunc+0x58>
            if (a[j]) bfree(ip->dev, a[j]);
        brelse(bp);
        bfree(ip->dev, ip->addrs[NDIRECT]);
        ip->addrs[NDIRECT] = 0;
    }
    ip->size = 0;
    802050d8:	0409a623          	sw	zero,76(s3)
    iupdate(ip);
    802050dc:	854e                	mv	a0,s3
    802050de:	00000097          	auipc	ra,0x0
    802050e2:	de0080e7          	jalr	-544(ra) # 80204ebe <iupdate>
}
    802050e6:	70a2                	ld	ra,40(sp)
    802050e8:	7402                	ld	s0,32(sp)
    802050ea:	64e2                	ld	s1,24(sp)
    802050ec:	6942                	ld	s2,16(sp)
    802050ee:	69a2                	ld	s3,8(sp)
    802050f0:	6145                	addi	sp,sp,48
    802050f2:	8082                	ret
    802050f4:	e052                	sd	s4,0(sp)
        struct buf *bp = bread(ip->dev, ip->addrs[NDIRECT]);
    802050f6:	0009a503          	lw	a0,0(s3)
    802050fa:	fffff097          	auipc	ra,0xfffff
    802050fe:	692080e7          	jalr	1682(ra) # 8020478c <bread>
    80205102:	8a2a                	mv	s4,a0
        for (uint32 j = 0; j < NINDIRECT; j++)
    80205104:	05850493          	addi	s1,a0,88
    80205108:	45850913          	addi	s2,a0,1112
    8020510c:	a021                	j	80205114 <itrunc+0x78>
    8020510e:	0491                	addi	s1,s1,4
    80205110:	01248b63          	beq	s1,s2,80205126 <itrunc+0x8a>
            if (a[j]) bfree(ip->dev, a[j]);
    80205114:	408c                	lw	a1,0(s1)
    80205116:	dde5                	beqz	a1,8020510e <itrunc+0x72>
    80205118:	0009a503          	lw	a0,0(s3)
    8020511c:	00000097          	auipc	ra,0x0
    80205120:	838080e7          	jalr	-1992(ra) # 80204954 <bfree>
    80205124:	b7ed                	j	8020510e <itrunc+0x72>
        brelse(bp);
    80205126:	8552                	mv	a0,s4
    80205128:	fffff097          	auipc	ra,0xfffff
    8020512c:	794080e7          	jalr	1940(ra) # 802048bc <brelse>
        bfree(ip->dev, ip->addrs[NDIRECT]);
    80205130:	0809a583          	lw	a1,128(s3)
    80205134:	0009a503          	lw	a0,0(s3)
    80205138:	00000097          	auipc	ra,0x0
    8020513c:	81c080e7          	jalr	-2020(ra) # 80204954 <bfree>
        ip->addrs[NDIRECT] = 0;
    80205140:	0809a023          	sw	zero,128(s3)
    80205144:	6a02                	ld	s4,0(sp)
    80205146:	bf49                	j	802050d8 <itrunc+0x3c>

0000000080205148 <iput>:
{
    80205148:	7179                	addi	sp,sp,-48
    8020514a:	f406                	sd	ra,40(sp)
    8020514c:	f022                	sd	s0,32(sp)
    8020514e:	ec26                	sd	s1,24(sp)
    80205150:	1800                	addi	s0,sp,48
    80205152:	84aa                	mv	s1,a0
    acquire(&icache.lock);
    80205154:	00134517          	auipc	a0,0x134
    80205158:	05450513          	addi	a0,a0,84 # 803391a8 <icache>
    8020515c:	ffffc097          	auipc	ra,0xffffc
    80205160:	1a4080e7          	jalr	420(ra) # 80201300 <acquire>
    if (ip->ref == 1 && ip->valid && ip->nlink == 0) {
    80205164:	4498                	lw	a4,8(s1)
    80205166:	4785                	li	a5,1
    80205168:	00f71763          	bne	a4,a5,80205176 <iput+0x2e>
    8020516c:	40bc                	lw	a5,64(s1)
    8020516e:	c781                	beqz	a5,80205176 <iput+0x2e>
    80205170:	04a4d783          	lhu	a5,74(s1)
    80205174:	c38d                	beqz	a5,80205196 <iput+0x4e>
    ip->ref--;
    80205176:	449c                	lw	a5,8(s1)
    80205178:	37fd                	addiw	a5,a5,-1
    8020517a:	c49c                	sw	a5,8(s1)
    release(&icache.lock);
    8020517c:	00134517          	auipc	a0,0x134
    80205180:	02c50513          	addi	a0,a0,44 # 803391a8 <icache>
    80205184:	ffffc097          	auipc	ra,0xffffc
    80205188:	22c080e7          	jalr	556(ra) # 802013b0 <release>
}
    8020518c:	70a2                	ld	ra,40(sp)
    8020518e:	7402                	ld	s0,32(sp)
    80205190:	64e2                	ld	s1,24(sp)
    80205192:	6145                	addi	sp,sp,48
    80205194:	8082                	ret
    80205196:	e84a                	sd	s2,16(sp)
    80205198:	e44e                	sd	s3,8(sp)
        acquiresleep(&ip->lock);
    8020519a:	01048993          	addi	s3,s1,16
    8020519e:	854e                	mv	a0,s3
    802051a0:	ffffc097          	auipc	ra,0xffffc
    802051a4:	292080e7          	jalr	658(ra) # 80201432 <acquiresleep>
        release(&icache.lock);
    802051a8:	00134517          	auipc	a0,0x134
    802051ac:	00050513          	mv	a0,a0
    802051b0:	ffffc097          	auipc	ra,0xffffc
    802051b4:	200080e7          	jalr	512(ra) # 802013b0 <release>
        itrunc(ip);
    802051b8:	8526                	mv	a0,s1
    802051ba:	00000097          	auipc	ra,0x0
    802051be:	ee2080e7          	jalr	-286(ra) # 8020509c <itrunc>
        ip->type = 0;
    802051c2:	04049223          	sh	zero,68(s1)
        iupdate(ip);
    802051c6:	8526                	mv	a0,s1
    802051c8:	00000097          	auipc	ra,0x0
    802051cc:	cf6080e7          	jalr	-778(ra) # 80204ebe <iupdate>
        struct buf *bp = bread(ip->dev, IBBLOCK(ip->inum, sb));
    802051d0:	40dc                	lw	a5,4(s1)
    802051d2:	00d7d79b          	srliw	a5,a5,0xd
    802051d6:	00134597          	auipc	a1,0x134
    802051da:	fbe5a583          	lw	a1,-66(a1) # 80339194 <sb+0x14>
    802051de:	9dbd                	addw	a1,a1,a5
    802051e0:	4088                	lw	a0,0(s1)
    802051e2:	fffff097          	auipc	ra,0xfffff
    802051e6:	5aa080e7          	jalr	1450(ra) # 8020478c <bread>
    802051ea:	892a                	mv	s2,a0
        uint32 bi = ip->inum % BPB;
    802051ec:	40d4                	lw	a3,4(s1)
    802051ee:	03369793          	slli	a5,a3,0x33
    802051f2:	0337d713          	srli	a4,a5,0x33
        if ((bp->data[bi / 8] & (1 << (bi % 8))) == 0)
    802051f6:	93d9                	srli	a5,a5,0x36
    802051f8:	97aa                	add	a5,a5,a0
    802051fa:	0587c603          	lbu	a2,88(a5)
    802051fe:	8a9d                	andi	a3,a3,7
    80205200:	40d657bb          	sraw	a5,a2,a3
    80205204:	8b85                	andi	a5,a5,1
    80205206:	c7b9                	beqz	a5,80205254 <iput+0x10c>
        bp->data[bi / 8] &= ~(1 << (bi % 8));
    80205208:	0037579b          	srliw	a5,a4,0x3
    8020520c:	97aa                	add	a5,a5,a0
    8020520e:	4705                	li	a4,1
    80205210:	00d7173b          	sllw	a4,a4,a3
    80205214:	fff74713          	not	a4,a4
    80205218:	8e79                	and	a2,a2,a4
    8020521a:	04c78c23          	sb	a2,88(a5)
        bwrite(bp);
    8020521e:	fffff097          	auipc	ra,0xfffff
    80205222:	660080e7          	jalr	1632(ra) # 8020487e <bwrite>
        brelse(bp);
    80205226:	854a                	mv	a0,s2
    80205228:	fffff097          	auipc	ra,0xfffff
    8020522c:	694080e7          	jalr	1684(ra) # 802048bc <brelse>
        ip->valid = 0;
    80205230:	0404a023          	sw	zero,64(s1)
        releasesleep(&ip->lock);
    80205234:	854e                	mv	a0,s3
    80205236:	ffffc097          	auipc	ra,0xffffc
    8020523a:	252080e7          	jalr	594(ra) # 80201488 <releasesleep>
        acquire(&icache.lock);
    8020523e:	00134517          	auipc	a0,0x134
    80205242:	f6a50513          	addi	a0,a0,-150 # 803391a8 <icache>
    80205246:	ffffc097          	auipc	ra,0xffffc
    8020524a:	0ba080e7          	jalr	186(ra) # 80201300 <acquire>
    8020524e:	6942                	ld	s2,16(sp)
    80205250:	69a2                	ld	s3,8(sp)
    80205252:	b715                	j	80205176 <iput+0x2e>
            panic("iput: inode bitmap already clear");
    80205254:	00003517          	auipc	a0,0x3
    80205258:	91450513          	addi	a0,a0,-1772 # 80207b68 <etext+0xb68>
    8020525c:	ffffb097          	auipc	ra,0xffffb
    80205260:	354080e7          	jalr	852(ra) # 802005b0 <panic>

0000000080205264 <iunlockput>:
void iunlockput(struct inode *ip) { iunlock(ip); iput(ip); }
    80205264:	1101                	addi	sp,sp,-32
    80205266:	ec06                	sd	ra,24(sp)
    80205268:	e822                	sd	s0,16(sp)
    8020526a:	e426                	sd	s1,8(sp)
    8020526c:	1000                	addi	s0,sp,32
    8020526e:	84aa                	mv	s1,a0
    80205270:	00000097          	auipc	ra,0x0
    80205274:	de0080e7          	jalr	-544(ra) # 80205050 <iunlock>
    80205278:	8526                	mv	a0,s1
    8020527a:	00000097          	auipc	ra,0x0
    8020527e:	ece080e7          	jalr	-306(ra) # 80205148 <iput>
    80205282:	60e2                	ld	ra,24(sp)
    80205284:	6442                	ld	s0,16(sp)
    80205286:	64a2                	ld	s1,8(sp)
    80205288:	6105                	addi	sp,sp,32
    8020528a:	8082                	ret

000000008020528c <stati>:

void stati(struct inode *ip, struct stat *st)
{
    8020528c:	1141                	addi	sp,sp,-16
    8020528e:	e406                	sd	ra,8(sp)
    80205290:	e022                	sd	s0,0(sp)
    80205292:	0800                	addi	s0,sp,16
    st->dev   = ip->dev;
    80205294:	411c                	lw	a5,0(a0)
    80205296:	c19c                	sw	a5,0(a1)
    st->ino   = ip->inum;
    80205298:	415c                	lw	a5,4(a0)
    8020529a:	c1dc                	sw	a5,4(a1)
    st->type  = ip->type;
    8020529c:	04455783          	lhu	a5,68(a0)
    802052a0:	00f59423          	sh	a5,8(a1)
    st->nlink = ip->nlink;
    802052a4:	04a55783          	lhu	a5,74(a0)
    802052a8:	00f59523          	sh	a5,10(a1)
    st->size  = ip->size;
    802052ac:	04c56783          	lwu	a5,76(a0)
    802052b0:	e99c                	sd	a5,16(a1)
}
    802052b2:	60a2                	ld	ra,8(sp)
    802052b4:	6402                	ld	s0,0(sp)
    802052b6:	0141                	addi	sp,sp,16
    802052b8:	8082                	ret

00000000802052ba <readi>:

/* Read n bytes at offset off into dst (user va if user_dst, else kernel).
 * Returns bytes read, or -1. Caller holds ip->lock. */
int readi(struct inode *ip, int user_dst, uint64 dst, uint32 off, uint32 n)
{
    if (off > ip->size || off + n < off) return 0;
    802052ba:	457c                	lw	a5,76(a0)
    802052bc:	12d7e163          	bltu	a5,a3,802053de <readi+0x124>
{
    802052c0:	7159                	addi	sp,sp,-112
    802052c2:	f486                	sd	ra,104(sp)
    802052c4:	f0a2                	sd	s0,96(sp)
    802052c6:	e8ca                	sd	s2,80(sp)
    802052c8:	e0d2                	sd	s4,64(sp)
    802052ca:	fc56                	sd	s5,56(sp)
    802052cc:	f85a                	sd	s6,48(sp)
    802052ce:	f45e                	sd	s7,40(sp)
    802052d0:	1880                	addi	s0,sp,112
    802052d2:	8b2a                	mv	s6,a0
    802052d4:	8bae                	mv	s7,a1
    802052d6:	8a32                	mv	s4,a2
    802052d8:	8936                	mv	s2,a3
    802052da:	8aba                	mv	s5,a4
    if (off > ip->size || off + n < off) return 0;
    802052dc:	9f35                	addw	a4,a4,a3
    802052de:	4501                	li	a0,0
    802052e0:	0ed76663          	bltu	a4,a3,802053cc <readi+0x112>
    802052e4:	e4ce                	sd	s3,72(sp)
    if (off + n > ip->size) n = ip->size - off;
    802052e6:	00e7f463          	bgeu	a5,a4,802052ee <readi+0x34>
    802052ea:	40d78abb          	subw	s5,a5,a3

    uint32 tot, m;
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    802052ee:	0c0a8663          	beqz	s5,802053ba <readi+0x100>
    802052f2:	eca6                	sd	s1,88(sp)
    802052f4:	f062                	sd	s8,32(sp)
    802052f6:	ec66                	sd	s9,24(sp)
    802052f8:	e86a                	sd	s10,16(sp)
    802052fa:	e46e                	sd	s11,8(sp)
    802052fc:	4981                	li	s3,0
        uint32 addr = bmap(ip, off / BSIZE);
        if (addr == 0) break;
        struct buf *bp = bread(ip->dev, addr);
        m = BSIZE - off % BSIZE;
    802052fe:	40000c13          	li	s8,1024
    80205302:	a815                	j	80205336 <readi+0x7c>
                brelse(bp);
                tot = -1;
                break;
            }
        } else {
            memmove((void *)dst, bp->data + off % BSIZE, m);
    80205304:	058c8593          	addi	a1,s9,88
    80205308:	020d1613          	slli	a2,s10,0x20
    8020530c:	9201                	srli	a2,a2,0x20
    8020530e:	95ee                	add	a1,a1,s11
    80205310:	8552                	mv	a0,s4
    80205312:	ffffb097          	auipc	ra,0xffffb
    80205316:	364080e7          	jalr	868(ra) # 80200676 <memmove>
        }
        brelse(bp);
    8020531a:	8566                	mv	a0,s9
    8020531c:	fffff097          	auipc	ra,0xfffff
    80205320:	5a0080e7          	jalr	1440(ra) # 802048bc <brelse>
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    80205324:	013489bb          	addw	s3,s1,s3
    80205328:	0124893b          	addw	s2,s1,s2
    8020532c:	1482                	slli	s1,s1,0x20
    8020532e:	9081                	srli	s1,s1,0x20
    80205330:	9a26                	add	s4,s4,s1
    80205332:	0759fe63          	bgeu	s3,s5,802053ae <readi+0xf4>
        uint32 addr = bmap(ip, off / BSIZE);
    80205336:	00a9559b          	srliw	a1,s2,0xa
    8020533a:	855a                	mv	a0,s6
    8020533c:	fffff097          	auipc	ra,0xfffff
    80205340:	7ba080e7          	jalr	1978(ra) # 80204af6 <bmap>
    80205344:	85aa                	mv	a1,a0
        if (addr == 0) break;
    80205346:	cd25                	beqz	a0,802053be <readi+0x104>
        struct buf *bp = bread(ip->dev, addr);
    80205348:	000b2503          	lw	a0,0(s6) # 2000 <_entry-0x801fe000>
    8020534c:	fffff097          	auipc	ra,0xfffff
    80205350:	440080e7          	jalr	1088(ra) # 8020478c <bread>
    80205354:	8caa                	mv	s9,a0
        m = BSIZE - off % BSIZE;
    80205356:	3ff97d93          	andi	s11,s2,1023
        if (m > n - tot) m = n - tot;
    8020535a:	413a87bb          	subw	a5,s5,s3
        m = BSIZE - off % BSIZE;
    8020535e:	41bc073b          	subw	a4,s8,s11
        if (m > n - tot) m = n - tot;
    80205362:	8d3e                	mv	s10,a5
    80205364:	00f77363          	bgeu	a4,a5,8020536a <readi+0xb0>
    80205368:	8d3a                	mv	s10,a4
    8020536a:	000d049b          	sext.w	s1,s10
        if (user_dst) {
    8020536e:	f80b8be3          	beqz	s7,80205304 <readi+0x4a>
            if (copyout(myproc()->pagetable, dst,
    80205372:	ffffc097          	auipc	ra,0xffffc
    80205376:	36c080e7          	jalr	876(ra) # 802016de <myproc>
                        (char *)bp->data + off % BSIZE, m) < 0) {
    8020537a:	058c8613          	addi	a2,s9,88
            if (copyout(myproc()->pagetable, dst,
    8020537e:	020d1693          	slli	a3,s10,0x20
    80205382:	9281                	srli	a3,a3,0x20
    80205384:	966e                	add	a2,a2,s11
    80205386:	85d2                	mv	a1,s4
    80205388:	6928                	ld	a0,80(a0)
    8020538a:	ffffe097          	auipc	ra,0xffffe
    8020538e:	b54080e7          	jalr	-1196(ra) # 80202ede <copyout>
    80205392:	f80554e3          	bgez	a0,8020531a <readi+0x60>
                brelse(bp);
    80205396:	8566                	mv	a0,s9
    80205398:	fffff097          	auipc	ra,0xfffff
    8020539c:	524080e7          	jalr	1316(ra) # 802048bc <brelse>
                tot = -1;
    802053a0:	59fd                	li	s3,-1
                break;
    802053a2:	64e6                	ld	s1,88(sp)
    802053a4:	7c02                	ld	s8,32(sp)
    802053a6:	6ce2                	ld	s9,24(sp)
    802053a8:	6d42                	ld	s10,16(sp)
    802053aa:	6da2                	ld	s11,8(sp)
    802053ac:	a831                	j	802053c8 <readi+0x10e>
    802053ae:	64e6                	ld	s1,88(sp)
    802053b0:	7c02                	ld	s8,32(sp)
    802053b2:	6ce2                	ld	s9,24(sp)
    802053b4:	6d42                	ld	s10,16(sp)
    802053b6:	6da2                	ld	s11,8(sp)
    802053b8:	a801                	j	802053c8 <readi+0x10e>
    for (tot = 0; tot < n; tot += m, off += m, dst += m) {
    802053ba:	89d6                	mv	s3,s5
    802053bc:	a031                	j	802053c8 <readi+0x10e>
    802053be:	64e6                	ld	s1,88(sp)
    802053c0:	7c02                	ld	s8,32(sp)
    802053c2:	6ce2                	ld	s9,24(sp)
    802053c4:	6d42                	ld	s10,16(sp)
    802053c6:	6da2                	ld	s11,8(sp)
    }
    return tot;
    802053c8:	854e                	mv	a0,s3
    802053ca:	69a6                	ld	s3,72(sp)
}
    802053cc:	70a6                	ld	ra,104(sp)
    802053ce:	7406                	ld	s0,96(sp)
    802053d0:	6946                	ld	s2,80(sp)
    802053d2:	6a06                	ld	s4,64(sp)
    802053d4:	7ae2                	ld	s5,56(sp)
    802053d6:	7b42                	ld	s6,48(sp)
    802053d8:	7ba2                	ld	s7,40(sp)
    802053da:	6165                	addi	sp,sp,112
    802053dc:	8082                	ret
    if (off > ip->size || off + n < off) return 0;
    802053de:	4501                	li	a0,0
}
    802053e0:	8082                	ret

00000000802053e2 <writei>:

/* Write n bytes at off from src. Grows the file if needed. Caller holds lock. */
int writei(struct inode *ip, int user_src, uint64 src, uint32 off, uint32 n)
{
    if (off > ip->size || off + n < off) return -1;
    802053e2:	457c                	lw	a5,76(a0)
    802053e4:	12d7eb63          	bltu	a5,a3,8020551a <writei+0x138>
{
    802053e8:	7159                	addi	sp,sp,-112
    802053ea:	f486                	sd	ra,104(sp)
    802053ec:	f0a2                	sd	s0,96(sp)
    802053ee:	e4ce                	sd	s3,72(sp)
    802053f0:	fc56                	sd	s5,56(sp)
    802053f2:	f85a                	sd	s6,48(sp)
    802053f4:	f45e                	sd	s7,40(sp)
    802053f6:	f062                	sd	s8,32(sp)
    802053f8:	1880                	addi	s0,sp,112
    802053fa:	8b2a                	mv	s6,a0
    802053fc:	8c2e                	mv	s8,a1
    802053fe:	8ab2                	mv	s5,a2
    80205400:	89b6                	mv	s3,a3
    80205402:	8bba                	mv	s7,a4
    if (off > ip->size || off + n < off) return -1;
    80205404:	00e687bb          	addw	a5,a3,a4
    80205408:	10d7eb63          	bltu	a5,a3,8020551e <writei+0x13c>
    if (off + n > MAXFILE * BSIZE) return -1;
    8020540c:	00043737          	lui	a4,0x43
    80205410:	10f76963          	bltu	a4,a5,80205522 <writei+0x140>
    80205414:	e0d2                	sd	s4,64(sp)

    uint32 tot, m;
    for (tot = 0; tot < n; tot += m, off += m, src += m) {
    80205416:	0e0b8a63          	beqz	s7,8020550a <writei+0x128>
    8020541a:	eca6                	sd	s1,88(sp)
    8020541c:	e8ca                	sd	s2,80(sp)
    8020541e:	ec66                	sd	s9,24(sp)
    80205420:	e86a                	sd	s10,16(sp)
    80205422:	e46e                	sd	s11,8(sp)
    80205424:	4a01                	li	s4,0
        uint32 addr = bmap(ip, off / BSIZE);
        if (addr == 0) break;                     /* disk full: partial write */
        struct buf *bp = bread(ip->dev, addr);
        m = BSIZE - off % BSIZE;
    80205426:	40000c93          	li	s9,1024
    8020542a:	a081                	j	8020546a <writei+0x88>
                       (char *)bp->data + off % BSIZE, src, m) < 0) {
                brelse(bp);
                break;
            }
        } else {
            memmove(bp->data + off % BSIZE, (void *)src, m);
    8020542c:	05848513          	addi	a0,s1,88
    80205430:	020d1613          	slli	a2,s10,0x20
    80205434:	9201                	srli	a2,a2,0x20
    80205436:	85d6                	mv	a1,s5
    80205438:	956e                	add	a0,a0,s11
    8020543a:	ffffb097          	auipc	ra,0xffffb
    8020543e:	23c080e7          	jalr	572(ra) # 80200676 <memmove>
        }
        bwrite(bp);
    80205442:	8526                	mv	a0,s1
    80205444:	fffff097          	auipc	ra,0xfffff
    80205448:	43a080e7          	jalr	1082(ra) # 8020487e <bwrite>
        brelse(bp);
    8020544c:	8526                	mv	a0,s1
    8020544e:	fffff097          	auipc	ra,0xfffff
    80205452:	46e080e7          	jalr	1134(ra) # 802048bc <brelse>
    for (tot = 0; tot < n; tot += m, off += m, src += m) {
    80205456:	01490a3b          	addw	s4,s2,s4
    8020545a:	013909bb          	addw	s3,s2,s3
    8020545e:	1902                	slli	s2,s2,0x20
    80205460:	02095913          	srli	s2,s2,0x20
    80205464:	9aca                	add	s5,s5,s2
    80205466:	077a7763          	bgeu	s4,s7,802054d4 <writei+0xf2>
        uint32 addr = bmap(ip, off / BSIZE);
    8020546a:	00a9d59b          	srliw	a1,s3,0xa
    8020546e:	855a                	mv	a0,s6
    80205470:	fffff097          	auipc	ra,0xfffff
    80205474:	686080e7          	jalr	1670(ra) # 80204af6 <bmap>
    80205478:	85aa                	mv	a1,a0
        if (addr == 0) break;                     /* disk full: partial write */
    8020547a:	cd29                	beqz	a0,802054d4 <writei+0xf2>
        struct buf *bp = bread(ip->dev, addr);
    8020547c:	000b2503          	lw	a0,0(s6)
    80205480:	fffff097          	auipc	ra,0xfffff
    80205484:	30c080e7          	jalr	780(ra) # 8020478c <bread>
    80205488:	84aa                	mv	s1,a0
        m = BSIZE - off % BSIZE;
    8020548a:	3ff9fd93          	andi	s11,s3,1023
        if (m > n - tot) m = n - tot;
    8020548e:	414b87bb          	subw	a5,s7,s4
        m = BSIZE - off % BSIZE;
    80205492:	41bc873b          	subw	a4,s9,s11
        if (m > n - tot) m = n - tot;
    80205496:	8d3e                	mv	s10,a5
    80205498:	00f77363          	bgeu	a4,a5,8020549e <writei+0xbc>
    8020549c:	8d3a                	mv	s10,a4
    8020549e:	000d091b          	sext.w	s2,s10
        if (user_src) {
    802054a2:	f80c05e3          	beqz	s8,8020542c <writei+0x4a>
            if (copyin(myproc()->pagetable,
    802054a6:	ffffc097          	auipc	ra,0xffffc
    802054aa:	238080e7          	jalr	568(ra) # 802016de <myproc>
                       (char *)bp->data + off % BSIZE, src, m) < 0) {
    802054ae:	05848593          	addi	a1,s1,88
            if (copyin(myproc()->pagetable,
    802054b2:	020d1693          	slli	a3,s10,0x20
    802054b6:	9281                	srli	a3,a3,0x20
    802054b8:	8656                	mv	a2,s5
    802054ba:	95ee                	add	a1,a1,s11
    802054bc:	6928                	ld	a0,80(a0)
    802054be:	ffffe097          	auipc	ra,0xffffe
    802054c2:	ae2080e7          	jalr	-1310(ra) # 80202fa0 <copyin>
    802054c6:	f6055ee3          	bgez	a0,80205442 <writei+0x60>
                brelse(bp);
    802054ca:	8526                	mv	a0,s1
    802054cc:	fffff097          	auipc	ra,0xfffff
    802054d0:	3f0080e7          	jalr	1008(ra) # 802048bc <brelse>
    }
    if (off > ip->size) ip->size = off;
    802054d4:	04cb2783          	lw	a5,76(s6)
    802054d8:	0337fb63          	bgeu	a5,s3,8020550e <writei+0x12c>
    802054dc:	053b2623          	sw	s3,76(s6)
    802054e0:	64e6                	ld	s1,88(sp)
    802054e2:	6946                	ld	s2,80(sp)
    802054e4:	6ce2                	ld	s9,24(sp)
    802054e6:	6d42                	ld	s10,16(sp)
    802054e8:	6da2                	ld	s11,8(sp)
    iupdate(ip);                    /* size and any new addrs[] hit the disk */
    802054ea:	855a                	mv	a0,s6
    802054ec:	00000097          	auipc	ra,0x0
    802054f0:	9d2080e7          	jalr	-1582(ra) # 80204ebe <iupdate>
    return tot;
    802054f4:	8552                	mv	a0,s4
    802054f6:	6a06                	ld	s4,64(sp)
}
    802054f8:	70a6                	ld	ra,104(sp)
    802054fa:	7406                	ld	s0,96(sp)
    802054fc:	69a6                	ld	s3,72(sp)
    802054fe:	7ae2                	ld	s5,56(sp)
    80205500:	7b42                	ld	s6,48(sp)
    80205502:	7ba2                	ld	s7,40(sp)
    80205504:	7c02                	ld	s8,32(sp)
    80205506:	6165                	addi	sp,sp,112
    80205508:	8082                	ret
    for (tot = 0; tot < n; tot += m, off += m, src += m) {
    8020550a:	8a5e                	mv	s4,s7
    8020550c:	bff9                	j	802054ea <writei+0x108>
    8020550e:	64e6                	ld	s1,88(sp)
    80205510:	6946                	ld	s2,80(sp)
    80205512:	6ce2                	ld	s9,24(sp)
    80205514:	6d42                	ld	s10,16(sp)
    80205516:	6da2                	ld	s11,8(sp)
    80205518:	bfc9                	j	802054ea <writei+0x108>
    if (off > ip->size || off + n < off) return -1;
    8020551a:	557d                	li	a0,-1
}
    8020551c:	8082                	ret
    if (off > ip->size || off + n < off) return -1;
    8020551e:	557d                	li	a0,-1
    80205520:	bfe1                	j	802054f8 <writei+0x116>
    if (off + n > MAXFILE * BSIZE) return -1;
    80205522:	557d                	li	a0,-1
    80205524:	bfd1                	j	802054f8 <writei+0x116>

0000000080205526 <namecmp>:

/* ---------- directories ---------- */

int namecmp(const char *s, const char *t) { return strncmp(s, t, DIRSIZ); }
    80205526:	1141                	addi	sp,sp,-16
    80205528:	e406                	sd	ra,8(sp)
    8020552a:	e022                	sd	s0,0(sp)
    8020552c:	0800                	addi	s0,sp,16
    8020552e:	4671                	li	a2,28
    80205530:	ffffb097          	auipc	ra,0xffffb
    80205534:	1be080e7          	jalr	446(ra) # 802006ee <strncmp>
    80205538:	60a2                	ld	ra,8(sp)
    8020553a:	6402                	ld	s0,0(sp)
    8020553c:	0141                	addi	sp,sp,16
    8020553e:	8082                	ret

0000000080205540 <dirlookup>:

/* Look up name in directory dp. Returns unlocked inode; *poff = entry offset. */
struct inode *dirlookup(struct inode *dp, char *name, uint32 *poff)
{
    80205540:	7159                	addi	sp,sp,-112
    80205542:	f486                	sd	ra,104(sp)
    80205544:	f0a2                	sd	s0,96(sp)
    80205546:	eca6                	sd	s1,88(sp)
    80205548:	e8ca                	sd	s2,80(sp)
    8020554a:	e4ce                	sd	s3,72(sp)
    8020554c:	e0d2                	sd	s4,64(sp)
    8020554e:	fc56                	sd	s5,56(sp)
    80205550:	f85a                	sd	s6,48(sp)
    80205552:	f45e                	sd	s7,40(sp)
    80205554:	1880                	addi	s0,sp,112
    if (dp->type != T_DIR) panic("dirlookup: not a directory");
    80205556:	04455703          	lhu	a4,68(a0)
    8020555a:	4785                	li	a5,1
    8020555c:	02f71063          	bne	a4,a5,8020557c <dirlookup+0x3c>
    80205560:	892a                	mv	s2,a0
    80205562:	8aae                	mv	s5,a1
    80205564:	8bb2                	mv	s7,a2

    struct dirent de;
    for (uint32 off = 0; off < dp->size; off += sizeof(de)) {
    80205566:	457c                	lw	a5,76(a0)
    80205568:	4481                	li	s1,0
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8020556a:	f9040a13          	addi	s4,s0,-112
    8020556e:	02000993          	li	s3,32
            panic("dirlookup: short directory read");
        if (de.inum == 0) continue;
        if (namecmp(name, de.name) == 0) {
    80205572:	f9440b13          	addi	s6,s0,-108
            if (poff) *poff = off;
            return iget(dp->dev, de.inum);
        }
    }
    return 0;
    80205576:	4501                	li	a0,0
    for (uint32 off = 0; off < dp->size; off += sizeof(de)) {
    80205578:	eb85                	bnez	a5,802055a8 <dirlookup+0x68>
    8020557a:	a895                	j	802055ee <dirlookup+0xae>
    if (dp->type != T_DIR) panic("dirlookup: not a directory");
    8020557c:	00002517          	auipc	a0,0x2
    80205580:	61450513          	addi	a0,a0,1556 # 80207b90 <etext+0xb90>
    80205584:	ffffb097          	auipc	ra,0xffffb
    80205588:	02c080e7          	jalr	44(ra) # 802005b0 <panic>
            panic("dirlookup: short directory read");
    8020558c:	00002517          	auipc	a0,0x2
    80205590:	62450513          	addi	a0,a0,1572 # 80207bb0 <etext+0xbb0>
    80205594:	ffffb097          	auipc	ra,0xffffb
    80205598:	01c080e7          	jalr	28(ra) # 802005b0 <panic>
    for (uint32 off = 0; off < dp->size; off += sizeof(de)) {
    8020559c:	0204849b          	addiw	s1,s1,32
    802055a0:	04c92783          	lw	a5,76(s2)
    802055a4:	04f4f463          	bgeu	s1,a5,802055ec <dirlookup+0xac>
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    802055a8:	874e                	mv	a4,s3
    802055aa:	86a6                	mv	a3,s1
    802055ac:	8652                	mv	a2,s4
    802055ae:	4581                	li	a1,0
    802055b0:	854a                	mv	a0,s2
    802055b2:	00000097          	auipc	ra,0x0
    802055b6:	d08080e7          	jalr	-760(ra) # 802052ba <readi>
    802055ba:	fd3519e3          	bne	a0,s3,8020558c <dirlookup+0x4c>
        if (de.inum == 0) continue;
    802055be:	f9042783          	lw	a5,-112(s0)
    802055c2:	dfe9                	beqz	a5,8020559c <dirlookup+0x5c>
        if (namecmp(name, de.name) == 0) {
    802055c4:	85da                	mv	a1,s6
    802055c6:	8556                	mv	a0,s5
    802055c8:	00000097          	auipc	ra,0x0
    802055cc:	f5e080e7          	jalr	-162(ra) # 80205526 <namecmp>
    802055d0:	f571                	bnez	a0,8020559c <dirlookup+0x5c>
            if (poff) *poff = off;
    802055d2:	000b8463          	beqz	s7,802055da <dirlookup+0x9a>
    802055d6:	009ba023          	sw	s1,0(s7)
            return iget(dp->dev, de.inum);
    802055da:	f9042583          	lw	a1,-112(s0)
    802055de:	00092503          	lw	a0,0(s2)
    802055e2:	fffff097          	auipc	ra,0xfffff
    802055e6:	5f0080e7          	jalr	1520(ra) # 80204bd2 <iget>
    802055ea:	a011                	j	802055ee <dirlookup+0xae>
    return 0;
    802055ec:	4501                	li	a0,0
}
    802055ee:	70a6                	ld	ra,104(sp)
    802055f0:	7406                	ld	s0,96(sp)
    802055f2:	64e6                	ld	s1,88(sp)
    802055f4:	6946                	ld	s2,80(sp)
    802055f6:	69a6                	ld	s3,72(sp)
    802055f8:	6a06                	ld	s4,64(sp)
    802055fa:	7ae2                	ld	s5,56(sp)
    802055fc:	7b42                	ld	s6,48(sp)
    802055fe:	7ba2                	ld	s7,40(sp)
    80205600:	6165                	addi	sp,sp,112
    80205602:	8082                	ret

0000000080205604 <namex>:
}

/* Walk path from / (or the cwd). If parent, stop one level early and copy the
 * final element into name. The RETURNED inode is unlocked and referenced. */
static struct inode *namex(char *path, int nameiparent_, char *name)
{
    80205604:	711d                	addi	sp,sp,-96
    80205606:	ec86                	sd	ra,88(sp)
    80205608:	e8a2                	sd	s0,80(sp)
    8020560a:	e4a6                	sd	s1,72(sp)
    8020560c:	e0ca                	sd	s2,64(sp)
    8020560e:	fc4e                	sd	s3,56(sp)
    80205610:	f852                	sd	s4,48(sp)
    80205612:	f456                	sd	s5,40(sp)
    80205614:	f05a                	sd	s6,32(sp)
    80205616:	ec5e                	sd	s7,24(sp)
    80205618:	e862                	sd	s8,16(sp)
    8020561a:	e466                	sd	s9,8(sp)
    8020561c:	e06a                	sd	s10,0(sp)
    8020561e:	1080                	addi	s0,sp,96
    80205620:	84aa                	mv	s1,a0
    80205622:	8b2e                	mv	s6,a1
    80205624:	8ab2                	mv	s5,a2
    struct inode *ip;
    if (*path == '/')
    80205626:	00054703          	lbu	a4,0(a0)
    8020562a:	02f00793          	li	a5,47
    8020562e:	02f70363          	beq	a4,a5,80205654 <namex+0x50>
        ip = iget(ROOTDEV, ROOTINO);
    else
        ip = idup(myproc()->cwd);
    80205632:	ffffc097          	auipc	ra,0xffffc
    80205636:	0ac080e7          	jalr	172(ra) # 802016de <myproc>
    8020563a:	15053503          	ld	a0,336(a0)
    8020563e:	00000097          	auipc	ra,0x0
    80205642:	90e080e7          	jalr	-1778(ra) # 80204f4c <idup>
    80205646:	8a2a                	mv	s4,a0
    while (*path == '/') path++;
    80205648:	02f00913          	li	s2,47
    if (len >= DIRSIZ) {
    8020564c:	4c6d                	li	s8,27
        memmove(name, s, DIRSIZ);                 /* truncate long names */
    8020564e:	4cf1                	li	s9,28

    while ((path = skipelem(path, name)) != 0) {
        ilock(ip);
        if (ip->type != T_DIR) { iunlockput(ip); return 0; }
    80205650:	4b85                	li	s7,1
    80205652:	a86d                	j	8020570c <namex+0x108>
        ip = iget(ROOTDEV, ROOTINO);
    80205654:	4585                	li	a1,1
    80205656:	4501                	li	a0,0
    80205658:	fffff097          	auipc	ra,0xfffff
    8020565c:	57a080e7          	jalr	1402(ra) # 80204bd2 <iget>
    80205660:	8a2a                	mv	s4,a0
    80205662:	b7dd                	j	80205648 <namex+0x44>
        if (ip->type != T_DIR) { iunlockput(ip); return 0; }
    80205664:	8552                	mv	a0,s4
    80205666:	00000097          	auipc	ra,0x0
    8020566a:	bfe080e7          	jalr	-1026(ra) # 80205264 <iunlockput>
    8020566e:	4a01                	li	s4,0
        iunlockput(ip);
        ip = next;
    }
    if (nameiparent_) { iput(ip); return 0; }
    return ip;
}
    80205670:	8552                	mv	a0,s4
    80205672:	60e6                	ld	ra,88(sp)
    80205674:	6446                	ld	s0,80(sp)
    80205676:	64a6                	ld	s1,72(sp)
    80205678:	6906                	ld	s2,64(sp)
    8020567a:	79e2                	ld	s3,56(sp)
    8020567c:	7a42                	ld	s4,48(sp)
    8020567e:	7aa2                	ld	s5,40(sp)
    80205680:	7b02                	ld	s6,32(sp)
    80205682:	6be2                	ld	s7,24(sp)
    80205684:	6c42                	ld	s8,16(sp)
    80205686:	6ca2                	ld	s9,8(sp)
    80205688:	6d02                	ld	s10,0(sp)
    8020568a:	6125                	addi	sp,sp,96
    8020568c:	8082                	ret
            iunlock(ip);                          /* stop at the parent */
    8020568e:	8552                	mv	a0,s4
    80205690:	00000097          	auipc	ra,0x0
    80205694:	9c0080e7          	jalr	-1600(ra) # 80205050 <iunlock>
            return ip;
    80205698:	bfe1                	j	80205670 <namex+0x6c>
        if (next == 0) { iunlockput(ip); return 0; }
    8020569a:	8552                	mv	a0,s4
    8020569c:	00000097          	auipc	ra,0x0
    802056a0:	bc8080e7          	jalr	-1080(ra) # 80205264 <iunlockput>
    802056a4:	8a4e                	mv	s4,s3
    802056a6:	b7e9                	j	80205670 <namex+0x6c>
    int len = path - s;
    802056a8:	40998d3b          	subw	s10,s3,s1
    if (len >= DIRSIZ) {
    802056ac:	09ac5763          	bge	s8,s10,8020573a <namex+0x136>
        memmove(name, s, DIRSIZ);                 /* truncate long names */
    802056b0:	8666                	mv	a2,s9
    802056b2:	85a6                	mv	a1,s1
    802056b4:	8556                	mv	a0,s5
    802056b6:	ffffb097          	auipc	ra,0xffffb
    802056ba:	fc0080e7          	jalr	-64(ra) # 80200676 <memmove>
    802056be:	84ce                	mv	s1,s3
    while (*path == '/') path++;
    802056c0:	0004c783          	lbu	a5,0(s1)
    802056c4:	01279763          	bne	a5,s2,802056d2 <namex+0xce>
    802056c8:	0485                	addi	s1,s1,1
    802056ca:	0004c783          	lbu	a5,0(s1)
    802056ce:	ff278de3          	beq	a5,s2,802056c8 <namex+0xc4>
        ilock(ip);
    802056d2:	8552                	mv	a0,s4
    802056d4:	00000097          	auipc	ra,0x0
    802056d8:	8b6080e7          	jalr	-1866(ra) # 80204f8a <ilock>
        if (ip->type != T_DIR) { iunlockput(ip); return 0; }
    802056dc:	044a5783          	lhu	a5,68(s4) # 2044 <_entry-0x801fdfbc>
    802056e0:	f97792e3          	bne	a5,s7,80205664 <namex+0x60>
        if (nameiparent_ && *path == '\0') {
    802056e4:	000b0563          	beqz	s6,802056ee <namex+0xea>
    802056e8:	0004c783          	lbu	a5,0(s1)
    802056ec:	d3cd                	beqz	a5,8020568e <namex+0x8a>
        struct inode *next = dirlookup(ip, name, 0);
    802056ee:	4601                	li	a2,0
    802056f0:	85d6                	mv	a1,s5
    802056f2:	8552                	mv	a0,s4
    802056f4:	00000097          	auipc	ra,0x0
    802056f8:	e4c080e7          	jalr	-436(ra) # 80205540 <dirlookup>
    802056fc:	89aa                	mv	s3,a0
        if (next == 0) { iunlockput(ip); return 0; }
    802056fe:	dd51                	beqz	a0,8020569a <namex+0x96>
        iunlockput(ip);
    80205700:	8552                	mv	a0,s4
    80205702:	00000097          	auipc	ra,0x0
    80205706:	b62080e7          	jalr	-1182(ra) # 80205264 <iunlockput>
        ip = next;
    8020570a:	8a4e                	mv	s4,s3
    while (*path == '/') path++;
    8020570c:	0004c783          	lbu	a5,0(s1)
    80205710:	01279763          	bne	a5,s2,8020571e <namex+0x11a>
    80205714:	0485                	addi	s1,s1,1
    80205716:	0004c783          	lbu	a5,0(s1)
    8020571a:	ff278de3          	beq	a5,s2,80205714 <namex+0x110>
    if (*path == 0) return 0;
    8020571e:	cb95                	beqz	a5,80205752 <namex+0x14e>
    while (*path != '/' && *path != 0) path++;
    80205720:	0004c783          	lbu	a5,0(s1)
    80205724:	89a6                	mv	s3,s1
    int len = path - s;
    80205726:	4d01                	li	s10,0
    while (*path != '/' && *path != 0) path++;
    80205728:	01278963          	beq	a5,s2,8020573a <namex+0x136>
    8020572c:	dfb5                	beqz	a5,802056a8 <namex+0xa4>
    8020572e:	0985                	addi	s3,s3,1
    80205730:	0009c783          	lbu	a5,0(s3)
    80205734:	ff279ce3          	bne	a5,s2,8020572c <namex+0x128>
    80205738:	bf85                	j	802056a8 <namex+0xa4>
        memmove(name, s, len);
    8020573a:	866a                	mv	a2,s10
    8020573c:	85a6                	mv	a1,s1
    8020573e:	8556                	mv	a0,s5
    80205740:	ffffb097          	auipc	ra,0xffffb
    80205744:	f36080e7          	jalr	-202(ra) # 80200676 <memmove>
        name[len] = 0;
    80205748:	9d56                	add	s10,s10,s5
    8020574a:	000d0023          	sb	zero,0(s10)
    8020574e:	84ce                	mv	s1,s3
    80205750:	bf85                	j	802056c0 <namex+0xbc>
    if (nameiparent_) { iput(ip); return 0; }
    80205752:	f00b0fe3          	beqz	s6,80205670 <namex+0x6c>
    80205756:	8552                	mv	a0,s4
    80205758:	00000097          	auipc	ra,0x0
    8020575c:	9f0080e7          	jalr	-1552(ra) # 80205148 <iput>
    80205760:	4a01                	li	s4,0
    80205762:	b739                	j	80205670 <namex+0x6c>

0000000080205764 <dirlink>:
{
    80205764:	711d                	addi	sp,sp,-96
    80205766:	ec86                	sd	ra,88(sp)
    80205768:	e8a2                	sd	s0,80(sp)
    8020576a:	e0ca                	sd	s2,64(sp)
    8020576c:	f456                	sd	s5,40(sp)
    8020576e:	f05a                	sd	s6,32(sp)
    80205770:	1080                	addi	s0,sp,96
    80205772:	892a                	mv	s2,a0
    80205774:	8aae                	mv	s5,a1
    80205776:	8b32                	mv	s6,a2
    if ((ip = dirlookup(dp, name, 0)) != 0) { iput(ip); return -1; }
    80205778:	4601                	li	a2,0
    8020577a:	00000097          	auipc	ra,0x0
    8020577e:	dc6080e7          	jalr	-570(ra) # 80205540 <dirlookup>
    80205782:	e139                	bnez	a0,802057c8 <dirlink+0x64>
    80205784:	e4a6                	sd	s1,72(sp)
    for (off = 0; off < dp->size; off += sizeof(de)) {
    80205786:	04c92483          	lw	s1,76(s2)
    8020578a:	ccb9                	beqz	s1,802057e8 <dirlink+0x84>
    8020578c:	fc4e                	sd	s3,56(sp)
    8020578e:	f852                	sd	s4,48(sp)
    80205790:	4481                	li	s1,0
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80205792:	fa040a13          	addi	s4,s0,-96
    80205796:	02000993          	li	s3,32
    8020579a:	874e                	mv	a4,s3
    8020579c:	86a6                	mv	a3,s1
    8020579e:	8652                	mv	a2,s4
    802057a0:	4581                	li	a1,0
    802057a2:	854a                	mv	a0,s2
    802057a4:	00000097          	auipc	ra,0x0
    802057a8:	b16080e7          	jalr	-1258(ra) # 802052ba <readi>
    802057ac:	03351463          	bne	a0,s3,802057d4 <dirlink+0x70>
        if (de.inum == 0) break;                  /* reuse a freed slot */
    802057b0:	fa042783          	lw	a5,-96(s0)
    802057b4:	cb85                	beqz	a5,802057e4 <dirlink+0x80>
    for (off = 0; off < dp->size; off += sizeof(de)) {
    802057b6:	0204849b          	addiw	s1,s1,32
    802057ba:	04c92783          	lw	a5,76(s2)
    802057be:	fcf4eee3          	bltu	s1,a5,8020579a <dirlink+0x36>
    802057c2:	79e2                	ld	s3,56(sp)
    802057c4:	7a42                	ld	s4,48(sp)
    802057c6:	a00d                	j	802057e8 <dirlink+0x84>
    if ((ip = dirlookup(dp, name, 0)) != 0) { iput(ip); return -1; }
    802057c8:	00000097          	auipc	ra,0x0
    802057cc:	980080e7          	jalr	-1664(ra) # 80205148 <iput>
    802057d0:	557d                	li	a0,-1
    802057d2:	a0b1                	j	8020581e <dirlink+0xba>
            panic("dirlink: short directory read");
    802057d4:	00002517          	auipc	a0,0x2
    802057d8:	3fc50513          	addi	a0,a0,1020 # 80207bd0 <etext+0xbd0>
    802057dc:	ffffb097          	auipc	ra,0xffffb
    802057e0:	dd4080e7          	jalr	-556(ra) # 802005b0 <panic>
    802057e4:	79e2                	ld	s3,56(sp)
    802057e6:	7a42                	ld	s4,48(sp)
    strncpy(de.name, name, DIRSIZ);
    802057e8:	4671                	li	a2,28
    802057ea:	85d6                	mv	a1,s5
    802057ec:	fa440513          	addi	a0,s0,-92
    802057f0:	ffffb097          	auipc	ra,0xffffb
    802057f4:	f38080e7          	jalr	-200(ra) # 80200728 <strncpy>
    de.inum = inum;
    802057f8:	fb642023          	sw	s6,-96(s0)
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    802057fc:	02000713          	li	a4,32
    80205800:	86a6                	mv	a3,s1
    80205802:	fa040613          	addi	a2,s0,-96
    80205806:	4581                	li	a1,0
    80205808:	854a                	mv	a0,s2
    8020580a:	00000097          	auipc	ra,0x0
    8020580e:	bd8080e7          	jalr	-1064(ra) # 802053e2 <writei>
    80205812:	1501                	addi	a0,a0,-32
    80205814:	00a03533          	snez	a0,a0
    80205818:	40a0053b          	negw	a0,a0
    8020581c:	64a6                	ld	s1,72(sp)
}
    8020581e:	60e6                	ld	ra,88(sp)
    80205820:	6446                	ld	s0,80(sp)
    80205822:	6906                	ld	s2,64(sp)
    80205824:	7aa2                	ld	s5,40(sp)
    80205826:	7b02                	ld	s6,32(sp)
    80205828:	6125                	addi	sp,sp,96
    8020582a:	8082                	ret

000000008020582c <namei>:

struct inode *namei(char *path)
{
    8020582c:	7179                	addi	sp,sp,-48
    8020582e:	f406                	sd	ra,40(sp)
    80205830:	f022                	sd	s0,32(sp)
    80205832:	1800                	addi	s0,sp,48
    char name[DIRSIZ];
    return namex(path, 0, name);
    80205834:	fd040613          	addi	a2,s0,-48
    80205838:	4581                	li	a1,0
    8020583a:	00000097          	auipc	ra,0x0
    8020583e:	dca080e7          	jalr	-566(ra) # 80205604 <namex>
}
    80205842:	70a2                	ld	ra,40(sp)
    80205844:	7402                	ld	s0,32(sp)
    80205846:	6145                	addi	sp,sp,48
    80205848:	8082                	ret

000000008020584a <nameiparent>:

struct inode *nameiparent(char *path, char *name)
{
    8020584a:	1141                	addi	sp,sp,-16
    8020584c:	e406                	sd	ra,8(sp)
    8020584e:	e022                	sd	s0,0(sp)
    80205850:	0800                	addi	s0,sp,16
    80205852:	862e                	mv	a2,a1
    return namex(path, 1, name);
    80205854:	4585                	li	a1,1
    80205856:	00000097          	auipc	ra,0x0
    8020585a:	dae080e7          	jalr	-594(ra) # 80205604 <namex>
}
    8020585e:	60a2                	ld	ra,8(sp)
    80205860:	6402                	ld	s0,0(sp)
    80205862:	0141                	addi	sp,sp,16
    80205864:	8082                	ret

0000000080205866 <fileinit>:
static struct {
    struct spinlock lock;
    struct file file[NFILE];
} ftable;

void fileinit(void) { initlock(&ftable.lock, "ftable"); }
    80205866:	1141                	addi	sp,sp,-16
    80205868:	e406                	sd	ra,8(sp)
    8020586a:	e022                	sd	s0,0(sp)
    8020586c:	0800                	addi	s0,sp,16
    8020586e:	00002597          	auipc	a1,0x2
    80205872:	38258593          	addi	a1,a1,898 # 80207bf0 <etext+0xbf0>
    80205876:	00135517          	auipc	a0,0x135
    8020587a:	47a50513          	addi	a0,a0,1146 # 8033acf0 <ftable>
    8020587e:	ffffc097          	auipc	ra,0xffffc
    80205882:	a02080e7          	jalr	-1534(ra) # 80201280 <initlock>
    80205886:	60a2                	ld	ra,8(sp)
    80205888:	6402                	ld	s0,0(sp)
    8020588a:	0141                	addi	sp,sp,16
    8020588c:	8082                	ret

000000008020588e <filealloc>:

struct file *filealloc(void)
{
    8020588e:	1101                	addi	sp,sp,-32
    80205890:	ec06                	sd	ra,24(sp)
    80205892:	e822                	sd	s0,16(sp)
    80205894:	e426                	sd	s1,8(sp)
    80205896:	1000                	addi	s0,sp,32
    acquire(&ftable.lock);
    80205898:	00135517          	auipc	a0,0x135
    8020589c:	45850513          	addi	a0,a0,1112 # 8033acf0 <ftable>
    802058a0:	ffffc097          	auipc	ra,0xffffc
    802058a4:	a60080e7          	jalr	-1440(ra) # 80201300 <acquire>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    802058a8:	00135497          	auipc	s1,0x135
    802058ac:	46048493          	addi	s1,s1,1120 # 8033ad08 <ftable+0x18>
    802058b0:	00136717          	auipc	a4,0x136
    802058b4:	3f870713          	addi	a4,a4,1016 # 8033bca8 <ftable+0xfb8>
        if (f->ref == 0) {
    802058b8:	40dc                	lw	a5,4(s1)
    802058ba:	cf99                	beqz	a5,802058d8 <filealloc+0x4a>
    for (struct file *f = ftable.file; f < ftable.file + NFILE; f++) {
    802058bc:	02848493          	addi	s1,s1,40
    802058c0:	fee49ce3          	bne	s1,a4,802058b8 <filealloc+0x2a>
            f->ref = 1;
            release(&ftable.lock);
            return f;
        }
    }
    release(&ftable.lock);
    802058c4:	00135517          	auipc	a0,0x135
    802058c8:	42c50513          	addi	a0,a0,1068 # 8033acf0 <ftable>
    802058cc:	ffffc097          	auipc	ra,0xffffc
    802058d0:	ae4080e7          	jalr	-1308(ra) # 802013b0 <release>
    return 0;
    802058d4:	4481                	li	s1,0
    802058d6:	a819                	j	802058ec <filealloc+0x5e>
            f->ref = 1;
    802058d8:	4785                	li	a5,1
    802058da:	c0dc                	sw	a5,4(s1)
            release(&ftable.lock);
    802058dc:	00135517          	auipc	a0,0x135
    802058e0:	41450513          	addi	a0,a0,1044 # 8033acf0 <ftable>
    802058e4:	ffffc097          	auipc	ra,0xffffc
    802058e8:	acc080e7          	jalr	-1332(ra) # 802013b0 <release>
}
    802058ec:	8526                	mv	a0,s1
    802058ee:	60e2                	ld	ra,24(sp)
    802058f0:	6442                	ld	s0,16(sp)
    802058f2:	64a2                	ld	s1,8(sp)
    802058f4:	6105                	addi	sp,sp,32
    802058f6:	8082                	ret

00000000802058f8 <filedup>:

struct file *filedup(struct file *f)
{
    802058f8:	1101                	addi	sp,sp,-32
    802058fa:	ec06                	sd	ra,24(sp)
    802058fc:	e822                	sd	s0,16(sp)
    802058fe:	e426                	sd	s1,8(sp)
    80205900:	1000                	addi	s0,sp,32
    80205902:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    80205904:	00135517          	auipc	a0,0x135
    80205908:	3ec50513          	addi	a0,a0,1004 # 8033acf0 <ftable>
    8020590c:	ffffc097          	auipc	ra,0xffffc
    80205910:	9f4080e7          	jalr	-1548(ra) # 80201300 <acquire>
    if (f->ref < 1) panic("filedup");
    80205914:	40dc                	lw	a5,4(s1)
    80205916:	02f05263          	blez	a5,8020593a <filedup+0x42>
    f->ref++;
    8020591a:	2785                	addiw	a5,a5,1
    8020591c:	c0dc                	sw	a5,4(s1)
    release(&ftable.lock);
    8020591e:	00135517          	auipc	a0,0x135
    80205922:	3d250513          	addi	a0,a0,978 # 8033acf0 <ftable>
    80205926:	ffffc097          	auipc	ra,0xffffc
    8020592a:	a8a080e7          	jalr	-1398(ra) # 802013b0 <release>
    return f;
}
    8020592e:	8526                	mv	a0,s1
    80205930:	60e2                	ld	ra,24(sp)
    80205932:	6442                	ld	s0,16(sp)
    80205934:	64a2                	ld	s1,8(sp)
    80205936:	6105                	addi	sp,sp,32
    80205938:	8082                	ret
    if (f->ref < 1) panic("filedup");
    8020593a:	00002517          	auipc	a0,0x2
    8020593e:	2be50513          	addi	a0,a0,702 # 80207bf8 <etext+0xbf8>
    80205942:	ffffb097          	auipc	ra,0xffffb
    80205946:	c6e080e7          	jalr	-914(ra) # 802005b0 <panic>

000000008020594a <fileclose>:

void fileclose(struct file *f)
{
    8020594a:	7139                	addi	sp,sp,-64
    8020594c:	fc06                	sd	ra,56(sp)
    8020594e:	f822                	sd	s0,48(sp)
    80205950:	f426                	sd	s1,40(sp)
    80205952:	0080                	addi	s0,sp,64
    80205954:	84aa                	mv	s1,a0
    acquire(&ftable.lock);
    80205956:	00135517          	auipc	a0,0x135
    8020595a:	39a50513          	addi	a0,a0,922 # 8033acf0 <ftable>
    8020595e:	ffffc097          	auipc	ra,0xffffc
    80205962:	9a2080e7          	jalr	-1630(ra) # 80201300 <acquire>
    if (f->ref < 1) panic("fileclose");
    80205966:	40dc                	lw	a5,4(s1)
    80205968:	04f05a63          	blez	a5,802059bc <fileclose+0x72>
    if (--f->ref > 0) { release(&ftable.lock); return; }
    8020596c:	37fd                	addiw	a5,a5,-1
    8020596e:	c0dc                	sw	a5,4(s1)
    80205970:	06f04263          	bgtz	a5,802059d4 <fileclose+0x8a>
    80205974:	f04a                	sd	s2,32(sp)
    80205976:	ec4e                	sd	s3,24(sp)
    80205978:	e852                	sd	s4,16(sp)
    8020597a:	e456                	sd	s5,8(sp)

    struct file ff = *f;                 /* copy, then free the slot */
    8020597c:	0004a903          	lw	s2,0(s1)
    80205980:	0094ca83          	lbu	s5,9(s1)
    80205984:	0104ba03          	ld	s4,16(s1)
    80205988:	0184b983          	ld	s3,24(s1)
    f->ref = 0;
    8020598c:	0004a223          	sw	zero,4(s1)
    f->type = FD_NONE;
    80205990:	0004a023          	sw	zero,0(s1)
    release(&ftable.lock);
    80205994:	00135517          	auipc	a0,0x135
    80205998:	35c50513          	addi	a0,a0,860 # 8033acf0 <ftable>
    8020599c:	ffffc097          	auipc	ra,0xffffc
    802059a0:	a14080e7          	jalr	-1516(ra) # 802013b0 <release>

    if (ff.type == FD_PIPE)
    802059a4:	4785                	li	a5,1
    802059a6:	04f90463          	beq	s2,a5,802059ee <fileclose+0xa4>
        pipeclose(ff.pipe, ff.writable);
    else if (ff.type == FD_INODE || ff.type == FD_DEVICE)
    802059aa:	3979                	addiw	s2,s2,-2
    802059ac:	4785                	li	a5,1
    802059ae:	0527fb63          	bgeu	a5,s2,80205a04 <fileclose+0xba>
    802059b2:	7902                	ld	s2,32(sp)
    802059b4:	69e2                	ld	s3,24(sp)
    802059b6:	6a42                	ld	s4,16(sp)
    802059b8:	6aa2                	ld	s5,8(sp)
    802059ba:	a02d                	j	802059e4 <fileclose+0x9a>
    802059bc:	f04a                	sd	s2,32(sp)
    802059be:	ec4e                	sd	s3,24(sp)
    802059c0:	e852                	sd	s4,16(sp)
    802059c2:	e456                	sd	s5,8(sp)
    if (f->ref < 1) panic("fileclose");
    802059c4:	00002517          	auipc	a0,0x2
    802059c8:	23c50513          	addi	a0,a0,572 # 80207c00 <etext+0xc00>
    802059cc:	ffffb097          	auipc	ra,0xffffb
    802059d0:	be4080e7          	jalr	-1052(ra) # 802005b0 <panic>
    if (--f->ref > 0) { release(&ftable.lock); return; }
    802059d4:	00135517          	auipc	a0,0x135
    802059d8:	31c50513          	addi	a0,a0,796 # 8033acf0 <ftable>
    802059dc:	ffffc097          	auipc	ra,0xffffc
    802059e0:	9d4080e7          	jalr	-1580(ra) # 802013b0 <release>
        iput(ff.ip);
}
    802059e4:	70e2                	ld	ra,56(sp)
    802059e6:	7442                	ld	s0,48(sp)
    802059e8:	74a2                	ld	s1,40(sp)
    802059ea:	6121                	addi	sp,sp,64
    802059ec:	8082                	ret
        pipeclose(ff.pipe, ff.writable);
    802059ee:	85d6                	mv	a1,s5
    802059f0:	8552                	mv	a0,s4
    802059f2:	00000097          	auipc	ra,0x0
    802059f6:	328080e7          	jalr	808(ra) # 80205d1a <pipeclose>
    802059fa:	7902                	ld	s2,32(sp)
    802059fc:	69e2                	ld	s3,24(sp)
    802059fe:	6a42                	ld	s4,16(sp)
    80205a00:	6aa2                	ld	s5,8(sp)
    80205a02:	b7cd                	j	802059e4 <fileclose+0x9a>
        iput(ff.ip);
    80205a04:	854e                	mv	a0,s3
    80205a06:	fffff097          	auipc	ra,0xfffff
    80205a0a:	742080e7          	jalr	1858(ra) # 80205148 <iput>
    80205a0e:	7902                	ld	s2,32(sp)
    80205a10:	69e2                	ld	s3,24(sp)
    80205a12:	6a42                	ld	s4,16(sp)
    80205a14:	6aa2                	ld	s5,8(sp)
    80205a16:	b7f9                	j	802059e4 <fileclose+0x9a>

0000000080205a18 <filestat>:

int filestat(struct file *f, uint64 uaddr)
{
    if (f->type == FD_INODE || f->type == FD_DEVICE) {
    80205a18:	411c                	lw	a5,0(a0)
    80205a1a:	37f9                	addiw	a5,a5,-2
    80205a1c:	4705                	li	a4,1
    80205a1e:	06f76263          	bltu	a4,a5,80205a82 <filestat+0x6a>
{
    80205a22:	715d                	addi	sp,sp,-80
    80205a24:	e486                	sd	ra,72(sp)
    80205a26:	e0a2                	sd	s0,64(sp)
    80205a28:	fc26                	sd	s1,56(sp)
    80205a2a:	f84a                	sd	s2,48(sp)
    80205a2c:	f44e                	sd	s3,40(sp)
    80205a2e:	0880                	addi	s0,sp,80
    80205a30:	84aa                	mv	s1,a0
    80205a32:	892e                	mv	s2,a1
        struct stat st;
        ilock(f->ip);
    80205a34:	6d08                	ld	a0,24(a0)
    80205a36:	fffff097          	auipc	ra,0xfffff
    80205a3a:	554080e7          	jalr	1364(ra) # 80204f8a <ilock>
        stati(f->ip, &st);
    80205a3e:	fb840993          	addi	s3,s0,-72
    80205a42:	85ce                	mv	a1,s3
    80205a44:	6c88                	ld	a0,24(s1)
    80205a46:	00000097          	auipc	ra,0x0
    80205a4a:	846080e7          	jalr	-1978(ra) # 8020528c <stati>
        iunlock(f->ip);
    80205a4e:	6c88                	ld	a0,24(s1)
    80205a50:	fffff097          	auipc	ra,0xfffff
    80205a54:	600080e7          	jalr	1536(ra) # 80205050 <iunlock>
        if (copyout(myproc()->pagetable, uaddr, (char *)&st, sizeof(st)) < 0)
    80205a58:	ffffc097          	auipc	ra,0xffffc
    80205a5c:	c86080e7          	jalr	-890(ra) # 802016de <myproc>
    80205a60:	46e1                	li	a3,24
    80205a62:	864e                	mv	a2,s3
    80205a64:	85ca                	mv	a1,s2
    80205a66:	6928                	ld	a0,80(a0)
    80205a68:	ffffd097          	auipc	ra,0xffffd
    80205a6c:	476080e7          	jalr	1142(ra) # 80202ede <copyout>
    80205a70:	41f5551b          	sraiw	a0,a0,0x1f
            return -1;
        return 0;
    }
    return -1;
}
    80205a74:	60a6                	ld	ra,72(sp)
    80205a76:	6406                	ld	s0,64(sp)
    80205a78:	74e2                	ld	s1,56(sp)
    80205a7a:	7942                	ld	s2,48(sp)
    80205a7c:	79a2                	ld	s3,40(sp)
    80205a7e:	6161                	addi	sp,sp,80
    80205a80:	8082                	ret
    return -1;
    80205a82:	557d                	li	a0,-1
}
    80205a84:	8082                	ret

0000000080205a86 <fileread>:

int fileread(struct file *f, uint64 uaddr, int n)
{
    80205a86:	7179                	addi	sp,sp,-48
    80205a88:	f406                	sd	ra,40(sp)
    80205a8a:	f022                	sd	s0,32(sp)
    80205a8c:	e84a                	sd	s2,16(sp)
    80205a8e:	1800                	addi	s0,sp,48
    if (f->readable == 0) return -1;
    80205a90:	00854783          	lbu	a5,8(a0)
    80205a94:	cbcd                	beqz	a5,80205b46 <fileread+0xc0>
    80205a96:	ec26                	sd	s1,24(sp)
    80205a98:	e44e                	sd	s3,8(sp)
    80205a9a:	84aa                	mv	s1,a0
    80205a9c:	89ae                	mv	s3,a1
    80205a9e:	8932                	mv	s2,a2

    if (f->type == FD_PIPE)
    80205aa0:	411c                	lw	a5,0(a0)
    80205aa2:	4705                	li	a4,1
    80205aa4:	04e78963          	beq	a5,a4,80205af6 <fileread+0x70>
        return piperead(f->pipe, uaddr, n);

    if (f->type == FD_DEVICE) {
    80205aa8:	470d                	li	a4,3
    80205aaa:	04e78f63          	beq	a5,a4,80205b08 <fileread+0x82>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) return -1;
        return devsw[f->major].read(uaddr, n);
    }
    if (f->type == FD_INODE) {
    80205aae:	4709                	li	a4,2
    80205ab0:	08e79363          	bne	a5,a4,80205b36 <fileread+0xb0>
        ilock(f->ip);
    80205ab4:	6d08                	ld	a0,24(a0)
    80205ab6:	fffff097          	auipc	ra,0xfffff
    80205aba:	4d4080e7          	jalr	1236(ra) # 80204f8a <ilock>
        int r = readi(f->ip, 1, uaddr, f->off, n);
    80205abe:	874a                	mv	a4,s2
    80205ac0:	5094                	lw	a3,32(s1)
    80205ac2:	864e                	mv	a2,s3
    80205ac4:	4585                	li	a1,1
    80205ac6:	6c88                	ld	a0,24(s1)
    80205ac8:	fffff097          	auipc	ra,0xfffff
    80205acc:	7f2080e7          	jalr	2034(ra) # 802052ba <readi>
    80205ad0:	892a                	mv	s2,a0
        if (r > 0) f->off += r;          /* offset update under the inode lock */
    80205ad2:	00a05563          	blez	a0,80205adc <fileread+0x56>
    80205ad6:	509c                	lw	a5,32(s1)
    80205ad8:	9fa9                	addw	a5,a5,a0
    80205ada:	d09c                	sw	a5,32(s1)
        iunlock(f->ip);
    80205adc:	6c88                	ld	a0,24(s1)
    80205ade:	fffff097          	auipc	ra,0xfffff
    80205ae2:	572080e7          	jalr	1394(ra) # 80205050 <iunlock>
        return r;
    80205ae6:	64e2                	ld	s1,24(sp)
    80205ae8:	69a2                	ld	s3,8(sp)
    }
    panic("fileread");
}
    80205aea:	854a                	mv	a0,s2
    80205aec:	70a2                	ld	ra,40(sp)
    80205aee:	7402                	ld	s0,32(sp)
    80205af0:	6942                	ld	s2,16(sp)
    80205af2:	6145                	addi	sp,sp,48
    80205af4:	8082                	ret
        return piperead(f->pipe, uaddr, n);
    80205af6:	6908                	ld	a0,16(a0)
    80205af8:	00000097          	auipc	ra,0x0
    80205afc:	39e080e7          	jalr	926(ra) # 80205e96 <piperead>
    80205b00:	892a                	mv	s2,a0
    80205b02:	64e2                	ld	s1,24(sp)
    80205b04:	69a2                	ld	s3,8(sp)
    80205b06:	b7d5                	j	80205aea <fileread+0x64>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) return -1;
    80205b08:	02451783          	lh	a5,36(a0)
    80205b0c:	03079693          	slli	a3,a5,0x30
    80205b10:	92c1                	srli	a3,a3,0x30
    80205b12:	4725                	li	a4,9
    80205b14:	02d76b63          	bltu	a4,a3,80205b4a <fileread+0xc4>
    80205b18:	0792                	slli	a5,a5,0x4
    80205b1a:	00135717          	auipc	a4,0x135
    80205b1e:	13670713          	addi	a4,a4,310 # 8033ac50 <devsw>
    80205b22:	97ba                	add	a5,a5,a4
    80205b24:	639c                	ld	a5,0(a5)
    80205b26:	c795                	beqz	a5,80205b52 <fileread+0xcc>
        return devsw[f->major].read(uaddr, n);
    80205b28:	85b2                	mv	a1,a2
    80205b2a:	854e                	mv	a0,s3
    80205b2c:	9782                	jalr	a5
    80205b2e:	892a                	mv	s2,a0
    80205b30:	64e2                	ld	s1,24(sp)
    80205b32:	69a2                	ld	s3,8(sp)
    80205b34:	bf5d                	j	80205aea <fileread+0x64>
    panic("fileread");
    80205b36:	00002517          	auipc	a0,0x2
    80205b3a:	0da50513          	addi	a0,a0,218 # 80207c10 <etext+0xc10>
    80205b3e:	ffffb097          	auipc	ra,0xffffb
    80205b42:	a72080e7          	jalr	-1422(ra) # 802005b0 <panic>
    if (f->readable == 0) return -1;
    80205b46:	597d                	li	s2,-1
    80205b48:	b74d                	j	80205aea <fileread+0x64>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].read) return -1;
    80205b4a:	597d                	li	s2,-1
    80205b4c:	64e2                	ld	s1,24(sp)
    80205b4e:	69a2                	ld	s3,8(sp)
    80205b50:	bf69                	j	80205aea <fileread+0x64>
    80205b52:	597d                	li	s2,-1
    80205b54:	64e2                	ld	s1,24(sp)
    80205b56:	69a2                	ld	s3,8(sp)
    80205b58:	bf49                	j	80205aea <fileread+0x64>

0000000080205b5a <filewrite>:

int filewrite(struct file *f, uint64 uaddr, int n)
{
    80205b5a:	7179                	addi	sp,sp,-48
    80205b5c:	f406                	sd	ra,40(sp)
    80205b5e:	f022                	sd	s0,32(sp)
    80205b60:	e84a                	sd	s2,16(sp)
    80205b62:	1800                	addi	s0,sp,48
    if (f->writable == 0) return -1;
    80205b64:	00954783          	lbu	a5,9(a0)
    80205b68:	cfdd                	beqz	a5,80205c26 <filewrite+0xcc>
    80205b6a:	ec26                	sd	s1,24(sp)
    80205b6c:	e44e                	sd	s3,8(sp)
    80205b6e:	84aa                	mv	s1,a0
    80205b70:	892e                	mv	s2,a1
    80205b72:	89b2                	mv	s3,a2

    if (f->type == FD_PIPE)
    80205b74:	411c                	lw	a5,0(a0)
    80205b76:	4705                	li	a4,1
    80205b78:	04e78c63          	beq	a5,a4,80205bd0 <filewrite+0x76>
        return pipewrite(f->pipe, uaddr, n);

    if (f->type == FD_DEVICE) {
    80205b7c:	470d                	li	a4,3
    80205b7e:	06e78263          	beq	a5,a4,80205be2 <filewrite+0x88>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) return -1;
        return devsw[f->major].write(uaddr, n);
    }
    if (f->type == FD_INODE) {
    80205b82:	4709                	li	a4,2
    80205b84:	08e79963          	bne	a5,a4,80205c16 <filewrite+0xbc>
        ilock(f->ip);
    80205b88:	6d08                	ld	a0,24(a0)
    80205b8a:	fffff097          	auipc	ra,0xfffff
    80205b8e:	400080e7          	jalr	1024(ra) # 80204f8a <ilock>
        int r = writei(f->ip, 1, uaddr, f->off, n);
    80205b92:	874e                	mv	a4,s3
    80205b94:	5094                	lw	a3,32(s1)
    80205b96:	864a                	mv	a2,s2
    80205b98:	4585                	li	a1,1
    80205b9a:	6c88                	ld	a0,24(s1)
    80205b9c:	00000097          	auipc	ra,0x0
    80205ba0:	846080e7          	jalr	-1978(ra) # 802053e2 <writei>
    80205ba4:	892a                	mv	s2,a0
        if (r > 0) f->off += r;
    80205ba6:	00a05563          	blez	a0,80205bb0 <filewrite+0x56>
    80205baa:	509c                	lw	a5,32(s1)
    80205bac:	9fa9                	addw	a5,a5,a0
    80205bae:	d09c                	sw	a5,32(s1)
        iunlock(f->ip);
    80205bb0:	6c88                	ld	a0,24(s1)
    80205bb2:	fffff097          	auipc	ra,0xfffff
    80205bb6:	49e080e7          	jalr	1182(ra) # 80205050 <iunlock>
        return (r == n) ? n : -1;        /* short write = disk full = error */
    80205bba:	05298b63          	beq	s3,s2,80205c10 <filewrite+0xb6>
    80205bbe:	597d                	li	s2,-1
    80205bc0:	64e2                	ld	s1,24(sp)
    80205bc2:	69a2                	ld	s3,8(sp)
    }
    panic("filewrite");
}
    80205bc4:	854a                	mv	a0,s2
    80205bc6:	70a2                	ld	ra,40(sp)
    80205bc8:	7402                	ld	s0,32(sp)
    80205bca:	6942                	ld	s2,16(sp)
    80205bcc:	6145                	addi	sp,sp,48
    80205bce:	8082                	ret
        return pipewrite(f->pipe, uaddr, n);
    80205bd0:	6908                	ld	a0,16(a0)
    80205bd2:	00000097          	auipc	ra,0x0
    80205bd6:	1b8080e7          	jalr	440(ra) # 80205d8a <pipewrite>
    80205bda:	892a                	mv	s2,a0
    80205bdc:	64e2                	ld	s1,24(sp)
    80205bde:	69a2                	ld	s3,8(sp)
    80205be0:	b7d5                	j	80205bc4 <filewrite+0x6a>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) return -1;
    80205be2:	02451783          	lh	a5,36(a0)
    80205be6:	03079693          	slli	a3,a5,0x30
    80205bea:	92c1                	srli	a3,a3,0x30
    80205bec:	4725                	li	a4,9
    80205bee:	02d76e63          	bltu	a4,a3,80205c2a <filewrite+0xd0>
    80205bf2:	0792                	slli	a5,a5,0x4
    80205bf4:	00135717          	auipc	a4,0x135
    80205bf8:	05c70713          	addi	a4,a4,92 # 8033ac50 <devsw>
    80205bfc:	97ba                	add	a5,a5,a4
    80205bfe:	679c                	ld	a5,8(a5)
    80205c00:	cb8d                	beqz	a5,80205c32 <filewrite+0xd8>
        return devsw[f->major].write(uaddr, n);
    80205c02:	85b2                	mv	a1,a2
    80205c04:	854a                	mv	a0,s2
    80205c06:	9782                	jalr	a5
    80205c08:	892a                	mv	s2,a0
    80205c0a:	64e2                	ld	s1,24(sp)
    80205c0c:	69a2                	ld	s3,8(sp)
    80205c0e:	bf5d                	j	80205bc4 <filewrite+0x6a>
    80205c10:	64e2                	ld	s1,24(sp)
    80205c12:	69a2                	ld	s3,8(sp)
    80205c14:	bf45                	j	80205bc4 <filewrite+0x6a>
    panic("filewrite");
    80205c16:	00002517          	auipc	a0,0x2
    80205c1a:	00a50513          	addi	a0,a0,10 # 80207c20 <etext+0xc20>
    80205c1e:	ffffb097          	auipc	ra,0xffffb
    80205c22:	992080e7          	jalr	-1646(ra) # 802005b0 <panic>
    if (f->writable == 0) return -1;
    80205c26:	597d                	li	s2,-1
    80205c28:	bf71                	j	80205bc4 <filewrite+0x6a>
        if (f->major < 0 || f->major >= NDEV || !devsw[f->major].write) return -1;
    80205c2a:	597d                	li	s2,-1
    80205c2c:	64e2                	ld	s1,24(sp)
    80205c2e:	69a2                	ld	s3,8(sp)
    80205c30:	bf51                	j	80205bc4 <filewrite+0x6a>
    80205c32:	597d                	li	s2,-1
    80205c34:	64e2                	ld	s1,24(sp)
    80205c36:	69a2                	ld	s3,8(sp)
    80205c38:	b771                	j	80205bc4 <filewrite+0x6a>

0000000080205c3a <pipealloc>:
    int    readopen;
    int    writeopen;
};

int pipealloc(struct file **f0, struct file **f1)
{
    80205c3a:	7179                	addi	sp,sp,-48
    80205c3c:	f406                	sd	ra,40(sp)
    80205c3e:	f022                	sd	s0,32(sp)
    80205c40:	ec26                	sd	s1,24(sp)
    80205c42:	e052                	sd	s4,0(sp)
    80205c44:	1800                	addi	s0,sp,48
    80205c46:	84aa                	mv	s1,a0
    80205c48:	8a2e                	mv	s4,a1
    struct pipe *pi = 0;
    *f0 = *f1 = 0;
    80205c4a:	0005b023          	sd	zero,0(a1)
    80205c4e:	00053023          	sd	zero,0(a0)

    if ((*f0 = filealloc()) == 0) goto bad;
    80205c52:	00000097          	auipc	ra,0x0
    80205c56:	c3c080e7          	jalr	-964(ra) # 8020588e <filealloc>
    80205c5a:	e088                	sd	a0,0(s1)
    80205c5c:	cd49                	beqz	a0,80205cf6 <pipealloc+0xbc>
    if ((*f1 = filealloc()) == 0) goto bad;
    80205c5e:	00000097          	auipc	ra,0x0
    80205c62:	c30080e7          	jalr	-976(ra) # 8020588e <filealloc>
    80205c66:	00aa3023          	sd	a0,0(s4)
    80205c6a:	c141                	beqz	a0,80205cea <pipealloc+0xb0>
    80205c6c:	e84a                	sd	s2,16(sp)
    if ((pi = (struct pipe *)palloc()) == 0) goto bad;
    80205c6e:	ffffb097          	auipc	ra,0xffffb
    80205c72:	400080e7          	jalr	1024(ra) # 8020106e <palloc>
    80205c76:	892a                	mv	s2,a0
    80205c78:	c13d                	beqz	a0,80205cde <pipealloc+0xa4>
    80205c7a:	e44e                	sd	s3,8(sp)

    pi->readopen  = 1;
    80205c7c:	4985                	li	s3,1
    80205c7e:	23352023          	sw	s3,544(a0)
    pi->writeopen = 1;
    80205c82:	23352223          	sw	s3,548(a0)
    pi->nread  = 0;
    80205c86:	20052c23          	sw	zero,536(a0)
    pi->nwrite = 0;
    80205c8a:	20052e23          	sw	zero,540(a0)
    initlock(&pi->lock, "pipe");
    80205c8e:	00002597          	auipc	a1,0x2
    80205c92:	fa258593          	addi	a1,a1,-94 # 80207c30 <etext+0xc30>
    80205c96:	ffffb097          	auipc	ra,0xffffb
    80205c9a:	5ea080e7          	jalr	1514(ra) # 80201280 <initlock>

    (*f0)->type = FD_PIPE; (*f0)->readable = 1; (*f0)->writable = 0; (*f0)->pipe = pi;
    80205c9e:	609c                	ld	a5,0(s1)
    80205ca0:	0137a023          	sw	s3,0(a5)
    80205ca4:	609c                	ld	a5,0(s1)
    80205ca6:	01378423          	sb	s3,8(a5)
    80205caa:	609c                	ld	a5,0(s1)
    80205cac:	000784a3          	sb	zero,9(a5)
    80205cb0:	609c                	ld	a5,0(s1)
    80205cb2:	0127b823          	sd	s2,16(a5)
    (*f1)->type = FD_PIPE; (*f1)->readable = 0; (*f1)->writable = 1; (*f1)->pipe = pi;
    80205cb6:	000a3783          	ld	a5,0(s4)
    80205cba:	0137a023          	sw	s3,0(a5)
    80205cbe:	000a3783          	ld	a5,0(s4)
    80205cc2:	00078423          	sb	zero,8(a5)
    80205cc6:	000a3783          	ld	a5,0(s4)
    80205cca:	013784a3          	sb	s3,9(a5)
    80205cce:	000a3783          	ld	a5,0(s4)
    80205cd2:	0127b823          	sd	s2,16(a5)
    return 0;
    80205cd6:	4501                	li	a0,0
    80205cd8:	6942                	ld	s2,16(sp)
    80205cda:	69a2                	ld	s3,8(sp)
    80205cdc:	a03d                	j	80205d0a <pipealloc+0xd0>

bad:
    if (*f0) fileclose(*f0);
    80205cde:	6088                	ld	a0,0(s1)
    80205ce0:	c119                	beqz	a0,80205ce6 <pipealloc+0xac>
    80205ce2:	6942                	ld	s2,16(sp)
    80205ce4:	a029                	j	80205cee <pipealloc+0xb4>
    80205ce6:	6942                	ld	s2,16(sp)
    80205ce8:	a039                	j	80205cf6 <pipealloc+0xbc>
    80205cea:	6088                	ld	a0,0(s1)
    80205cec:	c50d                	beqz	a0,80205d16 <pipealloc+0xdc>
    80205cee:	00000097          	auipc	ra,0x0
    80205cf2:	c5c080e7          	jalr	-932(ra) # 8020594a <fileclose>
    if (*f1) fileclose(*f1);
    80205cf6:	000a3783          	ld	a5,0(s4)
    return -1;
    80205cfa:	557d                	li	a0,-1
    if (*f1) fileclose(*f1);
    80205cfc:	c799                	beqz	a5,80205d0a <pipealloc+0xd0>
    80205cfe:	853e                	mv	a0,a5
    80205d00:	00000097          	auipc	ra,0x0
    80205d04:	c4a080e7          	jalr	-950(ra) # 8020594a <fileclose>
    return -1;
    80205d08:	557d                	li	a0,-1
}
    80205d0a:	70a2                	ld	ra,40(sp)
    80205d0c:	7402                	ld	s0,32(sp)
    80205d0e:	64e2                	ld	s1,24(sp)
    80205d10:	6a02                	ld	s4,0(sp)
    80205d12:	6145                	addi	sp,sp,48
    80205d14:	8082                	ret
    return -1;
    80205d16:	557d                	li	a0,-1
    80205d18:	bfcd                	j	80205d0a <pipealloc+0xd0>

0000000080205d1a <pipeclose>:

void pipeclose(struct pipe *pi, int writable)
{
    80205d1a:	1101                	addi	sp,sp,-32
    80205d1c:	ec06                	sd	ra,24(sp)
    80205d1e:	e822                	sd	s0,16(sp)
    80205d20:	e426                	sd	s1,8(sp)
    80205d22:	e04a                	sd	s2,0(sp)
    80205d24:	1000                	addi	s0,sp,32
    80205d26:	84aa                	mv	s1,a0
    80205d28:	892e                	mv	s2,a1
    acquire(&pi->lock);
    80205d2a:	ffffb097          	auipc	ra,0xffffb
    80205d2e:	5d6080e7          	jalr	1494(ra) # 80201300 <acquire>
    if (writable) {
    80205d32:	02090d63          	beqz	s2,80205d6c <pipeclose+0x52>
        pi->writeopen = 0;
    80205d36:	2204a223          	sw	zero,548(s1)
        wakeup(&pi->nread);          /* blocked readers must see EOF */
    80205d3a:	21848513          	addi	a0,s1,536
    80205d3e:	ffffc097          	auipc	ra,0xffffc
    80205d42:	192080e7          	jalr	402(ra) # 80201ed0 <wakeup>
    } else {
        pi->readopen = 0;
        wakeup(&pi->nwrite);         /* blocked writers must see the error */
    }
    if (pi->readopen == 0 && pi->writeopen == 0) {
    80205d46:	2204b783          	ld	a5,544(s1)
    80205d4a:	eb95                	bnez	a5,80205d7e <pipeclose+0x64>
        release(&pi->lock);
    80205d4c:	8526                	mv	a0,s1
    80205d4e:	ffffb097          	auipc	ra,0xffffb
    80205d52:	662080e7          	jalr	1634(ra) # 802013b0 <release>
        pfree(pi);
    80205d56:	8526                	mv	a0,s1
    80205d58:	ffffb097          	auipc	ra,0xffffb
    80205d5c:	426080e7          	jalr	1062(ra) # 8020117e <pfree>
    } else {
        release(&pi->lock);
    }
}
    80205d60:	60e2                	ld	ra,24(sp)
    80205d62:	6442                	ld	s0,16(sp)
    80205d64:	64a2                	ld	s1,8(sp)
    80205d66:	6902                	ld	s2,0(sp)
    80205d68:	6105                	addi	sp,sp,32
    80205d6a:	8082                	ret
        pi->readopen = 0;
    80205d6c:	2204a023          	sw	zero,544(s1)
        wakeup(&pi->nwrite);         /* blocked writers must see the error */
    80205d70:	21c48513          	addi	a0,s1,540
    80205d74:	ffffc097          	auipc	ra,0xffffc
    80205d78:	15c080e7          	jalr	348(ra) # 80201ed0 <wakeup>
    80205d7c:	b7e9                	j	80205d46 <pipeclose+0x2c>
        release(&pi->lock);
    80205d7e:	8526                	mv	a0,s1
    80205d80:	ffffb097          	auipc	ra,0xffffb
    80205d84:	630080e7          	jalr	1584(ra) # 802013b0 <release>
}
    80205d88:	bfe1                	j	80205d60 <pipeclose+0x46>

0000000080205d8a <pipewrite>:

int pipewrite(struct pipe *pi, uint64 uaddr, int n)
{
    80205d8a:	7159                	addi	sp,sp,-112
    80205d8c:	f486                	sd	ra,104(sp)
    80205d8e:	f0a2                	sd	s0,96(sp)
    80205d90:	eca6                	sd	s1,88(sp)
    80205d92:	e8ca                	sd	s2,80(sp)
    80205d94:	e4ce                	sd	s3,72(sp)
    80205d96:	e0d2                	sd	s4,64(sp)
    80205d98:	fc56                	sd	s5,56(sp)
    80205d9a:	1880                	addi	s0,sp,112
    80205d9c:	84aa                	mv	s1,a0
    80205d9e:	8aae                	mv	s5,a1
    80205da0:	8a32                	mv	s4,a2
    struct proc *pr = myproc();
    80205da2:	ffffc097          	auipc	ra,0xffffc
    80205da6:	93c080e7          	jalr	-1732(ra) # 802016de <myproc>
    80205daa:	89aa                	mv	s3,a0
    int i = 0;

    acquire(&pi->lock);
    80205dac:	8526                	mv	a0,s1
    80205dae:	ffffb097          	auipc	ra,0xffffb
    80205db2:	552080e7          	jalr	1362(ra) # 80201300 <acquire>
    while (i < n) {
    80205db6:	0d405963          	blez	s4,80205e88 <pipewrite+0xfe>
    80205dba:	f85a                	sd	s6,48(sp)
    80205dbc:	f45e                	sd	s7,40(sp)
    80205dbe:	f062                	sd	s8,32(sp)
    80205dc0:	ec66                	sd	s9,24(sp)
    int i = 0;
    80205dc2:	4901                	li	s2,0
        if (pi->nwrite == pi->nread + PIPESIZE) {   /* full */
            wakeup(&pi->nread);
            sleep(&pi->nwrite, &pi->lock);
        } else {
            char ch;
            if (copyin(pr->pagetable, &ch, uaddr + i, 1) < 0) break;
    80205dc4:	f9f40b93          	addi	s7,s0,-97
    80205dc8:	4b05                	li	s6,1
            wakeup(&pi->nread);
    80205dca:	21848c93          	addi	s9,s1,536
            sleep(&pi->nwrite, &pi->lock);
    80205dce:	21c48c13          	addi	s8,s1,540
    80205dd2:	a091                	j	80205e16 <pipewrite+0x8c>
            release(&pi->lock);
    80205dd4:	8526                	mv	a0,s1
    80205dd6:	ffffb097          	auipc	ra,0xffffb
    80205dda:	5da080e7          	jalr	1498(ra) # 802013b0 <release>
            return -1;
    80205dde:	597d                	li	s2,-1
    80205de0:	7b42                	ld	s6,48(sp)
    80205de2:	7ba2                	ld	s7,40(sp)
    80205de4:	7c02                	ld	s8,32(sp)
    80205de6:	6ce2                	ld	s9,24(sp)
        }
    }
    wakeup(&pi->nread);
    release(&pi->lock);
    return i;
}
    80205de8:	854a                	mv	a0,s2
    80205dea:	70a6                	ld	ra,104(sp)
    80205dec:	7406                	ld	s0,96(sp)
    80205dee:	64e6                	ld	s1,88(sp)
    80205df0:	6946                	ld	s2,80(sp)
    80205df2:	69a6                	ld	s3,72(sp)
    80205df4:	6a06                	ld	s4,64(sp)
    80205df6:	7ae2                	ld	s5,56(sp)
    80205df8:	6165                	addi	sp,sp,112
    80205dfa:	8082                	ret
            wakeup(&pi->nread);
    80205dfc:	8566                	mv	a0,s9
    80205dfe:	ffffc097          	auipc	ra,0xffffc
    80205e02:	0d2080e7          	jalr	210(ra) # 80201ed0 <wakeup>
            sleep(&pi->nwrite, &pi->lock);
    80205e06:	85a6                	mv	a1,s1
    80205e08:	8562                	mv	a0,s8
    80205e0a:	ffffc097          	auipc	ra,0xffffc
    80205e0e:	f46080e7          	jalr	-186(ra) # 80201d50 <sleep>
    while (i < n) {
    80205e12:	05495b63          	bge	s2,s4,80205e68 <pipewrite+0xde>
        if (pi->readopen == 0 || pr->killed) {
    80205e16:	2204a783          	lw	a5,544(s1)
    80205e1a:	dfcd                	beqz	a5,80205dd4 <pipewrite+0x4a>
    80205e1c:	0289a783          	lw	a5,40(s3)
    80205e20:	fbd5                	bnez	a5,80205dd4 <pipewrite+0x4a>
        if (pi->nwrite == pi->nread + PIPESIZE) {   /* full */
    80205e22:	2184a783          	lw	a5,536(s1)
    80205e26:	21c4a703          	lw	a4,540(s1)
    80205e2a:	2007879b          	addiw	a5,a5,512
    80205e2e:	fcf707e3          	beq	a4,a5,80205dfc <pipewrite+0x72>
            if (copyin(pr->pagetable, &ch, uaddr + i, 1) < 0) break;
    80205e32:	86da                	mv	a3,s6
    80205e34:	01590633          	add	a2,s2,s5
    80205e38:	85de                	mv	a1,s7
    80205e3a:	0509b503          	ld	a0,80(s3)
    80205e3e:	ffffd097          	auipc	ra,0xffffd
    80205e42:	162080e7          	jalr	354(ra) # 80202fa0 <copyin>
    80205e46:	04054363          	bltz	a0,80205e8c <pipewrite+0x102>
            pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80205e4a:	21c4a783          	lw	a5,540(s1)
    80205e4e:	0017871b          	addiw	a4,a5,1
    80205e52:	20e4ae23          	sw	a4,540(s1)
    80205e56:	1ff7f793          	andi	a5,a5,511
    80205e5a:	97a6                	add	a5,a5,s1
    80205e5c:	f9f44703          	lbu	a4,-97(s0)
    80205e60:	00e78c23          	sb	a4,24(a5)
            i++;
    80205e64:	2905                	addiw	s2,s2,1
    80205e66:	b775                	j	80205e12 <pipewrite+0x88>
    80205e68:	7b42                	ld	s6,48(sp)
    80205e6a:	7ba2                	ld	s7,40(sp)
    80205e6c:	7c02                	ld	s8,32(sp)
    80205e6e:	6ce2                	ld	s9,24(sp)
    wakeup(&pi->nread);
    80205e70:	21848513          	addi	a0,s1,536
    80205e74:	ffffc097          	auipc	ra,0xffffc
    80205e78:	05c080e7          	jalr	92(ra) # 80201ed0 <wakeup>
    release(&pi->lock);
    80205e7c:	8526                	mv	a0,s1
    80205e7e:	ffffb097          	auipc	ra,0xffffb
    80205e82:	532080e7          	jalr	1330(ra) # 802013b0 <release>
    return i;
    80205e86:	b78d                	j	80205de8 <pipewrite+0x5e>
    int i = 0;
    80205e88:	4901                	li	s2,0
    80205e8a:	b7dd                	j	80205e70 <pipewrite+0xe6>
    80205e8c:	7b42                	ld	s6,48(sp)
    80205e8e:	7ba2                	ld	s7,40(sp)
    80205e90:	7c02                	ld	s8,32(sp)
    80205e92:	6ce2                	ld	s9,24(sp)
    80205e94:	bff1                	j	80205e70 <pipewrite+0xe6>

0000000080205e96 <piperead>:

int piperead(struct pipe *pi, uint64 uaddr, int n)
{
    80205e96:	711d                	addi	sp,sp,-96
    80205e98:	ec86                	sd	ra,88(sp)
    80205e9a:	e8a2                	sd	s0,80(sp)
    80205e9c:	e4a6                	sd	s1,72(sp)
    80205e9e:	e0ca                	sd	s2,64(sp)
    80205ea0:	fc4e                	sd	s3,56(sp)
    80205ea2:	f852                	sd	s4,48(sp)
    80205ea4:	f456                	sd	s5,40(sp)
    80205ea6:	1080                	addi	s0,sp,96
    80205ea8:	84aa                	mv	s1,a0
    80205eaa:	892e                	mv	s2,a1
    80205eac:	8ab2                	mv	s5,a2
    struct proc *pr = myproc();
    80205eae:	ffffc097          	auipc	ra,0xffffc
    80205eb2:	830080e7          	jalr	-2000(ra) # 802016de <myproc>
    80205eb6:	8a2a                	mv	s4,a0

    acquire(&pi->lock);
    80205eb8:	8526                	mv	a0,s1
    80205eba:	ffffb097          	auipc	ra,0xffffb
    80205ebe:	446080e7          	jalr	1094(ra) # 80201300 <acquire>
    while (pi->nread == pi->nwrite && pi->writeopen) {  /* empty, not EOF */
    80205ec2:	2184a703          	lw	a4,536(s1)
    80205ec6:	21c4a783          	lw	a5,540(s1)
        if (pr->killed) { release(&pi->lock); return -1; }
        sleep(&pi->nread, &pi->lock);
    80205eca:	21848993          	addi	s3,s1,536
    while (pi->nread == pi->nwrite && pi->writeopen) {  /* empty, not EOF */
    80205ece:	02f71763          	bne	a4,a5,80205efc <piperead+0x66>
    80205ed2:	2244a783          	lw	a5,548(s1)
    80205ed6:	cf8d                	beqz	a5,80205f10 <piperead+0x7a>
        if (pr->killed) { release(&pi->lock); return -1; }
    80205ed8:	028a2783          	lw	a5,40(s4)
    80205edc:	e39d                	bnez	a5,80205f02 <piperead+0x6c>
        sleep(&pi->nread, &pi->lock);
    80205ede:	85a6                	mv	a1,s1
    80205ee0:	854e                	mv	a0,s3
    80205ee2:	ffffc097          	auipc	ra,0xffffc
    80205ee6:	e6e080e7          	jalr	-402(ra) # 80201d50 <sleep>
    while (pi->nread == pi->nwrite && pi->writeopen) {  /* empty, not EOF */
    80205eea:	2184a703          	lw	a4,536(s1)
    80205eee:	21c4a783          	lw	a5,540(s1)
    80205ef2:	fef700e3          	beq	a4,a5,80205ed2 <piperead+0x3c>
    80205ef6:	f05a                	sd	s6,32(sp)
    80205ef8:	ec5e                	sd	s7,24(sp)
    80205efa:	a829                	j	80205f14 <piperead+0x7e>
    80205efc:	f05a                	sd	s6,32(sp)
    80205efe:	ec5e                	sd	s7,24(sp)
    80205f00:	a811                	j	80205f14 <piperead+0x7e>
        if (pr->killed) { release(&pi->lock); return -1; }
    80205f02:	8526                	mv	a0,s1
    80205f04:	ffffb097          	auipc	ra,0xffffb
    80205f08:	4ac080e7          	jalr	1196(ra) # 802013b0 <release>
    80205f0c:	59fd                	li	s3,-1
    80205f0e:	a0bd                	j	80205f7c <piperead+0xe6>
    80205f10:	f05a                	sd	s6,32(sp)
    80205f12:	ec5e                	sd	s7,24(sp)
    }
    int i;
    for (i = 0; i < n; i++) {
    80205f14:	4981                	li	s3,0
        if (pi->nread == pi->nwrite) break;             /* drained */
        char ch = pi->data[pi->nread++ % PIPESIZE];
        if (copyout(pr->pagetable, uaddr + i, &ch, 1) < 0) break;
    80205f16:	faf40b93          	addi	s7,s0,-81
    80205f1a:	4b05                	li	s6,1
    for (i = 0; i < n; i++) {
    80205f1c:	05505363          	blez	s5,80205f62 <piperead+0xcc>
        if (pi->nread == pi->nwrite) break;             /* drained */
    80205f20:	2184a783          	lw	a5,536(s1)
    80205f24:	21c4a703          	lw	a4,540(s1)
    80205f28:	02f70d63          	beq	a4,a5,80205f62 <piperead+0xcc>
        char ch = pi->data[pi->nread++ % PIPESIZE];
    80205f2c:	0017871b          	addiw	a4,a5,1
    80205f30:	20e4ac23          	sw	a4,536(s1)
    80205f34:	1ff7f793          	andi	a5,a5,511
    80205f38:	97a6                	add	a5,a5,s1
    80205f3a:	0187c783          	lbu	a5,24(a5)
    80205f3e:	faf407a3          	sb	a5,-81(s0)
        if (copyout(pr->pagetable, uaddr + i, &ch, 1) < 0) break;
    80205f42:	86da                	mv	a3,s6
    80205f44:	865e                	mv	a2,s7
    80205f46:	85ca                	mv	a1,s2
    80205f48:	050a3503          	ld	a0,80(s4)
    80205f4c:	ffffd097          	auipc	ra,0xffffd
    80205f50:	f92080e7          	jalr	-110(ra) # 80202ede <copyout>
    80205f54:	00054763          	bltz	a0,80205f62 <piperead+0xcc>
    for (i = 0; i < n; i++) {
    80205f58:	2985                	addiw	s3,s3,1
    80205f5a:	0905                	addi	s2,s2,1
    80205f5c:	fd3a92e3          	bne	s5,s3,80205f20 <piperead+0x8a>
    80205f60:	89d6                	mv	s3,s5
    }
    wakeup(&pi->nwrite);
    80205f62:	21c48513          	addi	a0,s1,540
    80205f66:	ffffc097          	auipc	ra,0xffffc
    80205f6a:	f6a080e7          	jalr	-150(ra) # 80201ed0 <wakeup>
    release(&pi->lock);
    80205f6e:	8526                	mv	a0,s1
    80205f70:	ffffb097          	auipc	ra,0xffffb
    80205f74:	440080e7          	jalr	1088(ra) # 802013b0 <release>
    80205f78:	7b02                	ld	s6,32(sp)
    80205f7a:	6be2                	ld	s7,24(sp)
    return i;                                           /* 0 here = EOF */
}
    80205f7c:	854e                	mv	a0,s3
    80205f7e:	60e6                	ld	ra,88(sp)
    80205f80:	6446                	ld	s0,80(sp)
    80205f82:	64a6                	ld	s1,72(sp)
    80205f84:	6906                	ld	s2,64(sp)
    80205f86:	79e2                	ld	s3,56(sp)
    80205f88:	7a42                	ld	s4,48(sp)
    80205f8a:	7aa2                	ld	s5,40(sp)
    80205f8c:	6125                	addi	sp,sp,96
    80205f8e:	8082                	ret

0000000080205f90 <hal_intc_init>:
#define PLIC_PRIORITY(irq)   (plic + (irq) * 4)
#define PLIC_SENABLE(h)      (plic + 0x2080 + (h) * 0x100)
#define PLIC_STHRESHOLD(h)   (plic + 0x201000 + (h) * 0x2000)
#define PLIC_SCLAIM(h)       (plic + 0x201004 + (h) * 0x2000)

void hal_intc_init(uint64 plic_base) { plic = plic_base; }
    80205f90:	1141                	addi	sp,sp,-16
    80205f92:	e406                	sd	ra,8(sp)
    80205f94:	e022                	sd	s0,0(sp)
    80205f96:	0800                	addi	s0,sp,16
    80205f98:	00139797          	auipc	a5,0x139
    80205f9c:	08a7b823          	sd	a0,144(a5) # 8033f028 <plic>
    80205fa0:	60a2                	ld	ra,8(sp)
    80205fa2:	6402                	ld	s0,0(sp)
    80205fa4:	0141                	addi	sp,sp,16
    80205fa6:	8082                	ret

0000000080205fa8 <hal_intc_enable>:

void hal_intc_enable(int irq)
{
    80205fa8:	1141                	addi	sp,sp,-16
    80205faa:	e406                	sd	ra,8(sp)
    80205fac:	e022                	sd	s0,0(sp)
    80205fae:	0800                	addi	s0,sp,16
    if (!plic) return;
    80205fb0:	00139797          	auipc	a5,0x139
    80205fb4:	0787b783          	ld	a5,120(a5) # 8033f028 <plic>
    80205fb8:	c791                	beqz	a5,80205fc4 <hal_intc_enable+0x1c>
    *(volatile uint32 *)PLIC_PRIORITY(irq) = 1;   /* priority 0 = never fire */
    80205fba:	0025151b          	slliw	a0,a0,0x2
    80205fbe:	953e                	add	a0,a0,a5
    80205fc0:	4785                	li	a5,1
    80205fc2:	c11c                	sw	a5,0(a0)
}
    80205fc4:	60a2                	ld	ra,8(sp)
    80205fc6:	6402                	ld	s0,0(sp)
    80205fc8:	0141                	addi	sp,sp,16
    80205fca:	8082                	ret

0000000080205fcc <hal_intc_hart_init>:

void hal_intc_hart_init(int hart)
{
    80205fcc:	1141                	addi	sp,sp,-16
    80205fce:	e406                	sd	ra,8(sp)
    80205fd0:	e022                	sd	s0,0(sp)
    80205fd2:	0800                	addi	s0,sp,16
    if (!plic) return;
    80205fd4:	00139797          	auipc	a5,0x139
    80205fd8:	0547b783          	ld	a5,84(a5) # 8033f028 <plic>
    80205fdc:	cb89                	beqz	a5,80205fee <hal_intc_hart_init+0x22>
    *(volatile uint32 *)PLIC_STHRESHOLD(hart) = 0; /* accept any priority > 0 */
    80205fde:	00d5151b          	slliw	a0,a0,0xd
    80205fe2:	00201737          	lui	a4,0x201
    80205fe6:	97ba                	add	a5,a5,a4
    80205fe8:	953e                	add	a0,a0,a5
    80205fea:	00052023          	sw	zero,0(a0)
}
    80205fee:	60a2                	ld	ra,8(sp)
    80205ff0:	6402                	ld	s0,0(sp)
    80205ff2:	0141                	addi	sp,sp,16
    80205ff4:	8082                	ret

0000000080205ff6 <hal_intc_enable_hart>:

/* Enable irq for this hart (must be called after hal_intc_enable). */
void hal_intc_enable_hart(int hart, int irq)
{
    80205ff6:	1141                	addi	sp,sp,-16
    80205ff8:	e406                	sd	ra,8(sp)
    80205ffa:	e022                	sd	s0,0(sp)
    80205ffc:	0800                	addi	s0,sp,16
    if (!plic) return;
    80205ffe:	00139797          	auipc	a5,0x139
    80206002:	02a7b783          	ld	a5,42(a5) # 8033f028 <plic>
    80206006:	c79d                	beqz	a5,80206034 <hal_intc_enable_hart+0x3e>
    volatile uint32 *en = (volatile uint32 *)PLIC_SENABLE(hart);
    80206008:	0085151b          	slliw	a0,a0,0x8
    8020600c:	6709                	lui	a4,0x2
    8020600e:	08070713          	addi	a4,a4,128 # 2080 <_entry-0x801fdf80>
    80206012:	97ba                	add	a5,a5,a4
    80206014:	953e                	add	a0,a0,a5
    en[irq / 32] |= (1u << (irq % 32));
    80206016:	41f5d79b          	sraiw	a5,a1,0x1f
    8020601a:	01b7d79b          	srliw	a5,a5,0x1b
    8020601e:	9fad                	addw	a5,a5,a1
    80206020:	4057d79b          	sraiw	a5,a5,0x5
    80206024:	078a                	slli	a5,a5,0x2
    80206026:	953e                	add	a0,a0,a5
    80206028:	411c                	lw	a5,0(a0)
    8020602a:	4705                	li	a4,1
    8020602c:	00b7173b          	sllw	a4,a4,a1
    80206030:	8fd9                	or	a5,a5,a4
    80206032:	c11c                	sw	a5,0(a0)
}
    80206034:	60a2                	ld	ra,8(sp)
    80206036:	6402                	ld	s0,0(sp)
    80206038:	0141                	addi	sp,sp,16
    8020603a:	8082                	ret

000000008020603c <hal_intc_claim>:

int hal_intc_claim(void)
{
    8020603c:	1141                	addi	sp,sp,-16
    8020603e:	e406                	sd	ra,8(sp)
    80206040:	e022                	sd	s0,0(sp)
    80206042:	0800                	addi	s0,sp,16
    if (!plic) return 0;
    80206044:	00139797          	auipc	a5,0x139
    80206048:	fe47b783          	ld	a5,-28(a5) # 8033f028 <plic>
    8020604c:	4501                	li	a0,0
    8020604e:	e789                	bnez	a5,80206058 <hal_intc_claim+0x1c>
    return *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id());
}
    80206050:	60a2                	ld	ra,8(sp)
    80206052:	6402                	ld	s0,0(sp)
    80206054:	0141                	addi	sp,sp,16
    80206056:	8082                	ret
static inline uint64 r_tp(void){ uint64 x; asm volatile("mv %0, tp":"=r"(x)); return x; }
    80206058:	8712                	mv	a4,tp
    return *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id());
    8020605a:	00d7171b          	slliw	a4,a4,0xd
    8020605e:	002016b7          	lui	a3,0x201
    80206062:	0691                	addi	a3,a3,4 # 201004 <_entry-0x7fffeffc>
    80206064:	97b6                	add	a5,a5,a3
    80206066:	97ba                	add	a5,a5,a4
    80206068:	4388                	lw	a0,0(a5)
    8020606a:	2501                	sext.w	a0,a0
    8020606c:	b7d5                	j	80206050 <hal_intc_claim+0x14>

000000008020606e <hal_intc_complete>:

void hal_intc_complete(int irq)
{
    8020606e:	1141                	addi	sp,sp,-16
    80206070:	e406                	sd	ra,8(sp)
    80206072:	e022                	sd	s0,0(sp)
    80206074:	0800                	addi	s0,sp,16
    if (!plic) return;
    80206076:	00139797          	auipc	a5,0x139
    8020607a:	fb27b783          	ld	a5,-78(a5) # 8033f028 <plic>
    8020607e:	e789                	bnez	a5,80206088 <hal_intc_complete+0x1a>
    *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id()) = irq;
}
    80206080:	60a2                	ld	ra,8(sp)
    80206082:	6402                	ld	s0,0(sp)
    80206084:	0141                	addi	sp,sp,16
    80206086:	8082                	ret
    80206088:	8712                	mv	a4,tp
    *(volatile uint32 *)PLIC_SCLAIM(hal_hart_id()) = irq;
    8020608a:	00d7171b          	slliw	a4,a4,0xd
    8020608e:	002016b7          	lui	a3,0x201
    80206092:	0691                	addi	a3,a3,4 # 201004 <_entry-0x7fffeffc>
    80206094:	97b6                	add	a5,a5,a3
    80206096:	97ba                	add	a5,a5,a4
    80206098:	c388                	sw	a0,0(a5)
    8020609a:	b7dd                	j	80206080 <hal_intc_complete+0x12>

000000008020609c <hal_hart_id>:

int hal_hart_id(void) { return (int)r_tp(); }
    8020609c:	1141                	addi	sp,sp,-16
    8020609e:	e406                	sd	ra,8(sp)
    802060a0:	e022                	sd	s0,0(sp)
    802060a2:	0800                	addi	s0,sp,16
    802060a4:	8512                	mv	a0,tp
    802060a6:	2501                	sext.w	a0,a0
    802060a8:	60a2                	ld	ra,8(sp)
    802060aa:	6402                	ld	s0,0(sp)
    802060ac:	0141                	addi	sp,sp,16
    802060ae:	8082                	ret

00000000802060b0 <plic_dbg>:

int plic_dbg(int which)
{
    802060b0:	1141                	addi	sp,sp,-16
    802060b2:	e406                	sd	ra,8(sp)
    802060b4:	e022                	sd	s0,0(sp)
    802060b6:	0800                	addi	s0,sp,16
    if (which == 0) return *(volatile uint32 *)PLIC_PRIORITY(10);
    802060b8:	cd19                	beqz	a0,802060d6 <plic_dbg+0x26>
    return *(volatile uint32 *)PLIC_SENABLE(0);
    802060ba:	00139797          	auipc	a5,0x139
    802060be:	f6e7b783          	ld	a5,-146(a5) # 8033f028 <plic>
    802060c2:	6709                	lui	a4,0x2
    802060c4:	08070713          	addi	a4,a4,128 # 2080 <_entry-0x801fdf80>
    802060c8:	97ba                	add	a5,a5,a4
    802060ca:	4388                	lw	a0,0(a5)
    802060cc:	2501                	sext.w	a0,a0
}
    802060ce:	60a2                	ld	ra,8(sp)
    802060d0:	6402                	ld	s0,0(sp)
    802060d2:	0141                	addi	sp,sp,16
    802060d4:	8082                	ret
    if (which == 0) return *(volatile uint32 *)PLIC_PRIORITY(10);
    802060d6:	00139797          	auipc	a5,0x139
    802060da:	f527b783          	ld	a5,-174(a5) # 8033f028 <plic>
    802060de:	5788                	lw	a0,40(a5)
    802060e0:	2501                	sext.w	a0,a0
    802060e2:	b7f5                	j	802060ce <plic_dbg+0x1e>

00000000802060e4 <hal_time_read>:
#include "hal.h"
#include "riscv.h"
#include "defs.h"

void    hal_timer_init(void)          { hal_timer_next(1000000); }
uint64  hal_time_read(void)           { return r_time(); }
    802060e4:	1141                	addi	sp,sp,-16
    802060e6:	e406                	sd	ra,8(sp)
    802060e8:	e022                	sd	s0,0(sp)
    802060ea:	0800                	addi	s0,sp,16
static inline uint64 r_time(void){ uint64 x; asm volatile("rdtime %0":"=r"(x)); return x; }
    802060ec:	c0102573          	rdtime	a0
    802060f0:	60a2                	ld	ra,8(sp)
    802060f2:	6402                	ld	s0,0(sp)
    802060f4:	0141                	addi	sp,sp,16
    802060f6:	8082                	ret

00000000802060f8 <hal_timer_set>:
void    hal_timer_set(uint64 dl)      { sbi_set_timer(dl); }
    802060f8:	1141                	addi	sp,sp,-16
    802060fa:	e406                	sd	ra,8(sp)
    802060fc:	e022                	sd	s0,0(sp)
    802060fe:	0800                	addi	s0,sp,16
    80206100:	ffffa097          	auipc	ra,0xffffa
    80206104:	6ce080e7          	jalr	1742(ra) # 802007ce <sbi_set_timer>
    80206108:	60a2                	ld	ra,8(sp)
    8020610a:	6402                	ld	s0,0(sp)
    8020610c:	0141                	addi	sp,sp,16
    8020610e:	8082                	ret

0000000080206110 <hal_timer_ack>:
void    hal_timer_ack(void)           { /* SBI: next set_timer clears STIP */ }
    80206110:	1141                	addi	sp,sp,-16
    80206112:	e406                	sd	ra,8(sp)
    80206114:	e022                	sd	s0,0(sp)
    80206116:	0800                	addi	s0,sp,16
    80206118:	60a2                	ld	ra,8(sp)
    8020611a:	6402                	ld	s0,0(sp)
    8020611c:	0141                	addi	sp,sp,16
    8020611e:	8082                	ret

0000000080206120 <hal_timer_next>:
void    hal_timer_next(uint64 iv)     { hal_timer_set(hal_time_read() + iv); }
    80206120:	1141                	addi	sp,sp,-16
    80206122:	e406                	sd	ra,8(sp)
    80206124:	e022                	sd	s0,0(sp)
    80206126:	0800                	addi	s0,sp,16
    80206128:	c01027f3          	rdtime	a5
void    hal_timer_set(uint64 dl)      { sbi_set_timer(dl); }
    8020612c:	953e                	add	a0,a0,a5
    8020612e:	ffffa097          	auipc	ra,0xffffa
    80206132:	6a0080e7          	jalr	1696(ra) # 802007ce <sbi_set_timer>
void    hal_timer_next(uint64 iv)     { hal_timer_set(hal_time_read() + iv); }
    80206136:	60a2                	ld	ra,8(sp)
    80206138:	6402                	ld	s0,0(sp)
    8020613a:	0141                	addi	sp,sp,16
    8020613c:	8082                	ret

000000008020613e <hal_timer_init>:
void    hal_timer_init(void)          { hal_timer_next(1000000); }
    8020613e:	1141                	addi	sp,sp,-16
    80206140:	e406                	sd	ra,8(sp)
    80206142:	e022                	sd	s0,0(sp)
    80206144:	0800                	addi	s0,sp,16
    80206146:	000f4537          	lui	a0,0xf4
    8020614a:	24050513          	addi	a0,a0,576 # f4240 <_entry-0x8010bdc0>
    8020614e:	00000097          	auipc	ra,0x0
    80206152:	fd2080e7          	jalr	-46(ra) # 80206120 <hal_timer_next>
    80206156:	60a2                	ld	ra,8(sp)
    80206158:	6402                	ld	s0,0(sp)
    8020615a:	0141                	addi	sp,sp,16
    8020615c:	8082                	ret

000000008020615e <hal_console_init>:
#define LSR 5   /* line status              */
#define LSR_RX_READY  (1 << 0)
#define LSR_TX_IDLE   (1 << 5)

void hal_console_init(uint64 uart_base)
{
    8020615e:	1141                	addi	sp,sp,-16
    80206160:	e406                	sd	ra,8(sp)
    80206162:	e022                	sd	s0,0(sp)
    80206164:	0800                	addi	s0,sp,16
    uart = (volatile uint8 *)uart_base;
    80206166:	00139797          	auipc	a5,0x139
    8020616a:	eca7b523          	sd	a0,-310(a5) # 8033f030 <uart>
    uart[IER] = 0x00;              /* interrupts off while we configure */
    8020616e:	000500a3          	sb	zero,1(a0)
    uart[LCR] = 0x80;              /* DLAB=1: divisor latch visible     */
    80206172:	f8000793          	li	a5,-128
    80206176:	00f501a3          	sb	a5,3(a0)
    uart[0]   = 0x03;              /* divisor low: 38.4K                */
    8020617a:	478d                	li	a5,3
    8020617c:	00f50023          	sb	a5,0(a0)
    uart[1]   = 0x00;              /* divisor high                      */
    80206180:	000500a3          	sb	zero,1(a0)
    uart[LCR] = 0x03;              /* DLAB=0, 8 bits, no parity, 1 stop */
    80206184:	00f501a3          	sb	a5,3(a0)
    uart[FCR] = 0x07;              /* enable + clear FIFOs              */
    80206188:	479d                	li	a5,7
    8020618a:	00f50123          	sb	a5,2(a0)
    uart[IER] = 0x01;              /* receive interrupts on             */
    8020618e:	4785                	li	a5,1
    80206190:	00f500a3          	sb	a5,1(a0)
}
    80206194:	60a2                	ld	ra,8(sp)
    80206196:	6402                	ld	s0,0(sp)
    80206198:	0141                	addi	sp,sp,16
    8020619a:	8082                	ret

000000008020619c <hal_console_putc>:

void hal_console_putc(char c)
{
    8020619c:	1141                	addi	sp,sp,-16
    8020619e:	e406                	sd	ra,8(sp)
    802061a0:	e022                	sd	s0,0(sp)
    802061a2:	0800                	addi	s0,sp,16
    if (!uart) { return; }
    802061a4:	00139717          	auipc	a4,0x139
    802061a8:	e8c73703          	ld	a4,-372(a4) # 8033f030 <uart>
    802061ac:	cb01                	beqz	a4,802061bc <hal_console_putc+0x20>
    while ((uart[LSR] & LSR_TX_IDLE) == 0)   /* wait for the holding reg */
    802061ae:	00574783          	lbu	a5,5(a4)
    802061b2:	0207f793          	andi	a5,a5,32
    802061b6:	dfe5                	beqz	a5,802061ae <hal_console_putc+0x12>
        ;
    uart[THR] = c;
    802061b8:	00a70023          	sb	a0,0(a4)
}
    802061bc:	60a2                	ld	ra,8(sp)
    802061be:	6402                	ld	s0,0(sp)
    802061c0:	0141                	addi	sp,sp,16
    802061c2:	8082                	ret

00000000802061c4 <hal_console_getc>:

int hal_console_getc(void)
{
    802061c4:	1141                	addi	sp,sp,-16
    802061c6:	e406                	sd	ra,8(sp)
    802061c8:	e022                	sd	s0,0(sp)
    802061ca:	0800                	addi	s0,sp,16
    if (!uart) return -1;
    802061cc:	00139717          	auipc	a4,0x139
    802061d0:	e6473703          	ld	a4,-412(a4) # 8033f030 <uart>
    802061d4:	cb19                	beqz	a4,802061ea <hal_console_getc+0x26>
    if (uart[LSR] & LSR_RX_READY)
    802061d6:	00574783          	lbu	a5,5(a4)
    802061da:	8b85                	andi	a5,a5,1
    802061dc:	cb89                	beqz	a5,802061ee <hal_console_getc+0x2a>
        return uart[RHR];
    802061de:	00074503          	lbu	a0,0(a4)
    return -1;
}
    802061e2:	60a2                	ld	ra,8(sp)
    802061e4:	6402                	ld	s0,0(sp)
    802061e6:	0141                	addi	sp,sp,16
    802061e8:	8082                	ret
    if (!uart) return -1;
    802061ea:	557d                	li	a0,-1
    802061ec:	bfdd                	j	802061e2 <hal_console_getc+0x1e>
    return -1;
    802061ee:	557d                	li	a0,-1
    802061f0:	bfcd                	j	802061e2 <hal_console_getc+0x1e>

00000000802061f2 <free_desc>:
    for (int i = 0; i < VNUM; i++)
        if (vdisk.free[i]) { vdisk.free[i] = 0; return i; }
    return -1;
}
static void free_desc(int i)
{
    802061f2:	1141                	addi	sp,sp,-16
    802061f4:	e406                	sd	ra,8(sp)
    802061f6:	e022                	sd	s0,0(sp)
    802061f8:	0800                	addi	s0,sp,16
    if (i >= VNUM)      panic("virtio_blk: free_desc index");
    802061fa:	479d                	li	a5,7
    802061fc:	04a7c663          	blt	a5,a0,80206248 <free_desc+0x56>
    if (vdisk.free[i])  panic("virtio_blk: double free_desc");   /* I1 */
    80206200:	00136797          	auipc	a5,0x136
    80206204:	e0078793          	addi	a5,a5,-512 # 8033c000 <vdisk>
    80206208:	97aa                	add	a5,a5,a0
    8020620a:	0287c783          	lbu	a5,40(a5)
    8020620e:	e7a9                	bnez	a5,80206258 <free_desc+0x66>
    vdisk.desc[i] = (struct virtq_desc){0};
    80206210:	00136797          	auipc	a5,0x136
    80206214:	df078793          	addi	a5,a5,-528 # 8033c000 <vdisk>
    80206218:	6b98                	ld	a4,16(a5)
    8020621a:	00451693          	slli	a3,a0,0x4
    8020621e:	9736                	add	a4,a4,a3
    80206220:	00073023          	sd	zero,0(a4)
    80206224:	00073423          	sd	zero,8(a4)
    vdisk.free[i] = 1;
    80206228:	97aa                	add	a5,a5,a0
    8020622a:	4705                	li	a4,1
    8020622c:	02e78423          	sb	a4,40(a5)
    wakeup(&vdisk.free[0]);
    80206230:	00136517          	auipc	a0,0x136
    80206234:	df850513          	addi	a0,a0,-520 # 8033c028 <vdisk+0x28>
    80206238:	ffffc097          	auipc	ra,0xffffc
    8020623c:	c98080e7          	jalr	-872(ra) # 80201ed0 <wakeup>
}
    80206240:	60a2                	ld	ra,8(sp)
    80206242:	6402                	ld	s0,0(sp)
    80206244:	0141                	addi	sp,sp,16
    80206246:	8082                	ret
    if (i >= VNUM)      panic("virtio_blk: free_desc index");
    80206248:	00002517          	auipc	a0,0x2
    8020624c:	9f050513          	addi	a0,a0,-1552 # 80207c38 <etext+0xc38>
    80206250:	ffffa097          	auipc	ra,0xffffa
    80206254:	360080e7          	jalr	864(ra) # 802005b0 <panic>
    if (vdisk.free[i])  panic("virtio_blk: double free_desc");   /* I1 */
    80206258:	00002517          	auipc	a0,0x2
    8020625c:	a0050513          	addi	a0,a0,-1536 # 80207c58 <etext+0xc58>
    80206260:	ffffa097          	auipc	ra,0xffffa
    80206264:	350080e7          	jalr	848(ra) # 802005b0 <panic>

0000000080206268 <hal_block_irq>:
int hal_block_irq(void) { return vdisk.base ? vdisk.irq : 0; }
    80206268:	1141                	addi	sp,sp,-16
    8020626a:	e406                	sd	ra,8(sp)
    8020626c:	e022                	sd	s0,0(sp)
    8020626e:	0800                	addi	s0,sp,16
    80206270:	00136797          	auipc	a5,0x136
    80206274:	d907b783          	ld	a5,-624(a5) # 8033c000 <vdisk>
    80206278:	4501                	li	a0,0
    8020627a:	c789                	beqz	a5,80206284 <hal_block_irq+0x1c>
    8020627c:	00136517          	auipc	a0,0x136
    80206280:	d8c52503          	lw	a0,-628(a0) # 8033c008 <vdisk+0x8>
    80206284:	60a2                	ld	ra,8(sp)
    80206286:	6402                	ld	s0,0(sp)
    80206288:	0141                	addi	sp,sp,16
    8020628a:	8082                	ret

000000008020628c <hal_block_init>:
{
    8020628c:	7139                	addi	sp,sp,-64
    8020628e:	fc06                	sd	ra,56(sp)
    80206290:	f822                	sd	s0,48(sp)
    80206292:	f426                	sd	s1,40(sp)
    80206294:	0080                	addi	s0,sp,64
    initlock(&vdisk.lock, "virtio_blk");
    80206296:	00002597          	auipc	a1,0x2
    8020629a:	9e258593          	addi	a1,a1,-1566 # 80207c78 <etext+0xc78>
    8020629e:	00136517          	auipc	a0,0x136
    802062a2:	e9a50513          	addi	a0,a0,-358 # 8033c138 <vdisk+0x138>
    802062a6:	ffffb097          	auipc	ra,0xffffb
    802062aa:	fda080e7          	jalr	-38(ra) # 80201280 <initlock>
    for (int i = 0; i < fdt.nvirtio; i++) {
    802062ae:	00023797          	auipc	a5,0x23
    802062b2:	df27a783          	lw	a5,-526(a5) # 802290a0 <fdt+0x88>
    802062b6:	08f05c63          	blez	a5,8020634e <hal_block_init+0xc2>
    802062ba:	f04a                	sd	s2,32(sp)
    802062bc:	ec4e                	sd	s3,24(sp)
    802062be:	e852                	sd	s4,16(sp)
    802062c0:	e456                	sd	s5,8(sp)
    802062c2:	e05a                	sd	s6,0(sp)
    802062c4:	00023917          	auipc	s2,0x23
    802062c8:	d5490913          	addi	s2,s2,-684 # 80229018 <fdt>
    802062cc:	4481                	li	s1,0
        if (*magic == 0x74726976 && *devid == 2 && (*vers == 1 || *vers == 2)) {
    802062ce:	747279b7          	lui	s3,0x74727
    802062d2:	97698993          	addi	s3,s3,-1674 # 74726976 <_entry-0xbad968a>
    802062d6:	4a89                	li	s5,2
    802062d8:	4b05                	li	s6,1
    for (int i = 0; i < fdt.nvirtio; i++) {
    802062da:	8a4a                	mv	s4,s2
    802062dc:	a039                	j	802062ea <hal_block_init+0x5e>
    802062de:	2485                	addiw	s1,s1,1
    802062e0:	0921                	addi	s2,s2,8
    802062e2:	088a2783          	lw	a5,136(s4)
    802062e6:	04f4df63          	bge	s1,a5,80206344 <hal_block_init+0xb8>
        uint64 va = mmio_alias(fdt.virtio_base[i]);
    802062ea:	02893503          	ld	a0,40(s2)
    802062ee:	ffffc097          	auipc	ra,0xffffc
    802062f2:	6fe080e7          	jalr	1790(ra) # 802029ec <mmio_alias>
        if (*magic == 0x74726976 && *devid == 2 && (*vers == 1 || *vers == 2)) {
    802062f6:	411c                	lw	a5,0(a0)
    802062f8:	2781                	sext.w	a5,a5
    802062fa:	ff3792e3          	bne	a5,s3,802062de <hal_block_init+0x52>
    802062fe:	451c                	lw	a5,8(a0)
    80206300:	2781                	sext.w	a5,a5
    80206302:	fd579ee3          	bne	a5,s5,802062de <hal_block_init+0x52>
    80206306:	415c                	lw	a5,4(a0)
    80206308:	2781                	sext.w	a5,a5
    8020630a:	01678663          	beq	a5,s6,80206316 <hal_block_init+0x8a>
    8020630e:	415c                	lw	a5,4(a0)
    80206310:	2781                	sext.w	a5,a5
    80206312:	fd5796e3          	bne	a5,s5,802062de <hal_block_init+0x52>
            vdisk.base    = va;
    80206316:	00136717          	auipc	a4,0x136
    8020631a:	cea70713          	addi	a4,a4,-790 # 8033c000 <vdisk>
    8020631e:	e308                	sd	a0,0(a4)
            vdisk.irq     = fdt.virtio_irq[i];
    80206320:	01848793          	addi	a5,s1,24
    80206324:	078a                	slli	a5,a5,0x2
    80206326:	00023697          	auipc	a3,0x23
    8020632a:	cf268693          	addi	a3,a3,-782 # 80229018 <fdt>
    8020632e:	97b6                	add	a5,a5,a3
    80206330:	479c                	lw	a5,8(a5)
    80206332:	c71c                	sw	a5,8(a4)
            vdisk.version = *vers;
    80206334:	415c                	lw	a5,4(a0)
    80206336:	c75c                	sw	a5,12(a4)
            break;
    80206338:	7902                	ld	s2,32(sp)
    8020633a:	69e2                	ld	s3,24(sp)
    8020633c:	6a42                	ld	s4,16(sp)
    8020633e:	6aa2                	ld	s5,8(sp)
    80206340:	6b02                	ld	s6,0(sp)
    80206342:	a031                	j	8020634e <hal_block_init+0xc2>
    80206344:	7902                	ld	s2,32(sp)
    80206346:	69e2                	ld	s3,24(sp)
    80206348:	6a42                	ld	s4,16(sp)
    8020634a:	6aa2                	ld	s5,8(sp)
    8020634c:	6b02                	ld	s6,0(sp)
    if (!vdisk.base) return -1;                   /* no disk on this board */
    8020634e:	00136797          	auipc	a5,0x136
    80206352:	cb27b783          	ld	a5,-846(a5) # 8033c000 <vdisk>
    80206356:	1a078363          	beqz	a5,802064fc <hal_block_init+0x270>
    *R(VIRTIO_MMIO_STATUS) = 0;
    8020635a:	0607a823          	sw	zero,112(a5)
    *R(VIRTIO_MMIO_STATUS) = status;
    8020635e:	00136797          	auipc	a5,0x136
    80206362:	ca278793          	addi	a5,a5,-862 # 8033c000 <vdisk>
    80206366:	6398                	ld	a4,0(a5)
    80206368:	4685                	li	a3,1
    8020636a:	db34                	sw	a3,112(a4)
    *R(VIRTIO_MMIO_STATUS) = status;
    8020636c:	6398                	ld	a4,0(a5)
    8020636e:	468d                	li	a3,3
    80206370:	db34                	sw	a3,112(a4)
    uint32 feats = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80206372:	6390                	ld	a2,0(a5)
    80206374:	4a18                	lw	a4,16(a2)
    feats &= ~(1u << VIRTIO_RING_F_EVENT_IDX);
    80206376:	c7ffe6b7          	lui	a3,0xc7ffe
    8020637a:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <uart+0xffffffff47cbf72f>
    8020637e:	8f75                	and	a4,a4,a3
    *R(VIRTIO_MMIO_DRIVER_FEATURES) = feats;
    80206380:	d218                	sw	a4,32(a2)
    if (vdisk.version == 2) {
    80206382:	47d8                	lw	a4,12(a5)
    80206384:	4789                	li	a5,2
    status |= VIRTIO_CONFIG_S_DRIVER;
    80206386:	448d                	li	s1,3
    if (vdisk.version == 2) {
    80206388:	0ef70563          	beq	a4,a5,80206472 <hal_block_init+0x1e6>
    *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8020638c:	00136797          	auipc	a5,0x136
    80206390:	c7478793          	addi	a5,a5,-908 # 8033c000 <vdisk>
    80206394:	6398                	ld	a4,0(a5)
    80206396:	02072823          	sw	zero,48(a4)
    uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8020639a:	6398                	ld	a4,0(a5)
    8020639c:	5b5c                	lw	a5,52(a4)
    8020639e:	2781                	sext.w	a5,a5
    if (max == 0)  panic("virtio_blk: queue 0 does not exist");
    802063a0:	10078263          	beqz	a5,802064a4 <hal_block_init+0x218>
    if (max < VNUM) panic("virtio_blk: queue too short");
    802063a4:	469d                	li	a3,7
    802063a6:	10f6fc63          	bgeu	a3,a5,802064be <hal_block_init+0x232>
    *R(VIRTIO_MMIO_QUEUE_NUM) = VNUM;
    802063aa:	47a1                	li	a5,8
    802063ac:	df1c                	sw	a5,56(a4)
    memset(pages, 0, sizeof(pages));
    802063ae:	6609                	lui	a2,0x2
    802063b0:	4581                	li	a1,0
    802063b2:	00137517          	auipc	a0,0x137
    802063b6:	c4e50513          	addi	a0,a0,-946 # 8033d000 <pages.0>
    802063ba:	ffffa097          	auipc	ra,0xffffa
    802063be:	29c080e7          	jalr	668(ra) # 80200656 <memset>
    vdisk.desc  = (struct virtq_desc *)pages;
    802063c2:	00136797          	auipc	a5,0x136
    802063c6:	c3e78793          	addi	a5,a5,-962 # 8033c000 <vdisk>
    802063ca:	00137717          	auipc	a4,0x137
    802063ce:	c3670713          	addi	a4,a4,-970 # 8033d000 <pages.0>
    802063d2:	eb98                	sd	a4,16(a5)
    vdisk.avail = (struct virtq_avail *)(pages + VNUM * sizeof(struct virtq_desc));
    802063d4:	00137717          	auipc	a4,0x137
    802063d8:	cac70713          	addi	a4,a4,-852 # 8033d080 <pages.0+0x80>
    802063dc:	ef98                	sd	a4,24(a5)
    vdisk.used  = (struct virtq_used *)(pages + PGSIZE);
    802063de:	00138717          	auipc	a4,0x138
    802063e2:	c2270713          	addi	a4,a4,-990 # 8033e000 <pages.0+0x1000>
    802063e6:	f398                	sd	a4,32(a5)
    if (vdisk.version == 1) {
    802063e8:	47d8                	lw	a4,12(a5)
    802063ea:	4785                	li	a5,1
    802063ec:	0ef70663          	beq	a4,a5,802064d8 <hal_block_init+0x24c>
        *R(VIRTIO_MMIO_QUEUE_DESC_LOW)   = (uint64)vdisk.desc;
    802063f0:	00136797          	auipc	a5,0x136
    802063f4:	c1078793          	addi	a5,a5,-1008 # 8033c000 <vdisk>
    802063f8:	6398                	ld	a4,0(a5)
    802063fa:	00137697          	auipc	a3,0x137
    802063fe:	c0668693          	addi	a3,a3,-1018 # 8033d000 <pages.0>
    80206402:	08d72023          	sw	a3,128(a4)
        *R(VIRTIO_MMIO_QUEUE_DESC_HIGH)  = (uint64)vdisk.desc >> 32;
    80206406:	6398                	ld	a4,0(a5)
    80206408:	4bd4                	lw	a3,20(a5)
    8020640a:	08d72223          	sw	a3,132(a4)
        *R(VIRTIO_MMIO_DRIVER_DESC_LOW)  = (uint64)vdisk.avail;
    8020640e:	6398                	ld	a4,0(a5)
    80206410:	4f94                	lw	a3,24(a5)
    80206412:	08d72823          	sw	a3,144(a4)
        *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)vdisk.avail >> 32;
    80206416:	6398                	ld	a4,0(a5)
    80206418:	4fd4                	lw	a3,28(a5)
    8020641a:	08d72a23          	sw	a3,148(a4)
        *R(VIRTIO_MMIO_DEVICE_DESC_LOW)  = (uint64)vdisk.used;
    8020641e:	6398                	ld	a4,0(a5)
    80206420:	5394                	lw	a3,32(a5)
    80206422:	0ad72023          	sw	a3,160(a4)
        *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)vdisk.used >> 32;
    80206426:	6398                	ld	a4,0(a5)
    80206428:	53d4                	lw	a3,36(a5)
    8020642a:	0ad72223          	sw	a3,164(a4)
        *R(VIRTIO_MMIO_QUEUE_READY) = 1;
    8020642e:	639c                	ld	a5,0(a5)
    80206430:	4705                	li	a4,1
    80206432:	c3f8                	sw	a4,68(a5)
    for (int i = 0; i < VNUM; i++) vdisk.free[i] = 1;
    80206434:	00136797          	auipc	a5,0x136
    80206438:	bcc78793          	addi	a5,a5,-1076 # 8033c000 <vdisk>
    8020643c:	4705                	li	a4,1
    8020643e:	02e78423          	sb	a4,40(a5)
    80206442:	02e784a3          	sb	a4,41(a5)
    80206446:	02e78523          	sb	a4,42(a5)
    8020644a:	02e785a3          	sb	a4,43(a5)
    8020644e:	02e78623          	sb	a4,44(a5)
    80206452:	02e786a3          	sb	a4,45(a5)
    80206456:	02e78723          	sb	a4,46(a5)
    8020645a:	02e787a3          	sb	a4,47(a5)
    status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8020645e:	0044e493          	ori	s1,s1,4
    *R(VIRTIO_MMIO_STATUS) = status;
    80206462:	639c                	ld	a5,0(a5)
    80206464:	dba4                	sw	s1,112(a5)
    return 0;
    80206466:	4501                	li	a0,0
}
    80206468:	70e2                	ld	ra,56(sp)
    8020646a:	7442                	ld	s0,48(sp)
    8020646c:	74a2                	ld	s1,40(sp)
    8020646e:	6121                	addi	sp,sp,64
    80206470:	8082                	ret
        *R(VIRTIO_MMIO_STATUS) = status;
    80206472:	00136797          	auipc	a5,0x136
    80206476:	b8e78793          	addi	a5,a5,-1138 # 8033c000 <vdisk>
    8020647a:	6398                	ld	a4,0(a5)
    8020647c:	46ad                	li	a3,11
    8020647e:	db34                	sw	a3,112(a4)
        if (!(*R(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80206480:	639c                	ld	a5,0(a5)
    80206482:	5bbc                	lw	a5,112(a5)
    80206484:	8ba1                	andi	a5,a5,8
        status |= VIRTIO_CONFIG_S_FEATURES_OK;
    80206486:	84b6                	mv	s1,a3
        if (!(*R(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80206488:	f391                	bnez	a5,8020638c <hal_block_init+0x100>
    8020648a:	f04a                	sd	s2,32(sp)
    8020648c:	ec4e                	sd	s3,24(sp)
    8020648e:	e852                	sd	s4,16(sp)
    80206490:	e456                	sd	s5,8(sp)
    80206492:	e05a                	sd	s6,0(sp)
            panic("virtio_blk: device rejected our feature set");
    80206494:	00001517          	auipc	a0,0x1
    80206498:	7f450513          	addi	a0,a0,2036 # 80207c88 <etext+0xc88>
    8020649c:	ffffa097          	auipc	ra,0xffffa
    802064a0:	114080e7          	jalr	276(ra) # 802005b0 <panic>
    802064a4:	f04a                	sd	s2,32(sp)
    802064a6:	ec4e                	sd	s3,24(sp)
    802064a8:	e852                	sd	s4,16(sp)
    802064aa:	e456                	sd	s5,8(sp)
    802064ac:	e05a                	sd	s6,0(sp)
    if (max == 0)  panic("virtio_blk: queue 0 does not exist");
    802064ae:	00002517          	auipc	a0,0x2
    802064b2:	80a50513          	addi	a0,a0,-2038 # 80207cb8 <etext+0xcb8>
    802064b6:	ffffa097          	auipc	ra,0xffffa
    802064ba:	0fa080e7          	jalr	250(ra) # 802005b0 <panic>
    802064be:	f04a                	sd	s2,32(sp)
    802064c0:	ec4e                	sd	s3,24(sp)
    802064c2:	e852                	sd	s4,16(sp)
    802064c4:	e456                	sd	s5,8(sp)
    802064c6:	e05a                	sd	s6,0(sp)
    if (max < VNUM) panic("virtio_blk: queue too short");
    802064c8:	00002517          	auipc	a0,0x2
    802064cc:	81850513          	addi	a0,a0,-2024 # 80207ce0 <etext+0xce0>
    802064d0:	ffffa097          	auipc	ra,0xffffa
    802064d4:	0e0080e7          	jalr	224(ra) # 802005b0 <panic>
        *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    802064d8:	00136797          	auipc	a5,0x136
    802064dc:	b2878793          	addi	a5,a5,-1240 # 8033c000 <vdisk>
    802064e0:	6394                	ld	a3,0(a5)
    802064e2:	6705                	lui	a4,0x1
    802064e4:	d698                	sw	a4,40(a3)
        *R(VIRTIO_MMIO_QUEUE_ALIGN)     = PGSIZE;
    802064e6:	6394                	ld	a3,0(a5)
    802064e8:	ded8                	sw	a4,60(a3)
        *R(VIRTIO_MMIO_QUEUE_PFN)       = ((uint64)pages) >> 12;
    802064ea:	6398                	ld	a4,0(a5)
    802064ec:	00137797          	auipc	a5,0x137
    802064f0:	b1478793          	addi	a5,a5,-1260 # 8033d000 <pages.0>
    802064f4:	83b1                	srli	a5,a5,0xc
    802064f6:	2781                	sext.w	a5,a5
    802064f8:	c33c                	sw	a5,64(a4)
    802064fa:	bf2d                	j	80206434 <hal_block_init+0x1a8>
    if (!vdisk.base) return -1;                   /* no disk on this board */
    802064fc:	557d                	li	a0,-1
    802064fe:	b7ad                	j	80206468 <hal_block_init+0x1dc>

0000000080206500 <hal_block_rw>:
    }
    return 0;
}

void hal_block_rw(struct buf *b, int write)
{
    80206500:	711d                	addi	sp,sp,-96
    80206502:	ec86                	sd	ra,88(sp)
    80206504:	e8a2                	sd	s0,80(sp)
    80206506:	e4a6                	sd	s1,72(sp)
    80206508:	e0ca                	sd	s2,64(sp)
    8020650a:	fc4e                	sd	s3,56(sp)
    8020650c:	f852                	sd	s4,48(sp)
    8020650e:	f456                	sd	s5,40(sp)
    80206510:	f05a                	sd	s6,32(sp)
    80206512:	ec5e                	sd	s7,24(sp)
    80206514:	e862                	sd	s8,16(sp)
    80206516:	1080                	addi	s0,sp,96
    80206518:	89aa                	mv	s3,a0
    8020651a:	8bae                	mv	s7,a1
    /* LuitFS blocks are 1024 bytes = two 512-byte disk sectors. */
    uint64 sector = b->blockno * (BSIZE / 512);
    8020651c:	00c52b03          	lw	s6,12(a0)
    80206520:	001b1b1b          	slliw	s6,s6,0x1
    80206524:	1b02                	slli	s6,s6,0x20
    80206526:	020b5b13          	srli	s6,s6,0x20

    acquire(&vdisk.lock);
    8020652a:	00136517          	auipc	a0,0x136
    8020652e:	c0e50513          	addi	a0,a0,-1010 # 8033c138 <vdisk+0x138>
    80206532:	ffffb097          	auipc	ra,0xffffb
    80206536:	dce080e7          	jalr	-562(ra) # 80201300 <acquire>
    for (int i = 0; i < VNUM; i++)
    8020653a:	44a1                	li	s1,8
        if (vdisk.free[i]) { vdisk.free[i] = 0; return i; }
    8020653c:	00136a97          	auipc	s5,0x136
    80206540:	ac4a8a93          	addi	s5,s5,-1340 # 8033c000 <vdisk>
    for (int i = 0; i < 3; i++) {
    80206544:	4a0d                	li	s4,3
        idx[i] = alloc_desc();
    80206546:	5c7d                	li	s8,-1

    int idx[3];
    while (alloc3_desc(idx) != 0)
    80206548:	a885                	j	802065b8 <hal_block_rw+0xb8>
        if (vdisk.free[i]) { vdisk.free[i] = 0; return i; }
    8020654a:	00fa8733          	add	a4,s5,a5
    8020654e:	02070423          	sb	zero,40(a4) # 1028 <_entry-0x801fefd8>
        idx[i] = alloc_desc();
    80206552:	c19c                	sw	a5,0(a1)
        if (idx[i] < 0) {
    80206554:	0207c563          	bltz	a5,8020657e <hal_block_rw+0x7e>
    for (int i = 0; i < 3; i++) {
    80206558:	2905                	addiw	s2,s2,1
    8020655a:	0611                	addi	a2,a2,4 # 2004 <_entry-0x801fdffc>
    8020655c:	07490263          	beq	s2,s4,802065c0 <hal_block_rw+0xc0>
        idx[i] = alloc_desc();
    80206560:	85b2                	mv	a1,a2
    for (int i = 0; i < VNUM; i++)
    80206562:	00136717          	auipc	a4,0x136
    80206566:	a9e70713          	addi	a4,a4,-1378 # 8033c000 <vdisk>
    8020656a:	4781                	li	a5,0
        if (vdisk.free[i]) { vdisk.free[i] = 0; return i; }
    8020656c:	02874683          	lbu	a3,40(a4)
    80206570:	fee9                	bnez	a3,8020654a <hal_block_rw+0x4a>
    for (int i = 0; i < VNUM; i++)
    80206572:	2785                	addiw	a5,a5,1
    80206574:	0705                	addi	a4,a4,1
    80206576:	fe979be3          	bne	a5,s1,8020656c <hal_block_rw+0x6c>
        idx[i] = alloc_desc();
    8020657a:	0185a023          	sw	s8,0(a1)
            for (int j = 0; j < i; j++) free_desc(idx[j]);
    8020657e:	03205163          	blez	s2,802065a0 <hal_block_rw+0xa0>
    80206582:	fa042503          	lw	a0,-96(s0)
    80206586:	00000097          	auipc	ra,0x0
    8020658a:	c6c080e7          	jalr	-916(ra) # 802061f2 <free_desc>
    8020658e:	4785                	li	a5,1
    80206590:	0127d863          	bge	a5,s2,802065a0 <hal_block_rw+0xa0>
    80206594:	fa442503          	lw	a0,-92(s0)
    80206598:	00000097          	auipc	ra,0x0
    8020659c:	c5a080e7          	jalr	-934(ra) # 802061f2 <free_desc>
        sleep(&vdisk.free[0], &vdisk.lock);       /* ring full: wait */
    802065a0:	00136597          	auipc	a1,0x136
    802065a4:	b9858593          	addi	a1,a1,-1128 # 8033c138 <vdisk+0x138>
    802065a8:	00136517          	auipc	a0,0x136
    802065ac:	a8050513          	addi	a0,a0,-1408 # 8033c028 <vdisk+0x28>
    802065b0:	ffffb097          	auipc	ra,0xffffb
    802065b4:	7a0080e7          	jalr	1952(ra) # 80201d50 <sleep>
    for (int i = 0; i < 3; i++) {
    802065b8:	fa040613          	addi	a2,s0,-96
    802065bc:	4901                	li	s2,0
    802065be:	b74d                	j	80206560 <hal_block_rw+0x60>

    struct virtio_blk_req *req = &vdisk.info[idx[0]].req;
    802065c0:	fa042683          	lw	a3,-96(s0)
    802065c4:	00268793          	addi	a5,a3,2
    802065c8:	0796                	slli	a5,a5,0x5
    req->type     = write ? VIRTIO_BLK_T_OUT : VIRTIO_BLK_T_IN;
    802065ca:	00136597          	auipc	a1,0x136
    802065ce:	a3658593          	addi	a1,a1,-1482 # 8033c000 <vdisk>
    802065d2:	00569713          	slli	a4,a3,0x5
    802065d6:	972e                	add	a4,a4,a1
    802065d8:	01703633          	snez	a2,s7
    802065dc:	c330                	sw	a2,64(a4)
    req->reserved = 0;
    802065de:	04072223          	sw	zero,68(a4)
    req->sector   = sector;
    802065e2:	05673423          	sd	s6,72(a4)

    vdisk.desc[idx[0]] = (struct virtq_desc){
    802065e6:	00469613          	slli	a2,a3,0x4
    802065ea:	6998                	ld	a4,16(a1)
    802065ec:	9732                	add	a4,a4,a2
        (uint64)req, sizeof(*req), VRING_DESC_F_NEXT, (uint16)idx[1] };
    802065ee:	fa442603          	lw	a2,-92(s0)
    struct virtio_blk_req *req = &vdisk.info[idx[0]].req;
    802065f2:	00f58533          	add	a0,a1,a5
    vdisk.desc[idx[0]] = (struct virtq_desc){
    802065f6:	e308                	sd	a0,0(a4)
    802065f8:	4541                	li	a0,16
    802065fa:	c708                	sw	a0,8(a4)
    802065fc:	4505                	li	a0,1
    802065fe:	00a71623          	sh	a0,12(a4)
        (uint64)req, sizeof(*req), VRING_DESC_F_NEXT, (uint16)idx[1] };
    80206602:	00c71723          	sh	a2,14(a4)
    vdisk.desc[idx[1]] = (struct virtq_desc){
    80206606:	0612                	slli	a2,a2,0x4
    80206608:	6998                	ld	a4,16(a1)
    8020660a:	9732                	add	a4,a4,a2
        (uint64)b->data, BSIZE,
    8020660c:	05898513          	addi	a0,s3,88
        (uint16)((write ? 0 : VRING_DESC_F_WRITE) | VRING_DESC_F_NEXT),
    80206610:	460d                	li	a2,3
    80206612:	000b8363          	beqz	s7,80206618 <hal_block_rw+0x118>
    80206616:	4605                	li	a2,1
        (uint16)idx[2] };
    80206618:	fa842583          	lw	a1,-88(s0)
    vdisk.desc[idx[1]] = (struct virtq_desc){
    8020661c:	e308                	sd	a0,0(a4)
    8020661e:	40000513          	li	a0,1024
    80206622:	c708                	sw	a0,8(a4)
    80206624:	00c71623          	sh	a2,12(a4)
        (uint16)idx[2] };
    80206628:	00b71723          	sh	a1,14(a4)
    vdisk.info[idx[0]].status = 0xff;             /* device overwrites on success */
    8020662c:	00136717          	auipc	a4,0x136
    80206630:	9d470713          	addi	a4,a4,-1580 # 8033c000 <vdisk>
    80206634:	00268613          	addi	a2,a3,2
    80206638:	0616                	slli	a2,a2,0x5
    8020663a:	963a                	add	a2,a2,a4
    8020663c:	557d                	li	a0,-1
    8020663e:	00a60823          	sb	a0,16(a2)
    vdisk.desc[idx[2]] = (struct virtq_desc){
    80206642:	0592                	slli	a1,a1,0x4
    80206644:	6b10                	ld	a2,16(a4)
    80206646:	962e                	add	a2,a2,a1
        (uint64)&vdisk.info[idx[0]].status, 1, VRING_DESC_F_WRITE, 0 };
    80206648:	07c1                	addi	a5,a5,16
    8020664a:	97ba                	add	a5,a5,a4
    vdisk.desc[idx[2]] = (struct virtq_desc){
    8020664c:	e21c                	sd	a5,0(a2)
    8020664e:	4585                	li	a1,1
    80206650:	c60c                	sw	a1,8(a2)
    80206652:	4789                	li	a5,2
    80206654:	00f61623          	sh	a5,12(a2)
    80206658:	00061723          	sh	zero,14(a2)

    b->disk = 1;                                  /* I2: device owns b->data */
    8020665c:	00b9a223          	sw	a1,4(s3)
    vdisk.info[idx[0]].b = b;                     /* I3 */
    80206660:	00569793          	slli	a5,a3,0x5
    80206664:	97ba                	add	a5,a5,a4
    80206666:	0337bc23          	sd	s3,56(a5)

    vdisk.avail->ring[vdisk.avail->idx % VNUM] = idx[0];
    8020666a:	6f10                	ld	a2,24(a4)
    8020666c:	00265783          	lhu	a5,2(a2)
    80206670:	8b9d                	andi	a5,a5,7
    80206672:	0786                	slli	a5,a5,0x1
    80206674:	963e                	add	a2,a2,a5
    80206676:	00d61223          	sh	a3,4(a2)
    __sync_synchronize();          /* ring entry visible BEFORE idx bump */
    8020667a:	0330000f          	fence	rw,rw
    vdisk.avail->idx += 1;
    8020667e:	6f14                	ld	a3,24(a4)
    80206680:	0026d783          	lhu	a5,2(a3)
    80206684:	2785                	addiw	a5,a5,1
    80206686:	00f69123          	sh	a5,2(a3)
    __sync_synchronize();          /* idx visible BEFORE the doorbell    */
    8020668a:	0330000f          	fence	rw,rw
    *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    8020668e:	631c                	ld	a5,0(a4)
    80206690:	0407a823          	sw	zero,80(a5)

    while (b->disk == 1)
    80206694:	0049a783          	lw	a5,4(s3)
    80206698:	02b79163          	bne	a5,a1,802066ba <hal_block_rw+0x1ba>
        sleep(b, &vdisk.lock);                    /* intr handler wakes us */
    8020669c:	00136917          	auipc	s2,0x136
    802066a0:	a9c90913          	addi	s2,s2,-1380 # 8033c138 <vdisk+0x138>
    while (b->disk == 1)
    802066a4:	84ae                	mv	s1,a1
        sleep(b, &vdisk.lock);                    /* intr handler wakes us */
    802066a6:	85ca                	mv	a1,s2
    802066a8:	854e                	mv	a0,s3
    802066aa:	ffffb097          	auipc	ra,0xffffb
    802066ae:	6a6080e7          	jalr	1702(ra) # 80201d50 <sleep>
    while (b->disk == 1)
    802066b2:	0049a783          	lw	a5,4(s3)
    802066b6:	fe9788e3          	beq	a5,s1,802066a6 <hal_block_rw+0x1a6>

    vdisk.info[idx[0]].b = 0;
    802066ba:	fa042503          	lw	a0,-96(s0)
    802066be:	00551713          	slli	a4,a0,0x5
    802066c2:	00136797          	auipc	a5,0x136
    802066c6:	93e78793          	addi	a5,a5,-1730 # 8033c000 <vdisk>
    802066ca:	97ba                	add	a5,a5,a4
    802066cc:	0207bc23          	sd	zero,56(a5)
    free_desc(idx[0]); free_desc(idx[1]); free_desc(idx[2]);
    802066d0:	00000097          	auipc	ra,0x0
    802066d4:	b22080e7          	jalr	-1246(ra) # 802061f2 <free_desc>
    802066d8:	fa442503          	lw	a0,-92(s0)
    802066dc:	00000097          	auipc	ra,0x0
    802066e0:	b16080e7          	jalr	-1258(ra) # 802061f2 <free_desc>
    802066e4:	fa842503          	lw	a0,-88(s0)
    802066e8:	00000097          	auipc	ra,0x0
    802066ec:	b0a080e7          	jalr	-1270(ra) # 802061f2 <free_desc>

    release(&vdisk.lock);
    802066f0:	00136517          	auipc	a0,0x136
    802066f4:	a4850513          	addi	a0,a0,-1464 # 8033c138 <vdisk+0x138>
    802066f8:	ffffb097          	auipc	ra,0xffffb
    802066fc:	cb8080e7          	jalr	-840(ra) # 802013b0 <release>
}
    80206700:	60e6                	ld	ra,88(sp)
    80206702:	6446                	ld	s0,80(sp)
    80206704:	64a6                	ld	s1,72(sp)
    80206706:	6906                	ld	s2,64(sp)
    80206708:	79e2                	ld	s3,56(sp)
    8020670a:	7a42                	ld	s4,48(sp)
    8020670c:	7aa2                	ld	s5,40(sp)
    8020670e:	7b02                	ld	s6,32(sp)
    80206710:	6be2                	ld	s7,24(sp)
    80206712:	6c42                	ld	s8,16(sp)
    80206714:	6125                	addi	sp,sp,96
    80206716:	8082                	ret

0000000080206718 <hal_block_intr>:

void hal_block_intr(void)
{
    80206718:	1101                	addi	sp,sp,-32
    8020671a:	ec06                	sd	ra,24(sp)
    8020671c:	e822                	sd	s0,16(sp)
    8020671e:	e426                	sd	s1,8(sp)
    80206720:	1000                	addi	s0,sp,32
    acquire(&vdisk.lock);
    80206722:	00136497          	auipc	s1,0x136
    80206726:	8de48493          	addi	s1,s1,-1826 # 8033c000 <vdisk>
    8020672a:	00136517          	auipc	a0,0x136
    8020672e:	a0e50513          	addi	a0,a0,-1522 # 8033c138 <vdisk+0x138>
    80206732:	ffffb097          	auipc	ra,0xffffb
    80206736:	bce080e7          	jalr	-1074(ra) # 80201300 <acquire>

    /* Ack FIRST: a completion that lands after this read re-raises the
     * interrupt instead of being lost. */
    *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8020673a:	6098                	ld	a4,0(s1)
    8020673c:	533c                	lw	a5,96(a4)
    8020673e:	8b8d                	andi	a5,a5,3
    80206740:	d37c                	sw	a5,100(a4)
    __sync_synchronize();
    80206742:	0330000f          	fence	rw,rw

    while (vdisk.used_idx != vdisk.used->idx) {   /* may batch completions */
    80206746:	709c                	ld	a5,32(s1)
    80206748:	0304d703          	lhu	a4,48(s1)
    8020674c:	0027d783          	lhu	a5,2(a5)
    80206750:	04f70e63          	beq	a4,a5,802067ac <hal_block_intr+0x94>
    80206754:	e04a                	sd	s2,0(sp)

        if (vdisk.info[id].status != 0)
            panic("virtio_blk: request failed (status byte nonzero)");

        struct buf *b = vdisk.info[id].b;
        if (!b || b->disk != 1) panic("virtio_blk: completion for idle buf");
    80206756:	4905                	li	s2,1
        __sync_synchronize();
    80206758:	0330000f          	fence	rw,rw
        int id = vdisk.used->ring[vdisk.used_idx % VNUM].id;
    8020675c:	7098                	ld	a4,32(s1)
    8020675e:	0304d783          	lhu	a5,48(s1)
    80206762:	8b9d                	andi	a5,a5,7
    80206764:	078e                	slli	a5,a5,0x3
    80206766:	97ba                	add	a5,a5,a4
    80206768:	43dc                	lw	a5,4(a5)
        if (vdisk.info[id].status != 0)
    8020676a:	00278713          	addi	a4,a5,2
    8020676e:	0716                	slli	a4,a4,0x5
    80206770:	9726                	add	a4,a4,s1
    80206772:	01074703          	lbu	a4,16(a4)
    80206776:	eb21                	bnez	a4,802067c6 <hal_block_intr+0xae>
        struct buf *b = vdisk.info[id].b;
    80206778:	0796                	slli	a5,a5,0x5
    8020677a:	97a6                	add	a5,a5,s1
    8020677c:	7f88                	ld	a0,56(a5)
        if (!b || b->disk != 1) panic("virtio_blk: completion for idle buf");
    8020677e:	cd21                	beqz	a0,802067d6 <hal_block_intr+0xbe>
    80206780:	415c                	lw	a5,4(a0)
    80206782:	05279a63          	bne	a5,s2,802067d6 <hal_block_intr+0xbe>
        b->disk = 0;                              /* I2: hart owns data again */
    80206786:	00052223          	sw	zero,4(a0)
        wakeup(b);
    8020678a:	ffffb097          	auipc	ra,0xffffb
    8020678e:	746080e7          	jalr	1862(ra) # 80201ed0 <wakeup>

        vdisk.used_idx += 1;
    80206792:	0304d783          	lhu	a5,48(s1)
    80206796:	2785                	addiw	a5,a5,1
    80206798:	17c2                	slli	a5,a5,0x30
    8020679a:	93c1                	srli	a5,a5,0x30
    8020679c:	02f49823          	sh	a5,48(s1)
    while (vdisk.used_idx != vdisk.used->idx) {   /* may batch completions */
    802067a0:	7098                	ld	a4,32(s1)
    802067a2:	00275703          	lhu	a4,2(a4)
    802067a6:	faf719e3          	bne	a4,a5,80206758 <hal_block_intr+0x40>
    802067aa:	6902                	ld	s2,0(sp)
    }
    release(&vdisk.lock);
    802067ac:	00136517          	auipc	a0,0x136
    802067b0:	98c50513          	addi	a0,a0,-1652 # 8033c138 <vdisk+0x138>
    802067b4:	ffffb097          	auipc	ra,0xffffb
    802067b8:	bfc080e7          	jalr	-1028(ra) # 802013b0 <release>
}
    802067bc:	60e2                	ld	ra,24(sp)
    802067be:	6442                	ld	s0,16(sp)
    802067c0:	64a2                	ld	s1,8(sp)
    802067c2:	6105                	addi	sp,sp,32
    802067c4:	8082                	ret
            panic("virtio_blk: request failed (status byte nonzero)");
    802067c6:	00001517          	auipc	a0,0x1
    802067ca:	53a50513          	addi	a0,a0,1338 # 80207d00 <etext+0xd00>
    802067ce:	ffffa097          	auipc	ra,0xffffa
    802067d2:	de2080e7          	jalr	-542(ra) # 802005b0 <panic>
        if (!b || b->disk != 1) panic("virtio_blk: completion for idle buf");
    802067d6:	00001517          	auipc	a0,0x1
    802067da:	56250513          	addi	a0,a0,1378 # 80207d38 <etext+0xd38>
    802067de:	ffffa097          	auipc	ra,0xffffa
    802067e2:	dd2080e7          	jalr	-558(ra) # 802005b0 <panic>
