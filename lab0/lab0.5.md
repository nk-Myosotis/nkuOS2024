# 练习
## 实验要求
+ 基于markdown格式来完成，以文本方式为主
+ 填写各个基本练习中要求完成的报告内容
+ 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
+ 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

## 练习1: 使用GDB验证启动流程
本实验需要使用 GDB 调试 QEMU 模拟的 RISC-V 计算机加电开始运行到执行应用程序的第一条指令（即跳转到0x80200000）这个阶段的执行过程.
### 1. 内核运行成功
使用命令`$ qemu-system-riscv64 \
  --machine virt \
  --nographic \
  --bios default`

![alt text]({5AC36B83-98E2-40EA-8107-4D3A2861A604}.png)

opensbi 运行成功

### 2. 对QEMU进行调试
使用`make debug`完成内核镜像的生成和加载，启动 QEMU 时打开 GDB 监听端口，并暂停运行代码，等待 GDB 连接，提供了一个调试的起点。`make gdb`让 GDB 连接到监听端口，以进行远程调试。

我们在 lab0 界面打开一个终端，使用`make debug`启动 QEMU 并等待 GDB 连接；然后在另一个终端中，使用`make gdb`启动 GDB 并连接到 QEMU 。GDB 启动后，可以看到：

![alt text]({70C765F4-E0F0-4DAC-AAB3-439348426BF0}.png)

在GDB界面可以看到：
```
Reading symbols from bin/kernel...
The target architecture is set to "riscv:rv64".
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
```
其中`“0x0000000000001000 in ?? ()”`说明程序当前暂停在地址`0x1000`处。QEMU 模拟的 RISC-V 处理器的复位向量地址为`0x1000`，处理器将从此处开始执行复位代码。因此 GDB 显示程序暂停在`0x1000`处是合理的。这也说明 GDB 确实是从程序最开始的地方开始调试。
***
以下便是 RISC-V 硬件加电后的几条指令：
```
(gdb) x/10i 0x0000000000001000
   0x1000:	auipc	t0,0x0
=> 0x1004:	addi	a1,t0,32
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	t0,24(t0)
   0x1010:	jr	t0
```
RISC-V 硬件加电后，将要执行的指令在地址`0x1000`到地址`0x1010`处，在`0x1010`处将跳转到`0x80000000`执行 OpenSBI 程序。

`0x1000: auipc t0, 0x0`：用于将当前 PC 的值加上立即数 0x0 并将结果存储在寄存器 t0 中。用于生成全局地址。在这里，它将 t0 设置为 0。

`0x1004:	addi	a1,t0,32`：将寄存器 t0 中的值 0 与立即数 32 相加，并将结果存储在寄存器 a1 中。

`0x1008: csrr a0, mhartid`：用于从 CSR（Control and Status Register） mhartid 中读取值，并将结果存储在寄存器 a0 中。这通常用于获取硬件线程 ID。

`0x100c: ld t0, 24(t0)`：用于从存储器中加载一个双字（64 位）的数据，并将结果存储在寄存器 t0 中。地址计算是将寄存器 t0 的值加上立即数 24。

`0x1010: jr t0`：用于跳转到寄存器 t0 中存储的地址，实现无条件跳转，即开始执行 OpenSBI。
***
用`si`单步执行一条汇编指令跳转到`0x0000000000001004`，可以看见：
```
(gdb) si
0x0000000000001004 in ?? ()
```
***
使用`x/10i $pc`显示即将执行的10条汇编指令，可以看见：
```
(gdb) x/10i $pc
=> 0x1004:	addi	a1,t0,32
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	t0,24(t0)
   0x1010:	jr	t0
   0x1014:	unimp
   0x1016:	unimp
   0x1018:	unimp
   0x101a:	0x8000
   0x101c:	unimp
   0x101e:	unimp
```
***
使用`x/10i $pc`和单步调试，发现该程序较复杂。所以使用`break *0x80200000`在`0x80200000`处设置断点。
```
(gdb) break *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
```
***
接着使用`continue`执行到断点处。
```
(gdb) continue
Continuing.
Breakpoint 1, kern_entry () at kern/init/entry.S:7
7	    la sp, bootstacktop
```
执行到0x80200000，可以看见 OpenSBI 应用程序开始执行：

![alt text]({69CA4FDE-0200-46C9-AE4E-434B23B6E255}.png)
***
使用`x/10i $pc`观察，得到
```
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:	auipc	sp,0x3
   0x80200004 <kern_entry+4>:	mv	sp,sp
   0x80200008 <kern_entry+8>:	j	0x8020000a <kern_init>
   0x8020000a <kern_init>:	auipc	a0,0x3
   0x8020000e <kern_init+4>:	addi	a0,a0,-2
   0x80200012 <kern_init+8>:	auipc	a2,0x3
   0x80200016 <kern_init+12>:	addi	a2,a2,-10
   0x8020001a <kern_init+16>:	addi	sp,sp,-16
   0x8020001c <kern_init+18>:	li	a1,0
   0x8020001e <kern_init+20>:	sub	a2,a2,a0
```