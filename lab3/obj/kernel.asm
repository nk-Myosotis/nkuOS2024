
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addw	t1,zero,-3
ffffffffc0200008:	037a                	sll	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srl	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addw	t1,zero,-1
ffffffffc0200016:	137e                	sll	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	add	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000a517          	auipc	a0,0xa
ffffffffc0200036:	00e50513          	add	a0,a0,14 # ffffffffc020a040 <ide>
ffffffffc020003a:	00011617          	auipc	a2,0x11
ffffffffc020003e:	53660613          	add	a2,a2,1334 # ffffffffc0211570 <end>
kern_init(void) {
ffffffffc0200042:	1141                	add	sp,sp,-16 # ffffffffc0208ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	300040ef          	jal	ffffffffc020434a <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	32a58593          	add	a1,a1,810 # ffffffffc0204378 <etext+0x4>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	34250513          	add	a0,a0,834 # ffffffffc0204398 <etext+0x24>
ffffffffc020005e:	05c000ef          	jal	ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	09e000ef          	jal	ffffffffc0200100 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	26b010ef          	jal	ffffffffc0201ad0 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4c4000ef          	jal	ffffffffc020052e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	62e030ef          	jal	ffffffffc020369c <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	40e000ef          	jal	ffffffffc0200480 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	0f7020ef          	jal	ffffffffc020296c <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007a:	344000ef          	jal	ffffffffc02003be <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	add	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	388000ef          	jal	ffffffffc0200410 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	add	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	add	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	add	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	add	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	5d9030ef          	jal	ffffffffc0203e86 <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	add	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	add	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	add	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	f42e                	sd	a1,40(sp)
ffffffffc02000c2:	f832                	sd	a2,48(sp)
ffffffffc02000c4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c6:	862a                	mv	a2,a0
ffffffffc02000c8:	004c                	add	a1,sp,4
ffffffffc02000ca:	00000517          	auipc	a0,0x0
ffffffffc02000ce:	fb650513          	add	a0,a0,-74 # ffffffffc0200080 <cputch>
ffffffffc02000d2:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d4:	ec06                	sd	ra,24(sp)
ffffffffc02000d6:	e0ba                	sd	a4,64(sp)
ffffffffc02000d8:	e4be                	sd	a5,72(sp)
ffffffffc02000da:	e8c2                	sd	a6,80(sp)
ffffffffc02000dc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000de:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e0:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e2:	5a5030ef          	jal	ffffffffc0203e86 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e6:	60e2                	ld	ra,24(sp)
ffffffffc02000e8:	4512                	lw	a0,4(sp)
ffffffffc02000ea:	6125                	add	sp,sp,96
ffffffffc02000ec:	8082                	ret

ffffffffc02000ee <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ee:	a60d                	j	ffffffffc0200410 <cons_putc>

ffffffffc02000f0 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f0:	1141                	add	sp,sp,-16
ffffffffc02000f2:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000f4:	350000ef          	jal	ffffffffc0200444 <cons_getc>
ffffffffc02000f8:	dd75                	beqz	a0,ffffffffc02000f4 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02000fa:	60a2                	ld	ra,8(sp)
ffffffffc02000fc:	0141                	add	sp,sp,16
ffffffffc02000fe:	8082                	ret

ffffffffc0200100 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200100:	1141                	add	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200102:	00004517          	auipc	a0,0x4
ffffffffc0200106:	29e50513          	add	a0,a0,670 # ffffffffc02043a0 <etext+0x2c>
void print_kerninfo(void) {
ffffffffc020010a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020010c:	fafff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200110:	00000597          	auipc	a1,0x0
ffffffffc0200114:	f2258593          	add	a1,a1,-222 # ffffffffc0200032 <kern_init>
ffffffffc0200118:	00004517          	auipc	a0,0x4
ffffffffc020011c:	2a850513          	add	a0,a0,680 # ffffffffc02043c0 <etext+0x4c>
ffffffffc0200120:	f9bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200124:	00004597          	auipc	a1,0x4
ffffffffc0200128:	25058593          	add	a1,a1,592 # ffffffffc0204374 <etext>
ffffffffc020012c:	00004517          	auipc	a0,0x4
ffffffffc0200130:	2b450513          	add	a0,a0,692 # ffffffffc02043e0 <etext+0x6c>
ffffffffc0200134:	f87ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200138:	0000a597          	auipc	a1,0xa
ffffffffc020013c:	f0858593          	add	a1,a1,-248 # ffffffffc020a040 <ide>
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	2c050513          	add	a0,a0,704 # ffffffffc0204400 <etext+0x8c>
ffffffffc0200148:	f73ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020014c:	00011597          	auipc	a1,0x11
ffffffffc0200150:	42458593          	add	a1,a1,1060 # ffffffffc0211570 <end>
ffffffffc0200154:	00004517          	auipc	a0,0x4
ffffffffc0200158:	2cc50513          	add	a0,a0,716 # ffffffffc0204420 <etext+0xac>
ffffffffc020015c:	f5fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200160:	00012797          	auipc	a5,0x12
ffffffffc0200164:	80f78793          	add	a5,a5,-2033 # ffffffffc021196f <end+0x3ff>
ffffffffc0200168:	00000717          	auipc	a4,0x0
ffffffffc020016c:	eca70713          	add	a4,a4,-310 # ffffffffc0200032 <kern_init>
ffffffffc0200170:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200172:	43f7d593          	sra	a1,a5,0x3f
}
ffffffffc0200176:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200178:	3ff5f593          	and	a1,a1,1023
ffffffffc020017c:	95be                	add	a1,a1,a5
ffffffffc020017e:	85a9                	sra	a1,a1,0xa
ffffffffc0200180:	00004517          	auipc	a0,0x4
ffffffffc0200184:	2c050513          	add	a0,a0,704 # ffffffffc0204440 <etext+0xcc>
}
ffffffffc0200188:	0141                	add	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020018a:	bf05                	j	ffffffffc02000ba <cprintf>

ffffffffc020018c <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020018c:	1141                	add	sp,sp,-16

    panic("Not Implemented!");
ffffffffc020018e:	00004617          	auipc	a2,0x4
ffffffffc0200192:	2e260613          	add	a2,a2,738 # ffffffffc0204470 <etext+0xfc>
ffffffffc0200196:	04e00593          	li	a1,78
ffffffffc020019a:	00004517          	auipc	a0,0x4
ffffffffc020019e:	2ee50513          	add	a0,a0,750 # ffffffffc0204488 <etext+0x114>
void print_stackframe(void) {
ffffffffc02001a2:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001a4:	1bc000ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02001a8 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001a8:	1141                	add	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001aa:	00004617          	auipc	a2,0x4
ffffffffc02001ae:	2f660613          	add	a2,a2,758 # ffffffffc02044a0 <etext+0x12c>
ffffffffc02001b2:	00004597          	auipc	a1,0x4
ffffffffc02001b6:	30e58593          	add	a1,a1,782 # ffffffffc02044c0 <etext+0x14c>
ffffffffc02001ba:	00004517          	auipc	a0,0x4
ffffffffc02001be:	30e50513          	add	a0,a0,782 # ffffffffc02044c8 <etext+0x154>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001c2:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001c4:	ef7ff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001c8:	00004617          	auipc	a2,0x4
ffffffffc02001cc:	31060613          	add	a2,a2,784 # ffffffffc02044d8 <etext+0x164>
ffffffffc02001d0:	00004597          	auipc	a1,0x4
ffffffffc02001d4:	33058593          	add	a1,a1,816 # ffffffffc0204500 <etext+0x18c>
ffffffffc02001d8:	00004517          	auipc	a0,0x4
ffffffffc02001dc:	2f050513          	add	a0,a0,752 # ffffffffc02044c8 <etext+0x154>
ffffffffc02001e0:	edbff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001e4:	00004617          	auipc	a2,0x4
ffffffffc02001e8:	32c60613          	add	a2,a2,812 # ffffffffc0204510 <etext+0x19c>
ffffffffc02001ec:	00004597          	auipc	a1,0x4
ffffffffc02001f0:	34458593          	add	a1,a1,836 # ffffffffc0204530 <etext+0x1bc>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	2d450513          	add	a0,a0,724 # ffffffffc02044c8 <etext+0x154>
ffffffffc02001fc:	ebfff0ef          	jal	ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200200:	60a2                	ld	ra,8(sp)
ffffffffc0200202:	4501                	li	a0,0
ffffffffc0200204:	0141                	add	sp,sp,16
ffffffffc0200206:	8082                	ret

ffffffffc0200208 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	1141                	add	sp,sp,-16
ffffffffc020020a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020020c:	ef5ff0ef          	jal	ffffffffc0200100 <print_kerninfo>
    return 0;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	4501                	li	a0,0
ffffffffc0200214:	0141                	add	sp,sp,16
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200218:	1141                	add	sp,sp,-16
ffffffffc020021a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020021c:	f71ff0ef          	jal	ffffffffc020018c <print_stackframe>
    return 0;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	4501                	li	a0,0
ffffffffc0200224:	0141                	add	sp,sp,16
ffffffffc0200226:	8082                	ret

ffffffffc0200228 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200228:	7115                	add	sp,sp,-224
ffffffffc020022a:	f15a                	sd	s6,160(sp)
ffffffffc020022c:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	31250513          	add	a0,a0,786 # ffffffffc0204540 <etext+0x1cc>
kmonitor(struct trapframe *tf) {
ffffffffc0200236:	ed86                	sd	ra,216(sp)
ffffffffc0200238:	e9a2                	sd	s0,208(sp)
ffffffffc020023a:	e5a6                	sd	s1,200(sp)
ffffffffc020023c:	e1ca                	sd	s2,192(sp)
ffffffffc020023e:	fd4e                	sd	s3,184(sp)
ffffffffc0200240:	f952                	sd	s4,176(sp)
ffffffffc0200242:	f556                	sd	s5,168(sp)
ffffffffc0200244:	ed5e                	sd	s7,152(sp)
ffffffffc0200246:	e962                	sd	s8,144(sp)
ffffffffc0200248:	e566                	sd	s9,136(sp)
ffffffffc020024a:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020024c:	e6fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200250:	00004517          	auipc	a0,0x4
ffffffffc0200254:	31850513          	add	a0,a0,792 # ffffffffc0204568 <etext+0x1f4>
ffffffffc0200258:	e63ff0ef          	jal	ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc020025c:	000b0563          	beqz	s6,ffffffffc0200266 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200260:	855a                	mv	a0,s6
ffffffffc0200262:	4b6000ef          	jal	ffffffffc0200718 <print_trapframe>
ffffffffc0200266:	00006c17          	auipc	s8,0x6
ffffffffc020026a:	c52c0c13          	add	s8,s8,-942 # ffffffffc0205eb8 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc020026e:	00005917          	auipc	s2,0x5
ffffffffc0200272:	68290913          	add	s2,s2,1666 # ffffffffc02058f0 <etext+0x157c>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200276:	00004497          	auipc	s1,0x4
ffffffffc020027a:	31a48493          	add	s1,s1,794 # ffffffffc0204590 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc020027e:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200280:	00004a97          	auipc	s5,0x4
ffffffffc0200284:	318a8a93          	add	s5,s5,792 # ffffffffc0204598 <etext+0x224>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200288:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020028a:	00004b97          	auipc	s7,0x4
ffffffffc020028e:	32eb8b93          	add	s7,s7,814 # ffffffffc02045b8 <etext+0x244>
        if ((buf = readline("")) != NULL) {
ffffffffc0200292:	854a                	mv	a0,s2
ffffffffc0200294:	76d030ef          	jal	ffffffffc0204200 <readline>
ffffffffc0200298:	842a                	mv	s0,a0
ffffffffc020029a:	dd65                	beqz	a0,ffffffffc0200292 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020029c:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002a0:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002a2:	e59d                	bnez	a1,ffffffffc02002d0 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02002a4:	fe0c87e3          	beqz	s9,ffffffffc0200292 <kmonitor+0x6a>
ffffffffc02002a8:	00006d17          	auipc	s10,0x6
ffffffffc02002ac:	c10d0d13          	add	s10,s10,-1008 # ffffffffc0205eb8 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002b0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002b2:	6582                	ld	a1,0(sp)
ffffffffc02002b4:	000d3503          	ld	a0,0(s10)
ffffffffc02002b8:	044040ef          	jal	ffffffffc02042fc <strcmp>
ffffffffc02002bc:	c53d                	beqz	a0,ffffffffc020032a <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002be:	2405                	addw	s0,s0,1
ffffffffc02002c0:	0d61                	add	s10,s10,24
ffffffffc02002c2:	ff4418e3          	bne	s0,s4,ffffffffc02002b2 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002c6:	6582                	ld	a1,0(sp)
ffffffffc02002c8:	855e                	mv	a0,s7
ffffffffc02002ca:	df1ff0ef          	jal	ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02002ce:	b7d1                	j	ffffffffc0200292 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d0:	8526                	mv	a0,s1
ffffffffc02002d2:	062040ef          	jal	ffffffffc0204334 <strchr>
ffffffffc02002d6:	c901                	beqz	a0,ffffffffc02002e6 <kmonitor+0xbe>
ffffffffc02002d8:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02002dc:	00040023          	sb	zero,0(s0)
ffffffffc02002e0:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	d1e9                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc02002e4:	b7f5                	j	ffffffffc02002d0 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc02002e6:	00044783          	lbu	a5,0(s0)
ffffffffc02002ea:	dfcd                	beqz	a5,ffffffffc02002a4 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02002ec:	033c8a63          	beq	s9,s3,ffffffffc0200320 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc02002f0:	003c9793          	sll	a5,s9,0x3
ffffffffc02002f4:	08078793          	add	a5,a5,128
ffffffffc02002f8:	978a                	add	a5,a5,sp
ffffffffc02002fa:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02002fe:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200302:	2c85                	addw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200304:	e591                	bnez	a1,ffffffffc0200310 <kmonitor+0xe8>
ffffffffc0200306:	bf79                	j	ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc0200308:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020030c:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020030e:	d9d9                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc0200310:	8526                	mv	a0,s1
ffffffffc0200312:	022040ef          	jal	ffffffffc0204334 <strchr>
ffffffffc0200316:	d96d                	beqz	a0,ffffffffc0200308 <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200318:	00044583          	lbu	a1,0(s0)
ffffffffc020031c:	d5c1                	beqz	a1,ffffffffc02002a4 <kmonitor+0x7c>
ffffffffc020031e:	bf4d                	j	ffffffffc02002d0 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200320:	45c1                	li	a1,16
ffffffffc0200322:	8556                	mv	a0,s5
ffffffffc0200324:	d97ff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0200328:	b7e1                	j	ffffffffc02002f0 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020032a:	00141793          	sll	a5,s0,0x1
ffffffffc020032e:	97a2                	add	a5,a5,s0
ffffffffc0200330:	078e                	sll	a5,a5,0x3
ffffffffc0200332:	97e2                	add	a5,a5,s8
ffffffffc0200334:	6b9c                	ld	a5,16(a5)
ffffffffc0200336:	865a                	mv	a2,s6
ffffffffc0200338:	002c                	add	a1,sp,8
ffffffffc020033a:	fffc851b          	addw	a0,s9,-1
ffffffffc020033e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200340:	f40559e3          	bgez	a0,ffffffffc0200292 <kmonitor+0x6a>
}
ffffffffc0200344:	60ee                	ld	ra,216(sp)
ffffffffc0200346:	644e                	ld	s0,208(sp)
ffffffffc0200348:	64ae                	ld	s1,200(sp)
ffffffffc020034a:	690e                	ld	s2,192(sp)
ffffffffc020034c:	79ea                	ld	s3,184(sp)
ffffffffc020034e:	7a4a                	ld	s4,176(sp)
ffffffffc0200350:	7aaa                	ld	s5,168(sp)
ffffffffc0200352:	7b0a                	ld	s6,160(sp)
ffffffffc0200354:	6bea                	ld	s7,152(sp)
ffffffffc0200356:	6c4a                	ld	s8,144(sp)
ffffffffc0200358:	6caa                	ld	s9,136(sp)
ffffffffc020035a:	6d0a                	ld	s10,128(sp)
ffffffffc020035c:	612d                	add	sp,sp,224
ffffffffc020035e:	8082                	ret

ffffffffc0200360 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200360:	00011317          	auipc	t1,0x11
ffffffffc0200364:	19830313          	add	t1,t1,408 # ffffffffc02114f8 <is_panic>
ffffffffc0200368:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020036c:	715d                	add	sp,sp,-80
ffffffffc020036e:	ec06                	sd	ra,24(sp)
ffffffffc0200370:	f436                	sd	a3,40(sp)
ffffffffc0200372:	f83a                	sd	a4,48(sp)
ffffffffc0200374:	fc3e                	sd	a5,56(sp)
ffffffffc0200376:	e0c2                	sd	a6,64(sp)
ffffffffc0200378:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020037a:	020e1c63          	bnez	t3,ffffffffc02003b2 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020037e:	4785                	li	a5,1
ffffffffc0200380:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200384:	e822                	sd	s0,16(sp)
ffffffffc0200386:	103c                	add	a5,sp,40
ffffffffc0200388:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020038a:	862e                	mv	a2,a1
ffffffffc020038c:	85aa                	mv	a1,a0
ffffffffc020038e:	00004517          	auipc	a0,0x4
ffffffffc0200392:	24250513          	add	a0,a0,578 # ffffffffc02045d0 <etext+0x25c>
    va_start(ap, fmt);
ffffffffc0200396:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200398:	d23ff0ef          	jal	ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc020039c:	65a2                	ld	a1,8(sp)
ffffffffc020039e:	8522                	mv	a0,s0
ffffffffc02003a0:	cfbff0ef          	jal	ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	09c50513          	add	a0,a0,156 # ffffffffc0205440 <etext+0x10cc>
ffffffffc02003ac:	d0fff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02003b0:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003b2:	106000ef          	jal	ffffffffc02004b8 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003b6:	4501                	li	a0,0
ffffffffc02003b8:	e71ff0ef          	jal	ffffffffc0200228 <kmonitor>
    while (1) {
ffffffffc02003bc:	bfed                	j	ffffffffc02003b6 <__panic+0x56>

ffffffffc02003be <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02003be:	67e1                	lui	a5,0x18
ffffffffc02003c0:	6a078793          	add	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02003c4:	00011717          	auipc	a4,0x11
ffffffffc02003c8:	12f73e23          	sd	a5,316(a4) # ffffffffc0211500 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003cc:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02003d0:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003d2:	953e                	add	a0,a0,a5
ffffffffc02003d4:	4601                	li	a2,0
ffffffffc02003d6:	4881                	li	a7,0
ffffffffc02003d8:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02003dc:	02000793          	li	a5,32
ffffffffc02003e0:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02003e4:	00004517          	auipc	a0,0x4
ffffffffc02003e8:	20c50513          	add	a0,a0,524 # ffffffffc02045f0 <etext+0x27c>
    ticks = 0;
ffffffffc02003ec:	00011797          	auipc	a5,0x11
ffffffffc02003f0:	1007be23          	sd	zero,284(a5) # ffffffffc0211508 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02003f4:	b1d9                	j	ffffffffc02000ba <cprintf>

ffffffffc02003f6 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003f6:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003fa:	00011797          	auipc	a5,0x11
ffffffffc02003fe:	1067b783          	ld	a5,262(a5) # ffffffffc0211500 <timebase>
ffffffffc0200402:	953e                	add	a0,a0,a5
ffffffffc0200404:	4581                	li	a1,0
ffffffffc0200406:	4601                	li	a2,0
ffffffffc0200408:	4881                	li	a7,0
ffffffffc020040a:	00000073          	ecall
ffffffffc020040e:	8082                	ret

ffffffffc0200410 <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200410:	100027f3          	csrr	a5,sstatus
ffffffffc0200414:	8b89                	and	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200416:	0ff57513          	zext.b	a0,a0
ffffffffc020041a:	e799                	bnez	a5,ffffffffc0200428 <cons_putc+0x18>
ffffffffc020041c:	4581                	li	a1,0
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	4885                	li	a7,1
ffffffffc0200422:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200426:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200428:	1101                	add	sp,sp,-32
ffffffffc020042a:	ec06                	sd	ra,24(sp)
ffffffffc020042c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020042e:	08a000ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc0200432:	6522                	ld	a0,8(sp)
ffffffffc0200434:	4581                	li	a1,0
ffffffffc0200436:	4601                	li	a2,0
ffffffffc0200438:	4885                	li	a7,1
ffffffffc020043a:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020043e:	60e2                	ld	ra,24(sp)
ffffffffc0200440:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc0200442:	a885                	j	ffffffffc02004b2 <intr_enable>

ffffffffc0200444 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200444:	100027f3          	csrr	a5,sstatus
ffffffffc0200448:	8b89                	and	a5,a5,2
ffffffffc020044a:	eb89                	bnez	a5,ffffffffc020045c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020044c:	4501                	li	a0,0
ffffffffc020044e:	4581                	li	a1,0
ffffffffc0200450:	4601                	li	a2,0
ffffffffc0200452:	4889                	li	a7,2
ffffffffc0200454:	00000073          	ecall
ffffffffc0200458:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020045a:	8082                	ret
int cons_getc(void) {
ffffffffc020045c:	1101                	add	sp,sp,-32
ffffffffc020045e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200460:	058000ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc0200464:	4501                	li	a0,0
ffffffffc0200466:	4581                	li	a1,0
ffffffffc0200468:	4601                	li	a2,0
ffffffffc020046a:	4889                	li	a7,2
ffffffffc020046c:	00000073          	ecall
ffffffffc0200470:	2501                	sext.w	a0,a0
ffffffffc0200472:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200474:	03e000ef          	jal	ffffffffc02004b2 <intr_enable>
}
ffffffffc0200478:	60e2                	ld	ra,24(sp)
ffffffffc020047a:	6522                	ld	a0,8(sp)
ffffffffc020047c:	6105                	add	sp,sp,32
ffffffffc020047e:	8082                	ret

ffffffffc0200480 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200480:	8082                	ret

ffffffffc0200482 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200482:	00253513          	sltiu	a0,a0,2
ffffffffc0200486:	8082                	ret

ffffffffc0200488 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200488:	03800513          	li	a0,56
ffffffffc020048c:	8082                	ret

ffffffffc020048e <ide_write_secs>:
    return 0;
}

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc020048e:	0095979b          	sllw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200492:	0000a517          	auipc	a0,0xa
ffffffffc0200496:	bae50513          	add	a0,a0,-1106 # ffffffffc020a040 <ide>
                   size_t nsecs) {
ffffffffc020049a:	1141                	add	sp,sp,-16
ffffffffc020049c:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020049e:	953e                	add	a0,a0,a5
ffffffffc02004a0:	00969613          	sll	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004a4:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004a6:	6b7030ef          	jal	ffffffffc020435c <memcpy>
    return 0;
}
ffffffffc02004aa:	60a2                	ld	ra,8(sp)
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	0141                	add	sp,sp,16
ffffffffc02004b0:	8082                	ret

ffffffffc02004b2 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004b2:	100167f3          	csrrs	a5,sstatus,2
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004b8:	100177f3          	csrrc	a5,sstatus,2
ffffffffc02004bc:	8082                	ret

ffffffffc02004be <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004be:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004c2:	1141                	add	sp,sp,-16
ffffffffc02004c4:	e022                	sd	s0,0(sp)
ffffffffc02004c6:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004c8:	1007f793          	and	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004cc:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004d0:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004d2:	04b00613          	li	a2,75
ffffffffc02004d6:	e399                	bnez	a5,ffffffffc02004dc <pgfault_handler+0x1e>
ffffffffc02004d8:	05500613          	li	a2,85
ffffffffc02004dc:	11843703          	ld	a4,280(s0)
ffffffffc02004e0:	47bd                	li	a5,15
ffffffffc02004e2:	05200693          	li	a3,82
ffffffffc02004e6:	00f71463          	bne	a4,a5,ffffffffc02004ee <pgfault_handler+0x30>
ffffffffc02004ea:	05700693          	li	a3,87
ffffffffc02004ee:	00004517          	auipc	a0,0x4
ffffffffc02004f2:	12250513          	add	a0,a0,290 # ffffffffc0204610 <etext+0x29c>
ffffffffc02004f6:	bc5ff0ef          	jal	ffffffffc02000ba <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc02004fa:	00011517          	auipc	a0,0x11
ffffffffc02004fe:	06e53503          	ld	a0,110(a0) # ffffffffc0211568 <check_mm_struct>
ffffffffc0200502:	c911                	beqz	a0,ffffffffc0200516 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200504:	11043603          	ld	a2,272(s0)
ffffffffc0200508:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc020050c:	6402                	ld	s0,0(sp)
ffffffffc020050e:	60a2                	ld	ra,8(sp)
ffffffffc0200510:	0141                	add	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200512:	7780306f          	j	ffffffffc0203c8a <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200516:	00004617          	auipc	a2,0x4
ffffffffc020051a:	11a60613          	add	a2,a2,282 # ffffffffc0204630 <etext+0x2bc>
ffffffffc020051e:	07800593          	li	a1,120
ffffffffc0200522:	00004517          	auipc	a0,0x4
ffffffffc0200526:	12650513          	add	a0,a0,294 # ffffffffc0204648 <etext+0x2d4>
ffffffffc020052a:	e37ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020052e <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020052e:	14005073          	csrw	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200532:	00000797          	auipc	a5,0x0
ffffffffc0200536:	47e78793          	add	a5,a5,1150 # ffffffffc02009b0 <__alltraps>
ffffffffc020053a:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc020053e:	100167f3          	csrrs	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200542:	000407b7          	lui	a5,0x40
ffffffffc0200546:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020054a:	8082                	ret

ffffffffc020054c <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020054c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020054e:	1141                	add	sp,sp,-16
ffffffffc0200550:	e022                	sd	s0,0(sp)
ffffffffc0200552:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200554:	00004517          	auipc	a0,0x4
ffffffffc0200558:	10c50513          	add	a0,a0,268 # ffffffffc0204660 <etext+0x2ec>
void print_regs(struct pushregs *gpr) {
ffffffffc020055c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020055e:	b5dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200562:	640c                	ld	a1,8(s0)
ffffffffc0200564:	00004517          	auipc	a0,0x4
ffffffffc0200568:	11450513          	add	a0,a0,276 # ffffffffc0204678 <etext+0x304>
ffffffffc020056c:	b4fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200570:	680c                	ld	a1,16(s0)
ffffffffc0200572:	00004517          	auipc	a0,0x4
ffffffffc0200576:	11e50513          	add	a0,a0,286 # ffffffffc0204690 <etext+0x31c>
ffffffffc020057a:	b41ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020057e:	6c0c                	ld	a1,24(s0)
ffffffffc0200580:	00004517          	auipc	a0,0x4
ffffffffc0200584:	12850513          	add	a0,a0,296 # ffffffffc02046a8 <etext+0x334>
ffffffffc0200588:	b33ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020058c:	700c                	ld	a1,32(s0)
ffffffffc020058e:	00004517          	auipc	a0,0x4
ffffffffc0200592:	13250513          	add	a0,a0,306 # ffffffffc02046c0 <etext+0x34c>
ffffffffc0200596:	b25ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020059a:	740c                	ld	a1,40(s0)
ffffffffc020059c:	00004517          	auipc	a0,0x4
ffffffffc02005a0:	13c50513          	add	a0,a0,316 # ffffffffc02046d8 <etext+0x364>
ffffffffc02005a4:	b17ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005a8:	780c                	ld	a1,48(s0)
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	14650513          	add	a0,a0,326 # ffffffffc02046f0 <etext+0x37c>
ffffffffc02005b2:	b09ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005b6:	7c0c                	ld	a1,56(s0)
ffffffffc02005b8:	00004517          	auipc	a0,0x4
ffffffffc02005bc:	15050513          	add	a0,a0,336 # ffffffffc0204708 <etext+0x394>
ffffffffc02005c0:	afbff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005c4:	602c                	ld	a1,64(s0)
ffffffffc02005c6:	00004517          	auipc	a0,0x4
ffffffffc02005ca:	15a50513          	add	a0,a0,346 # ffffffffc0204720 <etext+0x3ac>
ffffffffc02005ce:	aedff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02005d2:	642c                	ld	a1,72(s0)
ffffffffc02005d4:	00004517          	auipc	a0,0x4
ffffffffc02005d8:	16450513          	add	a0,a0,356 # ffffffffc0204738 <etext+0x3c4>
ffffffffc02005dc:	adfff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02005e0:	682c                	ld	a1,80(s0)
ffffffffc02005e2:	00004517          	auipc	a0,0x4
ffffffffc02005e6:	16e50513          	add	a0,a0,366 # ffffffffc0204750 <etext+0x3dc>
ffffffffc02005ea:	ad1ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02005ee:	6c2c                	ld	a1,88(s0)
ffffffffc02005f0:	00004517          	auipc	a0,0x4
ffffffffc02005f4:	17850513          	add	a0,a0,376 # ffffffffc0204768 <etext+0x3f4>
ffffffffc02005f8:	ac3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02005fc:	702c                	ld	a1,96(s0)
ffffffffc02005fe:	00004517          	auipc	a0,0x4
ffffffffc0200602:	18250513          	add	a0,a0,386 # ffffffffc0204780 <etext+0x40c>
ffffffffc0200606:	ab5ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020060a:	742c                	ld	a1,104(s0)
ffffffffc020060c:	00004517          	auipc	a0,0x4
ffffffffc0200610:	18c50513          	add	a0,a0,396 # ffffffffc0204798 <etext+0x424>
ffffffffc0200614:	aa7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200618:	782c                	ld	a1,112(s0)
ffffffffc020061a:	00004517          	auipc	a0,0x4
ffffffffc020061e:	19650513          	add	a0,a0,406 # ffffffffc02047b0 <etext+0x43c>
ffffffffc0200622:	a99ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200626:	7c2c                	ld	a1,120(s0)
ffffffffc0200628:	00004517          	auipc	a0,0x4
ffffffffc020062c:	1a050513          	add	a0,a0,416 # ffffffffc02047c8 <etext+0x454>
ffffffffc0200630:	a8bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200634:	604c                	ld	a1,128(s0)
ffffffffc0200636:	00004517          	auipc	a0,0x4
ffffffffc020063a:	1aa50513          	add	a0,a0,426 # ffffffffc02047e0 <etext+0x46c>
ffffffffc020063e:	a7dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200642:	644c                	ld	a1,136(s0)
ffffffffc0200644:	00004517          	auipc	a0,0x4
ffffffffc0200648:	1b450513          	add	a0,a0,436 # ffffffffc02047f8 <etext+0x484>
ffffffffc020064c:	a6fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200650:	684c                	ld	a1,144(s0)
ffffffffc0200652:	00004517          	auipc	a0,0x4
ffffffffc0200656:	1be50513          	add	a0,a0,446 # ffffffffc0204810 <etext+0x49c>
ffffffffc020065a:	a61ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020065e:	6c4c                	ld	a1,152(s0)
ffffffffc0200660:	00004517          	auipc	a0,0x4
ffffffffc0200664:	1c850513          	add	a0,a0,456 # ffffffffc0204828 <etext+0x4b4>
ffffffffc0200668:	a53ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020066c:	704c                	ld	a1,160(s0)
ffffffffc020066e:	00004517          	auipc	a0,0x4
ffffffffc0200672:	1d250513          	add	a0,a0,466 # ffffffffc0204840 <etext+0x4cc>
ffffffffc0200676:	a45ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020067a:	744c                	ld	a1,168(s0)
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	1dc50513          	add	a0,a0,476 # ffffffffc0204858 <etext+0x4e4>
ffffffffc0200684:	a37ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200688:	784c                	ld	a1,176(s0)
ffffffffc020068a:	00004517          	auipc	a0,0x4
ffffffffc020068e:	1e650513          	add	a0,a0,486 # ffffffffc0204870 <etext+0x4fc>
ffffffffc0200692:	a29ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200696:	7c4c                	ld	a1,184(s0)
ffffffffc0200698:	00004517          	auipc	a0,0x4
ffffffffc020069c:	1f050513          	add	a0,a0,496 # ffffffffc0204888 <etext+0x514>
ffffffffc02006a0:	a1bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006a4:	606c                	ld	a1,192(s0)
ffffffffc02006a6:	00004517          	auipc	a0,0x4
ffffffffc02006aa:	1fa50513          	add	a0,a0,506 # ffffffffc02048a0 <etext+0x52c>
ffffffffc02006ae:	a0dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006b2:	646c                	ld	a1,200(s0)
ffffffffc02006b4:	00004517          	auipc	a0,0x4
ffffffffc02006b8:	20450513          	add	a0,a0,516 # ffffffffc02048b8 <etext+0x544>
ffffffffc02006bc:	9ffff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006c0:	686c                	ld	a1,208(s0)
ffffffffc02006c2:	00004517          	auipc	a0,0x4
ffffffffc02006c6:	20e50513          	add	a0,a0,526 # ffffffffc02048d0 <etext+0x55c>
ffffffffc02006ca:	9f1ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02006ce:	6c6c                	ld	a1,216(s0)
ffffffffc02006d0:	00004517          	auipc	a0,0x4
ffffffffc02006d4:	21850513          	add	a0,a0,536 # ffffffffc02048e8 <etext+0x574>
ffffffffc02006d8:	9e3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02006dc:	706c                	ld	a1,224(s0)
ffffffffc02006de:	00004517          	auipc	a0,0x4
ffffffffc02006e2:	22250513          	add	a0,a0,546 # ffffffffc0204900 <etext+0x58c>
ffffffffc02006e6:	9d5ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02006ea:	746c                	ld	a1,232(s0)
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	22c50513          	add	a0,a0,556 # ffffffffc0204918 <etext+0x5a4>
ffffffffc02006f4:	9c7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02006f8:	786c                	ld	a1,240(s0)
ffffffffc02006fa:	00004517          	auipc	a0,0x4
ffffffffc02006fe:	23650513          	add	a0,a0,566 # ffffffffc0204930 <etext+0x5bc>
ffffffffc0200702:	9b9ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200706:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200708:	6402                	ld	s0,0(sp)
ffffffffc020070a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020070c:	00004517          	auipc	a0,0x4
ffffffffc0200710:	23c50513          	add	a0,a0,572 # ffffffffc0204948 <etext+0x5d4>
}
ffffffffc0200714:	0141                	add	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200716:	b255                	j	ffffffffc02000ba <cprintf>

ffffffffc0200718 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200718:	1141                	add	sp,sp,-16
ffffffffc020071a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020071c:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020071e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200720:	00004517          	auipc	a0,0x4
ffffffffc0200724:	24050513          	add	a0,a0,576 # ffffffffc0204960 <etext+0x5ec>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200728:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020072a:	991ff0ef          	jal	ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc020072e:	8522                	mv	a0,s0
ffffffffc0200730:	e1dff0ef          	jal	ffffffffc020054c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200734:	10043583          	ld	a1,256(s0)
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	24050513          	add	a0,a0,576 # ffffffffc0204978 <etext+0x604>
ffffffffc0200740:	97bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200744:	10843583          	ld	a1,264(s0)
ffffffffc0200748:	00004517          	auipc	a0,0x4
ffffffffc020074c:	24850513          	add	a0,a0,584 # ffffffffc0204990 <etext+0x61c>
ffffffffc0200750:	96bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200754:	11043583          	ld	a1,272(s0)
ffffffffc0200758:	00004517          	auipc	a0,0x4
ffffffffc020075c:	25050513          	add	a0,a0,592 # ffffffffc02049a8 <etext+0x634>
ffffffffc0200760:	95bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200764:	11843583          	ld	a1,280(s0)
}
ffffffffc0200768:	6402                	ld	s0,0(sp)
ffffffffc020076a:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020076c:	00004517          	auipc	a0,0x4
ffffffffc0200770:	25450513          	add	a0,a0,596 # ffffffffc02049c0 <etext+0x64c>
}
ffffffffc0200774:	0141                	add	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200776:	945ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc020077a <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020077a:	11853783          	ld	a5,280(a0)
ffffffffc020077e:	472d                	li	a4,11
ffffffffc0200780:	0786                	sll	a5,a5,0x1
ffffffffc0200782:	8385                	srl	a5,a5,0x1
ffffffffc0200784:	06f76c63          	bltu	a4,a5,ffffffffc02007fc <interrupt_handler+0x82>
ffffffffc0200788:	00005717          	auipc	a4,0x5
ffffffffc020078c:	77870713          	add	a4,a4,1912 # ffffffffc0205f00 <commands+0x48>
ffffffffc0200790:	078a                	sll	a5,a5,0x2
ffffffffc0200792:	97ba                	add	a5,a5,a4
ffffffffc0200794:	439c                	lw	a5,0(a5)
ffffffffc0200796:	97ba                	add	a5,a5,a4
ffffffffc0200798:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc020079a:	00004517          	auipc	a0,0x4
ffffffffc020079e:	29e50513          	add	a0,a0,670 # ffffffffc0204a38 <etext+0x6c4>
ffffffffc02007a2:	919ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007a6:	00004517          	auipc	a0,0x4
ffffffffc02007aa:	27250513          	add	a0,a0,626 # ffffffffc0204a18 <etext+0x6a4>
ffffffffc02007ae:	90dff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007b2:	00004517          	auipc	a0,0x4
ffffffffc02007b6:	22650513          	add	a0,a0,550 # ffffffffc02049d8 <etext+0x664>
ffffffffc02007ba:	901ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007be:	00004517          	auipc	a0,0x4
ffffffffc02007c2:	23a50513          	add	a0,a0,570 # ffffffffc02049f8 <etext+0x684>
ffffffffc02007c6:	8f5ff06f          	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02007ca:	1141                	add	sp,sp,-16
ffffffffc02007cc:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02007ce:	c29ff0ef          	jal	ffffffffc02003f6 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02007d2:	00011697          	auipc	a3,0x11
ffffffffc02007d6:	d3668693          	add	a3,a3,-714 # ffffffffc0211508 <ticks>
ffffffffc02007da:	629c                	ld	a5,0(a3)
ffffffffc02007dc:	06400713          	li	a4,100
ffffffffc02007e0:	0785                	add	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
ffffffffc02007e2:	02e7f733          	remu	a4,a5,a4
ffffffffc02007e6:	e29c                	sd	a5,0(a3)
ffffffffc02007e8:	cb19                	beqz	a4,ffffffffc02007fe <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02007ea:	60a2                	ld	ra,8(sp)
ffffffffc02007ec:	0141                	add	sp,sp,16
ffffffffc02007ee:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc02007f0:	00004517          	auipc	a0,0x4
ffffffffc02007f4:	27850513          	add	a0,a0,632 # ffffffffc0204a68 <etext+0x6f4>
ffffffffc02007f8:	8c3ff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc02007fc:	bf31                	j	ffffffffc0200718 <print_trapframe>
}
ffffffffc02007fe:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200800:	06400593          	li	a1,100
ffffffffc0200804:	00004517          	auipc	a0,0x4
ffffffffc0200808:	25450513          	add	a0,a0,596 # ffffffffc0204a58 <etext+0x6e4>
}
ffffffffc020080c:	0141                	add	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020080e:	8adff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0200812 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200812:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200816:	1101                	add	sp,sp,-32
ffffffffc0200818:	e822                	sd	s0,16(sp)
ffffffffc020081a:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc020081c:	473d                	li	a4,15
void exception_handler(struct trapframe *tf) {
ffffffffc020081e:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200820:	14f76d63          	bltu	a4,a5,ffffffffc020097a <exception_handler+0x168>
ffffffffc0200824:	00005717          	auipc	a4,0x5
ffffffffc0200828:	70c70713          	add	a4,a4,1804 # ffffffffc0205f30 <commands+0x78>
ffffffffc020082c:	078a                	sll	a5,a5,0x2
ffffffffc020082e:	97ba                	add	a5,a5,a4
ffffffffc0200830:	439c                	lw	a5,0(a5)
ffffffffc0200832:	97ba                	add	a5,a5,a4
ffffffffc0200834:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200836:	00004517          	auipc	a0,0x4
ffffffffc020083a:	3f250513          	add	a0,a0,1010 # ffffffffc0204c28 <etext+0x8b4>
ffffffffc020083e:	e426                	sd	s1,8(sp)
ffffffffc0200840:	87bff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200844:	8522                	mv	a0,s0
ffffffffc0200846:	c79ff0ef          	jal	ffffffffc02004be <pgfault_handler>
ffffffffc020084a:	84aa                	mv	s1,a0
ffffffffc020084c:	12051c63          	bnez	a0,ffffffffc0200984 <exception_handler+0x172>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200850:	60e2                	ld	ra,24(sp)
ffffffffc0200852:	6442                	ld	s0,16(sp)
ffffffffc0200854:	64a2                	ld	s1,8(sp)
ffffffffc0200856:	6105                	add	sp,sp,32
ffffffffc0200858:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc020085a:	00004517          	auipc	a0,0x4
ffffffffc020085e:	22e50513          	add	a0,a0,558 # ffffffffc0204a88 <etext+0x714>
}
ffffffffc0200862:	6442                	ld	s0,16(sp)
ffffffffc0200864:	60e2                	ld	ra,24(sp)
ffffffffc0200866:	6105                	add	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200868:	853ff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc020086c:	00004517          	auipc	a0,0x4
ffffffffc0200870:	23c50513          	add	a0,a0,572 # ffffffffc0204aa8 <etext+0x734>
ffffffffc0200874:	b7fd                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200876:	00004517          	auipc	a0,0x4
ffffffffc020087a:	25250513          	add	a0,a0,594 # ffffffffc0204ac8 <etext+0x754>
ffffffffc020087e:	b7d5                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200880:	00004517          	auipc	a0,0x4
ffffffffc0200884:	26050513          	add	a0,a0,608 # ffffffffc0204ae0 <etext+0x76c>
ffffffffc0200888:	bfe9                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc020088a:	00004517          	auipc	a0,0x4
ffffffffc020088e:	26650513          	add	a0,a0,614 # ffffffffc0204af0 <etext+0x77c>
ffffffffc0200892:	bfc1                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200894:	00004517          	auipc	a0,0x4
ffffffffc0200898:	27c50513          	add	a0,a0,636 # ffffffffc0204b10 <etext+0x79c>
ffffffffc020089c:	e426                	sd	s1,8(sp)
ffffffffc020089e:	81dff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008a2:	8522                	mv	a0,s0
ffffffffc02008a4:	c1bff0ef          	jal	ffffffffc02004be <pgfault_handler>
ffffffffc02008a8:	84aa                	mv	s1,a0
ffffffffc02008aa:	d15d                	beqz	a0,ffffffffc0200850 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008ac:	8522                	mv	a0,s0
ffffffffc02008ae:	e6bff0ef          	jal	ffffffffc0200718 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008b2:	86a6                	mv	a3,s1
ffffffffc02008b4:	00004617          	auipc	a2,0x4
ffffffffc02008b8:	27460613          	add	a2,a2,628 # ffffffffc0204b28 <etext+0x7b4>
ffffffffc02008bc:	0ca00593          	li	a1,202
ffffffffc02008c0:	00004517          	auipc	a0,0x4
ffffffffc02008c4:	d8850513          	add	a0,a0,-632 # ffffffffc0204648 <etext+0x2d4>
ffffffffc02008c8:	a99ff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	27c50513          	add	a0,a0,636 # ffffffffc0204b48 <etext+0x7d4>
ffffffffc02008d4:	b779                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02008d6:	00004517          	auipc	a0,0x4
ffffffffc02008da:	28a50513          	add	a0,a0,650 # ffffffffc0204b60 <etext+0x7ec>
ffffffffc02008de:	e426                	sd	s1,8(sp)
ffffffffc02008e0:	fdaff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008e4:	8522                	mv	a0,s0
ffffffffc02008e6:	bd9ff0ef          	jal	ffffffffc02004be <pgfault_handler>
ffffffffc02008ea:	84aa                	mv	s1,a0
ffffffffc02008ec:	d135                	beqz	a0,ffffffffc0200850 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008ee:	8522                	mv	a0,s0
ffffffffc02008f0:	e29ff0ef          	jal	ffffffffc0200718 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008f4:	86a6                	mv	a3,s1
ffffffffc02008f6:	00004617          	auipc	a2,0x4
ffffffffc02008fa:	23260613          	add	a2,a2,562 # ffffffffc0204b28 <etext+0x7b4>
ffffffffc02008fe:	0d400593          	li	a1,212
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	d4650513          	add	a0,a0,-698 # ffffffffc0204648 <etext+0x2d4>
ffffffffc020090a:	a57ff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc020090e:	00004517          	auipc	a0,0x4
ffffffffc0200912:	26a50513          	add	a0,a0,618 # ffffffffc0204b78 <etext+0x804>
ffffffffc0200916:	b7b1                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200918:	00004517          	auipc	a0,0x4
ffffffffc020091c:	28050513          	add	a0,a0,640 # ffffffffc0204b98 <etext+0x824>
ffffffffc0200920:	b789                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200922:	00004517          	auipc	a0,0x4
ffffffffc0200926:	29650513          	add	a0,a0,662 # ffffffffc0204bb8 <etext+0x844>
ffffffffc020092a:	bf25                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	2ac50513          	add	a0,a0,684 # ffffffffc0204bd8 <etext+0x864>
ffffffffc0200934:	b73d                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200936:	00004517          	auipc	a0,0x4
ffffffffc020093a:	2c250513          	add	a0,a0,706 # ffffffffc0204bf8 <etext+0x884>
ffffffffc020093e:	b715                	j	ffffffffc0200862 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200940:	00004517          	auipc	a0,0x4
ffffffffc0200944:	2d050513          	add	a0,a0,720 # ffffffffc0204c10 <etext+0x89c>
ffffffffc0200948:	e426                	sd	s1,8(sp)
ffffffffc020094a:	f70ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020094e:	8522                	mv	a0,s0
ffffffffc0200950:	b6fff0ef          	jal	ffffffffc02004be <pgfault_handler>
ffffffffc0200954:	84aa                	mv	s1,a0
ffffffffc0200956:	ee050de3          	beqz	a0,ffffffffc0200850 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020095a:	8522                	mv	a0,s0
ffffffffc020095c:	dbdff0ef          	jal	ffffffffc0200718 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200960:	86a6                	mv	a3,s1
ffffffffc0200962:	00004617          	auipc	a2,0x4
ffffffffc0200966:	1c660613          	add	a2,a2,454 # ffffffffc0204b28 <etext+0x7b4>
ffffffffc020096a:	0ea00593          	li	a1,234
ffffffffc020096e:	00004517          	auipc	a0,0x4
ffffffffc0200972:	cda50513          	add	a0,a0,-806 # ffffffffc0204648 <etext+0x2d4>
ffffffffc0200976:	9ebff0ef          	jal	ffffffffc0200360 <__panic>
            print_trapframe(tf);
ffffffffc020097a:	8522                	mv	a0,s0
}
ffffffffc020097c:	6442                	ld	s0,16(sp)
ffffffffc020097e:	60e2                	ld	ra,24(sp)
ffffffffc0200980:	6105                	add	sp,sp,32
            print_trapframe(tf);
ffffffffc0200982:	bb59                	j	ffffffffc0200718 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200984:	8522                	mv	a0,s0
ffffffffc0200986:	d93ff0ef          	jal	ffffffffc0200718 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc020098a:	86a6                	mv	a3,s1
ffffffffc020098c:	00004617          	auipc	a2,0x4
ffffffffc0200990:	19c60613          	add	a2,a2,412 # ffffffffc0204b28 <etext+0x7b4>
ffffffffc0200994:	0f100593          	li	a1,241
ffffffffc0200998:	00004517          	auipc	a0,0x4
ffffffffc020099c:	cb050513          	add	a0,a0,-848 # ffffffffc0204648 <etext+0x2d4>
ffffffffc02009a0:	9c1ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02009a4 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009a4:	11853783          	ld	a5,280(a0)
ffffffffc02009a8:	0007c363          	bltz	a5,ffffffffc02009ae <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009ac:	b59d                	j	ffffffffc0200812 <exception_handler>
        interrupt_handler(tf);
ffffffffc02009ae:	b3f1                	j	ffffffffc020077a <interrupt_handler>

ffffffffc02009b0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009b0:	14011073          	csrw	sscratch,sp
ffffffffc02009b4:	712d                	add	sp,sp,-288
ffffffffc02009b6:	e406                	sd	ra,8(sp)
ffffffffc02009b8:	ec0e                	sd	gp,24(sp)
ffffffffc02009ba:	f012                	sd	tp,32(sp)
ffffffffc02009bc:	f416                	sd	t0,40(sp)
ffffffffc02009be:	f81a                	sd	t1,48(sp)
ffffffffc02009c0:	fc1e                	sd	t2,56(sp)
ffffffffc02009c2:	e0a2                	sd	s0,64(sp)
ffffffffc02009c4:	e4a6                	sd	s1,72(sp)
ffffffffc02009c6:	e8aa                	sd	a0,80(sp)
ffffffffc02009c8:	ecae                	sd	a1,88(sp)
ffffffffc02009ca:	f0b2                	sd	a2,96(sp)
ffffffffc02009cc:	f4b6                	sd	a3,104(sp)
ffffffffc02009ce:	f8ba                	sd	a4,112(sp)
ffffffffc02009d0:	fcbe                	sd	a5,120(sp)
ffffffffc02009d2:	e142                	sd	a6,128(sp)
ffffffffc02009d4:	e546                	sd	a7,136(sp)
ffffffffc02009d6:	e94a                	sd	s2,144(sp)
ffffffffc02009d8:	ed4e                	sd	s3,152(sp)
ffffffffc02009da:	f152                	sd	s4,160(sp)
ffffffffc02009dc:	f556                	sd	s5,168(sp)
ffffffffc02009de:	f95a                	sd	s6,176(sp)
ffffffffc02009e0:	fd5e                	sd	s7,184(sp)
ffffffffc02009e2:	e1e2                	sd	s8,192(sp)
ffffffffc02009e4:	e5e6                	sd	s9,200(sp)
ffffffffc02009e6:	e9ea                	sd	s10,208(sp)
ffffffffc02009e8:	edee                	sd	s11,216(sp)
ffffffffc02009ea:	f1f2                	sd	t3,224(sp)
ffffffffc02009ec:	f5f6                	sd	t4,232(sp)
ffffffffc02009ee:	f9fa                	sd	t5,240(sp)
ffffffffc02009f0:	fdfe                	sd	t6,248(sp)
ffffffffc02009f2:	14002473          	csrr	s0,sscratch
ffffffffc02009f6:	100024f3          	csrr	s1,sstatus
ffffffffc02009fa:	14102973          	csrr	s2,sepc
ffffffffc02009fe:	143029f3          	csrr	s3,stval
ffffffffc0200a02:	14202a73          	csrr	s4,scause
ffffffffc0200a06:	e822                	sd	s0,16(sp)
ffffffffc0200a08:	e226                	sd	s1,256(sp)
ffffffffc0200a0a:	e64a                	sd	s2,264(sp)
ffffffffc0200a0c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a0e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a10:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a12:	f93ff0ef          	jal	ffffffffc02009a4 <trap>

ffffffffc0200a16 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a16:	6492                	ld	s1,256(sp)
ffffffffc0200a18:	6932                	ld	s2,264(sp)
ffffffffc0200a1a:	10049073          	csrw	sstatus,s1
ffffffffc0200a1e:	14191073          	csrw	sepc,s2
ffffffffc0200a22:	60a2                	ld	ra,8(sp)
ffffffffc0200a24:	61e2                	ld	gp,24(sp)
ffffffffc0200a26:	7202                	ld	tp,32(sp)
ffffffffc0200a28:	72a2                	ld	t0,40(sp)
ffffffffc0200a2a:	7342                	ld	t1,48(sp)
ffffffffc0200a2c:	73e2                	ld	t2,56(sp)
ffffffffc0200a2e:	6406                	ld	s0,64(sp)
ffffffffc0200a30:	64a6                	ld	s1,72(sp)
ffffffffc0200a32:	6546                	ld	a0,80(sp)
ffffffffc0200a34:	65e6                	ld	a1,88(sp)
ffffffffc0200a36:	7606                	ld	a2,96(sp)
ffffffffc0200a38:	76a6                	ld	a3,104(sp)
ffffffffc0200a3a:	7746                	ld	a4,112(sp)
ffffffffc0200a3c:	77e6                	ld	a5,120(sp)
ffffffffc0200a3e:	680a                	ld	a6,128(sp)
ffffffffc0200a40:	68aa                	ld	a7,136(sp)
ffffffffc0200a42:	694a                	ld	s2,144(sp)
ffffffffc0200a44:	69ea                	ld	s3,152(sp)
ffffffffc0200a46:	7a0a                	ld	s4,160(sp)
ffffffffc0200a48:	7aaa                	ld	s5,168(sp)
ffffffffc0200a4a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a4c:	7bea                	ld	s7,184(sp)
ffffffffc0200a4e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a50:	6cae                	ld	s9,200(sp)
ffffffffc0200a52:	6d4e                	ld	s10,208(sp)
ffffffffc0200a54:	6dee                	ld	s11,216(sp)
ffffffffc0200a56:	7e0e                	ld	t3,224(sp)
ffffffffc0200a58:	7eae                	ld	t4,232(sp)
ffffffffc0200a5a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a5c:	7fee                	ld	t6,248(sp)
ffffffffc0200a5e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200a60:	10200073          	sret
	...

ffffffffc0200a70 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200a70:	00010797          	auipc	a5,0x10
ffffffffc0200a74:	5d078793          	add	a5,a5,1488 # ffffffffc0211040 <free_area>
ffffffffc0200a78:	e79c                	sd	a5,8(a5)
ffffffffc0200a7a:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200a7c:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200a80:	8082                	ret

ffffffffc0200a82 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200a82:	00010517          	auipc	a0,0x10
ffffffffc0200a86:	5ce56503          	lwu	a0,1486(a0) # ffffffffc0211050 <free_area+0x10>
ffffffffc0200a8a:	8082                	ret

ffffffffc0200a8c <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200a8c:	715d                	add	sp,sp,-80
ffffffffc0200a8e:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200a90:	00010417          	auipc	s0,0x10
ffffffffc0200a94:	5b040413          	add	s0,s0,1456 # ffffffffc0211040 <free_area>
ffffffffc0200a98:	641c                	ld	a5,8(s0)
ffffffffc0200a9a:	e486                	sd	ra,72(sp)
ffffffffc0200a9c:	fc26                	sd	s1,56(sp)
ffffffffc0200a9e:	f84a                	sd	s2,48(sp)
ffffffffc0200aa0:	f44e                	sd	s3,40(sp)
ffffffffc0200aa2:	f052                	sd	s4,32(sp)
ffffffffc0200aa4:	ec56                	sd	s5,24(sp)
ffffffffc0200aa6:	e85a                	sd	s6,16(sp)
ffffffffc0200aa8:	e45e                	sd	s7,8(sp)
ffffffffc0200aaa:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200aac:	2e878063          	beq	a5,s0,ffffffffc0200d8c <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200ab0:	4481                	li	s1,0
ffffffffc0200ab2:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ab4:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ab8:	8b09                	and	a4,a4,2
ffffffffc0200aba:	2c070d63          	beqz	a4,ffffffffc0200d94 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200abe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ac2:	679c                	ld	a5,8(a5)
ffffffffc0200ac4:	2905                	addw	s2,s2,1
ffffffffc0200ac6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ac8:	fe8796e3          	bne	a5,s0,ffffffffc0200ab4 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200acc:	89a6                	mv	s3,s1
ffffffffc0200ace:	395000ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc0200ad2:	73351163          	bne	a0,s3,ffffffffc02011f4 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ad6:	4505                	li	a0,1
ffffffffc0200ad8:	2bb000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200adc:	8a2a                	mv	s4,a0
ffffffffc0200ade:	44050b63          	beqz	a0,ffffffffc0200f34 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ae2:	4505                	li	a0,1
ffffffffc0200ae4:	2af000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200ae8:	89aa                	mv	s3,a0
ffffffffc0200aea:	72050563          	beqz	a0,ffffffffc0201214 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aee:	4505                	li	a0,1
ffffffffc0200af0:	2a3000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200af4:	8aaa                	mv	s5,a0
ffffffffc0200af6:	4a050f63          	beqz	a0,ffffffffc0200fb4 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200afa:	2b3a0d63          	beq	s4,s3,ffffffffc0200db4 <default_check+0x328>
ffffffffc0200afe:	2aaa0b63          	beq	s4,a0,ffffffffc0200db4 <default_check+0x328>
ffffffffc0200b02:	2aa98963          	beq	s3,a0,ffffffffc0200db4 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b06:	000a2783          	lw	a5,0(s4)
ffffffffc0200b0a:	2c079563          	bnez	a5,ffffffffc0200dd4 <default_check+0x348>
ffffffffc0200b0e:	0009a783          	lw	a5,0(s3)
ffffffffc0200b12:	2c079163          	bnez	a5,ffffffffc0200dd4 <default_check+0x348>
ffffffffc0200b16:	411c                	lw	a5,0(a0)
ffffffffc0200b18:	2a079e63          	bnez	a5,ffffffffc0200dd4 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b1c:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0200b20:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0200b24:	07b2                	sll	a5,a5,0xc
ffffffffc0200b26:	e3978793          	add	a5,a5,-455
ffffffffc0200b2a:	07b2                	sll	a5,a5,0xc
ffffffffc0200b2c:	00011717          	auipc	a4,0x11
ffffffffc0200b30:	a0c73703          	ld	a4,-1524(a4) # ffffffffc0211538 <pages>
ffffffffc0200b34:	e3978793          	add	a5,a5,-455
ffffffffc0200b38:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200b3c:	07b2                	sll	a5,a5,0xc
ffffffffc0200b3e:	868d                	sra	a3,a3,0x3
ffffffffc0200b40:	e3978793          	add	a5,a5,-455
ffffffffc0200b44:	02f686b3          	mul	a3,a3,a5
ffffffffc0200b48:	00005597          	auipc	a1,0x5
ffffffffc0200b4c:	5f05b583          	ld	a1,1520(a1) # ffffffffc0206138 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b50:	00011617          	auipc	a2,0x11
ffffffffc0200b54:	9e063603          	ld	a2,-1568(a2) # ffffffffc0211530 <npage>
ffffffffc0200b58:	0632                	sll	a2,a2,0xc
ffffffffc0200b5a:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b5c:	06b2                	sll	a3,a3,0xc
ffffffffc0200b5e:	28c6fb63          	bgeu	a3,a2,ffffffffc0200df4 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b62:	40e986b3          	sub	a3,s3,a4
ffffffffc0200b66:	868d                	sra	a3,a3,0x3
ffffffffc0200b68:	02f686b3          	mul	a3,a3,a5
ffffffffc0200b6c:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b6e:	06b2                	sll	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b70:	4cc6f263          	bgeu	a3,a2,ffffffffc0201034 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b74:	40e50733          	sub	a4,a0,a4
ffffffffc0200b78:	870d                	sra	a4,a4,0x3
ffffffffc0200b7a:	02f707b3          	mul	a5,a4,a5
ffffffffc0200b7e:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b80:	07b2                	sll	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b82:	30c7f963          	bgeu	a5,a2,ffffffffc0200e94 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200b86:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b88:	00043c03          	ld	s8,0(s0)
ffffffffc0200b8c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200b90:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200b94:	e400                	sd	s0,8(s0)
ffffffffc0200b96:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200b98:	00010797          	auipc	a5,0x10
ffffffffc0200b9c:	4a07ac23          	sw	zero,1208(a5) # ffffffffc0211050 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ba0:	1f3000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200ba4:	2c051863          	bnez	a0,ffffffffc0200e74 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200ba8:	4585                	li	a1,1
ffffffffc0200baa:	8552                	mv	a0,s4
ffffffffc0200bac:	277000ef          	jal	ffffffffc0201622 <free_pages>
    free_page(p1);
ffffffffc0200bb0:	4585                	li	a1,1
ffffffffc0200bb2:	854e                	mv	a0,s3
ffffffffc0200bb4:	26f000ef          	jal	ffffffffc0201622 <free_pages>
    free_page(p2);
ffffffffc0200bb8:	4585                	li	a1,1
ffffffffc0200bba:	8556                	mv	a0,s5
ffffffffc0200bbc:	267000ef          	jal	ffffffffc0201622 <free_pages>
    assert(nr_free == 3);
ffffffffc0200bc0:	4818                	lw	a4,16(s0)
ffffffffc0200bc2:	478d                	li	a5,3
ffffffffc0200bc4:	28f71863          	bne	a4,a5,ffffffffc0200e54 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bc8:	4505                	li	a0,1
ffffffffc0200bca:	1c9000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200bce:	89aa                	mv	s3,a0
ffffffffc0200bd0:	26050263          	beqz	a0,ffffffffc0200e34 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200bd4:	4505                	li	a0,1
ffffffffc0200bd6:	1bd000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200bda:	8aaa                	mv	s5,a0
ffffffffc0200bdc:	3a050c63          	beqz	a0,ffffffffc0200f94 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200be0:	4505                	li	a0,1
ffffffffc0200be2:	1b1000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200be6:	8a2a                	mv	s4,a0
ffffffffc0200be8:	38050663          	beqz	a0,ffffffffc0200f74 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200bec:	4505                	li	a0,1
ffffffffc0200bee:	1a5000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200bf2:	36051163          	bnez	a0,ffffffffc0200f54 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200bf6:	4585                	li	a1,1
ffffffffc0200bf8:	854e                	mv	a0,s3
ffffffffc0200bfa:	229000ef          	jal	ffffffffc0201622 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200bfe:	641c                	ld	a5,8(s0)
ffffffffc0200c00:	20878a63          	beq	a5,s0,ffffffffc0200e14 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200c04:	4505                	li	a0,1
ffffffffc0200c06:	18d000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200c0a:	30a99563          	bne	s3,a0,ffffffffc0200f14 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200c0e:	4505                	li	a0,1
ffffffffc0200c10:	183000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200c14:	2e051063          	bnez	a0,ffffffffc0200ef4 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200c18:	481c                	lw	a5,16(s0)
ffffffffc0200c1a:	2a079d63          	bnez	a5,ffffffffc0200ed4 <default_check+0x448>
    free_page(p);
ffffffffc0200c1e:	854e                	mv	a0,s3
ffffffffc0200c20:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200c22:	01843023          	sd	s8,0(s0)
ffffffffc0200c26:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200c2a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200c2e:	1f5000ef          	jal	ffffffffc0201622 <free_pages>
    free_page(p1);
ffffffffc0200c32:	4585                	li	a1,1
ffffffffc0200c34:	8556                	mv	a0,s5
ffffffffc0200c36:	1ed000ef          	jal	ffffffffc0201622 <free_pages>
    free_page(p2);
ffffffffc0200c3a:	4585                	li	a1,1
ffffffffc0200c3c:	8552                	mv	a0,s4
ffffffffc0200c3e:	1e5000ef          	jal	ffffffffc0201622 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200c42:	4515                	li	a0,5
ffffffffc0200c44:	14f000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200c48:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200c4a:	26050563          	beqz	a0,ffffffffc0200eb4 <default_check+0x428>
ffffffffc0200c4e:	651c                	ld	a5,8(a0)
ffffffffc0200c50:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200c52:	8b85                	and	a5,a5,1
ffffffffc0200c54:	54079063          	bnez	a5,ffffffffc0201194 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200c58:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c5a:	00043b03          	ld	s6,0(s0)
ffffffffc0200c5e:	00843a83          	ld	s5,8(s0)
ffffffffc0200c62:	e000                	sd	s0,0(s0)
ffffffffc0200c64:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200c66:	12d000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200c6a:	50051563          	bnez	a0,ffffffffc0201174 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200c6e:	09098a13          	add	s4,s3,144
ffffffffc0200c72:	8552                	mv	a0,s4
ffffffffc0200c74:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200c76:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200c7a:	00010797          	auipc	a5,0x10
ffffffffc0200c7e:	3c07ab23          	sw	zero,982(a5) # ffffffffc0211050 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200c82:	1a1000ef          	jal	ffffffffc0201622 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c86:	4511                	li	a0,4
ffffffffc0200c88:	10b000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200c8c:	4c051463          	bnez	a0,ffffffffc0201154 <default_check+0x6c8>
ffffffffc0200c90:	0989b783          	ld	a5,152(s3)
ffffffffc0200c94:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200c96:	8b85                	and	a5,a5,1
ffffffffc0200c98:	48078e63          	beqz	a5,ffffffffc0201134 <default_check+0x6a8>
ffffffffc0200c9c:	0a89a703          	lw	a4,168(s3)
ffffffffc0200ca0:	478d                	li	a5,3
ffffffffc0200ca2:	48f71963          	bne	a4,a5,ffffffffc0201134 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ca6:	450d                	li	a0,3
ffffffffc0200ca8:	0eb000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200cac:	8c2a                	mv	s8,a0
ffffffffc0200cae:	46050363          	beqz	a0,ffffffffc0201114 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200cb2:	4505                	li	a0,1
ffffffffc0200cb4:	0df000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200cb8:	42051e63          	bnez	a0,ffffffffc02010f4 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200cbc:	418a1c63          	bne	s4,s8,ffffffffc02010d4 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200cc0:	4585                	li	a1,1
ffffffffc0200cc2:	854e                	mv	a0,s3
ffffffffc0200cc4:	15f000ef          	jal	ffffffffc0201622 <free_pages>
    free_pages(p1, 3);
ffffffffc0200cc8:	458d                	li	a1,3
ffffffffc0200cca:	8552                	mv	a0,s4
ffffffffc0200ccc:	157000ef          	jal	ffffffffc0201622 <free_pages>
ffffffffc0200cd0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200cd4:	04898c13          	add	s8,s3,72
ffffffffc0200cd8:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200cda:	8b85                	and	a5,a5,1
ffffffffc0200cdc:	3c078c63          	beqz	a5,ffffffffc02010b4 <default_check+0x628>
ffffffffc0200ce0:	0189a703          	lw	a4,24(s3)
ffffffffc0200ce4:	4785                	li	a5,1
ffffffffc0200ce6:	3cf71763          	bne	a4,a5,ffffffffc02010b4 <default_check+0x628>
ffffffffc0200cea:	008a3783          	ld	a5,8(s4)
ffffffffc0200cee:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200cf0:	8b85                	and	a5,a5,1
ffffffffc0200cf2:	3a078163          	beqz	a5,ffffffffc0201094 <default_check+0x608>
ffffffffc0200cf6:	018a2703          	lw	a4,24(s4)
ffffffffc0200cfa:	478d                	li	a5,3
ffffffffc0200cfc:	38f71c63          	bne	a4,a5,ffffffffc0201094 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200d00:	4505                	li	a0,1
ffffffffc0200d02:	091000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200d06:	36a99763          	bne	s3,a0,ffffffffc0201074 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200d0a:	4585                	li	a1,1
ffffffffc0200d0c:	117000ef          	jal	ffffffffc0201622 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200d10:	4509                	li	a0,2
ffffffffc0200d12:	081000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200d16:	32aa1f63          	bne	s4,a0,ffffffffc0201054 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200d1a:	4589                	li	a1,2
ffffffffc0200d1c:	107000ef          	jal	ffffffffc0201622 <free_pages>
    free_page(p2);
ffffffffc0200d20:	4585                	li	a1,1
ffffffffc0200d22:	8562                	mv	a0,s8
ffffffffc0200d24:	0ff000ef          	jal	ffffffffc0201622 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200d28:	4515                	li	a0,5
ffffffffc0200d2a:	069000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200d2e:	89aa                	mv	s3,a0
ffffffffc0200d30:	48050263          	beqz	a0,ffffffffc02011b4 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200d34:	4505                	li	a0,1
ffffffffc0200d36:	05d000ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0200d3a:	2c051d63          	bnez	a0,ffffffffc0201014 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200d3e:	481c                	lw	a5,16(s0)
ffffffffc0200d40:	2a079a63          	bnez	a5,ffffffffc0200ff4 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200d44:	4595                	li	a1,5
ffffffffc0200d46:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200d48:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200d4c:	01643023          	sd	s6,0(s0)
ffffffffc0200d50:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200d54:	0cf000ef          	jal	ffffffffc0201622 <free_pages>
    return listelm->next;
ffffffffc0200d58:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d5a:	00878963          	beq	a5,s0,ffffffffc0200d6c <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200d5e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d62:	679c                	ld	a5,8(a5)
ffffffffc0200d64:	397d                	addw	s2,s2,-1
ffffffffc0200d66:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d68:	fe879be3          	bne	a5,s0,ffffffffc0200d5e <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200d6c:	26091463          	bnez	s2,ffffffffc0200fd4 <default_check+0x548>
    assert(total == 0);
ffffffffc0200d70:	46049263          	bnez	s1,ffffffffc02011d4 <default_check+0x748>
}
ffffffffc0200d74:	60a6                	ld	ra,72(sp)
ffffffffc0200d76:	6406                	ld	s0,64(sp)
ffffffffc0200d78:	74e2                	ld	s1,56(sp)
ffffffffc0200d7a:	7942                	ld	s2,48(sp)
ffffffffc0200d7c:	79a2                	ld	s3,40(sp)
ffffffffc0200d7e:	7a02                	ld	s4,32(sp)
ffffffffc0200d80:	6ae2                	ld	s5,24(sp)
ffffffffc0200d82:	6b42                	ld	s6,16(sp)
ffffffffc0200d84:	6ba2                	ld	s7,8(sp)
ffffffffc0200d86:	6c02                	ld	s8,0(sp)
ffffffffc0200d88:	6161                	add	sp,sp,80
ffffffffc0200d8a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d8c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200d8e:	4481                	li	s1,0
ffffffffc0200d90:	4901                	li	s2,0
ffffffffc0200d92:	bb35                	j	ffffffffc0200ace <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200d94:	00004697          	auipc	a3,0x4
ffffffffc0200d98:	eac68693          	add	a3,a3,-340 # ffffffffc0204c40 <etext+0x8cc>
ffffffffc0200d9c:	00004617          	auipc	a2,0x4
ffffffffc0200da0:	eb460613          	add	a2,a2,-332 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200da4:	0f000593          	li	a1,240
ffffffffc0200da8:	00004517          	auipc	a0,0x4
ffffffffc0200dac:	ec050513          	add	a0,a0,-320 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200db0:	db0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200db4:	00004697          	auipc	a3,0x4
ffffffffc0200db8:	f4c68693          	add	a3,a3,-180 # ffffffffc0204d00 <etext+0x98c>
ffffffffc0200dbc:	00004617          	auipc	a2,0x4
ffffffffc0200dc0:	e9460613          	add	a2,a2,-364 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200dc4:	0bd00593          	li	a1,189
ffffffffc0200dc8:	00004517          	auipc	a0,0x4
ffffffffc0200dcc:	ea050513          	add	a0,a0,-352 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200dd0:	d90ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200dd4:	00004697          	auipc	a3,0x4
ffffffffc0200dd8:	f5468693          	add	a3,a3,-172 # ffffffffc0204d28 <etext+0x9b4>
ffffffffc0200ddc:	00004617          	auipc	a2,0x4
ffffffffc0200de0:	e7460613          	add	a2,a2,-396 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200de4:	0be00593          	li	a1,190
ffffffffc0200de8:	00004517          	auipc	a0,0x4
ffffffffc0200dec:	e8050513          	add	a0,a0,-384 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200df0:	d70ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200df4:	00004697          	auipc	a3,0x4
ffffffffc0200df8:	f7468693          	add	a3,a3,-140 # ffffffffc0204d68 <etext+0x9f4>
ffffffffc0200dfc:	00004617          	auipc	a2,0x4
ffffffffc0200e00:	e5460613          	add	a2,a2,-428 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200e04:	0c000593          	li	a1,192
ffffffffc0200e08:	00004517          	auipc	a0,0x4
ffffffffc0200e0c:	e6050513          	add	a0,a0,-416 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200e10:	d50ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200e14:	00004697          	auipc	a3,0x4
ffffffffc0200e18:	fdc68693          	add	a3,a3,-36 # ffffffffc0204df0 <etext+0xa7c>
ffffffffc0200e1c:	00004617          	auipc	a2,0x4
ffffffffc0200e20:	e3460613          	add	a2,a2,-460 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200e24:	0d900593          	li	a1,217
ffffffffc0200e28:	00004517          	auipc	a0,0x4
ffffffffc0200e2c:	e4050513          	add	a0,a0,-448 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200e30:	d30ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e34:	00004697          	auipc	a3,0x4
ffffffffc0200e38:	e6c68693          	add	a3,a3,-404 # ffffffffc0204ca0 <etext+0x92c>
ffffffffc0200e3c:	00004617          	auipc	a2,0x4
ffffffffc0200e40:	e1460613          	add	a2,a2,-492 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200e44:	0d200593          	li	a1,210
ffffffffc0200e48:	00004517          	auipc	a0,0x4
ffffffffc0200e4c:	e2050513          	add	a0,a0,-480 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200e50:	d10ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 3);
ffffffffc0200e54:	00004697          	auipc	a3,0x4
ffffffffc0200e58:	f8c68693          	add	a3,a3,-116 # ffffffffc0204de0 <etext+0xa6c>
ffffffffc0200e5c:	00004617          	auipc	a2,0x4
ffffffffc0200e60:	df460613          	add	a2,a2,-524 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200e64:	0d000593          	li	a1,208
ffffffffc0200e68:	00004517          	auipc	a0,0x4
ffffffffc0200e6c:	e0050513          	add	a0,a0,-512 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200e70:	cf0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e74:	00004697          	auipc	a3,0x4
ffffffffc0200e78:	f5468693          	add	a3,a3,-172 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc0200e7c:	00004617          	auipc	a2,0x4
ffffffffc0200e80:	dd460613          	add	a2,a2,-556 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200e84:	0cb00593          	li	a1,203
ffffffffc0200e88:	00004517          	auipc	a0,0x4
ffffffffc0200e8c:	de050513          	add	a0,a0,-544 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200e90:	cd0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e94:	00004697          	auipc	a3,0x4
ffffffffc0200e98:	f1468693          	add	a3,a3,-236 # ffffffffc0204da8 <etext+0xa34>
ffffffffc0200e9c:	00004617          	auipc	a2,0x4
ffffffffc0200ea0:	db460613          	add	a2,a2,-588 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200ea4:	0c200593          	li	a1,194
ffffffffc0200ea8:	00004517          	auipc	a0,0x4
ffffffffc0200eac:	dc050513          	add	a0,a0,-576 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200eb0:	cb0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != NULL);
ffffffffc0200eb4:	00004697          	auipc	a3,0x4
ffffffffc0200eb8:	f8468693          	add	a3,a3,-124 # ffffffffc0204e38 <etext+0xac4>
ffffffffc0200ebc:	00004617          	auipc	a2,0x4
ffffffffc0200ec0:	d9460613          	add	a2,a2,-620 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200ec4:	0f800593          	li	a1,248
ffffffffc0200ec8:	00004517          	auipc	a0,0x4
ffffffffc0200ecc:	da050513          	add	a0,a0,-608 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200ed0:	c90ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0200ed4:	00004697          	auipc	a3,0x4
ffffffffc0200ed8:	f5468693          	add	a3,a3,-172 # ffffffffc0204e28 <etext+0xab4>
ffffffffc0200edc:	00004617          	auipc	a2,0x4
ffffffffc0200ee0:	d7460613          	add	a2,a2,-652 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200ee4:	0df00593          	li	a1,223
ffffffffc0200ee8:	00004517          	auipc	a0,0x4
ffffffffc0200eec:	d8050513          	add	a0,a0,-640 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200ef0:	c70ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ef4:	00004697          	auipc	a3,0x4
ffffffffc0200ef8:	ed468693          	add	a3,a3,-300 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc0200efc:	00004617          	auipc	a2,0x4
ffffffffc0200f00:	d5460613          	add	a2,a2,-684 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200f04:	0dd00593          	li	a1,221
ffffffffc0200f08:	00004517          	auipc	a0,0x4
ffffffffc0200f0c:	d6050513          	add	a0,a0,-672 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200f10:	c50ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f14:	00004697          	auipc	a3,0x4
ffffffffc0200f18:	ef468693          	add	a3,a3,-268 # ffffffffc0204e08 <etext+0xa94>
ffffffffc0200f1c:	00004617          	auipc	a2,0x4
ffffffffc0200f20:	d3460613          	add	a2,a2,-716 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200f24:	0dc00593          	li	a1,220
ffffffffc0200f28:	00004517          	auipc	a0,0x4
ffffffffc0200f2c:	d4050513          	add	a0,a0,-704 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200f30:	c30ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f34:	00004697          	auipc	a3,0x4
ffffffffc0200f38:	d6c68693          	add	a3,a3,-660 # ffffffffc0204ca0 <etext+0x92c>
ffffffffc0200f3c:	00004617          	auipc	a2,0x4
ffffffffc0200f40:	d1460613          	add	a2,a2,-748 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200f44:	0b900593          	li	a1,185
ffffffffc0200f48:	00004517          	auipc	a0,0x4
ffffffffc0200f4c:	d2050513          	add	a0,a0,-736 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200f50:	c10ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f54:	00004697          	auipc	a3,0x4
ffffffffc0200f58:	e7468693          	add	a3,a3,-396 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc0200f5c:	00004617          	auipc	a2,0x4
ffffffffc0200f60:	cf460613          	add	a2,a2,-780 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200f64:	0d600593          	li	a1,214
ffffffffc0200f68:	00004517          	auipc	a0,0x4
ffffffffc0200f6c:	d0050513          	add	a0,a0,-768 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200f70:	bf0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f74:	00004697          	auipc	a3,0x4
ffffffffc0200f78:	d6c68693          	add	a3,a3,-660 # ffffffffc0204ce0 <etext+0x96c>
ffffffffc0200f7c:	00004617          	auipc	a2,0x4
ffffffffc0200f80:	cd460613          	add	a2,a2,-812 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200f84:	0d400593          	li	a1,212
ffffffffc0200f88:	00004517          	auipc	a0,0x4
ffffffffc0200f8c:	ce050513          	add	a0,a0,-800 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200f90:	bd0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f94:	00004697          	auipc	a3,0x4
ffffffffc0200f98:	d2c68693          	add	a3,a3,-724 # ffffffffc0204cc0 <etext+0x94c>
ffffffffc0200f9c:	00004617          	auipc	a2,0x4
ffffffffc0200fa0:	cb460613          	add	a2,a2,-844 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200fa4:	0d300593          	li	a1,211
ffffffffc0200fa8:	00004517          	auipc	a0,0x4
ffffffffc0200fac:	cc050513          	add	a0,a0,-832 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200fb0:	bb0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fb4:	00004697          	auipc	a3,0x4
ffffffffc0200fb8:	d2c68693          	add	a3,a3,-724 # ffffffffc0204ce0 <etext+0x96c>
ffffffffc0200fbc:	00004617          	auipc	a2,0x4
ffffffffc0200fc0:	c9460613          	add	a2,a2,-876 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200fc4:	0bb00593          	li	a1,187
ffffffffc0200fc8:	00004517          	auipc	a0,0x4
ffffffffc0200fcc:	ca050513          	add	a0,a0,-864 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200fd0:	b90ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(count == 0);
ffffffffc0200fd4:	00004697          	auipc	a3,0x4
ffffffffc0200fd8:	fb468693          	add	a3,a3,-76 # ffffffffc0204f88 <etext+0xc14>
ffffffffc0200fdc:	00004617          	auipc	a2,0x4
ffffffffc0200fe0:	c7460613          	add	a2,a2,-908 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0200fe4:	12500593          	li	a1,293
ffffffffc0200fe8:	00004517          	auipc	a0,0x4
ffffffffc0200fec:	c8050513          	add	a0,a0,-896 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0200ff0:	b70ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0200ff4:	00004697          	auipc	a3,0x4
ffffffffc0200ff8:	e3468693          	add	a3,a3,-460 # ffffffffc0204e28 <etext+0xab4>
ffffffffc0200ffc:	00004617          	auipc	a2,0x4
ffffffffc0201000:	c5460613          	add	a2,a2,-940 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201004:	11a00593          	li	a1,282
ffffffffc0201008:	00004517          	auipc	a0,0x4
ffffffffc020100c:	c6050513          	add	a0,a0,-928 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201010:	b50ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201014:	00004697          	auipc	a3,0x4
ffffffffc0201018:	db468693          	add	a3,a3,-588 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc020101c:	00004617          	auipc	a2,0x4
ffffffffc0201020:	c3460613          	add	a2,a2,-972 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201024:	11800593          	li	a1,280
ffffffffc0201028:	00004517          	auipc	a0,0x4
ffffffffc020102c:	c4050513          	add	a0,a0,-960 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201030:	b30ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201034:	00004697          	auipc	a3,0x4
ffffffffc0201038:	d5468693          	add	a3,a3,-684 # ffffffffc0204d88 <etext+0xa14>
ffffffffc020103c:	00004617          	auipc	a2,0x4
ffffffffc0201040:	c1460613          	add	a2,a2,-1004 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201044:	0c100593          	li	a1,193
ffffffffc0201048:	00004517          	auipc	a0,0x4
ffffffffc020104c:	c2050513          	add	a0,a0,-992 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201050:	b10ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201054:	00004697          	auipc	a3,0x4
ffffffffc0201058:	ef468693          	add	a3,a3,-268 # ffffffffc0204f48 <etext+0xbd4>
ffffffffc020105c:	00004617          	auipc	a2,0x4
ffffffffc0201060:	bf460613          	add	a2,a2,-1036 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201064:	11200593          	li	a1,274
ffffffffc0201068:	00004517          	auipc	a0,0x4
ffffffffc020106c:	c0050513          	add	a0,a0,-1024 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201070:	af0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201074:	00004697          	auipc	a3,0x4
ffffffffc0201078:	eb468693          	add	a3,a3,-332 # ffffffffc0204f28 <etext+0xbb4>
ffffffffc020107c:	00004617          	auipc	a2,0x4
ffffffffc0201080:	bd460613          	add	a2,a2,-1068 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201084:	11000593          	li	a1,272
ffffffffc0201088:	00004517          	auipc	a0,0x4
ffffffffc020108c:	be050513          	add	a0,a0,-1056 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201090:	ad0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201094:	00004697          	auipc	a3,0x4
ffffffffc0201098:	e6c68693          	add	a3,a3,-404 # ffffffffc0204f00 <etext+0xb8c>
ffffffffc020109c:	00004617          	auipc	a2,0x4
ffffffffc02010a0:	bb460613          	add	a2,a2,-1100 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02010a4:	10e00593          	li	a1,270
ffffffffc02010a8:	00004517          	auipc	a0,0x4
ffffffffc02010ac:	bc050513          	add	a0,a0,-1088 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02010b0:	ab0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010b4:	00004697          	auipc	a3,0x4
ffffffffc02010b8:	e2468693          	add	a3,a3,-476 # ffffffffc0204ed8 <etext+0xb64>
ffffffffc02010bc:	00004617          	auipc	a2,0x4
ffffffffc02010c0:	b9460613          	add	a2,a2,-1132 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02010c4:	10d00593          	li	a1,269
ffffffffc02010c8:	00004517          	auipc	a0,0x4
ffffffffc02010cc:	ba050513          	add	a0,a0,-1120 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02010d0:	a90ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02010d4:	00004697          	auipc	a3,0x4
ffffffffc02010d8:	df468693          	add	a3,a3,-524 # ffffffffc0204ec8 <etext+0xb54>
ffffffffc02010dc:	00004617          	auipc	a2,0x4
ffffffffc02010e0:	b7460613          	add	a2,a2,-1164 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02010e4:	10800593          	li	a1,264
ffffffffc02010e8:	00004517          	auipc	a0,0x4
ffffffffc02010ec:	b8050513          	add	a0,a0,-1152 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02010f0:	a70ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010f4:	00004697          	auipc	a3,0x4
ffffffffc02010f8:	cd468693          	add	a3,a3,-812 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc02010fc:	00004617          	auipc	a2,0x4
ffffffffc0201100:	b5460613          	add	a2,a2,-1196 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201104:	10700593          	li	a1,263
ffffffffc0201108:	00004517          	auipc	a0,0x4
ffffffffc020110c:	b6050513          	add	a0,a0,-1184 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201110:	a50ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201114:	00004697          	auipc	a3,0x4
ffffffffc0201118:	d9468693          	add	a3,a3,-620 # ffffffffc0204ea8 <etext+0xb34>
ffffffffc020111c:	00004617          	auipc	a2,0x4
ffffffffc0201120:	b3460613          	add	a2,a2,-1228 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201124:	10600593          	li	a1,262
ffffffffc0201128:	00004517          	auipc	a0,0x4
ffffffffc020112c:	b4050513          	add	a0,a0,-1216 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201130:	a30ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201134:	00004697          	auipc	a3,0x4
ffffffffc0201138:	d4468693          	add	a3,a3,-700 # ffffffffc0204e78 <etext+0xb04>
ffffffffc020113c:	00004617          	auipc	a2,0x4
ffffffffc0201140:	b1460613          	add	a2,a2,-1260 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201144:	10500593          	li	a1,261
ffffffffc0201148:	00004517          	auipc	a0,0x4
ffffffffc020114c:	b2050513          	add	a0,a0,-1248 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201150:	a10ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201154:	00004697          	auipc	a3,0x4
ffffffffc0201158:	d0c68693          	add	a3,a3,-756 # ffffffffc0204e60 <etext+0xaec>
ffffffffc020115c:	00004617          	auipc	a2,0x4
ffffffffc0201160:	af460613          	add	a2,a2,-1292 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201164:	10400593          	li	a1,260
ffffffffc0201168:	00004517          	auipc	a0,0x4
ffffffffc020116c:	b0050513          	add	a0,a0,-1280 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201170:	9f0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201174:	00004697          	auipc	a3,0x4
ffffffffc0201178:	c5468693          	add	a3,a3,-940 # ffffffffc0204dc8 <etext+0xa54>
ffffffffc020117c:	00004617          	auipc	a2,0x4
ffffffffc0201180:	ad460613          	add	a2,a2,-1324 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201184:	0fe00593          	li	a1,254
ffffffffc0201188:	00004517          	auipc	a0,0x4
ffffffffc020118c:	ae050513          	add	a0,a0,-1312 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201190:	9d0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201194:	00004697          	auipc	a3,0x4
ffffffffc0201198:	cb468693          	add	a3,a3,-844 # ffffffffc0204e48 <etext+0xad4>
ffffffffc020119c:	00004617          	auipc	a2,0x4
ffffffffc02011a0:	ab460613          	add	a2,a2,-1356 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02011a4:	0f900593          	li	a1,249
ffffffffc02011a8:	00004517          	auipc	a0,0x4
ffffffffc02011ac:	ac050513          	add	a0,a0,-1344 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02011b0:	9b0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02011b4:	00004697          	auipc	a3,0x4
ffffffffc02011b8:	db468693          	add	a3,a3,-588 # ffffffffc0204f68 <etext+0xbf4>
ffffffffc02011bc:	00004617          	auipc	a2,0x4
ffffffffc02011c0:	a9460613          	add	a2,a2,-1388 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02011c4:	11700593          	li	a1,279
ffffffffc02011c8:	00004517          	auipc	a0,0x4
ffffffffc02011cc:	aa050513          	add	a0,a0,-1376 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02011d0:	990ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == 0);
ffffffffc02011d4:	00004697          	auipc	a3,0x4
ffffffffc02011d8:	dc468693          	add	a3,a3,-572 # ffffffffc0204f98 <etext+0xc24>
ffffffffc02011dc:	00004617          	auipc	a2,0x4
ffffffffc02011e0:	a7460613          	add	a2,a2,-1420 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02011e4:	12600593          	li	a1,294
ffffffffc02011e8:	00004517          	auipc	a0,0x4
ffffffffc02011ec:	a8050513          	add	a0,a0,-1408 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02011f0:	970ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == nr_free_pages());
ffffffffc02011f4:	00004697          	auipc	a3,0x4
ffffffffc02011f8:	a8c68693          	add	a3,a3,-1396 # ffffffffc0204c80 <etext+0x90c>
ffffffffc02011fc:	00004617          	auipc	a2,0x4
ffffffffc0201200:	a5460613          	add	a2,a2,-1452 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201204:	0f300593          	li	a1,243
ffffffffc0201208:	00004517          	auipc	a0,0x4
ffffffffc020120c:	a6050513          	add	a0,a0,-1440 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201210:	950ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201214:	00004697          	auipc	a3,0x4
ffffffffc0201218:	aac68693          	add	a3,a3,-1364 # ffffffffc0204cc0 <etext+0x94c>
ffffffffc020121c:	00004617          	auipc	a2,0x4
ffffffffc0201220:	a3460613          	add	a2,a2,-1484 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201224:	0ba00593          	li	a1,186
ffffffffc0201228:	00004517          	auipc	a0,0x4
ffffffffc020122c:	a4050513          	add	a0,a0,-1472 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201230:	930ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201234 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201234:	1141                	add	sp,sp,-16
ffffffffc0201236:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201238:	14058a63          	beqz	a1,ffffffffc020138c <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020123c:	00359713          	sll	a4,a1,0x3
ffffffffc0201240:	972e                	add	a4,a4,a1
ffffffffc0201242:	070e                	sll	a4,a4,0x3
ffffffffc0201244:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201248:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020124a:	c30d                	beqz	a4,ffffffffc020126c <default_free_pages+0x38>
ffffffffc020124c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020124e:	8b05                	and	a4,a4,1
ffffffffc0201250:	10071e63          	bnez	a4,ffffffffc020136c <default_free_pages+0x138>
ffffffffc0201254:	6798                	ld	a4,8(a5)
ffffffffc0201256:	8b09                	and	a4,a4,2
ffffffffc0201258:	10071a63          	bnez	a4,ffffffffc020136c <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020125c:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201260:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201264:	04878793          	add	a5,a5,72
ffffffffc0201268:	fed792e3          	bne	a5,a3,ffffffffc020124c <default_free_pages+0x18>
    base->property = n;
ffffffffc020126c:	2581                	sext.w	a1,a1
ffffffffc020126e:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0201270:	00850893          	add	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201274:	4789                	li	a5,2
ffffffffc0201276:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020127a:	00010697          	auipc	a3,0x10
ffffffffc020127e:	dc668693          	add	a3,a3,-570 # ffffffffc0211040 <free_area>
ffffffffc0201282:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201284:	669c                	ld	a5,8(a3)
ffffffffc0201286:	9f2d                	addw	a4,a4,a1
ffffffffc0201288:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020128a:	0ad78563          	beq	a5,a3,ffffffffc0201334 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc020128e:	fe078713          	add	a4,a5,-32
ffffffffc0201292:	4581                	li	a1,0
ffffffffc0201294:	02050613          	add	a2,a0,32
            if (base < page) {
ffffffffc0201298:	00e56a63          	bltu	a0,a4,ffffffffc02012ac <default_free_pages+0x78>
    return listelm->next;
ffffffffc020129c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020129e:	06d70263          	beq	a4,a3,ffffffffc0201302 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc02012a2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02012a4:	fe078713          	add	a4,a5,-32
            if (base < page) {
ffffffffc02012a8:	fee57ae3          	bgeu	a0,a4,ffffffffc020129c <default_free_pages+0x68>
ffffffffc02012ac:	c199                	beqz	a1,ffffffffc02012b2 <default_free_pages+0x7e>
ffffffffc02012ae:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02012b2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02012b4:	e390                	sd	a2,0(a5)
ffffffffc02012b6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02012b8:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02012ba:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc02012bc:	02d70063          	beq	a4,a3,ffffffffc02012dc <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc02012c0:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02012c4:	fe070593          	add	a1,a4,-32
        if (p + p->property == base) {
ffffffffc02012c8:	02081613          	sll	a2,a6,0x20
ffffffffc02012cc:	9201                	srl	a2,a2,0x20
ffffffffc02012ce:	00361793          	sll	a5,a2,0x3
ffffffffc02012d2:	97b2                	add	a5,a5,a2
ffffffffc02012d4:	078e                	sll	a5,a5,0x3
ffffffffc02012d6:	97ae                	add	a5,a5,a1
ffffffffc02012d8:	02f50f63          	beq	a0,a5,ffffffffc0201316 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc02012dc:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc02012de:	00d70f63          	beq	a4,a3,ffffffffc02012fc <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc02012e2:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc02012e4:	fe070693          	add	a3,a4,-32
        if (base + base->property == p) {
ffffffffc02012e8:	02059613          	sll	a2,a1,0x20
ffffffffc02012ec:	9201                	srl	a2,a2,0x20
ffffffffc02012ee:	00361793          	sll	a5,a2,0x3
ffffffffc02012f2:	97b2                	add	a5,a5,a2
ffffffffc02012f4:	078e                	sll	a5,a5,0x3
ffffffffc02012f6:	97aa                	add	a5,a5,a0
ffffffffc02012f8:	04f68a63          	beq	a3,a5,ffffffffc020134c <default_free_pages+0x118>
}
ffffffffc02012fc:	60a2                	ld	ra,8(sp)
ffffffffc02012fe:	0141                	add	sp,sp,16
ffffffffc0201300:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201302:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201304:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201306:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201308:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020130a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020130c:	02d70d63          	beq	a4,a3,ffffffffc0201346 <default_free_pages+0x112>
ffffffffc0201310:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201312:	87ba                	mv	a5,a4
ffffffffc0201314:	bf41                	j	ffffffffc02012a4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201316:	4d1c                	lw	a5,24(a0)
ffffffffc0201318:	010787bb          	addw	a5,a5,a6
ffffffffc020131c:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201320:	57f5                	li	a5,-3
ffffffffc0201322:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201326:	7110                	ld	a2,32(a0)
ffffffffc0201328:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc020132a:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020132c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020132e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201330:	e390                	sd	a2,0(a5)
ffffffffc0201332:	b775                	j	ffffffffc02012de <default_free_pages+0xaa>
}
ffffffffc0201334:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201336:	02050713          	add	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc020133a:	e398                	sd	a4,0(a5)
ffffffffc020133c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020133e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201340:	f11c                	sd	a5,32(a0)
}
ffffffffc0201342:	0141                	add	sp,sp,16
ffffffffc0201344:	8082                	ret
ffffffffc0201346:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201348:	873e                	mv	a4,a5
ffffffffc020134a:	bf8d                	j	ffffffffc02012bc <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020134c:	ff872783          	lw	a5,-8(a4)
ffffffffc0201350:	fe870693          	add	a3,a4,-24
ffffffffc0201354:	9fad                	addw	a5,a5,a1
ffffffffc0201356:	cd1c                	sw	a5,24(a0)
ffffffffc0201358:	57f5                	li	a5,-3
ffffffffc020135a:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020135e:	6314                	ld	a3,0(a4)
ffffffffc0201360:	671c                	ld	a5,8(a4)
}
ffffffffc0201362:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201364:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201366:	e394                	sd	a3,0(a5)
ffffffffc0201368:	0141                	add	sp,sp,16
ffffffffc020136a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020136c:	00004697          	auipc	a3,0x4
ffffffffc0201370:	c4468693          	add	a3,a3,-956 # ffffffffc0204fb0 <etext+0xc3c>
ffffffffc0201374:	00004617          	auipc	a2,0x4
ffffffffc0201378:	8dc60613          	add	a2,a2,-1828 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020137c:	08300593          	li	a1,131
ffffffffc0201380:	00004517          	auipc	a0,0x4
ffffffffc0201384:	8e850513          	add	a0,a0,-1816 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201388:	fd9fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc020138c:	00004697          	auipc	a3,0x4
ffffffffc0201390:	c1c68693          	add	a3,a3,-996 # ffffffffc0204fa8 <etext+0xc34>
ffffffffc0201394:	00004617          	auipc	a2,0x4
ffffffffc0201398:	8bc60613          	add	a2,a2,-1860 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020139c:	08000593          	li	a1,128
ffffffffc02013a0:	00004517          	auipc	a0,0x4
ffffffffc02013a4:	8c850513          	add	a0,a0,-1848 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc02013a8:	fb9fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02013ac <default_alloc_pages>:
    assert(n > 0);
ffffffffc02013ac:	c959                	beqz	a0,ffffffffc0201442 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02013ae:	00010617          	auipc	a2,0x10
ffffffffc02013b2:	c9260613          	add	a2,a2,-878 # ffffffffc0211040 <free_area>
ffffffffc02013b6:	4a0c                	lw	a1,16(a2)
ffffffffc02013b8:	86aa                	mv	a3,a0
ffffffffc02013ba:	02059793          	sll	a5,a1,0x20
ffffffffc02013be:	9381                	srl	a5,a5,0x20
ffffffffc02013c0:	00a7eb63          	bltu	a5,a0,ffffffffc02013d6 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc02013c4:	87b2                	mv	a5,a2
ffffffffc02013c6:	a029                	j	ffffffffc02013d0 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc02013c8:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02013cc:	00d77763          	bgeu	a4,a3,ffffffffc02013da <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc02013d0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02013d2:	fec79be3          	bne	a5,a2,ffffffffc02013c8 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc02013d6:	4501                	li	a0,0
}
ffffffffc02013d8:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc02013da:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc02013dc:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc02013e0:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02013e4:	fe078513          	add	a0,a5,-32
    prev->next = next;
ffffffffc02013e8:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02013ec:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc02013f0:	02089713          	sll	a4,a7,0x20
ffffffffc02013f4:	9301                	srl	a4,a4,0x20
            p->property = page->property - n;
ffffffffc02013f6:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc02013fa:	02e6fc63          	bgeu	a3,a4,ffffffffc0201432 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02013fe:	00369713          	sll	a4,a3,0x3
ffffffffc0201402:	9736                	add	a4,a4,a3
ffffffffc0201404:	070e                	sll	a4,a4,0x3
ffffffffc0201406:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201408:	406888bb          	subw	a7,a7,t1
ffffffffc020140c:	01172c23          	sw	a7,24(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201410:	4689                	li	a3,2
ffffffffc0201412:	00870593          	add	a1,a4,8
ffffffffc0201416:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020141a:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020141e:	02070893          	add	a7,a4,32
        nr_free -= n;
ffffffffc0201422:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201424:	0116b023          	sd	a7,0(a3)
ffffffffc0201428:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020142c:	f714                	sd	a3,40(a4)
    elm->prev = prev;
ffffffffc020142e:	03073023          	sd	a6,32(a4)
ffffffffc0201432:	406585bb          	subw	a1,a1,t1
ffffffffc0201436:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201438:	5775                	li	a4,-3
ffffffffc020143a:	17a1                	add	a5,a5,-24
ffffffffc020143c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201440:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201442:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc0201444:	00004697          	auipc	a3,0x4
ffffffffc0201448:	b6468693          	add	a3,a3,-1180 # ffffffffc0204fa8 <etext+0xc34>
ffffffffc020144c:	00004617          	auipc	a2,0x4
ffffffffc0201450:	80460613          	add	a2,a2,-2044 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0201454:	06200593          	li	a1,98
ffffffffc0201458:	00004517          	auipc	a0,0x4
ffffffffc020145c:	81050513          	add	a0,a0,-2032 # ffffffffc0204c68 <etext+0x8f4>
default_alloc_pages(size_t n) {
ffffffffc0201460:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201462:	efffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201466 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201466:	1141                	add	sp,sp,-16
ffffffffc0201468:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020146a:	c9e1                	beqz	a1,ffffffffc020153a <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020146c:	00359713          	sll	a4,a1,0x3
ffffffffc0201470:	972e                	add	a4,a4,a1
ffffffffc0201472:	070e                	sll	a4,a4,0x3
ffffffffc0201474:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201478:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020147a:	cf11                	beqz	a4,ffffffffc0201496 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020147c:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020147e:	8b05                	and	a4,a4,1
ffffffffc0201480:	cf49                	beqz	a4,ffffffffc020151a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201482:	0007ac23          	sw	zero,24(a5)
ffffffffc0201486:	0007b423          	sd	zero,8(a5)
ffffffffc020148a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020148e:	04878793          	add	a5,a5,72
ffffffffc0201492:	fed795e3          	bne	a5,a3,ffffffffc020147c <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201496:	2581                	sext.w	a1,a1
ffffffffc0201498:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020149a:	4789                	li	a5,2
ffffffffc020149c:	00850713          	add	a4,a0,8
ffffffffc02014a0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02014a4:	00010697          	auipc	a3,0x10
ffffffffc02014a8:	b9c68693          	add	a3,a3,-1124 # ffffffffc0211040 <free_area>
ffffffffc02014ac:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014ae:	669c                	ld	a5,8(a3)
ffffffffc02014b0:	9f2d                	addw	a4,a4,a1
ffffffffc02014b2:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014b4:	04d78663          	beq	a5,a3,ffffffffc0201500 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014b8:	fe078713          	add	a4,a5,-32
ffffffffc02014bc:	4581                	li	a1,0
ffffffffc02014be:	02050613          	add	a2,a0,32
            if (base < page) {
ffffffffc02014c2:	00e56a63          	bltu	a0,a4,ffffffffc02014d6 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02014c6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014c8:	02d70263          	beq	a4,a3,ffffffffc02014ec <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02014cc:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014ce:	fe078713          	add	a4,a5,-32
            if (base < page) {
ffffffffc02014d2:	fee57ae3          	bgeu	a0,a4,ffffffffc02014c6 <default_init_memmap+0x60>
ffffffffc02014d6:	c199                	beqz	a1,ffffffffc02014dc <default_init_memmap+0x76>
ffffffffc02014d8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014dc:	6398                	ld	a4,0(a5)
}
ffffffffc02014de:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02014e0:	e390                	sd	a2,0(a5)
ffffffffc02014e2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014e4:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02014e6:	f118                	sd	a4,32(a0)
ffffffffc02014e8:	0141                	add	sp,sp,16
ffffffffc02014ea:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02014ec:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014ee:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc02014f0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014f2:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc02014f4:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014f6:	00d70e63          	beq	a4,a3,ffffffffc0201512 <default_init_memmap+0xac>
ffffffffc02014fa:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02014fc:	87ba                	mv	a5,a4
ffffffffc02014fe:	bfc1                	j	ffffffffc02014ce <default_init_memmap+0x68>
}
ffffffffc0201500:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201502:	02050713          	add	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0201506:	e398                	sd	a4,0(a5)
ffffffffc0201508:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020150a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020150c:	f11c                	sd	a5,32(a0)
}
ffffffffc020150e:	0141                	add	sp,sp,16
ffffffffc0201510:	8082                	ret
ffffffffc0201512:	60a2                	ld	ra,8(sp)
ffffffffc0201514:	e290                	sd	a2,0(a3)
ffffffffc0201516:	0141                	add	sp,sp,16
ffffffffc0201518:	8082                	ret
        assert(PageReserved(p));
ffffffffc020151a:	00004697          	auipc	a3,0x4
ffffffffc020151e:	abe68693          	add	a3,a3,-1346 # ffffffffc0204fd8 <etext+0xc64>
ffffffffc0201522:	00003617          	auipc	a2,0x3
ffffffffc0201526:	72e60613          	add	a2,a2,1838 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020152a:	04900593          	li	a1,73
ffffffffc020152e:	00003517          	auipc	a0,0x3
ffffffffc0201532:	73a50513          	add	a0,a0,1850 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201536:	e2bfe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc020153a:	00004697          	auipc	a3,0x4
ffffffffc020153e:	a6e68693          	add	a3,a3,-1426 # ffffffffc0204fa8 <etext+0xc34>
ffffffffc0201542:	00003617          	auipc	a2,0x3
ffffffffc0201546:	70e60613          	add	a2,a2,1806 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020154a:	04600593          	li	a1,70
ffffffffc020154e:	00003517          	auipc	a0,0x3
ffffffffc0201552:	71a50513          	add	a0,a0,1818 # ffffffffc0204c68 <etext+0x8f4>
ffffffffc0201556:	e0bfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020155a <pa2page.part.0>:
    va_pa_offset = KERNBASE - 0x80200000;
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END; //硬编码取代 sbi_query_memory()接口
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
    cprintf("physcial memory map:\n");
ffffffffc020155a:	1141                	add	sp,sp,-16
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);
ffffffffc020155c:	00004617          	auipc	a2,0x4
ffffffffc0201560:	aa460613          	add	a2,a2,-1372 # ffffffffc0205000 <etext+0xc8c>
ffffffffc0201564:	06500593          	li	a1,101
ffffffffc0201568:	00004517          	auipc	a0,0x4
ffffffffc020156c:	ab850513          	add	a0,a0,-1352 # ffffffffc0205020 <etext+0xcac>
    cprintf("physcial memory map:\n");
ffffffffc0201570:	e406                	sd	ra,8(sp)
            mem_end - 1);
ffffffffc0201572:	deffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201576 <pte2page.part.0>:
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
ffffffffc0201576:	1141                	add	sp,sp,-16
    // BBL has put the initial page table at the first available page after the
    // kernel
ffffffffc0201578:	00004617          	auipc	a2,0x4
ffffffffc020157c:	ab860613          	add	a2,a2,-1352 # ffffffffc0205030 <etext+0xcbc>
ffffffffc0201580:	07000593          	li	a1,112
ffffffffc0201584:	00004517          	auipc	a0,0x4
ffffffffc0201588:	a9c50513          	add	a0,a0,-1380 # ffffffffc0205020 <etext+0xcac>
    npage = maxpa / PGSIZE;
ffffffffc020158c:	e406                	sd	ra,8(sp)
    // kernel
ffffffffc020158e:	dd3fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201592 <alloc_pages>:
struct Page *alloc_pages(size_t n) {
ffffffffc0201592:	7139                	add	sp,sp,-64
ffffffffc0201594:	f426                	sd	s1,40(sp)
ffffffffc0201596:	f04a                	sd	s2,32(sp)
ffffffffc0201598:	ec4e                	sd	s3,24(sp)
ffffffffc020159a:	e852                	sd	s4,16(sp)
ffffffffc020159c:	e456                	sd	s5,8(sp)
ffffffffc020159e:	e05a                	sd	s6,0(sp)
ffffffffc02015a0:	fc06                	sd	ra,56(sp)
ffffffffc02015a2:	f822                	sd	s0,48(sp)
ffffffffc02015a4:	84aa                	mv	s1,a0
ffffffffc02015a6:	00010917          	auipc	s2,0x10
ffffffffc02015aa:	f6a90913          	add	s2,s2,-150 # ffffffffc0211510 <pmm_manager>
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02015ae:	4a05                	li	s4,1
ffffffffc02015b0:	00010a97          	auipc	s5,0x10
ffffffffc02015b4:	f90a8a93          	add	s5,s5,-112 # ffffffffc0211540 <swap_init_ok>
        swap_out(check_mm_struct, n, 0);
ffffffffc02015b8:	0005099b          	sext.w	s3,a0
ffffffffc02015bc:	00010b17          	auipc	s6,0x10
ffffffffc02015c0:	facb0b13          	add	s6,s6,-84 # ffffffffc0211568 <check_mm_struct>
ffffffffc02015c4:	a015                	j	ffffffffc02015e8 <alloc_pages+0x56>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc02015c6:	00093783          	ld	a5,0(s2)
ffffffffc02015ca:	6f9c                	ld	a5,24(a5)
ffffffffc02015cc:	9782                	jalr	a5
ffffffffc02015ce:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc02015d0:	4601                	li	a2,0
ffffffffc02015d2:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02015d4:	ec05                	bnez	s0,ffffffffc020160c <alloc_pages+0x7a>
ffffffffc02015d6:	029a6b63          	bltu	s4,s1,ffffffffc020160c <alloc_pages+0x7a>
ffffffffc02015da:	000aa783          	lw	a5,0(s5)
ffffffffc02015de:	c79d                	beqz	a5,ffffffffc020160c <alloc_pages+0x7a>
        swap_out(check_mm_struct, n, 0);
ffffffffc02015e0:	000b3503          	ld	a0,0(s6)
ffffffffc02015e4:	233010ef          	jal	ffffffffc0203016 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02015e8:	100027f3          	csrr	a5,sstatus
ffffffffc02015ec:	8b89                	and	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc02015ee:	8526                	mv	a0,s1
ffffffffc02015f0:	dbf9                	beqz	a5,ffffffffc02015c6 <alloc_pages+0x34>
        intr_disable();
ffffffffc02015f2:	ec7fe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc02015f6:	00093783          	ld	a5,0(s2)
ffffffffc02015fa:	8526                	mv	a0,s1
ffffffffc02015fc:	6f9c                	ld	a5,24(a5)
ffffffffc02015fe:	9782                	jalr	a5
ffffffffc0201600:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201602:	eb1fe0ef          	jal	ffffffffc02004b2 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201606:	4601                	li	a2,0
ffffffffc0201608:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020160a:	d471                	beqz	s0,ffffffffc02015d6 <alloc_pages+0x44>
}
ffffffffc020160c:	70e2                	ld	ra,56(sp)
ffffffffc020160e:	8522                	mv	a0,s0
ffffffffc0201610:	7442                	ld	s0,48(sp)
ffffffffc0201612:	74a2                	ld	s1,40(sp)
ffffffffc0201614:	7902                	ld	s2,32(sp)
ffffffffc0201616:	69e2                	ld	s3,24(sp)
ffffffffc0201618:	6a42                	ld	s4,16(sp)
ffffffffc020161a:	6aa2                	ld	s5,8(sp)
ffffffffc020161c:	6b02                	ld	s6,0(sp)
ffffffffc020161e:	6121                	add	sp,sp,64
ffffffffc0201620:	8082                	ret

ffffffffc0201622 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201622:	100027f3          	csrr	a5,sstatus
ffffffffc0201626:	8b89                	and	a5,a5,2
ffffffffc0201628:	e799                	bnez	a5,ffffffffc0201636 <free_pages+0x14>
    { pmm_manager->free_pages(base, n); }
ffffffffc020162a:	00010797          	auipc	a5,0x10
ffffffffc020162e:	ee67b783          	ld	a5,-282(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201632:	739c                	ld	a5,32(a5)
ffffffffc0201634:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201636:	1101                	add	sp,sp,-32
ffffffffc0201638:	ec06                	sd	ra,24(sp)
ffffffffc020163a:	e822                	sd	s0,16(sp)
ffffffffc020163c:	e426                	sd	s1,8(sp)
ffffffffc020163e:	842a                	mv	s0,a0
ffffffffc0201640:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201642:	e77fe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201646:	00010797          	auipc	a5,0x10
ffffffffc020164a:	eca7b783          	ld	a5,-310(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc020164e:	739c                	ld	a5,32(a5)
ffffffffc0201650:	85a6                	mv	a1,s1
ffffffffc0201652:	8522                	mv	a0,s0
ffffffffc0201654:	9782                	jalr	a5
}
ffffffffc0201656:	6442                	ld	s0,16(sp)
ffffffffc0201658:	60e2                	ld	ra,24(sp)
ffffffffc020165a:	64a2                	ld	s1,8(sp)
ffffffffc020165c:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc020165e:	e55fe06f          	j	ffffffffc02004b2 <intr_enable>

ffffffffc0201662 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201662:	100027f3          	csrr	a5,sstatus
ffffffffc0201666:	8b89                	and	a5,a5,2
ffffffffc0201668:	e799                	bnez	a5,ffffffffc0201676 <nr_free_pages+0x14>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020166a:	00010797          	auipc	a5,0x10
ffffffffc020166e:	ea67b783          	ld	a5,-346(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201672:	779c                	ld	a5,40(a5)
ffffffffc0201674:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201676:	1141                	add	sp,sp,-16
ffffffffc0201678:	e406                	sd	ra,8(sp)
ffffffffc020167a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020167c:	e3dfe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201680:	00010797          	auipc	a5,0x10
ffffffffc0201684:	e907b783          	ld	a5,-368(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201688:	779c                	ld	a5,40(a5)
ffffffffc020168a:	9782                	jalr	a5
ffffffffc020168c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020168e:	e25fe0ef          	jal	ffffffffc02004b2 <intr_enable>
}
ffffffffc0201692:	60a2                	ld	ra,8(sp)
ffffffffc0201694:	8522                	mv	a0,s0
ffffffffc0201696:	6402                	ld	s0,0(sp)
ffffffffc0201698:	0141                	add	sp,sp,16
ffffffffc020169a:	8082                	ret

ffffffffc020169c <get_pte>:
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc020169c:	01e5d793          	srl	a5,a1,0x1e
ffffffffc02016a0:	1ff7f793          	and	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016a4:	715d                	add	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02016a6:	078e                	sll	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016a8:	f052                	sd	s4,32(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02016aa:	00f50a33          	add	s4,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016ae:	000a3683          	ld	a3,0(s4)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016b2:	f84a                	sd	s2,48(sp)
ffffffffc02016b4:	f44e                	sd	s3,40(sp)
ffffffffc02016b6:	ec56                	sd	s5,24(sp)
ffffffffc02016b8:	e486                	sd	ra,72(sp)
ffffffffc02016ba:	e0a2                	sd	s0,64(sp)
ffffffffc02016bc:	e85a                	sd	s6,16(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016be:	0016f793          	and	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016c2:	892e                	mv	s2,a1
ffffffffc02016c4:	8ab2                	mv	s5,a2
ffffffffc02016c6:	00010997          	auipc	s3,0x10
ffffffffc02016ca:	e6a98993          	add	s3,s3,-406 # ffffffffc0211530 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016ce:	efc1                	bnez	a5,ffffffffc0201766 <get_pte+0xca>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc02016d0:	18060663          	beqz	a2,ffffffffc020185c <get_pte+0x1c0>
ffffffffc02016d4:	4505                	li	a0,1
ffffffffc02016d6:	ebdff0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc02016da:	842a                	mv	s0,a0
ffffffffc02016dc:	18050063          	beqz	a0,ffffffffc020185c <get_pte+0x1c0>
ffffffffc02016e0:	fc26                	sd	s1,56(sp)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02016e2:	f8e394b7          	lui	s1,0xf8e39
ffffffffc02016e6:	e3948493          	add	s1,s1,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc02016ea:	e45e                	sd	s7,8(sp)
ffffffffc02016ec:	04b2                	sll	s1,s1,0xc
ffffffffc02016ee:	00010b97          	auipc	s7,0x10
ffffffffc02016f2:	e4ab8b93          	add	s7,s7,-438 # ffffffffc0211538 <pages>
ffffffffc02016f6:	000bb503          	ld	a0,0(s7)
ffffffffc02016fa:	e3948493          	add	s1,s1,-455
ffffffffc02016fe:	04b2                	sll	s1,s1,0xc
ffffffffc0201700:	e3948493          	add	s1,s1,-455
ffffffffc0201704:	40a40533          	sub	a0,s0,a0
ffffffffc0201708:	04b2                	sll	s1,s1,0xc
ffffffffc020170a:	850d                	sra	a0,a0,0x3
ffffffffc020170c:	e3948493          	add	s1,s1,-455
ffffffffc0201710:	02950533          	mul	a0,a0,s1
ffffffffc0201714:	00080b37          	lui	s6,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201718:	00010997          	auipc	s3,0x10
ffffffffc020171c:	e1898993          	add	s3,s3,-488 # ffffffffc0211530 <npage>
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201720:	4785                	li	a5,1
ffffffffc0201722:	0009b703          	ld	a4,0(s3)
ffffffffc0201726:	c01c                	sw	a5,0(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201728:	955a                	add	a0,a0,s6
ffffffffc020172a:	00c51793          	sll	a5,a0,0xc
ffffffffc020172e:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201730:	0532                	sll	a0,a0,0xc
ffffffffc0201732:	16e7ff63          	bgeu	a5,a4,ffffffffc02018b0 <get_pte+0x214>
ffffffffc0201736:	00010797          	auipc	a5,0x10
ffffffffc020173a:	df27b783          	ld	a5,-526(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc020173e:	953e                	add	a0,a0,a5
ffffffffc0201740:	6605                	lui	a2,0x1
ffffffffc0201742:	4581                	li	a1,0
ffffffffc0201744:	407020ef          	jal	ffffffffc020434a <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201748:	000bb783          	ld	a5,0(s7)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020174c:	6ba2                	ld	s7,8(sp)
ffffffffc020174e:	40f406b3          	sub	a3,s0,a5
ffffffffc0201752:	868d                	sra	a3,a3,0x3
ffffffffc0201754:	029686b3          	mul	a3,a3,s1
ffffffffc0201758:	74e2                	ld	s1,56(sp)
ffffffffc020175a:	96da                	add	a3,a3,s6

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020175c:	06aa                	sll	a3,a3,0xa
ffffffffc020175e:	0116e693          	or	a3,a3,17
ffffffffc0201762:	00da3023          	sd	a3,0(s4)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201766:	77fd                	lui	a5,0xfffff
ffffffffc0201768:	068a                	sll	a3,a3,0x2
ffffffffc020176a:	0009b703          	ld	a4,0(s3)
ffffffffc020176e:	8efd                	and	a3,a3,a5
ffffffffc0201770:	00c6d793          	srl	a5,a3,0xc
ffffffffc0201774:	0ee7f663          	bgeu	a5,a4,ffffffffc0201860 <get_pte+0x1c4>
ffffffffc0201778:	00010b17          	auipc	s6,0x10
ffffffffc020177c:	db0b0b13          	add	s6,s6,-592 # ffffffffc0211528 <va_pa_offset>
ffffffffc0201780:	000b3603          	ld	a2,0(s6)
ffffffffc0201784:	01595793          	srl	a5,s2,0x15
ffffffffc0201788:	1ff7f793          	and	a5,a5,511
ffffffffc020178c:	96b2                	add	a3,a3,a2
ffffffffc020178e:	078e                	sll	a5,a5,0x3
ffffffffc0201790:	00f68433          	add	s0,a3,a5
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201794:	6014                	ld	a3,0(s0)
ffffffffc0201796:	0016f793          	and	a5,a3,1
ffffffffc020179a:	e7d1                	bnez	a5,ffffffffc0201826 <get_pte+0x18a>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc020179c:	0c0a8063          	beqz	s5,ffffffffc020185c <get_pte+0x1c0>
ffffffffc02017a0:	4505                	li	a0,1
ffffffffc02017a2:	fc26                	sd	s1,56(sp)
ffffffffc02017a4:	defff0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc02017a8:	84aa                	mv	s1,a0
ffffffffc02017aa:	c945                	beqz	a0,ffffffffc020185a <get_pte+0x1be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017ac:	f8e39a37          	lui	s4,0xf8e39
ffffffffc02017b0:	e39a0a13          	add	s4,s4,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc02017b4:	e45e                	sd	s7,8(sp)
ffffffffc02017b6:	0a32                	sll	s4,s4,0xc
ffffffffc02017b8:	00010b97          	auipc	s7,0x10
ffffffffc02017bc:	d80b8b93          	add	s7,s7,-640 # ffffffffc0211538 <pages>
ffffffffc02017c0:	000bb683          	ld	a3,0(s7)
ffffffffc02017c4:	e39a0a13          	add	s4,s4,-455
ffffffffc02017c8:	0a32                	sll	s4,s4,0xc
ffffffffc02017ca:	e39a0a13          	add	s4,s4,-455
ffffffffc02017ce:	40d506b3          	sub	a3,a0,a3
ffffffffc02017d2:	0a32                	sll	s4,s4,0xc
ffffffffc02017d4:	868d                	sra	a3,a3,0x3
ffffffffc02017d6:	e39a0a13          	add	s4,s4,-455
ffffffffc02017da:	034686b3          	mul	a3,a3,s4
ffffffffc02017de:	00080ab7          	lui	s5,0x80
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017e2:	4785                	li	a5,1
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc02017e4:	0009b703          	ld	a4,0(s3)
ffffffffc02017e8:	c11c                	sw	a5,0(a0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017ea:	96d6                	add	a3,a3,s5
ffffffffc02017ec:	00c69793          	sll	a5,a3,0xc
ffffffffc02017f0:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02017f2:	06b2                	sll	a3,a3,0xc
ffffffffc02017f4:	0ae7f263          	bgeu	a5,a4,ffffffffc0201898 <get_pte+0x1fc>
ffffffffc02017f8:	000b3503          	ld	a0,0(s6)
ffffffffc02017fc:	6605                	lui	a2,0x1
ffffffffc02017fe:	4581                	li	a1,0
ffffffffc0201800:	9536                	add	a0,a0,a3
ffffffffc0201802:	349020ef          	jal	ffffffffc020434a <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201806:	000bb783          	ld	a5,0(s7)
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020180a:	6ba2                	ld	s7,8(sp)
ffffffffc020180c:	40f486b3          	sub	a3,s1,a5
ffffffffc0201810:	868d                	sra	a3,a3,0x3
ffffffffc0201812:	034686b3          	mul	a3,a3,s4
ffffffffc0201816:	74e2                	ld	s1,56(sp)
ffffffffc0201818:	96d6                	add	a3,a3,s5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020181a:	06aa                	sll	a3,a3,0xa
ffffffffc020181c:	0116e693          	or	a3,a3,17
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201820:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201822:	0009b703          	ld	a4,0(s3)
ffffffffc0201826:	77fd                	lui	a5,0xfffff
ffffffffc0201828:	068a                	sll	a3,a3,0x2
ffffffffc020182a:	8efd                	and	a3,a3,a5
ffffffffc020182c:	00c6d793          	srl	a5,a3,0xc
ffffffffc0201830:	04e7f663          	bgeu	a5,a4,ffffffffc020187c <get_pte+0x1e0>
ffffffffc0201834:	000b3783          	ld	a5,0(s6)
ffffffffc0201838:	00c95913          	srl	s2,s2,0xc
ffffffffc020183c:	1ff97913          	and	s2,s2,511
ffffffffc0201840:	96be                	add	a3,a3,a5
ffffffffc0201842:	090e                	sll	s2,s2,0x3
ffffffffc0201844:	01268533          	add	a0,a3,s2
}
ffffffffc0201848:	60a6                	ld	ra,72(sp)
ffffffffc020184a:	6406                	ld	s0,64(sp)
ffffffffc020184c:	7942                	ld	s2,48(sp)
ffffffffc020184e:	79a2                	ld	s3,40(sp)
ffffffffc0201850:	7a02                	ld	s4,32(sp)
ffffffffc0201852:	6ae2                	ld	s5,24(sp)
ffffffffc0201854:	6b42                	ld	s6,16(sp)
ffffffffc0201856:	6161                	add	sp,sp,80
ffffffffc0201858:	8082                	ret
ffffffffc020185a:	74e2                	ld	s1,56(sp)
            return NULL;
ffffffffc020185c:	4501                	li	a0,0
ffffffffc020185e:	b7ed                	j	ffffffffc0201848 <get_pte+0x1ac>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201860:	00003617          	auipc	a2,0x3
ffffffffc0201864:	7f860613          	add	a2,a2,2040 # ffffffffc0205058 <etext+0xce4>
ffffffffc0201868:	10200593          	li	a1,258
ffffffffc020186c:	00004517          	auipc	a0,0x4
ffffffffc0201870:	81450513          	add	a0,a0,-2028 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0201874:	fc26                	sd	s1,56(sp)
ffffffffc0201876:	e45e                	sd	s7,8(sp)
ffffffffc0201878:	ae9fe0ef          	jal	ffffffffc0200360 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020187c:	00003617          	auipc	a2,0x3
ffffffffc0201880:	7dc60613          	add	a2,a2,2012 # ffffffffc0205058 <etext+0xce4>
ffffffffc0201884:	10f00593          	li	a1,271
ffffffffc0201888:	00003517          	auipc	a0,0x3
ffffffffc020188c:	7f850513          	add	a0,a0,2040 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0201890:	fc26                	sd	s1,56(sp)
ffffffffc0201892:	e45e                	sd	s7,8(sp)
ffffffffc0201894:	acdfe0ef          	jal	ffffffffc0200360 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201898:	00003617          	auipc	a2,0x3
ffffffffc020189c:	7c060613          	add	a2,a2,1984 # ffffffffc0205058 <etext+0xce4>
ffffffffc02018a0:	10b00593          	li	a1,267
ffffffffc02018a4:	00003517          	auipc	a0,0x3
ffffffffc02018a8:	7dc50513          	add	a0,a0,2012 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02018ac:	ab5fe0ef          	jal	ffffffffc0200360 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02018b0:	86aa                	mv	a3,a0
ffffffffc02018b2:	00003617          	auipc	a2,0x3
ffffffffc02018b6:	7a660613          	add	a2,a2,1958 # ffffffffc0205058 <etext+0xce4>
ffffffffc02018ba:	0ff00593          	li	a1,255
ffffffffc02018be:	00003517          	auipc	a0,0x3
ffffffffc02018c2:	7c250513          	add	a0,a0,1986 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02018c6:	a9bfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02018ca <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02018ca:	1141                	add	sp,sp,-16
ffffffffc02018cc:	e022                	sd	s0,0(sp)
ffffffffc02018ce:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02018d0:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02018d2:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02018d4:	dc9ff0ef          	jal	ffffffffc020169c <get_pte>
    if (ptep_store != NULL) {
ffffffffc02018d8:	c011                	beqz	s0,ffffffffc02018dc <get_page+0x12>
        *ptep_store = ptep;
ffffffffc02018da:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02018dc:	c511                	beqz	a0,ffffffffc02018e8 <get_page+0x1e>
ffffffffc02018de:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02018e0:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02018e2:	0017f713          	and	a4,a5,1
ffffffffc02018e6:	e709                	bnez	a4,ffffffffc02018f0 <get_page+0x26>
}
ffffffffc02018e8:	60a2                	ld	ra,8(sp)
ffffffffc02018ea:	6402                	ld	s0,0(sp)
ffffffffc02018ec:	0141                	add	sp,sp,16
ffffffffc02018ee:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02018f0:	078a                	sll	a5,a5,0x2
ffffffffc02018f2:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02018f4:	00010717          	auipc	a4,0x10
ffffffffc02018f8:	c3c73703          	ld	a4,-964(a4) # ffffffffc0211530 <npage>
ffffffffc02018fc:	02e7f263          	bgeu	a5,a4,ffffffffc0201920 <get_page+0x56>
    return &pages[PPN(pa) - nbase];
ffffffffc0201900:	fff80737          	lui	a4,0xfff80
ffffffffc0201904:	97ba                	add	a5,a5,a4
ffffffffc0201906:	60a2                	ld	ra,8(sp)
ffffffffc0201908:	6402                	ld	s0,0(sp)
ffffffffc020190a:	00379713          	sll	a4,a5,0x3
ffffffffc020190e:	97ba                	add	a5,a5,a4
ffffffffc0201910:	00010517          	auipc	a0,0x10
ffffffffc0201914:	c2853503          	ld	a0,-984(a0) # ffffffffc0211538 <pages>
ffffffffc0201918:	078e                	sll	a5,a5,0x3
ffffffffc020191a:	953e                	add	a0,a0,a5
ffffffffc020191c:	0141                	add	sp,sp,16
ffffffffc020191e:	8082                	ret
ffffffffc0201920:	c3bff0ef          	jal	ffffffffc020155a <pa2page.part.0>

ffffffffc0201924 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201924:	1101                	add	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201926:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201928:	ec06                	sd	ra,24(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020192a:	d73ff0ef          	jal	ffffffffc020169c <get_pte>
    if (ptep != NULL) {
ffffffffc020192e:	c901                	beqz	a0,ffffffffc020193e <page_remove+0x1a>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201930:	611c                	ld	a5,0(a0)
ffffffffc0201932:	e822                	sd	s0,16(sp)
ffffffffc0201934:	842a                	mv	s0,a0
ffffffffc0201936:	0017f713          	and	a4,a5,1
ffffffffc020193a:	e709                	bnez	a4,ffffffffc0201944 <page_remove+0x20>
ffffffffc020193c:	6442                	ld	s0,16(sp)
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc020193e:	60e2                	ld	ra,24(sp)
ffffffffc0201940:	6105                	add	sp,sp,32
ffffffffc0201942:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201944:	078a                	sll	a5,a5,0x2
ffffffffc0201946:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201948:	00010717          	auipc	a4,0x10
ffffffffc020194c:	be873703          	ld	a4,-1048(a4) # ffffffffc0211530 <npage>
ffffffffc0201950:	06e7f563          	bgeu	a5,a4,ffffffffc02019ba <page_remove+0x96>
    return &pages[PPN(pa) - nbase];
ffffffffc0201954:	fff80737          	lui	a4,0xfff80
ffffffffc0201958:	97ba                	add	a5,a5,a4
ffffffffc020195a:	00379713          	sll	a4,a5,0x3
ffffffffc020195e:	97ba                	add	a5,a5,a4
ffffffffc0201960:	078e                	sll	a5,a5,0x3
ffffffffc0201962:	00010517          	auipc	a0,0x10
ffffffffc0201966:	bd653503          	ld	a0,-1066(a0) # ffffffffc0211538 <pages>
ffffffffc020196a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020196c:	411c                	lw	a5,0(a0)
ffffffffc020196e:	fff7871b          	addw	a4,a5,-1 # ffffffffffffefff <end+0x3fdeda8f>
ffffffffc0201972:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201974:	cb09                	beqz	a4,ffffffffc0201986 <page_remove+0x62>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201976:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc020197a:	12000073          	sfence.vma
ffffffffc020197e:	6442                	ld	s0,16(sp)
}
ffffffffc0201980:	60e2                	ld	ra,24(sp)
ffffffffc0201982:	6105                	add	sp,sp,32
ffffffffc0201984:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201986:	100027f3          	csrr	a5,sstatus
ffffffffc020198a:	8b89                	and	a5,a5,2
ffffffffc020198c:	eb89                	bnez	a5,ffffffffc020199e <page_remove+0x7a>
    { pmm_manager->free_pages(base, n); }
ffffffffc020198e:	00010797          	auipc	a5,0x10
ffffffffc0201992:	b827b783          	ld	a5,-1150(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201996:	739c                	ld	a5,32(a5)
ffffffffc0201998:	4585                	li	a1,1
ffffffffc020199a:	9782                	jalr	a5
    if (flag) {
ffffffffc020199c:	bfe9                	j	ffffffffc0201976 <page_remove+0x52>
        intr_disable();
ffffffffc020199e:	e42a                	sd	a0,8(sp)
ffffffffc02019a0:	b19fe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc02019a4:	00010797          	auipc	a5,0x10
ffffffffc02019a8:	b6c7b783          	ld	a5,-1172(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02019ac:	739c                	ld	a5,32(a5)
ffffffffc02019ae:	6522                	ld	a0,8(sp)
ffffffffc02019b0:	4585                	li	a1,1
ffffffffc02019b2:	9782                	jalr	a5
        intr_enable();
ffffffffc02019b4:	afffe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc02019b8:	bf7d                	j	ffffffffc0201976 <page_remove+0x52>
ffffffffc02019ba:	ba1ff0ef          	jal	ffffffffc020155a <pa2page.part.0>

ffffffffc02019be <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019be:	7179                	add	sp,sp,-48
ffffffffc02019c0:	87b2                	mv	a5,a2
ffffffffc02019c2:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02019c4:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019c6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02019c8:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019ca:	ec26                	sd	s1,24(sp)
ffffffffc02019cc:	f406                	sd	ra,40(sp)
ffffffffc02019ce:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02019d0:	ccdff0ef          	jal	ffffffffc020169c <get_pte>
    if (ptep == NULL) {
ffffffffc02019d4:	c975                	beqz	a0,ffffffffc0201ac8 <page_insert+0x10a>
    page->ref += 1;
ffffffffc02019d6:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc02019d8:	611c                	ld	a5,0(a0)
ffffffffc02019da:	e44e                	sd	s3,8(sp)
ffffffffc02019dc:	0016871b          	addw	a4,a3,1
ffffffffc02019e0:	c018                	sw	a4,0(s0)
ffffffffc02019e2:	0017f713          	and	a4,a5,1
ffffffffc02019e6:	89aa                	mv	s3,a0
ffffffffc02019e8:	eb21                	bnez	a4,ffffffffc0201a38 <page_insert+0x7a>
    return &pages[PPN(pa) - nbase];
ffffffffc02019ea:	00010717          	auipc	a4,0x10
ffffffffc02019ee:	b4e73703          	ld	a4,-1202(a4) # ffffffffc0211538 <pages>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02019f2:	f8e397b7          	lui	a5,0xf8e39
ffffffffc02019f6:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc02019fa:	07b2                	sll	a5,a5,0xc
ffffffffc02019fc:	e3978793          	add	a5,a5,-455
ffffffffc0201a00:	07b2                	sll	a5,a5,0xc
ffffffffc0201a02:	e3978793          	add	a5,a5,-455
ffffffffc0201a06:	8c19                	sub	s0,s0,a4
ffffffffc0201a08:	07b2                	sll	a5,a5,0xc
ffffffffc0201a0a:	840d                	sra	s0,s0,0x3
ffffffffc0201a0c:	e3978793          	add	a5,a5,-455
ffffffffc0201a10:	02f407b3          	mul	a5,s0,a5
ffffffffc0201a14:	00080737          	lui	a4,0x80
ffffffffc0201a18:	97ba                	add	a5,a5,a4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201a1a:	07aa                	sll	a5,a5,0xa
ffffffffc0201a1c:	8cdd                	or	s1,s1,a5
ffffffffc0201a1e:	0014e493          	or	s1,s1,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201a22:	0099b023          	sd	s1,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a26:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0201a2a:	69a2                	ld	s3,8(sp)
ffffffffc0201a2c:	4501                	li	a0,0
}
ffffffffc0201a2e:	70a2                	ld	ra,40(sp)
ffffffffc0201a30:	7402                	ld	s0,32(sp)
ffffffffc0201a32:	64e2                	ld	s1,24(sp)
ffffffffc0201a34:	6145                	add	sp,sp,48
ffffffffc0201a36:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201a38:	078a                	sll	a5,a5,0x2
ffffffffc0201a3a:	e84a                	sd	s2,16(sp)
ffffffffc0201a3c:	e052                	sd	s4,0(sp)
ffffffffc0201a3e:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a40:	00010717          	auipc	a4,0x10
ffffffffc0201a44:	af073703          	ld	a4,-1296(a4) # ffffffffc0211530 <npage>
ffffffffc0201a48:	08e7f263          	bgeu	a5,a4,ffffffffc0201acc <page_insert+0x10e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a4c:	fff80737          	lui	a4,0xfff80
ffffffffc0201a50:	97ba                	add	a5,a5,a4
ffffffffc0201a52:	00010a17          	auipc	s4,0x10
ffffffffc0201a56:	ae6a0a13          	add	s4,s4,-1306 # ffffffffc0211538 <pages>
ffffffffc0201a5a:	000a3703          	ld	a4,0(s4)
ffffffffc0201a5e:	00379913          	sll	s2,a5,0x3
ffffffffc0201a62:	993e                	add	s2,s2,a5
ffffffffc0201a64:	090e                	sll	s2,s2,0x3
ffffffffc0201a66:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201a68:	03240263          	beq	s0,s2,ffffffffc0201a8c <page_insert+0xce>
    page->ref -= 1;
ffffffffc0201a6c:	00092783          	lw	a5,0(s2)
ffffffffc0201a70:	fff7871b          	addw	a4,a5,-1
ffffffffc0201a74:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) ==
ffffffffc0201a78:	cf11                	beqz	a4,ffffffffc0201a94 <page_insert+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201a7a:	0009b023          	sd	zero,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a7e:	12000073          	sfence.vma
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a82:	000a3703          	ld	a4,0(s4)
ffffffffc0201a86:	6942                	ld	s2,16(sp)
ffffffffc0201a88:	6a02                	ld	s4,0(sp)
}
ffffffffc0201a8a:	b7a5                	j	ffffffffc02019f2 <page_insert+0x34>
    return page->ref;
ffffffffc0201a8c:	6942                	ld	s2,16(sp)
ffffffffc0201a8e:	6a02                	ld	s4,0(sp)
    page->ref -= 1;
ffffffffc0201a90:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201a92:	b785                	j	ffffffffc02019f2 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a94:	100027f3          	csrr	a5,sstatus
ffffffffc0201a98:	8b89                	and	a5,a5,2
ffffffffc0201a9a:	eb91                	bnez	a5,ffffffffc0201aae <page_insert+0xf0>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201a9c:	00010797          	auipc	a5,0x10
ffffffffc0201aa0:	a747b783          	ld	a5,-1420(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201aa4:	739c                	ld	a5,32(a5)
ffffffffc0201aa6:	4585                	li	a1,1
ffffffffc0201aa8:	854a                	mv	a0,s2
ffffffffc0201aaa:	9782                	jalr	a5
    if (flag) {
ffffffffc0201aac:	b7f9                	j	ffffffffc0201a7a <page_insert+0xbc>
        intr_disable();
ffffffffc0201aae:	a0bfe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc0201ab2:	00010797          	auipc	a5,0x10
ffffffffc0201ab6:	a5e7b783          	ld	a5,-1442(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201aba:	739c                	ld	a5,32(a5)
ffffffffc0201abc:	4585                	li	a1,1
ffffffffc0201abe:	854a                	mv	a0,s2
ffffffffc0201ac0:	9782                	jalr	a5
        intr_enable();
ffffffffc0201ac2:	9f1fe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0201ac6:	bf55                	j	ffffffffc0201a7a <page_insert+0xbc>
        return -E_NO_MEM;
ffffffffc0201ac8:	5571                	li	a0,-4
ffffffffc0201aca:	b795                	j	ffffffffc0201a2e <page_insert+0x70>
ffffffffc0201acc:	a8fff0ef          	jal	ffffffffc020155a <pa2page.part.0>

ffffffffc0201ad0 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201ad0:	00004797          	auipc	a5,0x4
ffffffffc0201ad4:	4a078793          	add	a5,a5,1184 # ffffffffc0205f70 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201ad8:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201ada:	7159                	add	sp,sp,-112
ffffffffc0201adc:	f486                	sd	ra,104(sp)
ffffffffc0201ade:	eca6                	sd	s1,88(sp)
ffffffffc0201ae0:	e4ce                	sd	s3,72(sp)
ffffffffc0201ae2:	f85a                	sd	s6,48(sp)
ffffffffc0201ae4:	f45e                	sd	s7,40(sp)
ffffffffc0201ae6:	f0a2                	sd	s0,96(sp)
ffffffffc0201ae8:	e8ca                	sd	s2,80(sp)
ffffffffc0201aea:	e0d2                	sd	s4,64(sp)
ffffffffc0201aec:	fc56                	sd	s5,56(sp)
ffffffffc0201aee:	f062                	sd	s8,32(sp)
ffffffffc0201af0:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201af2:	00010b97          	auipc	s7,0x10
ffffffffc0201af6:	a1eb8b93          	add	s7,s7,-1506 # ffffffffc0211510 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201afa:	00003517          	auipc	a0,0x3
ffffffffc0201afe:	59650513          	add	a0,a0,1430 # ffffffffc0205090 <etext+0xd1c>
    pmm_manager = &default_pmm_manager;
ffffffffc0201b02:	00fbb023          	sd	a5,0(s7)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b06:	db4fe0ef          	jal	ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc0201b0a:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b0e:	00010997          	auipc	s3,0x10
ffffffffc0201b12:	a1a98993          	add	s3,s3,-1510 # ffffffffc0211528 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0201b16:	00010497          	auipc	s1,0x10
ffffffffc0201b1a:	a1a48493          	add	s1,s1,-1510 # ffffffffc0211530 <npage>
    pmm_manager->init();
ffffffffc0201b1e:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201b20:	00010b17          	auipc	s6,0x10
ffffffffc0201b24:	a18b0b13          	add	s6,s6,-1512 # ffffffffc0211538 <pages>
    pmm_manager->init();
ffffffffc0201b28:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b2a:	57f5                	li	a5,-3
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b2c:	4645                	li	a2,17
ffffffffc0201b2e:	40100593          	li	a1,1025
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b32:	07fa                	sll	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b34:	07e006b7          	lui	a3,0x7e00
ffffffffc0201b38:	066e                	sll	a2,a2,0x1b
ffffffffc0201b3a:	05d6                	sll	a1,a1,0x15
ffffffffc0201b3c:	00003517          	auipc	a0,0x3
ffffffffc0201b40:	56c50513          	add	a0,a0,1388 # ffffffffc02050a8 <etext+0xd34>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b44:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b48:	d72fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201b4c:	00003517          	auipc	a0,0x3
ffffffffc0201b50:	58c50513          	add	a0,a0,1420 # ffffffffc02050d8 <etext+0xd64>
ffffffffc0201b54:	d66fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201b58:	46c5                	li	a3,17
ffffffffc0201b5a:	06ee                	sll	a3,a3,0x1b
ffffffffc0201b5c:	40100613          	li	a2,1025
ffffffffc0201b60:	16fd                	add	a3,a3,-1 # 7dfffff <kern_entry-0xffffffffb8400001>
ffffffffc0201b62:	0656                	sll	a2,a2,0x15
ffffffffc0201b64:	07e005b7          	lui	a1,0x7e00
ffffffffc0201b68:	00003517          	auipc	a0,0x3
ffffffffc0201b6c:	58850513          	add	a0,a0,1416 # ffffffffc02050f0 <etext+0xd7c>
ffffffffc0201b70:	d4afe0ef          	jal	ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201b74:	777d                	lui	a4,0xfffff
ffffffffc0201b76:	00011797          	auipc	a5,0x11
ffffffffc0201b7a:	9f978793          	add	a5,a5,-1543 # ffffffffc021256f <end+0xfff>
ffffffffc0201b7e:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201b80:	00088737          	lui	a4,0x88
ffffffffc0201b84:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201b86:	00fb3023          	sd	a5,0(s6)
ffffffffc0201b8a:	4705                	li	a4,1
ffffffffc0201b8c:	07a1                	add	a5,a5,8
ffffffffc0201b8e:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201b92:	04800693          	li	a3,72
ffffffffc0201b96:	4505                	li	a0,1
ffffffffc0201b98:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201b9c:	000b3783          	ld	a5,0(s6)
ffffffffc0201ba0:	97b6                	add	a5,a5,a3
ffffffffc0201ba2:	07a1                	add	a5,a5,8
ffffffffc0201ba4:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201ba8:	609c                	ld	a5,0(s1)
ffffffffc0201baa:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201bac:	04868693          	add	a3,a3,72
ffffffffc0201bb0:	00b78633          	add	a2,a5,a1
ffffffffc0201bb4:	fec764e3          	bltu	a4,a2,ffffffffc0201b9c <pmm_init+0xcc>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201bb8:	000b3503          	ld	a0,0(s6)
ffffffffc0201bbc:	00379693          	sll	a3,a5,0x3
ffffffffc0201bc0:	96be                	add	a3,a3,a5
ffffffffc0201bc2:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201bc6:	972a                	add	a4,a4,a0
ffffffffc0201bc8:	068e                	sll	a3,a3,0x3
ffffffffc0201bca:	96ba                	add	a3,a3,a4
ffffffffc0201bcc:	c0200737          	lui	a4,0xc0200
ffffffffc0201bd0:	68e6e563          	bltu	a3,a4,ffffffffc020225a <pmm_init+0x78a>
ffffffffc0201bd4:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc0201bd8:	4645                	li	a2,17
ffffffffc0201bda:	066e                	sll	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201bdc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201bde:	50c6e363          	bltu	a3,a2,ffffffffc02020e4 <pmm_init+0x614>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201be2:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201be6:	00010917          	auipc	s2,0x10
ffffffffc0201bea:	93a90913          	add	s2,s2,-1734 # ffffffffc0211520 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201bee:	7b9c                	ld	a5,48(a5)
ffffffffc0201bf0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201bf2:	00003517          	auipc	a0,0x3
ffffffffc0201bf6:	54e50513          	add	a0,a0,1358 # ffffffffc0205140 <etext+0xdcc>
ffffffffc0201bfa:	cc0fe0ef          	jal	ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201bfe:	00007697          	auipc	a3,0x7
ffffffffc0201c02:	40268693          	add	a3,a3,1026 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201c06:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201c0a:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c0e:	22f6eee3          	bltu	a3,a5,ffffffffc020264a <pmm_init+0xb7a>
ffffffffc0201c12:	0009b783          	ld	a5,0(s3)
ffffffffc0201c16:	8e9d                	sub	a3,a3,a5
ffffffffc0201c18:	00010797          	auipc	a5,0x10
ffffffffc0201c1c:	90d7b023          	sd	a3,-1792(a5) # ffffffffc0211518 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c20:	100027f3          	csrr	a5,sstatus
ffffffffc0201c24:	8b89                	and	a5,a5,2
ffffffffc0201c26:	4e079863          	bnez	a5,ffffffffc0202116 <pmm_init+0x646>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201c2a:	000bb783          	ld	a5,0(s7)
ffffffffc0201c2e:	779c                	ld	a5,40(a5)
ffffffffc0201c30:	9782                	jalr	a5
ffffffffc0201c32:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c34:	6098                	ld	a4,0(s1)
ffffffffc0201c36:	c80007b7          	lui	a5,0xc8000
ffffffffc0201c3a:	83b1                	srl	a5,a5,0xc
ffffffffc0201c3c:	66e7eb63          	bltu	a5,a4,ffffffffc02022b2 <pmm_init+0x7e2>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c40:	00093503          	ld	a0,0(s2)
ffffffffc0201c44:	64050763          	beqz	a0,ffffffffc0202292 <pmm_init+0x7c2>
ffffffffc0201c48:	03451793          	sll	a5,a0,0x34
ffffffffc0201c4c:	64079363          	bnez	a5,ffffffffc0202292 <pmm_init+0x7c2>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201c50:	4601                	li	a2,0
ffffffffc0201c52:	4581                	li	a1,0
ffffffffc0201c54:	c77ff0ef          	jal	ffffffffc02018ca <get_page>
ffffffffc0201c58:	6a051f63          	bnez	a0,ffffffffc0202316 <pmm_init+0x846>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201c5c:	4505                	li	a0,1
ffffffffc0201c5e:	935ff0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0201c62:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201c64:	00093503          	ld	a0,0(s2)
ffffffffc0201c68:	4681                	li	a3,0
ffffffffc0201c6a:	4601                	li	a2,0
ffffffffc0201c6c:	85d2                	mv	a1,s4
ffffffffc0201c6e:	d51ff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0201c72:	68051263          	bnez	a0,ffffffffc02022f6 <pmm_init+0x826>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201c76:	00093503          	ld	a0,0(s2)
ffffffffc0201c7a:	4601                	li	a2,0
ffffffffc0201c7c:	4581                	li	a1,0
ffffffffc0201c7e:	a1fff0ef          	jal	ffffffffc020169c <get_pte>
ffffffffc0201c82:	64050a63          	beqz	a0,ffffffffc02022d6 <pmm_init+0x806>
    assert(pte2page(*ptep) == p1);
ffffffffc0201c86:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201c88:	0017f713          	and	a4,a5,1
ffffffffc0201c8c:	64070363          	beqz	a4,ffffffffc02022d2 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201c90:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201c92:	078a                	sll	a5,a5,0x2
ffffffffc0201c94:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201c96:	5ac7f063          	bgeu	a5,a2,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c9a:	fff80737          	lui	a4,0xfff80
ffffffffc0201c9e:	97ba                	add	a5,a5,a4
ffffffffc0201ca0:	000b3683          	ld	a3,0(s6)
ffffffffc0201ca4:	00379713          	sll	a4,a5,0x3
ffffffffc0201ca8:	97ba                	add	a5,a5,a4
ffffffffc0201caa:	078e                	sll	a5,a5,0x3
ffffffffc0201cac:	97b6                	add	a5,a5,a3
ffffffffc0201cae:	58fa1663          	bne	s4,a5,ffffffffc020223a <pmm_init+0x76a>
    assert(page_ref(p1) == 1);
ffffffffc0201cb2:	000a2703          	lw	a4,0(s4)
ffffffffc0201cb6:	4785                	li	a5,1
ffffffffc0201cb8:	1cf711e3          	bne	a4,a5,ffffffffc020267a <pmm_init+0xbaa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201cbc:	00093503          	ld	a0,0(s2)
ffffffffc0201cc0:	77fd                	lui	a5,0xfffff
ffffffffc0201cc2:	6114                	ld	a3,0(a0)
ffffffffc0201cc4:	068a                	sll	a3,a3,0x2
ffffffffc0201cc6:	8efd                	and	a3,a3,a5
ffffffffc0201cc8:	00c6d713          	srl	a4,a3,0xc
ffffffffc0201ccc:	18c77be3          	bgeu	a4,a2,ffffffffc0202662 <pmm_init+0xb92>
ffffffffc0201cd0:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201cd4:	96e2                	add	a3,a3,s8
ffffffffc0201cd6:	0006ba83          	ld	s5,0(a3)
ffffffffc0201cda:	0a8a                	sll	s5,s5,0x2
ffffffffc0201cdc:	00fafab3          	and	s5,s5,a5
ffffffffc0201ce0:	00cad793          	srl	a5,s5,0xc
ffffffffc0201ce4:	6ac7f963          	bgeu	a5,a2,ffffffffc0202396 <pmm_init+0x8c6>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201ce8:	4601                	li	a2,0
ffffffffc0201cea:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201cec:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201cee:	9afff0ef          	jal	ffffffffc020169c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201cf2:	0c21                	add	s8,s8,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201cf4:	69851163          	bne	a0,s8,ffffffffc0202376 <pmm_init+0x8a6>

    p2 = alloc_page();
ffffffffc0201cf8:	4505                	li	a0,1
ffffffffc0201cfa:	899ff0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0201cfe:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d00:	00093503          	ld	a0,0(s2)
ffffffffc0201d04:	46d1                	li	a3,20
ffffffffc0201d06:	6605                	lui	a2,0x1
ffffffffc0201d08:	85d6                	mv	a1,s5
ffffffffc0201d0a:	cb5ff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0201d0e:	64051463          	bnez	a0,ffffffffc0202356 <pmm_init+0x886>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d12:	00093503          	ld	a0,0(s2)
ffffffffc0201d16:	4601                	li	a2,0
ffffffffc0201d18:	6585                	lui	a1,0x1
ffffffffc0201d1a:	983ff0ef          	jal	ffffffffc020169c <get_pte>
ffffffffc0201d1e:	60050c63          	beqz	a0,ffffffffc0202336 <pmm_init+0x866>
    assert(*ptep & PTE_U);
ffffffffc0201d22:	611c                	ld	a5,0(a0)
ffffffffc0201d24:	0107f713          	and	a4,a5,16
ffffffffc0201d28:	76070463          	beqz	a4,ffffffffc0202490 <pmm_init+0x9c0>
    assert(*ptep & PTE_W);
ffffffffc0201d2c:	8b91                	and	a5,a5,4
ffffffffc0201d2e:	74078163          	beqz	a5,ffffffffc0202470 <pmm_init+0x9a0>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d32:	00093503          	ld	a0,0(s2)
ffffffffc0201d36:	611c                	ld	a5,0(a0)
ffffffffc0201d38:	8bc1                	and	a5,a5,16
ffffffffc0201d3a:	70078b63          	beqz	a5,ffffffffc0202450 <pmm_init+0x980>
    assert(page_ref(p2) == 1);
ffffffffc0201d3e:	000aa703          	lw	a4,0(s5) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0201d42:	4785                	li	a5,1
ffffffffc0201d44:	6ef71663          	bne	a4,a5,ffffffffc0202430 <pmm_init+0x960>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201d48:	4681                	li	a3,0
ffffffffc0201d4a:	6605                	lui	a2,0x1
ffffffffc0201d4c:	85d2                	mv	a1,s4
ffffffffc0201d4e:	c71ff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0201d52:	6a051f63          	bnez	a0,ffffffffc0202410 <pmm_init+0x940>
    assert(page_ref(p1) == 2);
ffffffffc0201d56:	000a2703          	lw	a4,0(s4)
ffffffffc0201d5a:	4789                	li	a5,2
ffffffffc0201d5c:	68f71a63          	bne	a4,a5,ffffffffc02023f0 <pmm_init+0x920>
    assert(page_ref(p2) == 0);
ffffffffc0201d60:	000aa783          	lw	a5,0(s5)
ffffffffc0201d64:	66079663          	bnez	a5,ffffffffc02023d0 <pmm_init+0x900>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d68:	00093503          	ld	a0,0(s2)
ffffffffc0201d6c:	4601                	li	a2,0
ffffffffc0201d6e:	6585                	lui	a1,0x1
ffffffffc0201d70:	92dff0ef          	jal	ffffffffc020169c <get_pte>
ffffffffc0201d74:	62050e63          	beqz	a0,ffffffffc02023b0 <pmm_init+0x8e0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201d78:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201d7a:	00177793          	and	a5,a4,1
ffffffffc0201d7e:	54078a63          	beqz	a5,ffffffffc02022d2 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201d82:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d84:	00271793          	sll	a5,a4,0x2
ffffffffc0201d88:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d8a:	4ad7f663          	bgeu	a5,a3,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d8e:	fff806b7          	lui	a3,0xfff80
ffffffffc0201d92:	97b6                	add	a5,a5,a3
ffffffffc0201d94:	000b3603          	ld	a2,0(s6)
ffffffffc0201d98:	00379693          	sll	a3,a5,0x3
ffffffffc0201d9c:	97b6                	add	a5,a5,a3
ffffffffc0201d9e:	078e                	sll	a5,a5,0x3
ffffffffc0201da0:	97b2                	add	a5,a5,a2
ffffffffc0201da2:	76fa1763          	bne	s4,a5,ffffffffc0202510 <pmm_init+0xa40>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201da6:	8b41                	and	a4,a4,16
ffffffffc0201da8:	74071463          	bnez	a4,ffffffffc02024f0 <pmm_init+0xa20>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201dac:	00093503          	ld	a0,0(s2)
ffffffffc0201db0:	4581                	li	a1,0
ffffffffc0201db2:	b73ff0ef          	jal	ffffffffc0201924 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201db6:	000a2703          	lw	a4,0(s4)
ffffffffc0201dba:	4785                	li	a5,1
ffffffffc0201dbc:	70f71a63          	bne	a4,a5,ffffffffc02024d0 <pmm_init+0xa00>
    assert(page_ref(p2) == 0);
ffffffffc0201dc0:	000aa783          	lw	a5,0(s5)
ffffffffc0201dc4:	6e079663          	bnez	a5,ffffffffc02024b0 <pmm_init+0x9e0>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201dc8:	00093503          	ld	a0,0(s2)
ffffffffc0201dcc:	6585                	lui	a1,0x1
ffffffffc0201dce:	b57ff0ef          	jal	ffffffffc0201924 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201dd2:	000a2783          	lw	a5,0(s4)
ffffffffc0201dd6:	7a079a63          	bnez	a5,ffffffffc020258a <pmm_init+0xaba>
    assert(page_ref(p2) == 0);
ffffffffc0201dda:	000aa783          	lw	a5,0(s5)
ffffffffc0201dde:	78079663          	bnez	a5,ffffffffc020256a <pmm_init+0xa9a>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201de2:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201de6:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201de8:	000a3783          	ld	a5,0(s4)
ffffffffc0201dec:	078a                	sll	a5,a5,0x2
ffffffffc0201dee:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201df0:	44c7f363          	bgeu	a5,a2,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201df4:	fff80737          	lui	a4,0xfff80
ffffffffc0201df8:	97ba                	add	a5,a5,a4
ffffffffc0201dfa:	00379713          	sll	a4,a5,0x3
ffffffffc0201dfe:	000b3503          	ld	a0,0(s6)
ffffffffc0201e02:	973e                	add	a4,a4,a5
ffffffffc0201e04:	070e                	sll	a4,a4,0x3
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc0201e06:	00e507b3          	add	a5,a0,a4
ffffffffc0201e0a:	4394                	lw	a3,0(a5)
ffffffffc0201e0c:	4785                	li	a5,1
ffffffffc0201e0e:	72f69e63          	bne	a3,a5,ffffffffc020254a <pmm_init+0xa7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e12:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0201e16:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0201e1a:	07b2                	sll	a5,a5,0xc
ffffffffc0201e1c:	e3978793          	add	a5,a5,-455
ffffffffc0201e20:	07b2                	sll	a5,a5,0xc
ffffffffc0201e22:	e3978793          	add	a5,a5,-455
ffffffffc0201e26:	07b2                	sll	a5,a5,0xc
ffffffffc0201e28:	870d                	sra	a4,a4,0x3
ffffffffc0201e2a:	e3978793          	add	a5,a5,-455
ffffffffc0201e2e:	02f707b3          	mul	a5,a4,a5
ffffffffc0201e32:	00080737          	lui	a4,0x80
ffffffffc0201e36:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e38:	00c79693          	sll	a3,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e3c:	6ec7fb63          	bgeu	a5,a2,ffffffffc0202532 <pmm_init+0xa62>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201e40:	0009b783          	ld	a5,0(s3)
ffffffffc0201e44:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e46:	639c                	ld	a5,0(a5)
ffffffffc0201e48:	078a                	sll	a5,a5,0x2
ffffffffc0201e4a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e4c:	3ec7f563          	bgeu	a5,a2,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e50:	8f99                	sub	a5,a5,a4
ffffffffc0201e52:	00379713          	sll	a4,a5,0x3
ffffffffc0201e56:	97ba                	add	a5,a5,a4
ffffffffc0201e58:	078e                	sll	a5,a5,0x3
ffffffffc0201e5a:	953e                	add	a0,a0,a5
ffffffffc0201e5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e60:	8b89                	and	a5,a5,2
ffffffffc0201e62:	30079463          	bnez	a5,ffffffffc020216a <pmm_init+0x69a>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201e66:	000bb783          	ld	a5,0(s7)
ffffffffc0201e6a:	4585                	li	a1,1
ffffffffc0201e6c:	739c                	ld	a5,32(a5)
ffffffffc0201e6e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e70:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201e74:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e76:	078a                	sll	a5,a5,0x2
ffffffffc0201e78:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e7a:	3ae7fe63          	bgeu	a5,a4,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e7e:	fff80737          	lui	a4,0xfff80
ffffffffc0201e82:	97ba                	add	a5,a5,a4
ffffffffc0201e84:	000b3503          	ld	a0,0(s6)
ffffffffc0201e88:	00379713          	sll	a4,a5,0x3
ffffffffc0201e8c:	97ba                	add	a5,a5,a4
ffffffffc0201e8e:	078e                	sll	a5,a5,0x3
ffffffffc0201e90:	953e                	add	a0,a0,a5
ffffffffc0201e92:	100027f3          	csrr	a5,sstatus
ffffffffc0201e96:	8b89                	and	a5,a5,2
ffffffffc0201e98:	2a079d63          	bnez	a5,ffffffffc0202152 <pmm_init+0x682>
ffffffffc0201e9c:	000bb783          	ld	a5,0(s7)
ffffffffc0201ea0:	4585                	li	a1,1
ffffffffc0201ea2:	739c                	ld	a5,32(a5)
ffffffffc0201ea4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201ea6:	00093783          	ld	a5,0(s2)
ffffffffc0201eaa:	0007b023          	sd	zero,0(a5)
ffffffffc0201eae:	100027f3          	csrr	a5,sstatus
ffffffffc0201eb2:	8b89                	and	a5,a5,2
ffffffffc0201eb4:	28079563          	bnez	a5,ffffffffc020213e <pmm_init+0x66e>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201eb8:	000bb783          	ld	a5,0(s7)
ffffffffc0201ebc:	779c                	ld	a5,40(a5)
ffffffffc0201ebe:	9782                	jalr	a5
ffffffffc0201ec0:	8a2a                	mv	s4,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc0201ec2:	77441463          	bne	s0,s4,ffffffffc020262a <pmm_init+0xb5a>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201ec6:	00003517          	auipc	a0,0x3
ffffffffc0201eca:	56250513          	add	a0,a0,1378 # ffffffffc0205428 <etext+0x10b4>
ffffffffc0201ece:	9ecfe0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0201ed2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed6:	8b89                	and	a5,a5,2
ffffffffc0201ed8:	24079963          	bnez	a5,ffffffffc020212a <pmm_init+0x65a>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201edc:	000bb783          	ld	a5,0(s7)
ffffffffc0201ee0:	779c                	ld	a5,40(a5)
ffffffffc0201ee2:	9782                	jalr	a5
ffffffffc0201ee4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ee6:	6098                	ld	a4,0(s1)
ffffffffc0201ee8:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201eec:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201eee:	00c71793          	sll	a5,a4,0xc
ffffffffc0201ef2:	6a05                	lui	s4,0x1
ffffffffc0201ef4:	02f47c63          	bgeu	s0,a5,ffffffffc0201f2c <pmm_init+0x45c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ef8:	00c45793          	srl	a5,s0,0xc
ffffffffc0201efc:	00093503          	ld	a0,0(s2)
ffffffffc0201f00:	2ce7fe63          	bgeu	a5,a4,ffffffffc02021dc <pmm_init+0x70c>
ffffffffc0201f04:	0009b583          	ld	a1,0(s3)
ffffffffc0201f08:	4601                	li	a2,0
ffffffffc0201f0a:	95a2                	add	a1,a1,s0
ffffffffc0201f0c:	f90ff0ef          	jal	ffffffffc020169c <get_pte>
ffffffffc0201f10:	30050363          	beqz	a0,ffffffffc0202216 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f14:	611c                	ld	a5,0(a0)
ffffffffc0201f16:	078a                	sll	a5,a5,0x2
ffffffffc0201f18:	0157f7b3          	and	a5,a5,s5
ffffffffc0201f1c:	2c879d63          	bne	a5,s0,ffffffffc02021f6 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f20:	6098                	ld	a4,0(s1)
ffffffffc0201f22:	9452                	add	s0,s0,s4
ffffffffc0201f24:	00c71793          	sll	a5,a4,0xc
ffffffffc0201f28:	fcf468e3          	bltu	s0,a5,ffffffffc0201ef8 <pmm_init+0x428>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201f2c:	00093783          	ld	a5,0(s2)
ffffffffc0201f30:	639c                	ld	a5,0(a5)
ffffffffc0201f32:	6c079c63          	bnez	a5,ffffffffc020260a <pmm_init+0xb3a>

    struct Page *p;
    p = alloc_page();
ffffffffc0201f36:	4505                	li	a0,1
ffffffffc0201f38:	e5aff0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0201f3c:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201f3e:	00093503          	ld	a0,0(s2)
ffffffffc0201f42:	4699                	li	a3,6
ffffffffc0201f44:	10000613          	li	a2,256
ffffffffc0201f48:	85d2                	mv	a1,s4
ffffffffc0201f4a:	a75ff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0201f4e:	68051e63          	bnez	a0,ffffffffc02025ea <pmm_init+0xb1a>
    assert(page_ref(p) == 1);
ffffffffc0201f52:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201f56:	4785                	li	a5,1
ffffffffc0201f58:	66f71963          	bne	a4,a5,ffffffffc02025ca <pmm_init+0xafa>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201f5c:	00093503          	ld	a0,0(s2)
ffffffffc0201f60:	6605                	lui	a2,0x1
ffffffffc0201f62:	4699                	li	a3,6
ffffffffc0201f64:	10060613          	add	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201f68:	85d2                	mv	a1,s4
ffffffffc0201f6a:	a55ff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0201f6e:	62051e63          	bnez	a0,ffffffffc02025aa <pmm_init+0xada>
    assert(page_ref(p) == 2);
ffffffffc0201f72:	000a2703          	lw	a4,0(s4)
ffffffffc0201f76:	4789                	li	a5,2
ffffffffc0201f78:	76f71163          	bne	a4,a5,ffffffffc02026da <pmm_init+0xc0a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201f7c:	00003597          	auipc	a1,0x3
ffffffffc0201f80:	5e458593          	add	a1,a1,1508 # ffffffffc0205560 <etext+0x11ec>
ffffffffc0201f84:	10000513          	li	a0,256
ffffffffc0201f88:	362020ef          	jal	ffffffffc02042ea <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201f8c:	6585                	lui	a1,0x1
ffffffffc0201f8e:	10058593          	add	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201f92:	10000513          	li	a0,256
ffffffffc0201f96:	366020ef          	jal	ffffffffc02042fc <strcmp>
ffffffffc0201f9a:	72051063          	bnez	a0,ffffffffc02026ba <pmm_init+0xbea>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201f9e:	f8e39437          	lui	s0,0xf8e39
ffffffffc0201fa2:	e3940413          	add	s0,s0,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0201fa6:	0432                	sll	s0,s0,0xc
ffffffffc0201fa8:	000b3683          	ld	a3,0(s6)
ffffffffc0201fac:	e3940413          	add	s0,s0,-455
ffffffffc0201fb0:	0432                	sll	s0,s0,0xc
ffffffffc0201fb2:	e3940413          	add	s0,s0,-455
ffffffffc0201fb6:	40da06b3          	sub	a3,s4,a3
ffffffffc0201fba:	0432                	sll	s0,s0,0xc
ffffffffc0201fbc:	868d                	sra	a3,a3,0x3
ffffffffc0201fbe:	e3940413          	add	s0,s0,-455
ffffffffc0201fc2:	028686b3          	mul	a3,a3,s0
ffffffffc0201fc6:	00080cb7          	lui	s9,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fca:	6098                	ld	a4,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fcc:	96e6                	add	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fce:	00c69793          	sll	a5,a3,0xc
ffffffffc0201fd2:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd4:	06b2                	sll	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fd6:	54e7fe63          	bgeu	a5,a4,ffffffffc0202532 <pmm_init+0xa62>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fda:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fde:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fe2:	97b6                	add	a5,a5,a3
ffffffffc0201fe4:	10078023          	sb	zero,256(a5)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fe8:	2cc020ef          	jal	ffffffffc02042b4 <strlen>
ffffffffc0201fec:	6a051763          	bnez	a0,ffffffffc020269a <pmm_init+0xbca>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201ff0:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201ff4:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ff6:	000ab783          	ld	a5,0(s5) # fffffffffffff000 <end+0x3fdeda90>
ffffffffc0201ffa:	078a                	sll	a5,a5,0x2
ffffffffc0201ffc:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ffe:	22c7fc63          	bgeu	a5,a2,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202002:	419787b3          	sub	a5,a5,s9
ffffffffc0202006:	00379713          	sll	a4,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020200a:	97ba                	add	a5,a5,a4
ffffffffc020200c:	028787b3          	mul	a5,a5,s0
ffffffffc0202010:	97e6                	add	a5,a5,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc0202012:	00c79413          	sll	s0,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202016:	50c7fd63          	bgeu	a5,a2,ffffffffc0202530 <pmm_init+0xa60>
ffffffffc020201a:	0009b783          	ld	a5,0(s3)
ffffffffc020201e:	943e                	add	s0,s0,a5
ffffffffc0202020:	100027f3          	csrr	a5,sstatus
ffffffffc0202024:	8b89                	and	a5,a5,2
ffffffffc0202026:	1a079063          	bnez	a5,ffffffffc02021c6 <pmm_init+0x6f6>
    { pmm_manager->free_pages(base, n); }
ffffffffc020202a:	000bb783          	ld	a5,0(s7)
ffffffffc020202e:	4585                	li	a1,1
ffffffffc0202030:	8552                	mv	a0,s4
ffffffffc0202032:	739c                	ld	a5,32(a5)
ffffffffc0202034:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202036:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202038:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020203a:	078a                	sll	a5,a5,0x2
ffffffffc020203c:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020203e:	1ee7fc63          	bgeu	a5,a4,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202042:	fff80737          	lui	a4,0xfff80
ffffffffc0202046:	97ba                	add	a5,a5,a4
ffffffffc0202048:	000b3503          	ld	a0,0(s6)
ffffffffc020204c:	00379713          	sll	a4,a5,0x3
ffffffffc0202050:	97ba                	add	a5,a5,a4
ffffffffc0202052:	078e                	sll	a5,a5,0x3
ffffffffc0202054:	953e                	add	a0,a0,a5
ffffffffc0202056:	100027f3          	csrr	a5,sstatus
ffffffffc020205a:	8b89                	and	a5,a5,2
ffffffffc020205c:	14079963          	bnez	a5,ffffffffc02021ae <pmm_init+0x6de>
ffffffffc0202060:	000bb783          	ld	a5,0(s7)
ffffffffc0202064:	4585                	li	a1,1
ffffffffc0202066:	739c                	ld	a5,32(a5)
ffffffffc0202068:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020206a:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020206e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202070:	078a                	sll	a5,a5,0x2
ffffffffc0202072:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202074:	1ce7f163          	bgeu	a5,a4,ffffffffc0202236 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202078:	fff80737          	lui	a4,0xfff80
ffffffffc020207c:	97ba                	add	a5,a5,a4
ffffffffc020207e:	000b3503          	ld	a0,0(s6)
ffffffffc0202082:	00379713          	sll	a4,a5,0x3
ffffffffc0202086:	97ba                	add	a5,a5,a4
ffffffffc0202088:	078e                	sll	a5,a5,0x3
ffffffffc020208a:	953e                	add	a0,a0,a5
ffffffffc020208c:	100027f3          	csrr	a5,sstatus
ffffffffc0202090:	8b89                	and	a5,a5,2
ffffffffc0202092:	10079263          	bnez	a5,ffffffffc0202196 <pmm_init+0x6c6>
ffffffffc0202096:	000bb783          	ld	a5,0(s7)
ffffffffc020209a:	4585                	li	a1,1
ffffffffc020209c:	739c                	ld	a5,32(a5)
ffffffffc020209e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02020a0:	00093783          	ld	a5,0(s2)
ffffffffc02020a4:	0007b023          	sd	zero,0(a5)
ffffffffc02020a8:	100027f3          	csrr	a5,sstatus
ffffffffc02020ac:	8b89                	and	a5,a5,2
ffffffffc02020ae:	0c079a63          	bnez	a5,ffffffffc0202182 <pmm_init+0x6b2>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02020b2:	000bb783          	ld	a5,0(s7)
ffffffffc02020b6:	779c                	ld	a5,40(a5)
ffffffffc02020b8:	9782                	jalr	a5
ffffffffc02020ba:	842a                	mv	s0,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc02020bc:	1a8c1b63          	bne	s8,s0,ffffffffc0202272 <pmm_init+0x7a2>
}
ffffffffc02020c0:	7406                	ld	s0,96(sp)
ffffffffc02020c2:	70a6                	ld	ra,104(sp)
ffffffffc02020c4:	64e6                	ld	s1,88(sp)
ffffffffc02020c6:	6946                	ld	s2,80(sp)
ffffffffc02020c8:	69a6                	ld	s3,72(sp)
ffffffffc02020ca:	6a06                	ld	s4,64(sp)
ffffffffc02020cc:	7ae2                	ld	s5,56(sp)
ffffffffc02020ce:	7b42                	ld	s6,48(sp)
ffffffffc02020d0:	7ba2                	ld	s7,40(sp)
ffffffffc02020d2:	7c02                	ld	s8,32(sp)
ffffffffc02020d4:	6ce2                	ld	s9,24(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02020d6:	00003517          	auipc	a0,0x3
ffffffffc02020da:	50250513          	add	a0,a0,1282 # ffffffffc02055d8 <etext+0x1264>
}
ffffffffc02020de:	6165                	add	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02020e0:	fdbfd06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02020e4:	6705                	lui	a4,0x1
ffffffffc02020e6:	177d                	add	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02020e8:	96ba                	add	a3,a3,a4
ffffffffc02020ea:	777d                	lui	a4,0xfffff
ffffffffc02020ec:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) {
ffffffffc02020ee:	00c75693          	srl	a3,a4,0xc
ffffffffc02020f2:	14f6f263          	bgeu	a3,a5,ffffffffc0202236 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc02020f6:	000bb583          	ld	a1,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc02020fa:	fff807b7          	lui	a5,0xfff80
ffffffffc02020fe:	96be                	add	a3,a3,a5
ffffffffc0202100:	00369793          	sll	a5,a3,0x3
ffffffffc0202104:	97b6                	add	a5,a5,a3
ffffffffc0202106:	6994                	ld	a3,16(a1)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202108:	8e19                	sub	a2,a2,a4
ffffffffc020210a:	078e                	sll	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020210c:	00c65593          	srl	a1,a2,0xc
ffffffffc0202110:	953e                	add	a0,a0,a5
ffffffffc0202112:	9682                	jalr	a3
}
ffffffffc0202114:	b4f9                	j	ffffffffc0201be2 <pmm_init+0x112>
        intr_disable();
ffffffffc0202116:	ba2fe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020211a:	000bb783          	ld	a5,0(s7)
ffffffffc020211e:	779c                	ld	a5,40(a5)
ffffffffc0202120:	9782                	jalr	a5
ffffffffc0202122:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202124:	b8efe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0202128:	b631                	j	ffffffffc0201c34 <pmm_init+0x164>
        intr_disable();
ffffffffc020212a:	b8efe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc020212e:	000bb783          	ld	a5,0(s7)
ffffffffc0202132:	779c                	ld	a5,40(a5)
ffffffffc0202134:	9782                	jalr	a5
ffffffffc0202136:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202138:	b7afe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc020213c:	b36d                	j	ffffffffc0201ee6 <pmm_init+0x416>
        intr_disable();
ffffffffc020213e:	b7afe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc0202142:	000bb783          	ld	a5,0(s7)
ffffffffc0202146:	779c                	ld	a5,40(a5)
ffffffffc0202148:	9782                	jalr	a5
ffffffffc020214a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020214c:	b66fe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0202150:	bb8d                	j	ffffffffc0201ec2 <pmm_init+0x3f2>
ffffffffc0202152:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202154:	b64fe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0202158:	000bb783          	ld	a5,0(s7)
ffffffffc020215c:	6522                	ld	a0,8(sp)
ffffffffc020215e:	4585                	li	a1,1
ffffffffc0202160:	739c                	ld	a5,32(a5)
ffffffffc0202162:	9782                	jalr	a5
        intr_enable();
ffffffffc0202164:	b4efe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0202168:	bb3d                	j	ffffffffc0201ea6 <pmm_init+0x3d6>
ffffffffc020216a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020216c:	b4cfe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc0202170:	000bb783          	ld	a5,0(s7)
ffffffffc0202174:	6522                	ld	a0,8(sp)
ffffffffc0202176:	4585                	li	a1,1
ffffffffc0202178:	739c                	ld	a5,32(a5)
ffffffffc020217a:	9782                	jalr	a5
        intr_enable();
ffffffffc020217c:	b36fe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0202180:	b9c5                	j	ffffffffc0201e70 <pmm_init+0x3a0>
        intr_disable();
ffffffffc0202182:	b36fe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202186:	000bb783          	ld	a5,0(s7)
ffffffffc020218a:	779c                	ld	a5,40(a5)
ffffffffc020218c:	9782                	jalr	a5
ffffffffc020218e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202190:	b22fe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc0202194:	b725                	j	ffffffffc02020bc <pmm_init+0x5ec>
ffffffffc0202196:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202198:	b20fe0ef          	jal	ffffffffc02004b8 <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc020219c:	000bb783          	ld	a5,0(s7)
ffffffffc02021a0:	6522                	ld	a0,8(sp)
ffffffffc02021a2:	4585                	li	a1,1
ffffffffc02021a4:	739c                	ld	a5,32(a5)
ffffffffc02021a6:	9782                	jalr	a5
        intr_enable();
ffffffffc02021a8:	b0afe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc02021ac:	bdd5                	j	ffffffffc02020a0 <pmm_init+0x5d0>
ffffffffc02021ae:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021b0:	b08fe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc02021b4:	000bb783          	ld	a5,0(s7)
ffffffffc02021b8:	6522                	ld	a0,8(sp)
ffffffffc02021ba:	4585                	li	a1,1
ffffffffc02021bc:	739c                	ld	a5,32(a5)
ffffffffc02021be:	9782                	jalr	a5
        intr_enable();
ffffffffc02021c0:	af2fe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc02021c4:	b55d                	j	ffffffffc020206a <pmm_init+0x59a>
        intr_disable();
ffffffffc02021c6:	af2fe0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc02021ca:	000bb783          	ld	a5,0(s7)
ffffffffc02021ce:	4585                	li	a1,1
ffffffffc02021d0:	8552                	mv	a0,s4
ffffffffc02021d2:	739c                	ld	a5,32(a5)
ffffffffc02021d4:	9782                	jalr	a5
        intr_enable();
ffffffffc02021d6:	adcfe0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc02021da:	bdb1                	j	ffffffffc0202036 <pmm_init+0x566>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02021dc:	86a2                	mv	a3,s0
ffffffffc02021de:	00003617          	auipc	a2,0x3
ffffffffc02021e2:	e7a60613          	add	a2,a2,-390 # ffffffffc0205058 <etext+0xce4>
ffffffffc02021e6:	1cd00593          	li	a1,461
ffffffffc02021ea:	00003517          	auipc	a0,0x3
ffffffffc02021ee:	e9650513          	add	a0,a0,-362 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02021f2:	96efe0ef          	jal	ffffffffc0200360 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02021f6:	00003697          	auipc	a3,0x3
ffffffffc02021fa:	29268693          	add	a3,a3,658 # ffffffffc0205488 <etext+0x1114>
ffffffffc02021fe:	00003617          	auipc	a2,0x3
ffffffffc0202202:	a5260613          	add	a2,a2,-1454 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202206:	1ce00593          	li	a1,462
ffffffffc020220a:	00003517          	auipc	a0,0x3
ffffffffc020220e:	e7650513          	add	a0,a0,-394 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202212:	94efe0ef          	jal	ffffffffc0200360 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202216:	00003697          	auipc	a3,0x3
ffffffffc020221a:	23268693          	add	a3,a3,562 # ffffffffc0205448 <etext+0x10d4>
ffffffffc020221e:	00003617          	auipc	a2,0x3
ffffffffc0202222:	a3260613          	add	a2,a2,-1486 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202226:	1cd00593          	li	a1,461
ffffffffc020222a:	00003517          	auipc	a0,0x3
ffffffffc020222e:	e5650513          	add	a0,a0,-426 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202232:	92efe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0202236:	b24ff0ef          	jal	ffffffffc020155a <pa2page.part.0>
    assert(pte2page(*ptep) == p1);
ffffffffc020223a:	00003697          	auipc	a3,0x3
ffffffffc020223e:	00668693          	add	a3,a3,6 # ffffffffc0205240 <etext+0xecc>
ffffffffc0202242:	00003617          	auipc	a2,0x3
ffffffffc0202246:	a0e60613          	add	a2,a2,-1522 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020224a:	19b00593          	li	a1,411
ffffffffc020224e:	00003517          	auipc	a0,0x3
ffffffffc0202252:	e3250513          	add	a0,a0,-462 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202256:	90afe0ef          	jal	ffffffffc0200360 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020225a:	00003617          	auipc	a2,0x3
ffffffffc020225e:	ebe60613          	add	a2,a2,-322 # ffffffffc0205118 <etext+0xda4>
ffffffffc0202262:	07700593          	li	a1,119
ffffffffc0202266:	00003517          	auipc	a0,0x3
ffffffffc020226a:	e1a50513          	add	a0,a0,-486 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020226e:	8f2fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202272:	00003697          	auipc	a3,0x3
ffffffffc0202276:	19668693          	add	a3,a3,406 # ffffffffc0205408 <etext+0x1094>
ffffffffc020227a:	00003617          	auipc	a2,0x3
ffffffffc020227e:	9d660613          	add	a2,a2,-1578 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202282:	1e800593          	li	a1,488
ffffffffc0202286:	00003517          	auipc	a0,0x3
ffffffffc020228a:	dfa50513          	add	a0,a0,-518 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020228e:	8d2fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202292:	00003697          	auipc	a3,0x3
ffffffffc0202296:	eee68693          	add	a3,a3,-274 # ffffffffc0205180 <etext+0xe0c>
ffffffffc020229a:	00003617          	auipc	a2,0x3
ffffffffc020229e:	9b660613          	add	a2,a2,-1610 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02022a2:	19300593          	li	a1,403
ffffffffc02022a6:	00003517          	auipc	a0,0x3
ffffffffc02022aa:	dda50513          	add	a0,a0,-550 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02022ae:	8b2fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022b2:	00003697          	auipc	a3,0x3
ffffffffc02022b6:	eae68693          	add	a3,a3,-338 # ffffffffc0205160 <etext+0xdec>
ffffffffc02022ba:	00003617          	auipc	a2,0x3
ffffffffc02022be:	99660613          	add	a2,a2,-1642 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02022c2:	19200593          	li	a1,402
ffffffffc02022c6:	00003517          	auipc	a0,0x3
ffffffffc02022ca:	dba50513          	add	a0,a0,-582 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02022ce:	892fe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc02022d2:	aa4ff0ef          	jal	ffffffffc0201576 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02022d6:	00003697          	auipc	a3,0x3
ffffffffc02022da:	f3a68693          	add	a3,a3,-198 # ffffffffc0205210 <etext+0xe9c>
ffffffffc02022de:	00003617          	auipc	a2,0x3
ffffffffc02022e2:	97260613          	add	a2,a2,-1678 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02022e6:	19a00593          	li	a1,410
ffffffffc02022ea:	00003517          	auipc	a0,0x3
ffffffffc02022ee:	d9650513          	add	a0,a0,-618 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02022f2:	86efe0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02022f6:	00003697          	auipc	a3,0x3
ffffffffc02022fa:	eea68693          	add	a3,a3,-278 # ffffffffc02051e0 <etext+0xe6c>
ffffffffc02022fe:	00003617          	auipc	a2,0x3
ffffffffc0202302:	95260613          	add	a2,a2,-1710 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202306:	19800593          	li	a1,408
ffffffffc020230a:	00003517          	auipc	a0,0x3
ffffffffc020230e:	d7650513          	add	a0,a0,-650 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202312:	84efe0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202316:	00003697          	auipc	a3,0x3
ffffffffc020231a:	ea268693          	add	a3,a3,-350 # ffffffffc02051b8 <etext+0xe44>
ffffffffc020231e:	00003617          	auipc	a2,0x3
ffffffffc0202322:	93260613          	add	a2,a2,-1742 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202326:	19400593          	li	a1,404
ffffffffc020232a:	00003517          	auipc	a0,0x3
ffffffffc020232e:	d5650513          	add	a0,a0,-682 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202332:	82efe0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202336:	00003697          	auipc	a3,0x3
ffffffffc020233a:	f9a68693          	add	a3,a3,-102 # ffffffffc02052d0 <etext+0xf5c>
ffffffffc020233e:	00003617          	auipc	a2,0x3
ffffffffc0202342:	91260613          	add	a2,a2,-1774 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202346:	1a400593          	li	a1,420
ffffffffc020234a:	00003517          	auipc	a0,0x3
ffffffffc020234e:	d3650513          	add	a0,a0,-714 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202352:	80efe0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202356:	00003697          	auipc	a3,0x3
ffffffffc020235a:	f4268693          	add	a3,a3,-190 # ffffffffc0205298 <etext+0xf24>
ffffffffc020235e:	00003617          	auipc	a2,0x3
ffffffffc0202362:	8f260613          	add	a2,a2,-1806 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202366:	1a300593          	li	a1,419
ffffffffc020236a:	00003517          	auipc	a0,0x3
ffffffffc020236e:	d1650513          	add	a0,a0,-746 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202372:	feffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202376:	00003697          	auipc	a3,0x3
ffffffffc020237a:	efa68693          	add	a3,a3,-262 # ffffffffc0205270 <etext+0xefc>
ffffffffc020237e:	00003617          	auipc	a2,0x3
ffffffffc0202382:	8d260613          	add	a2,a2,-1838 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202386:	1a000593          	li	a1,416
ffffffffc020238a:	00003517          	auipc	a0,0x3
ffffffffc020238e:	cf650513          	add	a0,a0,-778 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202392:	fcffd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202396:	86d6                	mv	a3,s5
ffffffffc0202398:	00003617          	auipc	a2,0x3
ffffffffc020239c:	cc060613          	add	a2,a2,-832 # ffffffffc0205058 <etext+0xce4>
ffffffffc02023a0:	19f00593          	li	a1,415
ffffffffc02023a4:	00003517          	auipc	a0,0x3
ffffffffc02023a8:	cdc50513          	add	a0,a0,-804 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02023ac:	fb5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02023b0:	00003697          	auipc	a3,0x3
ffffffffc02023b4:	f2068693          	add	a3,a3,-224 # ffffffffc02052d0 <etext+0xf5c>
ffffffffc02023b8:	00003617          	auipc	a2,0x3
ffffffffc02023bc:	89860613          	add	a2,a2,-1896 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02023c0:	1ad00593          	li	a1,429
ffffffffc02023c4:	00003517          	auipc	a0,0x3
ffffffffc02023c8:	cbc50513          	add	a0,a0,-836 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02023cc:	f95fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02023d0:	00003697          	auipc	a3,0x3
ffffffffc02023d4:	fc868693          	add	a3,a3,-56 # ffffffffc0205398 <etext+0x1024>
ffffffffc02023d8:	00003617          	auipc	a2,0x3
ffffffffc02023dc:	87860613          	add	a2,a2,-1928 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02023e0:	1ac00593          	li	a1,428
ffffffffc02023e4:	00003517          	auipc	a0,0x3
ffffffffc02023e8:	c9c50513          	add	a0,a0,-868 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02023ec:	f75fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02023f0:	00003697          	auipc	a3,0x3
ffffffffc02023f4:	f9068693          	add	a3,a3,-112 # ffffffffc0205380 <etext+0x100c>
ffffffffc02023f8:	00003617          	auipc	a2,0x3
ffffffffc02023fc:	85860613          	add	a2,a2,-1960 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202400:	1ab00593          	li	a1,427
ffffffffc0202404:	00003517          	auipc	a0,0x3
ffffffffc0202408:	c7c50513          	add	a0,a0,-900 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020240c:	f55fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202410:	00003697          	auipc	a3,0x3
ffffffffc0202414:	f4068693          	add	a3,a3,-192 # ffffffffc0205350 <etext+0xfdc>
ffffffffc0202418:	00003617          	auipc	a2,0x3
ffffffffc020241c:	83860613          	add	a2,a2,-1992 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202420:	1aa00593          	li	a1,426
ffffffffc0202424:	00003517          	auipc	a0,0x3
ffffffffc0202428:	c5c50513          	add	a0,a0,-932 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020242c:	f35fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202430:	00003697          	auipc	a3,0x3
ffffffffc0202434:	f0868693          	add	a3,a3,-248 # ffffffffc0205338 <etext+0xfc4>
ffffffffc0202438:	00003617          	auipc	a2,0x3
ffffffffc020243c:	81860613          	add	a2,a2,-2024 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202440:	1a800593          	li	a1,424
ffffffffc0202444:	00003517          	auipc	a0,0x3
ffffffffc0202448:	c3c50513          	add	a0,a0,-964 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020244c:	f15fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202450:	00003697          	auipc	a3,0x3
ffffffffc0202454:	ed068693          	add	a3,a3,-304 # ffffffffc0205320 <etext+0xfac>
ffffffffc0202458:	00002617          	auipc	a2,0x2
ffffffffc020245c:	7f860613          	add	a2,a2,2040 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202460:	1a700593          	li	a1,423
ffffffffc0202464:	00003517          	auipc	a0,0x3
ffffffffc0202468:	c1c50513          	add	a0,a0,-996 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020246c:	ef5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202470:	00003697          	auipc	a3,0x3
ffffffffc0202474:	ea068693          	add	a3,a3,-352 # ffffffffc0205310 <etext+0xf9c>
ffffffffc0202478:	00002617          	auipc	a2,0x2
ffffffffc020247c:	7d860613          	add	a2,a2,2008 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202480:	1a600593          	li	a1,422
ffffffffc0202484:	00003517          	auipc	a0,0x3
ffffffffc0202488:	bfc50513          	add	a0,a0,-1028 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020248c:	ed5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202490:	00003697          	auipc	a3,0x3
ffffffffc0202494:	e7068693          	add	a3,a3,-400 # ffffffffc0205300 <etext+0xf8c>
ffffffffc0202498:	00002617          	auipc	a2,0x2
ffffffffc020249c:	7b860613          	add	a2,a2,1976 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02024a0:	1a500593          	li	a1,421
ffffffffc02024a4:	00003517          	auipc	a0,0x3
ffffffffc02024a8:	bdc50513          	add	a0,a0,-1060 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02024ac:	eb5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02024b0:	00003697          	auipc	a3,0x3
ffffffffc02024b4:	ee868693          	add	a3,a3,-280 # ffffffffc0205398 <etext+0x1024>
ffffffffc02024b8:	00002617          	auipc	a2,0x2
ffffffffc02024bc:	79860613          	add	a2,a2,1944 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02024c0:	1b300593          	li	a1,435
ffffffffc02024c4:	00003517          	auipc	a0,0x3
ffffffffc02024c8:	bbc50513          	add	a0,a0,-1092 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02024cc:	e95fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02024d0:	00003697          	auipc	a3,0x3
ffffffffc02024d4:	d8868693          	add	a3,a3,-632 # ffffffffc0205258 <etext+0xee4>
ffffffffc02024d8:	00002617          	auipc	a2,0x2
ffffffffc02024dc:	77860613          	add	a2,a2,1912 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02024e0:	1b200593          	li	a1,434
ffffffffc02024e4:	00003517          	auipc	a0,0x3
ffffffffc02024e8:	b9c50513          	add	a0,a0,-1124 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02024ec:	e75fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02024f0:	00003697          	auipc	a3,0x3
ffffffffc02024f4:	ec068693          	add	a3,a3,-320 # ffffffffc02053b0 <etext+0x103c>
ffffffffc02024f8:	00002617          	auipc	a2,0x2
ffffffffc02024fc:	75860613          	add	a2,a2,1880 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202500:	1af00593          	li	a1,431
ffffffffc0202504:	00003517          	auipc	a0,0x3
ffffffffc0202508:	b7c50513          	add	a0,a0,-1156 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020250c:	e55fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202510:	00003697          	auipc	a3,0x3
ffffffffc0202514:	d3068693          	add	a3,a3,-720 # ffffffffc0205240 <etext+0xecc>
ffffffffc0202518:	00002617          	auipc	a2,0x2
ffffffffc020251c:	73860613          	add	a2,a2,1848 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202520:	1ae00593          	li	a1,430
ffffffffc0202524:	00003517          	auipc	a0,0x3
ffffffffc0202528:	b5c50513          	add	a0,a0,-1188 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020252c:	e35fd0ef          	jal	ffffffffc0200360 <__panic>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202530:	86a2                	mv	a3,s0
ffffffffc0202532:	00003617          	auipc	a2,0x3
ffffffffc0202536:	b2660613          	add	a2,a2,-1242 # ffffffffc0205058 <etext+0xce4>
ffffffffc020253a:	06a00593          	li	a1,106
ffffffffc020253e:	00003517          	auipc	a0,0x3
ffffffffc0202542:	ae250513          	add	a0,a0,-1310 # ffffffffc0205020 <etext+0xcac>
ffffffffc0202546:	e1bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020254a:	00003697          	auipc	a3,0x3
ffffffffc020254e:	e9668693          	add	a3,a3,-362 # ffffffffc02053e0 <etext+0x106c>
ffffffffc0202552:	00002617          	auipc	a2,0x2
ffffffffc0202556:	6fe60613          	add	a2,a2,1790 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020255a:	1b900593          	li	a1,441
ffffffffc020255e:	00003517          	auipc	a0,0x3
ffffffffc0202562:	b2250513          	add	a0,a0,-1246 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202566:	dfbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020256a:	00003697          	auipc	a3,0x3
ffffffffc020256e:	e2e68693          	add	a3,a3,-466 # ffffffffc0205398 <etext+0x1024>
ffffffffc0202572:	00002617          	auipc	a2,0x2
ffffffffc0202576:	6de60613          	add	a2,a2,1758 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020257a:	1b700593          	li	a1,439
ffffffffc020257e:	00003517          	auipc	a0,0x3
ffffffffc0202582:	b0250513          	add	a0,a0,-1278 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202586:	ddbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020258a:	00003697          	auipc	a3,0x3
ffffffffc020258e:	e3e68693          	add	a3,a3,-450 # ffffffffc02053c8 <etext+0x1054>
ffffffffc0202592:	00002617          	auipc	a2,0x2
ffffffffc0202596:	6be60613          	add	a2,a2,1726 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020259a:	1b600593          	li	a1,438
ffffffffc020259e:	00003517          	auipc	a0,0x3
ffffffffc02025a2:	ae250513          	add	a0,a0,-1310 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02025a6:	dbbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025aa:	00003697          	auipc	a3,0x3
ffffffffc02025ae:	f5e68693          	add	a3,a3,-162 # ffffffffc0205508 <etext+0x1194>
ffffffffc02025b2:	00002617          	auipc	a2,0x2
ffffffffc02025b6:	69e60613          	add	a2,a2,1694 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02025ba:	1d800593          	li	a1,472
ffffffffc02025be:	00003517          	auipc	a0,0x3
ffffffffc02025c2:	ac250513          	add	a0,a0,-1342 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02025c6:	d9bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02025ca:	00003697          	auipc	a3,0x3
ffffffffc02025ce:	f2668693          	add	a3,a3,-218 # ffffffffc02054f0 <etext+0x117c>
ffffffffc02025d2:	00002617          	auipc	a2,0x2
ffffffffc02025d6:	67e60613          	add	a2,a2,1662 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02025da:	1d700593          	li	a1,471
ffffffffc02025de:	00003517          	auipc	a0,0x3
ffffffffc02025e2:	aa250513          	add	a0,a0,-1374 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02025e6:	d7bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025ea:	00003697          	auipc	a3,0x3
ffffffffc02025ee:	ece68693          	add	a3,a3,-306 # ffffffffc02054b8 <etext+0x1144>
ffffffffc02025f2:	00002617          	auipc	a2,0x2
ffffffffc02025f6:	65e60613          	add	a2,a2,1630 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02025fa:	1d600593          	li	a1,470
ffffffffc02025fe:	00003517          	auipc	a0,0x3
ffffffffc0202602:	a8250513          	add	a0,a0,-1406 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202606:	d5bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020260a:	00003697          	auipc	a3,0x3
ffffffffc020260e:	e9668693          	add	a3,a3,-362 # ffffffffc02054a0 <etext+0x112c>
ffffffffc0202612:	00002617          	auipc	a2,0x2
ffffffffc0202616:	63e60613          	add	a2,a2,1598 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020261a:	1d200593          	li	a1,466
ffffffffc020261e:	00003517          	auipc	a0,0x3
ffffffffc0202622:	a6250513          	add	a0,a0,-1438 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202626:	d3bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020262a:	00003697          	auipc	a3,0x3
ffffffffc020262e:	dde68693          	add	a3,a3,-546 # ffffffffc0205408 <etext+0x1094>
ffffffffc0202632:	00002617          	auipc	a2,0x2
ffffffffc0202636:	61e60613          	add	a2,a2,1566 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020263a:	1c000593          	li	a1,448
ffffffffc020263e:	00003517          	auipc	a0,0x3
ffffffffc0202642:	a4250513          	add	a0,a0,-1470 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202646:	d1bfd0ef          	jal	ffffffffc0200360 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020264a:	00003617          	auipc	a2,0x3
ffffffffc020264e:	ace60613          	add	a2,a2,-1330 # ffffffffc0205118 <etext+0xda4>
ffffffffc0202652:	0bd00593          	li	a1,189
ffffffffc0202656:	00003517          	auipc	a0,0x3
ffffffffc020265a:	a2a50513          	add	a0,a0,-1494 # ffffffffc0205080 <etext+0xd0c>
ffffffffc020265e:	d03fd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202662:	00003617          	auipc	a2,0x3
ffffffffc0202666:	9f660613          	add	a2,a2,-1546 # ffffffffc0205058 <etext+0xce4>
ffffffffc020266a:	19e00593          	li	a1,414
ffffffffc020266e:	00003517          	auipc	a0,0x3
ffffffffc0202672:	a1250513          	add	a0,a0,-1518 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202676:	cebfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020267a:	00003697          	auipc	a3,0x3
ffffffffc020267e:	bde68693          	add	a3,a3,-1058 # ffffffffc0205258 <etext+0xee4>
ffffffffc0202682:	00002617          	auipc	a2,0x2
ffffffffc0202686:	5ce60613          	add	a2,a2,1486 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020268a:	19c00593          	li	a1,412
ffffffffc020268e:	00003517          	auipc	a0,0x3
ffffffffc0202692:	9f250513          	add	a0,a0,-1550 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202696:	ccbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020269a:	00003697          	auipc	a3,0x3
ffffffffc020269e:	f1668693          	add	a3,a3,-234 # ffffffffc02055b0 <etext+0x123c>
ffffffffc02026a2:	00002617          	auipc	a2,0x2
ffffffffc02026a6:	5ae60613          	add	a2,a2,1454 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02026aa:	1e000593          	li	a1,480
ffffffffc02026ae:	00003517          	auipc	a0,0x3
ffffffffc02026b2:	9d250513          	add	a0,a0,-1582 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02026b6:	cabfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02026ba:	00003697          	auipc	a3,0x3
ffffffffc02026be:	ebe68693          	add	a3,a3,-322 # ffffffffc0205578 <etext+0x1204>
ffffffffc02026c2:	00002617          	auipc	a2,0x2
ffffffffc02026c6:	58e60613          	add	a2,a2,1422 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02026ca:	1dd00593          	li	a1,477
ffffffffc02026ce:	00003517          	auipc	a0,0x3
ffffffffc02026d2:	9b250513          	add	a0,a0,-1614 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02026d6:	c8bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02026da:	00003697          	auipc	a3,0x3
ffffffffc02026de:	e6e68693          	add	a3,a3,-402 # ffffffffc0205548 <etext+0x11d4>
ffffffffc02026e2:	00002617          	auipc	a2,0x2
ffffffffc02026e6:	56e60613          	add	a2,a2,1390 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02026ea:	1d900593          	li	a1,473
ffffffffc02026ee:	00003517          	auipc	a0,0x3
ffffffffc02026f2:	99250513          	add	a0,a0,-1646 # ffffffffc0205080 <etext+0xd0c>
ffffffffc02026f6:	c6bfd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02026fa <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc02026fa:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc02026fe:	8082                	ret

ffffffffc0202700 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202700:	7179                	add	sp,sp,-48
ffffffffc0202702:	e84a                	sd	s2,16(sp)
ffffffffc0202704:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202706:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202708:	ec26                	sd	s1,24(sp)
ffffffffc020270a:	e44e                	sd	s3,8(sp)
ffffffffc020270c:	f406                	sd	ra,40(sp)
ffffffffc020270e:	f022                	sd	s0,32(sp)
ffffffffc0202710:	84ae                	mv	s1,a1
ffffffffc0202712:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202714:	e7ffe0ef          	jal	ffffffffc0201592 <alloc_pages>
    if (page != NULL) {
ffffffffc0202718:	c131                	beqz	a0,ffffffffc020275c <pgdir_alloc_page+0x5c>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc020271a:	842a                	mv	s0,a0
ffffffffc020271c:	85aa                	mv	a1,a0
ffffffffc020271e:	86ce                	mv	a3,s3
ffffffffc0202720:	8626                	mv	a2,s1
ffffffffc0202722:	854a                	mv	a0,s2
ffffffffc0202724:	a9aff0ef          	jal	ffffffffc02019be <page_insert>
ffffffffc0202728:	ed11                	bnez	a0,ffffffffc0202744 <pgdir_alloc_page+0x44>
        if (swap_init_ok) {
ffffffffc020272a:	0000f797          	auipc	a5,0xf
ffffffffc020272e:	e167a783          	lw	a5,-490(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc0202732:	e79d                	bnez	a5,ffffffffc0202760 <pgdir_alloc_page+0x60>
}
ffffffffc0202734:	70a2                	ld	ra,40(sp)
ffffffffc0202736:	8522                	mv	a0,s0
ffffffffc0202738:	7402                	ld	s0,32(sp)
ffffffffc020273a:	64e2                	ld	s1,24(sp)
ffffffffc020273c:	6942                	ld	s2,16(sp)
ffffffffc020273e:	69a2                	ld	s3,8(sp)
ffffffffc0202740:	6145                	add	sp,sp,48
ffffffffc0202742:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202744:	100027f3          	csrr	a5,sstatus
ffffffffc0202748:	8b89                	and	a5,a5,2
ffffffffc020274a:	eba9                	bnez	a5,ffffffffc020279c <pgdir_alloc_page+0x9c>
    { pmm_manager->free_pages(base, n); }
ffffffffc020274c:	0000f797          	auipc	a5,0xf
ffffffffc0202750:	dc47b783          	ld	a5,-572(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0202754:	739c                	ld	a5,32(a5)
ffffffffc0202756:	4585                	li	a1,1
ffffffffc0202758:	8522                	mv	a0,s0
ffffffffc020275a:	9782                	jalr	a5
            return NULL;
ffffffffc020275c:	4401                	li	s0,0
ffffffffc020275e:	bfd9                	j	ffffffffc0202734 <pgdir_alloc_page+0x34>
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202760:	4681                	li	a3,0
ffffffffc0202762:	8622                	mv	a2,s0
ffffffffc0202764:	85a6                	mv	a1,s1
ffffffffc0202766:	0000f517          	auipc	a0,0xf
ffffffffc020276a:	e0253503          	ld	a0,-510(a0) # ffffffffc0211568 <check_mm_struct>
ffffffffc020276e:	09d000ef          	jal	ffffffffc020300a <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202772:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202774:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0202776:	4785                	li	a5,1
ffffffffc0202778:	faf70ee3          	beq	a4,a5,ffffffffc0202734 <pgdir_alloc_page+0x34>
ffffffffc020277c:	00003697          	auipc	a3,0x3
ffffffffc0202780:	e7c68693          	add	a3,a3,-388 # ffffffffc02055f8 <etext+0x1284>
ffffffffc0202784:	00002617          	auipc	a2,0x2
ffffffffc0202788:	4cc60613          	add	a2,a2,1228 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020278c:	17a00593          	li	a1,378
ffffffffc0202790:	00003517          	auipc	a0,0x3
ffffffffc0202794:	8f050513          	add	a0,a0,-1808 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202798:	bc9fd0ef          	jal	ffffffffc0200360 <__panic>
        intr_disable();
ffffffffc020279c:	d1dfd0ef          	jal	ffffffffc02004b8 <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc02027a0:	0000f797          	auipc	a5,0xf
ffffffffc02027a4:	d707b783          	ld	a5,-656(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02027a8:	739c                	ld	a5,32(a5)
ffffffffc02027aa:	8522                	mv	a0,s0
ffffffffc02027ac:	4585                	li	a1,1
ffffffffc02027ae:	9782                	jalr	a5
            return NULL;
ffffffffc02027b0:	4401                	li	s0,0
        intr_enable();
ffffffffc02027b2:	d01fd0ef          	jal	ffffffffc02004b2 <intr_enable>
ffffffffc02027b6:	bfbd                	j	ffffffffc0202734 <pgdir_alloc_page+0x34>

ffffffffc02027b8 <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc02027b8:	1141                	add	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027ba:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc02027bc:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027be:	fff50713          	add	a4,a0,-1
ffffffffc02027c2:	17f9                	add	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc02027c4:	06e7e363          	bltu	a5,a4,ffffffffc020282a <kmalloc+0x72>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02027c8:	6785                	lui	a5,0x1
ffffffffc02027ca:	17fd                	add	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02027cc:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc02027ce:	8131                	srl	a0,a0,0xc
ffffffffc02027d0:	dc3fe0ef          	jal	ffffffffc0201592 <alloc_pages>
    assert(base != NULL);
ffffffffc02027d4:	c941                	beqz	a0,ffffffffc0202864 <kmalloc+0xac>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02027d6:	f8e397b7          	lui	a5,0xf8e39
ffffffffc02027da:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc02027de:	07b2                	sll	a5,a5,0xc
ffffffffc02027e0:	e3978793          	add	a5,a5,-455
ffffffffc02027e4:	07b2                	sll	a5,a5,0xc
ffffffffc02027e6:	0000f717          	auipc	a4,0xf
ffffffffc02027ea:	d5273703          	ld	a4,-686(a4) # ffffffffc0211538 <pages>
ffffffffc02027ee:	e3978793          	add	a5,a5,-455
ffffffffc02027f2:	8d19                	sub	a0,a0,a4
ffffffffc02027f4:	07b2                	sll	a5,a5,0xc
ffffffffc02027f6:	e3978793          	add	a5,a5,-455
ffffffffc02027fa:	850d                	sra	a0,a0,0x3
ffffffffc02027fc:	02f50533          	mul	a0,a0,a5
ffffffffc0202800:	000807b7          	lui	a5,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202804:	0000f717          	auipc	a4,0xf
ffffffffc0202808:	d2c73703          	ld	a4,-724(a4) # ffffffffc0211530 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020280c:	953e                	add	a0,a0,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020280e:	00c51793          	sll	a5,a0,0xc
ffffffffc0202812:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202814:	0532                	sll	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202816:	02e7fa63          	bgeu	a5,a4,ffffffffc020284a <kmalloc+0x92>
    ptr = page2kva(base);
    return ptr;
}
ffffffffc020281a:	60a2                	ld	ra,8(sp)
ffffffffc020281c:	0000f797          	auipc	a5,0xf
ffffffffc0202820:	d0c7b783          	ld	a5,-756(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc0202824:	953e                	add	a0,a0,a5
ffffffffc0202826:	0141                	add	sp,sp,16
ffffffffc0202828:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020282a:	00003697          	auipc	a3,0x3
ffffffffc020282e:	de668693          	add	a3,a3,-538 # ffffffffc0205610 <etext+0x129c>
ffffffffc0202832:	00002617          	auipc	a2,0x2
ffffffffc0202836:	41e60613          	add	a2,a2,1054 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020283a:	1f000593          	li	a1,496
ffffffffc020283e:	00003517          	auipc	a0,0x3
ffffffffc0202842:	84250513          	add	a0,a0,-1982 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202846:	b1bfd0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc020284a:	86aa                	mv	a3,a0
ffffffffc020284c:	00003617          	auipc	a2,0x3
ffffffffc0202850:	80c60613          	add	a2,a2,-2036 # ffffffffc0205058 <etext+0xce4>
ffffffffc0202854:	06a00593          	li	a1,106
ffffffffc0202858:	00002517          	auipc	a0,0x2
ffffffffc020285c:	7c850513          	add	a0,a0,1992 # ffffffffc0205020 <etext+0xcac>
ffffffffc0202860:	b01fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(base != NULL);
ffffffffc0202864:	00003697          	auipc	a3,0x3
ffffffffc0202868:	dcc68693          	add	a3,a3,-564 # ffffffffc0205630 <etext+0x12bc>
ffffffffc020286c:	00002617          	auipc	a2,0x2
ffffffffc0202870:	3e460613          	add	a2,a2,996 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202874:	1f300593          	li	a1,499
ffffffffc0202878:	00003517          	auipc	a0,0x3
ffffffffc020287c:	80850513          	add	a0,a0,-2040 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202880:	ae1fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0202884 <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc0202884:	1101                	add	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202886:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc0202888:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020288a:	fff58713          	add	a4,a1,-1
ffffffffc020288e:	17f9                	add	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc0202890:	0ae7ee63          	bltu	a5,a4,ffffffffc020294c <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc0202894:	cd41                	beqz	a0,ffffffffc020292c <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc0202896:	6785                	lui	a5,0x1
ffffffffc0202898:	17fd                	add	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020289a:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc020289c:	c02007b7          	lui	a5,0xc0200
ffffffffc02028a0:	81b1                	srl	a1,a1,0xc
ffffffffc02028a2:	06f56863          	bltu	a0,a5,ffffffffc0202912 <kfree+0x8e>
ffffffffc02028a6:	0000f797          	auipc	a5,0xf
ffffffffc02028aa:	c827b783          	ld	a5,-894(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc02028ae:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02028b0:	8131                	srl	a0,a0,0xc
ffffffffc02028b2:	0000f797          	auipc	a5,0xf
ffffffffc02028b6:	c7e7b783          	ld	a5,-898(a5) # ffffffffc0211530 <npage>
ffffffffc02028ba:	04f57a63          	bgeu	a0,a5,ffffffffc020290e <kfree+0x8a>
    return &pages[PPN(pa) - nbase];
ffffffffc02028be:	fff807b7          	lui	a5,0xfff80
ffffffffc02028c2:	953e                	add	a0,a0,a5
ffffffffc02028c4:	00351793          	sll	a5,a0,0x3
ffffffffc02028c8:	97aa                	add	a5,a5,a0
ffffffffc02028ca:	078e                	sll	a5,a5,0x3
ffffffffc02028cc:	0000f517          	auipc	a0,0xf
ffffffffc02028d0:	c6c53503          	ld	a0,-916(a0) # ffffffffc0211538 <pages>
ffffffffc02028d4:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02028d6:	100027f3          	csrr	a5,sstatus
ffffffffc02028da:	8b89                	and	a5,a5,2
ffffffffc02028dc:	eb89                	bnez	a5,ffffffffc02028ee <kfree+0x6a>
    { pmm_manager->free_pages(base, n); }
ffffffffc02028de:	0000f797          	auipc	a5,0xf
ffffffffc02028e2:	c327b783          	ld	a5,-974(a5) # ffffffffc0211510 <pmm_manager>
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc02028e6:	60e2                	ld	ra,24(sp)
    { pmm_manager->free_pages(base, n); }
ffffffffc02028e8:	739c                	ld	a5,32(a5)
}
ffffffffc02028ea:	6105                	add	sp,sp,32
    { pmm_manager->free_pages(base, n); }
ffffffffc02028ec:	8782                	jr	a5
        intr_disable();
ffffffffc02028ee:	e42a                	sd	a0,8(sp)
ffffffffc02028f0:	e02e                	sd	a1,0(sp)
ffffffffc02028f2:	bc7fd0ef          	jal	ffffffffc02004b8 <intr_disable>
ffffffffc02028f6:	0000f797          	auipc	a5,0xf
ffffffffc02028fa:	c1a7b783          	ld	a5,-998(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02028fe:	6582                	ld	a1,0(sp)
ffffffffc0202900:	6522                	ld	a0,8(sp)
ffffffffc0202902:	739c                	ld	a5,32(a5)
ffffffffc0202904:	9782                	jalr	a5
}
ffffffffc0202906:	60e2                	ld	ra,24(sp)
ffffffffc0202908:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc020290a:	ba9fd06f          	j	ffffffffc02004b2 <intr_enable>
ffffffffc020290e:	c4dfe0ef          	jal	ffffffffc020155a <pa2page.part.0>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202912:	86aa                	mv	a3,a0
ffffffffc0202914:	00003617          	auipc	a2,0x3
ffffffffc0202918:	80460613          	add	a2,a2,-2044 # ffffffffc0205118 <etext+0xda4>
ffffffffc020291c:	06c00593          	li	a1,108
ffffffffc0202920:	00002517          	auipc	a0,0x2
ffffffffc0202924:	70050513          	add	a0,a0,1792 # ffffffffc0205020 <etext+0xcac>
ffffffffc0202928:	a39fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(ptr != NULL);
ffffffffc020292c:	00003697          	auipc	a3,0x3
ffffffffc0202930:	d1468693          	add	a3,a3,-748 # ffffffffc0205640 <etext+0x12cc>
ffffffffc0202934:	00002617          	auipc	a2,0x2
ffffffffc0202938:	31c60613          	add	a2,a2,796 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020293c:	1fa00593          	li	a1,506
ffffffffc0202940:	00002517          	auipc	a0,0x2
ffffffffc0202944:	74050513          	add	a0,a0,1856 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202948:	a19fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020294c:	00003697          	auipc	a3,0x3
ffffffffc0202950:	cc468693          	add	a3,a3,-828 # ffffffffc0205610 <etext+0x129c>
ffffffffc0202954:	00002617          	auipc	a2,0x2
ffffffffc0202958:	2fc60613          	add	a2,a2,764 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020295c:	1f900593          	li	a1,505
ffffffffc0202960:	00002517          	auipc	a0,0x2
ffffffffc0202964:	72050513          	add	a0,a0,1824 # ffffffffc0205080 <etext+0xd0c>
ffffffffc0202968:	9f9fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020296c <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020296c:	7135                	add	sp,sp,-160
ffffffffc020296e:	ed06                	sd	ra,152(sp)
     swapfs_init();
ffffffffc0202970:	3c4010ef          	jal	ffffffffc0203d34 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0202974:	0000f697          	auipc	a3,0xf
ffffffffc0202978:	bd46b683          	ld	a3,-1068(a3) # ffffffffc0211548 <max_swap_offset>
ffffffffc020297c:	010007b7          	lui	a5,0x1000
ffffffffc0202980:	ff968713          	add	a4,a3,-7
ffffffffc0202984:	17e1                	add	a5,a5,-8 # fffff8 <kern_entry-0xffffffffbf200008>
ffffffffc0202986:	40e7e463          	bltu	a5,a4,ffffffffc0202d8e <swap_init+0x422>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc020298a:	00007797          	auipc	a5,0x7
ffffffffc020298e:	67678793          	add	a5,a5,1654 # ffffffffc020a000 <swap_manager_clock>
     int r = sm->init();
ffffffffc0202992:	6798                	ld	a4,8(a5)
ffffffffc0202994:	fcce                	sd	s3,120(sp)
ffffffffc0202996:	f0da                	sd	s6,96(sp)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc0202998:	0000fb17          	auipc	s6,0xf
ffffffffc020299c:	bb8b0b13          	add	s6,s6,-1096 # ffffffffc0211550 <sm>
ffffffffc02029a0:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc02029a4:	9702                	jalr	a4
ffffffffc02029a6:	89aa                	mv	s3,a0
     
     if (r == 0)
ffffffffc02029a8:	c519                	beqz	a0,ffffffffc02029b6 <swap_init+0x4a>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02029aa:	60ea                	ld	ra,152(sp)
ffffffffc02029ac:	7b06                	ld	s6,96(sp)
ffffffffc02029ae:	854e                	mv	a0,s3
ffffffffc02029b0:	79e6                	ld	s3,120(sp)
ffffffffc02029b2:	610d                	add	sp,sp,160
ffffffffc02029b4:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02029b6:	000b3783          	ld	a5,0(s6)
ffffffffc02029ba:	00003517          	auipc	a0,0x3
ffffffffc02029be:	cc650513          	add	a0,a0,-826 # ffffffffc0205680 <etext+0x130c>
ffffffffc02029c2:	e922                	sd	s0,144(sp)
ffffffffc02029c4:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02029c6:	4785                	li	a5,1
ffffffffc02029c8:	e526                	sd	s1,136(sp)
ffffffffc02029ca:	e0ea                	sd	s10,64(sp)
ffffffffc02029cc:	0000f717          	auipc	a4,0xf
ffffffffc02029d0:	b6f72a23          	sw	a5,-1164(a4) # ffffffffc0211540 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02029d4:	e14a                	sd	s2,128(sp)
ffffffffc02029d6:	f8d2                	sd	s4,112(sp)
ffffffffc02029d8:	f4d6                	sd	s5,104(sp)
ffffffffc02029da:	ecde                	sd	s7,88(sp)
ffffffffc02029dc:	e8e2                	sd	s8,80(sp)
ffffffffc02029de:	e4e6                	sd	s9,72(sp)
ffffffffc02029e0:	fc6e                	sd	s11,56(sp)
    return listelm->next;
ffffffffc02029e2:	0000e497          	auipc	s1,0xe
ffffffffc02029e6:	65e48493          	add	s1,s1,1630 # ffffffffc0211040 <free_area>
ffffffffc02029ea:	ed0fd0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02029ee:	649c                	ld	a5,8(s1)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc02029f0:	4401                	li	s0,0
ffffffffc02029f2:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02029f4:	2e978363          	beq	a5,s1,ffffffffc0202cda <swap_init+0x36e>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02029f8:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02029fc:	8b09                	and	a4,a4,2
ffffffffc02029fe:	2e070063          	beqz	a4,ffffffffc0202cde <swap_init+0x372>
        count ++, total += p->property;
ffffffffc0202a02:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202a06:	679c                	ld	a5,8(a5)
ffffffffc0202a08:	2d05                	addw	s10,s10,1
ffffffffc0202a0a:	9c39                	addw	s0,s0,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a0c:	fe9796e3          	bne	a5,s1,ffffffffc02029f8 <swap_init+0x8c>
     }
     assert(total == nr_free_pages());
ffffffffc0202a10:	8922                	mv	s2,s0
ffffffffc0202a12:	c51fe0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc0202a16:	4b251463          	bne	a0,s2,ffffffffc0202ebe <swap_init+0x552>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202a1a:	8622                	mv	a2,s0
ffffffffc0202a1c:	85ea                	mv	a1,s10
ffffffffc0202a1e:	00003517          	auipc	a0,0x3
ffffffffc0202a22:	c7a50513          	add	a0,a0,-902 # ffffffffc0205698 <etext+0x1324>
ffffffffc0202a26:	e94fd0ef          	jal	ffffffffc02000ba <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202a2a:	2b7000ef          	jal	ffffffffc02034e0 <mm_create>
ffffffffc0202a2e:	ec2a                	sd	a0,24(sp)
     assert(mm != NULL);
ffffffffc0202a30:	56050763          	beqz	a0,ffffffffc0202f9e <swap_init+0x632>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202a34:	0000f797          	auipc	a5,0xf
ffffffffc0202a38:	b3478793          	add	a5,a5,-1228 # ffffffffc0211568 <check_mm_struct>
ffffffffc0202a3c:	6398                	ld	a4,0(a5)
ffffffffc0202a3e:	58071063          	bnez	a4,ffffffffc0202fbe <swap_init+0x652>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a42:	0000f697          	auipc	a3,0xf
ffffffffc0202a46:	ade6b683          	ld	a3,-1314(a3) # ffffffffc0211520 <boot_pgdir>
     check_mm_struct = mm;
ffffffffc0202a4a:	6662                	ld	a2,24(sp)
     assert(pgdir[0] == 0);
ffffffffc0202a4c:	6298                	ld	a4,0(a3)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a4e:	e836                	sd	a3,16(sp)
     check_mm_struct = mm;
ffffffffc0202a50:	e390                	sd	a2,0(a5)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a52:	ee14                	sd	a3,24(a2)
     assert(pgdir[0] == 0);
ffffffffc0202a54:	40071563          	bnez	a4,ffffffffc0202e5e <swap_init+0x4f2>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202a58:	6599                	lui	a1,0x6
ffffffffc0202a5a:	460d                	li	a2,3
ffffffffc0202a5c:	6505                	lui	a0,0x1
ffffffffc0202a5e:	2cb000ef          	jal	ffffffffc0203528 <vma_create>
ffffffffc0202a62:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202a64:	40050d63          	beqz	a0,ffffffffc0202e7e <swap_init+0x512>

     insert_vma_struct(mm, vma);
ffffffffc0202a68:	6962                	ld	s2,24(sp)
ffffffffc0202a6a:	854a                	mv	a0,s2
ffffffffc0202a6c:	32b000ef          	jal	ffffffffc0203596 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202a70:	00003517          	auipc	a0,0x3
ffffffffc0202a74:	c9850513          	add	a0,a0,-872 # ffffffffc0205708 <etext+0x1394>
ffffffffc0202a78:	e42fd0ef          	jal	ffffffffc02000ba <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202a7c:	01893503          	ld	a0,24(s2)
ffffffffc0202a80:	4605                	li	a2,1
ffffffffc0202a82:	6585                	lui	a1,0x1
ffffffffc0202a84:	c19fe0ef          	jal	ffffffffc020169c <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202a88:	40050b63          	beqz	a0,ffffffffc0202e9e <swap_init+0x532>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202a8c:	00003517          	auipc	a0,0x3
ffffffffc0202a90:	ccc50513          	add	a0,a0,-820 # ffffffffc0205758 <etext+0x13e4>
ffffffffc0202a94:	0000e917          	auipc	s2,0xe
ffffffffc0202a98:	5e490913          	add	s2,s2,1508 # ffffffffc0211078 <check_rp>
ffffffffc0202a9c:	e1efd0ef          	jal	ffffffffc02000ba <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202aa0:	0000ea17          	auipc	s4,0xe
ffffffffc0202aa4:	5f8a0a13          	add	s4,s4,1528 # ffffffffc0211098 <swap_out_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202aa8:	8c4a                	mv	s8,s2
          check_rp[i] = alloc_page();
ffffffffc0202aaa:	4505                	li	a0,1
ffffffffc0202aac:	ae7fe0ef          	jal	ffffffffc0201592 <alloc_pages>
ffffffffc0202ab0:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0202ab4:	2a050d63          	beqz	a0,ffffffffc0202d6e <swap_init+0x402>
ffffffffc0202ab8:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202aba:	8b89                	and	a5,a5,2
ffffffffc0202abc:	28079963          	bnez	a5,ffffffffc0202d4e <swap_init+0x3e2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ac0:	0c21                	add	s8,s8,8
ffffffffc0202ac2:	ff4c14e3          	bne	s8,s4,ffffffffc0202aaa <swap_init+0x13e>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202ac6:	609c                	ld	a5,0(s1)
ffffffffc0202ac8:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc0202acc:	e084                	sd	s1,0(s1)
ffffffffc0202ace:	f03e                	sd	a5,32(sp)
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
ffffffffc0202ad0:	489c                	lw	a5,16(s1)
ffffffffc0202ad2:	e484                	sd	s1,8(s1)
     nr_free = 0;
ffffffffc0202ad4:	0000ec17          	auipc	s8,0xe
ffffffffc0202ad8:	5a4c0c13          	add	s8,s8,1444 # ffffffffc0211078 <check_rp>
     unsigned int nr_free_store = nr_free;
ffffffffc0202adc:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0202ade:	0000e797          	auipc	a5,0xe
ffffffffc0202ae2:	5607a923          	sw	zero,1394(a5) # ffffffffc0211050 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202ae6:	000c3503          	ld	a0,0(s8)
ffffffffc0202aea:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202aec:	0c21                	add	s8,s8,8
        free_pages(check_rp[i],1);
ffffffffc0202aee:	b35fe0ef          	jal	ffffffffc0201622 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202af2:	ff4c1ae3          	bne	s8,s4,ffffffffc0202ae6 <swap_init+0x17a>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202af6:	0104ac03          	lw	s8,16(s1)
ffffffffc0202afa:	4791                	li	a5,4
ffffffffc0202afc:	4efc1163          	bne	s8,a5,ffffffffc0202fde <swap_init+0x672>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202b00:	00003517          	auipc	a0,0x3
ffffffffc0202b04:	ce050513          	add	a0,a0,-800 # ffffffffc02057e0 <etext+0x146c>
ffffffffc0202b08:	db2fd0ef          	jal	ffffffffc02000ba <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202b0c:	0000f797          	auipc	a5,0xf
ffffffffc0202b10:	a407aa23          	sw	zero,-1452(a5) # ffffffffc0211560 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202b14:	6785                	lui	a5,0x1
ffffffffc0202b16:	4529                	li	a0,10
ffffffffc0202b18:	00a78023          	sb	a0,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202b1c:	0000f597          	auipc	a1,0xf
ffffffffc0202b20:	a445a583          	lw	a1,-1468(a1) # ffffffffc0211560 <pgfault_num>
ffffffffc0202b24:	4605                	li	a2,1
ffffffffc0202b26:	0000f797          	auipc	a5,0xf
ffffffffc0202b2a:	a3a78793          	add	a5,a5,-1478 # ffffffffc0211560 <pgfault_num>
ffffffffc0202b2e:	42c59863          	bne	a1,a2,ffffffffc0202f5e <swap_init+0x5f2>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202b32:	6605                	lui	a2,0x1
ffffffffc0202b34:	00a60823          	sb	a0,16(a2) # 1010 <kern_entry-0xffffffffc01feff0>
     assert(pgfault_num==1);
ffffffffc0202b38:	4388                	lw	a0,0(a5)
ffffffffc0202b3a:	44b51263          	bne	a0,a1,ffffffffc0202f7e <swap_init+0x612>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202b3e:	6609                	lui	a2,0x2
ffffffffc0202b40:	45ad                	li	a1,11
ffffffffc0202b42:	00b60023          	sb	a1,0(a2) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202b46:	4390                	lw	a2,0(a5)
ffffffffc0202b48:	4809                	li	a6,2
ffffffffc0202b4a:	0006051b          	sext.w	a0,a2
ffffffffc0202b4e:	39061863          	bne	a2,a6,ffffffffc0202ede <swap_init+0x572>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202b52:	6609                	lui	a2,0x2
ffffffffc0202b54:	00b60823          	sb	a1,16(a2) # 2010 <kern_entry-0xffffffffc01fdff0>
     assert(pgfault_num==2);
ffffffffc0202b58:	438c                	lw	a1,0(a5)
ffffffffc0202b5a:	3aa59263          	bne	a1,a0,ffffffffc0202efe <swap_init+0x592>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202b5e:	660d                	lui	a2,0x3
ffffffffc0202b60:	45b1                	li	a1,12
ffffffffc0202b62:	00b60023          	sb	a1,0(a2) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202b66:	4390                	lw	a2,0(a5)
ffffffffc0202b68:	480d                	li	a6,3
ffffffffc0202b6a:	0006051b          	sext.w	a0,a2
ffffffffc0202b6e:	3b061863          	bne	a2,a6,ffffffffc0202f1e <swap_init+0x5b2>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202b72:	660d                	lui	a2,0x3
ffffffffc0202b74:	00b60823          	sb	a1,16(a2) # 3010 <kern_entry-0xffffffffc01fcff0>
     assert(pgfault_num==3);
ffffffffc0202b78:	438c                	lw	a1,0(a5)
ffffffffc0202b7a:	3ca59263          	bne	a1,a0,ffffffffc0202f3e <swap_init+0x5d2>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202b7e:	6611                	lui	a2,0x4
ffffffffc0202b80:	45b5                	li	a1,13
ffffffffc0202b82:	00b60023          	sb	a1,0(a2) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202b86:	4390                	lw	a2,0(a5)
ffffffffc0202b88:	0006051b          	sext.w	a0,a2
ffffffffc0202b8c:	25861963          	bne	a2,s8,ffffffffc0202dde <swap_init+0x472>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202b90:	6611                	lui	a2,0x4
ffffffffc0202b92:	00b60823          	sb	a1,16(a2) # 4010 <kern_entry-0xffffffffc01fbff0>
     assert(pgfault_num==4);
ffffffffc0202b96:	439c                	lw	a5,0(a5)
ffffffffc0202b98:	26a79363          	bne	a5,a0,ffffffffc0202dfe <swap_init+0x492>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202b9c:	489c                	lw	a5,16(s1)
ffffffffc0202b9e:	28079063          	bnez	a5,ffffffffc0202e1e <swap_init+0x4b2>
ffffffffc0202ba2:	0000e797          	auipc	a5,0xe
ffffffffc0202ba6:	51e78793          	add	a5,a5,1310 # ffffffffc02110c0 <swap_in_seq_no>
ffffffffc0202baa:	0000e617          	auipc	a2,0xe
ffffffffc0202bae:	4ee60613          	add	a2,a2,1262 # ffffffffc0211098 <swap_out_seq_no>
ffffffffc0202bb2:	0000e517          	auipc	a0,0xe
ffffffffc0202bb6:	53650513          	add	a0,a0,1334 # ffffffffc02110e8 <pra_list_head>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202bba:	55fd                	li	a1,-1
ffffffffc0202bbc:	c38c                	sw	a1,0(a5)
ffffffffc0202bbe:	c20c                	sw	a1,0(a2)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202bc0:	0791                	add	a5,a5,4
ffffffffc0202bc2:	0611                	add	a2,a2,4
ffffffffc0202bc4:	fea79ce3          	bne	a5,a0,ffffffffc0202bbc <swap_init+0x250>
ffffffffc0202bc8:	0000e817          	auipc	a6,0xe
ffffffffc0202bcc:	49080813          	add	a6,a6,1168 # ffffffffc0211058 <check_ptep>
ffffffffc0202bd0:	0000e897          	auipc	a7,0xe
ffffffffc0202bd4:	4a888893          	add	a7,a7,1192 # ffffffffc0211078 <check_rp>
ffffffffc0202bd8:	6a85                	lui	s5,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202bda:	0000fb97          	auipc	s7,0xf
ffffffffc0202bde:	956b8b93          	add	s7,s7,-1706 # ffffffffc0211530 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202be2:	0000fc17          	auipc	s8,0xf
ffffffffc0202be6:	956c0c13          	add	s8,s8,-1706 # ffffffffc0211538 <pages>
ffffffffc0202bea:	00003c97          	auipc	s9,0x3
ffffffffc0202bee:	54ec8c93          	add	s9,s9,1358 # ffffffffc0206138 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202bf2:	6542                	ld	a0,16(sp)
         check_ptep[i]=0;
ffffffffc0202bf4:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202bf8:	4601                	li	a2,0
ffffffffc0202bfa:	85d6                	mv	a1,s5
ffffffffc0202bfc:	e446                	sd	a7,8(sp)
         check_ptep[i]=0;
ffffffffc0202bfe:	e042                	sd	a6,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c00:	a9dfe0ef          	jal	ffffffffc020169c <get_pte>
ffffffffc0202c04:	6802                	ld	a6,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202c06:	68a2                	ld	a7,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c08:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL);
ffffffffc0202c0c:	1a050963          	beqz	a0,ffffffffc0202dbe <swap_init+0x452>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202c10:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202c12:	0017f613          	and	a2,a5,1
ffffffffc0202c16:	10060463          	beqz	a2,ffffffffc0202d1e <swap_init+0x3b2>
    if (PPN(pa) >= npage) {
ffffffffc0202c1a:	000bb603          	ld	a2,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c1e:	078a                	sll	a5,a5,0x2
ffffffffc0202c20:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c22:	10c7fa63          	bgeu	a5,a2,ffffffffc0202d36 <swap_init+0x3ca>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c26:	000cb603          	ld	a2,0(s9)
ffffffffc0202c2a:	000c3503          	ld	a0,0(s8)
ffffffffc0202c2e:	0008bf03          	ld	t5,0(a7)
ffffffffc0202c32:	8f91                	sub	a5,a5,a2
ffffffffc0202c34:	00379613          	sll	a2,a5,0x3
ffffffffc0202c38:	97b2                	add	a5,a5,a2
ffffffffc0202c3a:	078e                	sll	a5,a5,0x3
ffffffffc0202c3c:	6705                	lui	a4,0x1
ffffffffc0202c3e:	97aa                	add	a5,a5,a0
ffffffffc0202c40:	08a1                	add	a7,a7,8
ffffffffc0202c42:	0821                	add	a6,a6,8
ffffffffc0202c44:	9aba                	add	s5,s5,a4
ffffffffc0202c46:	0aff1c63          	bne	t5,a5,ffffffffc0202cfe <swap_init+0x392>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c4a:	6795                	lui	a5,0x5
ffffffffc0202c4c:	fafa93e3          	bne	s5,a5,ffffffffc0202bf2 <swap_init+0x286>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202c50:	00003517          	auipc	a0,0x3
ffffffffc0202c54:	c3850513          	add	a0,a0,-968 # ffffffffc0205888 <etext+0x1514>
ffffffffc0202c58:	c62fd0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = sm->check_swap();
ffffffffc0202c5c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c60:	7f9c                	ld	a5,56(a5)
ffffffffc0202c62:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202c64:	1c051d63          	bnez	a0,ffffffffc0202e3e <swap_init+0x4d2>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202c68:	00093503          	ld	a0,0(s2)
ffffffffc0202c6c:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c6e:	0921                	add	s2,s2,8
         free_pages(check_rp[i],1);
ffffffffc0202c70:	9b3fe0ef          	jal	ffffffffc0201622 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c74:	ff491ae3          	bne	s2,s4,ffffffffc0202c68 <swap_init+0x2fc>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202c78:	6562                	ld	a0,24(sp)
ffffffffc0202c7a:	1ed000ef          	jal	ffffffffc0203666 <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc0202c7e:	77a2                	ld	a5,40(sp)
     free_list = free_list_store;
ffffffffc0202c80:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store;
ffffffffc0202c84:	c89c                	sw	a5,16(s1)
     free_list = free_list_store;
ffffffffc0202c86:	7782                	ld	a5,32(sp)
ffffffffc0202c88:	e09c                	sd	a5,0(s1)

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c8a:	009d8a63          	beq	s11,s1,ffffffffc0202c9e <swap_init+0x332>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202c8e:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc0202c92:	008dbd83          	ld	s11,8(s11)
ffffffffc0202c96:	3d7d                	addw	s10,s10,-1
ffffffffc0202c98:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202c9a:	fe9d9ae3          	bne	s11,s1,ffffffffc0202c8e <swap_init+0x322>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202c9e:	8622                	mv	a2,s0
ffffffffc0202ca0:	85ea                	mv	a1,s10
ffffffffc0202ca2:	00003517          	auipc	a0,0x3
ffffffffc0202ca6:	c1650513          	add	a0,a0,-1002 # ffffffffc02058b8 <etext+0x1544>
ffffffffc0202caa:	c10fd0ef          	jal	ffffffffc02000ba <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202cae:	00003517          	auipc	a0,0x3
ffffffffc0202cb2:	c2a50513          	add	a0,a0,-982 # ffffffffc02058d8 <etext+0x1564>
ffffffffc0202cb6:	c04fd0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc0202cba:	60ea                	ld	ra,152(sp)
     cprintf("check_swap() succeeded!\n");
ffffffffc0202cbc:	644a                	ld	s0,144(sp)
ffffffffc0202cbe:	64aa                	ld	s1,136(sp)
ffffffffc0202cc0:	690a                	ld	s2,128(sp)
ffffffffc0202cc2:	7a46                	ld	s4,112(sp)
ffffffffc0202cc4:	7aa6                	ld	s5,104(sp)
ffffffffc0202cc6:	6be6                	ld	s7,88(sp)
ffffffffc0202cc8:	6c46                	ld	s8,80(sp)
ffffffffc0202cca:	6ca6                	ld	s9,72(sp)
ffffffffc0202ccc:	6d06                	ld	s10,64(sp)
ffffffffc0202cce:	7de2                	ld	s11,56(sp)
}
ffffffffc0202cd0:	7b06                	ld	s6,96(sp)
ffffffffc0202cd2:	854e                	mv	a0,s3
ffffffffc0202cd4:	79e6                	ld	s3,120(sp)
ffffffffc0202cd6:	610d                	add	sp,sp,160
ffffffffc0202cd8:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cda:	4901                	li	s2,0
ffffffffc0202cdc:	bb1d                	j	ffffffffc0202a12 <swap_init+0xa6>
        assert(PageProperty(p));
ffffffffc0202cde:	00002697          	auipc	a3,0x2
ffffffffc0202ce2:	f6268693          	add	a3,a3,-158 # ffffffffc0204c40 <etext+0x8cc>
ffffffffc0202ce6:	00002617          	auipc	a2,0x2
ffffffffc0202cea:	f6a60613          	add	a2,a2,-150 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202cee:	0ba00593          	li	a1,186
ffffffffc0202cf2:	00003517          	auipc	a0,0x3
ffffffffc0202cf6:	97e50513          	add	a0,a0,-1666 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202cfa:	e66fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202cfe:	00003697          	auipc	a3,0x3
ffffffffc0202d02:	b6268693          	add	a3,a3,-1182 # ffffffffc0205860 <etext+0x14ec>
ffffffffc0202d06:	00002617          	auipc	a2,0x2
ffffffffc0202d0a:	f4a60613          	add	a2,a2,-182 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202d0e:	0fa00593          	li	a1,250
ffffffffc0202d12:	00003517          	auipc	a0,0x3
ffffffffc0202d16:	95e50513          	add	a0,a0,-1698 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202d1a:	e46fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202d1e:	00002617          	auipc	a2,0x2
ffffffffc0202d22:	31260613          	add	a2,a2,786 # ffffffffc0205030 <etext+0xcbc>
ffffffffc0202d26:	07000593          	li	a1,112
ffffffffc0202d2a:	00002517          	auipc	a0,0x2
ffffffffc0202d2e:	2f650513          	add	a0,a0,758 # ffffffffc0205020 <etext+0xcac>
ffffffffc0202d32:	e2efd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202d36:	00002617          	auipc	a2,0x2
ffffffffc0202d3a:	2ca60613          	add	a2,a2,714 # ffffffffc0205000 <etext+0xc8c>
ffffffffc0202d3e:	06500593          	li	a1,101
ffffffffc0202d42:	00002517          	auipc	a0,0x2
ffffffffc0202d46:	2de50513          	add	a0,a0,734 # ffffffffc0205020 <etext+0xcac>
ffffffffc0202d4a:	e16fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202d4e:	00003697          	auipc	a3,0x3
ffffffffc0202d52:	a4a68693          	add	a3,a3,-1462 # ffffffffc0205798 <etext+0x1424>
ffffffffc0202d56:	00002617          	auipc	a2,0x2
ffffffffc0202d5a:	efa60613          	add	a2,a2,-262 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202d5e:	0db00593          	li	a1,219
ffffffffc0202d62:	00003517          	auipc	a0,0x3
ffffffffc0202d66:	90e50513          	add	a0,a0,-1778 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202d6a:	df6fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202d6e:	00003697          	auipc	a3,0x3
ffffffffc0202d72:	a1268693          	add	a3,a3,-1518 # ffffffffc0205780 <etext+0x140c>
ffffffffc0202d76:	00002617          	auipc	a2,0x2
ffffffffc0202d7a:	eda60613          	add	a2,a2,-294 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202d7e:	0da00593          	li	a1,218
ffffffffc0202d82:	00003517          	auipc	a0,0x3
ffffffffc0202d86:	8ee50513          	add	a0,a0,-1810 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202d8a:	dd6fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202d8e:	00003617          	auipc	a2,0x3
ffffffffc0202d92:	8c260613          	add	a2,a2,-1854 # ffffffffc0205650 <etext+0x12dc>
ffffffffc0202d96:	02700593          	li	a1,39
ffffffffc0202d9a:	00003517          	auipc	a0,0x3
ffffffffc0202d9e:	8d650513          	add	a0,a0,-1834 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202da2:	e922                	sd	s0,144(sp)
ffffffffc0202da4:	e526                	sd	s1,136(sp)
ffffffffc0202da6:	e14a                	sd	s2,128(sp)
ffffffffc0202da8:	fcce                	sd	s3,120(sp)
ffffffffc0202daa:	f8d2                	sd	s4,112(sp)
ffffffffc0202dac:	f4d6                	sd	s5,104(sp)
ffffffffc0202dae:	f0da                	sd	s6,96(sp)
ffffffffc0202db0:	ecde                	sd	s7,88(sp)
ffffffffc0202db2:	e8e2                	sd	s8,80(sp)
ffffffffc0202db4:	e4e6                	sd	s9,72(sp)
ffffffffc0202db6:	e0ea                	sd	s10,64(sp)
ffffffffc0202db8:	fc6e                	sd	s11,56(sp)
ffffffffc0202dba:	da6fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202dbe:	00003697          	auipc	a3,0x3
ffffffffc0202dc2:	a8a68693          	add	a3,a3,-1398 # ffffffffc0205848 <etext+0x14d4>
ffffffffc0202dc6:	00002617          	auipc	a2,0x2
ffffffffc0202dca:	e8a60613          	add	a2,a2,-374 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202dce:	0f900593          	li	a1,249
ffffffffc0202dd2:	00003517          	auipc	a0,0x3
ffffffffc0202dd6:	89e50513          	add	a0,a0,-1890 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202dda:	d86fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202dde:	00003697          	auipc	a3,0x3
ffffffffc0202de2:	a5a68693          	add	a3,a3,-1446 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0202de6:	00002617          	auipc	a2,0x2
ffffffffc0202dea:	e6a60613          	add	a2,a2,-406 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202dee:	09d00593          	li	a1,157
ffffffffc0202df2:	00003517          	auipc	a0,0x3
ffffffffc0202df6:	87e50513          	add	a0,a0,-1922 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202dfa:	d66fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202dfe:	00003697          	auipc	a3,0x3
ffffffffc0202e02:	a3a68693          	add	a3,a3,-1478 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0202e06:	00002617          	auipc	a2,0x2
ffffffffc0202e0a:	e4a60613          	add	a2,a2,-438 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202e0e:	09f00593          	li	a1,159
ffffffffc0202e12:	00003517          	auipc	a0,0x3
ffffffffc0202e16:	85e50513          	add	a0,a0,-1954 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202e1a:	d46fd0ef          	jal	ffffffffc0200360 <__panic>
     assert( nr_free == 0);         
ffffffffc0202e1e:	00002697          	auipc	a3,0x2
ffffffffc0202e22:	00a68693          	add	a3,a3,10 # ffffffffc0204e28 <etext+0xab4>
ffffffffc0202e26:	00002617          	auipc	a2,0x2
ffffffffc0202e2a:	e2a60613          	add	a2,a2,-470 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202e2e:	0f100593          	li	a1,241
ffffffffc0202e32:	00003517          	auipc	a0,0x3
ffffffffc0202e36:	83e50513          	add	a0,a0,-1986 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202e3a:	d26fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(ret==0);
ffffffffc0202e3e:	00003697          	auipc	a3,0x3
ffffffffc0202e42:	a7268693          	add	a3,a3,-1422 # ffffffffc02058b0 <etext+0x153c>
ffffffffc0202e46:	00002617          	auipc	a2,0x2
ffffffffc0202e4a:	e0a60613          	add	a2,a2,-502 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202e4e:	10000593          	li	a1,256
ffffffffc0202e52:	00003517          	auipc	a0,0x3
ffffffffc0202e56:	81e50513          	add	a0,a0,-2018 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202e5a:	d06fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202e5e:	00003697          	auipc	a3,0x3
ffffffffc0202e62:	88a68693          	add	a3,a3,-1910 # ffffffffc02056e8 <etext+0x1374>
ffffffffc0202e66:	00002617          	auipc	a2,0x2
ffffffffc0202e6a:	dea60613          	add	a2,a2,-534 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202e6e:	0ca00593          	li	a1,202
ffffffffc0202e72:	00002517          	auipc	a0,0x2
ffffffffc0202e76:	7fe50513          	add	a0,a0,2046 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202e7a:	ce6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(vma != NULL);
ffffffffc0202e7e:	00003697          	auipc	a3,0x3
ffffffffc0202e82:	87a68693          	add	a3,a3,-1926 # ffffffffc02056f8 <etext+0x1384>
ffffffffc0202e86:	00002617          	auipc	a2,0x2
ffffffffc0202e8a:	dca60613          	add	a2,a2,-566 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202e8e:	0cd00593          	li	a1,205
ffffffffc0202e92:	00002517          	auipc	a0,0x2
ffffffffc0202e96:	7de50513          	add	a0,a0,2014 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202e9a:	cc6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202e9e:	00003697          	auipc	a3,0x3
ffffffffc0202ea2:	8a268693          	add	a3,a3,-1886 # ffffffffc0205740 <etext+0x13cc>
ffffffffc0202ea6:	00002617          	auipc	a2,0x2
ffffffffc0202eaa:	daa60613          	add	a2,a2,-598 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202eae:	0d500593          	li	a1,213
ffffffffc0202eb2:	00002517          	auipc	a0,0x2
ffffffffc0202eb6:	7be50513          	add	a0,a0,1982 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202eba:	ca6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202ebe:	00002697          	auipc	a3,0x2
ffffffffc0202ec2:	dc268693          	add	a3,a3,-574 # ffffffffc0204c80 <etext+0x90c>
ffffffffc0202ec6:	00002617          	auipc	a2,0x2
ffffffffc0202eca:	d8a60613          	add	a2,a2,-630 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202ece:	0bd00593          	li	a1,189
ffffffffc0202ed2:	00002517          	auipc	a0,0x2
ffffffffc0202ed6:	79e50513          	add	a0,a0,1950 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202eda:	c86fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202ede:	00003697          	auipc	a3,0x3
ffffffffc0202ee2:	93a68693          	add	a3,a3,-1734 # ffffffffc0205818 <etext+0x14a4>
ffffffffc0202ee6:	00002617          	auipc	a2,0x2
ffffffffc0202eea:	d6a60613          	add	a2,a2,-662 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202eee:	09500593          	li	a1,149
ffffffffc0202ef2:	00002517          	auipc	a0,0x2
ffffffffc0202ef6:	77e50513          	add	a0,a0,1918 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202efa:	c66fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202efe:	00003697          	auipc	a3,0x3
ffffffffc0202f02:	91a68693          	add	a3,a3,-1766 # ffffffffc0205818 <etext+0x14a4>
ffffffffc0202f06:	00002617          	auipc	a2,0x2
ffffffffc0202f0a:	d4a60613          	add	a2,a2,-694 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202f0e:	09700593          	li	a1,151
ffffffffc0202f12:	00002517          	auipc	a0,0x2
ffffffffc0202f16:	75e50513          	add	a0,a0,1886 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202f1a:	c46fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202f1e:	00003697          	auipc	a3,0x3
ffffffffc0202f22:	90a68693          	add	a3,a3,-1782 # ffffffffc0205828 <etext+0x14b4>
ffffffffc0202f26:	00002617          	auipc	a2,0x2
ffffffffc0202f2a:	d2a60613          	add	a2,a2,-726 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202f2e:	09900593          	li	a1,153
ffffffffc0202f32:	00002517          	auipc	a0,0x2
ffffffffc0202f36:	73e50513          	add	a0,a0,1854 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202f3a:	c26fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202f3e:	00003697          	auipc	a3,0x3
ffffffffc0202f42:	8ea68693          	add	a3,a3,-1814 # ffffffffc0205828 <etext+0x14b4>
ffffffffc0202f46:	00002617          	auipc	a2,0x2
ffffffffc0202f4a:	d0a60613          	add	a2,a2,-758 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202f4e:	09b00593          	li	a1,155
ffffffffc0202f52:	00002517          	auipc	a0,0x2
ffffffffc0202f56:	71e50513          	add	a0,a0,1822 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202f5a:	c06fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202f5e:	00003697          	auipc	a3,0x3
ffffffffc0202f62:	8aa68693          	add	a3,a3,-1878 # ffffffffc0205808 <etext+0x1494>
ffffffffc0202f66:	00002617          	auipc	a2,0x2
ffffffffc0202f6a:	cea60613          	add	a2,a2,-790 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202f6e:	09100593          	li	a1,145
ffffffffc0202f72:	00002517          	auipc	a0,0x2
ffffffffc0202f76:	6fe50513          	add	a0,a0,1790 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202f7a:	be6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202f7e:	00003697          	auipc	a3,0x3
ffffffffc0202f82:	88a68693          	add	a3,a3,-1910 # ffffffffc0205808 <etext+0x1494>
ffffffffc0202f86:	00002617          	auipc	a2,0x2
ffffffffc0202f8a:	cca60613          	add	a2,a2,-822 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202f8e:	09300593          	li	a1,147
ffffffffc0202f92:	00002517          	auipc	a0,0x2
ffffffffc0202f96:	6de50513          	add	a0,a0,1758 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202f9a:	bc6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(mm != NULL);
ffffffffc0202f9e:	00002697          	auipc	a3,0x2
ffffffffc0202fa2:	72268693          	add	a3,a3,1826 # ffffffffc02056c0 <etext+0x134c>
ffffffffc0202fa6:	00002617          	auipc	a2,0x2
ffffffffc0202faa:	caa60613          	add	a2,a2,-854 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202fae:	0c200593          	li	a1,194
ffffffffc0202fb2:	00002517          	auipc	a0,0x2
ffffffffc0202fb6:	6be50513          	add	a0,a0,1726 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202fba:	ba6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202fbe:	00002697          	auipc	a3,0x2
ffffffffc0202fc2:	71268693          	add	a3,a3,1810 # ffffffffc02056d0 <etext+0x135c>
ffffffffc0202fc6:	00002617          	auipc	a2,0x2
ffffffffc0202fca:	c8a60613          	add	a2,a2,-886 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202fce:	0c500593          	li	a1,197
ffffffffc0202fd2:	00002517          	auipc	a0,0x2
ffffffffc0202fd6:	69e50513          	add	a0,a0,1694 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202fda:	b86fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202fde:	00002697          	auipc	a3,0x2
ffffffffc0202fe2:	7da68693          	add	a3,a3,2010 # ffffffffc02057b8 <etext+0x1444>
ffffffffc0202fe6:	00002617          	auipc	a2,0x2
ffffffffc0202fea:	c6a60613          	add	a2,a2,-918 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0202fee:	0e800593          	li	a1,232
ffffffffc0202ff2:	00002517          	auipc	a0,0x2
ffffffffc0202ff6:	67e50513          	add	a0,a0,1662 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0202ffa:	b66fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0202ffe <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202ffe:	0000e797          	auipc	a5,0xe
ffffffffc0203002:	5527b783          	ld	a5,1362(a5) # ffffffffc0211550 <sm>
ffffffffc0203006:	6b9c                	ld	a5,16(a5)
ffffffffc0203008:	8782                	jr	a5

ffffffffc020300a <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020300a:	0000e797          	auipc	a5,0xe
ffffffffc020300e:	5467b783          	ld	a5,1350(a5) # ffffffffc0211550 <sm>
ffffffffc0203012:	739c                	ld	a5,32(a5)
ffffffffc0203014:	8782                	jr	a5

ffffffffc0203016 <swap_out>:
{
ffffffffc0203016:	711d                	add	sp,sp,-96
ffffffffc0203018:	ec86                	sd	ra,88(sp)
ffffffffc020301a:	e8a2                	sd	s0,80(sp)
     for (i = 0; i != n; ++ i)
ffffffffc020301c:	0e058663          	beqz	a1,ffffffffc0203108 <swap_out+0xf2>
ffffffffc0203020:	e0ca                	sd	s2,64(sp)
ffffffffc0203022:	fc4e                	sd	s3,56(sp)
ffffffffc0203024:	f852                	sd	s4,48(sp)
ffffffffc0203026:	f456                	sd	s5,40(sp)
ffffffffc0203028:	f05a                	sd	s6,32(sp)
ffffffffc020302a:	ec5e                	sd	s7,24(sp)
ffffffffc020302c:	e4a6                	sd	s1,72(sp)
ffffffffc020302e:	e862                	sd	s8,16(sp)
ffffffffc0203030:	8a2e                	mv	s4,a1
ffffffffc0203032:	892a                	mv	s2,a0
ffffffffc0203034:	8ab2                	mv	s5,a2
ffffffffc0203036:	4401                	li	s0,0
ffffffffc0203038:	0000e997          	auipc	s3,0xe
ffffffffc020303c:	51898993          	add	s3,s3,1304 # ffffffffc0211550 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203040:	00003b17          	auipc	s6,0x3
ffffffffc0203044:	918b0b13          	add	s6,s6,-1768 # ffffffffc0205958 <etext+0x15e4>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203048:	00003b97          	auipc	s7,0x3
ffffffffc020304c:	8f8b8b93          	add	s7,s7,-1800 # ffffffffc0205940 <etext+0x15cc>
ffffffffc0203050:	a825                	j	ffffffffc0203088 <swap_out+0x72>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203052:	67a2                	ld	a5,8(sp)
ffffffffc0203054:	8626                	mv	a2,s1
ffffffffc0203056:	85a2                	mv	a1,s0
ffffffffc0203058:	63b4                	ld	a3,64(a5)
ffffffffc020305a:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc020305c:	2405                	addw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020305e:	82b1                	srl	a3,a3,0xc
ffffffffc0203060:	0685                	add	a3,a3,1
ffffffffc0203062:	858fd0ef          	jal	ffffffffc02000ba <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203066:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203068:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020306a:	613c                	ld	a5,64(a0)
ffffffffc020306c:	83b1                	srl	a5,a5,0xc
ffffffffc020306e:	0785                	add	a5,a5,1
ffffffffc0203070:	07a2                	sll	a5,a5,0x8
ffffffffc0203072:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203076:	dacfe0ef          	jal	ffffffffc0201622 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020307a:	01893503          	ld	a0,24(s2)
ffffffffc020307e:	85a6                	mv	a1,s1
ffffffffc0203080:	e7aff0ef          	jal	ffffffffc02026fa <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203084:	048a0d63          	beq	s4,s0,ffffffffc02030de <swap_out+0xc8>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203088:	0009b783          	ld	a5,0(s3)
ffffffffc020308c:	8656                	mv	a2,s5
ffffffffc020308e:	002c                	add	a1,sp,8
ffffffffc0203090:	7b9c                	ld	a5,48(a5)
ffffffffc0203092:	854a                	mv	a0,s2
ffffffffc0203094:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203096:	e12d                	bnez	a0,ffffffffc02030f8 <swap_out+0xe2>
          v=page->pra_vaddr; 
ffffffffc0203098:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020309a:	01893503          	ld	a0,24(s2)
ffffffffc020309e:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02030a0:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02030a2:	85a6                	mv	a1,s1
ffffffffc02030a4:	df8fe0ef          	jal	ffffffffc020169c <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02030a8:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02030aa:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02030ac:	8b85                	and	a5,a5,1
ffffffffc02030ae:	cfb9                	beqz	a5,ffffffffc020310c <swap_out+0xf6>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02030b0:	65a2                	ld	a1,8(sp)
ffffffffc02030b2:	61bc                	ld	a5,64(a1)
ffffffffc02030b4:	83b1                	srl	a5,a5,0xc
ffffffffc02030b6:	0785                	add	a5,a5,1
ffffffffc02030b8:	00879513          	sll	a0,a5,0x8
ffffffffc02030bc:	4b1000ef          	jal	ffffffffc0203d6c <swapfs_write>
ffffffffc02030c0:	d949                	beqz	a0,ffffffffc0203052 <swap_out+0x3c>
                    cprintf("SWAP: failed to save\n");
ffffffffc02030c2:	855e                	mv	a0,s7
ffffffffc02030c4:	ff7fc0ef          	jal	ffffffffc02000ba <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02030c8:	0009b783          	ld	a5,0(s3)
ffffffffc02030cc:	6622                	ld	a2,8(sp)
ffffffffc02030ce:	4681                	li	a3,0
ffffffffc02030d0:	739c                	ld	a5,32(a5)
ffffffffc02030d2:	85a6                	mv	a1,s1
ffffffffc02030d4:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02030d6:	2405                	addw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02030d8:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02030da:	fa8a17e3          	bne	s4,s0,ffffffffc0203088 <swap_out+0x72>
ffffffffc02030de:	64a6                	ld	s1,72(sp)
ffffffffc02030e0:	6906                	ld	s2,64(sp)
ffffffffc02030e2:	79e2                	ld	s3,56(sp)
ffffffffc02030e4:	7a42                	ld	s4,48(sp)
ffffffffc02030e6:	7aa2                	ld	s5,40(sp)
ffffffffc02030e8:	7b02                	ld	s6,32(sp)
ffffffffc02030ea:	6be2                	ld	s7,24(sp)
ffffffffc02030ec:	6c42                	ld	s8,16(sp)
}
ffffffffc02030ee:	60e6                	ld	ra,88(sp)
ffffffffc02030f0:	8522                	mv	a0,s0
ffffffffc02030f2:	6446                	ld	s0,80(sp)
ffffffffc02030f4:	6125                	add	sp,sp,96
ffffffffc02030f6:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc02030f8:	85a2                	mv	a1,s0
ffffffffc02030fa:	00002517          	auipc	a0,0x2
ffffffffc02030fe:	7fe50513          	add	a0,a0,2046 # ffffffffc02058f8 <etext+0x1584>
ffffffffc0203102:	fb9fc0ef          	jal	ffffffffc02000ba <cprintf>
                  break;
ffffffffc0203106:	bfe1                	j	ffffffffc02030de <swap_out+0xc8>
     for (i = 0; i != n; ++ i)
ffffffffc0203108:	4401                	li	s0,0
ffffffffc020310a:	b7d5                	j	ffffffffc02030ee <swap_out+0xd8>
          assert((*ptep & PTE_V) != 0);
ffffffffc020310c:	00003697          	auipc	a3,0x3
ffffffffc0203110:	81c68693          	add	a3,a3,-2020 # ffffffffc0205928 <etext+0x15b4>
ffffffffc0203114:	00002617          	auipc	a2,0x2
ffffffffc0203118:	b3c60613          	add	a2,a2,-1220 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020311c:	06600593          	li	a1,102
ffffffffc0203120:	00002517          	auipc	a0,0x2
ffffffffc0203124:	55050513          	add	a0,a0,1360 # ffffffffc0205670 <etext+0x12fc>
ffffffffc0203128:	a38fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020312c <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc020312c:	4501                	li	a0,0
ffffffffc020312e:	8082                	ret

ffffffffc0203130 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203130:	4501                	li	a0,0
ffffffffc0203132:	8082                	ret

ffffffffc0203134 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203134:	4501                	li	a0,0
ffffffffc0203136:	8082                	ret

ffffffffc0203138 <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc0203138:	1141                	add	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020313a:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc020313c:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020313e:	678d                	lui	a5,0x3
ffffffffc0203140:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203144:	0000e717          	auipc	a4,0xe
ffffffffc0203148:	41c72703          	lw	a4,1052(a4) # ffffffffc0211560 <pgfault_num>
ffffffffc020314c:	4691                	li	a3,4
ffffffffc020314e:	0ad71663          	bne	a4,a3,ffffffffc02031fa <_clock_check_swap+0xc2>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203152:	6685                	lui	a3,0x1
ffffffffc0203154:	4629                	li	a2,10
ffffffffc0203156:	00c68023          	sb	a2,0(a3) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020315a:	0000e797          	auipc	a5,0xe
ffffffffc020315e:	40678793          	add	a5,a5,1030 # ffffffffc0211560 <pgfault_num>
    assert(pgfault_num==4);
ffffffffc0203162:	4394                	lw	a3,0(a5)
ffffffffc0203164:	0006861b          	sext.w	a2,a3
ffffffffc0203168:	20e69963          	bne	a3,a4,ffffffffc020337a <_clock_check_swap+0x242>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020316c:	6711                	lui	a4,0x4
ffffffffc020316e:	46b5                	li	a3,13
ffffffffc0203170:	00d70023          	sb	a3,0(a4) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc0203174:	4398                	lw	a4,0(a5)
ffffffffc0203176:	0007069b          	sext.w	a3,a4
ffffffffc020317a:	1ec71063          	bne	a4,a2,ffffffffc020335a <_clock_check_swap+0x222>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020317e:	6709                	lui	a4,0x2
ffffffffc0203180:	462d                	li	a2,11
ffffffffc0203182:	00c70023          	sb	a2,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0203186:	4398                	lw	a4,0(a5)
ffffffffc0203188:	1ad71963          	bne	a4,a3,ffffffffc020333a <_clock_check_swap+0x202>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020318c:	6715                	lui	a4,0x5
ffffffffc020318e:	46b9                	li	a3,14
ffffffffc0203190:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0203194:	4398                	lw	a4,0(a5)
ffffffffc0203196:	4615                	li	a2,5
ffffffffc0203198:	0007069b          	sext.w	a3,a4
ffffffffc020319c:	16c71f63          	bne	a4,a2,ffffffffc020331a <_clock_check_swap+0x1e2>
    assert(pgfault_num==5);
ffffffffc02031a0:	4398                	lw	a4,0(a5)
ffffffffc02031a2:	0007061b          	sext.w	a2,a4
ffffffffc02031a6:	14d71a63          	bne	a4,a3,ffffffffc02032fa <_clock_check_swap+0x1c2>
    assert(pgfault_num==5);
ffffffffc02031aa:	4398                	lw	a4,0(a5)
ffffffffc02031ac:	0007069b          	sext.w	a3,a4
ffffffffc02031b0:	12c71563          	bne	a4,a2,ffffffffc02032da <_clock_check_swap+0x1a2>
    assert(pgfault_num==5);
ffffffffc02031b4:	4398                	lw	a4,0(a5)
ffffffffc02031b6:	0007061b          	sext.w	a2,a4
ffffffffc02031ba:	10d71063          	bne	a4,a3,ffffffffc02032ba <_clock_check_swap+0x182>
    assert(pgfault_num==5);
ffffffffc02031be:	4398                	lw	a4,0(a5)
ffffffffc02031c0:	0007069b          	sext.w	a3,a4
ffffffffc02031c4:	0cc71b63          	bne	a4,a2,ffffffffc020329a <_clock_check_swap+0x162>
    assert(pgfault_num==5);
ffffffffc02031c8:	4398                	lw	a4,0(a5)
ffffffffc02031ca:	0ad71863          	bne	a4,a3,ffffffffc020327a <_clock_check_swap+0x142>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02031ce:	6715                	lui	a4,0x5
ffffffffc02031d0:	46b9                	li	a3,14
ffffffffc02031d2:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02031d6:	4394                	lw	a3,0(a5)
ffffffffc02031d8:	4715                	li	a4,5
ffffffffc02031da:	08e69063          	bne	a3,a4,ffffffffc020325a <_clock_check_swap+0x122>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02031de:	6705                	lui	a4,0x1
ffffffffc02031e0:	00074683          	lbu	a3,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02031e4:	4729                	li	a4,10
ffffffffc02031e6:	04e69a63          	bne	a3,a4,ffffffffc020323a <_clock_check_swap+0x102>
    assert(pgfault_num==6);
ffffffffc02031ea:	4398                	lw	a4,0(a5)
ffffffffc02031ec:	4799                	li	a5,6
ffffffffc02031ee:	02f71663          	bne	a4,a5,ffffffffc020321a <_clock_check_swap+0xe2>
}
ffffffffc02031f2:	60a2                	ld	ra,8(sp)
ffffffffc02031f4:	4501                	li	a0,0
ffffffffc02031f6:	0141                	add	sp,sp,16
ffffffffc02031f8:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02031fa:	00002697          	auipc	a3,0x2
ffffffffc02031fe:	63e68693          	add	a3,a3,1598 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0203202:	00002617          	auipc	a2,0x2
ffffffffc0203206:	a4e60613          	add	a2,a2,-1458 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020320a:	08e00593          	li	a1,142
ffffffffc020320e:	00002517          	auipc	a0,0x2
ffffffffc0203212:	78a50513          	add	a0,a0,1930 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203216:	94afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==6);
ffffffffc020321a:	00002697          	auipc	a3,0x2
ffffffffc020321e:	7ce68693          	add	a3,a3,1998 # ffffffffc02059e8 <etext+0x1674>
ffffffffc0203222:	00002617          	auipc	a2,0x2
ffffffffc0203226:	a2e60613          	add	a2,a2,-1490 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020322a:	0a500593          	li	a1,165
ffffffffc020322e:	00002517          	auipc	a0,0x2
ffffffffc0203232:	76a50513          	add	a0,a0,1898 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203236:	92afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020323a:	00002697          	auipc	a3,0x2
ffffffffc020323e:	78668693          	add	a3,a3,1926 # ffffffffc02059c0 <etext+0x164c>
ffffffffc0203242:	00002617          	auipc	a2,0x2
ffffffffc0203246:	a0e60613          	add	a2,a2,-1522 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020324a:	0a300593          	li	a1,163
ffffffffc020324e:	00002517          	auipc	a0,0x2
ffffffffc0203252:	74a50513          	add	a0,a0,1866 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203256:	90afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc020325a:	00002697          	auipc	a3,0x2
ffffffffc020325e:	75668693          	add	a3,a3,1878 # ffffffffc02059b0 <etext+0x163c>
ffffffffc0203262:	00002617          	auipc	a2,0x2
ffffffffc0203266:	9ee60613          	add	a2,a2,-1554 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020326a:	0a200593          	li	a1,162
ffffffffc020326e:	00002517          	auipc	a0,0x2
ffffffffc0203272:	72a50513          	add	a0,a0,1834 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203276:	8eafd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc020327a:	00002697          	auipc	a3,0x2
ffffffffc020327e:	73668693          	add	a3,a3,1846 # ffffffffc02059b0 <etext+0x163c>
ffffffffc0203282:	00002617          	auipc	a2,0x2
ffffffffc0203286:	9ce60613          	add	a2,a2,-1586 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020328a:	0a000593          	li	a1,160
ffffffffc020328e:	00002517          	auipc	a0,0x2
ffffffffc0203292:	70a50513          	add	a0,a0,1802 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203296:	8cafd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc020329a:	00002697          	auipc	a3,0x2
ffffffffc020329e:	71668693          	add	a3,a3,1814 # ffffffffc02059b0 <etext+0x163c>
ffffffffc02032a2:	00002617          	auipc	a2,0x2
ffffffffc02032a6:	9ae60613          	add	a2,a2,-1618 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02032aa:	09e00593          	li	a1,158
ffffffffc02032ae:	00002517          	auipc	a0,0x2
ffffffffc02032b2:	6ea50513          	add	a0,a0,1770 # ffffffffc0205998 <etext+0x1624>
ffffffffc02032b6:	8aafd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02032ba:	00002697          	auipc	a3,0x2
ffffffffc02032be:	6f668693          	add	a3,a3,1782 # ffffffffc02059b0 <etext+0x163c>
ffffffffc02032c2:	00002617          	auipc	a2,0x2
ffffffffc02032c6:	98e60613          	add	a2,a2,-1650 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02032ca:	09c00593          	li	a1,156
ffffffffc02032ce:	00002517          	auipc	a0,0x2
ffffffffc02032d2:	6ca50513          	add	a0,a0,1738 # ffffffffc0205998 <etext+0x1624>
ffffffffc02032d6:	88afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02032da:	00002697          	auipc	a3,0x2
ffffffffc02032de:	6d668693          	add	a3,a3,1750 # ffffffffc02059b0 <etext+0x163c>
ffffffffc02032e2:	00002617          	auipc	a2,0x2
ffffffffc02032e6:	96e60613          	add	a2,a2,-1682 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02032ea:	09a00593          	li	a1,154
ffffffffc02032ee:	00002517          	auipc	a0,0x2
ffffffffc02032f2:	6aa50513          	add	a0,a0,1706 # ffffffffc0205998 <etext+0x1624>
ffffffffc02032f6:	86afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02032fa:	00002697          	auipc	a3,0x2
ffffffffc02032fe:	6b668693          	add	a3,a3,1718 # ffffffffc02059b0 <etext+0x163c>
ffffffffc0203302:	00002617          	auipc	a2,0x2
ffffffffc0203306:	94e60613          	add	a2,a2,-1714 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020330a:	09800593          	li	a1,152
ffffffffc020330e:	00002517          	auipc	a0,0x2
ffffffffc0203312:	68a50513          	add	a0,a0,1674 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203316:	84afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc020331a:	00002697          	auipc	a3,0x2
ffffffffc020331e:	69668693          	add	a3,a3,1686 # ffffffffc02059b0 <etext+0x163c>
ffffffffc0203322:	00002617          	auipc	a2,0x2
ffffffffc0203326:	92e60613          	add	a2,a2,-1746 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020332a:	09600593          	li	a1,150
ffffffffc020332e:	00002517          	auipc	a0,0x2
ffffffffc0203332:	66a50513          	add	a0,a0,1642 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203336:	82afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc020333a:	00002697          	auipc	a3,0x2
ffffffffc020333e:	4fe68693          	add	a3,a3,1278 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0203342:	00002617          	auipc	a2,0x2
ffffffffc0203346:	90e60613          	add	a2,a2,-1778 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020334a:	09400593          	li	a1,148
ffffffffc020334e:	00002517          	auipc	a0,0x2
ffffffffc0203352:	64a50513          	add	a0,a0,1610 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203356:	80afd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc020335a:	00002697          	auipc	a3,0x2
ffffffffc020335e:	4de68693          	add	a3,a3,1246 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0203362:	00002617          	auipc	a2,0x2
ffffffffc0203366:	8ee60613          	add	a2,a2,-1810 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020336a:	09200593          	li	a1,146
ffffffffc020336e:	00002517          	auipc	a0,0x2
ffffffffc0203372:	62a50513          	add	a0,a0,1578 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203376:	febfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc020337a:	00002697          	auipc	a3,0x2
ffffffffc020337e:	4be68693          	add	a3,a3,1214 # ffffffffc0205838 <etext+0x14c4>
ffffffffc0203382:	00002617          	auipc	a2,0x2
ffffffffc0203386:	8ce60613          	add	a2,a2,-1842 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc020338a:	09000593          	li	a1,144
ffffffffc020338e:	00002517          	auipc	a0,0x2
ffffffffc0203392:	60a50513          	add	a0,a0,1546 # ffffffffc0205998 <etext+0x1624>
ffffffffc0203396:	fcbfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020339a <_clock_init_mm>:
{     
ffffffffc020339a:	1141                	add	sp,sp,-16
ffffffffc020339c:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc020339e:	0000e797          	auipc	a5,0xe
ffffffffc02033a2:	d4a78793          	add	a5,a5,-694 # ffffffffc02110e8 <pra_list_head>
     mm->sm_priv = &pra_list_head;
ffffffffc02033a6:	f51c                	sd	a5,40(a0)
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc02033a8:	85be                	mv	a1,a5
ffffffffc02033aa:	00002517          	auipc	a0,0x2
ffffffffc02033ae:	64e50513          	add	a0,a0,1614 # ffffffffc02059f8 <etext+0x1684>
ffffffffc02033b2:	e79c                	sd	a5,8(a5)
ffffffffc02033b4:	e39c                	sd	a5,0(a5)
     curr_ptr = &pra_list_head;
ffffffffc02033b6:	0000e717          	auipc	a4,0xe
ffffffffc02033ba:	1af73123          	sd	a5,418(a4) # ffffffffc0211558 <curr_ptr>
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc02033be:	cfdfc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc02033c2:	60a2                	ld	ra,8(sp)
ffffffffc02033c4:	4501                	li	a0,0
ffffffffc02033c6:	0141                	add	sp,sp,16
ffffffffc02033c8:	8082                	ret

ffffffffc02033ca <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02033ca:	751c                	ld	a5,40(a0)
{
ffffffffc02033cc:	1141                	add	sp,sp,-16
ffffffffc02033ce:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc02033d0:	cba5                	beqz	a5,ffffffffc0203440 <_clock_swap_out_victim+0x76>
     assert(in_tick==0);
ffffffffc02033d2:	e639                	bnez	a2,ffffffffc0203420 <_clock_swap_out_victim+0x56>
    return listelm->prev;
ffffffffc02033d4:	639c                	ld	a5,0(a5)
        curr_ptr = list_prev(curr_ptr);
ffffffffc02033d6:	0000e517          	auipc	a0,0xe
ffffffffc02033da:	18250513          	add	a0,a0,386 # ffffffffc0211558 <curr_ptr>
ffffffffc02033de:	e11c                	sd	a5,0(a0)
        if (!curr_ptr) {
ffffffffc02033e0:	c785                	beqz	a5,ffffffffc0203408 <_clock_swap_out_victim+0x3e>
ffffffffc02033e2:	4601                	li	a2,0
ffffffffc02033e4:	a029                	j	ffffffffc02033ee <_clock_swap_out_victim+0x24>
            p->visited = 0;  // 标记页面为未访问
ffffffffc02033e6:	fe073023          	sd	zero,-32(a4)
        if (!curr_ptr) {
ffffffffc02033ea:	4605                	li	a2,1
ffffffffc02033ec:	c395                	beqz	a5,ffffffffc0203410 <_clock_swap_out_victim+0x46>
        if (p->visited == 0) {
ffffffffc02033ee:	fe07b683          	ld	a3,-32(a5)
ffffffffc02033f2:	873e                	mv	a4,a5
ffffffffc02033f4:	639c                	ld	a5,0(a5)
ffffffffc02033f6:	fae5                	bnez	a3,ffffffffc02033e6 <_clock_swap_out_victim+0x1c>
ffffffffc02033f8:	c211                	beqz	a2,ffffffffc02033fc <_clock_swap_out_victim+0x32>
ffffffffc02033fa:	e118                	sd	a4,0(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02033fc:	6714                	ld	a3,8(a4)
            *ptr_page = le2page(curr_ptr, pra_page_link);
ffffffffc02033fe:	fd070713          	add	a4,a4,-48
    prev->next = next;
ffffffffc0203402:	e794                	sd	a3,8(a5)
    next->prev = prev;
ffffffffc0203404:	e29c                	sd	a5,0(a3)
ffffffffc0203406:	e198                	sd	a4,0(a1)
}
ffffffffc0203408:	60a2                	ld	ra,8(sp)
ffffffffc020340a:	4501                	li	a0,0
ffffffffc020340c:	0141                	add	sp,sp,16
ffffffffc020340e:	8082                	ret
ffffffffc0203410:	60a2                	ld	ra,8(sp)
ffffffffc0203412:	0000e797          	auipc	a5,0xe
ffffffffc0203416:	1407b323          	sd	zero,326(a5) # ffffffffc0211558 <curr_ptr>
ffffffffc020341a:	4501                	li	a0,0
ffffffffc020341c:	0141                	add	sp,sp,16
ffffffffc020341e:	8082                	ret
     assert(in_tick==0);
ffffffffc0203420:	00002697          	auipc	a3,0x2
ffffffffc0203424:	61068693          	add	a3,a3,1552 # ffffffffc0205a30 <etext+0x16bc>
ffffffffc0203428:	00002617          	auipc	a2,0x2
ffffffffc020342c:	82860613          	add	a2,a2,-2008 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203430:	04c00593          	li	a1,76
ffffffffc0203434:	00002517          	auipc	a0,0x2
ffffffffc0203438:	56450513          	add	a0,a0,1380 # ffffffffc0205998 <etext+0x1624>
ffffffffc020343c:	f25fc0ef          	jal	ffffffffc0200360 <__panic>
         assert(head != NULL);
ffffffffc0203440:	00002697          	auipc	a3,0x2
ffffffffc0203444:	5e068693          	add	a3,a3,1504 # ffffffffc0205a20 <etext+0x16ac>
ffffffffc0203448:	00002617          	auipc	a2,0x2
ffffffffc020344c:	80860613          	add	a2,a2,-2040 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203450:	04b00593          	li	a1,75
ffffffffc0203454:	00002517          	auipc	a0,0x2
ffffffffc0203458:	54450513          	add	a0,a0,1348 # ffffffffc0205998 <etext+0x1624>
ffffffffc020345c:	f05fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203460 <_clock_map_swappable>:
{
ffffffffc0203460:	1141                	add	sp,sp,-16
ffffffffc0203462:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203464:	0000e597          	auipc	a1,0xe
ffffffffc0203468:	0f45b583          	ld	a1,244(a1) # ffffffffc0211558 <curr_ptr>
ffffffffc020346c:	c985                	beqz	a1,ffffffffc020349c <_clock_map_swappable+0x3c>
    __list_add(elm, listelm, listelm->next);
ffffffffc020346e:	0000e797          	auipc	a5,0xe
ffffffffc0203472:	c7a78793          	add	a5,a5,-902 # ffffffffc02110e8 <pra_list_head>
ffffffffc0203476:	6794                	ld	a3,8(a5)
ffffffffc0203478:	03060713          	add	a4,a2,48
    cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc020347c:	00002517          	auipc	a0,0x2
ffffffffc0203480:	5ec50513          	add	a0,a0,1516 # ffffffffc0205a68 <etext+0x16f4>
    prev->next = next->prev = elm;
ffffffffc0203484:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0203486:	fe14                	sd	a3,56(a2)
    page->visited=1;
ffffffffc0203488:	4685                	li	a3,1
    elm->prev = prev;
ffffffffc020348a:	fa1c                	sd	a5,48(a2)
ffffffffc020348c:	ea14                	sd	a3,16(a2)
    prev->next = next->prev = elm;
ffffffffc020348e:	e798                	sd	a4,8(a5)
    cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc0203490:	c2bfc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc0203494:	60a2                	ld	ra,8(sp)
ffffffffc0203496:	4501                	li	a0,0
ffffffffc0203498:	0141                	add	sp,sp,16
ffffffffc020349a:	8082                	ret
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020349c:	00002697          	auipc	a3,0x2
ffffffffc02034a0:	5a468693          	add	a3,a3,1444 # ffffffffc0205a40 <etext+0x16cc>
ffffffffc02034a4:	00001617          	auipc	a2,0x1
ffffffffc02034a8:	7ac60613          	add	a2,a2,1964 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02034ac:	03800593          	li	a1,56
ffffffffc02034b0:	00002517          	auipc	a0,0x2
ffffffffc02034b4:	4e850513          	add	a0,a0,1256 # ffffffffc0205998 <etext+0x1624>
ffffffffc02034b8:	ea9fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02034bc <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02034bc:	1141                	add	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02034be:	00002697          	auipc	a3,0x2
ffffffffc02034c2:	5d268693          	add	a3,a3,1490 # ffffffffc0205a90 <etext+0x171c>
ffffffffc02034c6:	00001617          	auipc	a2,0x1
ffffffffc02034ca:	78a60613          	add	a2,a2,1930 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02034ce:	07d00593          	li	a1,125
ffffffffc02034d2:	00002517          	auipc	a0,0x2
ffffffffc02034d6:	5de50513          	add	a0,a0,1502 # ffffffffc0205ab0 <etext+0x173c>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02034da:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02034dc:	e85fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02034e0 <mm_create>:
mm_create(void) {
ffffffffc02034e0:	1141                	add	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02034e2:	03000513          	li	a0,48
mm_create(void) {
ffffffffc02034e6:	e022                	sd	s0,0(sp)
ffffffffc02034e8:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02034ea:	aceff0ef          	jal	ffffffffc02027b8 <kmalloc>
ffffffffc02034ee:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02034f0:	c105                	beqz	a0,ffffffffc0203510 <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc02034f2:	e408                	sd	a0,8(s0)
ffffffffc02034f4:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02034f6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02034fa:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02034fe:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203502:	0000e797          	auipc	a5,0xe
ffffffffc0203506:	03e7a783          	lw	a5,62(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc020350a:	eb81                	bnez	a5,ffffffffc020351a <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc020350c:	02053423          	sd	zero,40(a0)
}
ffffffffc0203510:	60a2                	ld	ra,8(sp)
ffffffffc0203512:	8522                	mv	a0,s0
ffffffffc0203514:	6402                	ld	s0,0(sp)
ffffffffc0203516:	0141                	add	sp,sp,16
ffffffffc0203518:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020351a:	ae5ff0ef          	jal	ffffffffc0202ffe <swap_init_mm>
}
ffffffffc020351e:	60a2                	ld	ra,8(sp)
ffffffffc0203520:	8522                	mv	a0,s0
ffffffffc0203522:	6402                	ld	s0,0(sp)
ffffffffc0203524:	0141                	add	sp,sp,16
ffffffffc0203526:	8082                	ret

ffffffffc0203528 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0203528:	1101                	add	sp,sp,-32
ffffffffc020352a:	e04a                	sd	s2,0(sp)
ffffffffc020352c:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020352e:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0203532:	e822                	sd	s0,16(sp)
ffffffffc0203534:	e426                	sd	s1,8(sp)
ffffffffc0203536:	ec06                	sd	ra,24(sp)
ffffffffc0203538:	84ae                	mv	s1,a1
ffffffffc020353a:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020353c:	a7cff0ef          	jal	ffffffffc02027b8 <kmalloc>
    if (vma != NULL) {
ffffffffc0203540:	c509                	beqz	a0,ffffffffc020354a <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0203542:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203546:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203548:	ed00                	sd	s0,24(a0)
}
ffffffffc020354a:	60e2                	ld	ra,24(sp)
ffffffffc020354c:	6442                	ld	s0,16(sp)
ffffffffc020354e:	64a2                	ld	s1,8(sp)
ffffffffc0203550:	6902                	ld	s2,0(sp)
ffffffffc0203552:	6105                	add	sp,sp,32
ffffffffc0203554:	8082                	ret

ffffffffc0203556 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0203556:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0203558:	c505                	beqz	a0,ffffffffc0203580 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc020355a:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc020355c:	c501                	beqz	a0,ffffffffc0203564 <find_vma+0xe>
ffffffffc020355e:	651c                	ld	a5,8(a0)
ffffffffc0203560:	02f5f663          	bgeu	a1,a5,ffffffffc020358c <find_vma+0x36>
    return listelm->next;
ffffffffc0203564:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0203566:	00f68d63          	beq	a3,a5,ffffffffc0203580 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc020356a:	fe87b703          	ld	a4,-24(a5)
ffffffffc020356e:	00e5e663          	bltu	a1,a4,ffffffffc020357a <find_vma+0x24>
ffffffffc0203572:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203576:	00e5e763          	bltu	a1,a4,ffffffffc0203584 <find_vma+0x2e>
ffffffffc020357a:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc020357c:	fef697e3          	bne	a3,a5,ffffffffc020356a <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203580:	4501                	li	a0,0
}
ffffffffc0203582:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0203584:	fe078513          	add	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203588:	ea88                	sd	a0,16(a3)
ffffffffc020358a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc020358c:	691c                	ld	a5,16(a0)
ffffffffc020358e:	fcf5fbe3          	bgeu	a1,a5,ffffffffc0203564 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203592:	ea88                	sd	a0,16(a3)
ffffffffc0203594:	8082                	ret

ffffffffc0203596 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203596:	6590                	ld	a2,8(a1)
ffffffffc0203598:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc020359c:	1141                	add	sp,sp,-16
ffffffffc020359e:	e406                	sd	ra,8(sp)
ffffffffc02035a0:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02035a2:	01066763          	bltu	a2,a6,ffffffffc02035b0 <insert_vma_struct+0x1a>
ffffffffc02035a6:	a085                	j	ffffffffc0203606 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02035a8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02035ac:	04e66863          	bltu	a2,a4,ffffffffc02035fc <insert_vma_struct+0x66>
ffffffffc02035b0:	86be                	mv	a3,a5
ffffffffc02035b2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02035b4:	fef51ae3          	bne	a0,a5,ffffffffc02035a8 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02035b8:	02a68463          	beq	a3,a0,ffffffffc02035e0 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02035bc:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02035c0:	fe86b883          	ld	a7,-24(a3)
ffffffffc02035c4:	08e8f163          	bgeu	a7,a4,ffffffffc0203646 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02035c8:	04e66f63          	bltu	a2,a4,ffffffffc0203626 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc02035cc:	00f50a63          	beq	a0,a5,ffffffffc02035e0 <insert_vma_struct+0x4a>
ffffffffc02035d0:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02035d4:	05076963          	bltu	a4,a6,ffffffffc0203626 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc02035d8:	ff07b603          	ld	a2,-16(a5)
ffffffffc02035dc:	02c77363          	bgeu	a4,a2,ffffffffc0203602 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02035e0:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02035e2:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02035e4:	02058613          	add	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02035e8:	e390                	sd	a2,0(a5)
ffffffffc02035ea:	e690                	sd	a2,8(a3)
}
ffffffffc02035ec:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02035ee:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02035f0:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc02035f2:	0017079b          	addw	a5,a4,1
ffffffffc02035f6:	d11c                	sw	a5,32(a0)
}
ffffffffc02035f8:	0141                	add	sp,sp,16
ffffffffc02035fa:	8082                	ret
    if (le_prev != list) {
ffffffffc02035fc:	fca690e3          	bne	a3,a0,ffffffffc02035bc <insert_vma_struct+0x26>
ffffffffc0203600:	bfd1                	j	ffffffffc02035d4 <insert_vma_struct+0x3e>
ffffffffc0203602:	ebbff0ef          	jal	ffffffffc02034bc <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203606:	00002697          	auipc	a3,0x2
ffffffffc020360a:	4ba68693          	add	a3,a3,1210 # ffffffffc0205ac0 <etext+0x174c>
ffffffffc020360e:	00001617          	auipc	a2,0x1
ffffffffc0203612:	64260613          	add	a2,a2,1602 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203616:	08400593          	li	a1,132
ffffffffc020361a:	00002517          	auipc	a0,0x2
ffffffffc020361e:	49650513          	add	a0,a0,1174 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203622:	d3ffc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203626:	00002697          	auipc	a3,0x2
ffffffffc020362a:	4da68693          	add	a3,a3,1242 # ffffffffc0205b00 <etext+0x178c>
ffffffffc020362e:	00001617          	auipc	a2,0x1
ffffffffc0203632:	62260613          	add	a2,a2,1570 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203636:	07c00593          	li	a1,124
ffffffffc020363a:	00002517          	auipc	a0,0x2
ffffffffc020363e:	47650513          	add	a0,a0,1142 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203642:	d1ffc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203646:	00002697          	auipc	a3,0x2
ffffffffc020364a:	49a68693          	add	a3,a3,1178 # ffffffffc0205ae0 <etext+0x176c>
ffffffffc020364e:	00001617          	auipc	a2,0x1
ffffffffc0203652:	60260613          	add	a2,a2,1538 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203656:	07b00593          	li	a1,123
ffffffffc020365a:	00002517          	auipc	a0,0x2
ffffffffc020365e:	45650513          	add	a0,a0,1110 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203662:	cfffc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203666 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0203666:	1141                	add	sp,sp,-16
ffffffffc0203668:	e022                	sd	s0,0(sp)
ffffffffc020366a:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020366c:	6508                	ld	a0,8(a0)
ffffffffc020366e:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0203670:	00a40e63          	beq	s0,a0,ffffffffc020368c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203674:	6118                	ld	a4,0(a0)
ffffffffc0203676:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203678:	03000593          	li	a1,48
ffffffffc020367c:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc020367e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203680:	e398                	sd	a4,0(a5)
ffffffffc0203682:	a02ff0ef          	jal	ffffffffc0202884 <kfree>
    return listelm->next;
ffffffffc0203686:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203688:	fea416e3          	bne	s0,a0,ffffffffc0203674 <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020368c:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc020368e:	6402                	ld	s0,0(sp)
ffffffffc0203690:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203692:	03000593          	li	a1,48
}
ffffffffc0203696:	0141                	add	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203698:	9ecff06f          	j	ffffffffc0202884 <kfree>

ffffffffc020369c <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc020369c:	715d                	add	sp,sp,-80
ffffffffc020369e:	e486                	sd	ra,72(sp)
ffffffffc02036a0:	f44e                	sd	s3,40(sp)
ffffffffc02036a2:	f052                	sd	s4,32(sp)
ffffffffc02036a4:	e0a2                	sd	s0,64(sp)
ffffffffc02036a6:	fc26                	sd	s1,56(sp)
ffffffffc02036a8:	f84a                	sd	s2,48(sp)
ffffffffc02036aa:	ec56                	sd	s5,24(sp)
ffffffffc02036ac:	e85a                	sd	s6,16(sp)
ffffffffc02036ae:	e45e                	sd	s7,8(sp)
ffffffffc02036b0:	e062                	sd	s8,0(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02036b2:	fb1fd0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc02036b6:	89aa                	mv	s3,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02036b8:	fabfd0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc02036bc:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036be:	03000513          	li	a0,48
ffffffffc02036c2:	8f6ff0ef          	jal	ffffffffc02027b8 <kmalloc>
    if (mm != NULL) {
ffffffffc02036c6:	30050563          	beqz	a0,ffffffffc02039d0 <vmm_init+0x334>
    elm->prev = elm->next = elm;
ffffffffc02036ca:	e508                	sd	a0,8(a0)
ffffffffc02036cc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ce:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036d2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036d6:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02036da:	0000e797          	auipc	a5,0xe
ffffffffc02036de:	e667a783          	lw	a5,-410(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc02036e2:	842a                	mv	s0,a0
ffffffffc02036e4:	2c079363          	bnez	a5,ffffffffc02039aa <vmm_init+0x30e>
        else mm->sm_priv = NULL;
ffffffffc02036e8:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc02036ec:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02036f0:	03000513          	li	a0,48
ffffffffc02036f4:	8c4ff0ef          	jal	ffffffffc02027b8 <kmalloc>
ffffffffc02036f8:	00248913          	add	s2,s1,2
ffffffffc02036fc:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02036fe:	2a050963          	beqz	a0,ffffffffc02039b0 <vmm_init+0x314>
        vma->vm_start = vm_start;
ffffffffc0203702:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203704:	01253823          	sd	s2,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203708:	00053c23          	sd	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc020370c:	14ed                	add	s1,s1,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020370e:	8522                	mv	a0,s0
ffffffffc0203710:	e87ff0ef          	jal	ffffffffc0203596 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0203714:	fcf1                	bnez	s1,ffffffffc02036f0 <vmm_init+0x54>
ffffffffc0203716:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020371a:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020371e:	03000513          	li	a0,48
ffffffffc0203722:	896ff0ef          	jal	ffffffffc02027b8 <kmalloc>
ffffffffc0203726:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0203728:	2c050463          	beqz	a0,ffffffffc02039f0 <vmm_init+0x354>
        vma->vm_end = vm_end;
ffffffffc020372c:	00248793          	add	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203730:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203732:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203734:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203738:	0495                	add	s1,s1,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020373a:	8522                	mv	a0,s0
ffffffffc020373c:	e5bff0ef          	jal	ffffffffc0203596 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203740:	fd249fe3          	bne	s1,s2,ffffffffc020371e <vmm_init+0x82>
    return listelm->next;
ffffffffc0203744:	00843b03          	ld	s6,8(s0)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0203748:	3c8b0b63          	beq	s6,s0,ffffffffc0203b1e <vmm_init+0x482>
    list_entry_t *le = list_next(&(mm->mmap_list));
ffffffffc020374c:	87da                	mv	a5,s6
        assert(le != &(mm->mmap_list));
ffffffffc020374e:	4715                	li	a4,5
    for (i = 1; i <= step2; i ++) {
ffffffffc0203750:	1f400593          	li	a1,500
ffffffffc0203754:	a021                	j	ffffffffc020375c <vmm_init+0xc0>
        assert(le != &(mm->mmap_list));
ffffffffc0203756:	0715                	add	a4,a4,5
ffffffffc0203758:	3c878363          	beq	a5,s0,ffffffffc0203b1e <vmm_init+0x482>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020375c:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203760:	32e69f63          	bne	a3,a4,ffffffffc0203a9e <vmm_init+0x402>
ffffffffc0203764:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203768:	00270693          	add	a3,a4,2
ffffffffc020376c:	32d61963          	bne	a2,a3,ffffffffc0203a9e <vmm_init+0x402>
ffffffffc0203770:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i ++) {
ffffffffc0203772:	feb712e3          	bne	a4,a1,ffffffffc0203756 <vmm_init+0xba>
ffffffffc0203776:	4b9d                	li	s7,7
ffffffffc0203778:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020377a:	1f900c13          	li	s8,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc020377e:	85a6                	mv	a1,s1
ffffffffc0203780:	8522                	mv	a0,s0
ffffffffc0203782:	dd5ff0ef          	jal	ffffffffc0203556 <find_vma>
ffffffffc0203786:	8aaa                	mv	s5,a0
        assert(vma1 != NULL);
ffffffffc0203788:	3c050b63          	beqz	a0,ffffffffc0203b5e <vmm_init+0x4c2>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc020378c:	00148593          	add	a1,s1,1
ffffffffc0203790:	8522                	mv	a0,s0
ffffffffc0203792:	dc5ff0ef          	jal	ffffffffc0203556 <find_vma>
ffffffffc0203796:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc0203798:	3a050363          	beqz	a0,ffffffffc0203b3e <vmm_init+0x4a2>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc020379c:	85de                	mv	a1,s7
ffffffffc020379e:	8522                	mv	a0,s0
ffffffffc02037a0:	db7ff0ef          	jal	ffffffffc0203556 <find_vma>
        assert(vma3 == NULL);
ffffffffc02037a4:	32051d63          	bnez	a0,ffffffffc0203ade <vmm_init+0x442>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc02037a8:	00348593          	add	a1,s1,3
ffffffffc02037ac:	8522                	mv	a0,s0
ffffffffc02037ae:	da9ff0ef          	jal	ffffffffc0203556 <find_vma>
        assert(vma4 == NULL);
ffffffffc02037b2:	30051663          	bnez	a0,ffffffffc0203abe <vmm_init+0x422>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02037b6:	00448593          	add	a1,s1,4
ffffffffc02037ba:	8522                	mv	a0,s0
ffffffffc02037bc:	d9bff0ef          	jal	ffffffffc0203556 <find_vma>
        assert(vma5 == NULL);
ffffffffc02037c0:	32051f63          	bnez	a0,ffffffffc0203afe <vmm_init+0x462>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02037c4:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc02037c8:	2a979b63          	bne	a5,s1,ffffffffc0203a7e <vmm_init+0x3e2>
ffffffffc02037cc:	010ab783          	ld	a5,16(s5)
ffffffffc02037d0:	2afb9763          	bne	s7,a5,ffffffffc0203a7e <vmm_init+0x3e2>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02037d4:	00893783          	ld	a5,8(s2)
ffffffffc02037d8:	28979363          	bne	a5,s1,ffffffffc0203a5e <vmm_init+0x3c2>
ffffffffc02037dc:	01093783          	ld	a5,16(s2)
ffffffffc02037e0:	26fb9f63          	bne	s7,a5,ffffffffc0203a5e <vmm_init+0x3c2>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02037e4:	0495                	add	s1,s1,5
ffffffffc02037e6:	0b95                	add	s7,s7,5
ffffffffc02037e8:	f9849be3          	bne	s1,s8,ffffffffc020377e <vmm_init+0xe2>
ffffffffc02037ec:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02037ee:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02037f0:	85a6                	mv	a1,s1
ffffffffc02037f2:	8522                	mv	a0,s0
ffffffffc02037f4:	d63ff0ef          	jal	ffffffffc0203556 <find_vma>
        if (vma_below_5 != NULL ) {
ffffffffc02037f8:	3a051363          	bnez	a0,ffffffffc0203b9e <vmm_init+0x502>
    for (i =4; i>=0; i--) {
ffffffffc02037fc:	14fd                	add	s1,s1,-1
ffffffffc02037fe:	ff2499e3          	bne	s1,s2,ffffffffc02037f0 <vmm_init+0x154>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203802:	000b3703          	ld	a4,0(s6)
ffffffffc0203806:	008b3783          	ld	a5,8(s6)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc020380a:	fe0b0513          	add	a0,s6,-32
ffffffffc020380e:	03000593          	li	a1,48
    prev->next = next;
ffffffffc0203812:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203814:	e398                	sd	a4,0(a5)
ffffffffc0203816:	86eff0ef          	jal	ffffffffc0202884 <kfree>
    return listelm->next;
ffffffffc020381a:	00843b03          	ld	s6,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020381e:	ff6412e3          	bne	s0,s6,ffffffffc0203802 <vmm_init+0x166>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203822:	03000593          	li	a1,48
ffffffffc0203826:	8522                	mv	a0,s0
ffffffffc0203828:	85cff0ef          	jal	ffffffffc0202884 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020382c:	e37fd0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc0203830:	3caa1163          	bne	s4,a0,ffffffffc0203bf2 <vmm_init+0x556>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203834:	00002517          	auipc	a0,0x2
ffffffffc0203838:	45450513          	add	a0,a0,1108 # ffffffffc0205c88 <etext+0x1914>
ffffffffc020383c:	87ffc0ef          	jal	ffffffffc02000ba <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203840:	e23fd0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc0203844:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203846:	03000513          	li	a0,48
ffffffffc020384a:	f6ffe0ef          	jal	ffffffffc02027b8 <kmalloc>
ffffffffc020384e:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203850:	1e050063          	beqz	a0,ffffffffc0203a30 <vmm_init+0x394>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203854:	0000e797          	auipc	a5,0xe
ffffffffc0203858:	cec7a783          	lw	a5,-788(a5) # ffffffffc0211540 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc020385c:	e508                	sd	a0,8(a0)
ffffffffc020385e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203860:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203864:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203868:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020386c:	1e079663          	bnez	a5,ffffffffc0203a58 <vmm_init+0x3bc>
        else mm->sm_priv = NULL;
ffffffffc0203870:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();

    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203874:	0000ea17          	auipc	s4,0xe
ffffffffc0203878:	caca3a03          	ld	s4,-852(s4) # ffffffffc0211520 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc020387c:	000a3783          	ld	a5,0(s4)
    check_mm_struct = mm_create();
ffffffffc0203880:	0000e717          	auipc	a4,0xe
ffffffffc0203884:	ce873423          	sd	s0,-792(a4) # ffffffffc0211568 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203888:	01443c23          	sd	s4,24(s0)
    assert(pgdir[0] == 0);
ffffffffc020388c:	2e079963          	bnez	a5,ffffffffc0203b7e <vmm_init+0x4e2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203890:	03000513          	li	a0,48
ffffffffc0203894:	f25fe0ef          	jal	ffffffffc02027b8 <kmalloc>
ffffffffc0203898:	892a                	mv	s2,a0
    if (vma != NULL) {
ffffffffc020389a:	16050b63          	beqz	a0,ffffffffc0203a10 <vmm_init+0x374>
        vma->vm_end = vm_end;
ffffffffc020389e:	002007b7          	lui	a5,0x200
ffffffffc02038a2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038a4:	4789                	li	a5,2
ffffffffc02038a6:	ed1c                	sd	a5,24(a0)

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02038a8:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02038aa:	00053423          	sd	zero,8(a0)
    insert_vma_struct(mm, vma);
ffffffffc02038ae:	8522                	mv	a0,s0
ffffffffc02038b0:	ce7ff0ef          	jal	ffffffffc0203596 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02038b4:	10000593          	li	a1,256
ffffffffc02038b8:	8522                	mv	a0,s0
ffffffffc02038ba:	c9dff0ef          	jal	ffffffffc0203556 <find_vma>
ffffffffc02038be:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc02038c2:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02038c6:	30a91663          	bne	s2,a0,ffffffffc0203bd2 <vmm_init+0x536>
        *(char *)(addr + i) = i;
ffffffffc02038ca:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc02038ce:	0785                	add	a5,a5,1
ffffffffc02038d0:	fee79de3          	bne	a5,a4,ffffffffc02038ca <vmm_init+0x22e>
ffffffffc02038d4:	6705                	lui	a4,0x1
ffffffffc02038d6:	10000793          	li	a5,256
ffffffffc02038da:	35670713          	add	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02038de:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02038e2:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc02038e6:	0785                	add	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc02038e8:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02038ea:	fec79ce3          	bne	a5,a2,ffffffffc02038e2 <vmm_init+0x246>
    }
    assert(sum == 0);
ffffffffc02038ee:	32071e63          	bnez	a4,ffffffffc0203c2a <vmm_init+0x58e>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02038f2:	4581                	li	a1,0
ffffffffc02038f4:	8552                	mv	a0,s4
ffffffffc02038f6:	82efe0ef          	jal	ffffffffc0201924 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02038fa:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02038fe:	0000e717          	auipc	a4,0xe
ffffffffc0203902:	c3273703          	ld	a4,-974(a4) # ffffffffc0211530 <npage>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203906:	078a                	sll	a5,a5,0x2
ffffffffc0203908:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020390a:	30e7f463          	bgeu	a5,a4,ffffffffc0203c12 <vmm_init+0x576>
    return &pages[PPN(pa) - nbase];
ffffffffc020390e:	00003717          	auipc	a4,0x3
ffffffffc0203912:	82a73703          	ld	a4,-2006(a4) # ffffffffc0206138 <nbase>
ffffffffc0203916:	8f99                	sub	a5,a5,a4
ffffffffc0203918:	00379713          	sll	a4,a5,0x3
ffffffffc020391c:	97ba                	add	a5,a5,a4
ffffffffc020391e:	078e                	sll	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc0203920:	0000e517          	auipc	a0,0xe
ffffffffc0203924:	c1853503          	ld	a0,-1000(a0) # ffffffffc0211538 <pages>
ffffffffc0203928:	953e                	add	a0,a0,a5
ffffffffc020392a:	4585                	li	a1,1
ffffffffc020392c:	cf7fd0ef          	jal	ffffffffc0201622 <free_pages>
    return listelm->next;
ffffffffc0203930:	6408                	ld	a0,8(s0)

    pgdir[0] = 0;
ffffffffc0203932:	000a3023          	sd	zero,0(s4)

    mm->pgdir = NULL;
ffffffffc0203936:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020393a:	00850e63          	beq	a0,s0,ffffffffc0203956 <vmm_init+0x2ba>
    __list_del(listelm->prev, listelm->next);
ffffffffc020393e:	6118                	ld	a4,0(a0)
ffffffffc0203940:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203942:	03000593          	li	a1,48
ffffffffc0203946:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc0203948:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020394a:	e398                	sd	a4,0(a5)
ffffffffc020394c:	f39fe0ef          	jal	ffffffffc0202884 <kfree>
    return listelm->next;
ffffffffc0203950:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203952:	fea416e3          	bne	s0,a0,ffffffffc020393e <vmm_init+0x2a2>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203956:	03000593          	li	a1,48
ffffffffc020395a:	8522                	mv	a0,s0
ffffffffc020395c:	f29fe0ef          	jal	ffffffffc0202884 <kfree>
    mm_destroy(mm);

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0203960:	14fd                	add	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc0203962:	0000e797          	auipc	a5,0xe
ffffffffc0203966:	c007b323          	sd	zero,-1018(a5) # ffffffffc0211568 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020396a:	cf9fd0ef          	jal	ffffffffc0201662 <nr_free_pages>
ffffffffc020396e:	2ea49e63          	bne	s1,a0,ffffffffc0203c6a <vmm_init+0x5ce>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203972:	00002517          	auipc	a0,0x2
ffffffffc0203976:	37e50513          	add	a0,a0,894 # ffffffffc0205cf0 <etext+0x197c>
ffffffffc020397a:	f40fc0ef          	jal	ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020397e:	ce5fd0ef          	jal	ffffffffc0201662 <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0203982:	19fd                	add	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203984:	2ca99363          	bne	s3,a0,ffffffffc0203c4a <vmm_init+0x5ae>
}
ffffffffc0203988:	6406                	ld	s0,64(sp)
ffffffffc020398a:	60a6                	ld	ra,72(sp)
ffffffffc020398c:	74e2                	ld	s1,56(sp)
ffffffffc020398e:	7942                	ld	s2,48(sp)
ffffffffc0203990:	79a2                	ld	s3,40(sp)
ffffffffc0203992:	7a02                	ld	s4,32(sp)
ffffffffc0203994:	6ae2                	ld	s5,24(sp)
ffffffffc0203996:	6b42                	ld	s6,16(sp)
ffffffffc0203998:	6ba2                	ld	s7,8(sp)
ffffffffc020399a:	6c02                	ld	s8,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020399c:	00002517          	auipc	a0,0x2
ffffffffc02039a0:	37450513          	add	a0,a0,884 # ffffffffc0205d10 <etext+0x199c>
}
ffffffffc02039a4:	6161                	add	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc02039a6:	f14fc06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02039aa:	e54ff0ef          	jal	ffffffffc0202ffe <swap_init_mm>
    for (i = step1; i >= 1; i --) {
ffffffffc02039ae:	bb3d                	j	ffffffffc02036ec <vmm_init+0x50>
        assert(vma != NULL);
ffffffffc02039b0:	00002697          	auipc	a3,0x2
ffffffffc02039b4:	d4868693          	add	a3,a3,-696 # ffffffffc02056f8 <etext+0x1384>
ffffffffc02039b8:	00001617          	auipc	a2,0x1
ffffffffc02039bc:	29860613          	add	a2,a2,664 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02039c0:	0ce00593          	li	a1,206
ffffffffc02039c4:	00002517          	auipc	a0,0x2
ffffffffc02039c8:	0ec50513          	add	a0,a0,236 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc02039cc:	995fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(mm != NULL);
ffffffffc02039d0:	00002697          	auipc	a3,0x2
ffffffffc02039d4:	cf068693          	add	a3,a3,-784 # ffffffffc02056c0 <etext+0x134c>
ffffffffc02039d8:	00001617          	auipc	a2,0x1
ffffffffc02039dc:	27860613          	add	a2,a2,632 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc02039e0:	0c700593          	li	a1,199
ffffffffc02039e4:	00002517          	auipc	a0,0x2
ffffffffc02039e8:	0cc50513          	add	a0,a0,204 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc02039ec:	975fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma != NULL);
ffffffffc02039f0:	00002697          	auipc	a3,0x2
ffffffffc02039f4:	d0868693          	add	a3,a3,-760 # ffffffffc02056f8 <etext+0x1384>
ffffffffc02039f8:	00001617          	auipc	a2,0x1
ffffffffc02039fc:	25860613          	add	a2,a2,600 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203a00:	0d400593          	li	a1,212
ffffffffc0203a04:	00002517          	auipc	a0,0x2
ffffffffc0203a08:	0ac50513          	add	a0,a0,172 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203a0c:	955fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(vma != NULL);
ffffffffc0203a10:	00002697          	auipc	a3,0x2
ffffffffc0203a14:	ce868693          	add	a3,a3,-792 # ffffffffc02056f8 <etext+0x1384>
ffffffffc0203a18:	00001617          	auipc	a2,0x1
ffffffffc0203a1c:	23860613          	add	a2,a2,568 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203a20:	11100593          	li	a1,273
ffffffffc0203a24:	00002517          	auipc	a0,0x2
ffffffffc0203a28:	08c50513          	add	a0,a0,140 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203a2c:	935fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203a30:	00002697          	auipc	a3,0x2
ffffffffc0203a34:	27868693          	add	a3,a3,632 # ffffffffc0205ca8 <etext+0x1934>
ffffffffc0203a38:	00001617          	auipc	a2,0x1
ffffffffc0203a3c:	21860613          	add	a2,a2,536 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203a40:	10a00593          	li	a1,266
ffffffffc0203a44:	00002517          	auipc	a0,0x2
ffffffffc0203a48:	06c50513          	add	a0,a0,108 # ffffffffc0205ab0 <etext+0x173c>
    check_mm_struct = mm_create();
ffffffffc0203a4c:	0000e797          	auipc	a5,0xe
ffffffffc0203a50:	b007be23          	sd	zero,-1252(a5) # ffffffffc0211568 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc0203a54:	90dfc0ef          	jal	ffffffffc0200360 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a58:	da6ff0ef          	jal	ffffffffc0202ffe <swap_init_mm>
    assert(check_mm_struct != NULL);
ffffffffc0203a5c:	bd21                	j	ffffffffc0203874 <vmm_init+0x1d8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203a5e:	00002697          	auipc	a3,0x2
ffffffffc0203a62:	19268693          	add	a3,a3,402 # ffffffffc0205bf0 <etext+0x187c>
ffffffffc0203a66:	00001617          	auipc	a2,0x1
ffffffffc0203a6a:	1ea60613          	add	a2,a2,490 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203a6e:	0ee00593          	li	a1,238
ffffffffc0203a72:	00002517          	auipc	a0,0x2
ffffffffc0203a76:	03e50513          	add	a0,a0,62 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203a7a:	8e7fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203a7e:	00002697          	auipc	a3,0x2
ffffffffc0203a82:	14268693          	add	a3,a3,322 # ffffffffc0205bc0 <etext+0x184c>
ffffffffc0203a86:	00001617          	auipc	a2,0x1
ffffffffc0203a8a:	1ca60613          	add	a2,a2,458 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203a8e:	0ed00593          	li	a1,237
ffffffffc0203a92:	00002517          	auipc	a0,0x2
ffffffffc0203a96:	01e50513          	add	a0,a0,30 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203a9a:	8c7fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203a9e:	00002697          	auipc	a3,0x2
ffffffffc0203aa2:	09a68693          	add	a3,a3,154 # ffffffffc0205b38 <etext+0x17c4>
ffffffffc0203aa6:	00001617          	auipc	a2,0x1
ffffffffc0203aaa:	1aa60613          	add	a2,a2,426 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203aae:	0dd00593          	li	a1,221
ffffffffc0203ab2:	00002517          	auipc	a0,0x2
ffffffffc0203ab6:	ffe50513          	add	a0,a0,-2 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203aba:	8a7fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma4 == NULL);
ffffffffc0203abe:	00002697          	auipc	a3,0x2
ffffffffc0203ac2:	0e268693          	add	a3,a3,226 # ffffffffc0205ba0 <etext+0x182c>
ffffffffc0203ac6:	00001617          	auipc	a2,0x1
ffffffffc0203aca:	18a60613          	add	a2,a2,394 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203ace:	0e900593          	li	a1,233
ffffffffc0203ad2:	00002517          	auipc	a0,0x2
ffffffffc0203ad6:	fde50513          	add	a0,a0,-34 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203ada:	887fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma3 == NULL);
ffffffffc0203ade:	00002697          	auipc	a3,0x2
ffffffffc0203ae2:	0b268693          	add	a3,a3,178 # ffffffffc0205b90 <etext+0x181c>
ffffffffc0203ae6:	00001617          	auipc	a2,0x1
ffffffffc0203aea:	16a60613          	add	a2,a2,362 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203aee:	0e700593          	li	a1,231
ffffffffc0203af2:	00002517          	auipc	a0,0x2
ffffffffc0203af6:	fbe50513          	add	a0,a0,-66 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203afa:	867fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma5 == NULL);
ffffffffc0203afe:	00002697          	auipc	a3,0x2
ffffffffc0203b02:	0b268693          	add	a3,a3,178 # ffffffffc0205bb0 <etext+0x183c>
ffffffffc0203b06:	00001617          	auipc	a2,0x1
ffffffffc0203b0a:	14a60613          	add	a2,a2,330 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203b0e:	0eb00593          	li	a1,235
ffffffffc0203b12:	00002517          	auipc	a0,0x2
ffffffffc0203b16:	f9e50513          	add	a0,a0,-98 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203b1a:	847fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203b1e:	00002697          	auipc	a3,0x2
ffffffffc0203b22:	00268693          	add	a3,a3,2 # ffffffffc0205b20 <etext+0x17ac>
ffffffffc0203b26:	00001617          	auipc	a2,0x1
ffffffffc0203b2a:	12a60613          	add	a2,a2,298 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203b2e:	0db00593          	li	a1,219
ffffffffc0203b32:	00002517          	auipc	a0,0x2
ffffffffc0203b36:	f7e50513          	add	a0,a0,-130 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203b3a:	827fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma2 != NULL);
ffffffffc0203b3e:	00002697          	auipc	a3,0x2
ffffffffc0203b42:	04268693          	add	a3,a3,66 # ffffffffc0205b80 <etext+0x180c>
ffffffffc0203b46:	00001617          	auipc	a2,0x1
ffffffffc0203b4a:	10a60613          	add	a2,a2,266 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203b4e:	0e500593          	li	a1,229
ffffffffc0203b52:	00002517          	auipc	a0,0x2
ffffffffc0203b56:	f5e50513          	add	a0,a0,-162 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203b5a:	807fc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1 != NULL);
ffffffffc0203b5e:	00002697          	auipc	a3,0x2
ffffffffc0203b62:	01268693          	add	a3,a3,18 # ffffffffc0205b70 <etext+0x17fc>
ffffffffc0203b66:	00001617          	auipc	a2,0x1
ffffffffc0203b6a:	0ea60613          	add	a2,a2,234 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203b6e:	0e300593          	li	a1,227
ffffffffc0203b72:	00002517          	auipc	a0,0x2
ffffffffc0203b76:	f3e50513          	add	a0,a0,-194 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203b7a:	fe6fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203b7e:	00002697          	auipc	a3,0x2
ffffffffc0203b82:	b6a68693          	add	a3,a3,-1174 # ffffffffc02056e8 <etext+0x1374>
ffffffffc0203b86:	00001617          	auipc	a2,0x1
ffffffffc0203b8a:	0ca60613          	add	a2,a2,202 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203b8e:	10d00593          	li	a1,269
ffffffffc0203b92:	00002517          	auipc	a0,0x2
ffffffffc0203b96:	f1e50513          	add	a0,a0,-226 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203b9a:	fc6fc0ef          	jal	ffffffffc0200360 <__panic>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203b9e:	6914                	ld	a3,16(a0)
ffffffffc0203ba0:	6510                	ld	a2,8(a0)
ffffffffc0203ba2:	0004859b          	sext.w	a1,s1
ffffffffc0203ba6:	00002517          	auipc	a0,0x2
ffffffffc0203baa:	07a50513          	add	a0,a0,122 # ffffffffc0205c20 <etext+0x18ac>
ffffffffc0203bae:	d0cfc0ef          	jal	ffffffffc02000ba <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203bb2:	00002697          	auipc	a3,0x2
ffffffffc0203bb6:	09668693          	add	a3,a3,150 # ffffffffc0205c48 <etext+0x18d4>
ffffffffc0203bba:	00001617          	auipc	a2,0x1
ffffffffc0203bbe:	09660613          	add	a2,a2,150 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203bc2:	0f600593          	li	a1,246
ffffffffc0203bc6:	00002517          	auipc	a0,0x2
ffffffffc0203bca:	eea50513          	add	a0,a0,-278 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203bce:	f92fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203bd2:	00002697          	auipc	a3,0x2
ffffffffc0203bd6:	0ee68693          	add	a3,a3,238 # ffffffffc0205cc0 <etext+0x194c>
ffffffffc0203bda:	00001617          	auipc	a2,0x1
ffffffffc0203bde:	07660613          	add	a2,a2,118 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203be2:	11600593          	li	a1,278
ffffffffc0203be6:	00002517          	auipc	a0,0x2
ffffffffc0203bea:	eca50513          	add	a0,a0,-310 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203bee:	f72fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203bf2:	00002697          	auipc	a3,0x2
ffffffffc0203bf6:	06e68693          	add	a3,a3,110 # ffffffffc0205c60 <etext+0x18ec>
ffffffffc0203bfa:	00001617          	auipc	a2,0x1
ffffffffc0203bfe:	05660613          	add	a2,a2,86 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203c02:	0fb00593          	li	a1,251
ffffffffc0203c06:	00002517          	auipc	a0,0x2
ffffffffc0203c0a:	eaa50513          	add	a0,a0,-342 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203c0e:	f52fc0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203c12:	00001617          	auipc	a2,0x1
ffffffffc0203c16:	3ee60613          	add	a2,a2,1006 # ffffffffc0205000 <etext+0xc8c>
ffffffffc0203c1a:	06500593          	li	a1,101
ffffffffc0203c1e:	00001517          	auipc	a0,0x1
ffffffffc0203c22:	40250513          	add	a0,a0,1026 # ffffffffc0205020 <etext+0xcac>
ffffffffc0203c26:	f3afc0ef          	jal	ffffffffc0200360 <__panic>
    assert(sum == 0);
ffffffffc0203c2a:	00002697          	auipc	a3,0x2
ffffffffc0203c2e:	0b668693          	add	a3,a3,182 # ffffffffc0205ce0 <etext+0x196c>
ffffffffc0203c32:	00001617          	auipc	a2,0x1
ffffffffc0203c36:	01e60613          	add	a2,a2,30 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203c3a:	12000593          	li	a1,288
ffffffffc0203c3e:	00002517          	auipc	a0,0x2
ffffffffc0203c42:	e7250513          	add	a0,a0,-398 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203c46:	f1afc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203c4a:	00002697          	auipc	a3,0x2
ffffffffc0203c4e:	01668693          	add	a3,a3,22 # ffffffffc0205c60 <etext+0x18ec>
ffffffffc0203c52:	00001617          	auipc	a2,0x1
ffffffffc0203c56:	ffe60613          	add	a2,a2,-2 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203c5a:	0bd00593          	li	a1,189
ffffffffc0203c5e:	00002517          	auipc	a0,0x2
ffffffffc0203c62:	e5250513          	add	a0,a0,-430 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203c66:	efafc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203c6a:	00002697          	auipc	a3,0x2
ffffffffc0203c6e:	ff668693          	add	a3,a3,-10 # ffffffffc0205c60 <etext+0x18ec>
ffffffffc0203c72:	00001617          	auipc	a2,0x1
ffffffffc0203c76:	fde60613          	add	a2,a2,-34 # ffffffffc0204c50 <etext+0x8dc>
ffffffffc0203c7a:	12e00593          	li	a1,302
ffffffffc0203c7e:	00002517          	auipc	a0,0x2
ffffffffc0203c82:	e3250513          	add	a0,a0,-462 # ffffffffc0205ab0 <etext+0x173c>
ffffffffc0203c86:	edafc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203c8a <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203c8a:	1101                	add	sp,sp,-32
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203c8c:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203c8e:	e822                	sd	s0,16(sp)
ffffffffc0203c90:	e426                	sd	s1,8(sp)
ffffffffc0203c92:	ec06                	sd	ra,24(sp)
ffffffffc0203c94:	8432                	mv	s0,a2
ffffffffc0203c96:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203c98:	8bfff0ef          	jal	ffffffffc0203556 <find_vma>

    pgfault_num++;
ffffffffc0203c9c:	0000e797          	auipc	a5,0xe
ffffffffc0203ca0:	8c47a783          	lw	a5,-1852(a5) # ffffffffc0211560 <pgfault_num>
ffffffffc0203ca4:	2785                	addw	a5,a5,1
ffffffffc0203ca6:	0000e717          	auipc	a4,0xe
ffffffffc0203caa:	8af72d23          	sw	a5,-1862(a4) # ffffffffc0211560 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203cae:	c931                	beqz	a0,ffffffffc0203d02 <do_pgfault+0x78>
ffffffffc0203cb0:	651c                	ld	a5,8(a0)
ffffffffc0203cb2:	04f46863          	bltu	s0,a5,ffffffffc0203d02 <do_pgfault+0x78>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203cb6:	6d1c                	ld	a5,24(a0)
ffffffffc0203cb8:	e04a                	sd	s2,0(sp)
        perm |= (PTE_R | PTE_W);
ffffffffc0203cba:	4959                	li	s2,22
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203cbc:	8b89                	and	a5,a5,2
ffffffffc0203cbe:	c395                	beqz	a5,ffffffffc0203ce2 <do_pgfault+0x58>
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203cc0:	77fd                	lui	a5,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203cc2:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203cc4:	8c7d                	and	s0,s0,a5
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203cc6:	85a2                	mv	a1,s0
ffffffffc0203cc8:	4605                	li	a2,1
ffffffffc0203cca:	9d3fd0ef          	jal	ffffffffc020169c <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc0203cce:	610c                	ld	a1,0(a0)
ffffffffc0203cd0:	c999                	beqz	a1,ffffffffc0203ce6 <do_pgfault+0x5c>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0203cd2:	0000e797          	auipc	a5,0xe
ffffffffc0203cd6:	86e7a783          	lw	a5,-1938(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc0203cda:	cf8d                	beqz	a5,ffffffffc0203d14 <do_pgfault+0x8a>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            page->pra_vaddr = addr;
ffffffffc0203cdc:	04003023          	sd	zero,64(zero) # 40 <kern_entry-0xffffffffc01fffc0>
ffffffffc0203ce0:	9002                	ebreak
    uint32_t perm = PTE_U;
ffffffffc0203ce2:	4941                	li	s2,16
ffffffffc0203ce4:	bff1                	j	ffffffffc0203cc0 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203ce6:	6c88                	ld	a0,24(s1)
ffffffffc0203ce8:	864a                	mv	a2,s2
ffffffffc0203cea:	85a2                	mv	a1,s0
ffffffffc0203cec:	a15fe0ef          	jal	ffffffffc0202700 <pgdir_alloc_page>
ffffffffc0203cf0:	87aa                	mv	a5,a0
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0203cf2:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203cf4:	cb8d                	beqz	a5,ffffffffc0203d26 <do_pgfault+0x9c>
ffffffffc0203cf6:	6902                	ld	s2,0(sp)
failed:
    return ret;
}
ffffffffc0203cf8:	60e2                	ld	ra,24(sp)
ffffffffc0203cfa:	6442                	ld	s0,16(sp)
ffffffffc0203cfc:	64a2                	ld	s1,8(sp)
ffffffffc0203cfe:	6105                	add	sp,sp,32
ffffffffc0203d00:	8082                	ret
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203d02:	85a2                	mv	a1,s0
ffffffffc0203d04:	00002517          	auipc	a0,0x2
ffffffffc0203d08:	02450513          	add	a0,a0,36 # ffffffffc0205d28 <etext+0x19b4>
ffffffffc0203d0c:	baefc0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc0203d10:	5575                	li	a0,-3
        goto failed;
ffffffffc0203d12:	b7dd                	j	ffffffffc0203cf8 <do_pgfault+0x6e>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203d14:	00002517          	auipc	a0,0x2
ffffffffc0203d18:	06c50513          	add	a0,a0,108 # ffffffffc0205d80 <etext+0x1a0c>
ffffffffc0203d1c:	b9efc0ef          	jal	ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203d20:	6902                	ld	s2,0(sp)
ffffffffc0203d22:	5571                	li	a0,-4
ffffffffc0203d24:	bfd1                	j	ffffffffc0203cf8 <do_pgfault+0x6e>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203d26:	00002517          	auipc	a0,0x2
ffffffffc0203d2a:	03250513          	add	a0,a0,50 # ffffffffc0205d58 <etext+0x19e4>
ffffffffc0203d2e:	b8cfc0ef          	jal	ffffffffc02000ba <cprintf>
            goto failed;
ffffffffc0203d32:	b7fd                	j	ffffffffc0203d20 <do_pgfault+0x96>

ffffffffc0203d34 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203d34:	1141                	add	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203d36:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203d38:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203d3a:	f48fc0ef          	jal	ffffffffc0200482 <ide_device_valid>
ffffffffc0203d3e:	cd01                	beqz	a0,ffffffffc0203d56 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203d40:	4505                	li	a0,1
ffffffffc0203d42:	f46fc0ef          	jal	ffffffffc0200488 <ide_device_size>
}
ffffffffc0203d46:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203d48:	810d                	srl	a0,a0,0x3
ffffffffc0203d4a:	0000d797          	auipc	a5,0xd
ffffffffc0203d4e:	7ea7bf23          	sd	a0,2046(a5) # ffffffffc0211548 <max_swap_offset>
}
ffffffffc0203d52:	0141                	add	sp,sp,16
ffffffffc0203d54:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203d56:	00002617          	auipc	a2,0x2
ffffffffc0203d5a:	05260613          	add	a2,a2,82 # ffffffffc0205da8 <etext+0x1a34>
ffffffffc0203d5e:	45b5                	li	a1,13
ffffffffc0203d60:	00002517          	auipc	a0,0x2
ffffffffc0203d64:	06850513          	add	a0,a0,104 # ffffffffc0205dc8 <etext+0x1a54>
ffffffffc0203d68:	df8fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203d6c <swapfs_write>:
swapfs_read(swap_entry_t entry, struct Page *page) {
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203d6c:	1141                	add	sp,sp,-16
ffffffffc0203d6e:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d70:	00855713          	srl	a4,a0,0x8
ffffffffc0203d74:	cb2d                	beqz	a4,ffffffffc0203de6 <swapfs_write+0x7a>
ffffffffc0203d76:	0000d797          	auipc	a5,0xd
ffffffffc0203d7a:	7d27b783          	ld	a5,2002(a5) # ffffffffc0211548 <max_swap_offset>
ffffffffc0203d7e:	06f77463          	bgeu	a4,a5,ffffffffc0203de6 <swapfs_write+0x7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203d82:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0203d86:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0203d8a:	07b2                	sll	a5,a5,0xc
ffffffffc0203d8c:	e3978793          	add	a5,a5,-455
ffffffffc0203d90:	07b2                	sll	a5,a5,0xc
ffffffffc0203d92:	0000d697          	auipc	a3,0xd
ffffffffc0203d96:	7a66b683          	ld	a3,1958(a3) # ffffffffc0211538 <pages>
ffffffffc0203d9a:	e3978793          	add	a5,a5,-455
ffffffffc0203d9e:	8d95                	sub	a1,a1,a3
ffffffffc0203da0:	07b2                	sll	a5,a5,0xc
ffffffffc0203da2:	4035d613          	sra	a2,a1,0x3
ffffffffc0203da6:	e3978793          	add	a5,a5,-455
ffffffffc0203daa:	02f60633          	mul	a2,a2,a5
ffffffffc0203dae:	00002797          	auipc	a5,0x2
ffffffffc0203db2:	38a7b783          	ld	a5,906(a5) # ffffffffc0206138 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203db6:	0000d697          	auipc	a3,0xd
ffffffffc0203dba:	77a6b683          	ld	a3,1914(a3) # ffffffffc0211530 <npage>
ffffffffc0203dbe:	0037159b          	sllw	a1,a4,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203dc2:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203dc4:	00c61793          	sll	a5,a2,0xc
ffffffffc0203dc8:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203dca:	0632                	sll	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203dcc:	02d7f963          	bgeu	a5,a3,ffffffffc0203dfe <swapfs_write+0x92>
}
ffffffffc0203dd0:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dd2:	0000d797          	auipc	a5,0xd
ffffffffc0203dd6:	7567b783          	ld	a5,1878(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc0203dda:	46a1                	li	a3,8
ffffffffc0203ddc:	963e                	add	a2,a2,a5
ffffffffc0203dde:	4505                	li	a0,1
}
ffffffffc0203de0:	0141                	add	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203de2:	eacfc06f          	j	ffffffffc020048e <ide_write_secs>
ffffffffc0203de6:	86aa                	mv	a3,a0
ffffffffc0203de8:	00002617          	auipc	a2,0x2
ffffffffc0203dec:	ff860613          	add	a2,a2,-8 # ffffffffc0205de0 <etext+0x1a6c>
ffffffffc0203df0:	45e5                	li	a1,25
ffffffffc0203df2:	00002517          	auipc	a0,0x2
ffffffffc0203df6:	fd650513          	add	a0,a0,-42 # ffffffffc0205dc8 <etext+0x1a54>
ffffffffc0203dfa:	d66fc0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0203dfe:	86b2                	mv	a3,a2
ffffffffc0203e00:	06a00593          	li	a1,106
ffffffffc0203e04:	00001617          	auipc	a2,0x1
ffffffffc0203e08:	25460613          	add	a2,a2,596 # ffffffffc0205058 <etext+0xce4>
ffffffffc0203e0c:	00001517          	auipc	a0,0x1
ffffffffc0203e10:	21450513          	add	a0,a0,532 # ffffffffc0205020 <etext+0xcac>
ffffffffc0203e14:	d4cfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203e18 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203e18:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e1c:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203e1e:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e22:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203e24:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203e28:	f022                	sd	s0,32(sp)
ffffffffc0203e2a:	ec26                	sd	s1,24(sp)
ffffffffc0203e2c:	e84a                	sd	s2,16(sp)
ffffffffc0203e2e:	f406                	sd	ra,40(sp)
ffffffffc0203e30:	84aa                	mv	s1,a0
ffffffffc0203e32:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203e34:	fff7041b          	addw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203e38:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203e3a:	05067063          	bgeu	a2,a6,ffffffffc0203e7a <printnum+0x62>
ffffffffc0203e3e:	e44e                	sd	s3,8(sp)
ffffffffc0203e40:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203e42:	4785                	li	a5,1
ffffffffc0203e44:	00e7d763          	bge	a5,a4,ffffffffc0203e52 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0203e48:	85ca                	mv	a1,s2
ffffffffc0203e4a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203e4c:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203e4e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203e50:	fc65                	bnez	s0,ffffffffc0203e48 <printnum+0x30>
ffffffffc0203e52:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e54:	1a02                	sll	s4,s4,0x20
ffffffffc0203e56:	020a5a13          	srl	s4,s4,0x20
ffffffffc0203e5a:	00002797          	auipc	a5,0x2
ffffffffc0203e5e:	fa678793          	add	a5,a5,-90 # ffffffffc0205e00 <etext+0x1a8c>
ffffffffc0203e62:	97d2                	add	a5,a5,s4
}
ffffffffc0203e64:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e66:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0203e6a:	70a2                	ld	ra,40(sp)
ffffffffc0203e6c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e6e:	85ca                	mv	a1,s2
ffffffffc0203e70:	87a6                	mv	a5,s1
}
ffffffffc0203e72:	6942                	ld	s2,16(sp)
ffffffffc0203e74:	64e2                	ld	s1,24(sp)
ffffffffc0203e76:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203e78:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203e7a:	03065633          	divu	a2,a2,a6
ffffffffc0203e7e:	8722                	mv	a4,s0
ffffffffc0203e80:	f99ff0ef          	jal	ffffffffc0203e18 <printnum>
ffffffffc0203e84:	bfc1                	j	ffffffffc0203e54 <printnum+0x3c>

ffffffffc0203e86 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203e86:	7119                	add	sp,sp,-128
ffffffffc0203e88:	f4a6                	sd	s1,104(sp)
ffffffffc0203e8a:	f0ca                	sd	s2,96(sp)
ffffffffc0203e8c:	ecce                	sd	s3,88(sp)
ffffffffc0203e8e:	e8d2                	sd	s4,80(sp)
ffffffffc0203e90:	e4d6                	sd	s5,72(sp)
ffffffffc0203e92:	e0da                	sd	s6,64(sp)
ffffffffc0203e94:	f862                	sd	s8,48(sp)
ffffffffc0203e96:	fc86                	sd	ra,120(sp)
ffffffffc0203e98:	f8a2                	sd	s0,112(sp)
ffffffffc0203e9a:	fc5e                	sd	s7,56(sp)
ffffffffc0203e9c:	f466                	sd	s9,40(sp)
ffffffffc0203e9e:	f06a                	sd	s10,32(sp)
ffffffffc0203ea0:	ec6e                	sd	s11,24(sp)
ffffffffc0203ea2:	892a                	mv	s2,a0
ffffffffc0203ea4:	84ae                	mv	s1,a1
ffffffffc0203ea6:	8c32                	mv	s8,a2
ffffffffc0203ea8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eaa:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203eae:	05500b13          	li	s6,85
ffffffffc0203eb2:	00002a97          	auipc	s5,0x2
ffffffffc0203eb6:	0f6a8a93          	add	s5,s5,246 # ffffffffc0205fa8 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203eba:	000c4503          	lbu	a0,0(s8)
ffffffffc0203ebe:	001c0413          	add	s0,s8,1
ffffffffc0203ec2:	01350a63          	beq	a0,s3,ffffffffc0203ed6 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0203ec6:	cd0d                	beqz	a0,ffffffffc0203f00 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0203ec8:	85a6                	mv	a1,s1
ffffffffc0203eca:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203ecc:	00044503          	lbu	a0,0(s0)
ffffffffc0203ed0:	0405                	add	s0,s0,1
ffffffffc0203ed2:	ff351ae3          	bne	a0,s3,ffffffffc0203ec6 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0203ed6:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0203eda:	4b81                	li	s7,0
ffffffffc0203edc:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0203ede:	5d7d                	li	s10,-1
ffffffffc0203ee0:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ee2:	00044683          	lbu	a3,0(s0)
ffffffffc0203ee6:	00140c13          	add	s8,s0,1
ffffffffc0203eea:	fdd6859b          	addw	a1,a3,-35
ffffffffc0203eee:	0ff5f593          	zext.b	a1,a1
ffffffffc0203ef2:	02bb6663          	bltu	s6,a1,ffffffffc0203f1e <vprintfmt+0x98>
ffffffffc0203ef6:	058a                	sll	a1,a1,0x2
ffffffffc0203ef8:	95d6                	add	a1,a1,s5
ffffffffc0203efa:	4198                	lw	a4,0(a1)
ffffffffc0203efc:	9756                	add	a4,a4,s5
ffffffffc0203efe:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203f00:	70e6                	ld	ra,120(sp)
ffffffffc0203f02:	7446                	ld	s0,112(sp)
ffffffffc0203f04:	74a6                	ld	s1,104(sp)
ffffffffc0203f06:	7906                	ld	s2,96(sp)
ffffffffc0203f08:	69e6                	ld	s3,88(sp)
ffffffffc0203f0a:	6a46                	ld	s4,80(sp)
ffffffffc0203f0c:	6aa6                	ld	s5,72(sp)
ffffffffc0203f0e:	6b06                	ld	s6,64(sp)
ffffffffc0203f10:	7be2                	ld	s7,56(sp)
ffffffffc0203f12:	7c42                	ld	s8,48(sp)
ffffffffc0203f14:	7ca2                	ld	s9,40(sp)
ffffffffc0203f16:	7d02                	ld	s10,32(sp)
ffffffffc0203f18:	6de2                	ld	s11,24(sp)
ffffffffc0203f1a:	6109                	add	sp,sp,128
ffffffffc0203f1c:	8082                	ret
            putch('%', putdat);
ffffffffc0203f1e:	85a6                	mv	a1,s1
ffffffffc0203f20:	02500513          	li	a0,37
ffffffffc0203f24:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203f26:	fff44703          	lbu	a4,-1(s0)
ffffffffc0203f2a:	02500793          	li	a5,37
ffffffffc0203f2e:	8c22                	mv	s8,s0
ffffffffc0203f30:	f8f705e3          	beq	a4,a5,ffffffffc0203eba <vprintfmt+0x34>
ffffffffc0203f34:	02500713          	li	a4,37
ffffffffc0203f38:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203f3c:	1c7d                	add	s8,s8,-1
ffffffffc0203f3e:	fee79de3          	bne	a5,a4,ffffffffc0203f38 <vprintfmt+0xb2>
ffffffffc0203f42:	bfa5                	j	ffffffffc0203eba <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203f44:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203f48:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0203f4a:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203f4e:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc0203f52:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f56:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0203f58:	02b76563          	bltu	a4,a1,ffffffffc0203f82 <vprintfmt+0xfc>
ffffffffc0203f5c:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0203f5e:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203f62:	002d171b          	sllw	a4,s10,0x2
ffffffffc0203f66:	01a7073b          	addw	a4,a4,s10
ffffffffc0203f6a:	0017171b          	sllw	a4,a4,0x1
ffffffffc0203f6e:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203f70:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203f74:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203f76:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc0203f7a:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0203f7e:	feb570e3          	bgeu	a0,a1,ffffffffc0203f5e <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0203f82:	f60cd0e3          	bgez	s9,ffffffffc0203ee2 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203f86:	8cea                	mv	s9,s10
ffffffffc0203f88:	5d7d                	li	s10,-1
ffffffffc0203f8a:	bfa1                	j	ffffffffc0203ee2 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203f8c:	8db6                	mv	s11,a3
ffffffffc0203f8e:	8462                	mv	s0,s8
ffffffffc0203f90:	bf89                	j	ffffffffc0203ee2 <vprintfmt+0x5c>
ffffffffc0203f92:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203f94:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203f96:	b7b1                	j	ffffffffc0203ee2 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203f98:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203f9a:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0203f9e:	00c7c463          	blt	a5,a2,ffffffffc0203fa6 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0203fa2:	1a060163          	beqz	a2,ffffffffc0204144 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0203fa6:	000a3603          	ld	a2,0(s4)
ffffffffc0203faa:	46c1                	li	a3,16
ffffffffc0203fac:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203fae:	000d879b          	sext.w	a5,s11
ffffffffc0203fb2:	8766                	mv	a4,s9
ffffffffc0203fb4:	85a6                	mv	a1,s1
ffffffffc0203fb6:	854a                	mv	a0,s2
ffffffffc0203fb8:	e61ff0ef          	jal	ffffffffc0203e18 <printnum>
            break;
ffffffffc0203fbc:	bdfd                	j	ffffffffc0203eba <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203fbe:	000a2503          	lw	a0,0(s4)
ffffffffc0203fc2:	85a6                	mv	a1,s1
ffffffffc0203fc4:	0a21                	add	s4,s4,8
ffffffffc0203fc6:	9902                	jalr	s2
            break;
ffffffffc0203fc8:	bdcd                	j	ffffffffc0203eba <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203fca:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0203fcc:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0203fd0:	00c7c463          	blt	a5,a2,ffffffffc0203fd8 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0203fd4:	16060363          	beqz	a2,ffffffffc020413a <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0203fd8:	000a3603          	ld	a2,0(s4)
ffffffffc0203fdc:	46a9                	li	a3,10
ffffffffc0203fde:	8a3a                	mv	s4,a4
ffffffffc0203fe0:	b7f9                	j	ffffffffc0203fae <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0203fe2:	85a6                	mv	a1,s1
ffffffffc0203fe4:	03000513          	li	a0,48
ffffffffc0203fe8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203fea:	85a6                	mv	a1,s1
ffffffffc0203fec:	07800513          	li	a0,120
ffffffffc0203ff0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203ff2:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203ff6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203ff8:	0a21                	add	s4,s4,8
            goto number;
ffffffffc0203ffa:	bf55                	j	ffffffffc0203fae <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0203ffc:	85a6                	mv	a1,s1
ffffffffc0203ffe:	02500513          	li	a0,37
ffffffffc0204002:	9902                	jalr	s2
            break;
ffffffffc0204004:	bd5d                	j	ffffffffc0203eba <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0204006:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020400a:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc020400c:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc020400e:	bf95                	j	ffffffffc0203f82 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0204010:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204012:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204016:	00c7c463          	blt	a5,a2,ffffffffc020401e <vprintfmt+0x198>
    else if (lflag) {
ffffffffc020401a:	10060b63          	beqz	a2,ffffffffc0204130 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc020401e:	000a3603          	ld	a2,0(s4)
ffffffffc0204022:	46a1                	li	a3,8
ffffffffc0204024:	8a3a                	mv	s4,a4
ffffffffc0204026:	b761                	j	ffffffffc0203fae <vprintfmt+0x128>
            if (width < 0)
ffffffffc0204028:	fffcc793          	not	a5,s9
ffffffffc020402c:	97fd                	sra	a5,a5,0x3f
ffffffffc020402e:	00fcf7b3          	and	a5,s9,a5
ffffffffc0204032:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204036:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0204038:	b56d                	j	ffffffffc0203ee2 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020403a:	000a3403          	ld	s0,0(s4)
ffffffffc020403e:	008a0793          	add	a5,s4,8
ffffffffc0204042:	e43e                	sd	a5,8(sp)
ffffffffc0204044:	12040063          	beqz	s0,ffffffffc0204164 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0204048:	0d905963          	blez	s9,ffffffffc020411a <vprintfmt+0x294>
ffffffffc020404c:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204050:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0204054:	12fd9763          	bne	s11,a5,ffffffffc0204182 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204058:	00044783          	lbu	a5,0(s0)
ffffffffc020405c:	0007851b          	sext.w	a0,a5
ffffffffc0204060:	cb9d                	beqz	a5,ffffffffc0204096 <vprintfmt+0x210>
ffffffffc0204062:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204064:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204068:	000d4563          	bltz	s10,ffffffffc0204072 <vprintfmt+0x1ec>
ffffffffc020406c:	3d7d                	addw	s10,s10,-1
ffffffffc020406e:	028d0263          	beq	s10,s0,ffffffffc0204092 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0204072:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204074:	0c0b8d63          	beqz	s7,ffffffffc020414e <vprintfmt+0x2c8>
ffffffffc0204078:	3781                	addw	a5,a5,-32
ffffffffc020407a:	0cfdfa63          	bgeu	s11,a5,ffffffffc020414e <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc020407e:	03f00513          	li	a0,63
ffffffffc0204082:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204084:	000a4783          	lbu	a5,0(s4)
ffffffffc0204088:	3cfd                	addw	s9,s9,-1
ffffffffc020408a:	0a05                	add	s4,s4,1
ffffffffc020408c:	0007851b          	sext.w	a0,a5
ffffffffc0204090:	ffe1                	bnez	a5,ffffffffc0204068 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0204092:	01905963          	blez	s9,ffffffffc02040a4 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0204096:	85a6                	mv	a1,s1
ffffffffc0204098:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020409c:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020409e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02040a0:	fe0c9be3          	bnez	s9,ffffffffc0204096 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02040a4:	6a22                	ld	s4,8(sp)
ffffffffc02040a6:	bd11                	j	ffffffffc0203eba <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02040a8:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02040aa:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc02040ae:	00c7c363          	blt	a5,a2,ffffffffc02040b4 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02040b2:	ce25                	beqz	a2,ffffffffc020412a <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02040b4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02040b8:	08044d63          	bltz	s0,ffffffffc0204152 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02040bc:	8622                	mv	a2,s0
ffffffffc02040be:	8a5e                	mv	s4,s7
ffffffffc02040c0:	46a9                	li	a3,10
ffffffffc02040c2:	b5f5                	j	ffffffffc0203fae <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02040c4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02040c8:	4619                	li	a2,6
            if (err < 0) {
ffffffffc02040ca:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc02040ce:	8fb9                	xor	a5,a5,a4
ffffffffc02040d0:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02040d4:	02d64663          	blt	a2,a3,ffffffffc0204100 <vprintfmt+0x27a>
ffffffffc02040d8:	00369713          	sll	a4,a3,0x3
ffffffffc02040dc:	00002797          	auipc	a5,0x2
ffffffffc02040e0:	02478793          	add	a5,a5,36 # ffffffffc0206100 <error_string>
ffffffffc02040e4:	97ba                	add	a5,a5,a4
ffffffffc02040e6:	639c                	ld	a5,0(a5)
ffffffffc02040e8:	cf81                	beqz	a5,ffffffffc0204100 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02040ea:	86be                	mv	a3,a5
ffffffffc02040ec:	00002617          	auipc	a2,0x2
ffffffffc02040f0:	d4460613          	add	a2,a2,-700 # ffffffffc0205e30 <etext+0x1abc>
ffffffffc02040f4:	85a6                	mv	a1,s1
ffffffffc02040f6:	854a                	mv	a0,s2
ffffffffc02040f8:	0e8000ef          	jal	ffffffffc02041e0 <printfmt>
            err = va_arg(ap, int);
ffffffffc02040fc:	0a21                	add	s4,s4,8
ffffffffc02040fe:	bb75                	j	ffffffffc0203eba <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204100:	00002617          	auipc	a2,0x2
ffffffffc0204104:	d2060613          	add	a2,a2,-736 # ffffffffc0205e20 <etext+0x1aac>
ffffffffc0204108:	85a6                	mv	a1,s1
ffffffffc020410a:	854a                	mv	a0,s2
ffffffffc020410c:	0d4000ef          	jal	ffffffffc02041e0 <printfmt>
            err = va_arg(ap, int);
ffffffffc0204110:	0a21                	add	s4,s4,8
ffffffffc0204112:	b365                	j	ffffffffc0203eba <vprintfmt+0x34>
            lflag ++;
ffffffffc0204114:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204116:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0204118:	b3e9                	j	ffffffffc0203ee2 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020411a:	00044783          	lbu	a5,0(s0)
ffffffffc020411e:	0007851b          	sext.w	a0,a5
ffffffffc0204122:	d3c9                	beqz	a5,ffffffffc02040a4 <vprintfmt+0x21e>
ffffffffc0204124:	00140a13          	add	s4,s0,1
ffffffffc0204128:	bf2d                	j	ffffffffc0204062 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc020412a:	000a2403          	lw	s0,0(s4)
ffffffffc020412e:	b769                	j	ffffffffc02040b8 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0204130:	000a6603          	lwu	a2,0(s4)
ffffffffc0204134:	46a1                	li	a3,8
ffffffffc0204136:	8a3a                	mv	s4,a4
ffffffffc0204138:	bd9d                	j	ffffffffc0203fae <vprintfmt+0x128>
ffffffffc020413a:	000a6603          	lwu	a2,0(s4)
ffffffffc020413e:	46a9                	li	a3,10
ffffffffc0204140:	8a3a                	mv	s4,a4
ffffffffc0204142:	b5b5                	j	ffffffffc0203fae <vprintfmt+0x128>
ffffffffc0204144:	000a6603          	lwu	a2,0(s4)
ffffffffc0204148:	46c1                	li	a3,16
ffffffffc020414a:	8a3a                	mv	s4,a4
ffffffffc020414c:	b58d                	j	ffffffffc0203fae <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc020414e:	9902                	jalr	s2
ffffffffc0204150:	bf15                	j	ffffffffc0204084 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0204152:	85a6                	mv	a1,s1
ffffffffc0204154:	02d00513          	li	a0,45
ffffffffc0204158:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020415a:	40800633          	neg	a2,s0
ffffffffc020415e:	8a5e                	mv	s4,s7
ffffffffc0204160:	46a9                	li	a3,10
ffffffffc0204162:	b5b1                	j	ffffffffc0203fae <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0204164:	01905663          	blez	s9,ffffffffc0204170 <vprintfmt+0x2ea>
ffffffffc0204168:	02d00793          	li	a5,45
ffffffffc020416c:	04fd9263          	bne	s11,a5,ffffffffc02041b0 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204170:	02800793          	li	a5,40
ffffffffc0204174:	00002a17          	auipc	s4,0x2
ffffffffc0204178:	ca5a0a13          	add	s4,s4,-859 # ffffffffc0205e19 <etext+0x1aa5>
ffffffffc020417c:	02800513          	li	a0,40
ffffffffc0204180:	b5cd                	j	ffffffffc0204062 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204182:	85ea                	mv	a1,s10
ffffffffc0204184:	8522                	mv	a0,s0
ffffffffc0204186:	148000ef          	jal	ffffffffc02042ce <strnlen>
ffffffffc020418a:	40ac8cbb          	subw	s9,s9,a0
ffffffffc020418e:	01905963          	blez	s9,ffffffffc02041a0 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0204192:	2d81                	sext.w	s11,s11
ffffffffc0204194:	85a6                	mv	a1,s1
ffffffffc0204196:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204198:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc020419a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020419c:	fe0c9ce3          	bnez	s9,ffffffffc0204194 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041a0:	00044783          	lbu	a5,0(s0)
ffffffffc02041a4:	0007851b          	sext.w	a0,a5
ffffffffc02041a8:	ea079de3          	bnez	a5,ffffffffc0204062 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02041ac:	6a22                	ld	s4,8(sp)
ffffffffc02041ae:	b331                	j	ffffffffc0203eba <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041b0:	85ea                	mv	a1,s10
ffffffffc02041b2:	00002517          	auipc	a0,0x2
ffffffffc02041b6:	c6650513          	add	a0,a0,-922 # ffffffffc0205e18 <etext+0x1aa4>
ffffffffc02041ba:	114000ef          	jal	ffffffffc02042ce <strnlen>
ffffffffc02041be:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc02041c2:	00002417          	auipc	s0,0x2
ffffffffc02041c6:	c5640413          	add	s0,s0,-938 # ffffffffc0205e18 <etext+0x1aa4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041ca:	00002a17          	auipc	s4,0x2
ffffffffc02041ce:	c4fa0a13          	add	s4,s4,-945 # ffffffffc0205e19 <etext+0x1aa5>
ffffffffc02041d2:	02800793          	li	a5,40
ffffffffc02041d6:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02041da:	fb904ce3          	bgtz	s9,ffffffffc0204192 <vprintfmt+0x30c>
ffffffffc02041de:	b551                	j	ffffffffc0204062 <vprintfmt+0x1dc>

ffffffffc02041e0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041e0:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02041e2:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041e6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041e8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02041ea:	ec06                	sd	ra,24(sp)
ffffffffc02041ec:	f83a                	sd	a4,48(sp)
ffffffffc02041ee:	fc3e                	sd	a5,56(sp)
ffffffffc02041f0:	e0c2                	sd	a6,64(sp)
ffffffffc02041f2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02041f4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02041f6:	c91ff0ef          	jal	ffffffffc0203e86 <vprintfmt>
}
ffffffffc02041fa:	60e2                	ld	ra,24(sp)
ffffffffc02041fc:	6161                	add	sp,sp,80
ffffffffc02041fe:	8082                	ret

ffffffffc0204200 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0204200:	715d                	add	sp,sp,-80
ffffffffc0204202:	e486                	sd	ra,72(sp)
ffffffffc0204204:	e0a2                	sd	s0,64(sp)
ffffffffc0204206:	fc26                	sd	s1,56(sp)
ffffffffc0204208:	f84a                	sd	s2,48(sp)
ffffffffc020420a:	f44e                	sd	s3,40(sp)
ffffffffc020420c:	f052                	sd	s4,32(sp)
ffffffffc020420e:	ec56                	sd	s5,24(sp)
ffffffffc0204210:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0204212:	c901                	beqz	a0,ffffffffc0204222 <readline+0x22>
ffffffffc0204214:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0204216:	00002517          	auipc	a0,0x2
ffffffffc020421a:	c1a50513          	add	a0,a0,-998 # ffffffffc0205e30 <etext+0x1abc>
ffffffffc020421e:	e9dfb0ef          	jal	ffffffffc02000ba <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0204222:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204224:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204226:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204228:	4a29                	li	s4,10
ffffffffc020422a:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc020422c:	0000db17          	auipc	s6,0xd
ffffffffc0204230:	eccb0b13          	add	s6,s6,-308 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204234:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0204238:	eb9fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc020423c:	00054a63          	bltz	a0,ffffffffc0204250 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204240:	00a4da63          	bge	s1,a0,ffffffffc0204254 <readline+0x54>
ffffffffc0204244:	0289d263          	bge	s3,s0,ffffffffc0204268 <readline+0x68>
        c = getchar();
ffffffffc0204248:	ea9fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc020424c:	fe055ae3          	bgez	a0,ffffffffc0204240 <readline+0x40>
            return NULL;
ffffffffc0204250:	4501                	li	a0,0
ffffffffc0204252:	a091                	j	ffffffffc0204296 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0204254:	03251463          	bne	a0,s2,ffffffffc020427c <readline+0x7c>
ffffffffc0204258:	04804963          	bgtz	s0,ffffffffc02042aa <readline+0xaa>
        c = getchar();
ffffffffc020425c:	e95fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc0204260:	fe0548e3          	bltz	a0,ffffffffc0204250 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204264:	fea4d8e3          	bge	s1,a0,ffffffffc0204254 <readline+0x54>
            cputchar(c);
ffffffffc0204268:	e42a                	sd	a0,8(sp)
ffffffffc020426a:	e85fb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i ++] = c;
ffffffffc020426e:	6522                	ld	a0,8(sp)
ffffffffc0204270:	008b07b3          	add	a5,s6,s0
ffffffffc0204274:	2405                	addw	s0,s0,1
ffffffffc0204276:	00a78023          	sb	a0,0(a5)
ffffffffc020427a:	bf7d                	j	ffffffffc0204238 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020427c:	01450463          	beq	a0,s4,ffffffffc0204284 <readline+0x84>
ffffffffc0204280:	fb551ce3          	bne	a0,s5,ffffffffc0204238 <readline+0x38>
            cputchar(c);
ffffffffc0204284:	e6bfb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i] = '\0';
ffffffffc0204288:	0000d517          	auipc	a0,0xd
ffffffffc020428c:	e7050513          	add	a0,a0,-400 # ffffffffc02110f8 <buf>
ffffffffc0204290:	942a                	add	s0,s0,a0
ffffffffc0204292:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0204296:	60a6                	ld	ra,72(sp)
ffffffffc0204298:	6406                	ld	s0,64(sp)
ffffffffc020429a:	74e2                	ld	s1,56(sp)
ffffffffc020429c:	7942                	ld	s2,48(sp)
ffffffffc020429e:	79a2                	ld	s3,40(sp)
ffffffffc02042a0:	7a02                	ld	s4,32(sp)
ffffffffc02042a2:	6ae2                	ld	s5,24(sp)
ffffffffc02042a4:	6b42                	ld	s6,16(sp)
ffffffffc02042a6:	6161                	add	sp,sp,80
ffffffffc02042a8:	8082                	ret
            cputchar(c);
ffffffffc02042aa:	4521                	li	a0,8
ffffffffc02042ac:	e43fb0ef          	jal	ffffffffc02000ee <cputchar>
            i --;
ffffffffc02042b0:	347d                	addw	s0,s0,-1
ffffffffc02042b2:	b759                	j	ffffffffc0204238 <readline+0x38>

ffffffffc02042b4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02042b4:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02042b8:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02042ba:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02042bc:	cb81                	beqz	a5,ffffffffc02042cc <strlen+0x18>
        cnt ++;
ffffffffc02042be:	0505                	add	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02042c0:	00a707b3          	add	a5,a4,a0
ffffffffc02042c4:	0007c783          	lbu	a5,0(a5)
ffffffffc02042c8:	fbfd                	bnez	a5,ffffffffc02042be <strlen+0xa>
ffffffffc02042ca:	8082                	ret
    }
    return cnt;
}
ffffffffc02042cc:	8082                	ret

ffffffffc02042ce <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02042ce:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042d0:	e589                	bnez	a1,ffffffffc02042da <strnlen+0xc>
ffffffffc02042d2:	a811                	j	ffffffffc02042e6 <strnlen+0x18>
        cnt ++;
ffffffffc02042d4:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02042d6:	00f58863          	beq	a1,a5,ffffffffc02042e6 <strnlen+0x18>
ffffffffc02042da:	00f50733          	add	a4,a0,a5
ffffffffc02042de:	00074703          	lbu	a4,0(a4)
ffffffffc02042e2:	fb6d                	bnez	a4,ffffffffc02042d4 <strnlen+0x6>
ffffffffc02042e4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02042e6:	852e                	mv	a0,a1
ffffffffc02042e8:	8082                	ret

ffffffffc02042ea <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02042ea:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02042ec:	0005c703          	lbu	a4,0(a1)
ffffffffc02042f0:	0785                	add	a5,a5,1
ffffffffc02042f2:	0585                	add	a1,a1,1
ffffffffc02042f4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02042f8:	fb75                	bnez	a4,ffffffffc02042ec <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02042fa:	8082                	ret

ffffffffc02042fc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02042fc:	00054783          	lbu	a5,0(a0)
ffffffffc0204300:	e791                	bnez	a5,ffffffffc020430c <strcmp+0x10>
ffffffffc0204302:	a02d                	j	ffffffffc020432c <strcmp+0x30>
ffffffffc0204304:	00054783          	lbu	a5,0(a0)
ffffffffc0204308:	cf89                	beqz	a5,ffffffffc0204322 <strcmp+0x26>
ffffffffc020430a:	85b6                	mv	a1,a3
ffffffffc020430c:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0204310:	0505                	add	a0,a0,1
ffffffffc0204312:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204316:	fef707e3          	beq	a4,a5,ffffffffc0204304 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020431a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020431e:	9d19                	subw	a0,a0,a4
ffffffffc0204320:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204322:	0015c703          	lbu	a4,1(a1)
ffffffffc0204326:	4501                	li	a0,0
}
ffffffffc0204328:	9d19                	subw	a0,a0,a4
ffffffffc020432a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020432c:	0005c703          	lbu	a4,0(a1)
ffffffffc0204330:	4501                	li	a0,0
ffffffffc0204332:	b7f5                	j	ffffffffc020431e <strcmp+0x22>

ffffffffc0204334 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204334:	00054783          	lbu	a5,0(a0)
ffffffffc0204338:	c799                	beqz	a5,ffffffffc0204346 <strchr+0x12>
        if (*s == c) {
ffffffffc020433a:	00f58763          	beq	a1,a5,ffffffffc0204348 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020433e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204342:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc0204344:	fbfd                	bnez	a5,ffffffffc020433a <strchr+0x6>
    }
    return NULL;
ffffffffc0204346:	4501                	li	a0,0
}
ffffffffc0204348:	8082                	ret

ffffffffc020434a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020434a:	ca01                	beqz	a2,ffffffffc020435a <memset+0x10>
ffffffffc020434c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020434e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204350:	0785                	add	a5,a5,1
ffffffffc0204352:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204356:	fef61de3          	bne	a2,a5,ffffffffc0204350 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020435a:	8082                	ret

ffffffffc020435c <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc020435c:	ca19                	beqz	a2,ffffffffc0204372 <memcpy+0x16>
ffffffffc020435e:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204360:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204362:	0005c703          	lbu	a4,0(a1)
ffffffffc0204366:	0585                	add	a1,a1,1
ffffffffc0204368:	0785                	add	a5,a5,1
ffffffffc020436a:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc020436e:	feb61ae3          	bne	a2,a1,ffffffffc0204362 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204372:	8082                	ret
