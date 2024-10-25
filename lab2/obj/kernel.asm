
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
ffffffffc020004a:	0d3010ef          	jal	ffffffffc020191c <memset>
    cons_init();  // init the console
ffffffffc020004e:	3f8000ef          	jal	ffffffffc0200446 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	8de50513          	add	a0,a0,-1826 # ffffffffc0201930 <etext+0x2>
ffffffffc020005a:	08e000ef          	jal	ffffffffc02000e8 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e8000ef          	jal	ffffffffc0200146 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	3fe000ef          	jal	ffffffffc0200460 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	1bc010ef          	jal	ffffffffc0201222 <pmm_init>

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
ffffffffc02000a6:	38e010ef          	jal	ffffffffc0201434 <vprintfmt>
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
ffffffffc02000da:	35a010ef          	jal	ffffffffc0201434 <vprintfmt>
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
ffffffffc020014c:	80850513          	add	a0,a0,-2040 # ffffffffc0201950 <etext+0x22>
void print_kerninfo(void) {
ffffffffc0200150:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200152:	f61ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200156:	00000597          	auipc	a1,0x0
ffffffffc020015a:	edc58593          	add	a1,a1,-292 # ffffffffc0200032 <kern_init>
ffffffffc020015e:	00002517          	auipc	a0,0x2
ffffffffc0200162:	81250513          	add	a0,a0,-2030 # ffffffffc0201970 <etext+0x42>
ffffffffc0200166:	f4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020016a:	00001597          	auipc	a1,0x1
ffffffffc020016e:	7c458593          	add	a1,a1,1988 # ffffffffc020192e <etext>
ffffffffc0200172:	00002517          	auipc	a0,0x2
ffffffffc0200176:	81e50513          	add	a0,a0,-2018 # ffffffffc0201990 <etext+0x62>
ffffffffc020017a:	f39ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017e:	00006597          	auipc	a1,0x6
ffffffffc0200182:	e9258593          	add	a1,a1,-366 # ffffffffc0206010 <free_area>
ffffffffc0200186:	00002517          	auipc	a0,0x2
ffffffffc020018a:	82a50513          	add	a0,a0,-2006 # ffffffffc02019b0 <etext+0x82>
ffffffffc020018e:	f25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200192:	00006597          	auipc	a1,0x6
ffffffffc0200196:	2de58593          	add	a1,a1,734 # ffffffffc0206470 <end>
ffffffffc020019a:	00002517          	auipc	a0,0x2
ffffffffc020019e:	83650513          	add	a0,a0,-1994 # ffffffffc02019d0 <etext+0xa2>
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
ffffffffc02001ca:	82a50513          	add	a0,a0,-2006 # ffffffffc02019f0 <etext+0xc2>
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
ffffffffc02001d8:	84c60613          	add	a2,a2,-1972 # ffffffffc0201a20 <etext+0xf2>
ffffffffc02001dc:	04e00593          	li	a1,78
ffffffffc02001e0:	00002517          	auipc	a0,0x2
ffffffffc02001e4:	85850513          	add	a0,a0,-1960 # ffffffffc0201a38 <etext+0x10a>
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
ffffffffc02001f4:	86060613          	add	a2,a2,-1952 # ffffffffc0201a50 <etext+0x122>
ffffffffc02001f8:	00002597          	auipc	a1,0x2
ffffffffc02001fc:	87858593          	add	a1,a1,-1928 # ffffffffc0201a70 <etext+0x142>
ffffffffc0200200:	00002517          	auipc	a0,0x2
ffffffffc0200204:	87850513          	add	a0,a0,-1928 # ffffffffc0201a78 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	ea9ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020020e:	00002617          	auipc	a2,0x2
ffffffffc0200212:	87a60613          	add	a2,a2,-1926 # ffffffffc0201a88 <etext+0x15a>
ffffffffc0200216:	00002597          	auipc	a1,0x2
ffffffffc020021a:	89a58593          	add	a1,a1,-1894 # ffffffffc0201ab0 <etext+0x182>
ffffffffc020021e:	00002517          	auipc	a0,0x2
ffffffffc0200222:	85a50513          	add	a0,a0,-1958 # ffffffffc0201a78 <etext+0x14a>
ffffffffc0200226:	e8dff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	89660613          	add	a2,a2,-1898 # ffffffffc0201ac0 <etext+0x192>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	8ae58593          	add	a1,a1,-1874 # ffffffffc0201ae0 <etext+0x1b2>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	83e50513          	add	a0,a0,-1986 # ffffffffc0201a78 <etext+0x14a>
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
ffffffffc0200278:	87c50513          	add	a0,a0,-1924 # ffffffffc0201af0 <etext+0x1c2>
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
ffffffffc020029a:	88250513          	add	a0,a0,-1918 # ffffffffc0201b18 <etext+0x1ea>
ffffffffc020029e:	e15ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002a2:	000b0563          	beqz	s6,ffffffffc02002ac <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a6:	855a                	mv	a0,s6
ffffffffc02002a8:	396000ef          	jal	ffffffffc020063e <print_trapframe>
ffffffffc02002ac:	00002c17          	auipc	s8,0x2
ffffffffc02002b0:	28cc0c13          	add	s8,s8,652 # ffffffffc0202538 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b4:	00002917          	auipc	s2,0x2
ffffffffc02002b8:	88c90913          	add	s2,s2,-1908 # ffffffffc0201b40 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002bc:	00002497          	auipc	s1,0x2
ffffffffc02002c0:	88c48493          	add	s1,s1,-1908 # ffffffffc0201b48 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002c4:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c6:	00002a97          	auipc	s5,0x2
ffffffffc02002ca:	88aa8a93          	add	s5,s5,-1910 # ffffffffc0201b50 <etext+0x222>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002d0:	00002b97          	auipc	s7,0x2
ffffffffc02002d4:	8a0b8b93          	add	s7,s7,-1888 # ffffffffc0201b70 <etext+0x242>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	854a                	mv	a0,s2
ffffffffc02002da:	4d4010ef          	jal	ffffffffc02017ae <readline>
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
ffffffffc02002f2:	24ad0d13          	add	s10,s10,586 # ffffffffc0202538 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	000d3503          	ld	a0,0(s10)
ffffffffc02002fe:	5d0010ef          	jal	ffffffffc02018ce <strcmp>
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
ffffffffc0200318:	5ee010ef          	jal	ffffffffc0201906 <strchr>
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
ffffffffc0200358:	5ae010ef          	jal	ffffffffc0201906 <strchr>
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
ffffffffc02003d4:	00001517          	auipc	a0,0x1
ffffffffc02003d8:	7b450513          	add	a0,a0,1972 # ffffffffc0201b88 <etext+0x25a>
    va_start(ap, fmt);
ffffffffc02003dc:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003de:	cd5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e2:	65a2                	ld	a1,8(sp)
ffffffffc02003e4:	8522                	mv	a0,s0
ffffffffc02003e6:	cadff0ef          	jal	ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003ea:	00001517          	auipc	a0,0x1
ffffffffc02003ee:	7be50513          	add	a0,a0,1982 # ffffffffc0201ba8 <etext+0x27a>
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
ffffffffc020041c:	460010ef          	jal	ffffffffc020187c <sbi_set_timer>
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	0007b723          	sd	zero,14(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042a:	00001517          	auipc	a0,0x1
ffffffffc020042e:	78650513          	add	a0,a0,1926 # ffffffffc0201bb0 <etext+0x282>
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
ffffffffc0200442:	43a0106f          	j	ffffffffc020187c <sbi_set_timer>

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
ffffffffc020044c:	4160106f          	j	ffffffffc0201862 <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200450:	4460106f          	j	ffffffffc0201896 <sbi_console_getchar>

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
ffffffffc020047a:	00001517          	auipc	a0,0x1
ffffffffc020047e:	75650513          	add	a0,a0,1878 # ffffffffc0201bd0 <etext+0x2a2>
void print_regs(struct pushregs *gpr) {
ffffffffc0200482:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	c2fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00001517          	auipc	a0,0x1
ffffffffc020048e:	75e50513          	add	a0,a0,1886 # ffffffffc0201be8 <etext+0x2ba>
ffffffffc0200492:	c21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00001517          	auipc	a0,0x1
ffffffffc020049c:	76850513          	add	a0,a0,1896 # ffffffffc0201c00 <etext+0x2d2>
ffffffffc02004a0:	c13ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00001517          	auipc	a0,0x1
ffffffffc02004aa:	77250513          	add	a0,a0,1906 # ffffffffc0201c18 <etext+0x2ea>
ffffffffc02004ae:	c05ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00001517          	auipc	a0,0x1
ffffffffc02004b8:	77c50513          	add	a0,a0,1916 # ffffffffc0201c30 <etext+0x302>
ffffffffc02004bc:	bf7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00001517          	auipc	a0,0x1
ffffffffc02004c6:	78650513          	add	a0,a0,1926 # ffffffffc0201c48 <etext+0x31a>
ffffffffc02004ca:	be9ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00001517          	auipc	a0,0x1
ffffffffc02004d4:	79050513          	add	a0,a0,1936 # ffffffffc0201c60 <etext+0x332>
ffffffffc02004d8:	bdbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00001517          	auipc	a0,0x1
ffffffffc02004e2:	79a50513          	add	a0,a0,1946 # ffffffffc0201c78 <etext+0x34a>
ffffffffc02004e6:	bcdff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00001517          	auipc	a0,0x1
ffffffffc02004f0:	7a450513          	add	a0,a0,1956 # ffffffffc0201c90 <etext+0x362>
ffffffffc02004f4:	bbfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00001517          	auipc	a0,0x1
ffffffffc02004fe:	7ae50513          	add	a0,a0,1966 # ffffffffc0201ca8 <etext+0x37a>
ffffffffc0200502:	bb1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00001517          	auipc	a0,0x1
ffffffffc020050c:	7b850513          	add	a0,a0,1976 # ffffffffc0201cc0 <etext+0x392>
ffffffffc0200510:	ba3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00001517          	auipc	a0,0x1
ffffffffc020051a:	7c250513          	add	a0,a0,1986 # ffffffffc0201cd8 <etext+0x3aa>
ffffffffc020051e:	b95ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00001517          	auipc	a0,0x1
ffffffffc0200528:	7cc50513          	add	a0,a0,1996 # ffffffffc0201cf0 <etext+0x3c2>
ffffffffc020052c:	b87ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00001517          	auipc	a0,0x1
ffffffffc0200536:	7d650513          	add	a0,a0,2006 # ffffffffc0201d08 <etext+0x3da>
ffffffffc020053a:	b79ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00001517          	auipc	a0,0x1
ffffffffc0200544:	7e050513          	add	a0,a0,2016 # ffffffffc0201d20 <etext+0x3f2>
ffffffffc0200548:	b6bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00001517          	auipc	a0,0x1
ffffffffc0200552:	7ea50513          	add	a0,a0,2026 # ffffffffc0201d38 <etext+0x40a>
ffffffffc0200556:	b5dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00001517          	auipc	a0,0x1
ffffffffc0200560:	7f450513          	add	a0,a0,2036 # ffffffffc0201d50 <etext+0x422>
ffffffffc0200564:	b4fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00001517          	auipc	a0,0x1
ffffffffc020056e:	7fe50513          	add	a0,a0,2046 # ffffffffc0201d68 <etext+0x43a>
ffffffffc0200572:	b41ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00002517          	auipc	a0,0x2
ffffffffc020057c:	80850513          	add	a0,a0,-2040 # ffffffffc0201d80 <etext+0x452>
ffffffffc0200580:	b33ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00002517          	auipc	a0,0x2
ffffffffc020058a:	81250513          	add	a0,a0,-2030 # ffffffffc0201d98 <etext+0x46a>
ffffffffc020058e:	b25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00002517          	auipc	a0,0x2
ffffffffc0200598:	81c50513          	add	a0,a0,-2020 # ffffffffc0201db0 <etext+0x482>
ffffffffc020059c:	b17ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	82650513          	add	a0,a0,-2010 # ffffffffc0201dc8 <etext+0x49a>
ffffffffc02005aa:	b09ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00002517          	auipc	a0,0x2
ffffffffc02005b4:	83050513          	add	a0,a0,-2000 # ffffffffc0201de0 <etext+0x4b2>
ffffffffc02005b8:	afbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00002517          	auipc	a0,0x2
ffffffffc02005c2:	83a50513          	add	a0,a0,-1990 # ffffffffc0201df8 <etext+0x4ca>
ffffffffc02005c6:	aedff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00002517          	auipc	a0,0x2
ffffffffc02005d0:	84450513          	add	a0,a0,-1980 # ffffffffc0201e10 <etext+0x4e2>
ffffffffc02005d4:	adfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00002517          	auipc	a0,0x2
ffffffffc02005de:	84e50513          	add	a0,a0,-1970 # ffffffffc0201e28 <etext+0x4fa>
ffffffffc02005e2:	ad1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00002517          	auipc	a0,0x2
ffffffffc02005ec:	85850513          	add	a0,a0,-1960 # ffffffffc0201e40 <etext+0x512>
ffffffffc02005f0:	ac3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00002517          	auipc	a0,0x2
ffffffffc02005fa:	86250513          	add	a0,a0,-1950 # ffffffffc0201e58 <etext+0x52a>
ffffffffc02005fe:	ab5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00002517          	auipc	a0,0x2
ffffffffc0200608:	86c50513          	add	a0,a0,-1940 # ffffffffc0201e70 <etext+0x542>
ffffffffc020060c:	aa7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00002517          	auipc	a0,0x2
ffffffffc0200616:	87650513          	add	a0,a0,-1930 # ffffffffc0201e88 <etext+0x55a>
ffffffffc020061a:	a99ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	88050513          	add	a0,a0,-1920 # ffffffffc0201ea0 <etext+0x572>
ffffffffc0200628:	a8bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	88650513          	add	a0,a0,-1914 # ffffffffc0201eb8 <etext+0x58a>
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
ffffffffc020064a:	88a50513          	add	a0,a0,-1910 # ffffffffc0201ed0 <etext+0x5a2>
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
ffffffffc0200662:	88a50513          	add	a0,a0,-1910 # ffffffffc0201ee8 <etext+0x5ba>
ffffffffc0200666:	a4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00002517          	auipc	a0,0x2
ffffffffc0200672:	89250513          	add	a0,a0,-1902 # ffffffffc0201f00 <etext+0x5d2>
ffffffffc0200676:	a3dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00002517          	auipc	a0,0x2
ffffffffc0200682:	89a50513          	add	a0,a0,-1894 # ffffffffc0201f18 <etext+0x5ea>
ffffffffc0200686:	a2dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068a:	11843583          	ld	a1,280(s0)
}
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	00002517          	auipc	a0,0x2
ffffffffc0200696:	89e50513          	add	a0,a0,-1890 # ffffffffc0201f30 <etext+0x602>
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
ffffffffc02006b0:	ed470713          	add	a4,a4,-300 # ffffffffc0202580 <commands+0x48>
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
ffffffffc02006c2:	8ea50513          	add	a0,a0,-1814 # ffffffffc0201fa8 <etext+0x67a>
ffffffffc02006c6:	b2f5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006c8:	00002517          	auipc	a0,0x2
ffffffffc02006cc:	8c050513          	add	a0,a0,-1856 # ffffffffc0201f88 <etext+0x65a>
ffffffffc02006d0:	b2cd                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d2:	00002517          	auipc	a0,0x2
ffffffffc02006d6:	87650513          	add	a0,a0,-1930 # ffffffffc0201f48 <etext+0x61a>
ffffffffc02006da:	bae1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006dc:	00002517          	auipc	a0,0x2
ffffffffc02006e0:	8ec50513          	add	a0,a0,-1812 # ffffffffc0201fc8 <etext+0x69a>
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
ffffffffc0200710:	8e450513          	add	a0,a0,-1820 # ffffffffc0201ff0 <etext+0x6c2>
ffffffffc0200714:	ba79                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200716:	00002517          	auipc	a0,0x2
ffffffffc020071a:	85250513          	add	a0,a0,-1966 # ffffffffc0201f68 <etext+0x63a>
ffffffffc020071e:	ba51                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200720:	bf39                	j	ffffffffc020063e <print_trapframe>
}
ffffffffc0200722:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200724:	06400593          	li	a1,100
ffffffffc0200728:	00002517          	auipc	a0,0x2
ffffffffc020072c:	8b850513          	add	a0,a0,-1864 # ffffffffc0201fe0 <etext+0x6b2>
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

ffffffffc020081e <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc020081e:	715d                	add	sp,sp,-80
ffffffffc0200820:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200822:	00005417          	auipc	s0,0x5
ffffffffc0200826:	7ee40413          	add	s0,s0,2030 # ffffffffc0206010 <free_area>
ffffffffc020082a:	641c                	ld	a5,8(s0)
ffffffffc020082c:	e486                	sd	ra,72(sp)
ffffffffc020082e:	fc26                	sd	s1,56(sp)
ffffffffc0200830:	f84a                	sd	s2,48(sp)
ffffffffc0200832:	f44e                	sd	s3,40(sp)
ffffffffc0200834:	f052                	sd	s4,32(sp)
ffffffffc0200836:	ec56                	sd	s5,24(sp)
ffffffffc0200838:	e85a                	sd	s6,16(sp)
ffffffffc020083a:	e45e                	sd	s7,8(sp)
ffffffffc020083c:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020083e:	28878463          	beq	a5,s0,ffffffffc0200ac6 <best_fit_check+0x2a8>
    int count = 0, total = 0;
ffffffffc0200842:	4481                	li	s1,0
ffffffffc0200844:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200846:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020084a:	8b09                	and	a4,a4,2
ffffffffc020084c:	28070163          	beqz	a4,ffffffffc0200ace <best_fit_check+0x2b0>
        count ++, total += p->property;
ffffffffc0200850:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200854:	679c                	ld	a5,8(a5)
ffffffffc0200856:	2905                	addw	s2,s2,1
ffffffffc0200858:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020085a:	fe8796e3          	bne	a5,s0,ffffffffc0200846 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020085e:	89a6                	mv	s3,s1
ffffffffc0200860:	189000ef          	jal	ffffffffc02011e8 <nr_free_pages>
ffffffffc0200864:	35351563          	bne	a0,s3,ffffffffc0200bae <best_fit_check+0x390>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200868:	4505                	li	a0,1
ffffffffc020086a:	101000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc020086e:	8a2a                	mv	s4,a0
ffffffffc0200870:	36050f63          	beqz	a0,ffffffffc0200bee <best_fit_check+0x3d0>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200874:	4505                	li	a0,1
ffffffffc0200876:	0f5000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc020087a:	89aa                	mv	s3,a0
ffffffffc020087c:	34050963          	beqz	a0,ffffffffc0200bce <best_fit_check+0x3b0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200880:	4505                	li	a0,1
ffffffffc0200882:	0e9000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200886:	8aaa                	mv	s5,a0
ffffffffc0200888:	2e050363          	beqz	a0,ffffffffc0200b6e <best_fit_check+0x350>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020088c:	273a0163          	beq	s4,s3,ffffffffc0200aee <best_fit_check+0x2d0>
ffffffffc0200890:	24aa0f63          	beq	s4,a0,ffffffffc0200aee <best_fit_check+0x2d0>
ffffffffc0200894:	24a98d63          	beq	s3,a0,ffffffffc0200aee <best_fit_check+0x2d0>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200898:	000a2783          	lw	a5,0(s4)
ffffffffc020089c:	26079963          	bnez	a5,ffffffffc0200b0e <best_fit_check+0x2f0>
ffffffffc02008a0:	0009a783          	lw	a5,0(s3)
ffffffffc02008a4:	26079563          	bnez	a5,ffffffffc0200b0e <best_fit_check+0x2f0>
ffffffffc02008a8:	411c                	lw	a5,0(a0)
ffffffffc02008aa:	26079263          	bnez	a5,ffffffffc0200b0e <best_fit_check+0x2f0>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008ae:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc02008b2:	ccd78793          	add	a5,a5,-819 # fffffffffccccccd <end+0x3cac685d>
ffffffffc02008b6:	07b2                	sll	a5,a5,0xc
ffffffffc02008b8:	ccd78793          	add	a5,a5,-819
ffffffffc02008bc:	07b2                	sll	a5,a5,0xc
ffffffffc02008be:	00006717          	auipc	a4,0x6
ffffffffc02008c2:	ba273703          	ld	a4,-1118(a4) # ffffffffc0206460 <pages>
ffffffffc02008c6:	ccd78793          	add	a5,a5,-819
ffffffffc02008ca:	40ea06b3          	sub	a3,s4,a4
ffffffffc02008ce:	07b2                	sll	a5,a5,0xc
ffffffffc02008d0:	868d                	sra	a3,a3,0x3
ffffffffc02008d2:	ccd78793          	add	a5,a5,-819
ffffffffc02008d6:	02f686b3          	mul	a3,a3,a5
ffffffffc02008da:	00002597          	auipc	a1,0x2
ffffffffc02008de:	e9e5b583          	ld	a1,-354(a1) # ffffffffc0202778 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02008e2:	00006617          	auipc	a2,0x6
ffffffffc02008e6:	b7663603          	ld	a2,-1162(a2) # ffffffffc0206458 <npage>
ffffffffc02008ea:	0632                	sll	a2,a2,0xc
ffffffffc02008ec:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc02008ee:	06b2                	sll	a3,a3,0xc
ffffffffc02008f0:	22c6ff63          	bgeu	a3,a2,ffffffffc0200b2e <best_fit_check+0x310>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02008f4:	40e986b3          	sub	a3,s3,a4
ffffffffc02008f8:	868d                	sra	a3,a3,0x3
ffffffffc02008fa:	02f686b3          	mul	a3,a3,a5
ffffffffc02008fe:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200900:	06b2                	sll	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200902:	3ec6f663          	bgeu	a3,a2,ffffffffc0200cee <best_fit_check+0x4d0>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200906:	40e50733          	sub	a4,a0,a4
ffffffffc020090a:	870d                	sra	a4,a4,0x3
ffffffffc020090c:	02f707b3          	mul	a5,a4,a5
ffffffffc0200910:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200912:	07b2                	sll	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200914:	3ac7fd63          	bgeu	a5,a2,ffffffffc0200cce <best_fit_check+0x4b0>
    assert(alloc_page() == NULL);
ffffffffc0200918:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020091a:	00043c03          	ld	s8,0(s0)
ffffffffc020091e:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200922:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200926:	e400                	sd	s0,8(s0)
ffffffffc0200928:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc020092a:	00005797          	auipc	a5,0x5
ffffffffc020092e:	6e07ab23          	sw	zero,1782(a5) # ffffffffc0206020 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200932:	039000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200936:	36051c63          	bnez	a0,ffffffffc0200cae <best_fit_check+0x490>
    free_page(p0);
ffffffffc020093a:	4585                	li	a1,1
ffffffffc020093c:	8552                	mv	a0,s4
ffffffffc020093e:	06b000ef          	jal	ffffffffc02011a8 <free_pages>
    free_page(p1);
ffffffffc0200942:	4585                	li	a1,1
ffffffffc0200944:	854e                	mv	a0,s3
ffffffffc0200946:	063000ef          	jal	ffffffffc02011a8 <free_pages>
    free_page(p2);
ffffffffc020094a:	4585                	li	a1,1
ffffffffc020094c:	8556                	mv	a0,s5
ffffffffc020094e:	05b000ef          	jal	ffffffffc02011a8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200952:	4818                	lw	a4,16(s0)
ffffffffc0200954:	478d                	li	a5,3
ffffffffc0200956:	32f71c63          	bne	a4,a5,ffffffffc0200c8e <best_fit_check+0x470>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020095a:	4505                	li	a0,1
ffffffffc020095c:	00f000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200960:	89aa                	mv	s3,a0
ffffffffc0200962:	30050663          	beqz	a0,ffffffffc0200c6e <best_fit_check+0x450>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200966:	4505                	li	a0,1
ffffffffc0200968:	003000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc020096c:	8aaa                	mv	s5,a0
ffffffffc020096e:	2e050063          	beqz	a0,ffffffffc0200c4e <best_fit_check+0x430>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200972:	4505                	li	a0,1
ffffffffc0200974:	7f6000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200978:	8a2a                	mv	s4,a0
ffffffffc020097a:	2a050a63          	beqz	a0,ffffffffc0200c2e <best_fit_check+0x410>
    assert(alloc_page() == NULL);
ffffffffc020097e:	4505                	li	a0,1
ffffffffc0200980:	7ea000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200984:	28051563          	bnez	a0,ffffffffc0200c0e <best_fit_check+0x3f0>
    free_page(p0);
ffffffffc0200988:	4585                	li	a1,1
ffffffffc020098a:	854e                	mv	a0,s3
ffffffffc020098c:	01d000ef          	jal	ffffffffc02011a8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200990:	641c                	ld	a5,8(s0)
ffffffffc0200992:	1a878e63          	beq	a5,s0,ffffffffc0200b4e <best_fit_check+0x330>
    assert((p = alloc_page()) == p0);
ffffffffc0200996:	4505                	li	a0,1
ffffffffc0200998:	7d2000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc020099c:	52a99963          	bne	s3,a0,ffffffffc0200ece <best_fit_check+0x6b0>
    assert(alloc_page() == NULL);
ffffffffc02009a0:	4505                	li	a0,1
ffffffffc02009a2:	7c8000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc02009a6:	50051463          	bnez	a0,ffffffffc0200eae <best_fit_check+0x690>
    assert(nr_free == 0);
ffffffffc02009aa:	481c                	lw	a5,16(s0)
ffffffffc02009ac:	4e079163          	bnez	a5,ffffffffc0200e8e <best_fit_check+0x670>
    free_page(p);
ffffffffc02009b0:	854e                	mv	a0,s3
ffffffffc02009b2:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc02009b4:	01843023          	sd	s8,0(s0)
ffffffffc02009b8:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02009bc:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02009c0:	7e8000ef          	jal	ffffffffc02011a8 <free_pages>
    free_page(p1);
ffffffffc02009c4:	4585                	li	a1,1
ffffffffc02009c6:	8556                	mv	a0,s5
ffffffffc02009c8:	7e0000ef          	jal	ffffffffc02011a8 <free_pages>
    free_page(p2);
ffffffffc02009cc:	4585                	li	a1,1
ffffffffc02009ce:	8552                	mv	a0,s4
ffffffffc02009d0:	7d8000ef          	jal	ffffffffc02011a8 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02009d4:	4515                	li	a0,5
ffffffffc02009d6:	794000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc02009da:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02009dc:	48050963          	beqz	a0,ffffffffc0200e6e <best_fit_check+0x650>
ffffffffc02009e0:	651c                	ld	a5,8(a0)
ffffffffc02009e2:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc02009e4:	8b85                	and	a5,a5,1
ffffffffc02009e6:	46079463          	bnez	a5,ffffffffc0200e4e <best_fit_check+0x630>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02009ea:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02009ec:	00043a83          	ld	s5,0(s0)
ffffffffc02009f0:	00843a03          	ld	s4,8(s0)
ffffffffc02009f4:	e000                	sd	s0,0(s0)
ffffffffc02009f6:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02009f8:	772000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc02009fc:	42051963          	bnez	a0,ffffffffc0200e2e <best_fit_check+0x610>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200a00:	4589                	li	a1,2
ffffffffc0200a02:	02898513          	add	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200a06:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200a0a:	0a098c13          	add	s8,s3,160
    nr_free = 0;
ffffffffc0200a0e:	00005797          	auipc	a5,0x5
ffffffffc0200a12:	6007a923          	sw	zero,1554(a5) # ffffffffc0206020 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200a16:	792000ef          	jal	ffffffffc02011a8 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200a1a:	8562                	mv	a0,s8
ffffffffc0200a1c:	4585                	li	a1,1
ffffffffc0200a1e:	78a000ef          	jal	ffffffffc02011a8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200a22:	4511                	li	a0,4
ffffffffc0200a24:	746000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200a28:	3e051363          	bnez	a0,ffffffffc0200e0e <best_fit_check+0x5f0>
ffffffffc0200a2c:	0309b783          	ld	a5,48(s3)
ffffffffc0200a30:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200a32:	8b85                	and	a5,a5,1
ffffffffc0200a34:	3a078d63          	beqz	a5,ffffffffc0200dee <best_fit_check+0x5d0>
ffffffffc0200a38:	0389a703          	lw	a4,56(s3)
ffffffffc0200a3c:	4789                	li	a5,2
ffffffffc0200a3e:	3af71863          	bne	a4,a5,ffffffffc0200dee <best_fit_check+0x5d0>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200a42:	4505                	li	a0,1
ffffffffc0200a44:	726000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200a48:	8baa                	mv	s7,a0
ffffffffc0200a4a:	38050263          	beqz	a0,ffffffffc0200dce <best_fit_check+0x5b0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200a4e:	4509                	li	a0,2
ffffffffc0200a50:	71a000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200a54:	34050d63          	beqz	a0,ffffffffc0200dae <best_fit_check+0x590>
    assert(p0 + 4 == p1);
ffffffffc0200a58:	337c1b63          	bne	s8,s7,ffffffffc0200d8e <best_fit_check+0x570>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200a5c:	854e                	mv	a0,s3
ffffffffc0200a5e:	4595                	li	a1,5
ffffffffc0200a60:	748000ef          	jal	ffffffffc02011a8 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200a64:	4515                	li	a0,5
ffffffffc0200a66:	704000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200a6a:	89aa                	mv	s3,a0
ffffffffc0200a6c:	30050163          	beqz	a0,ffffffffc0200d6e <best_fit_check+0x550>
    assert(alloc_page() == NULL);
ffffffffc0200a70:	4505                	li	a0,1
ffffffffc0200a72:	6f8000ef          	jal	ffffffffc020116a <alloc_pages>
ffffffffc0200a76:	2c051c63          	bnez	a0,ffffffffc0200d4e <best_fit_check+0x530>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200a7a:	481c                	lw	a5,16(s0)
ffffffffc0200a7c:	2a079963          	bnez	a5,ffffffffc0200d2e <best_fit_check+0x510>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200a80:	4595                	li	a1,5
ffffffffc0200a82:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200a84:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200a88:	01543023          	sd	s5,0(s0)
ffffffffc0200a8c:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200a90:	718000ef          	jal	ffffffffc02011a8 <free_pages>
    return listelm->next;
ffffffffc0200a94:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200a96:	00878963          	beq	a5,s0,ffffffffc0200aa8 <best_fit_check+0x28a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200a9a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200a9e:	679c                	ld	a5,8(a5)
ffffffffc0200aa0:	397d                	addw	s2,s2,-1
ffffffffc0200aa2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200aa4:	fe879be3          	bne	a5,s0,ffffffffc0200a9a <best_fit_check+0x27c>
    }
    assert(count == 0);
ffffffffc0200aa8:	26091363          	bnez	s2,ffffffffc0200d0e <best_fit_check+0x4f0>
    assert(total == 0);
ffffffffc0200aac:	e0ed                	bnez	s1,ffffffffc0200b8e <best_fit_check+0x370>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200aae:	60a6                	ld	ra,72(sp)
ffffffffc0200ab0:	6406                	ld	s0,64(sp)
ffffffffc0200ab2:	74e2                	ld	s1,56(sp)
ffffffffc0200ab4:	7942                	ld	s2,48(sp)
ffffffffc0200ab6:	79a2                	ld	s3,40(sp)
ffffffffc0200ab8:	7a02                	ld	s4,32(sp)
ffffffffc0200aba:	6ae2                	ld	s5,24(sp)
ffffffffc0200abc:	6b42                	ld	s6,16(sp)
ffffffffc0200abe:	6ba2                	ld	s7,8(sp)
ffffffffc0200ac0:	6c02                	ld	s8,0(sp)
ffffffffc0200ac2:	6161                	add	sp,sp,80
ffffffffc0200ac4:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ac6:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ac8:	4481                	li	s1,0
ffffffffc0200aca:	4901                	li	s2,0
ffffffffc0200acc:	bb51                	j	ffffffffc0200860 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200ace:	00001697          	auipc	a3,0x1
ffffffffc0200ad2:	54268693          	add	a3,a3,1346 # ffffffffc0202010 <etext+0x6e2>
ffffffffc0200ad6:	00001617          	auipc	a2,0x1
ffffffffc0200ada:	54a60613          	add	a2,a2,1354 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200ade:	0f800593          	li	a1,248
ffffffffc0200ae2:	00001517          	auipc	a0,0x1
ffffffffc0200ae6:	55650513          	add	a0,a0,1366 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200aea:	8bdff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	5e268693          	add	a3,a3,1506 # ffffffffc02020d0 <etext+0x7a2>
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	52a60613          	add	a2,a2,1322 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200afe:	0c400593          	li	a1,196
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	53650513          	add	a0,a0,1334 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200b0a:	89dff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	5ea68693          	add	a3,a3,1514 # ffffffffc02020f8 <etext+0x7ca>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	50a60613          	add	a2,a2,1290 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200b1e:	0c500593          	li	a1,197
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	51650513          	add	a0,a0,1302 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200b2a:	87dff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b2e:	00001697          	auipc	a3,0x1
ffffffffc0200b32:	60a68693          	add	a3,a3,1546 # ffffffffc0202138 <etext+0x80a>
ffffffffc0200b36:	00001617          	auipc	a2,0x1
ffffffffc0200b3a:	4ea60613          	add	a2,a2,1258 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200b3e:	0c700593          	li	a1,199
ffffffffc0200b42:	00001517          	auipc	a0,0x1
ffffffffc0200b46:	4f650513          	add	a0,a0,1270 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200b4a:	85dff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200b4e:	00001697          	auipc	a3,0x1
ffffffffc0200b52:	67268693          	add	a3,a3,1650 # ffffffffc02021c0 <etext+0x892>
ffffffffc0200b56:	00001617          	auipc	a2,0x1
ffffffffc0200b5a:	4ca60613          	add	a2,a2,1226 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200b5e:	0e000593          	li	a1,224
ffffffffc0200b62:	00001517          	auipc	a0,0x1
ffffffffc0200b66:	4d650513          	add	a0,a0,1238 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200b6a:	83dff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b6e:	00001697          	auipc	a3,0x1
ffffffffc0200b72:	54268693          	add	a3,a3,1346 # ffffffffc02020b0 <etext+0x782>
ffffffffc0200b76:	00001617          	auipc	a2,0x1
ffffffffc0200b7a:	4aa60613          	add	a2,a2,1194 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200b7e:	0c200593          	li	a1,194
ffffffffc0200b82:	00001517          	auipc	a0,0x1
ffffffffc0200b86:	4b650513          	add	a0,a0,1206 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200b8a:	81dff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == 0);
ffffffffc0200b8e:	00001697          	auipc	a3,0x1
ffffffffc0200b92:	76268693          	add	a3,a3,1890 # ffffffffc02022f0 <etext+0x9c2>
ffffffffc0200b96:	00001617          	auipc	a2,0x1
ffffffffc0200b9a:	48a60613          	add	a2,a2,1162 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200b9e:	13a00593          	li	a1,314
ffffffffc0200ba2:	00001517          	auipc	a0,0x1
ffffffffc0200ba6:	49650513          	add	a0,a0,1174 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200baa:	ffcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200bae:	00001697          	auipc	a3,0x1
ffffffffc0200bb2:	4a268693          	add	a3,a3,1186 # ffffffffc0202050 <etext+0x722>
ffffffffc0200bb6:	00001617          	auipc	a2,0x1
ffffffffc0200bba:	46a60613          	add	a2,a2,1130 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200bbe:	0fb00593          	li	a1,251
ffffffffc0200bc2:	00001517          	auipc	a0,0x1
ffffffffc0200bc6:	47650513          	add	a0,a0,1142 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200bca:	fdcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200bce:	00001697          	auipc	a3,0x1
ffffffffc0200bd2:	4c268693          	add	a3,a3,1218 # ffffffffc0202090 <etext+0x762>
ffffffffc0200bd6:	00001617          	auipc	a2,0x1
ffffffffc0200bda:	44a60613          	add	a2,a2,1098 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200bde:	0c100593          	li	a1,193
ffffffffc0200be2:	00001517          	auipc	a0,0x1
ffffffffc0200be6:	45650513          	add	a0,a0,1110 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200bea:	fbcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bee:	00001697          	auipc	a3,0x1
ffffffffc0200bf2:	48268693          	add	a3,a3,1154 # ffffffffc0202070 <etext+0x742>
ffffffffc0200bf6:	00001617          	auipc	a2,0x1
ffffffffc0200bfa:	42a60613          	add	a2,a2,1066 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200bfe:	0c000593          	li	a1,192
ffffffffc0200c02:	00001517          	auipc	a0,0x1
ffffffffc0200c06:	43650513          	add	a0,a0,1078 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200c0a:	f9cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c0e:	00001697          	auipc	a3,0x1
ffffffffc0200c12:	58a68693          	add	a3,a3,1418 # ffffffffc0202198 <etext+0x86a>
ffffffffc0200c16:	00001617          	auipc	a2,0x1
ffffffffc0200c1a:	40a60613          	add	a2,a2,1034 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200c1e:	0dd00593          	li	a1,221
ffffffffc0200c22:	00001517          	auipc	a0,0x1
ffffffffc0200c26:	41650513          	add	a0,a0,1046 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200c2a:	f7cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c2e:	00001697          	auipc	a3,0x1
ffffffffc0200c32:	48268693          	add	a3,a3,1154 # ffffffffc02020b0 <etext+0x782>
ffffffffc0200c36:	00001617          	auipc	a2,0x1
ffffffffc0200c3a:	3ea60613          	add	a2,a2,1002 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200c3e:	0db00593          	li	a1,219
ffffffffc0200c42:	00001517          	auipc	a0,0x1
ffffffffc0200c46:	3f650513          	add	a0,a0,1014 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200c4a:	f5cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c4e:	00001697          	auipc	a3,0x1
ffffffffc0200c52:	44268693          	add	a3,a3,1090 # ffffffffc0202090 <etext+0x762>
ffffffffc0200c56:	00001617          	auipc	a2,0x1
ffffffffc0200c5a:	3ca60613          	add	a2,a2,970 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200c5e:	0da00593          	li	a1,218
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	3d650513          	add	a0,a0,982 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200c6a:	f3cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c6e:	00001697          	auipc	a3,0x1
ffffffffc0200c72:	40268693          	add	a3,a3,1026 # ffffffffc0202070 <etext+0x742>
ffffffffc0200c76:	00001617          	auipc	a2,0x1
ffffffffc0200c7a:	3aa60613          	add	a2,a2,938 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200c7e:	0d900593          	li	a1,217
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	3b650513          	add	a0,a0,950 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200c8a:	f1cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 3);
ffffffffc0200c8e:	00001697          	auipc	a3,0x1
ffffffffc0200c92:	52268693          	add	a3,a3,1314 # ffffffffc02021b0 <etext+0x882>
ffffffffc0200c96:	00001617          	auipc	a2,0x1
ffffffffc0200c9a:	38a60613          	add	a2,a2,906 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200c9e:	0d700593          	li	a1,215
ffffffffc0200ca2:	00001517          	auipc	a0,0x1
ffffffffc0200ca6:	39650513          	add	a0,a0,918 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200caa:	efcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cae:	00001697          	auipc	a3,0x1
ffffffffc0200cb2:	4ea68693          	add	a3,a3,1258 # ffffffffc0202198 <etext+0x86a>
ffffffffc0200cb6:	00001617          	auipc	a2,0x1
ffffffffc0200cba:	36a60613          	add	a2,a2,874 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200cbe:	0d200593          	li	a1,210
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	37650513          	add	a0,a0,886 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200cca:	edcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200cce:	00001697          	auipc	a3,0x1
ffffffffc0200cd2:	4aa68693          	add	a3,a3,1194 # ffffffffc0202178 <etext+0x84a>
ffffffffc0200cd6:	00001617          	auipc	a2,0x1
ffffffffc0200cda:	34a60613          	add	a2,a2,842 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200cde:	0c900593          	li	a1,201
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	35650513          	add	a0,a0,854 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200cea:	ebcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cee:	00001697          	auipc	a3,0x1
ffffffffc0200cf2:	46a68693          	add	a3,a3,1130 # ffffffffc0202158 <etext+0x82a>
ffffffffc0200cf6:	00001617          	auipc	a2,0x1
ffffffffc0200cfa:	32a60613          	add	a2,a2,810 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200cfe:	0c800593          	li	a1,200
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	33650513          	add	a0,a0,822 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200d0a:	e9cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(count == 0);
ffffffffc0200d0e:	00001697          	auipc	a3,0x1
ffffffffc0200d12:	5d268693          	add	a3,a3,1490 # ffffffffc02022e0 <etext+0x9b2>
ffffffffc0200d16:	00001617          	auipc	a2,0x1
ffffffffc0200d1a:	30a60613          	add	a2,a2,778 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200d1e:	13900593          	li	a1,313
ffffffffc0200d22:	00001517          	auipc	a0,0x1
ffffffffc0200d26:	31650513          	add	a0,a0,790 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200d2a:	e7cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200d2e:	00001697          	auipc	a3,0x1
ffffffffc0200d32:	4ca68693          	add	a3,a3,1226 # ffffffffc02021f8 <etext+0x8ca>
ffffffffc0200d36:	00001617          	auipc	a2,0x1
ffffffffc0200d3a:	2ea60613          	add	a2,a2,746 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200d3e:	12e00593          	li	a1,302
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	2f650513          	add	a0,a0,758 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200d4a:	e5cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d4e:	00001697          	auipc	a3,0x1
ffffffffc0200d52:	44a68693          	add	a3,a3,1098 # ffffffffc0202198 <etext+0x86a>
ffffffffc0200d56:	00001617          	auipc	a2,0x1
ffffffffc0200d5a:	2ca60613          	add	a2,a2,714 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200d5e:	12800593          	li	a1,296
ffffffffc0200d62:	00001517          	auipc	a0,0x1
ffffffffc0200d66:	2d650513          	add	a0,a0,726 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200d6a:	e3cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200d6e:	00001697          	auipc	a3,0x1
ffffffffc0200d72:	55268693          	add	a3,a3,1362 # ffffffffc02022c0 <etext+0x992>
ffffffffc0200d76:	00001617          	auipc	a2,0x1
ffffffffc0200d7a:	2aa60613          	add	a2,a2,682 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200d7e:	12700593          	li	a1,295
ffffffffc0200d82:	00001517          	auipc	a0,0x1
ffffffffc0200d86:	2b650513          	add	a0,a0,694 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200d8a:	e1cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200d8e:	00001697          	auipc	a3,0x1
ffffffffc0200d92:	52268693          	add	a3,a3,1314 # ffffffffc02022b0 <etext+0x982>
ffffffffc0200d96:	00001617          	auipc	a2,0x1
ffffffffc0200d9a:	28a60613          	add	a2,a2,650 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200d9e:	11f00593          	li	a1,287
ffffffffc0200da2:	00001517          	auipc	a0,0x1
ffffffffc0200da6:	29650513          	add	a0,a0,662 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200daa:	dfcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200dae:	00001697          	auipc	a3,0x1
ffffffffc0200db2:	4ea68693          	add	a3,a3,1258 # ffffffffc0202298 <etext+0x96a>
ffffffffc0200db6:	00001617          	auipc	a2,0x1
ffffffffc0200dba:	26a60613          	add	a2,a2,618 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200dbe:	11e00593          	li	a1,286
ffffffffc0200dc2:	00001517          	auipc	a0,0x1
ffffffffc0200dc6:	27650513          	add	a0,a0,630 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200dca:	ddcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200dce:	00001697          	auipc	a3,0x1
ffffffffc0200dd2:	4aa68693          	add	a3,a3,1194 # ffffffffc0202278 <etext+0x94a>
ffffffffc0200dd6:	00001617          	auipc	a2,0x1
ffffffffc0200dda:	24a60613          	add	a2,a2,586 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200dde:	11d00593          	li	a1,285
ffffffffc0200de2:	00001517          	auipc	a0,0x1
ffffffffc0200de6:	25650513          	add	a0,a0,598 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200dea:	dbcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200dee:	00001697          	auipc	a3,0x1
ffffffffc0200df2:	45a68693          	add	a3,a3,1114 # ffffffffc0202248 <etext+0x91a>
ffffffffc0200df6:	00001617          	auipc	a2,0x1
ffffffffc0200dfa:	22a60613          	add	a2,a2,554 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200dfe:	11b00593          	li	a1,283
ffffffffc0200e02:	00001517          	auipc	a0,0x1
ffffffffc0200e06:	23650513          	add	a0,a0,566 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200e0a:	d9cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e0e:	00001697          	auipc	a3,0x1
ffffffffc0200e12:	42268693          	add	a3,a3,1058 # ffffffffc0202230 <etext+0x902>
ffffffffc0200e16:	00001617          	auipc	a2,0x1
ffffffffc0200e1a:	20a60613          	add	a2,a2,522 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200e1e:	11a00593          	li	a1,282
ffffffffc0200e22:	00001517          	auipc	a0,0x1
ffffffffc0200e26:	21650513          	add	a0,a0,534 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200e2a:	d7cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e2e:	00001697          	auipc	a3,0x1
ffffffffc0200e32:	36a68693          	add	a3,a3,874 # ffffffffc0202198 <etext+0x86a>
ffffffffc0200e36:	00001617          	auipc	a2,0x1
ffffffffc0200e3a:	1ea60613          	add	a2,a2,490 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200e3e:	10e00593          	li	a1,270
ffffffffc0200e42:	00001517          	auipc	a0,0x1
ffffffffc0200e46:	1f650513          	add	a0,a0,502 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200e4a:	d5cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200e4e:	00001697          	auipc	a3,0x1
ffffffffc0200e52:	3ca68693          	add	a3,a3,970 # ffffffffc0202218 <etext+0x8ea>
ffffffffc0200e56:	00001617          	auipc	a2,0x1
ffffffffc0200e5a:	1ca60613          	add	a2,a2,458 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200e5e:	10500593          	li	a1,261
ffffffffc0200e62:	00001517          	auipc	a0,0x1
ffffffffc0200e66:	1d650513          	add	a0,a0,470 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200e6a:	d3cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != NULL);
ffffffffc0200e6e:	00001697          	auipc	a3,0x1
ffffffffc0200e72:	39a68693          	add	a3,a3,922 # ffffffffc0202208 <etext+0x8da>
ffffffffc0200e76:	00001617          	auipc	a2,0x1
ffffffffc0200e7a:	1aa60613          	add	a2,a2,426 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200e7e:	10400593          	li	a1,260
ffffffffc0200e82:	00001517          	auipc	a0,0x1
ffffffffc0200e86:	1b650513          	add	a0,a0,438 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200e8a:	d1cff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200e8e:	00001697          	auipc	a3,0x1
ffffffffc0200e92:	36a68693          	add	a3,a3,874 # ffffffffc02021f8 <etext+0x8ca>
ffffffffc0200e96:	00001617          	auipc	a2,0x1
ffffffffc0200e9a:	18a60613          	add	a2,a2,394 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200e9e:	0e600593          	li	a1,230
ffffffffc0200ea2:	00001517          	auipc	a0,0x1
ffffffffc0200ea6:	19650513          	add	a0,a0,406 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200eaa:	cfcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200eae:	00001697          	auipc	a3,0x1
ffffffffc0200eb2:	2ea68693          	add	a3,a3,746 # ffffffffc0202198 <etext+0x86a>
ffffffffc0200eb6:	00001617          	auipc	a2,0x1
ffffffffc0200eba:	16a60613          	add	a2,a2,362 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200ebe:	0e400593          	li	a1,228
ffffffffc0200ec2:	00001517          	auipc	a0,0x1
ffffffffc0200ec6:	17650513          	add	a0,a0,374 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200eca:	cdcff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200ece:	00001697          	auipc	a3,0x1
ffffffffc0200ed2:	30a68693          	add	a3,a3,778 # ffffffffc02021d8 <etext+0x8aa>
ffffffffc0200ed6:	00001617          	auipc	a2,0x1
ffffffffc0200eda:	14a60613          	add	a2,a2,330 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200ede:	0e300593          	li	a1,227
ffffffffc0200ee2:	00001517          	auipc	a0,0x1
ffffffffc0200ee6:	15650513          	add	a0,a0,342 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200eea:	cbcff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200eee <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200eee:	1141                	add	sp,sp,-16
ffffffffc0200ef0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ef2:	cded                	beqz	a1,ffffffffc0200fec <best_fit_free_pages+0xfe>
    for (; p != base + n; p ++) {
ffffffffc0200ef4:	00259713          	sll	a4,a1,0x2
ffffffffc0200ef8:	972e                	add	a4,a4,a1
ffffffffc0200efa:	070e                	sll	a4,a4,0x3
ffffffffc0200efc:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200f00:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200f02:	cf19                	beqz	a4,ffffffffc0200f20 <best_fit_free_pages+0x32>
ffffffffc0200f04:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200f06:	8b05                	and	a4,a4,1
ffffffffc0200f08:	e371                	bnez	a4,ffffffffc0200fcc <best_fit_free_pages+0xde>
ffffffffc0200f0a:	6798                	ld	a4,8(a5)
ffffffffc0200f0c:	8b09                	and	a4,a4,2
ffffffffc0200f0e:	ef5d                	bnez	a4,ffffffffc0200fcc <best_fit_free_pages+0xde>
        p->flags = 0;
ffffffffc0200f10:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200f14:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f18:	02878793          	add	a5,a5,40
ffffffffc0200f1c:	fed794e3          	bne	a5,a3,ffffffffc0200f04 <best_fit_free_pages+0x16>
    return list->next == list;
ffffffffc0200f20:	00005697          	auipc	a3,0x5
ffffffffc0200f24:	0f068693          	add	a3,a3,240 # ffffffffc0206010 <free_area>
ffffffffc0200f28:	669c                	ld	a5,8(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f2a:	06d78563          	beq	a5,a3,ffffffffc0200f94 <best_fit_free_pages+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f2e:	fe878713          	add	a4,a5,-24
ffffffffc0200f32:	4581                	li	a1,0
ffffffffc0200f34:	01850613          	add	a2,a0,24
            if (base < page) {
ffffffffc0200f38:	00e56a63          	bltu	a0,a4,ffffffffc0200f4c <best_fit_free_pages+0x5e>
    return listelm->next;
ffffffffc0200f3c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f3e:	04d70163          	beq	a4,a3,ffffffffc0200f80 <best_fit_free_pages+0x92>
    struct Page *p = base;
ffffffffc0200f42:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f44:	fe878713          	add	a4,a5,-24
            if (base < page) {
ffffffffc0200f48:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f3c <best_fit_free_pages+0x4e>
ffffffffc0200f4c:	c199                	beqz	a1,ffffffffc0200f52 <best_fit_free_pages+0x64>
ffffffffc0200f4e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f52:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200f54:	e390                	sd	a2,0(a5)
ffffffffc0200f56:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f58:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f5a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0200f5c:	00d78f63          	beq	a5,a3,ffffffffc0200f7a <best_fit_free_pages+0x8c>
        if (base + base->property == p) {
ffffffffc0200f60:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200f62:	fe878693          	add	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200f66:	02059613          	sll	a2,a1,0x20
ffffffffc0200f6a:	9201                	srl	a2,a2,0x20
ffffffffc0200f6c:	00261713          	sll	a4,a2,0x2
ffffffffc0200f70:	9732                	add	a4,a4,a2
ffffffffc0200f72:	070e                	sll	a4,a4,0x3
ffffffffc0200f74:	972a                	add	a4,a4,a0
ffffffffc0200f76:	02e68b63          	beq	a3,a4,ffffffffc0200fac <best_fit_free_pages+0xbe>
}
ffffffffc0200f7a:	60a2                	ld	ra,8(sp)
ffffffffc0200f7c:	0141                	add	sp,sp,16
ffffffffc0200f7e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f80:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f82:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f84:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f86:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200f88:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f8a:	00d70e63          	beq	a4,a3,ffffffffc0200fa6 <best_fit_free_pages+0xb8>
ffffffffc0200f8e:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200f90:	87ba                	mv	a5,a4
ffffffffc0200f92:	bf4d                	j	ffffffffc0200f44 <best_fit_free_pages+0x56>
}
ffffffffc0200f94:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f96:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200f9a:	e398                	sd	a4,0(a5)
ffffffffc0200f9c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200f9e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fa0:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200fa2:	0141                	add	sp,sp,16
ffffffffc0200fa4:	8082                	ret
ffffffffc0200fa6:	e290                	sd	a2,0(a3)
    return listelm->next;
ffffffffc0200fa8:	87b6                	mv	a5,a3
ffffffffc0200faa:	bf4d                	j	ffffffffc0200f5c <best_fit_free_pages+0x6e>
            base->property += p->property;
ffffffffc0200fac:	ff87a703          	lw	a4,-8(a5)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200fb0:	ff078693          	add	a3,a5,-16
ffffffffc0200fb4:	9f2d                	addw	a4,a4,a1
ffffffffc0200fb6:	c918                	sw	a4,16(a0)
ffffffffc0200fb8:	5775                	li	a4,-3
ffffffffc0200fba:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200fbe:	6398                	ld	a4,0(a5)
ffffffffc0200fc0:	679c                	ld	a5,8(a5)
}
ffffffffc0200fc2:	60a2                	ld	ra,8(sp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200fc4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200fc6:	e398                	sd	a4,0(a5)
ffffffffc0200fc8:	0141                	add	sp,sp,16
ffffffffc0200fca:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200fcc:	00001697          	auipc	a3,0x1
ffffffffc0200fd0:	33c68693          	add	a3,a3,828 # ffffffffc0202308 <etext+0x9da>
ffffffffc0200fd4:	00001617          	auipc	a2,0x1
ffffffffc0200fd8:	04c60613          	add	a2,a2,76 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200fdc:	08900593          	li	a1,137
ffffffffc0200fe0:	00001517          	auipc	a0,0x1
ffffffffc0200fe4:	05850513          	add	a0,a0,88 # ffffffffc0202038 <etext+0x70a>
ffffffffc0200fe8:	bbeff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc0200fec:	00001697          	auipc	a3,0x1
ffffffffc0200ff0:	31468693          	add	a3,a3,788 # ffffffffc0202300 <etext+0x9d2>
ffffffffc0200ff4:	00001617          	auipc	a2,0x1
ffffffffc0200ff8:	02c60613          	add	a2,a2,44 # ffffffffc0202020 <etext+0x6f2>
ffffffffc0200ffc:	08600593          	li	a1,134
ffffffffc0201000:	00001517          	auipc	a0,0x1
ffffffffc0201004:	03850513          	add	a0,a0,56 # ffffffffc0202038 <etext+0x70a>
ffffffffc0201008:	b9eff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc020100c <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020100c:	c959                	beqz	a0,ffffffffc02010a2 <best_fit_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020100e:	00005617          	auipc	a2,0x5
ffffffffc0201012:	00260613          	add	a2,a2,2 # ffffffffc0206010 <free_area>
ffffffffc0201016:	4a0c                	lw	a1,16(a2)
ffffffffc0201018:	86aa                	mv	a3,a0
ffffffffc020101a:	02059793          	sll	a5,a1,0x20
ffffffffc020101e:	9381                	srl	a5,a5,0x20
ffffffffc0201020:	00a7eb63          	bltu	a5,a0,ffffffffc0201036 <best_fit_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201024:	87b2                	mv	a5,a2
ffffffffc0201026:	a029                	j	ffffffffc0201030 <best_fit_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc0201028:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020102c:	00d77763          	bgeu	a4,a3,ffffffffc020103a <best_fit_alloc_pages+0x2e>
    return listelm->next;
ffffffffc0201030:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201032:	fec79be3          	bne	a5,a2,ffffffffc0201028 <best_fit_alloc_pages+0x1c>
        return NULL;
ffffffffc0201036:	4501                	li	a0,0
}
ffffffffc0201038:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020103a:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc020103c:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc0201040:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201044:	fe878513          	add	a0,a5,-24
    prev->next = next;
ffffffffc0201048:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020104c:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc0201050:	02089713          	sll	a4,a7,0x20
ffffffffc0201054:	9301                	srl	a4,a4,0x20
            p->property = page->property - n;
ffffffffc0201056:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc020105a:	02e6fc63          	bgeu	a3,a4,ffffffffc0201092 <best_fit_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020105e:	00269713          	sll	a4,a3,0x2
ffffffffc0201062:	9736                	add	a4,a4,a3
ffffffffc0201064:	070e                	sll	a4,a4,0x3
ffffffffc0201066:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201068:	406888bb          	subw	a7,a7,t1
ffffffffc020106c:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201070:	4689                	li	a3,2
ffffffffc0201072:	00870593          	add	a1,a4,8
ffffffffc0201076:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020107a:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020107e:	01870893          	add	a7,a4,24
        nr_free -= n;
ffffffffc0201082:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201084:	0116b023          	sd	a7,0(a3)
ffffffffc0201088:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020108c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020108e:	01073c23          	sd	a6,24(a4)
ffffffffc0201092:	406585bb          	subw	a1,a1,t1
ffffffffc0201096:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201098:	5775                	li	a4,-3
ffffffffc020109a:	17c1                	add	a5,a5,-16
ffffffffc020109c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02010a0:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02010a2:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc02010a4:	00001697          	auipc	a3,0x1
ffffffffc02010a8:	25c68693          	add	a3,a3,604 # ffffffffc0202300 <etext+0x9d2>
ffffffffc02010ac:	00001617          	auipc	a2,0x1
ffffffffc02010b0:	f7460613          	add	a2,a2,-140 # ffffffffc0202020 <etext+0x6f2>
ffffffffc02010b4:	06200593          	li	a1,98
ffffffffc02010b8:	00001517          	auipc	a0,0x1
ffffffffc02010bc:	f8050513          	add	a0,a0,-128 # ffffffffc0202038 <etext+0x70a>
best_fit_alloc_pages(size_t n) {
ffffffffc02010c0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010c2:	ae4ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02010c6 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02010c6:	1141                	add	sp,sp,-16
ffffffffc02010c8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010ca:	c1c1                	beqz	a1,ffffffffc020114a <best_fit_init_memmap+0x84>
    for (; p != base + n; p ++) {
ffffffffc02010cc:	00259713          	sll	a4,a1,0x2
ffffffffc02010d0:	972e                	add	a4,a4,a1
ffffffffc02010d2:	070e                	sll	a4,a4,0x3
ffffffffc02010d4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02010d8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02010da:	cb01                	beqz	a4,ffffffffc02010ea <best_fit_init_memmap+0x24>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02010dc:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02010de:	8b05                	and	a4,a4,1
ffffffffc02010e0:	c729                	beqz	a4,ffffffffc020112a <best_fit_init_memmap+0x64>
    for (; p != base + n; p ++) {
ffffffffc02010e2:	02878793          	add	a5,a5,40
ffffffffc02010e6:	fef69be3          	bne	a3,a5,ffffffffc02010dc <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02010ea:	2581                	sext.w	a1,a1
ffffffffc02010ec:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010ee:	4789                	li	a5,2
ffffffffc02010f0:	00850713          	add	a4,a0,8
ffffffffc02010f4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02010f8:	00005717          	auipc	a4,0x5
ffffffffc02010fc:	f1870713          	add	a4,a4,-232 # ffffffffc0206010 <free_area>
ffffffffc0201100:	4b14                	lw	a3,16(a4)
    return list->next == list;
ffffffffc0201102:	671c                	ld	a5,8(a4)
ffffffffc0201104:	9ead                	addw	a3,a3,a1
ffffffffc0201106:	cb14                	sw	a3,16(a4)
    if (list_empty(&free_list)) {
ffffffffc0201108:	00e78863          	beq	a5,a4,ffffffffc0201118 <best_fit_init_memmap+0x52>
    return listelm->next;
ffffffffc020110c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020110e:	fee79fe3          	bne	a5,a4,ffffffffc020110c <best_fit_init_memmap+0x46>
}
ffffffffc0201112:	60a2                	ld	ra,8(sp)
ffffffffc0201114:	0141                	add	sp,sp,16
ffffffffc0201116:	8082                	ret
ffffffffc0201118:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020111a:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020111e:	e398                	sd	a4,0(a5)
ffffffffc0201120:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201122:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201124:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201126:	0141                	add	sp,sp,16
ffffffffc0201128:	8082                	ret
        assert(PageReserved(p));
ffffffffc020112a:	00001697          	auipc	a3,0x1
ffffffffc020112e:	20668693          	add	a3,a3,518 # ffffffffc0202330 <etext+0xa02>
ffffffffc0201132:	00001617          	auipc	a2,0x1
ffffffffc0201136:	eee60613          	add	a2,a2,-274 # ffffffffc0202020 <etext+0x6f2>
ffffffffc020113a:	04a00593          	li	a1,74
ffffffffc020113e:	00001517          	auipc	a0,0x1
ffffffffc0201142:	efa50513          	add	a0,a0,-262 # ffffffffc0202038 <etext+0x70a>
ffffffffc0201146:	a60ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc020114a:	00001697          	auipc	a3,0x1
ffffffffc020114e:	1b668693          	add	a3,a3,438 # ffffffffc0202300 <etext+0x9d2>
ffffffffc0201152:	00001617          	auipc	a2,0x1
ffffffffc0201156:	ece60613          	add	a2,a2,-306 # ffffffffc0202020 <etext+0x6f2>
ffffffffc020115a:	04700593          	li	a1,71
ffffffffc020115e:	00001517          	auipc	a0,0x1
ffffffffc0201162:	eda50513          	add	a0,a0,-294 # ffffffffc0202038 <etext+0x70a>
ffffffffc0201166:	a40ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc020116a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020116a:	100027f3          	csrr	a5,sstatus
ffffffffc020116e:	8b89                	and	a5,a5,2
ffffffffc0201170:	e799                	bnez	a5,ffffffffc020117e <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201172:	00005797          	auipc	a5,0x5
ffffffffc0201176:	2c67b783          	ld	a5,710(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc020117a:	6f9c                	ld	a5,24(a5)
ffffffffc020117c:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020117e:	1141                	add	sp,sp,-16
ffffffffc0201180:	e406                	sd	ra,8(sp)
ffffffffc0201182:	e022                	sd	s0,0(sp)
ffffffffc0201184:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201186:	ad4ff0ef          	jal	ffffffffc020045a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020118a:	00005797          	auipc	a5,0x5
ffffffffc020118e:	2ae7b783          	ld	a5,686(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0201192:	6f9c                	ld	a5,24(a5)
ffffffffc0201194:	8522                	mv	a0,s0
ffffffffc0201196:	9782                	jalr	a5
ffffffffc0201198:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020119a:	abaff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020119e:	60a2                	ld	ra,8(sp)
ffffffffc02011a0:	8522                	mv	a0,s0
ffffffffc02011a2:	6402                	ld	s0,0(sp)
ffffffffc02011a4:	0141                	add	sp,sp,16
ffffffffc02011a6:	8082                	ret

ffffffffc02011a8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011a8:	100027f3          	csrr	a5,sstatus
ffffffffc02011ac:	8b89                	and	a5,a5,2
ffffffffc02011ae:	e799                	bnez	a5,ffffffffc02011bc <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02011b0:	00005797          	auipc	a5,0x5
ffffffffc02011b4:	2887b783          	ld	a5,648(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc02011b8:	739c                	ld	a5,32(a5)
ffffffffc02011ba:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02011bc:	1101                	add	sp,sp,-32
ffffffffc02011be:	ec06                	sd	ra,24(sp)
ffffffffc02011c0:	e822                	sd	s0,16(sp)
ffffffffc02011c2:	e426                	sd	s1,8(sp)
ffffffffc02011c4:	842a                	mv	s0,a0
ffffffffc02011c6:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02011c8:	a92ff0ef          	jal	ffffffffc020045a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02011cc:	00005797          	auipc	a5,0x5
ffffffffc02011d0:	26c7b783          	ld	a5,620(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc02011d4:	739c                	ld	a5,32(a5)
ffffffffc02011d6:	85a6                	mv	a1,s1
ffffffffc02011d8:	8522                	mv	a0,s0
ffffffffc02011da:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02011dc:	6442                	ld	s0,16(sp)
ffffffffc02011de:	60e2                	ld	ra,24(sp)
ffffffffc02011e0:	64a2                	ld	s1,8(sp)
ffffffffc02011e2:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc02011e4:	a70ff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc02011e8 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02011e8:	100027f3          	csrr	a5,sstatus
ffffffffc02011ec:	8b89                	and	a5,a5,2
ffffffffc02011ee:	e799                	bnez	a5,ffffffffc02011fc <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02011f0:	00005797          	auipc	a5,0x5
ffffffffc02011f4:	2487b783          	ld	a5,584(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc02011f8:	779c                	ld	a5,40(a5)
ffffffffc02011fa:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02011fc:	1141                	add	sp,sp,-16
ffffffffc02011fe:	e406                	sd	ra,8(sp)
ffffffffc0201200:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201202:	a58ff0ef          	jal	ffffffffc020045a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201206:	00005797          	auipc	a5,0x5
ffffffffc020120a:	2327b783          	ld	a5,562(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc020120e:	779c                	ld	a5,40(a5)
ffffffffc0201210:	9782                	jalr	a5
ffffffffc0201212:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201214:	a40ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201218:	60a2                	ld	ra,8(sp)
ffffffffc020121a:	8522                	mv	a0,s0
ffffffffc020121c:	6402                	ld	s0,0(sp)
ffffffffc020121e:	0141                	add	sp,sp,16
ffffffffc0201220:	8082                	ret

ffffffffc0201222 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201222:	00001797          	auipc	a5,0x1
ffffffffc0201226:	38e78793          	add	a5,a5,910 # ffffffffc02025b0 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020122a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020122c:	1101                	add	sp,sp,-32
ffffffffc020122e:	ec06                	sd	ra,24(sp)
ffffffffc0201230:	e822                	sd	s0,16(sp)
ffffffffc0201232:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201234:	00001517          	auipc	a0,0x1
ffffffffc0201238:	12450513          	add	a0,a0,292 # ffffffffc0202358 <etext+0xa2a>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020123c:	00005497          	auipc	s1,0x5
ffffffffc0201240:	1fc48493          	add	s1,s1,508 # ffffffffc0206438 <pmm_manager>
ffffffffc0201244:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201246:	e6dfe0ef          	jal	ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc020124a:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020124c:	00005417          	auipc	s0,0x5
ffffffffc0201250:	20440413          	add	s0,s0,516 # ffffffffc0206450 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201254:	679c                	ld	a5,8(a5)
ffffffffc0201256:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201258:	57f5                	li	a5,-3
ffffffffc020125a:	07fa                	sll	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020125c:	00001517          	auipc	a0,0x1
ffffffffc0201260:	11450513          	add	a0,a0,276 # ffffffffc0202370 <etext+0xa42>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201264:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0201266:	e4dfe0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020126a:	46c5                	li	a3,17
ffffffffc020126c:	06ee                	sll	a3,a3,0x1b
ffffffffc020126e:	40100613          	li	a2,1025
ffffffffc0201272:	16fd                	add	a3,a3,-1
ffffffffc0201274:	0656                	sll	a2,a2,0x15
ffffffffc0201276:	07e005b7          	lui	a1,0x7e00
ffffffffc020127a:	00001517          	auipc	a0,0x1
ffffffffc020127e:	10e50513          	add	a0,a0,270 # ffffffffc0202388 <etext+0xa5a>
ffffffffc0201282:	e31fe0ef          	jal	ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201286:	777d                	lui	a4,0xfffff
ffffffffc0201288:	00006797          	auipc	a5,0x6
ffffffffc020128c:	1e778793          	add	a5,a5,487 # ffffffffc020746f <end+0xfff>
ffffffffc0201290:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201292:	00005517          	auipc	a0,0x5
ffffffffc0201296:	1c650513          	add	a0,a0,454 # ffffffffc0206458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020129a:	00005597          	auipc	a1,0x5
ffffffffc020129e:	1c658593          	add	a1,a1,454 # ffffffffc0206460 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02012a2:	00088737          	lui	a4,0x88
ffffffffc02012a6:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02012a8:	e19c                	sd	a5,0(a1)
ffffffffc02012aa:	4705                	li	a4,1
ffffffffc02012ac:	07a1                	add	a5,a5,8
ffffffffc02012ae:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02012b2:	02800693          	li	a3,40
ffffffffc02012b6:	4885                	li	a7,1
ffffffffc02012b8:	fff80837          	lui	a6,0xfff80
        SetPageReserved(pages + i);
ffffffffc02012bc:	619c                	ld	a5,0(a1)
ffffffffc02012be:	97b6                	add	a5,a5,a3
ffffffffc02012c0:	07a1                	add	a5,a5,8
ffffffffc02012c2:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02012c6:	611c                	ld	a5,0(a0)
ffffffffc02012c8:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc02012ca:	02868693          	add	a3,a3,40
ffffffffc02012ce:	01078633          	add	a2,a5,a6
ffffffffc02012d2:	fec765e3          	bltu	a4,a2,ffffffffc02012bc <pmm_init+0x9a>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02012d6:	6190                	ld	a2,0(a1)
ffffffffc02012d8:	00279693          	sll	a3,a5,0x2
ffffffffc02012dc:	96be                	add	a3,a3,a5
ffffffffc02012de:	fec00737          	lui	a4,0xfec00
ffffffffc02012e2:	9732                	add	a4,a4,a2
ffffffffc02012e4:	068e                	sll	a3,a3,0x3
ffffffffc02012e6:	96ba                	add	a3,a3,a4
ffffffffc02012e8:	c0200737          	lui	a4,0xc0200
ffffffffc02012ec:	0ae6e463          	bltu	a3,a4,ffffffffc0201394 <pmm_init+0x172>
ffffffffc02012f0:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02012f2:	45c5                	li	a1,17
ffffffffc02012f4:	05ee                	sll	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02012f6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02012f8:	04b6e963          	bltu	a3,a1,ffffffffc020134a <pmm_init+0x128>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02012fc:	609c                	ld	a5,0(s1)
ffffffffc02012fe:	7b9c                	ld	a5,48(a5)
ffffffffc0201300:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201302:	00001517          	auipc	a0,0x1
ffffffffc0201306:	11e50513          	add	a0,a0,286 # ffffffffc0202420 <etext+0xaf2>
ffffffffc020130a:	da9fe0ef          	jal	ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020130e:	00004597          	auipc	a1,0x4
ffffffffc0201312:	cf258593          	add	a1,a1,-782 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201316:	00005797          	auipc	a5,0x5
ffffffffc020131a:	12b7b923          	sd	a1,306(a5) # ffffffffc0206448 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020131e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201322:	08f5e563          	bltu	a1,a5,ffffffffc02013ac <pmm_init+0x18a>
ffffffffc0201326:	601c                	ld	a5,0(s0)
}
ffffffffc0201328:	6442                	ld	s0,16(sp)
ffffffffc020132a:	60e2                	ld	ra,24(sp)
ffffffffc020132c:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020132e:	40f586b3          	sub	a3,a1,a5
ffffffffc0201332:	00005797          	auipc	a5,0x5
ffffffffc0201336:	10d7b723          	sd	a3,270(a5) # ffffffffc0206440 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020133a:	00001517          	auipc	a0,0x1
ffffffffc020133e:	10650513          	add	a0,a0,262 # ffffffffc0202440 <etext+0xb12>
ffffffffc0201342:	8636                	mv	a2,a3
}
ffffffffc0201344:	6105                	add	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201346:	d6dfe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020134a:	6705                	lui	a4,0x1
ffffffffc020134c:	177d                	add	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020134e:	96ba                	add	a3,a3,a4
ffffffffc0201350:	777d                	lui	a4,0xfffff
ffffffffc0201352:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201354:	00c6d713          	srl	a4,a3,0xc
ffffffffc0201358:	02f77263          	bgeu	a4,a5,ffffffffc020137c <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc020135c:	0004b803          	ld	a6,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201360:	fff807b7          	lui	a5,0xfff80
ffffffffc0201364:	97ba                	add	a5,a5,a4
ffffffffc0201366:	00279513          	sll	a0,a5,0x2
ffffffffc020136a:	953e                	add	a0,a0,a5
ffffffffc020136c:	01083783          	ld	a5,16(a6) # fffffffffff80010 <end+0x3fd79ba0>
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201370:	8d95                	sub	a1,a1,a3
ffffffffc0201372:	050e                	sll	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201374:	81b1                	srl	a1,a1,0xc
ffffffffc0201376:	9532                	add	a0,a0,a2
ffffffffc0201378:	9782                	jalr	a5
}
ffffffffc020137a:	b749                	j	ffffffffc02012fc <pmm_init+0xda>
        panic("pa2page called with invalid pa");
ffffffffc020137c:	00001617          	auipc	a2,0x1
ffffffffc0201380:	07460613          	add	a2,a2,116 # ffffffffc02023f0 <etext+0xac2>
ffffffffc0201384:	06b00593          	li	a1,107
ffffffffc0201388:	00001517          	auipc	a0,0x1
ffffffffc020138c:	08850513          	add	a0,a0,136 # ffffffffc0202410 <etext+0xae2>
ffffffffc0201390:	816ff0ef          	jal	ffffffffc02003a6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201394:	00001617          	auipc	a2,0x1
ffffffffc0201398:	02460613          	add	a2,a2,36 # ffffffffc02023b8 <etext+0xa8a>
ffffffffc020139c:	06e00593          	li	a1,110
ffffffffc02013a0:	00001517          	auipc	a0,0x1
ffffffffc02013a4:	04050513          	add	a0,a0,64 # ffffffffc02023e0 <etext+0xab2>
ffffffffc02013a8:	ffffe0ef          	jal	ffffffffc02003a6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02013ac:	86ae                	mv	a3,a1
ffffffffc02013ae:	00001617          	auipc	a2,0x1
ffffffffc02013b2:	00a60613          	add	a2,a2,10 # ffffffffc02023b8 <etext+0xa8a>
ffffffffc02013b6:	08900593          	li	a1,137
ffffffffc02013ba:	00001517          	auipc	a0,0x1
ffffffffc02013be:	02650513          	add	a0,a0,38 # ffffffffc02023e0 <etext+0xab2>
ffffffffc02013c2:	fe5fe0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc02013c6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02013c6:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013ca:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02013cc:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013d0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02013d2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02013d6:	f022                	sd	s0,32(sp)
ffffffffc02013d8:	ec26                	sd	s1,24(sp)
ffffffffc02013da:	e84a                	sd	s2,16(sp)
ffffffffc02013dc:	f406                	sd	ra,40(sp)
ffffffffc02013de:	84aa                	mv	s1,a0
ffffffffc02013e0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02013e2:	fff7041b          	addw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b8f>
    unsigned mod = do_div(result, base);
ffffffffc02013e6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02013e8:	05067063          	bgeu	a2,a6,ffffffffc0201428 <printnum+0x62>
ffffffffc02013ec:	e44e                	sd	s3,8(sp)
ffffffffc02013ee:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02013f0:	4785                	li	a5,1
ffffffffc02013f2:	00e7d763          	bge	a5,a4,ffffffffc0201400 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc02013f6:	85ca                	mv	a1,s2
ffffffffc02013f8:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02013fa:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02013fc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02013fe:	fc65                	bnez	s0,ffffffffc02013f6 <printnum+0x30>
ffffffffc0201400:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201402:	1a02                	sll	s4,s4,0x20
ffffffffc0201404:	020a5a13          	srl	s4,s4,0x20
ffffffffc0201408:	00001797          	auipc	a5,0x1
ffffffffc020140c:	07878793          	add	a5,a5,120 # ffffffffc0202480 <etext+0xb52>
ffffffffc0201410:	97d2                	add	a5,a5,s4
}
ffffffffc0201412:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201414:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201418:	70a2                	ld	ra,40(sp)
ffffffffc020141a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020141c:	85ca                	mv	a1,s2
ffffffffc020141e:	87a6                	mv	a5,s1
}
ffffffffc0201420:	6942                	ld	s2,16(sp)
ffffffffc0201422:	64e2                	ld	s1,24(sp)
ffffffffc0201424:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201426:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201428:	03065633          	divu	a2,a2,a6
ffffffffc020142c:	8722                	mv	a4,s0
ffffffffc020142e:	f99ff0ef          	jal	ffffffffc02013c6 <printnum>
ffffffffc0201432:	bfc1                	j	ffffffffc0201402 <printnum+0x3c>

ffffffffc0201434 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201434:	7119                	add	sp,sp,-128
ffffffffc0201436:	f4a6                	sd	s1,104(sp)
ffffffffc0201438:	f0ca                	sd	s2,96(sp)
ffffffffc020143a:	ecce                	sd	s3,88(sp)
ffffffffc020143c:	e8d2                	sd	s4,80(sp)
ffffffffc020143e:	e4d6                	sd	s5,72(sp)
ffffffffc0201440:	e0da                	sd	s6,64(sp)
ffffffffc0201442:	f862                	sd	s8,48(sp)
ffffffffc0201444:	fc86                	sd	ra,120(sp)
ffffffffc0201446:	f8a2                	sd	s0,112(sp)
ffffffffc0201448:	fc5e                	sd	s7,56(sp)
ffffffffc020144a:	f466                	sd	s9,40(sp)
ffffffffc020144c:	f06a                	sd	s10,32(sp)
ffffffffc020144e:	ec6e                	sd	s11,24(sp)
ffffffffc0201450:	892a                	mv	s2,a0
ffffffffc0201452:	84ae                	mv	s1,a1
ffffffffc0201454:	8c32                	mv	s8,a2
ffffffffc0201456:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201458:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145c:	05500b13          	li	s6,85
ffffffffc0201460:	00001a97          	auipc	s5,0x1
ffffffffc0201464:	188a8a93          	add	s5,s5,392 # ffffffffc02025e8 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201468:	000c4503          	lbu	a0,0(s8)
ffffffffc020146c:	001c0413          	add	s0,s8,1
ffffffffc0201470:	01350a63          	beq	a0,s3,ffffffffc0201484 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201474:	cd0d                	beqz	a0,ffffffffc02014ae <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201476:	85a6                	mv	a1,s1
ffffffffc0201478:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020147a:	00044503          	lbu	a0,0(s0)
ffffffffc020147e:	0405                	add	s0,s0,1
ffffffffc0201480:	ff351ae3          	bne	a0,s3,ffffffffc0201474 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201484:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201488:	4b81                	li	s7,0
ffffffffc020148a:	4601                	li	a2,0
        width = precision = -1;
ffffffffc020148c:	5d7d                	li	s10,-1
ffffffffc020148e:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201490:	00044683          	lbu	a3,0(s0)
ffffffffc0201494:	00140c13          	add	s8,s0,1
ffffffffc0201498:	fdd6859b          	addw	a1,a3,-35
ffffffffc020149c:	0ff5f593          	zext.b	a1,a1
ffffffffc02014a0:	02bb6663          	bltu	s6,a1,ffffffffc02014cc <vprintfmt+0x98>
ffffffffc02014a4:	058a                	sll	a1,a1,0x2
ffffffffc02014a6:	95d6                	add	a1,a1,s5
ffffffffc02014a8:	4198                	lw	a4,0(a1)
ffffffffc02014aa:	9756                	add	a4,a4,s5
ffffffffc02014ac:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02014ae:	70e6                	ld	ra,120(sp)
ffffffffc02014b0:	7446                	ld	s0,112(sp)
ffffffffc02014b2:	74a6                	ld	s1,104(sp)
ffffffffc02014b4:	7906                	ld	s2,96(sp)
ffffffffc02014b6:	69e6                	ld	s3,88(sp)
ffffffffc02014b8:	6a46                	ld	s4,80(sp)
ffffffffc02014ba:	6aa6                	ld	s5,72(sp)
ffffffffc02014bc:	6b06                	ld	s6,64(sp)
ffffffffc02014be:	7be2                	ld	s7,56(sp)
ffffffffc02014c0:	7c42                	ld	s8,48(sp)
ffffffffc02014c2:	7ca2                	ld	s9,40(sp)
ffffffffc02014c4:	7d02                	ld	s10,32(sp)
ffffffffc02014c6:	6de2                	ld	s11,24(sp)
ffffffffc02014c8:	6109                	add	sp,sp,128
ffffffffc02014ca:	8082                	ret
            putch('%', putdat);
ffffffffc02014cc:	85a6                	mv	a1,s1
ffffffffc02014ce:	02500513          	li	a0,37
ffffffffc02014d2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02014d4:	fff44703          	lbu	a4,-1(s0)
ffffffffc02014d8:	02500793          	li	a5,37
ffffffffc02014dc:	8c22                	mv	s8,s0
ffffffffc02014de:	f8f705e3          	beq	a4,a5,ffffffffc0201468 <vprintfmt+0x34>
ffffffffc02014e2:	02500713          	li	a4,37
ffffffffc02014e6:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02014ea:	1c7d                	add	s8,s8,-1
ffffffffc02014ec:	fee79de3          	bne	a5,a4,ffffffffc02014e6 <vprintfmt+0xb2>
ffffffffc02014f0:	bfa5                	j	ffffffffc0201468 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02014f2:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02014f6:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc02014f8:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02014fc:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc0201500:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201504:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201506:	02b76563          	bltu	a4,a1,ffffffffc0201530 <vprintfmt+0xfc>
ffffffffc020150a:	4525                	li	a0,9
                ch = *fmt;
ffffffffc020150c:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201510:	002d171b          	sllw	a4,s10,0x2
ffffffffc0201514:	01a7073b          	addw	a4,a4,s10
ffffffffc0201518:	0017171b          	sllw	a4,a4,0x1
ffffffffc020151c:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc020151e:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201522:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201524:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc0201528:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc020152c:	feb570e3          	bgeu	a0,a1,ffffffffc020150c <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201530:	f60cd0e3          	bgez	s9,ffffffffc0201490 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201534:	8cea                	mv	s9,s10
ffffffffc0201536:	5d7d                	li	s10,-1
ffffffffc0201538:	bfa1                	j	ffffffffc0201490 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020153a:	8db6                	mv	s11,a3
ffffffffc020153c:	8462                	mv	s0,s8
ffffffffc020153e:	bf89                	j	ffffffffc0201490 <vprintfmt+0x5c>
ffffffffc0201540:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201542:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201544:	b7b1                	j	ffffffffc0201490 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201546:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201548:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc020154c:	00c7c463          	blt	a5,a2,ffffffffc0201554 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201550:	1a060163          	beqz	a2,ffffffffc02016f2 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201554:	000a3603          	ld	a2,0(s4)
ffffffffc0201558:	46c1                	li	a3,16
ffffffffc020155a:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020155c:	000d879b          	sext.w	a5,s11
ffffffffc0201560:	8766                	mv	a4,s9
ffffffffc0201562:	85a6                	mv	a1,s1
ffffffffc0201564:	854a                	mv	a0,s2
ffffffffc0201566:	e61ff0ef          	jal	ffffffffc02013c6 <printnum>
            break;
ffffffffc020156a:	bdfd                	j	ffffffffc0201468 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020156c:	000a2503          	lw	a0,0(s4)
ffffffffc0201570:	85a6                	mv	a1,s1
ffffffffc0201572:	0a21                	add	s4,s4,8
ffffffffc0201574:	9902                	jalr	s2
            break;
ffffffffc0201576:	bdcd                	j	ffffffffc0201468 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201578:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020157a:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc020157e:	00c7c463          	blt	a5,a2,ffffffffc0201586 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201582:	16060363          	beqz	a2,ffffffffc02016e8 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201586:	000a3603          	ld	a2,0(s4)
ffffffffc020158a:	46a9                	li	a3,10
ffffffffc020158c:	8a3a                	mv	s4,a4
ffffffffc020158e:	b7f9                	j	ffffffffc020155c <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201590:	85a6                	mv	a1,s1
ffffffffc0201592:	03000513          	li	a0,48
ffffffffc0201596:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201598:	85a6                	mv	a1,s1
ffffffffc020159a:	07800513          	li	a0,120
ffffffffc020159e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015a0:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02015a4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02015a6:	0a21                	add	s4,s4,8
            goto number;
ffffffffc02015a8:	bf55                	j	ffffffffc020155c <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc02015aa:	85a6                	mv	a1,s1
ffffffffc02015ac:	02500513          	li	a0,37
ffffffffc02015b0:	9902                	jalr	s2
            break;
ffffffffc02015b2:	bd5d                	j	ffffffffc0201468 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02015b4:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015b8:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02015ba:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc02015bc:	bf95                	j	ffffffffc0201530 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc02015be:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02015c0:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc02015c4:	00c7c463          	blt	a5,a2,ffffffffc02015cc <vprintfmt+0x198>
    else if (lflag) {
ffffffffc02015c8:	10060b63          	beqz	a2,ffffffffc02016de <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc02015cc:	000a3603          	ld	a2,0(s4)
ffffffffc02015d0:	46a1                	li	a3,8
ffffffffc02015d2:	8a3a                	mv	s4,a4
ffffffffc02015d4:	b761                	j	ffffffffc020155c <vprintfmt+0x128>
            if (width < 0)
ffffffffc02015d6:	fffcc793          	not	a5,s9
ffffffffc02015da:	97fd                	sra	a5,a5,0x3f
ffffffffc02015dc:	00fcf7b3          	and	a5,s9,a5
ffffffffc02015e0:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015e4:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02015e6:	b56d                	j	ffffffffc0201490 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02015e8:	000a3403          	ld	s0,0(s4)
ffffffffc02015ec:	008a0793          	add	a5,s4,8
ffffffffc02015f0:	e43e                	sd	a5,8(sp)
ffffffffc02015f2:	12040063          	beqz	s0,ffffffffc0201712 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02015f6:	0d905963          	blez	s9,ffffffffc02016c8 <vprintfmt+0x294>
ffffffffc02015fa:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015fe:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0201602:	12fd9763          	bne	s11,a5,ffffffffc0201730 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201606:	00044783          	lbu	a5,0(s0)
ffffffffc020160a:	0007851b          	sext.w	a0,a5
ffffffffc020160e:	cb9d                	beqz	a5,ffffffffc0201644 <vprintfmt+0x210>
ffffffffc0201610:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201612:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201616:	000d4563          	bltz	s10,ffffffffc0201620 <vprintfmt+0x1ec>
ffffffffc020161a:	3d7d                	addw	s10,s10,-1
ffffffffc020161c:	028d0263          	beq	s10,s0,ffffffffc0201640 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201620:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201622:	0c0b8d63          	beqz	s7,ffffffffc02016fc <vprintfmt+0x2c8>
ffffffffc0201626:	3781                	addw	a5,a5,-32
ffffffffc0201628:	0cfdfa63          	bgeu	s11,a5,ffffffffc02016fc <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc020162c:	03f00513          	li	a0,63
ffffffffc0201630:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201632:	000a4783          	lbu	a5,0(s4)
ffffffffc0201636:	3cfd                	addw	s9,s9,-1
ffffffffc0201638:	0a05                	add	s4,s4,1
ffffffffc020163a:	0007851b          	sext.w	a0,a5
ffffffffc020163e:	ffe1                	bnez	a5,ffffffffc0201616 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201640:	01905963          	blez	s9,ffffffffc0201652 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201644:	85a6                	mv	a1,s1
ffffffffc0201646:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020164a:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc020164c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020164e:	fe0c9be3          	bnez	s9,ffffffffc0201644 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201652:	6a22                	ld	s4,8(sp)
ffffffffc0201654:	bd11                	j	ffffffffc0201468 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201656:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201658:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc020165c:	00c7c363          	blt	a5,a2,ffffffffc0201662 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201660:	ce25                	beqz	a2,ffffffffc02016d8 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201662:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201666:	08044d63          	bltz	s0,ffffffffc0201700 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020166a:	8622                	mv	a2,s0
ffffffffc020166c:	8a5e                	mv	s4,s7
ffffffffc020166e:	46a9                	li	a3,10
ffffffffc0201670:	b5f5                	j	ffffffffc020155c <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201672:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201676:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201678:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc020167c:	8fb9                	xor	a5,a5,a4
ffffffffc020167e:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201682:	02d64663          	blt	a2,a3,ffffffffc02016ae <vprintfmt+0x27a>
ffffffffc0201686:	00369713          	sll	a4,a3,0x3
ffffffffc020168a:	00001797          	auipc	a5,0x1
ffffffffc020168e:	0b678793          	add	a5,a5,182 # ffffffffc0202740 <error_string>
ffffffffc0201692:	97ba                	add	a5,a5,a4
ffffffffc0201694:	639c                	ld	a5,0(a5)
ffffffffc0201696:	cf81                	beqz	a5,ffffffffc02016ae <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201698:	86be                	mv	a3,a5
ffffffffc020169a:	00001617          	auipc	a2,0x1
ffffffffc020169e:	e1660613          	add	a2,a2,-490 # ffffffffc02024b0 <etext+0xb82>
ffffffffc02016a2:	85a6                	mv	a1,s1
ffffffffc02016a4:	854a                	mv	a0,s2
ffffffffc02016a6:	0e8000ef          	jal	ffffffffc020178e <printfmt>
            err = va_arg(ap, int);
ffffffffc02016aa:	0a21                	add	s4,s4,8
ffffffffc02016ac:	bb75                	j	ffffffffc0201468 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02016ae:	00001617          	auipc	a2,0x1
ffffffffc02016b2:	df260613          	add	a2,a2,-526 # ffffffffc02024a0 <etext+0xb72>
ffffffffc02016b6:	85a6                	mv	a1,s1
ffffffffc02016b8:	854a                	mv	a0,s2
ffffffffc02016ba:	0d4000ef          	jal	ffffffffc020178e <printfmt>
            err = va_arg(ap, int);
ffffffffc02016be:	0a21                	add	s4,s4,8
ffffffffc02016c0:	b365                	j	ffffffffc0201468 <vprintfmt+0x34>
            lflag ++;
ffffffffc02016c2:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016c4:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02016c6:	b3e9                	j	ffffffffc0201490 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02016c8:	00044783          	lbu	a5,0(s0)
ffffffffc02016cc:	0007851b          	sext.w	a0,a5
ffffffffc02016d0:	d3c9                	beqz	a5,ffffffffc0201652 <vprintfmt+0x21e>
ffffffffc02016d2:	00140a13          	add	s4,s0,1
ffffffffc02016d6:	bf2d                	j	ffffffffc0201610 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc02016d8:	000a2403          	lw	s0,0(s4)
ffffffffc02016dc:	b769                	j	ffffffffc0201666 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc02016de:	000a6603          	lwu	a2,0(s4)
ffffffffc02016e2:	46a1                	li	a3,8
ffffffffc02016e4:	8a3a                	mv	s4,a4
ffffffffc02016e6:	bd9d                	j	ffffffffc020155c <vprintfmt+0x128>
ffffffffc02016e8:	000a6603          	lwu	a2,0(s4)
ffffffffc02016ec:	46a9                	li	a3,10
ffffffffc02016ee:	8a3a                	mv	s4,a4
ffffffffc02016f0:	b5b5                	j	ffffffffc020155c <vprintfmt+0x128>
ffffffffc02016f2:	000a6603          	lwu	a2,0(s4)
ffffffffc02016f6:	46c1                	li	a3,16
ffffffffc02016f8:	8a3a                	mv	s4,a4
ffffffffc02016fa:	b58d                	j	ffffffffc020155c <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc02016fc:	9902                	jalr	s2
ffffffffc02016fe:	bf15                	j	ffffffffc0201632 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201700:	85a6                	mv	a1,s1
ffffffffc0201702:	02d00513          	li	a0,45
ffffffffc0201706:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201708:	40800633          	neg	a2,s0
ffffffffc020170c:	8a5e                	mv	s4,s7
ffffffffc020170e:	46a9                	li	a3,10
ffffffffc0201710:	b5b1                	j	ffffffffc020155c <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0201712:	01905663          	blez	s9,ffffffffc020171e <vprintfmt+0x2ea>
ffffffffc0201716:	02d00793          	li	a5,45
ffffffffc020171a:	04fd9263          	bne	s11,a5,ffffffffc020175e <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020171e:	02800793          	li	a5,40
ffffffffc0201722:	00001a17          	auipc	s4,0x1
ffffffffc0201726:	d77a0a13          	add	s4,s4,-649 # ffffffffc0202499 <etext+0xb6b>
ffffffffc020172a:	02800513          	li	a0,40
ffffffffc020172e:	b5cd                	j	ffffffffc0201610 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201730:	85ea                	mv	a1,s10
ffffffffc0201732:	8522                	mv	a0,s0
ffffffffc0201734:	17e000ef          	jal	ffffffffc02018b2 <strnlen>
ffffffffc0201738:	40ac8cbb          	subw	s9,s9,a0
ffffffffc020173c:	01905963          	blez	s9,ffffffffc020174e <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201740:	2d81                	sext.w	s11,s11
ffffffffc0201742:	85a6                	mv	a1,s1
ffffffffc0201744:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201746:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201748:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020174a:	fe0c9ce3          	bnez	s9,ffffffffc0201742 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020174e:	00044783          	lbu	a5,0(s0)
ffffffffc0201752:	0007851b          	sext.w	a0,a5
ffffffffc0201756:	ea079de3          	bnez	a5,ffffffffc0201610 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020175a:	6a22                	ld	s4,8(sp)
ffffffffc020175c:	b331                	j	ffffffffc0201468 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020175e:	85ea                	mv	a1,s10
ffffffffc0201760:	00001517          	auipc	a0,0x1
ffffffffc0201764:	d3850513          	add	a0,a0,-712 # ffffffffc0202498 <etext+0xb6a>
ffffffffc0201768:	14a000ef          	jal	ffffffffc02018b2 <strnlen>
ffffffffc020176c:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201770:	00001417          	auipc	s0,0x1
ffffffffc0201774:	d2840413          	add	s0,s0,-728 # ffffffffc0202498 <etext+0xb6a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201778:	00001a17          	auipc	s4,0x1
ffffffffc020177c:	d21a0a13          	add	s4,s4,-735 # ffffffffc0202499 <etext+0xb6b>
ffffffffc0201780:	02800793          	li	a5,40
ffffffffc0201784:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201788:	fb904ce3          	bgtz	s9,ffffffffc0201740 <vprintfmt+0x30c>
ffffffffc020178c:	b551                	j	ffffffffc0201610 <vprintfmt+0x1dc>

ffffffffc020178e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020178e:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201790:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201794:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201796:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201798:	ec06                	sd	ra,24(sp)
ffffffffc020179a:	f83a                	sd	a4,48(sp)
ffffffffc020179c:	fc3e                	sd	a5,56(sp)
ffffffffc020179e:	e0c2                	sd	a6,64(sp)
ffffffffc02017a0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02017a2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02017a4:	c91ff0ef          	jal	ffffffffc0201434 <vprintfmt>
}
ffffffffc02017a8:	60e2                	ld	ra,24(sp)
ffffffffc02017aa:	6161                	add	sp,sp,80
ffffffffc02017ac:	8082                	ret

ffffffffc02017ae <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02017ae:	715d                	add	sp,sp,-80
ffffffffc02017b0:	e486                	sd	ra,72(sp)
ffffffffc02017b2:	e0a2                	sd	s0,64(sp)
ffffffffc02017b4:	fc26                	sd	s1,56(sp)
ffffffffc02017b6:	f84a                	sd	s2,48(sp)
ffffffffc02017b8:	f44e                	sd	s3,40(sp)
ffffffffc02017ba:	f052                	sd	s4,32(sp)
ffffffffc02017bc:	ec56                	sd	s5,24(sp)
ffffffffc02017be:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc02017c0:	c901                	beqz	a0,ffffffffc02017d0 <readline+0x22>
ffffffffc02017c2:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02017c4:	00001517          	auipc	a0,0x1
ffffffffc02017c8:	cec50513          	add	a0,a0,-788 # ffffffffc02024b0 <etext+0xb82>
ffffffffc02017cc:	8e7fe0ef          	jal	ffffffffc02000b2 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02017d0:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02017d2:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc02017d4:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02017d6:	4a29                	li	s4,10
ffffffffc02017d8:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc02017da:	00005b17          	auipc	s6,0x5
ffffffffc02017de:	84eb0b13          	add	s6,s6,-1970 # ffffffffc0206028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02017e2:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02017e6:	951fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02017ea:	00054a63          	bltz	a0,ffffffffc02017fe <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02017ee:	00a4da63          	bge	s1,a0,ffffffffc0201802 <readline+0x54>
ffffffffc02017f2:	0289d263          	bge	s3,s0,ffffffffc0201816 <readline+0x68>
        c = getchar();
ffffffffc02017f6:	941fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc02017fa:	fe055ae3          	bgez	a0,ffffffffc02017ee <readline+0x40>
            return NULL;
ffffffffc02017fe:	4501                	li	a0,0
ffffffffc0201800:	a091                	j	ffffffffc0201844 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201802:	03251463          	bne	a0,s2,ffffffffc020182a <readline+0x7c>
ffffffffc0201806:	04804963          	bgtz	s0,ffffffffc0201858 <readline+0xaa>
        c = getchar();
ffffffffc020180a:	92dfe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc020180e:	fe0548e3          	bltz	a0,ffffffffc02017fe <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201812:	fea4d8e3          	bge	s1,a0,ffffffffc0201802 <readline+0x54>
            cputchar(c);
ffffffffc0201816:	e42a                	sd	a0,8(sp)
ffffffffc0201818:	8cffe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc020181c:	6522                	ld	a0,8(sp)
ffffffffc020181e:	008b07b3          	add	a5,s6,s0
ffffffffc0201822:	2405                	addw	s0,s0,1
ffffffffc0201824:	00a78023          	sb	a0,0(a5)
ffffffffc0201828:	bf7d                	j	ffffffffc02017e6 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020182a:	01450463          	beq	a0,s4,ffffffffc0201832 <readline+0x84>
ffffffffc020182e:	fb551ce3          	bne	a0,s5,ffffffffc02017e6 <readline+0x38>
            cputchar(c);
ffffffffc0201832:	8b5fe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc0201836:	00004517          	auipc	a0,0x4
ffffffffc020183a:	7f250513          	add	a0,a0,2034 # ffffffffc0206028 <buf>
ffffffffc020183e:	942a                	add	s0,s0,a0
ffffffffc0201840:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201844:	60a6                	ld	ra,72(sp)
ffffffffc0201846:	6406                	ld	s0,64(sp)
ffffffffc0201848:	74e2                	ld	s1,56(sp)
ffffffffc020184a:	7942                	ld	s2,48(sp)
ffffffffc020184c:	79a2                	ld	s3,40(sp)
ffffffffc020184e:	7a02                	ld	s4,32(sp)
ffffffffc0201850:	6ae2                	ld	s5,24(sp)
ffffffffc0201852:	6b42                	ld	s6,16(sp)
ffffffffc0201854:	6161                	add	sp,sp,80
ffffffffc0201856:	8082                	ret
            cputchar(c);
ffffffffc0201858:	4521                	li	a0,8
ffffffffc020185a:	88dfe0ef          	jal	ffffffffc02000e6 <cputchar>
            i --;
ffffffffc020185e:	347d                	addw	s0,s0,-1
ffffffffc0201860:	b759                	j	ffffffffc02017e6 <readline+0x38>

ffffffffc0201862 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201862:	4781                	li	a5,0
ffffffffc0201864:	00004717          	auipc	a4,0x4
ffffffffc0201868:	7a473703          	ld	a4,1956(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc020186c:	88ba                	mv	a7,a4
ffffffffc020186e:	852a                	mv	a0,a0
ffffffffc0201870:	85be                	mv	a1,a5
ffffffffc0201872:	863e                	mv	a2,a5
ffffffffc0201874:	00000073          	ecall
ffffffffc0201878:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020187a:	8082                	ret

ffffffffc020187c <sbi_set_timer>:
    __asm__ volatile (
ffffffffc020187c:	4781                	li	a5,0
ffffffffc020187e:	00005717          	auipc	a4,0x5
ffffffffc0201882:	bea73703          	ld	a4,-1046(a4) # ffffffffc0206468 <SBI_SET_TIMER>
ffffffffc0201886:	88ba                	mv	a7,a4
ffffffffc0201888:	852a                	mv	a0,a0
ffffffffc020188a:	85be                	mv	a1,a5
ffffffffc020188c:	863e                	mv	a2,a5
ffffffffc020188e:	00000073          	ecall
ffffffffc0201892:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201894:	8082                	ret

ffffffffc0201896 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201896:	4501                	li	a0,0
ffffffffc0201898:	00004797          	auipc	a5,0x4
ffffffffc020189c:	7687b783          	ld	a5,1896(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc02018a0:	88be                	mv	a7,a5
ffffffffc02018a2:	852a                	mv	a0,a0
ffffffffc02018a4:	85aa                	mv	a1,a0
ffffffffc02018a6:	862a                	mv	a2,a0
ffffffffc02018a8:	00000073          	ecall
ffffffffc02018ac:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc02018ae:	2501                	sext.w	a0,a0
ffffffffc02018b0:	8082                	ret

ffffffffc02018b2 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02018b2:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02018b4:	e589                	bnez	a1,ffffffffc02018be <strnlen+0xc>
ffffffffc02018b6:	a811                	j	ffffffffc02018ca <strnlen+0x18>
        cnt ++;
ffffffffc02018b8:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02018ba:	00f58863          	beq	a1,a5,ffffffffc02018ca <strnlen+0x18>
ffffffffc02018be:	00f50733          	add	a4,a0,a5
ffffffffc02018c2:	00074703          	lbu	a4,0(a4)
ffffffffc02018c6:	fb6d                	bnez	a4,ffffffffc02018b8 <strnlen+0x6>
ffffffffc02018c8:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02018ca:	852e                	mv	a0,a1
ffffffffc02018cc:	8082                	ret

ffffffffc02018ce <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02018ce:	00054783          	lbu	a5,0(a0)
ffffffffc02018d2:	e791                	bnez	a5,ffffffffc02018de <strcmp+0x10>
ffffffffc02018d4:	a02d                	j	ffffffffc02018fe <strcmp+0x30>
ffffffffc02018d6:	00054783          	lbu	a5,0(a0)
ffffffffc02018da:	cf89                	beqz	a5,ffffffffc02018f4 <strcmp+0x26>
ffffffffc02018dc:	85b6                	mv	a1,a3
ffffffffc02018de:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02018e2:	0505                	add	a0,a0,1
ffffffffc02018e4:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02018e8:	fef707e3          	beq	a4,a5,ffffffffc02018d6 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02018ec:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02018f0:	9d19                	subw	a0,a0,a4
ffffffffc02018f2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02018f4:	0015c703          	lbu	a4,1(a1)
ffffffffc02018f8:	4501                	li	a0,0
}
ffffffffc02018fa:	9d19                	subw	a0,a0,a4
ffffffffc02018fc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02018fe:	0005c703          	lbu	a4,0(a1)
ffffffffc0201902:	4501                	li	a0,0
ffffffffc0201904:	b7f5                	j	ffffffffc02018f0 <strcmp+0x22>

ffffffffc0201906 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201906:	00054783          	lbu	a5,0(a0)
ffffffffc020190a:	c799                	beqz	a5,ffffffffc0201918 <strchr+0x12>
        if (*s == c) {
ffffffffc020190c:	00f58763          	beq	a1,a5,ffffffffc020191a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201910:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201914:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc0201916:	fbfd                	bnez	a5,ffffffffc020190c <strchr+0x6>
    }
    return NULL;
ffffffffc0201918:	4501                	li	a0,0
}
ffffffffc020191a:	8082                	ret

ffffffffc020191c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020191c:	ca01                	beqz	a2,ffffffffc020192c <memset+0x10>
ffffffffc020191e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201920:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201922:	0785                	add	a5,a5,1
ffffffffc0201924:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201928:	fef61de3          	bne	a2,a5,ffffffffc0201922 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020192c:	8082                	ret
