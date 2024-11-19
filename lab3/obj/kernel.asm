
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
ffffffffc020004a:	476040ef          	jal	ffffffffc02044c0 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	4a258593          	add	a1,a1,1186 # ffffffffc02044f0 <etext+0x6>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	4ba50513          	add	a0,a0,1210 # ffffffffc0204510 <etext+0x26>
ffffffffc020005e:	05c000ef          	jal	ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	09e000ef          	jal	ffffffffc0200100 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	29b010ef          	jal	ffffffffc0201b00 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4e8000ef          	jal	ffffffffc0200552 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	6d8030ef          	jal	ffffffffc0203746 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	40e000ef          	jal	ffffffffc0200480 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	127020ef          	jal	ffffffffc020299c <swap_init>

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
ffffffffc02000ae:	74f030ef          	jal	ffffffffc0203ffc <vprintfmt>
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
ffffffffc02000e2:	71b030ef          	jal	ffffffffc0203ffc <vprintfmt>
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
ffffffffc0200106:	41650513          	add	a0,a0,1046 # ffffffffc0204518 <etext+0x2e>
void print_kerninfo(void) {
ffffffffc020010a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020010c:	fafff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200110:	00000597          	auipc	a1,0x0
ffffffffc0200114:	f2258593          	add	a1,a1,-222 # ffffffffc0200032 <kern_init>
ffffffffc0200118:	00004517          	auipc	a0,0x4
ffffffffc020011c:	42050513          	add	a0,a0,1056 # ffffffffc0204538 <etext+0x4e>
ffffffffc0200120:	f9bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200124:	00004597          	auipc	a1,0x4
ffffffffc0200128:	3c658593          	add	a1,a1,966 # ffffffffc02044ea <etext>
ffffffffc020012c:	00004517          	auipc	a0,0x4
ffffffffc0200130:	42c50513          	add	a0,a0,1068 # ffffffffc0204558 <etext+0x6e>
ffffffffc0200134:	f87ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200138:	0000a597          	auipc	a1,0xa
ffffffffc020013c:	f0858593          	add	a1,a1,-248 # ffffffffc020a040 <ide>
ffffffffc0200140:	00004517          	auipc	a0,0x4
ffffffffc0200144:	43850513          	add	a0,a0,1080 # ffffffffc0204578 <etext+0x8e>
ffffffffc0200148:	f73ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc020014c:	00011597          	auipc	a1,0x11
ffffffffc0200150:	42458593          	add	a1,a1,1060 # ffffffffc0211570 <end>
ffffffffc0200154:	00004517          	auipc	a0,0x4
ffffffffc0200158:	44450513          	add	a0,a0,1092 # ffffffffc0204598 <etext+0xae>
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
ffffffffc0200184:	43850513          	add	a0,a0,1080 # ffffffffc02045b8 <etext+0xce>
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
ffffffffc0200192:	45a60613          	add	a2,a2,1114 # ffffffffc02045e8 <etext+0xfe>
ffffffffc0200196:	04e00593          	li	a1,78
ffffffffc020019a:	00004517          	auipc	a0,0x4
ffffffffc020019e:	46650513          	add	a0,a0,1126 # ffffffffc0204600 <etext+0x116>
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
ffffffffc02001ae:	46e60613          	add	a2,a2,1134 # ffffffffc0204618 <etext+0x12e>
ffffffffc02001b2:	00004597          	auipc	a1,0x4
ffffffffc02001b6:	48658593          	add	a1,a1,1158 # ffffffffc0204638 <etext+0x14e>
ffffffffc02001ba:	00004517          	auipc	a0,0x4
ffffffffc02001be:	48650513          	add	a0,a0,1158 # ffffffffc0204640 <etext+0x156>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001c2:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001c4:	ef7ff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001c8:	00004617          	auipc	a2,0x4
ffffffffc02001cc:	48860613          	add	a2,a2,1160 # ffffffffc0204650 <etext+0x166>
ffffffffc02001d0:	00004597          	auipc	a1,0x4
ffffffffc02001d4:	4a858593          	add	a1,a1,1192 # ffffffffc0204678 <etext+0x18e>
ffffffffc02001d8:	00004517          	auipc	a0,0x4
ffffffffc02001dc:	46850513          	add	a0,a0,1128 # ffffffffc0204640 <etext+0x156>
ffffffffc02001e0:	edbff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02001e4:	00004617          	auipc	a2,0x4
ffffffffc02001e8:	4a460613          	add	a2,a2,1188 # ffffffffc0204688 <etext+0x19e>
ffffffffc02001ec:	00004597          	auipc	a1,0x4
ffffffffc02001f0:	4bc58593          	add	a1,a1,1212 # ffffffffc02046a8 <etext+0x1be>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	44c50513          	add	a0,a0,1100 # ffffffffc0204640 <etext+0x156>
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
ffffffffc0200232:	48a50513          	add	a0,a0,1162 # ffffffffc02046b8 <etext+0x1ce>
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
ffffffffc0200254:	49050513          	add	a0,a0,1168 # ffffffffc02046e0 <etext+0x1f6>
ffffffffc0200258:	e63ff0ef          	jal	ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc020025c:	000b0563          	beqz	s6,ffffffffc0200266 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200260:	855a                	mv	a0,s6
ffffffffc0200262:	4da000ef          	jal	ffffffffc020073c <print_trapframe>
ffffffffc0200266:	00006c17          	auipc	s8,0x6
ffffffffc020026a:	e1ac0c13          	add	s8,s8,-486 # ffffffffc0206080 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc020026e:	00005917          	auipc	s2,0x5
ffffffffc0200272:	7fa90913          	add	s2,s2,2042 # ffffffffc0205a68 <etext+0x157e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200276:	00004497          	auipc	s1,0x4
ffffffffc020027a:	49248493          	add	s1,s1,1170 # ffffffffc0204708 <etext+0x21e>
        if (argc == MAXARGS - 1) {
ffffffffc020027e:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200280:	00004a97          	auipc	s5,0x4
ffffffffc0200284:	490a8a93          	add	s5,s5,1168 # ffffffffc0204710 <etext+0x226>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200288:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020028a:	00004b97          	auipc	s7,0x4
ffffffffc020028e:	4a6b8b93          	add	s7,s7,1190 # ffffffffc0204730 <etext+0x246>
        if ((buf = readline("")) != NULL) {
ffffffffc0200292:	854a                	mv	a0,s2
ffffffffc0200294:	0e2040ef          	jal	ffffffffc0204376 <readline>
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
ffffffffc02002ac:	dd8d0d13          	add	s10,s10,-552 # ffffffffc0206080 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002b0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002b2:	6582                	ld	a1,0(sp)
ffffffffc02002b4:	000d3503          	ld	a0,0(s10)
ffffffffc02002b8:	1ba040ef          	jal	ffffffffc0204472 <strcmp>
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
ffffffffc02002d2:	1d8040ef          	jal	ffffffffc02044aa <strchr>
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
ffffffffc0200312:	198040ef          	jal	ffffffffc02044aa <strchr>
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
ffffffffc0200392:	3ba50513          	add	a0,a0,954 # ffffffffc0204748 <etext+0x25e>
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
ffffffffc02003a8:	21450513          	add	a0,a0,532 # ffffffffc02055b8 <etext+0x10ce>
ffffffffc02003ac:	d0fff0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc02003b0:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003b2:	12a000ef          	jal	ffffffffc02004dc <intr_disable>
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
ffffffffc02003e8:	38450513          	add	a0,a0,900 # ffffffffc0204768 <etext+0x27e>
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
ffffffffc020042e:	0ae000ef          	jal	ffffffffc02004dc <intr_disable>
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
ffffffffc0200442:	a851                	j	ffffffffc02004d6 <intr_enable>

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
ffffffffc0200460:	07c000ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0200464:	4501                	li	a0,0
ffffffffc0200466:	4581                	li	a1,0
ffffffffc0200468:	4601                	li	a2,0
ffffffffc020046a:	4889                	li	a7,2
ffffffffc020046c:	00000073          	ecall
ffffffffc0200470:	2501                	sext.w	a0,a0
ffffffffc0200472:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200474:	062000ef          	jal	ffffffffc02004d6 <intr_enable>
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

ffffffffc020048e <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020048e:	0000a797          	auipc	a5,0xa
ffffffffc0200492:	bb278793          	add	a5,a5,-1102 # ffffffffc020a040 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc0200496:	0095959b          	sllw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc020049a:	1141                	add	sp,sp,-16
ffffffffc020049c:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020049e:	95be                	add	a1,a1,a5
ffffffffc02004a0:	00969613          	sll	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004a4:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004a6:	02c040ef          	jal	ffffffffc02044d2 <memcpy>
    return 0;
}
ffffffffc02004aa:	60a2                	ld	ra,8(sp)
ffffffffc02004ac:	4501                	li	a0,0
ffffffffc02004ae:	0141                	add	sp,sp,16
ffffffffc02004b0:	8082                	ret

ffffffffc02004b2 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02004b2:	0095979b          	sllw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004b6:	0000a517          	auipc	a0,0xa
ffffffffc02004ba:	b8a50513          	add	a0,a0,-1142 # ffffffffc020a040 <ide>
                   size_t nsecs) {
ffffffffc02004be:	1141                	add	sp,sp,-16
ffffffffc02004c0:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004c2:	953e                	add	a0,a0,a5
ffffffffc02004c4:	00969613          	sll	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004c8:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ca:	008040ef          	jal	ffffffffc02044d2 <memcpy>
    return 0;
}
ffffffffc02004ce:	60a2                	ld	ra,8(sp)
ffffffffc02004d0:	4501                	li	a0,0
ffffffffc02004d2:	0141                	add	sp,sp,16
ffffffffc02004d4:	8082                	ret

ffffffffc02004d6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004d6:	100167f3          	csrrs	a5,sstatus,2
ffffffffc02004da:	8082                	ret

ffffffffc02004dc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004dc:	100177f3          	csrrc	a5,sstatus,2
ffffffffc02004e0:	8082                	ret

ffffffffc02004e2 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004e2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004e6:	1141                	add	sp,sp,-16
ffffffffc02004e8:	e022                	sd	s0,0(sp)
ffffffffc02004ea:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004ec:	1007f793          	and	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004f0:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004f4:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02004f6:	04b00613          	li	a2,75
ffffffffc02004fa:	e399                	bnez	a5,ffffffffc0200500 <pgfault_handler+0x1e>
ffffffffc02004fc:	05500613          	li	a2,85
ffffffffc0200500:	11843703          	ld	a4,280(s0)
ffffffffc0200504:	47bd                	li	a5,15
ffffffffc0200506:	05200693          	li	a3,82
ffffffffc020050a:	00f71463          	bne	a4,a5,ffffffffc0200512 <pgfault_handler+0x30>
ffffffffc020050e:	05700693          	li	a3,87
ffffffffc0200512:	00004517          	auipc	a0,0x4
ffffffffc0200516:	27650513          	add	a0,a0,630 # ffffffffc0204788 <etext+0x29e>
ffffffffc020051a:	ba1ff0ef          	jal	ffffffffc02000ba <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc020051e:	00011517          	auipc	a0,0x11
ffffffffc0200522:	04a53503          	ld	a0,74(a0) # ffffffffc0211568 <check_mm_struct>
ffffffffc0200526:	c911                	beqz	a0,ffffffffc020053a <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200528:	11043603          	ld	a2,272(s0)
ffffffffc020052c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200530:	6402                	ld	s0,0(sp)
ffffffffc0200532:	60a2                	ld	ra,8(sp)
ffffffffc0200534:	0141                	add	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200536:	7fe0306f          	j	ffffffffc0203d34 <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020053a:	00004617          	auipc	a2,0x4
ffffffffc020053e:	26e60613          	add	a2,a2,622 # ffffffffc02047a8 <etext+0x2be>
ffffffffc0200542:	07800593          	li	a1,120
ffffffffc0200546:	00004517          	auipc	a0,0x4
ffffffffc020054a:	27a50513          	add	a0,a0,634 # ffffffffc02047c0 <etext+0x2d6>
ffffffffc020054e:	e13ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0200552 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200552:	14005073          	csrw	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200556:	00000797          	auipc	a5,0x0
ffffffffc020055a:	48a78793          	add	a5,a5,1162 # ffffffffc02009e0 <__alltraps>
ffffffffc020055e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200562:	100167f3          	csrrs	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200566:	000407b7          	lui	a5,0x40
ffffffffc020056a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020056e:	8082                	ret

ffffffffc0200570 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200570:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200572:	1141                	add	sp,sp,-16
ffffffffc0200574:	e022                	sd	s0,0(sp)
ffffffffc0200576:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200578:	00004517          	auipc	a0,0x4
ffffffffc020057c:	26050513          	add	a0,a0,608 # ffffffffc02047d8 <etext+0x2ee>
void print_regs(struct pushregs *gpr) {
ffffffffc0200580:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200582:	b39ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200586:	640c                	ld	a1,8(s0)
ffffffffc0200588:	00004517          	auipc	a0,0x4
ffffffffc020058c:	26850513          	add	a0,a0,616 # ffffffffc02047f0 <etext+0x306>
ffffffffc0200590:	b2bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200594:	680c                	ld	a1,16(s0)
ffffffffc0200596:	00004517          	auipc	a0,0x4
ffffffffc020059a:	27250513          	add	a0,a0,626 # ffffffffc0204808 <etext+0x31e>
ffffffffc020059e:	b1dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005a2:	6c0c                	ld	a1,24(s0)
ffffffffc02005a4:	00004517          	auipc	a0,0x4
ffffffffc02005a8:	27c50513          	add	a0,a0,636 # ffffffffc0204820 <etext+0x336>
ffffffffc02005ac:	b0fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005b0:	700c                	ld	a1,32(s0)
ffffffffc02005b2:	00004517          	auipc	a0,0x4
ffffffffc02005b6:	28650513          	add	a0,a0,646 # ffffffffc0204838 <etext+0x34e>
ffffffffc02005ba:	b01ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005be:	740c                	ld	a1,40(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	29050513          	add	a0,a0,656 # ffffffffc0204850 <etext+0x366>
ffffffffc02005c8:	af3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005cc:	780c                	ld	a1,48(s0)
ffffffffc02005ce:	00004517          	auipc	a0,0x4
ffffffffc02005d2:	29a50513          	add	a0,a0,666 # ffffffffc0204868 <etext+0x37e>
ffffffffc02005d6:	ae5ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005da:	7c0c                	ld	a1,56(s0)
ffffffffc02005dc:	00004517          	auipc	a0,0x4
ffffffffc02005e0:	2a450513          	add	a0,a0,676 # ffffffffc0204880 <etext+0x396>
ffffffffc02005e4:	ad7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005e8:	602c                	ld	a1,64(s0)
ffffffffc02005ea:	00004517          	auipc	a0,0x4
ffffffffc02005ee:	2ae50513          	add	a0,a0,686 # ffffffffc0204898 <etext+0x3ae>
ffffffffc02005f2:	ac9ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02005f6:	642c                	ld	a1,72(s0)
ffffffffc02005f8:	00004517          	auipc	a0,0x4
ffffffffc02005fc:	2b850513          	add	a0,a0,696 # ffffffffc02048b0 <etext+0x3c6>
ffffffffc0200600:	abbff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200604:	682c                	ld	a1,80(s0)
ffffffffc0200606:	00004517          	auipc	a0,0x4
ffffffffc020060a:	2c250513          	add	a0,a0,706 # ffffffffc02048c8 <etext+0x3de>
ffffffffc020060e:	aadff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200612:	6c2c                	ld	a1,88(s0)
ffffffffc0200614:	00004517          	auipc	a0,0x4
ffffffffc0200618:	2cc50513          	add	a0,a0,716 # ffffffffc02048e0 <etext+0x3f6>
ffffffffc020061c:	a9fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200620:	702c                	ld	a1,96(s0)
ffffffffc0200622:	00004517          	auipc	a0,0x4
ffffffffc0200626:	2d650513          	add	a0,a0,726 # ffffffffc02048f8 <etext+0x40e>
ffffffffc020062a:	a91ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020062e:	742c                	ld	a1,104(s0)
ffffffffc0200630:	00004517          	auipc	a0,0x4
ffffffffc0200634:	2e050513          	add	a0,a0,736 # ffffffffc0204910 <etext+0x426>
ffffffffc0200638:	a83ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020063c:	782c                	ld	a1,112(s0)
ffffffffc020063e:	00004517          	auipc	a0,0x4
ffffffffc0200642:	2ea50513          	add	a0,a0,746 # ffffffffc0204928 <etext+0x43e>
ffffffffc0200646:	a75ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020064a:	7c2c                	ld	a1,120(s0)
ffffffffc020064c:	00004517          	auipc	a0,0x4
ffffffffc0200650:	2f450513          	add	a0,a0,756 # ffffffffc0204940 <etext+0x456>
ffffffffc0200654:	a67ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200658:	604c                	ld	a1,128(s0)
ffffffffc020065a:	00004517          	auipc	a0,0x4
ffffffffc020065e:	2fe50513          	add	a0,a0,766 # ffffffffc0204958 <etext+0x46e>
ffffffffc0200662:	a59ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200666:	644c                	ld	a1,136(s0)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	30850513          	add	a0,a0,776 # ffffffffc0204970 <etext+0x486>
ffffffffc0200670:	a4bff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200674:	684c                	ld	a1,144(s0)
ffffffffc0200676:	00004517          	auipc	a0,0x4
ffffffffc020067a:	31250513          	add	a0,a0,786 # ffffffffc0204988 <etext+0x49e>
ffffffffc020067e:	a3dff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200682:	6c4c                	ld	a1,152(s0)
ffffffffc0200684:	00004517          	auipc	a0,0x4
ffffffffc0200688:	31c50513          	add	a0,a0,796 # ffffffffc02049a0 <etext+0x4b6>
ffffffffc020068c:	a2fff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200690:	704c                	ld	a1,160(s0)
ffffffffc0200692:	00004517          	auipc	a0,0x4
ffffffffc0200696:	32650513          	add	a0,a0,806 # ffffffffc02049b8 <etext+0x4ce>
ffffffffc020069a:	a21ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020069e:	744c                	ld	a1,168(s0)
ffffffffc02006a0:	00004517          	auipc	a0,0x4
ffffffffc02006a4:	33050513          	add	a0,a0,816 # ffffffffc02049d0 <etext+0x4e6>
ffffffffc02006a8:	a13ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006ac:	784c                	ld	a1,176(s0)
ffffffffc02006ae:	00004517          	auipc	a0,0x4
ffffffffc02006b2:	33a50513          	add	a0,a0,826 # ffffffffc02049e8 <etext+0x4fe>
ffffffffc02006b6:	a05ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006ba:	7c4c                	ld	a1,184(s0)
ffffffffc02006bc:	00004517          	auipc	a0,0x4
ffffffffc02006c0:	34450513          	add	a0,a0,836 # ffffffffc0204a00 <etext+0x516>
ffffffffc02006c4:	9f7ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006c8:	606c                	ld	a1,192(s0)
ffffffffc02006ca:	00004517          	auipc	a0,0x4
ffffffffc02006ce:	34e50513          	add	a0,a0,846 # ffffffffc0204a18 <etext+0x52e>
ffffffffc02006d2:	9e9ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006d6:	646c                	ld	a1,200(s0)
ffffffffc02006d8:	00004517          	auipc	a0,0x4
ffffffffc02006dc:	35850513          	add	a0,a0,856 # ffffffffc0204a30 <etext+0x546>
ffffffffc02006e0:	9dbff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006e4:	686c                	ld	a1,208(s0)
ffffffffc02006e6:	00004517          	auipc	a0,0x4
ffffffffc02006ea:	36250513          	add	a0,a0,866 # ffffffffc0204a48 <etext+0x55e>
ffffffffc02006ee:	9cdff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02006f2:	6c6c                	ld	a1,216(s0)
ffffffffc02006f4:	00004517          	auipc	a0,0x4
ffffffffc02006f8:	36c50513          	add	a0,a0,876 # ffffffffc0204a60 <etext+0x576>
ffffffffc02006fc:	9bfff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200700:	706c                	ld	a1,224(s0)
ffffffffc0200702:	00004517          	auipc	a0,0x4
ffffffffc0200706:	37650513          	add	a0,a0,886 # ffffffffc0204a78 <etext+0x58e>
ffffffffc020070a:	9b1ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020070e:	746c                	ld	a1,232(s0)
ffffffffc0200710:	00004517          	auipc	a0,0x4
ffffffffc0200714:	38050513          	add	a0,a0,896 # ffffffffc0204a90 <etext+0x5a6>
ffffffffc0200718:	9a3ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020071c:	786c                	ld	a1,240(s0)
ffffffffc020071e:	00004517          	auipc	a0,0x4
ffffffffc0200722:	38a50513          	add	a0,a0,906 # ffffffffc0204aa8 <etext+0x5be>
ffffffffc0200726:	995ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020072a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020072c:	6402                	ld	s0,0(sp)
ffffffffc020072e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	39050513          	add	a0,a0,912 # ffffffffc0204ac0 <etext+0x5d6>
}
ffffffffc0200738:	0141                	add	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020073a:	b241                	j	ffffffffc02000ba <cprintf>

ffffffffc020073c <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020073c:	1141                	add	sp,sp,-16
ffffffffc020073e:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200740:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200742:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200744:	00004517          	auipc	a0,0x4
ffffffffc0200748:	39450513          	add	a0,a0,916 # ffffffffc0204ad8 <etext+0x5ee>
void print_trapframe(struct trapframe *tf) {
ffffffffc020074c:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020074e:	96dff0ef          	jal	ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200752:	8522                	mv	a0,s0
ffffffffc0200754:	e1dff0ef          	jal	ffffffffc0200570 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200758:	10043583          	ld	a1,256(s0)
ffffffffc020075c:	00004517          	auipc	a0,0x4
ffffffffc0200760:	39450513          	add	a0,a0,916 # ffffffffc0204af0 <etext+0x606>
ffffffffc0200764:	957ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200768:	10843583          	ld	a1,264(s0)
ffffffffc020076c:	00004517          	auipc	a0,0x4
ffffffffc0200770:	39c50513          	add	a0,a0,924 # ffffffffc0204b08 <etext+0x61e>
ffffffffc0200774:	947ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200778:	11043583          	ld	a1,272(s0)
ffffffffc020077c:	00004517          	auipc	a0,0x4
ffffffffc0200780:	3a450513          	add	a0,a0,932 # ffffffffc0204b20 <etext+0x636>
ffffffffc0200784:	937ff0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200788:	11843583          	ld	a1,280(s0)
}
ffffffffc020078c:	6402                	ld	s0,0(sp)
ffffffffc020078e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200790:	00004517          	auipc	a0,0x4
ffffffffc0200794:	3a850513          	add	a0,a0,936 # ffffffffc0204b38 <etext+0x64e>
}
ffffffffc0200798:	0141                	add	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020079a:	921ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc020079e <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020079e:	11853783          	ld	a5,280(a0)
ffffffffc02007a2:	472d                	li	a4,11
ffffffffc02007a4:	0786                	sll	a5,a5,0x1
ffffffffc02007a6:	8385                	srl	a5,a5,0x1
ffffffffc02007a8:	06f76c63          	bltu	a4,a5,ffffffffc0200820 <interrupt_handler+0x82>
ffffffffc02007ac:	00006717          	auipc	a4,0x6
ffffffffc02007b0:	91c70713          	add	a4,a4,-1764 # ffffffffc02060c8 <commands+0x48>
ffffffffc02007b4:	078a                	sll	a5,a5,0x2
ffffffffc02007b6:	97ba                	add	a5,a5,a4
ffffffffc02007b8:	439c                	lw	a5,0(a5)
ffffffffc02007ba:	97ba                	add	a5,a5,a4
ffffffffc02007bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007be:	00004517          	auipc	a0,0x4
ffffffffc02007c2:	3f250513          	add	a0,a0,1010 # ffffffffc0204bb0 <etext+0x6c6>
ffffffffc02007c6:	8f5ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007ca:	00004517          	auipc	a0,0x4
ffffffffc02007ce:	3c650513          	add	a0,a0,966 # ffffffffc0204b90 <etext+0x6a6>
ffffffffc02007d2:	8e9ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007d6:	00004517          	auipc	a0,0x4
ffffffffc02007da:	37a50513          	add	a0,a0,890 # ffffffffc0204b50 <etext+0x666>
ffffffffc02007de:	8ddff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	38e50513          	add	a0,a0,910 # ffffffffc0204b70 <etext+0x686>
ffffffffc02007ea:	8d1ff06f          	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02007ee:	1141                	add	sp,sp,-16
ffffffffc02007f0:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02007f2:	c05ff0ef          	jal	ffffffffc02003f6 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02007f6:	00011697          	auipc	a3,0x11
ffffffffc02007fa:	d1268693          	add	a3,a3,-750 # ffffffffc0211508 <ticks>
ffffffffc02007fe:	629c                	ld	a5,0(a3)
ffffffffc0200800:	06400713          	li	a4,100
ffffffffc0200804:	0785                	add	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
ffffffffc0200806:	02e7f733          	remu	a4,a5,a4
ffffffffc020080a:	e29c                	sd	a5,0(a3)
ffffffffc020080c:	cb19                	beqz	a4,ffffffffc0200822 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020080e:	60a2                	ld	ra,8(sp)
ffffffffc0200810:	0141                	add	sp,sp,16
ffffffffc0200812:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200814:	00004517          	auipc	a0,0x4
ffffffffc0200818:	3cc50513          	add	a0,a0,972 # ffffffffc0204be0 <etext+0x6f6>
ffffffffc020081c:	89fff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc0200820:	bf31                	j	ffffffffc020073c <print_trapframe>
}
ffffffffc0200822:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200824:	06400593          	li	a1,100
ffffffffc0200828:	00004517          	auipc	a0,0x4
ffffffffc020082c:	3a850513          	add	a0,a0,936 # ffffffffc0204bd0 <etext+0x6e6>
}
ffffffffc0200830:	0141                	add	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200832:	889ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0200836 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200836:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020083a:	1101                	add	sp,sp,-32
ffffffffc020083c:	e822                	sd	s0,16(sp)
ffffffffc020083e:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200840:	473d                	li	a4,15
void exception_handler(struct trapframe *tf) {
ffffffffc0200842:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200844:	14f76d63          	bltu	a4,a5,ffffffffc020099e <exception_handler+0x168>
ffffffffc0200848:	00006717          	auipc	a4,0x6
ffffffffc020084c:	8b070713          	add	a4,a4,-1872 # ffffffffc02060f8 <commands+0x78>
ffffffffc0200850:	078a                	sll	a5,a5,0x2
ffffffffc0200852:	97ba                	add	a5,a5,a4
ffffffffc0200854:	439c                	lw	a5,0(a5)
ffffffffc0200856:	97ba                	add	a5,a5,a4
ffffffffc0200858:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc020085a:	00004517          	auipc	a0,0x4
ffffffffc020085e:	54650513          	add	a0,a0,1350 # ffffffffc0204da0 <etext+0x8b6>
ffffffffc0200862:	e426                	sd	s1,8(sp)
ffffffffc0200864:	857ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200868:	8522                	mv	a0,s0
ffffffffc020086a:	c79ff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc020086e:	84aa                	mv	s1,a0
ffffffffc0200870:	12051c63          	bnez	a0,ffffffffc02009a8 <exception_handler+0x172>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200874:	60e2                	ld	ra,24(sp)
ffffffffc0200876:	6442                	ld	s0,16(sp)
ffffffffc0200878:	64a2                	ld	s1,8(sp)
ffffffffc020087a:	6105                	add	sp,sp,32
ffffffffc020087c:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc020087e:	00004517          	auipc	a0,0x4
ffffffffc0200882:	38250513          	add	a0,a0,898 # ffffffffc0204c00 <etext+0x716>
}
ffffffffc0200886:	6442                	ld	s0,16(sp)
ffffffffc0200888:	60e2                	ld	ra,24(sp)
ffffffffc020088a:	6105                	add	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc020088c:	82fff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc0200890:	00004517          	auipc	a0,0x4
ffffffffc0200894:	39050513          	add	a0,a0,912 # ffffffffc0204c20 <etext+0x736>
ffffffffc0200898:	b7fd                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc020089a:	00004517          	auipc	a0,0x4
ffffffffc020089e:	3a650513          	add	a0,a0,934 # ffffffffc0204c40 <etext+0x756>
ffffffffc02008a2:	b7d5                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008a4:	00004517          	auipc	a0,0x4
ffffffffc02008a8:	3b450513          	add	a0,a0,948 # ffffffffc0204c58 <etext+0x76e>
ffffffffc02008ac:	bfe9                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	3ba50513          	add	a0,a0,954 # ffffffffc0204c68 <etext+0x77e>
ffffffffc02008b6:	bfc1                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	3d050513          	add	a0,a0,976 # ffffffffc0204c88 <etext+0x79e>
ffffffffc02008c0:	e426                	sd	s1,8(sp)
ffffffffc02008c2:	ff8ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008c6:	8522                	mv	a0,s0
ffffffffc02008c8:	c1bff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc02008cc:	84aa                	mv	s1,a0
ffffffffc02008ce:	d15d                	beqz	a0,ffffffffc0200874 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008d0:	8522                	mv	a0,s0
ffffffffc02008d2:	e6bff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008d6:	86a6                	mv	a3,s1
ffffffffc02008d8:	00004617          	auipc	a2,0x4
ffffffffc02008dc:	3c860613          	add	a2,a2,968 # ffffffffc0204ca0 <etext+0x7b6>
ffffffffc02008e0:	0ca00593          	li	a1,202
ffffffffc02008e4:	00004517          	auipc	a0,0x4
ffffffffc02008e8:	edc50513          	add	a0,a0,-292 # ffffffffc02047c0 <etext+0x2d6>
ffffffffc02008ec:	a75ff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	3d050513          	add	a0,a0,976 # ffffffffc0204cc0 <etext+0x7d6>
ffffffffc02008f8:	b779                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02008fa:	00004517          	auipc	a0,0x4
ffffffffc02008fe:	3de50513          	add	a0,a0,990 # ffffffffc0204cd8 <etext+0x7ee>
ffffffffc0200902:	e426                	sd	s1,8(sp)
ffffffffc0200904:	fb6ff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200908:	8522                	mv	a0,s0
ffffffffc020090a:	bd9ff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc020090e:	84aa                	mv	s1,a0
ffffffffc0200910:	d135                	beqz	a0,ffffffffc0200874 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200912:	8522                	mv	a0,s0
ffffffffc0200914:	e29ff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200918:	86a6                	mv	a3,s1
ffffffffc020091a:	00004617          	auipc	a2,0x4
ffffffffc020091e:	38660613          	add	a2,a2,902 # ffffffffc0204ca0 <etext+0x7b6>
ffffffffc0200922:	0d400593          	li	a1,212
ffffffffc0200926:	00004517          	auipc	a0,0x4
ffffffffc020092a:	e9a50513          	add	a0,a0,-358 # ffffffffc02047c0 <etext+0x2d6>
ffffffffc020092e:	a33ff0ef          	jal	ffffffffc0200360 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200932:	00004517          	auipc	a0,0x4
ffffffffc0200936:	3be50513          	add	a0,a0,958 # ffffffffc0204cf0 <etext+0x806>
ffffffffc020093a:	b7b1                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc020093c:	00004517          	auipc	a0,0x4
ffffffffc0200940:	3d450513          	add	a0,a0,980 # ffffffffc0204d10 <etext+0x826>
ffffffffc0200944:	b789                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200946:	00004517          	auipc	a0,0x4
ffffffffc020094a:	3ea50513          	add	a0,a0,1002 # ffffffffc0204d30 <etext+0x846>
ffffffffc020094e:	bf25                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200950:	00004517          	auipc	a0,0x4
ffffffffc0200954:	40050513          	add	a0,a0,1024 # ffffffffc0204d50 <etext+0x866>
ffffffffc0200958:	b73d                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	41650513          	add	a0,a0,1046 # ffffffffc0204d70 <etext+0x886>
ffffffffc0200962:	b715                	j	ffffffffc0200886 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	42450513          	add	a0,a0,1060 # ffffffffc0204d88 <etext+0x89e>
ffffffffc020096c:	e426                	sd	s1,8(sp)
ffffffffc020096e:	f4cff0ef          	jal	ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200972:	8522                	mv	a0,s0
ffffffffc0200974:	b6fff0ef          	jal	ffffffffc02004e2 <pgfault_handler>
ffffffffc0200978:	84aa                	mv	s1,a0
ffffffffc020097a:	ee050de3          	beqz	a0,ffffffffc0200874 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020097e:	8522                	mv	a0,s0
ffffffffc0200980:	dbdff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200984:	86a6                	mv	a3,s1
ffffffffc0200986:	00004617          	auipc	a2,0x4
ffffffffc020098a:	31a60613          	add	a2,a2,794 # ffffffffc0204ca0 <etext+0x7b6>
ffffffffc020098e:	0ea00593          	li	a1,234
ffffffffc0200992:	00004517          	auipc	a0,0x4
ffffffffc0200996:	e2e50513          	add	a0,a0,-466 # ffffffffc02047c0 <etext+0x2d6>
ffffffffc020099a:	9c7ff0ef          	jal	ffffffffc0200360 <__panic>
            print_trapframe(tf);
ffffffffc020099e:	8522                	mv	a0,s0
}
ffffffffc02009a0:	6442                	ld	s0,16(sp)
ffffffffc02009a2:	60e2                	ld	ra,24(sp)
ffffffffc02009a4:	6105                	add	sp,sp,32
            print_trapframe(tf);
ffffffffc02009a6:	bb59                	j	ffffffffc020073c <print_trapframe>
                print_trapframe(tf);
ffffffffc02009a8:	8522                	mv	a0,s0
ffffffffc02009aa:	d93ff0ef          	jal	ffffffffc020073c <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ae:	86a6                	mv	a3,s1
ffffffffc02009b0:	00004617          	auipc	a2,0x4
ffffffffc02009b4:	2f060613          	add	a2,a2,752 # ffffffffc0204ca0 <etext+0x7b6>
ffffffffc02009b8:	0f100593          	li	a1,241
ffffffffc02009bc:	00004517          	auipc	a0,0x4
ffffffffc02009c0:	e0450513          	add	a0,a0,-508 # ffffffffc02047c0 <etext+0x2d6>
ffffffffc02009c4:	99dff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02009c8 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009c8:	11853783          	ld	a5,280(a0)
ffffffffc02009cc:	0007c363          	bltz	a5,ffffffffc02009d2 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009d0:	b59d                	j	ffffffffc0200836 <exception_handler>
        interrupt_handler(tf);
ffffffffc02009d2:	b3f1                	j	ffffffffc020079e <interrupt_handler>
	...

ffffffffc02009e0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009e0:	14011073          	csrw	sscratch,sp
ffffffffc02009e4:	712d                	add	sp,sp,-288
ffffffffc02009e6:	e406                	sd	ra,8(sp)
ffffffffc02009e8:	ec0e                	sd	gp,24(sp)
ffffffffc02009ea:	f012                	sd	tp,32(sp)
ffffffffc02009ec:	f416                	sd	t0,40(sp)
ffffffffc02009ee:	f81a                	sd	t1,48(sp)
ffffffffc02009f0:	fc1e                	sd	t2,56(sp)
ffffffffc02009f2:	e0a2                	sd	s0,64(sp)
ffffffffc02009f4:	e4a6                	sd	s1,72(sp)
ffffffffc02009f6:	e8aa                	sd	a0,80(sp)
ffffffffc02009f8:	ecae                	sd	a1,88(sp)
ffffffffc02009fa:	f0b2                	sd	a2,96(sp)
ffffffffc02009fc:	f4b6                	sd	a3,104(sp)
ffffffffc02009fe:	f8ba                	sd	a4,112(sp)
ffffffffc0200a00:	fcbe                	sd	a5,120(sp)
ffffffffc0200a02:	e142                	sd	a6,128(sp)
ffffffffc0200a04:	e546                	sd	a7,136(sp)
ffffffffc0200a06:	e94a                	sd	s2,144(sp)
ffffffffc0200a08:	ed4e                	sd	s3,152(sp)
ffffffffc0200a0a:	f152                	sd	s4,160(sp)
ffffffffc0200a0c:	f556                	sd	s5,168(sp)
ffffffffc0200a0e:	f95a                	sd	s6,176(sp)
ffffffffc0200a10:	fd5e                	sd	s7,184(sp)
ffffffffc0200a12:	e1e2                	sd	s8,192(sp)
ffffffffc0200a14:	e5e6                	sd	s9,200(sp)
ffffffffc0200a16:	e9ea                	sd	s10,208(sp)
ffffffffc0200a18:	edee                	sd	s11,216(sp)
ffffffffc0200a1a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a1c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a1e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a20:	fdfe                	sd	t6,248(sp)
ffffffffc0200a22:	14002473          	csrr	s0,sscratch
ffffffffc0200a26:	100024f3          	csrr	s1,sstatus
ffffffffc0200a2a:	14102973          	csrr	s2,sepc
ffffffffc0200a2e:	143029f3          	csrr	s3,stval
ffffffffc0200a32:	14202a73          	csrr	s4,scause
ffffffffc0200a36:	e822                	sd	s0,16(sp)
ffffffffc0200a38:	e226                	sd	s1,256(sp)
ffffffffc0200a3a:	e64a                	sd	s2,264(sp)
ffffffffc0200a3c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a3e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a40:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a42:	f87ff0ef          	jal	ffffffffc02009c8 <trap>

ffffffffc0200a46 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a46:	6492                	ld	s1,256(sp)
ffffffffc0200a48:	6932                	ld	s2,264(sp)
ffffffffc0200a4a:	10049073          	csrw	sstatus,s1
ffffffffc0200a4e:	14191073          	csrw	sepc,s2
ffffffffc0200a52:	60a2                	ld	ra,8(sp)
ffffffffc0200a54:	61e2                	ld	gp,24(sp)
ffffffffc0200a56:	7202                	ld	tp,32(sp)
ffffffffc0200a58:	72a2                	ld	t0,40(sp)
ffffffffc0200a5a:	7342                	ld	t1,48(sp)
ffffffffc0200a5c:	73e2                	ld	t2,56(sp)
ffffffffc0200a5e:	6406                	ld	s0,64(sp)
ffffffffc0200a60:	64a6                	ld	s1,72(sp)
ffffffffc0200a62:	6546                	ld	a0,80(sp)
ffffffffc0200a64:	65e6                	ld	a1,88(sp)
ffffffffc0200a66:	7606                	ld	a2,96(sp)
ffffffffc0200a68:	76a6                	ld	a3,104(sp)
ffffffffc0200a6a:	7746                	ld	a4,112(sp)
ffffffffc0200a6c:	77e6                	ld	a5,120(sp)
ffffffffc0200a6e:	680a                	ld	a6,128(sp)
ffffffffc0200a70:	68aa                	ld	a7,136(sp)
ffffffffc0200a72:	694a                	ld	s2,144(sp)
ffffffffc0200a74:	69ea                	ld	s3,152(sp)
ffffffffc0200a76:	7a0a                	ld	s4,160(sp)
ffffffffc0200a78:	7aaa                	ld	s5,168(sp)
ffffffffc0200a7a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a7c:	7bea                	ld	s7,184(sp)
ffffffffc0200a7e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a80:	6cae                	ld	s9,200(sp)
ffffffffc0200a82:	6d4e                	ld	s10,208(sp)
ffffffffc0200a84:	6dee                	ld	s11,216(sp)
ffffffffc0200a86:	7e0e                	ld	t3,224(sp)
ffffffffc0200a88:	7eae                	ld	t4,232(sp)
ffffffffc0200a8a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a8c:	7fee                	ld	t6,248(sp)
ffffffffc0200a8e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200a90:	10200073          	sret
	...

ffffffffc0200aa0 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200aa0:	00010797          	auipc	a5,0x10
ffffffffc0200aa4:	5a078793          	add	a5,a5,1440 # ffffffffc0211040 <free_area>
ffffffffc0200aa8:	e79c                	sd	a5,8(a5)
ffffffffc0200aaa:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200aac:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ab0:	8082                	ret

ffffffffc0200ab2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ab2:	00010517          	auipc	a0,0x10
ffffffffc0200ab6:	59e56503          	lwu	a0,1438(a0) # ffffffffc0211050 <free_area+0x10>
ffffffffc0200aba:	8082                	ret

ffffffffc0200abc <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200abc:	715d                	add	sp,sp,-80
ffffffffc0200abe:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ac0:	00010417          	auipc	s0,0x10
ffffffffc0200ac4:	58040413          	add	s0,s0,1408 # ffffffffc0211040 <free_area>
ffffffffc0200ac8:	641c                	ld	a5,8(s0)
ffffffffc0200aca:	e486                	sd	ra,72(sp)
ffffffffc0200acc:	fc26                	sd	s1,56(sp)
ffffffffc0200ace:	f84a                	sd	s2,48(sp)
ffffffffc0200ad0:	f44e                	sd	s3,40(sp)
ffffffffc0200ad2:	f052                	sd	s4,32(sp)
ffffffffc0200ad4:	ec56                	sd	s5,24(sp)
ffffffffc0200ad6:	e85a                	sd	s6,16(sp)
ffffffffc0200ad8:	e45e                	sd	s7,8(sp)
ffffffffc0200ada:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200adc:	2e878063          	beq	a5,s0,ffffffffc0200dbc <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200ae0:	4481                	li	s1,0
ffffffffc0200ae2:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ae4:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ae8:	8b09                	and	a4,a4,2
ffffffffc0200aea:	2c070d63          	beqz	a4,ffffffffc0200dc4 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200aee:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200af2:	679c                	ld	a5,8(a5)
ffffffffc0200af4:	2905                	addw	s2,s2,1
ffffffffc0200af6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200af8:	fe8796e3          	bne	a5,s0,ffffffffc0200ae4 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200afc:	89a6                	mv	s3,s1
ffffffffc0200afe:	395000ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc0200b02:	73351163          	bne	a0,s3,ffffffffc0201224 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b06:	4505                	li	a0,1
ffffffffc0200b08:	2bb000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200b0c:	8a2a                	mv	s4,a0
ffffffffc0200b0e:	44050b63          	beqz	a0,ffffffffc0200f64 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b12:	4505                	li	a0,1
ffffffffc0200b14:	2af000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200b18:	89aa                	mv	s3,a0
ffffffffc0200b1a:	72050563          	beqz	a0,ffffffffc0201244 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b1e:	4505                	li	a0,1
ffffffffc0200b20:	2a3000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200b24:	8aaa                	mv	s5,a0
ffffffffc0200b26:	4a050f63          	beqz	a0,ffffffffc0200fe4 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b2a:	2b3a0d63          	beq	s4,s3,ffffffffc0200de4 <default_check+0x328>
ffffffffc0200b2e:	2aaa0b63          	beq	s4,a0,ffffffffc0200de4 <default_check+0x328>
ffffffffc0200b32:	2aa98963          	beq	s3,a0,ffffffffc0200de4 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b36:	000a2783          	lw	a5,0(s4)
ffffffffc0200b3a:	2c079563          	bnez	a5,ffffffffc0200e04 <default_check+0x348>
ffffffffc0200b3e:	0009a783          	lw	a5,0(s3)
ffffffffc0200b42:	2c079163          	bnez	a5,ffffffffc0200e04 <default_check+0x348>
ffffffffc0200b46:	411c                	lw	a5,0(a0)
ffffffffc0200b48:	2a079e63          	bnez	a5,ffffffffc0200e04 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b4c:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0200b50:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0200b54:	07b2                	sll	a5,a5,0xc
ffffffffc0200b56:	e3978793          	add	a5,a5,-455
ffffffffc0200b5a:	07b2                	sll	a5,a5,0xc
ffffffffc0200b5c:	00011717          	auipc	a4,0x11
ffffffffc0200b60:	9dc73703          	ld	a4,-1572(a4) # ffffffffc0211538 <pages>
ffffffffc0200b64:	e3978793          	add	a5,a5,-455
ffffffffc0200b68:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200b6c:	07b2                	sll	a5,a5,0xc
ffffffffc0200b6e:	868d                	sra	a3,a3,0x3
ffffffffc0200b70:	e3978793          	add	a5,a5,-455
ffffffffc0200b74:	02f686b3          	mul	a3,a3,a5
ffffffffc0200b78:	00005597          	auipc	a1,0x5
ffffffffc0200b7c:	7885b583          	ld	a1,1928(a1) # ffffffffc0206300 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b80:	00011617          	auipc	a2,0x11
ffffffffc0200b84:	9b063603          	ld	a2,-1616(a2) # ffffffffc0211530 <npage>
ffffffffc0200b88:	0632                	sll	a2,a2,0xc
ffffffffc0200b8a:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b8c:	06b2                	sll	a3,a3,0xc
ffffffffc0200b8e:	28c6fb63          	bgeu	a3,a2,ffffffffc0200e24 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b92:	40e986b3          	sub	a3,s3,a4
ffffffffc0200b96:	868d                	sra	a3,a3,0x3
ffffffffc0200b98:	02f686b3          	mul	a3,a3,a5
ffffffffc0200b9c:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200b9e:	06b2                	sll	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ba0:	4cc6f263          	bgeu	a3,a2,ffffffffc0201064 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ba4:	40e50733          	sub	a4,a0,a4
ffffffffc0200ba8:	870d                	sra	a4,a4,0x3
ffffffffc0200baa:	02f707b3          	mul	a5,a4,a5
ffffffffc0200bae:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bb0:	07b2                	sll	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200bb2:	30c7f963          	bgeu	a5,a2,ffffffffc0200ec4 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200bb6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200bb8:	00043c03          	ld	s8,0(s0)
ffffffffc0200bbc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200bc0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200bc4:	e400                	sd	s0,8(s0)
ffffffffc0200bc6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200bc8:	00010797          	auipc	a5,0x10
ffffffffc0200bcc:	4807a423          	sw	zero,1160(a5) # ffffffffc0211050 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200bd0:	1f3000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200bd4:	2c051863          	bnez	a0,ffffffffc0200ea4 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200bd8:	4585                	li	a1,1
ffffffffc0200bda:	8552                	mv	a0,s4
ffffffffc0200bdc:	277000ef          	jal	ffffffffc0201652 <free_pages>
    free_page(p1);
ffffffffc0200be0:	4585                	li	a1,1
ffffffffc0200be2:	854e                	mv	a0,s3
ffffffffc0200be4:	26f000ef          	jal	ffffffffc0201652 <free_pages>
    free_page(p2);
ffffffffc0200be8:	4585                	li	a1,1
ffffffffc0200bea:	8556                	mv	a0,s5
ffffffffc0200bec:	267000ef          	jal	ffffffffc0201652 <free_pages>
    assert(nr_free == 3);
ffffffffc0200bf0:	4818                	lw	a4,16(s0)
ffffffffc0200bf2:	478d                	li	a5,3
ffffffffc0200bf4:	28f71863          	bne	a4,a5,ffffffffc0200e84 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bf8:	4505                	li	a0,1
ffffffffc0200bfa:	1c9000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200bfe:	89aa                	mv	s3,a0
ffffffffc0200c00:	26050263          	beqz	a0,ffffffffc0200e64 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c04:	4505                	li	a0,1
ffffffffc0200c06:	1bd000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c0a:	8aaa                	mv	s5,a0
ffffffffc0200c0c:	3a050c63          	beqz	a0,ffffffffc0200fc4 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c10:	4505                	li	a0,1
ffffffffc0200c12:	1b1000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c16:	8a2a                	mv	s4,a0
ffffffffc0200c18:	38050663          	beqz	a0,ffffffffc0200fa4 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200c1c:	4505                	li	a0,1
ffffffffc0200c1e:	1a5000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c22:	36051163          	bnez	a0,ffffffffc0200f84 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200c26:	4585                	li	a1,1
ffffffffc0200c28:	854e                	mv	a0,s3
ffffffffc0200c2a:	229000ef          	jal	ffffffffc0201652 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200c2e:	641c                	ld	a5,8(s0)
ffffffffc0200c30:	20878a63          	beq	a5,s0,ffffffffc0200e44 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200c34:	4505                	li	a0,1
ffffffffc0200c36:	18d000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c3a:	30a99563          	bne	s3,a0,ffffffffc0200f44 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200c3e:	4505                	li	a0,1
ffffffffc0200c40:	183000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c44:	2e051063          	bnez	a0,ffffffffc0200f24 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200c48:	481c                	lw	a5,16(s0)
ffffffffc0200c4a:	2a079d63          	bnez	a5,ffffffffc0200f04 <default_check+0x448>
    free_page(p);
ffffffffc0200c4e:	854e                	mv	a0,s3
ffffffffc0200c50:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200c52:	01843023          	sd	s8,0(s0)
ffffffffc0200c56:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200c5a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200c5e:	1f5000ef          	jal	ffffffffc0201652 <free_pages>
    free_page(p1);
ffffffffc0200c62:	4585                	li	a1,1
ffffffffc0200c64:	8556                	mv	a0,s5
ffffffffc0200c66:	1ed000ef          	jal	ffffffffc0201652 <free_pages>
    free_page(p2);
ffffffffc0200c6a:	4585                	li	a1,1
ffffffffc0200c6c:	8552                	mv	a0,s4
ffffffffc0200c6e:	1e5000ef          	jal	ffffffffc0201652 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200c72:	4515                	li	a0,5
ffffffffc0200c74:	14f000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c78:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200c7a:	26050563          	beqz	a0,ffffffffc0200ee4 <default_check+0x428>
ffffffffc0200c7e:	651c                	ld	a5,8(a0)
ffffffffc0200c80:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200c82:	8b85                	and	a5,a5,1
ffffffffc0200c84:	54079063          	bnez	a5,ffffffffc02011c4 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200c88:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c8a:	00043b03          	ld	s6,0(s0)
ffffffffc0200c8e:	00843a83          	ld	s5,8(s0)
ffffffffc0200c92:	e000                	sd	s0,0(s0)
ffffffffc0200c94:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200c96:	12d000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200c9a:	50051563          	bnez	a0,ffffffffc02011a4 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200c9e:	09098a13          	add	s4,s3,144
ffffffffc0200ca2:	8552                	mv	a0,s4
ffffffffc0200ca4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ca6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200caa:	00010797          	auipc	a5,0x10
ffffffffc0200cae:	3a07a323          	sw	zero,934(a5) # ffffffffc0211050 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200cb2:	1a1000ef          	jal	ffffffffc0201652 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200cb6:	4511                	li	a0,4
ffffffffc0200cb8:	10b000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200cbc:	4c051463          	bnez	a0,ffffffffc0201184 <default_check+0x6c8>
ffffffffc0200cc0:	0989b783          	ld	a5,152(s3)
ffffffffc0200cc4:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200cc6:	8b85                	and	a5,a5,1
ffffffffc0200cc8:	48078e63          	beqz	a5,ffffffffc0201164 <default_check+0x6a8>
ffffffffc0200ccc:	0a89a703          	lw	a4,168(s3)
ffffffffc0200cd0:	478d                	li	a5,3
ffffffffc0200cd2:	48f71963          	bne	a4,a5,ffffffffc0201164 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200cd6:	450d                	li	a0,3
ffffffffc0200cd8:	0eb000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200cdc:	8c2a                	mv	s8,a0
ffffffffc0200cde:	46050363          	beqz	a0,ffffffffc0201144 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200ce2:	4505                	li	a0,1
ffffffffc0200ce4:	0df000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200ce8:	42051e63          	bnez	a0,ffffffffc0201124 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200cec:	418a1c63          	bne	s4,s8,ffffffffc0201104 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200cf0:	4585                	li	a1,1
ffffffffc0200cf2:	854e                	mv	a0,s3
ffffffffc0200cf4:	15f000ef          	jal	ffffffffc0201652 <free_pages>
    free_pages(p1, 3);
ffffffffc0200cf8:	458d                	li	a1,3
ffffffffc0200cfa:	8552                	mv	a0,s4
ffffffffc0200cfc:	157000ef          	jal	ffffffffc0201652 <free_pages>
ffffffffc0200d00:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200d04:	04898c13          	add	s8,s3,72
ffffffffc0200d08:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200d0a:	8b85                	and	a5,a5,1
ffffffffc0200d0c:	3c078c63          	beqz	a5,ffffffffc02010e4 <default_check+0x628>
ffffffffc0200d10:	0189a703          	lw	a4,24(s3)
ffffffffc0200d14:	4785                	li	a5,1
ffffffffc0200d16:	3cf71763          	bne	a4,a5,ffffffffc02010e4 <default_check+0x628>
ffffffffc0200d1a:	008a3783          	ld	a5,8(s4)
ffffffffc0200d1e:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200d20:	8b85                	and	a5,a5,1
ffffffffc0200d22:	3a078163          	beqz	a5,ffffffffc02010c4 <default_check+0x608>
ffffffffc0200d26:	018a2703          	lw	a4,24(s4)
ffffffffc0200d2a:	478d                	li	a5,3
ffffffffc0200d2c:	38f71c63          	bne	a4,a5,ffffffffc02010c4 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200d30:	4505                	li	a0,1
ffffffffc0200d32:	091000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200d36:	36a99763          	bne	s3,a0,ffffffffc02010a4 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200d3a:	4585                	li	a1,1
ffffffffc0200d3c:	117000ef          	jal	ffffffffc0201652 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200d40:	4509                	li	a0,2
ffffffffc0200d42:	081000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200d46:	32aa1f63          	bne	s4,a0,ffffffffc0201084 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200d4a:	4589                	li	a1,2
ffffffffc0200d4c:	107000ef          	jal	ffffffffc0201652 <free_pages>
    free_page(p2);
ffffffffc0200d50:	4585                	li	a1,1
ffffffffc0200d52:	8562                	mv	a0,s8
ffffffffc0200d54:	0ff000ef          	jal	ffffffffc0201652 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200d58:	4515                	li	a0,5
ffffffffc0200d5a:	069000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200d5e:	89aa                	mv	s3,a0
ffffffffc0200d60:	48050263          	beqz	a0,ffffffffc02011e4 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200d64:	4505                	li	a0,1
ffffffffc0200d66:	05d000ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0200d6a:	2c051d63          	bnez	a0,ffffffffc0201044 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200d6e:	481c                	lw	a5,16(s0)
ffffffffc0200d70:	2a079a63          	bnez	a5,ffffffffc0201024 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200d74:	4595                	li	a1,5
ffffffffc0200d76:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200d78:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200d7c:	01643023          	sd	s6,0(s0)
ffffffffc0200d80:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200d84:	0cf000ef          	jal	ffffffffc0201652 <free_pages>
    return listelm->next;
ffffffffc0200d88:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d8a:	00878963          	beq	a5,s0,ffffffffc0200d9c <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200d8e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d92:	679c                	ld	a5,8(a5)
ffffffffc0200d94:	397d                	addw	s2,s2,-1
ffffffffc0200d96:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d98:	fe879be3          	bne	a5,s0,ffffffffc0200d8e <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200d9c:	26091463          	bnez	s2,ffffffffc0201004 <default_check+0x548>
    assert(total == 0);
ffffffffc0200da0:	46049263          	bnez	s1,ffffffffc0201204 <default_check+0x748>
}
ffffffffc0200da4:	60a6                	ld	ra,72(sp)
ffffffffc0200da6:	6406                	ld	s0,64(sp)
ffffffffc0200da8:	74e2                	ld	s1,56(sp)
ffffffffc0200daa:	7942                	ld	s2,48(sp)
ffffffffc0200dac:	79a2                	ld	s3,40(sp)
ffffffffc0200dae:	7a02                	ld	s4,32(sp)
ffffffffc0200db0:	6ae2                	ld	s5,24(sp)
ffffffffc0200db2:	6b42                	ld	s6,16(sp)
ffffffffc0200db4:	6ba2                	ld	s7,8(sp)
ffffffffc0200db6:	6c02                	ld	s8,0(sp)
ffffffffc0200db8:	6161                	add	sp,sp,80
ffffffffc0200dba:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dbc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200dbe:	4481                	li	s1,0
ffffffffc0200dc0:	4901                	li	s2,0
ffffffffc0200dc2:	bb35                	j	ffffffffc0200afe <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200dc4:	00004697          	auipc	a3,0x4
ffffffffc0200dc8:	ff468693          	add	a3,a3,-12 # ffffffffc0204db8 <etext+0x8ce>
ffffffffc0200dcc:	00004617          	auipc	a2,0x4
ffffffffc0200dd0:	ffc60613          	add	a2,a2,-4 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200dd4:	0f000593          	li	a1,240
ffffffffc0200dd8:	00004517          	auipc	a0,0x4
ffffffffc0200ddc:	00850513          	add	a0,a0,8 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200de0:	d80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200de4:	00004697          	auipc	a3,0x4
ffffffffc0200de8:	09468693          	add	a3,a3,148 # ffffffffc0204e78 <etext+0x98e>
ffffffffc0200dec:	00004617          	auipc	a2,0x4
ffffffffc0200df0:	fdc60613          	add	a2,a2,-36 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200df4:	0bd00593          	li	a1,189
ffffffffc0200df8:	00004517          	auipc	a0,0x4
ffffffffc0200dfc:	fe850513          	add	a0,a0,-24 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200e00:	d60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e04:	00004697          	auipc	a3,0x4
ffffffffc0200e08:	09c68693          	add	a3,a3,156 # ffffffffc0204ea0 <etext+0x9b6>
ffffffffc0200e0c:	00004617          	auipc	a2,0x4
ffffffffc0200e10:	fbc60613          	add	a2,a2,-68 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200e14:	0be00593          	li	a1,190
ffffffffc0200e18:	00004517          	auipc	a0,0x4
ffffffffc0200e1c:	fc850513          	add	a0,a0,-56 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200e20:	d40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e24:	00004697          	auipc	a3,0x4
ffffffffc0200e28:	0bc68693          	add	a3,a3,188 # ffffffffc0204ee0 <etext+0x9f6>
ffffffffc0200e2c:	00004617          	auipc	a2,0x4
ffffffffc0200e30:	f9c60613          	add	a2,a2,-100 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200e34:	0c000593          	li	a1,192
ffffffffc0200e38:	00004517          	auipc	a0,0x4
ffffffffc0200e3c:	fa850513          	add	a0,a0,-88 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200e40:	d20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200e44:	00004697          	auipc	a3,0x4
ffffffffc0200e48:	12468693          	add	a3,a3,292 # ffffffffc0204f68 <etext+0xa7e>
ffffffffc0200e4c:	00004617          	auipc	a2,0x4
ffffffffc0200e50:	f7c60613          	add	a2,a2,-132 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200e54:	0d900593          	li	a1,217
ffffffffc0200e58:	00004517          	auipc	a0,0x4
ffffffffc0200e5c:	f8850513          	add	a0,a0,-120 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200e60:	d00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e64:	00004697          	auipc	a3,0x4
ffffffffc0200e68:	fb468693          	add	a3,a3,-76 # ffffffffc0204e18 <etext+0x92e>
ffffffffc0200e6c:	00004617          	auipc	a2,0x4
ffffffffc0200e70:	f5c60613          	add	a2,a2,-164 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200e74:	0d200593          	li	a1,210
ffffffffc0200e78:	00004517          	auipc	a0,0x4
ffffffffc0200e7c:	f6850513          	add	a0,a0,-152 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200e80:	ce0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 3);
ffffffffc0200e84:	00004697          	auipc	a3,0x4
ffffffffc0200e88:	0d468693          	add	a3,a3,212 # ffffffffc0204f58 <etext+0xa6e>
ffffffffc0200e8c:	00004617          	auipc	a2,0x4
ffffffffc0200e90:	f3c60613          	add	a2,a2,-196 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200e94:	0d000593          	li	a1,208
ffffffffc0200e98:	00004517          	auipc	a0,0x4
ffffffffc0200e9c:	f4850513          	add	a0,a0,-184 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200ea0:	cc0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ea4:	00004697          	auipc	a3,0x4
ffffffffc0200ea8:	09c68693          	add	a3,a3,156 # ffffffffc0204f40 <etext+0xa56>
ffffffffc0200eac:	00004617          	auipc	a2,0x4
ffffffffc0200eb0:	f1c60613          	add	a2,a2,-228 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200eb4:	0cb00593          	li	a1,203
ffffffffc0200eb8:	00004517          	auipc	a0,0x4
ffffffffc0200ebc:	f2850513          	add	a0,a0,-216 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200ec0:	ca0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ec4:	00004697          	auipc	a3,0x4
ffffffffc0200ec8:	05c68693          	add	a3,a3,92 # ffffffffc0204f20 <etext+0xa36>
ffffffffc0200ecc:	00004617          	auipc	a2,0x4
ffffffffc0200ed0:	efc60613          	add	a2,a2,-260 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200ed4:	0c200593          	li	a1,194
ffffffffc0200ed8:	00004517          	auipc	a0,0x4
ffffffffc0200edc:	f0850513          	add	a0,a0,-248 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200ee0:	c80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 != NULL);
ffffffffc0200ee4:	00004697          	auipc	a3,0x4
ffffffffc0200ee8:	0cc68693          	add	a3,a3,204 # ffffffffc0204fb0 <etext+0xac6>
ffffffffc0200eec:	00004617          	auipc	a2,0x4
ffffffffc0200ef0:	edc60613          	add	a2,a2,-292 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200ef4:	0f800593          	li	a1,248
ffffffffc0200ef8:	00004517          	auipc	a0,0x4
ffffffffc0200efc:	ee850513          	add	a0,a0,-280 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200f00:	c60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0200f04:	00004697          	auipc	a3,0x4
ffffffffc0200f08:	09c68693          	add	a3,a3,156 # ffffffffc0204fa0 <etext+0xab6>
ffffffffc0200f0c:	00004617          	auipc	a2,0x4
ffffffffc0200f10:	ebc60613          	add	a2,a2,-324 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200f14:	0df00593          	li	a1,223
ffffffffc0200f18:	00004517          	auipc	a0,0x4
ffffffffc0200f1c:	ec850513          	add	a0,a0,-312 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200f20:	c40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f24:	00004697          	auipc	a3,0x4
ffffffffc0200f28:	01c68693          	add	a3,a3,28 # ffffffffc0204f40 <etext+0xa56>
ffffffffc0200f2c:	00004617          	auipc	a2,0x4
ffffffffc0200f30:	e9c60613          	add	a2,a2,-356 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200f34:	0dd00593          	li	a1,221
ffffffffc0200f38:	00004517          	auipc	a0,0x4
ffffffffc0200f3c:	ea850513          	add	a0,a0,-344 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200f40:	c20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f44:	00004697          	auipc	a3,0x4
ffffffffc0200f48:	03c68693          	add	a3,a3,60 # ffffffffc0204f80 <etext+0xa96>
ffffffffc0200f4c:	00004617          	auipc	a2,0x4
ffffffffc0200f50:	e7c60613          	add	a2,a2,-388 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200f54:	0dc00593          	li	a1,220
ffffffffc0200f58:	00004517          	auipc	a0,0x4
ffffffffc0200f5c:	e8850513          	add	a0,a0,-376 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200f60:	c00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f64:	00004697          	auipc	a3,0x4
ffffffffc0200f68:	eb468693          	add	a3,a3,-332 # ffffffffc0204e18 <etext+0x92e>
ffffffffc0200f6c:	00004617          	auipc	a2,0x4
ffffffffc0200f70:	e5c60613          	add	a2,a2,-420 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200f74:	0b900593          	li	a1,185
ffffffffc0200f78:	00004517          	auipc	a0,0x4
ffffffffc0200f7c:	e6850513          	add	a0,a0,-408 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200f80:	be0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f84:	00004697          	auipc	a3,0x4
ffffffffc0200f88:	fbc68693          	add	a3,a3,-68 # ffffffffc0204f40 <etext+0xa56>
ffffffffc0200f8c:	00004617          	auipc	a2,0x4
ffffffffc0200f90:	e3c60613          	add	a2,a2,-452 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200f94:	0d600593          	li	a1,214
ffffffffc0200f98:	00004517          	auipc	a0,0x4
ffffffffc0200f9c:	e4850513          	add	a0,a0,-440 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200fa0:	bc0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fa4:	00004697          	auipc	a3,0x4
ffffffffc0200fa8:	eb468693          	add	a3,a3,-332 # ffffffffc0204e58 <etext+0x96e>
ffffffffc0200fac:	00004617          	auipc	a2,0x4
ffffffffc0200fb0:	e1c60613          	add	a2,a2,-484 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200fb4:	0d400593          	li	a1,212
ffffffffc0200fb8:	00004517          	auipc	a0,0x4
ffffffffc0200fbc:	e2850513          	add	a0,a0,-472 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200fc0:	ba0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc4:	00004697          	auipc	a3,0x4
ffffffffc0200fc8:	e7468693          	add	a3,a3,-396 # ffffffffc0204e38 <etext+0x94e>
ffffffffc0200fcc:	00004617          	auipc	a2,0x4
ffffffffc0200fd0:	dfc60613          	add	a2,a2,-516 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200fd4:	0d300593          	li	a1,211
ffffffffc0200fd8:	00004517          	auipc	a0,0x4
ffffffffc0200fdc:	e0850513          	add	a0,a0,-504 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0200fe0:	b80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fe4:	00004697          	auipc	a3,0x4
ffffffffc0200fe8:	e7468693          	add	a3,a3,-396 # ffffffffc0204e58 <etext+0x96e>
ffffffffc0200fec:	00004617          	auipc	a2,0x4
ffffffffc0200ff0:	ddc60613          	add	a2,a2,-548 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0200ff4:	0bb00593          	li	a1,187
ffffffffc0200ff8:	00004517          	auipc	a0,0x4
ffffffffc0200ffc:	de850513          	add	a0,a0,-536 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201000:	b60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(count == 0);
ffffffffc0201004:	00004697          	auipc	a3,0x4
ffffffffc0201008:	0fc68693          	add	a3,a3,252 # ffffffffc0205100 <etext+0xc16>
ffffffffc020100c:	00004617          	auipc	a2,0x4
ffffffffc0201010:	dbc60613          	add	a2,a2,-580 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201014:	12500593          	li	a1,293
ffffffffc0201018:	00004517          	auipc	a0,0x4
ffffffffc020101c:	dc850513          	add	a0,a0,-568 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201020:	b40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free == 0);
ffffffffc0201024:	00004697          	auipc	a3,0x4
ffffffffc0201028:	f7c68693          	add	a3,a3,-132 # ffffffffc0204fa0 <etext+0xab6>
ffffffffc020102c:	00004617          	auipc	a2,0x4
ffffffffc0201030:	d9c60613          	add	a2,a2,-612 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201034:	11a00593          	li	a1,282
ffffffffc0201038:	00004517          	auipc	a0,0x4
ffffffffc020103c:	da850513          	add	a0,a0,-600 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201040:	b20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201044:	00004697          	auipc	a3,0x4
ffffffffc0201048:	efc68693          	add	a3,a3,-260 # ffffffffc0204f40 <etext+0xa56>
ffffffffc020104c:	00004617          	auipc	a2,0x4
ffffffffc0201050:	d7c60613          	add	a2,a2,-644 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201054:	11800593          	li	a1,280
ffffffffc0201058:	00004517          	auipc	a0,0x4
ffffffffc020105c:	d8850513          	add	a0,a0,-632 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201060:	b00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201064:	00004697          	auipc	a3,0x4
ffffffffc0201068:	e9c68693          	add	a3,a3,-356 # ffffffffc0204f00 <etext+0xa16>
ffffffffc020106c:	00004617          	auipc	a2,0x4
ffffffffc0201070:	d5c60613          	add	a2,a2,-676 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201074:	0c100593          	li	a1,193
ffffffffc0201078:	00004517          	auipc	a0,0x4
ffffffffc020107c:	d6850513          	add	a0,a0,-664 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201080:	ae0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201084:	00004697          	auipc	a3,0x4
ffffffffc0201088:	03c68693          	add	a3,a3,60 # ffffffffc02050c0 <etext+0xbd6>
ffffffffc020108c:	00004617          	auipc	a2,0x4
ffffffffc0201090:	d3c60613          	add	a2,a2,-708 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201094:	11200593          	li	a1,274
ffffffffc0201098:	00004517          	auipc	a0,0x4
ffffffffc020109c:	d4850513          	add	a0,a0,-696 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02010a0:	ac0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010a4:	00004697          	auipc	a3,0x4
ffffffffc02010a8:	ffc68693          	add	a3,a3,-4 # ffffffffc02050a0 <etext+0xbb6>
ffffffffc02010ac:	00004617          	auipc	a2,0x4
ffffffffc02010b0:	d1c60613          	add	a2,a2,-740 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02010b4:	11000593          	li	a1,272
ffffffffc02010b8:	00004517          	auipc	a0,0x4
ffffffffc02010bc:	d2850513          	add	a0,a0,-728 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02010c0:	aa0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010c4:	00004697          	auipc	a3,0x4
ffffffffc02010c8:	fb468693          	add	a3,a3,-76 # ffffffffc0205078 <etext+0xb8e>
ffffffffc02010cc:	00004617          	auipc	a2,0x4
ffffffffc02010d0:	cfc60613          	add	a2,a2,-772 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02010d4:	10e00593          	li	a1,270
ffffffffc02010d8:	00004517          	auipc	a0,0x4
ffffffffc02010dc:	d0850513          	add	a0,a0,-760 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02010e0:	a80ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010e4:	00004697          	auipc	a3,0x4
ffffffffc02010e8:	f6c68693          	add	a3,a3,-148 # ffffffffc0205050 <etext+0xb66>
ffffffffc02010ec:	00004617          	auipc	a2,0x4
ffffffffc02010f0:	cdc60613          	add	a2,a2,-804 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02010f4:	10d00593          	li	a1,269
ffffffffc02010f8:	00004517          	auipc	a0,0x4
ffffffffc02010fc:	ce850513          	add	a0,a0,-792 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201100:	a60ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201104:	00004697          	auipc	a3,0x4
ffffffffc0201108:	f3c68693          	add	a3,a3,-196 # ffffffffc0205040 <etext+0xb56>
ffffffffc020110c:	00004617          	auipc	a2,0x4
ffffffffc0201110:	cbc60613          	add	a2,a2,-836 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201114:	10800593          	li	a1,264
ffffffffc0201118:	00004517          	auipc	a0,0x4
ffffffffc020111c:	cc850513          	add	a0,a0,-824 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201120:	a40ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201124:	00004697          	auipc	a3,0x4
ffffffffc0201128:	e1c68693          	add	a3,a3,-484 # ffffffffc0204f40 <etext+0xa56>
ffffffffc020112c:	00004617          	auipc	a2,0x4
ffffffffc0201130:	c9c60613          	add	a2,a2,-868 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201134:	10700593          	li	a1,263
ffffffffc0201138:	00004517          	auipc	a0,0x4
ffffffffc020113c:	ca850513          	add	a0,a0,-856 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201140:	a20ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201144:	00004697          	auipc	a3,0x4
ffffffffc0201148:	edc68693          	add	a3,a3,-292 # ffffffffc0205020 <etext+0xb36>
ffffffffc020114c:	00004617          	auipc	a2,0x4
ffffffffc0201150:	c7c60613          	add	a2,a2,-900 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201154:	10600593          	li	a1,262
ffffffffc0201158:	00004517          	auipc	a0,0x4
ffffffffc020115c:	c8850513          	add	a0,a0,-888 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201160:	a00ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201164:	00004697          	auipc	a3,0x4
ffffffffc0201168:	e8c68693          	add	a3,a3,-372 # ffffffffc0204ff0 <etext+0xb06>
ffffffffc020116c:	00004617          	auipc	a2,0x4
ffffffffc0201170:	c5c60613          	add	a2,a2,-932 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201174:	10500593          	li	a1,261
ffffffffc0201178:	00004517          	auipc	a0,0x4
ffffffffc020117c:	c6850513          	add	a0,a0,-920 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201180:	9e0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201184:	00004697          	auipc	a3,0x4
ffffffffc0201188:	e5468693          	add	a3,a3,-428 # ffffffffc0204fd8 <etext+0xaee>
ffffffffc020118c:	00004617          	auipc	a2,0x4
ffffffffc0201190:	c3c60613          	add	a2,a2,-964 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201194:	10400593          	li	a1,260
ffffffffc0201198:	00004517          	auipc	a0,0x4
ffffffffc020119c:	c4850513          	add	a0,a0,-952 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02011a0:	9c0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011a4:	00004697          	auipc	a3,0x4
ffffffffc02011a8:	d9c68693          	add	a3,a3,-612 # ffffffffc0204f40 <etext+0xa56>
ffffffffc02011ac:	00004617          	auipc	a2,0x4
ffffffffc02011b0:	c1c60613          	add	a2,a2,-996 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02011b4:	0fe00593          	li	a1,254
ffffffffc02011b8:	00004517          	auipc	a0,0x4
ffffffffc02011bc:	c2850513          	add	a0,a0,-984 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02011c0:	9a0ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(!PageProperty(p0));
ffffffffc02011c4:	00004697          	auipc	a3,0x4
ffffffffc02011c8:	dfc68693          	add	a3,a3,-516 # ffffffffc0204fc0 <etext+0xad6>
ffffffffc02011cc:	00004617          	auipc	a2,0x4
ffffffffc02011d0:	bfc60613          	add	a2,a2,-1028 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02011d4:	0f900593          	li	a1,249
ffffffffc02011d8:	00004517          	auipc	a0,0x4
ffffffffc02011dc:	c0850513          	add	a0,a0,-1016 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02011e0:	980ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02011e4:	00004697          	auipc	a3,0x4
ffffffffc02011e8:	efc68693          	add	a3,a3,-260 # ffffffffc02050e0 <etext+0xbf6>
ffffffffc02011ec:	00004617          	auipc	a2,0x4
ffffffffc02011f0:	bdc60613          	add	a2,a2,-1060 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02011f4:	11700593          	li	a1,279
ffffffffc02011f8:	00004517          	auipc	a0,0x4
ffffffffc02011fc:	be850513          	add	a0,a0,-1048 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201200:	960ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == 0);
ffffffffc0201204:	00004697          	auipc	a3,0x4
ffffffffc0201208:	f0c68693          	add	a3,a3,-244 # ffffffffc0205110 <etext+0xc26>
ffffffffc020120c:	00004617          	auipc	a2,0x4
ffffffffc0201210:	bbc60613          	add	a2,a2,-1092 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201214:	12600593          	li	a1,294
ffffffffc0201218:	00004517          	auipc	a0,0x4
ffffffffc020121c:	bc850513          	add	a0,a0,-1080 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201220:	940ff0ef          	jal	ffffffffc0200360 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201224:	00004697          	auipc	a3,0x4
ffffffffc0201228:	bd468693          	add	a3,a3,-1068 # ffffffffc0204df8 <etext+0x90e>
ffffffffc020122c:	00004617          	auipc	a2,0x4
ffffffffc0201230:	b9c60613          	add	a2,a2,-1124 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201234:	0f300593          	li	a1,243
ffffffffc0201238:	00004517          	auipc	a0,0x4
ffffffffc020123c:	ba850513          	add	a0,a0,-1112 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201240:	920ff0ef          	jal	ffffffffc0200360 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201244:	00004697          	auipc	a3,0x4
ffffffffc0201248:	bf468693          	add	a3,a3,-1036 # ffffffffc0204e38 <etext+0x94e>
ffffffffc020124c:	00004617          	auipc	a2,0x4
ffffffffc0201250:	b7c60613          	add	a2,a2,-1156 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201254:	0ba00593          	li	a1,186
ffffffffc0201258:	00004517          	auipc	a0,0x4
ffffffffc020125c:	b8850513          	add	a0,a0,-1144 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201260:	900ff0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201264 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201264:	1141                	add	sp,sp,-16
ffffffffc0201266:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201268:	14058a63          	beqz	a1,ffffffffc02013bc <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020126c:	00359713          	sll	a4,a1,0x3
ffffffffc0201270:	972e                	add	a4,a4,a1
ffffffffc0201272:	070e                	sll	a4,a4,0x3
ffffffffc0201274:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201278:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc020127a:	c30d                	beqz	a4,ffffffffc020129c <default_free_pages+0x38>
ffffffffc020127c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020127e:	8b05                	and	a4,a4,1
ffffffffc0201280:	10071e63          	bnez	a4,ffffffffc020139c <default_free_pages+0x138>
ffffffffc0201284:	6798                	ld	a4,8(a5)
ffffffffc0201286:	8b09                	and	a4,a4,2
ffffffffc0201288:	10071a63          	bnez	a4,ffffffffc020139c <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020128c:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201290:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201294:	04878793          	add	a5,a5,72
ffffffffc0201298:	fed792e3          	bne	a5,a3,ffffffffc020127c <default_free_pages+0x18>
    base->property = n;
ffffffffc020129c:	2581                	sext.w	a1,a1
ffffffffc020129e:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc02012a0:	00850893          	add	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02012a4:	4789                	li	a5,2
ffffffffc02012a6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02012aa:	00010697          	auipc	a3,0x10
ffffffffc02012ae:	d9668693          	add	a3,a3,-618 # ffffffffc0211040 <free_area>
ffffffffc02012b2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02012b4:	669c                	ld	a5,8(a3)
ffffffffc02012b6:	9f2d                	addw	a4,a4,a1
ffffffffc02012b8:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02012ba:	0ad78563          	beq	a5,a3,ffffffffc0201364 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc02012be:	fe078713          	add	a4,a5,-32
ffffffffc02012c2:	4581                	li	a1,0
ffffffffc02012c4:	02050613          	add	a2,a0,32
            if (base < page) {
ffffffffc02012c8:	00e56a63          	bltu	a0,a4,ffffffffc02012dc <default_free_pages+0x78>
    return listelm->next;
ffffffffc02012cc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02012ce:	06d70263          	beq	a4,a3,ffffffffc0201332 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc02012d2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02012d4:	fe078713          	add	a4,a5,-32
            if (base < page) {
ffffffffc02012d8:	fee57ae3          	bgeu	a0,a4,ffffffffc02012cc <default_free_pages+0x68>
ffffffffc02012dc:	c199                	beqz	a1,ffffffffc02012e2 <default_free_pages+0x7e>
ffffffffc02012de:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02012e2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02012e4:	e390                	sd	a2,0(a5)
ffffffffc02012e6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02012e8:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02012ea:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc02012ec:	02d70063          	beq	a4,a3,ffffffffc020130c <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc02012f0:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02012f4:	fe070593          	add	a1,a4,-32
        if (p + p->property == base) {
ffffffffc02012f8:	02081613          	sll	a2,a6,0x20
ffffffffc02012fc:	9201                	srl	a2,a2,0x20
ffffffffc02012fe:	00361793          	sll	a5,a2,0x3
ffffffffc0201302:	97b2                	add	a5,a5,a2
ffffffffc0201304:	078e                	sll	a5,a5,0x3
ffffffffc0201306:	97ae                	add	a5,a5,a1
ffffffffc0201308:	02f50f63          	beq	a0,a5,ffffffffc0201346 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc020130c:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc020130e:	00d70f63          	beq	a4,a3,ffffffffc020132c <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc0201312:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc0201314:	fe070693          	add	a3,a4,-32
        if (base + base->property == p) {
ffffffffc0201318:	02059613          	sll	a2,a1,0x20
ffffffffc020131c:	9201                	srl	a2,a2,0x20
ffffffffc020131e:	00361793          	sll	a5,a2,0x3
ffffffffc0201322:	97b2                	add	a5,a5,a2
ffffffffc0201324:	078e                	sll	a5,a5,0x3
ffffffffc0201326:	97aa                	add	a5,a5,a0
ffffffffc0201328:	04f68a63          	beq	a3,a5,ffffffffc020137c <default_free_pages+0x118>
}
ffffffffc020132c:	60a2                	ld	ra,8(sp)
ffffffffc020132e:	0141                	add	sp,sp,16
ffffffffc0201330:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201332:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201334:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201336:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201338:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020133a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020133c:	02d70d63          	beq	a4,a3,ffffffffc0201376 <default_free_pages+0x112>
ffffffffc0201340:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201342:	87ba                	mv	a5,a4
ffffffffc0201344:	bf41                	j	ffffffffc02012d4 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201346:	4d1c                	lw	a5,24(a0)
ffffffffc0201348:	010787bb          	addw	a5,a5,a6
ffffffffc020134c:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201350:	57f5                	li	a5,-3
ffffffffc0201352:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201356:	7110                	ld	a2,32(a0)
ffffffffc0201358:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc020135a:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020135c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020135e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201360:	e390                	sd	a2,0(a5)
ffffffffc0201362:	b775                	j	ffffffffc020130e <default_free_pages+0xaa>
}
ffffffffc0201364:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201366:	02050713          	add	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc020136a:	e398                	sd	a4,0(a5)
ffffffffc020136c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020136e:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201370:	f11c                	sd	a5,32(a0)
}
ffffffffc0201372:	0141                	add	sp,sp,16
ffffffffc0201374:	8082                	ret
ffffffffc0201376:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201378:	873e                	mv	a4,a5
ffffffffc020137a:	bf8d                	j	ffffffffc02012ec <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020137c:	ff872783          	lw	a5,-8(a4)
ffffffffc0201380:	fe870693          	add	a3,a4,-24
ffffffffc0201384:	9fad                	addw	a5,a5,a1
ffffffffc0201386:	cd1c                	sw	a5,24(a0)
ffffffffc0201388:	57f5                	li	a5,-3
ffffffffc020138a:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020138e:	6314                	ld	a3,0(a4)
ffffffffc0201390:	671c                	ld	a5,8(a4)
}
ffffffffc0201392:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201394:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201396:	e394                	sd	a3,0(a5)
ffffffffc0201398:	0141                	add	sp,sp,16
ffffffffc020139a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020139c:	00004697          	auipc	a3,0x4
ffffffffc02013a0:	d8c68693          	add	a3,a3,-628 # ffffffffc0205128 <etext+0xc3e>
ffffffffc02013a4:	00004617          	auipc	a2,0x4
ffffffffc02013a8:	a2460613          	add	a2,a2,-1500 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02013ac:	08300593          	li	a1,131
ffffffffc02013b0:	00004517          	auipc	a0,0x4
ffffffffc02013b4:	a3050513          	add	a0,a0,-1488 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02013b8:	fa9fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc02013bc:	00004697          	auipc	a3,0x4
ffffffffc02013c0:	d6468693          	add	a3,a3,-668 # ffffffffc0205120 <etext+0xc36>
ffffffffc02013c4:	00004617          	auipc	a2,0x4
ffffffffc02013c8:	a0460613          	add	a2,a2,-1532 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02013cc:	08000593          	li	a1,128
ffffffffc02013d0:	00004517          	auipc	a0,0x4
ffffffffc02013d4:	a1050513          	add	a0,a0,-1520 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc02013d8:	f89fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02013dc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02013dc:	c959                	beqz	a0,ffffffffc0201472 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02013de:	00010617          	auipc	a2,0x10
ffffffffc02013e2:	c6260613          	add	a2,a2,-926 # ffffffffc0211040 <free_area>
ffffffffc02013e6:	4a0c                	lw	a1,16(a2)
ffffffffc02013e8:	86aa                	mv	a3,a0
ffffffffc02013ea:	02059793          	sll	a5,a1,0x20
ffffffffc02013ee:	9381                	srl	a5,a5,0x20
ffffffffc02013f0:	00a7eb63          	bltu	a5,a0,ffffffffc0201406 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc02013f4:	87b2                	mv	a5,a2
ffffffffc02013f6:	a029                	j	ffffffffc0201400 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc02013f8:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02013fc:	00d77763          	bgeu	a4,a3,ffffffffc020140a <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc0201400:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201402:	fec79be3          	bne	a5,a2,ffffffffc02013f8 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc0201406:	4501                	li	a0,0
}
ffffffffc0201408:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020140a:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc020140c:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc0201410:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201414:	fe078513          	add	a0,a5,-32
    prev->next = next;
ffffffffc0201418:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020141c:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc0201420:	02089713          	sll	a4,a7,0x20
ffffffffc0201424:	9301                	srl	a4,a4,0x20
            p->property = page->property - n;
ffffffffc0201426:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc020142a:	02e6fc63          	bgeu	a3,a4,ffffffffc0201462 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020142e:	00369713          	sll	a4,a3,0x3
ffffffffc0201432:	9736                	add	a4,a4,a3
ffffffffc0201434:	070e                	sll	a4,a4,0x3
ffffffffc0201436:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201438:	406888bb          	subw	a7,a7,t1
ffffffffc020143c:	01172c23          	sw	a7,24(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201440:	4689                	li	a3,2
ffffffffc0201442:	00870593          	add	a1,a4,8
ffffffffc0201446:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020144a:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020144e:	02070893          	add	a7,a4,32
        nr_free -= n;
ffffffffc0201452:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201454:	0116b023          	sd	a7,0(a3)
ffffffffc0201458:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020145c:	f714                	sd	a3,40(a4)
    elm->prev = prev;
ffffffffc020145e:	03073023          	sd	a6,32(a4)
ffffffffc0201462:	406585bb          	subw	a1,a1,t1
ffffffffc0201466:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201468:	5775                	li	a4,-3
ffffffffc020146a:	17a1                	add	a5,a5,-24
ffffffffc020146c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201470:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201472:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc0201474:	00004697          	auipc	a3,0x4
ffffffffc0201478:	cac68693          	add	a3,a3,-852 # ffffffffc0205120 <etext+0xc36>
ffffffffc020147c:	00004617          	auipc	a2,0x4
ffffffffc0201480:	94c60613          	add	a2,a2,-1716 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0201484:	06200593          	li	a1,98
ffffffffc0201488:	00004517          	auipc	a0,0x4
ffffffffc020148c:	95850513          	add	a0,a0,-1704 # ffffffffc0204de0 <etext+0x8f6>
default_alloc_pages(size_t n) {
ffffffffc0201490:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201492:	ecffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0201496 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201496:	1141                	add	sp,sp,-16
ffffffffc0201498:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020149a:	c9e1                	beqz	a1,ffffffffc020156a <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020149c:	00359713          	sll	a4,a1,0x3
ffffffffc02014a0:	972e                	add	a4,a4,a1
ffffffffc02014a2:	070e                	sll	a4,a4,0x3
ffffffffc02014a4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02014a8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02014aa:	cf11                	beqz	a4,ffffffffc02014c6 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02014ac:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02014ae:	8b05                	and	a4,a4,1
ffffffffc02014b0:	cf49                	beqz	a4,ffffffffc020154a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02014b2:	0007ac23          	sw	zero,24(a5)
ffffffffc02014b6:	0007b423          	sd	zero,8(a5)
ffffffffc02014ba:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014be:	04878793          	add	a5,a5,72
ffffffffc02014c2:	fed795e3          	bne	a5,a3,ffffffffc02014ac <default_init_memmap+0x16>
    base->property = n;
ffffffffc02014c6:	2581                	sext.w	a1,a1
ffffffffc02014c8:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014ca:	4789                	li	a5,2
ffffffffc02014cc:	00850713          	add	a4,a0,8
ffffffffc02014d0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02014d4:	00010697          	auipc	a3,0x10
ffffffffc02014d8:	b6c68693          	add	a3,a3,-1172 # ffffffffc0211040 <free_area>
ffffffffc02014dc:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014de:	669c                	ld	a5,8(a3)
ffffffffc02014e0:	9f2d                	addw	a4,a4,a1
ffffffffc02014e2:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014e4:	04d78663          	beq	a5,a3,ffffffffc0201530 <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014e8:	fe078713          	add	a4,a5,-32
ffffffffc02014ec:	4581                	li	a1,0
ffffffffc02014ee:	02050613          	add	a2,a0,32
            if (base < page) {
ffffffffc02014f2:	00e56a63          	bltu	a0,a4,ffffffffc0201506 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02014f6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014f8:	02d70263          	beq	a4,a3,ffffffffc020151c <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02014fc:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014fe:	fe078713          	add	a4,a5,-32
            if (base < page) {
ffffffffc0201502:	fee57ae3          	bgeu	a0,a4,ffffffffc02014f6 <default_init_memmap+0x60>
ffffffffc0201506:	c199                	beqz	a1,ffffffffc020150c <default_init_memmap+0x76>
ffffffffc0201508:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020150c:	6398                	ld	a4,0(a5)
}
ffffffffc020150e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201510:	e390                	sd	a2,0(a5)
ffffffffc0201512:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201514:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0201516:	f118                	sd	a4,32(a0)
ffffffffc0201518:	0141                	add	sp,sp,16
ffffffffc020151a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020151c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020151e:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0201520:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201522:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc0201524:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201526:	00d70e63          	beq	a4,a3,ffffffffc0201542 <default_init_memmap+0xac>
ffffffffc020152a:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020152c:	87ba                	mv	a5,a4
ffffffffc020152e:	bfc1                	j	ffffffffc02014fe <default_init_memmap+0x68>
}
ffffffffc0201530:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201532:	02050713          	add	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc0201536:	e398                	sd	a4,0(a5)
ffffffffc0201538:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020153a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020153c:	f11c                	sd	a5,32(a0)
}
ffffffffc020153e:	0141                	add	sp,sp,16
ffffffffc0201540:	8082                	ret
ffffffffc0201542:	60a2                	ld	ra,8(sp)
ffffffffc0201544:	e290                	sd	a2,0(a3)
ffffffffc0201546:	0141                	add	sp,sp,16
ffffffffc0201548:	8082                	ret
        assert(PageReserved(p));
ffffffffc020154a:	00004697          	auipc	a3,0x4
ffffffffc020154e:	c0668693          	add	a3,a3,-1018 # ffffffffc0205150 <etext+0xc66>
ffffffffc0201552:	00004617          	auipc	a2,0x4
ffffffffc0201556:	87660613          	add	a2,a2,-1930 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020155a:	04900593          	li	a1,73
ffffffffc020155e:	00004517          	auipc	a0,0x4
ffffffffc0201562:	88250513          	add	a0,a0,-1918 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201566:	dfbfe0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0);
ffffffffc020156a:	00004697          	auipc	a3,0x4
ffffffffc020156e:	bb668693          	add	a3,a3,-1098 # ffffffffc0205120 <etext+0xc36>
ffffffffc0201572:	00004617          	auipc	a2,0x4
ffffffffc0201576:	85660613          	add	a2,a2,-1962 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020157a:	04600593          	li	a1,70
ffffffffc020157e:	00004517          	auipc	a0,0x4
ffffffffc0201582:	86250513          	add	a0,a0,-1950 # ffffffffc0204de0 <etext+0x8f6>
ffffffffc0201586:	ddbfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020158a <pa2page.part.0>:
    va_pa_offset = KERNBASE - 0x80200000;
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END; //硬编码取代 sbi_query_memory()接口
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
    cprintf("physcial memory map:\n");
ffffffffc020158a:	1141                	add	sp,sp,-16
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);
ffffffffc020158c:	00004617          	auipc	a2,0x4
ffffffffc0201590:	bec60613          	add	a2,a2,-1044 # ffffffffc0205178 <etext+0xc8e>
ffffffffc0201594:	06500593          	li	a1,101
ffffffffc0201598:	00004517          	auipc	a0,0x4
ffffffffc020159c:	c0050513          	add	a0,a0,-1024 # ffffffffc0205198 <etext+0xcae>
    cprintf("physcial memory map:\n");
ffffffffc02015a0:	e406                	sd	ra,8(sp)
            mem_end - 1);
ffffffffc02015a2:	dbffe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02015a6 <pte2page.part.0>:
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
ffffffffc02015a6:	1141                	add	sp,sp,-16
    // BBL has put the initial page table at the first available page after the
    // kernel
ffffffffc02015a8:	00004617          	auipc	a2,0x4
ffffffffc02015ac:	c0060613          	add	a2,a2,-1024 # ffffffffc02051a8 <etext+0xcbe>
ffffffffc02015b0:	07000593          	li	a1,112
ffffffffc02015b4:	00004517          	auipc	a0,0x4
ffffffffc02015b8:	be450513          	add	a0,a0,-1052 # ffffffffc0205198 <etext+0xcae>
    npage = maxpa / PGSIZE;
ffffffffc02015bc:	e406                	sd	ra,8(sp)
    // kernel
ffffffffc02015be:	da3fe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02015c2 <alloc_pages>:
struct Page *alloc_pages(size_t n) {
ffffffffc02015c2:	7139                	add	sp,sp,-64
ffffffffc02015c4:	f426                	sd	s1,40(sp)
ffffffffc02015c6:	f04a                	sd	s2,32(sp)
ffffffffc02015c8:	ec4e                	sd	s3,24(sp)
ffffffffc02015ca:	e852                	sd	s4,16(sp)
ffffffffc02015cc:	e456                	sd	s5,8(sp)
ffffffffc02015ce:	e05a                	sd	s6,0(sp)
ffffffffc02015d0:	fc06                	sd	ra,56(sp)
ffffffffc02015d2:	f822                	sd	s0,48(sp)
ffffffffc02015d4:	84aa                	mv	s1,a0
ffffffffc02015d6:	00010917          	auipc	s2,0x10
ffffffffc02015da:	f3a90913          	add	s2,s2,-198 # ffffffffc0211510 <pmm_manager>
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02015de:	4a05                	li	s4,1
ffffffffc02015e0:	00010a97          	auipc	s5,0x10
ffffffffc02015e4:	f60a8a93          	add	s5,s5,-160 # ffffffffc0211540 <swap_init_ok>
        swap_out(check_mm_struct, n, 0);
ffffffffc02015e8:	0005099b          	sext.w	s3,a0
ffffffffc02015ec:	00010b17          	auipc	s6,0x10
ffffffffc02015f0:	f7cb0b13          	add	s6,s6,-132 # ffffffffc0211568 <check_mm_struct>
ffffffffc02015f4:	a015                	j	ffffffffc0201618 <alloc_pages+0x56>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc02015f6:	00093783          	ld	a5,0(s2)
ffffffffc02015fa:	6f9c                	ld	a5,24(a5)
ffffffffc02015fc:	9782                	jalr	a5
ffffffffc02015fe:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201600:	4601                	li	a2,0
ffffffffc0201602:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201604:	ec05                	bnez	s0,ffffffffc020163c <alloc_pages+0x7a>
ffffffffc0201606:	029a6b63          	bltu	s4,s1,ffffffffc020163c <alloc_pages+0x7a>
ffffffffc020160a:	000aa783          	lw	a5,0(s5)
ffffffffc020160e:	c79d                	beqz	a5,ffffffffc020163c <alloc_pages+0x7a>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201610:	000b3503          	ld	a0,0(s6)
ffffffffc0201614:	233010ef          	jal	ffffffffc0203046 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201618:	100027f3          	csrr	a5,sstatus
ffffffffc020161c:	8b89                	and	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc020161e:	8526                	mv	a0,s1
ffffffffc0201620:	dbf9                	beqz	a5,ffffffffc02015f6 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201622:	ebbfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0201626:	00093783          	ld	a5,0(s2)
ffffffffc020162a:	8526                	mv	a0,s1
ffffffffc020162c:	6f9c                	ld	a5,24(a5)
ffffffffc020162e:	9782                	jalr	a5
ffffffffc0201630:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201632:	ea5fe0ef          	jal	ffffffffc02004d6 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201636:	4601                	li	a2,0
ffffffffc0201638:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020163a:	d471                	beqz	s0,ffffffffc0201606 <alloc_pages+0x44>
}
ffffffffc020163c:	70e2                	ld	ra,56(sp)
ffffffffc020163e:	8522                	mv	a0,s0
ffffffffc0201640:	7442                	ld	s0,48(sp)
ffffffffc0201642:	74a2                	ld	s1,40(sp)
ffffffffc0201644:	7902                	ld	s2,32(sp)
ffffffffc0201646:	69e2                	ld	s3,24(sp)
ffffffffc0201648:	6a42                	ld	s4,16(sp)
ffffffffc020164a:	6aa2                	ld	s5,8(sp)
ffffffffc020164c:	6b02                	ld	s6,0(sp)
ffffffffc020164e:	6121                	add	sp,sp,64
ffffffffc0201650:	8082                	ret

ffffffffc0201652 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201652:	100027f3          	csrr	a5,sstatus
ffffffffc0201656:	8b89                	and	a5,a5,2
ffffffffc0201658:	e799                	bnez	a5,ffffffffc0201666 <free_pages+0x14>
    { pmm_manager->free_pages(base, n); }
ffffffffc020165a:	00010797          	auipc	a5,0x10
ffffffffc020165e:	eb67b783          	ld	a5,-330(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201662:	739c                	ld	a5,32(a5)
ffffffffc0201664:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201666:	1101                	add	sp,sp,-32
ffffffffc0201668:	ec06                	sd	ra,24(sp)
ffffffffc020166a:	e822                	sd	s0,16(sp)
ffffffffc020166c:	e426                	sd	s1,8(sp)
ffffffffc020166e:	842a                	mv	s0,a0
ffffffffc0201670:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201672:	e6bfe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201676:	00010797          	auipc	a5,0x10
ffffffffc020167a:	e9a7b783          	ld	a5,-358(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc020167e:	739c                	ld	a5,32(a5)
ffffffffc0201680:	85a6                	mv	a1,s1
ffffffffc0201682:	8522                	mv	a0,s0
ffffffffc0201684:	9782                	jalr	a5
}
ffffffffc0201686:	6442                	ld	s0,16(sp)
ffffffffc0201688:	60e2                	ld	ra,24(sp)
ffffffffc020168a:	64a2                	ld	s1,8(sp)
ffffffffc020168c:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc020168e:	e49fe06f          	j	ffffffffc02004d6 <intr_enable>

ffffffffc0201692 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201692:	100027f3          	csrr	a5,sstatus
ffffffffc0201696:	8b89                	and	a5,a5,2
ffffffffc0201698:	e799                	bnez	a5,ffffffffc02016a6 <nr_free_pages+0x14>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020169a:	00010797          	auipc	a5,0x10
ffffffffc020169e:	e767b783          	ld	a5,-394(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02016a2:	779c                	ld	a5,40(a5)
ffffffffc02016a4:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02016a6:	1141                	add	sp,sp,-16
ffffffffc02016a8:	e406                	sd	ra,8(sp)
ffffffffc02016aa:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02016ac:	e31fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02016b0:	00010797          	auipc	a5,0x10
ffffffffc02016b4:	e607b783          	ld	a5,-416(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02016b8:	779c                	ld	a5,40(a5)
ffffffffc02016ba:	9782                	jalr	a5
ffffffffc02016bc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02016be:	e19fe0ef          	jal	ffffffffc02004d6 <intr_enable>
}
ffffffffc02016c2:	60a2                	ld	ra,8(sp)
ffffffffc02016c4:	8522                	mv	a0,s0
ffffffffc02016c6:	6402                	ld	s0,0(sp)
ffffffffc02016c8:	0141                	add	sp,sp,16
ffffffffc02016ca:	8082                	ret

ffffffffc02016cc <get_pte>:
     *   PTE_W           0x002                   // page table/directory entry
     * flags bit : Writeable
     *   PTE_U           0x004                   // page table/directory entry
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02016cc:	01e5d793          	srl	a5,a1,0x1e
ffffffffc02016d0:	1ff7f793          	and	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016d4:	715d                	add	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02016d6:	078e                	sll	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016d8:	f052                	sd	s4,32(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02016da:	00f50a33          	add	s4,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016de:	000a3683          	ld	a3,0(s4)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016e2:	f84a                	sd	s2,48(sp)
ffffffffc02016e4:	f44e                	sd	s3,40(sp)
ffffffffc02016e6:	ec56                	sd	s5,24(sp)
ffffffffc02016e8:	e486                	sd	ra,72(sp)
ffffffffc02016ea:	e0a2                	sd	s0,64(sp)
ffffffffc02016ec:	e85a                	sd	s6,16(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016ee:	0016f793          	and	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02016f2:	892e                	mv	s2,a1
ffffffffc02016f4:	8ab2                	mv	s5,a2
ffffffffc02016f6:	00010997          	auipc	s3,0x10
ffffffffc02016fa:	e3a98993          	add	s3,s3,-454 # ffffffffc0211530 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc02016fe:	efc1                	bnez	a5,ffffffffc0201796 <get_pte+0xca>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201700:	18060663          	beqz	a2,ffffffffc020188c <get_pte+0x1c0>
ffffffffc0201704:	4505                	li	a0,1
ffffffffc0201706:	ebdff0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc020170a:	842a                	mv	s0,a0
ffffffffc020170c:	18050063          	beqz	a0,ffffffffc020188c <get_pte+0x1c0>
ffffffffc0201710:	fc26                	sd	s1,56(sp)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201712:	f8e394b7          	lui	s1,0xf8e39
ffffffffc0201716:	e3948493          	add	s1,s1,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc020171a:	e45e                	sd	s7,8(sp)
ffffffffc020171c:	04b2                	sll	s1,s1,0xc
ffffffffc020171e:	00010b97          	auipc	s7,0x10
ffffffffc0201722:	e1ab8b93          	add	s7,s7,-486 # ffffffffc0211538 <pages>
ffffffffc0201726:	000bb503          	ld	a0,0(s7)
ffffffffc020172a:	e3948493          	add	s1,s1,-455
ffffffffc020172e:	04b2                	sll	s1,s1,0xc
ffffffffc0201730:	e3948493          	add	s1,s1,-455
ffffffffc0201734:	40a40533          	sub	a0,s0,a0
ffffffffc0201738:	04b2                	sll	s1,s1,0xc
ffffffffc020173a:	850d                	sra	a0,a0,0x3
ffffffffc020173c:	e3948493          	add	s1,s1,-455
ffffffffc0201740:	02950533          	mul	a0,a0,s1
ffffffffc0201744:	00080b37          	lui	s6,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201748:	00010997          	auipc	s3,0x10
ffffffffc020174c:	de898993          	add	s3,s3,-536 # ffffffffc0211530 <npage>
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201750:	4785                	li	a5,1
ffffffffc0201752:	0009b703          	ld	a4,0(s3)
ffffffffc0201756:	c01c                	sw	a5,0(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201758:	955a                	add	a0,a0,s6
ffffffffc020175a:	00c51793          	sll	a5,a0,0xc
ffffffffc020175e:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201760:	0532                	sll	a0,a0,0xc
ffffffffc0201762:	16e7ff63          	bgeu	a5,a4,ffffffffc02018e0 <get_pte+0x214>
ffffffffc0201766:	00010797          	auipc	a5,0x10
ffffffffc020176a:	dc27b783          	ld	a5,-574(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc020176e:	953e                	add	a0,a0,a5
ffffffffc0201770:	6605                	lui	a2,0x1
ffffffffc0201772:	4581                	li	a1,0
ffffffffc0201774:	54d020ef          	jal	ffffffffc02044c0 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201778:	000bb783          	ld	a5,0(s7)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020177c:	6ba2                	ld	s7,8(sp)
ffffffffc020177e:	40f406b3          	sub	a3,s0,a5
ffffffffc0201782:	868d                	sra	a3,a3,0x3
ffffffffc0201784:	029686b3          	mul	a3,a3,s1
ffffffffc0201788:	74e2                	ld	s1,56(sp)
ffffffffc020178a:	96da                	add	a3,a3,s6

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020178c:	06aa                	sll	a3,a3,0xa
ffffffffc020178e:	0116e693          	or	a3,a3,17
ffffffffc0201792:	00da3023          	sd	a3,0(s4)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201796:	77fd                	lui	a5,0xfffff
ffffffffc0201798:	068a                	sll	a3,a3,0x2
ffffffffc020179a:	0009b703          	ld	a4,0(s3)
ffffffffc020179e:	8efd                	and	a3,a3,a5
ffffffffc02017a0:	00c6d793          	srl	a5,a3,0xc
ffffffffc02017a4:	0ee7f663          	bgeu	a5,a4,ffffffffc0201890 <get_pte+0x1c4>
ffffffffc02017a8:	00010b17          	auipc	s6,0x10
ffffffffc02017ac:	d80b0b13          	add	s6,s6,-640 # ffffffffc0211528 <va_pa_offset>
ffffffffc02017b0:	000b3603          	ld	a2,0(s6)
ffffffffc02017b4:	01595793          	srl	a5,s2,0x15
ffffffffc02017b8:	1ff7f793          	and	a5,a5,511
ffffffffc02017bc:	96b2                	add	a3,a3,a2
ffffffffc02017be:	078e                	sll	a5,a5,0x3
ffffffffc02017c0:	00f68433          	add	s0,a3,a5
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc02017c4:	6014                	ld	a3,0(s0)
ffffffffc02017c6:	0016f793          	and	a5,a3,1
ffffffffc02017ca:	e7d1                	bnez	a5,ffffffffc0201856 <get_pte+0x18a>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc02017cc:	0c0a8063          	beqz	s5,ffffffffc020188c <get_pte+0x1c0>
ffffffffc02017d0:	4505                	li	a0,1
ffffffffc02017d2:	fc26                	sd	s1,56(sp)
ffffffffc02017d4:	defff0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc02017d8:	84aa                	mv	s1,a0
ffffffffc02017da:	c945                	beqz	a0,ffffffffc020188a <get_pte+0x1be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017dc:	f8e39a37          	lui	s4,0xf8e39
ffffffffc02017e0:	e39a0a13          	add	s4,s4,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc02017e4:	e45e                	sd	s7,8(sp)
ffffffffc02017e6:	0a32                	sll	s4,s4,0xc
ffffffffc02017e8:	00010b97          	auipc	s7,0x10
ffffffffc02017ec:	d50b8b93          	add	s7,s7,-688 # ffffffffc0211538 <pages>
ffffffffc02017f0:	000bb683          	ld	a3,0(s7)
ffffffffc02017f4:	e39a0a13          	add	s4,s4,-455
ffffffffc02017f8:	0a32                	sll	s4,s4,0xc
ffffffffc02017fa:	e39a0a13          	add	s4,s4,-455
ffffffffc02017fe:	40d506b3          	sub	a3,a0,a3
ffffffffc0201802:	0a32                	sll	s4,s4,0xc
ffffffffc0201804:	868d                	sra	a3,a3,0x3
ffffffffc0201806:	e39a0a13          	add	s4,s4,-455
ffffffffc020180a:	034686b3          	mul	a3,a3,s4
ffffffffc020180e:	00080ab7          	lui	s5,0x80
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201812:	4785                	li	a5,1
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201814:	0009b703          	ld	a4,0(s3)
ffffffffc0201818:	c11c                	sw	a5,0(a0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020181a:	96d6                	add	a3,a3,s5
ffffffffc020181c:	00c69793          	sll	a5,a3,0xc
ffffffffc0201820:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201822:	06b2                	sll	a3,a3,0xc
ffffffffc0201824:	0ae7f263          	bgeu	a5,a4,ffffffffc02018c8 <get_pte+0x1fc>
ffffffffc0201828:	000b3503          	ld	a0,0(s6)
ffffffffc020182c:	6605                	lui	a2,0x1
ffffffffc020182e:	4581                	li	a1,0
ffffffffc0201830:	9536                	add	a0,a0,a3
ffffffffc0201832:	48f020ef          	jal	ffffffffc02044c0 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201836:	000bb783          	ld	a5,0(s7)
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020183a:	6ba2                	ld	s7,8(sp)
ffffffffc020183c:	40f486b3          	sub	a3,s1,a5
ffffffffc0201840:	868d                	sra	a3,a3,0x3
ffffffffc0201842:	034686b3          	mul	a3,a3,s4
ffffffffc0201846:	74e2                	ld	s1,56(sp)
ffffffffc0201848:	96d6                	add	a3,a3,s5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020184a:	06aa                	sll	a3,a3,0xa
ffffffffc020184c:	0116e693          	or	a3,a3,17
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201850:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201852:	0009b703          	ld	a4,0(s3)
ffffffffc0201856:	77fd                	lui	a5,0xfffff
ffffffffc0201858:	068a                	sll	a3,a3,0x2
ffffffffc020185a:	8efd                	and	a3,a3,a5
ffffffffc020185c:	00c6d793          	srl	a5,a3,0xc
ffffffffc0201860:	04e7f663          	bgeu	a5,a4,ffffffffc02018ac <get_pte+0x1e0>
ffffffffc0201864:	000b3783          	ld	a5,0(s6)
ffffffffc0201868:	00c95913          	srl	s2,s2,0xc
ffffffffc020186c:	1ff97913          	and	s2,s2,511
ffffffffc0201870:	96be                	add	a3,a3,a5
ffffffffc0201872:	090e                	sll	s2,s2,0x3
ffffffffc0201874:	01268533          	add	a0,a3,s2
}
ffffffffc0201878:	60a6                	ld	ra,72(sp)
ffffffffc020187a:	6406                	ld	s0,64(sp)
ffffffffc020187c:	7942                	ld	s2,48(sp)
ffffffffc020187e:	79a2                	ld	s3,40(sp)
ffffffffc0201880:	7a02                	ld	s4,32(sp)
ffffffffc0201882:	6ae2                	ld	s5,24(sp)
ffffffffc0201884:	6b42                	ld	s6,16(sp)
ffffffffc0201886:	6161                	add	sp,sp,80
ffffffffc0201888:	8082                	ret
ffffffffc020188a:	74e2                	ld	s1,56(sp)
            return NULL;
ffffffffc020188c:	4501                	li	a0,0
ffffffffc020188e:	b7ed                	j	ffffffffc0201878 <get_pte+0x1ac>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201890:	00004617          	auipc	a2,0x4
ffffffffc0201894:	94060613          	add	a2,a2,-1728 # ffffffffc02051d0 <etext+0xce6>
ffffffffc0201898:	10200593          	li	a1,258
ffffffffc020189c:	00004517          	auipc	a0,0x4
ffffffffc02018a0:	95c50513          	add	a0,a0,-1700 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02018a4:	fc26                	sd	s1,56(sp)
ffffffffc02018a6:	e45e                	sd	s7,8(sp)
ffffffffc02018a8:	ab9fe0ef          	jal	ffffffffc0200360 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02018ac:	00004617          	auipc	a2,0x4
ffffffffc02018b0:	92460613          	add	a2,a2,-1756 # ffffffffc02051d0 <etext+0xce6>
ffffffffc02018b4:	10f00593          	li	a1,271
ffffffffc02018b8:	00004517          	auipc	a0,0x4
ffffffffc02018bc:	94050513          	add	a0,a0,-1728 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02018c0:	fc26                	sd	s1,56(sp)
ffffffffc02018c2:	e45e                	sd	s7,8(sp)
ffffffffc02018c4:	a9dfe0ef          	jal	ffffffffc0200360 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc02018c8:	00004617          	auipc	a2,0x4
ffffffffc02018cc:	90860613          	add	a2,a2,-1784 # ffffffffc02051d0 <etext+0xce6>
ffffffffc02018d0:	10b00593          	li	a1,267
ffffffffc02018d4:	00004517          	auipc	a0,0x4
ffffffffc02018d8:	92450513          	add	a0,a0,-1756 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02018dc:	a85fe0ef          	jal	ffffffffc0200360 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02018e0:	86aa                	mv	a3,a0
ffffffffc02018e2:	00004617          	auipc	a2,0x4
ffffffffc02018e6:	8ee60613          	add	a2,a2,-1810 # ffffffffc02051d0 <etext+0xce6>
ffffffffc02018ea:	0ff00593          	li	a1,255
ffffffffc02018ee:	00004517          	auipc	a0,0x4
ffffffffc02018f2:	90a50513          	add	a0,a0,-1782 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02018f6:	a6bfe0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02018fa <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02018fa:	1141                	add	sp,sp,-16
ffffffffc02018fc:	e022                	sd	s0,0(sp)
ffffffffc02018fe:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201900:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201902:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201904:	dc9ff0ef          	jal	ffffffffc02016cc <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201908:	c011                	beqz	s0,ffffffffc020190c <get_page+0x12>
        *ptep_store = ptep;
ffffffffc020190a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020190c:	c511                	beqz	a0,ffffffffc0201918 <get_page+0x1e>
ffffffffc020190e:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201910:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201912:	0017f713          	and	a4,a5,1
ffffffffc0201916:	e709                	bnez	a4,ffffffffc0201920 <get_page+0x26>
}
ffffffffc0201918:	60a2                	ld	ra,8(sp)
ffffffffc020191a:	6402                	ld	s0,0(sp)
ffffffffc020191c:	0141                	add	sp,sp,16
ffffffffc020191e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201920:	078a                	sll	a5,a5,0x2
ffffffffc0201922:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201924:	00010717          	auipc	a4,0x10
ffffffffc0201928:	c0c73703          	ld	a4,-1012(a4) # ffffffffc0211530 <npage>
ffffffffc020192c:	02e7f263          	bgeu	a5,a4,ffffffffc0201950 <get_page+0x56>
    return &pages[PPN(pa) - nbase];
ffffffffc0201930:	fff80737          	lui	a4,0xfff80
ffffffffc0201934:	97ba                	add	a5,a5,a4
ffffffffc0201936:	60a2                	ld	ra,8(sp)
ffffffffc0201938:	6402                	ld	s0,0(sp)
ffffffffc020193a:	00379713          	sll	a4,a5,0x3
ffffffffc020193e:	97ba                	add	a5,a5,a4
ffffffffc0201940:	00010517          	auipc	a0,0x10
ffffffffc0201944:	bf853503          	ld	a0,-1032(a0) # ffffffffc0211538 <pages>
ffffffffc0201948:	078e                	sll	a5,a5,0x3
ffffffffc020194a:	953e                	add	a0,a0,a5
ffffffffc020194c:	0141                	add	sp,sp,16
ffffffffc020194e:	8082                	ret
ffffffffc0201950:	c3bff0ef          	jal	ffffffffc020158a <pa2page.part.0>

ffffffffc0201954 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201954:	1101                	add	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201956:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201958:	ec06                	sd	ra,24(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020195a:	d73ff0ef          	jal	ffffffffc02016cc <get_pte>
    if (ptep != NULL) {
ffffffffc020195e:	c901                	beqz	a0,ffffffffc020196e <page_remove+0x1a>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201960:	611c                	ld	a5,0(a0)
ffffffffc0201962:	e822                	sd	s0,16(sp)
ffffffffc0201964:	842a                	mv	s0,a0
ffffffffc0201966:	0017f713          	and	a4,a5,1
ffffffffc020196a:	e709                	bnez	a4,ffffffffc0201974 <page_remove+0x20>
ffffffffc020196c:	6442                	ld	s0,16(sp)
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc020196e:	60e2                	ld	ra,24(sp)
ffffffffc0201970:	6105                	add	sp,sp,32
ffffffffc0201972:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201974:	078a                	sll	a5,a5,0x2
ffffffffc0201976:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201978:	00010717          	auipc	a4,0x10
ffffffffc020197c:	bb873703          	ld	a4,-1096(a4) # ffffffffc0211530 <npage>
ffffffffc0201980:	06e7f563          	bgeu	a5,a4,ffffffffc02019ea <page_remove+0x96>
    return &pages[PPN(pa) - nbase];
ffffffffc0201984:	fff80737          	lui	a4,0xfff80
ffffffffc0201988:	97ba                	add	a5,a5,a4
ffffffffc020198a:	00379713          	sll	a4,a5,0x3
ffffffffc020198e:	97ba                	add	a5,a5,a4
ffffffffc0201990:	078e                	sll	a5,a5,0x3
ffffffffc0201992:	00010517          	auipc	a0,0x10
ffffffffc0201996:	ba653503          	ld	a0,-1114(a0) # ffffffffc0211538 <pages>
ffffffffc020199a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020199c:	411c                	lw	a5,0(a0)
ffffffffc020199e:	fff7871b          	addw	a4,a5,-1 # ffffffffffffefff <end+0x3fdeda8f>
ffffffffc02019a2:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02019a4:	cb09                	beqz	a4,ffffffffc02019b6 <page_remove+0x62>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02019a6:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc02019aa:	12000073          	sfence.vma
ffffffffc02019ae:	6442                	ld	s0,16(sp)
}
ffffffffc02019b0:	60e2                	ld	ra,24(sp)
ffffffffc02019b2:	6105                	add	sp,sp,32
ffffffffc02019b4:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b6:	100027f3          	csrr	a5,sstatus
ffffffffc02019ba:	8b89                	and	a5,a5,2
ffffffffc02019bc:	eb89                	bnez	a5,ffffffffc02019ce <page_remove+0x7a>
    { pmm_manager->free_pages(base, n); }
ffffffffc02019be:	00010797          	auipc	a5,0x10
ffffffffc02019c2:	b527b783          	ld	a5,-1198(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02019c6:	739c                	ld	a5,32(a5)
ffffffffc02019c8:	4585                	li	a1,1
ffffffffc02019ca:	9782                	jalr	a5
    if (flag) {
ffffffffc02019cc:	bfe9                	j	ffffffffc02019a6 <page_remove+0x52>
        intr_disable();
ffffffffc02019ce:	e42a                	sd	a0,8(sp)
ffffffffc02019d0:	b0dfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02019d4:	00010797          	auipc	a5,0x10
ffffffffc02019d8:	b3c7b783          	ld	a5,-1220(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02019dc:	739c                	ld	a5,32(a5)
ffffffffc02019de:	6522                	ld	a0,8(sp)
ffffffffc02019e0:	4585                	li	a1,1
ffffffffc02019e2:	9782                	jalr	a5
        intr_enable();
ffffffffc02019e4:	af3fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02019e8:	bf7d                	j	ffffffffc02019a6 <page_remove+0x52>
ffffffffc02019ea:	ba1ff0ef          	jal	ffffffffc020158a <pa2page.part.0>

ffffffffc02019ee <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019ee:	7179                	add	sp,sp,-48
ffffffffc02019f0:	87b2                	mv	a5,a2
ffffffffc02019f2:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02019f4:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019f6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02019f8:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02019fa:	ec26                	sd	s1,24(sp)
ffffffffc02019fc:	f406                	sd	ra,40(sp)
ffffffffc02019fe:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a00:	ccdff0ef          	jal	ffffffffc02016cc <get_pte>
    if (ptep == NULL) {
ffffffffc0201a04:	c975                	beqz	a0,ffffffffc0201af8 <page_insert+0x10a>
    page->ref += 1;
ffffffffc0201a06:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc0201a08:	611c                	ld	a5,0(a0)
ffffffffc0201a0a:	e44e                	sd	s3,8(sp)
ffffffffc0201a0c:	0016871b          	addw	a4,a3,1
ffffffffc0201a10:	c018                	sw	a4,0(s0)
ffffffffc0201a12:	0017f713          	and	a4,a5,1
ffffffffc0201a16:	89aa                	mv	s3,a0
ffffffffc0201a18:	eb21                	bnez	a4,ffffffffc0201a68 <page_insert+0x7a>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a1a:	00010717          	auipc	a4,0x10
ffffffffc0201a1e:	b1e73703          	ld	a4,-1250(a4) # ffffffffc0211538 <pages>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a22:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0201a26:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0201a2a:	07b2                	sll	a5,a5,0xc
ffffffffc0201a2c:	e3978793          	add	a5,a5,-455
ffffffffc0201a30:	07b2                	sll	a5,a5,0xc
ffffffffc0201a32:	e3978793          	add	a5,a5,-455
ffffffffc0201a36:	8c19                	sub	s0,s0,a4
ffffffffc0201a38:	07b2                	sll	a5,a5,0xc
ffffffffc0201a3a:	840d                	sra	s0,s0,0x3
ffffffffc0201a3c:	e3978793          	add	a5,a5,-455
ffffffffc0201a40:	02f407b3          	mul	a5,s0,a5
ffffffffc0201a44:	00080737          	lui	a4,0x80
ffffffffc0201a48:	97ba                	add	a5,a5,a4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201a4a:	07aa                	sll	a5,a5,0xa
ffffffffc0201a4c:	8cdd                	or	s1,s1,a5
ffffffffc0201a4e:	0014e493          	or	s1,s1,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201a52:	0099b023          	sd	s1,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a56:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0201a5a:	69a2                	ld	s3,8(sp)
ffffffffc0201a5c:	4501                	li	a0,0
}
ffffffffc0201a5e:	70a2                	ld	ra,40(sp)
ffffffffc0201a60:	7402                	ld	s0,32(sp)
ffffffffc0201a62:	64e2                	ld	s1,24(sp)
ffffffffc0201a64:	6145                	add	sp,sp,48
ffffffffc0201a66:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201a68:	078a                	sll	a5,a5,0x2
ffffffffc0201a6a:	e84a                	sd	s2,16(sp)
ffffffffc0201a6c:	e052                	sd	s4,0(sp)
ffffffffc0201a6e:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a70:	00010717          	auipc	a4,0x10
ffffffffc0201a74:	ac073703          	ld	a4,-1344(a4) # ffffffffc0211530 <npage>
ffffffffc0201a78:	08e7f263          	bgeu	a5,a4,ffffffffc0201afc <page_insert+0x10e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a7c:	fff80737          	lui	a4,0xfff80
ffffffffc0201a80:	97ba                	add	a5,a5,a4
ffffffffc0201a82:	00010a17          	auipc	s4,0x10
ffffffffc0201a86:	ab6a0a13          	add	s4,s4,-1354 # ffffffffc0211538 <pages>
ffffffffc0201a8a:	000a3703          	ld	a4,0(s4)
ffffffffc0201a8e:	00379913          	sll	s2,a5,0x3
ffffffffc0201a92:	993e                	add	s2,s2,a5
ffffffffc0201a94:	090e                	sll	s2,s2,0x3
ffffffffc0201a96:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201a98:	03240263          	beq	s0,s2,ffffffffc0201abc <page_insert+0xce>
    page->ref -= 1;
ffffffffc0201a9c:	00092783          	lw	a5,0(s2)
ffffffffc0201aa0:	fff7871b          	addw	a4,a5,-1
ffffffffc0201aa4:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) ==
ffffffffc0201aa8:	cf11                	beqz	a4,ffffffffc0201ac4 <page_insert+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201aaa:	0009b023          	sd	zero,0(s3)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201aae:	12000073          	sfence.vma
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201ab2:	000a3703          	ld	a4,0(s4)
ffffffffc0201ab6:	6942                	ld	s2,16(sp)
ffffffffc0201ab8:	6a02                	ld	s4,0(sp)
}
ffffffffc0201aba:	b7a5                	j	ffffffffc0201a22 <page_insert+0x34>
    return page->ref;
ffffffffc0201abc:	6942                	ld	s2,16(sp)
ffffffffc0201abe:	6a02                	ld	s4,0(sp)
    page->ref -= 1;
ffffffffc0201ac0:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201ac2:	b785                	j	ffffffffc0201a22 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ac4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ac8:	8b89                	and	a5,a5,2
ffffffffc0201aca:	eb91                	bnez	a5,ffffffffc0201ade <page_insert+0xf0>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201acc:	00010797          	auipc	a5,0x10
ffffffffc0201ad0:	a447b783          	ld	a5,-1468(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201ad4:	739c                	ld	a5,32(a5)
ffffffffc0201ad6:	4585                	li	a1,1
ffffffffc0201ad8:	854a                	mv	a0,s2
ffffffffc0201ada:	9782                	jalr	a5
    if (flag) {
ffffffffc0201adc:	b7f9                	j	ffffffffc0201aaa <page_insert+0xbc>
        intr_disable();
ffffffffc0201ade:	9fffe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0201ae2:	00010797          	auipc	a5,0x10
ffffffffc0201ae6:	a2e7b783          	ld	a5,-1490(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0201aea:	739c                	ld	a5,32(a5)
ffffffffc0201aec:	4585                	li	a1,1
ffffffffc0201aee:	854a                	mv	a0,s2
ffffffffc0201af0:	9782                	jalr	a5
        intr_enable();
ffffffffc0201af2:	9e5fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0201af6:	bf55                	j	ffffffffc0201aaa <page_insert+0xbc>
        return -E_NO_MEM;
ffffffffc0201af8:	5571                	li	a0,-4
ffffffffc0201afa:	b795                	j	ffffffffc0201a5e <page_insert+0x70>
ffffffffc0201afc:	a8fff0ef          	jal	ffffffffc020158a <pa2page.part.0>

ffffffffc0201b00 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201b00:	00004797          	auipc	a5,0x4
ffffffffc0201b04:	63878793          	add	a5,a5,1592 # ffffffffc0206138 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b08:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201b0a:	7159                	add	sp,sp,-112
ffffffffc0201b0c:	f486                	sd	ra,104(sp)
ffffffffc0201b0e:	eca6                	sd	s1,88(sp)
ffffffffc0201b10:	e4ce                	sd	s3,72(sp)
ffffffffc0201b12:	f85a                	sd	s6,48(sp)
ffffffffc0201b14:	f45e                	sd	s7,40(sp)
ffffffffc0201b16:	f0a2                	sd	s0,96(sp)
ffffffffc0201b18:	e8ca                	sd	s2,80(sp)
ffffffffc0201b1a:	e0d2                	sd	s4,64(sp)
ffffffffc0201b1c:	fc56                	sd	s5,56(sp)
ffffffffc0201b1e:	f062                	sd	s8,32(sp)
ffffffffc0201b20:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b22:	00010b97          	auipc	s7,0x10
ffffffffc0201b26:	9eeb8b93          	add	s7,s7,-1554 # ffffffffc0211510 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b2a:	00003517          	auipc	a0,0x3
ffffffffc0201b2e:	6de50513          	add	a0,a0,1758 # ffffffffc0205208 <etext+0xd1e>
    pmm_manager = &default_pmm_manager;
ffffffffc0201b32:	00fbb023          	sd	a5,0(s7)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b36:	d84fe0ef          	jal	ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc0201b3a:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b3e:	00010997          	auipc	s3,0x10
ffffffffc0201b42:	9ea98993          	add	s3,s3,-1558 # ffffffffc0211528 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0201b46:	00010497          	auipc	s1,0x10
ffffffffc0201b4a:	9ea48493          	add	s1,s1,-1558 # ffffffffc0211530 <npage>
    pmm_manager->init();
ffffffffc0201b4e:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201b50:	00010b17          	auipc	s6,0x10
ffffffffc0201b54:	9e8b0b13          	add	s6,s6,-1560 # ffffffffc0211538 <pages>
    pmm_manager->init();
ffffffffc0201b58:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b5a:	57f5                	li	a5,-3
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b5c:	4645                	li	a2,17
ffffffffc0201b5e:	40100593          	li	a1,1025
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b62:	07fa                	sll	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b64:	07e006b7          	lui	a3,0x7e00
ffffffffc0201b68:	066e                	sll	a2,a2,0x1b
ffffffffc0201b6a:	05d6                	sll	a1,a1,0x15
ffffffffc0201b6c:	00003517          	auipc	a0,0x3
ffffffffc0201b70:	6b450513          	add	a0,a0,1716 # ffffffffc0205220 <etext+0xd36>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b74:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b78:	d42fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201b7c:	00003517          	auipc	a0,0x3
ffffffffc0201b80:	6d450513          	add	a0,a0,1748 # ffffffffc0205250 <etext+0xd66>
ffffffffc0201b84:	d36fe0ef          	jal	ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201b88:	46c5                	li	a3,17
ffffffffc0201b8a:	06ee                	sll	a3,a3,0x1b
ffffffffc0201b8c:	40100613          	li	a2,1025
ffffffffc0201b90:	16fd                	add	a3,a3,-1 # 7dfffff <kern_entry-0xffffffffb8400001>
ffffffffc0201b92:	0656                	sll	a2,a2,0x15
ffffffffc0201b94:	07e005b7          	lui	a1,0x7e00
ffffffffc0201b98:	00003517          	auipc	a0,0x3
ffffffffc0201b9c:	6d050513          	add	a0,a0,1744 # ffffffffc0205268 <etext+0xd7e>
ffffffffc0201ba0:	d1afe0ef          	jal	ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201ba4:	777d                	lui	a4,0xfffff
ffffffffc0201ba6:	00011797          	auipc	a5,0x11
ffffffffc0201baa:	9c978793          	add	a5,a5,-1591 # ffffffffc021256f <end+0xfff>
ffffffffc0201bae:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201bb0:	00088737          	lui	a4,0x88
ffffffffc0201bb4:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bb6:	00fb3023          	sd	a5,0(s6)
ffffffffc0201bba:	4705                	li	a4,1
ffffffffc0201bbc:	07a1                	add	a5,a5,8
ffffffffc0201bbe:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201bc2:	04800693          	li	a3,72
ffffffffc0201bc6:	4505                	li	a0,1
ffffffffc0201bc8:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201bcc:	000b3783          	ld	a5,0(s6)
ffffffffc0201bd0:	97b6                	add	a5,a5,a3
ffffffffc0201bd2:	07a1                	add	a5,a5,8
ffffffffc0201bd4:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201bd8:	609c                	ld	a5,0(s1)
ffffffffc0201bda:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201bdc:	04868693          	add	a3,a3,72
ffffffffc0201be0:	00b78633          	add	a2,a5,a1
ffffffffc0201be4:	fec764e3          	bltu	a4,a2,ffffffffc0201bcc <pmm_init+0xcc>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201be8:	000b3503          	ld	a0,0(s6)
ffffffffc0201bec:	00379693          	sll	a3,a5,0x3
ffffffffc0201bf0:	96be                	add	a3,a3,a5
ffffffffc0201bf2:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201bf6:	972a                	add	a4,a4,a0
ffffffffc0201bf8:	068e                	sll	a3,a3,0x3
ffffffffc0201bfa:	96ba                	add	a3,a3,a4
ffffffffc0201bfc:	c0200737          	lui	a4,0xc0200
ffffffffc0201c00:	68e6e563          	bltu	a3,a4,ffffffffc020228a <pmm_init+0x78a>
ffffffffc0201c04:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc0201c08:	4645                	li	a2,17
ffffffffc0201c0a:	066e                	sll	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c0c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201c0e:	50c6e363          	bltu	a3,a2,ffffffffc0202114 <pmm_init+0x614>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201c12:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c16:	00010917          	auipc	s2,0x10
ffffffffc0201c1a:	90a90913          	add	s2,s2,-1782 # ffffffffc0211520 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201c1e:	7b9c                	ld	a5,48(a5)
ffffffffc0201c20:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201c22:	00003517          	auipc	a0,0x3
ffffffffc0201c26:	69650513          	add	a0,a0,1686 # ffffffffc02052b8 <etext+0xdce>
ffffffffc0201c2a:	c90fe0ef          	jal	ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c2e:	00007697          	auipc	a3,0x7
ffffffffc0201c32:	3d268693          	add	a3,a3,978 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201c36:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201c3a:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c3e:	22f6eee3          	bltu	a3,a5,ffffffffc020267a <pmm_init+0xb7a>
ffffffffc0201c42:	0009b783          	ld	a5,0(s3)
ffffffffc0201c46:	8e9d                	sub	a3,a3,a5
ffffffffc0201c48:	00010797          	auipc	a5,0x10
ffffffffc0201c4c:	8cd7b823          	sd	a3,-1840(a5) # ffffffffc0211518 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c50:	100027f3          	csrr	a5,sstatus
ffffffffc0201c54:	8b89                	and	a5,a5,2
ffffffffc0201c56:	4e079863          	bnez	a5,ffffffffc0202146 <pmm_init+0x646>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201c5a:	000bb783          	ld	a5,0(s7)
ffffffffc0201c5e:	779c                	ld	a5,40(a5)
ffffffffc0201c60:	9782                	jalr	a5
ffffffffc0201c62:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c64:	6098                	ld	a4,0(s1)
ffffffffc0201c66:	c80007b7          	lui	a5,0xc8000
ffffffffc0201c6a:	83b1                	srl	a5,a5,0xc
ffffffffc0201c6c:	66e7eb63          	bltu	a5,a4,ffffffffc02022e2 <pmm_init+0x7e2>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c70:	00093503          	ld	a0,0(s2)
ffffffffc0201c74:	64050763          	beqz	a0,ffffffffc02022c2 <pmm_init+0x7c2>
ffffffffc0201c78:	03451793          	sll	a5,a0,0x34
ffffffffc0201c7c:	64079363          	bnez	a5,ffffffffc02022c2 <pmm_init+0x7c2>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201c80:	4601                	li	a2,0
ffffffffc0201c82:	4581                	li	a1,0
ffffffffc0201c84:	c77ff0ef          	jal	ffffffffc02018fa <get_page>
ffffffffc0201c88:	6a051f63          	bnez	a0,ffffffffc0202346 <pmm_init+0x846>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201c8c:	4505                	li	a0,1
ffffffffc0201c8e:	935ff0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0201c92:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201c94:	00093503          	ld	a0,0(s2)
ffffffffc0201c98:	4681                	li	a3,0
ffffffffc0201c9a:	4601                	li	a2,0
ffffffffc0201c9c:	85d2                	mv	a1,s4
ffffffffc0201c9e:	d51ff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0201ca2:	68051263          	bnez	a0,ffffffffc0202326 <pmm_init+0x826>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201ca6:	00093503          	ld	a0,0(s2)
ffffffffc0201caa:	4601                	li	a2,0
ffffffffc0201cac:	4581                	li	a1,0
ffffffffc0201cae:	a1fff0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0201cb2:	64050a63          	beqz	a0,ffffffffc0202306 <pmm_init+0x806>
    assert(pte2page(*ptep) == p1);
ffffffffc0201cb6:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201cb8:	0017f713          	and	a4,a5,1
ffffffffc0201cbc:	64070363          	beqz	a4,ffffffffc0202302 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201cc0:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201cc2:	078a                	sll	a5,a5,0x2
ffffffffc0201cc4:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201cc6:	5ac7f063          	bgeu	a5,a2,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cca:	fff80737          	lui	a4,0xfff80
ffffffffc0201cce:	97ba                	add	a5,a5,a4
ffffffffc0201cd0:	000b3683          	ld	a3,0(s6)
ffffffffc0201cd4:	00379713          	sll	a4,a5,0x3
ffffffffc0201cd8:	97ba                	add	a5,a5,a4
ffffffffc0201cda:	078e                	sll	a5,a5,0x3
ffffffffc0201cdc:	97b6                	add	a5,a5,a3
ffffffffc0201cde:	58fa1663          	bne	s4,a5,ffffffffc020226a <pmm_init+0x76a>
    assert(page_ref(p1) == 1);
ffffffffc0201ce2:	000a2703          	lw	a4,0(s4)
ffffffffc0201ce6:	4785                	li	a5,1
ffffffffc0201ce8:	1cf711e3          	bne	a4,a5,ffffffffc02026aa <pmm_init+0xbaa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201cec:	00093503          	ld	a0,0(s2)
ffffffffc0201cf0:	77fd                	lui	a5,0xfffff
ffffffffc0201cf2:	6114                	ld	a3,0(a0)
ffffffffc0201cf4:	068a                	sll	a3,a3,0x2
ffffffffc0201cf6:	8efd                	and	a3,a3,a5
ffffffffc0201cf8:	00c6d713          	srl	a4,a3,0xc
ffffffffc0201cfc:	18c77be3          	bgeu	a4,a2,ffffffffc0202692 <pmm_init+0xb92>
ffffffffc0201d00:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d04:	96e2                	add	a3,a3,s8
ffffffffc0201d06:	0006ba83          	ld	s5,0(a3)
ffffffffc0201d0a:	0a8a                	sll	s5,s5,0x2
ffffffffc0201d0c:	00fafab3          	and	s5,s5,a5
ffffffffc0201d10:	00cad793          	srl	a5,s5,0xc
ffffffffc0201d14:	6ac7f963          	bgeu	a5,a2,ffffffffc02023c6 <pmm_init+0x8c6>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d18:	4601                	li	a2,0
ffffffffc0201d1a:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d1c:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d1e:	9afff0ef          	jal	ffffffffc02016cc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d22:	0c21                	add	s8,s8,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d24:	69851163          	bne	a0,s8,ffffffffc02023a6 <pmm_init+0x8a6>

    p2 = alloc_page();
ffffffffc0201d28:	4505                	li	a0,1
ffffffffc0201d2a:	899ff0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0201d2e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d30:	00093503          	ld	a0,0(s2)
ffffffffc0201d34:	46d1                	li	a3,20
ffffffffc0201d36:	6605                	lui	a2,0x1
ffffffffc0201d38:	85d6                	mv	a1,s5
ffffffffc0201d3a:	cb5ff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0201d3e:	64051463          	bnez	a0,ffffffffc0202386 <pmm_init+0x886>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d42:	00093503          	ld	a0,0(s2)
ffffffffc0201d46:	4601                	li	a2,0
ffffffffc0201d48:	6585                	lui	a1,0x1
ffffffffc0201d4a:	983ff0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0201d4e:	60050c63          	beqz	a0,ffffffffc0202366 <pmm_init+0x866>
    assert(*ptep & PTE_U);
ffffffffc0201d52:	611c                	ld	a5,0(a0)
ffffffffc0201d54:	0107f713          	and	a4,a5,16
ffffffffc0201d58:	76070463          	beqz	a4,ffffffffc02024c0 <pmm_init+0x9c0>
    assert(*ptep & PTE_W);
ffffffffc0201d5c:	8b91                	and	a5,a5,4
ffffffffc0201d5e:	74078163          	beqz	a5,ffffffffc02024a0 <pmm_init+0x9a0>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d62:	00093503          	ld	a0,0(s2)
ffffffffc0201d66:	611c                	ld	a5,0(a0)
ffffffffc0201d68:	8bc1                	and	a5,a5,16
ffffffffc0201d6a:	70078b63          	beqz	a5,ffffffffc0202480 <pmm_init+0x980>
    assert(page_ref(p2) == 1);
ffffffffc0201d6e:	000aa703          	lw	a4,0(s5) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0201d72:	4785                	li	a5,1
ffffffffc0201d74:	6ef71663          	bne	a4,a5,ffffffffc0202460 <pmm_init+0x960>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201d78:	4681                	li	a3,0
ffffffffc0201d7a:	6605                	lui	a2,0x1
ffffffffc0201d7c:	85d2                	mv	a1,s4
ffffffffc0201d7e:	c71ff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0201d82:	6a051f63          	bnez	a0,ffffffffc0202440 <pmm_init+0x940>
    assert(page_ref(p1) == 2);
ffffffffc0201d86:	000a2703          	lw	a4,0(s4)
ffffffffc0201d8a:	4789                	li	a5,2
ffffffffc0201d8c:	68f71a63          	bne	a4,a5,ffffffffc0202420 <pmm_init+0x920>
    assert(page_ref(p2) == 0);
ffffffffc0201d90:	000aa783          	lw	a5,0(s5)
ffffffffc0201d94:	66079663          	bnez	a5,ffffffffc0202400 <pmm_init+0x900>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d98:	00093503          	ld	a0,0(s2)
ffffffffc0201d9c:	4601                	li	a2,0
ffffffffc0201d9e:	6585                	lui	a1,0x1
ffffffffc0201da0:	92dff0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0201da4:	62050e63          	beqz	a0,ffffffffc02023e0 <pmm_init+0x8e0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201da8:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201daa:	00177793          	and	a5,a4,1
ffffffffc0201dae:	54078a63          	beqz	a5,ffffffffc0202302 <pmm_init+0x802>
    if (PPN(pa) >= npage) {
ffffffffc0201db2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201db4:	00271793          	sll	a5,a4,0x2
ffffffffc0201db8:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201dba:	4ad7f663          	bgeu	a5,a3,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dbe:	fff806b7          	lui	a3,0xfff80
ffffffffc0201dc2:	97b6                	add	a5,a5,a3
ffffffffc0201dc4:	000b3603          	ld	a2,0(s6)
ffffffffc0201dc8:	00379693          	sll	a3,a5,0x3
ffffffffc0201dcc:	97b6                	add	a5,a5,a3
ffffffffc0201dce:	078e                	sll	a5,a5,0x3
ffffffffc0201dd0:	97b2                	add	a5,a5,a2
ffffffffc0201dd2:	76fa1763          	bne	s4,a5,ffffffffc0202540 <pmm_init+0xa40>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201dd6:	8b41                	and	a4,a4,16
ffffffffc0201dd8:	74071463          	bnez	a4,ffffffffc0202520 <pmm_init+0xa20>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201ddc:	00093503          	ld	a0,0(s2)
ffffffffc0201de0:	4581                	li	a1,0
ffffffffc0201de2:	b73ff0ef          	jal	ffffffffc0201954 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201de6:	000a2703          	lw	a4,0(s4)
ffffffffc0201dea:	4785                	li	a5,1
ffffffffc0201dec:	70f71a63          	bne	a4,a5,ffffffffc0202500 <pmm_init+0xa00>
    assert(page_ref(p2) == 0);
ffffffffc0201df0:	000aa783          	lw	a5,0(s5)
ffffffffc0201df4:	6e079663          	bnez	a5,ffffffffc02024e0 <pmm_init+0x9e0>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201df8:	00093503          	ld	a0,0(s2)
ffffffffc0201dfc:	6585                	lui	a1,0x1
ffffffffc0201dfe:	b57ff0ef          	jal	ffffffffc0201954 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201e02:	000a2783          	lw	a5,0(s4)
ffffffffc0201e06:	7a079a63          	bnez	a5,ffffffffc02025ba <pmm_init+0xaba>
    assert(page_ref(p2) == 0);
ffffffffc0201e0a:	000aa783          	lw	a5,0(s5)
ffffffffc0201e0e:	78079663          	bnez	a5,ffffffffc020259a <pmm_init+0xa9a>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e12:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0201e16:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e18:	000a3783          	ld	a5,0(s4)
ffffffffc0201e1c:	078a                	sll	a5,a5,0x2
ffffffffc0201e1e:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e20:	44c7f363          	bgeu	a5,a2,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e24:	fff80737          	lui	a4,0xfff80
ffffffffc0201e28:	97ba                	add	a5,a5,a4
ffffffffc0201e2a:	00379713          	sll	a4,a5,0x3
ffffffffc0201e2e:	000b3503          	ld	a0,0(s6)
ffffffffc0201e32:	973e                	add	a4,a4,a5
ffffffffc0201e34:	070e                	sll	a4,a4,0x3
static inline int page_ref(struct Page *page) { return page->ref; }
ffffffffc0201e36:	00e507b3          	add	a5,a0,a4
ffffffffc0201e3a:	4394                	lw	a3,0(a5)
ffffffffc0201e3c:	4785                	li	a5,1
ffffffffc0201e3e:	72f69e63          	bne	a3,a5,ffffffffc020257a <pmm_init+0xa7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e42:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0201e46:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0201e4a:	07b2                	sll	a5,a5,0xc
ffffffffc0201e4c:	e3978793          	add	a5,a5,-455
ffffffffc0201e50:	07b2                	sll	a5,a5,0xc
ffffffffc0201e52:	e3978793          	add	a5,a5,-455
ffffffffc0201e56:	07b2                	sll	a5,a5,0xc
ffffffffc0201e58:	870d                	sra	a4,a4,0x3
ffffffffc0201e5a:	e3978793          	add	a5,a5,-455
ffffffffc0201e5e:	02f707b3          	mul	a5,a4,a5
ffffffffc0201e62:	00080737          	lui	a4,0x80
ffffffffc0201e66:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e68:	00c79693          	sll	a3,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e6c:	6ec7fb63          	bgeu	a5,a2,ffffffffc0202562 <pmm_init+0xa62>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201e70:	0009b783          	ld	a5,0(s3)
ffffffffc0201e74:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e76:	639c                	ld	a5,0(a5)
ffffffffc0201e78:	078a                	sll	a5,a5,0x2
ffffffffc0201e7a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e7c:	3ec7f563          	bgeu	a5,a2,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e80:	8f99                	sub	a5,a5,a4
ffffffffc0201e82:	00379713          	sll	a4,a5,0x3
ffffffffc0201e86:	97ba                	add	a5,a5,a4
ffffffffc0201e88:	078e                	sll	a5,a5,0x3
ffffffffc0201e8a:	953e                	add	a0,a0,a5
ffffffffc0201e8c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e90:	8b89                	and	a5,a5,2
ffffffffc0201e92:	30079463          	bnez	a5,ffffffffc020219a <pmm_init+0x69a>
    { pmm_manager->free_pages(base, n); }
ffffffffc0201e96:	000bb783          	ld	a5,0(s7)
ffffffffc0201e9a:	4585                	li	a1,1
ffffffffc0201e9c:	739c                	ld	a5,32(a5)
ffffffffc0201e9e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ea0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0201ea4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201ea6:	078a                	sll	a5,a5,0x2
ffffffffc0201ea8:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201eaa:	3ae7fe63          	bgeu	a5,a4,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0201eae:	fff80737          	lui	a4,0xfff80
ffffffffc0201eb2:	97ba                	add	a5,a5,a4
ffffffffc0201eb4:	000b3503          	ld	a0,0(s6)
ffffffffc0201eb8:	00379713          	sll	a4,a5,0x3
ffffffffc0201ebc:	97ba                	add	a5,a5,a4
ffffffffc0201ebe:	078e                	sll	a5,a5,0x3
ffffffffc0201ec0:	953e                	add	a0,a0,a5
ffffffffc0201ec2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ec6:	8b89                	and	a5,a5,2
ffffffffc0201ec8:	2a079d63          	bnez	a5,ffffffffc0202182 <pmm_init+0x682>
ffffffffc0201ecc:	000bb783          	ld	a5,0(s7)
ffffffffc0201ed0:	4585                	li	a1,1
ffffffffc0201ed2:	739c                	ld	a5,32(a5)
ffffffffc0201ed4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0201ed6:	00093783          	ld	a5,0(s2)
ffffffffc0201eda:	0007b023          	sd	zero,0(a5)
ffffffffc0201ede:	100027f3          	csrr	a5,sstatus
ffffffffc0201ee2:	8b89                	and	a5,a5,2
ffffffffc0201ee4:	28079563          	bnez	a5,ffffffffc020216e <pmm_init+0x66e>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201ee8:	000bb783          	ld	a5,0(s7)
ffffffffc0201eec:	779c                	ld	a5,40(a5)
ffffffffc0201eee:	9782                	jalr	a5
ffffffffc0201ef0:	8a2a                	mv	s4,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc0201ef2:	77441463          	bne	s0,s4,ffffffffc020265a <pmm_init+0xb5a>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201ef6:	00003517          	auipc	a0,0x3
ffffffffc0201efa:	6aa50513          	add	a0,a0,1706 # ffffffffc02055a0 <etext+0x10b6>
ffffffffc0201efe:	9bcfe0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0201f02:	100027f3          	csrr	a5,sstatus
ffffffffc0201f06:	8b89                	and	a5,a5,2
ffffffffc0201f08:	24079963          	bnez	a5,ffffffffc020215a <pmm_init+0x65a>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201f0c:	000bb783          	ld	a5,0(s7)
ffffffffc0201f10:	779c                	ld	a5,40(a5)
ffffffffc0201f12:	9782                	jalr	a5
ffffffffc0201f14:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f16:	6098                	ld	a4,0(s1)
ffffffffc0201f18:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f1c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f1e:	00c71793          	sll	a5,a4,0xc
ffffffffc0201f22:	6a05                	lui	s4,0x1
ffffffffc0201f24:	02f47c63          	bgeu	s0,a5,ffffffffc0201f5c <pmm_init+0x45c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201f28:	00c45793          	srl	a5,s0,0xc
ffffffffc0201f2c:	00093503          	ld	a0,0(s2)
ffffffffc0201f30:	2ce7fe63          	bgeu	a5,a4,ffffffffc020220c <pmm_init+0x70c>
ffffffffc0201f34:	0009b583          	ld	a1,0(s3)
ffffffffc0201f38:	4601                	li	a2,0
ffffffffc0201f3a:	95a2                	add	a1,a1,s0
ffffffffc0201f3c:	f90ff0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0201f40:	30050363          	beqz	a0,ffffffffc0202246 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f44:	611c                	ld	a5,0(a0)
ffffffffc0201f46:	078a                	sll	a5,a5,0x2
ffffffffc0201f48:	0157f7b3          	and	a5,a5,s5
ffffffffc0201f4c:	2c879d63          	bne	a5,s0,ffffffffc0202226 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f50:	6098                	ld	a4,0(s1)
ffffffffc0201f52:	9452                	add	s0,s0,s4
ffffffffc0201f54:	00c71793          	sll	a5,a4,0xc
ffffffffc0201f58:	fcf468e3          	bltu	s0,a5,ffffffffc0201f28 <pmm_init+0x428>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201f5c:	00093783          	ld	a5,0(s2)
ffffffffc0201f60:	639c                	ld	a5,0(a5)
ffffffffc0201f62:	6c079c63          	bnez	a5,ffffffffc020263a <pmm_init+0xb3a>

    struct Page *p;
    p = alloc_page();
ffffffffc0201f66:	4505                	li	a0,1
ffffffffc0201f68:	e5aff0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0201f6c:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201f6e:	00093503          	ld	a0,0(s2)
ffffffffc0201f72:	4699                	li	a3,6
ffffffffc0201f74:	10000613          	li	a2,256
ffffffffc0201f78:	85d2                	mv	a1,s4
ffffffffc0201f7a:	a75ff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0201f7e:	68051e63          	bnez	a0,ffffffffc020261a <pmm_init+0xb1a>
    assert(page_ref(p) == 1);
ffffffffc0201f82:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201f86:	4785                	li	a5,1
ffffffffc0201f88:	66f71963          	bne	a4,a5,ffffffffc02025fa <pmm_init+0xafa>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201f8c:	00093503          	ld	a0,0(s2)
ffffffffc0201f90:	6605                	lui	a2,0x1
ffffffffc0201f92:	4699                	li	a3,6
ffffffffc0201f94:	10060613          	add	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201f98:	85d2                	mv	a1,s4
ffffffffc0201f9a:	a55ff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0201f9e:	62051e63          	bnez	a0,ffffffffc02025da <pmm_init+0xada>
    assert(page_ref(p) == 2);
ffffffffc0201fa2:	000a2703          	lw	a4,0(s4)
ffffffffc0201fa6:	4789                	li	a5,2
ffffffffc0201fa8:	76f71163          	bne	a4,a5,ffffffffc020270a <pmm_init+0xc0a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201fac:	00003597          	auipc	a1,0x3
ffffffffc0201fb0:	72c58593          	add	a1,a1,1836 # ffffffffc02056d8 <etext+0x11ee>
ffffffffc0201fb4:	10000513          	li	a0,256
ffffffffc0201fb8:	4a8020ef          	jal	ffffffffc0204460 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201fbc:	6585                	lui	a1,0x1
ffffffffc0201fbe:	10058593          	add	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0201fc2:	10000513          	li	a0,256
ffffffffc0201fc6:	4ac020ef          	jal	ffffffffc0204472 <strcmp>
ffffffffc0201fca:	72051063          	bnez	a0,ffffffffc02026ea <pmm_init+0xbea>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fce:	f8e39437          	lui	s0,0xf8e39
ffffffffc0201fd2:	e3940413          	add	s0,s0,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0201fd6:	0432                	sll	s0,s0,0xc
ffffffffc0201fd8:	000b3683          	ld	a3,0(s6)
ffffffffc0201fdc:	e3940413          	add	s0,s0,-455
ffffffffc0201fe0:	0432                	sll	s0,s0,0xc
ffffffffc0201fe2:	e3940413          	add	s0,s0,-455
ffffffffc0201fe6:	40da06b3          	sub	a3,s4,a3
ffffffffc0201fea:	0432                	sll	s0,s0,0xc
ffffffffc0201fec:	868d                	sra	a3,a3,0x3
ffffffffc0201fee:	e3940413          	add	s0,s0,-455
ffffffffc0201ff2:	028686b3          	mul	a3,a3,s0
ffffffffc0201ff6:	00080cb7          	lui	s9,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ffa:	6098                	ld	a4,0(s1)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201ffc:	96e6                	add	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ffe:	00c69793          	sll	a5,a3,0xc
ffffffffc0202002:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202004:	06b2                	sll	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202006:	54e7fe63          	bgeu	a5,a4,ffffffffc0202562 <pmm_init+0xa62>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020200a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020200e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202012:	97b6                	add	a5,a5,a3
ffffffffc0202014:	10078023          	sb	zero,256(a5)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202018:	412020ef          	jal	ffffffffc020442a <strlen>
ffffffffc020201c:	6a051763          	bnez	a0,ffffffffc02026ca <pmm_init+0xbca>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202020:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202024:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202026:	000ab783          	ld	a5,0(s5) # fffffffffffff000 <end+0x3fdeda90>
ffffffffc020202a:	078a                	sll	a5,a5,0x2
ffffffffc020202c:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020202e:	22c7fc63          	bgeu	a5,a2,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202032:	419787b3          	sub	a5,a5,s9
ffffffffc0202036:	00379713          	sll	a4,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020203a:	97ba                	add	a5,a5,a4
ffffffffc020203c:	028787b3          	mul	a5,a5,s0
ffffffffc0202040:	97e6                	add	a5,a5,s9
    return page2ppn(page) << PGSHIFT;
ffffffffc0202042:	00c79413          	sll	s0,a5,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202046:	50c7fd63          	bgeu	a5,a2,ffffffffc0202560 <pmm_init+0xa60>
ffffffffc020204a:	0009b783          	ld	a5,0(s3)
ffffffffc020204e:	943e                	add	s0,s0,a5
ffffffffc0202050:	100027f3          	csrr	a5,sstatus
ffffffffc0202054:	8b89                	and	a5,a5,2
ffffffffc0202056:	1a079063          	bnez	a5,ffffffffc02021f6 <pmm_init+0x6f6>
    { pmm_manager->free_pages(base, n); }
ffffffffc020205a:	000bb783          	ld	a5,0(s7)
ffffffffc020205e:	4585                	li	a1,1
ffffffffc0202060:	8552                	mv	a0,s4
ffffffffc0202062:	739c                	ld	a5,32(a5)
ffffffffc0202064:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202066:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202068:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020206a:	078a                	sll	a5,a5,0x2
ffffffffc020206c:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020206e:	1ee7fc63          	bgeu	a5,a4,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202072:	fff80737          	lui	a4,0xfff80
ffffffffc0202076:	97ba                	add	a5,a5,a4
ffffffffc0202078:	000b3503          	ld	a0,0(s6)
ffffffffc020207c:	00379713          	sll	a4,a5,0x3
ffffffffc0202080:	97ba                	add	a5,a5,a4
ffffffffc0202082:	078e                	sll	a5,a5,0x3
ffffffffc0202084:	953e                	add	a0,a0,a5
ffffffffc0202086:	100027f3          	csrr	a5,sstatus
ffffffffc020208a:	8b89                	and	a5,a5,2
ffffffffc020208c:	14079963          	bnez	a5,ffffffffc02021de <pmm_init+0x6de>
ffffffffc0202090:	000bb783          	ld	a5,0(s7)
ffffffffc0202094:	4585                	li	a1,1
ffffffffc0202096:	739c                	ld	a5,32(a5)
ffffffffc0202098:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020209a:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020209e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02020a0:	078a                	sll	a5,a5,0x2
ffffffffc02020a2:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020a4:	1ce7f163          	bgeu	a5,a4,ffffffffc0202266 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02020a8:	fff80737          	lui	a4,0xfff80
ffffffffc02020ac:	97ba                	add	a5,a5,a4
ffffffffc02020ae:	000b3503          	ld	a0,0(s6)
ffffffffc02020b2:	00379713          	sll	a4,a5,0x3
ffffffffc02020b6:	97ba                	add	a5,a5,a4
ffffffffc02020b8:	078e                	sll	a5,a5,0x3
ffffffffc02020ba:	953e                	add	a0,a0,a5
ffffffffc02020bc:	100027f3          	csrr	a5,sstatus
ffffffffc02020c0:	8b89                	and	a5,a5,2
ffffffffc02020c2:	10079263          	bnez	a5,ffffffffc02021c6 <pmm_init+0x6c6>
ffffffffc02020c6:	000bb783          	ld	a5,0(s7)
ffffffffc02020ca:	4585                	li	a1,1
ffffffffc02020cc:	739c                	ld	a5,32(a5)
ffffffffc02020ce:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02020d0:	00093783          	ld	a5,0(s2)
ffffffffc02020d4:	0007b023          	sd	zero,0(a5)
ffffffffc02020d8:	100027f3          	csrr	a5,sstatus
ffffffffc02020dc:	8b89                	and	a5,a5,2
ffffffffc02020de:	0c079a63          	bnez	a5,ffffffffc02021b2 <pmm_init+0x6b2>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02020e2:	000bb783          	ld	a5,0(s7)
ffffffffc02020e6:	779c                	ld	a5,40(a5)
ffffffffc02020e8:	9782                	jalr	a5
ffffffffc02020ea:	842a                	mv	s0,a0

    assert(nr_free_store==nr_free_pages());
ffffffffc02020ec:	1a8c1b63          	bne	s8,s0,ffffffffc02022a2 <pmm_init+0x7a2>
}
ffffffffc02020f0:	7406                	ld	s0,96(sp)
ffffffffc02020f2:	70a6                	ld	ra,104(sp)
ffffffffc02020f4:	64e6                	ld	s1,88(sp)
ffffffffc02020f6:	6946                	ld	s2,80(sp)
ffffffffc02020f8:	69a6                	ld	s3,72(sp)
ffffffffc02020fa:	6a06                	ld	s4,64(sp)
ffffffffc02020fc:	7ae2                	ld	s5,56(sp)
ffffffffc02020fe:	7b42                	ld	s6,48(sp)
ffffffffc0202100:	7ba2                	ld	s7,40(sp)
ffffffffc0202102:	7c02                	ld	s8,32(sp)
ffffffffc0202104:	6ce2                	ld	s9,24(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202106:	00003517          	auipc	a0,0x3
ffffffffc020210a:	64a50513          	add	a0,a0,1610 # ffffffffc0205750 <etext+0x1266>
}
ffffffffc020210e:	6165                	add	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202110:	fabfd06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202114:	6705                	lui	a4,0x1
ffffffffc0202116:	177d                	add	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202118:	96ba                	add	a3,a3,a4
ffffffffc020211a:	777d                	lui	a4,0xfffff
ffffffffc020211c:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) {
ffffffffc020211e:	00c75693          	srl	a3,a4,0xc
ffffffffc0202122:	14f6f263          	bgeu	a3,a5,ffffffffc0202266 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202126:	000bb583          	ld	a1,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc020212a:	fff807b7          	lui	a5,0xfff80
ffffffffc020212e:	96be                	add	a3,a3,a5
ffffffffc0202130:	00369793          	sll	a5,a3,0x3
ffffffffc0202134:	97b6                	add	a5,a5,a3
ffffffffc0202136:	6994                	ld	a3,16(a1)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202138:	8e19                	sub	a2,a2,a4
ffffffffc020213a:	078e                	sll	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020213c:	00c65593          	srl	a1,a2,0xc
ffffffffc0202140:	953e                	add	a0,a0,a5
ffffffffc0202142:	9682                	jalr	a3
}
ffffffffc0202144:	b4f9                	j	ffffffffc0201c12 <pmm_init+0x112>
        intr_disable();
ffffffffc0202146:	b96fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020214a:	000bb783          	ld	a5,0(s7)
ffffffffc020214e:	779c                	ld	a5,40(a5)
ffffffffc0202150:	9782                	jalr	a5
ffffffffc0202152:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202154:	b82fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202158:	b631                	j	ffffffffc0201c64 <pmm_init+0x164>
        intr_disable();
ffffffffc020215a:	b82fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc020215e:	000bb783          	ld	a5,0(s7)
ffffffffc0202162:	779c                	ld	a5,40(a5)
ffffffffc0202164:	9782                	jalr	a5
ffffffffc0202166:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202168:	b6efe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc020216c:	b36d                	j	ffffffffc0201f16 <pmm_init+0x416>
        intr_disable();
ffffffffc020216e:	b6efe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0202172:	000bb783          	ld	a5,0(s7)
ffffffffc0202176:	779c                	ld	a5,40(a5)
ffffffffc0202178:	9782                	jalr	a5
ffffffffc020217a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020217c:	b5afe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202180:	bb8d                	j	ffffffffc0201ef2 <pmm_init+0x3f2>
ffffffffc0202182:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202184:	b58fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc0202188:	000bb783          	ld	a5,0(s7)
ffffffffc020218c:	6522                	ld	a0,8(sp)
ffffffffc020218e:	4585                	li	a1,1
ffffffffc0202190:	739c                	ld	a5,32(a5)
ffffffffc0202192:	9782                	jalr	a5
        intr_enable();
ffffffffc0202194:	b42fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc0202198:	bb3d                	j	ffffffffc0201ed6 <pmm_init+0x3d6>
ffffffffc020219a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020219c:	b40fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02021a0:	000bb783          	ld	a5,0(s7)
ffffffffc02021a4:	6522                	ld	a0,8(sp)
ffffffffc02021a6:	4585                	li	a1,1
ffffffffc02021a8:	739c                	ld	a5,32(a5)
ffffffffc02021aa:	9782                	jalr	a5
        intr_enable();
ffffffffc02021ac:	b2afe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021b0:	b9c5                	j	ffffffffc0201ea0 <pmm_init+0x3a0>
        intr_disable();
ffffffffc02021b2:	b2afe0ef          	jal	ffffffffc02004dc <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02021b6:	000bb783          	ld	a5,0(s7)
ffffffffc02021ba:	779c                	ld	a5,40(a5)
ffffffffc02021bc:	9782                	jalr	a5
ffffffffc02021be:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02021c0:	b16fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021c4:	b725                	j	ffffffffc02020ec <pmm_init+0x5ec>
ffffffffc02021c6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021c8:	b14fe0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc02021cc:	000bb783          	ld	a5,0(s7)
ffffffffc02021d0:	6522                	ld	a0,8(sp)
ffffffffc02021d2:	4585                	li	a1,1
ffffffffc02021d4:	739c                	ld	a5,32(a5)
ffffffffc02021d6:	9782                	jalr	a5
        intr_enable();
ffffffffc02021d8:	afefe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021dc:	bdd5                	j	ffffffffc02020d0 <pmm_init+0x5d0>
ffffffffc02021de:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02021e0:	afcfe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02021e4:	000bb783          	ld	a5,0(s7)
ffffffffc02021e8:	6522                	ld	a0,8(sp)
ffffffffc02021ea:	4585                	li	a1,1
ffffffffc02021ec:	739c                	ld	a5,32(a5)
ffffffffc02021ee:	9782                	jalr	a5
        intr_enable();
ffffffffc02021f0:	ae6fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02021f4:	b55d                	j	ffffffffc020209a <pmm_init+0x59a>
        intr_disable();
ffffffffc02021f6:	ae6fe0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc02021fa:	000bb783          	ld	a5,0(s7)
ffffffffc02021fe:	4585                	li	a1,1
ffffffffc0202200:	8552                	mv	a0,s4
ffffffffc0202202:	739c                	ld	a5,32(a5)
ffffffffc0202204:	9782                	jalr	a5
        intr_enable();
ffffffffc0202206:	ad0fe0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc020220a:	bdb1                	j	ffffffffc0202066 <pmm_init+0x566>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020220c:	86a2                	mv	a3,s0
ffffffffc020220e:	00003617          	auipc	a2,0x3
ffffffffc0202212:	fc260613          	add	a2,a2,-62 # ffffffffc02051d0 <etext+0xce6>
ffffffffc0202216:	1cd00593          	li	a1,461
ffffffffc020221a:	00003517          	auipc	a0,0x3
ffffffffc020221e:	fde50513          	add	a0,a0,-34 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202222:	93efe0ef          	jal	ffffffffc0200360 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202226:	00003697          	auipc	a3,0x3
ffffffffc020222a:	3da68693          	add	a3,a3,986 # ffffffffc0205600 <etext+0x1116>
ffffffffc020222e:	00003617          	auipc	a2,0x3
ffffffffc0202232:	b9a60613          	add	a2,a2,-1126 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202236:	1ce00593          	li	a1,462
ffffffffc020223a:	00003517          	auipc	a0,0x3
ffffffffc020223e:	fbe50513          	add	a0,a0,-66 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202242:	91efe0ef          	jal	ffffffffc0200360 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202246:	00003697          	auipc	a3,0x3
ffffffffc020224a:	37a68693          	add	a3,a3,890 # ffffffffc02055c0 <etext+0x10d6>
ffffffffc020224e:	00003617          	auipc	a2,0x3
ffffffffc0202252:	b7a60613          	add	a2,a2,-1158 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202256:	1cd00593          	li	a1,461
ffffffffc020225a:	00003517          	auipc	a0,0x3
ffffffffc020225e:	f9e50513          	add	a0,a0,-98 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202262:	8fefe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0202266:	b24ff0ef          	jal	ffffffffc020158a <pa2page.part.0>
    assert(pte2page(*ptep) == p1);
ffffffffc020226a:	00003697          	auipc	a3,0x3
ffffffffc020226e:	14e68693          	add	a3,a3,334 # ffffffffc02053b8 <etext+0xece>
ffffffffc0202272:	00003617          	auipc	a2,0x3
ffffffffc0202276:	b5660613          	add	a2,a2,-1194 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020227a:	19b00593          	li	a1,411
ffffffffc020227e:	00003517          	auipc	a0,0x3
ffffffffc0202282:	f7a50513          	add	a0,a0,-134 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202286:	8dafe0ef          	jal	ffffffffc0200360 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020228a:	00003617          	auipc	a2,0x3
ffffffffc020228e:	00660613          	add	a2,a2,6 # ffffffffc0205290 <etext+0xda6>
ffffffffc0202292:	07700593          	li	a1,119
ffffffffc0202296:	00003517          	auipc	a0,0x3
ffffffffc020229a:	f6250513          	add	a0,a0,-158 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020229e:	8c2fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02022a2:	00003697          	auipc	a3,0x3
ffffffffc02022a6:	2de68693          	add	a3,a3,734 # ffffffffc0205580 <etext+0x1096>
ffffffffc02022aa:	00003617          	auipc	a2,0x3
ffffffffc02022ae:	b1e60613          	add	a2,a2,-1250 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02022b2:	1e800593          	li	a1,488
ffffffffc02022b6:	00003517          	auipc	a0,0x3
ffffffffc02022ba:	f4250513          	add	a0,a0,-190 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02022be:	8a2fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02022c2:	00003697          	auipc	a3,0x3
ffffffffc02022c6:	03668693          	add	a3,a3,54 # ffffffffc02052f8 <etext+0xe0e>
ffffffffc02022ca:	00003617          	auipc	a2,0x3
ffffffffc02022ce:	afe60613          	add	a2,a2,-1282 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02022d2:	19300593          	li	a1,403
ffffffffc02022d6:	00003517          	auipc	a0,0x3
ffffffffc02022da:	f2250513          	add	a0,a0,-222 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02022de:	882fe0ef          	jal	ffffffffc0200360 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022e2:	00003697          	auipc	a3,0x3
ffffffffc02022e6:	ff668693          	add	a3,a3,-10 # ffffffffc02052d8 <etext+0xdee>
ffffffffc02022ea:	00003617          	auipc	a2,0x3
ffffffffc02022ee:	ade60613          	add	a2,a2,-1314 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02022f2:	19200593          	li	a1,402
ffffffffc02022f6:	00003517          	auipc	a0,0x3
ffffffffc02022fa:	f0250513          	add	a0,a0,-254 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02022fe:	862fe0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0202302:	aa4ff0ef          	jal	ffffffffc02015a6 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202306:	00003697          	auipc	a3,0x3
ffffffffc020230a:	08268693          	add	a3,a3,130 # ffffffffc0205388 <etext+0xe9e>
ffffffffc020230e:	00003617          	auipc	a2,0x3
ffffffffc0202312:	aba60613          	add	a2,a2,-1350 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202316:	19a00593          	li	a1,410
ffffffffc020231a:	00003517          	auipc	a0,0x3
ffffffffc020231e:	ede50513          	add	a0,a0,-290 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202322:	83efe0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202326:	00003697          	auipc	a3,0x3
ffffffffc020232a:	03268693          	add	a3,a3,50 # ffffffffc0205358 <etext+0xe6e>
ffffffffc020232e:	00003617          	auipc	a2,0x3
ffffffffc0202332:	a9a60613          	add	a2,a2,-1382 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202336:	19800593          	li	a1,408
ffffffffc020233a:	00003517          	auipc	a0,0x3
ffffffffc020233e:	ebe50513          	add	a0,a0,-322 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202342:	81efe0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202346:	00003697          	auipc	a3,0x3
ffffffffc020234a:	fea68693          	add	a3,a3,-22 # ffffffffc0205330 <etext+0xe46>
ffffffffc020234e:	00003617          	auipc	a2,0x3
ffffffffc0202352:	a7a60613          	add	a2,a2,-1414 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202356:	19400593          	li	a1,404
ffffffffc020235a:	00003517          	auipc	a0,0x3
ffffffffc020235e:	e9e50513          	add	a0,a0,-354 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202362:	ffffd0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202366:	00003697          	auipc	a3,0x3
ffffffffc020236a:	0e268693          	add	a3,a3,226 # ffffffffc0205448 <etext+0xf5e>
ffffffffc020236e:	00003617          	auipc	a2,0x3
ffffffffc0202372:	a5a60613          	add	a2,a2,-1446 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202376:	1a400593          	li	a1,420
ffffffffc020237a:	00003517          	auipc	a0,0x3
ffffffffc020237e:	e7e50513          	add	a0,a0,-386 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202382:	fdffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202386:	00003697          	auipc	a3,0x3
ffffffffc020238a:	08a68693          	add	a3,a3,138 # ffffffffc0205410 <etext+0xf26>
ffffffffc020238e:	00003617          	auipc	a2,0x3
ffffffffc0202392:	a3a60613          	add	a2,a2,-1478 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202396:	1a300593          	li	a1,419
ffffffffc020239a:	00003517          	auipc	a0,0x3
ffffffffc020239e:	e5e50513          	add	a0,a0,-418 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02023a2:	fbffd0ef          	jal	ffffffffc0200360 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02023a6:	00003697          	auipc	a3,0x3
ffffffffc02023aa:	04268693          	add	a3,a3,66 # ffffffffc02053e8 <etext+0xefe>
ffffffffc02023ae:	00003617          	auipc	a2,0x3
ffffffffc02023b2:	a1a60613          	add	a2,a2,-1510 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02023b6:	1a000593          	li	a1,416
ffffffffc02023ba:	00003517          	auipc	a0,0x3
ffffffffc02023be:	e3e50513          	add	a0,a0,-450 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02023c2:	f9ffd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02023c6:	86d6                	mv	a3,s5
ffffffffc02023c8:	00003617          	auipc	a2,0x3
ffffffffc02023cc:	e0860613          	add	a2,a2,-504 # ffffffffc02051d0 <etext+0xce6>
ffffffffc02023d0:	19f00593          	li	a1,415
ffffffffc02023d4:	00003517          	auipc	a0,0x3
ffffffffc02023d8:	e2450513          	add	a0,a0,-476 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02023dc:	f85fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02023e0:	00003697          	auipc	a3,0x3
ffffffffc02023e4:	06868693          	add	a3,a3,104 # ffffffffc0205448 <etext+0xf5e>
ffffffffc02023e8:	00003617          	auipc	a2,0x3
ffffffffc02023ec:	9e060613          	add	a2,a2,-1568 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02023f0:	1ad00593          	li	a1,429
ffffffffc02023f4:	00003517          	auipc	a0,0x3
ffffffffc02023f8:	e0450513          	add	a0,a0,-508 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02023fc:	f65fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202400:	00003697          	auipc	a3,0x3
ffffffffc0202404:	11068693          	add	a3,a3,272 # ffffffffc0205510 <etext+0x1026>
ffffffffc0202408:	00003617          	auipc	a2,0x3
ffffffffc020240c:	9c060613          	add	a2,a2,-1600 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202410:	1ac00593          	li	a1,428
ffffffffc0202414:	00003517          	auipc	a0,0x3
ffffffffc0202418:	de450513          	add	a0,a0,-540 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020241c:	f45fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202420:	00003697          	auipc	a3,0x3
ffffffffc0202424:	0d868693          	add	a3,a3,216 # ffffffffc02054f8 <etext+0x100e>
ffffffffc0202428:	00003617          	auipc	a2,0x3
ffffffffc020242c:	9a060613          	add	a2,a2,-1632 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202430:	1ab00593          	li	a1,427
ffffffffc0202434:	00003517          	auipc	a0,0x3
ffffffffc0202438:	dc450513          	add	a0,a0,-572 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020243c:	f25fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202440:	00003697          	auipc	a3,0x3
ffffffffc0202444:	08868693          	add	a3,a3,136 # ffffffffc02054c8 <etext+0xfde>
ffffffffc0202448:	00003617          	auipc	a2,0x3
ffffffffc020244c:	98060613          	add	a2,a2,-1664 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202450:	1aa00593          	li	a1,426
ffffffffc0202454:	00003517          	auipc	a0,0x3
ffffffffc0202458:	da450513          	add	a0,a0,-604 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020245c:	f05fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202460:	00003697          	auipc	a3,0x3
ffffffffc0202464:	05068693          	add	a3,a3,80 # ffffffffc02054b0 <etext+0xfc6>
ffffffffc0202468:	00003617          	auipc	a2,0x3
ffffffffc020246c:	96060613          	add	a2,a2,-1696 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202470:	1a800593          	li	a1,424
ffffffffc0202474:	00003517          	auipc	a0,0x3
ffffffffc0202478:	d8450513          	add	a0,a0,-636 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020247c:	ee5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202480:	00003697          	auipc	a3,0x3
ffffffffc0202484:	01868693          	add	a3,a3,24 # ffffffffc0205498 <etext+0xfae>
ffffffffc0202488:	00003617          	auipc	a2,0x3
ffffffffc020248c:	94060613          	add	a2,a2,-1728 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202490:	1a700593          	li	a1,423
ffffffffc0202494:	00003517          	auipc	a0,0x3
ffffffffc0202498:	d6450513          	add	a0,a0,-668 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020249c:	ec5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02024a0:	00003697          	auipc	a3,0x3
ffffffffc02024a4:	fe868693          	add	a3,a3,-24 # ffffffffc0205488 <etext+0xf9e>
ffffffffc02024a8:	00003617          	auipc	a2,0x3
ffffffffc02024ac:	92060613          	add	a2,a2,-1760 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02024b0:	1a600593          	li	a1,422
ffffffffc02024b4:	00003517          	auipc	a0,0x3
ffffffffc02024b8:	d4450513          	add	a0,a0,-700 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02024bc:	ea5fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02024c0:	00003697          	auipc	a3,0x3
ffffffffc02024c4:	fb868693          	add	a3,a3,-72 # ffffffffc0205478 <etext+0xf8e>
ffffffffc02024c8:	00003617          	auipc	a2,0x3
ffffffffc02024cc:	90060613          	add	a2,a2,-1792 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02024d0:	1a500593          	li	a1,421
ffffffffc02024d4:	00003517          	auipc	a0,0x3
ffffffffc02024d8:	d2450513          	add	a0,a0,-732 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02024dc:	e85fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02024e0:	00003697          	auipc	a3,0x3
ffffffffc02024e4:	03068693          	add	a3,a3,48 # ffffffffc0205510 <etext+0x1026>
ffffffffc02024e8:	00003617          	auipc	a2,0x3
ffffffffc02024ec:	8e060613          	add	a2,a2,-1824 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02024f0:	1b300593          	li	a1,435
ffffffffc02024f4:	00003517          	auipc	a0,0x3
ffffffffc02024f8:	d0450513          	add	a0,a0,-764 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02024fc:	e65fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202500:	00003697          	auipc	a3,0x3
ffffffffc0202504:	ed068693          	add	a3,a3,-304 # ffffffffc02053d0 <etext+0xee6>
ffffffffc0202508:	00003617          	auipc	a2,0x3
ffffffffc020250c:	8c060613          	add	a2,a2,-1856 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202510:	1b200593          	li	a1,434
ffffffffc0202514:	00003517          	auipc	a0,0x3
ffffffffc0202518:	ce450513          	add	a0,a0,-796 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020251c:	e45fd0ef          	jal	ffffffffc0200360 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202520:	00003697          	auipc	a3,0x3
ffffffffc0202524:	00868693          	add	a3,a3,8 # ffffffffc0205528 <etext+0x103e>
ffffffffc0202528:	00003617          	auipc	a2,0x3
ffffffffc020252c:	8a060613          	add	a2,a2,-1888 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202530:	1af00593          	li	a1,431
ffffffffc0202534:	00003517          	auipc	a0,0x3
ffffffffc0202538:	cc450513          	add	a0,a0,-828 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020253c:	e25fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202540:	00003697          	auipc	a3,0x3
ffffffffc0202544:	e7868693          	add	a3,a3,-392 # ffffffffc02053b8 <etext+0xece>
ffffffffc0202548:	00003617          	auipc	a2,0x3
ffffffffc020254c:	88060613          	add	a2,a2,-1920 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202550:	1ae00593          	li	a1,430
ffffffffc0202554:	00003517          	auipc	a0,0x3
ffffffffc0202558:	ca450513          	add	a0,a0,-860 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020255c:	e05fd0ef          	jal	ffffffffc0200360 <__panic>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202560:	86a2                	mv	a3,s0
ffffffffc0202562:	00003617          	auipc	a2,0x3
ffffffffc0202566:	c6e60613          	add	a2,a2,-914 # ffffffffc02051d0 <etext+0xce6>
ffffffffc020256a:	06a00593          	li	a1,106
ffffffffc020256e:	00003517          	auipc	a0,0x3
ffffffffc0202572:	c2a50513          	add	a0,a0,-982 # ffffffffc0205198 <etext+0xcae>
ffffffffc0202576:	debfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020257a:	00003697          	auipc	a3,0x3
ffffffffc020257e:	fde68693          	add	a3,a3,-34 # ffffffffc0205558 <etext+0x106e>
ffffffffc0202582:	00003617          	auipc	a2,0x3
ffffffffc0202586:	84660613          	add	a2,a2,-1978 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020258a:	1b900593          	li	a1,441
ffffffffc020258e:	00003517          	auipc	a0,0x3
ffffffffc0202592:	c6a50513          	add	a0,a0,-918 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202596:	dcbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020259a:	00003697          	auipc	a3,0x3
ffffffffc020259e:	f7668693          	add	a3,a3,-138 # ffffffffc0205510 <etext+0x1026>
ffffffffc02025a2:	00003617          	auipc	a2,0x3
ffffffffc02025a6:	82660613          	add	a2,a2,-2010 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02025aa:	1b700593          	li	a1,439
ffffffffc02025ae:	00003517          	auipc	a0,0x3
ffffffffc02025b2:	c4a50513          	add	a0,a0,-950 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02025b6:	dabfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02025ba:	00003697          	auipc	a3,0x3
ffffffffc02025be:	f8668693          	add	a3,a3,-122 # ffffffffc0205540 <etext+0x1056>
ffffffffc02025c2:	00003617          	auipc	a2,0x3
ffffffffc02025c6:	80660613          	add	a2,a2,-2042 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02025ca:	1b600593          	li	a1,438
ffffffffc02025ce:	00003517          	auipc	a0,0x3
ffffffffc02025d2:	c2a50513          	add	a0,a0,-982 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02025d6:	d8bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025da:	00003697          	auipc	a3,0x3
ffffffffc02025de:	0a668693          	add	a3,a3,166 # ffffffffc0205680 <etext+0x1196>
ffffffffc02025e2:	00002617          	auipc	a2,0x2
ffffffffc02025e6:	7e660613          	add	a2,a2,2022 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02025ea:	1d800593          	li	a1,472
ffffffffc02025ee:	00003517          	auipc	a0,0x3
ffffffffc02025f2:	c0a50513          	add	a0,a0,-1014 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02025f6:	d6bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 1);
ffffffffc02025fa:	00003697          	auipc	a3,0x3
ffffffffc02025fe:	06e68693          	add	a3,a3,110 # ffffffffc0205668 <etext+0x117e>
ffffffffc0202602:	00002617          	auipc	a2,0x2
ffffffffc0202606:	7c660613          	add	a2,a2,1990 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020260a:	1d700593          	li	a1,471
ffffffffc020260e:	00003517          	auipc	a0,0x3
ffffffffc0202612:	bea50513          	add	a0,a0,-1046 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202616:	d4bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020261a:	00003697          	auipc	a3,0x3
ffffffffc020261e:	01668693          	add	a3,a3,22 # ffffffffc0205630 <etext+0x1146>
ffffffffc0202622:	00002617          	auipc	a2,0x2
ffffffffc0202626:	7a660613          	add	a2,a2,1958 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020262a:	1d600593          	li	a1,470
ffffffffc020262e:	00003517          	auipc	a0,0x3
ffffffffc0202632:	bca50513          	add	a0,a0,-1078 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202636:	d2bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020263a:	00003697          	auipc	a3,0x3
ffffffffc020263e:	fde68693          	add	a3,a3,-34 # ffffffffc0205618 <etext+0x112e>
ffffffffc0202642:	00002617          	auipc	a2,0x2
ffffffffc0202646:	78660613          	add	a2,a2,1926 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020264a:	1d200593          	li	a1,466
ffffffffc020264e:	00003517          	auipc	a0,0x3
ffffffffc0202652:	baa50513          	add	a0,a0,-1110 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202656:	d0bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020265a:	00003697          	auipc	a3,0x3
ffffffffc020265e:	f2668693          	add	a3,a3,-218 # ffffffffc0205580 <etext+0x1096>
ffffffffc0202662:	00002617          	auipc	a2,0x2
ffffffffc0202666:	76660613          	add	a2,a2,1894 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020266a:	1c000593          	li	a1,448
ffffffffc020266e:	00003517          	auipc	a0,0x3
ffffffffc0202672:	b8a50513          	add	a0,a0,-1142 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202676:	cebfd0ef          	jal	ffffffffc0200360 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020267a:	00003617          	auipc	a2,0x3
ffffffffc020267e:	c1660613          	add	a2,a2,-1002 # ffffffffc0205290 <etext+0xda6>
ffffffffc0202682:	0bd00593          	li	a1,189
ffffffffc0202686:	00003517          	auipc	a0,0x3
ffffffffc020268a:	b7250513          	add	a0,a0,-1166 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc020268e:	cd3fd0ef          	jal	ffffffffc0200360 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202692:	00003617          	auipc	a2,0x3
ffffffffc0202696:	b3e60613          	add	a2,a2,-1218 # ffffffffc02051d0 <etext+0xce6>
ffffffffc020269a:	19e00593          	li	a1,414
ffffffffc020269e:	00003517          	auipc	a0,0x3
ffffffffc02026a2:	b5a50513          	add	a0,a0,-1190 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02026a6:	cbbfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02026aa:	00003697          	auipc	a3,0x3
ffffffffc02026ae:	d2668693          	add	a3,a3,-730 # ffffffffc02053d0 <etext+0xee6>
ffffffffc02026b2:	00002617          	auipc	a2,0x2
ffffffffc02026b6:	71660613          	add	a2,a2,1814 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02026ba:	19c00593          	li	a1,412
ffffffffc02026be:	00003517          	auipc	a0,0x3
ffffffffc02026c2:	b3a50513          	add	a0,a0,-1222 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02026c6:	c9bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02026ca:	00003697          	auipc	a3,0x3
ffffffffc02026ce:	05e68693          	add	a3,a3,94 # ffffffffc0205728 <etext+0x123e>
ffffffffc02026d2:	00002617          	auipc	a2,0x2
ffffffffc02026d6:	6f660613          	add	a2,a2,1782 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02026da:	1e000593          	li	a1,480
ffffffffc02026de:	00003517          	auipc	a0,0x3
ffffffffc02026e2:	b1a50513          	add	a0,a0,-1254 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02026e6:	c7bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02026ea:	00003697          	auipc	a3,0x3
ffffffffc02026ee:	00668693          	add	a3,a3,6 # ffffffffc02056f0 <etext+0x1206>
ffffffffc02026f2:	00002617          	auipc	a2,0x2
ffffffffc02026f6:	6d660613          	add	a2,a2,1750 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02026fa:	1dd00593          	li	a1,477
ffffffffc02026fe:	00003517          	auipc	a0,0x3
ffffffffc0202702:	afa50513          	add	a0,a0,-1286 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202706:	c5bfd0ef          	jal	ffffffffc0200360 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020270a:	00003697          	auipc	a3,0x3
ffffffffc020270e:	fb668693          	add	a3,a3,-74 # ffffffffc02056c0 <etext+0x11d6>
ffffffffc0202712:	00002617          	auipc	a2,0x2
ffffffffc0202716:	6b660613          	add	a2,a2,1718 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020271a:	1d900593          	li	a1,473
ffffffffc020271e:	00003517          	auipc	a0,0x3
ffffffffc0202722:	ada50513          	add	a0,a0,-1318 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202726:	c3bfd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020272a <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc020272a:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc020272e:	8082                	ret

ffffffffc0202730 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202730:	7179                	add	sp,sp,-48
ffffffffc0202732:	e84a                	sd	s2,16(sp)
ffffffffc0202734:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202736:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202738:	ec26                	sd	s1,24(sp)
ffffffffc020273a:	e44e                	sd	s3,8(sp)
ffffffffc020273c:	f406                	sd	ra,40(sp)
ffffffffc020273e:	f022                	sd	s0,32(sp)
ffffffffc0202740:	84ae                	mv	s1,a1
ffffffffc0202742:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202744:	e7ffe0ef          	jal	ffffffffc02015c2 <alloc_pages>
    if (page != NULL) {
ffffffffc0202748:	c131                	beqz	a0,ffffffffc020278c <pgdir_alloc_page+0x5c>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc020274a:	842a                	mv	s0,a0
ffffffffc020274c:	85aa                	mv	a1,a0
ffffffffc020274e:	86ce                	mv	a3,s3
ffffffffc0202750:	8626                	mv	a2,s1
ffffffffc0202752:	854a                	mv	a0,s2
ffffffffc0202754:	a9aff0ef          	jal	ffffffffc02019ee <page_insert>
ffffffffc0202758:	ed11                	bnez	a0,ffffffffc0202774 <pgdir_alloc_page+0x44>
        if (swap_init_ok) {
ffffffffc020275a:	0000f797          	auipc	a5,0xf
ffffffffc020275e:	de67a783          	lw	a5,-538(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc0202762:	e79d                	bnez	a5,ffffffffc0202790 <pgdir_alloc_page+0x60>
}
ffffffffc0202764:	70a2                	ld	ra,40(sp)
ffffffffc0202766:	8522                	mv	a0,s0
ffffffffc0202768:	7402                	ld	s0,32(sp)
ffffffffc020276a:	64e2                	ld	s1,24(sp)
ffffffffc020276c:	6942                	ld	s2,16(sp)
ffffffffc020276e:	69a2                	ld	s3,8(sp)
ffffffffc0202770:	6145                	add	sp,sp,48
ffffffffc0202772:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202774:	100027f3          	csrr	a5,sstatus
ffffffffc0202778:	8b89                	and	a5,a5,2
ffffffffc020277a:	eba9                	bnez	a5,ffffffffc02027cc <pgdir_alloc_page+0x9c>
    { pmm_manager->free_pages(base, n); }
ffffffffc020277c:	0000f797          	auipc	a5,0xf
ffffffffc0202780:	d947b783          	ld	a5,-620(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc0202784:	739c                	ld	a5,32(a5)
ffffffffc0202786:	4585                	li	a1,1
ffffffffc0202788:	8522                	mv	a0,s0
ffffffffc020278a:	9782                	jalr	a5
            return NULL;
ffffffffc020278c:	4401                	li	s0,0
ffffffffc020278e:	bfd9                	j	ffffffffc0202764 <pgdir_alloc_page+0x34>
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202790:	4681                	li	a3,0
ffffffffc0202792:	8622                	mv	a2,s0
ffffffffc0202794:	85a6                	mv	a1,s1
ffffffffc0202796:	0000f517          	auipc	a0,0xf
ffffffffc020279a:	dd253503          	ld	a0,-558(a0) # ffffffffc0211568 <check_mm_struct>
ffffffffc020279e:	09d000ef          	jal	ffffffffc020303a <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc02027a2:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc02027a4:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc02027a6:	4785                	li	a5,1
ffffffffc02027a8:	faf70ee3          	beq	a4,a5,ffffffffc0202764 <pgdir_alloc_page+0x34>
ffffffffc02027ac:	00003697          	auipc	a3,0x3
ffffffffc02027b0:	fc468693          	add	a3,a3,-60 # ffffffffc0205770 <etext+0x1286>
ffffffffc02027b4:	00002617          	auipc	a2,0x2
ffffffffc02027b8:	61460613          	add	a2,a2,1556 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02027bc:	17a00593          	li	a1,378
ffffffffc02027c0:	00003517          	auipc	a0,0x3
ffffffffc02027c4:	a3850513          	add	a0,a0,-1480 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02027c8:	b99fd0ef          	jal	ffffffffc0200360 <__panic>
        intr_disable();
ffffffffc02027cc:	d11fd0ef          	jal	ffffffffc02004dc <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc02027d0:	0000f797          	auipc	a5,0xf
ffffffffc02027d4:	d407b783          	ld	a5,-704(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc02027d8:	739c                	ld	a5,32(a5)
ffffffffc02027da:	8522                	mv	a0,s0
ffffffffc02027dc:	4585                	li	a1,1
ffffffffc02027de:	9782                	jalr	a5
            return NULL;
ffffffffc02027e0:	4401                	li	s0,0
        intr_enable();
ffffffffc02027e2:	cf5fd0ef          	jal	ffffffffc02004d6 <intr_enable>
ffffffffc02027e6:	bfbd                	j	ffffffffc0202764 <pgdir_alloc_page+0x34>

ffffffffc02027e8 <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc02027e8:	1141                	add	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027ea:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc02027ec:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027ee:	fff50713          	add	a4,a0,-1
ffffffffc02027f2:	17f9                	add	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc02027f4:	06e7e363          	bltu	a5,a4,ffffffffc020285a <kmalloc+0x72>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02027f8:	6785                	lui	a5,0x1
ffffffffc02027fa:	17fd                	add	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02027fc:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc02027fe:	8131                	srl	a0,a0,0xc
ffffffffc0202800:	dc3fe0ef          	jal	ffffffffc02015c2 <alloc_pages>
    assert(base != NULL);
ffffffffc0202804:	c941                	beqz	a0,ffffffffc0202894 <kmalloc+0xac>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0202806:	f8e397b7          	lui	a5,0xf8e39
ffffffffc020280a:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc020280e:	07b2                	sll	a5,a5,0xc
ffffffffc0202810:	e3978793          	add	a5,a5,-455
ffffffffc0202814:	07b2                	sll	a5,a5,0xc
ffffffffc0202816:	0000f717          	auipc	a4,0xf
ffffffffc020281a:	d2273703          	ld	a4,-734(a4) # ffffffffc0211538 <pages>
ffffffffc020281e:	e3978793          	add	a5,a5,-455
ffffffffc0202822:	8d19                	sub	a0,a0,a4
ffffffffc0202824:	07b2                	sll	a5,a5,0xc
ffffffffc0202826:	e3978793          	add	a5,a5,-455
ffffffffc020282a:	850d                	sra	a0,a0,0x3
ffffffffc020282c:	02f50533          	mul	a0,a0,a5
ffffffffc0202830:	000807b7          	lui	a5,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202834:	0000f717          	auipc	a4,0xf
ffffffffc0202838:	cfc73703          	ld	a4,-772(a4) # ffffffffc0211530 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020283c:	953e                	add	a0,a0,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020283e:	00c51793          	sll	a5,a0,0xc
ffffffffc0202842:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202844:	0532                	sll	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0202846:	02e7fa63          	bgeu	a5,a4,ffffffffc020287a <kmalloc+0x92>
    ptr = page2kva(base);
    return ptr;
}
ffffffffc020284a:	60a2                	ld	ra,8(sp)
ffffffffc020284c:	0000f797          	auipc	a5,0xf
ffffffffc0202850:	cdc7b783          	ld	a5,-804(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc0202854:	953e                	add	a0,a0,a5
ffffffffc0202856:	0141                	add	sp,sp,16
ffffffffc0202858:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020285a:	00003697          	auipc	a3,0x3
ffffffffc020285e:	f2e68693          	add	a3,a3,-210 # ffffffffc0205788 <etext+0x129e>
ffffffffc0202862:	00002617          	auipc	a2,0x2
ffffffffc0202866:	56660613          	add	a2,a2,1382 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020286a:	1f000593          	li	a1,496
ffffffffc020286e:	00003517          	auipc	a0,0x3
ffffffffc0202872:	98a50513          	add	a0,a0,-1654 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202876:	aebfd0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc020287a:	86aa                	mv	a3,a0
ffffffffc020287c:	00003617          	auipc	a2,0x3
ffffffffc0202880:	95460613          	add	a2,a2,-1708 # ffffffffc02051d0 <etext+0xce6>
ffffffffc0202884:	06a00593          	li	a1,106
ffffffffc0202888:	00003517          	auipc	a0,0x3
ffffffffc020288c:	91050513          	add	a0,a0,-1776 # ffffffffc0205198 <etext+0xcae>
ffffffffc0202890:	ad1fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(base != NULL);
ffffffffc0202894:	00003697          	auipc	a3,0x3
ffffffffc0202898:	f1468693          	add	a3,a3,-236 # ffffffffc02057a8 <etext+0x12be>
ffffffffc020289c:	00002617          	auipc	a2,0x2
ffffffffc02028a0:	52c60613          	add	a2,a2,1324 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02028a4:	1f300593          	li	a1,499
ffffffffc02028a8:	00003517          	auipc	a0,0x3
ffffffffc02028ac:	95050513          	add	a0,a0,-1712 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc02028b0:	ab1fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02028b4 <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc02028b4:	1101                	add	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02028b6:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc02028b8:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02028ba:	fff58713          	add	a4,a1,-1
ffffffffc02028be:	17f9                	add	a5,a5,-2 # 14ffe <kern_entry-0xffffffffc01eb002>
ffffffffc02028c0:	0ae7ee63          	bltu	a5,a4,ffffffffc020297c <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc02028c4:	cd41                	beqz	a0,ffffffffc020295c <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc02028c6:	6785                	lui	a5,0x1
ffffffffc02028c8:	17fd                	add	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02028ca:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02028cc:	c02007b7          	lui	a5,0xc0200
ffffffffc02028d0:	81b1                	srl	a1,a1,0xc
ffffffffc02028d2:	06f56863          	bltu	a0,a5,ffffffffc0202942 <kfree+0x8e>
ffffffffc02028d6:	0000f797          	auipc	a5,0xf
ffffffffc02028da:	c527b783          	ld	a5,-942(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc02028de:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02028e0:	8131                	srl	a0,a0,0xc
ffffffffc02028e2:	0000f797          	auipc	a5,0xf
ffffffffc02028e6:	c4e7b783          	ld	a5,-946(a5) # ffffffffc0211530 <npage>
ffffffffc02028ea:	04f57a63          	bgeu	a0,a5,ffffffffc020293e <kfree+0x8a>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ee:	fff807b7          	lui	a5,0xfff80
ffffffffc02028f2:	953e                	add	a0,a0,a5
ffffffffc02028f4:	00351793          	sll	a5,a0,0x3
ffffffffc02028f8:	97aa                	add	a5,a5,a0
ffffffffc02028fa:	078e                	sll	a5,a5,0x3
ffffffffc02028fc:	0000f517          	auipc	a0,0xf
ffffffffc0202900:	c3c53503          	ld	a0,-964(a0) # ffffffffc0211538 <pages>
ffffffffc0202904:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202906:	100027f3          	csrr	a5,sstatus
ffffffffc020290a:	8b89                	and	a5,a5,2
ffffffffc020290c:	eb89                	bnez	a5,ffffffffc020291e <kfree+0x6a>
    { pmm_manager->free_pages(base, n); }
ffffffffc020290e:	0000f797          	auipc	a5,0xf
ffffffffc0202912:	c027b783          	ld	a5,-1022(a5) # ffffffffc0211510 <pmm_manager>
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc0202916:	60e2                	ld	ra,24(sp)
    { pmm_manager->free_pages(base, n); }
ffffffffc0202918:	739c                	ld	a5,32(a5)
}
ffffffffc020291a:	6105                	add	sp,sp,32
    { pmm_manager->free_pages(base, n); }
ffffffffc020291c:	8782                	jr	a5
        intr_disable();
ffffffffc020291e:	e42a                	sd	a0,8(sp)
ffffffffc0202920:	e02e                	sd	a1,0(sp)
ffffffffc0202922:	bbbfd0ef          	jal	ffffffffc02004dc <intr_disable>
ffffffffc0202926:	0000f797          	auipc	a5,0xf
ffffffffc020292a:	bea7b783          	ld	a5,-1046(a5) # ffffffffc0211510 <pmm_manager>
ffffffffc020292e:	6582                	ld	a1,0(sp)
ffffffffc0202930:	6522                	ld	a0,8(sp)
ffffffffc0202932:	739c                	ld	a5,32(a5)
ffffffffc0202934:	9782                	jalr	a5
}
ffffffffc0202936:	60e2                	ld	ra,24(sp)
ffffffffc0202938:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc020293a:	b9dfd06f          	j	ffffffffc02004d6 <intr_enable>
ffffffffc020293e:	c4dfe0ef          	jal	ffffffffc020158a <pa2page.part.0>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202942:	86aa                	mv	a3,a0
ffffffffc0202944:	00003617          	auipc	a2,0x3
ffffffffc0202948:	94c60613          	add	a2,a2,-1716 # ffffffffc0205290 <etext+0xda6>
ffffffffc020294c:	06c00593          	li	a1,108
ffffffffc0202950:	00003517          	auipc	a0,0x3
ffffffffc0202954:	84850513          	add	a0,a0,-1976 # ffffffffc0205198 <etext+0xcae>
ffffffffc0202958:	a09fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(ptr != NULL);
ffffffffc020295c:	00003697          	auipc	a3,0x3
ffffffffc0202960:	e5c68693          	add	a3,a3,-420 # ffffffffc02057b8 <etext+0x12ce>
ffffffffc0202964:	00002617          	auipc	a2,0x2
ffffffffc0202968:	46460613          	add	a2,a2,1124 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020296c:	1fa00593          	li	a1,506
ffffffffc0202970:	00003517          	auipc	a0,0x3
ffffffffc0202974:	88850513          	add	a0,a0,-1912 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202978:	9e9fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020297c:	00003697          	auipc	a3,0x3
ffffffffc0202980:	e0c68693          	add	a3,a3,-500 # ffffffffc0205788 <etext+0x129e>
ffffffffc0202984:	00002617          	auipc	a2,0x2
ffffffffc0202988:	44460613          	add	a2,a2,1092 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020298c:	1f900593          	li	a1,505
ffffffffc0202990:	00003517          	auipc	a0,0x3
ffffffffc0202994:	86850513          	add	a0,a0,-1944 # ffffffffc02051f8 <etext+0xd0e>
ffffffffc0202998:	9c9fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020299c <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020299c:	7135                	add	sp,sp,-160
ffffffffc020299e:	ed06                	sd	ra,152(sp)
     swapfs_init();
ffffffffc02029a0:	45e010ef          	jal	ffffffffc0203dfe <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02029a4:	0000f697          	auipc	a3,0xf
ffffffffc02029a8:	ba46b683          	ld	a3,-1116(a3) # ffffffffc0211548 <max_swap_offset>
ffffffffc02029ac:	010007b7          	lui	a5,0x1000
ffffffffc02029b0:	ff968713          	add	a4,a3,-7
ffffffffc02029b4:	17e1                	add	a5,a5,-8 # fffff8 <kern_entry-0xffffffffbf200008>
ffffffffc02029b6:	40e7e463          	bltu	a5,a4,ffffffffc0202dbe <swap_init+0x422>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02029ba:	00007797          	auipc	a5,0x7
ffffffffc02029be:	64678793          	add	a5,a5,1606 # ffffffffc020a000 <swap_manager_clock>
     int r = sm->init();
ffffffffc02029c2:	6798                	ld	a4,8(a5)
ffffffffc02029c4:	fcce                	sd	s3,120(sp)
ffffffffc02029c6:	f0da                	sd	s6,96(sp)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc02029c8:	0000fb17          	auipc	s6,0xf
ffffffffc02029cc:	b88b0b13          	add	s6,s6,-1144 # ffffffffc0211550 <sm>
ffffffffc02029d0:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc02029d4:	9702                	jalr	a4
ffffffffc02029d6:	89aa                	mv	s3,a0
     
     if (r == 0)
ffffffffc02029d8:	c519                	beqz	a0,ffffffffc02029e6 <swap_init+0x4a>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02029da:	60ea                	ld	ra,152(sp)
ffffffffc02029dc:	7b06                	ld	s6,96(sp)
ffffffffc02029de:	854e                	mv	a0,s3
ffffffffc02029e0:	79e6                	ld	s3,120(sp)
ffffffffc02029e2:	610d                	add	sp,sp,160
ffffffffc02029e4:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02029e6:	000b3783          	ld	a5,0(s6)
ffffffffc02029ea:	00003517          	auipc	a0,0x3
ffffffffc02029ee:	e0e50513          	add	a0,a0,-498 # ffffffffc02057f8 <etext+0x130e>
ffffffffc02029f2:	e922                	sd	s0,144(sp)
ffffffffc02029f4:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02029f6:	4785                	li	a5,1
ffffffffc02029f8:	e526                	sd	s1,136(sp)
ffffffffc02029fa:	e0ea                	sd	s10,64(sp)
ffffffffc02029fc:	0000f717          	auipc	a4,0xf
ffffffffc0202a00:	b4f72223          	sw	a5,-1212(a4) # ffffffffc0211540 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202a04:	e14a                	sd	s2,128(sp)
ffffffffc0202a06:	f8d2                	sd	s4,112(sp)
ffffffffc0202a08:	f4d6                	sd	s5,104(sp)
ffffffffc0202a0a:	ecde                	sd	s7,88(sp)
ffffffffc0202a0c:	e8e2                	sd	s8,80(sp)
ffffffffc0202a0e:	e4e6                	sd	s9,72(sp)
ffffffffc0202a10:	fc6e                	sd	s11,56(sp)
    return listelm->next;
ffffffffc0202a12:	0000e497          	auipc	s1,0xe
ffffffffc0202a16:	62e48493          	add	s1,s1,1582 # ffffffffc0211040 <free_area>
ffffffffc0202a1a:	ea0fd0ef          	jal	ffffffffc02000ba <cprintf>
ffffffffc0202a1e:	649c                	ld	a5,8(s1)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202a20:	4401                	li	s0,0
ffffffffc0202a22:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a24:	2e978363          	beq	a5,s1,ffffffffc0202d0a <swap_init+0x36e>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202a28:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202a2c:	8b09                	and	a4,a4,2
ffffffffc0202a2e:	2e070063          	beqz	a4,ffffffffc0202d0e <swap_init+0x372>
        count ++, total += p->property;
ffffffffc0202a32:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202a36:	679c                	ld	a5,8(a5)
ffffffffc0202a38:	2d05                	addw	s10,s10,1
ffffffffc0202a3a:	9c39                	addw	s0,s0,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202a3c:	fe9796e3          	bne	a5,s1,ffffffffc0202a28 <swap_init+0x8c>
     }
     assert(total == nr_free_pages());
ffffffffc0202a40:	8922                	mv	s2,s0
ffffffffc0202a42:	c51fe0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc0202a46:	4b251463          	bne	a0,s2,ffffffffc0202eee <swap_init+0x552>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202a4a:	8622                	mv	a2,s0
ffffffffc0202a4c:	85ea                	mv	a1,s10
ffffffffc0202a4e:	00003517          	auipc	a0,0x3
ffffffffc0202a52:	dc250513          	add	a0,a0,-574 # ffffffffc0205810 <etext+0x1326>
ffffffffc0202a56:	e64fd0ef          	jal	ffffffffc02000ba <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202a5a:	331000ef          	jal	ffffffffc020358a <mm_create>
ffffffffc0202a5e:	ec2a                	sd	a0,24(sp)
     assert(mm != NULL);
ffffffffc0202a60:	56050763          	beqz	a0,ffffffffc0202fce <swap_init+0x632>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202a64:	0000f797          	auipc	a5,0xf
ffffffffc0202a68:	b0478793          	add	a5,a5,-1276 # ffffffffc0211568 <check_mm_struct>
ffffffffc0202a6c:	6398                	ld	a4,0(a5)
ffffffffc0202a6e:	58071063          	bnez	a4,ffffffffc0202fee <swap_init+0x652>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a72:	0000f697          	auipc	a3,0xf
ffffffffc0202a76:	aae6b683          	ld	a3,-1362(a3) # ffffffffc0211520 <boot_pgdir>
     check_mm_struct = mm;
ffffffffc0202a7a:	6662                	ld	a2,24(sp)
     assert(pgdir[0] == 0);
ffffffffc0202a7c:	6298                	ld	a4,0(a3)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a7e:	e836                	sd	a3,16(sp)
     check_mm_struct = mm;
ffffffffc0202a80:	e390                	sd	a2,0(a5)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202a82:	ee14                	sd	a3,24(a2)
     assert(pgdir[0] == 0);
ffffffffc0202a84:	40071563          	bnez	a4,ffffffffc0202e8e <swap_init+0x4f2>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202a88:	6599                	lui	a1,0x6
ffffffffc0202a8a:	460d                	li	a2,3
ffffffffc0202a8c:	6505                	lui	a0,0x1
ffffffffc0202a8e:	345000ef          	jal	ffffffffc02035d2 <vma_create>
ffffffffc0202a92:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202a94:	40050d63          	beqz	a0,ffffffffc0202eae <swap_init+0x512>

     insert_vma_struct(mm, vma);
ffffffffc0202a98:	6962                	ld	s2,24(sp)
ffffffffc0202a9a:	854a                	mv	a0,s2
ffffffffc0202a9c:	3a5000ef          	jal	ffffffffc0203640 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202aa0:	00003517          	auipc	a0,0x3
ffffffffc0202aa4:	de050513          	add	a0,a0,-544 # ffffffffc0205880 <etext+0x1396>
ffffffffc0202aa8:	e12fd0ef          	jal	ffffffffc02000ba <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202aac:	01893503          	ld	a0,24(s2)
ffffffffc0202ab0:	4605                	li	a2,1
ffffffffc0202ab2:	6585                	lui	a1,0x1
ffffffffc0202ab4:	c19fe0ef          	jal	ffffffffc02016cc <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202ab8:	40050b63          	beqz	a0,ffffffffc0202ece <swap_init+0x532>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202abc:	00003517          	auipc	a0,0x3
ffffffffc0202ac0:	e1450513          	add	a0,a0,-492 # ffffffffc02058d0 <etext+0x13e6>
ffffffffc0202ac4:	0000e917          	auipc	s2,0xe
ffffffffc0202ac8:	5b490913          	add	s2,s2,1460 # ffffffffc0211078 <check_rp>
ffffffffc0202acc:	deefd0ef          	jal	ffffffffc02000ba <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ad0:	0000ea17          	auipc	s4,0xe
ffffffffc0202ad4:	5c8a0a13          	add	s4,s4,1480 # ffffffffc0211098 <swap_out_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202ad8:	8c4a                	mv	s8,s2
          check_rp[i] = alloc_page();
ffffffffc0202ada:	4505                	li	a0,1
ffffffffc0202adc:	ae7fe0ef          	jal	ffffffffc02015c2 <alloc_pages>
ffffffffc0202ae0:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc0202ae4:	2a050d63          	beqz	a0,ffffffffc0202d9e <swap_init+0x402>
ffffffffc0202ae8:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202aea:	8b89                	and	a5,a5,2
ffffffffc0202aec:	28079963          	bnez	a5,ffffffffc0202d7e <swap_init+0x3e2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202af0:	0c21                	add	s8,s8,8
ffffffffc0202af2:	ff4c14e3          	bne	s8,s4,ffffffffc0202ada <swap_init+0x13e>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202af6:	609c                	ld	a5,0(s1)
ffffffffc0202af8:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc0202afc:	e084                	sd	s1,0(s1)
ffffffffc0202afe:	f03e                	sd	a5,32(sp)
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
ffffffffc0202b00:	489c                	lw	a5,16(s1)
ffffffffc0202b02:	e484                	sd	s1,8(s1)
     nr_free = 0;
ffffffffc0202b04:	0000ec17          	auipc	s8,0xe
ffffffffc0202b08:	574c0c13          	add	s8,s8,1396 # ffffffffc0211078 <check_rp>
     unsigned int nr_free_store = nr_free;
ffffffffc0202b0c:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0202b0e:	0000e797          	auipc	a5,0xe
ffffffffc0202b12:	5407a123          	sw	zero,1346(a5) # ffffffffc0211050 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202b16:	000c3503          	ld	a0,0(s8)
ffffffffc0202b1a:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b1c:	0c21                	add	s8,s8,8
        free_pages(check_rp[i],1);
ffffffffc0202b1e:	b35fe0ef          	jal	ffffffffc0201652 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202b22:	ff4c1ae3          	bne	s8,s4,ffffffffc0202b16 <swap_init+0x17a>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202b26:	0104ac03          	lw	s8,16(s1)
ffffffffc0202b2a:	4791                	li	a5,4
ffffffffc0202b2c:	4efc1163          	bne	s8,a5,ffffffffc020300e <swap_init+0x672>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202b30:	00003517          	auipc	a0,0x3
ffffffffc0202b34:	e2850513          	add	a0,a0,-472 # ffffffffc0205958 <etext+0x146e>
ffffffffc0202b38:	d82fd0ef          	jal	ffffffffc02000ba <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202b3c:	0000f797          	auipc	a5,0xf
ffffffffc0202b40:	a207a223          	sw	zero,-1500(a5) # ffffffffc0211560 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202b44:	6785                	lui	a5,0x1
ffffffffc0202b46:	4529                	li	a0,10
ffffffffc0202b48:	00a78023          	sb	a0,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202b4c:	0000f597          	auipc	a1,0xf
ffffffffc0202b50:	a145a583          	lw	a1,-1516(a1) # ffffffffc0211560 <pgfault_num>
ffffffffc0202b54:	4605                	li	a2,1
ffffffffc0202b56:	0000f797          	auipc	a5,0xf
ffffffffc0202b5a:	a0a78793          	add	a5,a5,-1526 # ffffffffc0211560 <pgfault_num>
ffffffffc0202b5e:	42c59863          	bne	a1,a2,ffffffffc0202f8e <swap_init+0x5f2>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202b62:	6605                	lui	a2,0x1
ffffffffc0202b64:	00a60823          	sb	a0,16(a2) # 1010 <kern_entry-0xffffffffc01feff0>
     assert(pgfault_num==1);
ffffffffc0202b68:	4388                	lw	a0,0(a5)
ffffffffc0202b6a:	44b51263          	bne	a0,a1,ffffffffc0202fae <swap_init+0x612>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202b6e:	6609                	lui	a2,0x2
ffffffffc0202b70:	45ad                	li	a1,11
ffffffffc0202b72:	00b60023          	sb	a1,0(a2) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202b76:	4390                	lw	a2,0(a5)
ffffffffc0202b78:	4809                	li	a6,2
ffffffffc0202b7a:	0006051b          	sext.w	a0,a2
ffffffffc0202b7e:	39061863          	bne	a2,a6,ffffffffc0202f0e <swap_init+0x572>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202b82:	6609                	lui	a2,0x2
ffffffffc0202b84:	00b60823          	sb	a1,16(a2) # 2010 <kern_entry-0xffffffffc01fdff0>
     assert(pgfault_num==2);
ffffffffc0202b88:	438c                	lw	a1,0(a5)
ffffffffc0202b8a:	3aa59263          	bne	a1,a0,ffffffffc0202f2e <swap_init+0x592>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202b8e:	660d                	lui	a2,0x3
ffffffffc0202b90:	45b1                	li	a1,12
ffffffffc0202b92:	00b60023          	sb	a1,0(a2) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202b96:	4390                	lw	a2,0(a5)
ffffffffc0202b98:	480d                	li	a6,3
ffffffffc0202b9a:	0006051b          	sext.w	a0,a2
ffffffffc0202b9e:	3b061863          	bne	a2,a6,ffffffffc0202f4e <swap_init+0x5b2>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202ba2:	660d                	lui	a2,0x3
ffffffffc0202ba4:	00b60823          	sb	a1,16(a2) # 3010 <kern_entry-0xffffffffc01fcff0>
     assert(pgfault_num==3);
ffffffffc0202ba8:	438c                	lw	a1,0(a5)
ffffffffc0202baa:	3ca59263          	bne	a1,a0,ffffffffc0202f6e <swap_init+0x5d2>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202bae:	6611                	lui	a2,0x4
ffffffffc0202bb0:	45b5                	li	a1,13
ffffffffc0202bb2:	00b60023          	sb	a1,0(a2) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202bb6:	4390                	lw	a2,0(a5)
ffffffffc0202bb8:	0006051b          	sext.w	a0,a2
ffffffffc0202bbc:	25861963          	bne	a2,s8,ffffffffc0202e0e <swap_init+0x472>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202bc0:	6611                	lui	a2,0x4
ffffffffc0202bc2:	00b60823          	sb	a1,16(a2) # 4010 <kern_entry-0xffffffffc01fbff0>
     assert(pgfault_num==4);
ffffffffc0202bc6:	439c                	lw	a5,0(a5)
ffffffffc0202bc8:	26a79363          	bne	a5,a0,ffffffffc0202e2e <swap_init+0x492>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202bcc:	489c                	lw	a5,16(s1)
ffffffffc0202bce:	28079063          	bnez	a5,ffffffffc0202e4e <swap_init+0x4b2>
ffffffffc0202bd2:	0000e797          	auipc	a5,0xe
ffffffffc0202bd6:	4ee78793          	add	a5,a5,1262 # ffffffffc02110c0 <swap_in_seq_no>
ffffffffc0202bda:	0000e617          	auipc	a2,0xe
ffffffffc0202bde:	4be60613          	add	a2,a2,1214 # ffffffffc0211098 <swap_out_seq_no>
ffffffffc0202be2:	0000e517          	auipc	a0,0xe
ffffffffc0202be6:	50650513          	add	a0,a0,1286 # ffffffffc02110e8 <pra_list_head>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202bea:	55fd                	li	a1,-1
ffffffffc0202bec:	c38c                	sw	a1,0(a5)
ffffffffc0202bee:	c20c                	sw	a1,0(a2)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202bf0:	0791                	add	a5,a5,4
ffffffffc0202bf2:	0611                	add	a2,a2,4
ffffffffc0202bf4:	fea79ce3          	bne	a5,a0,ffffffffc0202bec <swap_init+0x250>
ffffffffc0202bf8:	0000e817          	auipc	a6,0xe
ffffffffc0202bfc:	46080813          	add	a6,a6,1120 # ffffffffc0211058 <check_ptep>
ffffffffc0202c00:	0000e897          	auipc	a7,0xe
ffffffffc0202c04:	47888893          	add	a7,a7,1144 # ffffffffc0211078 <check_rp>
ffffffffc0202c08:	6a85                	lui	s5,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202c0a:	0000fb97          	auipc	s7,0xf
ffffffffc0202c0e:	926b8b93          	add	s7,s7,-1754 # ffffffffc0211530 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c12:	0000fc17          	auipc	s8,0xf
ffffffffc0202c16:	926c0c13          	add	s8,s8,-1754 # ffffffffc0211538 <pages>
ffffffffc0202c1a:	00003c97          	auipc	s9,0x3
ffffffffc0202c1e:	6e6c8c93          	add	s9,s9,1766 # ffffffffc0206300 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c22:	6542                	ld	a0,16(sp)
         check_ptep[i]=0;
ffffffffc0202c24:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c28:	4601                	li	a2,0
ffffffffc0202c2a:	85d6                	mv	a1,s5
ffffffffc0202c2c:	e446                	sd	a7,8(sp)
         check_ptep[i]=0;
ffffffffc0202c2e:	e042                	sd	a6,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c30:	a9dfe0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0202c34:	6802                	ld	a6,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202c36:	68a2                	ld	a7,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202c38:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL);
ffffffffc0202c3c:	1a050963          	beqz	a0,ffffffffc0202dee <swap_init+0x452>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202c40:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202c42:	0017f613          	and	a2,a5,1
ffffffffc0202c46:	10060463          	beqz	a2,ffffffffc0202d4e <swap_init+0x3b2>
    if (PPN(pa) >= npage) {
ffffffffc0202c4a:	000bb603          	ld	a2,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202c4e:	078a                	sll	a5,a5,0x2
ffffffffc0202c50:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202c52:	10c7fa63          	bgeu	a5,a2,ffffffffc0202d66 <swap_init+0x3ca>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c56:	000cb603          	ld	a2,0(s9)
ffffffffc0202c5a:	000c3503          	ld	a0,0(s8)
ffffffffc0202c5e:	0008bf03          	ld	t5,0(a7)
ffffffffc0202c62:	8f91                	sub	a5,a5,a2
ffffffffc0202c64:	00379613          	sll	a2,a5,0x3
ffffffffc0202c68:	97b2                	add	a5,a5,a2
ffffffffc0202c6a:	078e                	sll	a5,a5,0x3
ffffffffc0202c6c:	6705                	lui	a4,0x1
ffffffffc0202c6e:	97aa                	add	a5,a5,a0
ffffffffc0202c70:	08a1                	add	a7,a7,8
ffffffffc0202c72:	0821                	add	a6,a6,8
ffffffffc0202c74:	9aba                	add	s5,s5,a4
ffffffffc0202c76:	0aff1c63          	bne	t5,a5,ffffffffc0202d2e <swap_init+0x392>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c7a:	6795                	lui	a5,0x5
ffffffffc0202c7c:	fafa93e3          	bne	s5,a5,ffffffffc0202c22 <swap_init+0x286>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202c80:	00003517          	auipc	a0,0x3
ffffffffc0202c84:	d8050513          	add	a0,a0,-640 # ffffffffc0205a00 <etext+0x1516>
ffffffffc0202c88:	c32fd0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = sm->check_swap();
ffffffffc0202c8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c90:	7f9c                	ld	a5,56(a5)
ffffffffc0202c92:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202c94:	1c051d63          	bnez	a0,ffffffffc0202e6e <swap_init+0x4d2>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202c98:	00093503          	ld	a0,0(s2)
ffffffffc0202c9c:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c9e:	0921                	add	s2,s2,8
         free_pages(check_rp[i],1);
ffffffffc0202ca0:	9b3fe0ef          	jal	ffffffffc0201652 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202ca4:	ff491ae3          	bne	s2,s4,ffffffffc0202c98 <swap_init+0x2fc>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202ca8:	6562                	ld	a0,24(sp)
ffffffffc0202caa:	267000ef          	jal	ffffffffc0203710 <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc0202cae:	77a2                	ld	a5,40(sp)
     free_list = free_list_store;
ffffffffc0202cb0:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store;
ffffffffc0202cb4:	c89c                	sw	a5,16(s1)
     free_list = free_list_store;
ffffffffc0202cb6:	7782                	ld	a5,32(sp)
ffffffffc0202cb8:	e09c                	sd	a5,0(s1)

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cba:	009d8a63          	beq	s11,s1,ffffffffc0202cce <swap_init+0x332>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202cbe:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc0202cc2:	008dbd83          	ld	s11,8(s11)
ffffffffc0202cc6:	3d7d                	addw	s10,s10,-1
ffffffffc0202cc8:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202cca:	fe9d9ae3          	bne	s11,s1,ffffffffc0202cbe <swap_init+0x322>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202cce:	8622                	mv	a2,s0
ffffffffc0202cd0:	85ea                	mv	a1,s10
ffffffffc0202cd2:	00003517          	auipc	a0,0x3
ffffffffc0202cd6:	d5e50513          	add	a0,a0,-674 # ffffffffc0205a30 <etext+0x1546>
ffffffffc0202cda:	be0fd0ef          	jal	ffffffffc02000ba <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202cde:	00003517          	auipc	a0,0x3
ffffffffc0202ce2:	d7250513          	add	a0,a0,-654 # ffffffffc0205a50 <etext+0x1566>
ffffffffc0202ce6:	bd4fd0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc0202cea:	60ea                	ld	ra,152(sp)
     cprintf("check_swap() succeeded!\n");
ffffffffc0202cec:	644a                	ld	s0,144(sp)
ffffffffc0202cee:	64aa                	ld	s1,136(sp)
ffffffffc0202cf0:	690a                	ld	s2,128(sp)
ffffffffc0202cf2:	7a46                	ld	s4,112(sp)
ffffffffc0202cf4:	7aa6                	ld	s5,104(sp)
ffffffffc0202cf6:	6be6                	ld	s7,88(sp)
ffffffffc0202cf8:	6c46                	ld	s8,80(sp)
ffffffffc0202cfa:	6ca6                	ld	s9,72(sp)
ffffffffc0202cfc:	6d06                	ld	s10,64(sp)
ffffffffc0202cfe:	7de2                	ld	s11,56(sp)
}
ffffffffc0202d00:	7b06                	ld	s6,96(sp)
ffffffffc0202d02:	854e                	mv	a0,s3
ffffffffc0202d04:	79e6                	ld	s3,120(sp)
ffffffffc0202d06:	610d                	add	sp,sp,160
ffffffffc0202d08:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202d0a:	4901                	li	s2,0
ffffffffc0202d0c:	bb1d                	j	ffffffffc0202a42 <swap_init+0xa6>
        assert(PageProperty(p));
ffffffffc0202d0e:	00002697          	auipc	a3,0x2
ffffffffc0202d12:	0aa68693          	add	a3,a3,170 # ffffffffc0204db8 <etext+0x8ce>
ffffffffc0202d16:	00002617          	auipc	a2,0x2
ffffffffc0202d1a:	0b260613          	add	a2,a2,178 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202d1e:	0ba00593          	li	a1,186
ffffffffc0202d22:	00003517          	auipc	a0,0x3
ffffffffc0202d26:	ac650513          	add	a0,a0,-1338 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202d2a:	e36fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202d2e:	00003697          	auipc	a3,0x3
ffffffffc0202d32:	caa68693          	add	a3,a3,-854 # ffffffffc02059d8 <etext+0x14ee>
ffffffffc0202d36:	00002617          	auipc	a2,0x2
ffffffffc0202d3a:	09260613          	add	a2,a2,146 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202d3e:	0fa00593          	li	a1,250
ffffffffc0202d42:	00003517          	auipc	a0,0x3
ffffffffc0202d46:	aa650513          	add	a0,a0,-1370 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202d4a:	e16fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202d4e:	00002617          	auipc	a2,0x2
ffffffffc0202d52:	45a60613          	add	a2,a2,1114 # ffffffffc02051a8 <etext+0xcbe>
ffffffffc0202d56:	07000593          	li	a1,112
ffffffffc0202d5a:	00002517          	auipc	a0,0x2
ffffffffc0202d5e:	43e50513          	add	a0,a0,1086 # ffffffffc0205198 <etext+0xcae>
ffffffffc0202d62:	dfefd0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202d66:	00002617          	auipc	a2,0x2
ffffffffc0202d6a:	41260613          	add	a2,a2,1042 # ffffffffc0205178 <etext+0xc8e>
ffffffffc0202d6e:	06500593          	li	a1,101
ffffffffc0202d72:	00002517          	auipc	a0,0x2
ffffffffc0202d76:	42650513          	add	a0,a0,1062 # ffffffffc0205198 <etext+0xcae>
ffffffffc0202d7a:	de6fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202d7e:	00003697          	auipc	a3,0x3
ffffffffc0202d82:	b9268693          	add	a3,a3,-1134 # ffffffffc0205910 <etext+0x1426>
ffffffffc0202d86:	00002617          	auipc	a2,0x2
ffffffffc0202d8a:	04260613          	add	a2,a2,66 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202d8e:	0db00593          	li	a1,219
ffffffffc0202d92:	00003517          	auipc	a0,0x3
ffffffffc0202d96:	a5650513          	add	a0,a0,-1450 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202d9a:	dc6fd0ef          	jal	ffffffffc0200360 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202d9e:	00003697          	auipc	a3,0x3
ffffffffc0202da2:	b5a68693          	add	a3,a3,-1190 # ffffffffc02058f8 <etext+0x140e>
ffffffffc0202da6:	00002617          	auipc	a2,0x2
ffffffffc0202daa:	02260613          	add	a2,a2,34 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202dae:	0da00593          	li	a1,218
ffffffffc0202db2:	00003517          	auipc	a0,0x3
ffffffffc0202db6:	a3650513          	add	a0,a0,-1482 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202dba:	da6fd0ef          	jal	ffffffffc0200360 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202dbe:	00003617          	auipc	a2,0x3
ffffffffc0202dc2:	a0a60613          	add	a2,a2,-1526 # ffffffffc02057c8 <etext+0x12de>
ffffffffc0202dc6:	02700593          	li	a1,39
ffffffffc0202dca:	00003517          	auipc	a0,0x3
ffffffffc0202dce:	a1e50513          	add	a0,a0,-1506 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202dd2:	e922                	sd	s0,144(sp)
ffffffffc0202dd4:	e526                	sd	s1,136(sp)
ffffffffc0202dd6:	e14a                	sd	s2,128(sp)
ffffffffc0202dd8:	fcce                	sd	s3,120(sp)
ffffffffc0202dda:	f8d2                	sd	s4,112(sp)
ffffffffc0202ddc:	f4d6                	sd	s5,104(sp)
ffffffffc0202dde:	f0da                	sd	s6,96(sp)
ffffffffc0202de0:	ecde                	sd	s7,88(sp)
ffffffffc0202de2:	e8e2                	sd	s8,80(sp)
ffffffffc0202de4:	e4e6                	sd	s9,72(sp)
ffffffffc0202de6:	e0ea                	sd	s10,64(sp)
ffffffffc0202de8:	fc6e                	sd	s11,56(sp)
ffffffffc0202dea:	d76fd0ef          	jal	ffffffffc0200360 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202dee:	00003697          	auipc	a3,0x3
ffffffffc0202df2:	bd268693          	add	a3,a3,-1070 # ffffffffc02059c0 <etext+0x14d6>
ffffffffc0202df6:	00002617          	auipc	a2,0x2
ffffffffc0202dfa:	fd260613          	add	a2,a2,-46 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202dfe:	0f900593          	li	a1,249
ffffffffc0202e02:	00003517          	auipc	a0,0x3
ffffffffc0202e06:	9e650513          	add	a0,a0,-1562 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202e0a:	d56fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202e0e:	00003697          	auipc	a3,0x3
ffffffffc0202e12:	ba268693          	add	a3,a3,-1118 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc0202e16:	00002617          	auipc	a2,0x2
ffffffffc0202e1a:	fb260613          	add	a2,a2,-78 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202e1e:	09d00593          	li	a1,157
ffffffffc0202e22:	00003517          	auipc	a0,0x3
ffffffffc0202e26:	9c650513          	add	a0,a0,-1594 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202e2a:	d36fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==4);
ffffffffc0202e2e:	00003697          	auipc	a3,0x3
ffffffffc0202e32:	b8268693          	add	a3,a3,-1150 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc0202e36:	00002617          	auipc	a2,0x2
ffffffffc0202e3a:	f9260613          	add	a2,a2,-110 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202e3e:	09f00593          	li	a1,159
ffffffffc0202e42:	00003517          	auipc	a0,0x3
ffffffffc0202e46:	9a650513          	add	a0,a0,-1626 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202e4a:	d16fd0ef          	jal	ffffffffc0200360 <__panic>
     assert( nr_free == 0);         
ffffffffc0202e4e:	00002697          	auipc	a3,0x2
ffffffffc0202e52:	15268693          	add	a3,a3,338 # ffffffffc0204fa0 <etext+0xab6>
ffffffffc0202e56:	00002617          	auipc	a2,0x2
ffffffffc0202e5a:	f7260613          	add	a2,a2,-142 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202e5e:	0f100593          	li	a1,241
ffffffffc0202e62:	00003517          	auipc	a0,0x3
ffffffffc0202e66:	98650513          	add	a0,a0,-1658 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202e6a:	cf6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(ret==0);
ffffffffc0202e6e:	00003697          	auipc	a3,0x3
ffffffffc0202e72:	bba68693          	add	a3,a3,-1094 # ffffffffc0205a28 <etext+0x153e>
ffffffffc0202e76:	00002617          	auipc	a2,0x2
ffffffffc0202e7a:	f5260613          	add	a2,a2,-174 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202e7e:	10000593          	li	a1,256
ffffffffc0202e82:	00003517          	auipc	a0,0x3
ffffffffc0202e86:	96650513          	add	a0,a0,-1690 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202e8a:	cd6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202e8e:	00003697          	auipc	a3,0x3
ffffffffc0202e92:	9d268693          	add	a3,a3,-1582 # ffffffffc0205860 <etext+0x1376>
ffffffffc0202e96:	00002617          	auipc	a2,0x2
ffffffffc0202e9a:	f3260613          	add	a2,a2,-206 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202e9e:	0ca00593          	li	a1,202
ffffffffc0202ea2:	00003517          	auipc	a0,0x3
ffffffffc0202ea6:	94650513          	add	a0,a0,-1722 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202eaa:	cb6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(vma != NULL);
ffffffffc0202eae:	00003697          	auipc	a3,0x3
ffffffffc0202eb2:	9c268693          	add	a3,a3,-1598 # ffffffffc0205870 <etext+0x1386>
ffffffffc0202eb6:	00002617          	auipc	a2,0x2
ffffffffc0202eba:	f1260613          	add	a2,a2,-238 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202ebe:	0cd00593          	li	a1,205
ffffffffc0202ec2:	00003517          	auipc	a0,0x3
ffffffffc0202ec6:	92650513          	add	a0,a0,-1754 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202eca:	c96fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202ece:	00003697          	auipc	a3,0x3
ffffffffc0202ed2:	9ea68693          	add	a3,a3,-1558 # ffffffffc02058b8 <etext+0x13ce>
ffffffffc0202ed6:	00002617          	auipc	a2,0x2
ffffffffc0202eda:	ef260613          	add	a2,a2,-270 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202ede:	0d500593          	li	a1,213
ffffffffc0202ee2:	00003517          	auipc	a0,0x3
ffffffffc0202ee6:	90650513          	add	a0,a0,-1786 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202eea:	c76fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202eee:	00002697          	auipc	a3,0x2
ffffffffc0202ef2:	f0a68693          	add	a3,a3,-246 # ffffffffc0204df8 <etext+0x90e>
ffffffffc0202ef6:	00002617          	auipc	a2,0x2
ffffffffc0202efa:	ed260613          	add	a2,a2,-302 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202efe:	0bd00593          	li	a1,189
ffffffffc0202f02:	00003517          	auipc	a0,0x3
ffffffffc0202f06:	8e650513          	add	a0,a0,-1818 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202f0a:	c56fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202f0e:	00003697          	auipc	a3,0x3
ffffffffc0202f12:	a8268693          	add	a3,a3,-1406 # ffffffffc0205990 <etext+0x14a6>
ffffffffc0202f16:	00002617          	auipc	a2,0x2
ffffffffc0202f1a:	eb260613          	add	a2,a2,-334 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202f1e:	09500593          	li	a1,149
ffffffffc0202f22:	00003517          	auipc	a0,0x3
ffffffffc0202f26:	8c650513          	add	a0,a0,-1850 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202f2a:	c36fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==2);
ffffffffc0202f2e:	00003697          	auipc	a3,0x3
ffffffffc0202f32:	a6268693          	add	a3,a3,-1438 # ffffffffc0205990 <etext+0x14a6>
ffffffffc0202f36:	00002617          	auipc	a2,0x2
ffffffffc0202f3a:	e9260613          	add	a2,a2,-366 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202f3e:	09700593          	li	a1,151
ffffffffc0202f42:	00003517          	auipc	a0,0x3
ffffffffc0202f46:	8a650513          	add	a0,a0,-1882 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202f4a:	c16fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202f4e:	00003697          	auipc	a3,0x3
ffffffffc0202f52:	a5268693          	add	a3,a3,-1454 # ffffffffc02059a0 <etext+0x14b6>
ffffffffc0202f56:	00002617          	auipc	a2,0x2
ffffffffc0202f5a:	e7260613          	add	a2,a2,-398 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202f5e:	09900593          	li	a1,153
ffffffffc0202f62:	00003517          	auipc	a0,0x3
ffffffffc0202f66:	88650513          	add	a0,a0,-1914 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202f6a:	bf6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==3);
ffffffffc0202f6e:	00003697          	auipc	a3,0x3
ffffffffc0202f72:	a3268693          	add	a3,a3,-1486 # ffffffffc02059a0 <etext+0x14b6>
ffffffffc0202f76:	00002617          	auipc	a2,0x2
ffffffffc0202f7a:	e5260613          	add	a2,a2,-430 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202f7e:	09b00593          	li	a1,155
ffffffffc0202f82:	00003517          	auipc	a0,0x3
ffffffffc0202f86:	86650513          	add	a0,a0,-1946 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202f8a:	bd6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202f8e:	00003697          	auipc	a3,0x3
ffffffffc0202f92:	9f268693          	add	a3,a3,-1550 # ffffffffc0205980 <etext+0x1496>
ffffffffc0202f96:	00002617          	auipc	a2,0x2
ffffffffc0202f9a:	e3260613          	add	a2,a2,-462 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202f9e:	09100593          	li	a1,145
ffffffffc0202fa2:	00003517          	auipc	a0,0x3
ffffffffc0202fa6:	84650513          	add	a0,a0,-1978 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202faa:	bb6fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(pgfault_num==1);
ffffffffc0202fae:	00003697          	auipc	a3,0x3
ffffffffc0202fb2:	9d268693          	add	a3,a3,-1582 # ffffffffc0205980 <etext+0x1496>
ffffffffc0202fb6:	00002617          	auipc	a2,0x2
ffffffffc0202fba:	e1260613          	add	a2,a2,-494 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202fbe:	09300593          	li	a1,147
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	82650513          	add	a0,a0,-2010 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202fca:	b96fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(mm != NULL);
ffffffffc0202fce:	00003697          	auipc	a3,0x3
ffffffffc0202fd2:	86a68693          	add	a3,a3,-1942 # ffffffffc0205838 <etext+0x134e>
ffffffffc0202fd6:	00002617          	auipc	a2,0x2
ffffffffc0202fda:	df260613          	add	a2,a2,-526 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202fde:	0c200593          	li	a1,194
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	80650513          	add	a0,a0,-2042 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0202fea:	b76fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202fee:	00003697          	auipc	a3,0x3
ffffffffc0202ff2:	85a68693          	add	a3,a3,-1958 # ffffffffc0205848 <etext+0x135e>
ffffffffc0202ff6:	00002617          	auipc	a2,0x2
ffffffffc0202ffa:	dd260613          	add	a2,a2,-558 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0202ffe:	0c500593          	li	a1,197
ffffffffc0203002:	00002517          	auipc	a0,0x2
ffffffffc0203006:	7e650513          	add	a0,a0,2022 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc020300a:	b56fd0ef          	jal	ffffffffc0200360 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020300e:	00003697          	auipc	a3,0x3
ffffffffc0203012:	92268693          	add	a3,a3,-1758 # ffffffffc0205930 <etext+0x1446>
ffffffffc0203016:	00002617          	auipc	a2,0x2
ffffffffc020301a:	db260613          	add	a2,a2,-590 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020301e:	0e800593          	li	a1,232
ffffffffc0203022:	00002517          	auipc	a0,0x2
ffffffffc0203026:	7c650513          	add	a0,a0,1990 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc020302a:	b36fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020302e <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020302e:	0000e797          	auipc	a5,0xe
ffffffffc0203032:	5227b783          	ld	a5,1314(a5) # ffffffffc0211550 <sm>
ffffffffc0203036:	6b9c                	ld	a5,16(a5)
ffffffffc0203038:	8782                	jr	a5

ffffffffc020303a <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020303a:	0000e797          	auipc	a5,0xe
ffffffffc020303e:	5167b783          	ld	a5,1302(a5) # ffffffffc0211550 <sm>
ffffffffc0203042:	739c                	ld	a5,32(a5)
ffffffffc0203044:	8782                	jr	a5

ffffffffc0203046 <swap_out>:
{
ffffffffc0203046:	711d                	add	sp,sp,-96
ffffffffc0203048:	ec86                	sd	ra,88(sp)
ffffffffc020304a:	e8a2                	sd	s0,80(sp)
     for (i = 0; i != n; ++ i)
ffffffffc020304c:	0e058663          	beqz	a1,ffffffffc0203138 <swap_out+0xf2>
ffffffffc0203050:	e0ca                	sd	s2,64(sp)
ffffffffc0203052:	fc4e                	sd	s3,56(sp)
ffffffffc0203054:	f852                	sd	s4,48(sp)
ffffffffc0203056:	f456                	sd	s5,40(sp)
ffffffffc0203058:	f05a                	sd	s6,32(sp)
ffffffffc020305a:	ec5e                	sd	s7,24(sp)
ffffffffc020305c:	e4a6                	sd	s1,72(sp)
ffffffffc020305e:	e862                	sd	s8,16(sp)
ffffffffc0203060:	8a2e                	mv	s4,a1
ffffffffc0203062:	892a                	mv	s2,a0
ffffffffc0203064:	8ab2                	mv	s5,a2
ffffffffc0203066:	4401                	li	s0,0
ffffffffc0203068:	0000e997          	auipc	s3,0xe
ffffffffc020306c:	4e898993          	add	s3,s3,1256 # ffffffffc0211550 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203070:	00003b17          	auipc	s6,0x3
ffffffffc0203074:	a60b0b13          	add	s6,s6,-1440 # ffffffffc0205ad0 <etext+0x15e6>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203078:	00003b97          	auipc	s7,0x3
ffffffffc020307c:	a40b8b93          	add	s7,s7,-1472 # ffffffffc0205ab8 <etext+0x15ce>
ffffffffc0203080:	a825                	j	ffffffffc02030b8 <swap_out+0x72>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203082:	67a2                	ld	a5,8(sp)
ffffffffc0203084:	8626                	mv	a2,s1
ffffffffc0203086:	85a2                	mv	a1,s0
ffffffffc0203088:	63b4                	ld	a3,64(a5)
ffffffffc020308a:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc020308c:	2405                	addw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020308e:	82b1                	srl	a3,a3,0xc
ffffffffc0203090:	0685                	add	a3,a3,1
ffffffffc0203092:	828fd0ef          	jal	ffffffffc02000ba <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203096:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203098:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020309a:	613c                	ld	a5,64(a0)
ffffffffc020309c:	83b1                	srl	a5,a5,0xc
ffffffffc020309e:	0785                	add	a5,a5,1
ffffffffc02030a0:	07a2                	sll	a5,a5,0x8
ffffffffc02030a2:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc02030a6:	dacfe0ef          	jal	ffffffffc0201652 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc02030aa:	01893503          	ld	a0,24(s2)
ffffffffc02030ae:	85a6                	mv	a1,s1
ffffffffc02030b0:	e7aff0ef          	jal	ffffffffc020272a <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02030b4:	048a0d63          	beq	s4,s0,ffffffffc020310e <swap_out+0xc8>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02030b8:	0009b783          	ld	a5,0(s3)
ffffffffc02030bc:	8656                	mv	a2,s5
ffffffffc02030be:	002c                	add	a1,sp,8
ffffffffc02030c0:	7b9c                	ld	a5,48(a5)
ffffffffc02030c2:	854a                	mv	a0,s2
ffffffffc02030c4:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02030c6:	e12d                	bnez	a0,ffffffffc0203128 <swap_out+0xe2>
          v=page->pra_vaddr; 
ffffffffc02030c8:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02030ca:	01893503          	ld	a0,24(s2)
ffffffffc02030ce:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02030d0:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02030d2:	85a6                	mv	a1,s1
ffffffffc02030d4:	df8fe0ef          	jal	ffffffffc02016cc <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02030d8:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02030da:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02030dc:	8b85                	and	a5,a5,1
ffffffffc02030de:	cfb9                	beqz	a5,ffffffffc020313c <swap_out+0xf6>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02030e0:	65a2                	ld	a1,8(sp)
ffffffffc02030e2:	61bc                	ld	a5,64(a1)
ffffffffc02030e4:	83b1                	srl	a5,a5,0xc
ffffffffc02030e6:	0785                	add	a5,a5,1
ffffffffc02030e8:	00879513          	sll	a0,a5,0x8
ffffffffc02030ec:	5f7000ef          	jal	ffffffffc0203ee2 <swapfs_write>
ffffffffc02030f0:	d949                	beqz	a0,ffffffffc0203082 <swap_out+0x3c>
                    cprintf("SWAP: failed to save\n");
ffffffffc02030f2:	855e                	mv	a0,s7
ffffffffc02030f4:	fc7fc0ef          	jal	ffffffffc02000ba <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02030f8:	0009b783          	ld	a5,0(s3)
ffffffffc02030fc:	6622                	ld	a2,8(sp)
ffffffffc02030fe:	4681                	li	a3,0
ffffffffc0203100:	739c                	ld	a5,32(a5)
ffffffffc0203102:	85a6                	mv	a1,s1
ffffffffc0203104:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203106:	2405                	addw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203108:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020310a:	fa8a17e3          	bne	s4,s0,ffffffffc02030b8 <swap_out+0x72>
ffffffffc020310e:	64a6                	ld	s1,72(sp)
ffffffffc0203110:	6906                	ld	s2,64(sp)
ffffffffc0203112:	79e2                	ld	s3,56(sp)
ffffffffc0203114:	7a42                	ld	s4,48(sp)
ffffffffc0203116:	7aa2                	ld	s5,40(sp)
ffffffffc0203118:	7b02                	ld	s6,32(sp)
ffffffffc020311a:	6be2                	ld	s7,24(sp)
ffffffffc020311c:	6c42                	ld	s8,16(sp)
}
ffffffffc020311e:	60e6                	ld	ra,88(sp)
ffffffffc0203120:	8522                	mv	a0,s0
ffffffffc0203122:	6446                	ld	s0,80(sp)
ffffffffc0203124:	6125                	add	sp,sp,96
ffffffffc0203126:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203128:	85a2                	mv	a1,s0
ffffffffc020312a:	00003517          	auipc	a0,0x3
ffffffffc020312e:	94650513          	add	a0,a0,-1722 # ffffffffc0205a70 <etext+0x1586>
ffffffffc0203132:	f89fc0ef          	jal	ffffffffc02000ba <cprintf>
                  break;
ffffffffc0203136:	bfe1                	j	ffffffffc020310e <swap_out+0xc8>
     for (i = 0; i != n; ++ i)
ffffffffc0203138:	4401                	li	s0,0
ffffffffc020313a:	b7d5                	j	ffffffffc020311e <swap_out+0xd8>
          assert((*ptep & PTE_V) != 0);
ffffffffc020313c:	00003697          	auipc	a3,0x3
ffffffffc0203140:	96468693          	add	a3,a3,-1692 # ffffffffc0205aa0 <etext+0x15b6>
ffffffffc0203144:	00002617          	auipc	a2,0x2
ffffffffc0203148:	c8460613          	add	a2,a2,-892 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc020314c:	06600593          	li	a1,102
ffffffffc0203150:	00002517          	auipc	a0,0x2
ffffffffc0203154:	69850513          	add	a0,a0,1688 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc0203158:	a08fd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020315c <swap_in>:
{
ffffffffc020315c:	7179                	add	sp,sp,-48
ffffffffc020315e:	e84a                	sd	s2,16(sp)
ffffffffc0203160:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203162:	4505                	li	a0,1
{
ffffffffc0203164:	ec26                	sd	s1,24(sp)
ffffffffc0203166:	e44e                	sd	s3,8(sp)
ffffffffc0203168:	f406                	sd	ra,40(sp)
ffffffffc020316a:	f022                	sd	s0,32(sp)
ffffffffc020316c:	84ae                	mv	s1,a1
ffffffffc020316e:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203170:	c52fe0ef          	jal	ffffffffc02015c2 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203174:	c129                	beqz	a0,ffffffffc02031b6 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203176:	842a                	mv	s0,a0
ffffffffc0203178:	01893503          	ld	a0,24(s2)
ffffffffc020317c:	4601                	li	a2,0
ffffffffc020317e:	85a6                	mv	a1,s1
ffffffffc0203180:	d4cfe0ef          	jal	ffffffffc02016cc <get_pte>
ffffffffc0203184:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203186:	6108                	ld	a0,0(a0)
ffffffffc0203188:	85a2                	mv	a1,s0
ffffffffc020318a:	4ad000ef          	jal	ffffffffc0203e36 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc020318e:	00093583          	ld	a1,0(s2)
ffffffffc0203192:	8626                	mv	a2,s1
ffffffffc0203194:	00003517          	auipc	a0,0x3
ffffffffc0203198:	98c50513          	add	a0,a0,-1652 # ffffffffc0205b20 <etext+0x1636>
ffffffffc020319c:	81a1                	srl	a1,a1,0x8
ffffffffc020319e:	f1dfc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc02031a2:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02031a4:	0089b023          	sd	s0,0(s3)
}
ffffffffc02031a8:	7402                	ld	s0,32(sp)
ffffffffc02031aa:	64e2                	ld	s1,24(sp)
ffffffffc02031ac:	6942                	ld	s2,16(sp)
ffffffffc02031ae:	69a2                	ld	s3,8(sp)
ffffffffc02031b0:	4501                	li	a0,0
ffffffffc02031b2:	6145                	add	sp,sp,48
ffffffffc02031b4:	8082                	ret
     assert(result!=NULL);
ffffffffc02031b6:	00003697          	auipc	a3,0x3
ffffffffc02031ba:	95a68693          	add	a3,a3,-1702 # ffffffffc0205b10 <etext+0x1626>
ffffffffc02031be:	00002617          	auipc	a2,0x2
ffffffffc02031c2:	c0a60613          	add	a2,a2,-1014 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02031c6:	07c00593          	li	a1,124
ffffffffc02031ca:	00002517          	auipc	a0,0x2
ffffffffc02031ce:	61e50513          	add	a0,a0,1566 # ffffffffc02057e8 <etext+0x12fe>
ffffffffc02031d2:	98efd0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc02031d6 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc02031d6:	4501                	li	a0,0
ffffffffc02031d8:	8082                	ret

ffffffffc02031da <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02031da:	4501                	li	a0,0
ffffffffc02031dc:	8082                	ret

ffffffffc02031de <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc02031de:	4501                	li	a0,0
ffffffffc02031e0:	8082                	ret

ffffffffc02031e2 <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc02031e2:	1141                	add	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02031e4:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc02031e6:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc02031e8:	678d                	lui	a5,0x3
ffffffffc02031ea:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc02031ee:	0000e717          	auipc	a4,0xe
ffffffffc02031f2:	37272703          	lw	a4,882(a4) # ffffffffc0211560 <pgfault_num>
ffffffffc02031f6:	4691                	li	a3,4
ffffffffc02031f8:	0ad71663          	bne	a4,a3,ffffffffc02032a4 <_clock_check_swap+0xc2>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02031fc:	6685                	lui	a3,0x1
ffffffffc02031fe:	4629                	li	a2,10
ffffffffc0203200:	00c68023          	sb	a2,0(a3) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203204:	0000e797          	auipc	a5,0xe
ffffffffc0203208:	35c78793          	add	a5,a5,860 # ffffffffc0211560 <pgfault_num>
    assert(pgfault_num==4);
ffffffffc020320c:	4394                	lw	a3,0(a5)
ffffffffc020320e:	0006861b          	sext.w	a2,a3
ffffffffc0203212:	20e69963          	bne	a3,a4,ffffffffc0203424 <_clock_check_swap+0x242>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203216:	6711                	lui	a4,0x4
ffffffffc0203218:	46b5                	li	a3,13
ffffffffc020321a:	00d70023          	sb	a3,0(a4) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc020321e:	4398                	lw	a4,0(a5)
ffffffffc0203220:	0007069b          	sext.w	a3,a4
ffffffffc0203224:	1ec71063          	bne	a4,a2,ffffffffc0203404 <_clock_check_swap+0x222>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203228:	6709                	lui	a4,0x2
ffffffffc020322a:	462d                	li	a2,11
ffffffffc020322c:	00c70023          	sb	a2,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0203230:	4398                	lw	a4,0(a5)
ffffffffc0203232:	1ad71963          	bne	a4,a3,ffffffffc02033e4 <_clock_check_swap+0x202>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203236:	6715                	lui	a4,0x5
ffffffffc0203238:	46b9                	li	a3,14
ffffffffc020323a:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc020323e:	4398                	lw	a4,0(a5)
ffffffffc0203240:	4615                	li	a2,5
ffffffffc0203242:	0007069b          	sext.w	a3,a4
ffffffffc0203246:	16c71f63          	bne	a4,a2,ffffffffc02033c4 <_clock_check_swap+0x1e2>
    assert(pgfault_num==5);
ffffffffc020324a:	4398                	lw	a4,0(a5)
ffffffffc020324c:	0007061b          	sext.w	a2,a4
ffffffffc0203250:	14d71a63          	bne	a4,a3,ffffffffc02033a4 <_clock_check_swap+0x1c2>
    assert(pgfault_num==5);
ffffffffc0203254:	4398                	lw	a4,0(a5)
ffffffffc0203256:	0007069b          	sext.w	a3,a4
ffffffffc020325a:	12c71563          	bne	a4,a2,ffffffffc0203384 <_clock_check_swap+0x1a2>
    assert(pgfault_num==5);
ffffffffc020325e:	4398                	lw	a4,0(a5)
ffffffffc0203260:	0007061b          	sext.w	a2,a4
ffffffffc0203264:	10d71063          	bne	a4,a3,ffffffffc0203364 <_clock_check_swap+0x182>
    assert(pgfault_num==5);
ffffffffc0203268:	4398                	lw	a4,0(a5)
ffffffffc020326a:	0007069b          	sext.w	a3,a4
ffffffffc020326e:	0cc71b63          	bne	a4,a2,ffffffffc0203344 <_clock_check_swap+0x162>
    assert(pgfault_num==5);
ffffffffc0203272:	4398                	lw	a4,0(a5)
ffffffffc0203274:	0ad71863          	bne	a4,a3,ffffffffc0203324 <_clock_check_swap+0x142>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203278:	6715                	lui	a4,0x5
ffffffffc020327a:	46b9                	li	a3,14
ffffffffc020327c:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0203280:	4394                	lw	a3,0(a5)
ffffffffc0203282:	4715                	li	a4,5
ffffffffc0203284:	08e69063          	bne	a3,a4,ffffffffc0203304 <_clock_check_swap+0x122>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203288:	6705                	lui	a4,0x1
ffffffffc020328a:	00074683          	lbu	a3,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020328e:	4729                	li	a4,10
ffffffffc0203290:	04e69a63          	bne	a3,a4,ffffffffc02032e4 <_clock_check_swap+0x102>
    assert(pgfault_num==6);
ffffffffc0203294:	4398                	lw	a4,0(a5)
ffffffffc0203296:	4799                	li	a5,6
ffffffffc0203298:	02f71663          	bne	a4,a5,ffffffffc02032c4 <_clock_check_swap+0xe2>
}
ffffffffc020329c:	60a2                	ld	ra,8(sp)
ffffffffc020329e:	4501                	li	a0,0
ffffffffc02032a0:	0141                	add	sp,sp,16
ffffffffc02032a2:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02032a4:	00002697          	auipc	a3,0x2
ffffffffc02032a8:	70c68693          	add	a3,a3,1804 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc02032ac:	00002617          	auipc	a2,0x2
ffffffffc02032b0:	b1c60613          	add	a2,a2,-1252 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02032b4:	08e00593          	li	a1,142
ffffffffc02032b8:	00003517          	auipc	a0,0x3
ffffffffc02032bc:	8a850513          	add	a0,a0,-1880 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02032c0:	8a0fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==6);
ffffffffc02032c4:	00003697          	auipc	a3,0x3
ffffffffc02032c8:	8ec68693          	add	a3,a3,-1812 # ffffffffc0205bb0 <etext+0x16c6>
ffffffffc02032cc:	00002617          	auipc	a2,0x2
ffffffffc02032d0:	afc60613          	add	a2,a2,-1284 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02032d4:	0a500593          	li	a1,165
ffffffffc02032d8:	00003517          	auipc	a0,0x3
ffffffffc02032dc:	88850513          	add	a0,a0,-1912 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02032e0:	880fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02032e4:	00003697          	auipc	a3,0x3
ffffffffc02032e8:	8a468693          	add	a3,a3,-1884 # ffffffffc0205b88 <etext+0x169e>
ffffffffc02032ec:	00002617          	auipc	a2,0x2
ffffffffc02032f0:	adc60613          	add	a2,a2,-1316 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02032f4:	0a300593          	li	a1,163
ffffffffc02032f8:	00003517          	auipc	a0,0x3
ffffffffc02032fc:	86850513          	add	a0,a0,-1944 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203300:	860fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203304:	00003697          	auipc	a3,0x3
ffffffffc0203308:	87468693          	add	a3,a3,-1932 # ffffffffc0205b78 <etext+0x168e>
ffffffffc020330c:	00002617          	auipc	a2,0x2
ffffffffc0203310:	abc60613          	add	a2,a2,-1348 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203314:	0a200593          	li	a1,162
ffffffffc0203318:	00003517          	auipc	a0,0x3
ffffffffc020331c:	84850513          	add	a0,a0,-1976 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203320:	840fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203324:	00003697          	auipc	a3,0x3
ffffffffc0203328:	85468693          	add	a3,a3,-1964 # ffffffffc0205b78 <etext+0x168e>
ffffffffc020332c:	00002617          	auipc	a2,0x2
ffffffffc0203330:	a9c60613          	add	a2,a2,-1380 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203334:	0a000593          	li	a1,160
ffffffffc0203338:	00003517          	auipc	a0,0x3
ffffffffc020333c:	82850513          	add	a0,a0,-2008 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203340:	820fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203344:	00003697          	auipc	a3,0x3
ffffffffc0203348:	83468693          	add	a3,a3,-1996 # ffffffffc0205b78 <etext+0x168e>
ffffffffc020334c:	00002617          	auipc	a2,0x2
ffffffffc0203350:	a7c60613          	add	a2,a2,-1412 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203354:	09e00593          	li	a1,158
ffffffffc0203358:	00003517          	auipc	a0,0x3
ffffffffc020335c:	80850513          	add	a0,a0,-2040 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203360:	800fd0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203364:	00003697          	auipc	a3,0x3
ffffffffc0203368:	81468693          	add	a3,a3,-2028 # ffffffffc0205b78 <etext+0x168e>
ffffffffc020336c:	00002617          	auipc	a2,0x2
ffffffffc0203370:	a5c60613          	add	a2,a2,-1444 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203374:	09c00593          	li	a1,156
ffffffffc0203378:	00002517          	auipc	a0,0x2
ffffffffc020337c:	7e850513          	add	a0,a0,2024 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203380:	fe1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc0203384:	00002697          	auipc	a3,0x2
ffffffffc0203388:	7f468693          	add	a3,a3,2036 # ffffffffc0205b78 <etext+0x168e>
ffffffffc020338c:	00002617          	auipc	a2,0x2
ffffffffc0203390:	a3c60613          	add	a2,a2,-1476 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203394:	09a00593          	li	a1,154
ffffffffc0203398:	00002517          	auipc	a0,0x2
ffffffffc020339c:	7c850513          	add	a0,a0,1992 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02033a0:	fc1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02033a4:	00002697          	auipc	a3,0x2
ffffffffc02033a8:	7d468693          	add	a3,a3,2004 # ffffffffc0205b78 <etext+0x168e>
ffffffffc02033ac:	00002617          	auipc	a2,0x2
ffffffffc02033b0:	a1c60613          	add	a2,a2,-1508 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02033b4:	09800593          	li	a1,152
ffffffffc02033b8:	00002517          	auipc	a0,0x2
ffffffffc02033bc:	7a850513          	add	a0,a0,1960 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02033c0:	fa1fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==5);
ffffffffc02033c4:	00002697          	auipc	a3,0x2
ffffffffc02033c8:	7b468693          	add	a3,a3,1972 # ffffffffc0205b78 <etext+0x168e>
ffffffffc02033cc:	00002617          	auipc	a2,0x2
ffffffffc02033d0:	9fc60613          	add	a2,a2,-1540 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02033d4:	09600593          	li	a1,150
ffffffffc02033d8:	00002517          	auipc	a0,0x2
ffffffffc02033dc:	78850513          	add	a0,a0,1928 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02033e0:	f81fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc02033e4:	00002697          	auipc	a3,0x2
ffffffffc02033e8:	5cc68693          	add	a3,a3,1484 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc02033ec:	00002617          	auipc	a2,0x2
ffffffffc02033f0:	9dc60613          	add	a2,a2,-1572 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02033f4:	09400593          	li	a1,148
ffffffffc02033f8:	00002517          	auipc	a0,0x2
ffffffffc02033fc:	76850513          	add	a0,a0,1896 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203400:	f61fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc0203404:	00002697          	auipc	a3,0x2
ffffffffc0203408:	5ac68693          	add	a3,a3,1452 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc020340c:	00002617          	auipc	a2,0x2
ffffffffc0203410:	9bc60613          	add	a2,a2,-1604 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203414:	09200593          	li	a1,146
ffffffffc0203418:	00002517          	auipc	a0,0x2
ffffffffc020341c:	74850513          	add	a0,a0,1864 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203420:	f41fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgfault_num==4);
ffffffffc0203424:	00002697          	auipc	a3,0x2
ffffffffc0203428:	58c68693          	add	a3,a3,1420 # ffffffffc02059b0 <etext+0x14c6>
ffffffffc020342c:	00002617          	auipc	a2,0x2
ffffffffc0203430:	99c60613          	add	a2,a2,-1636 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203434:	09000593          	li	a1,144
ffffffffc0203438:	00002517          	auipc	a0,0x2
ffffffffc020343c:	72850513          	add	a0,a0,1832 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203440:	f21fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203444 <_clock_init_mm>:
{     
ffffffffc0203444:	1141                	add	sp,sp,-16
ffffffffc0203446:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0203448:	0000e797          	auipc	a5,0xe
ffffffffc020344c:	ca078793          	add	a5,a5,-864 # ffffffffc02110e8 <pra_list_head>
     mm->sm_priv = &pra_list_head;
ffffffffc0203450:	f51c                	sd	a5,40(a0)
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc0203452:	85be                	mv	a1,a5
ffffffffc0203454:	00002517          	auipc	a0,0x2
ffffffffc0203458:	76c50513          	add	a0,a0,1900 # ffffffffc0205bc0 <etext+0x16d6>
ffffffffc020345c:	e79c                	sd	a5,8(a5)
ffffffffc020345e:	e39c                	sd	a5,0(a5)
     curr_ptr = &pra_list_head;
ffffffffc0203460:	0000e717          	auipc	a4,0xe
ffffffffc0203464:	0ef73c23          	sd	a5,248(a4) # ffffffffc0211558 <curr_ptr>
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
ffffffffc0203468:	c53fc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc020346c:	60a2                	ld	ra,8(sp)
ffffffffc020346e:	4501                	li	a0,0
ffffffffc0203470:	0141                	add	sp,sp,16
ffffffffc0203472:	8082                	ret

ffffffffc0203474 <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203474:	751c                	ld	a5,40(a0)
{
ffffffffc0203476:	1141                	add	sp,sp,-16
ffffffffc0203478:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020347a:	cba5                	beqz	a5,ffffffffc02034ea <_clock_swap_out_victim+0x76>
     assert(in_tick==0);
ffffffffc020347c:	e639                	bnez	a2,ffffffffc02034ca <_clock_swap_out_victim+0x56>
    return listelm->prev;
ffffffffc020347e:	639c                	ld	a5,0(a5)
        curr_ptr = list_prev(curr_ptr);
ffffffffc0203480:	0000e517          	auipc	a0,0xe
ffffffffc0203484:	0d850513          	add	a0,a0,216 # ffffffffc0211558 <curr_ptr>
ffffffffc0203488:	e11c                	sd	a5,0(a0)
        if (!curr_ptr) {
ffffffffc020348a:	c785                	beqz	a5,ffffffffc02034b2 <_clock_swap_out_victim+0x3e>
ffffffffc020348c:	4601                	li	a2,0
ffffffffc020348e:	a029                	j	ffffffffc0203498 <_clock_swap_out_victim+0x24>
            p->visited = 0;  // 标记页面为未访问
ffffffffc0203490:	fe073023          	sd	zero,-32(a4)
        if (!curr_ptr) {
ffffffffc0203494:	4605                	li	a2,1
ffffffffc0203496:	c395                	beqz	a5,ffffffffc02034ba <_clock_swap_out_victim+0x46>
        if (p->visited == 0) {
ffffffffc0203498:	fe07b683          	ld	a3,-32(a5)
ffffffffc020349c:	873e                	mv	a4,a5
ffffffffc020349e:	639c                	ld	a5,0(a5)
ffffffffc02034a0:	fae5                	bnez	a3,ffffffffc0203490 <_clock_swap_out_victim+0x1c>
ffffffffc02034a2:	c211                	beqz	a2,ffffffffc02034a6 <_clock_swap_out_victim+0x32>
ffffffffc02034a4:	e118                	sd	a4,0(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02034a6:	6714                	ld	a3,8(a4)
            *ptr_page = le2page(curr_ptr, pra_page_link);
ffffffffc02034a8:	fd070713          	add	a4,a4,-48
    prev->next = next;
ffffffffc02034ac:	e794                	sd	a3,8(a5)
    next->prev = prev;
ffffffffc02034ae:	e29c                	sd	a5,0(a3)
ffffffffc02034b0:	e198                	sd	a4,0(a1)
}
ffffffffc02034b2:	60a2                	ld	ra,8(sp)
ffffffffc02034b4:	4501                	li	a0,0
ffffffffc02034b6:	0141                	add	sp,sp,16
ffffffffc02034b8:	8082                	ret
ffffffffc02034ba:	60a2                	ld	ra,8(sp)
ffffffffc02034bc:	0000e797          	auipc	a5,0xe
ffffffffc02034c0:	0807be23          	sd	zero,156(a5) # ffffffffc0211558 <curr_ptr>
ffffffffc02034c4:	4501                	li	a0,0
ffffffffc02034c6:	0141                	add	sp,sp,16
ffffffffc02034c8:	8082                	ret
     assert(in_tick==0);
ffffffffc02034ca:	00002697          	auipc	a3,0x2
ffffffffc02034ce:	72e68693          	add	a3,a3,1838 # ffffffffc0205bf8 <etext+0x170e>
ffffffffc02034d2:	00002617          	auipc	a2,0x2
ffffffffc02034d6:	8f660613          	add	a2,a2,-1802 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02034da:	04c00593          	li	a1,76
ffffffffc02034de:	00002517          	auipc	a0,0x2
ffffffffc02034e2:	68250513          	add	a0,a0,1666 # ffffffffc0205b60 <etext+0x1676>
ffffffffc02034e6:	e7bfc0ef          	jal	ffffffffc0200360 <__panic>
         assert(head != NULL);
ffffffffc02034ea:	00002697          	auipc	a3,0x2
ffffffffc02034ee:	6fe68693          	add	a3,a3,1790 # ffffffffc0205be8 <etext+0x16fe>
ffffffffc02034f2:	00002617          	auipc	a2,0x2
ffffffffc02034f6:	8d660613          	add	a2,a2,-1834 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02034fa:	04b00593          	li	a1,75
ffffffffc02034fe:	00002517          	auipc	a0,0x2
ffffffffc0203502:	66250513          	add	a0,a0,1634 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203506:	e5bfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020350a <_clock_map_swappable>:
{
ffffffffc020350a:	1141                	add	sp,sp,-16
ffffffffc020350c:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020350e:	0000e597          	auipc	a1,0xe
ffffffffc0203512:	04a5b583          	ld	a1,74(a1) # ffffffffc0211558 <curr_ptr>
ffffffffc0203516:	c985                	beqz	a1,ffffffffc0203546 <_clock_map_swappable+0x3c>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203518:	0000e797          	auipc	a5,0xe
ffffffffc020351c:	bd078793          	add	a5,a5,-1072 # ffffffffc02110e8 <pra_list_head>
ffffffffc0203520:	6794                	ld	a3,8(a5)
ffffffffc0203522:	03060713          	add	a4,a2,48
    cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc0203526:	00002517          	auipc	a0,0x2
ffffffffc020352a:	70a50513          	add	a0,a0,1802 # ffffffffc0205c30 <etext+0x1746>
    prev->next = next->prev = elm;
ffffffffc020352e:	e298                	sd	a4,0(a3)
    elm->next = next;
ffffffffc0203530:	fe14                	sd	a3,56(a2)
    page->visited=1;
ffffffffc0203532:	4685                	li	a3,1
    elm->prev = prev;
ffffffffc0203534:	fa1c                	sd	a5,48(a2)
ffffffffc0203536:	ea14                	sd	a3,16(a2)
    prev->next = next->prev = elm;
ffffffffc0203538:	e798                	sd	a4,8(a5)
    cprintf("curr_ptr %p\n", curr_ptr);
ffffffffc020353a:	b81fc0ef          	jal	ffffffffc02000ba <cprintf>
}
ffffffffc020353e:	60a2                	ld	ra,8(sp)
ffffffffc0203540:	4501                	li	a0,0
ffffffffc0203542:	0141                	add	sp,sp,16
ffffffffc0203544:	8082                	ret
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203546:	00002697          	auipc	a3,0x2
ffffffffc020354a:	6c268693          	add	a3,a3,1730 # ffffffffc0205c08 <etext+0x171e>
ffffffffc020354e:	00002617          	auipc	a2,0x2
ffffffffc0203552:	87a60613          	add	a2,a2,-1926 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203556:	03800593          	li	a1,56
ffffffffc020355a:	00002517          	auipc	a0,0x2
ffffffffc020355e:	60650513          	add	a0,a0,1542 # ffffffffc0205b60 <etext+0x1676>
ffffffffc0203562:	dfffc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203566 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203566:	1141                	add	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203568:	00002697          	auipc	a3,0x2
ffffffffc020356c:	6f068693          	add	a3,a3,1776 # ffffffffc0205c58 <etext+0x176e>
ffffffffc0203570:	00002617          	auipc	a2,0x2
ffffffffc0203574:	85860613          	add	a2,a2,-1960 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203578:	07d00593          	li	a1,125
ffffffffc020357c:	00002517          	auipc	a0,0x2
ffffffffc0203580:	6fc50513          	add	a0,a0,1788 # ffffffffc0205c78 <etext+0x178e>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203584:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203586:	ddbfc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc020358a <mm_create>:
mm_create(void) {
ffffffffc020358a:	1141                	add	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020358c:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0203590:	e022                	sd	s0,0(sp)
ffffffffc0203592:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203594:	a54ff0ef          	jal	ffffffffc02027e8 <kmalloc>
ffffffffc0203598:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020359a:	c105                	beqz	a0,ffffffffc02035ba <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc020359c:	e408                	sd	a0,8(s0)
ffffffffc020359e:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02035a0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02035a4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02035a8:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02035ac:	0000e797          	auipc	a5,0xe
ffffffffc02035b0:	f947a783          	lw	a5,-108(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc02035b4:	eb81                	bnez	a5,ffffffffc02035c4 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc02035b6:	02053423          	sd	zero,40(a0)
}
ffffffffc02035ba:	60a2                	ld	ra,8(sp)
ffffffffc02035bc:	8522                	mv	a0,s0
ffffffffc02035be:	6402                	ld	s0,0(sp)
ffffffffc02035c0:	0141                	add	sp,sp,16
ffffffffc02035c2:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02035c4:	a6bff0ef          	jal	ffffffffc020302e <swap_init_mm>
}
ffffffffc02035c8:	60a2                	ld	ra,8(sp)
ffffffffc02035ca:	8522                	mv	a0,s0
ffffffffc02035cc:	6402                	ld	s0,0(sp)
ffffffffc02035ce:	0141                	add	sp,sp,16
ffffffffc02035d0:	8082                	ret

ffffffffc02035d2 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc02035d2:	1101                	add	sp,sp,-32
ffffffffc02035d4:	e04a                	sd	s2,0(sp)
ffffffffc02035d6:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02035d8:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc02035dc:	e822                	sd	s0,16(sp)
ffffffffc02035de:	e426                	sd	s1,8(sp)
ffffffffc02035e0:	ec06                	sd	ra,24(sp)
ffffffffc02035e2:	84ae                	mv	s1,a1
ffffffffc02035e4:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02035e6:	a02ff0ef          	jal	ffffffffc02027e8 <kmalloc>
    if (vma != NULL) {
ffffffffc02035ea:	c509                	beqz	a0,ffffffffc02035f4 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02035ec:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02035f0:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02035f2:	ed00                	sd	s0,24(a0)
}
ffffffffc02035f4:	60e2                	ld	ra,24(sp)
ffffffffc02035f6:	6442                	ld	s0,16(sp)
ffffffffc02035f8:	64a2                	ld	s1,8(sp)
ffffffffc02035fa:	6902                	ld	s2,0(sp)
ffffffffc02035fc:	6105                	add	sp,sp,32
ffffffffc02035fe:	8082                	ret

ffffffffc0203600 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0203600:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0203602:	c505                	beqz	a0,ffffffffc020362a <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203604:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203606:	c501                	beqz	a0,ffffffffc020360e <find_vma+0xe>
ffffffffc0203608:	651c                	ld	a5,8(a0)
ffffffffc020360a:	02f5f663          	bgeu	a1,a5,ffffffffc0203636 <find_vma+0x36>
    return listelm->next;
ffffffffc020360e:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0203610:	00f68d63          	beq	a3,a5,ffffffffc020362a <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0203614:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203618:	00e5e663          	bltu	a1,a4,ffffffffc0203624 <find_vma+0x24>
ffffffffc020361c:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203620:	00e5e763          	bltu	a1,a4,ffffffffc020362e <find_vma+0x2e>
ffffffffc0203624:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0203626:	fef697e3          	bne	a3,a5,ffffffffc0203614 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc020362a:	4501                	li	a0,0
}
ffffffffc020362c:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc020362e:	fe078513          	add	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203632:	ea88                	sd	a0,16(a3)
ffffffffc0203634:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203636:	691c                	ld	a5,16(a0)
ffffffffc0203638:	fcf5fbe3          	bgeu	a1,a5,ffffffffc020360e <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc020363c:	ea88                	sd	a0,16(a3)
ffffffffc020363e:	8082                	ret

ffffffffc0203640 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203640:	6590                	ld	a2,8(a1)
ffffffffc0203642:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0203646:	1141                	add	sp,sp,-16
ffffffffc0203648:	e406                	sd	ra,8(sp)
ffffffffc020364a:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020364c:	01066763          	bltu	a2,a6,ffffffffc020365a <insert_vma_struct+0x1a>
ffffffffc0203650:	a085                	j	ffffffffc02036b0 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0203652:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203656:	04e66863          	bltu	a2,a4,ffffffffc02036a6 <insert_vma_struct+0x66>
ffffffffc020365a:	86be                	mv	a3,a5
ffffffffc020365c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020365e:	fef51ae3          	bne	a0,a5,ffffffffc0203652 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0203662:	02a68463          	beq	a3,a0,ffffffffc020368a <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203666:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020366a:	fe86b883          	ld	a7,-24(a3)
ffffffffc020366e:	08e8f163          	bgeu	a7,a4,ffffffffc02036f0 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203672:	04e66f63          	bltu	a2,a4,ffffffffc02036d0 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0203676:	00f50a63          	beq	a0,a5,ffffffffc020368a <insert_vma_struct+0x4a>
ffffffffc020367a:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020367e:	05076963          	bltu	a4,a6,ffffffffc02036d0 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203682:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203686:	02c77363          	bgeu	a4,a2,ffffffffc02036ac <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020368a:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020368c:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020368e:	02058613          	add	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203692:	e390                	sd	a2,0(a5)
ffffffffc0203694:	e690                	sd	a2,8(a3)
}
ffffffffc0203696:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203698:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020369a:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc020369c:	0017079b          	addw	a5,a4,1
ffffffffc02036a0:	d11c                	sw	a5,32(a0)
}
ffffffffc02036a2:	0141                	add	sp,sp,16
ffffffffc02036a4:	8082                	ret
    if (le_prev != list) {
ffffffffc02036a6:	fca690e3          	bne	a3,a0,ffffffffc0203666 <insert_vma_struct+0x26>
ffffffffc02036aa:	bfd1                	j	ffffffffc020367e <insert_vma_struct+0x3e>
ffffffffc02036ac:	ebbff0ef          	jal	ffffffffc0203566 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02036b0:	00002697          	auipc	a3,0x2
ffffffffc02036b4:	5d868693          	add	a3,a3,1496 # ffffffffc0205c88 <etext+0x179e>
ffffffffc02036b8:	00001617          	auipc	a2,0x1
ffffffffc02036bc:	71060613          	add	a2,a2,1808 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02036c0:	08400593          	li	a1,132
ffffffffc02036c4:	00002517          	auipc	a0,0x2
ffffffffc02036c8:	5b450513          	add	a0,a0,1460 # ffffffffc0205c78 <etext+0x178e>
ffffffffc02036cc:	c95fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02036d0:	00002697          	auipc	a3,0x2
ffffffffc02036d4:	5f868693          	add	a3,a3,1528 # ffffffffc0205cc8 <etext+0x17de>
ffffffffc02036d8:	00001617          	auipc	a2,0x1
ffffffffc02036dc:	6f060613          	add	a2,a2,1776 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc02036e0:	07c00593          	li	a1,124
ffffffffc02036e4:	00002517          	auipc	a0,0x2
ffffffffc02036e8:	59450513          	add	a0,a0,1428 # ffffffffc0205c78 <etext+0x178e>
ffffffffc02036ec:	c75fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02036f0:	00002697          	auipc	a3,0x2
ffffffffc02036f4:	5b868693          	add	a3,a3,1464 # ffffffffc0205ca8 <etext+0x17be>
ffffffffc02036f8:	00001617          	auipc	a2,0x1
ffffffffc02036fc:	6d060613          	add	a2,a2,1744 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203700:	07b00593          	li	a1,123
ffffffffc0203704:	00002517          	auipc	a0,0x2
ffffffffc0203708:	57450513          	add	a0,a0,1396 # ffffffffc0205c78 <etext+0x178e>
ffffffffc020370c:	c55fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203710 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0203710:	1141                	add	sp,sp,-16
ffffffffc0203712:	e022                	sd	s0,0(sp)
ffffffffc0203714:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203716:	6508                	ld	a0,8(a0)
ffffffffc0203718:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc020371a:	00a40e63          	beq	s0,a0,ffffffffc0203736 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020371e:	6118                	ld	a4,0(a0)
ffffffffc0203720:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203722:	03000593          	li	a1,48
ffffffffc0203726:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc0203728:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020372a:	e398                	sd	a4,0(a5)
ffffffffc020372c:	988ff0ef          	jal	ffffffffc02028b4 <kfree>
    return listelm->next;
ffffffffc0203730:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203732:	fea416e3          	bne	s0,a0,ffffffffc020371e <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203736:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0203738:	6402                	ld	s0,0(sp)
ffffffffc020373a:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc020373c:	03000593          	li	a1,48
}
ffffffffc0203740:	0141                	add	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203742:	972ff06f          	j	ffffffffc02028b4 <kfree>

ffffffffc0203746 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203746:	715d                	add	sp,sp,-80
ffffffffc0203748:	e486                	sd	ra,72(sp)
ffffffffc020374a:	f44e                	sd	s3,40(sp)
ffffffffc020374c:	f052                	sd	s4,32(sp)
ffffffffc020374e:	e0a2                	sd	s0,64(sp)
ffffffffc0203750:	fc26                	sd	s1,56(sp)
ffffffffc0203752:	f84a                	sd	s2,48(sp)
ffffffffc0203754:	ec56                	sd	s5,24(sp)
ffffffffc0203756:	e85a                	sd	s6,16(sp)
ffffffffc0203758:	e45e                	sd	s7,8(sp)
ffffffffc020375a:	e062                	sd	s8,0(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020375c:	f37fd0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc0203760:	89aa                	mv	s3,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203762:	f31fd0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc0203766:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203768:	03000513          	li	a0,48
ffffffffc020376c:	87cff0ef          	jal	ffffffffc02027e8 <kmalloc>
    if (mm != NULL) {
ffffffffc0203770:	30050563          	beqz	a0,ffffffffc0203a7a <vmm_init+0x334>
    elm->prev = elm->next = elm;
ffffffffc0203774:	e508                	sd	a0,8(a0)
ffffffffc0203776:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203778:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020377c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203780:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203784:	0000e797          	auipc	a5,0xe
ffffffffc0203788:	dbc7a783          	lw	a5,-580(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc020378c:	842a                	mv	s0,a0
ffffffffc020378e:	2c079363          	bnez	a5,ffffffffc0203a54 <vmm_init+0x30e>
        else mm->sm_priv = NULL;
ffffffffc0203792:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0203796:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020379a:	03000513          	li	a0,48
ffffffffc020379e:	84aff0ef          	jal	ffffffffc02027e8 <kmalloc>
ffffffffc02037a2:	00248913          	add	s2,s1,2
ffffffffc02037a6:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02037a8:	2a050963          	beqz	a0,ffffffffc0203a5a <vmm_init+0x314>
        vma->vm_start = vm_start;
ffffffffc02037ac:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02037ae:	01253823          	sd	s2,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02037b2:	00053c23          	sd	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc02037b6:	14ed                	add	s1,s1,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02037b8:	8522                	mv	a0,s0
ffffffffc02037ba:	e87ff0ef          	jal	ffffffffc0203640 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02037be:	fcf1                	bnez	s1,ffffffffc020379a <vmm_init+0x54>
ffffffffc02037c0:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02037c4:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02037c8:	03000513          	li	a0,48
ffffffffc02037cc:	81cff0ef          	jal	ffffffffc02027e8 <kmalloc>
ffffffffc02037d0:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02037d2:	2c050463          	beqz	a0,ffffffffc0203a9a <vmm_init+0x354>
        vma->vm_end = vm_end;
ffffffffc02037d6:	00248793          	add	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc02037da:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02037dc:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02037de:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02037e2:	0495                	add	s1,s1,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02037e4:	8522                	mv	a0,s0
ffffffffc02037e6:	e5bff0ef          	jal	ffffffffc0203640 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02037ea:	fd249fe3          	bne	s1,s2,ffffffffc02037c8 <vmm_init+0x82>
    return listelm->next;
ffffffffc02037ee:	00843b03          	ld	s6,8(s0)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc02037f2:	3c8b0b63          	beq	s6,s0,ffffffffc0203bc8 <vmm_init+0x482>
    list_entry_t *le = list_next(&(mm->mmap_list));
ffffffffc02037f6:	87da                	mv	a5,s6
        assert(le != &(mm->mmap_list));
ffffffffc02037f8:	4715                	li	a4,5
    for (i = 1; i <= step2; i ++) {
ffffffffc02037fa:	1f400593          	li	a1,500
ffffffffc02037fe:	a021                	j	ffffffffc0203806 <vmm_init+0xc0>
        assert(le != &(mm->mmap_list));
ffffffffc0203800:	0715                	add	a4,a4,5
ffffffffc0203802:	3c878363          	beq	a5,s0,ffffffffc0203bc8 <vmm_init+0x482>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203806:	fe87b683          	ld	a3,-24(a5)
ffffffffc020380a:	32e69f63          	bne	a3,a4,ffffffffc0203b48 <vmm_init+0x402>
ffffffffc020380e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203812:	00270693          	add	a3,a4,2
ffffffffc0203816:	32d61963          	bne	a2,a3,ffffffffc0203b48 <vmm_init+0x402>
ffffffffc020381a:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i ++) {
ffffffffc020381c:	feb712e3          	bne	a4,a1,ffffffffc0203800 <vmm_init+0xba>
ffffffffc0203820:	4b9d                	li	s7,7
ffffffffc0203822:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203824:	1f900c13          	li	s8,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203828:	85a6                	mv	a1,s1
ffffffffc020382a:	8522                	mv	a0,s0
ffffffffc020382c:	dd5ff0ef          	jal	ffffffffc0203600 <find_vma>
ffffffffc0203830:	8aaa                	mv	s5,a0
        assert(vma1 != NULL);
ffffffffc0203832:	3c050b63          	beqz	a0,ffffffffc0203c08 <vmm_init+0x4c2>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203836:	00148593          	add	a1,s1,1
ffffffffc020383a:	8522                	mv	a0,s0
ffffffffc020383c:	dc5ff0ef          	jal	ffffffffc0203600 <find_vma>
ffffffffc0203840:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc0203842:	3a050363          	beqz	a0,ffffffffc0203be8 <vmm_init+0x4a2>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203846:	85de                	mv	a1,s7
ffffffffc0203848:	8522                	mv	a0,s0
ffffffffc020384a:	db7ff0ef          	jal	ffffffffc0203600 <find_vma>
        assert(vma3 == NULL);
ffffffffc020384e:	32051d63          	bnez	a0,ffffffffc0203b88 <vmm_init+0x442>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203852:	00348593          	add	a1,s1,3
ffffffffc0203856:	8522                	mv	a0,s0
ffffffffc0203858:	da9ff0ef          	jal	ffffffffc0203600 <find_vma>
        assert(vma4 == NULL);
ffffffffc020385c:	30051663          	bnez	a0,ffffffffc0203b68 <vmm_init+0x422>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0203860:	00448593          	add	a1,s1,4
ffffffffc0203864:	8522                	mv	a0,s0
ffffffffc0203866:	d9bff0ef          	jal	ffffffffc0203600 <find_vma>
        assert(vma5 == NULL);
ffffffffc020386a:	32051f63          	bnez	a0,ffffffffc0203ba8 <vmm_init+0x462>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020386e:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0203872:	2a979b63          	bne	a5,s1,ffffffffc0203b28 <vmm_init+0x3e2>
ffffffffc0203876:	010ab783          	ld	a5,16(s5)
ffffffffc020387a:	2afb9763          	bne	s7,a5,ffffffffc0203b28 <vmm_init+0x3e2>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020387e:	00893783          	ld	a5,8(s2)
ffffffffc0203882:	28979363          	bne	a5,s1,ffffffffc0203b08 <vmm_init+0x3c2>
ffffffffc0203886:	01093783          	ld	a5,16(s2)
ffffffffc020388a:	26fb9f63          	bne	s7,a5,ffffffffc0203b08 <vmm_init+0x3c2>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020388e:	0495                	add	s1,s1,5
ffffffffc0203890:	0b95                	add	s7,s7,5
ffffffffc0203892:	f9849be3          	bne	s1,s8,ffffffffc0203828 <vmm_init+0xe2>
ffffffffc0203896:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0203898:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc020389a:	85a6                	mv	a1,s1
ffffffffc020389c:	8522                	mv	a0,s0
ffffffffc020389e:	d63ff0ef          	jal	ffffffffc0203600 <find_vma>
        if (vma_below_5 != NULL ) {
ffffffffc02038a2:	3a051363          	bnez	a0,ffffffffc0203c48 <vmm_init+0x502>
    for (i =4; i>=0; i--) {
ffffffffc02038a6:	14fd                	add	s1,s1,-1
ffffffffc02038a8:	ff2499e3          	bne	s1,s2,ffffffffc020389a <vmm_init+0x154>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038ac:	000b3703          	ld	a4,0(s6)
ffffffffc02038b0:	008b3783          	ld	a5,8(s6)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc02038b4:	fe0b0513          	add	a0,s6,-32
ffffffffc02038b8:	03000593          	li	a1,48
    prev->next = next;
ffffffffc02038bc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038be:	e398                	sd	a4,0(a5)
ffffffffc02038c0:	ff5fe0ef          	jal	ffffffffc02028b4 <kfree>
    return listelm->next;
ffffffffc02038c4:	00843b03          	ld	s6,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02038c8:	ff6412e3          	bne	s0,s6,ffffffffc02038ac <vmm_init+0x166>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc02038cc:	03000593          	li	a1,48
ffffffffc02038d0:	8522                	mv	a0,s0
ffffffffc02038d2:	fe3fe0ef          	jal	ffffffffc02028b4 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02038d6:	dbdfd0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc02038da:	3caa1163          	bne	s4,a0,ffffffffc0203c9c <vmm_init+0x556>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02038de:	00002517          	auipc	a0,0x2
ffffffffc02038e2:	57250513          	add	a0,a0,1394 # ffffffffc0205e50 <etext+0x1966>
ffffffffc02038e6:	fd4fc0ef          	jal	ffffffffc02000ba <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02038ea:	da9fd0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc02038ee:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02038f0:	03000513          	li	a0,48
ffffffffc02038f4:	ef5fe0ef          	jal	ffffffffc02027e8 <kmalloc>
ffffffffc02038f8:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02038fa:	1e050063          	beqz	a0,ffffffffc0203ada <vmm_init+0x394>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02038fe:	0000e797          	auipc	a5,0xe
ffffffffc0203902:	c427a783          	lw	a5,-958(a5) # ffffffffc0211540 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0203906:	e508                	sd	a0,8(a0)
ffffffffc0203908:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020390a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020390e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203912:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203916:	1e079663          	bnez	a5,ffffffffc0203b02 <vmm_init+0x3bc>
        else mm->sm_priv = NULL;
ffffffffc020391a:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();

    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020391e:	0000ea17          	auipc	s4,0xe
ffffffffc0203922:	c02a3a03          	ld	s4,-1022(s4) # ffffffffc0211520 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0203926:	000a3783          	ld	a5,0(s4)
    check_mm_struct = mm_create();
ffffffffc020392a:	0000e717          	auipc	a4,0xe
ffffffffc020392e:	c2873f23          	sd	s0,-962(a4) # ffffffffc0211568 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203932:	01443c23          	sd	s4,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0203936:	2e079963          	bnez	a5,ffffffffc0203c28 <vmm_init+0x4e2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020393a:	03000513          	li	a0,48
ffffffffc020393e:	eabfe0ef          	jal	ffffffffc02027e8 <kmalloc>
ffffffffc0203942:	892a                	mv	s2,a0
    if (vma != NULL) {
ffffffffc0203944:	16050b63          	beqz	a0,ffffffffc0203aba <vmm_init+0x374>
        vma->vm_end = vm_end;
ffffffffc0203948:	002007b7          	lui	a5,0x200
ffffffffc020394c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020394e:	4789                	li	a5,2
ffffffffc0203950:	ed1c                	sd	a5,24(a0)

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203952:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203954:	00053423          	sd	zero,8(a0)
    insert_vma_struct(mm, vma);
ffffffffc0203958:	8522                	mv	a0,s0
ffffffffc020395a:	ce7ff0ef          	jal	ffffffffc0203640 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020395e:	10000593          	li	a1,256
ffffffffc0203962:	8522                	mv	a0,s0
ffffffffc0203964:	c9dff0ef          	jal	ffffffffc0203600 <find_vma>
ffffffffc0203968:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc020396c:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203970:	30a91663          	bne	s2,a0,ffffffffc0203c7c <vmm_init+0x536>
        *(char *)(addr + i) = i;
ffffffffc0203974:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0203978:	0785                	add	a5,a5,1
ffffffffc020397a:	fee79de3          	bne	a5,a4,ffffffffc0203974 <vmm_init+0x22e>
ffffffffc020397e:	6705                	lui	a4,0x1
ffffffffc0203980:	10000793          	li	a5,256
ffffffffc0203984:	35670713          	add	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0203988:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc020398c:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0203990:	0785                	add	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0203992:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0203994:	fec79ce3          	bne	a5,a2,ffffffffc020398c <vmm_init+0x246>
    }
    assert(sum == 0);
ffffffffc0203998:	32071e63          	bnez	a4,ffffffffc0203cd4 <vmm_init+0x58e>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020399c:	4581                	li	a1,0
ffffffffc020399e:	8552                	mv	a0,s4
ffffffffc02039a0:	fb5fd0ef          	jal	ffffffffc0201954 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02039a4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02039a8:	0000e717          	auipc	a4,0xe
ffffffffc02039ac:	b8873703          	ld	a4,-1144(a4) # ffffffffc0211530 <npage>
    return pa2page(PDE_ADDR(pde));
ffffffffc02039b0:	078a                	sll	a5,a5,0x2
ffffffffc02039b2:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02039b4:	30e7f463          	bgeu	a5,a4,ffffffffc0203cbc <vmm_init+0x576>
    return &pages[PPN(pa) - nbase];
ffffffffc02039b8:	00003717          	auipc	a4,0x3
ffffffffc02039bc:	94873703          	ld	a4,-1720(a4) # ffffffffc0206300 <nbase>
ffffffffc02039c0:	8f99                	sub	a5,a5,a4
ffffffffc02039c2:	00379713          	sll	a4,a5,0x3
ffffffffc02039c6:	97ba                	add	a5,a5,a4
ffffffffc02039c8:	078e                	sll	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc02039ca:	0000e517          	auipc	a0,0xe
ffffffffc02039ce:	b6e53503          	ld	a0,-1170(a0) # ffffffffc0211538 <pages>
ffffffffc02039d2:	953e                	add	a0,a0,a5
ffffffffc02039d4:	4585                	li	a1,1
ffffffffc02039d6:	c7dfd0ef          	jal	ffffffffc0201652 <free_pages>
    return listelm->next;
ffffffffc02039da:	6408                	ld	a0,8(s0)

    pgdir[0] = 0;
ffffffffc02039dc:	000a3023          	sd	zero,0(s4)

    mm->pgdir = NULL;
ffffffffc02039e0:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02039e4:	00850e63          	beq	a0,s0,ffffffffc0203a00 <vmm_init+0x2ba>
    __list_del(listelm->prev, listelm->next);
ffffffffc02039e8:	6118                	ld	a4,0(a0)
ffffffffc02039ea:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc02039ec:	03000593          	li	a1,48
ffffffffc02039f0:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc02039f2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02039f4:	e398                	sd	a4,0(a5)
ffffffffc02039f6:	ebffe0ef          	jal	ffffffffc02028b4 <kfree>
    return listelm->next;
ffffffffc02039fa:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02039fc:	fea416e3          	bne	s0,a0,ffffffffc02039e8 <vmm_init+0x2a2>
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203a00:	03000593          	li	a1,48
ffffffffc0203a04:	8522                	mv	a0,s0
ffffffffc0203a06:	eaffe0ef          	jal	ffffffffc02028b4 <kfree>
    mm_destroy(mm);

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0203a0a:	14fd                	add	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc0203a0c:	0000e797          	auipc	a5,0xe
ffffffffc0203a10:	b407be23          	sd	zero,-1188(a5) # ffffffffc0211568 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a14:	c7ffd0ef          	jal	ffffffffc0201692 <nr_free_pages>
ffffffffc0203a18:	2ea49e63          	bne	s1,a0,ffffffffc0203d14 <vmm_init+0x5ce>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203a1c:	00002517          	auipc	a0,0x2
ffffffffc0203a20:	49c50513          	add	a0,a0,1180 # ffffffffc0205eb8 <etext+0x19ce>
ffffffffc0203a24:	e96fc0ef          	jal	ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a28:	c6bfd0ef          	jal	ffffffffc0201692 <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0203a2c:	19fd                	add	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203a2e:	2ca99363          	bne	s3,a0,ffffffffc0203cf4 <vmm_init+0x5ae>
}
ffffffffc0203a32:	6406                	ld	s0,64(sp)
ffffffffc0203a34:	60a6                	ld	ra,72(sp)
ffffffffc0203a36:	74e2                	ld	s1,56(sp)
ffffffffc0203a38:	7942                	ld	s2,48(sp)
ffffffffc0203a3a:	79a2                	ld	s3,40(sp)
ffffffffc0203a3c:	7a02                	ld	s4,32(sp)
ffffffffc0203a3e:	6ae2                	ld	s5,24(sp)
ffffffffc0203a40:	6b42                	ld	s6,16(sp)
ffffffffc0203a42:	6ba2                	ld	s7,8(sp)
ffffffffc0203a44:	6c02                	ld	s8,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a46:	00002517          	auipc	a0,0x2
ffffffffc0203a4a:	49250513          	add	a0,a0,1170 # ffffffffc0205ed8 <etext+0x19ee>
}
ffffffffc0203a4e:	6161                	add	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203a50:	e6afc06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a54:	ddaff0ef          	jal	ffffffffc020302e <swap_init_mm>
    for (i = step1; i >= 1; i --) {
ffffffffc0203a58:	bb3d                	j	ffffffffc0203796 <vmm_init+0x50>
        assert(vma != NULL);
ffffffffc0203a5a:	00002697          	auipc	a3,0x2
ffffffffc0203a5e:	e1668693          	add	a3,a3,-490 # ffffffffc0205870 <etext+0x1386>
ffffffffc0203a62:	00001617          	auipc	a2,0x1
ffffffffc0203a66:	36660613          	add	a2,a2,870 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203a6a:	0ce00593          	li	a1,206
ffffffffc0203a6e:	00002517          	auipc	a0,0x2
ffffffffc0203a72:	20a50513          	add	a0,a0,522 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203a76:	8ebfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(mm != NULL);
ffffffffc0203a7a:	00002697          	auipc	a3,0x2
ffffffffc0203a7e:	dbe68693          	add	a3,a3,-578 # ffffffffc0205838 <etext+0x134e>
ffffffffc0203a82:	00001617          	auipc	a2,0x1
ffffffffc0203a86:	34660613          	add	a2,a2,838 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203a8a:	0c700593          	li	a1,199
ffffffffc0203a8e:	00002517          	auipc	a0,0x2
ffffffffc0203a92:	1ea50513          	add	a0,a0,490 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203a96:	8cbfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma != NULL);
ffffffffc0203a9a:	00002697          	auipc	a3,0x2
ffffffffc0203a9e:	dd668693          	add	a3,a3,-554 # ffffffffc0205870 <etext+0x1386>
ffffffffc0203aa2:	00001617          	auipc	a2,0x1
ffffffffc0203aa6:	32660613          	add	a2,a2,806 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203aaa:	0d400593          	li	a1,212
ffffffffc0203aae:	00002517          	auipc	a0,0x2
ffffffffc0203ab2:	1ca50513          	add	a0,a0,458 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203ab6:	8abfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(vma != NULL);
ffffffffc0203aba:	00002697          	auipc	a3,0x2
ffffffffc0203abe:	db668693          	add	a3,a3,-586 # ffffffffc0205870 <etext+0x1386>
ffffffffc0203ac2:	00001617          	auipc	a2,0x1
ffffffffc0203ac6:	30660613          	add	a2,a2,774 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203aca:	11100593          	li	a1,273
ffffffffc0203ace:	00002517          	auipc	a0,0x2
ffffffffc0203ad2:	1aa50513          	add	a0,a0,426 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203ad6:	88bfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203ada:	00002697          	auipc	a3,0x2
ffffffffc0203ade:	39668693          	add	a3,a3,918 # ffffffffc0205e70 <etext+0x1986>
ffffffffc0203ae2:	00001617          	auipc	a2,0x1
ffffffffc0203ae6:	2e660613          	add	a2,a2,742 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203aea:	10a00593          	li	a1,266
ffffffffc0203aee:	00002517          	auipc	a0,0x2
ffffffffc0203af2:	18a50513          	add	a0,a0,394 # ffffffffc0205c78 <etext+0x178e>
    check_mm_struct = mm_create();
ffffffffc0203af6:	0000e797          	auipc	a5,0xe
ffffffffc0203afa:	a607b923          	sd	zero,-1422(a5) # ffffffffc0211568 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc0203afe:	863fc0ef          	jal	ffffffffc0200360 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203b02:	d2cff0ef          	jal	ffffffffc020302e <swap_init_mm>
    assert(check_mm_struct != NULL);
ffffffffc0203b06:	bd21                	j	ffffffffc020391e <vmm_init+0x1d8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203b08:	00002697          	auipc	a3,0x2
ffffffffc0203b0c:	2b068693          	add	a3,a3,688 # ffffffffc0205db8 <etext+0x18ce>
ffffffffc0203b10:	00001617          	auipc	a2,0x1
ffffffffc0203b14:	2b860613          	add	a2,a2,696 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203b18:	0ee00593          	li	a1,238
ffffffffc0203b1c:	00002517          	auipc	a0,0x2
ffffffffc0203b20:	15c50513          	add	a0,a0,348 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203b24:	83dfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203b28:	00002697          	auipc	a3,0x2
ffffffffc0203b2c:	26068693          	add	a3,a3,608 # ffffffffc0205d88 <etext+0x189e>
ffffffffc0203b30:	00001617          	auipc	a2,0x1
ffffffffc0203b34:	29860613          	add	a2,a2,664 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203b38:	0ed00593          	li	a1,237
ffffffffc0203b3c:	00002517          	auipc	a0,0x2
ffffffffc0203b40:	13c50513          	add	a0,a0,316 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203b44:	81dfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b48:	00002697          	auipc	a3,0x2
ffffffffc0203b4c:	1b868693          	add	a3,a3,440 # ffffffffc0205d00 <etext+0x1816>
ffffffffc0203b50:	00001617          	auipc	a2,0x1
ffffffffc0203b54:	27860613          	add	a2,a2,632 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203b58:	0dd00593          	li	a1,221
ffffffffc0203b5c:	00002517          	auipc	a0,0x2
ffffffffc0203b60:	11c50513          	add	a0,a0,284 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203b64:	ffcfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma4 == NULL);
ffffffffc0203b68:	00002697          	auipc	a3,0x2
ffffffffc0203b6c:	20068693          	add	a3,a3,512 # ffffffffc0205d68 <etext+0x187e>
ffffffffc0203b70:	00001617          	auipc	a2,0x1
ffffffffc0203b74:	25860613          	add	a2,a2,600 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203b78:	0e900593          	li	a1,233
ffffffffc0203b7c:	00002517          	auipc	a0,0x2
ffffffffc0203b80:	0fc50513          	add	a0,a0,252 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203b84:	fdcfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma3 == NULL);
ffffffffc0203b88:	00002697          	auipc	a3,0x2
ffffffffc0203b8c:	1d068693          	add	a3,a3,464 # ffffffffc0205d58 <etext+0x186e>
ffffffffc0203b90:	00001617          	auipc	a2,0x1
ffffffffc0203b94:	23860613          	add	a2,a2,568 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203b98:	0e700593          	li	a1,231
ffffffffc0203b9c:	00002517          	auipc	a0,0x2
ffffffffc0203ba0:	0dc50513          	add	a0,a0,220 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203ba4:	fbcfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma5 == NULL);
ffffffffc0203ba8:	00002697          	auipc	a3,0x2
ffffffffc0203bac:	1d068693          	add	a3,a3,464 # ffffffffc0205d78 <etext+0x188e>
ffffffffc0203bb0:	00001617          	auipc	a2,0x1
ffffffffc0203bb4:	21860613          	add	a2,a2,536 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203bb8:	0eb00593          	li	a1,235
ffffffffc0203bbc:	00002517          	auipc	a0,0x2
ffffffffc0203bc0:	0bc50513          	add	a0,a0,188 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203bc4:	f9cfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203bc8:	00002697          	auipc	a3,0x2
ffffffffc0203bcc:	12068693          	add	a3,a3,288 # ffffffffc0205ce8 <etext+0x17fe>
ffffffffc0203bd0:	00001617          	auipc	a2,0x1
ffffffffc0203bd4:	1f860613          	add	a2,a2,504 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203bd8:	0db00593          	li	a1,219
ffffffffc0203bdc:	00002517          	auipc	a0,0x2
ffffffffc0203be0:	09c50513          	add	a0,a0,156 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203be4:	f7cfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma2 != NULL);
ffffffffc0203be8:	00002697          	auipc	a3,0x2
ffffffffc0203bec:	16068693          	add	a3,a3,352 # ffffffffc0205d48 <etext+0x185e>
ffffffffc0203bf0:	00001617          	auipc	a2,0x1
ffffffffc0203bf4:	1d860613          	add	a2,a2,472 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203bf8:	0e500593          	li	a1,229
ffffffffc0203bfc:	00002517          	auipc	a0,0x2
ffffffffc0203c00:	07c50513          	add	a0,a0,124 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203c04:	f5cfc0ef          	jal	ffffffffc0200360 <__panic>
        assert(vma1 != NULL);
ffffffffc0203c08:	00002697          	auipc	a3,0x2
ffffffffc0203c0c:	13068693          	add	a3,a3,304 # ffffffffc0205d38 <etext+0x184e>
ffffffffc0203c10:	00001617          	auipc	a2,0x1
ffffffffc0203c14:	1b860613          	add	a2,a2,440 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203c18:	0e300593          	li	a1,227
ffffffffc0203c1c:	00002517          	auipc	a0,0x2
ffffffffc0203c20:	05c50513          	add	a0,a0,92 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203c24:	f3cfc0ef          	jal	ffffffffc0200360 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203c28:	00002697          	auipc	a3,0x2
ffffffffc0203c2c:	c3868693          	add	a3,a3,-968 # ffffffffc0205860 <etext+0x1376>
ffffffffc0203c30:	00001617          	auipc	a2,0x1
ffffffffc0203c34:	19860613          	add	a2,a2,408 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203c38:	10d00593          	li	a1,269
ffffffffc0203c3c:	00002517          	auipc	a0,0x2
ffffffffc0203c40:	03c50513          	add	a0,a0,60 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203c44:	f1cfc0ef          	jal	ffffffffc0200360 <__panic>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203c48:	6914                	ld	a3,16(a0)
ffffffffc0203c4a:	6510                	ld	a2,8(a0)
ffffffffc0203c4c:	0004859b          	sext.w	a1,s1
ffffffffc0203c50:	00002517          	auipc	a0,0x2
ffffffffc0203c54:	19850513          	add	a0,a0,408 # ffffffffc0205de8 <etext+0x18fe>
ffffffffc0203c58:	c62fc0ef          	jal	ffffffffc02000ba <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203c5c:	00002697          	auipc	a3,0x2
ffffffffc0203c60:	1b468693          	add	a3,a3,436 # ffffffffc0205e10 <etext+0x1926>
ffffffffc0203c64:	00001617          	auipc	a2,0x1
ffffffffc0203c68:	16460613          	add	a2,a2,356 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203c6c:	0f600593          	li	a1,246
ffffffffc0203c70:	00002517          	auipc	a0,0x2
ffffffffc0203c74:	00850513          	add	a0,a0,8 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203c78:	ee8fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203c7c:	00002697          	auipc	a3,0x2
ffffffffc0203c80:	20c68693          	add	a3,a3,524 # ffffffffc0205e88 <etext+0x199e>
ffffffffc0203c84:	00001617          	auipc	a2,0x1
ffffffffc0203c88:	14460613          	add	a2,a2,324 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203c8c:	11600593          	li	a1,278
ffffffffc0203c90:	00002517          	auipc	a0,0x2
ffffffffc0203c94:	fe850513          	add	a0,a0,-24 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203c98:	ec8fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203c9c:	00002697          	auipc	a3,0x2
ffffffffc0203ca0:	18c68693          	add	a3,a3,396 # ffffffffc0205e28 <etext+0x193e>
ffffffffc0203ca4:	00001617          	auipc	a2,0x1
ffffffffc0203ca8:	12460613          	add	a2,a2,292 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203cac:	0fb00593          	li	a1,251
ffffffffc0203cb0:	00002517          	auipc	a0,0x2
ffffffffc0203cb4:	fc850513          	add	a0,a0,-56 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203cb8:	ea8fc0ef          	jal	ffffffffc0200360 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203cbc:	00001617          	auipc	a2,0x1
ffffffffc0203cc0:	4bc60613          	add	a2,a2,1212 # ffffffffc0205178 <etext+0xc8e>
ffffffffc0203cc4:	06500593          	li	a1,101
ffffffffc0203cc8:	00001517          	auipc	a0,0x1
ffffffffc0203ccc:	4d050513          	add	a0,a0,1232 # ffffffffc0205198 <etext+0xcae>
ffffffffc0203cd0:	e90fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(sum == 0);
ffffffffc0203cd4:	00002697          	auipc	a3,0x2
ffffffffc0203cd8:	1d468693          	add	a3,a3,468 # ffffffffc0205ea8 <etext+0x19be>
ffffffffc0203cdc:	00001617          	auipc	a2,0x1
ffffffffc0203ce0:	0ec60613          	add	a2,a2,236 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203ce4:	12000593          	li	a1,288
ffffffffc0203ce8:	00002517          	auipc	a0,0x2
ffffffffc0203cec:	f9050513          	add	a0,a0,-112 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203cf0:	e70fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203cf4:	00002697          	auipc	a3,0x2
ffffffffc0203cf8:	13468693          	add	a3,a3,308 # ffffffffc0205e28 <etext+0x193e>
ffffffffc0203cfc:	00001617          	auipc	a2,0x1
ffffffffc0203d00:	0cc60613          	add	a2,a2,204 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203d04:	0bd00593          	li	a1,189
ffffffffc0203d08:	00002517          	auipc	a0,0x2
ffffffffc0203d0c:	f7050513          	add	a0,a0,-144 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203d10:	e50fc0ef          	jal	ffffffffc0200360 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203d14:	00002697          	auipc	a3,0x2
ffffffffc0203d18:	11468693          	add	a3,a3,276 # ffffffffc0205e28 <etext+0x193e>
ffffffffc0203d1c:	00001617          	auipc	a2,0x1
ffffffffc0203d20:	0ac60613          	add	a2,a2,172 # ffffffffc0204dc8 <etext+0x8de>
ffffffffc0203d24:	12e00593          	li	a1,302
ffffffffc0203d28:	00002517          	auipc	a0,0x2
ffffffffc0203d2c:	f5050513          	add	a0,a0,-176 # ffffffffc0205c78 <etext+0x178e>
ffffffffc0203d30:	e30fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203d34 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203d34:	7179                	add	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d36:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0203d38:	f022                	sd	s0,32(sp)
ffffffffc0203d3a:	ec26                	sd	s1,24(sp)
ffffffffc0203d3c:	f406                	sd	ra,40(sp)
ffffffffc0203d3e:	8432                	mv	s0,a2
ffffffffc0203d40:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203d42:	8bfff0ef          	jal	ffffffffc0203600 <find_vma>

    pgfault_num++;
ffffffffc0203d46:	0000e797          	auipc	a5,0xe
ffffffffc0203d4a:	81a7a783          	lw	a5,-2022(a5) # ffffffffc0211560 <pgfault_num>
ffffffffc0203d4e:	2785                	addw	a5,a5,1
ffffffffc0203d50:	0000e717          	auipc	a4,0xe
ffffffffc0203d54:	80f72823          	sw	a5,-2032(a4) # ffffffffc0211560 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0203d58:	c159                	beqz	a0,ffffffffc0203dde <do_pgfault+0xaa>
ffffffffc0203d5a:	651c                	ld	a5,8(a0)
ffffffffc0203d5c:	08f46163          	bltu	s0,a5,ffffffffc0203dde <do_pgfault+0xaa>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203d60:	6d1c                	ld	a5,24(a0)
ffffffffc0203d62:	e84a                	sd	s2,16(sp)
        perm |= (PTE_R | PTE_W);
ffffffffc0203d64:	4959                	li	s2,22
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0203d66:	8b89                	and	a5,a5,2
ffffffffc0203d68:	cbb1                	beqz	a5,ffffffffc0203dbc <do_pgfault+0x88>
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d6a:	77fd                	lui	a5,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203d6c:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203d6e:	8c7d                	and	s0,s0,a5
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc0203d70:	85a2                	mv	a1,s0
ffffffffc0203d72:	4605                	li	a2,1
ffffffffc0203d74:	959fd0ef          	jal	ffffffffc02016cc <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc0203d78:	610c                	ld	a1,0(a0)
ffffffffc0203d7a:	c1b9                	beqz	a1,ffffffffc0203dc0 <do_pgfault+0x8c>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0203d7c:	0000d797          	auipc	a5,0xd
ffffffffc0203d80:	7c47a783          	lw	a5,1988(a5) # ffffffffc0211540 <swap_init_ok>
ffffffffc0203d84:	c7b5                	beqz	a5,ffffffffc0203df0 <do_pgfault+0xbc>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            swap_in(mm, addr, &page);
ffffffffc0203d86:	0030                	add	a2,sp,8
ffffffffc0203d88:	85a2                	mv	a1,s0
ffffffffc0203d8a:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0203d8c:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc0203d8e:	bceff0ef          	jal	ffffffffc020315c <swap_in>
            page_insert(mm->pgdir, page, addr, perm); 
ffffffffc0203d92:	65a2                	ld	a1,8(sp)
ffffffffc0203d94:	6c88                	ld	a0,24(s1)
ffffffffc0203d96:	86ca                	mv	a3,s2
ffffffffc0203d98:	8622                	mv	a2,s0
ffffffffc0203d9a:	c55fd0ef          	jal	ffffffffc02019ee <page_insert>
            swap_map_swappable(mm, addr, page, 1);
ffffffffc0203d9e:	6622                	ld	a2,8(sp)
ffffffffc0203da0:	4685                	li	a3,1
ffffffffc0203da2:	85a2                	mv	a1,s0
ffffffffc0203da4:	8526                	mv	a0,s1
ffffffffc0203da6:	a94ff0ef          	jal	ffffffffc020303a <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0203daa:	67a2                	ld	a5,8(sp)
ffffffffc0203dac:	e3a0                	sd	s0,64(a5)
ffffffffc0203dae:	6942                	ld	s2,16(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0203db0:	4501                	li	a0,0
failed:
    return ret;
}
ffffffffc0203db2:	70a2                	ld	ra,40(sp)
ffffffffc0203db4:	7402                	ld	s0,32(sp)
ffffffffc0203db6:	64e2                	ld	s1,24(sp)
ffffffffc0203db8:	6145                	add	sp,sp,48
ffffffffc0203dba:	8082                	ret
    uint32_t perm = PTE_U;
ffffffffc0203dbc:	4941                	li	s2,16
ffffffffc0203dbe:	b775                	j	ffffffffc0203d6a <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0203dc0:	6c88                	ld	a0,24(s1)
ffffffffc0203dc2:	864a                	mv	a2,s2
ffffffffc0203dc4:	85a2                	mv	a1,s0
ffffffffc0203dc6:	96bfe0ef          	jal	ffffffffc0202730 <pgdir_alloc_page>
ffffffffc0203dca:	f175                	bnez	a0,ffffffffc0203dae <do_pgfault+0x7a>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0203dcc:	00002517          	auipc	a0,0x2
ffffffffc0203dd0:	15450513          	add	a0,a0,340 # ffffffffc0205f20 <etext+0x1a36>
ffffffffc0203dd4:	ae6fc0ef          	jal	ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM;
ffffffffc0203dd8:	6942                	ld	s2,16(sp)
ffffffffc0203dda:	5571                	li	a0,-4
ffffffffc0203ddc:	bfd9                	j	ffffffffc0203db2 <do_pgfault+0x7e>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0203dde:	85a2                	mv	a1,s0
ffffffffc0203de0:	00002517          	auipc	a0,0x2
ffffffffc0203de4:	11050513          	add	a0,a0,272 # ffffffffc0205ef0 <etext+0x1a06>
ffffffffc0203de8:	ad2fc0ef          	jal	ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc0203dec:	5575                	li	a0,-3
        goto failed;
ffffffffc0203dee:	b7d1                	j	ffffffffc0203db2 <do_pgfault+0x7e>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0203df0:	00002517          	auipc	a0,0x2
ffffffffc0203df4:	15850513          	add	a0,a0,344 # ffffffffc0205f48 <etext+0x1a5e>
ffffffffc0203df8:	ac2fc0ef          	jal	ffffffffc02000ba <cprintf>
            goto failed;
ffffffffc0203dfc:	bff1                	j	ffffffffc0203dd8 <do_pgfault+0xa4>

ffffffffc0203dfe <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203dfe:	1141                	add	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203e00:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203e02:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203e04:	e7efc0ef          	jal	ffffffffc0200482 <ide_device_valid>
ffffffffc0203e08:	cd01                	beqz	a0,ffffffffc0203e20 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203e0a:	4505                	li	a0,1
ffffffffc0203e0c:	e7cfc0ef          	jal	ffffffffc0200488 <ide_device_size>
}
ffffffffc0203e10:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203e12:	810d                	srl	a0,a0,0x3
ffffffffc0203e14:	0000d797          	auipc	a5,0xd
ffffffffc0203e18:	72a7ba23          	sd	a0,1844(a5) # ffffffffc0211548 <max_swap_offset>
}
ffffffffc0203e1c:	0141                	add	sp,sp,16
ffffffffc0203e1e:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203e20:	00002617          	auipc	a2,0x2
ffffffffc0203e24:	15060613          	add	a2,a2,336 # ffffffffc0205f70 <etext+0x1a86>
ffffffffc0203e28:	45b5                	li	a1,13
ffffffffc0203e2a:	00002517          	auipc	a0,0x2
ffffffffc0203e2e:	16650513          	add	a0,a0,358 # ffffffffc0205f90 <etext+0x1aa6>
ffffffffc0203e32:	d2efc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203e36 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203e36:	1141                	add	sp,sp,-16
ffffffffc0203e38:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e3a:	00855713          	srl	a4,a0,0x8
ffffffffc0203e3e:	cb2d                	beqz	a4,ffffffffc0203eb0 <swapfs_read+0x7a>
ffffffffc0203e40:	0000d797          	auipc	a5,0xd
ffffffffc0203e44:	7087b783          	ld	a5,1800(a5) # ffffffffc0211548 <max_swap_offset>
ffffffffc0203e48:	06f77463          	bgeu	a4,a5,ffffffffc0203eb0 <swapfs_read+0x7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e4c:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0203e50:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0203e54:	07b2                	sll	a5,a5,0xc
ffffffffc0203e56:	e3978793          	add	a5,a5,-455
ffffffffc0203e5a:	07b2                	sll	a5,a5,0xc
ffffffffc0203e5c:	0000d697          	auipc	a3,0xd
ffffffffc0203e60:	6dc6b683          	ld	a3,1756(a3) # ffffffffc0211538 <pages>
ffffffffc0203e64:	e3978793          	add	a5,a5,-455
ffffffffc0203e68:	8d95                	sub	a1,a1,a3
ffffffffc0203e6a:	07b2                	sll	a5,a5,0xc
ffffffffc0203e6c:	4035d613          	sra	a2,a1,0x3
ffffffffc0203e70:	e3978793          	add	a5,a5,-455
ffffffffc0203e74:	02f60633          	mul	a2,a2,a5
ffffffffc0203e78:	00002797          	auipc	a5,0x2
ffffffffc0203e7c:	4887b783          	ld	a5,1160(a5) # ffffffffc0206300 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e80:	0000d697          	auipc	a3,0xd
ffffffffc0203e84:	6b06b683          	ld	a3,1712(a3) # ffffffffc0211530 <npage>
ffffffffc0203e88:	0037159b          	sllw	a1,a4,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203e8c:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e8e:	00c61793          	sll	a5,a2,0xc
ffffffffc0203e92:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e94:	0632                	sll	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203e96:	02d7f963          	bgeu	a5,a3,ffffffffc0203ec8 <swapfs_read+0x92>
}
ffffffffc0203e9a:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e9c:	0000d797          	auipc	a5,0xd
ffffffffc0203ea0:	68c7b783          	ld	a5,1676(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc0203ea4:	46a1                	li	a3,8
ffffffffc0203ea6:	963e                	add	a2,a2,a5
ffffffffc0203ea8:	4505                	li	a0,1
}
ffffffffc0203eaa:	0141                	add	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203eac:	de2fc06f          	j	ffffffffc020048e <ide_read_secs>
ffffffffc0203eb0:	86aa                	mv	a3,a0
ffffffffc0203eb2:	00002617          	auipc	a2,0x2
ffffffffc0203eb6:	0f660613          	add	a2,a2,246 # ffffffffc0205fa8 <etext+0x1abe>
ffffffffc0203eba:	45d1                	li	a1,20
ffffffffc0203ebc:	00002517          	auipc	a0,0x2
ffffffffc0203ec0:	0d450513          	add	a0,a0,212 # ffffffffc0205f90 <etext+0x1aa6>
ffffffffc0203ec4:	c9cfc0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0203ec8:	86b2                	mv	a3,a2
ffffffffc0203eca:	06a00593          	li	a1,106
ffffffffc0203ece:	00001617          	auipc	a2,0x1
ffffffffc0203ed2:	30260613          	add	a2,a2,770 # ffffffffc02051d0 <etext+0xce6>
ffffffffc0203ed6:	00001517          	auipc	a0,0x1
ffffffffc0203eda:	2c250513          	add	a0,a0,706 # ffffffffc0205198 <etext+0xcae>
ffffffffc0203ede:	c82fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203ee2 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203ee2:	1141                	add	sp,sp,-16
ffffffffc0203ee4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203ee6:	00855713          	srl	a4,a0,0x8
ffffffffc0203eea:	cb2d                	beqz	a4,ffffffffc0203f5c <swapfs_write+0x7a>
ffffffffc0203eec:	0000d797          	auipc	a5,0xd
ffffffffc0203ef0:	65c7b783          	ld	a5,1628(a5) # ffffffffc0211548 <max_swap_offset>
ffffffffc0203ef4:	06f77463          	bgeu	a4,a5,ffffffffc0203f5c <swapfs_write+0x7a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203ef8:	f8e397b7          	lui	a5,0xf8e39
ffffffffc0203efc:	e3978793          	add	a5,a5,-455 # fffffffff8e38e39 <end+0x38c278c9>
ffffffffc0203f00:	07b2                	sll	a5,a5,0xc
ffffffffc0203f02:	e3978793          	add	a5,a5,-455
ffffffffc0203f06:	07b2                	sll	a5,a5,0xc
ffffffffc0203f08:	0000d697          	auipc	a3,0xd
ffffffffc0203f0c:	6306b683          	ld	a3,1584(a3) # ffffffffc0211538 <pages>
ffffffffc0203f10:	e3978793          	add	a5,a5,-455
ffffffffc0203f14:	8d95                	sub	a1,a1,a3
ffffffffc0203f16:	07b2                	sll	a5,a5,0xc
ffffffffc0203f18:	4035d613          	sra	a2,a1,0x3
ffffffffc0203f1c:	e3978793          	add	a5,a5,-455
ffffffffc0203f20:	02f60633          	mul	a2,a2,a5
ffffffffc0203f24:	00002797          	auipc	a5,0x2
ffffffffc0203f28:	3dc7b783          	ld	a5,988(a5) # ffffffffc0206300 <nbase>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203f2c:	0000d697          	auipc	a3,0xd
ffffffffc0203f30:	6046b683          	ld	a3,1540(a3) # ffffffffc0211530 <npage>
ffffffffc0203f34:	0037159b          	sllw	a1,a4,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203f38:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203f3a:	00c61793          	sll	a5,a2,0xc
ffffffffc0203f3e:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203f40:	0632                	sll	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0203f42:	02d7f963          	bgeu	a5,a3,ffffffffc0203f74 <swapfs_write+0x92>
}
ffffffffc0203f46:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f48:	0000d797          	auipc	a5,0xd
ffffffffc0203f4c:	5e07b783          	ld	a5,1504(a5) # ffffffffc0211528 <va_pa_offset>
ffffffffc0203f50:	46a1                	li	a3,8
ffffffffc0203f52:	963e                	add	a2,a2,a5
ffffffffc0203f54:	4505                	li	a0,1
}
ffffffffc0203f56:	0141                	add	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f58:	d5afc06f          	j	ffffffffc02004b2 <ide_write_secs>
ffffffffc0203f5c:	86aa                	mv	a3,a0
ffffffffc0203f5e:	00002617          	auipc	a2,0x2
ffffffffc0203f62:	04a60613          	add	a2,a2,74 # ffffffffc0205fa8 <etext+0x1abe>
ffffffffc0203f66:	45e5                	li	a1,25
ffffffffc0203f68:	00002517          	auipc	a0,0x2
ffffffffc0203f6c:	02850513          	add	a0,a0,40 # ffffffffc0205f90 <etext+0x1aa6>
ffffffffc0203f70:	bf0fc0ef          	jal	ffffffffc0200360 <__panic>
ffffffffc0203f74:	86b2                	mv	a3,a2
ffffffffc0203f76:	06a00593          	li	a1,106
ffffffffc0203f7a:	00001617          	auipc	a2,0x1
ffffffffc0203f7e:	25660613          	add	a2,a2,598 # ffffffffc02051d0 <etext+0xce6>
ffffffffc0203f82:	00001517          	auipc	a0,0x1
ffffffffc0203f86:	21650513          	add	a0,a0,534 # ffffffffc0205198 <etext+0xcae>
ffffffffc0203f8a:	bd6fc0ef          	jal	ffffffffc0200360 <__panic>

ffffffffc0203f8e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203f8e:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f92:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203f94:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f98:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203f9a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f9e:	f022                	sd	s0,32(sp)
ffffffffc0203fa0:	ec26                	sd	s1,24(sp)
ffffffffc0203fa2:	e84a                	sd	s2,16(sp)
ffffffffc0203fa4:	f406                	sd	ra,40(sp)
ffffffffc0203fa6:	84aa                	mv	s1,a0
ffffffffc0203fa8:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203faa:	fff7041b          	addw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203fae:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203fb0:	05067063          	bgeu	a2,a6,ffffffffc0203ff0 <printnum+0x62>
ffffffffc0203fb4:	e44e                	sd	s3,8(sp)
ffffffffc0203fb6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203fb8:	4785                	li	a5,1
ffffffffc0203fba:	00e7d763          	bge	a5,a4,ffffffffc0203fc8 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0203fbe:	85ca                	mv	a1,s2
ffffffffc0203fc0:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203fc2:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203fc4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203fc6:	fc65                	bnez	s0,ffffffffc0203fbe <printnum+0x30>
ffffffffc0203fc8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203fca:	1a02                	sll	s4,s4,0x20
ffffffffc0203fcc:	020a5a13          	srl	s4,s4,0x20
ffffffffc0203fd0:	00002797          	auipc	a5,0x2
ffffffffc0203fd4:	ff878793          	add	a5,a5,-8 # ffffffffc0205fc8 <etext+0x1ade>
ffffffffc0203fd8:	97d2                	add	a5,a5,s4
}
ffffffffc0203fda:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203fdc:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0203fe0:	70a2                	ld	ra,40(sp)
ffffffffc0203fe2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203fe4:	85ca                	mv	a1,s2
ffffffffc0203fe6:	87a6                	mv	a5,s1
}
ffffffffc0203fe8:	6942                	ld	s2,16(sp)
ffffffffc0203fea:	64e2                	ld	s1,24(sp)
ffffffffc0203fec:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203fee:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203ff0:	03065633          	divu	a2,a2,a6
ffffffffc0203ff4:	8722                	mv	a4,s0
ffffffffc0203ff6:	f99ff0ef          	jal	ffffffffc0203f8e <printnum>
ffffffffc0203ffa:	bfc1                	j	ffffffffc0203fca <printnum+0x3c>

ffffffffc0203ffc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203ffc:	7119                	add	sp,sp,-128
ffffffffc0203ffe:	f4a6                	sd	s1,104(sp)
ffffffffc0204000:	f0ca                	sd	s2,96(sp)
ffffffffc0204002:	ecce                	sd	s3,88(sp)
ffffffffc0204004:	e8d2                	sd	s4,80(sp)
ffffffffc0204006:	e4d6                	sd	s5,72(sp)
ffffffffc0204008:	e0da                	sd	s6,64(sp)
ffffffffc020400a:	f862                	sd	s8,48(sp)
ffffffffc020400c:	fc86                	sd	ra,120(sp)
ffffffffc020400e:	f8a2                	sd	s0,112(sp)
ffffffffc0204010:	fc5e                	sd	s7,56(sp)
ffffffffc0204012:	f466                	sd	s9,40(sp)
ffffffffc0204014:	f06a                	sd	s10,32(sp)
ffffffffc0204016:	ec6e                	sd	s11,24(sp)
ffffffffc0204018:	892a                	mv	s2,a0
ffffffffc020401a:	84ae                	mv	s1,a1
ffffffffc020401c:	8c32                	mv	s8,a2
ffffffffc020401e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204020:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204024:	05500b13          	li	s6,85
ffffffffc0204028:	00002a97          	auipc	s5,0x2
ffffffffc020402c:	148a8a93          	add	s5,s5,328 # ffffffffc0206170 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204030:	000c4503          	lbu	a0,0(s8)
ffffffffc0204034:	001c0413          	add	s0,s8,1
ffffffffc0204038:	01350a63          	beq	a0,s3,ffffffffc020404c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020403c:	cd0d                	beqz	a0,ffffffffc0204076 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020403e:	85a6                	mv	a1,s1
ffffffffc0204040:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204042:	00044503          	lbu	a0,0(s0)
ffffffffc0204046:	0405                	add	s0,s0,1
ffffffffc0204048:	ff351ae3          	bne	a0,s3,ffffffffc020403c <vprintfmt+0x40>
        char padc = ' ';
ffffffffc020404c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0204050:	4b81                	li	s7,0
ffffffffc0204052:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0204054:	5d7d                	li	s10,-1
ffffffffc0204056:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204058:	00044683          	lbu	a3,0(s0)
ffffffffc020405c:	00140c13          	add	s8,s0,1
ffffffffc0204060:	fdd6859b          	addw	a1,a3,-35
ffffffffc0204064:	0ff5f593          	zext.b	a1,a1
ffffffffc0204068:	02bb6663          	bltu	s6,a1,ffffffffc0204094 <vprintfmt+0x98>
ffffffffc020406c:	058a                	sll	a1,a1,0x2
ffffffffc020406e:	95d6                	add	a1,a1,s5
ffffffffc0204070:	4198                	lw	a4,0(a1)
ffffffffc0204072:	9756                	add	a4,a4,s5
ffffffffc0204074:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204076:	70e6                	ld	ra,120(sp)
ffffffffc0204078:	7446                	ld	s0,112(sp)
ffffffffc020407a:	74a6                	ld	s1,104(sp)
ffffffffc020407c:	7906                	ld	s2,96(sp)
ffffffffc020407e:	69e6                	ld	s3,88(sp)
ffffffffc0204080:	6a46                	ld	s4,80(sp)
ffffffffc0204082:	6aa6                	ld	s5,72(sp)
ffffffffc0204084:	6b06                	ld	s6,64(sp)
ffffffffc0204086:	7be2                	ld	s7,56(sp)
ffffffffc0204088:	7c42                	ld	s8,48(sp)
ffffffffc020408a:	7ca2                	ld	s9,40(sp)
ffffffffc020408c:	7d02                	ld	s10,32(sp)
ffffffffc020408e:	6de2                	ld	s11,24(sp)
ffffffffc0204090:	6109                	add	sp,sp,128
ffffffffc0204092:	8082                	ret
            putch('%', putdat);
ffffffffc0204094:	85a6                	mv	a1,s1
ffffffffc0204096:	02500513          	li	a0,37
ffffffffc020409a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020409c:	fff44703          	lbu	a4,-1(s0)
ffffffffc02040a0:	02500793          	li	a5,37
ffffffffc02040a4:	8c22                	mv	s8,s0
ffffffffc02040a6:	f8f705e3          	beq	a4,a5,ffffffffc0204030 <vprintfmt+0x34>
ffffffffc02040aa:	02500713          	li	a4,37
ffffffffc02040ae:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02040b2:	1c7d                	add	s8,s8,-1
ffffffffc02040b4:	fee79de3          	bne	a5,a4,ffffffffc02040ae <vprintfmt+0xb2>
ffffffffc02040b8:	bfa5                	j	ffffffffc0204030 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02040ba:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02040be:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc02040c0:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02040c4:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc02040c8:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040cc:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc02040ce:	02b76563          	bltu	a4,a1,ffffffffc02040f8 <vprintfmt+0xfc>
ffffffffc02040d2:	4525                	li	a0,9
                ch = *fmt;
ffffffffc02040d4:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02040d8:	002d171b          	sllw	a4,s10,0x2
ffffffffc02040dc:	01a7073b          	addw	a4,a4,s10
ffffffffc02040e0:	0017171b          	sllw	a4,a4,0x1
ffffffffc02040e4:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc02040e6:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02040ea:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02040ec:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc02040f0:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc02040f4:	feb570e3          	bgeu	a0,a1,ffffffffc02040d4 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc02040f8:	f60cd0e3          	bgez	s9,ffffffffc0204058 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02040fc:	8cea                	mv	s9,s10
ffffffffc02040fe:	5d7d                	li	s10,-1
ffffffffc0204100:	bfa1                	j	ffffffffc0204058 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204102:	8db6                	mv	s11,a3
ffffffffc0204104:	8462                	mv	s0,s8
ffffffffc0204106:	bf89                	j	ffffffffc0204058 <vprintfmt+0x5c>
ffffffffc0204108:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020410a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020410c:	b7b1                	j	ffffffffc0204058 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020410e:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204110:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204114:	00c7c463          	blt	a5,a2,ffffffffc020411c <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0204118:	1a060163          	beqz	a2,ffffffffc02042ba <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc020411c:	000a3603          	ld	a2,0(s4)
ffffffffc0204120:	46c1                	li	a3,16
ffffffffc0204122:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204124:	000d879b          	sext.w	a5,s11
ffffffffc0204128:	8766                	mv	a4,s9
ffffffffc020412a:	85a6                	mv	a1,s1
ffffffffc020412c:	854a                	mv	a0,s2
ffffffffc020412e:	e61ff0ef          	jal	ffffffffc0203f8e <printnum>
            break;
ffffffffc0204132:	bdfd                	j	ffffffffc0204030 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0204134:	000a2503          	lw	a0,0(s4)
ffffffffc0204138:	85a6                	mv	a1,s1
ffffffffc020413a:	0a21                	add	s4,s4,8
ffffffffc020413c:	9902                	jalr	s2
            break;
ffffffffc020413e:	bdcd                	j	ffffffffc0204030 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0204140:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204142:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204146:	00c7c463          	blt	a5,a2,ffffffffc020414e <vprintfmt+0x152>
    else if (lflag) {
ffffffffc020414a:	16060363          	beqz	a2,ffffffffc02042b0 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc020414e:	000a3603          	ld	a2,0(s4)
ffffffffc0204152:	46a9                	li	a3,10
ffffffffc0204154:	8a3a                	mv	s4,a4
ffffffffc0204156:	b7f9                	j	ffffffffc0204124 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0204158:	85a6                	mv	a1,s1
ffffffffc020415a:	03000513          	li	a0,48
ffffffffc020415e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204160:	85a6                	mv	a1,s1
ffffffffc0204162:	07800513          	li	a0,120
ffffffffc0204166:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204168:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020416c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020416e:	0a21                	add	s4,s4,8
            goto number;
ffffffffc0204170:	bf55                	j	ffffffffc0204124 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0204172:	85a6                	mv	a1,s1
ffffffffc0204174:	02500513          	li	a0,37
ffffffffc0204178:	9902                	jalr	s2
            break;
ffffffffc020417a:	bd5d                	j	ffffffffc0204030 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020417c:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204180:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0204182:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc0204184:	bf95                	j	ffffffffc02040f8 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0204186:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204188:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc020418c:	00c7c463          	blt	a5,a2,ffffffffc0204194 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0204190:	10060b63          	beqz	a2,ffffffffc02042a6 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0204194:	000a3603          	ld	a2,0(s4)
ffffffffc0204198:	46a1                	li	a3,8
ffffffffc020419a:	8a3a                	mv	s4,a4
ffffffffc020419c:	b761                	j	ffffffffc0204124 <vprintfmt+0x128>
            if (width < 0)
ffffffffc020419e:	fffcc793          	not	a5,s9
ffffffffc02041a2:	97fd                	sra	a5,a5,0x3f
ffffffffc02041a4:	00fcf7b3          	and	a5,s9,a5
ffffffffc02041a8:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041ac:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02041ae:	b56d                	j	ffffffffc0204058 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02041b0:	000a3403          	ld	s0,0(s4)
ffffffffc02041b4:	008a0793          	add	a5,s4,8
ffffffffc02041b8:	e43e                	sd	a5,8(sp)
ffffffffc02041ba:	12040063          	beqz	s0,ffffffffc02042da <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02041be:	0d905963          	blez	s9,ffffffffc0204290 <vprintfmt+0x294>
ffffffffc02041c2:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041c6:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc02041ca:	12fd9763          	bne	s11,a5,ffffffffc02042f8 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041ce:	00044783          	lbu	a5,0(s0)
ffffffffc02041d2:	0007851b          	sext.w	a0,a5
ffffffffc02041d6:	cb9d                	beqz	a5,ffffffffc020420c <vprintfmt+0x210>
ffffffffc02041d8:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02041da:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041de:	000d4563          	bltz	s10,ffffffffc02041e8 <vprintfmt+0x1ec>
ffffffffc02041e2:	3d7d                	addw	s10,s10,-1
ffffffffc02041e4:	028d0263          	beq	s10,s0,ffffffffc0204208 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc02041e8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02041ea:	0c0b8d63          	beqz	s7,ffffffffc02042c4 <vprintfmt+0x2c8>
ffffffffc02041ee:	3781                	addw	a5,a5,-32
ffffffffc02041f0:	0cfdfa63          	bgeu	s11,a5,ffffffffc02042c4 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc02041f4:	03f00513          	li	a0,63
ffffffffc02041f8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02041fa:	000a4783          	lbu	a5,0(s4)
ffffffffc02041fe:	3cfd                	addw	s9,s9,-1
ffffffffc0204200:	0a05                	add	s4,s4,1
ffffffffc0204202:	0007851b          	sext.w	a0,a5
ffffffffc0204206:	ffe1                	bnez	a5,ffffffffc02041de <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0204208:	01905963          	blez	s9,ffffffffc020421a <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc020420c:	85a6                	mv	a1,s1
ffffffffc020420e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0204212:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0204214:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204216:	fe0c9be3          	bnez	s9,ffffffffc020420c <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020421a:	6a22                	ld	s4,8(sp)
ffffffffc020421c:	bd11                	j	ffffffffc0204030 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020421e:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204220:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc0204224:	00c7c363          	blt	a5,a2,ffffffffc020422a <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0204228:	ce25                	beqz	a2,ffffffffc02042a0 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc020422a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020422e:	08044d63          	bltz	s0,ffffffffc02042c8 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0204232:	8622                	mv	a2,s0
ffffffffc0204234:	8a5e                	mv	s4,s7
ffffffffc0204236:	46a9                	li	a3,10
ffffffffc0204238:	b5f5                	j	ffffffffc0204124 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc020423a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020423e:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0204240:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc0204244:	8fb9                	xor	a5,a5,a4
ffffffffc0204246:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020424a:	02d64663          	blt	a2,a3,ffffffffc0204276 <vprintfmt+0x27a>
ffffffffc020424e:	00369713          	sll	a4,a3,0x3
ffffffffc0204252:	00002797          	auipc	a5,0x2
ffffffffc0204256:	07678793          	add	a5,a5,118 # ffffffffc02062c8 <error_string>
ffffffffc020425a:	97ba                	add	a5,a5,a4
ffffffffc020425c:	639c                	ld	a5,0(a5)
ffffffffc020425e:	cf81                	beqz	a5,ffffffffc0204276 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204260:	86be                	mv	a3,a5
ffffffffc0204262:	00002617          	auipc	a2,0x2
ffffffffc0204266:	d9660613          	add	a2,a2,-618 # ffffffffc0205ff8 <etext+0x1b0e>
ffffffffc020426a:	85a6                	mv	a1,s1
ffffffffc020426c:	854a                	mv	a0,s2
ffffffffc020426e:	0e8000ef          	jal	ffffffffc0204356 <printfmt>
            err = va_arg(ap, int);
ffffffffc0204272:	0a21                	add	s4,s4,8
ffffffffc0204274:	bb75                	j	ffffffffc0204030 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204276:	00002617          	auipc	a2,0x2
ffffffffc020427a:	d7260613          	add	a2,a2,-654 # ffffffffc0205fe8 <etext+0x1afe>
ffffffffc020427e:	85a6                	mv	a1,s1
ffffffffc0204280:	854a                	mv	a0,s2
ffffffffc0204282:	0d4000ef          	jal	ffffffffc0204356 <printfmt>
            err = va_arg(ap, int);
ffffffffc0204286:	0a21                	add	s4,s4,8
ffffffffc0204288:	b365                	j	ffffffffc0204030 <vprintfmt+0x34>
            lflag ++;
ffffffffc020428a:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020428c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020428e:	b3e9                	j	ffffffffc0204058 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204290:	00044783          	lbu	a5,0(s0)
ffffffffc0204294:	0007851b          	sext.w	a0,a5
ffffffffc0204298:	d3c9                	beqz	a5,ffffffffc020421a <vprintfmt+0x21e>
ffffffffc020429a:	00140a13          	add	s4,s0,1
ffffffffc020429e:	bf2d                	j	ffffffffc02041d8 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc02042a0:	000a2403          	lw	s0,0(s4)
ffffffffc02042a4:	b769                	j	ffffffffc020422e <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc02042a6:	000a6603          	lwu	a2,0(s4)
ffffffffc02042aa:	46a1                	li	a3,8
ffffffffc02042ac:	8a3a                	mv	s4,a4
ffffffffc02042ae:	bd9d                	j	ffffffffc0204124 <vprintfmt+0x128>
ffffffffc02042b0:	000a6603          	lwu	a2,0(s4)
ffffffffc02042b4:	46a9                	li	a3,10
ffffffffc02042b6:	8a3a                	mv	s4,a4
ffffffffc02042b8:	b5b5                	j	ffffffffc0204124 <vprintfmt+0x128>
ffffffffc02042ba:	000a6603          	lwu	a2,0(s4)
ffffffffc02042be:	46c1                	li	a3,16
ffffffffc02042c0:	8a3a                	mv	s4,a4
ffffffffc02042c2:	b58d                	j	ffffffffc0204124 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc02042c4:	9902                	jalr	s2
ffffffffc02042c6:	bf15                	j	ffffffffc02041fa <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc02042c8:	85a6                	mv	a1,s1
ffffffffc02042ca:	02d00513          	li	a0,45
ffffffffc02042ce:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02042d0:	40800633          	neg	a2,s0
ffffffffc02042d4:	8a5e                	mv	s4,s7
ffffffffc02042d6:	46a9                	li	a3,10
ffffffffc02042d8:	b5b1                	j	ffffffffc0204124 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc02042da:	01905663          	blez	s9,ffffffffc02042e6 <vprintfmt+0x2ea>
ffffffffc02042de:	02d00793          	li	a5,45
ffffffffc02042e2:	04fd9263          	bne	s11,a5,ffffffffc0204326 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02042e6:	02800793          	li	a5,40
ffffffffc02042ea:	00002a17          	auipc	s4,0x2
ffffffffc02042ee:	cf7a0a13          	add	s4,s4,-777 # ffffffffc0205fe1 <etext+0x1af7>
ffffffffc02042f2:	02800513          	li	a0,40
ffffffffc02042f6:	b5cd                	j	ffffffffc02041d8 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02042f8:	85ea                	mv	a1,s10
ffffffffc02042fa:	8522                	mv	a0,s0
ffffffffc02042fc:	148000ef          	jal	ffffffffc0204444 <strnlen>
ffffffffc0204300:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0204304:	01905963          	blez	s9,ffffffffc0204316 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0204308:	2d81                	sext.w	s11,s11
ffffffffc020430a:	85a6                	mv	a1,s1
ffffffffc020430c:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020430e:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0204310:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204312:	fe0c9ce3          	bnez	s9,ffffffffc020430a <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204316:	00044783          	lbu	a5,0(s0)
ffffffffc020431a:	0007851b          	sext.w	a0,a5
ffffffffc020431e:	ea079de3          	bnez	a5,ffffffffc02041d8 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204322:	6a22                	ld	s4,8(sp)
ffffffffc0204324:	b331                	j	ffffffffc0204030 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204326:	85ea                	mv	a1,s10
ffffffffc0204328:	00002517          	auipc	a0,0x2
ffffffffc020432c:	cb850513          	add	a0,a0,-840 # ffffffffc0205fe0 <etext+0x1af6>
ffffffffc0204330:	114000ef          	jal	ffffffffc0204444 <strnlen>
ffffffffc0204334:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0204338:	00002417          	auipc	s0,0x2
ffffffffc020433c:	ca840413          	add	s0,s0,-856 # ffffffffc0205fe0 <etext+0x1af6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204340:	00002a17          	auipc	s4,0x2
ffffffffc0204344:	ca1a0a13          	add	s4,s4,-863 # ffffffffc0205fe1 <etext+0x1af7>
ffffffffc0204348:	02800793          	li	a5,40
ffffffffc020434c:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204350:	fb904ce3          	bgtz	s9,ffffffffc0204308 <vprintfmt+0x30c>
ffffffffc0204354:	b551                	j	ffffffffc02041d8 <vprintfmt+0x1dc>

ffffffffc0204356 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204356:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204358:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020435c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020435e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204360:	ec06                	sd	ra,24(sp)
ffffffffc0204362:	f83a                	sd	a4,48(sp)
ffffffffc0204364:	fc3e                	sd	a5,56(sp)
ffffffffc0204366:	e0c2                	sd	a6,64(sp)
ffffffffc0204368:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020436a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020436c:	c91ff0ef          	jal	ffffffffc0203ffc <vprintfmt>
}
ffffffffc0204370:	60e2                	ld	ra,24(sp)
ffffffffc0204372:	6161                	add	sp,sp,80
ffffffffc0204374:	8082                	ret

ffffffffc0204376 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0204376:	715d                	add	sp,sp,-80
ffffffffc0204378:	e486                	sd	ra,72(sp)
ffffffffc020437a:	e0a2                	sd	s0,64(sp)
ffffffffc020437c:	fc26                	sd	s1,56(sp)
ffffffffc020437e:	f84a                	sd	s2,48(sp)
ffffffffc0204380:	f44e                	sd	s3,40(sp)
ffffffffc0204382:	f052                	sd	s4,32(sp)
ffffffffc0204384:	ec56                	sd	s5,24(sp)
ffffffffc0204386:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0204388:	c901                	beqz	a0,ffffffffc0204398 <readline+0x22>
ffffffffc020438a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020438c:	00002517          	auipc	a0,0x2
ffffffffc0204390:	c6c50513          	add	a0,a0,-916 # ffffffffc0205ff8 <etext+0x1b0e>
ffffffffc0204394:	d27fb0ef          	jal	ffffffffc02000ba <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0204398:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020439a:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc020439c:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020439e:	4a29                	li	s4,10
ffffffffc02043a0:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc02043a2:	0000db17          	auipc	s6,0xd
ffffffffc02043a6:	d56b0b13          	add	s6,s6,-682 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02043aa:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02043ae:	d43fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc02043b2:	00054a63          	bltz	a0,ffffffffc02043c6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02043b6:	00a4da63          	bge	s1,a0,ffffffffc02043ca <readline+0x54>
ffffffffc02043ba:	0289d263          	bge	s3,s0,ffffffffc02043de <readline+0x68>
        c = getchar();
ffffffffc02043be:	d33fb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc02043c2:	fe055ae3          	bgez	a0,ffffffffc02043b6 <readline+0x40>
            return NULL;
ffffffffc02043c6:	4501                	li	a0,0
ffffffffc02043c8:	a091                	j	ffffffffc020440c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02043ca:	03251463          	bne	a0,s2,ffffffffc02043f2 <readline+0x7c>
ffffffffc02043ce:	04804963          	bgtz	s0,ffffffffc0204420 <readline+0xaa>
        c = getchar();
ffffffffc02043d2:	d1ffb0ef          	jal	ffffffffc02000f0 <getchar>
        if (c < 0) {
ffffffffc02043d6:	fe0548e3          	bltz	a0,ffffffffc02043c6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02043da:	fea4d8e3          	bge	s1,a0,ffffffffc02043ca <readline+0x54>
            cputchar(c);
ffffffffc02043de:	e42a                	sd	a0,8(sp)
ffffffffc02043e0:	d0ffb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i ++] = c;
ffffffffc02043e4:	6522                	ld	a0,8(sp)
ffffffffc02043e6:	008b07b3          	add	a5,s6,s0
ffffffffc02043ea:	2405                	addw	s0,s0,1
ffffffffc02043ec:	00a78023          	sb	a0,0(a5)
ffffffffc02043f0:	bf7d                	j	ffffffffc02043ae <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02043f2:	01450463          	beq	a0,s4,ffffffffc02043fa <readline+0x84>
ffffffffc02043f6:	fb551ce3          	bne	a0,s5,ffffffffc02043ae <readline+0x38>
            cputchar(c);
ffffffffc02043fa:	cf5fb0ef          	jal	ffffffffc02000ee <cputchar>
            buf[i] = '\0';
ffffffffc02043fe:	0000d517          	auipc	a0,0xd
ffffffffc0204402:	cfa50513          	add	a0,a0,-774 # ffffffffc02110f8 <buf>
ffffffffc0204406:	942a                	add	s0,s0,a0
ffffffffc0204408:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc020440c:	60a6                	ld	ra,72(sp)
ffffffffc020440e:	6406                	ld	s0,64(sp)
ffffffffc0204410:	74e2                	ld	s1,56(sp)
ffffffffc0204412:	7942                	ld	s2,48(sp)
ffffffffc0204414:	79a2                	ld	s3,40(sp)
ffffffffc0204416:	7a02                	ld	s4,32(sp)
ffffffffc0204418:	6ae2                	ld	s5,24(sp)
ffffffffc020441a:	6b42                	ld	s6,16(sp)
ffffffffc020441c:	6161                	add	sp,sp,80
ffffffffc020441e:	8082                	ret
            cputchar(c);
ffffffffc0204420:	4521                	li	a0,8
ffffffffc0204422:	ccdfb0ef          	jal	ffffffffc02000ee <cputchar>
            i --;
ffffffffc0204426:	347d                	addw	s0,s0,-1
ffffffffc0204428:	b759                	j	ffffffffc02043ae <readline+0x38>

ffffffffc020442a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020442a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020442e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204430:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204432:	cb81                	beqz	a5,ffffffffc0204442 <strlen+0x18>
        cnt ++;
ffffffffc0204434:	0505                	add	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204436:	00a707b3          	add	a5,a4,a0
ffffffffc020443a:	0007c783          	lbu	a5,0(a5)
ffffffffc020443e:	fbfd                	bnez	a5,ffffffffc0204434 <strlen+0xa>
ffffffffc0204440:	8082                	ret
    }
    return cnt;
}
ffffffffc0204442:	8082                	ret

ffffffffc0204444 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204444:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204446:	e589                	bnez	a1,ffffffffc0204450 <strnlen+0xc>
ffffffffc0204448:	a811                	j	ffffffffc020445c <strnlen+0x18>
        cnt ++;
ffffffffc020444a:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020444c:	00f58863          	beq	a1,a5,ffffffffc020445c <strnlen+0x18>
ffffffffc0204450:	00f50733          	add	a4,a0,a5
ffffffffc0204454:	00074703          	lbu	a4,0(a4)
ffffffffc0204458:	fb6d                	bnez	a4,ffffffffc020444a <strnlen+0x6>
ffffffffc020445a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020445c:	852e                	mv	a0,a1
ffffffffc020445e:	8082                	ret

ffffffffc0204460 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204460:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204462:	0005c703          	lbu	a4,0(a1)
ffffffffc0204466:	0785                	add	a5,a5,1
ffffffffc0204468:	0585                	add	a1,a1,1
ffffffffc020446a:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020446e:	fb75                	bnez	a4,ffffffffc0204462 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204470:	8082                	ret

ffffffffc0204472 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204472:	00054783          	lbu	a5,0(a0)
ffffffffc0204476:	e791                	bnez	a5,ffffffffc0204482 <strcmp+0x10>
ffffffffc0204478:	a02d                	j	ffffffffc02044a2 <strcmp+0x30>
ffffffffc020447a:	00054783          	lbu	a5,0(a0)
ffffffffc020447e:	cf89                	beqz	a5,ffffffffc0204498 <strcmp+0x26>
ffffffffc0204480:	85b6                	mv	a1,a3
ffffffffc0204482:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0204486:	0505                	add	a0,a0,1
ffffffffc0204488:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020448c:	fef707e3          	beq	a4,a5,ffffffffc020447a <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204490:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204494:	9d19                	subw	a0,a0,a4
ffffffffc0204496:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204498:	0015c703          	lbu	a4,1(a1)
ffffffffc020449c:	4501                	li	a0,0
}
ffffffffc020449e:	9d19                	subw	a0,a0,a4
ffffffffc02044a0:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02044a2:	0005c703          	lbu	a4,0(a1)
ffffffffc02044a6:	4501                	li	a0,0
ffffffffc02044a8:	b7f5                	j	ffffffffc0204494 <strcmp+0x22>

ffffffffc02044aa <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02044aa:	00054783          	lbu	a5,0(a0)
ffffffffc02044ae:	c799                	beqz	a5,ffffffffc02044bc <strchr+0x12>
        if (*s == c) {
ffffffffc02044b0:	00f58763          	beq	a1,a5,ffffffffc02044be <strchr+0x14>
    while (*s != '\0') {
ffffffffc02044b4:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02044b8:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc02044ba:	fbfd                	bnez	a5,ffffffffc02044b0 <strchr+0x6>
    }
    return NULL;
ffffffffc02044bc:	4501                	li	a0,0
}
ffffffffc02044be:	8082                	ret

ffffffffc02044c0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02044c0:	ca01                	beqz	a2,ffffffffc02044d0 <memset+0x10>
ffffffffc02044c2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02044c4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02044c6:	0785                	add	a5,a5,1
ffffffffc02044c8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02044cc:	fef61de3          	bne	a2,a5,ffffffffc02044c6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02044d0:	8082                	ret

ffffffffc02044d2 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02044d2:	ca19                	beqz	a2,ffffffffc02044e8 <memcpy+0x16>
ffffffffc02044d4:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02044d6:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02044d8:	0005c703          	lbu	a4,0(a1)
ffffffffc02044dc:	0585                	add	a1,a1,1
ffffffffc02044de:	0785                	add	a5,a5,1
ffffffffc02044e0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02044e4:	feb61ae3          	bne	a2,a1,ffffffffc02044d8 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02044e8:	8082                	ret
