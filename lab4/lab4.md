### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。

###  练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）


初始化的思路非常简单，主要是进行清零操作，即将所有成员变量都设置为0，指针则设置为NULL，个别字段需要特殊处理。指导书给出了三个需要特别初始化的部分：进程的状态设置为PROC_UNINIT，pid设置为-1，页表基址设置为uCore内核已建立的启动页表地址，即boot_cr3。

```c
        proc->state = PROC_UNINIT; 
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN);
```
        
proc_struct中的struct context context字段表示进程执行的上下文，具体来说，struct context结构体包含了14个寄存器（ra、sp、s0至s11），这些寄存器用于在进程切换时还原之前进程的运行状态。需要注意的是，并非所有寄存器都需要保存，编译器会根据函数调用约定自动生成保存和恢复调用者保存（caller-saved）寄存器的代码，因此在进程切换中，我们只需要保存被调用者保存（callee-saved）寄存器。

进程的中断帧由struct trapframe *tf表示，记录了进程从用户空间跳转到内核空间时的执行状态。在本次实验中，我们仅关注内核线程的管理，因此tf主要用于保存第一个内核线程（initproc）的中断帧。我们可以从kernel_thread函数的实现来了解如何创建并切换到initproc。

在创建initproc时，kernel_thread函数使用局部变量tf来保存内核线程的临时中断帧，并将其指针传递给do_fork函数，而do_fork函数会调用copy_thread来进行线程的复制和初始化：

```c
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}
```

copy_thread函数在新进程的内核栈上为进程的中断帧分配空间，并将传入的tf（中断帧）拷贝到新进程的中断帧中。然后，将a0寄存器设置为0，表明这是一个子进程。接着将上下文的ra寄存器设置为forkret函数的入口，确保进程切换后能返回到forkret函数。copy_thread函数还把tf的地址保存在上下文的栈顶，forkret函数会将tf传递给forkrets。

```c
static void
forkret(void) {
    forkrets(current->tf);
}
```

forkrets函数将tf参数放入sp寄存器：

```c
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
    j __trapret
```

在__trapret中，我们使用RESTORE_ALL指令恢复进程的所有寄存器，并执行srret跳回用户空间：

```c
__trapret:
    RESTORE_ALL
    # go back from supervisor call
    sret
```

在初始化过程中，我们还将中断帧中的epc寄存器设置为kernel_thread_entry，kernel_thread_entry函数将执行内核线程的主体代码：

```c
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
    move a0, s1
    jalr s0

    jal do_exit
```

在kernel_thread_entry中，s0寄存器保存着要执行的函数地址，s1寄存器则保存该函数的参数。我们将参数放入a0寄存器，并跳转到jalr s0执行指定的函数，完成内核线程的初始化。

总结起来，struct context context的作用是保存进程的上下文信息，尤其是被调用者保存的寄存器，从而在进程切换时能够恢复之前进程的状态；而struct trapframe *tf的作用是保存进程的中断帧，用于在内核线程初始化时保存执行状态，并在上下文切换时恢复进程的所有寄存器。

### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要”fork”的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块。
- 为进程分配一个内核栈。
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。


请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

```c
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 2213029
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        // 中断使能。
        local_intr_save(intr_flag);
        // 将当前进程设为传入的进程
        current = proc;
        // 修改页表项
        // 重新加载 cr3 寄存器(页目录表基址) 进行进程间的页表切换
        lcr3(next->cr3);
        // 使用 switch_to 进行上下文切换。
        switch_to(&(prev->context), &(next->context));
        local_intr_restore(intr_flag);
    }
}
```
pron_run实现了切换到一个新的进程（线程）的功能。在这段代码中，首先，需要判断切换到的进程（线程）是否是当前进程（线程），如果是，则无需进行任何处理；如果要切换的进程（线程）不是当前进程（线程），则进行进程切换操作；调用 local_intr_save(intr_flag) 函数关闭中断，以确保在进程切换过程中不会被中断；接着声明两个指向 struct proc_struct 类型的指针 prev 和 next，分别用于保存当前进程和要切换到的下一个进程，将当前进程指针 current 设置为要切换到的下一个进程；调用 lcr3(proc->cr3) 函数切换到下一个进程的页表，即将页表寄存器 CR3 的值设置为下一个进程的页表基址；调用 switch_to(&(prev->context), &(next->context)) 函数进行上下文切换，将当前进程的上下文保存到 prev->context 中，将下一个进程的上下文恢复到 next->context 中；最后再调用 local_intr_restore(intr_flag) 函数开启中断，恢复中断状态。至此，进程切换完成，当前进程被切换为要切换到的下一个进程（线程）。

在本实验中，一共创建了两个内核线程，一个为 idle 另外一个为执行 init_main 的 init 线程。

### 扩展练习 Challenge：

说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

```c
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

在 local_intr_save 宏中，x = __intr_save(); 会调用 __intr_save() 函数来禁用中断、保存当前中断状态并将其存储在 intr_flag 变量中。而在 local_intr_restore 宏中，__intr_restore(x); 会使用之前保存的中断状态来恢复中断。
1. local_intr_save(intr_flag);:
    这个宏调用了 __intr_save() 函数，并将返回值赋给 intr_flag。
    __intr_save() 函数的作用是检查当前的中断状态（通过读取 sstatus 寄存器的 SSTATUS_SIE 位）。
    如果中断是开启的（SSTATUS_SIE 位为1），则调用 intr_disable() 函数来关闭中断，并返回 1。
    如果中断是关闭的，则直接返回 0。
    因此，intr_flag 会保存中断在调用 local_intr_save 之前的状态。
2. local_intr_restore(intr_flag);:
    这个宏调用了 __intr_restore(intr_flag);。
    __intr_restore() 函数根据传入的 flag 值决定是否重新开启中断。
    如果 flag 为 1，则调用 intr_enable() 函数来开启中断。
    如果 flag 为 0，则不做任何操作。
