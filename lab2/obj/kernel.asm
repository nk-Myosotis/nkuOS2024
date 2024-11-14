
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
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
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	add	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	add	a0,a0,-34 # ffffffffc0206010 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	43660613          	add	a2,a2,1078 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	add	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	18b010ef          	jal	ffffffffc02019d4 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3f8000ef          	jal	ffffffffc0200446 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	99650513          	add	a0,a0,-1642 # ffffffffc02019e8 <etext+0x2>
ffffffffc020005a:	08e000ef          	jal	ffffffffc02000e8 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e8000ef          	jal	ffffffffc0200146 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	3fe000ef          	jal	ffffffffc0200460 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	274010ef          	jal	ffffffffc02012da <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3f6000ef          	jal	ffffffffc0200460 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	396000ef          	jal	ffffffffc0200404 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e2000ef          	jal	ffffffffc0200454 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	add	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3c8000ef          	jal	ffffffffc0200448 <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	add	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	add	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	add	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	add	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	446010ef          	jal	ffffffffc02014ec <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	add	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	add	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	add	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	f42e                	sd	a1,40(sp)
ffffffffc02000ba:	f832                	sd	a2,48(sp)
ffffffffc02000bc:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	862a                	mv	a2,a0
ffffffffc02000c0:	004c                	add	a1,sp,4
ffffffffc02000c2:	00000517          	auipc	a0,0x0
ffffffffc02000c6:	fb650513          	add	a0,a0,-74 # ffffffffc0200078 <cputch>
ffffffffc02000ca:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
ffffffffc02000ce:	e0ba                	sd	a4,64(sp)
ffffffffc02000d0:	e4be                	sd	a5,72(sp)
ffffffffc02000d2:	e8c2                	sd	a6,80(sp)
ffffffffc02000d4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000d8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	412010ef          	jal	ffffffffc02014ec <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4512                	lw	a0,4(sp)
ffffffffc02000e2:	6125                	add	sp,sp,96
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e6:	a68d                	j	ffffffffc0200448 <cons_putc>

ffffffffc02000e8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000e8:	1101                	add	sp,sp,-32
ffffffffc02000ea:	ec06                	sd	ra,24(sp)
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f0:	00054503          	lbu	a0,0(a0)
ffffffffc02000f4:	c905                	beqz	a0,ffffffffc0200124 <cputs+0x3c>
ffffffffc02000f6:	e426                	sd	s1,8(sp)
ffffffffc02000f8:	00178493          	add	s1,a5,1
ffffffffc02000fc:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc02000fe:	34a000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200102:	00044503          	lbu	a0,0(s0)
ffffffffc0200106:	87a2                	mv	a5,s0
ffffffffc0200108:	0405                	add	s0,s0,1
ffffffffc020010a:	f975                	bnez	a0,ffffffffc02000fe <cputs+0x16>
    (*cnt) ++;
ffffffffc020010c:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc020010e:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200110:	0027841b          	addw	s0,a5,2
ffffffffc0200114:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc0200116:	332000ef          	jal	ffffffffc0200448 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	6105                	add	sp,sp,32
ffffffffc0200122:	8082                	ret
    cons_putc(c);
ffffffffc0200124:	4529                	li	a0,10
ffffffffc0200126:	322000ef          	jal	ffffffffc0200448 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
}
ffffffffc020012c:	60e2                	ld	ra,24(sp)
ffffffffc020012e:	8522                	mv	a0,s0
ffffffffc0200130:	6442                	ld	s0,16(sp)
ffffffffc0200132:	6105                	add	sp,sp,32
ffffffffc0200134:	8082                	ret

ffffffffc0200136 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200136:	1141                	add	sp,sp,-16
ffffffffc0200138:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020013a:	316000ef          	jal	ffffffffc0200450 <cons_getc>
ffffffffc020013e:	dd75                	beqz	a0,ffffffffc020013a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200140:	60a2                	ld	ra,8(sp)
ffffffffc0200142:	0141                	add	sp,sp,16
ffffffffc0200144:	8082                	ret

ffffffffc0200146 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200146:	1141                	add	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200148:	00002517          	auipc	a0,0x2
ffffffffc020014c:	8c050513          	add	a0,a0,-1856 # ffffffffc0201a08 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200150:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200152:	f61ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200156:	00000597          	auipc	a1,0x0
ffffffffc020015a:	edc58593          	add	a1,a1,-292 # ffffffffc0200032 <kern_init>
ffffffffc020015e:	00002517          	auipc	a0,0x2
ffffffffc0200162:	8ca50513          	add	a0,a0,-1846 # ffffffffc0201a28 <etext+0x42>
ffffffffc0200166:	f4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020016a:	00002597          	auipc	a1,0x2
ffffffffc020016e:	87c58593          	add	a1,a1,-1924 # ffffffffc02019e6 <etext>
ffffffffc0200172:	00002517          	auipc	a0,0x2
ffffffffc0200176:	8d650513          	add	a0,a0,-1834 # ffffffffc0201a48 <etext+0x62>
ffffffffc020017a:	f39ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017e:	00006597          	auipc	a1,0x6
ffffffffc0200182:	e9258593          	add	a1,a1,-366 # ffffffffc0206010 <free_area>
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	8e250513          	add	a0,a0,-1822 # ffffffffc0201a68 <etext+0x82>
ffffffffc020018e:	f25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200192:	00006597          	auipc	a1,0x6
ffffffffc0200196:	2de58593          	add	a1,a1,734 # ffffffffc0206470 <end>
ffffffffc020019a:	00002517          	auipc	a0,0x2
ffffffffc020019e:	8ee50513          	add	a0,a0,-1810 # ffffffffc0201a88 <etext+0xa2>
ffffffffc02001a2:	f11ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001a6:	00006797          	auipc	a5,0x6
ffffffffc02001aa:	6c978793          	add	a5,a5,1737 # ffffffffc020686f <end+0x3ff>
ffffffffc02001ae:	00000717          	auipc	a4,0x0
ffffffffc02001b2:	e8470713          	add	a4,a4,-380 # ffffffffc0200032 <kern_init>
ffffffffc02001b6:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	43f7d593          	sra	a1,a5,0x3f
}
ffffffffc02001bc:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001be:	3ff5f593          	and	a1,a1,1023
ffffffffc02001c2:	95be                	add	a1,a1,a5
ffffffffc02001c4:	85a9                	sra	a1,a1,0xa
ffffffffc02001c6:	00002517          	auipc	a0,0x2
ffffffffc02001ca:	8e250513          	add	a0,a0,-1822 # ffffffffc0201aa8 <etext+0xc2>
}
ffffffffc02001ce:	0141                	add	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d0:	b5cd                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001d2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001d2:	1141                	add	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d4:	00002617          	auipc	a2,0x2
ffffffffc02001d8:	90460613          	add	a2,a2,-1788 # ffffffffc0201ad8 <etext+0xf2>
ffffffffc02001dc:	04e00593          	li	a1,78
ffffffffc02001e0:	00002517          	auipc	a0,0x2
ffffffffc02001e4:	91050513          	add	a0,a0,-1776 # ffffffffc0201af0 <etext+0x10a>
void print_stackframe(void) {
ffffffffc02001e8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ea:	1bc000ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02001ee <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ee:	1141                	add	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	91860613          	add	a2,a2,-1768 # ffffffffc0201b08 <etext+0x122>
ffffffffc02001f8:	00002597          	auipc	a1,0x2
ffffffffc02001fc:	93058593          	add	a1,a1,-1744 # ffffffffc0201b28 <etext+0x142>
ffffffffc0200200:	00002517          	auipc	a0,0x2
ffffffffc0200204:	93050513          	add	a0,a0,-1744 # ffffffffc0201b30 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	ea9ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020020e:	00002617          	auipc	a2,0x2
ffffffffc0200212:	93260613          	add	a2,a2,-1742 # ffffffffc0201b40 <etext+0x15a>
ffffffffc0200216:	00002597          	auipc	a1,0x2
ffffffffc020021a:	95258593          	add	a1,a1,-1710 # ffffffffc0201b68 <etext+0x182>
ffffffffc020021e:	00002517          	auipc	a0,0x2
ffffffffc0200222:	91250513          	add	a0,a0,-1774 # ffffffffc0201b30 <etext+0x14a>
ffffffffc0200226:	e8dff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	94e60613          	add	a2,a2,-1714 # ffffffffc0201b78 <etext+0x192>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	96658593          	add	a1,a1,-1690 # ffffffffc0201b98 <etext+0x1b2>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	8f650513          	add	a0,a0,-1802 # ffffffffc0201b30 <etext+0x14a>
ffffffffc0200242:	e71ff0ef          	jal	ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc0200246:	60a2                	ld	ra,8(sp)
ffffffffc0200248:	4501                	li	a0,0
ffffffffc020024a:	0141                	add	sp,sp,16
ffffffffc020024c:	8082                	ret

ffffffffc020024e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024e:	1141                	add	sp,sp,-16
ffffffffc0200250:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200252:	ef5ff0ef          	jal	ffffffffc0200146 <print_kerninfo>
    return 0;
}
ffffffffc0200256:	60a2                	ld	ra,8(sp)
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	0141                	add	sp,sp,16
ffffffffc020025c:	8082                	ret

ffffffffc020025e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025e:	1141                	add	sp,sp,-16
ffffffffc0200260:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200262:	f71ff0ef          	jal	ffffffffc02001d2 <print_stackframe>
    return 0;
}
ffffffffc0200266:	60a2                	ld	ra,8(sp)
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	0141                	add	sp,sp,16
ffffffffc020026c:	8082                	ret

ffffffffc020026e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026e:	7115                	add	sp,sp,-224
ffffffffc0200270:	f15a                	sd	s6,160(sp)
ffffffffc0200272:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200274:	00002517          	auipc	a0,0x2
ffffffffc0200278:	93450513          	add	a0,a0,-1740 # ffffffffc0201ba8 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc020027c:	ed86                	sd	ra,216(sp)
ffffffffc020027e:	e9a2                	sd	s0,208(sp)
ffffffffc0200280:	e5a6                	sd	s1,200(sp)
ffffffffc0200282:	e1ca                	sd	s2,192(sp)
ffffffffc0200284:	fd4e                	sd	s3,184(sp)
ffffffffc0200286:	f952                	sd	s4,176(sp)
ffffffffc0200288:	f556                	sd	s5,168(sp)
ffffffffc020028a:	ed5e                	sd	s7,152(sp)
ffffffffc020028c:	e962                	sd	s8,144(sp)
ffffffffc020028e:	e566                	sd	s9,136(sp)
ffffffffc0200290:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200292:	e21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200296:	00002517          	auipc	a0,0x2
ffffffffc020029a:	93a50513          	add	a0,a0,-1734 # ffffffffc0201bd0 <etext+0x1ea>
ffffffffc020029e:	e15ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002a2:	000b0563          	beqz	s6,ffffffffc02002ac <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a6:	855a                	mv	a0,s6
ffffffffc02002a8:	396000ef          	jal	ffffffffc020063e <print_trapframe>
ffffffffc02002ac:	00002c17          	auipc	s8,0x2
ffffffffc02002b0:	344c0c13          	add	s8,s8,836 # ffffffffc02025f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b4:	00002917          	auipc	s2,0x2
ffffffffc02002b8:	94490913          	add	s2,s2,-1724 # ffffffffc0201bf8 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002bc:	00002497          	auipc	s1,0x2
ffffffffc02002c0:	94448493          	add	s1,s1,-1724 # ffffffffc0201c00 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002c4:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c6:	00002a97          	auipc	s5,0x2
ffffffffc02002ca:	942a8a93          	add	s5,s5,-1726 # ffffffffc0201c08 <etext+0x222>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002d0:	00002b97          	auipc	s7,0x2
ffffffffc02002d4:	958b8b93          	add	s7,s7,-1704 # ffffffffc0201c28 <etext+0x242>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	854a                	mv	a0,s2
ffffffffc02002da:	58c010ef          	jal	ffffffffc0201866 <readline>
ffffffffc02002de:	842a                	mv	s0,a0
ffffffffc02002e0:	dd65                	beqz	a0,ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e6:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e8:	e59d                	bnez	a1,ffffffffc0200316 <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc02002ea:	fe0c87e3          	beqz	s9,ffffffffc02002d8 <kmonitor+0x6a>
ffffffffc02002ee:	00002d17          	auipc	s10,0x2
ffffffffc02002f2:	302d0d13          	add	s10,s10,770 # ffffffffc02025f0 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	000d3503          	ld	a0,0(s10)
ffffffffc02002fe:	688010ef          	jal	ffffffffc0201986 <strcmp>
ffffffffc0200302:	c53d                	beqz	a0,ffffffffc0200370 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200304:	2405                	addw	s0,s0,1
ffffffffc0200306:	0d61                	add	s10,s10,24
ffffffffc0200308:	ff4418e3          	bne	s0,s4,ffffffffc02002f8 <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020030c:	6582                	ld	a1,0(sp)
ffffffffc020030e:	855e                	mv	a0,s7
ffffffffc0200310:	da3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc0200314:	b7d1                	j	ffffffffc02002d8 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200316:	8526                	mv	a0,s1
ffffffffc0200318:	6a6010ef          	jal	ffffffffc02019be <strchr>
ffffffffc020031c:	c901                	beqz	a0,ffffffffc020032c <kmonitor+0xbe>
ffffffffc020031e:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200322:	00040023          	sb	zero,0(s0)
ffffffffc0200326:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200328:	d1e9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020032a:	b7f5                	j	ffffffffc0200316 <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc020032c:	00044783          	lbu	a5,0(s0)
ffffffffc0200330:	dfcd                	beqz	a5,ffffffffc02002ea <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200332:	033c8a63          	beq	s9,s3,ffffffffc0200366 <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc0200336:	003c9793          	sll	a5,s9,0x3
ffffffffc020033a:	08078793          	add	a5,a5,128
ffffffffc020033e:	978a                	add	a5,a5,sp
ffffffffc0200340:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200344:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200348:	2c85                	addw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020034a:	e591                	bnez	a1,ffffffffc0200356 <kmonitor+0xe8>
ffffffffc020034c:	bf79                	j	ffffffffc02002ea <kmonitor+0x7c>
ffffffffc020034e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200352:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200354:	d9d9                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200356:	8526                	mv	a0,s1
ffffffffc0200358:	666010ef          	jal	ffffffffc02019be <strchr>
ffffffffc020035c:	d96d                	beqz	a0,ffffffffc020034e <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020035e:	00044583          	lbu	a1,0(s0)
ffffffffc0200362:	d5c1                	beqz	a1,ffffffffc02002ea <kmonitor+0x7c>
ffffffffc0200364:	bf4d                	j	ffffffffc0200316 <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200366:	45c1                	li	a1,16
ffffffffc0200368:	8556                	mv	a0,s5
ffffffffc020036a:	d49ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020036e:	b7e1                	j	ffffffffc0200336 <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200370:	00141793          	sll	a5,s0,0x1
ffffffffc0200374:	97a2                	add	a5,a5,s0
ffffffffc0200376:	078e                	sll	a5,a5,0x3
ffffffffc0200378:	97e2                	add	a5,a5,s8
ffffffffc020037a:	6b9c                	ld	a5,16(a5)
ffffffffc020037c:	865a                	mv	a2,s6
ffffffffc020037e:	002c                	add	a1,sp,8
ffffffffc0200380:	fffc851b          	addw	a0,s9,-1
ffffffffc0200384:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200386:	f40559e3          	bgez	a0,ffffffffc02002d8 <kmonitor+0x6a>
}
ffffffffc020038a:	60ee                	ld	ra,216(sp)
ffffffffc020038c:	644e                	ld	s0,208(sp)
ffffffffc020038e:	64ae                	ld	s1,200(sp)
ffffffffc0200390:	690e                	ld	s2,192(sp)
ffffffffc0200392:	79ea                	ld	s3,184(sp)
ffffffffc0200394:	7a4a                	ld	s4,176(sp)
ffffffffc0200396:	7aaa                	ld	s5,168(sp)
ffffffffc0200398:	7b0a                	ld	s6,160(sp)
ffffffffc020039a:	6bea                	ld	s7,152(sp)
ffffffffc020039c:	6c4a                	ld	s8,144(sp)
ffffffffc020039e:	6caa                	ld	s9,136(sp)
ffffffffc02003a0:	6d0a                	ld	s10,128(sp)
ffffffffc02003a2:	612d                	add	sp,sp,224
ffffffffc02003a4:	8082                	ret

ffffffffc02003a6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003a6:	00006317          	auipc	t1,0x6
ffffffffc02003aa:	08230313          	add	t1,t1,130 # ffffffffc0206428 <is_panic>
ffffffffc02003ae:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b2:	715d                	add	sp,sp,-80
ffffffffc02003b4:	ec06                	sd	ra,24(sp)
ffffffffc02003b6:	f436                	sd	a3,40(sp)
ffffffffc02003b8:	f83a                	sd	a4,48(sp)
ffffffffc02003ba:	fc3e                	sd	a5,56(sp)
ffffffffc02003bc:	e0c2                	sd	a6,64(sp)
ffffffffc02003be:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c0:	020e1c63          	bnez	t3,ffffffffc02003f8 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003c4:	4785                	li	a5,1
ffffffffc02003c6:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003ca:	e822                	sd	s0,16(sp)
ffffffffc02003cc:	103c                	add	a5,sp,40
ffffffffc02003ce:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d0:	862e                	mv	a2,a1
ffffffffc02003d2:	85aa                	mv	a1,a0
ffffffffc02003d4:	00002517          	auipc	a0,0x2
ffffffffc02003d8:	86c50513          	add	a0,a0,-1940 # ffffffffc0201c40 <etext+0x25a>
    va_start(ap, fmt);
ffffffffc02003dc:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	cd5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e2:	65a2                	ld	a1,8(sp)
ffffffffc02003e4:	8522                	mv	a0,s0
ffffffffc02003e6:	cadff0ef          	jal	ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003ea:	00002517          	auipc	a0,0x2
ffffffffc02003ee:	87650513          	add	a0,a0,-1930 # ffffffffc0201c60 <etext+0x27a>
ffffffffc02003f2:	cc1ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc02003f6:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003f8:	062000ef          	jal	ffffffffc020045a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	e71ff0ef          	jal	ffffffffc020026e <kmonitor>
    while (1) {
ffffffffc0200402:	bfed                	j	ffffffffc02003fc <__panic+0x56>

ffffffffc0200404 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200404:	1141                	add	sp,sp,-16
ffffffffc0200406:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200408:	02000793          	li	a5,32
ffffffffc020040c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200410:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200414:	67e1                	lui	a5,0x18
ffffffffc0200416:	6a078793          	add	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041a:	953e                	add	a0,a0,a5
ffffffffc020041c:	518010ef          	jal	ffffffffc0201934 <sbi_set_timer>
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	0007b723          	sd	zero,14(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	83e50513          	add	a0,a0,-1986 # ffffffffc0201c68 <etext+0x282>
}
ffffffffc0200432:	0141                	add	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200434:	b9bd                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200436 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	add	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	4f20106f          	j	ffffffffc0201934 <sbi_set_timer>

ffffffffc0200446 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200446:	8082                	ret

ffffffffc0200448 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200448:	0ff57513          	zext.b	a0,a0
ffffffffc020044c:	4ce0106f          	j	ffffffffc020191a <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200450:	4fe0106f          	j	ffffffffc020194e <sbi_console_getchar>

ffffffffc0200454 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200454:	100167f3          	csrrs	a5,sstatus,2
ffffffffc0200458:	8082                	ret

ffffffffc020045a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045a:	100177f3          	csrrc	a5,sstatus,2
ffffffffc020045e:	8082                	ret

ffffffffc0200460 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200460:	14005073          	csrw	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200464:	00000797          	auipc	a5,0x0
ffffffffc0200468:	2e878793          	add	a5,a5,744 # ffffffffc020074c <__alltraps>
ffffffffc020046c:	10579073          	csrw	stvec,a5
}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200472:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200474:	1141                	add	sp,sp,-16
ffffffffc0200476:	e022                	sd	s0,0(sp)
ffffffffc0200478:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047a:	00002517          	auipc	a0,0x2
ffffffffc020047e:	80e50513          	add	a0,a0,-2034 # ffffffffc0201c88 <etext+0x2a2>
void print_regs(struct pushregs *gpr) {
ffffffffc0200482:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	c2fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	81650513          	add	a0,a0,-2026 # ffffffffc0201ca0 <etext+0x2ba>
ffffffffc0200492:	c21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00002517          	auipc	a0,0x2
ffffffffc020049c:	82050513          	add	a0,a0,-2016 # ffffffffc0201cb8 <etext+0x2d2>
ffffffffc02004a0:	c13ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00002517          	auipc	a0,0x2
ffffffffc02004aa:	82a50513          	add	a0,a0,-2006 # ffffffffc0201cd0 <etext+0x2ea>
ffffffffc02004ae:	c05ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	83450513          	add	a0,a0,-1996 # ffffffffc0201ce8 <etext+0x302>
ffffffffc02004bc:	bf7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00002517          	auipc	a0,0x2
ffffffffc02004c6:	83e50513          	add	a0,a0,-1986 # ffffffffc0201d00 <etext+0x31a>
ffffffffc02004ca:	be9ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00002517          	auipc	a0,0x2
ffffffffc02004d4:	84850513          	add	a0,a0,-1976 # ffffffffc0201d18 <etext+0x332>
ffffffffc02004d8:	bdbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00002517          	auipc	a0,0x2
ffffffffc02004e2:	85250513          	add	a0,a0,-1966 # ffffffffc0201d30 <etext+0x34a>
ffffffffc02004e6:	bcdff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00002517          	auipc	a0,0x2
ffffffffc02004f0:	85c50513          	add	a0,a0,-1956 # ffffffffc0201d48 <etext+0x362>
ffffffffc02004f4:	bbfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	86650513          	add	a0,a0,-1946 # ffffffffc0201d60 <etext+0x37a>
ffffffffc0200502:	bb1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00002517          	auipc	a0,0x2
ffffffffc020050c:	87050513          	add	a0,a0,-1936 # ffffffffc0201d78 <etext+0x392>
ffffffffc0200510:	ba3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00002517          	auipc	a0,0x2
ffffffffc020051a:	87a50513          	add	a0,a0,-1926 # ffffffffc0201d90 <etext+0x3aa>
ffffffffc020051e:	b95ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00002517          	auipc	a0,0x2
ffffffffc0200528:	88450513          	add	a0,a0,-1916 # ffffffffc0201da8 <etext+0x3c2>
ffffffffc020052c:	b87ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00002517          	auipc	a0,0x2
ffffffffc0200536:	88e50513          	add	a0,a0,-1906 # ffffffffc0201dc0 <etext+0x3da>
ffffffffc020053a:	b79ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00002517          	auipc	a0,0x2
ffffffffc0200544:	89850513          	add	a0,a0,-1896 # ffffffffc0201dd8 <etext+0x3f2>
ffffffffc0200548:	b6bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00002517          	auipc	a0,0x2
ffffffffc0200552:	8a250513          	add	a0,a0,-1886 # ffffffffc0201df0 <etext+0x40a>
ffffffffc0200556:	b5dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00002517          	auipc	a0,0x2
ffffffffc0200560:	8ac50513          	add	a0,a0,-1876 # ffffffffc0201e08 <etext+0x422>
ffffffffc0200564:	b4fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00002517          	auipc	a0,0x2
ffffffffc020056e:	8b650513          	add	a0,a0,-1866 # ffffffffc0201e20 <etext+0x43a>
ffffffffc0200572:	b41ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00002517          	auipc	a0,0x2
ffffffffc020057c:	8c050513          	add	a0,a0,-1856 # ffffffffc0201e38 <etext+0x452>
ffffffffc0200580:	b33ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00002517          	auipc	a0,0x2
ffffffffc020058a:	8ca50513          	add	a0,a0,-1846 # ffffffffc0201e50 <etext+0x46a>
ffffffffc020058e:	b25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00002517          	auipc	a0,0x2
ffffffffc0200598:	8d450513          	add	a0,a0,-1836 # ffffffffc0201e68 <etext+0x482>
ffffffffc020059c:	b17ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	8de50513          	add	a0,a0,-1826 # ffffffffc0201e80 <etext+0x49a>
ffffffffc02005aa:	b09ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00002517          	auipc	a0,0x2
ffffffffc02005b4:	8e850513          	add	a0,a0,-1816 # ffffffffc0201e98 <etext+0x4b2>
ffffffffc02005b8:	afbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00002517          	auipc	a0,0x2
ffffffffc02005c2:	8f250513          	add	a0,a0,-1806 # ffffffffc0201eb0 <etext+0x4ca>
ffffffffc02005c6:	aedff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00002517          	auipc	a0,0x2
ffffffffc02005d0:	8fc50513          	add	a0,a0,-1796 # ffffffffc0201ec8 <etext+0x4e2>
ffffffffc02005d4:	adfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	90650513          	add	a0,a0,-1786 # ffffffffc0201ee0 <etext+0x4fa>
ffffffffc02005e2:	ad1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00002517          	auipc	a0,0x2
ffffffffc02005ec:	91050513          	add	a0,a0,-1776 # ffffffffc0201ef8 <etext+0x512>
ffffffffc02005f0:	ac3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00002517          	auipc	a0,0x2
ffffffffc02005fa:	91a50513          	add	a0,a0,-1766 # ffffffffc0201f10 <etext+0x52a>
ffffffffc02005fe:	ab5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00002517          	auipc	a0,0x2
ffffffffc0200608:	92450513          	add	a0,a0,-1756 # ffffffffc0201f28 <etext+0x542>
ffffffffc020060c:	aa7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00002517          	auipc	a0,0x2
ffffffffc0200616:	92e50513          	add	a0,a0,-1746 # ffffffffc0201f40 <etext+0x55a>
ffffffffc020061a:	a99ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	93850513          	add	a0,a0,-1736 # ffffffffc0201f58 <etext+0x572>
ffffffffc0200628:	a8bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	93e50513          	add	a0,a0,-1730 # ffffffffc0201f70 <etext+0x58a>
}
ffffffffc020063a:	0141                	add	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	bc9d                	j	ffffffffc02000b2 <cprintf>

ffffffffc020063e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020063e:	1141                	add	sp,sp,-16
ffffffffc0200640:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200642:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200644:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	94250513          	add	a0,a0,-1726 # ffffffffc0201f88 <etext+0x5a2>
void print_trapframe(struct trapframe *tf) {
ffffffffc020064e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200650:	a63ff0ef          	jal	ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200654:	8522                	mv	a0,s0
ffffffffc0200656:	e1dff0ef          	jal	ffffffffc0200472 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065a:	10043583          	ld	a1,256(s0)
ffffffffc020065e:	00002517          	auipc	a0,0x2
ffffffffc0200662:	94250513          	add	a0,a0,-1726 # ffffffffc0201fa0 <etext+0x5ba>
ffffffffc0200666:	a4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00002517          	auipc	a0,0x2
ffffffffc0200672:	94a50513          	add	a0,a0,-1718 # ffffffffc0201fb8 <etext+0x5d2>
ffffffffc0200676:	a3dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00002517          	auipc	a0,0x2
ffffffffc0200682:	95250513          	add	a0,a0,-1710 # ffffffffc0201fd0 <etext+0x5ea>
ffffffffc0200686:	a2dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068a:	11843583          	ld	a1,280(s0)
}
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	00002517          	auipc	a0,0x2
ffffffffc0200696:	95650513          	add	a0,a0,-1706 # ffffffffc0201fe8 <etext+0x602>
}
ffffffffc020069a:	0141                	add	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069c:	bc19                	j	ffffffffc02000b2 <cprintf>

ffffffffc020069e <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc020069e:	11853783          	ld	a5,280(a0)
ffffffffc02006a2:	472d                	li	a4,11
ffffffffc02006a4:	0786                	sll	a5,a5,0x1
ffffffffc02006a6:	8385                	srl	a5,a5,0x1
ffffffffc02006a8:	06f76c63          	bltu	a4,a5,ffffffffc0200720 <interrupt_handler+0x82>
ffffffffc02006ac:	00002717          	auipc	a4,0x2
ffffffffc02006b0:	f8c70713          	add	a4,a4,-116 # ffffffffc0202638 <commands+0x48>
ffffffffc02006b4:	078a                	sll	a5,a5,0x2
ffffffffc02006b6:	97ba                	add	a5,a5,a4
ffffffffc02006b8:	439c                	lw	a5,0(a5)
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006be:	00002517          	auipc	a0,0x2
ffffffffc02006c2:	9a250513          	add	a0,a0,-1630 # ffffffffc0202060 <etext+0x67a>
ffffffffc02006c6:	b2f5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006c8:	00002517          	auipc	a0,0x2
ffffffffc02006cc:	97850513          	add	a0,a0,-1672 # ffffffffc0202040 <etext+0x65a>
ffffffffc02006d0:	b2cd                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d2:	00002517          	auipc	a0,0x2
ffffffffc02006d6:	92e50513          	add	a0,a0,-1746 # ffffffffc0202000 <etext+0x61a>
ffffffffc02006da:	bae1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006dc:	00002517          	auipc	a0,0x2
ffffffffc02006e0:	9a450513          	add	a0,a0,-1628 # ffffffffc0202080 <etext+0x69a>
ffffffffc02006e4:	b2f9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006e6:	1141                	add	sp,sp,-16
ffffffffc02006e8:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ea:	d4dff0ef          	jal	ffffffffc0200436 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006ee:	00006697          	auipc	a3,0x6
ffffffffc02006f2:	d4268693          	add	a3,a3,-702 # ffffffffc0206430 <ticks>
ffffffffc02006f6:	629c                	ld	a5,0(a3)
ffffffffc02006f8:	06400713          	li	a4,100
ffffffffc02006fc:	0785                	add	a5,a5,1
ffffffffc02006fe:	02e7f733          	remu	a4,a5,a4
ffffffffc0200702:	e29c                	sd	a5,0(a3)
ffffffffc0200704:	cf19                	beqz	a4,ffffffffc0200722 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200706:	60a2                	ld	ra,8(sp)
ffffffffc0200708:	0141                	add	sp,sp,16
ffffffffc020070a:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020070c:	00002517          	auipc	a0,0x2
ffffffffc0200710:	99c50513          	add	a0,a0,-1636 # ffffffffc02020a8 <etext+0x6c2>
ffffffffc0200714:	ba79                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200716:	00002517          	auipc	a0,0x2
ffffffffc020071a:	90a50513          	add	a0,a0,-1782 # ffffffffc0202020 <etext+0x63a>
ffffffffc020071e:	ba51                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200720:	bf39                	j	ffffffffc020063e <print_trapframe>
}
ffffffffc0200722:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200724:	06400593          	li	a1,100
ffffffffc0200728:	00002517          	auipc	a0,0x2
ffffffffc020072c:	97050513          	add	a0,a0,-1680 # ffffffffc0202098 <etext+0x6b2>
}
ffffffffc0200730:	0141                	add	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200732:	981ff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc0200736 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200736:	11853783          	ld	a5,280(a0)
ffffffffc020073a:	0007c763          	bltz	a5,ffffffffc0200748 <trap+0x12>
    switch (tf->cause) {
ffffffffc020073e:	472d                	li	a4,11
ffffffffc0200740:	00f76363          	bltu	a4,a5,ffffffffc0200746 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200744:	8082                	ret
            print_trapframe(tf);
ffffffffc0200746:	bde5                	j	ffffffffc020063e <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200748:	bf99                	j	ffffffffc020069e <interrupt_handler>
	...

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	add	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f87ff0ef          	jal	ffffffffc0200736 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200802:	00006797          	auipc	a5,0x6
ffffffffc0200806:	80e78793          	add	a5,a5,-2034 # ffffffffc0206010 <free_area>
ffffffffc020080a:	e79c                	sd	a5,8(a5)
ffffffffc020080c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020080e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200814:	00006517          	auipc	a0,0x6
ffffffffc0200818:	80c56503          	lwu	a0,-2036(a0) # ffffffffc0206020 <free_area+0x10>
ffffffffc020081c:	8082                	ret

ffffffffc020081e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020081e:	c14d                	beqz	a0,ffffffffc02008c0 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200820:	00005617          	auipc	a2,0x5
ffffffffc0200824:	7f060613          	add	a2,a2,2032 # ffffffffc0206010 <free_area>
ffffffffc0200828:	01062803          	lw	a6,16(a2)
ffffffffc020082c:	86aa                	mv	a3,a0
ffffffffc020082e:	02081793          	sll	a5,a6,0x20
ffffffffc0200832:	9381                	srl	a5,a5,0x20
ffffffffc0200834:	08a7e463          	bltu	a5,a0,ffffffffc02008bc <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200838:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc020083a:	0018059b          	addw	a1,a6,1
ffffffffc020083e:	1582                	sll	a1,a1,0x20
ffffffffc0200840:	9181                	srl	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200842:	4501                	li	a0,0
    while((le = list_next(le)) != &free_list){
ffffffffc0200844:	06c78b63          	beq	a5,a2,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) 
ffffffffc0200848:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020084c:	00d76763          	bltu	a4,a3,ffffffffc020085a <best_fit_alloc_pages+0x3c>
ffffffffc0200850:	00b77563          	bgeu	a4,a1,ffffffffc020085a <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200854:	fe878513          	add	a0,a5,-24
            min_size = p->property;
ffffffffc0200858:	85ba                	mv	a1,a4
ffffffffc020085a:	679c                	ld	a5,8(a5)
    while((le = list_next(le)) != &free_list){
ffffffffc020085c:	fec796e3          	bne	a5,a2,ffffffffc0200848 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200860:	cd29                	beqz	a0,ffffffffc02008ba <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200862:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200864:	6d18                	ld	a4,24(a0)
        if (page->property > n) 
ffffffffc0200866:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200868:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020086c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020086e:	e398                	sd	a4,0(a5)
        if (page->property > n) 
ffffffffc0200870:	02059793          	sll	a5,a1,0x20
ffffffffc0200874:	9381                	srl	a5,a5,0x20
ffffffffc0200876:	02f6f863          	bgeu	a3,a5,ffffffffc02008a6 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc020087a:	00269793          	sll	a5,a3,0x2
ffffffffc020087e:	97b6                	add	a5,a5,a3
ffffffffc0200880:	078e                	sll	a5,a5,0x3
ffffffffc0200882:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200884:	411585bb          	subw	a1,a1,a7
ffffffffc0200888:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020088a:	4689                	li	a3,2
ffffffffc020088c:	00878593          	add	a1,a5,8
ffffffffc0200890:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200894:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200896:	01878593          	add	a1,a5,24
        nr_free -= n;
ffffffffc020089a:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc020089e:	e28c                	sd	a1,0(a3)
ffffffffc02008a0:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc02008a2:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc02008a4:	ef98                	sd	a4,24(a5)
ffffffffc02008a6:	4118083b          	subw	a6,a6,a7
ffffffffc02008aa:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008ae:	57f5                	li	a5,-3
ffffffffc02008b0:	00850713          	add	a4,a0,8
ffffffffc02008b4:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc02008b8:	8082                	ret
}
ffffffffc02008ba:	8082                	ret
        return NULL;
ffffffffc02008bc:	4501                	li	a0,0
ffffffffc02008be:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02008c0:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc02008c2:	00002697          	auipc	a3,0x2
ffffffffc02008c6:	80668693          	add	a3,a3,-2042 # ffffffffc02020c8 <etext+0x6e2>
ffffffffc02008ca:	00002617          	auipc	a2,0x2
ffffffffc02008ce:	80660613          	add	a2,a2,-2042 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc02008d2:	06f00593          	li	a1,111
ffffffffc02008d6:	00002517          	auipc	a0,0x2
ffffffffc02008da:	81250513          	add	a0,a0,-2030 # ffffffffc02020e8 <etext+0x702>
best_fit_alloc_pages(size_t n) {
ffffffffc02008de:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02008e0:	ac7ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02008e4 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02008e4:	715d                	add	sp,sp,-80
ffffffffc02008e6:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02008e8:	00005417          	auipc	s0,0x5
ffffffffc02008ec:	72840413          	add	s0,s0,1832 # ffffffffc0206010 <free_area>
ffffffffc02008f0:	641c                	ld	a5,8(s0)
ffffffffc02008f2:	e486                	sd	ra,72(sp)
ffffffffc02008f4:	fc26                	sd	s1,56(sp)
ffffffffc02008f6:	f84a                	sd	s2,48(sp)
ffffffffc02008f8:	f44e                	sd	s3,40(sp)
ffffffffc02008fa:	f052                	sd	s4,32(sp)
ffffffffc02008fc:	ec56                	sd	s5,24(sp)
ffffffffc02008fe:	e85a                	sd	s6,16(sp)
ffffffffc0200900:	e45e                	sd	s7,8(sp)
ffffffffc0200902:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200904:	28878463          	beq	a5,s0,ffffffffc0200b8c <best_fit_check+0x2a8>
    int count = 0, total = 0;
ffffffffc0200908:	4481                	li	s1,0
ffffffffc020090a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020090c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200910:	8b09                	and	a4,a4,2
ffffffffc0200912:	28070163          	beqz	a4,ffffffffc0200b94 <best_fit_check+0x2b0>
        count ++, total += p->property;
ffffffffc0200916:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091a:	679c                	ld	a5,8(a5)
ffffffffc020091c:	2905                	addw	s2,s2,1
ffffffffc020091e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200920:	fe8796e3          	bne	a5,s0,ffffffffc020090c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200924:	89a6                	mv	s3,s1
ffffffffc0200926:	17b000ef          	jal	ffffffffc02012a0 <nr_free_pages>
ffffffffc020092a:	35351563          	bne	a0,s3,ffffffffc0200c74 <best_fit_check+0x390>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020092e:	4505                	li	a0,1
ffffffffc0200930:	0f3000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200934:	8a2a                	mv	s4,a0
ffffffffc0200936:	36050f63          	beqz	a0,ffffffffc0200cb4 <best_fit_check+0x3d0>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020093a:	4505                	li	a0,1
ffffffffc020093c:	0e7000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200940:	89aa                	mv	s3,a0
ffffffffc0200942:	34050963          	beqz	a0,ffffffffc0200c94 <best_fit_check+0x3b0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200946:	4505                	li	a0,1
ffffffffc0200948:	0db000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc020094c:	8aaa                	mv	s5,a0
ffffffffc020094e:	2e050363          	beqz	a0,ffffffffc0200c34 <best_fit_check+0x350>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200952:	273a0163          	beq	s4,s3,ffffffffc0200bb4 <best_fit_check+0x2d0>
ffffffffc0200956:	24aa0f63          	beq	s4,a0,ffffffffc0200bb4 <best_fit_check+0x2d0>
ffffffffc020095a:	24a98d63          	beq	s3,a0,ffffffffc0200bb4 <best_fit_check+0x2d0>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020095e:	000a2783          	lw	a5,0(s4)
ffffffffc0200962:	26079963          	bnez	a5,ffffffffc0200bd4 <best_fit_check+0x2f0>
ffffffffc0200966:	0009a783          	lw	a5,0(s3)
ffffffffc020096a:	26079563          	bnez	a5,ffffffffc0200bd4 <best_fit_check+0x2f0>
ffffffffc020096e:	411c                	lw	a5,0(a0)
ffffffffc0200970:	26079263          	bnez	a5,ffffffffc0200bd4 <best_fit_check+0x2f0>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200974:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200978:	ccd78793          	add	a5,a5,-819 # fffffffffccccccd <end+0x3cac685d>
ffffffffc020097c:	07b2                	sll	a5,a5,0xc
ffffffffc020097e:	ccd78793          	add	a5,a5,-819
ffffffffc0200982:	07b2                	sll	a5,a5,0xc
ffffffffc0200984:	00006717          	auipc	a4,0x6
ffffffffc0200988:	adc73703          	ld	a4,-1316(a4) # ffffffffc0206460 <pages>
ffffffffc020098c:	ccd78793          	add	a5,a5,-819
ffffffffc0200990:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200994:	07b2                	sll	a5,a5,0xc
ffffffffc0200996:	868d                	sra	a3,a3,0x3
ffffffffc0200998:	ccd78793          	add	a5,a5,-819
ffffffffc020099c:	02f686b3          	mul	a3,a3,a5
ffffffffc02009a0:	00002597          	auipc	a1,0x2
ffffffffc02009a4:	e905b583          	ld	a1,-368(a1) # ffffffffc0202830 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a8:	00006617          	auipc	a2,0x6
ffffffffc02009ac:	ab063603          	ld	a2,-1360(a2) # ffffffffc0206458 <npage>
ffffffffc02009b0:	0632                	sll	a2,a2,0xc
ffffffffc02009b2:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02009b4:	06b2                	sll	a3,a3,0xc
ffffffffc02009b6:	22c6ff63          	bgeu	a3,a2,ffffffffc0200bf4 <best_fit_check+0x310>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009ba:	40e986b3          	sub	a3,s3,a4
ffffffffc02009be:	868d                	sra	a3,a3,0x3
ffffffffc02009c0:	02f686b3          	mul	a3,a3,a5
ffffffffc02009c4:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02009c6:	06b2                	sll	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02009c8:	3ec6f663          	bgeu	a3,a2,ffffffffc0200db4 <best_fit_check+0x4d0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009cc:	40e50733          	sub	a4,a0,a4
ffffffffc02009d0:	870d                	sra	a4,a4,0x3
ffffffffc02009d2:	02f707b3          	mul	a5,a4,a5
ffffffffc02009d6:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02009d8:	07b2                	sll	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02009da:	3ac7fd63          	bgeu	a5,a2,ffffffffc0200d94 <best_fit_check+0x4b0>
    assert(alloc_page() == NULL);
ffffffffc02009de:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009e0:	00043c03          	ld	s8,0(s0)
ffffffffc02009e4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02009e8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02009ec:	e400                	sd	s0,8(s0)
ffffffffc02009ee:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02009f0:	00005797          	auipc	a5,0x5
ffffffffc02009f4:	6207a823          	sw	zero,1584(a5) # ffffffffc0206020 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02009f8:	02b000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc02009fc:	36051c63          	bnez	a0,ffffffffc0200d74 <best_fit_check+0x490>
    free_page(p0);
ffffffffc0200a00:	4585                	li	a1,1
ffffffffc0200a02:	8552                	mv	a0,s4
ffffffffc0200a04:	05d000ef          	jal	ffffffffc0201260 <free_pages>
    free_page(p1);
ffffffffc0200a08:	4585                	li	a1,1
ffffffffc0200a0a:	854e                	mv	a0,s3
ffffffffc0200a0c:	055000ef          	jal	ffffffffc0201260 <free_pages>
    free_page(p2);
ffffffffc0200a10:	4585                	li	a1,1
ffffffffc0200a12:	8556                	mv	a0,s5
ffffffffc0200a14:	04d000ef          	jal	ffffffffc0201260 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a18:	4818                	lw	a4,16(s0)
ffffffffc0200a1a:	478d                	li	a5,3
ffffffffc0200a1c:	32f71c63          	bne	a4,a5,ffffffffc0200d54 <best_fit_check+0x470>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a20:	4505                	li	a0,1
ffffffffc0200a22:	001000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a26:	89aa                	mv	s3,a0
ffffffffc0200a28:	30050663          	beqz	a0,ffffffffc0200d34 <best_fit_check+0x450>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a2c:	4505                	li	a0,1
ffffffffc0200a2e:	7f4000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a32:	8aaa                	mv	s5,a0
ffffffffc0200a34:	2e050063          	beqz	a0,ffffffffc0200d14 <best_fit_check+0x430>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a38:	4505                	li	a0,1
ffffffffc0200a3a:	7e8000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a3e:	8a2a                	mv	s4,a0
ffffffffc0200a40:	2a050a63          	beqz	a0,ffffffffc0200cf4 <best_fit_check+0x410>
    assert(alloc_page() == NULL);
ffffffffc0200a44:	4505                	li	a0,1
ffffffffc0200a46:	7dc000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a4a:	28051563          	bnez	a0,ffffffffc0200cd4 <best_fit_check+0x3f0>
    free_page(p0);
ffffffffc0200a4e:	4585                	li	a1,1
ffffffffc0200a50:	854e                	mv	a0,s3
ffffffffc0200a52:	00f000ef          	jal	ffffffffc0201260 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200a56:	641c                	ld	a5,8(s0)
ffffffffc0200a58:	1a878e63          	beq	a5,s0,ffffffffc0200c14 <best_fit_check+0x330>
    assert((p = alloc_page()) == p0);
ffffffffc0200a5c:	4505                	li	a0,1
ffffffffc0200a5e:	7c4000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a62:	52a99963          	bne	s3,a0,ffffffffc0200f94 <best_fit_check+0x6b0>
    assert(alloc_page() == NULL);
ffffffffc0200a66:	4505                	li	a0,1
ffffffffc0200a68:	7ba000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200a6c:	50051463          	bnez	a0,ffffffffc0200f74 <best_fit_check+0x690>
    assert(nr_free == 0);
ffffffffc0200a70:	481c                	lw	a5,16(s0)
ffffffffc0200a72:	4e079163          	bnez	a5,ffffffffc0200f54 <best_fit_check+0x670>
    free_page(p);
ffffffffc0200a76:	854e                	mv	a0,s3
ffffffffc0200a78:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200a7a:	01843023          	sd	s8,0(s0)
ffffffffc0200a7e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200a82:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200a86:	7da000ef          	jal	ffffffffc0201260 <free_pages>
    free_page(p1);
ffffffffc0200a8a:	4585                	li	a1,1
ffffffffc0200a8c:	8556                	mv	a0,s5
ffffffffc0200a8e:	7d2000ef          	jal	ffffffffc0201260 <free_pages>
    free_page(p2);
ffffffffc0200a92:	4585                	li	a1,1
ffffffffc0200a94:	8552                	mv	a0,s4
ffffffffc0200a96:	7ca000ef          	jal	ffffffffc0201260 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200a9a:	4515                	li	a0,5
ffffffffc0200a9c:	786000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200aa0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200aa2:	48050963          	beqz	a0,ffffffffc0200f34 <best_fit_check+0x650>
ffffffffc0200aa6:	651c                	ld	a5,8(a0)
ffffffffc0200aa8:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200aaa:	8b85                	and	a5,a5,1
ffffffffc0200aac:	46079463          	bnez	a5,ffffffffc0200f14 <best_fit_check+0x630>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200ab0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ab2:	00043a83          	ld	s5,0(s0)
ffffffffc0200ab6:	00843a03          	ld	s4,8(s0)
ffffffffc0200aba:	e000                	sd	s0,0(s0)
ffffffffc0200abc:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200abe:	764000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200ac2:	42051963          	bnez	a0,ffffffffc0200ef4 <best_fit_check+0x610>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200ac6:	4589                	li	a1,2
ffffffffc0200ac8:	02898513          	add	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200acc:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200ad0:	0a098c13          	add	s8,s3,160
    nr_free = 0;
ffffffffc0200ad4:	00005797          	auipc	a5,0x5
ffffffffc0200ad8:	5407a623          	sw	zero,1356(a5) # ffffffffc0206020 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200adc:	784000ef          	jal	ffffffffc0201260 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200ae0:	8562                	mv	a0,s8
ffffffffc0200ae2:	4585                	li	a1,1
ffffffffc0200ae4:	77c000ef          	jal	ffffffffc0201260 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ae8:	4511                	li	a0,4
ffffffffc0200aea:	738000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200aee:	3e051363          	bnez	a0,ffffffffc0200ed4 <best_fit_check+0x5f0>
ffffffffc0200af2:	0309b783          	ld	a5,48(s3)
ffffffffc0200af6:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200af8:	8b85                	and	a5,a5,1
ffffffffc0200afa:	3a078d63          	beqz	a5,ffffffffc0200eb4 <best_fit_check+0x5d0>
ffffffffc0200afe:	0389a703          	lw	a4,56(s3)
ffffffffc0200b02:	4789                	li	a5,2
ffffffffc0200b04:	3af71863          	bne	a4,a5,ffffffffc0200eb4 <best_fit_check+0x5d0>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200b08:	4505                	li	a0,1
ffffffffc0200b0a:	718000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200b0e:	8baa                	mv	s7,a0
ffffffffc0200b10:	38050263          	beqz	a0,ffffffffc0200e94 <best_fit_check+0x5b0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b14:	4509                	li	a0,2
ffffffffc0200b16:	70c000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200b1a:	34050d63          	beqz	a0,ffffffffc0200e74 <best_fit_check+0x590>
    assert(p0 + 4 == p1);
ffffffffc0200b1e:	337c1b63          	bne	s8,s7,ffffffffc0200e54 <best_fit_check+0x570>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b22:	854e                	mv	a0,s3
ffffffffc0200b24:	4595                	li	a1,5
ffffffffc0200b26:	73a000ef          	jal	ffffffffc0201260 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b2a:	4515                	li	a0,5
ffffffffc0200b2c:	6f6000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200b30:	89aa                	mv	s3,a0
ffffffffc0200b32:	30050163          	beqz	a0,ffffffffc0200e34 <best_fit_check+0x550>
    assert(alloc_page() == NULL);
ffffffffc0200b36:	4505                	li	a0,1
ffffffffc0200b38:	6ea000ef          	jal	ffffffffc0201222 <alloc_pages>
ffffffffc0200b3c:	2c051c63          	bnez	a0,ffffffffc0200e14 <best_fit_check+0x530>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b40:	481c                	lw	a5,16(s0)
ffffffffc0200b42:	2a079963          	bnez	a5,ffffffffc0200df4 <best_fit_check+0x510>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b46:	4595                	li	a1,5
ffffffffc0200b48:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200b4a:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200b4e:	01543023          	sd	s5,0(s0)
ffffffffc0200b52:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200b56:	70a000ef          	jal	ffffffffc0201260 <free_pages>
    return listelm->next;
ffffffffc0200b5a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b5c:	00878963          	beq	a5,s0,ffffffffc0200b6e <best_fit_check+0x28a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200b60:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b64:	679c                	ld	a5,8(a5)
ffffffffc0200b66:	397d                	addw	s2,s2,-1
ffffffffc0200b68:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b6a:	fe879be3          	bne	a5,s0,ffffffffc0200b60 <best_fit_check+0x27c>
    }
    assert(count == 0);
ffffffffc0200b6e:	26091363          	bnez	s2,ffffffffc0200dd4 <best_fit_check+0x4f0>
    assert(total == 0);
ffffffffc0200b72:	e0ed                	bnez	s1,ffffffffc0200c54 <best_fit_check+0x370>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200b74:	60a6                	ld	ra,72(sp)
ffffffffc0200b76:	6406                	ld	s0,64(sp)
ffffffffc0200b78:	74e2                	ld	s1,56(sp)
ffffffffc0200b7a:	7942                	ld	s2,48(sp)
ffffffffc0200b7c:	79a2                	ld	s3,40(sp)
ffffffffc0200b7e:	7a02                	ld	s4,32(sp)
ffffffffc0200b80:	6ae2                	ld	s5,24(sp)
ffffffffc0200b82:	6b42                	ld	s6,16(sp)
ffffffffc0200b84:	6ba2                	ld	s7,8(sp)
ffffffffc0200b86:	6c02                	ld	s8,0(sp)
ffffffffc0200b88:	6161                	add	sp,sp,80
ffffffffc0200b8a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b8c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200b8e:	4481                	li	s1,0
ffffffffc0200b90:	4901                	li	s2,0
ffffffffc0200b92:	bb51                	j	ffffffffc0200926 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200b94:	00001697          	auipc	a3,0x1
ffffffffc0200b98:	56c68693          	add	a3,a3,1388 # ffffffffc0202100 <etext+0x71a>
ffffffffc0200b9c:	00001617          	auipc	a2,0x1
ffffffffc0200ba0:	53460613          	add	a2,a2,1332 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ba4:	11100593          	li	a1,273
ffffffffc0200ba8:	00001517          	auipc	a0,0x1
ffffffffc0200bac:	54050513          	add	a0,a0,1344 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200bb0:	ff6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200bb4:	00001697          	auipc	a3,0x1
ffffffffc0200bb8:	5dc68693          	add	a3,a3,1500 # ffffffffc0202190 <etext+0x7aa>
ffffffffc0200bbc:	00001617          	auipc	a2,0x1
ffffffffc0200bc0:	51460613          	add	a2,a2,1300 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200bc4:	0dd00593          	li	a1,221
ffffffffc0200bc8:	00001517          	auipc	a0,0x1
ffffffffc0200bcc:	52050513          	add	a0,a0,1312 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200bd0:	fd6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bd4:	00001697          	auipc	a3,0x1
ffffffffc0200bd8:	5e468693          	add	a3,a3,1508 # ffffffffc02021b8 <etext+0x7d2>
ffffffffc0200bdc:	00001617          	auipc	a2,0x1
ffffffffc0200be0:	4f460613          	add	a2,a2,1268 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200be4:	0de00593          	li	a1,222
ffffffffc0200be8:	00001517          	auipc	a0,0x1
ffffffffc0200bec:	50050513          	add	a0,a0,1280 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200bf0:	fb6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bf4:	00001697          	auipc	a3,0x1
ffffffffc0200bf8:	60468693          	add	a3,a3,1540 # ffffffffc02021f8 <etext+0x812>
ffffffffc0200bfc:	00001617          	auipc	a2,0x1
ffffffffc0200c00:	4d460613          	add	a2,a2,1236 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200c04:	0e000593          	li	a1,224
ffffffffc0200c08:	00001517          	auipc	a0,0x1
ffffffffc0200c0c:	4e050513          	add	a0,a0,1248 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200c10:	f96ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c14:	00001697          	auipc	a3,0x1
ffffffffc0200c18:	66c68693          	add	a3,a3,1644 # ffffffffc0202280 <etext+0x89a>
ffffffffc0200c1c:	00001617          	auipc	a2,0x1
ffffffffc0200c20:	4b460613          	add	a2,a2,1204 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200c24:	0f900593          	li	a1,249
ffffffffc0200c28:	00001517          	auipc	a0,0x1
ffffffffc0200c2c:	4c050513          	add	a0,a0,1216 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200c30:	f76ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c34:	00001697          	auipc	a3,0x1
ffffffffc0200c38:	53c68693          	add	a3,a3,1340 # ffffffffc0202170 <etext+0x78a>
ffffffffc0200c3c:	00001617          	auipc	a2,0x1
ffffffffc0200c40:	49460613          	add	a2,a2,1172 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200c44:	0db00593          	li	a1,219
ffffffffc0200c48:	00001517          	auipc	a0,0x1
ffffffffc0200c4c:	4a050513          	add	a0,a0,1184 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200c50:	f56ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == 0);
ffffffffc0200c54:	00001697          	auipc	a3,0x1
ffffffffc0200c58:	75c68693          	add	a3,a3,1884 # ffffffffc02023b0 <etext+0x9ca>
ffffffffc0200c5c:	00001617          	auipc	a2,0x1
ffffffffc0200c60:	47460613          	add	a2,a2,1140 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200c64:	15300593          	li	a1,339
ffffffffc0200c68:	00001517          	auipc	a0,0x1
ffffffffc0200c6c:	48050513          	add	a0,a0,1152 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200c70:	f36ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200c74:	00001697          	auipc	a3,0x1
ffffffffc0200c78:	49c68693          	add	a3,a3,1180 # ffffffffc0202110 <etext+0x72a>
ffffffffc0200c7c:	00001617          	auipc	a2,0x1
ffffffffc0200c80:	45460613          	add	a2,a2,1108 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200c84:	11400593          	li	a1,276
ffffffffc0200c88:	00001517          	auipc	a0,0x1
ffffffffc0200c8c:	46050513          	add	a0,a0,1120 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200c90:	f16ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c94:	00001697          	auipc	a3,0x1
ffffffffc0200c98:	4bc68693          	add	a3,a3,1212 # ffffffffc0202150 <etext+0x76a>
ffffffffc0200c9c:	00001617          	auipc	a2,0x1
ffffffffc0200ca0:	43460613          	add	a2,a2,1076 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ca4:	0da00593          	li	a1,218
ffffffffc0200ca8:	00001517          	auipc	a0,0x1
ffffffffc0200cac:	44050513          	add	a0,a0,1088 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200cb0:	ef6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cb4:	00001697          	auipc	a3,0x1
ffffffffc0200cb8:	47c68693          	add	a3,a3,1148 # ffffffffc0202130 <etext+0x74a>
ffffffffc0200cbc:	00001617          	auipc	a2,0x1
ffffffffc0200cc0:	41460613          	add	a2,a2,1044 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200cc4:	0d900593          	li	a1,217
ffffffffc0200cc8:	00001517          	auipc	a0,0x1
ffffffffc0200ccc:	42050513          	add	a0,a0,1056 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200cd0:	ed6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cd4:	00001697          	auipc	a3,0x1
ffffffffc0200cd8:	58468693          	add	a3,a3,1412 # ffffffffc0202258 <etext+0x872>
ffffffffc0200cdc:	00001617          	auipc	a2,0x1
ffffffffc0200ce0:	3f460613          	add	a2,a2,1012 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ce4:	0f600593          	li	a1,246
ffffffffc0200ce8:	00001517          	auipc	a0,0x1
ffffffffc0200cec:	40050513          	add	a0,a0,1024 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200cf0:	eb6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cf4:	00001697          	auipc	a3,0x1
ffffffffc0200cf8:	47c68693          	add	a3,a3,1148 # ffffffffc0202170 <etext+0x78a>
ffffffffc0200cfc:	00001617          	auipc	a2,0x1
ffffffffc0200d00:	3d460613          	add	a2,a2,980 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200d04:	0f400593          	li	a1,244
ffffffffc0200d08:	00001517          	auipc	a0,0x1
ffffffffc0200d0c:	3e050513          	add	a0,a0,992 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200d10:	e96ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d14:	00001697          	auipc	a3,0x1
ffffffffc0200d18:	43c68693          	add	a3,a3,1084 # ffffffffc0202150 <etext+0x76a>
ffffffffc0200d1c:	00001617          	auipc	a2,0x1
ffffffffc0200d20:	3b460613          	add	a2,a2,948 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200d24:	0f300593          	li	a1,243
ffffffffc0200d28:	00001517          	auipc	a0,0x1
ffffffffc0200d2c:	3c050513          	add	a0,a0,960 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200d30:	e76ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d34:	00001697          	auipc	a3,0x1
ffffffffc0200d38:	3fc68693          	add	a3,a3,1020 # ffffffffc0202130 <etext+0x74a>
ffffffffc0200d3c:	00001617          	auipc	a2,0x1
ffffffffc0200d40:	39460613          	add	a2,a2,916 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200d44:	0f200593          	li	a1,242
ffffffffc0200d48:	00001517          	auipc	a0,0x1
ffffffffc0200d4c:	3a050513          	add	a0,a0,928 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200d50:	e56ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 3);
ffffffffc0200d54:	00001697          	auipc	a3,0x1
ffffffffc0200d58:	51c68693          	add	a3,a3,1308 # ffffffffc0202270 <etext+0x88a>
ffffffffc0200d5c:	00001617          	auipc	a2,0x1
ffffffffc0200d60:	37460613          	add	a2,a2,884 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200d64:	0f000593          	li	a1,240
ffffffffc0200d68:	00001517          	auipc	a0,0x1
ffffffffc0200d6c:	38050513          	add	a0,a0,896 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200d70:	e36ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d74:	00001697          	auipc	a3,0x1
ffffffffc0200d78:	4e468693          	add	a3,a3,1252 # ffffffffc0202258 <etext+0x872>
ffffffffc0200d7c:	00001617          	auipc	a2,0x1
ffffffffc0200d80:	35460613          	add	a2,a2,852 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200d84:	0eb00593          	li	a1,235
ffffffffc0200d88:	00001517          	auipc	a0,0x1
ffffffffc0200d8c:	36050513          	add	a0,a0,864 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200d90:	e16ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d94:	00001697          	auipc	a3,0x1
ffffffffc0200d98:	4a468693          	add	a3,a3,1188 # ffffffffc0202238 <etext+0x852>
ffffffffc0200d9c:	00001617          	auipc	a2,0x1
ffffffffc0200da0:	33460613          	add	a2,a2,820 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200da4:	0e200593          	li	a1,226
ffffffffc0200da8:	00001517          	auipc	a0,0x1
ffffffffc0200dac:	34050513          	add	a0,a0,832 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200db0:	df6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200db4:	00001697          	auipc	a3,0x1
ffffffffc0200db8:	46468693          	add	a3,a3,1124 # ffffffffc0202218 <etext+0x832>
ffffffffc0200dbc:	00001617          	auipc	a2,0x1
ffffffffc0200dc0:	31460613          	add	a2,a2,788 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200dc4:	0e100593          	li	a1,225
ffffffffc0200dc8:	00001517          	auipc	a0,0x1
ffffffffc0200dcc:	32050513          	add	a0,a0,800 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200dd0:	dd6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(count == 0);
ffffffffc0200dd4:	00001697          	auipc	a3,0x1
ffffffffc0200dd8:	5cc68693          	add	a3,a3,1484 # ffffffffc02023a0 <etext+0x9ba>
ffffffffc0200ddc:	00001617          	auipc	a2,0x1
ffffffffc0200de0:	2f460613          	add	a2,a2,756 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200de4:	15200593          	li	a1,338
ffffffffc0200de8:	00001517          	auipc	a0,0x1
ffffffffc0200dec:	30050513          	add	a0,a0,768 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200df0:	db6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200df4:	00001697          	auipc	a3,0x1
ffffffffc0200df8:	4c468693          	add	a3,a3,1220 # ffffffffc02022b8 <etext+0x8d2>
ffffffffc0200dfc:	00001617          	auipc	a2,0x1
ffffffffc0200e00:	2d460613          	add	a2,a2,724 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200e04:	14700593          	li	a1,327
ffffffffc0200e08:	00001517          	auipc	a0,0x1
ffffffffc0200e0c:	2e050513          	add	a0,a0,736 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200e10:	d96ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e14:	00001697          	auipc	a3,0x1
ffffffffc0200e18:	44468693          	add	a3,a3,1092 # ffffffffc0202258 <etext+0x872>
ffffffffc0200e1c:	00001617          	auipc	a2,0x1
ffffffffc0200e20:	2b460613          	add	a2,a2,692 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200e24:	14100593          	li	a1,321
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	2c050513          	add	a0,a0,704 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200e30:	d76ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e34:	00001697          	auipc	a3,0x1
ffffffffc0200e38:	54c68693          	add	a3,a3,1356 # ffffffffc0202380 <etext+0x99a>
ffffffffc0200e3c:	00001617          	auipc	a2,0x1
ffffffffc0200e40:	29460613          	add	a2,a2,660 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200e44:	14000593          	li	a1,320
ffffffffc0200e48:	00001517          	auipc	a0,0x1
ffffffffc0200e4c:	2a050513          	add	a0,a0,672 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200e50:	d56ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200e54:	00001697          	auipc	a3,0x1
ffffffffc0200e58:	51c68693          	add	a3,a3,1308 # ffffffffc0202370 <etext+0x98a>
ffffffffc0200e5c:	00001617          	auipc	a2,0x1
ffffffffc0200e60:	27460613          	add	a2,a2,628 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200e64:	13800593          	li	a1,312
ffffffffc0200e68:	00001517          	auipc	a0,0x1
ffffffffc0200e6c:	28050513          	add	a0,a0,640 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200e70:	d36ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e74:	00001697          	auipc	a3,0x1
ffffffffc0200e78:	4e468693          	add	a3,a3,1252 # ffffffffc0202358 <etext+0x972>
ffffffffc0200e7c:	00001617          	auipc	a2,0x1
ffffffffc0200e80:	25460613          	add	a2,a2,596 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200e84:	13700593          	li	a1,311
ffffffffc0200e88:	00001517          	auipc	a0,0x1
ffffffffc0200e8c:	26050513          	add	a0,a0,608 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200e90:	d16ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e94:	00001697          	auipc	a3,0x1
ffffffffc0200e98:	4a468693          	add	a3,a3,1188 # ffffffffc0202338 <etext+0x952>
ffffffffc0200e9c:	00001617          	auipc	a2,0x1
ffffffffc0200ea0:	23460613          	add	a2,a2,564 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ea4:	13600593          	li	a1,310
ffffffffc0200ea8:	00001517          	auipc	a0,0x1
ffffffffc0200eac:	24050513          	add	a0,a0,576 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200eb0:	cf6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200eb4:	00001697          	auipc	a3,0x1
ffffffffc0200eb8:	45468693          	add	a3,a3,1108 # ffffffffc0202308 <etext+0x922>
ffffffffc0200ebc:	00001617          	auipc	a2,0x1
ffffffffc0200ec0:	21460613          	add	a2,a2,532 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ec4:	13400593          	li	a1,308
ffffffffc0200ec8:	00001517          	auipc	a0,0x1
ffffffffc0200ecc:	22050513          	add	a0,a0,544 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200ed0:	cd6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ed4:	00001697          	auipc	a3,0x1
ffffffffc0200ed8:	41c68693          	add	a3,a3,1052 # ffffffffc02022f0 <etext+0x90a>
ffffffffc0200edc:	00001617          	auipc	a2,0x1
ffffffffc0200ee0:	1f460613          	add	a2,a2,500 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200ee4:	13300593          	li	a1,307
ffffffffc0200ee8:	00001517          	auipc	a0,0x1
ffffffffc0200eec:	20050513          	add	a0,a0,512 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200ef0:	cb6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ef4:	00001697          	auipc	a3,0x1
ffffffffc0200ef8:	36468693          	add	a3,a3,868 # ffffffffc0202258 <etext+0x872>
ffffffffc0200efc:	00001617          	auipc	a2,0x1
ffffffffc0200f00:	1d460613          	add	a2,a2,468 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200f04:	12700593          	li	a1,295
ffffffffc0200f08:	00001517          	auipc	a0,0x1
ffffffffc0200f0c:	1e050513          	add	a0,a0,480 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200f10:	c96ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f14:	00001697          	auipc	a3,0x1
ffffffffc0200f18:	3c468693          	add	a3,a3,964 # ffffffffc02022d8 <etext+0x8f2>
ffffffffc0200f1c:	00001617          	auipc	a2,0x1
ffffffffc0200f20:	1b460613          	add	a2,a2,436 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200f24:	11e00593          	li	a1,286
ffffffffc0200f28:	00001517          	auipc	a0,0x1
ffffffffc0200f2c:	1c050513          	add	a0,a0,448 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200f30:	c76ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != NULL);
ffffffffc0200f34:	00001697          	auipc	a3,0x1
ffffffffc0200f38:	39468693          	add	a3,a3,916 # ffffffffc02022c8 <etext+0x8e2>
ffffffffc0200f3c:	00001617          	auipc	a2,0x1
ffffffffc0200f40:	19460613          	add	a2,a2,404 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200f44:	11d00593          	li	a1,285
ffffffffc0200f48:	00001517          	auipc	a0,0x1
ffffffffc0200f4c:	1a050513          	add	a0,a0,416 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200f50:	c56ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200f54:	00001697          	auipc	a3,0x1
ffffffffc0200f58:	36468693          	add	a3,a3,868 # ffffffffc02022b8 <etext+0x8d2>
ffffffffc0200f5c:	00001617          	auipc	a2,0x1
ffffffffc0200f60:	17460613          	add	a2,a2,372 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200f64:	0ff00593          	li	a1,255
ffffffffc0200f68:	00001517          	auipc	a0,0x1
ffffffffc0200f6c:	18050513          	add	a0,a0,384 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200f70:	c36ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f74:	00001697          	auipc	a3,0x1
ffffffffc0200f78:	2e468693          	add	a3,a3,740 # ffffffffc0202258 <etext+0x872>
ffffffffc0200f7c:	00001617          	auipc	a2,0x1
ffffffffc0200f80:	15460613          	add	a2,a2,340 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200f84:	0fd00593          	li	a1,253
ffffffffc0200f88:	00001517          	auipc	a0,0x1
ffffffffc0200f8c:	16050513          	add	a0,a0,352 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200f90:	c16ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200f94:	00001697          	auipc	a3,0x1
ffffffffc0200f98:	30468693          	add	a3,a3,772 # ffffffffc0202298 <etext+0x8b2>
ffffffffc0200f9c:	00001617          	auipc	a2,0x1
ffffffffc0200fa0:	13460613          	add	a2,a2,308 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0200fa4:	0fc00593          	li	a1,252
ffffffffc0200fa8:	00001517          	auipc	a0,0x1
ffffffffc0200fac:	14050513          	add	a0,a0,320 # ffffffffc02020e8 <etext+0x702>
ffffffffc0200fb0:	bf6ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200fb4 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200fb4:	1141                	add	sp,sp,-16
ffffffffc0200fb6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200fb8:	14058a63          	beqz	a1,ffffffffc020110c <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0200fbc:	00259713          	sll	a4,a1,0x2
ffffffffc0200fc0:	972e                	add	a4,a4,a1
ffffffffc0200fc2:	070e                	sll	a4,a4,0x3
ffffffffc0200fc4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200fc8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200fca:	c30d                	beqz	a4,ffffffffc0200fec <best_fit_free_pages+0x38>
ffffffffc0200fcc:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fce:	8b05                	and	a4,a4,1
ffffffffc0200fd0:	10071e63          	bnez	a4,ffffffffc02010ec <best_fit_free_pages+0x138>
ffffffffc0200fd4:	6798                	ld	a4,8(a5)
ffffffffc0200fd6:	8b09                	and	a4,a4,2
ffffffffc0200fd8:	10071a63          	bnez	a4,ffffffffc02010ec <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0200fdc:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200fe0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200fe4:	02878793          	add	a5,a5,40
ffffffffc0200fe8:	fed792e3          	bne	a5,a3,ffffffffc0200fcc <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0200fec:	2581                	sext.w	a1,a1
ffffffffc0200fee:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200ff0:	00850893          	add	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200ff4:	4789                	li	a5,2
ffffffffc0200ff6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0200ffa:	00005697          	auipc	a3,0x5
ffffffffc0200ffe:	01668693          	add	a3,a3,22 # ffffffffc0206010 <free_area>
ffffffffc0201002:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201004:	669c                	ld	a5,8(a3)
ffffffffc0201006:	9f2d                	addw	a4,a4,a1
ffffffffc0201008:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020100a:	0ad78563          	beq	a5,a3,ffffffffc02010b4 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc020100e:	fe878713          	add	a4,a5,-24
ffffffffc0201012:	4581                	li	a1,0
ffffffffc0201014:	01850613          	add	a2,a0,24
            if (base < page) {
ffffffffc0201018:	00e56a63          	bltu	a0,a4,ffffffffc020102c <best_fit_free_pages+0x78>
    return listelm->next;
ffffffffc020101c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020101e:	06d70263          	beq	a4,a3,ffffffffc0201082 <best_fit_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201022:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201024:	fe878713          	add	a4,a5,-24
            if (base < page) {
ffffffffc0201028:	fee57ae3          	bgeu	a0,a4,ffffffffc020101c <best_fit_free_pages+0x68>
ffffffffc020102c:	c199                	beqz	a1,ffffffffc0201032 <best_fit_free_pages+0x7e>
ffffffffc020102e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201032:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201034:	e390                	sd	a2,0(a5)
ffffffffc0201036:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201038:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020103a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020103c:	02d70063          	beq	a4,a3,ffffffffc020105c <best_fit_free_pages+0xa8>
        if(p + p->property == base)
ffffffffc0201040:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201044:	fe870593          	add	a1,a4,-24
        if(p + p->property == base)
ffffffffc0201048:	02081613          	sll	a2,a6,0x20
ffffffffc020104c:	9201                	srl	a2,a2,0x20
ffffffffc020104e:	00261793          	sll	a5,a2,0x2
ffffffffc0201052:	97b2                	add	a5,a5,a2
ffffffffc0201054:	078e                	sll	a5,a5,0x3
ffffffffc0201056:	97ae                	add	a5,a5,a1
ffffffffc0201058:	02f50f63          	beq	a0,a5,ffffffffc0201096 <best_fit_free_pages+0xe2>
    return listelm->next;
ffffffffc020105c:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020105e:	00d70f63          	beq	a4,a3,ffffffffc020107c <best_fit_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc0201062:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201064:	fe870693          	add	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201068:	02059613          	sll	a2,a1,0x20
ffffffffc020106c:	9201                	srl	a2,a2,0x20
ffffffffc020106e:	00261793          	sll	a5,a2,0x2
ffffffffc0201072:	97b2                	add	a5,a5,a2
ffffffffc0201074:	078e                	sll	a5,a5,0x3
ffffffffc0201076:	97aa                	add	a5,a5,a0
ffffffffc0201078:	04f68a63          	beq	a3,a5,ffffffffc02010cc <best_fit_free_pages+0x118>
}
ffffffffc020107c:	60a2                	ld	ra,8(sp)
ffffffffc020107e:	0141                	add	sp,sp,16
ffffffffc0201080:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201082:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201084:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201086:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201088:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020108a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020108c:	02d70d63          	beq	a4,a3,ffffffffc02010c6 <best_fit_free_pages+0x112>
ffffffffc0201090:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201092:	87ba                	mv	a5,a4
ffffffffc0201094:	bf41                	j	ffffffffc0201024 <best_fit_free_pages+0x70>
            p->property += base->property;
ffffffffc0201096:	491c                	lw	a5,16(a0)
ffffffffc0201098:	010787bb          	addw	a5,a5,a6
ffffffffc020109c:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02010a0:	57f5                	li	a5,-3
ffffffffc02010a2:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010a6:	6d10                	ld	a2,24(a0)
ffffffffc02010a8:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02010aa:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02010ac:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02010ae:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02010b0:	e390                	sd	a2,0(a5)
ffffffffc02010b2:	b775                	j	ffffffffc020105e <best_fit_free_pages+0xaa>
}
ffffffffc02010b4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02010b6:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02010ba:	e398                	sd	a4,0(a5)
ffffffffc02010bc:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02010be:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010c0:	ed1c                	sd	a5,24(a0)
}
ffffffffc02010c2:	0141                	add	sp,sp,16
ffffffffc02010c4:	8082                	ret
ffffffffc02010c6:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02010c8:	873e                	mv	a4,a5
ffffffffc02010ca:	bf8d                	j	ffffffffc020103c <best_fit_free_pages+0x88>
            base->property += p->property;
ffffffffc02010cc:	ff872783          	lw	a5,-8(a4)
ffffffffc02010d0:	ff070693          	add	a3,a4,-16
ffffffffc02010d4:	9fad                	addw	a5,a5,a1
ffffffffc02010d6:	c91c                	sw	a5,16(a0)
ffffffffc02010d8:	57f5                	li	a5,-3
ffffffffc02010da:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02010de:	6314                	ld	a3,0(a4)
ffffffffc02010e0:	671c                	ld	a5,8(a4)
}
ffffffffc02010e2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02010e4:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02010e6:	e394                	sd	a3,0(a5)
ffffffffc02010e8:	0141                	add	sp,sp,16
ffffffffc02010ea:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010ec:	00001697          	auipc	a3,0x1
ffffffffc02010f0:	2d468693          	add	a3,a3,724 # ffffffffc02023c0 <etext+0x9da>
ffffffffc02010f4:	00001617          	auipc	a2,0x1
ffffffffc02010f8:	fdc60613          	add	a2,a2,-36 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc02010fc:	09800593          	li	a1,152
ffffffffc0201100:	00001517          	auipc	a0,0x1
ffffffffc0201104:	fe850513          	add	a0,a0,-24 # ffffffffc02020e8 <etext+0x702>
ffffffffc0201108:	a9eff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc020110c:	00001697          	auipc	a3,0x1
ffffffffc0201110:	fbc68693          	add	a3,a3,-68 # ffffffffc02020c8 <etext+0x6e2>
ffffffffc0201114:	00001617          	auipc	a2,0x1
ffffffffc0201118:	fbc60613          	add	a2,a2,-68 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc020111c:	09500593          	li	a1,149
ffffffffc0201120:	00001517          	auipc	a0,0x1
ffffffffc0201124:	fc850513          	add	a0,a0,-56 # ffffffffc02020e8 <etext+0x702>
ffffffffc0201128:	a7eff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc020112c <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020112c:	1141                	add	sp,sp,-16
ffffffffc020112e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201130:	c9e9                	beqz	a1,ffffffffc0201202 <best_fit_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc0201132:	00259713          	sll	a4,a1,0x2
ffffffffc0201136:	972e                	add	a4,a4,a1
ffffffffc0201138:	070e                	sll	a4,a4,0x3
ffffffffc020113a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020113e:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201140:	cf11                	beqz	a4,ffffffffc020115c <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201142:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201144:	8b05                	and	a4,a4,1
ffffffffc0201146:	cf51                	beqz	a4,ffffffffc02011e2 <best_fit_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0201148:	0007a823          	sw	zero,16(a5)
ffffffffc020114c:	0007b423          	sd	zero,8(a5)
ffffffffc0201150:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201154:	02878793          	add	a5,a5,40
ffffffffc0201158:	fed795e3          	bne	a5,a3,ffffffffc0201142 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc020115c:	2581                	sext.w	a1,a1
ffffffffc020115e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201160:	4789                	li	a5,2
ffffffffc0201162:	00850713          	add	a4,a0,8
ffffffffc0201166:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020116a:	00005697          	auipc	a3,0x5
ffffffffc020116e:	ea668693          	add	a3,a3,-346 # ffffffffc0206010 <free_area>
ffffffffc0201172:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201174:	669c                	ld	a5,8(a3)
ffffffffc0201176:	9f2d                	addw	a4,a4,a1
ffffffffc0201178:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020117a:	04d78763          	beq	a5,a3,ffffffffc02011c8 <best_fit_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc020117e:	fe878713          	add	a4,a5,-24
ffffffffc0201182:	4581                	li	a1,0
ffffffffc0201184:	01850613          	add	a2,a0,24
            if(base < page)
ffffffffc0201188:	00e56a63          	bltu	a0,a4,ffffffffc020119c <best_fit_init_memmap+0x70>
    return listelm->next;
ffffffffc020118c:	6798                	ld	a4,8(a5)
            else if(list_next(le) == &free_list)
ffffffffc020118e:	02d70263          	beq	a4,a3,ffffffffc02011b2 <best_fit_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201192:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201194:	fe878713          	add	a4,a5,-24
            if(base < page)
ffffffffc0201198:	fee57ae3          	bgeu	a0,a4,ffffffffc020118c <best_fit_init_memmap+0x60>
ffffffffc020119c:	c199                	beqz	a1,ffffffffc02011a2 <best_fit_init_memmap+0x76>
ffffffffc020119e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02011a2:	6398                	ld	a4,0(a5)
}
ffffffffc02011a4:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02011a6:	e390                	sd	a2,0(a5)
ffffffffc02011a8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02011aa:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011ac:	ed18                	sd	a4,24(a0)
ffffffffc02011ae:	0141                	add	sp,sp,16
ffffffffc02011b0:	8082                	ret
    __list_add(elm, listelm, listelm->next);
ffffffffc02011b2:	7118                	ld	a4,32(a0)
                list_add(&(base->page_link), &free_list);
ffffffffc02011b4:	8832                	mv	a6,a2
    prev->next = next->prev = elm;
ffffffffc02011b6:	e314                	sd	a3,0(a4)
ffffffffc02011b8:	f114                	sd	a3,32(a0)
    elm->next = next;
ffffffffc02011ba:	e698                	sd	a4,8(a3)
    return listelm->next;
ffffffffc02011bc:	6798                	ld	a4,8(a5)
        while ((le = list_next(le)) != &free_list) 
ffffffffc02011be:	00d70e63          	beq	a4,a3,ffffffffc02011da <best_fit_init_memmap+0xae>
ffffffffc02011c2:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02011c4:	87ba                	mv	a5,a4
ffffffffc02011c6:	b7f9                	j	ffffffffc0201194 <best_fit_init_memmap+0x68>
}
ffffffffc02011c8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02011ca:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02011ce:	e398                	sd	a4,0(a5)
ffffffffc02011d0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02011d2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011d4:	ed1c                	sd	a5,24(a0)
}
ffffffffc02011d6:	0141                	add	sp,sp,16
ffffffffc02011d8:	8082                	ret
ffffffffc02011da:	60a2                	ld	ra,8(sp)
ffffffffc02011dc:	e290                	sd	a2,0(a3)
ffffffffc02011de:	0141                	add	sp,sp,16
ffffffffc02011e0:	8082                	ret
        assert(PageReserved(p));
ffffffffc02011e2:	00001697          	auipc	a3,0x1
ffffffffc02011e6:	20668693          	add	a3,a3,518 # ffffffffc02023e8 <etext+0xa02>
ffffffffc02011ea:	00001617          	auipc	a2,0x1
ffffffffc02011ee:	ee660613          	add	a2,a2,-282 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc02011f2:	04a00593          	li	a1,74
ffffffffc02011f6:	00001517          	auipc	a0,0x1
ffffffffc02011fa:	ef250513          	add	a0,a0,-270 # ffffffffc02020e8 <etext+0x702>
ffffffffc02011fe:	9a8ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc0201202:	00001697          	auipc	a3,0x1
ffffffffc0201206:	ec668693          	add	a3,a3,-314 # ffffffffc02020c8 <etext+0x6e2>
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	ec660613          	add	a2,a2,-314 # ffffffffc02020d0 <etext+0x6ea>
ffffffffc0201212:	04700593          	li	a1,71
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	ed250513          	add	a0,a0,-302 # ffffffffc02020e8 <etext+0x702>
ffffffffc020121e:	988ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0201222 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201222:	100027f3          	csrr	a5,sstatus
ffffffffc0201226:	8b89                	and	a5,a5,2
ffffffffc0201228:	e799                	bnez	a5,ffffffffc0201236 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020122a:	00005797          	auipc	a5,0x5
ffffffffc020122e:	20e7b783          	ld	a5,526(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0201232:	6f9c                	ld	a5,24(a5)
ffffffffc0201234:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201236:	1141                	add	sp,sp,-16
ffffffffc0201238:	e406                	sd	ra,8(sp)
ffffffffc020123a:	e022                	sd	s0,0(sp)
ffffffffc020123c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020123e:	a1cff0ef          	jal	ffffffffc020045a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201242:	00005797          	auipc	a5,0x5
ffffffffc0201246:	1f67b783          	ld	a5,502(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc020124a:	6f9c                	ld	a5,24(a5)
ffffffffc020124c:	8522                	mv	a0,s0
ffffffffc020124e:	9782                	jalr	a5
ffffffffc0201250:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201252:	a02ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201256:	60a2                	ld	ra,8(sp)
ffffffffc0201258:	8522                	mv	a0,s0
ffffffffc020125a:	6402                	ld	s0,0(sp)
ffffffffc020125c:	0141                	add	sp,sp,16
ffffffffc020125e:	8082                	ret

ffffffffc0201260 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201260:	100027f3          	csrr	a5,sstatus
ffffffffc0201264:	8b89                	and	a5,a5,2
ffffffffc0201266:	e799                	bnez	a5,ffffffffc0201274 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201268:	00005797          	auipc	a5,0x5
ffffffffc020126c:	1d07b783          	ld	a5,464(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0201270:	739c                	ld	a5,32(a5)
ffffffffc0201272:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201274:	1101                	add	sp,sp,-32
ffffffffc0201276:	ec06                	sd	ra,24(sp)
ffffffffc0201278:	e822                	sd	s0,16(sp)
ffffffffc020127a:	e426                	sd	s1,8(sp)
ffffffffc020127c:	842a                	mv	s0,a0
ffffffffc020127e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201280:	9daff0ef          	jal	ffffffffc020045a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201284:	00005797          	auipc	a5,0x5
ffffffffc0201288:	1b47b783          	ld	a5,436(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc020128c:	739c                	ld	a5,32(a5)
ffffffffc020128e:	85a6                	mv	a1,s1
ffffffffc0201290:	8522                	mv	a0,s0
ffffffffc0201292:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201294:	6442                	ld	s0,16(sp)
ffffffffc0201296:	60e2                	ld	ra,24(sp)
ffffffffc0201298:	64a2                	ld	s1,8(sp)
ffffffffc020129a:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc020129c:	9b8ff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc02012a0 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012a0:	100027f3          	csrr	a5,sstatus
ffffffffc02012a4:	8b89                	and	a5,a5,2
ffffffffc02012a6:	e799                	bnez	a5,ffffffffc02012b4 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02012a8:	00005797          	auipc	a5,0x5
ffffffffc02012ac:	1907b783          	ld	a5,400(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc02012b0:	779c                	ld	a5,40(a5)
ffffffffc02012b2:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02012b4:	1141                	add	sp,sp,-16
ffffffffc02012b6:	e406                	sd	ra,8(sp)
ffffffffc02012b8:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02012ba:	9a0ff0ef          	jal	ffffffffc020045a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02012be:	00005797          	auipc	a5,0x5
ffffffffc02012c2:	17a7b783          	ld	a5,378(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc02012c6:	779c                	ld	a5,40(a5)
ffffffffc02012c8:	9782                	jalr	a5
ffffffffc02012ca:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02012cc:	988ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02012d0:	60a2                	ld	ra,8(sp)
ffffffffc02012d2:	8522                	mv	a0,s0
ffffffffc02012d4:	6402                	ld	s0,0(sp)
ffffffffc02012d6:	0141                	add	sp,sp,16
ffffffffc02012d8:	8082                	ret

ffffffffc02012da <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012da:	00001797          	auipc	a5,0x1
ffffffffc02012de:	38e78793          	add	a5,a5,910 # ffffffffc0202668 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012e2:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02012e4:	1101                	add	sp,sp,-32
ffffffffc02012e6:	ec06                	sd	ra,24(sp)
ffffffffc02012e8:	e822                	sd	s0,16(sp)
ffffffffc02012ea:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012ec:	00001517          	auipc	a0,0x1
ffffffffc02012f0:	12450513          	add	a0,a0,292 # ffffffffc0202410 <etext+0xa2a>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02012f4:	00005497          	auipc	s1,0x5
ffffffffc02012f8:	14448493          	add	s1,s1,324 # ffffffffc0206438 <pmm_manager>
ffffffffc02012fc:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02012fe:	db5fe0ef          	jal	ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0201302:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201304:	00005417          	auipc	s0,0x5
ffffffffc0201308:	14c40413          	add	s0,s0,332 # ffffffffc0206450 <va_pa_offset>
    pmm_manager->init();
ffffffffc020130c:	679c                	ld	a5,8(a5)
ffffffffc020130e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201310:	57f5                	li	a5,-3
ffffffffc0201312:	07fa                	sll	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201314:	00001517          	auipc	a0,0x1
ffffffffc0201318:	11450513          	add	a0,a0,276 # ffffffffc0202428 <etext+0xa42>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020131c:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc020131e:	d95fe0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201322:	46c5                	li	a3,17
ffffffffc0201324:	06ee                	sll	a3,a3,0x1b
ffffffffc0201326:	40100613          	li	a2,1025
ffffffffc020132a:	16fd                	add	a3,a3,-1
ffffffffc020132c:	0656                	sll	a2,a2,0x15
ffffffffc020132e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201332:	00001517          	auipc	a0,0x1
ffffffffc0201336:	10e50513          	add	a0,a0,270 # ffffffffc0202440 <etext+0xa5a>
ffffffffc020133a:	d79fe0ef          	jal	ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020133e:	777d                	lui	a4,0xfffff
ffffffffc0201340:	00006797          	auipc	a5,0x6
ffffffffc0201344:	12f78793          	add	a5,a5,303 # ffffffffc020746f <end+0xfff>
ffffffffc0201348:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020134a:	00005517          	auipc	a0,0x5
ffffffffc020134e:	10e50513          	add	a0,a0,270 # ffffffffc0206458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201352:	00005597          	auipc	a1,0x5
ffffffffc0201356:	10e58593          	add	a1,a1,270 # ffffffffc0206460 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020135a:	00088737          	lui	a4,0x88
ffffffffc020135e:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201360:	e19c                	sd	a5,0(a1)
ffffffffc0201362:	4705                	li	a4,1
ffffffffc0201364:	07a1                	add	a5,a5,8
ffffffffc0201366:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020136a:	02800693          	li	a3,40
ffffffffc020136e:	4885                	li	a7,1
ffffffffc0201370:	fff80837          	lui	a6,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201374:	619c                	ld	a5,0(a1)
ffffffffc0201376:	97b6                	add	a5,a5,a3
ffffffffc0201378:	07a1                	add	a5,a5,8
ffffffffc020137a:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020137e:	611c                	ld	a5,0(a0)
ffffffffc0201380:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201382:	02868693          	add	a3,a3,40
ffffffffc0201386:	01078633          	add	a2,a5,a6
ffffffffc020138a:	fec765e3          	bltu	a4,a2,ffffffffc0201374 <pmm_init+0x9a>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020138e:	6190                	ld	a2,0(a1)
ffffffffc0201390:	00279693          	sll	a3,a5,0x2
ffffffffc0201394:	96be                	add	a3,a3,a5
ffffffffc0201396:	fec00737          	lui	a4,0xfec00
ffffffffc020139a:	9732                	add	a4,a4,a2
ffffffffc020139c:	068e                	sll	a3,a3,0x3
ffffffffc020139e:	96ba                	add	a3,a3,a4
ffffffffc02013a0:	c0200737          	lui	a4,0xc0200
ffffffffc02013a4:	0ae6e463          	bltu	a3,a4,ffffffffc020144c <pmm_init+0x172>
ffffffffc02013a8:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02013aa:	45c5                	li	a1,17
ffffffffc02013ac:	05ee                	sll	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013ae:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02013b0:	04b6e963          	bltu	a3,a1,ffffffffc0201402 <pmm_init+0x128>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02013b4:	609c                	ld	a5,0(s1)
ffffffffc02013b6:	7b9c                	ld	a5,48(a5)
ffffffffc02013b8:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02013ba:	00001517          	auipc	a0,0x1
ffffffffc02013be:	11e50513          	add	a0,a0,286 # ffffffffc02024d8 <etext+0xaf2>
ffffffffc02013c2:	cf1fe0ef          	jal	ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02013c6:	00004597          	auipc	a1,0x4
ffffffffc02013ca:	c3a58593          	add	a1,a1,-966 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02013ce:	00005797          	auipc	a5,0x5
ffffffffc02013d2:	06b7bd23          	sd	a1,122(a5) # ffffffffc0206448 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013d6:	c02007b7          	lui	a5,0xc0200
ffffffffc02013da:	08f5e563          	bltu	a1,a5,ffffffffc0201464 <pmm_init+0x18a>
ffffffffc02013de:	601c                	ld	a5,0(s0)
}
ffffffffc02013e0:	6442                	ld	s0,16(sp)
ffffffffc02013e2:	60e2                	ld	ra,24(sp)
ffffffffc02013e4:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02013e6:	40f586b3          	sub	a3,a1,a5
ffffffffc02013ea:	00005797          	auipc	a5,0x5
ffffffffc02013ee:	04d7bb23          	sd	a3,86(a5) # ffffffffc0206440 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013f2:	00001517          	auipc	a0,0x1
ffffffffc02013f6:	10650513          	add	a0,a0,262 # ffffffffc02024f8 <etext+0xb12>
ffffffffc02013fa:	8636                	mv	a2,a3
}
ffffffffc02013fc:	6105                	add	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02013fe:	cb5fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201402:	6705                	lui	a4,0x1
ffffffffc0201404:	177d                	add	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201406:	96ba                	add	a3,a3,a4
ffffffffc0201408:	777d                	lui	a4,0xfffff
ffffffffc020140a:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020140c:	00c6d713          	srl	a4,a3,0xc
ffffffffc0201410:	02f77263          	bgeu	a4,a5,ffffffffc0201434 <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201414:	0004b803          	ld	a6,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201418:	fff807b7          	lui	a5,0xfff80
ffffffffc020141c:	97ba                	add	a5,a5,a4
ffffffffc020141e:	00279513          	sll	a0,a5,0x2
ffffffffc0201422:	953e                	add	a0,a0,a5
ffffffffc0201424:	01083783          	ld	a5,16(a6) # fffffffffff80010 <end+0x3fd79ba0>
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201428:	8d95                	sub	a1,a1,a3
ffffffffc020142a:	050e                	sll	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020142c:	81b1                	srl	a1,a1,0xc
ffffffffc020142e:	9532                	add	a0,a0,a2
ffffffffc0201430:	9782                	jalr	a5
}
ffffffffc0201432:	b749                	j	ffffffffc02013b4 <pmm_init+0xda>
        panic("pa2page called with invalid pa");
ffffffffc0201434:	00001617          	auipc	a2,0x1
ffffffffc0201438:	07460613          	add	a2,a2,116 # ffffffffc02024a8 <etext+0xac2>
ffffffffc020143c:	06b00593          	li	a1,107
ffffffffc0201440:	00001517          	auipc	a0,0x1
ffffffffc0201444:	08850513          	add	a0,a0,136 # ffffffffc02024c8 <etext+0xae2>
ffffffffc0201448:	f5ffe0ef          	jal	ffffffffc02003a6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020144c:	00001617          	auipc	a2,0x1
ffffffffc0201450:	02460613          	add	a2,a2,36 # ffffffffc0202470 <etext+0xa8a>
ffffffffc0201454:	06f00593          	li	a1,111
ffffffffc0201458:	00001517          	auipc	a0,0x1
ffffffffc020145c:	04050513          	add	a0,a0,64 # ffffffffc0202498 <etext+0xab2>
ffffffffc0201460:	f47fe0ef          	jal	ffffffffc02003a6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201464:	86ae                	mv	a3,a1
ffffffffc0201466:	00001617          	auipc	a2,0x1
ffffffffc020146a:	00a60613          	add	a2,a2,10 # ffffffffc0202470 <etext+0xa8a>
ffffffffc020146e:	08a00593          	li	a1,138
ffffffffc0201472:	00001517          	auipc	a0,0x1
ffffffffc0201476:	02650513          	add	a0,a0,38 # ffffffffc0202498 <etext+0xab2>
ffffffffc020147a:	f2dfe0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc020147e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020147e:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201482:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201484:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201488:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020148a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020148e:	f022                	sd	s0,32(sp)
ffffffffc0201490:	ec26                	sd	s1,24(sp)
ffffffffc0201492:	e84a                	sd	s2,16(sp)
ffffffffc0201494:	f406                	sd	ra,40(sp)
ffffffffc0201496:	84aa                	mv	s1,a0
ffffffffc0201498:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020149a:	fff7041b          	addw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b8f>
    unsigned mod = do_div(result, base);
ffffffffc020149e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02014a0:	05067063          	bgeu	a2,a6,ffffffffc02014e0 <printnum+0x62>
ffffffffc02014a4:	e44e                	sd	s3,8(sp)
ffffffffc02014a6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02014a8:	4785                	li	a5,1
ffffffffc02014aa:	00e7d763          	bge	a5,a4,ffffffffc02014b8 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc02014ae:	85ca                	mv	a1,s2
ffffffffc02014b0:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02014b2:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02014b4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02014b6:	fc65                	bnez	s0,ffffffffc02014ae <printnum+0x30>
ffffffffc02014b8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014ba:	1a02                	sll	s4,s4,0x20
ffffffffc02014bc:	020a5a13          	srl	s4,s4,0x20
ffffffffc02014c0:	00001797          	auipc	a5,0x1
ffffffffc02014c4:	07878793          	add	a5,a5,120 # ffffffffc0202538 <etext+0xb52>
ffffffffc02014c8:	97d2                	add	a5,a5,s4
}
ffffffffc02014ca:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014cc:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02014d0:	70a2                	ld	ra,40(sp)
ffffffffc02014d2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014d4:	85ca                	mv	a1,s2
ffffffffc02014d6:	87a6                	mv	a5,s1
}
ffffffffc02014d8:	6942                	ld	s2,16(sp)
ffffffffc02014da:	64e2                	ld	s1,24(sp)
ffffffffc02014dc:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014de:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02014e0:	03065633          	divu	a2,a2,a6
ffffffffc02014e4:	8722                	mv	a4,s0
ffffffffc02014e6:	f99ff0ef          	jal	ffffffffc020147e <printnum>
ffffffffc02014ea:	bfc1                	j	ffffffffc02014ba <printnum+0x3c>

ffffffffc02014ec <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02014ec:	7119                	add	sp,sp,-128
ffffffffc02014ee:	f4a6                	sd	s1,104(sp)
ffffffffc02014f0:	f0ca                	sd	s2,96(sp)
ffffffffc02014f2:	ecce                	sd	s3,88(sp)
ffffffffc02014f4:	e8d2                	sd	s4,80(sp)
ffffffffc02014f6:	e4d6                	sd	s5,72(sp)
ffffffffc02014f8:	e0da                	sd	s6,64(sp)
ffffffffc02014fa:	f862                	sd	s8,48(sp)
ffffffffc02014fc:	fc86                	sd	ra,120(sp)
ffffffffc02014fe:	f8a2                	sd	s0,112(sp)
ffffffffc0201500:	fc5e                	sd	s7,56(sp)
ffffffffc0201502:	f466                	sd	s9,40(sp)
ffffffffc0201504:	f06a                	sd	s10,32(sp)
ffffffffc0201506:	ec6e                	sd	s11,24(sp)
ffffffffc0201508:	892a                	mv	s2,a0
ffffffffc020150a:	84ae                	mv	s1,a1
ffffffffc020150c:	8c32                	mv	s8,a2
ffffffffc020150e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201510:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201514:	05500b13          	li	s6,85
ffffffffc0201518:	00001a97          	auipc	s5,0x1
ffffffffc020151c:	188a8a93          	add	s5,s5,392 # ffffffffc02026a0 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201520:	000c4503          	lbu	a0,0(s8)
ffffffffc0201524:	001c0413          	add	s0,s8,1
ffffffffc0201528:	01350a63          	beq	a0,s3,ffffffffc020153c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc020152c:	cd0d                	beqz	a0,ffffffffc0201566 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020152e:	85a6                	mv	a1,s1
ffffffffc0201530:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201532:	00044503          	lbu	a0,0(s0)
ffffffffc0201536:	0405                	add	s0,s0,1
ffffffffc0201538:	ff351ae3          	bne	a0,s3,ffffffffc020152c <vprintfmt+0x40>
        char padc = ' ';
ffffffffc020153c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201540:	4b81                	li	s7,0
ffffffffc0201542:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0201544:	5d7d                	li	s10,-1
ffffffffc0201546:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201548:	00044683          	lbu	a3,0(s0)
ffffffffc020154c:	00140c13          	add	s8,s0,1
ffffffffc0201550:	fdd6859b          	addw	a1,a3,-35
ffffffffc0201554:	0ff5f593          	zext.b	a1,a1
ffffffffc0201558:	02bb6663          	bltu	s6,a1,ffffffffc0201584 <vprintfmt+0x98>
ffffffffc020155c:	058a                	sll	a1,a1,0x2
ffffffffc020155e:	95d6                	add	a1,a1,s5
ffffffffc0201560:	4198                	lw	a4,0(a1)
ffffffffc0201562:	9756                	add	a4,a4,s5
ffffffffc0201564:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201566:	70e6                	ld	ra,120(sp)
ffffffffc0201568:	7446                	ld	s0,112(sp)
ffffffffc020156a:	74a6                	ld	s1,104(sp)
ffffffffc020156c:	7906                	ld	s2,96(sp)
ffffffffc020156e:	69e6                	ld	s3,88(sp)
ffffffffc0201570:	6a46                	ld	s4,80(sp)
ffffffffc0201572:	6aa6                	ld	s5,72(sp)
ffffffffc0201574:	6b06                	ld	s6,64(sp)
ffffffffc0201576:	7be2                	ld	s7,56(sp)
ffffffffc0201578:	7c42                	ld	s8,48(sp)
ffffffffc020157a:	7ca2                	ld	s9,40(sp)
ffffffffc020157c:	7d02                	ld	s10,32(sp)
ffffffffc020157e:	6de2                	ld	s11,24(sp)
ffffffffc0201580:	6109                	add	sp,sp,128
ffffffffc0201582:	8082                	ret
            putch('%', putdat);
ffffffffc0201584:	85a6                	mv	a1,s1
ffffffffc0201586:	02500513          	li	a0,37
ffffffffc020158a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020158c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201590:	02500793          	li	a5,37
ffffffffc0201594:	8c22                	mv	s8,s0
ffffffffc0201596:	f8f705e3          	beq	a4,a5,ffffffffc0201520 <vprintfmt+0x34>
ffffffffc020159a:	02500713          	li	a4,37
ffffffffc020159e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02015a2:	1c7d                	add	s8,s8,-1
ffffffffc02015a4:	fee79de3          	bne	a5,a4,ffffffffc020159e <vprintfmt+0xb2>
ffffffffc02015a8:	bfa5                	j	ffffffffc0201520 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02015aa:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02015ae:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc02015b0:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02015b4:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc02015b8:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015bc:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc02015be:	02b76563          	bltu	a4,a1,ffffffffc02015e8 <vprintfmt+0xfc>
ffffffffc02015c2:	4525                	li	a0,9
                ch = *fmt;
ffffffffc02015c4:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02015c8:	002d171b          	sllw	a4,s10,0x2
ffffffffc02015cc:	01a7073b          	addw	a4,a4,s10
ffffffffc02015d0:	0017171b          	sllw	a4,a4,0x1
ffffffffc02015d4:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc02015d6:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02015da:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02015dc:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc02015e0:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc02015e4:	feb570e3          	bgeu	a0,a1,ffffffffc02015c4 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc02015e8:	f60cd0e3          	bgez	s9,ffffffffc0201548 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02015ec:	8cea                	mv	s9,s10
ffffffffc02015ee:	5d7d                	li	s10,-1
ffffffffc02015f0:	bfa1                	j	ffffffffc0201548 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015f2:	8db6                	mv	s11,a3
ffffffffc02015f4:	8462                	mv	s0,s8
ffffffffc02015f6:	bf89                	j	ffffffffc0201548 <vprintfmt+0x5c>
ffffffffc02015f8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02015fa:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02015fc:	b7b1                	j	ffffffffc0201548 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02015fe:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201600:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201604:	00c7c463          	blt	a5,a2,ffffffffc020160c <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201608:	1a060163          	beqz	a2,ffffffffc02017aa <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc020160c:	000a3603          	ld	a2,0(s4)
ffffffffc0201610:	46c1                	li	a3,16
ffffffffc0201612:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201614:	000d879b          	sext.w	a5,s11
ffffffffc0201618:	8766                	mv	a4,s9
ffffffffc020161a:	85a6                	mv	a1,s1
ffffffffc020161c:	854a                	mv	a0,s2
ffffffffc020161e:	e61ff0ef          	jal	ffffffffc020147e <printnum>
            break;
ffffffffc0201622:	bdfd                	j	ffffffffc0201520 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201624:	000a2503          	lw	a0,0(s4)
ffffffffc0201628:	85a6                	mv	a1,s1
ffffffffc020162a:	0a21                	add	s4,s4,8
ffffffffc020162c:	9902                	jalr	s2
            break;
ffffffffc020162e:	bdcd                	j	ffffffffc0201520 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201630:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201632:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201636:	00c7c463          	blt	a5,a2,ffffffffc020163e <vprintfmt+0x152>
    else if (lflag) {
ffffffffc020163a:	16060363          	beqz	a2,ffffffffc02017a0 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc020163e:	000a3603          	ld	a2,0(s4)
ffffffffc0201642:	46a9                	li	a3,10
ffffffffc0201644:	8a3a                	mv	s4,a4
ffffffffc0201646:	b7f9                	j	ffffffffc0201614 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201648:	85a6                	mv	a1,s1
ffffffffc020164a:	03000513          	li	a0,48
ffffffffc020164e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201650:	85a6                	mv	a1,s1
ffffffffc0201652:	07800513          	li	a0,120
ffffffffc0201656:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201658:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020165c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020165e:	0a21                	add	s4,s4,8
            goto number;
ffffffffc0201660:	bf55                	j	ffffffffc0201614 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201662:	85a6                	mv	a1,s1
ffffffffc0201664:	02500513          	li	a0,37
ffffffffc0201668:	9902                	jalr	s2
            break;
ffffffffc020166a:	bd5d                	j	ffffffffc0201520 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020166c:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201670:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201672:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc0201674:	bf95                	j	ffffffffc02015e8 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201676:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201678:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc020167c:	00c7c463          	blt	a5,a2,ffffffffc0201684 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201680:	10060b63          	beqz	a2,ffffffffc0201796 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201684:	000a3603          	ld	a2,0(s4)
ffffffffc0201688:	46a1                	li	a3,8
ffffffffc020168a:	8a3a                	mv	s4,a4
ffffffffc020168c:	b761                	j	ffffffffc0201614 <vprintfmt+0x128>
            if (width < 0)
ffffffffc020168e:	fffcc793          	not	a5,s9
ffffffffc0201692:	97fd                	sra	a5,a5,0x3f
ffffffffc0201694:	00fcf7b3          	and	a5,s9,a5
ffffffffc0201698:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020169c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020169e:	b56d                	j	ffffffffc0201548 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02016a0:	000a3403          	ld	s0,0(s4)
ffffffffc02016a4:	008a0793          	add	a5,s4,8
ffffffffc02016a8:	e43e                	sd	a5,8(sp)
ffffffffc02016aa:	12040063          	beqz	s0,ffffffffc02017ca <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02016ae:	0d905963          	blez	s9,ffffffffc0201780 <vprintfmt+0x294>
ffffffffc02016b2:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016b6:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc02016ba:	12fd9763          	bne	s11,a5,ffffffffc02017e8 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016be:	00044783          	lbu	a5,0(s0)
ffffffffc02016c2:	0007851b          	sext.w	a0,a5
ffffffffc02016c6:	cb9d                	beqz	a5,ffffffffc02016fc <vprintfmt+0x210>
ffffffffc02016c8:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016ca:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016ce:	000d4563          	bltz	s10,ffffffffc02016d8 <vprintfmt+0x1ec>
ffffffffc02016d2:	3d7d                	addw	s10,s10,-1
ffffffffc02016d4:	028d0263          	beq	s10,s0,ffffffffc02016f8 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc02016d8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02016da:	0c0b8d63          	beqz	s7,ffffffffc02017b4 <vprintfmt+0x2c8>
ffffffffc02016de:	3781                	addw	a5,a5,-32
ffffffffc02016e0:	0cfdfa63          	bgeu	s11,a5,ffffffffc02017b4 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc02016e4:	03f00513          	li	a0,63
ffffffffc02016e8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016ea:	000a4783          	lbu	a5,0(s4)
ffffffffc02016ee:	3cfd                	addw	s9,s9,-1
ffffffffc02016f0:	0a05                	add	s4,s4,1
ffffffffc02016f2:	0007851b          	sext.w	a0,a5
ffffffffc02016f6:	ffe1                	bnez	a5,ffffffffc02016ce <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc02016f8:	01905963          	blez	s9,ffffffffc020170a <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc02016fc:	85a6                	mv	a1,s1
ffffffffc02016fe:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201702:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201704:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201706:	fe0c9be3          	bnez	s9,ffffffffc02016fc <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020170a:	6a22                	ld	s4,8(sp)
ffffffffc020170c:	bd11                	j	ffffffffc0201520 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020170e:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201710:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201714:	00c7c363          	blt	a5,a2,ffffffffc020171a <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201718:	ce25                	beqz	a2,ffffffffc0201790 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc020171a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020171e:	08044d63          	bltz	s0,ffffffffc02017b8 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201722:	8622                	mv	a2,s0
ffffffffc0201724:	8a5e                	mv	s4,s7
ffffffffc0201726:	46a9                	li	a3,10
ffffffffc0201728:	b5f5                	j	ffffffffc0201614 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc020172a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020172e:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201730:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc0201734:	8fb9                	xor	a5,a5,a4
ffffffffc0201736:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020173a:	02d64663          	blt	a2,a3,ffffffffc0201766 <vprintfmt+0x27a>
ffffffffc020173e:	00369713          	sll	a4,a3,0x3
ffffffffc0201742:	00001797          	auipc	a5,0x1
ffffffffc0201746:	0b678793          	add	a5,a5,182 # ffffffffc02027f8 <error_string>
ffffffffc020174a:	97ba                	add	a5,a5,a4
ffffffffc020174c:	639c                	ld	a5,0(a5)
ffffffffc020174e:	cf81                	beqz	a5,ffffffffc0201766 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201750:	86be                	mv	a3,a5
ffffffffc0201752:	00001617          	auipc	a2,0x1
ffffffffc0201756:	e1660613          	add	a2,a2,-490 # ffffffffc0202568 <etext+0xb82>
ffffffffc020175a:	85a6                	mv	a1,s1
ffffffffc020175c:	854a                	mv	a0,s2
ffffffffc020175e:	0e8000ef          	jal	ffffffffc0201846 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201762:	0a21                	add	s4,s4,8
ffffffffc0201764:	bb75                	j	ffffffffc0201520 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201766:	00001617          	auipc	a2,0x1
ffffffffc020176a:	df260613          	add	a2,a2,-526 # ffffffffc0202558 <etext+0xb72>
ffffffffc020176e:	85a6                	mv	a1,s1
ffffffffc0201770:	854a                	mv	a0,s2
ffffffffc0201772:	0d4000ef          	jal	ffffffffc0201846 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201776:	0a21                	add	s4,s4,8
ffffffffc0201778:	b365                	j	ffffffffc0201520 <vprintfmt+0x34>
            lflag ++;
ffffffffc020177a:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020177c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020177e:	b3e9                	j	ffffffffc0201548 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201780:	00044783          	lbu	a5,0(s0)
ffffffffc0201784:	0007851b          	sext.w	a0,a5
ffffffffc0201788:	d3c9                	beqz	a5,ffffffffc020170a <vprintfmt+0x21e>
ffffffffc020178a:	00140a13          	add	s4,s0,1
ffffffffc020178e:	bf2d                	j	ffffffffc02016c8 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201790:	000a2403          	lw	s0,0(s4)
ffffffffc0201794:	b769                	j	ffffffffc020171e <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201796:	000a6603          	lwu	a2,0(s4)
ffffffffc020179a:	46a1                	li	a3,8
ffffffffc020179c:	8a3a                	mv	s4,a4
ffffffffc020179e:	bd9d                	j	ffffffffc0201614 <vprintfmt+0x128>
ffffffffc02017a0:	000a6603          	lwu	a2,0(s4)
ffffffffc02017a4:	46a9                	li	a3,10
ffffffffc02017a6:	8a3a                	mv	s4,a4
ffffffffc02017a8:	b5b5                	j	ffffffffc0201614 <vprintfmt+0x128>
ffffffffc02017aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02017ae:	46c1                	li	a3,16
ffffffffc02017b0:	8a3a                	mv	s4,a4
ffffffffc02017b2:	b58d                	j	ffffffffc0201614 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc02017b4:	9902                	jalr	s2
ffffffffc02017b6:	bf15                	j	ffffffffc02016ea <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc02017b8:	85a6                	mv	a1,s1
ffffffffc02017ba:	02d00513          	li	a0,45
ffffffffc02017be:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02017c0:	40800633          	neg	a2,s0
ffffffffc02017c4:	8a5e                	mv	s4,s7
ffffffffc02017c6:	46a9                	li	a3,10
ffffffffc02017c8:	b5b1                	j	ffffffffc0201614 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc02017ca:	01905663          	blez	s9,ffffffffc02017d6 <vprintfmt+0x2ea>
ffffffffc02017ce:	02d00793          	li	a5,45
ffffffffc02017d2:	04fd9263          	bne	s11,a5,ffffffffc0201816 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017d6:	02800793          	li	a5,40
ffffffffc02017da:	00001a17          	auipc	s4,0x1
ffffffffc02017de:	d77a0a13          	add	s4,s4,-649 # ffffffffc0202551 <etext+0xb6b>
ffffffffc02017e2:	02800513          	li	a0,40
ffffffffc02017e6:	b5cd                	j	ffffffffc02016c8 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017e8:	85ea                	mv	a1,s10
ffffffffc02017ea:	8522                	mv	a0,s0
ffffffffc02017ec:	17e000ef          	jal	ffffffffc020196a <strnlen>
ffffffffc02017f0:	40ac8cbb          	subw	s9,s9,a0
ffffffffc02017f4:	01905963          	blez	s9,ffffffffc0201806 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc02017f8:	2d81                	sext.w	s11,s11
ffffffffc02017fa:	85a6                	mv	a1,s1
ffffffffc02017fc:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017fe:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201800:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201802:	fe0c9ce3          	bnez	s9,ffffffffc02017fa <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201806:	00044783          	lbu	a5,0(s0)
ffffffffc020180a:	0007851b          	sext.w	a0,a5
ffffffffc020180e:	ea079de3          	bnez	a5,ffffffffc02016c8 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201812:	6a22                	ld	s4,8(sp)
ffffffffc0201814:	b331                	j	ffffffffc0201520 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201816:	85ea                	mv	a1,s10
ffffffffc0201818:	00001517          	auipc	a0,0x1
ffffffffc020181c:	d3850513          	add	a0,a0,-712 # ffffffffc0202550 <etext+0xb6a>
ffffffffc0201820:	14a000ef          	jal	ffffffffc020196a <strnlen>
ffffffffc0201824:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201828:	00001417          	auipc	s0,0x1
ffffffffc020182c:	d2840413          	add	s0,s0,-728 # ffffffffc0202550 <etext+0xb6a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201830:	00001a17          	auipc	s4,0x1
ffffffffc0201834:	d21a0a13          	add	s4,s4,-735 # ffffffffc0202551 <etext+0xb6b>
ffffffffc0201838:	02800793          	li	a5,40
ffffffffc020183c:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201840:	fb904ce3          	bgtz	s9,ffffffffc02017f8 <vprintfmt+0x30c>
ffffffffc0201844:	b551                	j	ffffffffc02016c8 <vprintfmt+0x1dc>

ffffffffc0201846 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201846:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201848:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020184c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020184e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201850:	ec06                	sd	ra,24(sp)
ffffffffc0201852:	f83a                	sd	a4,48(sp)
ffffffffc0201854:	fc3e                	sd	a5,56(sp)
ffffffffc0201856:	e0c2                	sd	a6,64(sp)
ffffffffc0201858:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020185a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020185c:	c91ff0ef          	jal	ffffffffc02014ec <vprintfmt>
}
ffffffffc0201860:	60e2                	ld	ra,24(sp)
ffffffffc0201862:	6161                	add	sp,sp,80
ffffffffc0201864:	8082                	ret

ffffffffc0201866 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201866:	715d                	add	sp,sp,-80
ffffffffc0201868:	e486                	sd	ra,72(sp)
ffffffffc020186a:	e0a2                	sd	s0,64(sp)
ffffffffc020186c:	fc26                	sd	s1,56(sp)
ffffffffc020186e:	f84a                	sd	s2,48(sp)
ffffffffc0201870:	f44e                	sd	s3,40(sp)
ffffffffc0201872:	f052                	sd	s4,32(sp)
ffffffffc0201874:	ec56                	sd	s5,24(sp)
ffffffffc0201876:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201878:	c901                	beqz	a0,ffffffffc0201888 <readline+0x22>
ffffffffc020187a:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020187c:	00001517          	auipc	a0,0x1
ffffffffc0201880:	cec50513          	add	a0,a0,-788 # ffffffffc0202568 <etext+0xb82>
ffffffffc0201884:	82ffe0ef          	jal	ffffffffc02000b2 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201888:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020188a:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc020188c:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020188e:	4a29                	li	s4,10
ffffffffc0201890:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201892:	00004b17          	auipc	s6,0x4
ffffffffc0201896:	796b0b13          	add	s6,s6,1942 # ffffffffc0206028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020189a:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc020189e:	899fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02018a2:	00054a63          	bltz	a0,ffffffffc02018b6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018a6:	00a4da63          	bge	s1,a0,ffffffffc02018ba <readline+0x54>
ffffffffc02018aa:	0289d263          	bge	s3,s0,ffffffffc02018ce <readline+0x68>
        c = getchar();
ffffffffc02018ae:	889fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02018b2:	fe055ae3          	bgez	a0,ffffffffc02018a6 <readline+0x40>
            return NULL;
ffffffffc02018b6:	4501                	li	a0,0
ffffffffc02018b8:	a091                	j	ffffffffc02018fc <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02018ba:	03251463          	bne	a0,s2,ffffffffc02018e2 <readline+0x7c>
ffffffffc02018be:	04804963          	bgtz	s0,ffffffffc0201910 <readline+0xaa>
        c = getchar();
ffffffffc02018c2:	875fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02018c6:	fe0548e3          	bltz	a0,ffffffffc02018b6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018ca:	fea4d8e3          	bge	s1,a0,ffffffffc02018ba <readline+0x54>
            cputchar(c);
ffffffffc02018ce:	e42a                	sd	a0,8(sp)
ffffffffc02018d0:	817fe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc02018d4:	6522                	ld	a0,8(sp)
ffffffffc02018d6:	008b07b3          	add	a5,s6,s0
ffffffffc02018da:	2405                	addw	s0,s0,1
ffffffffc02018dc:	00a78023          	sb	a0,0(a5)
ffffffffc02018e0:	bf7d                	j	ffffffffc020189e <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02018e2:	01450463          	beq	a0,s4,ffffffffc02018ea <readline+0x84>
ffffffffc02018e6:	fb551ce3          	bne	a0,s5,ffffffffc020189e <readline+0x38>
            cputchar(c);
ffffffffc02018ea:	ffcfe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc02018ee:	00004517          	auipc	a0,0x4
ffffffffc02018f2:	73a50513          	add	a0,a0,1850 # ffffffffc0206028 <buf>
ffffffffc02018f6:	942a                	add	s0,s0,a0
ffffffffc02018f8:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc02018fc:	60a6                	ld	ra,72(sp)
ffffffffc02018fe:	6406                	ld	s0,64(sp)
ffffffffc0201900:	74e2                	ld	s1,56(sp)
ffffffffc0201902:	7942                	ld	s2,48(sp)
ffffffffc0201904:	79a2                	ld	s3,40(sp)
ffffffffc0201906:	7a02                	ld	s4,32(sp)
ffffffffc0201908:	6ae2                	ld	s5,24(sp)
ffffffffc020190a:	6b42                	ld	s6,16(sp)
ffffffffc020190c:	6161                	add	sp,sp,80
ffffffffc020190e:	8082                	ret
            cputchar(c);
ffffffffc0201910:	4521                	li	a0,8
ffffffffc0201912:	fd4fe0ef          	jal	ffffffffc02000e6 <cputchar>
            i --;
ffffffffc0201916:	347d                	addw	s0,s0,-1
ffffffffc0201918:	b759                	j	ffffffffc020189e <readline+0x38>

ffffffffc020191a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020191a:	4781                	li	a5,0
ffffffffc020191c:	00004717          	auipc	a4,0x4
ffffffffc0201920:	6ec73703          	ld	a4,1772(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201924:	88ba                	mv	a7,a4
ffffffffc0201926:	852a                	mv	a0,a0
ffffffffc0201928:	85be                	mv	a1,a5
ffffffffc020192a:	863e                	mv	a2,a5
ffffffffc020192c:	00000073          	ecall
ffffffffc0201930:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201932:	8082                	ret

ffffffffc0201934 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201934:	4781                	li	a5,0
ffffffffc0201936:	00005717          	auipc	a4,0x5
ffffffffc020193a:	b3273703          	ld	a4,-1230(a4) # ffffffffc0206468 <SBI_SET_TIMER>
ffffffffc020193e:	88ba                	mv	a7,a4
ffffffffc0201940:	852a                	mv	a0,a0
ffffffffc0201942:	85be                	mv	a1,a5
ffffffffc0201944:	863e                	mv	a2,a5
ffffffffc0201946:	00000073          	ecall
ffffffffc020194a:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc020194c:	8082                	ret

ffffffffc020194e <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc020194e:	4501                	li	a0,0
ffffffffc0201950:	00004797          	auipc	a5,0x4
ffffffffc0201954:	6b07b783          	ld	a5,1712(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201958:	88be                	mv	a7,a5
ffffffffc020195a:	852a                	mv	a0,a0
ffffffffc020195c:	85aa                	mv	a1,a0
ffffffffc020195e:	862a                	mv	a2,a0
ffffffffc0201960:	00000073          	ecall
ffffffffc0201964:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201966:	2501                	sext.w	a0,a0
ffffffffc0201968:	8082                	ret

ffffffffc020196a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020196a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020196c:	e589                	bnez	a1,ffffffffc0201976 <strnlen+0xc>
ffffffffc020196e:	a811                	j	ffffffffc0201982 <strnlen+0x18>
        cnt ++;
ffffffffc0201970:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201972:	00f58863          	beq	a1,a5,ffffffffc0201982 <strnlen+0x18>
ffffffffc0201976:	00f50733          	add	a4,a0,a5
ffffffffc020197a:	00074703          	lbu	a4,0(a4)
ffffffffc020197e:	fb6d                	bnez	a4,ffffffffc0201970 <strnlen+0x6>
ffffffffc0201980:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201982:	852e                	mv	a0,a1
ffffffffc0201984:	8082                	ret

ffffffffc0201986 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201986:	00054783          	lbu	a5,0(a0)
ffffffffc020198a:	e791                	bnez	a5,ffffffffc0201996 <strcmp+0x10>
ffffffffc020198c:	a02d                	j	ffffffffc02019b6 <strcmp+0x30>
ffffffffc020198e:	00054783          	lbu	a5,0(a0)
ffffffffc0201992:	cf89                	beqz	a5,ffffffffc02019ac <strcmp+0x26>
ffffffffc0201994:	85b6                	mv	a1,a3
ffffffffc0201996:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020199a:	0505                	add	a0,a0,1
ffffffffc020199c:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019a0:	fef707e3          	beq	a4,a5,ffffffffc020198e <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019a4:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02019a8:	9d19                	subw	a0,a0,a4
ffffffffc02019aa:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019ac:	0015c703          	lbu	a4,1(a1)
ffffffffc02019b0:	4501                	li	a0,0
}
ffffffffc02019b2:	9d19                	subw	a0,a0,a4
ffffffffc02019b4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019b6:	0005c703          	lbu	a4,0(a1)
ffffffffc02019ba:	4501                	li	a0,0
ffffffffc02019bc:	b7f5                	j	ffffffffc02019a8 <strcmp+0x22>

ffffffffc02019be <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02019be:	00054783          	lbu	a5,0(a0)
ffffffffc02019c2:	c799                	beqz	a5,ffffffffc02019d0 <strchr+0x12>
        if (*s == c) {
ffffffffc02019c4:	00f58763          	beq	a1,a5,ffffffffc02019d2 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02019c8:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02019cc:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc02019ce:	fbfd                	bnez	a5,ffffffffc02019c4 <strchr+0x6>
    }
    return NULL;
ffffffffc02019d0:	4501                	li	a0,0
}
ffffffffc02019d2:	8082                	ret

ffffffffc02019d4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02019d4:	ca01                	beqz	a2,ffffffffc02019e4 <memset+0x10>
ffffffffc02019d6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02019d8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02019da:	0785                	add	a5,a5,1
ffffffffc02019dc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02019e0:	fef61de3          	bne	a2,a5,ffffffffc02019da <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02019e4:	8082                	ret
