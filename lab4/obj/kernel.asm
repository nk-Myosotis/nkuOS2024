
bin/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc0200024:	c020a137          	lui	sp,0xc020a

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000b517          	auipc	a0,0xb
ffffffffc0200036:	02e50513          	add	a0,a0,46 # ffffffffc020b060 <buf>
ffffffffc020003a:	00016617          	auipc	a2,0x16
ffffffffc020003e:	59660613          	add	a2,a2,1430 # ffffffffc02165d0 <end>
kern_init(void) {
ffffffffc0200042:	1141                	add	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	6a3040ef          	jal	ffffffffc0204eec <memset>

    cons_init();                // init the console
ffffffffc020004e:	494000ef          	jal	ffffffffc02004e2 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	eee58593          	add	a1,a1,-274 # ffffffffc0204f40 <etext+0x6>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	f0650513          	add	a0,a0,-250 # ffffffffc0204f60 <etext+0x26>
ffffffffc0200062:	11e000ef          	jal	ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	160000ef          	jal	ffffffffc02001c6 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	65d010ef          	jal	ffffffffc0201ec6 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	548000ef          	jal	ffffffffc02005b6 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5b6000ef          	jal	ffffffffc0200628 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	18b030ef          	jal	ffffffffc0203a00 <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	648040ef          	jal	ffffffffc02046c2 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	4d6000ef          	jal	ffffffffc0200554 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	2bb020ef          	jal	ffffffffc0202b3c <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	40a000ef          	jal	ffffffffc0200490 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	520000ef          	jal	ffffffffc02005aa <intr_enable>

    cpu_idle();                 // run idle process
ffffffffc020008e:	081040ef          	jal	ffffffffc020490e <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	add	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a2                	sd	s0,64(sp)
ffffffffc0200098:	fc26                	sd	s1,56(sp)
ffffffffc020009a:	f84a                	sd	s2,48(sp)
ffffffffc020009c:	f44e                	sd	s3,40(sp)
ffffffffc020009e:	f052                	sd	s4,32(sp)
ffffffffc02000a0:	ec56                	sd	s5,24(sp)
ffffffffc02000a2:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00005517          	auipc	a0,0x5
ffffffffc02000ac:	ec050513          	add	a0,a0,-320 # ffffffffc0204f68 <etext+0x2e>
ffffffffc02000b0:	0d0000ef          	jal	ffffffffc0200180 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000b4:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4a29                	li	s4,10
ffffffffc02000bc:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc02000be:	0000bb17          	auipc	s6,0xb
ffffffffc02000c2:	fa2b0b13          	add	s6,s6,-94 # ffffffffc020b060 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc02000ca:	0ec000ef          	jal	ffffffffc02001b6 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a4da63          	bge	s1,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	0289d263          	bge	s3,s0,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	0dc000ef          	jal	ffffffffc02001b6 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03251463          	bne	a0,s2,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	04804963          	bgtz	s0,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ee:	0c8000ef          	jal	ffffffffc02001b6 <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe0548e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f6:	fea4d8e3          	bge	s1,a0,ffffffffc02000e6 <readline+0x54>
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0b8000ef          	jal	ffffffffc02001b4 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	008b07b3          	add	a5,s6,s0
ffffffffc0200106:	2405                	addw	s0,s0,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01450463          	beq	a0,s4,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb551ce3          	bne	a0,s5,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	09e000ef          	jal	ffffffffc02001b4 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	0000b517          	auipc	a0,0xb
ffffffffc020011e:	f4650513          	add	a0,a0,-186 # ffffffffc020b060 <buf>
ffffffffc0200122:	942a                	add	s0,s0,a0
ffffffffc0200124:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6406                	ld	s0,64(sp)
ffffffffc020012c:	74e2                	ld	s1,56(sp)
ffffffffc020012e:	7942                	ld	s2,48(sp)
ffffffffc0200130:	79a2                	ld	s3,40(sp)
ffffffffc0200132:	7a02                	ld	s4,32(sp)
ffffffffc0200134:	6ae2                	ld	s5,24(sp)
ffffffffc0200136:	6b42                	ld	s6,16(sp)
ffffffffc0200138:	6161                	add	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	076000ef          	jal	ffffffffc02001b4 <cputchar>
            i --;
ffffffffc0200142:	347d                	addw	s0,s0,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	add	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	396000ef          	jal	ffffffffc02004e4 <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	add	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	add	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	add	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	add	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	169040ef          	jal	ffffffffc0204adc <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	add	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	add	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	add	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200186:	f42e                	sd	a1,40(sp)
ffffffffc0200188:	f832                	sd	a2,48(sp)
ffffffffc020018a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018c:	862a                	mv	a2,a0
ffffffffc020018e:	004c                	add	a1,sp,4
ffffffffc0200190:	00000517          	auipc	a0,0x0
ffffffffc0200194:	fb650513          	add	a0,a0,-74 # ffffffffc0200146 <cputch>
ffffffffc0200198:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc020019a:	ec06                	sd	ra,24(sp)
ffffffffc020019c:	e0ba                	sd	a4,64(sp)
ffffffffc020019e:	e4be                	sd	a5,72(sp)
ffffffffc02001a0:	e8c2                	sd	a6,80(sp)
ffffffffc02001a2:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a4:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a6:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001a8:	135040ef          	jal	ffffffffc0204adc <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	4512                	lw	a0,4(sp)
ffffffffc02001b0:	6125                	add	sp,sp,96
ffffffffc02001b2:	8082                	ret

ffffffffc02001b4 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b4:	ae05                	j	ffffffffc02004e4 <cons_putc>

ffffffffc02001b6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001b6:	1141                	add	sp,sp,-16
ffffffffc02001b8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ba:	35e000ef          	jal	ffffffffc0200518 <cons_getc>
ffffffffc02001be:	dd75                	beqz	a0,ffffffffc02001ba <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001c0:	60a2                	ld	ra,8(sp)
ffffffffc02001c2:	0141                	add	sp,sp,16
ffffffffc02001c4:	8082                	ret

ffffffffc02001c6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02001c6:	1141                	add	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001c8:	00005517          	auipc	a0,0x5
ffffffffc02001cc:	da850513          	add	a0,a0,-600 # ffffffffc0204f70 <etext+0x36>
void print_kerninfo(void) {
ffffffffc02001d0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001d2:	fafff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001d6:	00000597          	auipc	a1,0x0
ffffffffc02001da:	e5c58593          	add	a1,a1,-420 # ffffffffc0200032 <kern_init>
ffffffffc02001de:	00005517          	auipc	a0,0x5
ffffffffc02001e2:	db250513          	add	a0,a0,-590 # ffffffffc0204f90 <etext+0x56>
ffffffffc02001e6:	f9bff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001ea:	00005597          	auipc	a1,0x5
ffffffffc02001ee:	d5058593          	add	a1,a1,-688 # ffffffffc0204f3a <etext>
ffffffffc02001f2:	00005517          	auipc	a0,0x5
ffffffffc02001f6:	dbe50513          	add	a0,a0,-578 # ffffffffc0204fb0 <etext+0x76>
ffffffffc02001fa:	f87ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02001fe:	0000b597          	auipc	a1,0xb
ffffffffc0200202:	e6258593          	add	a1,a1,-414 # ffffffffc020b060 <buf>
ffffffffc0200206:	00005517          	auipc	a0,0x5
ffffffffc020020a:	dca50513          	add	a0,a0,-566 # ffffffffc0204fd0 <etext+0x96>
ffffffffc020020e:	f73ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200212:	00016597          	auipc	a1,0x16
ffffffffc0200216:	3be58593          	add	a1,a1,958 # ffffffffc02165d0 <end>
ffffffffc020021a:	00005517          	auipc	a0,0x5
ffffffffc020021e:	dd650513          	add	a0,a0,-554 # ffffffffc0204ff0 <etext+0xb6>
ffffffffc0200222:	f5fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200226:	00016797          	auipc	a5,0x16
ffffffffc020022a:	7a978793          	add	a5,a5,1961 # ffffffffc02169cf <end+0x3ff>
ffffffffc020022e:	00000717          	auipc	a4,0x0
ffffffffc0200232:	e0470713          	add	a4,a4,-508 # ffffffffc0200032 <kern_init>
ffffffffc0200236:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200238:	43f7d593          	sra	a1,a5,0x3f
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020023e:	3ff5f593          	and	a1,a1,1023
ffffffffc0200242:	95be                	add	a1,a1,a5
ffffffffc0200244:	85a9                	sra	a1,a1,0xa
ffffffffc0200246:	00005517          	auipc	a0,0x5
ffffffffc020024a:	dca50513          	add	a0,a0,-566 # ffffffffc0205010 <etext+0xd6>
}
ffffffffc020024e:	0141                	add	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	bf05                	j	ffffffffc0200180 <cprintf>

ffffffffc0200252 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200252:	1141                	add	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200254:	00005617          	auipc	a2,0x5
ffffffffc0200258:	dec60613          	add	a2,a2,-532 # ffffffffc0205040 <etext+0x106>
ffffffffc020025c:	04d00593          	li	a1,77
ffffffffc0200260:	00005517          	auipc	a0,0x5
ffffffffc0200264:	df850513          	add	a0,a0,-520 # ffffffffc0205058 <etext+0x11e>
void print_stackframe(void) {
ffffffffc0200268:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020026a:	1c8000ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020026e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026e:	1141                	add	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200270:	00005617          	auipc	a2,0x5
ffffffffc0200274:	e0060613          	add	a2,a2,-512 # ffffffffc0205070 <etext+0x136>
ffffffffc0200278:	00005597          	auipc	a1,0x5
ffffffffc020027c:	e1858593          	add	a1,a1,-488 # ffffffffc0205090 <etext+0x156>
ffffffffc0200280:	00005517          	auipc	a0,0x5
ffffffffc0200284:	e1850513          	add	a0,a0,-488 # ffffffffc0205098 <etext+0x15e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200288:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020028a:	ef7ff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc020028e:	00005617          	auipc	a2,0x5
ffffffffc0200292:	e1a60613          	add	a2,a2,-486 # ffffffffc02050a8 <etext+0x16e>
ffffffffc0200296:	00005597          	auipc	a1,0x5
ffffffffc020029a:	e3a58593          	add	a1,a1,-454 # ffffffffc02050d0 <etext+0x196>
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	dfa50513          	add	a0,a0,-518 # ffffffffc0205098 <etext+0x15e>
ffffffffc02002a6:	edbff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02002aa:	00005617          	auipc	a2,0x5
ffffffffc02002ae:	e3660613          	add	a2,a2,-458 # ffffffffc02050e0 <etext+0x1a6>
ffffffffc02002b2:	00005597          	auipc	a1,0x5
ffffffffc02002b6:	e4e58593          	add	a1,a1,-434 # ffffffffc0205100 <etext+0x1c6>
ffffffffc02002ba:	00005517          	auipc	a0,0x5
ffffffffc02002be:	dde50513          	add	a0,a0,-546 # ffffffffc0205098 <etext+0x15e>
ffffffffc02002c2:	ebfff0ef          	jal	ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc02002c6:	60a2                	ld	ra,8(sp)
ffffffffc02002c8:	4501                	li	a0,0
ffffffffc02002ca:	0141                	add	sp,sp,16
ffffffffc02002cc:	8082                	ret

ffffffffc02002ce <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ce:	1141                	add	sp,sp,-16
ffffffffc02002d0:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002d2:	ef5ff0ef          	jal	ffffffffc02001c6 <print_kerninfo>
    return 0;
}
ffffffffc02002d6:	60a2                	ld	ra,8(sp)
ffffffffc02002d8:	4501                	li	a0,0
ffffffffc02002da:	0141                	add	sp,sp,16
ffffffffc02002dc:	8082                	ret

ffffffffc02002de <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002de:	1141                	add	sp,sp,-16
ffffffffc02002e0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002e2:	f71ff0ef          	jal	ffffffffc0200252 <print_stackframe>
    return 0;
}
ffffffffc02002e6:	60a2                	ld	ra,8(sp)
ffffffffc02002e8:	4501                	li	a0,0
ffffffffc02002ea:	0141                	add	sp,sp,16
ffffffffc02002ec:	8082                	ret

ffffffffc02002ee <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002ee:	7115                	add	sp,sp,-224
ffffffffc02002f0:	f15a                	sd	s6,160(sp)
ffffffffc02002f2:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f4:	00005517          	auipc	a0,0x5
ffffffffc02002f8:	e1c50513          	add	a0,a0,-484 # ffffffffc0205110 <etext+0x1d6>
kmonitor(struct trapframe *tf) {
ffffffffc02002fc:	ed86                	sd	ra,216(sp)
ffffffffc02002fe:	e9a2                	sd	s0,208(sp)
ffffffffc0200300:	e5a6                	sd	s1,200(sp)
ffffffffc0200302:	e1ca                	sd	s2,192(sp)
ffffffffc0200304:	fd4e                	sd	s3,184(sp)
ffffffffc0200306:	f952                	sd	s4,176(sp)
ffffffffc0200308:	f556                	sd	s5,168(sp)
ffffffffc020030a:	ed5e                	sd	s7,152(sp)
ffffffffc020030c:	e962                	sd	s8,144(sp)
ffffffffc020030e:	e566                	sd	s9,136(sp)
ffffffffc0200310:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200312:	e6fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200316:	00005517          	auipc	a0,0x5
ffffffffc020031a:	e2250513          	add	a0,a0,-478 # ffffffffc0205138 <etext+0x1fe>
ffffffffc020031e:	e63ff0ef          	jal	ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200322:	000b0563          	beqz	s6,ffffffffc020032c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200326:	855a                	mv	a0,s6
ffffffffc0200328:	4e8000ef          	jal	ffffffffc0200810 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	4581                	li	a1,0
ffffffffc0200330:	4601                	li	a2,0
ffffffffc0200332:	48a1                	li	a7,8
ffffffffc0200334:	00000073          	ecall
ffffffffc0200338:	00007c17          	auipc	s8,0x7
ffffffffc020033c:	a70c0c13          	add	s8,s8,-1424 # ffffffffc0206da8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200340:	00005917          	auipc	s2,0x5
ffffffffc0200344:	e2090913          	add	s2,s2,-480 # ffffffffc0205160 <etext+0x226>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200348:	00005497          	auipc	s1,0x5
ffffffffc020034c:	e2048493          	add	s1,s1,-480 # ffffffffc0205168 <etext+0x22e>
        if (argc == MAXARGS - 1) {
ffffffffc0200350:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200352:	00005a97          	auipc	s5,0x5
ffffffffc0200356:	e1ea8a93          	add	s5,s5,-482 # ffffffffc0205170 <etext+0x236>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020035c:	00005b97          	auipc	s7,0x5
ffffffffc0200360:	e34b8b93          	add	s7,s7,-460 # ffffffffc0205190 <etext+0x256>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200364:	854a                	mv	a0,s2
ffffffffc0200366:	d2dff0ef          	jal	ffffffffc0200092 <readline>
ffffffffc020036a:	842a                	mv	s0,a0
ffffffffc020036c:	dd65                	beqz	a0,ffffffffc0200364 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036e:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200372:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200374:	e59d                	bnez	a1,ffffffffc02003a2 <kmonitor+0xb4>
    if (argc == 0) {
ffffffffc0200376:	fe0c87e3          	beqz	s9,ffffffffc0200364 <kmonitor+0x76>
ffffffffc020037a:	00007d17          	auipc	s10,0x7
ffffffffc020037e:	a2ed0d13          	add	s10,s10,-1490 # ffffffffc0206da8 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200382:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200384:	6582                	ld	a1,0(sp)
ffffffffc0200386:	000d3503          	ld	a0,0(s10)
ffffffffc020038a:	315040ef          	jal	ffffffffc0204e9e <strcmp>
ffffffffc020038e:	c53d                	beqz	a0,ffffffffc02003fc <kmonitor+0x10e>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200390:	2405                	addw	s0,s0,1
ffffffffc0200392:	0d61                	add	s10,s10,24
ffffffffc0200394:	ff4418e3          	bne	s0,s4,ffffffffc0200384 <kmonitor+0x96>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200398:	6582                	ld	a1,0(sp)
ffffffffc020039a:	855e                	mv	a0,s7
ffffffffc020039c:	de5ff0ef          	jal	ffffffffc0200180 <cprintf>
    return 0;
ffffffffc02003a0:	b7d1                	j	ffffffffc0200364 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a2:	8526                	mv	a0,s1
ffffffffc02003a4:	333040ef          	jal	ffffffffc0204ed6 <strchr>
ffffffffc02003a8:	c901                	beqz	a0,ffffffffc02003b8 <kmonitor+0xca>
ffffffffc02003aa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003ae:	00040023          	sb	zero,0(s0)
ffffffffc02003b2:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b4:	d1e9                	beqz	a1,ffffffffc0200376 <kmonitor+0x88>
ffffffffc02003b6:	b7f5                	j	ffffffffc02003a2 <kmonitor+0xb4>
        if (*buf == '\0') {
ffffffffc02003b8:	00044783          	lbu	a5,0(s0)
ffffffffc02003bc:	dfcd                	beqz	a5,ffffffffc0200376 <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc02003be:	033c8a63          	beq	s9,s3,ffffffffc02003f2 <kmonitor+0x104>
        argv[argc ++] = buf;
ffffffffc02003c2:	003c9793          	sll	a5,s9,0x3
ffffffffc02003c6:	08078793          	add	a5,a5,128
ffffffffc02003ca:	978a                	add	a5,a5,sp
ffffffffc02003cc:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003d4:	2c85                	addw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d6:	e591                	bnez	a1,ffffffffc02003e2 <kmonitor+0xf4>
ffffffffc02003d8:	bf79                	j	ffffffffc0200376 <kmonitor+0x88>
ffffffffc02003da:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003de:	0405                	add	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003e0:	d9d9                	beqz	a1,ffffffffc0200376 <kmonitor+0x88>
ffffffffc02003e2:	8526                	mv	a0,s1
ffffffffc02003e4:	2f3040ef          	jal	ffffffffc0204ed6 <strchr>
ffffffffc02003e8:	d96d                	beqz	a0,ffffffffc02003da <kmonitor+0xec>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ea:	00044583          	lbu	a1,0(s0)
ffffffffc02003ee:	d5c1                	beqz	a1,ffffffffc0200376 <kmonitor+0x88>
ffffffffc02003f0:	bf4d                	j	ffffffffc02003a2 <kmonitor+0xb4>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003f2:	45c1                	li	a1,16
ffffffffc02003f4:	8556                	mv	a0,s5
ffffffffc02003f6:	d8bff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02003fa:	b7e1                	j	ffffffffc02003c2 <kmonitor+0xd4>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003fc:	00141793          	sll	a5,s0,0x1
ffffffffc0200400:	97a2                	add	a5,a5,s0
ffffffffc0200402:	078e                	sll	a5,a5,0x3
ffffffffc0200404:	97e2                	add	a5,a5,s8
ffffffffc0200406:	6b9c                	ld	a5,16(a5)
ffffffffc0200408:	865a                	mv	a2,s6
ffffffffc020040a:	002c                	add	a1,sp,8
ffffffffc020040c:	fffc851b          	addw	a0,s9,-1
ffffffffc0200410:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200412:	f40559e3          	bgez	a0,ffffffffc0200364 <kmonitor+0x76>
}
ffffffffc0200416:	60ee                	ld	ra,216(sp)
ffffffffc0200418:	644e                	ld	s0,208(sp)
ffffffffc020041a:	64ae                	ld	s1,200(sp)
ffffffffc020041c:	690e                	ld	s2,192(sp)
ffffffffc020041e:	79ea                	ld	s3,184(sp)
ffffffffc0200420:	7a4a                	ld	s4,176(sp)
ffffffffc0200422:	7aaa                	ld	s5,168(sp)
ffffffffc0200424:	7b0a                	ld	s6,160(sp)
ffffffffc0200426:	6bea                	ld	s7,152(sp)
ffffffffc0200428:	6c4a                	ld	s8,144(sp)
ffffffffc020042a:	6caa                	ld	s9,136(sp)
ffffffffc020042c:	6d0a                	ld	s10,128(sp)
ffffffffc020042e:	612d                	add	sp,sp,224
ffffffffc0200430:	8082                	ret

ffffffffc0200432 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200432:	00016317          	auipc	t1,0x16
ffffffffc0200436:	10630313          	add	t1,t1,262 # ffffffffc0216538 <is_panic>
ffffffffc020043a:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020043e:	715d                	add	sp,sp,-80
ffffffffc0200440:	ec06                	sd	ra,24(sp)
ffffffffc0200442:	f436                	sd	a3,40(sp)
ffffffffc0200444:	f83a                	sd	a4,48(sp)
ffffffffc0200446:	fc3e                	sd	a5,56(sp)
ffffffffc0200448:	e0c2                	sd	a6,64(sp)
ffffffffc020044a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020044c:	020e1c63          	bnez	t3,ffffffffc0200484 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200450:	4785                	li	a5,1
ffffffffc0200452:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200456:	e822                	sd	s0,16(sp)
ffffffffc0200458:	103c                	add	a5,sp,40
ffffffffc020045a:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020045c:	862e                	mv	a2,a1
ffffffffc020045e:	85aa                	mv	a1,a0
ffffffffc0200460:	00005517          	auipc	a0,0x5
ffffffffc0200464:	d4850513          	add	a0,a0,-696 # ffffffffc02051a8 <etext+0x26e>
    va_start(ap, fmt);
ffffffffc0200468:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020046a:	d17ff0ef          	jal	ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020046e:	65a2                	ld	a1,8(sp)
ffffffffc0200470:	8522                	mv	a0,s0
ffffffffc0200472:	cefff0ef          	jal	ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc0200476:	00005517          	auipc	a0,0x5
ffffffffc020047a:	d5250513          	add	a0,a0,-686 # ffffffffc02051c8 <etext+0x28e>
ffffffffc020047e:	d03ff0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0200482:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200484:	12c000ef          	jal	ffffffffc02005b0 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200488:	4501                	li	a0,0
ffffffffc020048a:	e65ff0ef          	jal	ffffffffc02002ee <kmonitor>
    while (1) {
ffffffffc020048e:	bfed                	j	ffffffffc0200488 <__panic+0x56>

ffffffffc0200490 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200490:	67e1                	lui	a5,0x18
ffffffffc0200492:	6a078793          	add	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200496:	00016717          	auipc	a4,0x16
ffffffffc020049a:	0af73523          	sd	a5,170(a4) # ffffffffc0216540 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049e:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004a2:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a4:	953e                	add	a0,a0,a5
ffffffffc02004a6:	4601                	li	a2,0
ffffffffc02004a8:	4881                	li	a7,0
ffffffffc02004aa:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004ae:	02000793          	li	a5,32
ffffffffc02004b2:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004b6:	00005517          	auipc	a0,0x5
ffffffffc02004ba:	d1a50513          	add	a0,a0,-742 # ffffffffc02051d0 <etext+0x296>
    ticks = 0;
ffffffffc02004be:	00016797          	auipc	a5,0x16
ffffffffc02004c2:	0807b523          	sd	zero,138(a5) # ffffffffc0216548 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004c6:	b96d                	j	ffffffffc0200180 <cprintf>

ffffffffc02004c8 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c8:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004cc:	00016797          	auipc	a5,0x16
ffffffffc02004d0:	0747b783          	ld	a5,116(a5) # ffffffffc0216540 <timebase>
ffffffffc02004d4:	953e                	add	a0,a0,a5
ffffffffc02004d6:	4581                	li	a1,0
ffffffffc02004d8:	4601                	li	a2,0
ffffffffc02004da:	4881                	li	a7,0
ffffffffc02004dc:	00000073          	ecall
ffffffffc02004e0:	8082                	ret

ffffffffc02004e2 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004e2:	8082                	ret

ffffffffc02004e4 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004e4:	100027f3          	csrr	a5,sstatus
ffffffffc02004e8:	8b89                	and	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004ea:	0ff57513          	zext.b	a0,a0
ffffffffc02004ee:	e799                	bnez	a5,ffffffffc02004fc <cons_putc+0x18>
ffffffffc02004f0:	4581                	li	a1,0
ffffffffc02004f2:	4601                	li	a2,0
ffffffffc02004f4:	4885                	li	a7,1
ffffffffc02004f6:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004fa:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004fc:	1101                	add	sp,sp,-32
ffffffffc02004fe:	ec06                	sd	ra,24(sp)
ffffffffc0200500:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200502:	0ae000ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0200506:	6522                	ld	a0,8(sp)
ffffffffc0200508:	4581                	li	a1,0
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4885                	li	a7,1
ffffffffc020050e:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200512:	60e2                	ld	ra,24(sp)
ffffffffc0200514:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc0200516:	a851                	j	ffffffffc02005aa <intr_enable>

ffffffffc0200518 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200518:	100027f3          	csrr	a5,sstatus
ffffffffc020051c:	8b89                	and	a5,a5,2
ffffffffc020051e:	eb89                	bnez	a5,ffffffffc0200530 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200520:	4501                	li	a0,0
ffffffffc0200522:	4581                	li	a1,0
ffffffffc0200524:	4601                	li	a2,0
ffffffffc0200526:	4889                	li	a7,2
ffffffffc0200528:	00000073          	ecall
ffffffffc020052c:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020052e:	8082                	ret
int cons_getc(void) {
ffffffffc0200530:	1101                	add	sp,sp,-32
ffffffffc0200532:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200534:	07c000ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0200538:	4501                	li	a0,0
ffffffffc020053a:	4581                	li	a1,0
ffffffffc020053c:	4601                	li	a2,0
ffffffffc020053e:	4889                	li	a7,2
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	2501                	sext.w	a0,a0
ffffffffc0200546:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200548:	062000ef          	jal	ffffffffc02005aa <intr_enable>
}
ffffffffc020054c:	60e2                	ld	ra,24(sp)
ffffffffc020054e:	6522                	ld	a0,8(sp)
ffffffffc0200550:	6105                	add	sp,sp,32
ffffffffc0200552:	8082                	ret

ffffffffc0200554 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200554:	8082                	ret

ffffffffc0200556 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200556:	00253513          	sltiu	a0,a0,2
ffffffffc020055a:	8082                	ret

ffffffffc020055c <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020055c:	03800513          	li	a0,56
ffffffffc0200560:	8082                	ret

ffffffffc0200562 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200562:	0000b797          	auipc	a5,0xb
ffffffffc0200566:	efe78793          	add	a5,a5,-258 # ffffffffc020b460 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc020056a:	0095959b          	sllw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc020056e:	1141                	add	sp,sp,-16
ffffffffc0200570:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200572:	95be                	add	a1,a1,a5
ffffffffc0200574:	00969613          	sll	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200578:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020057a:	185040ef          	jal	ffffffffc0204efe <memcpy>
    return 0;
}
ffffffffc020057e:	60a2                	ld	ra,8(sp)
ffffffffc0200580:	4501                	li	a0,0
ffffffffc0200582:	0141                	add	sp,sp,16
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200586:	0095979b          	sllw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020058a:	0000b517          	auipc	a0,0xb
ffffffffc020058e:	ed650513          	add	a0,a0,-298 # ffffffffc020b460 <ide>
                   size_t nsecs) {
ffffffffc0200592:	1141                	add	sp,sp,-16
ffffffffc0200594:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200596:	953e                	add	a0,a0,a5
ffffffffc0200598:	00969613          	sll	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020059c:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020059e:	161040ef          	jal	ffffffffc0204efe <memcpy>
    return 0;
}
ffffffffc02005a2:	60a2                	ld	ra,8(sp)
ffffffffc02005a4:	4501                	li	a0,0
ffffffffc02005a6:	0141                	add	sp,sp,16
ffffffffc02005a8:	8082                	ret

ffffffffc02005aa <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005aa:	100167f3          	csrrs	a5,sstatus,2
ffffffffc02005ae:	8082                	ret

ffffffffc02005b0 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005b0:	100177f3          	csrrc	a5,sstatus,2
ffffffffc02005b4:	8082                	ret

ffffffffc02005b6 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005b8:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005bc:	1141                	add	sp,sp,-16
ffffffffc02005be:	e022                	sd	s0,0(sp)
ffffffffc02005c0:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005c2:	1007f793          	and	a5,a5,256
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005c6:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005ca:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005cc:	04b00613          	li	a2,75
ffffffffc02005d0:	e399                	bnez	a5,ffffffffc02005d6 <pgfault_handler+0x1e>
ffffffffc02005d2:	05500613          	li	a2,85
ffffffffc02005d6:	11843703          	ld	a4,280(s0)
ffffffffc02005da:	47bd                	li	a5,15
ffffffffc02005dc:	05200693          	li	a3,82
ffffffffc02005e0:	00f71463          	bne	a4,a5,ffffffffc02005e8 <pgfault_handler+0x30>
ffffffffc02005e4:	05700693          	li	a3,87
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	c0850513          	add	a0,a0,-1016 # ffffffffc02051f0 <etext+0x2b6>
ffffffffc02005f0:	b91ff0ef          	jal	ffffffffc0200180 <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc02005f4:	00016517          	auipc	a0,0x16
ffffffffc02005f8:	fb453503          	ld	a0,-76(a0) # ffffffffc02165a8 <check_mm_struct>
ffffffffc02005fc:	c911                	beqz	a0,ffffffffc0200610 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc02005fe:	11043603          	ld	a2,272(s0)
ffffffffc0200602:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200606:	6402                	ld	s0,0(sp)
ffffffffc0200608:	60a2                	ld	ra,8(sp)
ffffffffc020060a:	0141                	add	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020060c:	1df0306f          	j	ffffffffc0203fea <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200610:	00005617          	auipc	a2,0x5
ffffffffc0200614:	c0060613          	add	a2,a2,-1024 # ffffffffc0205210 <etext+0x2d6>
ffffffffc0200618:	06200593          	li	a1,98
ffffffffc020061c:	00005517          	auipc	a0,0x5
ffffffffc0200620:	c0c50513          	add	a0,a0,-1012 # ffffffffc0205228 <etext+0x2ee>
ffffffffc0200624:	e0fff0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0200628 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200628:	14005073          	csrw	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020062c:	00000797          	auipc	a5,0x0
ffffffffc0200630:	47c78793          	add	a5,a5,1148 # ffffffffc0200aa8 <__alltraps>
ffffffffc0200634:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200638:	000407b7          	lui	a5,0x40
ffffffffc020063c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200640:	8082                	ret

ffffffffc0200642 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200642:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200644:	1141                	add	sp,sp,-16
ffffffffc0200646:	e022                	sd	s0,0(sp)
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020064a:	00005517          	auipc	a0,0x5
ffffffffc020064e:	bf650513          	add	a0,a0,-1034 # ffffffffc0205240 <etext+0x306>
void print_regs(struct pushregs *gpr) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200654:	b2dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200658:	640c                	ld	a1,8(s0)
ffffffffc020065a:	00005517          	auipc	a0,0x5
ffffffffc020065e:	bfe50513          	add	a0,a0,-1026 # ffffffffc0205258 <etext+0x31e>
ffffffffc0200662:	b1fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200666:	680c                	ld	a1,16(s0)
ffffffffc0200668:	00005517          	auipc	a0,0x5
ffffffffc020066c:	c0850513          	add	a0,a0,-1016 # ffffffffc0205270 <etext+0x336>
ffffffffc0200670:	b11ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200674:	6c0c                	ld	a1,24(s0)
ffffffffc0200676:	00005517          	auipc	a0,0x5
ffffffffc020067a:	c1250513          	add	a0,a0,-1006 # ffffffffc0205288 <etext+0x34e>
ffffffffc020067e:	b03ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200682:	700c                	ld	a1,32(s0)
ffffffffc0200684:	00005517          	auipc	a0,0x5
ffffffffc0200688:	c1c50513          	add	a0,a0,-996 # ffffffffc02052a0 <etext+0x366>
ffffffffc020068c:	af5ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200690:	740c                	ld	a1,40(s0)
ffffffffc0200692:	00005517          	auipc	a0,0x5
ffffffffc0200696:	c2650513          	add	a0,a0,-986 # ffffffffc02052b8 <etext+0x37e>
ffffffffc020069a:	ae7ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020069e:	780c                	ld	a1,48(s0)
ffffffffc02006a0:	00005517          	auipc	a0,0x5
ffffffffc02006a4:	c3050513          	add	a0,a0,-976 # ffffffffc02052d0 <etext+0x396>
ffffffffc02006a8:	ad9ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006ac:	7c0c                	ld	a1,56(s0)
ffffffffc02006ae:	00005517          	auipc	a0,0x5
ffffffffc02006b2:	c3a50513          	add	a0,a0,-966 # ffffffffc02052e8 <etext+0x3ae>
ffffffffc02006b6:	acbff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006ba:	602c                	ld	a1,64(s0)
ffffffffc02006bc:	00005517          	auipc	a0,0x5
ffffffffc02006c0:	c4450513          	add	a0,a0,-956 # ffffffffc0205300 <etext+0x3c6>
ffffffffc02006c4:	abdff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006c8:	642c                	ld	a1,72(s0)
ffffffffc02006ca:	00005517          	auipc	a0,0x5
ffffffffc02006ce:	c4e50513          	add	a0,a0,-946 # ffffffffc0205318 <etext+0x3de>
ffffffffc02006d2:	aafff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006d6:	682c                	ld	a1,80(s0)
ffffffffc02006d8:	00005517          	auipc	a0,0x5
ffffffffc02006dc:	c5850513          	add	a0,a0,-936 # ffffffffc0205330 <etext+0x3f6>
ffffffffc02006e0:	aa1ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02006e4:	6c2c                	ld	a1,88(s0)
ffffffffc02006e6:	00005517          	auipc	a0,0x5
ffffffffc02006ea:	c6250513          	add	a0,a0,-926 # ffffffffc0205348 <etext+0x40e>
ffffffffc02006ee:	a93ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02006f2:	702c                	ld	a1,96(s0)
ffffffffc02006f4:	00005517          	auipc	a0,0x5
ffffffffc02006f8:	c6c50513          	add	a0,a0,-916 # ffffffffc0205360 <etext+0x426>
ffffffffc02006fc:	a85ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200700:	742c                	ld	a1,104(s0)
ffffffffc0200702:	00005517          	auipc	a0,0x5
ffffffffc0200706:	c7650513          	add	a0,a0,-906 # ffffffffc0205378 <etext+0x43e>
ffffffffc020070a:	a77ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020070e:	782c                	ld	a1,112(s0)
ffffffffc0200710:	00005517          	auipc	a0,0x5
ffffffffc0200714:	c8050513          	add	a0,a0,-896 # ffffffffc0205390 <etext+0x456>
ffffffffc0200718:	a69ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020071c:	7c2c                	ld	a1,120(s0)
ffffffffc020071e:	00005517          	auipc	a0,0x5
ffffffffc0200722:	c8a50513          	add	a0,a0,-886 # ffffffffc02053a8 <etext+0x46e>
ffffffffc0200726:	a5bff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020072a:	604c                	ld	a1,128(s0)
ffffffffc020072c:	00005517          	auipc	a0,0x5
ffffffffc0200730:	c9450513          	add	a0,a0,-876 # ffffffffc02053c0 <etext+0x486>
ffffffffc0200734:	a4dff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200738:	644c                	ld	a1,136(s0)
ffffffffc020073a:	00005517          	auipc	a0,0x5
ffffffffc020073e:	c9e50513          	add	a0,a0,-866 # ffffffffc02053d8 <etext+0x49e>
ffffffffc0200742:	a3fff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200746:	684c                	ld	a1,144(s0)
ffffffffc0200748:	00005517          	auipc	a0,0x5
ffffffffc020074c:	ca850513          	add	a0,a0,-856 # ffffffffc02053f0 <etext+0x4b6>
ffffffffc0200750:	a31ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200754:	6c4c                	ld	a1,152(s0)
ffffffffc0200756:	00005517          	auipc	a0,0x5
ffffffffc020075a:	cb250513          	add	a0,a0,-846 # ffffffffc0205408 <etext+0x4ce>
ffffffffc020075e:	a23ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200762:	704c                	ld	a1,160(s0)
ffffffffc0200764:	00005517          	auipc	a0,0x5
ffffffffc0200768:	cbc50513          	add	a0,a0,-836 # ffffffffc0205420 <etext+0x4e6>
ffffffffc020076c:	a15ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200770:	744c                	ld	a1,168(s0)
ffffffffc0200772:	00005517          	auipc	a0,0x5
ffffffffc0200776:	cc650513          	add	a0,a0,-826 # ffffffffc0205438 <etext+0x4fe>
ffffffffc020077a:	a07ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020077e:	784c                	ld	a1,176(s0)
ffffffffc0200780:	00005517          	auipc	a0,0x5
ffffffffc0200784:	cd050513          	add	a0,a0,-816 # ffffffffc0205450 <etext+0x516>
ffffffffc0200788:	9f9ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020078c:	7c4c                	ld	a1,184(s0)
ffffffffc020078e:	00005517          	auipc	a0,0x5
ffffffffc0200792:	cda50513          	add	a0,a0,-806 # ffffffffc0205468 <etext+0x52e>
ffffffffc0200796:	9ebff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020079a:	606c                	ld	a1,192(s0)
ffffffffc020079c:	00005517          	auipc	a0,0x5
ffffffffc02007a0:	ce450513          	add	a0,a0,-796 # ffffffffc0205480 <etext+0x546>
ffffffffc02007a4:	9ddff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007a8:	646c                	ld	a1,200(s0)
ffffffffc02007aa:	00005517          	auipc	a0,0x5
ffffffffc02007ae:	cee50513          	add	a0,a0,-786 # ffffffffc0205498 <etext+0x55e>
ffffffffc02007b2:	9cfff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007b6:	686c                	ld	a1,208(s0)
ffffffffc02007b8:	00005517          	auipc	a0,0x5
ffffffffc02007bc:	cf850513          	add	a0,a0,-776 # ffffffffc02054b0 <etext+0x576>
ffffffffc02007c0:	9c1ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007c4:	6c6c                	ld	a1,216(s0)
ffffffffc02007c6:	00005517          	auipc	a0,0x5
ffffffffc02007ca:	d0250513          	add	a0,a0,-766 # ffffffffc02054c8 <etext+0x58e>
ffffffffc02007ce:	9b3ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007d2:	706c                	ld	a1,224(s0)
ffffffffc02007d4:	00005517          	auipc	a0,0x5
ffffffffc02007d8:	d0c50513          	add	a0,a0,-756 # ffffffffc02054e0 <etext+0x5a6>
ffffffffc02007dc:	9a5ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02007e0:	746c                	ld	a1,232(s0)
ffffffffc02007e2:	00005517          	auipc	a0,0x5
ffffffffc02007e6:	d1650513          	add	a0,a0,-746 # ffffffffc02054f8 <etext+0x5be>
ffffffffc02007ea:	997ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02007ee:	786c                	ld	a1,240(s0)
ffffffffc02007f0:	00005517          	auipc	a0,0x5
ffffffffc02007f4:	d2050513          	add	a0,a0,-736 # ffffffffc0205510 <etext+0x5d6>
ffffffffc02007f8:	989ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02007fc:	7c6c                	ld	a1,248(s0)
}
ffffffffc02007fe:	6402                	ld	s0,0(sp)
ffffffffc0200800:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200802:	00005517          	auipc	a0,0x5
ffffffffc0200806:	d2650513          	add	a0,a0,-730 # ffffffffc0205528 <etext+0x5ee>
}
ffffffffc020080a:	0141                	add	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020080c:	975ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200810 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200810:	1141                	add	sp,sp,-16
ffffffffc0200812:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200814:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200816:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200818:	00005517          	auipc	a0,0x5
ffffffffc020081c:	d2850513          	add	a0,a0,-728 # ffffffffc0205540 <etext+0x606>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200820:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200822:	95fff0ef          	jal	ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200826:	8522                	mv	a0,s0
ffffffffc0200828:	e1bff0ef          	jal	ffffffffc0200642 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020082c:	10043583          	ld	a1,256(s0)
ffffffffc0200830:	00005517          	auipc	a0,0x5
ffffffffc0200834:	d2850513          	add	a0,a0,-728 # ffffffffc0205558 <etext+0x61e>
ffffffffc0200838:	949ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020083c:	10843583          	ld	a1,264(s0)
ffffffffc0200840:	00005517          	auipc	a0,0x5
ffffffffc0200844:	d3050513          	add	a0,a0,-720 # ffffffffc0205570 <etext+0x636>
ffffffffc0200848:	939ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020084c:	11043583          	ld	a1,272(s0)
ffffffffc0200850:	00005517          	auipc	a0,0x5
ffffffffc0200854:	d3850513          	add	a0,a0,-712 # ffffffffc0205588 <etext+0x64e>
ffffffffc0200858:	929ff0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020085c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200860:	6402                	ld	s0,0(sp)
ffffffffc0200862:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200864:	00005517          	auipc	a0,0x5
ffffffffc0200868:	d3c50513          	add	a0,a0,-708 # ffffffffc02055a0 <etext+0x666>
}
ffffffffc020086c:	0141                	add	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020086e:	913ff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200872 <interrupt_handler>:
static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200872:	11853783          	ld	a5,280(a0)
ffffffffc0200876:	472d                	li	a4,11
ffffffffc0200878:	0786                	sll	a5,a5,0x1
ffffffffc020087a:	8385                	srl	a5,a5,0x1
ffffffffc020087c:	06f76c63          	bltu	a4,a5,ffffffffc02008f4 <interrupt_handler+0x82>
ffffffffc0200880:	00006717          	auipc	a4,0x6
ffffffffc0200884:	57070713          	add	a4,a4,1392 # ffffffffc0206df0 <commands+0x48>
ffffffffc0200888:	078a                	sll	a5,a5,0x2
ffffffffc020088a:	97ba                	add	a5,a5,a4
ffffffffc020088c:	439c                	lw	a5,0(a5)
ffffffffc020088e:	97ba                	add	a5,a5,a4
ffffffffc0200890:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200892:	00005517          	auipc	a0,0x5
ffffffffc0200896:	d8650513          	add	a0,a0,-634 # ffffffffc0205618 <etext+0x6de>
ffffffffc020089a:	8e7ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc020089e:	00005517          	auipc	a0,0x5
ffffffffc02008a2:	d5a50513          	add	a0,a0,-678 # ffffffffc02055f8 <etext+0x6be>
ffffffffc02008a6:	8dbff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008aa:	00005517          	auipc	a0,0x5
ffffffffc02008ae:	d0e50513          	add	a0,a0,-754 # ffffffffc02055b8 <etext+0x67e>
ffffffffc02008b2:	8cfff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008b6:	00005517          	auipc	a0,0x5
ffffffffc02008ba:	d2250513          	add	a0,a0,-734 # ffffffffc02055d8 <etext+0x69e>
ffffffffc02008be:	8c3ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008c2:	1141                	add	sp,sp,-16
ffffffffc02008c4:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02008c6:	c03ff0ef          	jal	ffffffffc02004c8 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02008ca:	00016697          	auipc	a3,0x16
ffffffffc02008ce:	c7e68693          	add	a3,a3,-898 # ffffffffc0216548 <ticks>
ffffffffc02008d2:	629c                	ld	a5,0(a3)
ffffffffc02008d4:	06400713          	li	a4,100
ffffffffc02008d8:	0785                	add	a5,a5,1 # 40001 <kern_entry-0xffffffffc01bffff>
ffffffffc02008da:	02e7f733          	remu	a4,a5,a4
ffffffffc02008de:	e29c                	sd	a5,0(a3)
ffffffffc02008e0:	cb19                	beqz	a4,ffffffffc02008f6 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008e2:	60a2                	ld	ra,8(sp)
ffffffffc02008e4:	0141                	add	sp,sp,16
ffffffffc02008e6:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc02008e8:	00005517          	auipc	a0,0x5
ffffffffc02008ec:	d6050513          	add	a0,a0,-672 # ffffffffc0205648 <etext+0x70e>
ffffffffc02008f0:	891ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc02008f4:	bf31                	j	ffffffffc0200810 <print_trapframe>
}
ffffffffc02008f6:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc02008f8:	06400593          	li	a1,100
ffffffffc02008fc:	00005517          	auipc	a0,0x5
ffffffffc0200900:	d3c50513          	add	a0,a0,-708 # ffffffffc0205638 <etext+0x6fe>
}
ffffffffc0200904:	0141                	add	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200906:	87bff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc020090a <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020090a:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020090e:	1101                	add	sp,sp,-32
ffffffffc0200910:	e822                	sd	s0,16(sp)
ffffffffc0200912:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200914:	473d                	li	a4,15
void exception_handler(struct trapframe *tf) {
ffffffffc0200916:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200918:	14f76d63          	bltu	a4,a5,ffffffffc0200a72 <exception_handler+0x168>
ffffffffc020091c:	00006717          	auipc	a4,0x6
ffffffffc0200920:	50470713          	add	a4,a4,1284 # ffffffffc0206e20 <commands+0x78>
ffffffffc0200924:	078a                	sll	a5,a5,0x2
ffffffffc0200926:	97ba                	add	a5,a5,a4
ffffffffc0200928:	439c                	lw	a5,0(a5)
ffffffffc020092a:	97ba                	add	a5,a5,a4
ffffffffc020092c:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	eda50513          	add	a0,a0,-294 # ffffffffc0205808 <etext+0x8ce>
ffffffffc0200936:	e426                	sd	s1,8(sp)
ffffffffc0200938:	849ff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020093c:	8522                	mv	a0,s0
ffffffffc020093e:	c7bff0ef          	jal	ffffffffc02005b8 <pgfault_handler>
ffffffffc0200942:	84aa                	mv	s1,a0
ffffffffc0200944:	12051c63          	bnez	a0,ffffffffc0200a7c <exception_handler+0x172>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200948:	60e2                	ld	ra,24(sp)
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	64a2                	ld	s1,8(sp)
ffffffffc020094e:	6105                	add	sp,sp,32
ffffffffc0200950:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200952:	00005517          	auipc	a0,0x5
ffffffffc0200956:	d1650513          	add	a0,a0,-746 # ffffffffc0205668 <etext+0x72e>
}
ffffffffc020095a:	6442                	ld	s0,16(sp)
ffffffffc020095c:	60e2                	ld	ra,24(sp)
ffffffffc020095e:	6105                	add	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200960:	821ff06f          	j	ffffffffc0200180 <cprintf>
ffffffffc0200964:	00005517          	auipc	a0,0x5
ffffffffc0200968:	d2450513          	add	a0,a0,-732 # ffffffffc0205688 <etext+0x74e>
ffffffffc020096c:	b7fd                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc020096e:	00005517          	auipc	a0,0x5
ffffffffc0200972:	d3a50513          	add	a0,a0,-710 # ffffffffc02056a8 <etext+0x76e>
ffffffffc0200976:	b7d5                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200978:	00005517          	auipc	a0,0x5
ffffffffc020097c:	d4850513          	add	a0,a0,-696 # ffffffffc02056c0 <etext+0x786>
ffffffffc0200980:	bfe9                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc0200982:	00005517          	auipc	a0,0x5
ffffffffc0200986:	d4e50513          	add	a0,a0,-690 # ffffffffc02056d0 <etext+0x796>
ffffffffc020098a:	bfc1                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	d6450513          	add	a0,a0,-668 # ffffffffc02056f0 <etext+0x7b6>
ffffffffc0200994:	e426                	sd	s1,8(sp)
ffffffffc0200996:	feaff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020099a:	8522                	mv	a0,s0
ffffffffc020099c:	c1dff0ef          	jal	ffffffffc02005b8 <pgfault_handler>
ffffffffc02009a0:	84aa                	mv	s1,a0
ffffffffc02009a2:	d15d                	beqz	a0,ffffffffc0200948 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009a4:	8522                	mv	a0,s0
ffffffffc02009a6:	e6bff0ef          	jal	ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009aa:	86a6                	mv	a3,s1
ffffffffc02009ac:	00005617          	auipc	a2,0x5
ffffffffc02009b0:	d5c60613          	add	a2,a2,-676 # ffffffffc0205708 <etext+0x7ce>
ffffffffc02009b4:	0b300593          	li	a1,179
ffffffffc02009b8:	00005517          	auipc	a0,0x5
ffffffffc02009bc:	87050513          	add	a0,a0,-1936 # ffffffffc0205228 <etext+0x2ee>
ffffffffc02009c0:	a73ff0ef          	jal	ffffffffc0200432 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009c4:	00005517          	auipc	a0,0x5
ffffffffc02009c8:	d6450513          	add	a0,a0,-668 # ffffffffc0205728 <etext+0x7ee>
ffffffffc02009cc:	b779                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02009ce:	00005517          	auipc	a0,0x5
ffffffffc02009d2:	d7250513          	add	a0,a0,-654 # ffffffffc0205740 <etext+0x806>
ffffffffc02009d6:	e426                	sd	s1,8(sp)
ffffffffc02009d8:	fa8ff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009dc:	8522                	mv	a0,s0
ffffffffc02009de:	bdbff0ef          	jal	ffffffffc02005b8 <pgfault_handler>
ffffffffc02009e2:	84aa                	mv	s1,a0
ffffffffc02009e4:	d135                	beqz	a0,ffffffffc0200948 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009e6:	8522                	mv	a0,s0
ffffffffc02009e8:	e29ff0ef          	jal	ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ec:	86a6                	mv	a3,s1
ffffffffc02009ee:	00005617          	auipc	a2,0x5
ffffffffc02009f2:	d1a60613          	add	a2,a2,-742 # ffffffffc0205708 <etext+0x7ce>
ffffffffc02009f6:	0bd00593          	li	a1,189
ffffffffc02009fa:	00005517          	auipc	a0,0x5
ffffffffc02009fe:	82e50513          	add	a0,a0,-2002 # ffffffffc0205228 <etext+0x2ee>
ffffffffc0200a02:	a31ff0ef          	jal	ffffffffc0200432 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a06:	00005517          	auipc	a0,0x5
ffffffffc0200a0a:	d5250513          	add	a0,a0,-686 # ffffffffc0205758 <etext+0x81e>
ffffffffc0200a0e:	b7b1                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	d6850513          	add	a0,a0,-664 # ffffffffc0205778 <etext+0x83e>
ffffffffc0200a18:	b789                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a1a:	00005517          	auipc	a0,0x5
ffffffffc0200a1e:	d7e50513          	add	a0,a0,-642 # ffffffffc0205798 <etext+0x85e>
ffffffffc0200a22:	bf25                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a24:	00005517          	auipc	a0,0x5
ffffffffc0200a28:	d9450513          	add	a0,a0,-620 # ffffffffc02057b8 <etext+0x87e>
ffffffffc0200a2c:	b73d                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a2e:	00005517          	auipc	a0,0x5
ffffffffc0200a32:	daa50513          	add	a0,a0,-598 # ffffffffc02057d8 <etext+0x89e>
ffffffffc0200a36:	b715                	j	ffffffffc020095a <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a38:	00005517          	auipc	a0,0x5
ffffffffc0200a3c:	db850513          	add	a0,a0,-584 # ffffffffc02057f0 <etext+0x8b6>
ffffffffc0200a40:	e426                	sd	s1,8(sp)
ffffffffc0200a42:	f3eff0ef          	jal	ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a46:	8522                	mv	a0,s0
ffffffffc0200a48:	b71ff0ef          	jal	ffffffffc02005b8 <pgfault_handler>
ffffffffc0200a4c:	84aa                	mv	s1,a0
ffffffffc0200a4e:	ee050de3          	beqz	a0,ffffffffc0200948 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a52:	8522                	mv	a0,s0
ffffffffc0200a54:	dbdff0ef          	jal	ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a58:	86a6                	mv	a3,s1
ffffffffc0200a5a:	00005617          	auipc	a2,0x5
ffffffffc0200a5e:	cae60613          	add	a2,a2,-850 # ffffffffc0205708 <etext+0x7ce>
ffffffffc0200a62:	0d300593          	li	a1,211
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	7c250513          	add	a0,a0,1986 # ffffffffc0205228 <etext+0x2ee>
ffffffffc0200a6e:	9c5ff0ef          	jal	ffffffffc0200432 <__panic>
            print_trapframe(tf);
ffffffffc0200a72:	8522                	mv	a0,s0
}
ffffffffc0200a74:	6442                	ld	s0,16(sp)
ffffffffc0200a76:	60e2                	ld	ra,24(sp)
ffffffffc0200a78:	6105                	add	sp,sp,32
            print_trapframe(tf);
ffffffffc0200a7a:	bb59                	j	ffffffffc0200810 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200a7c:	8522                	mv	a0,s0
ffffffffc0200a7e:	d93ff0ef          	jal	ffffffffc0200810 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a82:	86a6                	mv	a3,s1
ffffffffc0200a84:	00005617          	auipc	a2,0x5
ffffffffc0200a88:	c8460613          	add	a2,a2,-892 # ffffffffc0205708 <etext+0x7ce>
ffffffffc0200a8c:	0da00593          	li	a1,218
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	79850513          	add	a0,a0,1944 # ffffffffc0205228 <etext+0x2ee>
ffffffffc0200a98:	99bff0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0200a9c <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200a9c:	11853783          	ld	a5,280(a0)
ffffffffc0200aa0:	0007c363          	bltz	a5,ffffffffc0200aa6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200aa4:	b59d                	j	ffffffffc020090a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200aa6:	b3f1                	j	ffffffffc0200872 <interrupt_handler>

ffffffffc0200aa8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200aa8:	14011073          	csrw	sscratch,sp
ffffffffc0200aac:	712d                	add	sp,sp,-288
ffffffffc0200aae:	e406                	sd	ra,8(sp)
ffffffffc0200ab0:	ec0e                	sd	gp,24(sp)
ffffffffc0200ab2:	f012                	sd	tp,32(sp)
ffffffffc0200ab4:	f416                	sd	t0,40(sp)
ffffffffc0200ab6:	f81a                	sd	t1,48(sp)
ffffffffc0200ab8:	fc1e                	sd	t2,56(sp)
ffffffffc0200aba:	e0a2                	sd	s0,64(sp)
ffffffffc0200abc:	e4a6                	sd	s1,72(sp)
ffffffffc0200abe:	e8aa                	sd	a0,80(sp)
ffffffffc0200ac0:	ecae                	sd	a1,88(sp)
ffffffffc0200ac2:	f0b2                	sd	a2,96(sp)
ffffffffc0200ac4:	f4b6                	sd	a3,104(sp)
ffffffffc0200ac6:	f8ba                	sd	a4,112(sp)
ffffffffc0200ac8:	fcbe                	sd	a5,120(sp)
ffffffffc0200aca:	e142                	sd	a6,128(sp)
ffffffffc0200acc:	e546                	sd	a7,136(sp)
ffffffffc0200ace:	e94a                	sd	s2,144(sp)
ffffffffc0200ad0:	ed4e                	sd	s3,152(sp)
ffffffffc0200ad2:	f152                	sd	s4,160(sp)
ffffffffc0200ad4:	f556                	sd	s5,168(sp)
ffffffffc0200ad6:	f95a                	sd	s6,176(sp)
ffffffffc0200ad8:	fd5e                	sd	s7,184(sp)
ffffffffc0200ada:	e1e2                	sd	s8,192(sp)
ffffffffc0200adc:	e5e6                	sd	s9,200(sp)
ffffffffc0200ade:	e9ea                	sd	s10,208(sp)
ffffffffc0200ae0:	edee                	sd	s11,216(sp)
ffffffffc0200ae2:	f1f2                	sd	t3,224(sp)
ffffffffc0200ae4:	f5f6                	sd	t4,232(sp)
ffffffffc0200ae6:	f9fa                	sd	t5,240(sp)
ffffffffc0200ae8:	fdfe                	sd	t6,248(sp)
ffffffffc0200aea:	14002473          	csrr	s0,sscratch
ffffffffc0200aee:	100024f3          	csrr	s1,sstatus
ffffffffc0200af2:	14102973          	csrr	s2,sepc
ffffffffc0200af6:	143029f3          	csrr	s3,stval
ffffffffc0200afa:	14202a73          	csrr	s4,scause
ffffffffc0200afe:	e822                	sd	s0,16(sp)
ffffffffc0200b00:	e226                	sd	s1,256(sp)
ffffffffc0200b02:	e64a                	sd	s2,264(sp)
ffffffffc0200b04:	ea4e                	sd	s3,272(sp)
ffffffffc0200b06:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b08:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b0a:	f93ff0ef          	jal	ffffffffc0200a9c <trap>

ffffffffc0200b0e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b0e:	6492                	ld	s1,256(sp)
ffffffffc0200b10:	6932                	ld	s2,264(sp)
ffffffffc0200b12:	10049073          	csrw	sstatus,s1
ffffffffc0200b16:	14191073          	csrw	sepc,s2
ffffffffc0200b1a:	60a2                	ld	ra,8(sp)
ffffffffc0200b1c:	61e2                	ld	gp,24(sp)
ffffffffc0200b1e:	7202                	ld	tp,32(sp)
ffffffffc0200b20:	72a2                	ld	t0,40(sp)
ffffffffc0200b22:	7342                	ld	t1,48(sp)
ffffffffc0200b24:	73e2                	ld	t2,56(sp)
ffffffffc0200b26:	6406                	ld	s0,64(sp)
ffffffffc0200b28:	64a6                	ld	s1,72(sp)
ffffffffc0200b2a:	6546                	ld	a0,80(sp)
ffffffffc0200b2c:	65e6                	ld	a1,88(sp)
ffffffffc0200b2e:	7606                	ld	a2,96(sp)
ffffffffc0200b30:	76a6                	ld	a3,104(sp)
ffffffffc0200b32:	7746                	ld	a4,112(sp)
ffffffffc0200b34:	77e6                	ld	a5,120(sp)
ffffffffc0200b36:	680a                	ld	a6,128(sp)
ffffffffc0200b38:	68aa                	ld	a7,136(sp)
ffffffffc0200b3a:	694a                	ld	s2,144(sp)
ffffffffc0200b3c:	69ea                	ld	s3,152(sp)
ffffffffc0200b3e:	7a0a                	ld	s4,160(sp)
ffffffffc0200b40:	7aaa                	ld	s5,168(sp)
ffffffffc0200b42:	7b4a                	ld	s6,176(sp)
ffffffffc0200b44:	7bea                	ld	s7,184(sp)
ffffffffc0200b46:	6c0e                	ld	s8,192(sp)
ffffffffc0200b48:	6cae                	ld	s9,200(sp)
ffffffffc0200b4a:	6d4e                	ld	s10,208(sp)
ffffffffc0200b4c:	6dee                	ld	s11,216(sp)
ffffffffc0200b4e:	7e0e                	ld	t3,224(sp)
ffffffffc0200b50:	7eae                	ld	t4,232(sp)
ffffffffc0200b52:	7f4e                	ld	t5,240(sp)
ffffffffc0200b54:	7fee                	ld	t6,248(sp)
ffffffffc0200b56:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b58:	10200073          	sret

ffffffffc0200b5c <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b5c:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b5e:	bf45                	j	ffffffffc0200b0e <__trapret>
	...

ffffffffc0200b62 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b62:	00012797          	auipc	a5,0x12
ffffffffc0200b66:	8fe78793          	add	a5,a5,-1794 # ffffffffc0212460 <free_area>
ffffffffc0200b6a:	e79c                	sd	a5,8(a5)
ffffffffc0200b6c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b72:	8082                	ret

ffffffffc0200b74 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b74:	00012517          	auipc	a0,0x12
ffffffffc0200b78:	8fc56503          	lwu	a0,-1796(a0) # ffffffffc0212470 <free_area+0x10>
ffffffffc0200b7c:	8082                	ret

ffffffffc0200b7e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200b7e:	715d                	add	sp,sp,-80
ffffffffc0200b80:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b82:	00012417          	auipc	s0,0x12
ffffffffc0200b86:	8de40413          	add	s0,s0,-1826 # ffffffffc0212460 <free_area>
ffffffffc0200b8a:	641c                	ld	a5,8(s0)
ffffffffc0200b8c:	e486                	sd	ra,72(sp)
ffffffffc0200b8e:	fc26                	sd	s1,56(sp)
ffffffffc0200b90:	f84a                	sd	s2,48(sp)
ffffffffc0200b92:	f44e                	sd	s3,40(sp)
ffffffffc0200b94:	f052                	sd	s4,32(sp)
ffffffffc0200b96:	ec56                	sd	s5,24(sp)
ffffffffc0200b98:	e85a                	sd	s6,16(sp)
ffffffffc0200b9a:	e45e                	sd	s7,8(sp)
ffffffffc0200b9c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b9e:	2a878d63          	beq	a5,s0,ffffffffc0200e58 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200ba2:	4481                	li	s1,0
ffffffffc0200ba4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ba6:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200baa:	8b09                	and	a4,a4,2
ffffffffc0200bac:	2a070a63          	beqz	a4,ffffffffc0200e60 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200bb0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bb4:	679c                	ld	a5,8(a5)
ffffffffc0200bb6:	2905                	addw	s2,s2,1
ffffffffc0200bb8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bba:	fe8796e3          	bne	a5,s0,ffffffffc0200ba6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200bbe:	89a6                	mv	s3,s1
ffffffffc0200bc0:	711000ef          	jal	ffffffffc0201ad0 <nr_free_pages>
ffffffffc0200bc4:	6f351e63          	bne	a0,s3,ffffffffc02012c0 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bc8:	4505                	li	a0,1
ffffffffc0200bca:	637000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200bce:	8aaa                	mv	s5,a0
ffffffffc0200bd0:	42050863          	beqz	a0,ffffffffc0201000 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200bd4:	4505                	li	a0,1
ffffffffc0200bd6:	62b000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200bda:	89aa                	mv	s3,a0
ffffffffc0200bdc:	70050263          	beqz	a0,ffffffffc02012e0 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200be0:	4505                	li	a0,1
ffffffffc0200be2:	61f000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200be6:	8a2a                	mv	s4,a0
ffffffffc0200be8:	48050c63          	beqz	a0,ffffffffc0201080 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200bec:	293a8a63          	beq	s5,s3,ffffffffc0200e80 <default_check+0x302>
ffffffffc0200bf0:	28aa8863          	beq	s5,a0,ffffffffc0200e80 <default_check+0x302>
ffffffffc0200bf4:	28a98663          	beq	s3,a0,ffffffffc0200e80 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bf8:	000aa783          	lw	a5,0(s5)
ffffffffc0200bfc:	2a079263          	bnez	a5,ffffffffc0200ea0 <default_check+0x322>
ffffffffc0200c00:	0009a783          	lw	a5,0(s3)
ffffffffc0200c04:	28079e63          	bnez	a5,ffffffffc0200ea0 <default_check+0x322>
ffffffffc0200c08:	411c                	lw	a5,0(a0)
ffffffffc0200c0a:	28079b63          	bnez	a5,ffffffffc0200ea0 <default_check+0x322>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200c0e:	00016797          	auipc	a5,0x16
ffffffffc0200c12:	9727b783          	ld	a5,-1678(a5) # ffffffffc0216580 <pages>
ffffffffc0200c16:	40fa8733          	sub	a4,s5,a5
ffffffffc0200c1a:	00006617          	auipc	a2,0x6
ffffffffc0200c1e:	40e63603          	ld	a2,1038(a2) # ffffffffc0207028 <nbase>
ffffffffc0200c22:	8719                	sra	a4,a4,0x6
ffffffffc0200c24:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c26:	00016697          	auipc	a3,0x16
ffffffffc0200c2a:	9526b683          	ld	a3,-1710(a3) # ffffffffc0216578 <npage>
ffffffffc0200c2e:	06b2                	sll	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c30:	0732                	sll	a4,a4,0xc
ffffffffc0200c32:	28d77763          	bgeu	a4,a3,ffffffffc0200ec0 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200c36:	40f98733          	sub	a4,s3,a5
ffffffffc0200c3a:	8719                	sra	a4,a4,0x6
ffffffffc0200c3c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c3e:	0732                	sll	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c40:	4cd77063          	bgeu	a4,a3,ffffffffc0201100 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200c44:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c48:	8799                	sra	a5,a5,0x6
ffffffffc0200c4a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c4c:	07b2                	sll	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c4e:	30d7f963          	bgeu	a5,a3,ffffffffc0200f60 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200c52:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c54:	00043c03          	ld	s8,0(s0)
ffffffffc0200c58:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200c5c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200c60:	e400                	sd	s0,8(s0)
ffffffffc0200c62:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200c64:	00012797          	auipc	a5,0x12
ffffffffc0200c68:	8007a623          	sw	zero,-2036(a5) # ffffffffc0212470 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c6c:	595000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200c70:	2c051863          	bnez	a0,ffffffffc0200f40 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200c74:	4585                	li	a1,1
ffffffffc0200c76:	8556                	mv	a0,s5
ffffffffc0200c78:	619000ef          	jal	ffffffffc0201a90 <free_pages>
    free_page(p1);
ffffffffc0200c7c:	4585                	li	a1,1
ffffffffc0200c7e:	854e                	mv	a0,s3
ffffffffc0200c80:	611000ef          	jal	ffffffffc0201a90 <free_pages>
    free_page(p2);
ffffffffc0200c84:	4585                	li	a1,1
ffffffffc0200c86:	8552                	mv	a0,s4
ffffffffc0200c88:	609000ef          	jal	ffffffffc0201a90 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c8c:	4818                	lw	a4,16(s0)
ffffffffc0200c8e:	478d                	li	a5,3
ffffffffc0200c90:	28f71863          	bne	a4,a5,ffffffffc0200f20 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c94:	4505                	li	a0,1
ffffffffc0200c96:	56b000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200c9a:	89aa                	mv	s3,a0
ffffffffc0200c9c:	26050263          	beqz	a0,ffffffffc0200f00 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ca0:	4505                	li	a0,1
ffffffffc0200ca2:	55f000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200ca6:	8aaa                	mv	s5,a0
ffffffffc0200ca8:	3a050c63          	beqz	a0,ffffffffc0201060 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cac:	4505                	li	a0,1
ffffffffc0200cae:	553000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200cb2:	8a2a                	mv	s4,a0
ffffffffc0200cb4:	38050663          	beqz	a0,ffffffffc0201040 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200cb8:	4505                	li	a0,1
ffffffffc0200cba:	547000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200cbe:	36051163          	bnez	a0,ffffffffc0201020 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200cc2:	4585                	li	a1,1
ffffffffc0200cc4:	854e                	mv	a0,s3
ffffffffc0200cc6:	5cb000ef          	jal	ffffffffc0201a90 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200cca:	641c                	ld	a5,8(s0)
ffffffffc0200ccc:	20878a63          	beq	a5,s0,ffffffffc0200ee0 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200cd0:	4505                	li	a0,1
ffffffffc0200cd2:	52f000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200cd6:	30a99563          	bne	s3,a0,ffffffffc0200fe0 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200cda:	4505                	li	a0,1
ffffffffc0200cdc:	525000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200ce0:	2e051063          	bnez	a0,ffffffffc0200fc0 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200ce4:	481c                	lw	a5,16(s0)
ffffffffc0200ce6:	2a079d63          	bnez	a5,ffffffffc0200fa0 <default_check+0x422>
    free_page(p);
ffffffffc0200cea:	854e                	mv	a0,s3
ffffffffc0200cec:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200cee:	01843023          	sd	s8,0(s0)
ffffffffc0200cf2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200cf6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200cfa:	597000ef          	jal	ffffffffc0201a90 <free_pages>
    free_page(p1);
ffffffffc0200cfe:	4585                	li	a1,1
ffffffffc0200d00:	8556                	mv	a0,s5
ffffffffc0200d02:	58f000ef          	jal	ffffffffc0201a90 <free_pages>
    free_page(p2);
ffffffffc0200d06:	4585                	li	a1,1
ffffffffc0200d08:	8552                	mv	a0,s4
ffffffffc0200d0a:	587000ef          	jal	ffffffffc0201a90 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200d0e:	4515                	li	a0,5
ffffffffc0200d10:	4f1000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200d14:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d16:	26050563          	beqz	a0,ffffffffc0200f80 <default_check+0x402>
ffffffffc0200d1a:	651c                	ld	a5,8(a0)
ffffffffc0200d1c:	8385                	srl	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200d1e:	8b85                	and	a5,a5,1
ffffffffc0200d20:	54079063          	bnez	a5,ffffffffc0201260 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200d24:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d26:	00043b03          	ld	s6,0(s0)
ffffffffc0200d2a:	00843a83          	ld	s5,8(s0)
ffffffffc0200d2e:	e000                	sd	s0,0(s0)
ffffffffc0200d30:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200d32:	4cf000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200d36:	50051563          	bnez	a0,ffffffffc0201240 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200d3a:	08098a13          	add	s4,s3,128
ffffffffc0200d3e:	8552                	mv	a0,s4
ffffffffc0200d40:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d42:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200d46:	00011797          	auipc	a5,0x11
ffffffffc0200d4a:	7207a523          	sw	zero,1834(a5) # ffffffffc0212470 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d4e:	543000ef          	jal	ffffffffc0201a90 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d52:	4511                	li	a0,4
ffffffffc0200d54:	4ad000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200d58:	4c051463          	bnez	a0,ffffffffc0201220 <default_check+0x6a2>
ffffffffc0200d5c:	0889b783          	ld	a5,136(s3)
ffffffffc0200d60:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d62:	8b85                	and	a5,a5,1
ffffffffc0200d64:	48078e63          	beqz	a5,ffffffffc0201200 <default_check+0x682>
ffffffffc0200d68:	0909a703          	lw	a4,144(s3)
ffffffffc0200d6c:	478d                	li	a5,3
ffffffffc0200d6e:	48f71963          	bne	a4,a5,ffffffffc0201200 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d72:	450d                	li	a0,3
ffffffffc0200d74:	48d000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200d78:	8c2a                	mv	s8,a0
ffffffffc0200d7a:	46050363          	beqz	a0,ffffffffc02011e0 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200d7e:	4505                	li	a0,1
ffffffffc0200d80:	481000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200d84:	42051e63          	bnez	a0,ffffffffc02011c0 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200d88:	418a1c63          	bne	s4,s8,ffffffffc02011a0 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d8c:	4585                	li	a1,1
ffffffffc0200d8e:	854e                	mv	a0,s3
ffffffffc0200d90:	501000ef          	jal	ffffffffc0201a90 <free_pages>
    free_pages(p1, 3);
ffffffffc0200d94:	458d                	li	a1,3
ffffffffc0200d96:	8552                	mv	a0,s4
ffffffffc0200d98:	4f9000ef          	jal	ffffffffc0201a90 <free_pages>
ffffffffc0200d9c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200da0:	04098c13          	add	s8,s3,64
ffffffffc0200da4:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200da6:	8b85                	and	a5,a5,1
ffffffffc0200da8:	3c078c63          	beqz	a5,ffffffffc0201180 <default_check+0x602>
ffffffffc0200dac:	0109a703          	lw	a4,16(s3)
ffffffffc0200db0:	4785                	li	a5,1
ffffffffc0200db2:	3cf71763          	bne	a4,a5,ffffffffc0201180 <default_check+0x602>
ffffffffc0200db6:	008a3783          	ld	a5,8(s4)
ffffffffc0200dba:	8385                	srl	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200dbc:	8b85                	and	a5,a5,1
ffffffffc0200dbe:	3a078163          	beqz	a5,ffffffffc0201160 <default_check+0x5e2>
ffffffffc0200dc2:	010a2703          	lw	a4,16(s4)
ffffffffc0200dc6:	478d                	li	a5,3
ffffffffc0200dc8:	38f71c63          	bne	a4,a5,ffffffffc0201160 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200dcc:	4505                	li	a0,1
ffffffffc0200dce:	433000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200dd2:	36a99763          	bne	s3,a0,ffffffffc0201140 <default_check+0x5c2>
    free_page(p0);
ffffffffc0200dd6:	4585                	li	a1,1
ffffffffc0200dd8:	4b9000ef          	jal	ffffffffc0201a90 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200ddc:	4509                	li	a0,2
ffffffffc0200dde:	423000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200de2:	32aa1f63          	bne	s4,a0,ffffffffc0201120 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0200de6:	4589                	li	a1,2
ffffffffc0200de8:	4a9000ef          	jal	ffffffffc0201a90 <free_pages>
    free_page(p2);
ffffffffc0200dec:	4585                	li	a1,1
ffffffffc0200dee:	8562                	mv	a0,s8
ffffffffc0200df0:	4a1000ef          	jal	ffffffffc0201a90 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200df4:	4515                	li	a0,5
ffffffffc0200df6:	40b000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200dfa:	89aa                	mv	s3,a0
ffffffffc0200dfc:	48050263          	beqz	a0,ffffffffc0201280 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0200e00:	4505                	li	a0,1
ffffffffc0200e02:	3ff000ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0200e06:	2c051d63          	bnez	a0,ffffffffc02010e0 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0200e0a:	481c                	lw	a5,16(s0)
ffffffffc0200e0c:	2a079a63          	bnez	a5,ffffffffc02010c0 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e10:	4595                	li	a1,5
ffffffffc0200e12:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e14:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200e18:	01643023          	sd	s6,0(s0)
ffffffffc0200e1c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200e20:	471000ef          	jal	ffffffffc0201a90 <free_pages>
    return listelm->next;
ffffffffc0200e24:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e26:	00878963          	beq	a5,s0,ffffffffc0200e38 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200e2a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e2e:	679c                	ld	a5,8(a5)
ffffffffc0200e30:	397d                	addw	s2,s2,-1
ffffffffc0200e32:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e34:	fe879be3          	bne	a5,s0,ffffffffc0200e2a <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0200e38:	26091463          	bnez	s2,ffffffffc02010a0 <default_check+0x522>
    assert(total == 0);
ffffffffc0200e3c:	46049263          	bnez	s1,ffffffffc02012a0 <default_check+0x722>
}
ffffffffc0200e40:	60a6                	ld	ra,72(sp)
ffffffffc0200e42:	6406                	ld	s0,64(sp)
ffffffffc0200e44:	74e2                	ld	s1,56(sp)
ffffffffc0200e46:	7942                	ld	s2,48(sp)
ffffffffc0200e48:	79a2                	ld	s3,40(sp)
ffffffffc0200e4a:	7a02                	ld	s4,32(sp)
ffffffffc0200e4c:	6ae2                	ld	s5,24(sp)
ffffffffc0200e4e:	6b42                	ld	s6,16(sp)
ffffffffc0200e50:	6ba2                	ld	s7,8(sp)
ffffffffc0200e52:	6c02                	ld	s8,0(sp)
ffffffffc0200e54:	6161                	add	sp,sp,80
ffffffffc0200e56:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e58:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e5a:	4481                	li	s1,0
ffffffffc0200e5c:	4901                	li	s2,0
ffffffffc0200e5e:	b38d                	j	ffffffffc0200bc0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200e60:	00005697          	auipc	a3,0x5
ffffffffc0200e64:	9c068693          	add	a3,a3,-1600 # ffffffffc0205820 <etext+0x8e6>
ffffffffc0200e68:	00005617          	auipc	a2,0x5
ffffffffc0200e6c:	9c860613          	add	a2,a2,-1592 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200e70:	0f000593          	li	a1,240
ffffffffc0200e74:	00005517          	auipc	a0,0x5
ffffffffc0200e78:	9d450513          	add	a0,a0,-1580 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200e7c:	db6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e80:	00005697          	auipc	a3,0x5
ffffffffc0200e84:	a6068693          	add	a3,a3,-1440 # ffffffffc02058e0 <etext+0x9a6>
ffffffffc0200e88:	00005617          	auipc	a2,0x5
ffffffffc0200e8c:	9a860613          	add	a2,a2,-1624 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200e90:	0bd00593          	li	a1,189
ffffffffc0200e94:	00005517          	auipc	a0,0x5
ffffffffc0200e98:	9b450513          	add	a0,a0,-1612 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200e9c:	d96ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ea0:	00005697          	auipc	a3,0x5
ffffffffc0200ea4:	a6868693          	add	a3,a3,-1432 # ffffffffc0205908 <etext+0x9ce>
ffffffffc0200ea8:	00005617          	auipc	a2,0x5
ffffffffc0200eac:	98860613          	add	a2,a2,-1656 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200eb0:	0be00593          	li	a1,190
ffffffffc0200eb4:	00005517          	auipc	a0,0x5
ffffffffc0200eb8:	99450513          	add	a0,a0,-1644 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200ebc:	d76ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ec0:	00005697          	auipc	a3,0x5
ffffffffc0200ec4:	a8868693          	add	a3,a3,-1400 # ffffffffc0205948 <etext+0xa0e>
ffffffffc0200ec8:	00005617          	auipc	a2,0x5
ffffffffc0200ecc:	96860613          	add	a2,a2,-1688 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200ed0:	0c000593          	li	a1,192
ffffffffc0200ed4:	00005517          	auipc	a0,0x5
ffffffffc0200ed8:	97450513          	add	a0,a0,-1676 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200edc:	d56ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200ee0:	00005697          	auipc	a3,0x5
ffffffffc0200ee4:	af068693          	add	a3,a3,-1296 # ffffffffc02059d0 <etext+0xa96>
ffffffffc0200ee8:	00005617          	auipc	a2,0x5
ffffffffc0200eec:	94860613          	add	a2,a2,-1720 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200ef0:	0d900593          	li	a1,217
ffffffffc0200ef4:	00005517          	auipc	a0,0x5
ffffffffc0200ef8:	95450513          	add	a0,a0,-1708 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200efc:	d36ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f00:	00005697          	auipc	a3,0x5
ffffffffc0200f04:	98068693          	add	a3,a3,-1664 # ffffffffc0205880 <etext+0x946>
ffffffffc0200f08:	00005617          	auipc	a2,0x5
ffffffffc0200f0c:	92860613          	add	a2,a2,-1752 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200f10:	0d200593          	li	a1,210
ffffffffc0200f14:	00005517          	auipc	a0,0x5
ffffffffc0200f18:	93450513          	add	a0,a0,-1740 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200f1c:	d16ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free == 3);
ffffffffc0200f20:	00005697          	auipc	a3,0x5
ffffffffc0200f24:	aa068693          	add	a3,a3,-1376 # ffffffffc02059c0 <etext+0xa86>
ffffffffc0200f28:	00005617          	auipc	a2,0x5
ffffffffc0200f2c:	90860613          	add	a2,a2,-1784 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200f30:	0d000593          	li	a1,208
ffffffffc0200f34:	00005517          	auipc	a0,0x5
ffffffffc0200f38:	91450513          	add	a0,a0,-1772 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200f3c:	cf6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f40:	00005697          	auipc	a3,0x5
ffffffffc0200f44:	a6868693          	add	a3,a3,-1432 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc0200f48:	00005617          	auipc	a2,0x5
ffffffffc0200f4c:	8e860613          	add	a2,a2,-1816 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200f50:	0cb00593          	li	a1,203
ffffffffc0200f54:	00005517          	auipc	a0,0x5
ffffffffc0200f58:	8f450513          	add	a0,a0,-1804 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200f5c:	cd6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f60:	00005697          	auipc	a3,0x5
ffffffffc0200f64:	a2868693          	add	a3,a3,-1496 # ffffffffc0205988 <etext+0xa4e>
ffffffffc0200f68:	00005617          	auipc	a2,0x5
ffffffffc0200f6c:	8c860613          	add	a2,a2,-1848 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200f70:	0c200593          	li	a1,194
ffffffffc0200f74:	00005517          	auipc	a0,0x5
ffffffffc0200f78:	8d450513          	add	a0,a0,-1836 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200f7c:	cb6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(p0 != NULL);
ffffffffc0200f80:	00005697          	auipc	a3,0x5
ffffffffc0200f84:	a9868693          	add	a3,a3,-1384 # ffffffffc0205a18 <etext+0xade>
ffffffffc0200f88:	00005617          	auipc	a2,0x5
ffffffffc0200f8c:	8a860613          	add	a2,a2,-1880 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200f90:	0f800593          	li	a1,248
ffffffffc0200f94:	00005517          	auipc	a0,0x5
ffffffffc0200f98:	8b450513          	add	a0,a0,-1868 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200f9c:	c96ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free == 0);
ffffffffc0200fa0:	00005697          	auipc	a3,0x5
ffffffffc0200fa4:	a6868693          	add	a3,a3,-1432 # ffffffffc0205a08 <etext+0xace>
ffffffffc0200fa8:	00005617          	auipc	a2,0x5
ffffffffc0200fac:	88860613          	add	a2,a2,-1912 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200fb0:	0df00593          	li	a1,223
ffffffffc0200fb4:	00005517          	auipc	a0,0x5
ffffffffc0200fb8:	89450513          	add	a0,a0,-1900 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200fbc:	c76ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fc0:	00005697          	auipc	a3,0x5
ffffffffc0200fc4:	9e868693          	add	a3,a3,-1560 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc0200fc8:	00005617          	auipc	a2,0x5
ffffffffc0200fcc:	86860613          	add	a2,a2,-1944 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200fd0:	0dd00593          	li	a1,221
ffffffffc0200fd4:	00005517          	auipc	a0,0x5
ffffffffc0200fd8:	87450513          	add	a0,a0,-1932 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200fdc:	c56ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200fe0:	00005697          	auipc	a3,0x5
ffffffffc0200fe4:	a0868693          	add	a3,a3,-1528 # ffffffffc02059e8 <etext+0xaae>
ffffffffc0200fe8:	00005617          	auipc	a2,0x5
ffffffffc0200fec:	84860613          	add	a2,a2,-1976 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0200ff0:	0dc00593          	li	a1,220
ffffffffc0200ff4:	00005517          	auipc	a0,0x5
ffffffffc0200ff8:	85450513          	add	a0,a0,-1964 # ffffffffc0205848 <etext+0x90e>
ffffffffc0200ffc:	c36ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201000:	00005697          	auipc	a3,0x5
ffffffffc0201004:	88068693          	add	a3,a3,-1920 # ffffffffc0205880 <etext+0x946>
ffffffffc0201008:	00005617          	auipc	a2,0x5
ffffffffc020100c:	82860613          	add	a2,a2,-2008 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201010:	0b900593          	li	a1,185
ffffffffc0201014:	00005517          	auipc	a0,0x5
ffffffffc0201018:	83450513          	add	a0,a0,-1996 # ffffffffc0205848 <etext+0x90e>
ffffffffc020101c:	c16ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201020:	00005697          	auipc	a3,0x5
ffffffffc0201024:	98868693          	add	a3,a3,-1656 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc0201028:	00005617          	auipc	a2,0x5
ffffffffc020102c:	80860613          	add	a2,a2,-2040 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201030:	0d600593          	li	a1,214
ffffffffc0201034:	00005517          	auipc	a0,0x5
ffffffffc0201038:	81450513          	add	a0,a0,-2028 # ffffffffc0205848 <etext+0x90e>
ffffffffc020103c:	bf6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201040:	00005697          	auipc	a3,0x5
ffffffffc0201044:	88068693          	add	a3,a3,-1920 # ffffffffc02058c0 <etext+0x986>
ffffffffc0201048:	00004617          	auipc	a2,0x4
ffffffffc020104c:	7e860613          	add	a2,a2,2024 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201050:	0d400593          	li	a1,212
ffffffffc0201054:	00004517          	auipc	a0,0x4
ffffffffc0201058:	7f450513          	add	a0,a0,2036 # ffffffffc0205848 <etext+0x90e>
ffffffffc020105c:	bd6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201060:	00005697          	auipc	a3,0x5
ffffffffc0201064:	84068693          	add	a3,a3,-1984 # ffffffffc02058a0 <etext+0x966>
ffffffffc0201068:	00004617          	auipc	a2,0x4
ffffffffc020106c:	7c860613          	add	a2,a2,1992 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201070:	0d300593          	li	a1,211
ffffffffc0201074:	00004517          	auipc	a0,0x4
ffffffffc0201078:	7d450513          	add	a0,a0,2004 # ffffffffc0205848 <etext+0x90e>
ffffffffc020107c:	bb6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201080:	00005697          	auipc	a3,0x5
ffffffffc0201084:	84068693          	add	a3,a3,-1984 # ffffffffc02058c0 <etext+0x986>
ffffffffc0201088:	00004617          	auipc	a2,0x4
ffffffffc020108c:	7a860613          	add	a2,a2,1960 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201090:	0bb00593          	li	a1,187
ffffffffc0201094:	00004517          	auipc	a0,0x4
ffffffffc0201098:	7b450513          	add	a0,a0,1972 # ffffffffc0205848 <etext+0x90e>
ffffffffc020109c:	b96ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(count == 0);
ffffffffc02010a0:	00005697          	auipc	a3,0x5
ffffffffc02010a4:	ac868693          	add	a3,a3,-1336 # ffffffffc0205b68 <etext+0xc2e>
ffffffffc02010a8:	00004617          	auipc	a2,0x4
ffffffffc02010ac:	78860613          	add	a2,a2,1928 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02010b0:	12500593          	li	a1,293
ffffffffc02010b4:	00004517          	auipc	a0,0x4
ffffffffc02010b8:	79450513          	add	a0,a0,1940 # ffffffffc0205848 <etext+0x90e>
ffffffffc02010bc:	b76ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free == 0);
ffffffffc02010c0:	00005697          	auipc	a3,0x5
ffffffffc02010c4:	94868693          	add	a3,a3,-1720 # ffffffffc0205a08 <etext+0xace>
ffffffffc02010c8:	00004617          	auipc	a2,0x4
ffffffffc02010cc:	76860613          	add	a2,a2,1896 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02010d0:	11a00593          	li	a1,282
ffffffffc02010d4:	00004517          	auipc	a0,0x4
ffffffffc02010d8:	77450513          	add	a0,a0,1908 # ffffffffc0205848 <etext+0x90e>
ffffffffc02010dc:	b56ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010e0:	00005697          	auipc	a3,0x5
ffffffffc02010e4:	8c868693          	add	a3,a3,-1848 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc02010e8:	00004617          	auipc	a2,0x4
ffffffffc02010ec:	74860613          	add	a2,a2,1864 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02010f0:	11800593          	li	a1,280
ffffffffc02010f4:	00004517          	auipc	a0,0x4
ffffffffc02010f8:	75450513          	add	a0,a0,1876 # ffffffffc0205848 <etext+0x90e>
ffffffffc02010fc:	b36ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201100:	00005697          	auipc	a3,0x5
ffffffffc0201104:	86868693          	add	a3,a3,-1944 # ffffffffc0205968 <etext+0xa2e>
ffffffffc0201108:	00004617          	auipc	a2,0x4
ffffffffc020110c:	72860613          	add	a2,a2,1832 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201110:	0c100593          	li	a1,193
ffffffffc0201114:	00004517          	auipc	a0,0x4
ffffffffc0201118:	73450513          	add	a0,a0,1844 # ffffffffc0205848 <etext+0x90e>
ffffffffc020111c:	b16ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201120:	00005697          	auipc	a3,0x5
ffffffffc0201124:	a0868693          	add	a3,a3,-1528 # ffffffffc0205b28 <etext+0xbee>
ffffffffc0201128:	00004617          	auipc	a2,0x4
ffffffffc020112c:	70860613          	add	a2,a2,1800 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201130:	11200593          	li	a1,274
ffffffffc0201134:	00004517          	auipc	a0,0x4
ffffffffc0201138:	71450513          	add	a0,a0,1812 # ffffffffc0205848 <etext+0x90e>
ffffffffc020113c:	af6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201140:	00005697          	auipc	a3,0x5
ffffffffc0201144:	9c868693          	add	a3,a3,-1592 # ffffffffc0205b08 <etext+0xbce>
ffffffffc0201148:	00004617          	auipc	a2,0x4
ffffffffc020114c:	6e860613          	add	a2,a2,1768 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201150:	11000593          	li	a1,272
ffffffffc0201154:	00004517          	auipc	a0,0x4
ffffffffc0201158:	6f450513          	add	a0,a0,1780 # ffffffffc0205848 <etext+0x90e>
ffffffffc020115c:	ad6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201160:	00005697          	auipc	a3,0x5
ffffffffc0201164:	98068693          	add	a3,a3,-1664 # ffffffffc0205ae0 <etext+0xba6>
ffffffffc0201168:	00004617          	auipc	a2,0x4
ffffffffc020116c:	6c860613          	add	a2,a2,1736 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201170:	10e00593          	li	a1,270
ffffffffc0201174:	00004517          	auipc	a0,0x4
ffffffffc0201178:	6d450513          	add	a0,a0,1748 # ffffffffc0205848 <etext+0x90e>
ffffffffc020117c:	ab6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201180:	00005697          	auipc	a3,0x5
ffffffffc0201184:	93868693          	add	a3,a3,-1736 # ffffffffc0205ab8 <etext+0xb7e>
ffffffffc0201188:	00004617          	auipc	a2,0x4
ffffffffc020118c:	6a860613          	add	a2,a2,1704 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201190:	10d00593          	li	a1,269
ffffffffc0201194:	00004517          	auipc	a0,0x4
ffffffffc0201198:	6b450513          	add	a0,a0,1716 # ffffffffc0205848 <etext+0x90e>
ffffffffc020119c:	a96ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02011a0:	00005697          	auipc	a3,0x5
ffffffffc02011a4:	90868693          	add	a3,a3,-1784 # ffffffffc0205aa8 <etext+0xb6e>
ffffffffc02011a8:	00004617          	auipc	a2,0x4
ffffffffc02011ac:	68860613          	add	a2,a2,1672 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02011b0:	10800593          	li	a1,264
ffffffffc02011b4:	00004517          	auipc	a0,0x4
ffffffffc02011b8:	69450513          	add	a0,a0,1684 # ffffffffc0205848 <etext+0x90e>
ffffffffc02011bc:	a76ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011c0:	00004697          	auipc	a3,0x4
ffffffffc02011c4:	7e868693          	add	a3,a3,2024 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc02011c8:	00004617          	auipc	a2,0x4
ffffffffc02011cc:	66860613          	add	a2,a2,1640 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02011d0:	10700593          	li	a1,263
ffffffffc02011d4:	00004517          	auipc	a0,0x4
ffffffffc02011d8:	67450513          	add	a0,a0,1652 # ffffffffc0205848 <etext+0x90e>
ffffffffc02011dc:	a56ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011e0:	00005697          	auipc	a3,0x5
ffffffffc02011e4:	8a868693          	add	a3,a3,-1880 # ffffffffc0205a88 <etext+0xb4e>
ffffffffc02011e8:	00004617          	auipc	a2,0x4
ffffffffc02011ec:	64860613          	add	a2,a2,1608 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02011f0:	10600593          	li	a1,262
ffffffffc02011f4:	00004517          	auipc	a0,0x4
ffffffffc02011f8:	65450513          	add	a0,a0,1620 # ffffffffc0205848 <etext+0x90e>
ffffffffc02011fc:	a36ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201200:	00005697          	auipc	a3,0x5
ffffffffc0201204:	85868693          	add	a3,a3,-1960 # ffffffffc0205a58 <etext+0xb1e>
ffffffffc0201208:	00004617          	auipc	a2,0x4
ffffffffc020120c:	62860613          	add	a2,a2,1576 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201210:	10500593          	li	a1,261
ffffffffc0201214:	00004517          	auipc	a0,0x4
ffffffffc0201218:	63450513          	add	a0,a0,1588 # ffffffffc0205848 <etext+0x90e>
ffffffffc020121c:	a16ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201220:	00005697          	auipc	a3,0x5
ffffffffc0201224:	82068693          	add	a3,a3,-2016 # ffffffffc0205a40 <etext+0xb06>
ffffffffc0201228:	00004617          	auipc	a2,0x4
ffffffffc020122c:	60860613          	add	a2,a2,1544 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201230:	10400593          	li	a1,260
ffffffffc0201234:	00004517          	auipc	a0,0x4
ffffffffc0201238:	61450513          	add	a0,a0,1556 # ffffffffc0205848 <etext+0x90e>
ffffffffc020123c:	9f6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201240:	00004697          	auipc	a3,0x4
ffffffffc0201244:	76868693          	add	a3,a3,1896 # ffffffffc02059a8 <etext+0xa6e>
ffffffffc0201248:	00004617          	auipc	a2,0x4
ffffffffc020124c:	5e860613          	add	a2,a2,1512 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201250:	0fe00593          	li	a1,254
ffffffffc0201254:	00004517          	auipc	a0,0x4
ffffffffc0201258:	5f450513          	add	a0,a0,1524 # ffffffffc0205848 <etext+0x90e>
ffffffffc020125c:	9d6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201260:	00004697          	auipc	a3,0x4
ffffffffc0201264:	7c868693          	add	a3,a3,1992 # ffffffffc0205a28 <etext+0xaee>
ffffffffc0201268:	00004617          	auipc	a2,0x4
ffffffffc020126c:	5c860613          	add	a2,a2,1480 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201270:	0f900593          	li	a1,249
ffffffffc0201274:	00004517          	auipc	a0,0x4
ffffffffc0201278:	5d450513          	add	a0,a0,1492 # ffffffffc0205848 <etext+0x90e>
ffffffffc020127c:	9b6ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201280:	00005697          	auipc	a3,0x5
ffffffffc0201284:	8c868693          	add	a3,a3,-1848 # ffffffffc0205b48 <etext+0xc0e>
ffffffffc0201288:	00004617          	auipc	a2,0x4
ffffffffc020128c:	5a860613          	add	a2,a2,1448 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201290:	11700593          	li	a1,279
ffffffffc0201294:	00004517          	auipc	a0,0x4
ffffffffc0201298:	5b450513          	add	a0,a0,1460 # ffffffffc0205848 <etext+0x90e>
ffffffffc020129c:	996ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(total == 0);
ffffffffc02012a0:	00005697          	auipc	a3,0x5
ffffffffc02012a4:	8d868693          	add	a3,a3,-1832 # ffffffffc0205b78 <etext+0xc3e>
ffffffffc02012a8:	00004617          	auipc	a2,0x4
ffffffffc02012ac:	58860613          	add	a2,a2,1416 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02012b0:	12600593          	li	a1,294
ffffffffc02012b4:	00004517          	auipc	a0,0x4
ffffffffc02012b8:	59450513          	add	a0,a0,1428 # ffffffffc0205848 <etext+0x90e>
ffffffffc02012bc:	976ff0ef          	jal	ffffffffc0200432 <__panic>
    assert(total == nr_free_pages());
ffffffffc02012c0:	00004697          	auipc	a3,0x4
ffffffffc02012c4:	5a068693          	add	a3,a3,1440 # ffffffffc0205860 <etext+0x926>
ffffffffc02012c8:	00004617          	auipc	a2,0x4
ffffffffc02012cc:	56860613          	add	a2,a2,1384 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02012d0:	0f300593          	li	a1,243
ffffffffc02012d4:	00004517          	auipc	a0,0x4
ffffffffc02012d8:	57450513          	add	a0,a0,1396 # ffffffffc0205848 <etext+0x90e>
ffffffffc02012dc:	956ff0ef          	jal	ffffffffc0200432 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012e0:	00004697          	auipc	a3,0x4
ffffffffc02012e4:	5c068693          	add	a3,a3,1472 # ffffffffc02058a0 <etext+0x966>
ffffffffc02012e8:	00004617          	auipc	a2,0x4
ffffffffc02012ec:	54860613          	add	a2,a2,1352 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02012f0:	0ba00593          	li	a1,186
ffffffffc02012f4:	00004517          	auipc	a0,0x4
ffffffffc02012f8:	55450513          	add	a0,a0,1364 # ffffffffc0205848 <etext+0x90e>
ffffffffc02012fc:	936ff0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201300 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201300:	1141                	add	sp,sp,-16
ffffffffc0201302:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201304:	14058463          	beqz	a1,ffffffffc020144c <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0201308:	00659713          	sll	a4,a1,0x6
ffffffffc020130c:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201310:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201312:	c30d                	beqz	a4,ffffffffc0201334 <default_free_pages+0x34>
ffffffffc0201314:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201316:	8b05                	and	a4,a4,1
ffffffffc0201318:	10071a63          	bnez	a4,ffffffffc020142c <default_free_pages+0x12c>
ffffffffc020131c:	6798                	ld	a4,8(a5)
ffffffffc020131e:	8b09                	and	a4,a4,2
ffffffffc0201320:	10071663          	bnez	a4,ffffffffc020142c <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0201324:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201328:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020132c:	04078793          	add	a5,a5,64
ffffffffc0201330:	fed792e3          	bne	a5,a3,ffffffffc0201314 <default_free_pages+0x14>
    base->property = n;
ffffffffc0201334:	2581                	sext.w	a1,a1
ffffffffc0201336:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201338:	00850893          	add	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020133c:	4789                	li	a5,2
ffffffffc020133e:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201342:	00011697          	auipc	a3,0x11
ffffffffc0201346:	11e68693          	add	a3,a3,286 # ffffffffc0212460 <free_area>
ffffffffc020134a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020134c:	669c                	ld	a5,8(a3)
ffffffffc020134e:	9f2d                	addw	a4,a4,a1
ffffffffc0201350:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201352:	0ad78163          	beq	a5,a3,ffffffffc02013f4 <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc0201356:	fe878713          	add	a4,a5,-24
ffffffffc020135a:	4581                	li	a1,0
ffffffffc020135c:	01850613          	add	a2,a0,24
            if (base < page) {
ffffffffc0201360:	00e56a63          	bltu	a0,a4,ffffffffc0201374 <default_free_pages+0x74>
    return listelm->next;
ffffffffc0201364:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201366:	04d70c63          	beq	a4,a3,ffffffffc02013be <default_free_pages+0xbe>
    struct Page *p = base;
ffffffffc020136a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020136c:	fe878713          	add	a4,a5,-24
            if (base < page) {
ffffffffc0201370:	fee57ae3          	bgeu	a0,a4,ffffffffc0201364 <default_free_pages+0x64>
ffffffffc0201374:	c199                	beqz	a1,ffffffffc020137a <default_free_pages+0x7a>
ffffffffc0201376:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020137a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020137c:	e390                	sd	a2,0(a5)
ffffffffc020137e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201380:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201382:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201384:	00d70d63          	beq	a4,a3,ffffffffc020139e <default_free_pages+0x9e>
        if (p + p->property == base) {
ffffffffc0201388:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020138c:	fe870613          	add	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201390:	02059813          	sll	a6,a1,0x20
ffffffffc0201394:	01a85793          	srl	a5,a6,0x1a
ffffffffc0201398:	97b2                	add	a5,a5,a2
ffffffffc020139a:	02f50c63          	beq	a0,a5,ffffffffc02013d2 <default_free_pages+0xd2>
    return listelm->next;
ffffffffc020139e:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02013a0:	00d78c63          	beq	a5,a3,ffffffffc02013b8 <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc02013a4:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02013a6:	fe878693          	add	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02013aa:	02061593          	sll	a1,a2,0x20
ffffffffc02013ae:	01a5d713          	srl	a4,a1,0x1a
ffffffffc02013b2:	972a                	add	a4,a4,a0
ffffffffc02013b4:	04e68c63          	beq	a3,a4,ffffffffc020140c <default_free_pages+0x10c>
}
ffffffffc02013b8:	60a2                	ld	ra,8(sp)
ffffffffc02013ba:	0141                	add	sp,sp,16
ffffffffc02013bc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02013be:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013c0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02013c2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013c4:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02013c6:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013c8:	02d70f63          	beq	a4,a3,ffffffffc0201406 <default_free_pages+0x106>
ffffffffc02013cc:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02013ce:	87ba                	mv	a5,a4
ffffffffc02013d0:	bf71                	j	ffffffffc020136c <default_free_pages+0x6c>
            p->property += base->property;
ffffffffc02013d2:	491c                	lw	a5,16(a0)
ffffffffc02013d4:	9fad                	addw	a5,a5,a1
ffffffffc02013d6:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013da:	57f5                	li	a5,-3
ffffffffc02013dc:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013e0:	01853803          	ld	a6,24(a0)
ffffffffc02013e4:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02013e6:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02013e8:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02013ec:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02013ee:	0105b023          	sd	a6,0(a1)
ffffffffc02013f2:	b77d                	j	ffffffffc02013a0 <default_free_pages+0xa0>
}
ffffffffc02013f4:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02013f6:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02013fa:	e398                	sd	a4,0(a5)
ffffffffc02013fc:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02013fe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201400:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201402:	0141                	add	sp,sp,16
ffffffffc0201404:	8082                	ret
ffffffffc0201406:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201408:	873e                	mv	a4,a5
ffffffffc020140a:	bfad                	j	ffffffffc0201384 <default_free_pages+0x84>
            base->property += p->property;
ffffffffc020140c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201410:	ff078693          	add	a3,a5,-16
ffffffffc0201414:	9f31                	addw	a4,a4,a2
ffffffffc0201416:	c918                	sw	a4,16(a0)
ffffffffc0201418:	5775                	li	a4,-3
ffffffffc020141a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020141e:	6398                	ld	a4,0(a5)
ffffffffc0201420:	679c                	ld	a5,8(a5)
}
ffffffffc0201422:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201424:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201426:	e398                	sd	a4,0(a5)
ffffffffc0201428:	0141                	add	sp,sp,16
ffffffffc020142a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020142c:	00004697          	auipc	a3,0x4
ffffffffc0201430:	76468693          	add	a3,a3,1892 # ffffffffc0205b90 <etext+0xc56>
ffffffffc0201434:	00004617          	auipc	a2,0x4
ffffffffc0201438:	3fc60613          	add	a2,a2,1020 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020143c:	08300593          	li	a1,131
ffffffffc0201440:	00004517          	auipc	a0,0x4
ffffffffc0201444:	40850513          	add	a0,a0,1032 # ffffffffc0205848 <etext+0x90e>
ffffffffc0201448:	febfe0ef          	jal	ffffffffc0200432 <__panic>
    assert(n > 0);
ffffffffc020144c:	00004697          	auipc	a3,0x4
ffffffffc0201450:	73c68693          	add	a3,a3,1852 # ffffffffc0205b88 <etext+0xc4e>
ffffffffc0201454:	00004617          	auipc	a2,0x4
ffffffffc0201458:	3dc60613          	add	a2,a2,988 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020145c:	08000593          	li	a1,128
ffffffffc0201460:	00004517          	auipc	a0,0x4
ffffffffc0201464:	3e850513          	add	a0,a0,1000 # ffffffffc0205848 <etext+0x90e>
ffffffffc0201468:	fcbfe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020146c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020146c:	c949                	beqz	a0,ffffffffc02014fe <default_alloc_pages+0x92>
    if (n > nr_free) {
ffffffffc020146e:	00011617          	auipc	a2,0x11
ffffffffc0201472:	ff260613          	add	a2,a2,-14 # ffffffffc0212460 <free_area>
ffffffffc0201476:	4a0c                	lw	a1,16(a2)
ffffffffc0201478:	872a                	mv	a4,a0
ffffffffc020147a:	02059793          	sll	a5,a1,0x20
ffffffffc020147e:	9381                	srl	a5,a5,0x20
ffffffffc0201480:	00a7eb63          	bltu	a5,a0,ffffffffc0201496 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201484:	87b2                	mv	a5,a2
ffffffffc0201486:	a029                	j	ffffffffc0201490 <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc0201488:	ff87e683          	lwu	a3,-8(a5)
ffffffffc020148c:	00e6f763          	bgeu	a3,a4,ffffffffc020149a <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc0201490:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201492:	fec79be3          	bne	a5,a2,ffffffffc0201488 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc0201496:	4501                	li	a0,0
}
ffffffffc0201498:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc020149a:	0087b883          	ld	a7,8(a5)
        if (page->property > n) {
ffffffffc020149e:	ff87a803          	lw	a6,-8(a5)
    return listelm->prev;
ffffffffc02014a2:	6394                	ld	a3,0(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02014a4:	fe878513          	add	a0,a5,-24
        if (page->property > n) {
ffffffffc02014a8:	02081313          	sll	t1,a6,0x20
    prev->next = next;
ffffffffc02014ac:	0116b423          	sd	a7,8(a3)
    next->prev = prev;
ffffffffc02014b0:	00d8b023          	sd	a3,0(a7)
ffffffffc02014b4:	02035313          	srl	t1,t1,0x20
            p->property = page->property - n;
ffffffffc02014b8:	0007089b          	sext.w	a7,a4
        if (page->property > n) {
ffffffffc02014bc:	02677963          	bgeu	a4,t1,ffffffffc02014ee <default_alloc_pages+0x82>
            struct Page *p = page + n;
ffffffffc02014c0:	071a                	sll	a4,a4,0x6
ffffffffc02014c2:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02014c4:	4118083b          	subw	a6,a6,a7
ffffffffc02014c8:	01072823          	sw	a6,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014cc:	4589                	li	a1,2
ffffffffc02014ce:	00870813          	add	a6,a4,8
ffffffffc02014d2:	40b8302f          	amoor.d	zero,a1,(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014d6:	0086b803          	ld	a6,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc02014da:	01870313          	add	t1,a4,24
        nr_free -= n;
ffffffffc02014de:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc02014e0:	00683023          	sd	t1,0(a6)
ffffffffc02014e4:	0066b423          	sd	t1,8(a3)
    elm->next = next;
ffffffffc02014e8:	03073023          	sd	a6,32(a4)
    elm->prev = prev;
ffffffffc02014ec:	ef14                	sd	a3,24(a4)
ffffffffc02014ee:	411585bb          	subw	a1,a1,a7
ffffffffc02014f2:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02014f4:	5775                	li	a4,-3
ffffffffc02014f6:	17c1                	add	a5,a5,-16
ffffffffc02014f8:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02014fc:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02014fe:	1141                	add	sp,sp,-16
    assert(n > 0);
ffffffffc0201500:	00004697          	auipc	a3,0x4
ffffffffc0201504:	68868693          	add	a3,a3,1672 # ffffffffc0205b88 <etext+0xc4e>
ffffffffc0201508:	00004617          	auipc	a2,0x4
ffffffffc020150c:	32860613          	add	a2,a2,808 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201510:	06200593          	li	a1,98
ffffffffc0201514:	00004517          	auipc	a0,0x4
ffffffffc0201518:	33450513          	add	a0,a0,820 # ffffffffc0205848 <etext+0x90e>
default_alloc_pages(size_t n) {
ffffffffc020151c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020151e:	f15fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201522 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201522:	1141                	add	sp,sp,-16
ffffffffc0201524:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201526:	c5f1                	beqz	a1,ffffffffc02015f2 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0201528:	00659713          	sll	a4,a1,0x6
ffffffffc020152c:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201530:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0201532:	cf11                	beqz	a4,ffffffffc020154e <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201534:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201536:	8b05                	and	a4,a4,1
ffffffffc0201538:	cf49                	beqz	a4,ffffffffc02015d2 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020153a:	0007a823          	sw	zero,16(a5)
ffffffffc020153e:	0007b423          	sd	zero,8(a5)
ffffffffc0201542:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201546:	04078793          	add	a5,a5,64
ffffffffc020154a:	fed795e3          	bne	a5,a3,ffffffffc0201534 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020154e:	2581                	sext.w	a1,a1
ffffffffc0201550:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201552:	4789                	li	a5,2
ffffffffc0201554:	00850713          	add	a4,a0,8
ffffffffc0201558:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020155c:	00011697          	auipc	a3,0x11
ffffffffc0201560:	f0468693          	add	a3,a3,-252 # ffffffffc0212460 <free_area>
ffffffffc0201564:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201566:	669c                	ld	a5,8(a3)
ffffffffc0201568:	9f2d                	addw	a4,a4,a1
ffffffffc020156a:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020156c:	04d78663          	beq	a5,a3,ffffffffc02015b8 <default_init_memmap+0x96>
            struct Page* page = le2page(le, page_link);
ffffffffc0201570:	fe878713          	add	a4,a5,-24
ffffffffc0201574:	4581                	li	a1,0
ffffffffc0201576:	01850613          	add	a2,a0,24
            if (base < page) {
ffffffffc020157a:	00e56a63          	bltu	a0,a4,ffffffffc020158e <default_init_memmap+0x6c>
    return listelm->next;
ffffffffc020157e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201580:	02d70263          	beq	a4,a3,ffffffffc02015a4 <default_init_memmap+0x82>
    struct Page *p = base;
ffffffffc0201584:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201586:	fe878713          	add	a4,a5,-24
            if (base < page) {
ffffffffc020158a:	fee57ae3          	bgeu	a0,a4,ffffffffc020157e <default_init_memmap+0x5c>
ffffffffc020158e:	c199                	beqz	a1,ffffffffc0201594 <default_init_memmap+0x72>
ffffffffc0201590:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201594:	6398                	ld	a4,0(a5)
}
ffffffffc0201596:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201598:	e390                	sd	a2,0(a5)
ffffffffc020159a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020159c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020159e:	ed18                	sd	a4,24(a0)
ffffffffc02015a0:	0141                	add	sp,sp,16
ffffffffc02015a2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015a4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015a6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015a8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015aa:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02015ac:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ae:	00d70e63          	beq	a4,a3,ffffffffc02015ca <default_init_memmap+0xa8>
ffffffffc02015b2:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02015b4:	87ba                	mv	a5,a4
ffffffffc02015b6:	bfc1                	j	ffffffffc0201586 <default_init_memmap+0x64>
}
ffffffffc02015b8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015ba:	01850713          	add	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02015be:	e398                	sd	a4,0(a5)
ffffffffc02015c0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02015c2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015c4:	ed1c                	sd	a5,24(a0)
}
ffffffffc02015c6:	0141                	add	sp,sp,16
ffffffffc02015c8:	8082                	ret
ffffffffc02015ca:	60a2                	ld	ra,8(sp)
ffffffffc02015cc:	e290                	sd	a2,0(a3)
ffffffffc02015ce:	0141                	add	sp,sp,16
ffffffffc02015d0:	8082                	ret
        assert(PageReserved(p));
ffffffffc02015d2:	00004697          	auipc	a3,0x4
ffffffffc02015d6:	5e668693          	add	a3,a3,1510 # ffffffffc0205bb8 <etext+0xc7e>
ffffffffc02015da:	00004617          	auipc	a2,0x4
ffffffffc02015de:	25660613          	add	a2,a2,598 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02015e2:	04900593          	li	a1,73
ffffffffc02015e6:	00004517          	auipc	a0,0x4
ffffffffc02015ea:	26250513          	add	a0,a0,610 # ffffffffc0205848 <etext+0x90e>
ffffffffc02015ee:	e45fe0ef          	jal	ffffffffc0200432 <__panic>
    assert(n > 0);
ffffffffc02015f2:	00004697          	auipc	a3,0x4
ffffffffc02015f6:	59668693          	add	a3,a3,1430 # ffffffffc0205b88 <etext+0xc4e>
ffffffffc02015fa:	00004617          	auipc	a2,0x4
ffffffffc02015fe:	23660613          	add	a2,a2,566 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0201602:	04600593          	li	a1,70
ffffffffc0201606:	00004517          	auipc	a0,0x4
ffffffffc020160a:	24250513          	add	a0,a0,578 # ffffffffc0205848 <etext+0x90e>
ffffffffc020160e:	e25fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201612 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201612:	cd49                	beqz	a0,ffffffffc02016ac <slob_free+0x9a>
{
ffffffffc0201614:	1141                	add	sp,sp,-16
ffffffffc0201616:	e022                	sd	s0,0(sp)
ffffffffc0201618:	e406                	sd	ra,8(sp)
ffffffffc020161a:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020161c:	eda1                	bnez	a1,ffffffffc0201674 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020161e:	100027f3          	csrr	a5,sstatus
ffffffffc0201622:	8b89                	and	a5,a5,2
    return 0;
ffffffffc0201624:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201626:	efb9                	bnez	a5,ffffffffc0201684 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201628:	0000a617          	auipc	a2,0xa
ffffffffc020162c:	a2860613          	add	a2,a2,-1496 # ffffffffc020b050 <slobfree>
ffffffffc0201630:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201632:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201634:	0287fa63          	bgeu	a5,s0,ffffffffc0201668 <slob_free+0x56>
ffffffffc0201638:	00e46463          	bltu	s0,a4,ffffffffc0201640 <slob_free+0x2e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020163c:	02e7ea63          	bltu	a5,a4,ffffffffc0201670 <slob_free+0x5e>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201640:	400c                	lw	a1,0(s0)
ffffffffc0201642:	00459693          	sll	a3,a1,0x4
ffffffffc0201646:	96a2                	add	a3,a3,s0
ffffffffc0201648:	04d70d63          	beq	a4,a3,ffffffffc02016a2 <slob_free+0x90>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020164c:	438c                	lw	a1,0(a5)
ffffffffc020164e:	e418                	sd	a4,8(s0)
ffffffffc0201650:	00459693          	sll	a3,a1,0x4
ffffffffc0201654:	96be                	add	a3,a3,a5
ffffffffc0201656:	04d40063          	beq	s0,a3,ffffffffc0201696 <slob_free+0x84>
ffffffffc020165a:	e780                	sd	s0,8(a5)
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;

	slobfree = cur;
ffffffffc020165c:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc020165e:	e51d                	bnez	a0,ffffffffc020168c <slob_free+0x7a>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201660:	60a2                	ld	ra,8(sp)
ffffffffc0201662:	6402                	ld	s0,0(sp)
ffffffffc0201664:	0141                	add	sp,sp,16
ffffffffc0201666:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201668:	00e7e463          	bltu	a5,a4,ffffffffc0201670 <slob_free+0x5e>
ffffffffc020166c:	fce46ae3          	bltu	s0,a4,ffffffffc0201640 <slob_free+0x2e>
        return 1;
ffffffffc0201670:	87ba                	mv	a5,a4
ffffffffc0201672:	b7c1                	j	ffffffffc0201632 <slob_free+0x20>
		b->units = SLOB_UNITS(size);
ffffffffc0201674:	25bd                	addw	a1,a1,15
ffffffffc0201676:	8191                	srl	a1,a1,0x4
ffffffffc0201678:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020167a:	100027f3          	csrr	a5,sstatus
ffffffffc020167e:	8b89                	and	a5,a5,2
    return 0;
ffffffffc0201680:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201682:	d3dd                	beqz	a5,ffffffffc0201628 <slob_free+0x16>
        intr_disable();
ffffffffc0201684:	f2dfe0ef          	jal	ffffffffc02005b0 <intr_disable>
        return 1;
ffffffffc0201688:	4505                	li	a0,1
ffffffffc020168a:	bf79                	j	ffffffffc0201628 <slob_free+0x16>
}
ffffffffc020168c:	6402                	ld	s0,0(sp)
ffffffffc020168e:	60a2                	ld	ra,8(sp)
ffffffffc0201690:	0141                	add	sp,sp,16
        intr_enable();
ffffffffc0201692:	f19fe06f          	j	ffffffffc02005aa <intr_enable>
		cur->units += b->units;
ffffffffc0201696:	4014                	lw	a3,0(s0)
		cur->next = b->next;
ffffffffc0201698:	843a                	mv	s0,a4
		cur->units += b->units;
ffffffffc020169a:	00b6873b          	addw	a4,a3,a1
ffffffffc020169e:	c398                	sw	a4,0(a5)
		cur->next = b->next;
ffffffffc02016a0:	bf6d                	j	ffffffffc020165a <slob_free+0x48>
		b->units += cur->next->units;
ffffffffc02016a2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02016a4:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc02016a6:	9ead                	addw	a3,a3,a1
ffffffffc02016a8:	c014                	sw	a3,0(s0)
		b->next = cur->next->next;
ffffffffc02016aa:	b74d                	j	ffffffffc020164c <slob_free+0x3a>
ffffffffc02016ac:	8082                	ret

ffffffffc02016ae <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016ae:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02016b0:	1141                	add	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016b2:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02016b6:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02016b8:	348000ef          	jal	ffffffffc0201a00 <alloc_pages>
  if(!page)
ffffffffc02016bc:	c91d                	beqz	a0,ffffffffc02016f2 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02016be:	00015797          	auipc	a5,0x15
ffffffffc02016c2:	ec27b783          	ld	a5,-318(a5) # ffffffffc0216580 <pages>
ffffffffc02016c6:	8d1d                	sub	a0,a0,a5
ffffffffc02016c8:	8519                	sra	a0,a0,0x6
ffffffffc02016ca:	00006797          	auipc	a5,0x6
ffffffffc02016ce:	95e7b783          	ld	a5,-1698(a5) # ffffffffc0207028 <nbase>
ffffffffc02016d2:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc02016d4:	00c51793          	sll	a5,a0,0xc
ffffffffc02016d8:	83b1                	srl	a5,a5,0xc
ffffffffc02016da:	00015717          	auipc	a4,0x15
ffffffffc02016de:	e9e73703          	ld	a4,-354(a4) # ffffffffc0216578 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02016e2:	0532                	sll	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02016e4:	00e7fa63          	bgeu	a5,a4,ffffffffc02016f8 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02016e8:	00015797          	auipc	a5,0x15
ffffffffc02016ec:	e887b783          	ld	a5,-376(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc02016f0:	953e                	add	a0,a0,a5
}
ffffffffc02016f2:	60a2                	ld	ra,8(sp)
ffffffffc02016f4:	0141                	add	sp,sp,16
ffffffffc02016f6:	8082                	ret
ffffffffc02016f8:	86aa                	mv	a3,a0
ffffffffc02016fa:	00004617          	auipc	a2,0x4
ffffffffc02016fe:	4e660613          	add	a2,a2,1254 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0201702:	06900593          	li	a1,105
ffffffffc0201706:	00004517          	auipc	a0,0x4
ffffffffc020170a:	50250513          	add	a0,a0,1282 # ffffffffc0205c08 <etext+0xcce>
ffffffffc020170e:	d25fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201712 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201712:	1101                	add	sp,sp,-32
ffffffffc0201714:	ec06                	sd	ra,24(sp)
ffffffffc0201716:	e822                	sd	s0,16(sp)
ffffffffc0201718:	e426                	sd	s1,8(sp)
ffffffffc020171a:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc020171c:	01050713          	add	a4,a0,16
ffffffffc0201720:	6785                	lui	a5,0x1
ffffffffc0201722:	0cf77363          	bgeu	a4,a5,ffffffffc02017e8 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201726:	00f50493          	add	s1,a0,15
ffffffffc020172a:	8091                	srl	s1,s1,0x4
ffffffffc020172c:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020172e:	10002673          	csrr	a2,sstatus
ffffffffc0201732:	8a09                	and	a2,a2,2
ffffffffc0201734:	e25d                	bnez	a2,ffffffffc02017da <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201736:	0000a917          	auipc	s2,0xa
ffffffffc020173a:	91a90913          	add	s2,s2,-1766 # ffffffffc020b050 <slobfree>
ffffffffc020173e:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201742:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201744:	4398                	lw	a4,0(a5)
ffffffffc0201746:	08975e63          	bge	a4,s1,ffffffffc02017e2 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc020174a:	00f68b63          	beq	a3,a5,ffffffffc0201760 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020174e:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201750:	4018                	lw	a4,0(s0)
ffffffffc0201752:	02975a63          	bge	a4,s1,ffffffffc0201786 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201756:	00093683          	ld	a3,0(s2)
ffffffffc020175a:	87a2                	mv	a5,s0
ffffffffc020175c:	fef699e3          	bne	a3,a5,ffffffffc020174e <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201760:	ee31                	bnez	a2,ffffffffc02017bc <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201762:	4501                	li	a0,0
ffffffffc0201764:	f4bff0ef          	jal	ffffffffc02016ae <__slob_get_free_pages.constprop.0>
ffffffffc0201768:	842a                	mv	s0,a0
			if (!cur)
ffffffffc020176a:	cd05                	beqz	a0,ffffffffc02017a2 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc020176c:	6585                	lui	a1,0x1
ffffffffc020176e:	ea5ff0ef          	jal	ffffffffc0201612 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201772:	10002673          	csrr	a2,sstatus
ffffffffc0201776:	8a09                	and	a2,a2,2
ffffffffc0201778:	ee05                	bnez	a2,ffffffffc02017b0 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc020177a:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020177e:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201780:	4018                	lw	a4,0(s0)
ffffffffc0201782:	fc974ae3          	blt	a4,s1,ffffffffc0201756 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201786:	04e48763          	beq	s1,a4,ffffffffc02017d4 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc020178a:	00449693          	sll	a3,s1,0x4
ffffffffc020178e:	96a2                	add	a3,a3,s0
ffffffffc0201790:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201792:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201794:	9f05                	subw	a4,a4,s1
ffffffffc0201796:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201798:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc020179a:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc020179c:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02017a0:	e20d                	bnez	a2,ffffffffc02017c2 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02017a2:	60e2                	ld	ra,24(sp)
ffffffffc02017a4:	8522                	mv	a0,s0
ffffffffc02017a6:	6442                	ld	s0,16(sp)
ffffffffc02017a8:	64a2                	ld	s1,8(sp)
ffffffffc02017aa:	6902                	ld	s2,0(sp)
ffffffffc02017ac:	6105                	add	sp,sp,32
ffffffffc02017ae:	8082                	ret
        intr_disable();
ffffffffc02017b0:	e01fe0ef          	jal	ffffffffc02005b0 <intr_disable>
			cur = slobfree;
ffffffffc02017b4:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02017b8:	4605                	li	a2,1
ffffffffc02017ba:	b7d1                	j	ffffffffc020177e <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02017bc:	deffe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02017c0:	b74d                	j	ffffffffc0201762 <slob_alloc.constprop.0+0x50>
ffffffffc02017c2:	de9fe0ef          	jal	ffffffffc02005aa <intr_enable>
}
ffffffffc02017c6:	60e2                	ld	ra,24(sp)
ffffffffc02017c8:	8522                	mv	a0,s0
ffffffffc02017ca:	6442                	ld	s0,16(sp)
ffffffffc02017cc:	64a2                	ld	s1,8(sp)
ffffffffc02017ce:	6902                	ld	s2,0(sp)
ffffffffc02017d0:	6105                	add	sp,sp,32
ffffffffc02017d2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02017d4:	6418                	ld	a4,8(s0)
ffffffffc02017d6:	e798                	sd	a4,8(a5)
ffffffffc02017d8:	b7d1                	j	ffffffffc020179c <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02017da:	dd7fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        return 1;
ffffffffc02017de:	4605                	li	a2,1
ffffffffc02017e0:	bf99                	j	ffffffffc0201736 <slob_alloc.constprop.0+0x24>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc02017e2:	843e                	mv	s0,a5
	prev = slobfree;
ffffffffc02017e4:	87b6                	mv	a5,a3
ffffffffc02017e6:	b745                	j	ffffffffc0201786 <slob_alloc.constprop.0+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02017e8:	00004697          	auipc	a3,0x4
ffffffffc02017ec:	43068693          	add	a3,a3,1072 # ffffffffc0205c18 <etext+0xcde>
ffffffffc02017f0:	00004617          	auipc	a2,0x4
ffffffffc02017f4:	04060613          	add	a2,a2,64 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02017f8:	06300593          	li	a1,99
ffffffffc02017fc:	00004517          	auipc	a0,0x4
ffffffffc0201800:	43c50513          	add	a0,a0,1084 # ffffffffc0205c38 <etext+0xcfe>
ffffffffc0201804:	c2ffe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201808 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201808:	1141                	add	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc020180a:	00004517          	auipc	a0,0x4
ffffffffc020180e:	44650513          	add	a0,a0,1094 # ffffffffc0205c50 <etext+0xd16>
kmalloc_init(void) {
ffffffffc0201812:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201814:	96dfe0ef          	jal	ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201818:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc020181a:	00004517          	auipc	a0,0x4
ffffffffc020181e:	44e50513          	add	a0,a0,1102 # ffffffffc0205c68 <etext+0xd2e>
}
ffffffffc0201822:	0141                	add	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201824:	95dfe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201828 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201828:	1101                	add	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc020182a:	6785                	lui	a5,0x1
{
ffffffffc020182c:	e822                	sd	s0,16(sp)
ffffffffc020182e:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201830:	17bd                	add	a5,a5,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201832:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201834:	04a7fa63          	bgeu	a5,a0,ffffffffc0201888 <kmalloc+0x60>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201838:	4561                	li	a0,24
ffffffffc020183a:	e426                	sd	s1,8(sp)
ffffffffc020183c:	ed7ff0ef          	jal	ffffffffc0201712 <slob_alloc.constprop.0>
ffffffffc0201840:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201842:	c549                	beqz	a0,ffffffffc02018cc <kmalloc+0xa4>
ffffffffc0201844:	e04a                	sd	s2,0(sp)
	bb->order = find_order(size);
ffffffffc0201846:	0004079b          	sext.w	a5,s0
ffffffffc020184a:	6905                	lui	s2,0x1
	int order = 0;
ffffffffc020184c:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc020184e:	00f95763          	bge	s2,a5,ffffffffc020185c <kmalloc+0x34>
ffffffffc0201852:	6705                	lui	a4,0x1
ffffffffc0201854:	8785                	sra	a5,a5,0x1
		order++;
ffffffffc0201856:	2505                	addw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201858:	fef74ee3          	blt	a4,a5,ffffffffc0201854 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc020185c:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc020185e:	e51ff0ef          	jal	ffffffffc02016ae <__slob_get_free_pages.constprop.0>
ffffffffc0201862:	e488                	sd	a0,8(s1)
	if (bb->pages) {
ffffffffc0201864:	cd21                	beqz	a0,ffffffffc02018bc <kmalloc+0x94>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201866:	100027f3          	csrr	a5,sstatus
ffffffffc020186a:	8b89                	and	a5,a5,2
ffffffffc020186c:	e795                	bnez	a5,ffffffffc0201898 <kmalloc+0x70>
		bb->next = bigblocks;
ffffffffc020186e:	00015797          	auipc	a5,0x15
ffffffffc0201872:	ce278793          	add	a5,a5,-798 # ffffffffc0216550 <bigblocks>
ffffffffc0201876:	6398                	ld	a4,0(a5)
ffffffffc0201878:	6902                	ld	s2,0(sp)
		bigblocks = bb;
ffffffffc020187a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc020187c:	e898                	sd	a4,16(s1)
    if (flag) {
ffffffffc020187e:	64a2                	ld	s1,8(sp)
  return __kmalloc(size, 0);
}
ffffffffc0201880:	60e2                	ld	ra,24(sp)
ffffffffc0201882:	6442                	ld	s0,16(sp)
ffffffffc0201884:	6105                	add	sp,sp,32
ffffffffc0201886:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201888:	0541                	add	a0,a0,16
ffffffffc020188a:	e89ff0ef          	jal	ffffffffc0201712 <slob_alloc.constprop.0>
ffffffffc020188e:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201890:	0541                	add	a0,a0,16
ffffffffc0201892:	f7fd                	bnez	a5,ffffffffc0201880 <kmalloc+0x58>
		return 0;
ffffffffc0201894:	4501                	li	a0,0
  return __kmalloc(size, 0);
ffffffffc0201896:	b7ed                	j	ffffffffc0201880 <kmalloc+0x58>
        intr_disable();
ffffffffc0201898:	d19fe0ef          	jal	ffffffffc02005b0 <intr_disable>
		bb->next = bigblocks;
ffffffffc020189c:	00015797          	auipc	a5,0x15
ffffffffc02018a0:	cb478793          	add	a5,a5,-844 # ffffffffc0216550 <bigblocks>
ffffffffc02018a4:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc02018a6:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc02018a8:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc02018aa:	d01fe0ef          	jal	ffffffffc02005aa <intr_enable>
}
ffffffffc02018ae:	60e2                	ld	ra,24(sp)
ffffffffc02018b0:	6442                	ld	s0,16(sp)
		return bb->pages;
ffffffffc02018b2:	6488                	ld	a0,8(s1)
ffffffffc02018b4:	6902                	ld	s2,0(sp)
ffffffffc02018b6:	64a2                	ld	s1,8(sp)
}
ffffffffc02018b8:	6105                	add	sp,sp,32
ffffffffc02018ba:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02018bc:	8526                	mv	a0,s1
ffffffffc02018be:	45e1                	li	a1,24
ffffffffc02018c0:	d53ff0ef          	jal	ffffffffc0201612 <slob_free>
		return 0;
ffffffffc02018c4:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc02018c6:	64a2                	ld	s1,8(sp)
ffffffffc02018c8:	6902                	ld	s2,0(sp)
ffffffffc02018ca:	bf5d                	j	ffffffffc0201880 <kmalloc+0x58>
ffffffffc02018cc:	64a2                	ld	s1,8(sp)
		return 0;
ffffffffc02018ce:	4501                	li	a0,0
ffffffffc02018d0:	bf45                	j	ffffffffc0201880 <kmalloc+0x58>

ffffffffc02018d2 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc02018d2:	c169                	beqz	a0,ffffffffc0201994 <kfree+0xc2>
{
ffffffffc02018d4:	1101                	add	sp,sp,-32
ffffffffc02018d6:	e822                	sd	s0,16(sp)
ffffffffc02018d8:	ec06                	sd	ra,24(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc02018da:	03451793          	sll	a5,a0,0x34
ffffffffc02018de:	842a                	mv	s0,a0
ffffffffc02018e0:	e7c9                	bnez	a5,ffffffffc020196a <kfree+0x98>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018e2:	100027f3          	csrr	a5,sstatus
ffffffffc02018e6:	8b89                	and	a5,a5,2
ffffffffc02018e8:	ebc1                	bnez	a5,ffffffffc0201978 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc02018ea:	00015797          	auipc	a5,0x15
ffffffffc02018ee:	c667b783          	ld	a5,-922(a5) # ffffffffc0216550 <bigblocks>
    return 0;
ffffffffc02018f2:	4601                	li	a2,0
ffffffffc02018f4:	cbbd                	beqz	a5,ffffffffc020196a <kfree+0x98>
ffffffffc02018f6:	e426                	sd	s1,8(sp)
	bigblock_t *bb, **last = &bigblocks;
ffffffffc02018f8:	00015697          	auipc	a3,0x15
ffffffffc02018fc:	c5868693          	add	a3,a3,-936 # ffffffffc0216550 <bigblocks>
ffffffffc0201900:	a021                	j	ffffffffc0201908 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201902:	01048693          	add	a3,s1,16
ffffffffc0201906:	c3a5                	beqz	a5,ffffffffc0201966 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201908:	6798                	ld	a4,8(a5)
ffffffffc020190a:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc020190c:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc020190e:	fe871ae3          	bne	a4,s0,ffffffffc0201902 <kfree+0x30>
				*last = bb->next;
ffffffffc0201912:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201914:	ee2d                	bnez	a2,ffffffffc020198e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201916:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc020191a:	4098                	lw	a4,0(s1)
ffffffffc020191c:	08f46963          	bltu	s0,a5,ffffffffc02019ae <kfree+0xdc>
ffffffffc0201920:	00015797          	auipc	a5,0x15
ffffffffc0201924:	c507b783          	ld	a5,-944(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc0201928:	8c1d                	sub	s0,s0,a5
    if (PPN(pa) >= npage) {
ffffffffc020192a:	8031                	srl	s0,s0,0xc
ffffffffc020192c:	00015797          	auipc	a5,0x15
ffffffffc0201930:	c4c7b783          	ld	a5,-948(a5) # ffffffffc0216578 <npage>
ffffffffc0201934:	06f47163          	bgeu	s0,a5,ffffffffc0201996 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201938:	00005797          	auipc	a5,0x5
ffffffffc020193c:	6f07b783          	ld	a5,1776(a5) # ffffffffc0207028 <nbase>
ffffffffc0201940:	8c1d                	sub	s0,s0,a5
ffffffffc0201942:	041a                	sll	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201944:	00015517          	auipc	a0,0x15
ffffffffc0201948:	c3c53503          	ld	a0,-964(a0) # ffffffffc0216580 <pages>
ffffffffc020194c:	4585                	li	a1,1
ffffffffc020194e:	9522                	add	a0,a0,s0
ffffffffc0201950:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201954:	13c000ef          	jal	ffffffffc0201a90 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201958:	6442                	ld	s0,16(sp)
ffffffffc020195a:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc020195c:	8526                	mv	a0,s1
ffffffffc020195e:	64a2                	ld	s1,8(sp)
ffffffffc0201960:	45e1                	li	a1,24
}
ffffffffc0201962:	6105                	add	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201964:	b17d                	j	ffffffffc0201612 <slob_free>
ffffffffc0201966:	64a2                	ld	s1,8(sp)
ffffffffc0201968:	e205                	bnez	a2,ffffffffc0201988 <kfree+0xb6>
ffffffffc020196a:	ff040513          	add	a0,s0,-16
}
ffffffffc020196e:	6442                	ld	s0,16(sp)
ffffffffc0201970:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201972:	4581                	li	a1,0
}
ffffffffc0201974:	6105                	add	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201976:	b971                	j	ffffffffc0201612 <slob_free>
        intr_disable();
ffffffffc0201978:	c39fe0ef          	jal	ffffffffc02005b0 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc020197c:	00015797          	auipc	a5,0x15
ffffffffc0201980:	bd47b783          	ld	a5,-1068(a5) # ffffffffc0216550 <bigblocks>
        return 1;
ffffffffc0201984:	4605                	li	a2,1
ffffffffc0201986:	fba5                	bnez	a5,ffffffffc02018f6 <kfree+0x24>
        intr_enable();
ffffffffc0201988:	c23fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc020198c:	bff9                	j	ffffffffc020196a <kfree+0x98>
ffffffffc020198e:	c1dfe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0201992:	b751                	j	ffffffffc0201916 <kfree+0x44>
ffffffffc0201994:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201996:	00004617          	auipc	a2,0x4
ffffffffc020199a:	31a60613          	add	a2,a2,794 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc020199e:	06200593          	li	a1,98
ffffffffc02019a2:	00004517          	auipc	a0,0x4
ffffffffc02019a6:	26650513          	add	a0,a0,614 # ffffffffc0205c08 <etext+0xcce>
ffffffffc02019aa:	a89fe0ef          	jal	ffffffffc0200432 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02019ae:	86a2                	mv	a3,s0
ffffffffc02019b0:	00004617          	auipc	a2,0x4
ffffffffc02019b4:	2d860613          	add	a2,a2,728 # ffffffffc0205c88 <etext+0xd4e>
ffffffffc02019b8:	06e00593          	li	a1,110
ffffffffc02019bc:	00004517          	auipc	a0,0x4
ffffffffc02019c0:	24c50513          	add	a0,a0,588 # ffffffffc0205c08 <etext+0xcce>
ffffffffc02019c4:	a6ffe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02019c8 <pa2page.part.0>:
    local_intr_restore(intr_flag);
    return ret;
}

/* pmm_init - initialize the physical memory management */
static void page_init(void) {
ffffffffc02019c8:	1141                	add	sp,sp,-16
    extern char kern_entry[];

ffffffffc02019ca:	00004617          	auipc	a2,0x4
ffffffffc02019ce:	2e660613          	add	a2,a2,742 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc02019d2:	06200593          	li	a1,98
ffffffffc02019d6:	00004517          	auipc	a0,0x4
ffffffffc02019da:	23250513          	add	a0,a0,562 # ffffffffc0205c08 <etext+0xcce>
static void page_init(void) {
ffffffffc02019de:	e406                	sd	ra,8(sp)

ffffffffc02019e0:	a53fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02019e4 <pte2page.part.0>:
    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

ffffffffc02019e4:	1141                	add	sp,sp,-16
    extern char end[];

ffffffffc02019e6:	00004617          	auipc	a2,0x4
ffffffffc02019ea:	2ea60613          	add	a2,a2,746 # ffffffffc0205cd0 <etext+0xd96>
ffffffffc02019ee:	07400593          	li	a1,116
ffffffffc02019f2:	00004517          	auipc	a0,0x4
ffffffffc02019f6:	21650513          	add	a0,a0,534 # ffffffffc0205c08 <etext+0xcce>

ffffffffc02019fa:	e406                	sd	ra,8(sp)

ffffffffc02019fc:	a37fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201a00 <alloc_pages>:
struct Page *alloc_pages(size_t n) {
ffffffffc0201a00:	7139                	add	sp,sp,-64
ffffffffc0201a02:	f426                	sd	s1,40(sp)
ffffffffc0201a04:	f04a                	sd	s2,32(sp)
ffffffffc0201a06:	ec4e                	sd	s3,24(sp)
ffffffffc0201a08:	e852                	sd	s4,16(sp)
ffffffffc0201a0a:	e456                	sd	s5,8(sp)
ffffffffc0201a0c:	e05a                	sd	s6,0(sp)
ffffffffc0201a0e:	fc06                	sd	ra,56(sp)
ffffffffc0201a10:	f822                	sd	s0,48(sp)
ffffffffc0201a12:	84aa                	mv	s1,a0
ffffffffc0201a14:	00015917          	auipc	s2,0x15
ffffffffc0201a18:	b4490913          	add	s2,s2,-1212 # ffffffffc0216558 <pmm_manager>
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a1c:	4a05                	li	s4,1
ffffffffc0201a1e:	00015a97          	auipc	s5,0x15
ffffffffc0201a22:	b6aa8a93          	add	s5,s5,-1174 # ffffffffc0216588 <swap_init_ok>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a26:	0005099b          	sext.w	s3,a0
ffffffffc0201a2a:	00015b17          	auipc	s6,0x15
ffffffffc0201a2e:	b7eb0b13          	add	s6,s6,-1154 # ffffffffc02165a8 <check_mm_struct>
ffffffffc0201a32:	a015                	j	ffffffffc0201a56 <alloc_pages+0x56>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201a34:	00093783          	ld	a5,0(s2)
ffffffffc0201a38:	6f9c                	ld	a5,24(a5)
ffffffffc0201a3a:	9782                	jalr	a5
ffffffffc0201a3c:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a3e:	4601                	li	a2,0
ffffffffc0201a40:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a42:	ec05                	bnez	s0,ffffffffc0201a7a <alloc_pages+0x7a>
ffffffffc0201a44:	029a6b63          	bltu	s4,s1,ffffffffc0201a7a <alloc_pages+0x7a>
ffffffffc0201a48:	000aa783          	lw	a5,0(s5)
ffffffffc0201a4c:	c79d                	beqz	a5,ffffffffc0201a7a <alloc_pages+0x7a>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a4e:	000b3503          	ld	a0,0(s6)
ffffffffc0201a52:	065010ef          	jal	ffffffffc02032b6 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a56:	100027f3          	csrr	a5,sstatus
ffffffffc0201a5a:	8b89                	and	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201a5c:	8526                	mv	a0,s1
ffffffffc0201a5e:	dbf9                	beqz	a5,ffffffffc0201a34 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201a60:	b51fe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0201a64:	00093783          	ld	a5,0(s2)
ffffffffc0201a68:	8526                	mv	a0,s1
ffffffffc0201a6a:	6f9c                	ld	a5,24(a5)
ffffffffc0201a6c:	9782                	jalr	a5
ffffffffc0201a6e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201a70:	b3bfe0ef          	jal	ffffffffc02005aa <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201a74:	4601                	li	a2,0
ffffffffc0201a76:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201a78:	d471                	beqz	s0,ffffffffc0201a44 <alloc_pages+0x44>
}
ffffffffc0201a7a:	70e2                	ld	ra,56(sp)
ffffffffc0201a7c:	8522                	mv	a0,s0
ffffffffc0201a7e:	7442                	ld	s0,48(sp)
ffffffffc0201a80:	74a2                	ld	s1,40(sp)
ffffffffc0201a82:	7902                	ld	s2,32(sp)
ffffffffc0201a84:	69e2                	ld	s3,24(sp)
ffffffffc0201a86:	6a42                	ld	s4,16(sp)
ffffffffc0201a88:	6aa2                	ld	s5,8(sp)
ffffffffc0201a8a:	6b02                	ld	s6,0(sp)
ffffffffc0201a8c:	6121                	add	sp,sp,64
ffffffffc0201a8e:	8082                	ret

ffffffffc0201a90 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a90:	100027f3          	csrr	a5,sstatus
ffffffffc0201a94:	8b89                	and	a5,a5,2
ffffffffc0201a96:	e799                	bnez	a5,ffffffffc0201aa4 <free_pages+0x14>
        pmm_manager->free_pages(base, n);
ffffffffc0201a98:	00015797          	auipc	a5,0x15
ffffffffc0201a9c:	ac07b783          	ld	a5,-1344(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201aa0:	739c                	ld	a5,32(a5)
ffffffffc0201aa2:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201aa4:	1101                	add	sp,sp,-32
ffffffffc0201aa6:	ec06                	sd	ra,24(sp)
ffffffffc0201aa8:	e822                	sd	s0,16(sp)
ffffffffc0201aaa:	e426                	sd	s1,8(sp)
ffffffffc0201aac:	842a                	mv	s0,a0
ffffffffc0201aae:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ab0:	b01fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ab4:	00015797          	auipc	a5,0x15
ffffffffc0201ab8:	aa47b783          	ld	a5,-1372(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201abc:	739c                	ld	a5,32(a5)
ffffffffc0201abe:	85a6                	mv	a1,s1
ffffffffc0201ac0:	8522                	mv	a0,s0
ffffffffc0201ac2:	9782                	jalr	a5
}
ffffffffc0201ac4:	6442                	ld	s0,16(sp)
ffffffffc0201ac6:	60e2                	ld	ra,24(sp)
ffffffffc0201ac8:	64a2                	ld	s1,8(sp)
ffffffffc0201aca:	6105                	add	sp,sp,32
        intr_enable();
ffffffffc0201acc:	adffe06f          	j	ffffffffc02005aa <intr_enable>

ffffffffc0201ad0 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ad0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ad4:	8b89                	and	a5,a5,2
ffffffffc0201ad6:	e799                	bnez	a5,ffffffffc0201ae4 <nr_free_pages+0x14>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ad8:	00015797          	auipc	a5,0x15
ffffffffc0201adc:	a807b783          	ld	a5,-1408(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201ae0:	779c                	ld	a5,40(a5)
ffffffffc0201ae2:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201ae4:	1141                	add	sp,sp,-16
ffffffffc0201ae6:	e406                	sd	ra,8(sp)
ffffffffc0201ae8:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201aea:	ac7fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201aee:	00015797          	auipc	a5,0x15
ffffffffc0201af2:	a6a7b783          	ld	a5,-1430(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201af6:	779c                	ld	a5,40(a5)
ffffffffc0201af8:	9782                	jalr	a5
ffffffffc0201afa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201afc:	aaffe0ef          	jal	ffffffffc02005aa <intr_enable>
}
ffffffffc0201b00:	60a2                	ld	ra,8(sp)
ffffffffc0201b02:	8522                	mv	a0,s0
ffffffffc0201b04:	6402                	ld	s0,0(sp)
ffffffffc0201b06:	0141                	add	sp,sp,16
ffffffffc0201b08:	8082                	ret

ffffffffc0201b0a <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b0a:	01e5d793          	srl	a5,a1,0x1e
ffffffffc0201b0e:	1ff7f793          	and	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b12:	7139                	add	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b14:	078e                	sll	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b16:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201b18:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b1c:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b1e:	f04a                	sd	s2,32(sp)
ffffffffc0201b20:	ec4e                	sd	s3,24(sp)
ffffffffc0201b22:	e852                	sd	s4,16(sp)
ffffffffc0201b24:	fc06                	sd	ra,56(sp)
ffffffffc0201b26:	f822                	sd	s0,48(sp)
ffffffffc0201b28:	e456                	sd	s5,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b2a:	0016f793          	and	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201b2e:	892e                	mv	s2,a1
ffffffffc0201b30:	89b2                	mv	s3,a2
ffffffffc0201b32:	00015a17          	auipc	s4,0x15
ffffffffc0201b36:	a46a0a13          	add	s4,s4,-1466 # ffffffffc0216578 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201b3a:	eba5                	bnez	a5,ffffffffc0201baa <get_pte+0xa0>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201b3c:	12060e63          	beqz	a2,ffffffffc0201c78 <get_pte+0x16e>
ffffffffc0201b40:	4505                	li	a0,1
ffffffffc0201b42:	ebfff0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0201b46:	842a                	mv	s0,a0
ffffffffc0201b48:	12050863          	beqz	a0,ffffffffc0201c78 <get_pte+0x16e>
    page->ref = val;
ffffffffc0201b4c:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201b4e:	00015b17          	auipc	s6,0x15
ffffffffc0201b52:	a32b0b13          	add	s6,s6,-1486 # ffffffffc0216580 <pages>
ffffffffc0201b56:	000b3503          	ld	a0,0(s6)
ffffffffc0201b5a:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201b5e:	00015a17          	auipc	s4,0x15
ffffffffc0201b62:	a1aa0a13          	add	s4,s4,-1510 # ffffffffc0216578 <npage>
ffffffffc0201b66:	40a40533          	sub	a0,s0,a0
ffffffffc0201b6a:	8519                	sra	a0,a0,0x6
ffffffffc0201b6c:	9556                	add	a0,a0,s5
ffffffffc0201b6e:	000a3703          	ld	a4,0(s4)
ffffffffc0201b72:	00c51793          	sll	a5,a0,0xc
    page->ref = val;
ffffffffc0201b76:	4685                	li	a3,1
ffffffffc0201b78:	c014                	sw	a3,0(s0)
ffffffffc0201b7a:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b7c:	0532                	sll	a0,a0,0xc
ffffffffc0201b7e:	14e7f563          	bgeu	a5,a4,ffffffffc0201cc8 <get_pte+0x1be>
ffffffffc0201b82:	00015797          	auipc	a5,0x15
ffffffffc0201b86:	9ee7b783          	ld	a5,-1554(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc0201b8a:	953e                	add	a0,a0,a5
ffffffffc0201b8c:	6605                	lui	a2,0x1
ffffffffc0201b8e:	4581                	li	a1,0
ffffffffc0201b90:	35c030ef          	jal	ffffffffc0204eec <memset>
    return page - pages + nbase;
ffffffffc0201b94:	000b3783          	ld	a5,0(s6)
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201b98:	6b02                	ld	s6,0(sp)
ffffffffc0201b9a:	40f406b3          	sub	a3,s0,a5
ffffffffc0201b9e:	8699                	sra	a3,a3,0x6
ffffffffc0201ba0:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ba2:	06aa                	sll	a3,a3,0xa
ffffffffc0201ba4:	0116e693          	or	a3,a3,17
ffffffffc0201ba8:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201baa:	77fd                	lui	a5,0xfffff
ffffffffc0201bac:	068a                	sll	a3,a3,0x2
ffffffffc0201bae:	000a3703          	ld	a4,0(s4)
ffffffffc0201bb2:	8efd                	and	a3,a3,a5
ffffffffc0201bb4:	00c6d793          	srl	a5,a3,0xc
ffffffffc0201bb8:	0ce7f263          	bgeu	a5,a4,ffffffffc0201c7c <get_pte+0x172>
ffffffffc0201bbc:	00015a97          	auipc	s5,0x15
ffffffffc0201bc0:	9b4a8a93          	add	s5,s5,-1612 # ffffffffc0216570 <va_pa_offset>
ffffffffc0201bc4:	000ab603          	ld	a2,0(s5)
ffffffffc0201bc8:	01595793          	srl	a5,s2,0x15
ffffffffc0201bcc:	1ff7f793          	and	a5,a5,511
ffffffffc0201bd0:	96b2                	add	a3,a3,a2
ffffffffc0201bd2:	078e                	sll	a5,a5,0x3
ffffffffc0201bd4:	00f68433          	add	s0,a3,a5
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201bd8:	6014                	ld	a3,0(s0)
ffffffffc0201bda:	0016f793          	and	a5,a3,1
ffffffffc0201bde:	e3bd                	bnez	a5,ffffffffc0201c44 <get_pte+0x13a>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201be0:	08098c63          	beqz	s3,ffffffffc0201c78 <get_pte+0x16e>
ffffffffc0201be4:	4505                	li	a0,1
ffffffffc0201be6:	e1bff0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0201bea:	84aa                	mv	s1,a0
ffffffffc0201bec:	c551                	beqz	a0,ffffffffc0201c78 <get_pte+0x16e>
    page->ref = val;
ffffffffc0201bee:	e05a                	sd	s6,0(sp)
    return page - pages + nbase;
ffffffffc0201bf0:	00015b17          	auipc	s6,0x15
ffffffffc0201bf4:	990b0b13          	add	s6,s6,-1648 # ffffffffc0216580 <pages>
ffffffffc0201bf8:	000b3683          	ld	a3,0(s6)
ffffffffc0201bfc:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201c00:	000a3703          	ld	a4,0(s4)
ffffffffc0201c04:	40d506b3          	sub	a3,a0,a3
ffffffffc0201c08:	8699                	sra	a3,a3,0x6
ffffffffc0201c0a:	96ce                	add	a3,a3,s3
ffffffffc0201c0c:	00c69793          	sll	a5,a3,0xc
    page->ref = val;
ffffffffc0201c10:	4605                	li	a2,1
ffffffffc0201c12:	c110                	sw	a2,0(a0)
ffffffffc0201c14:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c16:	06b2                	sll	a3,a3,0xc
ffffffffc0201c18:	08e7fc63          	bgeu	a5,a4,ffffffffc0201cb0 <get_pte+0x1a6>
ffffffffc0201c1c:	000ab503          	ld	a0,0(s5)
ffffffffc0201c20:	6605                	lui	a2,0x1
ffffffffc0201c22:	4581                	li	a1,0
ffffffffc0201c24:	9536                	add	a0,a0,a3
ffffffffc0201c26:	2c6030ef          	jal	ffffffffc0204eec <memset>
    return page - pages + nbase;
ffffffffc0201c2a:	000b3783          	ld	a5,0(s6)
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201c2e:	6b02                	ld	s6,0(sp)
ffffffffc0201c30:	40f486b3          	sub	a3,s1,a5
ffffffffc0201c34:	8699                	sra	a3,a3,0x6
ffffffffc0201c36:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201c38:	06aa                	sll	a3,a3,0xa
ffffffffc0201c3a:	0116e693          	or	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201c3e:	e014                	sd	a3,0(s0)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201c40:	000a3703          	ld	a4,0(s4)
ffffffffc0201c44:	77fd                	lui	a5,0xfffff
ffffffffc0201c46:	068a                	sll	a3,a3,0x2
ffffffffc0201c48:	8efd                	and	a3,a3,a5
ffffffffc0201c4a:	00c6d793          	srl	a5,a3,0xc
ffffffffc0201c4e:	04e7f463          	bgeu	a5,a4,ffffffffc0201c96 <get_pte+0x18c>
ffffffffc0201c52:	000ab783          	ld	a5,0(s5)
ffffffffc0201c56:	00c95913          	srl	s2,s2,0xc
ffffffffc0201c5a:	1ff97913          	and	s2,s2,511
ffffffffc0201c5e:	96be                	add	a3,a3,a5
ffffffffc0201c60:	090e                	sll	s2,s2,0x3
ffffffffc0201c62:	01268533          	add	a0,a3,s2
}
ffffffffc0201c66:	70e2                	ld	ra,56(sp)
ffffffffc0201c68:	7442                	ld	s0,48(sp)
ffffffffc0201c6a:	74a2                	ld	s1,40(sp)
ffffffffc0201c6c:	7902                	ld	s2,32(sp)
ffffffffc0201c6e:	69e2                	ld	s3,24(sp)
ffffffffc0201c70:	6a42                	ld	s4,16(sp)
ffffffffc0201c72:	6aa2                	ld	s5,8(sp)
ffffffffc0201c74:	6121                	add	sp,sp,64
ffffffffc0201c76:	8082                	ret
            return NULL;
ffffffffc0201c78:	4501                	li	a0,0
ffffffffc0201c7a:	b7f5                	j	ffffffffc0201c66 <get_pte+0x15c>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201c7c:	00004617          	auipc	a2,0x4
ffffffffc0201c80:	f6460613          	add	a2,a2,-156 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0201c84:	0e400593          	li	a1,228
ffffffffc0201c88:	00004517          	auipc	a0,0x4
ffffffffc0201c8c:	07050513          	add	a0,a0,112 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0201c90:	e05a                	sd	s6,0(sp)
ffffffffc0201c92:	fa0fe0ef          	jal	ffffffffc0200432 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201c96:	00004617          	auipc	a2,0x4
ffffffffc0201c9a:	f4a60613          	add	a2,a2,-182 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0201c9e:	0ef00593          	li	a1,239
ffffffffc0201ca2:	00004517          	auipc	a0,0x4
ffffffffc0201ca6:	05650513          	add	a0,a0,86 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0201caa:	e05a                	sd	s6,0(sp)
ffffffffc0201cac:	f86fe0ef          	jal	ffffffffc0200432 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201cb0:	00004617          	auipc	a2,0x4
ffffffffc0201cb4:	f3060613          	add	a2,a2,-208 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0201cb8:	0ec00593          	li	a1,236
ffffffffc0201cbc:	00004517          	auipc	a0,0x4
ffffffffc0201cc0:	03c50513          	add	a0,a0,60 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0201cc4:	f6efe0ef          	jal	ffffffffc0200432 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201cc8:	86aa                	mv	a3,a0
ffffffffc0201cca:	00004617          	auipc	a2,0x4
ffffffffc0201cce:	f1660613          	add	a2,a2,-234 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0201cd2:	0e100593          	li	a1,225
ffffffffc0201cd6:	00004517          	auipc	a0,0x4
ffffffffc0201cda:	02250513          	add	a0,a0,34 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0201cde:	f54fe0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0201ce2 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201ce2:	1141                	add	sp,sp,-16
ffffffffc0201ce4:	e022                	sd	s0,0(sp)
ffffffffc0201ce6:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201ce8:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201cea:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201cec:	e1fff0ef          	jal	ffffffffc0201b0a <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201cf0:	c011                	beqz	s0,ffffffffc0201cf4 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201cf2:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201cf4:	c511                	beqz	a0,ffffffffc0201d00 <get_page+0x1e>
ffffffffc0201cf6:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201cf8:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201cfa:	0017f713          	and	a4,a5,1
ffffffffc0201cfe:	e709                	bnez	a4,ffffffffc0201d08 <get_page+0x26>
}
ffffffffc0201d00:	60a2                	ld	ra,8(sp)
ffffffffc0201d02:	6402                	ld	s0,0(sp)
ffffffffc0201d04:	0141                	add	sp,sp,16
ffffffffc0201d06:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d08:	078a                	sll	a5,a5,0x2
ffffffffc0201d0a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d0c:	00015717          	auipc	a4,0x15
ffffffffc0201d10:	86c73703          	ld	a4,-1940(a4) # ffffffffc0216578 <npage>
ffffffffc0201d14:	00e7ff63          	bgeu	a5,a4,ffffffffc0201d32 <get_page+0x50>
ffffffffc0201d18:	60a2                	ld	ra,8(sp)
ffffffffc0201d1a:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201d1c:	fff80737          	lui	a4,0xfff80
ffffffffc0201d20:	97ba                	add	a5,a5,a4
ffffffffc0201d22:	00015517          	auipc	a0,0x15
ffffffffc0201d26:	85e53503          	ld	a0,-1954(a0) # ffffffffc0216580 <pages>
ffffffffc0201d2a:	079a                	sll	a5,a5,0x6
ffffffffc0201d2c:	953e                	add	a0,a0,a5
ffffffffc0201d2e:	0141                	add	sp,sp,16
ffffffffc0201d30:	8082                	ret
ffffffffc0201d32:	c97ff0ef          	jal	ffffffffc02019c8 <pa2page.part.0>

ffffffffc0201d36 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201d36:	7179                	add	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d38:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0201d3a:	ec26                	sd	s1,24(sp)
ffffffffc0201d3c:	f406                	sd	ra,40(sp)
ffffffffc0201d3e:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201d40:	dcbff0ef          	jal	ffffffffc0201b0a <get_pte>
    if (ptep != NULL) {
ffffffffc0201d44:	c901                	beqz	a0,ffffffffc0201d54 <page_remove+0x1e>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0201d46:	611c                	ld	a5,0(a0)
ffffffffc0201d48:	f022                	sd	s0,32(sp)
ffffffffc0201d4a:	842a                	mv	s0,a0
ffffffffc0201d4c:	0017f713          	and	a4,a5,1
ffffffffc0201d50:	e711                	bnez	a4,ffffffffc0201d5c <page_remove+0x26>
ffffffffc0201d52:	7402                	ld	s0,32(sp)
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201d54:	70a2                	ld	ra,40(sp)
ffffffffc0201d56:	64e2                	ld	s1,24(sp)
ffffffffc0201d58:	6145                	add	sp,sp,48
ffffffffc0201d5a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201d5c:	078a                	sll	a5,a5,0x2
ffffffffc0201d5e:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201d60:	00015717          	auipc	a4,0x15
ffffffffc0201d64:	81873703          	ld	a4,-2024(a4) # ffffffffc0216578 <npage>
ffffffffc0201d68:	06e7f363          	bgeu	a5,a4,ffffffffc0201dce <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d6c:	fff80737          	lui	a4,0xfff80
ffffffffc0201d70:	97ba                	add	a5,a5,a4
ffffffffc0201d72:	079a                	sll	a5,a5,0x6
ffffffffc0201d74:	00015517          	auipc	a0,0x15
ffffffffc0201d78:	80c53503          	ld	a0,-2036(a0) # ffffffffc0216580 <pages>
ffffffffc0201d7c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201d7e:	411c                	lw	a5,0(a0)
ffffffffc0201d80:	fff7871b          	addw	a4,a5,-1 # ffffffffffffefff <end+0x3fde8a2f>
ffffffffc0201d84:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201d86:	cb11                	beqz	a4,ffffffffc0201d9a <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201d88:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201d8c:	12048073          	sfence.vma	s1
ffffffffc0201d90:	7402                	ld	s0,32(sp)
}
ffffffffc0201d92:	70a2                	ld	ra,40(sp)
ffffffffc0201d94:	64e2                	ld	s1,24(sp)
ffffffffc0201d96:	6145                	add	sp,sp,48
ffffffffc0201d98:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d9e:	8b89                	and	a5,a5,2
ffffffffc0201da0:	eb89                	bnez	a5,ffffffffc0201db2 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201da2:	00014797          	auipc	a5,0x14
ffffffffc0201da6:	7b67b783          	ld	a5,1974(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201daa:	739c                	ld	a5,32(a5)
ffffffffc0201dac:	4585                	li	a1,1
ffffffffc0201dae:	9782                	jalr	a5
    if (flag) {
ffffffffc0201db0:	bfe1                	j	ffffffffc0201d88 <page_remove+0x52>
        intr_disable();
ffffffffc0201db2:	e42a                	sd	a0,8(sp)
ffffffffc0201db4:	ffcfe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0201db8:	00014797          	auipc	a5,0x14
ffffffffc0201dbc:	7a07b783          	ld	a5,1952(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201dc0:	739c                	ld	a5,32(a5)
ffffffffc0201dc2:	6522                	ld	a0,8(sp)
ffffffffc0201dc4:	4585                	li	a1,1
ffffffffc0201dc6:	9782                	jalr	a5
        intr_enable();
ffffffffc0201dc8:	fe2fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0201dcc:	bf75                	j	ffffffffc0201d88 <page_remove+0x52>
ffffffffc0201dce:	bfbff0ef          	jal	ffffffffc02019c8 <pa2page.part.0>

ffffffffc0201dd2 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201dd2:	7139                	add	sp,sp,-64
ffffffffc0201dd4:	e852                	sd	s4,16(sp)
ffffffffc0201dd6:	8a32                	mv	s4,a2
ffffffffc0201dd8:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201dda:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201ddc:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201dde:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201de0:	f426                	sd	s1,40(sp)
ffffffffc0201de2:	fc06                	sd	ra,56(sp)
ffffffffc0201de4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201de6:	d25ff0ef          	jal	ffffffffc0201b0a <get_pte>
    if (ptep == NULL) {
ffffffffc0201dea:	c971                	beqz	a0,ffffffffc0201ebe <page_insert+0xec>
    page->ref += 1;
ffffffffc0201dec:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0201dee:	611c                	ld	a5,0(a0)
ffffffffc0201df0:	ec4e                	sd	s3,24(sp)
ffffffffc0201df2:	0016871b          	addw	a4,a3,1
ffffffffc0201df6:	c018                	sw	a4,0(s0)
ffffffffc0201df8:	0017f713          	and	a4,a5,1
ffffffffc0201dfc:	89aa                	mv	s3,a0
ffffffffc0201dfe:	eb15                	bnez	a4,ffffffffc0201e32 <page_insert+0x60>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e00:	00014717          	auipc	a4,0x14
ffffffffc0201e04:	78073703          	ld	a4,1920(a4) # ffffffffc0216580 <pages>
    return page - pages + nbase;
ffffffffc0201e08:	8c19                	sub	s0,s0,a4
ffffffffc0201e0a:	000807b7          	lui	a5,0x80
ffffffffc0201e0e:	8419                	sra	s0,s0,0x6
ffffffffc0201e10:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e12:	042a                	sll	s0,s0,0xa
ffffffffc0201e14:	8cc1                	or	s1,s1,s0
ffffffffc0201e16:	0014e493          	or	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201e1a:	0099b023          	sd	s1,0(s3) # 80000 <kern_entry-0xffffffffc0180000>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201e1e:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0201e22:	69e2                	ld	s3,24(sp)
ffffffffc0201e24:	4501                	li	a0,0
}
ffffffffc0201e26:	70e2                	ld	ra,56(sp)
ffffffffc0201e28:	7442                	ld	s0,48(sp)
ffffffffc0201e2a:	74a2                	ld	s1,40(sp)
ffffffffc0201e2c:	6a42                	ld	s4,16(sp)
ffffffffc0201e2e:	6121                	add	sp,sp,64
ffffffffc0201e30:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201e32:	078a                	sll	a5,a5,0x2
ffffffffc0201e34:	f04a                	sd	s2,32(sp)
ffffffffc0201e36:	e456                	sd	s5,8(sp)
ffffffffc0201e38:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e3a:	00014717          	auipc	a4,0x14
ffffffffc0201e3e:	73e73703          	ld	a4,1854(a4) # ffffffffc0216578 <npage>
ffffffffc0201e42:	08e7f063          	bgeu	a5,a4,ffffffffc0201ec2 <page_insert+0xf0>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e46:	00014a97          	auipc	s5,0x14
ffffffffc0201e4a:	73aa8a93          	add	s5,s5,1850 # ffffffffc0216580 <pages>
ffffffffc0201e4e:	000ab703          	ld	a4,0(s5)
ffffffffc0201e52:	fff80637          	lui	a2,0xfff80
ffffffffc0201e56:	00c78933          	add	s2,a5,a2
ffffffffc0201e5a:	091a                	sll	s2,s2,0x6
ffffffffc0201e5c:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0201e5e:	01240e63          	beq	s0,s2,ffffffffc0201e7a <page_insert+0xa8>
    page->ref -= 1;
ffffffffc0201e62:	00092783          	lw	a5,0(s2)
ffffffffc0201e66:	fff7869b          	addw	a3,a5,-1 # 7ffff <kern_entry-0xffffffffc0180001>
ffffffffc0201e6a:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0201e6e:	ca91                	beqz	a3,ffffffffc0201e82 <page_insert+0xb0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201e70:	120a0073          	sfence.vma	s4
ffffffffc0201e74:	7902                	ld	s2,32(sp)
ffffffffc0201e76:	6aa2                	ld	s5,8(sp)
}
ffffffffc0201e78:	bf41                	j	ffffffffc0201e08 <page_insert+0x36>
    return page->ref;
ffffffffc0201e7a:	7902                	ld	s2,32(sp)
ffffffffc0201e7c:	6aa2                	ld	s5,8(sp)
    page->ref -= 1;
ffffffffc0201e7e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201e80:	b761                	j	ffffffffc0201e08 <page_insert+0x36>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201e82:	100027f3          	csrr	a5,sstatus
ffffffffc0201e86:	8b89                	and	a5,a5,2
ffffffffc0201e88:	ef81                	bnez	a5,ffffffffc0201ea0 <page_insert+0xce>
        pmm_manager->free_pages(base, n);
ffffffffc0201e8a:	00014797          	auipc	a5,0x14
ffffffffc0201e8e:	6ce7b783          	ld	a5,1742(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201e92:	739c                	ld	a5,32(a5)
ffffffffc0201e94:	4585                	li	a1,1
ffffffffc0201e96:	854a                	mv	a0,s2
ffffffffc0201e98:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0201e9a:	000ab703          	ld	a4,0(s5)
ffffffffc0201e9e:	bfc9                	j	ffffffffc0201e70 <page_insert+0x9e>
        intr_disable();
ffffffffc0201ea0:	f10fe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0201ea4:	00014797          	auipc	a5,0x14
ffffffffc0201ea8:	6b47b783          	ld	a5,1716(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0201eac:	739c                	ld	a5,32(a5)
ffffffffc0201eae:	4585                	li	a1,1
ffffffffc0201eb0:	854a                	mv	a0,s2
ffffffffc0201eb2:	9782                	jalr	a5
        intr_enable();
ffffffffc0201eb4:	ef6fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0201eb8:	000ab703          	ld	a4,0(s5)
ffffffffc0201ebc:	bf55                	j	ffffffffc0201e70 <page_insert+0x9e>
        return -E_NO_MEM;
ffffffffc0201ebe:	5571                	li	a0,-4
ffffffffc0201ec0:	b79d                	j	ffffffffc0201e26 <page_insert+0x54>
ffffffffc0201ec2:	b07ff0ef          	jal	ffffffffc02019c8 <pa2page.part.0>

ffffffffc0201ec6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201ec6:	00005797          	auipc	a5,0x5
ffffffffc0201eca:	f9a78793          	add	a5,a5,-102 # ffffffffc0206e60 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201ece:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201ed0:	711d                	add	sp,sp,-96
ffffffffc0201ed2:	ec86                	sd	ra,88(sp)
ffffffffc0201ed4:	e4a6                	sd	s1,72(sp)
ffffffffc0201ed6:	fc4e                	sd	s3,56(sp)
ffffffffc0201ed8:	f05a                	sd	s6,32(sp)
ffffffffc0201eda:	ec5e                	sd	s7,24(sp)
ffffffffc0201edc:	e8a2                	sd	s0,80(sp)
ffffffffc0201ede:	e0ca                	sd	s2,64(sp)
ffffffffc0201ee0:	f852                	sd	s4,48(sp)
ffffffffc0201ee2:	f456                	sd	s5,40(sp)
ffffffffc0201ee4:	e862                	sd	s8,16(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201ee6:	00014b97          	auipc	s7,0x14
ffffffffc0201eea:	672b8b93          	add	s7,s7,1650 # ffffffffc0216558 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201eee:	00004517          	auipc	a0,0x4
ffffffffc0201ef2:	e1a50513          	add	a0,a0,-486 # ffffffffc0205d08 <etext+0xdce>
    pmm_manager = &default_pmm_manager;
ffffffffc0201ef6:	00fbb023          	sd	a5,0(s7)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201efa:	a86fe0ef          	jal	ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc0201efe:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f02:	00014997          	auipc	s3,0x14
ffffffffc0201f06:	66e98993          	add	s3,s3,1646 # ffffffffc0216570 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0201f0a:	00014497          	auipc	s1,0x14
ffffffffc0201f0e:	66e48493          	add	s1,s1,1646 # ffffffffc0216578 <npage>
    pmm_manager->init();
ffffffffc0201f12:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f14:	00014b17          	auipc	s6,0x14
ffffffffc0201f18:	66cb0b13          	add	s6,s6,1644 # ffffffffc0216580 <pages>
    pmm_manager->init();
ffffffffc0201f1c:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f1e:	57f5                	li	a5,-3
ffffffffc0201f20:	07fa                	sll	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201f22:	00004517          	auipc	a0,0x4
ffffffffc0201f26:	dfe50513          	add	a0,a0,-514 # ffffffffc0205d20 <etext+0xde6>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201f2a:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc0201f2e:	a52fe0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201f32:	46c5                	li	a3,17
ffffffffc0201f34:	06ee                	sll	a3,a3,0x1b
ffffffffc0201f36:	40100613          	li	a2,1025
ffffffffc0201f3a:	16fd                	add	a3,a3,-1
ffffffffc0201f3c:	0656                	sll	a2,a2,0x15
ffffffffc0201f3e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201f42:	00004517          	auipc	a0,0x4
ffffffffc0201f46:	df650513          	add	a0,a0,-522 # ffffffffc0205d38 <etext+0xdfe>
ffffffffc0201f4a:	a36fe0ef          	jal	ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f4e:	777d                	lui	a4,0xfffff
ffffffffc0201f50:	00015797          	auipc	a5,0x15
ffffffffc0201f54:	67f78793          	add	a5,a5,1663 # ffffffffc02175cf <end+0xfff>
ffffffffc0201f58:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201f5a:	00088737          	lui	a4,0x88
ffffffffc0201f5e:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201f60:	00fb3023          	sd	a5,0(s6)
ffffffffc0201f64:	4705                	li	a4,1
ffffffffc0201f66:	07a1                	add	a5,a5,8
ffffffffc0201f68:	40e7b02f          	amoor.d	zero,a4,(a5)
ffffffffc0201f6c:	4505                	li	a0,1
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201f6e:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201f72:	000b3783          	ld	a5,0(s6)
ffffffffc0201f76:	00671693          	sll	a3,a4,0x6
ffffffffc0201f7a:	97b6                	add	a5,a5,a3
ffffffffc0201f7c:	07a1                	add	a5,a5,8
ffffffffc0201f7e:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201f82:	6090                	ld	a2,0(s1)
ffffffffc0201f84:	0705                	add	a4,a4,1 # 88001 <kern_entry-0xffffffffc0177fff>
ffffffffc0201f86:	00b607b3          	add	a5,a2,a1
ffffffffc0201f8a:	fef764e3          	bltu	a4,a5,ffffffffc0201f72 <pmm_init+0xac>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201f8e:	000b3503          	ld	a0,0(s6)
ffffffffc0201f92:	079a                	sll	a5,a5,0x6
ffffffffc0201f94:	c0200737          	lui	a4,0xc0200
ffffffffc0201f98:	00f506b3          	add	a3,a0,a5
ffffffffc0201f9c:	60e6e463          	bltu	a3,a4,ffffffffc02025a4 <pmm_init+0x6de>
ffffffffc0201fa0:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0201fa4:	4745                	li	a4,17
ffffffffc0201fa6:	076e                	sll	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201fa8:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0201faa:	4ae6e363          	bltu	a3,a4,ffffffffc0202450 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0201fae:	00004517          	auipc	a0,0x4
ffffffffc0201fb2:	db250513          	add	a0,a0,-590 # ffffffffc0205d60 <etext+0xe26>
ffffffffc0201fb6:	9cafe0ef          	jal	ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201fba:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201fbe:	00014917          	auipc	s2,0x14
ffffffffc0201fc2:	5aa90913          	add	s2,s2,1450 # ffffffffc0216568 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201fc6:	7b9c                	ld	a5,48(a5)
ffffffffc0201fc8:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201fca:	00004517          	auipc	a0,0x4
ffffffffc0201fce:	dae50513          	add	a0,a0,-594 # ffffffffc0205d78 <etext+0xe3e>
ffffffffc0201fd2:	9aefe0ef          	jal	ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201fd6:	00008697          	auipc	a3,0x8
ffffffffc0201fda:	02a68693          	add	a3,a3,42 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0201fde:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201fe2:	c02007b7          	lui	a5,0xc0200
ffffffffc0201fe6:	5cf6eb63          	bltu	a3,a5,ffffffffc02025bc <pmm_init+0x6f6>
ffffffffc0201fea:	0009b783          	ld	a5,0(s3)
ffffffffc0201fee:	8e9d                	sub	a3,a3,a5
ffffffffc0201ff0:	00014797          	auipc	a5,0x14
ffffffffc0201ff4:	56d7b823          	sd	a3,1392(a5) # ffffffffc0216560 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ff8:	100027f3          	csrr	a5,sstatus
ffffffffc0201ffc:	8b89                	and	a5,a5,2
ffffffffc0201ffe:	48079163          	bnez	a5,ffffffffc0202480 <pmm_init+0x5ba>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202002:	000bb783          	ld	a5,0(s7)
ffffffffc0202006:	779c                	ld	a5,40(a5)
ffffffffc0202008:	9782                	jalr	a5
ffffffffc020200a:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020200c:	6098                	ld	a4,0(s1)
ffffffffc020200e:	c80007b7          	lui	a5,0xc8000
ffffffffc0202012:	83b1                	srl	a5,a5,0xc
ffffffffc0202014:	5ee7e063          	bltu	a5,a4,ffffffffc02025f4 <pmm_init+0x72e>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202018:	00093503          	ld	a0,0(s2)
ffffffffc020201c:	5a050c63          	beqz	a0,ffffffffc02025d4 <pmm_init+0x70e>
ffffffffc0202020:	03451793          	sll	a5,a0,0x34
ffffffffc0202024:	5a079863          	bnez	a5,ffffffffc02025d4 <pmm_init+0x70e>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202028:	4601                	li	a2,0
ffffffffc020202a:	4581                	li	a1,0
ffffffffc020202c:	cb7ff0ef          	jal	ffffffffc0201ce2 <get_page>
ffffffffc0202030:	62051463          	bnez	a0,ffffffffc0202658 <pmm_init+0x792>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0202034:	4505                	li	a0,1
ffffffffc0202036:	9cbff0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc020203a:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020203c:	00093503          	ld	a0,0(s2)
ffffffffc0202040:	4681                	li	a3,0
ffffffffc0202042:	4601                	li	a2,0
ffffffffc0202044:	85d2                	mv	a1,s4
ffffffffc0202046:	d8dff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc020204a:	5e051763          	bnez	a0,ffffffffc0202638 <pmm_init+0x772>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020204e:	00093503          	ld	a0,0(s2)
ffffffffc0202052:	4601                	li	a2,0
ffffffffc0202054:	4581                	li	a1,0
ffffffffc0202056:	ab5ff0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc020205a:	5a050f63          	beqz	a0,ffffffffc0202618 <pmm_init+0x752>
    assert(pte2page(*ptep) == p1);
ffffffffc020205e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202060:	0017f713          	and	a4,a5,1
ffffffffc0202064:	5a070863          	beqz	a4,ffffffffc0202614 <pmm_init+0x74e>
    if (PPN(pa) >= npage) {
ffffffffc0202068:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020206a:	078a                	sll	a5,a5,0x2
ffffffffc020206c:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020206e:	52e7f963          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202072:	000b3683          	ld	a3,0(s6)
ffffffffc0202076:	fff80637          	lui	a2,0xfff80
ffffffffc020207a:	97b2                	add	a5,a5,a2
ffffffffc020207c:	079a                	sll	a5,a5,0x6
ffffffffc020207e:	97b6                	add	a5,a5,a3
ffffffffc0202080:	10fa15e3          	bne	s4,a5,ffffffffc020298a <pmm_init+0xac4>
    assert(page_ref(p1) == 1);
ffffffffc0202084:	000a2683          	lw	a3,0(s4)
ffffffffc0202088:	4785                	li	a5,1
ffffffffc020208a:	12f69ce3          	bne	a3,a5,ffffffffc02029c2 <pmm_init+0xafc>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020208e:	00093503          	ld	a0,0(s2)
ffffffffc0202092:	77fd                	lui	a5,0xfffff
ffffffffc0202094:	6114                	ld	a3,0(a0)
ffffffffc0202096:	068a                	sll	a3,a3,0x2
ffffffffc0202098:	8efd                	and	a3,a3,a5
ffffffffc020209a:	00c6d613          	srl	a2,a3,0xc
ffffffffc020209e:	10e676e3          	bgeu	a2,a4,ffffffffc02029aa <pmm_init+0xae4>
ffffffffc02020a2:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020a6:	96e2                	add	a3,a3,s8
ffffffffc02020a8:	0006ba83          	ld	s5,0(a3)
ffffffffc02020ac:	0a8a                	sll	s5,s5,0x2
ffffffffc02020ae:	00fafab3          	and	s5,s5,a5
ffffffffc02020b2:	00cad793          	srl	a5,s5,0xc
ffffffffc02020b6:	62e7f163          	bgeu	a5,a4,ffffffffc02026d8 <pmm_init+0x812>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020ba:	4601                	li	a2,0
ffffffffc02020bc:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020be:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020c0:	a4bff0ef          	jal	ffffffffc0201b0a <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02020c4:	0c21                	add	s8,s8,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02020c6:	5f851963          	bne	a0,s8,ffffffffc02026b8 <pmm_init+0x7f2>

    p2 = alloc_page();
ffffffffc02020ca:	4505                	li	a0,1
ffffffffc02020cc:	935ff0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc02020d0:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02020d2:	00093503          	ld	a0,0(s2)
ffffffffc02020d6:	46d1                	li	a3,20
ffffffffc02020d8:	6605                	lui	a2,0x1
ffffffffc02020da:	85d6                	mv	a1,s5
ffffffffc02020dc:	cf7ff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc02020e0:	58051c63          	bnez	a0,ffffffffc0202678 <pmm_init+0x7b2>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02020e4:	00093503          	ld	a0,0(s2)
ffffffffc02020e8:	4601                	li	a2,0
ffffffffc02020ea:	6585                	lui	a1,0x1
ffffffffc02020ec:	a1fff0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc02020f0:	0e0509e3          	beqz	a0,ffffffffc02029e2 <pmm_init+0xb1c>
    assert(*ptep & PTE_U);
ffffffffc02020f4:	611c                	ld	a5,0(a0)
ffffffffc02020f6:	0107f713          	and	a4,a5,16
ffffffffc02020fa:	6e070c63          	beqz	a4,ffffffffc02027f2 <pmm_init+0x92c>
    assert(*ptep & PTE_W);
ffffffffc02020fe:	8b91                	and	a5,a5,4
ffffffffc0202100:	6a078963          	beqz	a5,ffffffffc02027b2 <pmm_init+0x8ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202104:	00093503          	ld	a0,0(s2)
ffffffffc0202108:	611c                	ld	a5,0(a0)
ffffffffc020210a:	8bc1                	and	a5,a5,16
ffffffffc020210c:	68078363          	beqz	a5,ffffffffc0202792 <pmm_init+0x8cc>
    assert(page_ref(p2) == 1);
ffffffffc0202110:	000aa703          	lw	a4,0(s5)
ffffffffc0202114:	4785                	li	a5,1
ffffffffc0202116:	58f71163          	bne	a4,a5,ffffffffc0202698 <pmm_init+0x7d2>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc020211a:	4681                	li	a3,0
ffffffffc020211c:	6605                	lui	a2,0x1
ffffffffc020211e:	85d2                	mv	a1,s4
ffffffffc0202120:	cb3ff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc0202124:	62051763          	bnez	a0,ffffffffc0202752 <pmm_init+0x88c>
    assert(page_ref(p1) == 2);
ffffffffc0202128:	000a2703          	lw	a4,0(s4)
ffffffffc020212c:	4789                	li	a5,2
ffffffffc020212e:	60f71263          	bne	a4,a5,ffffffffc0202732 <pmm_init+0x86c>
    assert(page_ref(p2) == 0);
ffffffffc0202132:	000aa783          	lw	a5,0(s5)
ffffffffc0202136:	5c079e63          	bnez	a5,ffffffffc0202712 <pmm_init+0x84c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020213a:	00093503          	ld	a0,0(s2)
ffffffffc020213e:	4601                	li	a2,0
ffffffffc0202140:	6585                	lui	a1,0x1
ffffffffc0202142:	9c9ff0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc0202146:	5a050663          	beqz	a0,ffffffffc02026f2 <pmm_init+0x82c>
    assert(pte2page(*ptep) == p1);
ffffffffc020214a:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020214c:	00177793          	and	a5,a4,1
ffffffffc0202150:	4c078263          	beqz	a5,ffffffffc0202614 <pmm_init+0x74e>
    if (PPN(pa) >= npage) {
ffffffffc0202154:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202156:	00271793          	sll	a5,a4,0x2
ffffffffc020215a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020215c:	44d7f263          	bgeu	a5,a3,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202160:	000b3683          	ld	a3,0(s6)
ffffffffc0202164:	fff80637          	lui	a2,0xfff80
ffffffffc0202168:	97b2                	add	a5,a5,a2
ffffffffc020216a:	079a                	sll	a5,a5,0x6
ffffffffc020216c:	97b6                	add	a5,a5,a3
ffffffffc020216e:	6efa1263          	bne	s4,a5,ffffffffc0202852 <pmm_init+0x98c>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202172:	8b41                	and	a4,a4,16
ffffffffc0202174:	6a071f63          	bnez	a4,ffffffffc0202832 <pmm_init+0x96c>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202178:	00093503          	ld	a0,0(s2)
ffffffffc020217c:	4581                	li	a1,0
ffffffffc020217e:	bb9ff0ef          	jal	ffffffffc0201d36 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202182:	000a2703          	lw	a4,0(s4)
ffffffffc0202186:	4785                	li	a5,1
ffffffffc0202188:	68f71563          	bne	a4,a5,ffffffffc0202812 <pmm_init+0x94c>
    assert(page_ref(p2) == 0);
ffffffffc020218c:	000aa783          	lw	a5,0(s5)
ffffffffc0202190:	74079d63          	bnez	a5,ffffffffc02028ea <pmm_init+0xa24>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202194:	00093503          	ld	a0,0(s2)
ffffffffc0202198:	6585                	lui	a1,0x1
ffffffffc020219a:	b9dff0ef          	jal	ffffffffc0201d36 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020219e:	000a2783          	lw	a5,0(s4)
ffffffffc02021a2:	72079463          	bnez	a5,ffffffffc02028ca <pmm_init+0xa04>
    assert(page_ref(p2) == 0);
ffffffffc02021a6:	000aa783          	lw	a5,0(s5)
ffffffffc02021aa:	70079063          	bnez	a5,ffffffffc02028aa <pmm_init+0x9e4>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02021ae:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02021b2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021b4:	000a3783          	ld	a5,0(s4)
ffffffffc02021b8:	078a                	sll	a5,a5,0x2
ffffffffc02021ba:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021bc:	3ee7f263          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc02021c0:	fff806b7          	lui	a3,0xfff80
ffffffffc02021c4:	000b3503          	ld	a0,0(s6)
ffffffffc02021c8:	97b6                	add	a5,a5,a3
ffffffffc02021ca:	079a                	sll	a5,a5,0x6
    return page->ref;
ffffffffc02021cc:	00f506b3          	add	a3,a0,a5
ffffffffc02021d0:	4290                	lw	a2,0(a3)
ffffffffc02021d2:	4685                	li	a3,1
ffffffffc02021d4:	6ad61b63          	bne	a2,a3,ffffffffc020288a <pmm_init+0x9c4>
    return page - pages + nbase;
ffffffffc02021d8:	8799                	sra	a5,a5,0x6
ffffffffc02021da:	00080637          	lui	a2,0x80
ffffffffc02021de:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02021e0:	00c79693          	sll	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02021e4:	68e7f763          	bgeu	a5,a4,ffffffffc0202872 <pmm_init+0x9ac>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02021e8:	0009b783          	ld	a5,0(s3)
ffffffffc02021ec:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc02021ee:	639c                	ld	a5,0(a5)
ffffffffc02021f0:	078a                	sll	a5,a5,0x2
ffffffffc02021f2:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02021f4:	3ae7f663          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc02021f8:	8f91                	sub	a5,a5,a2
ffffffffc02021fa:	079a                	sll	a5,a5,0x6
ffffffffc02021fc:	953e                	add	a0,a0,a5
ffffffffc02021fe:	100027f3          	csrr	a5,sstatus
ffffffffc0202202:	8b89                	and	a5,a5,2
ffffffffc0202204:	2c079863          	bnez	a5,ffffffffc02024d4 <pmm_init+0x60e>
        pmm_manager->free_pages(base, n);
ffffffffc0202208:	000bb783          	ld	a5,0(s7)
ffffffffc020220c:	4585                	li	a1,1
ffffffffc020220e:	739c                	ld	a5,32(a5)
ffffffffc0202210:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202212:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202216:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202218:	078a                	sll	a5,a5,0x2
ffffffffc020221a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020221c:	38e7f263          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc0202220:	000b3503          	ld	a0,0(s6)
ffffffffc0202224:	fff80737          	lui	a4,0xfff80
ffffffffc0202228:	97ba                	add	a5,a5,a4
ffffffffc020222a:	079a                	sll	a5,a5,0x6
ffffffffc020222c:	953e                	add	a0,a0,a5
ffffffffc020222e:	100027f3          	csrr	a5,sstatus
ffffffffc0202232:	8b89                	and	a5,a5,2
ffffffffc0202234:	28079463          	bnez	a5,ffffffffc02024bc <pmm_init+0x5f6>
ffffffffc0202238:	000bb783          	ld	a5,0(s7)
ffffffffc020223c:	4585                	li	a1,1
ffffffffc020223e:	739c                	ld	a5,32(a5)
ffffffffc0202240:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202242:	00093783          	ld	a5,0(s2)
ffffffffc0202246:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fde8a30>
  asm volatile("sfence.vma");
ffffffffc020224a:	12000073          	sfence.vma
ffffffffc020224e:	100027f3          	csrr	a5,sstatus
ffffffffc0202252:	8b89                	and	a5,a5,2
ffffffffc0202254:	24079a63          	bnez	a5,ffffffffc02024a8 <pmm_init+0x5e2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202258:	000bb783          	ld	a5,0(s7)
ffffffffc020225c:	779c                	ld	a5,40(a5)
ffffffffc020225e:	9782                	jalr	a5
ffffffffc0202260:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202262:	71441463          	bne	s0,s4,ffffffffc020296a <pmm_init+0xaa4>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202266:	00004517          	auipc	a0,0x4
ffffffffc020226a:	dfa50513          	add	a0,a0,-518 # ffffffffc0206060 <etext+0x1126>
ffffffffc020226e:	f13fd0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0202272:	100027f3          	csrr	a5,sstatus
ffffffffc0202276:	8b89                	and	a5,a5,2
ffffffffc0202278:	20079e63          	bnez	a5,ffffffffc0202494 <pmm_init+0x5ce>
        ret = pmm_manager->nr_free_pages();
ffffffffc020227c:	000bb783          	ld	a5,0(s7)
ffffffffc0202280:	779c                	ld	a5,40(a5)
ffffffffc0202282:	9782                	jalr	a5
ffffffffc0202284:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202286:	6098                	ld	a4,0(s1)
ffffffffc0202288:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020228c:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020228e:	00c71793          	sll	a5,a4,0xc
ffffffffc0202292:	6a05                	lui	s4,0x1
ffffffffc0202294:	02f47c63          	bgeu	s0,a5,ffffffffc02022cc <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202298:	00c45793          	srl	a5,s0,0xc
ffffffffc020229c:	00093503          	ld	a0,0(s2)
ffffffffc02022a0:	2ee7f363          	bgeu	a5,a4,ffffffffc0202586 <pmm_init+0x6c0>
ffffffffc02022a4:	0009b583          	ld	a1,0(s3)
ffffffffc02022a8:	4601                	li	a2,0
ffffffffc02022aa:	95a2                	add	a1,a1,s0
ffffffffc02022ac:	85fff0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc02022b0:	2a050b63          	beqz	a0,ffffffffc0202566 <pmm_init+0x6a0>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02022b4:	611c                	ld	a5,0(a0)
ffffffffc02022b6:	078a                	sll	a5,a5,0x2
ffffffffc02022b8:	0157f7b3          	and	a5,a5,s5
ffffffffc02022bc:	28879563          	bne	a5,s0,ffffffffc0202546 <pmm_init+0x680>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02022c0:	6098                	ld	a4,0(s1)
ffffffffc02022c2:	9452                	add	s0,s0,s4
ffffffffc02022c4:	00c71793          	sll	a5,a4,0xc
ffffffffc02022c8:	fcf468e3          	bltu	s0,a5,ffffffffc0202298 <pmm_init+0x3d2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc02022cc:	00093783          	ld	a5,0(s2)
ffffffffc02022d0:	639c                	ld	a5,0(a5)
ffffffffc02022d2:	66079c63          	bnez	a5,ffffffffc020294a <pmm_init+0xa84>

    struct Page *p;
    p = alloc_page();
ffffffffc02022d6:	4505                	li	a0,1
ffffffffc02022d8:	f28ff0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc02022dc:	842a                	mv	s0,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02022de:	00093503          	ld	a0,0(s2)
ffffffffc02022e2:	4699                	li	a3,6
ffffffffc02022e4:	10000613          	li	a2,256
ffffffffc02022e8:	85a2                	mv	a1,s0
ffffffffc02022ea:	ae9ff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc02022ee:	62051e63          	bnez	a0,ffffffffc020292a <pmm_init+0xa64>
    assert(page_ref(p) == 1);
ffffffffc02022f2:	4018                	lw	a4,0(s0)
ffffffffc02022f4:	4785                	li	a5,1
ffffffffc02022f6:	60f71a63          	bne	a4,a5,ffffffffc020290a <pmm_init+0xa44>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02022fa:	00093503          	ld	a0,0(s2)
ffffffffc02022fe:	6605                	lui	a2,0x1
ffffffffc0202300:	4699                	li	a3,6
ffffffffc0202302:	10060613          	add	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0202306:	85a2                	mv	a1,s0
ffffffffc0202308:	acbff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc020230c:	46051363          	bnez	a0,ffffffffc0202772 <pmm_init+0x8ac>
    assert(page_ref(p) == 2);
ffffffffc0202310:	4018                	lw	a4,0(s0)
ffffffffc0202312:	4789                	li	a5,2
ffffffffc0202314:	72f71763          	bne	a4,a5,ffffffffc0202a42 <pmm_init+0xb7c>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202318:	00004597          	auipc	a1,0x4
ffffffffc020231c:	e8058593          	add	a1,a1,-384 # ffffffffc0206198 <etext+0x125e>
ffffffffc0202320:	10000513          	li	a0,256
ffffffffc0202324:	369020ef          	jal	ffffffffc0204e8c <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202328:	6585                	lui	a1,0x1
ffffffffc020232a:	10058593          	add	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020232e:	10000513          	li	a0,256
ffffffffc0202332:	36d020ef          	jal	ffffffffc0204e9e <strcmp>
ffffffffc0202336:	6e051663          	bnez	a0,ffffffffc0202a22 <pmm_init+0xb5c>
    return page - pages + nbase;
ffffffffc020233a:	000b3683          	ld	a3,0(s6)
ffffffffc020233e:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202342:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202344:	40d406b3          	sub	a3,s0,a3
ffffffffc0202348:	8699                	sra	a3,a3,0x6
ffffffffc020234a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020234c:	00c69793          	sll	a5,a3,0xc
ffffffffc0202350:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202352:	06b2                	sll	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202354:	50e7ff63          	bgeu	a5,a4,ffffffffc0202872 <pmm_init+0x9ac>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202358:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020235c:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202360:	97b6                	add	a5,a5,a3
ffffffffc0202362:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202366:	2f1020ef          	jal	ffffffffc0204e56 <strlen>
ffffffffc020236a:	68051c63          	bnez	a0,ffffffffc0202a02 <pmm_init+0xb3c>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc020236e:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202372:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202374:	000a3783          	ld	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202378:	078a                	sll	a5,a5,0x2
ffffffffc020237a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020237c:	22e7f263          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202380:	00c79693          	sll	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202384:	4ee7f763          	bgeu	a5,a4,ffffffffc0202872 <pmm_init+0x9ac>
ffffffffc0202388:	0009b783          	ld	a5,0(s3)
ffffffffc020238c:	00f689b3          	add	s3,a3,a5
ffffffffc0202390:	100027f3          	csrr	a5,sstatus
ffffffffc0202394:	8b89                	and	a5,a5,2
ffffffffc0202396:	18079d63          	bnez	a5,ffffffffc0202530 <pmm_init+0x66a>
        pmm_manager->free_pages(base, n);
ffffffffc020239a:	000bb783          	ld	a5,0(s7)
ffffffffc020239e:	4585                	li	a1,1
ffffffffc02023a0:	8522                	mv	a0,s0
ffffffffc02023a2:	739c                	ld	a5,32(a5)
ffffffffc02023a4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02023a6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc02023aa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023ac:	078a                	sll	a5,a5,0x2
ffffffffc02023ae:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023b0:	1ee7f863          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b4:	000b3503          	ld	a0,0(s6)
ffffffffc02023b8:	fff80737          	lui	a4,0xfff80
ffffffffc02023bc:	97ba                	add	a5,a5,a4
ffffffffc02023be:	079a                	sll	a5,a5,0x6
ffffffffc02023c0:	953e                	add	a0,a0,a5
ffffffffc02023c2:	100027f3          	csrr	a5,sstatus
ffffffffc02023c6:	8b89                	and	a5,a5,2
ffffffffc02023c8:	14079863          	bnez	a5,ffffffffc0202518 <pmm_init+0x652>
ffffffffc02023cc:	000bb783          	ld	a5,0(s7)
ffffffffc02023d0:	4585                	li	a1,1
ffffffffc02023d2:	739c                	ld	a5,32(a5)
ffffffffc02023d4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02023d6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02023da:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023dc:	078a                	sll	a5,a5,0x2
ffffffffc02023de:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023e0:	1ce7f063          	bgeu	a5,a4,ffffffffc02025a0 <pmm_init+0x6da>
    return &pages[PPN(pa) - nbase];
ffffffffc02023e4:	000b3503          	ld	a0,0(s6)
ffffffffc02023e8:	fff80737          	lui	a4,0xfff80
ffffffffc02023ec:	97ba                	add	a5,a5,a4
ffffffffc02023ee:	079a                	sll	a5,a5,0x6
ffffffffc02023f0:	953e                	add	a0,a0,a5
ffffffffc02023f2:	100027f3          	csrr	a5,sstatus
ffffffffc02023f6:	8b89                	and	a5,a5,2
ffffffffc02023f8:	10079463          	bnez	a5,ffffffffc0202500 <pmm_init+0x63a>
ffffffffc02023fc:	000bb783          	ld	a5,0(s7)
ffffffffc0202400:	4585                	li	a1,1
ffffffffc0202402:	739c                	ld	a5,32(a5)
ffffffffc0202404:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202406:	00093783          	ld	a5,0(s2)
ffffffffc020240a:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc020240e:	12000073          	sfence.vma
ffffffffc0202412:	100027f3          	csrr	a5,sstatus
ffffffffc0202416:	8b89                	and	a5,a5,2
ffffffffc0202418:	0c079a63          	bnez	a5,ffffffffc02024ec <pmm_init+0x626>
        ret = pmm_manager->nr_free_pages();
ffffffffc020241c:	000bb783          	ld	a5,0(s7)
ffffffffc0202420:	779c                	ld	a5,40(a5)
ffffffffc0202422:	9782                	jalr	a5
ffffffffc0202424:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202426:	3a8c1663          	bne	s8,s0,ffffffffc02027d2 <pmm_init+0x90c>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020242a:	00004517          	auipc	a0,0x4
ffffffffc020242e:	de650513          	add	a0,a0,-538 # ffffffffc0206210 <etext+0x12d6>
ffffffffc0202432:	d4ffd0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0202436:	6446                	ld	s0,80(sp)
ffffffffc0202438:	60e6                	ld	ra,88(sp)
ffffffffc020243a:	64a6                	ld	s1,72(sp)
ffffffffc020243c:	6906                	ld	s2,64(sp)
ffffffffc020243e:	79e2                	ld	s3,56(sp)
ffffffffc0202440:	7a42                	ld	s4,48(sp)
ffffffffc0202442:	7aa2                	ld	s5,40(sp)
ffffffffc0202444:	7b02                	ld	s6,32(sp)
ffffffffc0202446:	6be2                	ld	s7,24(sp)
ffffffffc0202448:	6c42                	ld	s8,16(sp)
ffffffffc020244a:	6125                	add	sp,sp,96
    kmalloc_init();
ffffffffc020244c:	bbcff06f          	j	ffffffffc0201808 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202450:	6785                	lui	a5,0x1
ffffffffc0202452:	17fd                	add	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0202454:	96be                	add	a3,a3,a5
ffffffffc0202456:	77fd                	lui	a5,0xfffff
ffffffffc0202458:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc020245a:	00c7d693          	srl	a3,a5,0xc
ffffffffc020245e:	14c6f163          	bgeu	a3,a2,ffffffffc02025a0 <pmm_init+0x6da>
    pmm_manager->init_memmap(base, n);
ffffffffc0202462:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202466:	fff805b7          	lui	a1,0xfff80
ffffffffc020246a:	96ae                	add	a3,a3,a1
ffffffffc020246c:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020246e:	8f1d                	sub	a4,a4,a5
ffffffffc0202470:	069a                	sll	a3,a3,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202472:	00c75593          	srl	a1,a4,0xc
ffffffffc0202476:	9536                	add	a0,a0,a3
ffffffffc0202478:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc020247a:	0009b583          	ld	a1,0(s3)
}
ffffffffc020247e:	be05                	j	ffffffffc0201fae <pmm_init+0xe8>
        intr_disable();
ffffffffc0202480:	930fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202484:	000bb783          	ld	a5,0(s7)
ffffffffc0202488:	779c                	ld	a5,40(a5)
ffffffffc020248a:	9782                	jalr	a5
ffffffffc020248c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020248e:	91cfe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0202492:	bead                	j	ffffffffc020200c <pmm_init+0x146>
        intr_disable();
ffffffffc0202494:	91cfe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0202498:	000bb783          	ld	a5,0(s7)
ffffffffc020249c:	779c                	ld	a5,40(a5)
ffffffffc020249e:	9782                	jalr	a5
ffffffffc02024a0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02024a2:	908fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02024a6:	b3c5                	j	ffffffffc0202286 <pmm_init+0x3c0>
        intr_disable();
ffffffffc02024a8:	908fe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc02024ac:	000bb783          	ld	a5,0(s7)
ffffffffc02024b0:	779c                	ld	a5,40(a5)
ffffffffc02024b2:	9782                	jalr	a5
ffffffffc02024b4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02024b6:	8f4fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02024ba:	b365                	j	ffffffffc0202262 <pmm_init+0x39c>
ffffffffc02024bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02024be:	8f2fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024c2:	000bb783          	ld	a5,0(s7)
ffffffffc02024c6:	6522                	ld	a0,8(sp)
ffffffffc02024c8:	4585                	li	a1,1
ffffffffc02024ca:	739c                	ld	a5,32(a5)
ffffffffc02024cc:	9782                	jalr	a5
        intr_enable();
ffffffffc02024ce:	8dcfe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02024d2:	bb85                	j	ffffffffc0202242 <pmm_init+0x37c>
ffffffffc02024d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02024d6:	8dafe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc02024da:	000bb783          	ld	a5,0(s7)
ffffffffc02024de:	6522                	ld	a0,8(sp)
ffffffffc02024e0:	4585                	li	a1,1
ffffffffc02024e2:	739c                	ld	a5,32(a5)
ffffffffc02024e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02024e6:	8c4fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02024ea:	b325                	j	ffffffffc0202212 <pmm_init+0x34c>
        intr_disable();
ffffffffc02024ec:	8c4fe0ef          	jal	ffffffffc02005b0 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024f0:	000bb783          	ld	a5,0(s7)
ffffffffc02024f4:	779c                	ld	a5,40(a5)
ffffffffc02024f6:	9782                	jalr	a5
ffffffffc02024f8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02024fa:	8b0fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc02024fe:	b725                	j	ffffffffc0202426 <pmm_init+0x560>
ffffffffc0202500:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202502:	8aefe0ef          	jal	ffffffffc02005b0 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202506:	000bb783          	ld	a5,0(s7)
ffffffffc020250a:	6522                	ld	a0,8(sp)
ffffffffc020250c:	4585                	li	a1,1
ffffffffc020250e:	739c                	ld	a5,32(a5)
ffffffffc0202510:	9782                	jalr	a5
        intr_enable();
ffffffffc0202512:	898fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0202516:	bdc5                	j	ffffffffc0202406 <pmm_init+0x540>
ffffffffc0202518:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020251a:	896fe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc020251e:	000bb783          	ld	a5,0(s7)
ffffffffc0202522:	6522                	ld	a0,8(sp)
ffffffffc0202524:	4585                	li	a1,1
ffffffffc0202526:	739c                	ld	a5,32(a5)
ffffffffc0202528:	9782                	jalr	a5
        intr_enable();
ffffffffc020252a:	880fe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc020252e:	b565                	j	ffffffffc02023d6 <pmm_init+0x510>
        intr_disable();
ffffffffc0202530:	880fe0ef          	jal	ffffffffc02005b0 <intr_disable>
ffffffffc0202534:	000bb783          	ld	a5,0(s7)
ffffffffc0202538:	4585                	li	a1,1
ffffffffc020253a:	8522                	mv	a0,s0
ffffffffc020253c:	739c                	ld	a5,32(a5)
ffffffffc020253e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202540:	86afe0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0202544:	b58d                	j	ffffffffc02023a6 <pmm_init+0x4e0>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202546:	00004697          	auipc	a3,0x4
ffffffffc020254a:	b7a68693          	add	a3,a3,-1158 # ffffffffc02060c0 <etext+0x1186>
ffffffffc020254e:	00003617          	auipc	a2,0x3
ffffffffc0202552:	2e260613          	add	a2,a2,738 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202556:	19e00593          	li	a1,414
ffffffffc020255a:	00003517          	auipc	a0,0x3
ffffffffc020255e:	79e50513          	add	a0,a0,1950 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202562:	ed1fd0ef          	jal	ffffffffc0200432 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202566:	00004697          	auipc	a3,0x4
ffffffffc020256a:	b1a68693          	add	a3,a3,-1254 # ffffffffc0206080 <etext+0x1146>
ffffffffc020256e:	00003617          	auipc	a2,0x3
ffffffffc0202572:	2c260613          	add	a2,a2,706 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202576:	19d00593          	li	a1,413
ffffffffc020257a:	00003517          	auipc	a0,0x3
ffffffffc020257e:	77e50513          	add	a0,a0,1918 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202582:	eb1fd0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc0202586:	86a2                	mv	a3,s0
ffffffffc0202588:	00003617          	auipc	a2,0x3
ffffffffc020258c:	65860613          	add	a2,a2,1624 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0202590:	19d00593          	li	a1,413
ffffffffc0202594:	00003517          	auipc	a0,0x3
ffffffffc0202598:	76450513          	add	a0,a0,1892 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020259c:	e97fd0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc02025a0:	c28ff0ef          	jal	ffffffffc02019c8 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02025a4:	00003617          	auipc	a2,0x3
ffffffffc02025a8:	6e460613          	add	a2,a2,1764 # ffffffffc0205c88 <etext+0xd4e>
ffffffffc02025ac:	07f00593          	li	a1,127
ffffffffc02025b0:	00003517          	auipc	a0,0x3
ffffffffc02025b4:	74850513          	add	a0,a0,1864 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02025b8:	e7bfd0ef          	jal	ffffffffc0200432 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02025bc:	00003617          	auipc	a2,0x3
ffffffffc02025c0:	6cc60613          	add	a2,a2,1740 # ffffffffc0205c88 <etext+0xd4e>
ffffffffc02025c4:	0c300593          	li	a1,195
ffffffffc02025c8:	00003517          	auipc	a0,0x3
ffffffffc02025cc:	73050513          	add	a0,a0,1840 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02025d0:	e63fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02025d4:	00003697          	auipc	a3,0x3
ffffffffc02025d8:	7e468693          	add	a3,a3,2020 # ffffffffc0205db8 <etext+0xe7e>
ffffffffc02025dc:	00003617          	auipc	a2,0x3
ffffffffc02025e0:	25460613          	add	a2,a2,596 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02025e4:	16100593          	li	a1,353
ffffffffc02025e8:	00003517          	auipc	a0,0x3
ffffffffc02025ec:	71050513          	add	a0,a0,1808 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02025f0:	e43fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02025f4:	00003697          	auipc	a3,0x3
ffffffffc02025f8:	7a468693          	add	a3,a3,1956 # ffffffffc0205d98 <etext+0xe5e>
ffffffffc02025fc:	00003617          	auipc	a2,0x3
ffffffffc0202600:	23460613          	add	a2,a2,564 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202604:	16000593          	li	a1,352
ffffffffc0202608:	00003517          	auipc	a0,0x3
ffffffffc020260c:	6f050513          	add	a0,a0,1776 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202610:	e23fd0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc0202614:	bd0ff0ef          	jal	ffffffffc02019e4 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202618:	00004697          	auipc	a3,0x4
ffffffffc020261c:	83068693          	add	a3,a3,-2000 # ffffffffc0205e48 <etext+0xf0e>
ffffffffc0202620:	00003617          	auipc	a2,0x3
ffffffffc0202624:	21060613          	add	a2,a2,528 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202628:	16900593          	li	a1,361
ffffffffc020262c:	00003517          	auipc	a0,0x3
ffffffffc0202630:	6cc50513          	add	a0,a0,1740 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202634:	dfffd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202638:	00003697          	auipc	a3,0x3
ffffffffc020263c:	7e068693          	add	a3,a3,2016 # ffffffffc0205e18 <etext+0xede>
ffffffffc0202640:	00003617          	auipc	a2,0x3
ffffffffc0202644:	1f060613          	add	a2,a2,496 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202648:	16600593          	li	a1,358
ffffffffc020264c:	00003517          	auipc	a0,0x3
ffffffffc0202650:	6ac50513          	add	a0,a0,1708 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202654:	ddffd0ef          	jal	ffffffffc0200432 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202658:	00003697          	auipc	a3,0x3
ffffffffc020265c:	79868693          	add	a3,a3,1944 # ffffffffc0205df0 <etext+0xeb6>
ffffffffc0202660:	00003617          	auipc	a2,0x3
ffffffffc0202664:	1d060613          	add	a2,a2,464 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202668:	16200593          	li	a1,354
ffffffffc020266c:	00003517          	auipc	a0,0x3
ffffffffc0202670:	68c50513          	add	a0,a0,1676 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202674:	dbffd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202678:	00004697          	auipc	a3,0x4
ffffffffc020267c:	85868693          	add	a3,a3,-1960 # ffffffffc0205ed0 <etext+0xf96>
ffffffffc0202680:	00003617          	auipc	a2,0x3
ffffffffc0202684:	1b060613          	add	a2,a2,432 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202688:	17200593          	li	a1,370
ffffffffc020268c:	00003517          	auipc	a0,0x3
ffffffffc0202690:	66c50513          	add	a0,a0,1644 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202694:	d9ffd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202698:	00004697          	auipc	a3,0x4
ffffffffc020269c:	8d868693          	add	a3,a3,-1832 # ffffffffc0205f70 <etext+0x1036>
ffffffffc02026a0:	00003617          	auipc	a2,0x3
ffffffffc02026a4:	19060613          	add	a2,a2,400 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02026a8:	17700593          	li	a1,375
ffffffffc02026ac:	00003517          	auipc	a0,0x3
ffffffffc02026b0:	64c50513          	add	a0,a0,1612 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02026b4:	d7ffd0ef          	jal	ffffffffc0200432 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02026b8:	00003697          	auipc	a3,0x3
ffffffffc02026bc:	7f068693          	add	a3,a3,2032 # ffffffffc0205ea8 <etext+0xf6e>
ffffffffc02026c0:	00003617          	auipc	a2,0x3
ffffffffc02026c4:	17060613          	add	a2,a2,368 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02026c8:	16f00593          	li	a1,367
ffffffffc02026cc:	00003517          	auipc	a0,0x3
ffffffffc02026d0:	62c50513          	add	a0,a0,1580 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02026d4:	d5ffd0ef          	jal	ffffffffc0200432 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02026d8:	86d6                	mv	a3,s5
ffffffffc02026da:	00003617          	auipc	a2,0x3
ffffffffc02026de:	50660613          	add	a2,a2,1286 # ffffffffc0205be0 <etext+0xca6>
ffffffffc02026e2:	16e00593          	li	a1,366
ffffffffc02026e6:	00003517          	auipc	a0,0x3
ffffffffc02026ea:	61250513          	add	a0,a0,1554 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02026ee:	d45fd0ef          	jal	ffffffffc0200432 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02026f2:	00004697          	auipc	a3,0x4
ffffffffc02026f6:	81668693          	add	a3,a3,-2026 # ffffffffc0205f08 <etext+0xfce>
ffffffffc02026fa:	00003617          	auipc	a2,0x3
ffffffffc02026fe:	13660613          	add	a2,a2,310 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202702:	17c00593          	li	a1,380
ffffffffc0202706:	00003517          	auipc	a0,0x3
ffffffffc020270a:	5f250513          	add	a0,a0,1522 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020270e:	d25fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202712:	00004697          	auipc	a3,0x4
ffffffffc0202716:	8be68693          	add	a3,a3,-1858 # ffffffffc0205fd0 <etext+0x1096>
ffffffffc020271a:	00003617          	auipc	a2,0x3
ffffffffc020271e:	11660613          	add	a2,a2,278 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202722:	17b00593          	li	a1,379
ffffffffc0202726:	00003517          	auipc	a0,0x3
ffffffffc020272a:	5d250513          	add	a0,a0,1490 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020272e:	d05fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202732:	00004697          	auipc	a3,0x4
ffffffffc0202736:	88668693          	add	a3,a3,-1914 # ffffffffc0205fb8 <etext+0x107e>
ffffffffc020273a:	00003617          	auipc	a2,0x3
ffffffffc020273e:	0f660613          	add	a2,a2,246 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202742:	17a00593          	li	a1,378
ffffffffc0202746:	00003517          	auipc	a0,0x3
ffffffffc020274a:	5b250513          	add	a0,a0,1458 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020274e:	ce5fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202752:	00004697          	auipc	a3,0x4
ffffffffc0202756:	83668693          	add	a3,a3,-1994 # ffffffffc0205f88 <etext+0x104e>
ffffffffc020275a:	00003617          	auipc	a2,0x3
ffffffffc020275e:	0d660613          	add	a2,a2,214 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202762:	17900593          	li	a1,377
ffffffffc0202766:	00003517          	auipc	a0,0x3
ffffffffc020276a:	59250513          	add	a0,a0,1426 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020276e:	cc5fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202772:	00004697          	auipc	a3,0x4
ffffffffc0202776:	9ce68693          	add	a3,a3,-1586 # ffffffffc0206140 <etext+0x1206>
ffffffffc020277a:	00003617          	auipc	a2,0x3
ffffffffc020277e:	0b660613          	add	a2,a2,182 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202782:	1a700593          	li	a1,423
ffffffffc0202786:	00003517          	auipc	a0,0x3
ffffffffc020278a:	57250513          	add	a0,a0,1394 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020278e:	ca5fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202792:	00003697          	auipc	a3,0x3
ffffffffc0202796:	7c668693          	add	a3,a3,1990 # ffffffffc0205f58 <etext+0x101e>
ffffffffc020279a:	00003617          	auipc	a2,0x3
ffffffffc020279e:	09660613          	add	a2,a2,150 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02027a2:	17600593          	li	a1,374
ffffffffc02027a6:	00003517          	auipc	a0,0x3
ffffffffc02027aa:	55250513          	add	a0,a0,1362 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02027ae:	c85fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02027b2:	00003697          	auipc	a3,0x3
ffffffffc02027b6:	79668693          	add	a3,a3,1942 # ffffffffc0205f48 <etext+0x100e>
ffffffffc02027ba:	00003617          	auipc	a2,0x3
ffffffffc02027be:	07660613          	add	a2,a2,118 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02027c2:	17500593          	li	a1,373
ffffffffc02027c6:	00003517          	auipc	a0,0x3
ffffffffc02027ca:	53250513          	add	a0,a0,1330 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02027ce:	c65fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02027d2:	00004697          	auipc	a3,0x4
ffffffffc02027d6:	86e68693          	add	a3,a3,-1938 # ffffffffc0206040 <etext+0x1106>
ffffffffc02027da:	00003617          	auipc	a2,0x3
ffffffffc02027de:	05660613          	add	a2,a2,86 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02027e2:	1b800593          	li	a1,440
ffffffffc02027e6:	00003517          	auipc	a0,0x3
ffffffffc02027ea:	51250513          	add	a0,a0,1298 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02027ee:	c45fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02027f2:	00003697          	auipc	a3,0x3
ffffffffc02027f6:	74668693          	add	a3,a3,1862 # ffffffffc0205f38 <etext+0xffe>
ffffffffc02027fa:	00003617          	auipc	a2,0x3
ffffffffc02027fe:	03660613          	add	a2,a2,54 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202802:	17400593          	li	a1,372
ffffffffc0202806:	00003517          	auipc	a0,0x3
ffffffffc020280a:	4f250513          	add	a0,a0,1266 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020280e:	c25fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202812:	00003697          	auipc	a3,0x3
ffffffffc0202816:	67e68693          	add	a3,a3,1662 # ffffffffc0205e90 <etext+0xf56>
ffffffffc020281a:	00003617          	auipc	a2,0x3
ffffffffc020281e:	01660613          	add	a2,a2,22 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202822:	18100593          	li	a1,385
ffffffffc0202826:	00003517          	auipc	a0,0x3
ffffffffc020282a:	4d250513          	add	a0,a0,1234 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020282e:	c05fd0ef          	jal	ffffffffc0200432 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202832:	00003697          	auipc	a3,0x3
ffffffffc0202836:	7b668693          	add	a3,a3,1974 # ffffffffc0205fe8 <etext+0x10ae>
ffffffffc020283a:	00003617          	auipc	a2,0x3
ffffffffc020283e:	ff660613          	add	a2,a2,-10 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202842:	17e00593          	li	a1,382
ffffffffc0202846:	00003517          	auipc	a0,0x3
ffffffffc020284a:	4b250513          	add	a0,a0,1202 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020284e:	be5fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202852:	00003697          	auipc	a3,0x3
ffffffffc0202856:	62668693          	add	a3,a3,1574 # ffffffffc0205e78 <etext+0xf3e>
ffffffffc020285a:	00003617          	auipc	a2,0x3
ffffffffc020285e:	fd660613          	add	a2,a2,-42 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202862:	17d00593          	li	a1,381
ffffffffc0202866:	00003517          	auipc	a0,0x3
ffffffffc020286a:	49250513          	add	a0,a0,1170 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc020286e:	bc5fd0ef          	jal	ffffffffc0200432 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202872:	00003617          	auipc	a2,0x3
ffffffffc0202876:	36e60613          	add	a2,a2,878 # ffffffffc0205be0 <etext+0xca6>
ffffffffc020287a:	06900593          	li	a1,105
ffffffffc020287e:	00003517          	auipc	a0,0x3
ffffffffc0202882:	38a50513          	add	a0,a0,906 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0202886:	badfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020288a:	00003697          	auipc	a3,0x3
ffffffffc020288e:	78e68693          	add	a3,a3,1934 # ffffffffc0206018 <etext+0x10de>
ffffffffc0202892:	00003617          	auipc	a2,0x3
ffffffffc0202896:	f9e60613          	add	a2,a2,-98 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020289a:	18800593          	li	a1,392
ffffffffc020289e:	00003517          	auipc	a0,0x3
ffffffffc02028a2:	45a50513          	add	a0,a0,1114 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02028a6:	b8dfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02028aa:	00003697          	auipc	a3,0x3
ffffffffc02028ae:	72668693          	add	a3,a3,1830 # ffffffffc0205fd0 <etext+0x1096>
ffffffffc02028b2:	00003617          	auipc	a2,0x3
ffffffffc02028b6:	f7e60613          	add	a2,a2,-130 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02028ba:	18600593          	li	a1,390
ffffffffc02028be:	00003517          	auipc	a0,0x3
ffffffffc02028c2:	43a50513          	add	a0,a0,1082 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02028c6:	b6dfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02028ca:	00003697          	auipc	a3,0x3
ffffffffc02028ce:	73668693          	add	a3,a3,1846 # ffffffffc0206000 <etext+0x10c6>
ffffffffc02028d2:	00003617          	auipc	a2,0x3
ffffffffc02028d6:	f5e60613          	add	a2,a2,-162 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02028da:	18500593          	li	a1,389
ffffffffc02028de:	00003517          	auipc	a0,0x3
ffffffffc02028e2:	41a50513          	add	a0,a0,1050 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02028e6:	b4dfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02028ea:	00003697          	auipc	a3,0x3
ffffffffc02028ee:	6e668693          	add	a3,a3,1766 # ffffffffc0205fd0 <etext+0x1096>
ffffffffc02028f2:	00003617          	auipc	a2,0x3
ffffffffc02028f6:	f3e60613          	add	a2,a2,-194 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02028fa:	18200593          	li	a1,386
ffffffffc02028fe:	00003517          	auipc	a0,0x3
ffffffffc0202902:	3fa50513          	add	a0,a0,1018 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202906:	b2dfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020290a:	00004697          	auipc	a3,0x4
ffffffffc020290e:	81e68693          	add	a3,a3,-2018 # ffffffffc0206128 <etext+0x11ee>
ffffffffc0202912:	00003617          	auipc	a2,0x3
ffffffffc0202916:	f1e60613          	add	a2,a2,-226 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020291a:	1a600593          	li	a1,422
ffffffffc020291e:	00003517          	auipc	a0,0x3
ffffffffc0202922:	3da50513          	add	a0,a0,986 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202926:	b0dfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020292a:	00003697          	auipc	a3,0x3
ffffffffc020292e:	7c668693          	add	a3,a3,1990 # ffffffffc02060f0 <etext+0x11b6>
ffffffffc0202932:	00003617          	auipc	a2,0x3
ffffffffc0202936:	efe60613          	add	a2,a2,-258 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020293a:	1a500593          	li	a1,421
ffffffffc020293e:	00003517          	auipc	a0,0x3
ffffffffc0202942:	3ba50513          	add	a0,a0,954 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202946:	aedfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020294a:	00003697          	auipc	a3,0x3
ffffffffc020294e:	78e68693          	add	a3,a3,1934 # ffffffffc02060d8 <etext+0x119e>
ffffffffc0202952:	00003617          	auipc	a2,0x3
ffffffffc0202956:	ede60613          	add	a2,a2,-290 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020295a:	1a100593          	li	a1,417
ffffffffc020295e:	00003517          	auipc	a0,0x3
ffffffffc0202962:	39a50513          	add	a0,a0,922 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202966:	acdfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020296a:	00003697          	auipc	a3,0x3
ffffffffc020296e:	6d668693          	add	a3,a3,1750 # ffffffffc0206040 <etext+0x1106>
ffffffffc0202972:	00003617          	auipc	a2,0x3
ffffffffc0202976:	ebe60613          	add	a2,a2,-322 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020297a:	19000593          	li	a1,400
ffffffffc020297e:	00003517          	auipc	a0,0x3
ffffffffc0202982:	37a50513          	add	a0,a0,890 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202986:	aadfd0ef          	jal	ffffffffc0200432 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020298a:	00003697          	auipc	a3,0x3
ffffffffc020298e:	4ee68693          	add	a3,a3,1262 # ffffffffc0205e78 <etext+0xf3e>
ffffffffc0202992:	00003617          	auipc	a2,0x3
ffffffffc0202996:	e9e60613          	add	a2,a2,-354 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020299a:	16a00593          	li	a1,362
ffffffffc020299e:	00003517          	auipc	a0,0x3
ffffffffc02029a2:	35a50513          	add	a0,a0,858 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02029a6:	a8dfd0ef          	jal	ffffffffc0200432 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02029aa:	00003617          	auipc	a2,0x3
ffffffffc02029ae:	23660613          	add	a2,a2,566 # ffffffffc0205be0 <etext+0xca6>
ffffffffc02029b2:	16d00593          	li	a1,365
ffffffffc02029b6:	00003517          	auipc	a0,0x3
ffffffffc02029ba:	34250513          	add	a0,a0,834 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02029be:	a75fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02029c2:	00003697          	auipc	a3,0x3
ffffffffc02029c6:	4ce68693          	add	a3,a3,1230 # ffffffffc0205e90 <etext+0xf56>
ffffffffc02029ca:	00003617          	auipc	a2,0x3
ffffffffc02029ce:	e6660613          	add	a2,a2,-410 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02029d2:	16b00593          	li	a1,363
ffffffffc02029d6:	00003517          	auipc	a0,0x3
ffffffffc02029da:	32250513          	add	a0,a0,802 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02029de:	a55fd0ef          	jal	ffffffffc0200432 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02029e2:	00003697          	auipc	a3,0x3
ffffffffc02029e6:	52668693          	add	a3,a3,1318 # ffffffffc0205f08 <etext+0xfce>
ffffffffc02029ea:	00003617          	auipc	a2,0x3
ffffffffc02029ee:	e4660613          	add	a2,a2,-442 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02029f2:	17300593          	li	a1,371
ffffffffc02029f6:	00003517          	auipc	a0,0x3
ffffffffc02029fa:	30250513          	add	a0,a0,770 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc02029fe:	a35fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a02:	00003697          	auipc	a3,0x3
ffffffffc0202a06:	7e668693          	add	a3,a3,2022 # ffffffffc02061e8 <etext+0x12ae>
ffffffffc0202a0a:	00003617          	auipc	a2,0x3
ffffffffc0202a0e:	e2660613          	add	a2,a2,-474 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202a12:	1af00593          	li	a1,431
ffffffffc0202a16:	00003517          	auipc	a0,0x3
ffffffffc0202a1a:	2e250513          	add	a0,a0,738 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202a1e:	a15fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a22:	00003697          	auipc	a3,0x3
ffffffffc0202a26:	78e68693          	add	a3,a3,1934 # ffffffffc02061b0 <etext+0x1276>
ffffffffc0202a2a:	00003617          	auipc	a2,0x3
ffffffffc0202a2e:	e0660613          	add	a2,a2,-506 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202a32:	1ac00593          	li	a1,428
ffffffffc0202a36:	00003517          	auipc	a0,0x3
ffffffffc0202a3a:	2c250513          	add	a0,a0,706 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202a3e:	9f5fd0ef          	jal	ffffffffc0200432 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202a42:	00003697          	auipc	a3,0x3
ffffffffc0202a46:	73e68693          	add	a3,a3,1854 # ffffffffc0206180 <etext+0x1246>
ffffffffc0202a4a:	00003617          	auipc	a2,0x3
ffffffffc0202a4e:	de660613          	add	a2,a2,-538 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202a52:	1a800593          	li	a1,424
ffffffffc0202a56:	00003517          	auipc	a0,0x3
ffffffffc0202a5a:	2a250513          	add	a0,a0,674 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202a5e:	9d5fd0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0202a62 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202a62:	12058073          	sfence.vma	a1
}
ffffffffc0202a66:	8082                	ret

ffffffffc0202a68 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202a68:	7179                	add	sp,sp,-48
ffffffffc0202a6a:	e84a                	sd	s2,16(sp)
ffffffffc0202a6c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0202a6e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202a70:	ec26                	sd	s1,24(sp)
ffffffffc0202a72:	e44e                	sd	s3,8(sp)
ffffffffc0202a74:	f406                	sd	ra,40(sp)
ffffffffc0202a76:	f022                	sd	s0,32(sp)
ffffffffc0202a78:	84ae                	mv	s1,a1
ffffffffc0202a7a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0202a7c:	f85fe0ef          	jal	ffffffffc0201a00 <alloc_pages>
    if (page != NULL) {
ffffffffc0202a80:	c131                	beqz	a0,ffffffffc0202ac4 <pgdir_alloc_page+0x5c>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0202a82:	842a                	mv	s0,a0
ffffffffc0202a84:	85aa                	mv	a1,a0
ffffffffc0202a86:	86ce                	mv	a3,s3
ffffffffc0202a88:	8626                	mv	a2,s1
ffffffffc0202a8a:	854a                	mv	a0,s2
ffffffffc0202a8c:	b46ff0ef          	jal	ffffffffc0201dd2 <page_insert>
ffffffffc0202a90:	ed11                	bnez	a0,ffffffffc0202aac <pgdir_alloc_page+0x44>
        if (swap_init_ok) {
ffffffffc0202a92:	00014797          	auipc	a5,0x14
ffffffffc0202a96:	af67a783          	lw	a5,-1290(a5) # ffffffffc0216588 <swap_init_ok>
ffffffffc0202a9a:	e79d                	bnez	a5,ffffffffc0202ac8 <pgdir_alloc_page+0x60>
}
ffffffffc0202a9c:	70a2                	ld	ra,40(sp)
ffffffffc0202a9e:	8522                	mv	a0,s0
ffffffffc0202aa0:	7402                	ld	s0,32(sp)
ffffffffc0202aa2:	64e2                	ld	s1,24(sp)
ffffffffc0202aa4:	6942                	ld	s2,16(sp)
ffffffffc0202aa6:	69a2                	ld	s3,8(sp)
ffffffffc0202aa8:	6145                	add	sp,sp,48
ffffffffc0202aaa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202aac:	100027f3          	csrr	a5,sstatus
ffffffffc0202ab0:	8b89                	and	a5,a5,2
ffffffffc0202ab2:	eba9                	bnez	a5,ffffffffc0202b04 <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n);
ffffffffc0202ab4:	00014797          	auipc	a5,0x14
ffffffffc0202ab8:	aa47b783          	ld	a5,-1372(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0202abc:	739c                	ld	a5,32(a5)
ffffffffc0202abe:	4585                	li	a1,1
ffffffffc0202ac0:	8522                	mv	a0,s0
ffffffffc0202ac2:	9782                	jalr	a5
            return NULL;
ffffffffc0202ac4:	4401                	li	s0,0
ffffffffc0202ac6:	bfd9                	j	ffffffffc0202a9c <pgdir_alloc_page+0x34>
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202ac8:	4681                	li	a3,0
ffffffffc0202aca:	8622                	mv	a2,s0
ffffffffc0202acc:	85a6                	mv	a1,s1
ffffffffc0202ace:	00014517          	auipc	a0,0x14
ffffffffc0202ad2:	ada53503          	ld	a0,-1318(a0) # ffffffffc02165a8 <check_mm_struct>
ffffffffc0202ad6:	7d4000ef          	jal	ffffffffc02032aa <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202ada:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202adc:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0202ade:	4785                	li	a5,1
ffffffffc0202ae0:	faf70ee3          	beq	a4,a5,ffffffffc0202a9c <pgdir_alloc_page+0x34>
ffffffffc0202ae4:	00003697          	auipc	a3,0x3
ffffffffc0202ae8:	74c68693          	add	a3,a3,1868 # ffffffffc0206230 <etext+0x12f6>
ffffffffc0202aec:	00003617          	auipc	a2,0x3
ffffffffc0202af0:	d4460613          	add	a2,a2,-700 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202af4:	14800593          	li	a1,328
ffffffffc0202af8:	00003517          	auipc	a0,0x3
ffffffffc0202afc:	20050513          	add	a0,a0,512 # ffffffffc0205cf8 <etext+0xdbe>
ffffffffc0202b00:	933fd0ef          	jal	ffffffffc0200432 <__panic>
        intr_disable();
ffffffffc0202b04:	aadfd0ef          	jal	ffffffffc02005b0 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b08:	00014797          	auipc	a5,0x14
ffffffffc0202b0c:	a507b783          	ld	a5,-1456(a5) # ffffffffc0216558 <pmm_manager>
ffffffffc0202b10:	739c                	ld	a5,32(a5)
ffffffffc0202b12:	8522                	mv	a0,s0
ffffffffc0202b14:	4585                	li	a1,1
ffffffffc0202b16:	9782                	jalr	a5
            return NULL;
ffffffffc0202b18:	4401                	li	s0,0
        intr_enable();
ffffffffc0202b1a:	a91fd0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0202b1e:	bfbd                	j	ffffffffc0202a9c <pgdir_alloc_page+0x34>

ffffffffc0202b20 <pa2page.part.0>:
          //struct Page **ptr_page=NULL;
          struct Page *page;
          // cprintf("i %d, SWAP: call swap_out_victim\n",i);
          int r = sm->swap_out_victim(mm, &page, in_tick);
          if (r != 0) {
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202b20:	1141                	add	sp,sp,-16
                  break;
          }          
ffffffffc0202b22:	00003617          	auipc	a2,0x3
ffffffffc0202b26:	18e60613          	add	a2,a2,398 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc0202b2a:	06200593          	li	a1,98
ffffffffc0202b2e:	00003517          	auipc	a0,0x3
ffffffffc0202b32:	0da50513          	add	a0,a0,218 # ffffffffc0205c08 <etext+0xcce>
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202b36:	e406                	sd	ra,8(sp)
          }          
ffffffffc0202b38:	8fbfd0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0202b3c <swap_init>:
{
ffffffffc0202b3c:	7135                	add	sp,sp,-160
ffffffffc0202b3e:	ed06                	sd	ra,152(sp)
     swapfs_init();
ffffffffc0202b40:	584010ef          	jal	ffffffffc02040c4 <swapfs_init>
     if (!(7 <= max_swap_offset &&
ffffffffc0202b44:	00014697          	auipc	a3,0x14
ffffffffc0202b48:	a4c6b683          	ld	a3,-1460(a3) # ffffffffc0216590 <max_swap_offset>
ffffffffc0202b4c:	010007b7          	lui	a5,0x1000
ffffffffc0202b50:	ff968713          	add	a4,a3,-7
ffffffffc0202b54:	17e1                	add	a5,a5,-8 # fffff8 <kern_entry-0xffffffffbf200008>
ffffffffc0202b56:	44e7e463          	bltu	a5,a4,ffffffffc0202f9e <swap_init+0x462>
     sm = &swap_manager_fifo;
ffffffffc0202b5a:	00008797          	auipc	a5,0x8
ffffffffc0202b5e:	4b678793          	add	a5,a5,1206 # ffffffffc020b010 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0202b62:	6798                	ld	a4,8(a5)
ffffffffc0202b64:	e14a                	sd	s2,128(sp)
ffffffffc0202b66:	f0da                	sd	s6,96(sp)
     sm = &swap_manager_fifo;
ffffffffc0202b68:	00014b17          	auipc	s6,0x14
ffffffffc0202b6c:	a30b0b13          	add	s6,s6,-1488 # ffffffffc0216598 <sm>
ffffffffc0202b70:	00fb3023          	sd	a5,0(s6)
     int r = sm->init();
ffffffffc0202b74:	9702                	jalr	a4
ffffffffc0202b76:	892a                	mv	s2,a0
     if (r == 0)
ffffffffc0202b78:	c519                	beqz	a0,ffffffffc0202b86 <swap_init+0x4a>
}
ffffffffc0202b7a:	60ea                	ld	ra,152(sp)
ffffffffc0202b7c:	7b06                	ld	s6,96(sp)
ffffffffc0202b7e:	854a                	mv	a0,s2
ffffffffc0202b80:	690a                	ld	s2,128(sp)
ffffffffc0202b82:	610d                	add	sp,sp,160
ffffffffc0202b84:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202b86:	000b3783          	ld	a5,0(s6)
ffffffffc0202b8a:	00003517          	auipc	a0,0x3
ffffffffc0202b8e:	6ee50513          	add	a0,a0,1774 # ffffffffc0206278 <etext+0x133e>
ffffffffc0202b92:	e922                	sd	s0,144(sp)
ffffffffc0202b94:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202b96:	4785                	li	a5,1
ffffffffc0202b98:	e0ea                	sd	s10,64(sp)
ffffffffc0202b9a:	fc6e                	sd	s11,56(sp)
ffffffffc0202b9c:	00014717          	auipc	a4,0x14
ffffffffc0202ba0:	9ef72623          	sw	a5,-1556(a4) # ffffffffc0216588 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202ba4:	e526                	sd	s1,136(sp)
ffffffffc0202ba6:	fcce                	sd	s3,120(sp)
ffffffffc0202ba8:	f8d2                	sd	s4,112(sp)
ffffffffc0202baa:	f4d6                	sd	s5,104(sp)
ffffffffc0202bac:	ecde                	sd	s7,88(sp)
ffffffffc0202bae:	e8e2                	sd	s8,80(sp)
ffffffffc0202bb0:	e4e6                	sd	s9,72(sp)
    return listelm->next;
ffffffffc0202bb2:	00010417          	auipc	s0,0x10
ffffffffc0202bb6:	8ae40413          	add	s0,s0,-1874 # ffffffffc0212460 <free_area>
ffffffffc0202bba:	dc6fd0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc0202bbe:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202bc0:	4d81                	li	s11,0
ffffffffc0202bc2:	4d01                	li	s10,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202bc4:	34878d63          	beq	a5,s0,ffffffffc0202f1e <swap_init+0x3e2>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202bc8:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202bcc:	8b09                	and	a4,a4,2
ffffffffc0202bce:	34070a63          	beqz	a4,ffffffffc0202f22 <swap_init+0x3e6>
        count ++, total += p->property;
ffffffffc0202bd2:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202bd6:	679c                	ld	a5,8(a5)
ffffffffc0202bd8:	2d05                	addw	s10,s10,1
ffffffffc0202bda:	01b70dbb          	addw	s11,a4,s11
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202bde:	fe8795e3          	bne	a5,s0,ffffffffc0202bc8 <swap_init+0x8c>
     }
     assert(total == nr_free_pages());
ffffffffc0202be2:	84ee                	mv	s1,s11
ffffffffc0202be4:	eedfe0ef          	jal	ffffffffc0201ad0 <nr_free_pages>
ffffffffc0202be8:	44951f63          	bne	a0,s1,ffffffffc0203046 <swap_init+0x50a>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202bec:	866e                	mv	a2,s11
ffffffffc0202bee:	85ea                	mv	a1,s10
ffffffffc0202bf0:	00003517          	auipc	a0,0x3
ffffffffc0202bf4:	6a050513          	add	a0,a0,1696 # ffffffffc0206290 <etext+0x1356>
ffffffffc0202bf8:	d88fd0ef          	jal	ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202bfc:	451000ef          	jal	ffffffffc020384c <mm_create>
ffffffffc0202c00:	e82a                	sd	a0,16(sp)
     assert(mm != NULL);
ffffffffc0202c02:	4a050263          	beqz	a0,ffffffffc02030a6 <swap_init+0x56a>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202c06:	00014797          	auipc	a5,0x14
ffffffffc0202c0a:	9a278793          	add	a5,a5,-1630 # ffffffffc02165a8 <check_mm_struct>
ffffffffc0202c0e:	6398                	ld	a4,0(a5)
ffffffffc0202c10:	40071b63          	bnez	a4,ffffffffc0203026 <swap_init+0x4ea>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202c14:	00014717          	auipc	a4,0x14
ffffffffc0202c18:	95470713          	add	a4,a4,-1708 # ffffffffc0216568 <boot_pgdir>
ffffffffc0202c1c:	00073a83          	ld	s5,0(a4)
     check_mm_struct = mm;
ffffffffc0202c20:	6742                	ld	a4,16(sp)
ffffffffc0202c22:	e398                	sd	a4,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0202c24:	000ab783          	ld	a5,0(s5) # fffffffffffff000 <end+0x3fde8a30>
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202c28:	01573c23          	sd	s5,24(a4)
     assert(pgdir[0] == 0);
ffffffffc0202c2c:	44079d63          	bnez	a5,ffffffffc0203086 <swap_init+0x54a>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202c30:	6599                	lui	a1,0x6
ffffffffc0202c32:	460d                	li	a2,3
ffffffffc0202c34:	6505                	lui	a0,0x1
ffffffffc0202c36:	45f000ef          	jal	ffffffffc0203894 <vma_create>
ffffffffc0202c3a:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202c3c:	56050163          	beqz	a0,ffffffffc020319e <swap_init+0x662>

     insert_vma_struct(mm, vma);
ffffffffc0202c40:	64c2                	ld	s1,16(sp)
ffffffffc0202c42:	8526                	mv	a0,s1
ffffffffc0202c44:	4bf000ef          	jal	ffffffffc0203902 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202c48:	00003517          	auipc	a0,0x3
ffffffffc0202c4c:	6b850513          	add	a0,a0,1720 # ffffffffc0206300 <etext+0x13c6>
ffffffffc0202c50:	d30fd0ef          	jal	ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202c54:	6c88                	ld	a0,24(s1)
ffffffffc0202c56:	4605                	li	a2,1
ffffffffc0202c58:	6585                	lui	a1,0x1
ffffffffc0202c5a:	eb1fe0ef          	jal	ffffffffc0201b0a <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202c5e:	50050063          	beqz	a0,ffffffffc020315e <swap_init+0x622>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202c62:	00003517          	auipc	a0,0x3
ffffffffc0202c66:	6ee50513          	add	a0,a0,1774 # ffffffffc0206350 <etext+0x1416>
ffffffffc0202c6a:	00010497          	auipc	s1,0x10
ffffffffc0202c6e:	82e48493          	add	s1,s1,-2002 # ffffffffc0212498 <check_rp>
ffffffffc0202c72:	d0efd0ef          	jal	ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c76:	00010997          	auipc	s3,0x10
ffffffffc0202c7a:	84298993          	add	s3,s3,-1982 # ffffffffc02124b8 <swap_out_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202c7e:	8ba6                	mv	s7,s1
          check_rp[i] = alloc_page();
ffffffffc0202c80:	4505                	li	a0,1
ffffffffc0202c82:	d7ffe0ef          	jal	ffffffffc0201a00 <alloc_pages>
ffffffffc0202c86:	00abb023          	sd	a0,0(s7)
          assert(check_rp[i] != NULL );
ffffffffc0202c8a:	2e050a63          	beqz	a0,ffffffffc0202f7e <swap_init+0x442>
ffffffffc0202c8e:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202c90:	8b89                	and	a5,a5,2
ffffffffc0202c92:	36079a63          	bnez	a5,ffffffffc0203006 <swap_init+0x4ca>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c96:	0ba1                	add	s7,s7,8
ffffffffc0202c98:	ff3b94e3          	bne	s7,s3,ffffffffc0202c80 <swap_init+0x144>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202c9c:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202c9e:	0000fb97          	auipc	s7,0xf
ffffffffc0202ca2:	7fab8b93          	add	s7,s7,2042 # ffffffffc0212498 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0202ca6:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0202ca8:	f43e                	sd	a5,40(sp)
ffffffffc0202caa:	641c                	ld	a5,8(s0)
ffffffffc0202cac:	e400                	sd	s0,8(s0)
ffffffffc0202cae:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202cb0:	481c                	lw	a5,16(s0)
ffffffffc0202cb2:	ec3e                	sd	a5,24(sp)
     nr_free = 0;
ffffffffc0202cb4:	0000f797          	auipc	a5,0xf
ffffffffc0202cb8:	7a07ae23          	sw	zero,1980(a5) # ffffffffc0212470 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202cbc:	000bb503          	ld	a0,0(s7)
ffffffffc0202cc0:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cc2:	0ba1                	add	s7,s7,8
        free_pages(check_rp[i],1);
ffffffffc0202cc4:	dcdfe0ef          	jal	ffffffffc0201a90 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202cc8:	ff3b9ae3          	bne	s7,s3,ffffffffc0202cbc <swap_init+0x180>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202ccc:	01042b83          	lw	s7,16(s0)
ffffffffc0202cd0:	4791                	li	a5,4
ffffffffc0202cd2:	46fb9663          	bne	s7,a5,ffffffffc020313e <swap_init+0x602>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202cd6:	00003517          	auipc	a0,0x3
ffffffffc0202cda:	70250513          	add	a0,a0,1794 # ffffffffc02063d8 <etext+0x149e>
ffffffffc0202cde:	ca2fd0ef          	jal	ffffffffc0200180 <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202ce2:	00014797          	auipc	a5,0x14
ffffffffc0202ce6:	8a07af23          	sw	zero,-1858(a5) # ffffffffc02165a0 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202cea:	6785                	lui	a5,0x1
ffffffffc0202cec:	4629                	li	a2,10
ffffffffc0202cee:	00c78023          	sb	a2,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0202cf2:	00014697          	auipc	a3,0x14
ffffffffc0202cf6:	8ae6a683          	lw	a3,-1874(a3) # ffffffffc02165a0 <pgfault_num>
ffffffffc0202cfa:	4705                	li	a4,1
ffffffffc0202cfc:	00014797          	auipc	a5,0x14
ffffffffc0202d00:	8a478793          	add	a5,a5,-1884 # ffffffffc02165a0 <pgfault_num>
ffffffffc0202d04:	56e69d63          	bne	a3,a4,ffffffffc020327e <swap_init+0x742>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202d08:	6705                	lui	a4,0x1
ffffffffc0202d0a:	00c70823          	sb	a2,16(a4) # 1010 <kern_entry-0xffffffffc01feff0>
     assert(pgfault_num==1);
ffffffffc0202d0e:	4390                	lw	a2,0(a5)
ffffffffc0202d10:	40d61763          	bne	a2,a3,ffffffffc020311e <swap_init+0x5e2>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202d14:	6709                	lui	a4,0x2
ffffffffc0202d16:	46ad                	li	a3,11
ffffffffc0202d18:	00d70023          	sb	a3,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0202d1c:	4398                	lw	a4,0(a5)
ffffffffc0202d1e:	4589                	li	a1,2
ffffffffc0202d20:	0007061b          	sext.w	a2,a4
ffffffffc0202d24:	4cb71d63          	bne	a4,a1,ffffffffc02031fe <swap_init+0x6c2>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202d28:	6709                	lui	a4,0x2
ffffffffc0202d2a:	00d70823          	sb	a3,16(a4) # 2010 <kern_entry-0xffffffffc01fdff0>
     assert(pgfault_num==2);
ffffffffc0202d2e:	4394                	lw	a3,0(a5)
ffffffffc0202d30:	4ec69763          	bne	a3,a2,ffffffffc020321e <swap_init+0x6e2>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202d34:	670d                	lui	a4,0x3
ffffffffc0202d36:	46b1                	li	a3,12
ffffffffc0202d38:	00d70023          	sb	a3,0(a4) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0202d3c:	4398                	lw	a4,0(a5)
ffffffffc0202d3e:	458d                	li	a1,3
ffffffffc0202d40:	0007061b          	sext.w	a2,a4
ffffffffc0202d44:	4eb71d63          	bne	a4,a1,ffffffffc020323e <swap_init+0x702>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202d48:	670d                	lui	a4,0x3
ffffffffc0202d4a:	00d70823          	sb	a3,16(a4) # 3010 <kern_entry-0xffffffffc01fcff0>
     assert(pgfault_num==3);
ffffffffc0202d4e:	4394                	lw	a3,0(a5)
ffffffffc0202d50:	50c69763          	bne	a3,a2,ffffffffc020325e <swap_init+0x722>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202d54:	6711                	lui	a4,0x4
ffffffffc0202d56:	46b5                	li	a3,13
ffffffffc0202d58:	00d70023          	sb	a3,0(a4) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0202d5c:	4398                	lw	a4,0(a5)
ffffffffc0202d5e:	0007061b          	sext.w	a2,a4
ffffffffc0202d62:	45771e63          	bne	a4,s7,ffffffffc02031be <swap_init+0x682>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202d66:	6711                	lui	a4,0x4
ffffffffc0202d68:	00d70823          	sb	a3,16(a4) # 4010 <kern_entry-0xffffffffc01fbff0>
     assert(pgfault_num==4);
ffffffffc0202d6c:	439c                	lw	a5,0(a5)
ffffffffc0202d6e:	46c79863          	bne	a5,a2,ffffffffc02031de <swap_init+0x6a2>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202d72:	481c                	lw	a5,16(s0)
ffffffffc0202d74:	2e079963          	bnez	a5,ffffffffc0203066 <swap_init+0x52a>
ffffffffc0202d78:	0000f797          	auipc	a5,0xf
ffffffffc0202d7c:	76878793          	add	a5,a5,1896 # ffffffffc02124e0 <swap_in_seq_no>
ffffffffc0202d80:	0000f717          	auipc	a4,0xf
ffffffffc0202d84:	73870713          	add	a4,a4,1848 # ffffffffc02124b8 <swap_out_seq_no>
ffffffffc0202d88:	0000f617          	auipc	a2,0xf
ffffffffc0202d8c:	78060613          	add	a2,a2,1920 # ffffffffc0212508 <pra_list_head>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202d90:	56fd                	li	a3,-1
ffffffffc0202d92:	c394                	sw	a3,0(a5)
ffffffffc0202d94:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202d96:	0791                	add	a5,a5,4
ffffffffc0202d98:	0711                	add	a4,a4,4
ffffffffc0202d9a:	fec79ce3          	bne	a5,a2,ffffffffc0202d92 <swap_init+0x256>
ffffffffc0202d9e:	0000f717          	auipc	a4,0xf
ffffffffc0202da2:	6da70713          	add	a4,a4,1754 # ffffffffc0212478 <check_ptep>
ffffffffc0202da6:	0000f697          	auipc	a3,0xf
ffffffffc0202daa:	6f268693          	add	a3,a3,1778 # ffffffffc0212498 <check_rp>
ffffffffc0202dae:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202db0:	00013b97          	auipc	s7,0x13
ffffffffc0202db4:	7c8b8b93          	add	s7,s7,1992 # ffffffffc0216578 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202db8:	00013c17          	auipc	s8,0x13
ffffffffc0202dbc:	7c8c0c13          	add	s8,s8,1992 # ffffffffc0216580 <pages>
ffffffffc0202dc0:	00004c97          	auipc	s9,0x4
ffffffffc0202dc4:	268c8c93          	add	s9,s9,616 # ffffffffc0207028 <nbase>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0202dc8:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202dcc:	4601                	li	a2,0
ffffffffc0202dce:	85d2                	mv	a1,s4
ffffffffc0202dd0:	8556                	mv	a0,s5
ffffffffc0202dd2:	e436                	sd	a3,8(sp)
         check_ptep[i]=0;
ffffffffc0202dd4:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202dd6:	d35fe0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc0202dda:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202ddc:	66a2                	ld	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202dde:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0202de0:	1e050763          	beqz	a0,ffffffffc0202fce <swap_init+0x492>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202de4:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202de6:	0017f613          	and	a2,a5,1
ffffffffc0202dea:	20060263          	beqz	a2,ffffffffc0202fee <swap_init+0x4b2>
    if (PPN(pa) >= npage) {
ffffffffc0202dee:	000bb603          	ld	a2,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202df2:	078a                	sll	a5,a5,0x2
ffffffffc0202df4:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202df6:	14c7f863          	bgeu	a5,a2,ffffffffc0202f46 <swap_init+0x40a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202dfa:	000cb303          	ld	t1,0(s9)
ffffffffc0202dfe:	000c3603          	ld	a2,0(s8)
ffffffffc0202e02:	6288                	ld	a0,0(a3)
ffffffffc0202e04:	406787b3          	sub	a5,a5,t1
ffffffffc0202e08:	079a                	sll	a5,a5,0x6
ffffffffc0202e0a:	97b2                	add	a5,a5,a2
ffffffffc0202e0c:	6605                	lui	a2,0x1
ffffffffc0202e0e:	06a1                	add	a3,a3,8
ffffffffc0202e10:	0721                	add	a4,a4,8
ffffffffc0202e12:	9a32                	add	s4,s4,a2
ffffffffc0202e14:	14f51563          	bne	a0,a5,ffffffffc0202f5e <swap_init+0x422>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e18:	6795                	lui	a5,0x5
ffffffffc0202e1a:	fafa17e3          	bne	s4,a5,ffffffffc0202dc8 <swap_init+0x28c>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202e1e:	00003517          	auipc	a0,0x3
ffffffffc0202e22:	66250513          	add	a0,a0,1634 # ffffffffc0206480 <etext+0x1546>
ffffffffc0202e26:	b5afd0ef          	jal	ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc0202e2a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2e:	7f9c                	ld	a5,56(a5)
ffffffffc0202e30:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202e32:	34051663          	bnez	a0,ffffffffc020317e <swap_init+0x642>

     nr_free = nr_free_store;
ffffffffc0202e36:	67e2                	ld	a5,24(sp)
ffffffffc0202e38:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0202e3a:	77a2                	ld	a5,40(sp)
ffffffffc0202e3c:	e01c                	sd	a5,0(s0)
ffffffffc0202e3e:	7782                	ld	a5,32(sp)
ffffffffc0202e40:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202e42:	6088                	ld	a0,0(s1)
ffffffffc0202e44:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e46:	04a1                	add	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0202e48:	c49fe0ef          	jal	ffffffffc0201a90 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202e4c:	ff349be3          	bne	s1,s3,ffffffffc0202e42 <swap_init+0x306>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202e50:	6542                	ld	a0,16(sp)
ffffffffc0202e52:	381000ef          	jal	ffffffffc02039d2 <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202e56:	00013797          	auipc	a5,0x13
ffffffffc0202e5a:	71278793          	add	a5,a5,1810 # ffffffffc0216568 <boot_pgdir>
ffffffffc0202e5e:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202e60:	000bb703          	ld	a4,0(s7)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e64:	639c                	ld	a5,0(a5)
ffffffffc0202e66:	078a                	sll	a5,a5,0x2
ffffffffc0202e68:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e6a:	0ce7fc63          	bgeu	a5,a4,ffffffffc0202f42 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0202e6e:	000cb483          	ld	s1,0(s9)
ffffffffc0202e72:	000c3503          	ld	a0,0(s8)
ffffffffc0202e76:	409786b3          	sub	a3,a5,s1
ffffffffc0202e7a:	069a                	sll	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0202e7c:	8699                	sra	a3,a3,0x6
ffffffffc0202e7e:	96a6                	add	a3,a3,s1
    return KADDR(page2pa(page));
ffffffffc0202e80:	00c69793          	sll	a5,a3,0xc
ffffffffc0202e84:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202e86:	06b2                	sll	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202e88:	24e7ff63          	bgeu	a5,a4,ffffffffc02030e6 <swap_init+0x5aa>
     free_page(pde2page(pd0[0]));
ffffffffc0202e8c:	00013797          	auipc	a5,0x13
ffffffffc0202e90:	6e47b783          	ld	a5,1764(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc0202e94:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202e96:	639c                	ld	a5,0(a5)
ffffffffc0202e98:	078a                	sll	a5,a5,0x2
ffffffffc0202e9a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202e9c:	0ae7f363          	bgeu	a5,a4,ffffffffc0202f42 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ea0:	8f85                	sub	a5,a5,s1
ffffffffc0202ea2:	079a                	sll	a5,a5,0x6
ffffffffc0202ea4:	953e                	add	a0,a0,a5
ffffffffc0202ea6:	4585                	li	a1,1
ffffffffc0202ea8:	be9fe0ef          	jal	ffffffffc0201a90 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202eac:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc0202eb0:	000bb703          	ld	a4,0(s7)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202eb4:	078a                	sll	a5,a5,0x2
ffffffffc0202eb6:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202eb8:	08e7f563          	bgeu	a5,a4,ffffffffc0202f42 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ebc:	000c3503          	ld	a0,0(s8)
ffffffffc0202ec0:	8f85                	sub	a5,a5,s1
ffffffffc0202ec2:	079a                	sll	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0202ec4:	4585                	li	a1,1
ffffffffc0202ec6:	953e                	add	a0,a0,a5
ffffffffc0202ec8:	bc9fe0ef          	jal	ffffffffc0201a90 <free_pages>
     pgdir[0] = 0;
ffffffffc0202ecc:	000ab023          	sd	zero,0(s5)
  asm volatile("sfence.vma");
ffffffffc0202ed0:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0202ed4:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202ed6:	00878a63          	beq	a5,s0,ffffffffc0202eea <swap_init+0x3ae>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202eda:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202ede:	679c                	ld	a5,8(a5)
ffffffffc0202ee0:	3d7d                	addw	s10,s10,-1
ffffffffc0202ee2:	40ed8dbb          	subw	s11,s11,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202ee6:	fe879ae3          	bne	a5,s0,ffffffffc0202eda <swap_init+0x39e>
     }
     assert(count==0);
ffffffffc0202eea:	200d1a63          	bnez	s10,ffffffffc02030fe <swap_init+0x5c2>
     assert(total==0);
ffffffffc0202eee:	1c0d9c63          	bnez	s11,ffffffffc02030c6 <swap_init+0x58a>

     cprintf("check_swap() succeeded!\n");
ffffffffc0202ef2:	00003517          	auipc	a0,0x3
ffffffffc0202ef6:	5de50513          	add	a0,a0,1502 # ffffffffc02064d0 <etext+0x1596>
ffffffffc0202efa:	a86fd0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0202efe:	60ea                	ld	ra,152(sp)
     cprintf("check_swap() succeeded!\n");
ffffffffc0202f00:	644a                	ld	s0,144(sp)
ffffffffc0202f02:	64aa                	ld	s1,136(sp)
ffffffffc0202f04:	79e6                	ld	s3,120(sp)
ffffffffc0202f06:	7a46                	ld	s4,112(sp)
ffffffffc0202f08:	7aa6                	ld	s5,104(sp)
ffffffffc0202f0a:	6be6                	ld	s7,88(sp)
ffffffffc0202f0c:	6c46                	ld	s8,80(sp)
ffffffffc0202f0e:	6ca6                	ld	s9,72(sp)
ffffffffc0202f10:	6d06                	ld	s10,64(sp)
ffffffffc0202f12:	7de2                	ld	s11,56(sp)
}
ffffffffc0202f14:	7b06                	ld	s6,96(sp)
ffffffffc0202f16:	854a                	mv	a0,s2
ffffffffc0202f18:	690a                	ld	s2,128(sp)
ffffffffc0202f1a:	610d                	add	sp,sp,160
ffffffffc0202f1c:	8082                	ret
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f1e:	4481                	li	s1,0
ffffffffc0202f20:	b1d1                	j	ffffffffc0202be4 <swap_init+0xa8>
        assert(PageProperty(p));
ffffffffc0202f22:	00003697          	auipc	a3,0x3
ffffffffc0202f26:	8fe68693          	add	a3,a3,-1794 # ffffffffc0205820 <etext+0x8e6>
ffffffffc0202f2a:	00003617          	auipc	a2,0x3
ffffffffc0202f2e:	90660613          	add	a2,a2,-1786 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202f32:	0bd00593          	li	a1,189
ffffffffc0202f36:	00003517          	auipc	a0,0x3
ffffffffc0202f3a:	33250513          	add	a0,a0,818 # ffffffffc0206268 <etext+0x132e>
ffffffffc0202f3e:	cf4fd0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc0202f42:	bdfff0ef          	jal	ffffffffc0202b20 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0202f46:	00003617          	auipc	a2,0x3
ffffffffc0202f4a:	d6a60613          	add	a2,a2,-662 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc0202f4e:	06200593          	li	a1,98
ffffffffc0202f52:	00003517          	auipc	a0,0x3
ffffffffc0202f56:	cb650513          	add	a0,a0,-842 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0202f5a:	cd8fd0ef          	jal	ffffffffc0200432 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202f5e:	00003697          	auipc	a3,0x3
ffffffffc0202f62:	4fa68693          	add	a3,a3,1274 # ffffffffc0206458 <etext+0x151e>
ffffffffc0202f66:	00003617          	auipc	a2,0x3
ffffffffc0202f6a:	8ca60613          	add	a2,a2,-1846 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202f6e:	0fd00593          	li	a1,253
ffffffffc0202f72:	00003517          	auipc	a0,0x3
ffffffffc0202f76:	2f650513          	add	a0,a0,758 # ffffffffc0206268 <etext+0x132e>
ffffffffc0202f7a:	cb8fd0ef          	jal	ffffffffc0200432 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202f7e:	00003697          	auipc	a3,0x3
ffffffffc0202f82:	3fa68693          	add	a3,a3,1018 # ffffffffc0206378 <etext+0x143e>
ffffffffc0202f86:	00003617          	auipc	a2,0x3
ffffffffc0202f8a:	8aa60613          	add	a2,a2,-1878 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202f8e:	0dd00593          	li	a1,221
ffffffffc0202f92:	00003517          	auipc	a0,0x3
ffffffffc0202f96:	2d650513          	add	a0,a0,726 # ffffffffc0206268 <etext+0x132e>
ffffffffc0202f9a:	c98fd0ef          	jal	ffffffffc0200432 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202f9e:	00003617          	auipc	a2,0x3
ffffffffc0202fa2:	2aa60613          	add	a2,a2,682 # ffffffffc0206248 <etext+0x130e>
ffffffffc0202fa6:	02a00593          	li	a1,42
ffffffffc0202faa:	00003517          	auipc	a0,0x3
ffffffffc0202fae:	2be50513          	add	a0,a0,702 # ffffffffc0206268 <etext+0x132e>
ffffffffc0202fb2:	e922                	sd	s0,144(sp)
ffffffffc0202fb4:	e526                	sd	s1,136(sp)
ffffffffc0202fb6:	e14a                	sd	s2,128(sp)
ffffffffc0202fb8:	fcce                	sd	s3,120(sp)
ffffffffc0202fba:	f8d2                	sd	s4,112(sp)
ffffffffc0202fbc:	f4d6                	sd	s5,104(sp)
ffffffffc0202fbe:	f0da                	sd	s6,96(sp)
ffffffffc0202fc0:	ecde                	sd	s7,88(sp)
ffffffffc0202fc2:	e8e2                	sd	s8,80(sp)
ffffffffc0202fc4:	e4e6                	sd	s9,72(sp)
ffffffffc0202fc6:	e0ea                	sd	s10,64(sp)
ffffffffc0202fc8:	fc6e                	sd	s11,56(sp)
ffffffffc0202fca:	c68fd0ef          	jal	ffffffffc0200432 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202fce:	00003697          	auipc	a3,0x3
ffffffffc0202fd2:	47268693          	add	a3,a3,1138 # ffffffffc0206440 <etext+0x1506>
ffffffffc0202fd6:	00003617          	auipc	a2,0x3
ffffffffc0202fda:	85a60613          	add	a2,a2,-1958 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0202fde:	0fc00593          	li	a1,252
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	28650513          	add	a0,a0,646 # ffffffffc0206268 <etext+0x132e>
ffffffffc0202fea:	c48fd0ef          	jal	ffffffffc0200432 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202fee:	00003617          	auipc	a2,0x3
ffffffffc0202ff2:	ce260613          	add	a2,a2,-798 # ffffffffc0205cd0 <etext+0xd96>
ffffffffc0202ff6:	07400593          	li	a1,116
ffffffffc0202ffa:	00003517          	auipc	a0,0x3
ffffffffc0202ffe:	c0e50513          	add	a0,a0,-1010 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0203002:	c30fd0ef          	jal	ffffffffc0200432 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203006:	00003697          	auipc	a3,0x3
ffffffffc020300a:	38a68693          	add	a3,a3,906 # ffffffffc0206390 <etext+0x1456>
ffffffffc020300e:	00003617          	auipc	a2,0x3
ffffffffc0203012:	82260613          	add	a2,a2,-2014 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203016:	0de00593          	li	a1,222
ffffffffc020301a:	00003517          	auipc	a0,0x3
ffffffffc020301e:	24e50513          	add	a0,a0,590 # ffffffffc0206268 <etext+0x132e>
ffffffffc0203022:	c10fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203026:	00003697          	auipc	a3,0x3
ffffffffc020302a:	2a268693          	add	a3,a3,674 # ffffffffc02062c8 <etext+0x138e>
ffffffffc020302e:	00003617          	auipc	a2,0x3
ffffffffc0203032:	80260613          	add	a2,a2,-2046 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203036:	0c800593          	li	a1,200
ffffffffc020303a:	00003517          	auipc	a0,0x3
ffffffffc020303e:	22e50513          	add	a0,a0,558 # ffffffffc0206268 <etext+0x132e>
ffffffffc0203042:	bf0fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203046:	00003697          	auipc	a3,0x3
ffffffffc020304a:	81a68693          	add	a3,a3,-2022 # ffffffffc0205860 <etext+0x926>
ffffffffc020304e:	00002617          	auipc	a2,0x2
ffffffffc0203052:	7e260613          	add	a2,a2,2018 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203056:	0c000593          	li	a1,192
ffffffffc020305a:	00003517          	auipc	a0,0x3
ffffffffc020305e:	20e50513          	add	a0,a0,526 # ffffffffc0206268 <etext+0x132e>
ffffffffc0203062:	bd0fd0ef          	jal	ffffffffc0200432 <__panic>
     assert( nr_free == 0);         
ffffffffc0203066:	00003697          	auipc	a3,0x3
ffffffffc020306a:	9a268693          	add	a3,a3,-1630 # ffffffffc0205a08 <etext+0xace>
ffffffffc020306e:	00002617          	auipc	a2,0x2
ffffffffc0203072:	7c260613          	add	a2,a2,1986 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203076:	0f400593          	li	a1,244
ffffffffc020307a:	00003517          	auipc	a0,0x3
ffffffffc020307e:	1ee50513          	add	a0,a0,494 # ffffffffc0206268 <etext+0x132e>
ffffffffc0203082:	bb0fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203086:	00003697          	auipc	a3,0x3
ffffffffc020308a:	25a68693          	add	a3,a3,602 # ffffffffc02062e0 <etext+0x13a6>
ffffffffc020308e:	00002617          	auipc	a2,0x2
ffffffffc0203092:	7a260613          	add	a2,a2,1954 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203096:	0cd00593          	li	a1,205
ffffffffc020309a:	00003517          	auipc	a0,0x3
ffffffffc020309e:	1ce50513          	add	a0,a0,462 # ffffffffc0206268 <etext+0x132e>
ffffffffc02030a2:	b90fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(mm != NULL);
ffffffffc02030a6:	00003697          	auipc	a3,0x3
ffffffffc02030aa:	21268693          	add	a3,a3,530 # ffffffffc02062b8 <etext+0x137e>
ffffffffc02030ae:	00002617          	auipc	a2,0x2
ffffffffc02030b2:	78260613          	add	a2,a2,1922 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02030b6:	0c500593          	li	a1,197
ffffffffc02030ba:	00003517          	auipc	a0,0x3
ffffffffc02030be:	1ae50513          	add	a0,a0,430 # ffffffffc0206268 <etext+0x132e>
ffffffffc02030c2:	b70fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(total==0);
ffffffffc02030c6:	00003697          	auipc	a3,0x3
ffffffffc02030ca:	3fa68693          	add	a3,a3,1018 # ffffffffc02064c0 <etext+0x1586>
ffffffffc02030ce:	00002617          	auipc	a2,0x2
ffffffffc02030d2:	76260613          	add	a2,a2,1890 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02030d6:	11d00593          	li	a1,285
ffffffffc02030da:	00003517          	auipc	a0,0x3
ffffffffc02030de:	18e50513          	add	a0,a0,398 # ffffffffc0206268 <etext+0x132e>
ffffffffc02030e2:	b50fd0ef          	jal	ffffffffc0200432 <__panic>
    return KADDR(page2pa(page));
ffffffffc02030e6:	00003617          	auipc	a2,0x3
ffffffffc02030ea:	afa60613          	add	a2,a2,-1286 # ffffffffc0205be0 <etext+0xca6>
ffffffffc02030ee:	06900593          	li	a1,105
ffffffffc02030f2:	00003517          	auipc	a0,0x3
ffffffffc02030f6:	b1650513          	add	a0,a0,-1258 # ffffffffc0205c08 <etext+0xcce>
ffffffffc02030fa:	b38fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(count==0);
ffffffffc02030fe:	00003697          	auipc	a3,0x3
ffffffffc0203102:	3b268693          	add	a3,a3,946 # ffffffffc02064b0 <etext+0x1576>
ffffffffc0203106:	00002617          	auipc	a2,0x2
ffffffffc020310a:	72a60613          	add	a2,a2,1834 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020310e:	11c00593          	li	a1,284
ffffffffc0203112:	00003517          	auipc	a0,0x3
ffffffffc0203116:	15650513          	add	a0,a0,342 # ffffffffc0206268 <etext+0x132e>
ffffffffc020311a:	b18fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==1);
ffffffffc020311e:	00003697          	auipc	a3,0x3
ffffffffc0203122:	2e268693          	add	a3,a3,738 # ffffffffc0206400 <etext+0x14c6>
ffffffffc0203126:	00002617          	auipc	a2,0x2
ffffffffc020312a:	70a60613          	add	a2,a2,1802 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020312e:	09600593          	li	a1,150
ffffffffc0203132:	00003517          	auipc	a0,0x3
ffffffffc0203136:	13650513          	add	a0,a0,310 # ffffffffc0206268 <etext+0x132e>
ffffffffc020313a:	af8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020313e:	00003697          	auipc	a3,0x3
ffffffffc0203142:	27268693          	add	a3,a3,626 # ffffffffc02063b0 <etext+0x1476>
ffffffffc0203146:	00002617          	auipc	a2,0x2
ffffffffc020314a:	6ea60613          	add	a2,a2,1770 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020314e:	0eb00593          	li	a1,235
ffffffffc0203152:	00003517          	auipc	a0,0x3
ffffffffc0203156:	11650513          	add	a0,a0,278 # ffffffffc0206268 <etext+0x132e>
ffffffffc020315a:	ad8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc020315e:	00003697          	auipc	a3,0x3
ffffffffc0203162:	1da68693          	add	a3,a3,474 # ffffffffc0206338 <etext+0x13fe>
ffffffffc0203166:	00002617          	auipc	a2,0x2
ffffffffc020316a:	6ca60613          	add	a2,a2,1738 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020316e:	0d800593          	li	a1,216
ffffffffc0203172:	00003517          	auipc	a0,0x3
ffffffffc0203176:	0f650513          	add	a0,a0,246 # ffffffffc0206268 <etext+0x132e>
ffffffffc020317a:	ab8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(ret==0);
ffffffffc020317e:	00003697          	auipc	a3,0x3
ffffffffc0203182:	32a68693          	add	a3,a3,810 # ffffffffc02064a8 <etext+0x156e>
ffffffffc0203186:	00002617          	auipc	a2,0x2
ffffffffc020318a:	6aa60613          	add	a2,a2,1706 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020318e:	10300593          	li	a1,259
ffffffffc0203192:	00003517          	auipc	a0,0x3
ffffffffc0203196:	0d650513          	add	a0,a0,214 # ffffffffc0206268 <etext+0x132e>
ffffffffc020319a:	a98fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(vma != NULL);
ffffffffc020319e:	00003697          	auipc	a3,0x3
ffffffffc02031a2:	15268693          	add	a3,a3,338 # ffffffffc02062f0 <etext+0x13b6>
ffffffffc02031a6:	00002617          	auipc	a2,0x2
ffffffffc02031aa:	68a60613          	add	a2,a2,1674 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02031ae:	0d000593          	li	a1,208
ffffffffc02031b2:	00003517          	auipc	a0,0x3
ffffffffc02031b6:	0b650513          	add	a0,a0,182 # ffffffffc0206268 <etext+0x132e>
ffffffffc02031ba:	a78fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==4);
ffffffffc02031be:	00003697          	auipc	a3,0x3
ffffffffc02031c2:	27268693          	add	a3,a3,626 # ffffffffc0206430 <etext+0x14f6>
ffffffffc02031c6:	00002617          	auipc	a2,0x2
ffffffffc02031ca:	66a60613          	add	a2,a2,1642 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02031ce:	0a000593          	li	a1,160
ffffffffc02031d2:	00003517          	auipc	a0,0x3
ffffffffc02031d6:	09650513          	add	a0,a0,150 # ffffffffc0206268 <etext+0x132e>
ffffffffc02031da:	a58fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==4);
ffffffffc02031de:	00003697          	auipc	a3,0x3
ffffffffc02031e2:	25268693          	add	a3,a3,594 # ffffffffc0206430 <etext+0x14f6>
ffffffffc02031e6:	00002617          	auipc	a2,0x2
ffffffffc02031ea:	64a60613          	add	a2,a2,1610 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02031ee:	0a200593          	li	a1,162
ffffffffc02031f2:	00003517          	auipc	a0,0x3
ffffffffc02031f6:	07650513          	add	a0,a0,118 # ffffffffc0206268 <etext+0x132e>
ffffffffc02031fa:	a38fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==2);
ffffffffc02031fe:	00003697          	auipc	a3,0x3
ffffffffc0203202:	21268693          	add	a3,a3,530 # ffffffffc0206410 <etext+0x14d6>
ffffffffc0203206:	00002617          	auipc	a2,0x2
ffffffffc020320a:	62a60613          	add	a2,a2,1578 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020320e:	09800593          	li	a1,152
ffffffffc0203212:	00003517          	auipc	a0,0x3
ffffffffc0203216:	05650513          	add	a0,a0,86 # ffffffffc0206268 <etext+0x132e>
ffffffffc020321a:	a18fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==2);
ffffffffc020321e:	00003697          	auipc	a3,0x3
ffffffffc0203222:	1f268693          	add	a3,a3,498 # ffffffffc0206410 <etext+0x14d6>
ffffffffc0203226:	00002617          	auipc	a2,0x2
ffffffffc020322a:	60a60613          	add	a2,a2,1546 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020322e:	09a00593          	li	a1,154
ffffffffc0203232:	00003517          	auipc	a0,0x3
ffffffffc0203236:	03650513          	add	a0,a0,54 # ffffffffc0206268 <etext+0x132e>
ffffffffc020323a:	9f8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==3);
ffffffffc020323e:	00003697          	auipc	a3,0x3
ffffffffc0203242:	1e268693          	add	a3,a3,482 # ffffffffc0206420 <etext+0x14e6>
ffffffffc0203246:	00002617          	auipc	a2,0x2
ffffffffc020324a:	5ea60613          	add	a2,a2,1514 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020324e:	09c00593          	li	a1,156
ffffffffc0203252:	00003517          	auipc	a0,0x3
ffffffffc0203256:	01650513          	add	a0,a0,22 # ffffffffc0206268 <etext+0x132e>
ffffffffc020325a:	9d8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==3);
ffffffffc020325e:	00003697          	auipc	a3,0x3
ffffffffc0203262:	1c268693          	add	a3,a3,450 # ffffffffc0206420 <etext+0x14e6>
ffffffffc0203266:	00002617          	auipc	a2,0x2
ffffffffc020326a:	5ca60613          	add	a2,a2,1482 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020326e:	09e00593          	li	a1,158
ffffffffc0203272:	00003517          	auipc	a0,0x3
ffffffffc0203276:	ff650513          	add	a0,a0,-10 # ffffffffc0206268 <etext+0x132e>
ffffffffc020327a:	9b8fd0ef          	jal	ffffffffc0200432 <__panic>
     assert(pgfault_num==1);
ffffffffc020327e:	00003697          	auipc	a3,0x3
ffffffffc0203282:	18268693          	add	a3,a3,386 # ffffffffc0206400 <etext+0x14c6>
ffffffffc0203286:	00002617          	auipc	a2,0x2
ffffffffc020328a:	5aa60613          	add	a2,a2,1450 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020328e:	09400593          	li	a1,148
ffffffffc0203292:	00003517          	auipc	a0,0x3
ffffffffc0203296:	fd650513          	add	a0,a0,-42 # ffffffffc0206268 <etext+0x132e>
ffffffffc020329a:	998fd0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020329e <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020329e:	00013797          	auipc	a5,0x13
ffffffffc02032a2:	2fa7b783          	ld	a5,762(a5) # ffffffffc0216598 <sm>
ffffffffc02032a6:	6b9c                	ld	a5,16(a5)
ffffffffc02032a8:	8782                	jr	a5

ffffffffc02032aa <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc02032aa:	00013797          	auipc	a5,0x13
ffffffffc02032ae:	2ee7b783          	ld	a5,750(a5) # ffffffffc0216598 <sm>
ffffffffc02032b2:	739c                	ld	a5,32(a5)
ffffffffc02032b4:	8782                	jr	a5

ffffffffc02032b6 <swap_out>:
{
ffffffffc02032b6:	711d                	add	sp,sp,-96
ffffffffc02032b8:	ec86                	sd	ra,88(sp)
ffffffffc02032ba:	e8a2                	sd	s0,80(sp)
     for (i = 0; i != n; ++ i)
ffffffffc02032bc:	0e058663          	beqz	a1,ffffffffc02033a8 <swap_out+0xf2>
ffffffffc02032c0:	e0ca                	sd	s2,64(sp)
ffffffffc02032c2:	fc4e                	sd	s3,56(sp)
ffffffffc02032c4:	f852                	sd	s4,48(sp)
ffffffffc02032c6:	f456                	sd	s5,40(sp)
ffffffffc02032c8:	f05a                	sd	s6,32(sp)
ffffffffc02032ca:	ec5e                	sd	s7,24(sp)
ffffffffc02032cc:	e4a6                	sd	s1,72(sp)
ffffffffc02032ce:	e862                	sd	s8,16(sp)
ffffffffc02032d0:	8a2e                	mv	s4,a1
ffffffffc02032d2:	892a                	mv	s2,a0
ffffffffc02032d4:	8ab2                	mv	s5,a2
ffffffffc02032d6:	4401                	li	s0,0
ffffffffc02032d8:	00013997          	auipc	s3,0x13
ffffffffc02032dc:	2c098993          	add	s3,s3,704 # ffffffffc0216598 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032e0:	00003b17          	auipc	s6,0x3
ffffffffc02032e4:	270b0b13          	add	s6,s6,624 # ffffffffc0206550 <etext+0x1616>
                    cprintf("SWAP: failed to save\n");
ffffffffc02032e8:	00003b97          	auipc	s7,0x3
ffffffffc02032ec:	250b8b93          	add	s7,s7,592 # ffffffffc0206538 <etext+0x15fe>
ffffffffc02032f0:	a825                	j	ffffffffc0203328 <swap_out+0x72>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032f2:	67a2                	ld	a5,8(sp)
ffffffffc02032f4:	8626                	mv	a2,s1
ffffffffc02032f6:	85a2                	mv	a1,s0
ffffffffc02032f8:	7f94                	ld	a3,56(a5)
ffffffffc02032fa:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc02032fc:	2405                	addw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc02032fe:	82b1                	srl	a3,a3,0xc
ffffffffc0203300:	0685                	add	a3,a3,1
ffffffffc0203302:	e7ffc0ef          	jal	ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203306:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203308:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020330a:	7d1c                	ld	a5,56(a0)
ffffffffc020330c:	83b1                	srl	a5,a5,0xc
ffffffffc020330e:	0785                	add	a5,a5,1
ffffffffc0203310:	07a2                	sll	a5,a5,0x8
ffffffffc0203312:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203316:	f7afe0ef          	jal	ffffffffc0201a90 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020331a:	01893503          	ld	a0,24(s2)
ffffffffc020331e:	85a6                	mv	a1,s1
ffffffffc0203320:	f42ff0ef          	jal	ffffffffc0202a62 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203324:	048a0d63          	beq	s4,s0,ffffffffc020337e <swap_out+0xc8>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203328:	0009b783          	ld	a5,0(s3)
ffffffffc020332c:	8656                	mv	a2,s5
ffffffffc020332e:	002c                	add	a1,sp,8
ffffffffc0203330:	7b9c                	ld	a5,48(a5)
ffffffffc0203332:	854a                	mv	a0,s2
ffffffffc0203334:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203336:	e12d                	bnez	a0,ffffffffc0203398 <swap_out+0xe2>
          v=page->pra_vaddr; 
ffffffffc0203338:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020333a:	01893503          	ld	a0,24(s2)
ffffffffc020333e:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203340:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203342:	85a6                	mv	a1,s1
ffffffffc0203344:	fc6fe0ef          	jal	ffffffffc0201b0a <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203348:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020334a:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc020334c:	8b85                	and	a5,a5,1
ffffffffc020334e:	cfb9                	beqz	a5,ffffffffc02033ac <swap_out+0xf6>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203350:	65a2                	ld	a1,8(sp)
ffffffffc0203352:	7d9c                	ld	a5,56(a1)
ffffffffc0203354:	83b1                	srl	a5,a5,0xc
ffffffffc0203356:	0785                	add	a5,a5,1
ffffffffc0203358:	00879513          	sll	a0,a5,0x8
ffffffffc020335c:	62f000ef          	jal	ffffffffc020418a <swapfs_write>
ffffffffc0203360:	d949                	beqz	a0,ffffffffc02032f2 <swap_out+0x3c>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203362:	855e                	mv	a0,s7
ffffffffc0203364:	e1dfc0ef          	jal	ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203368:	0009b783          	ld	a5,0(s3)
ffffffffc020336c:	6622                	ld	a2,8(sp)
ffffffffc020336e:	4681                	li	a3,0
ffffffffc0203370:	739c                	ld	a5,32(a5)
ffffffffc0203372:	85a6                	mv	a1,s1
ffffffffc0203374:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203376:	2405                	addw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203378:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc020337a:	fa8a17e3          	bne	s4,s0,ffffffffc0203328 <swap_out+0x72>
ffffffffc020337e:	64a6                	ld	s1,72(sp)
ffffffffc0203380:	6906                	ld	s2,64(sp)
ffffffffc0203382:	79e2                	ld	s3,56(sp)
ffffffffc0203384:	7a42                	ld	s4,48(sp)
ffffffffc0203386:	7aa2                	ld	s5,40(sp)
ffffffffc0203388:	7b02                	ld	s6,32(sp)
ffffffffc020338a:	6be2                	ld	s7,24(sp)
ffffffffc020338c:	6c42                	ld	s8,16(sp)
}
ffffffffc020338e:	60e6                	ld	ra,88(sp)
ffffffffc0203390:	8522                	mv	a0,s0
ffffffffc0203392:	6446                	ld	s0,80(sp)
ffffffffc0203394:	6125                	add	sp,sp,96
ffffffffc0203396:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203398:	85a2                	mv	a1,s0
ffffffffc020339a:	00003517          	auipc	a0,0x3
ffffffffc020339e:	15650513          	add	a0,a0,342 # ffffffffc02064f0 <etext+0x15b6>
ffffffffc02033a2:	ddffc0ef          	jal	ffffffffc0200180 <cprintf>
                  break;
ffffffffc02033a6:	bfe1                	j	ffffffffc020337e <swap_out+0xc8>
     for (i = 0; i != n; ++ i)
ffffffffc02033a8:	4401                	li	s0,0
ffffffffc02033aa:	b7d5                	j	ffffffffc020338e <swap_out+0xd8>
          assert((*ptep & PTE_V) != 0);
ffffffffc02033ac:	00003697          	auipc	a3,0x3
ffffffffc02033b0:	17468693          	add	a3,a3,372 # ffffffffc0206520 <etext+0x15e6>
ffffffffc02033b4:	00002617          	auipc	a2,0x2
ffffffffc02033b8:	47c60613          	add	a2,a2,1148 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02033bc:	06900593          	li	a1,105
ffffffffc02033c0:	00003517          	auipc	a0,0x3
ffffffffc02033c4:	ea850513          	add	a0,a0,-344 # ffffffffc0206268 <etext+0x132e>
ffffffffc02033c8:	86afd0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02033cc <swap_in>:
{
ffffffffc02033cc:	7179                	add	sp,sp,-48
ffffffffc02033ce:	e84a                	sd	s2,16(sp)
ffffffffc02033d0:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc02033d2:	4505                	li	a0,1
{
ffffffffc02033d4:	ec26                	sd	s1,24(sp)
ffffffffc02033d6:	e44e                	sd	s3,8(sp)
ffffffffc02033d8:	f406                	sd	ra,40(sp)
ffffffffc02033da:	f022                	sd	s0,32(sp)
ffffffffc02033dc:	84ae                	mv	s1,a1
ffffffffc02033de:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc02033e0:	e20fe0ef          	jal	ffffffffc0201a00 <alloc_pages>
     assert(result!=NULL);
ffffffffc02033e4:	c129                	beqz	a0,ffffffffc0203426 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc02033e6:	842a                	mv	s0,a0
ffffffffc02033e8:	01893503          	ld	a0,24(s2)
ffffffffc02033ec:	4601                	li	a2,0
ffffffffc02033ee:	85a6                	mv	a1,s1
ffffffffc02033f0:	f1afe0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc02033f4:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc02033f6:	6108                	ld	a0,0(a0)
ffffffffc02033f8:	85a2                	mv	a1,s0
ffffffffc02033fa:	503000ef          	jal	ffffffffc02040fc <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc02033fe:	00093583          	ld	a1,0(s2)
ffffffffc0203402:	8626                	mv	a2,s1
ffffffffc0203404:	00003517          	auipc	a0,0x3
ffffffffc0203408:	19c50513          	add	a0,a0,412 # ffffffffc02065a0 <etext+0x1666>
ffffffffc020340c:	81a1                	srl	a1,a1,0x8
ffffffffc020340e:	d73fc0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0203412:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203414:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203418:	7402                	ld	s0,32(sp)
ffffffffc020341a:	64e2                	ld	s1,24(sp)
ffffffffc020341c:	6942                	ld	s2,16(sp)
ffffffffc020341e:	69a2                	ld	s3,8(sp)
ffffffffc0203420:	4501                	li	a0,0
ffffffffc0203422:	6145                	add	sp,sp,48
ffffffffc0203424:	8082                	ret
     assert(result!=NULL);
ffffffffc0203426:	00003697          	auipc	a3,0x3
ffffffffc020342a:	16a68693          	add	a3,a3,362 # ffffffffc0206590 <etext+0x1656>
ffffffffc020342e:	00002617          	auipc	a2,0x2
ffffffffc0203432:	40260613          	add	a2,a2,1026 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203436:	07f00593          	li	a1,127
ffffffffc020343a:	00003517          	auipc	a0,0x3
ffffffffc020343e:	e2e50513          	add	a0,a0,-466 # ffffffffc0206268 <etext+0x132e>
ffffffffc0203442:	ff1fc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0203446 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203446:	0000f797          	auipc	a5,0xf
ffffffffc020344a:	0c278793          	add	a5,a5,194 # ffffffffc0212508 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc020344e:	f51c                	sd	a5,40(a0)
ffffffffc0203450:	e79c                	sd	a5,8(a5)
ffffffffc0203452:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203454:	4501                	li	a0,0
ffffffffc0203456:	8082                	ret

ffffffffc0203458 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203458:	4501                	li	a0,0
ffffffffc020345a:	8082                	ret

ffffffffc020345c <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020345c:	4501                	li	a0,0
ffffffffc020345e:	8082                	ret

ffffffffc0203460 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203460:	4501                	li	a0,0
ffffffffc0203462:	8082                	ret

ffffffffc0203464 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203464:	711d                	add	sp,sp,-96
ffffffffc0203466:	fc4e                	sd	s3,56(sp)
ffffffffc0203468:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc020346a:	00003517          	auipc	a0,0x3
ffffffffc020346e:	17650513          	add	a0,a0,374 # ffffffffc02065e0 <etext+0x16a6>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203472:	698d                	lui	s3,0x3
ffffffffc0203474:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203476:	e4a6                	sd	s1,72(sp)
ffffffffc0203478:	ec86                	sd	ra,88(sp)
ffffffffc020347a:	e8a2                	sd	s0,80(sp)
ffffffffc020347c:	e0ca                	sd	s2,64(sp)
ffffffffc020347e:	f456                	sd	s5,40(sp)
ffffffffc0203480:	f05a                	sd	s6,32(sp)
ffffffffc0203482:	ec5e                	sd	s7,24(sp)
ffffffffc0203484:	e862                	sd	s8,16(sp)
ffffffffc0203486:	e466                	sd	s9,8(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203488:	cf9fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020348c:	01498023          	sb	s4,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203490:	00013497          	auipc	s1,0x13
ffffffffc0203494:	1104a483          	lw	s1,272(s1) # ffffffffc02165a0 <pgfault_num>
ffffffffc0203498:	4791                	li	a5,4
ffffffffc020349a:	14f49963          	bne	s1,a5,ffffffffc02035ec <_fifo_check_swap+0x188>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020349e:	00003517          	auipc	a0,0x3
ffffffffc02034a2:	18250513          	add	a0,a0,386 # ffffffffc0206620 <etext+0x16e6>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02034a6:	6a85                	lui	s5,0x1
ffffffffc02034a8:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02034aa:	cd7fc0ef          	jal	ffffffffc0200180 <cprintf>
ffffffffc02034ae:	00013417          	auipc	s0,0x13
ffffffffc02034b2:	0f240413          	add	s0,s0,242 # ffffffffc02165a0 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02034b6:	016a8023          	sb	s6,0(s5) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc02034ba:	401c                	lw	a5,0(s0)
ffffffffc02034bc:	0007891b          	sext.w	s2,a5
ffffffffc02034c0:	2a979663          	bne	a5,s1,ffffffffc020376c <_fifo_check_swap+0x308>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02034c4:	00003517          	auipc	a0,0x3
ffffffffc02034c8:	18450513          	add	a0,a0,388 # ffffffffc0206648 <etext+0x170e>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02034cc:	6b91                	lui	s7,0x4
ffffffffc02034ce:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02034d0:	cb1fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02034d4:	018b8023          	sb	s8,0(s7) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02034d8:	401c                	lw	a5,0(s0)
ffffffffc02034da:	00078c9b          	sext.w	s9,a5
ffffffffc02034de:	27279763          	bne	a5,s2,ffffffffc020374c <_fifo_check_swap+0x2e8>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02034e2:	00003517          	auipc	a0,0x3
ffffffffc02034e6:	18e50513          	add	a0,a0,398 # ffffffffc0206670 <etext+0x1736>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02034ea:	6489                	lui	s1,0x2
ffffffffc02034ec:	492d                	li	s2,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02034ee:	c93fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02034f2:	01248023          	sb	s2,0(s1) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02034f6:	401c                	lw	a5,0(s0)
ffffffffc02034f8:	23979a63          	bne	a5,s9,ffffffffc020372c <_fifo_check_swap+0x2c8>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02034fc:	00003517          	auipc	a0,0x3
ffffffffc0203500:	19c50513          	add	a0,a0,412 # ffffffffc0206698 <etext+0x175e>
ffffffffc0203504:	c7dfc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203508:	6795                	lui	a5,0x5
ffffffffc020350a:	4739                	li	a4,14
ffffffffc020350c:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0203510:	401c                	lw	a5,0(s0)
ffffffffc0203512:	4715                	li	a4,5
ffffffffc0203514:	00078c9b          	sext.w	s9,a5
ffffffffc0203518:	1ee79a63          	bne	a5,a4,ffffffffc020370c <_fifo_check_swap+0x2a8>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020351c:	00003517          	auipc	a0,0x3
ffffffffc0203520:	15450513          	add	a0,a0,340 # ffffffffc0206670 <etext+0x1736>
ffffffffc0203524:	c5dfc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203528:	01248023          	sb	s2,0(s1)
    assert(pgfault_num==5);
ffffffffc020352c:	401c                	lw	a5,0(s0)
ffffffffc020352e:	1b979f63          	bne	a5,s9,ffffffffc02036ec <_fifo_check_swap+0x288>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203532:	00003517          	auipc	a0,0x3
ffffffffc0203536:	0ee50513          	add	a0,a0,238 # ffffffffc0206620 <etext+0x16e6>
ffffffffc020353a:	c47fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020353e:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203542:	4018                	lw	a4,0(s0)
ffffffffc0203544:	4799                	li	a5,6
ffffffffc0203546:	18f71363          	bne	a4,a5,ffffffffc02036cc <_fifo_check_swap+0x268>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020354a:	00003517          	auipc	a0,0x3
ffffffffc020354e:	12650513          	add	a0,a0,294 # ffffffffc0206670 <etext+0x1736>
ffffffffc0203552:	c2ffc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203556:	01248023          	sb	s2,0(s1)
    assert(pgfault_num==7);
ffffffffc020355a:	4018                	lw	a4,0(s0)
ffffffffc020355c:	479d                	li	a5,7
ffffffffc020355e:	14f71763          	bne	a4,a5,ffffffffc02036ac <_fifo_check_swap+0x248>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203562:	00003517          	auipc	a0,0x3
ffffffffc0203566:	07e50513          	add	a0,a0,126 # ffffffffc02065e0 <etext+0x16a6>
ffffffffc020356a:	c17fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020356e:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203572:	4018                	lw	a4,0(s0)
ffffffffc0203574:	47a1                	li	a5,8
ffffffffc0203576:	10f71b63          	bne	a4,a5,ffffffffc020368c <_fifo_check_swap+0x228>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc020357a:	00003517          	auipc	a0,0x3
ffffffffc020357e:	0ce50513          	add	a0,a0,206 # ffffffffc0206648 <etext+0x170e>
ffffffffc0203582:	bfffc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203586:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc020358a:	4018                	lw	a4,0(s0)
ffffffffc020358c:	47a5                	li	a5,9
ffffffffc020358e:	0cf71f63          	bne	a4,a5,ffffffffc020366c <_fifo_check_swap+0x208>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203592:	00003517          	auipc	a0,0x3
ffffffffc0203596:	10650513          	add	a0,a0,262 # ffffffffc0206698 <etext+0x175e>
ffffffffc020359a:	be7fc0ef          	jal	ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020359e:	6795                	lui	a5,0x5
ffffffffc02035a0:	4739                	li	a4,14
ffffffffc02035a2:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc02035a6:	401c                	lw	a5,0(s0)
ffffffffc02035a8:	4729                	li	a4,10
ffffffffc02035aa:	0007849b          	sext.w	s1,a5
ffffffffc02035ae:	08e79f63          	bne	a5,a4,ffffffffc020364c <_fifo_check_swap+0x1e8>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc02035b2:	00003517          	auipc	a0,0x3
ffffffffc02035b6:	06e50513          	add	a0,a0,110 # ffffffffc0206620 <etext+0x16e6>
ffffffffc02035ba:	bc7fc0ef          	jal	ffffffffc0200180 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02035be:	6785                	lui	a5,0x1
ffffffffc02035c0:	0007c783          	lbu	a5,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02035c4:	06979463          	bne	a5,s1,ffffffffc020362c <_fifo_check_swap+0x1c8>
    assert(pgfault_num==11);
ffffffffc02035c8:	4018                	lw	a4,0(s0)
ffffffffc02035ca:	47ad                	li	a5,11
ffffffffc02035cc:	04f71063          	bne	a4,a5,ffffffffc020360c <_fifo_check_swap+0x1a8>
}
ffffffffc02035d0:	60e6                	ld	ra,88(sp)
ffffffffc02035d2:	6446                	ld	s0,80(sp)
ffffffffc02035d4:	64a6                	ld	s1,72(sp)
ffffffffc02035d6:	6906                	ld	s2,64(sp)
ffffffffc02035d8:	79e2                	ld	s3,56(sp)
ffffffffc02035da:	7a42                	ld	s4,48(sp)
ffffffffc02035dc:	7aa2                	ld	s5,40(sp)
ffffffffc02035de:	7b02                	ld	s6,32(sp)
ffffffffc02035e0:	6be2                	ld	s7,24(sp)
ffffffffc02035e2:	6c42                	ld	s8,16(sp)
ffffffffc02035e4:	6ca2                	ld	s9,8(sp)
ffffffffc02035e6:	4501                	li	a0,0
ffffffffc02035e8:	6125                	add	sp,sp,96
ffffffffc02035ea:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02035ec:	00003697          	auipc	a3,0x3
ffffffffc02035f0:	e4468693          	add	a3,a3,-444 # ffffffffc0206430 <etext+0x14f6>
ffffffffc02035f4:	00002617          	auipc	a2,0x2
ffffffffc02035f8:	23c60613          	add	a2,a2,572 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02035fc:	05100593          	li	a1,81
ffffffffc0203600:	00003517          	auipc	a0,0x3
ffffffffc0203604:	00850513          	add	a0,a0,8 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203608:	e2bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==11);
ffffffffc020360c:	00003697          	auipc	a3,0x3
ffffffffc0203610:	13c68693          	add	a3,a3,316 # ffffffffc0206748 <etext+0x180e>
ffffffffc0203614:	00002617          	auipc	a2,0x2
ffffffffc0203618:	21c60613          	add	a2,a2,540 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020361c:	07300593          	li	a1,115
ffffffffc0203620:	00003517          	auipc	a0,0x3
ffffffffc0203624:	fe850513          	add	a0,a0,-24 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203628:	e0bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc020362c:	00003697          	auipc	a3,0x3
ffffffffc0203630:	0f468693          	add	a3,a3,244 # ffffffffc0206720 <etext+0x17e6>
ffffffffc0203634:	00002617          	auipc	a2,0x2
ffffffffc0203638:	1fc60613          	add	a2,a2,508 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020363c:	07100593          	li	a1,113
ffffffffc0203640:	00003517          	auipc	a0,0x3
ffffffffc0203644:	fc850513          	add	a0,a0,-56 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203648:	debfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==10);
ffffffffc020364c:	00003697          	auipc	a3,0x3
ffffffffc0203650:	0c468693          	add	a3,a3,196 # ffffffffc0206710 <etext+0x17d6>
ffffffffc0203654:	00002617          	auipc	a2,0x2
ffffffffc0203658:	1dc60613          	add	a2,a2,476 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020365c:	06f00593          	li	a1,111
ffffffffc0203660:	00003517          	auipc	a0,0x3
ffffffffc0203664:	fa850513          	add	a0,a0,-88 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203668:	dcbfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==9);
ffffffffc020366c:	00003697          	auipc	a3,0x3
ffffffffc0203670:	09468693          	add	a3,a3,148 # ffffffffc0206700 <etext+0x17c6>
ffffffffc0203674:	00002617          	auipc	a2,0x2
ffffffffc0203678:	1bc60613          	add	a2,a2,444 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020367c:	06c00593          	li	a1,108
ffffffffc0203680:	00003517          	auipc	a0,0x3
ffffffffc0203684:	f8850513          	add	a0,a0,-120 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203688:	dabfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==8);
ffffffffc020368c:	00003697          	auipc	a3,0x3
ffffffffc0203690:	06468693          	add	a3,a3,100 # ffffffffc02066f0 <etext+0x17b6>
ffffffffc0203694:	00002617          	auipc	a2,0x2
ffffffffc0203698:	19c60613          	add	a2,a2,412 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020369c:	06900593          	li	a1,105
ffffffffc02036a0:	00003517          	auipc	a0,0x3
ffffffffc02036a4:	f6850513          	add	a0,a0,-152 # ffffffffc0206608 <etext+0x16ce>
ffffffffc02036a8:	d8bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==7);
ffffffffc02036ac:	00003697          	auipc	a3,0x3
ffffffffc02036b0:	03468693          	add	a3,a3,52 # ffffffffc02066e0 <etext+0x17a6>
ffffffffc02036b4:	00002617          	auipc	a2,0x2
ffffffffc02036b8:	17c60613          	add	a2,a2,380 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02036bc:	06600593          	li	a1,102
ffffffffc02036c0:	00003517          	auipc	a0,0x3
ffffffffc02036c4:	f4850513          	add	a0,a0,-184 # ffffffffc0206608 <etext+0x16ce>
ffffffffc02036c8:	d6bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==6);
ffffffffc02036cc:	00003697          	auipc	a3,0x3
ffffffffc02036d0:	00468693          	add	a3,a3,4 # ffffffffc02066d0 <etext+0x1796>
ffffffffc02036d4:	00002617          	auipc	a2,0x2
ffffffffc02036d8:	15c60613          	add	a2,a2,348 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02036dc:	06300593          	li	a1,99
ffffffffc02036e0:	00003517          	auipc	a0,0x3
ffffffffc02036e4:	f2850513          	add	a0,a0,-216 # ffffffffc0206608 <etext+0x16ce>
ffffffffc02036e8:	d4bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==5);
ffffffffc02036ec:	00003697          	auipc	a3,0x3
ffffffffc02036f0:	fd468693          	add	a3,a3,-44 # ffffffffc02066c0 <etext+0x1786>
ffffffffc02036f4:	00002617          	auipc	a2,0x2
ffffffffc02036f8:	13c60613          	add	a2,a2,316 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02036fc:	06000593          	li	a1,96
ffffffffc0203700:	00003517          	auipc	a0,0x3
ffffffffc0203704:	f0850513          	add	a0,a0,-248 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203708:	d2bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==5);
ffffffffc020370c:	00003697          	auipc	a3,0x3
ffffffffc0203710:	fb468693          	add	a3,a3,-76 # ffffffffc02066c0 <etext+0x1786>
ffffffffc0203714:	00002617          	auipc	a2,0x2
ffffffffc0203718:	11c60613          	add	a2,a2,284 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020371c:	05d00593          	li	a1,93
ffffffffc0203720:	00003517          	auipc	a0,0x3
ffffffffc0203724:	ee850513          	add	a0,a0,-280 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203728:	d0bfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==4);
ffffffffc020372c:	00003697          	auipc	a3,0x3
ffffffffc0203730:	d0468693          	add	a3,a3,-764 # ffffffffc0206430 <etext+0x14f6>
ffffffffc0203734:	00002617          	auipc	a2,0x2
ffffffffc0203738:	0fc60613          	add	a2,a2,252 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020373c:	05a00593          	li	a1,90
ffffffffc0203740:	00003517          	auipc	a0,0x3
ffffffffc0203744:	ec850513          	add	a0,a0,-312 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203748:	cebfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==4);
ffffffffc020374c:	00003697          	auipc	a3,0x3
ffffffffc0203750:	ce468693          	add	a3,a3,-796 # ffffffffc0206430 <etext+0x14f6>
ffffffffc0203754:	00002617          	auipc	a2,0x2
ffffffffc0203758:	0dc60613          	add	a2,a2,220 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020375c:	05700593          	li	a1,87
ffffffffc0203760:	00003517          	auipc	a0,0x3
ffffffffc0203764:	ea850513          	add	a0,a0,-344 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203768:	ccbfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgfault_num==4);
ffffffffc020376c:	00003697          	auipc	a3,0x3
ffffffffc0203770:	cc468693          	add	a3,a3,-828 # ffffffffc0206430 <etext+0x14f6>
ffffffffc0203774:	00002617          	auipc	a2,0x2
ffffffffc0203778:	0bc60613          	add	a2,a2,188 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020377c:	05400593          	li	a1,84
ffffffffc0203780:	00003517          	auipc	a0,0x3
ffffffffc0203784:	e8850513          	add	a0,a0,-376 # ffffffffc0206608 <etext+0x16ce>
ffffffffc0203788:	cabfc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020378c <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020378c:	751c                	ld	a5,40(a0)
{
ffffffffc020378e:	1141                	add	sp,sp,-16
ffffffffc0203790:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0203792:	cf91                	beqz	a5,ffffffffc02037ae <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0203794:	ee0d                	bnez	a2,ffffffffc02037ce <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0203796:	679c                	ld	a5,8(a5)
}
ffffffffc0203798:	60a2                	ld	ra,8(sp)
ffffffffc020379a:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc020379c:	6394                	ld	a3,0(a5)
ffffffffc020379e:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc02037a0:	fd878793          	add	a5,a5,-40
    prev->next = next;
ffffffffc02037a4:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02037a6:	e314                	sd	a3,0(a4)
ffffffffc02037a8:	e19c                	sd	a5,0(a1)
}
ffffffffc02037aa:	0141                	add	sp,sp,16
ffffffffc02037ac:	8082                	ret
         assert(head != NULL);
ffffffffc02037ae:	00003697          	auipc	a3,0x3
ffffffffc02037b2:	faa68693          	add	a3,a3,-86 # ffffffffc0206758 <etext+0x181e>
ffffffffc02037b6:	00002617          	auipc	a2,0x2
ffffffffc02037ba:	07a60613          	add	a2,a2,122 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02037be:	04100593          	li	a1,65
ffffffffc02037c2:	00003517          	auipc	a0,0x3
ffffffffc02037c6:	e4650513          	add	a0,a0,-442 # ffffffffc0206608 <etext+0x16ce>
ffffffffc02037ca:	c69fc0ef          	jal	ffffffffc0200432 <__panic>
     assert(in_tick==0);
ffffffffc02037ce:	00003697          	auipc	a3,0x3
ffffffffc02037d2:	f9a68693          	add	a3,a3,-102 # ffffffffc0206768 <etext+0x182e>
ffffffffc02037d6:	00002617          	auipc	a2,0x2
ffffffffc02037da:	05a60613          	add	a2,a2,90 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02037de:	04200593          	li	a1,66
ffffffffc02037e2:	00003517          	auipc	a0,0x3
ffffffffc02037e6:	e2650513          	add	a0,a0,-474 # ffffffffc0206608 <etext+0x16ce>
ffffffffc02037ea:	c49fc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02037ee <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02037ee:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02037f0:	cb91                	beqz	a5,ffffffffc0203804 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02037f2:	6394                	ld	a3,0(a5)
ffffffffc02037f4:	02860713          	add	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02037f8:	e398                	sd	a4,0(a5)
ffffffffc02037fa:	e698                	sd	a4,8(a3)
}
ffffffffc02037fc:	4501                	li	a0,0
    elm->next = next;
ffffffffc02037fe:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0203800:	f614                	sd	a3,40(a2)
ffffffffc0203802:	8082                	ret
{
ffffffffc0203804:	1141                	add	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0203806:	00003697          	auipc	a3,0x3
ffffffffc020380a:	f7268693          	add	a3,a3,-142 # ffffffffc0206778 <etext+0x183e>
ffffffffc020380e:	00002617          	auipc	a2,0x2
ffffffffc0203812:	02260613          	add	a2,a2,34 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203816:	03200593          	li	a1,50
ffffffffc020381a:	00003517          	auipc	a0,0x3
ffffffffc020381e:	dee50513          	add	a0,a0,-530 # ffffffffc0206608 <etext+0x16ce>
{
ffffffffc0203822:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203824:	c0ffc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0203828 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203828:	1141                	add	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020382a:	00003697          	auipc	a3,0x3
ffffffffc020382e:	f8668693          	add	a3,a3,-122 # ffffffffc02067b0 <etext+0x1876>
ffffffffc0203832:	00002617          	auipc	a2,0x2
ffffffffc0203836:	ffe60613          	add	a2,a2,-2 # ffffffffc0205830 <etext+0x8f6>
ffffffffc020383a:	07e00593          	li	a1,126
ffffffffc020383e:	00003517          	auipc	a0,0x3
ffffffffc0203842:	f9250513          	add	a0,a0,-110 # ffffffffc02067d0 <etext+0x1896>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203846:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203848:	bebfc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020384c <mm_create>:
mm_create(void) {
ffffffffc020384c:	1141                	add	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020384e:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0203852:	e022                	sd	s0,0(sp)
ffffffffc0203854:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203856:	fd3fd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc020385a:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020385c:	c105                	beqz	a0,ffffffffc020387c <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc020385e:	e408                	sd	a0,8(s0)
ffffffffc0203860:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0203862:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203866:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020386a:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020386e:	00013797          	auipc	a5,0x13
ffffffffc0203872:	d1a7a783          	lw	a5,-742(a5) # ffffffffc0216588 <swap_init_ok>
ffffffffc0203876:	eb81                	bnez	a5,ffffffffc0203886 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc0203878:	02053423          	sd	zero,40(a0)
}
ffffffffc020387c:	60a2                	ld	ra,8(sp)
ffffffffc020387e:	8522                	mv	a0,s0
ffffffffc0203880:	6402                	ld	s0,0(sp)
ffffffffc0203882:	0141                	add	sp,sp,16
ffffffffc0203884:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203886:	a19ff0ef          	jal	ffffffffc020329e <swap_init_mm>
}
ffffffffc020388a:	60a2                	ld	ra,8(sp)
ffffffffc020388c:	8522                	mv	a0,s0
ffffffffc020388e:	6402                	ld	s0,0(sp)
ffffffffc0203890:	0141                	add	sp,sp,16
ffffffffc0203892:	8082                	ret

ffffffffc0203894 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0203894:	1101                	add	sp,sp,-32
ffffffffc0203896:	e04a                	sd	s2,0(sp)
ffffffffc0203898:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020389a:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020389e:	e822                	sd	s0,16(sp)
ffffffffc02038a0:	e426                	sd	s1,8(sp)
ffffffffc02038a2:	ec06                	sd	ra,24(sp)
ffffffffc02038a4:	84ae                	mv	s1,a1
ffffffffc02038a6:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038a8:	f81fd0ef          	jal	ffffffffc0201828 <kmalloc>
    if (vma != NULL) {
ffffffffc02038ac:	c509                	beqz	a0,ffffffffc02038b6 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02038ae:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02038b2:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02038b4:	cd00                	sw	s0,24(a0)
}
ffffffffc02038b6:	60e2                	ld	ra,24(sp)
ffffffffc02038b8:	6442                	ld	s0,16(sp)
ffffffffc02038ba:	64a2                	ld	s1,8(sp)
ffffffffc02038bc:	6902                	ld	s2,0(sp)
ffffffffc02038be:	6105                	add	sp,sp,32
ffffffffc02038c0:	8082                	ret

ffffffffc02038c2 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02038c2:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02038c4:	c505                	beqz	a0,ffffffffc02038ec <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02038c6:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02038c8:	c501                	beqz	a0,ffffffffc02038d0 <find_vma+0xe>
ffffffffc02038ca:	651c                	ld	a5,8(a0)
ffffffffc02038cc:	02f5f663          	bgeu	a1,a5,ffffffffc02038f8 <find_vma+0x36>
    return listelm->next;
ffffffffc02038d0:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc02038d2:	00f68d63          	beq	a3,a5,ffffffffc02038ec <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02038d6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02038da:	00e5e663          	bltu	a1,a4,ffffffffc02038e6 <find_vma+0x24>
ffffffffc02038de:	ff07b703          	ld	a4,-16(a5)
ffffffffc02038e2:	00e5e763          	bltu	a1,a4,ffffffffc02038f0 <find_vma+0x2e>
ffffffffc02038e6:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02038e8:	fef697e3          	bne	a3,a5,ffffffffc02038d6 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02038ec:	4501                	li	a0,0
}
ffffffffc02038ee:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02038f0:	fe078513          	add	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02038f4:	ea88                	sd	a0,16(a3)
ffffffffc02038f6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02038f8:	691c                	ld	a5,16(a0)
ffffffffc02038fa:	fcf5fbe3          	bgeu	a1,a5,ffffffffc02038d0 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02038fe:	ea88                	sd	a0,16(a3)
ffffffffc0203900:	8082                	ret

ffffffffc0203902 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203902:	6590                	ld	a2,8(a1)
ffffffffc0203904:	0105b803          	ld	a6,16(a1) # 1010 <kern_entry-0xffffffffc01feff0>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0203908:	1141                	add	sp,sp,-16
ffffffffc020390a:	e406                	sd	ra,8(sp)
ffffffffc020390c:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020390e:	01066763          	bltu	a2,a6,ffffffffc020391c <insert_vma_struct+0x1a>
ffffffffc0203912:	a085                	j	ffffffffc0203972 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0203914:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203918:	04e66863          	bltu	a2,a4,ffffffffc0203968 <insert_vma_struct+0x66>
ffffffffc020391c:	86be                	mv	a3,a5
ffffffffc020391e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0203920:	fef51ae3          	bne	a0,a5,ffffffffc0203914 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0203924:	02a68463          	beq	a3,a0,ffffffffc020394c <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203928:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020392c:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203930:	08e8f163          	bgeu	a7,a4,ffffffffc02039b2 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203934:	04e66f63          	bltu	a2,a4,ffffffffc0203992 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0203938:	00f50a63          	beq	a0,a5,ffffffffc020394c <insert_vma_struct+0x4a>
ffffffffc020393c:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203940:	05076963          	bltu	a4,a6,ffffffffc0203992 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203944:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203948:	02c77363          	bgeu	a4,a2,ffffffffc020396e <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020394c:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020394e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203950:	02058613          	add	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203954:	e390                	sd	a2,0(a5)
ffffffffc0203956:	e690                	sd	a2,8(a3)
}
ffffffffc0203958:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020395a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020395c:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc020395e:	0017079b          	addw	a5,a4,1
ffffffffc0203962:	d11c                	sw	a5,32(a0)
}
ffffffffc0203964:	0141                	add	sp,sp,16
ffffffffc0203966:	8082                	ret
    if (le_prev != list) {
ffffffffc0203968:	fca690e3          	bne	a3,a0,ffffffffc0203928 <insert_vma_struct+0x26>
ffffffffc020396c:	bfd1                	j	ffffffffc0203940 <insert_vma_struct+0x3e>
ffffffffc020396e:	ebbff0ef          	jal	ffffffffc0203828 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203972:	00003697          	auipc	a3,0x3
ffffffffc0203976:	e6e68693          	add	a3,a3,-402 # ffffffffc02067e0 <etext+0x18a6>
ffffffffc020397a:	00002617          	auipc	a2,0x2
ffffffffc020397e:	eb660613          	add	a2,a2,-330 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203982:	08500593          	li	a1,133
ffffffffc0203986:	00003517          	auipc	a0,0x3
ffffffffc020398a:	e4a50513          	add	a0,a0,-438 # ffffffffc02067d0 <etext+0x1896>
ffffffffc020398e:	aa5fc0ef          	jal	ffffffffc0200432 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203992:	00003697          	auipc	a3,0x3
ffffffffc0203996:	e8e68693          	add	a3,a3,-370 # ffffffffc0206820 <etext+0x18e6>
ffffffffc020399a:	00002617          	auipc	a2,0x2
ffffffffc020399e:	e9660613          	add	a2,a2,-362 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02039a2:	07d00593          	li	a1,125
ffffffffc02039a6:	00003517          	auipc	a0,0x3
ffffffffc02039aa:	e2a50513          	add	a0,a0,-470 # ffffffffc02067d0 <etext+0x1896>
ffffffffc02039ae:	a85fc0ef          	jal	ffffffffc0200432 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02039b2:	00003697          	auipc	a3,0x3
ffffffffc02039b6:	e4e68693          	add	a3,a3,-434 # ffffffffc0206800 <etext+0x18c6>
ffffffffc02039ba:	00002617          	auipc	a2,0x2
ffffffffc02039be:	e7660613          	add	a2,a2,-394 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02039c2:	07c00593          	li	a1,124
ffffffffc02039c6:	00003517          	auipc	a0,0x3
ffffffffc02039ca:	e0a50513          	add	a0,a0,-502 # ffffffffc02067d0 <etext+0x1896>
ffffffffc02039ce:	a65fc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02039d2 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc02039d2:	1141                	add	sp,sp,-16
ffffffffc02039d4:	e022                	sd	s0,0(sp)
ffffffffc02039d6:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02039d8:	6508                	ld	a0,8(a0)
ffffffffc02039da:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02039dc:	00a40c63          	beq	s0,a0,ffffffffc02039f4 <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc02039e0:	6118                	ld	a4,0(a0)
ffffffffc02039e2:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02039e4:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc02039e6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02039e8:	e398                	sd	a4,0(a5)
ffffffffc02039ea:	ee9fd0ef          	jal	ffffffffc02018d2 <kfree>
    return listelm->next;
ffffffffc02039ee:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02039f0:	fea418e3          	bne	s0,a0,ffffffffc02039e0 <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
ffffffffc02039f4:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02039f6:	6402                	ld	s0,0(sp)
ffffffffc02039f8:	60a2                	ld	ra,8(sp)
ffffffffc02039fa:	0141                	add	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02039fc:	ed7fd06f          	j	ffffffffc02018d2 <kfree>

ffffffffc0203a00 <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203a00:	7139                	add	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a02:	03000513          	li	a0,48
vmm_init(void) {
ffffffffc0203a06:	fc06                	sd	ra,56(sp)
ffffffffc0203a08:	f822                	sd	s0,48(sp)
ffffffffc0203a0a:	f426                	sd	s1,40(sp)
ffffffffc0203a0c:	f04a                	sd	s2,32(sp)
ffffffffc0203a0e:	ec4e                	sd	s3,24(sp)
ffffffffc0203a10:	e852                	sd	s4,16(sp)
ffffffffc0203a12:	e456                	sd	s5,8(sp)
ffffffffc0203a14:	e05a                	sd	s6,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a16:	e13fd0ef          	jal	ffffffffc0201828 <kmalloc>
    if (mm != NULL) {
ffffffffc0203a1a:	32050f63          	beqz	a0,ffffffffc0203d58 <vmm_init+0x358>
    elm->prev = elm->next = elm;
ffffffffc0203a1e:	e508                	sd	a0,8(a0)
ffffffffc0203a20:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a22:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a26:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a2a:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203a2e:	00013797          	auipc	a5,0x13
ffffffffc0203a32:	b5a7a783          	lw	a5,-1190(a5) # ffffffffc0216588 <swap_init_ok>
ffffffffc0203a36:	842a                	mv	s0,a0
ffffffffc0203a38:	2e079d63          	bnez	a5,ffffffffc0203d32 <vmm_init+0x332>
        else mm->sm_priv = NULL;
ffffffffc0203a3c:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0203a40:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a44:	03000513          	li	a0,48
ffffffffc0203a48:	de1fd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc0203a4c:	00248913          	add	s2,s1,2
ffffffffc0203a50:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0203a52:	2e050363          	beqz	a0,ffffffffc0203d38 <vmm_init+0x338>
        vma->vm_start = vm_start;
ffffffffc0203a56:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a58:	01253823          	sd	s2,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a5c:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0203a60:	14ed                	add	s1,s1,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a62:	8522                	mv	a0,s0
ffffffffc0203a64:	e9fff0ef          	jal	ffffffffc0203902 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0203a68:	fcf1                	bnez	s1,ffffffffc0203a44 <vmm_init+0x44>
ffffffffc0203a6a:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203a6e:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a72:	03000513          	li	a0,48
ffffffffc0203a76:	db3fd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc0203a7a:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0203a7c:	2e050e63          	beqz	a0,ffffffffc0203d78 <vmm_init+0x378>
        vma->vm_end = vm_end;
ffffffffc0203a80:	00248793          	add	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203a84:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a86:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a88:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203a8c:	0495                	add	s1,s1,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a8e:	8522                	mv	a0,s0
ffffffffc0203a90:	e73ff0ef          	jal	ffffffffc0203902 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203a94:	fd249fe3          	bne	s1,s2,ffffffffc0203a72 <vmm_init+0x72>
    return listelm->next;
ffffffffc0203a98:	00843a03          	ld	s4,8(s0)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0203a9c:	3a8a0563          	beq	s4,s0,ffffffffc0203e46 <vmm_init+0x446>
    list_entry_t *le = list_next(&(mm->mmap_list));
ffffffffc0203aa0:	87d2                	mv	a5,s4
        assert(le != &(mm->mmap_list));
ffffffffc0203aa2:	4715                	li	a4,5
    for (i = 1; i <= step2; i ++) {
ffffffffc0203aa4:	1f400593          	li	a1,500
ffffffffc0203aa8:	a021                	j	ffffffffc0203ab0 <vmm_init+0xb0>
        assert(le != &(mm->mmap_list));
ffffffffc0203aaa:	0715                	add	a4,a4,5
ffffffffc0203aac:	38878d63          	beq	a5,s0,ffffffffc0203e46 <vmm_init+0x446>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ab0:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203ab4:	36d71963          	bne	a4,a3,ffffffffc0203e26 <vmm_init+0x426>
ffffffffc0203ab8:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203abc:	00270693          	add	a3,a4,2
ffffffffc0203ac0:	36d61363          	bne	a2,a3,ffffffffc0203e26 <vmm_init+0x426>
ffffffffc0203ac4:	679c                	ld	a5,8(a5)
    for (i = 1; i <= step2; i ++) {
ffffffffc0203ac6:	feb712e3          	bne	a4,a1,ffffffffc0203aaa <vmm_init+0xaa>
ffffffffc0203aca:	4a9d                	li	s5,7
ffffffffc0203acc:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203ace:	1f900b13          	li	s6,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203ad2:	85a6                	mv	a1,s1
ffffffffc0203ad4:	8522                	mv	a0,s0
ffffffffc0203ad6:	dedff0ef          	jal	ffffffffc02038c2 <find_vma>
ffffffffc0203ada:	89aa                	mv	s3,a0
        assert(vma1 != NULL);
ffffffffc0203adc:	3a050563          	beqz	a0,ffffffffc0203e86 <vmm_init+0x486>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203ae0:	00148593          	add	a1,s1,1
ffffffffc0203ae4:	8522                	mv	a0,s0
ffffffffc0203ae6:	dddff0ef          	jal	ffffffffc02038c2 <find_vma>
ffffffffc0203aea:	892a                	mv	s2,a0
        assert(vma2 != NULL);
ffffffffc0203aec:	36050d63          	beqz	a0,ffffffffc0203e66 <vmm_init+0x466>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203af0:	85d6                	mv	a1,s5
ffffffffc0203af2:	8522                	mv	a0,s0
ffffffffc0203af4:	dcfff0ef          	jal	ffffffffc02038c2 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203af8:	3e051763          	bnez	a0,ffffffffc0203ee6 <vmm_init+0x4e6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203afc:	00348593          	add	a1,s1,3
ffffffffc0203b00:	8522                	mv	a0,s0
ffffffffc0203b02:	dc1ff0ef          	jal	ffffffffc02038c2 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b06:	3c051063          	bnez	a0,ffffffffc0203ec6 <vmm_init+0x4c6>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0203b0a:	00448593          	add	a1,s1,4
ffffffffc0203b0e:	8522                	mv	a0,s0
ffffffffc0203b10:	db3ff0ef          	jal	ffffffffc02038c2 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b14:	38051963          	bnez	a0,ffffffffc0203ea6 <vmm_init+0x4a6>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203b18:	0089b783          	ld	a5,8(s3)
ffffffffc0203b1c:	2ef49563          	bne	s1,a5,ffffffffc0203e06 <vmm_init+0x406>
ffffffffc0203b20:	0109b783          	ld	a5,16(s3)
ffffffffc0203b24:	2f579163          	bne	a5,s5,ffffffffc0203e06 <vmm_init+0x406>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203b28:	00893783          	ld	a5,8(s2)
ffffffffc0203b2c:	2af49d63          	bne	s1,a5,ffffffffc0203de6 <vmm_init+0x3e6>
ffffffffc0203b30:	01093783          	ld	a5,16(s2)
ffffffffc0203b34:	2b579963          	bne	a5,s5,ffffffffc0203de6 <vmm_init+0x3e6>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203b38:	0495                	add	s1,s1,5
ffffffffc0203b3a:	0a95                	add	s5,s5,5
ffffffffc0203b3c:	f9649be3          	bne	s1,s6,ffffffffc0203ad2 <vmm_init+0xd2>
ffffffffc0203b40:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0203b42:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0203b44:	85a6                	mv	a1,s1
ffffffffc0203b46:	8522                	mv	a0,s0
ffffffffc0203b48:	d7bff0ef          	jal	ffffffffc02038c2 <find_vma>
        if (vma_below_5 != NULL ) {
ffffffffc0203b4c:	3a051d63          	bnez	a0,ffffffffc0203f06 <vmm_init+0x506>
    for (i =4; i>=0; i--) {
ffffffffc0203b50:	14fd                	add	s1,s1,-1
ffffffffc0203b52:	ff2499e3          	bne	s1,s2,ffffffffc0203b44 <vmm_init+0x144>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203b56:	000a3703          	ld	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203b5a:	008a3783          	ld	a5,8(s4)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0203b5e:	fe0a0513          	add	a0,s4,-32
    prev->next = next;
ffffffffc0203b62:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203b64:	e398                	sd	a4,0(a5)
ffffffffc0203b66:	d6dfd0ef          	jal	ffffffffc02018d2 <kfree>
    return listelm->next;
ffffffffc0203b6a:	00843a03          	ld	s4,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203b6e:	ff4414e3          	bne	s0,s4,ffffffffc0203b56 <vmm_init+0x156>
    kfree(mm); //kfree mm
ffffffffc0203b72:	8522                	mv	a0,s0
ffffffffc0203b74:	d5ffd0ef          	jal	ffffffffc02018d2 <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203b78:	00003517          	auipc	a0,0x3
ffffffffc0203b7c:	e0850513          	add	a0,a0,-504 # ffffffffc0206980 <etext+0x1a46>
ffffffffc0203b80:	e00fc0ef          	jal	ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203b84:	f4dfd0ef          	jal	ffffffffc0201ad0 <nr_free_pages>
ffffffffc0203b88:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203b8a:	03000513          	li	a0,48
ffffffffc0203b8e:	c9bfd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc0203b92:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203b94:	22050263          	beqz	a0,ffffffffc0203db8 <vmm_init+0x3b8>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203b98:	00013797          	auipc	a5,0x13
ffffffffc0203b9c:	9f07a783          	lw	a5,-1552(a5) # ffffffffc0216588 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0203ba0:	e508                	sd	a0,8(a0)
ffffffffc0203ba2:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203ba4:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203ba8:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203bac:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203bb0:	22079863          	bnez	a5,ffffffffc0203de0 <vmm_init+0x3e0>
        else mm->sm_priv = NULL;
ffffffffc0203bb4:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203bb8:	00013917          	auipc	s2,0x13
ffffffffc0203bbc:	9b093903          	ld	s2,-1616(s2) # ffffffffc0216568 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0203bc0:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0203bc4:	00013717          	auipc	a4,0x13
ffffffffc0203bc8:	9e873223          	sd	s0,-1564(a4) # ffffffffc02165a8 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203bcc:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0203bd0:	3c079d63          	bnez	a5,ffffffffc0203faa <vmm_init+0x5aa>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bd4:	03000513          	li	a0,48
ffffffffc0203bd8:	c51fd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc0203bdc:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0203bde:	1a050d63          	beqz	a0,ffffffffc0203d98 <vmm_init+0x398>
        vma->vm_end = vm_end;
ffffffffc0203be2:	002007b7          	lui	a5,0x200
ffffffffc0203be6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203be8:	4789                	li	a5,2
ffffffffc0203bea:	cd1c                	sw	a5,24(a0)

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203bec:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203bee:	00053423          	sd	zero,8(a0)
    insert_vma_struct(mm, vma);
ffffffffc0203bf2:	8522                	mv	a0,s0
ffffffffc0203bf4:	d0fff0ef          	jal	ffffffffc0203902 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203bf8:	10000593          	li	a1,256
ffffffffc0203bfc:	8522                	mv	a0,s0
ffffffffc0203bfe:	cc5ff0ef          	jal	ffffffffc02038c2 <find_vma>
ffffffffc0203c02:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0203c06:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203c0a:	38a99063          	bne	s3,a0,ffffffffc0203f8a <vmm_init+0x58a>
        *(char *)(addr + i) = i;
ffffffffc0203c0e:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0203c12:	0785                	add	a5,a5,1
ffffffffc0203c14:	fee79de3          	bne	a5,a4,ffffffffc0203c0e <vmm_init+0x20e>
ffffffffc0203c18:	6705                	lui	a4,0x1
ffffffffc0203c1a:	10000793          	li	a5,256
ffffffffc0203c1e:	35670713          	add	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0203c22:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0203c26:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0203c2a:	0785                	add	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0203c2c:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0203c2e:	fec79ce3          	bne	a5,a2,ffffffffc0203c26 <vmm_init+0x226>
    }
    assert(sum == 0);
ffffffffc0203c32:	32071c63          	bnez	a4,ffffffffc0203f6a <vmm_init+0x56a>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c36:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203c3a:	00013a97          	auipc	s5,0x13
ffffffffc0203c3e:	93ea8a93          	add	s5,s5,-1730 # ffffffffc0216578 <npage>
ffffffffc0203c42:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c46:	078a                	sll	a5,a5,0x2
ffffffffc0203c48:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c4a:	30e7f463          	bgeu	a5,a4,ffffffffc0203f52 <vmm_init+0x552>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c4e:	00003a17          	auipc	s4,0x3
ffffffffc0203c52:	3daa3a03          	ld	s4,986(s4) # ffffffffc0207028 <nbase>
ffffffffc0203c56:	414786b3          	sub	a3,a5,s4
ffffffffc0203c5a:	069a                	sll	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203c5c:	8699                	sra	a3,a3,0x6
ffffffffc0203c5e:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0203c60:	00c69793          	sll	a5,a3,0xc
ffffffffc0203c64:	83b1                	srl	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203c66:	06b2                	sll	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203c68:	2ce7f963          	bgeu	a5,a4,ffffffffc0203f3a <vmm_init+0x53a>
ffffffffc0203c6c:	00013797          	auipc	a5,0x13
ffffffffc0203c70:	9047b783          	ld	a5,-1788(a5) # ffffffffc0216570 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0203c74:	4581                	li	a1,0
ffffffffc0203c76:	854a                	mv	a0,s2
ffffffffc0203c78:	00f689b3          	add	s3,a3,a5
ffffffffc0203c7c:	8bafe0ef          	jal	ffffffffc0201d36 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c80:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0203c84:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203c88:	078a                	sll	a5,a5,0x2
ffffffffc0203c8a:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c8c:	2ce7f363          	bgeu	a5,a4,ffffffffc0203f52 <vmm_init+0x552>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c90:	00013997          	auipc	s3,0x13
ffffffffc0203c94:	8f098993          	add	s3,s3,-1808 # ffffffffc0216580 <pages>
ffffffffc0203c98:	0009b503          	ld	a0,0(s3)
ffffffffc0203c9c:	414787b3          	sub	a5,a5,s4
ffffffffc0203ca0:	079a                	sll	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0203ca2:	953e                	add	a0,a0,a5
ffffffffc0203ca4:	4585                	li	a1,1
ffffffffc0203ca6:	debfd0ef          	jal	ffffffffc0201a90 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203caa:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203cae:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203cb2:	078a                	sll	a5,a5,0x2
ffffffffc0203cb4:	83b1                	srl	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203cb6:	28e7fe63          	bgeu	a5,a4,ffffffffc0203f52 <vmm_init+0x552>
    return &pages[PPN(pa) - nbase];
ffffffffc0203cba:	0009b503          	ld	a0,0(s3)
ffffffffc0203cbe:	414787b3          	sub	a5,a5,s4
ffffffffc0203cc2:	079a                	sll	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0203cc4:	4585                	li	a1,1
ffffffffc0203cc6:	953e                	add	a0,a0,a5
ffffffffc0203cc8:	dc9fd0ef          	jal	ffffffffc0201a90 <free_pages>
    pgdir[0] = 0;
ffffffffc0203ccc:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0203cd0:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203cd4:	6408                	ld	a0,8(s0)
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0203cd6:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203cda:	00a40c63          	beq	s0,a0,ffffffffc0203cf2 <vmm_init+0x2f2>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203cde:	6118                	ld	a4,0(a0)
ffffffffc0203ce0:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0203ce2:	1501                	add	a0,a0,-32
    prev->next = next;
ffffffffc0203ce4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203ce6:	e398                	sd	a4,0(a5)
ffffffffc0203ce8:	bebfd0ef          	jal	ffffffffc02018d2 <kfree>
    return listelm->next;
ffffffffc0203cec:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203cee:	fea418e3          	bne	s0,a0,ffffffffc0203cde <vmm_init+0x2de>
    kfree(mm); //kfree mm
ffffffffc0203cf2:	8522                	mv	a0,s0
ffffffffc0203cf4:	bdffd0ef          	jal	ffffffffc02018d2 <kfree>
    mm_destroy(mm);
    check_mm_struct = NULL;
ffffffffc0203cf8:	00013797          	auipc	a5,0x13
ffffffffc0203cfc:	8a07b823          	sd	zero,-1872(a5) # ffffffffc02165a8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203d00:	dd1fd0ef          	jal	ffffffffc0201ad0 <nr_free_pages>
ffffffffc0203d04:	2ca49363          	bne	s1,a0,ffffffffc0203fca <vmm_init+0x5ca>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203d08:	00003517          	auipc	a0,0x3
ffffffffc0203d0c:	d0850513          	add	a0,a0,-760 # ffffffffc0206a10 <etext+0x1ad6>
ffffffffc0203d10:	c70fc0ef          	jal	ffffffffc0200180 <cprintf>
}
ffffffffc0203d14:	7442                	ld	s0,48(sp)
ffffffffc0203d16:	70e2                	ld	ra,56(sp)
ffffffffc0203d18:	74a2                	ld	s1,40(sp)
ffffffffc0203d1a:	7902                	ld	s2,32(sp)
ffffffffc0203d1c:	69e2                	ld	s3,24(sp)
ffffffffc0203d1e:	6a42                	ld	s4,16(sp)
ffffffffc0203d20:	6aa2                	ld	s5,8(sp)
ffffffffc0203d22:	6b02                	ld	s6,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d24:	00003517          	auipc	a0,0x3
ffffffffc0203d28:	d0c50513          	add	a0,a0,-756 # ffffffffc0206a30 <etext+0x1af6>
}
ffffffffc0203d2c:	6121                	add	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203d2e:	c52fc06f          	j	ffffffffc0200180 <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203d32:	d6cff0ef          	jal	ffffffffc020329e <swap_init_mm>
    for (i = step1; i >= 1; i --) {
ffffffffc0203d36:	b329                	j	ffffffffc0203a40 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203d38:	00002697          	auipc	a3,0x2
ffffffffc0203d3c:	5b868693          	add	a3,a3,1464 # ffffffffc02062f0 <etext+0x13b6>
ffffffffc0203d40:	00002617          	auipc	a2,0x2
ffffffffc0203d44:	af060613          	add	a2,a2,-1296 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203d48:	0c900593          	li	a1,201
ffffffffc0203d4c:	00003517          	auipc	a0,0x3
ffffffffc0203d50:	a8450513          	add	a0,a0,-1404 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203d54:	edefc0ef          	jal	ffffffffc0200432 <__panic>
    assert(mm != NULL);
ffffffffc0203d58:	00002697          	auipc	a3,0x2
ffffffffc0203d5c:	56068693          	add	a3,a3,1376 # ffffffffc02062b8 <etext+0x137e>
ffffffffc0203d60:	00002617          	auipc	a2,0x2
ffffffffc0203d64:	ad060613          	add	a2,a2,-1328 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203d68:	0c200593          	li	a1,194
ffffffffc0203d6c:	00003517          	auipc	a0,0x3
ffffffffc0203d70:	a6450513          	add	a0,a0,-1436 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203d74:	ebefc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma != NULL);
ffffffffc0203d78:	00002697          	auipc	a3,0x2
ffffffffc0203d7c:	57868693          	add	a3,a3,1400 # ffffffffc02062f0 <etext+0x13b6>
ffffffffc0203d80:	00002617          	auipc	a2,0x2
ffffffffc0203d84:	ab060613          	add	a2,a2,-1360 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203d88:	0cf00593          	li	a1,207
ffffffffc0203d8c:	00003517          	auipc	a0,0x3
ffffffffc0203d90:	a4450513          	add	a0,a0,-1468 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203d94:	e9efc0ef          	jal	ffffffffc0200432 <__panic>
    assert(vma != NULL);
ffffffffc0203d98:	00002697          	auipc	a3,0x2
ffffffffc0203d9c:	55868693          	add	a3,a3,1368 # ffffffffc02062f0 <etext+0x13b6>
ffffffffc0203da0:	00002617          	auipc	a2,0x2
ffffffffc0203da4:	a9060613          	add	a2,a2,-1392 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203da8:	10800593          	li	a1,264
ffffffffc0203dac:	00003517          	auipc	a0,0x3
ffffffffc0203db0:	a2450513          	add	a0,a0,-1500 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203db4:	e7efc0ef          	jal	ffffffffc0200432 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0203db8:	00003697          	auipc	a3,0x3
ffffffffc0203dbc:	be868693          	add	a3,a3,-1048 # ffffffffc02069a0 <etext+0x1a66>
ffffffffc0203dc0:	00002617          	auipc	a2,0x2
ffffffffc0203dc4:	a7060613          	add	a2,a2,-1424 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203dc8:	10100593          	li	a1,257
ffffffffc0203dcc:	00003517          	auipc	a0,0x3
ffffffffc0203dd0:	a0450513          	add	a0,a0,-1532 # ffffffffc02067d0 <etext+0x1896>
    check_mm_struct = mm_create();
ffffffffc0203dd4:	00012797          	auipc	a5,0x12
ffffffffc0203dd8:	7c07ba23          	sd	zero,2004(a5) # ffffffffc02165a8 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc0203ddc:	e56fc0ef          	jal	ffffffffc0200432 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203de0:	cbeff0ef          	jal	ffffffffc020329e <swap_init_mm>
    assert(check_mm_struct != NULL);
ffffffffc0203de4:	bbd1                	j	ffffffffc0203bb8 <vmm_init+0x1b8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203de6:	00003697          	auipc	a3,0x3
ffffffffc0203dea:	b2a68693          	add	a3,a3,-1238 # ffffffffc0206910 <etext+0x19d6>
ffffffffc0203dee:	00002617          	auipc	a2,0x2
ffffffffc0203df2:	a4260613          	add	a2,a2,-1470 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203df6:	0e900593          	li	a1,233
ffffffffc0203dfa:	00003517          	auipc	a0,0x3
ffffffffc0203dfe:	9d650513          	add	a0,a0,-1578 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203e02:	e30fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203e06:	00003697          	auipc	a3,0x3
ffffffffc0203e0a:	ada68693          	add	a3,a3,-1318 # ffffffffc02068e0 <etext+0x19a6>
ffffffffc0203e0e:	00002617          	auipc	a2,0x2
ffffffffc0203e12:	a2260613          	add	a2,a2,-1502 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203e16:	0e800593          	li	a1,232
ffffffffc0203e1a:	00003517          	auipc	a0,0x3
ffffffffc0203e1e:	9b650513          	add	a0,a0,-1610 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203e22:	e10fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203e26:	00003697          	auipc	a3,0x3
ffffffffc0203e2a:	a3268693          	add	a3,a3,-1486 # ffffffffc0206858 <etext+0x191e>
ffffffffc0203e2e:	00002617          	auipc	a2,0x2
ffffffffc0203e32:	a0260613          	add	a2,a2,-1534 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203e36:	0d800593          	li	a1,216
ffffffffc0203e3a:	00003517          	auipc	a0,0x3
ffffffffc0203e3e:	99650513          	add	a0,a0,-1642 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203e42:	df0fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203e46:	00003697          	auipc	a3,0x3
ffffffffc0203e4a:	9fa68693          	add	a3,a3,-1542 # ffffffffc0206840 <etext+0x1906>
ffffffffc0203e4e:	00002617          	auipc	a2,0x2
ffffffffc0203e52:	9e260613          	add	a2,a2,-1566 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203e56:	0d600593          	li	a1,214
ffffffffc0203e5a:	00003517          	auipc	a0,0x3
ffffffffc0203e5e:	97650513          	add	a0,a0,-1674 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203e62:	dd0fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma2 != NULL);
ffffffffc0203e66:	00003697          	auipc	a3,0x3
ffffffffc0203e6a:	a3a68693          	add	a3,a3,-1478 # ffffffffc02068a0 <etext+0x1966>
ffffffffc0203e6e:	00002617          	auipc	a2,0x2
ffffffffc0203e72:	9c260613          	add	a2,a2,-1598 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203e76:	0e000593          	li	a1,224
ffffffffc0203e7a:	00003517          	auipc	a0,0x3
ffffffffc0203e7e:	95650513          	add	a0,a0,-1706 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203e82:	db0fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma1 != NULL);
ffffffffc0203e86:	00003697          	auipc	a3,0x3
ffffffffc0203e8a:	a0a68693          	add	a3,a3,-1526 # ffffffffc0206890 <etext+0x1956>
ffffffffc0203e8e:	00002617          	auipc	a2,0x2
ffffffffc0203e92:	9a260613          	add	a2,a2,-1630 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203e96:	0de00593          	li	a1,222
ffffffffc0203e9a:	00003517          	auipc	a0,0x3
ffffffffc0203e9e:	93650513          	add	a0,a0,-1738 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203ea2:	d90fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma5 == NULL);
ffffffffc0203ea6:	00003697          	auipc	a3,0x3
ffffffffc0203eaa:	a2a68693          	add	a3,a3,-1494 # ffffffffc02068d0 <etext+0x1996>
ffffffffc0203eae:	00002617          	auipc	a2,0x2
ffffffffc0203eb2:	98260613          	add	a2,a2,-1662 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203eb6:	0e600593          	li	a1,230
ffffffffc0203eba:	00003517          	auipc	a0,0x3
ffffffffc0203ebe:	91650513          	add	a0,a0,-1770 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203ec2:	d70fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma4 == NULL);
ffffffffc0203ec6:	00003697          	auipc	a3,0x3
ffffffffc0203eca:	9fa68693          	add	a3,a3,-1542 # ffffffffc02068c0 <etext+0x1986>
ffffffffc0203ece:	00002617          	auipc	a2,0x2
ffffffffc0203ed2:	96260613          	add	a2,a2,-1694 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203ed6:	0e400593          	li	a1,228
ffffffffc0203eda:	00003517          	auipc	a0,0x3
ffffffffc0203ede:	8f650513          	add	a0,a0,-1802 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203ee2:	d50fc0ef          	jal	ffffffffc0200432 <__panic>
        assert(vma3 == NULL);
ffffffffc0203ee6:	00003697          	auipc	a3,0x3
ffffffffc0203eea:	9ca68693          	add	a3,a3,-1590 # ffffffffc02068b0 <etext+0x1976>
ffffffffc0203eee:	00002617          	auipc	a2,0x2
ffffffffc0203ef2:	94260613          	add	a2,a2,-1726 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203ef6:	0e200593          	li	a1,226
ffffffffc0203efa:	00003517          	auipc	a0,0x3
ffffffffc0203efe:	8d650513          	add	a0,a0,-1834 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203f02:	d30fc0ef          	jal	ffffffffc0200432 <__panic>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203f06:	6914                	ld	a3,16(a0)
ffffffffc0203f08:	6510                	ld	a2,8(a0)
ffffffffc0203f0a:	0004859b          	sext.w	a1,s1
ffffffffc0203f0e:	00003517          	auipc	a0,0x3
ffffffffc0203f12:	a3250513          	add	a0,a0,-1486 # ffffffffc0206940 <etext+0x1a06>
ffffffffc0203f16:	a6afc0ef          	jal	ffffffffc0200180 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203f1a:	00003697          	auipc	a3,0x3
ffffffffc0203f1e:	a4e68693          	add	a3,a3,-1458 # ffffffffc0206968 <etext+0x1a2e>
ffffffffc0203f22:	00002617          	auipc	a2,0x2
ffffffffc0203f26:	90e60613          	add	a2,a2,-1778 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203f2a:	0f100593          	li	a1,241
ffffffffc0203f2e:	00003517          	auipc	a0,0x3
ffffffffc0203f32:	8a250513          	add	a0,a0,-1886 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203f36:	cfcfc0ef          	jal	ffffffffc0200432 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203f3a:	00002617          	auipc	a2,0x2
ffffffffc0203f3e:	ca660613          	add	a2,a2,-858 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0203f42:	06900593          	li	a1,105
ffffffffc0203f46:	00002517          	auipc	a0,0x2
ffffffffc0203f4a:	cc250513          	add	a0,a0,-830 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0203f4e:	ce4fc0ef          	jal	ffffffffc0200432 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f52:	00002617          	auipc	a2,0x2
ffffffffc0203f56:	d5e60613          	add	a2,a2,-674 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc0203f5a:	06200593          	li	a1,98
ffffffffc0203f5e:	00002517          	auipc	a0,0x2
ffffffffc0203f62:	caa50513          	add	a0,a0,-854 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0203f66:	cccfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(sum == 0);
ffffffffc0203f6a:	00003697          	auipc	a3,0x3
ffffffffc0203f6e:	a6e68693          	add	a3,a3,-1426 # ffffffffc02069d8 <etext+0x1a9e>
ffffffffc0203f72:	00002617          	auipc	a2,0x2
ffffffffc0203f76:	8be60613          	add	a2,a2,-1858 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203f7a:	11700593          	li	a1,279
ffffffffc0203f7e:	00003517          	auipc	a0,0x3
ffffffffc0203f82:	85250513          	add	a0,a0,-1966 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203f86:	cacfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f8a:	00003697          	auipc	a3,0x3
ffffffffc0203f8e:	a2e68693          	add	a3,a3,-1490 # ffffffffc02069b8 <etext+0x1a7e>
ffffffffc0203f92:	00002617          	auipc	a2,0x2
ffffffffc0203f96:	89e60613          	add	a2,a2,-1890 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203f9a:	10d00593          	li	a1,269
ffffffffc0203f9e:	00003517          	auipc	a0,0x3
ffffffffc0203fa2:	83250513          	add	a0,a0,-1998 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203fa6:	c8cfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0203faa:	00002697          	auipc	a3,0x2
ffffffffc0203fae:	33668693          	add	a3,a3,822 # ffffffffc02062e0 <etext+0x13a6>
ffffffffc0203fb2:	00002617          	auipc	a2,0x2
ffffffffc0203fb6:	87e60613          	add	a2,a2,-1922 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203fba:	10500593          	li	a1,261
ffffffffc0203fbe:	00003517          	auipc	a0,0x3
ffffffffc0203fc2:	81250513          	add	a0,a0,-2030 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203fc6:	c6cfc0ef          	jal	ffffffffc0200432 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203fca:	00003697          	auipc	a3,0x3
ffffffffc0203fce:	a1e68693          	add	a3,a3,-1506 # ffffffffc02069e8 <etext+0x1aae>
ffffffffc0203fd2:	00002617          	auipc	a2,0x2
ffffffffc0203fd6:	85e60613          	add	a2,a2,-1954 # ffffffffc0205830 <etext+0x8f6>
ffffffffc0203fda:	12400593          	li	a1,292
ffffffffc0203fde:	00002517          	auipc	a0,0x2
ffffffffc0203fe2:	7f250513          	add	a0,a0,2034 # ffffffffc02067d0 <etext+0x1896>
ffffffffc0203fe6:	c4cfc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0203fea <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203fea:	7179                	add	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203fec:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203fee:	f022                	sd	s0,32(sp)
ffffffffc0203ff0:	ec26                	sd	s1,24(sp)
ffffffffc0203ff2:	f406                	sd	ra,40(sp)
ffffffffc0203ff4:	8432                	mv	s0,a2
ffffffffc0203ff6:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203ff8:	8cbff0ef          	jal	ffffffffc02038c2 <find_vma>

    pgfault_num++;
ffffffffc0203ffc:	00012797          	auipc	a5,0x12
ffffffffc0204000:	5a47a783          	lw	a5,1444(a5) # ffffffffc02165a0 <pgfault_num>
ffffffffc0204004:	2785                	addw	a5,a5,1
ffffffffc0204006:	00012717          	auipc	a4,0x12
ffffffffc020400a:	58f72d23          	sw	a5,1434(a4) # ffffffffc02165a0 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc020400e:	c541                	beqz	a0,ffffffffc0204096 <do_pgfault+0xac>
ffffffffc0204010:	651c                	ld	a5,8(a0)
ffffffffc0204012:	08f46263          	bltu	s0,a5,ffffffffc0204096 <do_pgfault+0xac>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204016:	4d1c                	lw	a5,24(a0)
ffffffffc0204018:	e84a                	sd	s2,16(sp)
        perm |= READ_WRITE;
ffffffffc020401a:	495d                	li	s2,23
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020401c:	8b89                	and	a5,a5,2
ffffffffc020401e:	cbb9                	beqz	a5,ffffffffc0204074 <do_pgfault+0x8a>
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204020:	77fd                	lui	a5,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204022:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204024:	8c7d                	and	s0,s0,a5
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204026:	4605                	li	a2,1
ffffffffc0204028:	85a2                	mv	a1,s0
ffffffffc020402a:	ae1fd0ef          	jal	ffffffffc0201b0a <get_pte>
ffffffffc020402e:	c541                	beqz	a0,ffffffffc02040b6 <do_pgfault+0xcc>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0204030:	610c                	ld	a1,0(a0)
ffffffffc0204032:	c1b9                	beqz	a1,ffffffffc0204078 <do_pgfault+0x8e>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0204034:	00012797          	auipc	a5,0x12
ffffffffc0204038:	5547a783          	lw	a5,1364(a5) # ffffffffc0216588 <swap_init_ok>
ffffffffc020403c:	c7b5                	beqz	a5,ffffffffc02040a8 <do_pgfault+0xbe>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            swap_in(mm, addr, &page);
ffffffffc020403e:	0030                	add	a2,sp,8
ffffffffc0204040:	85a2                	mv	a1,s0
ffffffffc0204042:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204044:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc0204046:	b86ff0ef          	jal	ffffffffc02033cc <swap_in>
            page_insert(mm->pgdir, page, addr, perm); 
ffffffffc020404a:	65a2                	ld	a1,8(sp)
ffffffffc020404c:	6c88                	ld	a0,24(s1)
ffffffffc020404e:	86ca                	mv	a3,s2
ffffffffc0204050:	8622                	mv	a2,s0
ffffffffc0204052:	d81fd0ef          	jal	ffffffffc0201dd2 <page_insert>
            swap_map_swappable(mm, addr, page, 1);
ffffffffc0204056:	6622                	ld	a2,8(sp)
ffffffffc0204058:	4685                	li	a3,1
ffffffffc020405a:	85a2                	mv	a1,s0
ffffffffc020405c:	8526                	mv	a0,s1
ffffffffc020405e:	a4cff0ef          	jal	ffffffffc02032aa <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204062:	67a2                	ld	a5,8(sp)
ffffffffc0204064:	ff80                	sd	s0,56(a5)
ffffffffc0204066:	6942                	ld	s2,16(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0204068:	4501                	li	a0,0
failed:
    return ret;
}
ffffffffc020406a:	70a2                	ld	ra,40(sp)
ffffffffc020406c:	7402                	ld	s0,32(sp)
ffffffffc020406e:	64e2                	ld	s1,24(sp)
ffffffffc0204070:	6145                	add	sp,sp,48
ffffffffc0204072:	8082                	ret
    uint32_t perm = PTE_U;
ffffffffc0204074:	4941                	li	s2,16
ffffffffc0204076:	b76d                	j	ffffffffc0204020 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204078:	6c88                	ld	a0,24(s1)
ffffffffc020407a:	864a                	mv	a2,s2
ffffffffc020407c:	85a2                	mv	a1,s0
ffffffffc020407e:	9ebfe0ef          	jal	ffffffffc0202a68 <pgdir_alloc_page>
ffffffffc0204082:	f175                	bnez	a0,ffffffffc0204066 <do_pgfault+0x7c>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204084:	00003517          	auipc	a0,0x3
ffffffffc0204088:	a1450513          	add	a0,a0,-1516 # ffffffffc0206a98 <etext+0x1b5e>
ffffffffc020408c:	8f4fc0ef          	jal	ffffffffc0200180 <cprintf>
            goto failed;
ffffffffc0204090:	6942                	ld	s2,16(sp)
    ret = -E_NO_MEM;
ffffffffc0204092:	5571                	li	a0,-4
ffffffffc0204094:	bfd9                	j	ffffffffc020406a <do_pgfault+0x80>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204096:	85a2                	mv	a1,s0
ffffffffc0204098:	00003517          	auipc	a0,0x3
ffffffffc020409c:	9b050513          	add	a0,a0,-1616 # ffffffffc0206a48 <etext+0x1b0e>
ffffffffc02040a0:	8e0fc0ef          	jal	ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc02040a4:	5575                	li	a0,-3
        goto failed;
ffffffffc02040a6:	b7d1                	j	ffffffffc020406a <do_pgfault+0x80>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02040a8:	00003517          	auipc	a0,0x3
ffffffffc02040ac:	a1850513          	add	a0,a0,-1512 # ffffffffc0206ac0 <etext+0x1b86>
ffffffffc02040b0:	8d0fc0ef          	jal	ffffffffc0200180 <cprintf>
            goto failed;
ffffffffc02040b4:	bff1                	j	ffffffffc0204090 <do_pgfault+0xa6>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc02040b6:	00003517          	auipc	a0,0x3
ffffffffc02040ba:	9c250513          	add	a0,a0,-1598 # ffffffffc0206a78 <etext+0x1b3e>
ffffffffc02040be:	8c2fc0ef          	jal	ffffffffc0200180 <cprintf>
        goto failed;
ffffffffc02040c2:	b7f9                	j	ffffffffc0204090 <do_pgfault+0xa6>

ffffffffc02040c4 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc02040c4:	1141                	add	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040c6:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc02040c8:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040ca:	c8cfc0ef          	jal	ffffffffc0200556 <ide_device_valid>
ffffffffc02040ce:	cd01                	beqz	a0,ffffffffc02040e6 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040d0:	4505                	li	a0,1
ffffffffc02040d2:	c8afc0ef          	jal	ffffffffc020055c <ide_device_size>
}
ffffffffc02040d6:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040d8:	810d                	srl	a0,a0,0x3
ffffffffc02040da:	00012797          	auipc	a5,0x12
ffffffffc02040de:	4aa7bb23          	sd	a0,1206(a5) # ffffffffc0216590 <max_swap_offset>
}
ffffffffc02040e2:	0141                	add	sp,sp,16
ffffffffc02040e4:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc02040e6:	00003617          	auipc	a2,0x3
ffffffffc02040ea:	a0260613          	add	a2,a2,-1534 # ffffffffc0206ae8 <etext+0x1bae>
ffffffffc02040ee:	45b5                	li	a1,13
ffffffffc02040f0:	00003517          	auipc	a0,0x3
ffffffffc02040f4:	a1850513          	add	a0,a0,-1512 # ffffffffc0206b08 <etext+0x1bce>
ffffffffc02040f8:	b3afc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02040fc <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc02040fc:	1141                	add	sp,sp,-16
ffffffffc02040fe:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204100:	00855793          	srl	a5,a0,0x8
ffffffffc0204104:	cbb1                	beqz	a5,ffffffffc0204158 <swapfs_read+0x5c>
ffffffffc0204106:	00012717          	auipc	a4,0x12
ffffffffc020410a:	48a73703          	ld	a4,1162(a4) # ffffffffc0216590 <max_swap_offset>
ffffffffc020410e:	04e7f563          	bgeu	a5,a4,ffffffffc0204158 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204112:	00012717          	auipc	a4,0x12
ffffffffc0204116:	46e73703          	ld	a4,1134(a4) # ffffffffc0216580 <pages>
ffffffffc020411a:	8d99                	sub	a1,a1,a4
ffffffffc020411c:	4065d613          	sra	a2,a1,0x6
ffffffffc0204120:	00003717          	auipc	a4,0x3
ffffffffc0204124:	f0873703          	ld	a4,-248(a4) # ffffffffc0207028 <nbase>
ffffffffc0204128:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc020412a:	00c61713          	sll	a4,a2,0xc
ffffffffc020412e:	8331                	srl	a4,a4,0xc
ffffffffc0204130:	00012697          	auipc	a3,0x12
ffffffffc0204134:	4486b683          	ld	a3,1096(a3) # ffffffffc0216578 <npage>
ffffffffc0204138:	0037959b          	sllw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc020413c:	0632                	sll	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020413e:	02d77963          	bgeu	a4,a3,ffffffffc0204170 <swapfs_read+0x74>
}
ffffffffc0204142:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204144:	00012797          	auipc	a5,0x12
ffffffffc0204148:	42c7b783          	ld	a5,1068(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc020414c:	46a1                	li	a3,8
ffffffffc020414e:	963e                	add	a2,a2,a5
ffffffffc0204150:	4505                	li	a0,1
}
ffffffffc0204152:	0141                	add	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204154:	c0efc06f          	j	ffffffffc0200562 <ide_read_secs>
ffffffffc0204158:	86aa                	mv	a3,a0
ffffffffc020415a:	00003617          	auipc	a2,0x3
ffffffffc020415e:	9c660613          	add	a2,a2,-1594 # ffffffffc0206b20 <etext+0x1be6>
ffffffffc0204162:	45d1                	li	a1,20
ffffffffc0204164:	00003517          	auipc	a0,0x3
ffffffffc0204168:	9a450513          	add	a0,a0,-1628 # ffffffffc0206b08 <etext+0x1bce>
ffffffffc020416c:	ac6fc0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc0204170:	86b2                	mv	a3,a2
ffffffffc0204172:	06900593          	li	a1,105
ffffffffc0204176:	00002617          	auipc	a2,0x2
ffffffffc020417a:	a6a60613          	add	a2,a2,-1430 # ffffffffc0205be0 <etext+0xca6>
ffffffffc020417e:	00002517          	auipc	a0,0x2
ffffffffc0204182:	a8a50513          	add	a0,a0,-1398 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0204186:	aacfc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020418a <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc020418a:	1141                	add	sp,sp,-16
ffffffffc020418c:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020418e:	00855793          	srl	a5,a0,0x8
ffffffffc0204192:	cbb1                	beqz	a5,ffffffffc02041e6 <swapfs_write+0x5c>
ffffffffc0204194:	00012717          	auipc	a4,0x12
ffffffffc0204198:	3fc73703          	ld	a4,1020(a4) # ffffffffc0216590 <max_swap_offset>
ffffffffc020419c:	04e7f563          	bgeu	a5,a4,ffffffffc02041e6 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc02041a0:	00012717          	auipc	a4,0x12
ffffffffc02041a4:	3e073703          	ld	a4,992(a4) # ffffffffc0216580 <pages>
ffffffffc02041a8:	8d99                	sub	a1,a1,a4
ffffffffc02041aa:	4065d613          	sra	a2,a1,0x6
ffffffffc02041ae:	00003717          	auipc	a4,0x3
ffffffffc02041b2:	e7a73703          	ld	a4,-390(a4) # ffffffffc0207028 <nbase>
ffffffffc02041b6:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc02041b8:	00c61713          	sll	a4,a2,0xc
ffffffffc02041bc:	8331                	srl	a4,a4,0xc
ffffffffc02041be:	00012697          	auipc	a3,0x12
ffffffffc02041c2:	3ba6b683          	ld	a3,954(a3) # ffffffffc0216578 <npage>
ffffffffc02041c6:	0037959b          	sllw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041ca:	0632                	sll	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02041cc:	02d77963          	bgeu	a4,a3,ffffffffc02041fe <swapfs_write+0x74>
}
ffffffffc02041d0:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041d2:	00012797          	auipc	a5,0x12
ffffffffc02041d6:	39e7b783          	ld	a5,926(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc02041da:	46a1                	li	a3,8
ffffffffc02041dc:	963e                	add	a2,a2,a5
ffffffffc02041de:	4505                	li	a0,1
}
ffffffffc02041e0:	0141                	add	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041e2:	ba4fc06f          	j	ffffffffc0200586 <ide_write_secs>
ffffffffc02041e6:	86aa                	mv	a3,a0
ffffffffc02041e8:	00003617          	auipc	a2,0x3
ffffffffc02041ec:	93860613          	add	a2,a2,-1736 # ffffffffc0206b20 <etext+0x1be6>
ffffffffc02041f0:	45e5                	li	a1,25
ffffffffc02041f2:	00003517          	auipc	a0,0x3
ffffffffc02041f6:	91650513          	add	a0,a0,-1770 # ffffffffc0206b08 <etext+0x1bce>
ffffffffc02041fa:	a38fc0ef          	jal	ffffffffc0200432 <__panic>
ffffffffc02041fe:	86b2                	mv	a3,a2
ffffffffc0204200:	06900593          	li	a1,105
ffffffffc0204204:	00002617          	auipc	a2,0x2
ffffffffc0204208:	9dc60613          	add	a2,a2,-1572 # ffffffffc0205be0 <etext+0xca6>
ffffffffc020420c:	00002517          	auipc	a0,0x2
ffffffffc0204210:	9fc50513          	add	a0,a0,-1540 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0204214:	a1efc0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0204218 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204218:	8526                	mv	a0,s1
	jalr s0
ffffffffc020421a:	9402                	jalr	s0

	jal do_exit
ffffffffc020421c:	48a000ef          	jal	ffffffffc02046a6 <do_exit>

ffffffffc0204220 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204220:	1141                	add	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204222:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc0204226:	e022                	sd	s0,0(sp)
ffffffffc0204228:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020422a:	dfefd0ef          	jal	ffffffffc0201828 <kmalloc>
ffffffffc020422e:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204230:	c521                	beqz	a0,ffffffffc0204278 <alloc_proc+0x58>
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
        proc->state = PROC_UNINIT; 
ffffffffc0204232:	57fd                	li	a5,-1
ffffffffc0204234:	1782                	sll	a5,a5,0x20
ffffffffc0204236:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0204238:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc020423c:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204240:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204244:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204248:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc020424c:	07000613          	li	a2,112
ffffffffc0204250:	4581                	li	a1,0
ffffffffc0204252:	03050513          	add	a0,a0,48
ffffffffc0204256:	497000ef          	jal	ffffffffc0204eec <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
ffffffffc020425a:	00012797          	auipc	a5,0x12
ffffffffc020425e:	3067b783          	ld	a5,774(a5) # ffffffffc0216560 <boot_cr3>
        proc->tf = NULL;
ffffffffc0204262:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3;
ffffffffc0204266:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204268:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc020426c:	463d                	li	a2,15
ffffffffc020426e:	4581                	li	a1,0
ffffffffc0204270:	0b440513          	add	a0,s0,180
ffffffffc0204274:	479000ef          	jal	ffffffffc0204eec <memset>
    }
    return proc;
}
ffffffffc0204278:	60a2                	ld	ra,8(sp)
ffffffffc020427a:	8522                	mv	a0,s0
ffffffffc020427c:	6402                	ld	s0,0(sp)
ffffffffc020427e:	0141                	add	sp,sp,16
ffffffffc0204280:	8082                	ret

ffffffffc0204282 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204282:	00012797          	auipc	a5,0x12
ffffffffc0204286:	3367b783          	ld	a5,822(a5) # ffffffffc02165b8 <current>
ffffffffc020428a:	73c8                	ld	a0,160(a5)
ffffffffc020428c:	8d1fc06f          	j	ffffffffc0200b5c <forkrets>

ffffffffc0204290 <init_main>:
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc0204290:	1101                	add	sp,sp,-32
ffffffffc0204292:	e822                	sd	s0,16(sp)
ffffffffc0204294:	e426                	sd	s1,8(sp)
ffffffffc0204296:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204298:	00012497          	auipc	s1,0x12
ffffffffc020429c:	3204b483          	ld	s1,800(s1) # ffffffffc02165b8 <current>
    memset(name, 0, sizeof(name));
ffffffffc02042a0:	4641                	li	a2,16
ffffffffc02042a2:	4581                	li	a1,0
ffffffffc02042a4:	0000e517          	auipc	a0,0xe
ffffffffc02042a8:	27450513          	add	a0,a0,628 # ffffffffc0212518 <name.2>
init_main(void *arg) {
ffffffffc02042ac:	ec06                	sd	ra,24(sp)
ffffffffc02042ae:	e04a                	sd	s2,0(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02042b0:	0044a903          	lw	s2,4(s1)
    memset(name, 0, sizeof(name));
ffffffffc02042b4:	439000ef          	jal	ffffffffc0204eec <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc02042b8:	0b448593          	add	a1,s1,180
ffffffffc02042bc:	463d                	li	a2,15
ffffffffc02042be:	0000e517          	auipc	a0,0xe
ffffffffc02042c2:	25a50513          	add	a0,a0,602 # ffffffffc0212518 <name.2>
ffffffffc02042c6:	439000ef          	jal	ffffffffc0204efe <memcpy>
ffffffffc02042ca:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02042cc:	85ca                	mv	a1,s2
ffffffffc02042ce:	00003517          	auipc	a0,0x3
ffffffffc02042d2:	87250513          	add	a0,a0,-1934 # ffffffffc0206b40 <etext+0x1c06>
ffffffffc02042d6:	eabfb0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02042da:	85a2                	mv	a1,s0
ffffffffc02042dc:	00003517          	auipc	a0,0x3
ffffffffc02042e0:	88c50513          	add	a0,a0,-1908 # ffffffffc0206b68 <etext+0x1c2e>
ffffffffc02042e4:	e9dfb0ef          	jal	ffffffffc0200180 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02042e8:	00003517          	auipc	a0,0x3
ffffffffc02042ec:	89050513          	add	a0,a0,-1904 # ffffffffc0206b78 <etext+0x1c3e>
ffffffffc02042f0:	e91fb0ef          	jal	ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc02042f4:	60e2                	ld	ra,24(sp)
ffffffffc02042f6:	6442                	ld	s0,16(sp)
ffffffffc02042f8:	64a2                	ld	s1,8(sp)
ffffffffc02042fa:	6902                	ld	s2,0(sp)
ffffffffc02042fc:	4501                	li	a0,0
ffffffffc02042fe:	6105                	add	sp,sp,32
ffffffffc0204300:	8082                	ret

ffffffffc0204302 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204302:	7179                	add	sp,sp,-48
ffffffffc0204304:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204306:	00012917          	auipc	s2,0x12
ffffffffc020430a:	2b290913          	add	s2,s2,690 # ffffffffc02165b8 <current>
proc_run(struct proc_struct *proc) {
ffffffffc020430e:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204310:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204314:	f406                	sd	ra,40(sp)
    if (proc != current) {
ffffffffc0204316:	02a48b63          	beq	s1,a0,ffffffffc020434c <proc_run+0x4a>
ffffffffc020431a:	e84e                	sd	s3,16(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020431c:	100027f3          	csrr	a5,sstatus
ffffffffc0204320:	8b89                	and	a5,a5,2
    return 0;
ffffffffc0204322:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204324:	e3a1                	bnez	a5,ffffffffc0204364 <proc_run+0x62>
        lcr3(next->cr3);
ffffffffc0204326:	755c                	ld	a5,168(a0)

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204328:	80000737          	lui	a4,0x80000
        current = proc;
ffffffffc020432c:	00a93023          	sd	a0,0(s2)
ffffffffc0204330:	00c7d79b          	srlw	a5,a5,0xc
ffffffffc0204334:	8fd9                	or	a5,a5,a4
ffffffffc0204336:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(next->context));
ffffffffc020433a:	03050593          	add	a1,a0,48
ffffffffc020433e:	03048513          	add	a0,s1,48
ffffffffc0204342:	5e6000ef          	jal	ffffffffc0204928 <switch_to>
    if (flag) {
ffffffffc0204346:	00099863          	bnez	s3,ffffffffc0204356 <proc_run+0x54>
ffffffffc020434a:	69c2                	ld	s3,16(sp)
}
ffffffffc020434c:	70a2                	ld	ra,40(sp)
ffffffffc020434e:	7482                	ld	s1,32(sp)
ffffffffc0204350:	6962                	ld	s2,24(sp)
ffffffffc0204352:	6145                	add	sp,sp,48
ffffffffc0204354:	8082                	ret
        intr_enable();
ffffffffc0204356:	69c2                	ld	s3,16(sp)
ffffffffc0204358:	70a2                	ld	ra,40(sp)
ffffffffc020435a:	7482                	ld	s1,32(sp)
ffffffffc020435c:	6962                	ld	s2,24(sp)
ffffffffc020435e:	6145                	add	sp,sp,48
ffffffffc0204360:	a4afc06f          	j	ffffffffc02005aa <intr_enable>
ffffffffc0204364:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204366:	a4afc0ef          	jal	ffffffffc02005b0 <intr_disable>
        return 1;
ffffffffc020436a:	6522                	ld	a0,8(sp)
ffffffffc020436c:	4985                	li	s3,1
ffffffffc020436e:	bf65                	j	ffffffffc0204326 <proc_run+0x24>

ffffffffc0204370 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204370:	7179                	add	sp,sp,-48
ffffffffc0204372:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204374:	00012497          	auipc	s1,0x12
ffffffffc0204378:	23c48493          	add	s1,s1,572 # ffffffffc02165b0 <nr_process>
ffffffffc020437c:	4098                	lw	a4,0(s1)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc020437e:	f406                	sd	ra,40(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204380:	6785                	lui	a5,0x1
ffffffffc0204382:	26f75463          	bge	a4,a5,ffffffffc02045ea <do_fork+0x27a>
ffffffffc0204386:	f022                	sd	s0,32(sp)
ffffffffc0204388:	e84a                	sd	s2,16(sp)
ffffffffc020438a:	e44e                	sd	s3,8(sp)
ffffffffc020438c:	892e                	mv	s2,a1
ffffffffc020438e:	8432                	mv	s0,a2
    proc = alloc_proc();    // 调用alloc_proc函数分配一个proc_struct结构体
ffffffffc0204390:	e91ff0ef          	jal	ffffffffc0204220 <alloc_proc>
ffffffffc0204394:	89aa                	mv	s3,a0
    if (proc == NULL) { // 如果分配失败，返回错误码
ffffffffc0204396:	24050563          	beqz	a0,ffffffffc02045e0 <do_fork+0x270>
ffffffffc020439a:	e052                	sd	s4,0(sp)
    proc->parent = current; // 设置父进程为当前进程
ffffffffc020439c:	00012a17          	auipc	s4,0x12
ffffffffc02043a0:	21ca0a13          	add	s4,s4,540 # ffffffffc02165b8 <current>
ffffffffc02043a4:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02043a8:	4509                	li	a0,2
    proc->parent = current; // 设置父进程为当前进程
ffffffffc02043aa:	02f9b023          	sd	a5,32(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02043ae:	e52fd0ef          	jal	ffffffffc0201a00 <alloc_pages>
    if (page != NULL) {
ffffffffc02043b2:	1e050263          	beqz	a0,ffffffffc0204596 <do_fork+0x226>
    return page - pages + nbase;
ffffffffc02043b6:	00012797          	auipc	a5,0x12
ffffffffc02043ba:	1ca7b783          	ld	a5,458(a5) # ffffffffc0216580 <pages>
ffffffffc02043be:	40f506b3          	sub	a3,a0,a5
ffffffffc02043c2:	8699                	sra	a3,a3,0x6
ffffffffc02043c4:	00003797          	auipc	a5,0x3
ffffffffc02043c8:	c647b783          	ld	a5,-924(a5) # ffffffffc0207028 <nbase>
ffffffffc02043cc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02043ce:	00c69793          	sll	a5,a3,0xc
ffffffffc02043d2:	83b1                	srl	a5,a5,0xc
ffffffffc02043d4:	00012717          	auipc	a4,0x12
ffffffffc02043d8:	1a473703          	ld	a4,420(a4) # ffffffffc0216578 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02043dc:	06b2                	sll	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02043de:	22e7f863          	bgeu	a5,a4,ffffffffc020460e <do_fork+0x29e>
    assert(current->mm == NULL);
ffffffffc02043e2:	000a3783          	ld	a5,0(s4)
ffffffffc02043e6:	00012717          	auipc	a4,0x12
ffffffffc02043ea:	18a73703          	ld	a4,394(a4) # ffffffffc0216570 <va_pa_offset>
ffffffffc02043ee:	96ba                	add	a3,a3,a4
ffffffffc02043f0:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02043f2:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02043f6:	1e079c63          	bnez	a5,ffffffffc02045ee <do_fork+0x27e>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02043fa:	6789                	lui	a5,0x2
ffffffffc02043fc:	ee078793          	add	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0204400:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204402:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204404:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc0204408:	87b6                	mv	a5,a3
ffffffffc020440a:	12040893          	add	a7,s0,288
ffffffffc020440e:	00063803          	ld	a6,0(a2)
ffffffffc0204412:	6608                	ld	a0,8(a2)
ffffffffc0204414:	6a0c                	ld	a1,16(a2)
ffffffffc0204416:	6e18                	ld	a4,24(a2)
ffffffffc0204418:	0107b023          	sd	a6,0(a5)
ffffffffc020441c:	e788                	sd	a0,8(a5)
ffffffffc020441e:	eb8c                	sd	a1,16(a5)
ffffffffc0204420:	ef98                	sd	a4,24(a5)
ffffffffc0204422:	02060613          	add	a2,a2,32
ffffffffc0204426:	02078793          	add	a5,a5,32
ffffffffc020442a:	ff1612e3          	bne	a2,a7,ffffffffc020440e <do_fork+0x9e>
    proc->tf->gpr.a0 = 0;
ffffffffc020442e:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204432:	12090463          	beqz	s2,ffffffffc020455a <do_fork+0x1ea>
ffffffffc0204436:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020443a:	00000797          	auipc	a5,0x0
ffffffffc020443e:	e4878793          	add	a5,a5,-440 # ffffffffc0204282 <forkret>
ffffffffc0204442:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204446:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020444a:	100027f3          	csrr	a5,sstatus
ffffffffc020444e:	8b89                	and	a5,a5,2
    return 0;
ffffffffc0204450:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204452:	12079563          	bnez	a5,ffffffffc020457c <do_fork+0x20c>
    if (++ last_pid >= MAX_PID) {
ffffffffc0204456:	00007817          	auipc	a6,0x7
ffffffffc020445a:	c0680813          	add	a6,a6,-1018 # ffffffffc020b05c <last_pid.1>
ffffffffc020445e:	00082783          	lw	a5,0(a6)
ffffffffc0204462:	6709                	lui	a4,0x2
ffffffffc0204464:	0017851b          	addw	a0,a5,1
ffffffffc0204468:	00a82023          	sw	a0,0(a6)
ffffffffc020446c:	08e55163          	bge	a0,a4,ffffffffc02044ee <do_fork+0x17e>
    if (last_pid >= next_safe) {
ffffffffc0204470:	00007317          	auipc	t1,0x7
ffffffffc0204474:	be830313          	add	t1,t1,-1048 # ffffffffc020b058 <next_safe.0>
ffffffffc0204478:	00032783          	lw	a5,0(t1)
ffffffffc020447c:	00012417          	auipc	s0,0x12
ffffffffc0204480:	0ac40413          	add	s0,s0,172 # ffffffffc0216528 <proc_list>
ffffffffc0204484:	06f55d63          	bge	a0,a5,ffffffffc02044fe <do_fork+0x18e>
    proc->pid = get_pid();  // 为子进程分配pid
ffffffffc0204488:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020448c:	45a9                	li	a1,10
ffffffffc020448e:	2501                	sext.w	a0,a0
ffffffffc0204490:	5c8000ef          	jal	ffffffffc0204a58 <hash32>
ffffffffc0204494:	02051793          	sll	a5,a0,0x20
ffffffffc0204498:	01c7d513          	srl	a0,a5,0x1c
ffffffffc020449c:	0000e797          	auipc	a5,0xe
ffffffffc02044a0:	08c78793          	add	a5,a5,140 # ffffffffc0212528 <hash_list>
ffffffffc02044a4:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02044a6:	6510                	ld	a2,8(a0)
ffffffffc02044a8:	0d898793          	add	a5,s3,216
ffffffffc02044ac:	6414                	ld	a3,8(s0)
    nr_process++;
ffffffffc02044ae:	4098                	lw	a4,0(s1)
    prev->next = next->prev = elm;
ffffffffc02044b0:	e21c                	sd	a5,0(a2)
ffffffffc02044b2:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02044b4:	0ec9b023          	sd	a2,224(s3)
    list_add(&proc_list, &(proc->list_link));   // 将子进程添加到proc_list中
ffffffffc02044b8:	0c898793          	add	a5,s3,200
    elm->prev = prev;
ffffffffc02044bc:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc02044c0:	e29c                	sd	a5,0(a3)
    nr_process++;
ffffffffc02044c2:	2705                	addw	a4,a4,1 # 2001 <kern_entry-0xffffffffc01fdfff>
ffffffffc02044c4:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02044c6:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc02044ca:	0c89b423          	sd	s0,200(s3)
ffffffffc02044ce:	c098                	sw	a4,0(s1)
    if (flag) {
ffffffffc02044d0:	0a091a63          	bnez	s2,ffffffffc0204584 <do_fork+0x214>
    wakeup_proc(proc);  // 唤醒子进程
ffffffffc02044d4:	854e                	mv	a0,s3
ffffffffc02044d6:	4bc000ef          	jal	ffffffffc0204992 <wakeup_proc>
    ret = proc->pid;    // 设置返回值为子进程的pid
ffffffffc02044da:	0049a503          	lw	a0,4(s3)
ffffffffc02044de:	7402                	ld	s0,32(sp)
ffffffffc02044e0:	6942                	ld	s2,16(sp)
ffffffffc02044e2:	69a2                	ld	s3,8(sp)
ffffffffc02044e4:	6a02                	ld	s4,0(sp)
}
ffffffffc02044e6:	70a2                	ld	ra,40(sp)
ffffffffc02044e8:	64e2                	ld	s1,24(sp)
ffffffffc02044ea:	6145                	add	sp,sp,48
ffffffffc02044ec:	8082                	ret
        last_pid = 1;
ffffffffc02044ee:	4785                	li	a5,1
ffffffffc02044f0:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02044f4:	4505                	li	a0,1
ffffffffc02044f6:	00007317          	auipc	t1,0x7
ffffffffc02044fa:	b6230313          	add	t1,t1,-1182 # ffffffffc020b058 <next_safe.0>
    return listelm->next;
ffffffffc02044fe:	00012417          	auipc	s0,0x12
ffffffffc0204502:	02a40413          	add	s0,s0,42 # ffffffffc0216528 <proc_list>
ffffffffc0204506:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc020450a:	6789                	lui	a5,0x2
ffffffffc020450c:	00f32023          	sw	a5,0(t1)
ffffffffc0204510:	86aa                	mv	a3,a0
ffffffffc0204512:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc0204514:	028e0e63          	beq	t3,s0,ffffffffc0204550 <do_fork+0x1e0>
ffffffffc0204518:	88ae                	mv	a7,a1
ffffffffc020451a:	87f2                	mv	a5,t3
ffffffffc020451c:	6609                	lui	a2,0x2
ffffffffc020451e:	a811                	j	ffffffffc0204532 <do_fork+0x1c2>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0204520:	00e6d663          	bge	a3,a4,ffffffffc020452c <do_fork+0x1bc>
ffffffffc0204524:	00c75463          	bge	a4,a2,ffffffffc020452c <do_fork+0x1bc>
                next_safe = proc->pid;
ffffffffc0204528:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc020452a:	4885                	li	a7,1
ffffffffc020452c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020452e:	00878d63          	beq	a5,s0,ffffffffc0204548 <do_fork+0x1d8>
            if (proc->pid == last_pid) {
ffffffffc0204532:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0204536:	fed715e3          	bne	a4,a3,ffffffffc0204520 <do_fork+0x1b0>
                if (++ last_pid >= next_safe) {
ffffffffc020453a:	2685                	addw	a3,a3,1
ffffffffc020453c:	04c6d763          	bge	a3,a2,ffffffffc020458a <do_fork+0x21a>
ffffffffc0204540:	679c                	ld	a5,8(a5)
ffffffffc0204542:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc0204544:	fe8797e3          	bne	a5,s0,ffffffffc0204532 <do_fork+0x1c2>
ffffffffc0204548:	00088463          	beqz	a7,ffffffffc0204550 <do_fork+0x1e0>
ffffffffc020454c:	00c32023          	sw	a2,0(t1)
ffffffffc0204550:	dd85                	beqz	a1,ffffffffc0204488 <do_fork+0x118>
ffffffffc0204552:	00d82023          	sw	a3,0(a6)
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0204556:	8536                	mv	a0,a3
ffffffffc0204558:	bf05                	j	ffffffffc0204488 <do_fork+0x118>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020455a:	8936                	mv	s2,a3
ffffffffc020455c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204560:	00000797          	auipc	a5,0x0
ffffffffc0204564:	d2278793          	add	a5,a5,-734 # ffffffffc0204282 <forkret>
ffffffffc0204568:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020456c:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204570:	100027f3          	csrr	a5,sstatus
ffffffffc0204574:	8b89                	and	a5,a5,2
    return 0;
ffffffffc0204576:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204578:	ec078fe3          	beqz	a5,ffffffffc0204456 <do_fork+0xe6>
        intr_disable();
ffffffffc020457c:	834fc0ef          	jal	ffffffffc02005b0 <intr_disable>
        return 1;
ffffffffc0204580:	4905                	li	s2,1
ffffffffc0204582:	bdd1                	j	ffffffffc0204456 <do_fork+0xe6>
        intr_enable();
ffffffffc0204584:	826fc0ef          	jal	ffffffffc02005aa <intr_enable>
ffffffffc0204588:	b7b1                	j	ffffffffc02044d4 <do_fork+0x164>
                    if (last_pid >= MAX_PID) {
ffffffffc020458a:	6789                	lui	a5,0x2
ffffffffc020458c:	00f6c363          	blt	a3,a5,ffffffffc0204592 <do_fork+0x222>
                        last_pid = 1;
ffffffffc0204590:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204592:	4585                	li	a1,1
ffffffffc0204594:	b741                	j	ffffffffc0204514 <do_fork+0x1a4>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204596:	0109b683          	ld	a3,16(s3)
    return pa2page(PADDR(kva));
ffffffffc020459a:	c02007b7          	lui	a5,0xc0200
ffffffffc020459e:	0af6e063          	bltu	a3,a5,ffffffffc020463e <do_fork+0x2ce>
ffffffffc02045a2:	00012797          	auipc	a5,0x12
ffffffffc02045a6:	fce7b783          	ld	a5,-50(a5) # ffffffffc0216570 <va_pa_offset>
ffffffffc02045aa:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02045ae:	83b1                	srl	a5,a5,0xc
ffffffffc02045b0:	00012717          	auipc	a4,0x12
ffffffffc02045b4:	fc873703          	ld	a4,-56(a4) # ffffffffc0216578 <npage>
ffffffffc02045b8:	06e7f763          	bgeu	a5,a4,ffffffffc0204626 <do_fork+0x2b6>
    return &pages[PPN(pa) - nbase];
ffffffffc02045bc:	00003717          	auipc	a4,0x3
ffffffffc02045c0:	a6c73703          	ld	a4,-1428(a4) # ffffffffc0207028 <nbase>
ffffffffc02045c4:	8f99                	sub	a5,a5,a4
ffffffffc02045c6:	079a                	sll	a5,a5,0x6
ffffffffc02045c8:	00012517          	auipc	a0,0x12
ffffffffc02045cc:	fb853503          	ld	a0,-72(a0) # ffffffffc0216580 <pages>
ffffffffc02045d0:	953e                	add	a0,a0,a5
ffffffffc02045d2:	4589                	li	a1,2
ffffffffc02045d4:	cbcfd0ef          	jal	ffffffffc0201a90 <free_pages>
    kfree(proc);
ffffffffc02045d8:	854e                	mv	a0,s3
ffffffffc02045da:	af8fd0ef          	jal	ffffffffc02018d2 <kfree>
ffffffffc02045de:	6a02                	ld	s4,0(sp)
ffffffffc02045e0:	7402                	ld	s0,32(sp)
ffffffffc02045e2:	6942                	ld	s2,16(sp)
ffffffffc02045e4:	69a2                	ld	s3,8(sp)
    ret = -E_NO_MEM;
ffffffffc02045e6:	5571                	li	a0,-4
ffffffffc02045e8:	bdfd                	j	ffffffffc02044e6 <do_fork+0x176>
    int ret = -E_NO_FREE_PROC;
ffffffffc02045ea:	556d                	li	a0,-5
ffffffffc02045ec:	bded                	j	ffffffffc02044e6 <do_fork+0x176>
    assert(current->mm == NULL);
ffffffffc02045ee:	00002697          	auipc	a3,0x2
ffffffffc02045f2:	5aa68693          	add	a3,a3,1450 # ffffffffc0206b98 <etext+0x1c5e>
ffffffffc02045f6:	00001617          	auipc	a2,0x1
ffffffffc02045fa:	23a60613          	add	a2,a2,570 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02045fe:	10800593          	li	a1,264
ffffffffc0204602:	00002517          	auipc	a0,0x2
ffffffffc0204606:	5ae50513          	add	a0,a0,1454 # ffffffffc0206bb0 <etext+0x1c76>
ffffffffc020460a:	e29fb0ef          	jal	ffffffffc0200432 <__panic>
    return KADDR(page2pa(page));
ffffffffc020460e:	00001617          	auipc	a2,0x1
ffffffffc0204612:	5d260613          	add	a2,a2,1490 # ffffffffc0205be0 <etext+0xca6>
ffffffffc0204616:	06900593          	li	a1,105
ffffffffc020461a:	00001517          	auipc	a0,0x1
ffffffffc020461e:	5ee50513          	add	a0,a0,1518 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0204622:	e11fb0ef          	jal	ffffffffc0200432 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204626:	00001617          	auipc	a2,0x1
ffffffffc020462a:	68a60613          	add	a2,a2,1674 # ffffffffc0205cb0 <etext+0xd76>
ffffffffc020462e:	06200593          	li	a1,98
ffffffffc0204632:	00001517          	auipc	a0,0x1
ffffffffc0204636:	5d650513          	add	a0,a0,1494 # ffffffffc0205c08 <etext+0xcce>
ffffffffc020463a:	df9fb0ef          	jal	ffffffffc0200432 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020463e:	00001617          	auipc	a2,0x1
ffffffffc0204642:	64a60613          	add	a2,a2,1610 # ffffffffc0205c88 <etext+0xd4e>
ffffffffc0204646:	06e00593          	li	a1,110
ffffffffc020464a:	00001517          	auipc	a0,0x1
ffffffffc020464e:	5be50513          	add	a0,a0,1470 # ffffffffc0205c08 <etext+0xcce>
ffffffffc0204652:	de1fb0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc0204656 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0204656:	7129                	add	sp,sp,-320
ffffffffc0204658:	fa22                	sd	s0,304(sp)
ffffffffc020465a:	f626                	sd	s1,296(sp)
ffffffffc020465c:	f24a                	sd	s2,288(sp)
ffffffffc020465e:	84ae                	mv	s1,a1
ffffffffc0204660:	892a                	mv	s2,a0
ffffffffc0204662:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204664:	4581                	li	a1,0
ffffffffc0204666:	12000613          	li	a2,288
ffffffffc020466a:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020466c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020466e:	07f000ef          	jal	ffffffffc0204eec <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204672:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204674:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204676:	100027f3          	csrr	a5,sstatus
ffffffffc020467a:	edd7f793          	and	a5,a5,-291
ffffffffc020467e:	1207e793          	or	a5,a5,288
ffffffffc0204682:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204684:	860a                	mv	a2,sp
ffffffffc0204686:	10046513          	or	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020468a:	00000797          	auipc	a5,0x0
ffffffffc020468e:	b8e78793          	add	a5,a5,-1138 # ffffffffc0204218 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204692:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204694:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204696:	cdbff0ef          	jal	ffffffffc0204370 <do_fork>
}
ffffffffc020469a:	70f2                	ld	ra,312(sp)
ffffffffc020469c:	7452                	ld	s0,304(sp)
ffffffffc020469e:	74b2                	ld	s1,296(sp)
ffffffffc02046a0:	7912                	ld	s2,288(sp)
ffffffffc02046a2:	6131                	add	sp,sp,320
ffffffffc02046a4:	8082                	ret

ffffffffc02046a6 <do_exit>:
do_exit(int error_code) {
ffffffffc02046a6:	1141                	add	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02046a8:	00002617          	auipc	a2,0x2
ffffffffc02046ac:	52060613          	add	a2,a2,1312 # ffffffffc0206bc8 <etext+0x1c8e>
ffffffffc02046b0:	17200593          	li	a1,370
ffffffffc02046b4:	00002517          	auipc	a0,0x2
ffffffffc02046b8:	4fc50513          	add	a0,a0,1276 # ffffffffc0206bb0 <etext+0x1c76>
do_exit(int error_code) {
ffffffffc02046bc:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02046be:	d75fb0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02046c2 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc02046c2:	7179                	add	sp,sp,-48
ffffffffc02046c4:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02046c6:	00012797          	auipc	a5,0x12
ffffffffc02046ca:	e6278793          	add	a5,a5,-414 # ffffffffc0216528 <proc_list>
ffffffffc02046ce:	f406                	sd	ra,40(sp)
ffffffffc02046d0:	f022                	sd	s0,32(sp)
ffffffffc02046d2:	e84a                	sd	s2,16(sp)
ffffffffc02046d4:	e44e                	sd	s3,8(sp)
ffffffffc02046d6:	0000e497          	auipc	s1,0xe
ffffffffc02046da:	e5248493          	add	s1,s1,-430 # ffffffffc0212528 <hash_list>
ffffffffc02046de:	e79c                	sd	a5,8(a5)
ffffffffc02046e0:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc02046e2:	00012717          	auipc	a4,0x12
ffffffffc02046e6:	e4670713          	add	a4,a4,-442 # ffffffffc0216528 <proc_list>
ffffffffc02046ea:	87a6                	mv	a5,s1
ffffffffc02046ec:	e79c                	sd	a5,8(a5)
ffffffffc02046ee:	e39c                	sd	a5,0(a5)
ffffffffc02046f0:	07c1                	add	a5,a5,16
ffffffffc02046f2:	fee79de3          	bne	a5,a4,ffffffffc02046ec <proc_init+0x2a>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc02046f6:	b2bff0ef          	jal	ffffffffc0204220 <alloc_proc>
ffffffffc02046fa:	00012917          	auipc	s2,0x12
ffffffffc02046fe:	ece90913          	add	s2,s2,-306 # ffffffffc02165c8 <idleproc>
ffffffffc0204702:	00a93023          	sd	a0,0(s2)
ffffffffc0204706:	18050c63          	beqz	a0,ffffffffc020489e <proc_init+0x1dc>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc020470a:	07000513          	li	a0,112
ffffffffc020470e:	91afd0ef          	jal	ffffffffc0201828 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204712:	07000613          	li	a2,112
ffffffffc0204716:	4581                	li	a1,0
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204718:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020471a:	7d2000ef          	jal	ffffffffc0204eec <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020471e:	00093503          	ld	a0,0(s2)
ffffffffc0204722:	85a2                	mv	a1,s0
ffffffffc0204724:	07000613          	li	a2,112
ffffffffc0204728:	03050513          	add	a0,a0,48
ffffffffc020472c:	7ea000ef          	jal	ffffffffc0204f16 <memcmp>
ffffffffc0204730:	89aa                	mv	s3,a0

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc0204732:	453d                	li	a0,15
ffffffffc0204734:	8f4fd0ef          	jal	ffffffffc0201828 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204738:	463d                	li	a2,15
ffffffffc020473a:	4581                	li	a1,0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc020473c:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020473e:	7ae000ef          	jal	ffffffffc0204eec <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0204742:	00093503          	ld	a0,0(s2)
ffffffffc0204746:	463d                	li	a2,15
ffffffffc0204748:	85a2                	mv	a1,s0
ffffffffc020474a:	0b450513          	add	a0,a0,180
ffffffffc020474e:	7c8000ef          	jal	ffffffffc0204f16 <memcmp>

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc0204752:	00093783          	ld	a5,0(s2)
ffffffffc0204756:	00012717          	auipc	a4,0x12
ffffffffc020475a:	e0a73703          	ld	a4,-502(a4) # ffffffffc0216560 <boot_cr3>
ffffffffc020475e:	77d4                	ld	a3,168(a5)
ffffffffc0204760:	0ee68563          	beq	a3,a4,ffffffffc020484a <proc_init+0x188>
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204764:	4709                	li	a4,2
ffffffffc0204766:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204768:	00004717          	auipc	a4,0x4
ffffffffc020476c:	89870713          	add	a4,a4,-1896 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204770:	0b478413          	add	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204774:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0204776:	4705                	li	a4,1
ffffffffc0204778:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020477a:	4641                	li	a2,16
ffffffffc020477c:	4581                	li	a1,0
ffffffffc020477e:	8522                	mv	a0,s0
ffffffffc0204780:	76c000ef          	jal	ffffffffc0204eec <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204784:	463d                	li	a2,15
ffffffffc0204786:	00002597          	auipc	a1,0x2
ffffffffc020478a:	48a58593          	add	a1,a1,1162 # ffffffffc0206c10 <etext+0x1cd6>
ffffffffc020478e:	8522                	mv	a0,s0
ffffffffc0204790:	76e000ef          	jal	ffffffffc0204efe <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc0204794:	00012717          	auipc	a4,0x12
ffffffffc0204798:	e1c70713          	add	a4,a4,-484 # ffffffffc02165b0 <nr_process>
ffffffffc020479c:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc020479e:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047a2:	4601                	li	a2,0
    nr_process ++;
ffffffffc02047a4:	2785                	addw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047a6:	00002597          	auipc	a1,0x2
ffffffffc02047aa:	47258593          	add	a1,a1,1138 # ffffffffc0206c18 <etext+0x1cde>
ffffffffc02047ae:	00000517          	auipc	a0,0x0
ffffffffc02047b2:	ae250513          	add	a0,a0,-1310 # ffffffffc0204290 <init_main>
    nr_process ++;
ffffffffc02047b6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02047b8:	00012797          	auipc	a5,0x12
ffffffffc02047bc:	e0d7b023          	sd	a3,-512(a5) # ffffffffc02165b8 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02047c0:	e97ff0ef          	jal	ffffffffc0204656 <kernel_thread>
ffffffffc02047c4:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc02047c6:	0ea05863          	blez	a0,ffffffffc02048b6 <proc_init+0x1f4>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02047ca:	6789                	lui	a5,0x2
ffffffffc02047cc:	fff5071b          	addw	a4,a0,-1
ffffffffc02047d0:	17f9                	add	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc02047d2:	2501                	sext.w	a0,a0
ffffffffc02047d4:	02e7e463          	bltu	a5,a4,ffffffffc02047fc <proc_init+0x13a>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02047d8:	45a9                	li	a1,10
ffffffffc02047da:	27e000ef          	jal	ffffffffc0204a58 <hash32>
ffffffffc02047de:	02051713          	sll	a4,a0,0x20
ffffffffc02047e2:	01c75793          	srl	a5,a4,0x1c
ffffffffc02047e6:	00f486b3          	add	a3,s1,a5
ffffffffc02047ea:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc02047ec:	a029                	j	ffffffffc02047f6 <proc_init+0x134>
            if (proc->pid == pid) {
ffffffffc02047ee:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02047f2:	0a870363          	beq	a4,s0,ffffffffc0204898 <proc_init+0x1d6>
    return listelm->next;
ffffffffc02047f6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02047f8:	fef69be3          	bne	a3,a5,ffffffffc02047ee <proc_init+0x12c>
    return NULL;
ffffffffc02047fc:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02047fe:	0b478493          	add	s1,a5,180
ffffffffc0204802:	4641                	li	a2,16
ffffffffc0204804:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204806:	00012417          	auipc	s0,0x12
ffffffffc020480a:	dba40413          	add	s0,s0,-582 # ffffffffc02165c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020480e:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204810:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204812:	6da000ef          	jal	ffffffffc0204eec <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204816:	463d                	li	a2,15
ffffffffc0204818:	00002597          	auipc	a1,0x2
ffffffffc020481c:	43058593          	add	a1,a1,1072 # ffffffffc0206c48 <etext+0x1d0e>
ffffffffc0204820:	8526                	mv	a0,s1
ffffffffc0204822:	6dc000ef          	jal	ffffffffc0204efe <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204826:	00093783          	ld	a5,0(s2)
ffffffffc020482a:	c3f1                	beqz	a5,ffffffffc02048ee <proc_init+0x22c>
ffffffffc020482c:	43dc                	lw	a5,4(a5)
ffffffffc020482e:	e3e1                	bnez	a5,ffffffffc02048ee <proc_init+0x22c>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204830:	601c                	ld	a5,0(s0)
ffffffffc0204832:	cfd1                	beqz	a5,ffffffffc02048ce <proc_init+0x20c>
ffffffffc0204834:	43d8                	lw	a4,4(a5)
ffffffffc0204836:	4785                	li	a5,1
ffffffffc0204838:	08f71b63          	bne	a4,a5,ffffffffc02048ce <proc_init+0x20c>
}
ffffffffc020483c:	70a2                	ld	ra,40(sp)
ffffffffc020483e:	7402                	ld	s0,32(sp)
ffffffffc0204840:	64e2                	ld	s1,24(sp)
ffffffffc0204842:	6942                	ld	s2,16(sp)
ffffffffc0204844:	69a2                	ld	s3,8(sp)
ffffffffc0204846:	6145                	add	sp,sp,48
ffffffffc0204848:	8082                	ret
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc020484a:	73d8                	ld	a4,160(a5)
ffffffffc020484c:	ff01                	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
ffffffffc020484e:	f0099be3          	bnez	s3,ffffffffc0204764 <proc_init+0xa2>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc0204852:	6394                	ld	a3,0(a5)
ffffffffc0204854:	577d                	li	a4,-1
ffffffffc0204856:	1702                	sll	a4,a4,0x20
ffffffffc0204858:	f0e696e3          	bne	a3,a4,ffffffffc0204764 <proc_init+0xa2>
ffffffffc020485c:	4798                	lw	a4,8(a5)
ffffffffc020485e:	f00713e3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc0204862:	6b98                	ld	a4,16(a5)
ffffffffc0204864:	f00710e3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
ffffffffc0204868:	4f98                	lw	a4,24(a5)
ffffffffc020486a:	ee071de3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
ffffffffc020486e:	7398                	ld	a4,32(a5)
ffffffffc0204870:	ee071ae3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
ffffffffc0204874:	7798                	ld	a4,40(a5)
ffffffffc0204876:	ee0717e3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
ffffffffc020487a:	0b07a703          	lw	a4,176(a5)
ffffffffc020487e:	8f49                	or	a4,a4,a0
ffffffffc0204880:	2701                	sext.w	a4,a4
ffffffffc0204882:	ee0711e3          	bnez	a4,ffffffffc0204764 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0204886:	00002517          	auipc	a0,0x2
ffffffffc020488a:	37250513          	add	a0,a0,882 # ffffffffc0206bf8 <etext+0x1cbe>
ffffffffc020488e:	8f3fb0ef          	jal	ffffffffc0200180 <cprintf>
    idleproc->pid = 0;
ffffffffc0204892:	00093783          	ld	a5,0(s2)
ffffffffc0204896:	b5f9                	j	ffffffffc0204764 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204898:	f2878793          	add	a5,a5,-216
ffffffffc020489c:	b78d                	j	ffffffffc02047fe <proc_init+0x13c>
        panic("cannot alloc idleproc.\n");
ffffffffc020489e:	00002617          	auipc	a2,0x2
ffffffffc02048a2:	34260613          	add	a2,a2,834 # ffffffffc0206be0 <etext+0x1ca6>
ffffffffc02048a6:	18a00593          	li	a1,394
ffffffffc02048aa:	00002517          	auipc	a0,0x2
ffffffffc02048ae:	30650513          	add	a0,a0,774 # ffffffffc0206bb0 <etext+0x1c76>
ffffffffc02048b2:	b81fb0ef          	jal	ffffffffc0200432 <__panic>
        panic("create init_main failed.\n");
ffffffffc02048b6:	00002617          	auipc	a2,0x2
ffffffffc02048ba:	37260613          	add	a2,a2,882 # ffffffffc0206c28 <etext+0x1cee>
ffffffffc02048be:	1aa00593          	li	a1,426
ffffffffc02048c2:	00002517          	auipc	a0,0x2
ffffffffc02048c6:	2ee50513          	add	a0,a0,750 # ffffffffc0206bb0 <etext+0x1c76>
ffffffffc02048ca:	b69fb0ef          	jal	ffffffffc0200432 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02048ce:	00002697          	auipc	a3,0x2
ffffffffc02048d2:	3aa68693          	add	a3,a3,938 # ffffffffc0206c78 <etext+0x1d3e>
ffffffffc02048d6:	00001617          	auipc	a2,0x1
ffffffffc02048da:	f5a60613          	add	a2,a2,-166 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02048de:	1b100593          	li	a1,433
ffffffffc02048e2:	00002517          	auipc	a0,0x2
ffffffffc02048e6:	2ce50513          	add	a0,a0,718 # ffffffffc0206bb0 <etext+0x1c76>
ffffffffc02048ea:	b49fb0ef          	jal	ffffffffc0200432 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02048ee:	00002697          	auipc	a3,0x2
ffffffffc02048f2:	36268693          	add	a3,a3,866 # ffffffffc0206c50 <etext+0x1d16>
ffffffffc02048f6:	00001617          	auipc	a2,0x1
ffffffffc02048fa:	f3a60613          	add	a2,a2,-198 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02048fe:	1b000593          	li	a1,432
ffffffffc0204902:	00002517          	auipc	a0,0x2
ffffffffc0204906:	2ae50513          	add	a0,a0,686 # ffffffffc0206bb0 <etext+0x1c76>
ffffffffc020490a:	b29fb0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc020490e <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc020490e:	1141                	add	sp,sp,-16
ffffffffc0204910:	e022                	sd	s0,0(sp)
ffffffffc0204912:	e406                	sd	ra,8(sp)
ffffffffc0204914:	00012417          	auipc	s0,0x12
ffffffffc0204918:	ca440413          	add	s0,s0,-860 # ffffffffc02165b8 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc020491c:	6018                	ld	a4,0(s0)
ffffffffc020491e:	4f1c                	lw	a5,24(a4)
ffffffffc0204920:	dffd                	beqz	a5,ffffffffc020491e <cpu_idle+0x10>
            schedule();
ffffffffc0204922:	0a2000ef          	jal	ffffffffc02049c4 <schedule>
ffffffffc0204926:	bfdd                	j	ffffffffc020491c <cpu_idle+0xe>

ffffffffc0204928 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204928:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020492c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204930:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204932:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204934:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204938:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020493c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204940:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204944:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204948:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020494c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204950:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204954:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204958:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020495c:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204960:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204964:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204966:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204968:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020496c:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204970:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204974:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204978:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020497c:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204980:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204984:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204988:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020498c:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204990:	8082                	ret

ffffffffc0204992 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0204992:	411c                	lw	a5,0(a0)
ffffffffc0204994:	4705                	li	a4,1
ffffffffc0204996:	37f9                	addw	a5,a5,-2
ffffffffc0204998:	00f77563          	bgeu	a4,a5,ffffffffc02049a2 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc020499c:	4789                	li	a5,2
ffffffffc020499e:	c11c                	sw	a5,0(a0)
ffffffffc02049a0:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049a2:	1141                	add	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049a4:	00002697          	auipc	a3,0x2
ffffffffc02049a8:	2fc68693          	add	a3,a3,764 # ffffffffc0206ca0 <etext+0x1d66>
ffffffffc02049ac:	00001617          	auipc	a2,0x1
ffffffffc02049b0:	e8460613          	add	a2,a2,-380 # ffffffffc0205830 <etext+0x8f6>
ffffffffc02049b4:	45a5                	li	a1,9
ffffffffc02049b6:	00002517          	auipc	a0,0x2
ffffffffc02049ba:	32a50513          	add	a0,a0,810 # ffffffffc0206ce0 <etext+0x1da6>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049be:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049c0:	a73fb0ef          	jal	ffffffffc0200432 <__panic>

ffffffffc02049c4 <schedule>:
}

void
schedule(void) {
ffffffffc02049c4:	1141                	add	sp,sp,-16
ffffffffc02049c6:	e406                	sd	ra,8(sp)
ffffffffc02049c8:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02049ca:	100027f3          	csrr	a5,sstatus
ffffffffc02049ce:	8b89                	and	a5,a5,2
ffffffffc02049d0:	4401                	li	s0,0
ffffffffc02049d2:	efbd                	bnez	a5,ffffffffc0204a50 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02049d4:	00012897          	auipc	a7,0x12
ffffffffc02049d8:	be48b883          	ld	a7,-1052(a7) # ffffffffc02165b8 <current>
ffffffffc02049dc:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02049e0:	00012517          	auipc	a0,0x12
ffffffffc02049e4:	be853503          	ld	a0,-1048(a0) # ffffffffc02165c8 <idleproc>
ffffffffc02049e8:	04a88e63          	beq	a7,a0,ffffffffc0204a44 <schedule+0x80>
ffffffffc02049ec:	0c888693          	add	a3,a7,200
ffffffffc02049f0:	00012617          	auipc	a2,0x12
ffffffffc02049f4:	b3860613          	add	a2,a2,-1224 # ffffffffc0216528 <proc_list>
        le = last;
ffffffffc02049f8:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02049fa:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02049fc:	4809                	li	a6,2
ffffffffc02049fe:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0204a00:	00c78863          	beq	a5,a2,ffffffffc0204a10 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a04:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0204a08:	f3878593          	add	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a0c:	03070163          	beq	a4,a6,ffffffffc0204a2e <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204a10:	fef697e3          	bne	a3,a5,ffffffffc02049fe <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a14:	ed89                	bnez	a1,ffffffffc0204a2e <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0204a16:	451c                	lw	a5,8(a0)
ffffffffc0204a18:	2785                	addw	a5,a5,1
ffffffffc0204a1a:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204a1c:	00a88463          	beq	a7,a0,ffffffffc0204a24 <schedule+0x60>
            proc_run(next);
ffffffffc0204a20:	8e3ff0ef          	jal	ffffffffc0204302 <proc_run>
    if (flag) {
ffffffffc0204a24:	e819                	bnez	s0,ffffffffc0204a3a <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204a26:	60a2                	ld	ra,8(sp)
ffffffffc0204a28:	6402                	ld	s0,0(sp)
ffffffffc0204a2a:	0141                	add	sp,sp,16
ffffffffc0204a2c:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a2e:	4198                	lw	a4,0(a1)
ffffffffc0204a30:	4789                	li	a5,2
ffffffffc0204a32:	fef712e3          	bne	a4,a5,ffffffffc0204a16 <schedule+0x52>
ffffffffc0204a36:	852e                	mv	a0,a1
ffffffffc0204a38:	bff9                	j	ffffffffc0204a16 <schedule+0x52>
}
ffffffffc0204a3a:	6402                	ld	s0,0(sp)
ffffffffc0204a3c:	60a2                	ld	ra,8(sp)
ffffffffc0204a3e:	0141                	add	sp,sp,16
        intr_enable();
ffffffffc0204a40:	b6bfb06f          	j	ffffffffc02005aa <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204a44:	00012617          	auipc	a2,0x12
ffffffffc0204a48:	ae460613          	add	a2,a2,-1308 # ffffffffc0216528 <proc_list>
ffffffffc0204a4c:	86b2                	mv	a3,a2
ffffffffc0204a4e:	b76d                	j	ffffffffc02049f8 <schedule+0x34>
        intr_disable();
ffffffffc0204a50:	b61fb0ef          	jal	ffffffffc02005b0 <intr_disable>
        return 1;
ffffffffc0204a54:	4405                	li	s0,1
ffffffffc0204a56:	bfbd                	j	ffffffffc02049d4 <schedule+0x10>

ffffffffc0204a58 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204a58:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204a5c:	2785                	addw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc0204a5e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0204a62:	02000513          	li	a0,32
ffffffffc0204a66:	9d0d                	subw	a0,a0,a1
}
ffffffffc0204a68:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0204a6c:	8082                	ret

ffffffffc0204a6e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204a6e:	02069813          	sll	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a72:	7179                	add	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204a74:	02085813          	srl	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a78:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204a7a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204a7e:	f022                	sd	s0,32(sp)
ffffffffc0204a80:	ec26                	sd	s1,24(sp)
ffffffffc0204a82:	e84a                	sd	s2,16(sp)
ffffffffc0204a84:	f406                	sd	ra,40(sp)
ffffffffc0204a86:	84aa                	mv	s1,a0
ffffffffc0204a88:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204a8a:	fff7041b          	addw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204a8e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0204a90:	05067063          	bgeu	a2,a6,ffffffffc0204ad0 <printnum+0x62>
ffffffffc0204a94:	e44e                	sd	s3,8(sp)
ffffffffc0204a96:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0204a98:	4785                	li	a5,1
ffffffffc0204a9a:	00e7d763          	bge	a5,a4,ffffffffc0204aa8 <printnum+0x3a>
            putch(padc, putdat);
ffffffffc0204a9e:	85ca                	mv	a1,s2
ffffffffc0204aa0:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0204aa2:	347d                	addw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204aa4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204aa6:	fc65                	bnez	s0,ffffffffc0204a9e <printnum+0x30>
ffffffffc0204aa8:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204aaa:	1a02                	sll	s4,s4,0x20
ffffffffc0204aac:	020a5a13          	srl	s4,s4,0x20
ffffffffc0204ab0:	00002797          	auipc	a5,0x2
ffffffffc0204ab4:	24878793          	add	a5,a5,584 # ffffffffc0206cf8 <etext+0x1dbe>
ffffffffc0204ab8:	97d2                	add	a5,a5,s4
}
ffffffffc0204aba:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204abc:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0204ac0:	70a2                	ld	ra,40(sp)
ffffffffc0204ac2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204ac4:	85ca                	mv	a1,s2
ffffffffc0204ac6:	87a6                	mv	a5,s1
}
ffffffffc0204ac8:	6942                	ld	s2,16(sp)
ffffffffc0204aca:	64e2                	ld	s1,24(sp)
ffffffffc0204acc:	6145                	add	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204ace:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204ad0:	03065633          	divu	a2,a2,a6
ffffffffc0204ad4:	8722                	mv	a4,s0
ffffffffc0204ad6:	f99ff0ef          	jal	ffffffffc0204a6e <printnum>
ffffffffc0204ada:	bfc1                	j	ffffffffc0204aaa <printnum+0x3c>

ffffffffc0204adc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204adc:	7119                	add	sp,sp,-128
ffffffffc0204ade:	f4a6                	sd	s1,104(sp)
ffffffffc0204ae0:	f0ca                	sd	s2,96(sp)
ffffffffc0204ae2:	ecce                	sd	s3,88(sp)
ffffffffc0204ae4:	e8d2                	sd	s4,80(sp)
ffffffffc0204ae6:	e4d6                	sd	s5,72(sp)
ffffffffc0204ae8:	e0da                	sd	s6,64(sp)
ffffffffc0204aea:	f862                	sd	s8,48(sp)
ffffffffc0204aec:	fc86                	sd	ra,120(sp)
ffffffffc0204aee:	f8a2                	sd	s0,112(sp)
ffffffffc0204af0:	fc5e                	sd	s7,56(sp)
ffffffffc0204af2:	f466                	sd	s9,40(sp)
ffffffffc0204af4:	f06a                	sd	s10,32(sp)
ffffffffc0204af6:	ec6e                	sd	s11,24(sp)
ffffffffc0204af8:	892a                	mv	s2,a0
ffffffffc0204afa:	84ae                	mv	s1,a1
ffffffffc0204afc:	8c32                	mv	s8,a2
ffffffffc0204afe:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b00:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b04:	05500b13          	li	s6,85
ffffffffc0204b08:	00002a97          	auipc	s5,0x2
ffffffffc0204b0c:	390a8a93          	add	s5,s5,912 # ffffffffc0206e98 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b10:	000c4503          	lbu	a0,0(s8)
ffffffffc0204b14:	001c0413          	add	s0,s8,1
ffffffffc0204b18:	01350a63          	beq	a0,s3,ffffffffc0204b2c <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0204b1c:	cd0d                	beqz	a0,ffffffffc0204b56 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0204b1e:	85a6                	mv	a1,s1
ffffffffc0204b20:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204b22:	00044503          	lbu	a0,0(s0)
ffffffffc0204b26:	0405                	add	s0,s0,1
ffffffffc0204b28:	ff351ae3          	bne	a0,s3,ffffffffc0204b1c <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0204b2c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0204b30:	4b81                	li	s7,0
ffffffffc0204b32:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0204b34:	5d7d                	li	s10,-1
ffffffffc0204b36:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204b38:	00044683          	lbu	a3,0(s0)
ffffffffc0204b3c:	00140c13          	add	s8,s0,1
ffffffffc0204b40:	fdd6859b          	addw	a1,a3,-35
ffffffffc0204b44:	0ff5f593          	zext.b	a1,a1
ffffffffc0204b48:	02bb6663          	bltu	s6,a1,ffffffffc0204b74 <vprintfmt+0x98>
ffffffffc0204b4c:	058a                	sll	a1,a1,0x2
ffffffffc0204b4e:	95d6                	add	a1,a1,s5
ffffffffc0204b50:	4198                	lw	a4,0(a1)
ffffffffc0204b52:	9756                	add	a4,a4,s5
ffffffffc0204b54:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204b56:	70e6                	ld	ra,120(sp)
ffffffffc0204b58:	7446                	ld	s0,112(sp)
ffffffffc0204b5a:	74a6                	ld	s1,104(sp)
ffffffffc0204b5c:	7906                	ld	s2,96(sp)
ffffffffc0204b5e:	69e6                	ld	s3,88(sp)
ffffffffc0204b60:	6a46                	ld	s4,80(sp)
ffffffffc0204b62:	6aa6                	ld	s5,72(sp)
ffffffffc0204b64:	6b06                	ld	s6,64(sp)
ffffffffc0204b66:	7be2                	ld	s7,56(sp)
ffffffffc0204b68:	7c42                	ld	s8,48(sp)
ffffffffc0204b6a:	7ca2                	ld	s9,40(sp)
ffffffffc0204b6c:	7d02                	ld	s10,32(sp)
ffffffffc0204b6e:	6de2                	ld	s11,24(sp)
ffffffffc0204b70:	6109                	add	sp,sp,128
ffffffffc0204b72:	8082                	ret
            putch('%', putdat);
ffffffffc0204b74:	85a6                	mv	a1,s1
ffffffffc0204b76:	02500513          	li	a0,37
ffffffffc0204b7a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204b7c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0204b80:	02500793          	li	a5,37
ffffffffc0204b84:	8c22                	mv	s8,s0
ffffffffc0204b86:	f8f705e3          	beq	a4,a5,ffffffffc0204b10 <vprintfmt+0x34>
ffffffffc0204b8a:	02500713          	li	a4,37
ffffffffc0204b8e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0204b92:	1c7d                	add	s8,s8,-1
ffffffffc0204b94:	fee79de3          	bne	a5,a4,ffffffffc0204b8e <vprintfmt+0xb2>
ffffffffc0204b98:	bfa5                	j	ffffffffc0204b10 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0204b9a:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0204b9e:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0204ba0:	fd068d1b          	addw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0204ba4:	fd07859b          	addw	a1,a5,-48
                ch = *fmt;
ffffffffc0204ba8:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bac:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0204bae:	02b76563          	bltu	a4,a1,ffffffffc0204bd8 <vprintfmt+0xfc>
ffffffffc0204bb2:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0204bb4:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204bb8:	002d171b          	sllw	a4,s10,0x2
ffffffffc0204bbc:	01a7073b          	addw	a4,a4,s10
ffffffffc0204bc0:	0017171b          	sllw	a4,a4,0x1
ffffffffc0204bc4:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0204bc6:	fd07859b          	addw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204bca:	0405                	add	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204bcc:	fd070d1b          	addw	s10,a4,-48
                ch = *fmt;
ffffffffc0204bd0:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0204bd4:	feb570e3          	bgeu	a0,a1,ffffffffc0204bb4 <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0204bd8:	f60cd0e3          	bgez	s9,ffffffffc0204b38 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0204bdc:	8cea                	mv	s9,s10
ffffffffc0204bde:	5d7d                	li	s10,-1
ffffffffc0204be0:	bfa1                	j	ffffffffc0204b38 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204be2:	8db6                	mv	s11,a3
ffffffffc0204be4:	8462                	mv	s0,s8
ffffffffc0204be6:	bf89                	j	ffffffffc0204b38 <vprintfmt+0x5c>
ffffffffc0204be8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0204bea:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0204bec:	b7b1                	j	ffffffffc0204b38 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0204bee:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204bf0:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204bf4:	00c7c463          	blt	a5,a2,ffffffffc0204bfc <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0204bf8:	1a060163          	beqz	a2,ffffffffc0204d9a <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0204bfc:	000a3603          	ld	a2,0(s4)
ffffffffc0204c00:	46c1                	li	a3,16
ffffffffc0204c02:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204c04:	000d879b          	sext.w	a5,s11
ffffffffc0204c08:	8766                	mv	a4,s9
ffffffffc0204c0a:	85a6                	mv	a1,s1
ffffffffc0204c0c:	854a                	mv	a0,s2
ffffffffc0204c0e:	e61ff0ef          	jal	ffffffffc0204a6e <printnum>
            break;
ffffffffc0204c12:	bdfd                	j	ffffffffc0204b10 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0204c14:	000a2503          	lw	a0,0(s4)
ffffffffc0204c18:	85a6                	mv	a1,s1
ffffffffc0204c1a:	0a21                	add	s4,s4,8
ffffffffc0204c1c:	9902                	jalr	s2
            break;
ffffffffc0204c1e:	bdcd                	j	ffffffffc0204b10 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0204c20:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204c22:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204c26:	00c7c463          	blt	a5,a2,ffffffffc0204c2e <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0204c2a:	16060363          	beqz	a2,ffffffffc0204d90 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0204c2e:	000a3603          	ld	a2,0(s4)
ffffffffc0204c32:	46a9                	li	a3,10
ffffffffc0204c34:	8a3a                	mv	s4,a4
ffffffffc0204c36:	b7f9                	j	ffffffffc0204c04 <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0204c38:	85a6                	mv	a1,s1
ffffffffc0204c3a:	03000513          	li	a0,48
ffffffffc0204c3e:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204c40:	85a6                	mv	a1,s1
ffffffffc0204c42:	07800513          	li	a0,120
ffffffffc0204c46:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204c48:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0204c4c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204c4e:	0a21                	add	s4,s4,8
            goto number;
ffffffffc0204c50:	bf55                	j	ffffffffc0204c04 <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0204c52:	85a6                	mv	a1,s1
ffffffffc0204c54:	02500513          	li	a0,37
ffffffffc0204c58:	9902                	jalr	s2
            break;
ffffffffc0204c5a:	bd5d                	j	ffffffffc0204b10 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0204c5c:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c60:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0204c62:	0a21                	add	s4,s4,8
            goto process_precision;
ffffffffc0204c64:	bf95                	j	ffffffffc0204bd8 <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0204c66:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204c68:	008a0713          	add	a4,s4,8
    if (lflag >= 2) {
ffffffffc0204c6c:	00c7c463          	blt	a5,a2,ffffffffc0204c74 <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0204c70:	10060b63          	beqz	a2,ffffffffc0204d86 <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0204c74:	000a3603          	ld	a2,0(s4)
ffffffffc0204c78:	46a1                	li	a3,8
ffffffffc0204c7a:	8a3a                	mv	s4,a4
ffffffffc0204c7c:	b761                	j	ffffffffc0204c04 <vprintfmt+0x128>
            if (width < 0)
ffffffffc0204c7e:	fffcc793          	not	a5,s9
ffffffffc0204c82:	97fd                	sra	a5,a5,0x3f
ffffffffc0204c84:	00fcf7b3          	and	a5,s9,a5
ffffffffc0204c88:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c8c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0204c8e:	b56d                	j	ffffffffc0204b38 <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204c90:	000a3403          	ld	s0,0(s4)
ffffffffc0204c94:	008a0793          	add	a5,s4,8
ffffffffc0204c98:	e43e                	sd	a5,8(sp)
ffffffffc0204c9a:	12040063          	beqz	s0,ffffffffc0204dba <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0204c9e:	0d905963          	blez	s9,ffffffffc0204d70 <vprintfmt+0x294>
ffffffffc0204ca2:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204ca6:	00140a13          	add	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0204caa:	12fd9763          	bne	s11,a5,ffffffffc0204dd8 <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cae:	00044783          	lbu	a5,0(s0)
ffffffffc0204cb2:	0007851b          	sext.w	a0,a5
ffffffffc0204cb6:	cb9d                	beqz	a5,ffffffffc0204cec <vprintfmt+0x210>
ffffffffc0204cb8:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204cba:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cbe:	000d4563          	bltz	s10,ffffffffc0204cc8 <vprintfmt+0x1ec>
ffffffffc0204cc2:	3d7d                	addw	s10,s10,-1
ffffffffc0204cc4:	028d0263          	beq	s10,s0,ffffffffc0204ce8 <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0204cc8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204cca:	0c0b8d63          	beqz	s7,ffffffffc0204da4 <vprintfmt+0x2c8>
ffffffffc0204cce:	3781                	addw	a5,a5,-32
ffffffffc0204cd0:	0cfdfa63          	bgeu	s11,a5,ffffffffc0204da4 <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0204cd4:	03f00513          	li	a0,63
ffffffffc0204cd8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204cda:	000a4783          	lbu	a5,0(s4)
ffffffffc0204cde:	3cfd                	addw	s9,s9,-1
ffffffffc0204ce0:	0a05                	add	s4,s4,1
ffffffffc0204ce2:	0007851b          	sext.w	a0,a5
ffffffffc0204ce6:	ffe1                	bnez	a5,ffffffffc0204cbe <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0204ce8:	01905963          	blez	s9,ffffffffc0204cfa <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0204cec:	85a6                	mv	a1,s1
ffffffffc0204cee:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0204cf2:	3cfd                	addw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0204cf4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204cf6:	fe0c9be3          	bnez	s9,ffffffffc0204cec <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204cfa:	6a22                	ld	s4,8(sp)
ffffffffc0204cfc:	bd11                	j	ffffffffc0204b10 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0204cfe:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0204d00:	008a0b93          	add	s7,s4,8
    if (lflag >= 2) {
ffffffffc0204d04:	00c7c363          	blt	a5,a2,ffffffffc0204d0a <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0204d08:	ce25                	beqz	a2,ffffffffc0204d80 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0204d0a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204d0e:	08044d63          	bltz	s0,ffffffffc0204da8 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0204d12:	8622                	mv	a2,s0
ffffffffc0204d14:	8a5e                	mv	s4,s7
ffffffffc0204d16:	46a9                	li	a3,10
ffffffffc0204d18:	b5f5                	j	ffffffffc0204c04 <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0204d1a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204d1e:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0204d20:	41f7d71b          	sraw	a4,a5,0x1f
ffffffffc0204d24:	8fb9                	xor	a5,a5,a4
ffffffffc0204d26:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204d2a:	02d64663          	blt	a2,a3,ffffffffc0204d56 <vprintfmt+0x27a>
ffffffffc0204d2e:	00369713          	sll	a4,a3,0x3
ffffffffc0204d32:	00002797          	auipc	a5,0x2
ffffffffc0204d36:	2be78793          	add	a5,a5,702 # ffffffffc0206ff0 <error_string>
ffffffffc0204d3a:	97ba                	add	a5,a5,a4
ffffffffc0204d3c:	639c                	ld	a5,0(a5)
ffffffffc0204d3e:	cf81                	beqz	a5,ffffffffc0204d56 <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204d40:	86be                	mv	a3,a5
ffffffffc0204d42:	00000617          	auipc	a2,0x0
ffffffffc0204d46:	22660613          	add	a2,a2,550 # ffffffffc0204f68 <etext+0x2e>
ffffffffc0204d4a:	85a6                	mv	a1,s1
ffffffffc0204d4c:	854a                	mv	a0,s2
ffffffffc0204d4e:	0e8000ef          	jal	ffffffffc0204e36 <printfmt>
            err = va_arg(ap, int);
ffffffffc0204d52:	0a21                	add	s4,s4,8
ffffffffc0204d54:	bb75                	j	ffffffffc0204b10 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204d56:	00002617          	auipc	a2,0x2
ffffffffc0204d5a:	fc260613          	add	a2,a2,-62 # ffffffffc0206d18 <etext+0x1dde>
ffffffffc0204d5e:	85a6                	mv	a1,s1
ffffffffc0204d60:	854a                	mv	a0,s2
ffffffffc0204d62:	0d4000ef          	jal	ffffffffc0204e36 <printfmt>
            err = va_arg(ap, int);
ffffffffc0204d66:	0a21                	add	s4,s4,8
ffffffffc0204d68:	b365                	j	ffffffffc0204b10 <vprintfmt+0x34>
            lflag ++;
ffffffffc0204d6a:	2605                	addw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d6c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0204d6e:	b3e9                	j	ffffffffc0204b38 <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d70:	00044783          	lbu	a5,0(s0)
ffffffffc0204d74:	0007851b          	sext.w	a0,a5
ffffffffc0204d78:	d3c9                	beqz	a5,ffffffffc0204cfa <vprintfmt+0x21e>
ffffffffc0204d7a:	00140a13          	add	s4,s0,1
ffffffffc0204d7e:	bf2d                	j	ffffffffc0204cb8 <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0204d80:	000a2403          	lw	s0,0(s4)
ffffffffc0204d84:	b769                	j	ffffffffc0204d0e <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0204d86:	000a6603          	lwu	a2,0(s4)
ffffffffc0204d8a:	46a1                	li	a3,8
ffffffffc0204d8c:	8a3a                	mv	s4,a4
ffffffffc0204d8e:	bd9d                	j	ffffffffc0204c04 <vprintfmt+0x128>
ffffffffc0204d90:	000a6603          	lwu	a2,0(s4)
ffffffffc0204d94:	46a9                	li	a3,10
ffffffffc0204d96:	8a3a                	mv	s4,a4
ffffffffc0204d98:	b5b5                	j	ffffffffc0204c04 <vprintfmt+0x128>
ffffffffc0204d9a:	000a6603          	lwu	a2,0(s4)
ffffffffc0204d9e:	46c1                	li	a3,16
ffffffffc0204da0:	8a3a                	mv	s4,a4
ffffffffc0204da2:	b58d                	j	ffffffffc0204c04 <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0204da4:	9902                	jalr	s2
ffffffffc0204da6:	bf15                	j	ffffffffc0204cda <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0204da8:	85a6                	mv	a1,s1
ffffffffc0204daa:	02d00513          	li	a0,45
ffffffffc0204dae:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204db0:	40800633          	neg	a2,s0
ffffffffc0204db4:	8a5e                	mv	s4,s7
ffffffffc0204db6:	46a9                	li	a3,10
ffffffffc0204db8:	b5b1                	j	ffffffffc0204c04 <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0204dba:	01905663          	blez	s9,ffffffffc0204dc6 <vprintfmt+0x2ea>
ffffffffc0204dbe:	02d00793          	li	a5,45
ffffffffc0204dc2:	04fd9263          	bne	s11,a5,ffffffffc0204e06 <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204dc6:	02800793          	li	a5,40
ffffffffc0204dca:	00002a17          	auipc	s4,0x2
ffffffffc0204dce:	f47a0a13          	add	s4,s4,-185 # ffffffffc0206d11 <etext+0x1dd7>
ffffffffc0204dd2:	02800513          	li	a0,40
ffffffffc0204dd6:	b5cd                	j	ffffffffc0204cb8 <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dd8:	85ea                	mv	a1,s10
ffffffffc0204dda:	8522                	mv	a0,s0
ffffffffc0204ddc:	094000ef          	jal	ffffffffc0204e70 <strnlen>
ffffffffc0204de0:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0204de4:	01905963          	blez	s9,ffffffffc0204df6 <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0204de8:	2d81                	sext.w	s11,s11
ffffffffc0204dea:	85a6                	mv	a1,s1
ffffffffc0204dec:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204dee:	3cfd                	addw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0204df0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204df2:	fe0c9ce3          	bnez	s9,ffffffffc0204dea <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204df6:	00044783          	lbu	a5,0(s0)
ffffffffc0204dfa:	0007851b          	sext.w	a0,a5
ffffffffc0204dfe:	ea079de3          	bnez	a5,ffffffffc0204cb8 <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204e02:	6a22                	ld	s4,8(sp)
ffffffffc0204e04:	b331                	j	ffffffffc0204b10 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e06:	85ea                	mv	a1,s10
ffffffffc0204e08:	00002517          	auipc	a0,0x2
ffffffffc0204e0c:	f0850513          	add	a0,a0,-248 # ffffffffc0206d10 <etext+0x1dd6>
ffffffffc0204e10:	060000ef          	jal	ffffffffc0204e70 <strnlen>
ffffffffc0204e14:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0204e18:	00002417          	auipc	s0,0x2
ffffffffc0204e1c:	ef840413          	add	s0,s0,-264 # ffffffffc0206d10 <etext+0x1dd6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e20:	00002a17          	auipc	s4,0x2
ffffffffc0204e24:	ef1a0a13          	add	s4,s4,-271 # ffffffffc0206d11 <etext+0x1dd7>
ffffffffc0204e28:	02800793          	li	a5,40
ffffffffc0204e2c:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e30:	fb904ce3          	bgtz	s9,ffffffffc0204de8 <vprintfmt+0x30c>
ffffffffc0204e34:	b551                	j	ffffffffc0204cb8 <vprintfmt+0x1dc>

ffffffffc0204e36 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e36:	715d                	add	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204e38:	02810313          	add	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e3c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e3e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204e40:	ec06                	sd	ra,24(sp)
ffffffffc0204e42:	f83a                	sd	a4,48(sp)
ffffffffc0204e44:	fc3e                	sd	a5,56(sp)
ffffffffc0204e46:	e0c2                	sd	a6,64(sp)
ffffffffc0204e48:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204e4a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204e4c:	c91ff0ef          	jal	ffffffffc0204adc <vprintfmt>
}
ffffffffc0204e50:	60e2                	ld	ra,24(sp)
ffffffffc0204e52:	6161                	add	sp,sp,80
ffffffffc0204e54:	8082                	ret

ffffffffc0204e56 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204e56:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204e5a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204e5c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204e5e:	cb81                	beqz	a5,ffffffffc0204e6e <strlen+0x18>
        cnt ++;
ffffffffc0204e60:	0505                	add	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204e62:	00a707b3          	add	a5,a4,a0
ffffffffc0204e66:	0007c783          	lbu	a5,0(a5)
ffffffffc0204e6a:	fbfd                	bnez	a5,ffffffffc0204e60 <strlen+0xa>
ffffffffc0204e6c:	8082                	ret
    }
    return cnt;
}
ffffffffc0204e6e:	8082                	ret

ffffffffc0204e70 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204e70:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204e72:	e589                	bnez	a1,ffffffffc0204e7c <strnlen+0xc>
ffffffffc0204e74:	a811                	j	ffffffffc0204e88 <strnlen+0x18>
        cnt ++;
ffffffffc0204e76:	0785                	add	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204e78:	00f58863          	beq	a1,a5,ffffffffc0204e88 <strnlen+0x18>
ffffffffc0204e7c:	00f50733          	add	a4,a0,a5
ffffffffc0204e80:	00074703          	lbu	a4,0(a4)
ffffffffc0204e84:	fb6d                	bnez	a4,ffffffffc0204e76 <strnlen+0x6>
ffffffffc0204e86:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204e88:	852e                	mv	a0,a1
ffffffffc0204e8a:	8082                	ret

ffffffffc0204e8c <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204e8c:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204e8e:	0005c703          	lbu	a4,0(a1)
ffffffffc0204e92:	0785                	add	a5,a5,1
ffffffffc0204e94:	0585                	add	a1,a1,1
ffffffffc0204e96:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204e9a:	fb75                	bnez	a4,ffffffffc0204e8e <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204e9c:	8082                	ret

ffffffffc0204e9e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204e9e:	00054783          	lbu	a5,0(a0)
ffffffffc0204ea2:	e791                	bnez	a5,ffffffffc0204eae <strcmp+0x10>
ffffffffc0204ea4:	a02d                	j	ffffffffc0204ece <strcmp+0x30>
ffffffffc0204ea6:	00054783          	lbu	a5,0(a0)
ffffffffc0204eaa:	cf89                	beqz	a5,ffffffffc0204ec4 <strcmp+0x26>
ffffffffc0204eac:	85b6                	mv	a1,a3
ffffffffc0204eae:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0204eb2:	0505                	add	a0,a0,1
ffffffffc0204eb4:	00158693          	add	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204eb8:	fef707e3          	beq	a4,a5,ffffffffc0204ea6 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ebc:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204ec0:	9d19                	subw	a0,a0,a4
ffffffffc0204ec2:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ec4:	0015c703          	lbu	a4,1(a1)
ffffffffc0204ec8:	4501                	li	a0,0
}
ffffffffc0204eca:	9d19                	subw	a0,a0,a4
ffffffffc0204ecc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ece:	0005c703          	lbu	a4,0(a1)
ffffffffc0204ed2:	4501                	li	a0,0
ffffffffc0204ed4:	b7f5                	j	ffffffffc0204ec0 <strcmp+0x22>

ffffffffc0204ed6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204ed6:	00054783          	lbu	a5,0(a0)
ffffffffc0204eda:	c799                	beqz	a5,ffffffffc0204ee8 <strchr+0x12>
        if (*s == c) {
ffffffffc0204edc:	00f58763          	beq	a1,a5,ffffffffc0204eea <strchr+0x14>
    while (*s != '\0') {
ffffffffc0204ee0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204ee4:	0505                	add	a0,a0,1
    while (*s != '\0') {
ffffffffc0204ee6:	fbfd                	bnez	a5,ffffffffc0204edc <strchr+0x6>
    }
    return NULL;
ffffffffc0204ee8:	4501                	li	a0,0
}
ffffffffc0204eea:	8082                	ret

ffffffffc0204eec <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204eec:	ca01                	beqz	a2,ffffffffc0204efc <memset+0x10>
ffffffffc0204eee:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204ef0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204ef2:	0785                	add	a5,a5,1
ffffffffc0204ef4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204ef8:	fef61de3          	bne	a2,a5,ffffffffc0204ef2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204efc:	8082                	ret

ffffffffc0204efe <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204efe:	ca19                	beqz	a2,ffffffffc0204f14 <memcpy+0x16>
ffffffffc0204f00:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204f02:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204f04:	0005c703          	lbu	a4,0(a1)
ffffffffc0204f08:	0585                	add	a1,a1,1
ffffffffc0204f0a:	0785                	add	a5,a5,1
ffffffffc0204f0c:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204f10:	feb61ae3          	bne	a2,a1,ffffffffc0204f04 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204f14:	8082                	ret

ffffffffc0204f16 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204f16:	c205                	beqz	a2,ffffffffc0204f36 <memcmp+0x20>
ffffffffc0204f18:	962a                	add	a2,a2,a0
ffffffffc0204f1a:	a019                	j	ffffffffc0204f20 <memcmp+0xa>
ffffffffc0204f1c:	00c50d63          	beq	a0,a2,ffffffffc0204f36 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204f20:	00054783          	lbu	a5,0(a0)
ffffffffc0204f24:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204f28:	0505                	add	a0,a0,1
ffffffffc0204f2a:	0585                	add	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204f2c:	fee788e3          	beq	a5,a4,ffffffffc0204f1c <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204f30:	40e7853b          	subw	a0,a5,a4
ffffffffc0204f34:	8082                	ret
    }
    return 0;
ffffffffc0204f36:	4501                	li	a0,0
}
ffffffffc0204f38:	8082                	ret
