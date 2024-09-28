# 练习
## 实验要求
+ 基于markdown格式来完成，以文本方式为主
+ 填写各个基本练习中要求完成的报告内容
+ 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
+ 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

## 练习1: 理解内核启动中的程序入口操作
阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 `la sp, bootstacktop` 完成了什么操作，目的是什么？ `tail kern_init` 完成了什么操作，目的是什么？

### 1. 指令 `la sp, bootstacktop`
用于将栈顶指针sp设置到最高位，实现栈空间初始化;
目的是为系统加载设置栈空间。

### 2. 指令 `tail kern_init`
用于跳转到系统入口点;
目的是进入系统入口点，正式启动系统。

## 练习2：完善中断处理 （需要编程）
请编程完善trap.c中的中断处理函数`trap`，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用`print_ticks`子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的`shut_down()`函数关机。

补充`interrupt_handler`函数中，`case IRQ_S_TIMER` 即 处理定时器中断部分 的代码，如下：

```
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2  2212880  YOUR CODE :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            if(ticks==100)
            {
            	print_ticks();
            	num+=1;
            	if(num==10)
            	{
            		sbi_shutdown();
            	}
            	ticks=0;
            }
            clock_set_next_event();
            ticks+=1;
            
```

### 实现过程：

设置下次中断：调用 `clock_set_next_event()` 来安排下一次定时器中断。

计数器增加：每次中断时，ticks 加 1。

检查条件：若 ticks 达到 100，调用 `print_ticks()` 输出信息，并将 num 加 1；
如果 num 达到 10，调用 `sbi_shutdown()` 关机。

重置计数器：输出后，将 ticks 重置为 0。



### 定时器中断处理流程：

中断触发：当定时器到达设定的时间间隔时，硬件会产生一个中断信号，通知处理器。
中断处理函数入口：控制权转移到对应的中断处理函数（在这里是 IRQ_S_TIMER 的处理逻辑）。
保存上下文：在进入中断处理之前，通常需要保存当前的 CPU 上下文，以便中断处理完成后能够恢复。
执行中断处理逻辑：执行上述实现过程中描述的步骤，处理时钟中断，更新计数器，并根据条件输出信息或执行关机操作。
清除中断标志：通常需要清除中断标志，以确保不会重复处理同一个中断。
恢复上下文并返回：恢复之前保存的上下文，然后返回到被中断的程序继续执行。



然后在终端中输入代码`make qemu`，即根据 Makefile 文件中的定义，编译源代码和相关资源，可以看到：

```
++ setup timer interrupts
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```

终端在打印完10行“100 ticks”后，进程结束，符合预期功能。

## 扩展练习 Challenge1：描述与理解中断流程
回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中`mov a0，sp`的目的是什么？SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，`__alltraps` 中都需要保存所有寄存器吗？请说明理由。

### 异常产生与处理中断流程

1.异常产生：当 CPU 检测到异常（如非法指令、页面缺失等）或中断（如定时器中断）时，会自动保存当前程序状态，并转移控制权到异常处理程序。

2.进入异常处理程序：

CPU 会自动将程序计数器（PC）和必要的状态信息推入栈。
控制权转移到 `__alltraps`，这是所有异常和中断的统一入口。

3.保存上下文：

在 `__alltraps` 中，通常需要保存所有寄存器的值，以便在异常处理完成后能够恢复程序的执行状态。

使用 SAVE_ALL 宏将寄存器状态保存到栈上。这里的 `mov a0, sp` 的目的是将当前栈指针（`sp`）的值存储到 `a0` 寄存器中，以便后续操作中可以访问栈的状态。

4.处理异常或中断：

根据不同的异常类型，执行相应的异常处理逻辑。

5.恢复上下文：

执行完异常处理后，使用 RESTORE_ALL 宏将之前保存的寄存器值从栈中恢复。

6.返回到原程序：

恢复完上下文后，返回到中断或异常发生前的执行点，继续执行原程序。

### SAVE_ALL 中寄存器保存在栈中的位置：

保存寄存器的位置是根据栈指针（`sp`）动态确定的。具体的保存位置取决于 `sp` 的当前值，所以每次处理异常时，寄存器的保存位置都是基于当时的栈状态。

### 是否需要保存所有寄存器：

是，通常，对于任何中断，`__alltraps` 需要保存所有寄存器，因为在中断期间，可能会调用其他函数或中断处理程序，这些操作可能会修改寄存器。如果不保存所有寄存器，可能会丢失原程序的状态，导致后续执行出现错误。

## 扩展练习 Challenge2：理解上下文切换机制

回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

### csrw sscratch, sp 和 csrrw s0, sscratch, x0 实现了什么操作，目的是什么？

`csrw sscratch, sp` 将当前栈指针 sp 保存到 sscratch 寄存器中。
`csrrw s0, sscratch, x0` 将 sscratch 寄存器的值交换到 s0 寄存器中，同时将 x0（零寄存器）的值写入 sscratch。
这些操作的目的是保存和恢复栈指针，以便在中断处理过程中正确管理栈。

### SAVE_ALL 里面保存了 stval 和 scause 这些 CSR，而在 RESTORE_ALL 里面却不还原它们？那这样 store 的意义何在呢？

保存 stval 和 scause 的目的是在中断处理过程中可以访问这些寄存器的值，以便确定中断或异常的原因和相关信息。而在恢复上下文时，不需要还原这些寄存器，因为它们的值在中断处理完成后已经不再需要。

## 扩展练习 Challenge3：完善异常中断

编程完善在触发一条非法指令异常 mret 和 ebreak 时，在 kern/trap/trap.c 的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址。

### 补充代码

```
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
            tf->epc += 4; // 跳过非法指令
            break;
        case CAUSE_BREAKPOINT:
            cprintf("Exception type: Breakpoint\n");
            cprintf("Breakpoint caught at 0x%08x\n", tf->epc);
            tf->epc += 4; // 跳过断点指令
            break;
        // 其他异常处理...
    }
}
```

exception_handler 函数接收一个指向 trapframe 结构体的指针 tf，该结构体包含了中断或异常发生时的寄存器状态和其他信息。tf->cause 存储了导致异常的原因。通过 switch 语句，我们可以根据不同的异常类型执行相应的处理逻辑。

当捕获到非法指令异常时，首先打印出异常信息，包括触发异常的地址（tf->epc）。tf->epc 是异常发生时的程序计数器（PC），指向导致异常的指令地址。通过 tf->epc += 4;，我们将 epc 增加 4，跳过当前的非法指令，继续执行后面的指令。这是因为 RISC-V 指令通常是 4 字节对齐的。

 当捕获到断点异常时，执行类似的处理逻辑。打印出触发断点的地址和异常类型，通过 tf->epc += 4，可以跳过断点指令，继续执行后面的指令。
