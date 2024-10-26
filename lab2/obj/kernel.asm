
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
ffffffffc0200036:	fde50513          	add	a0,a0,-34 # ffffffffc0206010 <buf>
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
ffffffffc020004a:	63c010ef          	jal	ffffffffc0201686 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3f8000ef          	jal	ffffffffc0200446 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	64650513          	add	a0,a0,1606 # ffffffffc0201698 <etext>
ffffffffc020005a:	08e000ef          	jal	ffffffffc02000e8 <cputs>

    print_kerninfo();
ffffffffc020005e:	0e8000ef          	jal	ffffffffc0200146 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	3fe000ef          	jal	ffffffffc0200460 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	727000ef          	jal	ffffffffc0200f8c <pmm_init>

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
ffffffffc02000a6:	0f8010ef          	jal	ffffffffc020119e <vprintfmt>
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
ffffffffc02000da:	0c4010ef          	jal	ffffffffc020119e <vprintfmt>
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
ffffffffc0200148:	00001517          	auipc	a0,0x1
ffffffffc020014c:	57050513          	add	a0,a0,1392 # ffffffffc02016b8 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200150:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200152:	f61ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200156:	00000597          	auipc	a1,0x0
ffffffffc020015a:	edc58593          	add	a1,a1,-292 # ffffffffc0200032 <kern_init>
ffffffffc020015e:	00001517          	auipc	a0,0x1
ffffffffc0200162:	57a50513          	add	a0,a0,1402 # ffffffffc02016d8 <etext+0x40>
ffffffffc0200166:	f4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020016a:	00001597          	auipc	a1,0x1
ffffffffc020016e:	52e58593          	add	a1,a1,1326 # ffffffffc0201698 <etext>
ffffffffc0200172:	00001517          	auipc	a0,0x1
ffffffffc0200176:	58650513          	add	a0,a0,1414 # ffffffffc02016f8 <etext+0x60>
ffffffffc020017a:	f39ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020017e:	00006597          	auipc	a1,0x6
ffffffffc0200182:	e9258593          	add	a1,a1,-366 # ffffffffc0206010 <buf>
ffffffffc0200186:	00001517          	auipc	a0,0x1
ffffffffc020018a:	59250513          	add	a0,a0,1426 # ffffffffc0201718 <etext+0x80>
ffffffffc020018e:	f25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200192:	00006597          	auipc	a1,0x6
ffffffffc0200196:	2de58593          	add	a1,a1,734 # ffffffffc0206470 <end>
ffffffffc020019a:	00001517          	auipc	a0,0x1
ffffffffc020019e:	59e50513          	add	a0,a0,1438 # ffffffffc0201738 <etext+0xa0>
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
ffffffffc02001c6:	00001517          	auipc	a0,0x1
ffffffffc02001ca:	59250513          	add	a0,a0,1426 # ffffffffc0201758 <etext+0xc0>
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
ffffffffc02001d4:	00001617          	auipc	a2,0x1
ffffffffc02001d8:	5b460613          	add	a2,a2,1460 # ffffffffc0201788 <etext+0xf0>
ffffffffc02001dc:	04e00593          	li	a1,78
ffffffffc02001e0:	00001517          	auipc	a0,0x1
ffffffffc02001e4:	5c050513          	add	a0,a0,1472 # ffffffffc02017a0 <etext+0x108>
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
ffffffffc02001f0:	00001617          	auipc	a2,0x1
ffffffffc02001f4:	5c860613          	add	a2,a2,1480 # ffffffffc02017b8 <etext+0x120>
ffffffffc02001f8:	00001597          	auipc	a1,0x1
ffffffffc02001fc:	5e058593          	add	a1,a1,1504 # ffffffffc02017d8 <etext+0x140>
ffffffffc0200200:	00001517          	auipc	a0,0x1
ffffffffc0200204:	5e050513          	add	a0,a0,1504 # ffffffffc02017e0 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	ea9ff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020020e:	00001617          	auipc	a2,0x1
ffffffffc0200212:	5e260613          	add	a2,a2,1506 # ffffffffc02017f0 <etext+0x158>
ffffffffc0200216:	00001597          	auipc	a1,0x1
ffffffffc020021a:	60258593          	add	a1,a1,1538 # ffffffffc0201818 <etext+0x180>
ffffffffc020021e:	00001517          	auipc	a0,0x1
ffffffffc0200222:	5c250513          	add	a0,a0,1474 # ffffffffc02017e0 <etext+0x148>
ffffffffc0200226:	e8dff0ef          	jal	ffffffffc02000b2 <cprintf>
ffffffffc020022a:	00001617          	auipc	a2,0x1
ffffffffc020022e:	5fe60613          	add	a2,a2,1534 # ffffffffc0201828 <etext+0x190>
ffffffffc0200232:	00001597          	auipc	a1,0x1
ffffffffc0200236:	61658593          	add	a1,a1,1558 # ffffffffc0201848 <etext+0x1b0>
ffffffffc020023a:	00001517          	auipc	a0,0x1
ffffffffc020023e:	5a650513          	add	a0,a0,1446 # ffffffffc02017e0 <etext+0x148>
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
ffffffffc0200274:	00001517          	auipc	a0,0x1
ffffffffc0200278:	5e450513          	add	a0,a0,1508 # ffffffffc0201858 <etext+0x1c0>
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
ffffffffc0200296:	00001517          	auipc	a0,0x1
ffffffffc020029a:	5ea50513          	add	a0,a0,1514 # ffffffffc0201880 <etext+0x1e8>
ffffffffc020029e:	e15ff0ef          	jal	ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002a2:	000b0563          	beqz	s6,ffffffffc02002ac <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a6:	855a                	mv	a0,s6
ffffffffc02002a8:	396000ef          	jal	ffffffffc020063e <print_trapframe>
ffffffffc02002ac:	00002c17          	auipc	s8,0x2
ffffffffc02002b0:	f04c0c13          	add	s8,s8,-252 # ffffffffc02021b0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b4:	00001917          	auipc	s2,0x1
ffffffffc02002b8:	5f490913          	add	s2,s2,1524 # ffffffffc02018a8 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002bc:	00001497          	auipc	s1,0x1
ffffffffc02002c0:	5f448493          	add	s1,s1,1524 # ffffffffc02018b0 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002c4:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c6:	00001a97          	auipc	s5,0x1
ffffffffc02002ca:	5f2a8a93          	add	s5,s5,1522 # ffffffffc02018b8 <etext+0x220>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002d0:	00001b97          	auipc	s7,0x1
ffffffffc02002d4:	608b8b93          	add	s7,s7,1544 # ffffffffc02018d8 <etext+0x240>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d8:	854a                	mv	a0,s2
ffffffffc02002da:	23e010ef          	jal	ffffffffc0201518 <readline>
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
ffffffffc02002f2:	ec2d0d13          	add	s10,s10,-318 # ffffffffc02021b0 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f6:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	000d3503          	ld	a0,0(s10)
ffffffffc02002fe:	33a010ef          	jal	ffffffffc0201638 <strcmp>
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
ffffffffc0200318:	358010ef          	jal	ffffffffc0201670 <strchr>
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
ffffffffc0200358:	318010ef          	jal	ffffffffc0201670 <strchr>
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
ffffffffc02003aa:	06a30313          	add	t1,t1,106 # ffffffffc0206410 <is_panic>
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
ffffffffc02003d8:	51c50513          	add	a0,a0,1308 # ffffffffc02018f0 <etext+0x258>
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
ffffffffc02003ee:	52650513          	add	a0,a0,1318 # ffffffffc0201910 <etext+0x278>
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
ffffffffc020041c:	1ca010ef          	jal	ffffffffc02015e6 <sbi_set_timer>
}
ffffffffc0200420:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200422:	00006797          	auipc	a5,0x6
ffffffffc0200426:	fe07bb23          	sd	zero,-10(a5) # ffffffffc0206418 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042a:	00001517          	auipc	a0,0x1
ffffffffc020042e:	4ee50513          	add	a0,a0,1262 # ffffffffc0201918 <etext+0x280>
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
ffffffffc0200442:	1a40106f          	j	ffffffffc02015e6 <sbi_set_timer>

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
ffffffffc020044c:	1800106f          	j	ffffffffc02015cc <sbi_console_putchar>

ffffffffc0200450 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200450:	1b00106f          	j	ffffffffc0201600 <sbi_console_getchar>

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
ffffffffc020047e:	4be50513          	add	a0,a0,1214 # ffffffffc0201938 <etext+0x2a0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200482:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	c2fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200488:	640c                	ld	a1,8(s0)
ffffffffc020048a:	00001517          	auipc	a0,0x1
ffffffffc020048e:	4c650513          	add	a0,a0,1222 # ffffffffc0201950 <etext+0x2b8>
ffffffffc0200492:	c21ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200496:	680c                	ld	a1,16(s0)
ffffffffc0200498:	00001517          	auipc	a0,0x1
ffffffffc020049c:	4d050513          	add	a0,a0,1232 # ffffffffc0201968 <etext+0x2d0>
ffffffffc02004a0:	c13ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a4:	6c0c                	ld	a1,24(s0)
ffffffffc02004a6:	00001517          	auipc	a0,0x1
ffffffffc02004aa:	4da50513          	add	a0,a0,1242 # ffffffffc0201980 <etext+0x2e8>
ffffffffc02004ae:	c05ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b2:	700c                	ld	a1,32(s0)
ffffffffc02004b4:	00001517          	auipc	a0,0x1
ffffffffc02004b8:	4e450513          	add	a0,a0,1252 # ffffffffc0201998 <etext+0x300>
ffffffffc02004bc:	bf7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c0:	740c                	ld	a1,40(s0)
ffffffffc02004c2:	00001517          	auipc	a0,0x1
ffffffffc02004c6:	4ee50513          	add	a0,a0,1262 # ffffffffc02019b0 <etext+0x318>
ffffffffc02004ca:	be9ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004ce:	780c                	ld	a1,48(s0)
ffffffffc02004d0:	00001517          	auipc	a0,0x1
ffffffffc02004d4:	4f850513          	add	a0,a0,1272 # ffffffffc02019c8 <etext+0x330>
ffffffffc02004d8:	bdbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004dc:	7c0c                	ld	a1,56(s0)
ffffffffc02004de:	00001517          	auipc	a0,0x1
ffffffffc02004e2:	50250513          	add	a0,a0,1282 # ffffffffc02019e0 <etext+0x348>
ffffffffc02004e6:	bcdff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ea:	602c                	ld	a1,64(s0)
ffffffffc02004ec:	00001517          	auipc	a0,0x1
ffffffffc02004f0:	50c50513          	add	a0,a0,1292 # ffffffffc02019f8 <etext+0x360>
ffffffffc02004f4:	bbfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004f8:	642c                	ld	a1,72(s0)
ffffffffc02004fa:	00001517          	auipc	a0,0x1
ffffffffc02004fe:	51650513          	add	a0,a0,1302 # ffffffffc0201a10 <etext+0x378>
ffffffffc0200502:	bb1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200506:	682c                	ld	a1,80(s0)
ffffffffc0200508:	00001517          	auipc	a0,0x1
ffffffffc020050c:	52050513          	add	a0,a0,1312 # ffffffffc0201a28 <etext+0x390>
ffffffffc0200510:	ba3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200514:	6c2c                	ld	a1,88(s0)
ffffffffc0200516:	00001517          	auipc	a0,0x1
ffffffffc020051a:	52a50513          	add	a0,a0,1322 # ffffffffc0201a40 <etext+0x3a8>
ffffffffc020051e:	b95ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200522:	702c                	ld	a1,96(s0)
ffffffffc0200524:	00001517          	auipc	a0,0x1
ffffffffc0200528:	53450513          	add	a0,a0,1332 # ffffffffc0201a58 <etext+0x3c0>
ffffffffc020052c:	b87ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200530:	742c                	ld	a1,104(s0)
ffffffffc0200532:	00001517          	auipc	a0,0x1
ffffffffc0200536:	53e50513          	add	a0,a0,1342 # ffffffffc0201a70 <etext+0x3d8>
ffffffffc020053a:	b79ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020053e:	782c                	ld	a1,112(s0)
ffffffffc0200540:	00001517          	auipc	a0,0x1
ffffffffc0200544:	54850513          	add	a0,a0,1352 # ffffffffc0201a88 <etext+0x3f0>
ffffffffc0200548:	b6bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020054c:	7c2c                	ld	a1,120(s0)
ffffffffc020054e:	00001517          	auipc	a0,0x1
ffffffffc0200552:	55250513          	add	a0,a0,1362 # ffffffffc0201aa0 <etext+0x408>
ffffffffc0200556:	b5dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055a:	604c                	ld	a1,128(s0)
ffffffffc020055c:	00001517          	auipc	a0,0x1
ffffffffc0200560:	55c50513          	add	a0,a0,1372 # ffffffffc0201ab8 <etext+0x420>
ffffffffc0200564:	b4fff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200568:	644c                	ld	a1,136(s0)
ffffffffc020056a:	00001517          	auipc	a0,0x1
ffffffffc020056e:	56650513          	add	a0,a0,1382 # ffffffffc0201ad0 <etext+0x438>
ffffffffc0200572:	b41ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200576:	684c                	ld	a1,144(s0)
ffffffffc0200578:	00001517          	auipc	a0,0x1
ffffffffc020057c:	57050513          	add	a0,a0,1392 # ffffffffc0201ae8 <etext+0x450>
ffffffffc0200580:	b33ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200584:	6c4c                	ld	a1,152(s0)
ffffffffc0200586:	00001517          	auipc	a0,0x1
ffffffffc020058a:	57a50513          	add	a0,a0,1402 # ffffffffc0201b00 <etext+0x468>
ffffffffc020058e:	b25ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200592:	704c                	ld	a1,160(s0)
ffffffffc0200594:	00001517          	auipc	a0,0x1
ffffffffc0200598:	58450513          	add	a0,a0,1412 # ffffffffc0201b18 <etext+0x480>
ffffffffc020059c:	b17ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a0:	744c                	ld	a1,168(s0)
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	58e50513          	add	a0,a0,1422 # ffffffffc0201b30 <etext+0x498>
ffffffffc02005aa:	b09ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005ae:	784c                	ld	a1,176(s0)
ffffffffc02005b0:	00001517          	auipc	a0,0x1
ffffffffc02005b4:	59850513          	add	a0,a0,1432 # ffffffffc0201b48 <etext+0x4b0>
ffffffffc02005b8:	afbff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005bc:	7c4c                	ld	a1,184(s0)
ffffffffc02005be:	00001517          	auipc	a0,0x1
ffffffffc02005c2:	5a250513          	add	a0,a0,1442 # ffffffffc0201b60 <etext+0x4c8>
ffffffffc02005c6:	aedff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ca:	606c                	ld	a1,192(s0)
ffffffffc02005cc:	00001517          	auipc	a0,0x1
ffffffffc02005d0:	5ac50513          	add	a0,a0,1452 # ffffffffc0201b78 <etext+0x4e0>
ffffffffc02005d4:	adfff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005d8:	646c                	ld	a1,200(s0)
ffffffffc02005da:	00001517          	auipc	a0,0x1
ffffffffc02005de:	5b650513          	add	a0,a0,1462 # ffffffffc0201b90 <etext+0x4f8>
ffffffffc02005e2:	ad1ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005e6:	686c                	ld	a1,208(s0)
ffffffffc02005e8:	00001517          	auipc	a0,0x1
ffffffffc02005ec:	5c050513          	add	a0,a0,1472 # ffffffffc0201ba8 <etext+0x510>
ffffffffc02005f0:	ac3ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f4:	6c6c                	ld	a1,216(s0)
ffffffffc02005f6:	00001517          	auipc	a0,0x1
ffffffffc02005fa:	5ca50513          	add	a0,a0,1482 # ffffffffc0201bc0 <etext+0x528>
ffffffffc02005fe:	ab5ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200602:	706c                	ld	a1,224(s0)
ffffffffc0200604:	00001517          	auipc	a0,0x1
ffffffffc0200608:	5d450513          	add	a0,a0,1492 # ffffffffc0201bd8 <etext+0x540>
ffffffffc020060c:	aa7ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200610:	746c                	ld	a1,232(s0)
ffffffffc0200612:	00001517          	auipc	a0,0x1
ffffffffc0200616:	5de50513          	add	a0,a0,1502 # ffffffffc0201bf0 <etext+0x558>
ffffffffc020061a:	a99ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020061e:	786c                	ld	a1,240(s0)
ffffffffc0200620:	00001517          	auipc	a0,0x1
ffffffffc0200624:	5e850513          	add	a0,a0,1512 # ffffffffc0201c08 <etext+0x570>
ffffffffc0200628:	a8bff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020062c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020062e:	6402                	ld	s0,0(sp)
ffffffffc0200630:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	00001517          	auipc	a0,0x1
ffffffffc0200636:	5ee50513          	add	a0,a0,1518 # ffffffffc0201c20 <etext+0x588>
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
ffffffffc0200646:	00001517          	auipc	a0,0x1
ffffffffc020064a:	5f250513          	add	a0,a0,1522 # ffffffffc0201c38 <etext+0x5a0>
void print_trapframe(struct trapframe *tf) {
ffffffffc020064e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200650:	a63ff0ef          	jal	ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200654:	8522                	mv	a0,s0
ffffffffc0200656:	e1dff0ef          	jal	ffffffffc0200472 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065a:	10043583          	ld	a1,256(s0)
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	5f250513          	add	a0,a0,1522 # ffffffffc0201c50 <etext+0x5b8>
ffffffffc0200666:	a4dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066a:	10843583          	ld	a1,264(s0)
ffffffffc020066e:	00001517          	auipc	a0,0x1
ffffffffc0200672:	5fa50513          	add	a0,a0,1530 # ffffffffc0201c68 <etext+0x5d0>
ffffffffc0200676:	a3dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067a:	11043583          	ld	a1,272(s0)
ffffffffc020067e:	00001517          	auipc	a0,0x1
ffffffffc0200682:	60250513          	add	a0,a0,1538 # ffffffffc0201c80 <etext+0x5e8>
ffffffffc0200686:	a2dff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068a:	11843583          	ld	a1,280(s0)
}
ffffffffc020068e:	6402                	ld	s0,0(sp)
ffffffffc0200690:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	00001517          	auipc	a0,0x1
ffffffffc0200696:	60650513          	add	a0,a0,1542 # ffffffffc0201c98 <etext+0x600>
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
ffffffffc02006b0:	b4c70713          	add	a4,a4,-1204 # ffffffffc02021f8 <commands+0x48>
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
ffffffffc02006be:	00001517          	auipc	a0,0x1
ffffffffc02006c2:	65250513          	add	a0,a0,1618 # ffffffffc0201d10 <etext+0x678>
ffffffffc02006c6:	b2f5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006c8:	00001517          	auipc	a0,0x1
ffffffffc02006cc:	62850513          	add	a0,a0,1576 # ffffffffc0201cf0 <etext+0x658>
ffffffffc02006d0:	b2cd                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d2:	00001517          	auipc	a0,0x1
ffffffffc02006d6:	5de50513          	add	a0,a0,1502 # ffffffffc0201cb0 <etext+0x618>
ffffffffc02006da:	bae1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006dc:	00001517          	auipc	a0,0x1
ffffffffc02006e0:	65450513          	add	a0,a0,1620 # ffffffffc0201d30 <etext+0x698>
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
ffffffffc02006f2:	d2a68693          	add	a3,a3,-726 # ffffffffc0206418 <ticks>
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
ffffffffc020070c:	00001517          	auipc	a0,0x1
ffffffffc0200710:	64c50513          	add	a0,a0,1612 # ffffffffc0201d58 <etext+0x6c0>
ffffffffc0200714:	ba79                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200716:	00001517          	auipc	a0,0x1
ffffffffc020071a:	5ba50513          	add	a0,a0,1466 # ffffffffc0201cd0 <etext+0x638>
ffffffffc020071e:	ba51                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200720:	bf39                	j	ffffffffc020063e <print_trapframe>
}
ffffffffc0200722:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200724:	06400593          	li	a1,100
ffffffffc0200728:	00001517          	auipc	a0,0x1
ffffffffc020072c:	62050513          	add	a0,a0,1568 # ffffffffc0201d48 <etext+0x6b0>
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

ffffffffc0200802 <buddy_init>:
static unsigned int buddy_page_num; //伙伴页数目
static unsigned int useable_page_num; //可用的页数目
static struct Page* useable_page_base;

static void
buddy_init(void) {}
ffffffffc0200802:	8082                	ret

ffffffffc0200804 <buddy_nr_free_pages>:
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_page[1];
ffffffffc0200804:	00006797          	auipc	a5,0x6
ffffffffc0200808:	c2c7b783          	ld	a5,-980(a5) # ffffffffc0206430 <buddy_page>
}
ffffffffc020080c:	0047e503          	lwu	a0,4(a5)
ffffffffc0200810:	8082                	ret

ffffffffc0200812 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc0200812:	c57d                	beqz	a0,ffffffffc0200900 <buddy_alloc_pages+0xee>
    if (n > buddy_page[1]){
ffffffffc0200814:	00006817          	auipc	a6,0x6
ffffffffc0200818:	c1c80813          	add	a6,a6,-996 # ffffffffc0206430 <buddy_page>
ffffffffc020081c:	00083583          	ld	a1,0(a6)
ffffffffc0200820:	0045e783          	lwu	a5,4(a1)
ffffffffc0200824:	0ca7ec63          	bltu	a5,a0,ffffffffc02008fc <buddy_alloc_pages+0xea>
    unsigned int index = 1;
ffffffffc0200828:	4685                	li	a3,1
        if (buddy_page[LEFT_CHILD(index)] >= n){
ffffffffc020082a:	0016971b          	sllw	a4,a3,0x1
ffffffffc020082e:	02071793          	sll	a5,a4,0x20
ffffffffc0200832:	83f9                	srl	a5,a5,0x1e
ffffffffc0200834:	97ae                	add	a5,a5,a1
ffffffffc0200836:	0007e783          	lwu	a5,0(a5)
ffffffffc020083a:	0006861b          	sext.w	a2,a3
ffffffffc020083e:	0007069b          	sext.w	a3,a4
ffffffffc0200842:	fea7f4e3          	bgeu	a5,a0,ffffffffc020082a <buddy_alloc_pages+0x18>
        else if (buddy_page[RIGHT_CHILD(index)] >= n){
ffffffffc0200846:	2705                	addw	a4,a4,1
ffffffffc0200848:	02071693          	sll	a3,a4,0x20
ffffffffc020084c:	01e6d793          	srl	a5,a3,0x1e
ffffffffc0200850:	97ae                	add	a5,a5,a1
ffffffffc0200852:	0007e783          	lwu	a5,0(a5)
ffffffffc0200856:	0007069b          	sext.w	a3,a4
ffffffffc020085a:	fca7f8e3          	bgeu	a5,a0,ffffffffc020082a <buddy_alloc_pages+0x18>
    unsigned int size = buddy_page[index]; //整个找到的页面一起分配出去
ffffffffc020085e:	02061713          	sll	a4,a2,0x20
ffffffffc0200862:	01e75793          	srl	a5,a4,0x1e
ffffffffc0200866:	95be                	add	a1,a1,a5
ffffffffc0200868:	4194                	lw	a3,0(a1)
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc020086a:	00006517          	auipc	a0,0x6
ffffffffc020086e:	bbe52503          	lw	a0,-1090(a0) # ffffffffc0206428 <useable_page_num>
    buddy_page[index] = 0; //清零计数，表示在管理页中该节点和其之下的所有结点都不能使用
ffffffffc0200872:	0005a023          	sw	zero,0(a1)
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200876:	02d607bb          	mulw	a5,a2,a3
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc020087a:	1682                	sll	a3,a3,0x20
ffffffffc020087c:	9281                	srl	a3,a3,0x20
ffffffffc020087e:	00269713          	sll	a4,a3,0x2
ffffffffc0200882:	9736                	add	a4,a4,a3
ffffffffc0200884:	070e                	sll	a4,a4,0x3
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200886:	9f89                	subw	a5,a5,a0
ffffffffc0200888:	1782                	sll	a5,a5,0x20
ffffffffc020088a:	9381                	srl	a5,a5,0x20
ffffffffc020088c:	00279693          	sll	a3,a5,0x2
ffffffffc0200890:	97b6                	add	a5,a5,a3
ffffffffc0200892:	078e                	sll	a5,a5,0x3
ffffffffc0200894:	00006517          	auipc	a0,0x6
ffffffffc0200898:	b8c53503          	ld	a0,-1140(a0) # ffffffffc0206420 <useable_page_base>
ffffffffc020089c:	953e                	add	a0,a0,a5
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc020089e:	972a                	add	a4,a4,a0
ffffffffc02008a0:	00e50e63          	beq	a0,a4,ffffffffc02008bc <buddy_alloc_pages+0xaa>
ffffffffc02008a4:	87aa                	mv	a5,a0
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008a6:	56f5                	li	a3,-3
ffffffffc02008a8:	00878593          	add	a1,a5,8
ffffffffc02008ac:	60d5b02f          	amoand.d	zero,a3,(a1)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008b0:	0007a023          	sw	zero,0(a5)
ffffffffc02008b4:	02878793          	add	a5,a5,40
ffffffffc02008b8:	fee798e3          	bne	a5,a4,ffffffffc02008a8 <buddy_alloc_pages+0x96>
    index = PARENT(index);
ffffffffc02008bc:	0016561b          	srlw	a2,a2,0x1
    while(index > 0){
ffffffffc02008c0:	ce1d                	beqz	a2,ffffffffc02008fe <buddy_alloc_pages+0xec>
        buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc02008c2:	00083683          	ld	a3,0(a6)
ffffffffc02008c6:	0016179b          	sllw	a5,a2,0x1
ffffffffc02008ca:	0017871b          	addw	a4,a5,1
ffffffffc02008ce:	1782                	sll	a5,a5,0x20
ffffffffc02008d0:	02071593          	sll	a1,a4,0x20
ffffffffc02008d4:	9381                	srl	a5,a5,0x20
ffffffffc02008d6:	01e5d713          	srl	a4,a1,0x1e
ffffffffc02008da:	078a                	sll	a5,a5,0x2
ffffffffc02008dc:	97b6                	add	a5,a5,a3
ffffffffc02008de:	9736                	add	a4,a4,a3
ffffffffc02008e0:	4318                	lw	a4,0(a4)
ffffffffc02008e2:	0007a803          	lw	a6,0(a5)
ffffffffc02008e6:	00261793          	sll	a5,a2,0x2
ffffffffc02008ea:	97b6                	add	a5,a5,a3
ffffffffc02008ec:	85ba                	mv	a1,a4
ffffffffc02008ee:	01077363          	bgeu	a4,a6,ffffffffc02008f4 <buddy_alloc_pages+0xe2>
ffffffffc02008f2:	85c2                	mv	a1,a6
ffffffffc02008f4:	c38c                	sw	a1,0(a5)
        index = PARENT(index);
ffffffffc02008f6:	8205                	srl	a2,a2,0x1
    while(index > 0){
ffffffffc02008f8:	f679                	bnez	a2,ffffffffc02008c6 <buddy_alloc_pages+0xb4>
ffffffffc02008fa:	8082                	ret
        return NULL;
ffffffffc02008fc:	4501                	li	a0,0
}
ffffffffc02008fe:	8082                	ret
Page* buddy_alloc_pages(size_t n) {
ffffffffc0200900:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc0200902:	00001697          	auipc	a3,0x1
ffffffffc0200906:	47668693          	add	a3,a3,1142 # ffffffffc0201d78 <etext+0x6e0>
ffffffffc020090a:	00001617          	auipc	a2,0x1
ffffffffc020090e:	47660613          	add	a2,a2,1142 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200912:	03800593          	li	a1,56
ffffffffc0200916:	00001517          	auipc	a0,0x1
ffffffffc020091a:	48250513          	add	a0,a0,1154 # ffffffffc0201d98 <etext+0x700>
Page* buddy_alloc_pages(size_t n) {
ffffffffc020091e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200920:	a87ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200924 <buddy_check>:

static void
buddy_check(void) {
ffffffffc0200924:	7139                	add	sp,sp,-64
ffffffffc0200926:	e852                	sd	s4,16(sp)
    return buddy_page[1];
ffffffffc0200928:	00006a17          	auipc	s4,0x6
ffffffffc020092c:	b08a0a13          	add	s4,s4,-1272 # ffffffffc0206430 <buddy_page>
ffffffffc0200930:	000a3783          	ld	a5,0(s4)
buddy_check(void) {
ffffffffc0200934:	ec4e                	sd	s3,24(sp)
ffffffffc0200936:	fc06                	sd	ra,56(sp)
    int all_pages = buddy_nr_free_pages();
ffffffffc0200938:	0047a983          	lw	s3,4(a5)
buddy_check(void) {
ffffffffc020093c:	f822                	sd	s0,48(sp)
ffffffffc020093e:	f426                	sd	s1,40(sp)
    struct Page* p0, *p1, *p2, *p3;
    // 分配过大的页数
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200940:	0019851b          	addw	a0,s3,1
buddy_check(void) {
ffffffffc0200944:	f04a                	sd	s2,32(sp)
ffffffffc0200946:	e456                	sd	s5,8(sp)
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200948:	5c6000ef          	jal	ffffffffc0200f0e <alloc_pages>
ffffffffc020094c:	26051463          	bnez	a0,ffffffffc0200bb4 <buddy_check+0x290>
    // 分配两个组页
    p0 = alloc_pages(1);
ffffffffc0200950:	4505                	li	a0,1
ffffffffc0200952:	5bc000ef          	jal	ffffffffc0200f0e <alloc_pages>
ffffffffc0200956:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200958:	22050e63          	beqz	a0,ffffffffc0200b94 <buddy_check+0x270>
    p1 = alloc_pages(2);
ffffffffc020095c:	4509                	li	a0,2
ffffffffc020095e:	5b0000ef          	jal	ffffffffc0200f0e <alloc_pages>
    assert(p1 == p0 + 2);
ffffffffc0200962:	05040793          	add	a5,s0,80
    p1 = alloc_pages(2);
ffffffffc0200966:	84aa                	mv	s1,a0
    assert(p1 == p0 + 2);
ffffffffc0200968:	1af51663          	bne	a0,a5,ffffffffc0200b14 <buddy_check+0x1f0>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020096c:	641c                	ld	a5,8(s0)
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc020096e:	8b85                	and	a5,a5,1
ffffffffc0200970:	12079263          	bnez	a5,ffffffffc0200a94 <buddy_check+0x170>
ffffffffc0200974:	641c                	ld	a5,8(s0)
ffffffffc0200976:	8385                	srl	a5,a5,0x1
ffffffffc0200978:	8b85                	and	a5,a5,1
ffffffffc020097a:	10079d63          	bnez	a5,ffffffffc0200a94 <buddy_check+0x170>
ffffffffc020097e:	651c                	ld	a5,8(a0)
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc0200980:	8b85                	and	a5,a5,1
ffffffffc0200982:	0e079963          	bnez	a5,ffffffffc0200a74 <buddy_check+0x150>
ffffffffc0200986:	651c                	ld	a5,8(a0)
ffffffffc0200988:	8385                	srl	a5,a5,0x1
ffffffffc020098a:	8b85                	and	a5,a5,1
ffffffffc020098c:	0e079463          	bnez	a5,ffffffffc0200a74 <buddy_check+0x150>
    // 再分配两个组页
    p2 = alloc_pages(1);
ffffffffc0200990:	4505                	li	a0,1
ffffffffc0200992:	57c000ef          	jal	ffffffffc0200f0e <alloc_pages>
    assert(p2 == p0 + 1);
ffffffffc0200996:	02840793          	add	a5,s0,40
    p2 = alloc_pages(1);
ffffffffc020099a:	8aaa                	mv	s5,a0
    assert(p2 == p0 + 1);
ffffffffc020099c:	12f51c63          	bne	a0,a5,ffffffffc0200ad4 <buddy_check+0x1b0>
    p3 = alloc_pages(8);
ffffffffc02009a0:	4521                	li	a0,8
ffffffffc02009a2:	56c000ef          	jal	ffffffffc0200f0e <alloc_pages>
    assert(p3 == p0 + 8);
ffffffffc02009a6:	14040793          	add	a5,s0,320
    p3 = alloc_pages(8);
ffffffffc02009aa:	892a                	mv	s2,a0
    assert(p3 == p0 + 8);
ffffffffc02009ac:	24f51463          	bne	a0,a5,ffffffffc0200bf4 <buddy_check+0x2d0>
ffffffffc02009b0:	651c                	ld	a5,8(a0)
ffffffffc02009b2:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc02009b4:	8b85                	and	a5,a5,1
ffffffffc02009b6:	efd9                	bnez	a5,ffffffffc0200a54 <buddy_check+0x130>
ffffffffc02009b8:	12053783          	ld	a5,288(a0)
ffffffffc02009bc:	8385                	srl	a5,a5,0x1
ffffffffc02009be:	8b85                	and	a5,a5,1
ffffffffc02009c0:	ebd1                	bnez	a5,ffffffffc0200a54 <buddy_check+0x130>
ffffffffc02009c2:	14853783          	ld	a5,328(a0)
ffffffffc02009c6:	8385                	srl	a5,a5,0x1
ffffffffc02009c8:	8b85                	and	a5,a5,1
ffffffffc02009ca:	c7c9                	beqz	a5,ffffffffc0200a54 <buddy_check+0x130>
    // 回收页
    free_pages(p1, 2);
ffffffffc02009cc:	4589                	li	a1,2
ffffffffc02009ce:	8526                	mv	a0,s1
ffffffffc02009d0:	57c000ef          	jal	ffffffffc0200f4c <free_pages>
ffffffffc02009d4:	649c                	ld	a5,8(s1)
ffffffffc02009d6:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc02009d8:	8b85                	and	a5,a5,1
ffffffffc02009da:	0c078d63          	beqz	a5,ffffffffc0200ab4 <buddy_check+0x190>
ffffffffc02009de:	789c                	ld	a5,48(s1)
ffffffffc02009e0:	8385                	srl	a5,a5,0x1
ffffffffc02009e2:	8b85                	and	a5,a5,1
ffffffffc02009e4:	cbe1                	beqz	a5,ffffffffc0200ab4 <buddy_check+0x190>
    assert(p1->ref == 0);
ffffffffc02009e6:	409c                	lw	a5,0(s1)
ffffffffc02009e8:	14079663          	bnez	a5,ffffffffc0200b34 <buddy_check+0x210>
    free_pages(p0, 1);
ffffffffc02009ec:	4585                	li	a1,1
ffffffffc02009ee:	8522                	mv	a0,s0
ffffffffc02009f0:	55c000ef          	jal	ffffffffc0200f4c <free_pages>
    free_pages(p2, 1);
ffffffffc02009f4:	8556                	mv	a0,s5
ffffffffc02009f6:	4585                	li	a1,1
ffffffffc02009f8:	554000ef          	jal	ffffffffc0200f4c <free_pages>
    // 回收后再分配
    p2 = alloc_pages(3);
ffffffffc02009fc:	450d                	li	a0,3
ffffffffc02009fe:	510000ef          	jal	ffffffffc0200f0e <alloc_pages>
    assert(p2 == p0);
ffffffffc0200a02:	16a41963          	bne	s0,a0,ffffffffc0200b74 <buddy_check+0x250>
    free_pages(p2, 3);
ffffffffc0200a06:	458d                	li	a1,3
ffffffffc0200a08:	544000ef          	jal	ffffffffc0200f4c <free_pages>
    assert((p2 + 2)->ref == 0);
ffffffffc0200a0c:	483c                	lw	a5,80(s0)
ffffffffc0200a0e:	14079363          	bnez	a5,ffffffffc0200b54 <buddy_check+0x230>
    return buddy_page[1];
ffffffffc0200a12:	000a3783          	ld	a5,0(s4)
    assert(buddy_nr_free_pages() == all_pages >> 1);
ffffffffc0200a16:	4019d993          	sra	s3,s3,0x1
    return buddy_page[1];
ffffffffc0200a1a:	0047e783          	lwu	a5,4(a5)
    assert(buddy_nr_free_pages() == all_pages >> 1);
ffffffffc0200a1e:	0cf99b63          	bne	s3,a5,ffffffffc0200af4 <buddy_check+0x1d0>

    p1 = alloc_pages(129);
ffffffffc0200a22:	08100513          	li	a0,129
ffffffffc0200a26:	4e8000ef          	jal	ffffffffc0200f0e <alloc_pages>
    assert(p1 == p0 + 256);
ffffffffc0200a2a:	678d                	lui	a5,0x3
ffffffffc0200a2c:	80078793          	add	a5,a5,-2048 # 2800 <kern_entry-0xffffffffc01fd800>
ffffffffc0200a30:	943e                	add	s0,s0,a5
ffffffffc0200a32:	1a851163          	bne	a0,s0,ffffffffc0200bd4 <buddy_check+0x2b0>
    free_pages(p1, 256);
ffffffffc0200a36:	10000593          	li	a1,256
ffffffffc0200a3a:	512000ef          	jal	ffffffffc0200f4c <free_pages>
    free_pages(p3, 8);
}
ffffffffc0200a3e:	7442                	ld	s0,48(sp)
ffffffffc0200a40:	70e2                	ld	ra,56(sp)
ffffffffc0200a42:	74a2                	ld	s1,40(sp)
ffffffffc0200a44:	69e2                	ld	s3,24(sp)
ffffffffc0200a46:	6a42                	ld	s4,16(sp)
ffffffffc0200a48:	6aa2                	ld	s5,8(sp)
    free_pages(p3, 8);
ffffffffc0200a4a:	854a                	mv	a0,s2
}
ffffffffc0200a4c:	7902                	ld	s2,32(sp)
    free_pages(p3, 8);
ffffffffc0200a4e:	45a1                	li	a1,8
}
ffffffffc0200a50:	6121                	add	sp,sp,64
    free_pages(p3, 8);
ffffffffc0200a52:	a9ed                	j	ffffffffc0200f4c <free_pages>
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc0200a54:	00001697          	auipc	a3,0x1
ffffffffc0200a58:	41c68693          	add	a3,a3,1052 # ffffffffc0201e70 <etext+0x7d8>
ffffffffc0200a5c:	00001617          	auipc	a2,0x1
ffffffffc0200a60:	32460613          	add	a2,a2,804 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200a64:	09200593          	li	a1,146
ffffffffc0200a68:	00001517          	auipc	a0,0x1
ffffffffc0200a6c:	33050513          	add	a0,a0,816 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200a70:	937ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc0200a74:	00001697          	auipc	a3,0x1
ffffffffc0200a78:	3b468693          	add	a3,a3,948 # ffffffffc0201e28 <etext+0x790>
ffffffffc0200a7c:	00001617          	auipc	a2,0x1
ffffffffc0200a80:	30460613          	add	a2,a2,772 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200a84:	08c00593          	li	a1,140
ffffffffc0200a88:	00001517          	auipc	a0,0x1
ffffffffc0200a8c:	31050513          	add	a0,a0,784 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200a90:	917ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc0200a94:	00001697          	auipc	a3,0x1
ffffffffc0200a98:	36c68693          	add	a3,a3,876 # ffffffffc0201e00 <etext+0x768>
ffffffffc0200a9c:	00001617          	auipc	a2,0x1
ffffffffc0200aa0:	2e460613          	add	a2,a2,740 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200aa4:	08b00593          	li	a1,139
ffffffffc0200aa8:	00001517          	auipc	a0,0x1
ffffffffc0200aac:	2f050513          	add	a0,a0,752 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200ab0:	8f7ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc0200ab4:	00001697          	auipc	a3,0x1
ffffffffc0200ab8:	40468693          	add	a3,a3,1028 # ffffffffc0201eb8 <etext+0x820>
ffffffffc0200abc:	00001617          	auipc	a2,0x1
ffffffffc0200ac0:	2c460613          	add	a2,a2,708 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200ac4:	09500593          	li	a1,149
ffffffffc0200ac8:	00001517          	auipc	a0,0x1
ffffffffc0200acc:	2d050513          	add	a0,a0,720 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200ad0:	8d7ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p2 == p0 + 1);
ffffffffc0200ad4:	00001697          	auipc	a3,0x1
ffffffffc0200ad8:	37c68693          	add	a3,a3,892 # ffffffffc0201e50 <etext+0x7b8>
ffffffffc0200adc:	00001617          	auipc	a2,0x1
ffffffffc0200ae0:	2a460613          	add	a2,a2,676 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200ae4:	08f00593          	li	a1,143
ffffffffc0200ae8:	00001517          	auipc	a0,0x1
ffffffffc0200aec:	2b050513          	add	a0,a0,688 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200af0:	8b7ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(buddy_nr_free_pages() == all_pages >> 1);
ffffffffc0200af4:	00001697          	auipc	a3,0x1
ffffffffc0200af8:	42c68693          	add	a3,a3,1068 # ffffffffc0201f20 <etext+0x888>
ffffffffc0200afc:	00001617          	auipc	a2,0x1
ffffffffc0200b00:	28460613          	add	a2,a2,644 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200b04:	09e00593          	li	a1,158
ffffffffc0200b08:	00001517          	auipc	a0,0x1
ffffffffc0200b0c:	29050513          	add	a0,a0,656 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200b10:	897ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p1 == p0 + 2);
ffffffffc0200b14:	00001697          	auipc	a3,0x1
ffffffffc0200b18:	2dc68693          	add	a3,a3,732 # ffffffffc0201df0 <etext+0x758>
ffffffffc0200b1c:	00001617          	auipc	a2,0x1
ffffffffc0200b20:	26460613          	add	a2,a2,612 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200b24:	08a00593          	li	a1,138
ffffffffc0200b28:	00001517          	auipc	a0,0x1
ffffffffc0200b2c:	27050513          	add	a0,a0,624 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200b30:	877ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p1->ref == 0);
ffffffffc0200b34:	00001697          	auipc	a3,0x1
ffffffffc0200b38:	3b468693          	add	a3,a3,948 # ffffffffc0201ee8 <etext+0x850>
ffffffffc0200b3c:	00001617          	auipc	a2,0x1
ffffffffc0200b40:	24460613          	add	a2,a2,580 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200b44:	09600593          	li	a1,150
ffffffffc0200b48:	00001517          	auipc	a0,0x1
ffffffffc0200b4c:	25050513          	add	a0,a0,592 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200b50:	857ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((p2 + 2)->ref == 0);
ffffffffc0200b54:	00001697          	auipc	a3,0x1
ffffffffc0200b58:	3b468693          	add	a3,a3,948 # ffffffffc0201f08 <etext+0x870>
ffffffffc0200b5c:	00001617          	auipc	a2,0x1
ffffffffc0200b60:	22460613          	add	a2,a2,548 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200b64:	09d00593          	li	a1,157
ffffffffc0200b68:	00001517          	auipc	a0,0x1
ffffffffc0200b6c:	23050513          	add	a0,a0,560 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200b70:	837ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p2 == p0);
ffffffffc0200b74:	00001697          	auipc	a3,0x1
ffffffffc0200b78:	38468693          	add	a3,a3,900 # ffffffffc0201ef8 <etext+0x860>
ffffffffc0200b7c:	00001617          	auipc	a2,0x1
ffffffffc0200b80:	20460613          	add	a2,a2,516 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200b84:	09b00593          	li	a1,155
ffffffffc0200b88:	00001517          	auipc	a0,0x1
ffffffffc0200b8c:	21050513          	add	a0,a0,528 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200b90:	817ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p0 != NULL);
ffffffffc0200b94:	00001697          	auipc	a3,0x1
ffffffffc0200b98:	24c68693          	add	a3,a3,588 # ffffffffc0201de0 <etext+0x748>
ffffffffc0200b9c:	00001617          	auipc	a2,0x1
ffffffffc0200ba0:	1e460613          	add	a2,a2,484 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200ba4:	08800593          	li	a1,136
ffffffffc0200ba8:	00001517          	auipc	a0,0x1
ffffffffc0200bac:	1f050513          	add	a0,a0,496 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200bb0:	ff6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200bb4:	00001697          	auipc	a3,0x1
ffffffffc0200bb8:	20468693          	add	a3,a3,516 # ffffffffc0201db8 <etext+0x720>
ffffffffc0200bbc:	00001617          	auipc	a2,0x1
ffffffffc0200bc0:	1c460613          	add	a2,a2,452 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200bc4:	08500593          	li	a1,133
ffffffffc0200bc8:	00001517          	auipc	a0,0x1
ffffffffc0200bcc:	1d050513          	add	a0,a0,464 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200bd0:	fd6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p1 == p0 + 256);
ffffffffc0200bd4:	00001697          	auipc	a3,0x1
ffffffffc0200bd8:	37468693          	add	a3,a3,884 # ffffffffc0201f48 <etext+0x8b0>
ffffffffc0200bdc:	00001617          	auipc	a2,0x1
ffffffffc0200be0:	1a460613          	add	a2,a2,420 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200be4:	0a100593          	li	a1,161
ffffffffc0200be8:	00001517          	auipc	a0,0x1
ffffffffc0200bec:	1b050513          	add	a0,a0,432 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200bf0:	fb6ff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(p3 == p0 + 8);
ffffffffc0200bf4:	00001697          	auipc	a3,0x1
ffffffffc0200bf8:	26c68693          	add	a3,a3,620 # ffffffffc0201e60 <etext+0x7c8>
ffffffffc0200bfc:	00001617          	auipc	a2,0x1
ffffffffc0200c00:	18460613          	add	a2,a2,388 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200c04:	09100593          	li	a1,145
ffffffffc0200c08:	00001517          	auipc	a0,0x1
ffffffffc0200c0c:	19050513          	add	a0,a0,400 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200c10:	f96ff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200c14 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200c14:	1141                	add	sp,sp,-16
ffffffffc0200c16:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c18:	10058a63          	beqz	a1,ffffffffc0200d2c <buddy_free_pages+0x118>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c1c:	00259713          	sll	a4,a1,0x2
ffffffffc0200c20:	972e                	add	a4,a4,a1
ffffffffc0200c22:	070e                	sll	a4,a4,0x3
ffffffffc0200c24:	00e50633          	add	a2,a0,a4
ffffffffc0200c28:	87aa                	mv	a5,a0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c2a:	4689                	li	a3,2
ffffffffc0200c2c:	c30d                	beqz	a4,ffffffffc0200c4e <buddy_free_pages+0x3a>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c2e:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200c30:	8b05                	and	a4,a4,1
ffffffffc0200c32:	ef69                	bnez	a4,ffffffffc0200d0c <buddy_free_pages+0xf8>
ffffffffc0200c34:	6798                	ld	a4,8(a5)
ffffffffc0200c36:	8b09                	and	a4,a4,2
ffffffffc0200c38:	eb71                	bnez	a4,ffffffffc0200d0c <buddy_free_pages+0xf8>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c3a:	00878713          	add	a4,a5,8
ffffffffc0200c3e:	40d7302f          	amoor.d	zero,a3,(a4)
ffffffffc0200c42:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c46:	02878793          	add	a5,a5,40
ffffffffc0200c4a:	fec792e3          	bne	a5,a2,ffffffffc0200c2e <buddy_free_pages+0x1a>
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200c4e:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200c52:	ccd78793          	add	a5,a5,-819 # fffffffffccccccd <end+0x3cac685d>
ffffffffc0200c56:	07b2                	sll	a5,a5,0xc
ffffffffc0200c58:	ccd78793          	add	a5,a5,-819
ffffffffc0200c5c:	07b2                	sll	a5,a5,0xc
ffffffffc0200c5e:	00005717          	auipc	a4,0x5
ffffffffc0200c62:	7c273703          	ld	a4,1986(a4) # ffffffffc0206420 <useable_page_base>
ffffffffc0200c66:	ccd78793          	add	a5,a5,-819
ffffffffc0200c6a:	40e506b3          	sub	a3,a0,a4
ffffffffc0200c6e:	07b2                	sll	a5,a5,0xc
ffffffffc0200c70:	ccd78793          	add	a5,a5,-819
ffffffffc0200c74:	868d                	sra	a3,a3,0x3
ffffffffc0200c76:	02f686b3          	mul	a3,a3,a5
ffffffffc0200c7a:	00005797          	auipc	a5,0x5
ffffffffc0200c7e:	7ae7a783          	lw	a5,1966(a5) # ffffffffc0206428 <useable_page_num>
    while(buddy_page[index] > 0){
ffffffffc0200c82:	00005817          	auipc	a6,0x5
ffffffffc0200c86:	7ae83803          	ld	a6,1966(a6) # ffffffffc0206430 <buddy_page>
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200c8a:	4705                	li	a4,1
ffffffffc0200c8c:	9fb5                	addw	a5,a5,a3
    while(buddy_page[index] > 0){
ffffffffc0200c8e:	02079613          	sll	a2,a5,0x20
ffffffffc0200c92:	01e65693          	srl	a3,a2,0x1e
ffffffffc0200c96:	96c2                	add	a3,a3,a6
ffffffffc0200c98:	4290                	lw	a2,0(a3)
ffffffffc0200c9a:	ca19                	beqz	a2,ffffffffc0200cb0 <buddy_free_pages+0x9c>
        index=PARENT(index);
ffffffffc0200c9c:	0017d79b          	srlw	a5,a5,0x1
    while(buddy_page[index] > 0){
ffffffffc0200ca0:	02079693          	sll	a3,a5,0x20
ffffffffc0200ca4:	82f9                	srl	a3,a3,0x1e
ffffffffc0200ca6:	96c2                	add	a3,a3,a6
ffffffffc0200ca8:	4290                	lw	a2,0(a3)
        size <<= 1;
ffffffffc0200caa:	0017171b          	sllw	a4,a4,0x1
    while(buddy_page[index] > 0){
ffffffffc0200cae:	f67d                	bnez	a2,ffffffffc0200c9c <buddy_free_pages+0x88>
    buddy_page[index] = size;
ffffffffc0200cb0:	c298                	sw	a4,0(a3)
    while((index = PARENT(index)) > 0){
ffffffffc0200cb2:	0017d61b          	srlw	a2,a5,0x1
ffffffffc0200cb6:	e219                	bnez	a2,ffffffffc0200cbc <buddy_free_pages+0xa8>
ffffffffc0200cb8:	a0b9                	j	ffffffffc0200d06 <buddy_free_pages+0xf2>
ffffffffc0200cba:	8636                	mv	a2,a3
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cbc:	9bf9                	and	a5,a5,-2
ffffffffc0200cbe:	02079693          	sll	a3,a5,0x20
ffffffffc0200cc2:	2785                	addw	a5,a5,1
ffffffffc0200cc4:	02079593          	sll	a1,a5,0x20
ffffffffc0200cc8:	9281                	srl	a3,a3,0x20
ffffffffc0200cca:	01e5d793          	srl	a5,a1,0x1e
ffffffffc0200cce:	068a                	sll	a3,a3,0x2
ffffffffc0200cd0:	96c2                	add	a3,a3,a6
ffffffffc0200cd2:	97c2                	add	a5,a5,a6
ffffffffc0200cd4:	4288                	lw	a0,0(a3)
ffffffffc0200cd6:	438c                	lw	a1,0(a5)
            buddy_page[index] = size;
ffffffffc0200cd8:	02061793          	sll	a5,a2,0x20
ffffffffc0200cdc:	01e7d693          	srl	a3,a5,0x1e
        size <<= 1;
ffffffffc0200ce0:	0017171b          	sllw	a4,a4,0x1
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200ce4:	00a587bb          	addw	a5,a1,a0
            buddy_page[index] = size;
ffffffffc0200ce8:	96c2                	add	a3,a3,a6
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cea:	00e78863          	beq	a5,a4,ffffffffc0200cfa <buddy_free_pages+0xe6>
            buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc0200cee:	0005879b          	sext.w	a5,a1
ffffffffc0200cf2:	00a5f463          	bgeu	a1,a0,ffffffffc0200cfa <buddy_free_pages+0xe6>
ffffffffc0200cf6:	0005079b          	sext.w	a5,a0
ffffffffc0200cfa:	c29c                	sw	a5,0(a3)
    while((index = PARENT(index)) > 0){
ffffffffc0200cfc:	0016569b          	srlw	a3,a2,0x1
ffffffffc0200d00:	0006079b          	sext.w	a5,a2
ffffffffc0200d04:	fadd                	bnez	a3,ffffffffc0200cba <buddy_free_pages+0xa6>
}
ffffffffc0200d06:	60a2                	ld	ra,8(sp)
ffffffffc0200d08:	0141                	add	sp,sp,16
ffffffffc0200d0a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d0c:	00001697          	auipc	a3,0x1
ffffffffc0200d10:	24c68693          	add	a3,a3,588 # ffffffffc0201f58 <etext+0x8c0>
ffffffffc0200d14:	00001617          	auipc	a2,0x1
ffffffffc0200d18:	06c60613          	add	a2,a2,108 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200d1c:	06500593          	li	a1,101
ffffffffc0200d20:	00001517          	auipc	a0,0x1
ffffffffc0200d24:	07850513          	add	a0,a0,120 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200d28:	e7eff0ef          	jal	ffffffffc02003a6 <__panic>
    assert(n > 0);
ffffffffc0200d2c:	00001697          	auipc	a3,0x1
ffffffffc0200d30:	04c68693          	add	a3,a3,76 # ffffffffc0201d78 <etext+0x6e0>
ffffffffc0200d34:	00001617          	auipc	a2,0x1
ffffffffc0200d38:	04c60613          	add	a2,a2,76 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200d3c:	06200593          	li	a1,98
ffffffffc0200d40:	00001517          	auipc	a0,0x1
ffffffffc0200d44:	05850513          	add	a0,a0,88 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200d48:	e5eff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200d4c <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200d4c:	1141                	add	sp,sp,-16
ffffffffc0200d4e:	e406                	sd	ra,8(sp)
    assert((n > 0));
ffffffffc0200d50:	1a058063          	beqz	a1,ffffffffc0200ef0 <buddy_init_memmap+0x1a4>
ffffffffc0200d54:	46f5                	li	a3,29
ffffffffc0200d56:	4801                	li	a6,0
ffffffffc0200d58:	4705                	li	a4,1
ffffffffc0200d5a:	a801                	j	ffffffffc0200d6a <buddy_init_memmap+0x1e>
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200d5c:	36fd                	addw	a3,a3,-1
         i++, useable_page_num <<= 1);
ffffffffc0200d5e:	0017161b          	sllw	a2,a4,0x1
ffffffffc0200d62:	4805                	li	a6,1
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200d64:	14068d63          	beqz	a3,ffffffffc0200ebe <buddy_init_memmap+0x172>
         i++, useable_page_num <<= 1);
ffffffffc0200d68:	8732                	mv	a4,a2
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200d6a:	0097579b          	srlw	a5,a4,0x9
ffffffffc0200d6e:	9fb9                	addw	a5,a5,a4
ffffffffc0200d70:	1782                	sll	a5,a5,0x20
ffffffffc0200d72:	9381                	srl	a5,a5,0x20
ffffffffc0200d74:	feb7e4e3          	bltu	a5,a1,ffffffffc0200d5c <buddy_init_memmap+0x10>
ffffffffc0200d78:	12080e63          	beqz	a6,ffffffffc0200eb4 <buddy_init_memmap+0x168>
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d7c:	00a7579b          	srlw	a5,a4,0xa
ffffffffc0200d80:	2785                	addw	a5,a5,1
    useable_page_base = base + buddy_page_num;
ffffffffc0200d82:	02079613          	sll	a2,a5,0x20
ffffffffc0200d86:	9201                	srl	a2,a2,0x20
ffffffffc0200d88:	00261693          	sll	a3,a2,0x2
ffffffffc0200d8c:	96b2                	add	a3,a3,a2
    useable_page_num >>= 1;
ffffffffc0200d8e:	0017571b          	srlw	a4,a4,0x1
    useable_page_base = base + buddy_page_num;
ffffffffc0200d92:	068e                	sll	a3,a3,0x3
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d94:	00005617          	auipc	a2,0x5
ffffffffc0200d98:	69860613          	add	a2,a2,1688 # ffffffffc020642c <buddy_page_num>
    useable_page_base = base + buddy_page_num;
ffffffffc0200d9c:	96aa                	add	a3,a3,a0
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d9e:	c21c                	sw	a5,0(a2)
    useable_page_num >>= 1;
ffffffffc0200da0:	00005897          	auipc	a7,0x5
ffffffffc0200da4:	68888893          	add	a7,a7,1672 # ffffffffc0206428 <useable_page_num>
    useable_page_base = base + buddy_page_num;
ffffffffc0200da8:	00005797          	auipc	a5,0x5
ffffffffc0200dac:	66d7bc23          	sd	a3,1656(a5) # ffffffffc0206420 <useable_page_base>
    useable_page_num >>= 1;
ffffffffc0200db0:	00e8a023          	sw	a4,0(a7)
    for (int i = 0; i != buddy_page_num; i++){
ffffffffc0200db4:	00850793          	add	a5,a0,8
ffffffffc0200db8:	4701                	li	a4,0
ffffffffc0200dba:	4805                	li	a6,1
ffffffffc0200dbc:	4107b02f          	amoor.d	zero,a6,(a5)
ffffffffc0200dc0:	4214                	lw	a3,0(a2)
ffffffffc0200dc2:	2705                	addw	a4,a4,1
ffffffffc0200dc4:	02878793          	add	a5,a5,40
ffffffffc0200dc8:	fee69ae3          	bne	a3,a4,ffffffffc0200dbc <buddy_init_memmap+0x70>
    for (int i = buddy_page_num; i != n; i++){
ffffffffc0200dcc:	1702                	sll	a4,a4,0x20
ffffffffc0200dce:	9301                	srl	a4,a4,0x20
ffffffffc0200dd0:	02e58563          	beq	a1,a4,ffffffffc0200dfa <buddy_init_memmap+0xae>
ffffffffc0200dd4:	00271793          	sll	a5,a4,0x2
ffffffffc0200dd8:	97ba                	add	a5,a5,a4
ffffffffc0200dda:	078e                	sll	a5,a5,0x3
ffffffffc0200ddc:	07a1                	add	a5,a5,8
ffffffffc0200dde:	97aa                	add	a5,a5,a0
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200de0:	5679                	li	a2,-2
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200de2:	4689                	li	a3,2
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200de4:	60c7b02f          	amoand.d	zero,a2,(a5)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200de8:	40d7b02f          	amoor.d	zero,a3,(a5)
ffffffffc0200dec:	fe07ac23          	sw	zero,-8(a5)
ffffffffc0200df0:	0705                	add	a4,a4,1
ffffffffc0200df2:	02878793          	add	a5,a5,40
ffffffffc0200df6:	fee597e3          	bne	a1,a4,ffffffffc0200de4 <buddy_init_memmap+0x98>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dfa:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200dfe:	ccd78793          	add	a5,a5,-819 # fffffffffccccccd <end+0x3cac685d>
ffffffffc0200e02:	07b2                	sll	a5,a5,0xc
ffffffffc0200e04:	ccd78793          	add	a5,a5,-819
ffffffffc0200e08:	07b2                	sll	a5,a5,0xc
ffffffffc0200e0a:	ccd78793          	add	a5,a5,-819
ffffffffc0200e0e:	00005697          	auipc	a3,0x5
ffffffffc0200e12:	6526b683          	ld	a3,1618(a3) # ffffffffc0206460 <pages>
ffffffffc0200e16:	40d506b3          	sub	a3,a0,a3
ffffffffc0200e1a:	07b2                	sll	a5,a5,0xc
ffffffffc0200e1c:	ccd78793          	add	a5,a5,-819
ffffffffc0200e20:	868d                	sra	a3,a3,0x3
ffffffffc0200e22:	02f686b3          	mul	a3,a3,a5
ffffffffc0200e26:	00001797          	auipc	a5,0x1
ffffffffc0200e2a:	5ca7b783          	ld	a5,1482(a5) # ffffffffc02023f0 <nbase>
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e2e:	00005717          	auipc	a4,0x5
ffffffffc0200e32:	62a73703          	ld	a4,1578(a4) # ffffffffc0206458 <npage>
ffffffffc0200e36:	96be                	add	a3,a3,a5
ffffffffc0200e38:	00c69793          	sll	a5,a3,0xc
ffffffffc0200e3c:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e3e:	06b2                	sll	a3,a3,0xc
ffffffffc0200e40:	08e7fc63          	bgeu	a5,a4,ffffffffc0200ed8 <buddy_init_memmap+0x18c>
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e44:	0008a783          	lw	a5,0(a7)
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e48:	00005717          	auipc	a4,0x5
ffffffffc0200e4c:	60873703          	ld	a4,1544(a4) # ffffffffc0206450 <va_pa_offset>
ffffffffc0200e50:	96ba                	add	a3,a3,a4
ffffffffc0200e52:	00005717          	auipc	a4,0x5
ffffffffc0200e56:	5cd73f23          	sd	a3,1502(a4) # ffffffffc0206430 <buddy_page>
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e5a:	0017959b          	sllw	a1,a5,0x1
ffffffffc0200e5e:	0007871b          	sext.w	a4,a5
ffffffffc0200e62:	02b7f063          	bgeu	a5,a1,ffffffffc0200e82 <buddy_init_memmap+0x136>
ffffffffc0200e66:	40f5863b          	subw	a2,a1,a5
ffffffffc0200e6a:	1602                	sll	a2,a2,0x20
ffffffffc0200e6c:	9201                	srl	a2,a2,0x20
ffffffffc0200e6e:	963a                	add	a2,a2,a4
ffffffffc0200e70:	060a                	sll	a2,a2,0x2
ffffffffc0200e72:	070a                	sll	a4,a4,0x2
ffffffffc0200e74:	9736                	add	a4,a4,a3
ffffffffc0200e76:	9636                	add	a2,a2,a3
        buddy_page[i] = 1;
ffffffffc0200e78:	4585                	li	a1,1
ffffffffc0200e7a:	c30c                	sw	a1,0(a4)
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e7c:	0711                	add	a4,a4,4
ffffffffc0200e7e:	fee61ee3          	bne	a2,a4,ffffffffc0200e7a <buddy_init_memmap+0x12e>
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200e82:	37fd                	addw	a5,a5,-1
ffffffffc0200e84:	0007871b          	sext.w	a4,a5
ffffffffc0200e88:	02e05363          	blez	a4,ffffffffc0200eae <buddy_init_memmap+0x162>
ffffffffc0200e8c:	02079713          	sll	a4,a5,0x20
ffffffffc0200e90:	01e75613          	srl	a2,a4,0x1e
ffffffffc0200e94:	0017979b          	sllw	a5,a5,0x1
ffffffffc0200e98:	9636                	add	a2,a2,a3
        buddy_page[i] = buddy_page[i << 1] << 1;
ffffffffc0200e9a:	00279713          	sll	a4,a5,0x2
ffffffffc0200e9e:	9736                	add	a4,a4,a3
ffffffffc0200ea0:	4318                	lw	a4,0(a4)
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200ea2:	1671                	add	a2,a2,-4
ffffffffc0200ea4:	37f9                	addw	a5,a5,-2
        buddy_page[i] = buddy_page[i << 1] << 1;
ffffffffc0200ea6:	0017171b          	sllw	a4,a4,0x1
ffffffffc0200eaa:	c258                	sw	a4,4(a2)
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200eac:	f7fd                	bnez	a5,ffffffffc0200e9a <buddy_init_memmap+0x14e>
}
ffffffffc0200eae:	60a2                	ld	ra,8(sp)
ffffffffc0200eb0:	0141                	add	sp,sp,16
ffffffffc0200eb2:	8082                	ret
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200eb4:	02800693          	li	a3,40
ffffffffc0200eb8:	4785                	li	a5,1
ffffffffc0200eba:	4701                	li	a4,0
ffffffffc0200ebc:	bde1                	j	ffffffffc0200d94 <buddy_init_memmap+0x48>
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200ebe:	00a6579b          	srlw	a5,a2,0xa
ffffffffc0200ec2:	2785                	addw	a5,a5,1
    useable_page_base = base + buddy_page_num;
ffffffffc0200ec4:	02079613          	sll	a2,a5,0x20
ffffffffc0200ec8:	9201                	srl	a2,a2,0x20
ffffffffc0200eca:	00261693          	sll	a3,a2,0x2
    useable_page_num >>= 1;
ffffffffc0200ece:	1706                	sll	a4,a4,0x21
    useable_page_base = base + buddy_page_num;
ffffffffc0200ed0:	96b2                	add	a3,a3,a2
    useable_page_num >>= 1;
ffffffffc0200ed2:	9305                	srl	a4,a4,0x21
    useable_page_base = base + buddy_page_num;
ffffffffc0200ed4:	068e                	sll	a3,a3,0x3
ffffffffc0200ed6:	bd7d                	j	ffffffffc0200d94 <buddy_init_memmap+0x48>
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200ed8:	00001617          	auipc	a2,0x1
ffffffffc0200edc:	0b060613          	add	a2,a2,176 # ffffffffc0201f88 <etext+0x8f0>
ffffffffc0200ee0:	02c00593          	li	a1,44
ffffffffc0200ee4:	00001517          	auipc	a0,0x1
ffffffffc0200ee8:	eb450513          	add	a0,a0,-332 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200eec:	cbaff0ef          	jal	ffffffffc02003a6 <__panic>
    assert((n > 0));
ffffffffc0200ef0:	00001697          	auipc	a3,0x1
ffffffffc0200ef4:	09068693          	add	a3,a3,144 # ffffffffc0201f80 <etext+0x8e8>
ffffffffc0200ef8:	00001617          	auipc	a2,0x1
ffffffffc0200efc:	e8860613          	add	a2,a2,-376 # ffffffffc0201d80 <etext+0x6e8>
ffffffffc0200f00:	45dd                	li	a1,23
ffffffffc0200f02:	00001517          	auipc	a0,0x1
ffffffffc0200f06:	e9650513          	add	a0,a0,-362 # ffffffffc0201d98 <etext+0x700>
ffffffffc0200f0a:	c9cff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0200f0e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f0e:	100027f3          	csrr	a5,sstatus
ffffffffc0200f12:	8b89                	and	a5,a5,2
ffffffffc0200f14:	e799                	bnez	a5,ffffffffc0200f22 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f16:	00005797          	auipc	a5,0x5
ffffffffc0200f1a:	5227b783          	ld	a5,1314(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0200f1e:	6f9c                	ld	a5,24(a5)
ffffffffc0200f20:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200f22:	1141                	add	sp,sp,-16
ffffffffc0200f24:	e406                	sd	ra,8(sp)
ffffffffc0200f26:	e022                	sd	s0,0(sp)
ffffffffc0200f28:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200f2a:	d30ff0ef          	jal	ffffffffc020045a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200f2e:	00005797          	auipc	a5,0x5
ffffffffc0200f32:	50a7b783          	ld	a5,1290(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0200f36:	6f9c                	ld	a5,24(a5)
ffffffffc0200f38:	8522                	mv	a0,s0
ffffffffc0200f3a:	9782                	jalr	a5
ffffffffc0200f3c:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200f3e:	d16ff0ef          	jal	ffffffffc0200454 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200f42:	60a2                	ld	ra,8(sp)
ffffffffc0200f44:	8522                	mv	a0,s0
ffffffffc0200f46:	6402                	ld	s0,0(sp)
ffffffffc0200f48:	0141                	add	sp,sp,16
ffffffffc0200f4a:	8082                	ret

ffffffffc0200f4c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f4c:	100027f3          	csrr	a5,sstatus
ffffffffc0200f50:	8b89                	and	a5,a5,2
ffffffffc0200f52:	e799                	bnez	a5,ffffffffc0200f60 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200f54:	00005797          	auipc	a5,0x5
ffffffffc0200f58:	4e47b783          	ld	a5,1252(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0200f5c:	739c                	ld	a5,32(a5)
ffffffffc0200f5e:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f60:	1101                	add	sp,sp,-32
ffffffffc0200f62:	ec06                	sd	ra,24(sp)
ffffffffc0200f64:	e822                	sd	s0,16(sp)
ffffffffc0200f66:	e426                	sd	s1,8(sp)
ffffffffc0200f68:	842a                	mv	s0,a0
ffffffffc0200f6a:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f6c:	ceeff0ef          	jal	ffffffffc020045a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200f70:	00005797          	auipc	a5,0x5
ffffffffc0200f74:	4c87b783          	ld	a5,1224(a5) # ffffffffc0206438 <pmm_manager>
ffffffffc0200f78:	739c                	ld	a5,32(a5)
ffffffffc0200f7a:	85a6                	mv	a1,s1
ffffffffc0200f7c:	8522                	mv	a0,s0
ffffffffc0200f7e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200f80:	6442                	ld	s0,16(sp)
ffffffffc0200f82:	60e2                	ld	ra,24(sp)
ffffffffc0200f84:	64a2                	ld	s1,8(sp)
ffffffffc0200f86:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc0200f88:	cccff06f          	j	ffffffffc0200454 <intr_enable>

ffffffffc0200f8c <pmm_init>:
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200f8c:	00001797          	auipc	a5,0x1
ffffffffc0200f90:	29c78793          	add	a5,a5,668 # ffffffffc0202228 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f94:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f96:	1101                	add	sp,sp,-32
ffffffffc0200f98:	ec06                	sd	ra,24(sp)
ffffffffc0200f9a:	e822                	sd	s0,16(sp)
ffffffffc0200f9c:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	03250513          	add	a0,a0,50 # ffffffffc0201fd0 <etext+0x938>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0200fa6:	00005497          	auipc	s1,0x5
ffffffffc0200faa:	49248493          	add	s1,s1,1170 # ffffffffc0206438 <pmm_manager>
ffffffffc0200fae:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fb0:	902ff0ef          	jal	ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0200fb4:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fb6:	00005417          	auipc	s0,0x5
ffffffffc0200fba:	49a40413          	add	s0,s0,1178 # ffffffffc0206450 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200fbe:	679c                	ld	a5,8(a5)
ffffffffc0200fc0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fc2:	57f5                	li	a5,-3
ffffffffc0200fc4:	07fa                	sll	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	02250513          	add	a0,a0,34 # ffffffffc0201fe8 <etext+0x950>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fce:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0200fd0:	8e2ff0ef          	jal	ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200fd4:	46c5                	li	a3,17
ffffffffc0200fd6:	06ee                	sll	a3,a3,0x1b
ffffffffc0200fd8:	40100613          	li	a2,1025
ffffffffc0200fdc:	16fd                	add	a3,a3,-1
ffffffffc0200fde:	0656                	sll	a2,a2,0x15
ffffffffc0200fe0:	07e005b7          	lui	a1,0x7e00
ffffffffc0200fe4:	00001517          	auipc	a0,0x1
ffffffffc0200fe8:	01c50513          	add	a0,a0,28 # ffffffffc0202000 <etext+0x968>
ffffffffc0200fec:	8c6ff0ef          	jal	ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200ff0:	777d                	lui	a4,0xfffff
ffffffffc0200ff2:	00006797          	auipc	a5,0x6
ffffffffc0200ff6:	47d78793          	add	a5,a5,1149 # ffffffffc020746f <end+0xfff>
ffffffffc0200ffa:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0200ffc:	00005517          	auipc	a0,0x5
ffffffffc0201000:	45c50513          	add	a0,a0,1116 # ffffffffc0206458 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201004:	00005597          	auipc	a1,0x5
ffffffffc0201008:	45c58593          	add	a1,a1,1116 # ffffffffc0206460 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020100c:	00088737          	lui	a4,0x88
ffffffffc0201010:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201012:	e19c                	sd	a5,0(a1)
ffffffffc0201014:	4705                	li	a4,1
ffffffffc0201016:	07a1                	add	a5,a5,8
ffffffffc0201018:	40e7b02f          	amoor.d	zero,a4,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020101c:	02800693          	li	a3,40
ffffffffc0201020:	4885                	li	a7,1
ffffffffc0201022:	fff80837          	lui	a6,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201026:	619c                	ld	a5,0(a1)
ffffffffc0201028:	97b6                	add	a5,a5,a3
ffffffffc020102a:	07a1                	add	a5,a5,8
ffffffffc020102c:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201030:	611c                	ld	a5,0(a0)
ffffffffc0201032:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201034:	02868693          	add	a3,a3,40
ffffffffc0201038:	01078633          	add	a2,a5,a6
ffffffffc020103c:	fec765e3          	bltu	a4,a2,ffffffffc0201026 <pmm_init+0x9a>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201040:	6190                	ld	a2,0(a1)
ffffffffc0201042:	00279693          	sll	a3,a5,0x2
ffffffffc0201046:	96be                	add	a3,a3,a5
ffffffffc0201048:	fec00737          	lui	a4,0xfec00
ffffffffc020104c:	9732                	add	a4,a4,a2
ffffffffc020104e:	068e                	sll	a3,a3,0x3
ffffffffc0201050:	96ba                	add	a3,a3,a4
ffffffffc0201052:	c0200737          	lui	a4,0xc0200
ffffffffc0201056:	0ae6e463          	bltu	a3,a4,ffffffffc02010fe <pmm_init+0x172>
ffffffffc020105a:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc020105c:	45c5                	li	a1,17
ffffffffc020105e:	05ee                	sll	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201060:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201062:	04b6e963          	bltu	a3,a1,ffffffffc02010b4 <pmm_init+0x128>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201066:	609c                	ld	a5,0(s1)
ffffffffc0201068:	7b9c                	ld	a5,48(a5)
ffffffffc020106a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020106c:	00001517          	auipc	a0,0x1
ffffffffc0201070:	02c50513          	add	a0,a0,44 # ffffffffc0202098 <etext+0xa00>
ffffffffc0201074:	83eff0ef          	jal	ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201078:	00004597          	auipc	a1,0x4
ffffffffc020107c:	f8858593          	add	a1,a1,-120 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201080:	00005797          	auipc	a5,0x5
ffffffffc0201084:	3cb7b423          	sd	a1,968(a5) # ffffffffc0206448 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201088:	c02007b7          	lui	a5,0xc0200
ffffffffc020108c:	08f5e563          	bltu	a1,a5,ffffffffc0201116 <pmm_init+0x18a>
ffffffffc0201090:	601c                	ld	a5,0(s0)
}
ffffffffc0201092:	6442                	ld	s0,16(sp)
ffffffffc0201094:	60e2                	ld	ra,24(sp)
ffffffffc0201096:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201098:	40f586b3          	sub	a3,a1,a5
ffffffffc020109c:	00005797          	auipc	a5,0x5
ffffffffc02010a0:	3ad7b223          	sd	a3,932(a5) # ffffffffc0206440 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02010a4:	00001517          	auipc	a0,0x1
ffffffffc02010a8:	01450513          	add	a0,a0,20 # ffffffffc02020b8 <etext+0xa20>
ffffffffc02010ac:	8636                	mv	a2,a3
}
ffffffffc02010ae:	6105                	add	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02010b0:	802ff06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02010b4:	6705                	lui	a4,0x1
ffffffffc02010b6:	177d                	add	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02010b8:	96ba                	add	a3,a3,a4
ffffffffc02010ba:	777d                	lui	a4,0xfffff
ffffffffc02010bc:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02010be:	00c6d713          	srl	a4,a3,0xc
ffffffffc02010c2:	02f77263          	bgeu	a4,a5,ffffffffc02010e6 <pmm_init+0x15a>
    pmm_manager->init_memmap(base, n);
ffffffffc02010c6:	0004b803          	ld	a6,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02010ca:	fff807b7          	lui	a5,0xfff80
ffffffffc02010ce:	97ba                	add	a5,a5,a4
ffffffffc02010d0:	00279513          	sll	a0,a5,0x2
ffffffffc02010d4:	953e                	add	a0,a0,a5
ffffffffc02010d6:	01083783          	ld	a5,16(a6) # fffffffffff80010 <end+0x3fd79ba0>
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02010da:	8d95                	sub	a1,a1,a3
ffffffffc02010dc:	050e                	sll	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02010de:	81b1                	srl	a1,a1,0xc
ffffffffc02010e0:	9532                	add	a0,a0,a2
ffffffffc02010e2:	9782                	jalr	a5
}
ffffffffc02010e4:	b749                	j	ffffffffc0201066 <pmm_init+0xda>
        panic("pa2page called with invalid pa");
ffffffffc02010e6:	00001617          	auipc	a2,0x1
ffffffffc02010ea:	f8260613          	add	a2,a2,-126 # ffffffffc0202068 <etext+0x9d0>
ffffffffc02010ee:	06b00593          	li	a1,107
ffffffffc02010f2:	00001517          	auipc	a0,0x1
ffffffffc02010f6:	f9650513          	add	a0,a0,-106 # ffffffffc0202088 <etext+0x9f0>
ffffffffc02010fa:	aacff0ef          	jal	ffffffffc02003a6 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010fe:	00001617          	auipc	a2,0x1
ffffffffc0201102:	f3260613          	add	a2,a2,-206 # ffffffffc0202030 <etext+0x998>
ffffffffc0201106:	06f00593          	li	a1,111
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	f4e50513          	add	a0,a0,-178 # ffffffffc0202058 <etext+0x9c0>
ffffffffc0201112:	a94ff0ef          	jal	ffffffffc02003a6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201116:	86ae                	mv	a3,a1
ffffffffc0201118:	00001617          	auipc	a2,0x1
ffffffffc020111c:	f1860613          	add	a2,a2,-232 # ffffffffc0202030 <etext+0x998>
ffffffffc0201120:	08a00593          	li	a1,138
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	f3450513          	add	a0,a0,-204 # ffffffffc0202058 <etext+0x9c0>
ffffffffc020112c:	a7aff0ef          	jal	ffffffffc02003a6 <__panic>

ffffffffc0201130 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201130:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201134:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201136:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020113a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020113c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201140:	f022                	sd	s0,32(sp)
ffffffffc0201142:	ec26                	sd	s1,24(sp)
ffffffffc0201144:	e84a                	sd	s2,16(sp)
ffffffffc0201146:	f406                	sd	ra,40(sp)
ffffffffc0201148:	84aa                	mv	s1,a0
ffffffffc020114a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020114c:	fff7041b          	addw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b8f>
    unsigned mod = do_div(result, base);
ffffffffc0201150:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201152:	05067063          	bgeu	a2,a6,ffffffffc0201192 <printnum+0x62>
ffffffffc0201156:	e44e                	sd	s3,8(sp)
ffffffffc0201158:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020115a:	4785                	li	a5,1
ffffffffc020115c:	00e7d763          	bge	a5,a4,ffffffffc020116a <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0201160:	85ca                	mv	a1,s2
ffffffffc0201162:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201164:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201166:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201168:	fc65                	bnez	s0,ffffffffc0201160 <printnum+0x30>
ffffffffc020116a:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020116c:	1a02                	sll	s4,s4,0x20
ffffffffc020116e:	020a5a13          	srl	s4,s4,0x20
ffffffffc0201172:	00001797          	auipc	a5,0x1
ffffffffc0201176:	f8678793          	add	a5,a5,-122 # ffffffffc02020f8 <etext+0xa60>
ffffffffc020117a:	97d2                	add	a5,a5,s4
}
ffffffffc020117c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020117e:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201182:	70a2                	ld	ra,40(sp)
ffffffffc0201184:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201186:	85ca                	mv	a1,s2
ffffffffc0201188:	87a6                	mv	a5,s1
}
ffffffffc020118a:	6942                	ld	s2,16(sp)
ffffffffc020118c:	64e2                	ld	s1,24(sp)
ffffffffc020118e:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201190:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201192:	03065633          	divu	a2,a2,a6
ffffffffc0201196:	8722                	mv	a4,s0
ffffffffc0201198:	f99ff0ef          	jal	ffffffffc0201130 <printnum>
ffffffffc020119c:	bfc1                	j	ffffffffc020116c <printnum+0x3c>

ffffffffc020119e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020119e:	7119                	add	sp,sp,-128
ffffffffc02011a0:	f4a6                	sd	s1,104(sp)
ffffffffc02011a2:	f0ca                	sd	s2,96(sp)
ffffffffc02011a4:	ecce                	sd	s3,88(sp)
ffffffffc02011a6:	e8d2                	sd	s4,80(sp)
ffffffffc02011a8:	e4d6                	sd	s5,72(sp)
ffffffffc02011aa:	e0da                	sd	s6,64(sp)
ffffffffc02011ac:	f862                	sd	s8,48(sp)
ffffffffc02011ae:	fc86                	sd	ra,120(sp)
ffffffffc02011b0:	f8a2                	sd	s0,112(sp)
ffffffffc02011b2:	fc5e                	sd	s7,56(sp)
ffffffffc02011b4:	f466                	sd	s9,40(sp)
ffffffffc02011b6:	f06a                	sd	s10,32(sp)
ffffffffc02011b8:	ec6e                	sd	s11,24(sp)
ffffffffc02011ba:	892a                	mv	s2,a0
ffffffffc02011bc:	84ae                	mv	s1,a1
ffffffffc02011be:	8c32                	mv	s8,a2
ffffffffc02011c0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011c2:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011c6:	05500b13          	li	s6,85
ffffffffc02011ca:	00001a97          	auipc	s5,0x1
ffffffffc02011ce:	096a8a93          	add	s5,s5,150 # ffffffffc0202260 <buddy_system_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011d2:	000c4503          	lbu	a0,0(s8)
ffffffffc02011d6:	001c0413          	add	s0,s8,1
ffffffffc02011da:	01350a63          	beq	a0,s3,ffffffffc02011ee <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02011de:	cd0d                	beqz	a0,ffffffffc0201218 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02011e0:	85a6                	mv	a1,s1
ffffffffc02011e2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011e4:	00044503          	lbu	a0,0(s0)
ffffffffc02011e8:	0405                	add	s0,s0,1
ffffffffc02011ea:	ff351ae3          	bne	a0,s3,ffffffffc02011de <vprintfmt+0x40>
        char padc = ' ';
ffffffffc02011ee:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02011f2:	4b81                	li	s7,0
ffffffffc02011f4:	4601                	li	a2,0
        width = precision = -1;
ffffffffc02011f6:	5d7d                	li	s10,-1
ffffffffc02011f8:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011fa:	00044683          	lbu	a3,0(s0)
ffffffffc02011fe:	00140c13          	add	s8,s0,1
ffffffffc0201202:	fdd6859b          	addw	a1,a3,-35
ffffffffc0201206:	0ff5f593          	zext.b	a1,a1
ffffffffc020120a:	02bb6663          	bltu	s6,a1,ffffffffc0201236 <vprintfmt+0x98>
ffffffffc020120e:	058a                	sll	a1,a1,0x2
ffffffffc0201210:	95d6                	add	a1,a1,s5
ffffffffc0201212:	4198                	lw	a4,0(a1)
ffffffffc0201214:	9756                	add	a4,a4,s5
ffffffffc0201216:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201218:	70e6                	ld	ra,120(sp)
ffffffffc020121a:	7446                	ld	s0,112(sp)
ffffffffc020121c:	74a6                	ld	s1,104(sp)
ffffffffc020121e:	7906                	ld	s2,96(sp)
ffffffffc0201220:	69e6                	ld	s3,88(sp)
ffffffffc0201222:	6a46                	ld	s4,80(sp)
ffffffffc0201224:	6aa6                	ld	s5,72(sp)
ffffffffc0201226:	6b06                	ld	s6,64(sp)
ffffffffc0201228:	7be2                	ld	s7,56(sp)
ffffffffc020122a:	7c42                	ld	s8,48(sp)
ffffffffc020122c:	7ca2                	ld	s9,40(sp)
ffffffffc020122e:	7d02                	ld	s10,32(sp)
ffffffffc0201230:	6de2                	ld	s11,24(sp)
ffffffffc0201232:	6109                	add	sp,sp,128
ffffffffc0201234:	8082                	ret
            putch('%', putdat);
ffffffffc0201236:	85a6                	mv	a1,s1
ffffffffc0201238:	02500513          	li	a0,37
ffffffffc020123c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020123e:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201242:	02500793          	li	a5,37
ffffffffc0201246:	8c22                	mv	s8,s0
ffffffffc0201248:	f8f705e3          	beq	a4,a5,ffffffffc02011d2 <vprintfmt+0x34>
ffffffffc020124c:	02500713          	li	a4,37
ffffffffc0201250:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201254:	1c7d                	add	s8,s8,-1
ffffffffc0201256:	fee79de3          	bne	a5,a4,ffffffffc0201250 <vprintfmt+0xb2>
ffffffffc020125a:	bfa5                	j	ffffffffc02011d2 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020125c:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201260:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201262:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201266:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc020126a:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020126e:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201270:	02b76563          	bltu	a4,a1,ffffffffc020129a <vprintfmt+0xfc>
ffffffffc0201274:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201276:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020127a:	002d171b          	sllw	a4,s10,0x2
ffffffffc020127e:	01a7073b          	addw	a4,a4,s10
ffffffffc0201282:	0017171b          	sllw	a4,a4,0x1
ffffffffc0201286:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201288:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020128c:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020128e:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc0201292:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201296:	feb570e3          	bgeu	a0,a1,ffffffffc0201276 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc020129a:	f60cd0e3          	bgez	s9,ffffffffc02011fa <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020129e:	8cea                	mv	s9,s10
ffffffffc02012a0:	5d7d                	li	s10,-1
ffffffffc02012a2:	bfa1                	j	ffffffffc02011fa <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012a4:	8db6                	mv	s11,a3
ffffffffc02012a6:	8462                	mv	s0,s8
ffffffffc02012a8:	bf89                	j	ffffffffc02011fa <vprintfmt+0x5c>
ffffffffc02012aa:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02012ac:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02012ae:	b7b1                	j	ffffffffc02011fa <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02012b0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02012b2:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc02012b6:	00c7c463          	blt	a5,a2,ffffffffc02012be <vprintfmt+0x120>
    else if (lflag) {
ffffffffc02012ba:	1a060163          	beqz	a2,ffffffffc020145c <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc02012be:	000a3603          	ld	a2,0(s4)
ffffffffc02012c2:	46c1                	li	a3,16
ffffffffc02012c4:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02012c6:	000d879b          	sext.w	a5,s11
ffffffffc02012ca:	8766                	mv	a4,s9
ffffffffc02012cc:	85a6                	mv	a1,s1
ffffffffc02012ce:	854a                	mv	a0,s2
ffffffffc02012d0:	e61ff0ef          	jal	ffffffffc0201130 <printnum>
            break;
ffffffffc02012d4:	bdfd                	j	ffffffffc02011d2 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02012d6:	000a2503          	lw	a0,0(s4)
ffffffffc02012da:	85a6                	mv	a1,s1
ffffffffc02012dc:	0a21                	add	s4,s4,8
ffffffffc02012de:	9902                	jalr	s2
            break;
ffffffffc02012e0:	bdcd                	j	ffffffffc02011d2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02012e2:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02012e4:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc02012e8:	00c7c463          	blt	a5,a2,ffffffffc02012f0 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc02012ec:	16060363          	beqz	a2,ffffffffc0201452 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc02012f0:	000a3603          	ld	a2,0(s4)
ffffffffc02012f4:	46a9                	li	a3,10
ffffffffc02012f6:	8a3a                	mv	s4,a4
ffffffffc02012f8:	b7f9                	j	ffffffffc02012c6 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc02012fa:	85a6                	mv	a1,s1
ffffffffc02012fc:	03000513          	li	a0,48
ffffffffc0201300:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201302:	85a6                	mv	a1,s1
ffffffffc0201304:	07800513          	li	a0,120
ffffffffc0201308:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020130a:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020130e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201310:	0a21                	add	s4,s4,8
            goto number;
ffffffffc0201312:	bf55                	j	ffffffffc02012c6 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201314:	85a6                	mv	a1,s1
ffffffffc0201316:	02500513          	li	a0,37
ffffffffc020131a:	9902                	jalr	s2
            break;
ffffffffc020131c:	bd5d                	j	ffffffffc02011d2 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020131e:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201322:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201324:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc0201326:	bf95                	j	ffffffffc020129a <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201328:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc020132a:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc020132e:	00c7c463          	blt	a5,a2,ffffffffc0201336 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201332:	10060b63          	beqz	a2,ffffffffc0201448 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201336:	000a3603          	ld	a2,0(s4)
ffffffffc020133a:	46a1                	li	a3,8
ffffffffc020133c:	8a3a                	mv	s4,a4
ffffffffc020133e:	b761                	j	ffffffffc02012c6 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201340:	fffcc793          	not	a5,s9
ffffffffc0201344:	97fd                	sra	a5,a5,0x3f
ffffffffc0201346:	00fcf7b3          	and	a5,s9,a5
ffffffffc020134a:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020134e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201350:	b56d                	j	ffffffffc02011fa <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201352:	000a3403          	ld	s0,0(s4)
ffffffffc0201356:	008a0793          	add	a5,s4,8
ffffffffc020135a:	e43e                	sd	a5,8(sp)
ffffffffc020135c:	12040063          	beqz	s0,ffffffffc020147c <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201360:	0d905963          	blez	s9,ffffffffc0201432 <vprintfmt+0x294>
ffffffffc0201364:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201368:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc020136c:	12fd9763          	bne	s11,a5,ffffffffc020149a <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201370:	00044783          	lbu	a5,0(s0)
ffffffffc0201374:	0007851b          	sext.w	a0,a5
ffffffffc0201378:	cb9d                	beqz	a5,ffffffffc02013ae <vprintfmt+0x210>
ffffffffc020137a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020137c:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201380:	000d4563          	bltz	s10,ffffffffc020138a <vprintfmt+0x1ec>
ffffffffc0201384:	3d7d                	addw	s10,s10,-1
ffffffffc0201386:	028d0263          	beq	s10,s0,ffffffffc02013aa <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc020138a:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020138c:	0c0b8d63          	beqz	s7,ffffffffc0201466 <vprintfmt+0x2c8>
ffffffffc0201390:	3781                	addw	a5,a5,-32
ffffffffc0201392:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201466 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201396:	03f00513          	li	a0,63
ffffffffc020139a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020139c:	000a4783          	lbu	a5,0(s4)
ffffffffc02013a0:	3cfd                	addw	s9,s9,-1
ffffffffc02013a2:	0a05                	add	s4,s4,1
ffffffffc02013a4:	0007851b          	sext.w	a0,a5
ffffffffc02013a8:	ffe1                	bnez	a5,ffffffffc0201380 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc02013aa:	01905963          	blez	s9,ffffffffc02013bc <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc02013ae:	85a6                	mv	a1,s1
ffffffffc02013b0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02013b4:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc02013b6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013b8:	fe0c9be3          	bnez	s9,ffffffffc02013ae <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013bc:	6a22                	ld	s4,8(sp)
ffffffffc02013be:	bd11                	j	ffffffffc02011d2 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02013c0:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc02013c2:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc02013c6:	00c7c363          	blt	a5,a2,ffffffffc02013cc <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc02013ca:	ce25                	beqz	a2,ffffffffc0201442 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc02013cc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02013d0:	08044d63          	bltz	s0,ffffffffc020146a <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02013d4:	8622                	mv	a2,s0
ffffffffc02013d6:	8a5e                	mv	s4,s7
ffffffffc02013d8:	46a9                	li	a3,10
ffffffffc02013da:	b5f5                	j	ffffffffc02012c6 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc02013dc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013e0:	4619                	li	a2,6
            if (err < 0) {
ffffffffc02013e2:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc02013e6:	8fb9                	xor	a5,a5,a4
ffffffffc02013e8:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013ec:	02d64663          	blt	a2,a3,ffffffffc0201418 <vprintfmt+0x27a>
ffffffffc02013f0:	00369713          	sll	a4,a3,0x3
ffffffffc02013f4:	00001797          	auipc	a5,0x1
ffffffffc02013f8:	fc478793          	add	a5,a5,-60 # ffffffffc02023b8 <error_string>
ffffffffc02013fc:	97ba                	add	a5,a5,a4
ffffffffc02013fe:	639c                	ld	a5,0(a5)
ffffffffc0201400:	cf81                	beqz	a5,ffffffffc0201418 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201402:	86be                	mv	a3,a5
ffffffffc0201404:	00001617          	auipc	a2,0x1
ffffffffc0201408:	d2460613          	add	a2,a2,-732 # ffffffffc0202128 <etext+0xa90>
ffffffffc020140c:	85a6                	mv	a1,s1
ffffffffc020140e:	854a                	mv	a0,s2
ffffffffc0201410:	0e8000ef          	jal	ffffffffc02014f8 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201414:	0a21                	add	s4,s4,8
ffffffffc0201416:	bb75                	j	ffffffffc02011d2 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	d0060613          	add	a2,a2,-768 # ffffffffc0202118 <etext+0xa80>
ffffffffc0201420:	85a6                	mv	a1,s1
ffffffffc0201422:	854a                	mv	a0,s2
ffffffffc0201424:	0d4000ef          	jal	ffffffffc02014f8 <printfmt>
            err = va_arg(ap, int);
ffffffffc0201428:	0a21                	add	s4,s4,8
ffffffffc020142a:	b365                	j	ffffffffc02011d2 <vprintfmt+0x34>
            lflag ++;
ffffffffc020142c:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020142e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201430:	b3e9                	j	ffffffffc02011fa <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201432:	00044783          	lbu	a5,0(s0)
ffffffffc0201436:	0007851b          	sext.w	a0,a5
ffffffffc020143a:	d3c9                	beqz	a5,ffffffffc02013bc <vprintfmt+0x21e>
ffffffffc020143c:	00140a13          	add	s4,s0,1
ffffffffc0201440:	bf2d                	j	ffffffffc020137a <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201442:	000a2403          	lw	s0,0(s4)
ffffffffc0201446:	b769                	j	ffffffffc02013d0 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201448:	000a6603          	lwu	a2,0(s4)
ffffffffc020144c:	46a1                	li	a3,8
ffffffffc020144e:	8a3a                	mv	s4,a4
ffffffffc0201450:	bd9d                	j	ffffffffc02012c6 <vprintfmt+0x128>
ffffffffc0201452:	000a6603          	lwu	a2,0(s4)
ffffffffc0201456:	46a9                	li	a3,10
ffffffffc0201458:	8a3a                	mv	s4,a4
ffffffffc020145a:	b5b5                	j	ffffffffc02012c6 <vprintfmt+0x128>
ffffffffc020145c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201460:	46c1                	li	a3,16
ffffffffc0201462:	8a3a                	mv	s4,a4
ffffffffc0201464:	b58d                	j	ffffffffc02012c6 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201466:	9902                	jalr	s2
ffffffffc0201468:	bf15                	j	ffffffffc020139c <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc020146a:	85a6                	mv	a1,s1
ffffffffc020146c:	02d00513          	li	a0,45
ffffffffc0201470:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201472:	40800633          	neg	a2,s0
ffffffffc0201476:	8a5e                	mv	s4,s7
ffffffffc0201478:	46a9                	li	a3,10
ffffffffc020147a:	b5b1                	j	ffffffffc02012c6 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc020147c:	01905663          	blez	s9,ffffffffc0201488 <vprintfmt+0x2ea>
ffffffffc0201480:	02d00793          	li	a5,45
ffffffffc0201484:	04fd9263          	bne	s11,a5,ffffffffc02014c8 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201488:	02800793          	li	a5,40
ffffffffc020148c:	00001a17          	auipc	s4,0x1
ffffffffc0201490:	c85a0a13          	add	s4,s4,-891 # ffffffffc0202111 <etext+0xa79>
ffffffffc0201494:	02800513          	li	a0,40
ffffffffc0201498:	b5cd                	j	ffffffffc020137a <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020149a:	85ea                	mv	a1,s10
ffffffffc020149c:	8522                	mv	a0,s0
ffffffffc020149e:	17e000ef          	jal	ffffffffc020161c <strnlen>
ffffffffc02014a2:	40ac8cbb          	subw	s9,s9,a0
ffffffffc02014a6:	01905963          	blez	s9,ffffffffc02014b8 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc02014aa:	2d81                	sext.w	s11,s11
ffffffffc02014ac:	85a6                	mv	a1,s1
ffffffffc02014ae:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014b0:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc02014b2:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014b4:	fe0c9ce3          	bnez	s9,ffffffffc02014ac <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014b8:	00044783          	lbu	a5,0(s0)
ffffffffc02014bc:	0007851b          	sext.w	a0,a5
ffffffffc02014c0:	ea079de3          	bnez	a5,ffffffffc020137a <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014c4:	6a22                	ld	s4,8(sp)
ffffffffc02014c6:	b331                	j	ffffffffc02011d2 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014c8:	85ea                	mv	a1,s10
ffffffffc02014ca:	00001517          	auipc	a0,0x1
ffffffffc02014ce:	c4650513          	add	a0,a0,-954 # ffffffffc0202110 <etext+0xa78>
ffffffffc02014d2:	14a000ef          	jal	ffffffffc020161c <strnlen>
ffffffffc02014d6:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc02014da:	00001417          	auipc	s0,0x1
ffffffffc02014de:	c3640413          	add	s0,s0,-970 # ffffffffc0202110 <etext+0xa78>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014e2:	00001a17          	auipc	s4,0x1
ffffffffc02014e6:	c2fa0a13          	add	s4,s4,-977 # ffffffffc0202111 <etext+0xa79>
ffffffffc02014ea:	02800793          	li	a5,40
ffffffffc02014ee:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02014f2:	fb904ce3          	bgtz	s9,ffffffffc02014aa <vprintfmt+0x30c>
ffffffffc02014f6:	b551                	j	ffffffffc020137a <vprintfmt+0x1dc>

ffffffffc02014f8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014f8:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02014fa:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014fe:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201500:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201502:	ec06                	sd	ra,24(sp)
ffffffffc0201504:	f83a                	sd	a4,48(sp)
ffffffffc0201506:	fc3e                	sd	a5,56(sp)
ffffffffc0201508:	e0c2                	sd	a6,64(sp)
ffffffffc020150a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020150c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020150e:	c91ff0ef          	jal	ffffffffc020119e <vprintfmt>
}
ffffffffc0201512:	60e2                	ld	ra,24(sp)
ffffffffc0201514:	6161                	add	sp,sp,80
ffffffffc0201516:	8082                	ret

ffffffffc0201518 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201518:	715d                	add	sp,sp,-80
ffffffffc020151a:	e486                	sd	ra,72(sp)
ffffffffc020151c:	e0a2                	sd	s0,64(sp)
ffffffffc020151e:	fc26                	sd	s1,56(sp)
ffffffffc0201520:	f84a                	sd	s2,48(sp)
ffffffffc0201522:	f44e                	sd	s3,40(sp)
ffffffffc0201524:	f052                	sd	s4,32(sp)
ffffffffc0201526:	ec56                	sd	s5,24(sp)
ffffffffc0201528:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc020152a:	c901                	beqz	a0,ffffffffc020153a <readline+0x22>
ffffffffc020152c:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020152e:	00001517          	auipc	a0,0x1
ffffffffc0201532:	bfa50513          	add	a0,a0,-1030 # ffffffffc0202128 <etext+0xa90>
ffffffffc0201536:	b7dfe0ef          	jal	ffffffffc02000b2 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc020153a:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020153c:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc020153e:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201540:	4a29                	li	s4,10
ffffffffc0201542:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201544:	00005b17          	auipc	s6,0x5
ffffffffc0201548:	accb0b13          	add	s6,s6,-1332 # ffffffffc0206010 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020154c:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201550:	be7fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201554:	00054a63          	bltz	a0,ffffffffc0201568 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201558:	00a4da63          	bge	s1,a0,ffffffffc020156c <readline+0x54>
ffffffffc020155c:	0289d263          	bge	s3,s0,ffffffffc0201580 <readline+0x68>
        c = getchar();
ffffffffc0201560:	bd7fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201564:	fe055ae3          	bgez	a0,ffffffffc0201558 <readline+0x40>
            return NULL;
ffffffffc0201568:	4501                	li	a0,0
ffffffffc020156a:	a091                	j	ffffffffc02015ae <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020156c:	03251463          	bne	a0,s2,ffffffffc0201594 <readline+0x7c>
ffffffffc0201570:	04804963          	bgtz	s0,ffffffffc02015c2 <readline+0xaa>
        c = getchar();
ffffffffc0201574:	bc3fe0ef          	jal	ffffffffc0200136 <getchar>
        if (c < 0) {
ffffffffc0201578:	fe0548e3          	bltz	a0,ffffffffc0201568 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020157c:	fea4d8e3          	bge	s1,a0,ffffffffc020156c <readline+0x54>
            cputchar(c);
ffffffffc0201580:	e42a                	sd	a0,8(sp)
ffffffffc0201582:	b65fe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc0201586:	6522                	ld	a0,8(sp)
ffffffffc0201588:	008b07b3          	add	a5,s6,s0
ffffffffc020158c:	2405                	addw	s0,s0,1
ffffffffc020158e:	00a78023          	sb	a0,0(a5)
ffffffffc0201592:	bf7d                	j	ffffffffc0201550 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201594:	01450463          	beq	a0,s4,ffffffffc020159c <readline+0x84>
ffffffffc0201598:	fb551ce3          	bne	a0,s5,ffffffffc0201550 <readline+0x38>
            cputchar(c);
ffffffffc020159c:	b4bfe0ef          	jal	ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	a7050513          	add	a0,a0,-1424 # ffffffffc0206010 <buf>
ffffffffc02015a8:	942a                	add	s0,s0,a0
ffffffffc02015aa:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc02015ae:	60a6                	ld	ra,72(sp)
ffffffffc02015b0:	6406                	ld	s0,64(sp)
ffffffffc02015b2:	74e2                	ld	s1,56(sp)
ffffffffc02015b4:	7942                	ld	s2,48(sp)
ffffffffc02015b6:	79a2                	ld	s3,40(sp)
ffffffffc02015b8:	7a02                	ld	s4,32(sp)
ffffffffc02015ba:	6ae2                	ld	s5,24(sp)
ffffffffc02015bc:	6b42                	ld	s6,16(sp)
ffffffffc02015be:	6161                	add	sp,sp,80
ffffffffc02015c0:	8082                	ret
            cputchar(c);
ffffffffc02015c2:	4521                	li	a0,8
ffffffffc02015c4:	b23fe0ef          	jal	ffffffffc02000e6 <cputchar>
            i --;
ffffffffc02015c8:	347d                	addw	s0,s0,-1
ffffffffc02015ca:	b759                	j	ffffffffc0201550 <readline+0x38>

ffffffffc02015cc <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015cc:	4781                	li	a5,0
ffffffffc02015ce:	00005717          	auipc	a4,0x5
ffffffffc02015d2:	a3a73703          	ld	a4,-1478(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015d6:	88ba                	mv	a7,a4
ffffffffc02015d8:	852a                	mv	a0,a0
ffffffffc02015da:	85be                	mv	a1,a5
ffffffffc02015dc:	863e                	mv	a2,a5
ffffffffc02015de:	00000073          	ecall
ffffffffc02015e2:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015e4:	8082                	ret

ffffffffc02015e6 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02015e6:	4781                	li	a5,0
ffffffffc02015e8:	00005717          	auipc	a4,0x5
ffffffffc02015ec:	e8073703          	ld	a4,-384(a4) # ffffffffc0206468 <SBI_SET_TIMER>
ffffffffc02015f0:	88ba                	mv	a7,a4
ffffffffc02015f2:	852a                	mv	a0,a0
ffffffffc02015f4:	85be                	mv	a1,a5
ffffffffc02015f6:	863e                	mv	a2,a5
ffffffffc02015f8:	00000073          	ecall
ffffffffc02015fc:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02015fe:	8082                	ret

ffffffffc0201600 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201600:	4501                	li	a0,0
ffffffffc0201602:	00005797          	auipc	a5,0x5
ffffffffc0201606:	9fe7b783          	ld	a5,-1538(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc020160a:	88be                	mv	a7,a5
ffffffffc020160c:	852a                	mv	a0,a0
ffffffffc020160e:	85aa                	mv	a1,a0
ffffffffc0201610:	862a                	mv	a2,a0
ffffffffc0201612:	00000073          	ecall
ffffffffc0201616:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201618:	2501                	sext.w	a0,a0
ffffffffc020161a:	8082                	ret

ffffffffc020161c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020161c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020161e:	e589                	bnez	a1,ffffffffc0201628 <strnlen+0xc>
ffffffffc0201620:	a811                	j	ffffffffc0201634 <strnlen+0x18>
        cnt ++;
ffffffffc0201622:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201624:	00f58863          	beq	a1,a5,ffffffffc0201634 <strnlen+0x18>
ffffffffc0201628:	00f50733          	add	a4,a0,a5
ffffffffc020162c:	00074703          	lbu	a4,0(a4)
ffffffffc0201630:	fb6d                	bnez	a4,ffffffffc0201622 <strnlen+0x6>
ffffffffc0201632:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201634:	852e                	mv	a0,a1
ffffffffc0201636:	8082                	ret

ffffffffc0201638 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201638:	00054783          	lbu	a5,0(a0)
ffffffffc020163c:	e791                	bnez	a5,ffffffffc0201648 <strcmp+0x10>
ffffffffc020163e:	a02d                	j	ffffffffc0201668 <strcmp+0x30>
ffffffffc0201640:	00054783          	lbu	a5,0(a0)
ffffffffc0201644:	cf89                	beqz	a5,ffffffffc020165e <strcmp+0x26>
ffffffffc0201646:	85b6                	mv	a1,a3
ffffffffc0201648:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020164c:	0505                	add	a0,a0,1
ffffffffc020164e:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201652:	fef707e3          	beq	a4,a5,ffffffffc0201640 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201656:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020165a:	9d19                	subw	a0,a0,a4
ffffffffc020165c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020165e:	0015c703          	lbu	a4,1(a1)
ffffffffc0201662:	4501                	li	a0,0
}
ffffffffc0201664:	9d19                	subw	a0,a0,a4
ffffffffc0201666:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201668:	0005c703          	lbu	a4,0(a1)
ffffffffc020166c:	4501                	li	a0,0
ffffffffc020166e:	b7f5                	j	ffffffffc020165a <strcmp+0x22>

ffffffffc0201670 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201670:	00054783          	lbu	a5,0(a0)
ffffffffc0201674:	c799                	beqz	a5,ffffffffc0201682 <strchr+0x12>
        if (*s == c) {
ffffffffc0201676:	00f58763          	beq	a1,a5,ffffffffc0201684 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020167a:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020167e:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc0201680:	fbfd                	bnez	a5,ffffffffc0201676 <strchr+0x6>
    }
    return NULL;
ffffffffc0201682:	4501                	li	a0,0
}
ffffffffc0201684:	8082                	ret

ffffffffc0201686 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201686:	ca01                	beqz	a2,ffffffffc0201696 <memset+0x10>
ffffffffc0201688:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020168a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020168c:	0785                	add	a5,a5,1
ffffffffc020168e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201692:	fef61de3          	bne	a2,a5,ffffffffc020168c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201696:	8082                	ret
