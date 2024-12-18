# LAB5实验报告

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
## 练习0：填写已有实验 

> 本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行lab5的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。

本次练习0在填入之前代码时，另外补充修改了实验4的一点代码。

涉及到了实验4中的进程控制块（PCB）初始化和do_fork函数的修改。

1. 进程控制块的初始化
在本次实验中，我们对进程控制块进行了扩展，新增了几个成员变量，主要是为了管理进程的父子关系。新增的成员变量包括：

```C
cptr：指向当前进程的子线程双向链表头结点。
yptr：指向当前进程的“较年轻”的兄弟进程。
optr：指向当前进程的“较年长”的兄弟进程。
```
引入这几个成员变量的原因主要是因为这里用户进程会随着程序的执行不断的被创建、退出并销毁，为此引入了父子进程的概念，在子进程退出时，由于其内核栈和子进程自己的进程控制块无法进行自我回收，因此需要通知其父进程进行最后的回收工作。这里我们初始化为0或者NULL就行。

```C
proc->wait_state = 0;
proc->cptr = proc->yptr = proc->optr = NULL;
```

另外，还引入了一个新的成员变量wait_state，它用于表示进程的等待状态。相关的宏定义有：

```C
#define WT_CHILD                    (0x00000001 | WT_INTERRUPTED)
#define WT_INTERRUPTED               0x80000000  // 表示进程等待的状态可以被中断
```

2. 修改do_fork函数
在do_fork函数中，我们需要进行一些修改。首先，我们要确保当前进程的wait_state被设置为0。为了保证这一点，可以通过assert()来进行检查，确保在创建子进程时当前进程的等待状态是正确的。

接着，在插入新进程到进程哈希表和进程链表时，我们要设置新进程之间的链接。为了处理这些链接关系，实验中提供了一个set_links函数，这个函数不仅负责将进程插入链表，还会更新进程总数。因此，在do_fork中插入新进程时，我们需要调用set_links，而实验中原先的相关代码要被注释掉，避免重复操作。

关于lab3的内容直接使用了之前的do_pgfault（mm/vmm.c）函数，没有改动。

## 练习1: 加载应用程序并执行（需要编码） 
**do\_execv**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。

请在实验报告中简要说明你的设计实现过程。

请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

我们来分析一下到执行`load_icode`函数的过程。首先在实验4中，`init_proc`只是单单在控制台中打印了`hello world`。但是实验5则不一样，在`init_proc`中fork了一个内核线程执行`user_main`函数。

```C
int pid = kernel_thread(user_main, NULL, 0);
```

而我们在`user_main`所做的，就是执行了`kern_execve("exit", _binary_obj___user_exit_out_start,_binary_obj___user_exit_out_size)`这么一个函数，用于执行BIOS引导时与ucore内核一起被加载到内存中的用户程序/user/exit.c，让exit.c在用户态中执行。用指导手册的话来说，就是加载了存储在这个位置的程序exit并在user_main这个进程里开始执行。这时user_main就从内核进程变成了用户进程。

`kern_execve`函数实现如下：
```C
// kernel_execve - do SYS_exec syscall to exec a user program called by user_main kernel_thread
static int
kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
 //   ret = do_execve(name, len, binary, size);
    asm volatile(
        "li a0, %1\n"
        "lw a1, %2\n"
        "lw a2, %3\n"
        "lw a3, %4\n"
        "lw a4, %5\n"
    	"li a7, 10\n"
        "ebreak\n"
        "sw a0, %0\n"
        : "=m"(ret)
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
        : "memory");
    cprintf("ret = %d\n", ret);
    return ret;
}
```

实验中没有直接执行`do_execve()`函数，原因也是很简单，就是没有实现上下文的切换。本实验就采用了一种内联汇编的格式，用ebreak产生断点中断进行处理，通过设置a7寄存器的值为10说明这不是一个普通的断点中断，而是要转发到syscall()，实现了在内核态使用系统调用。

下面是`do\_execve`函数，其基本思路就是借着当前线程的壳（空间），用被加载的二进制程序的内存空间替换掉之前线程的内存空间。


```C
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm;
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {//检查传入的程序名是否在用户内存空间中是合法的，否就返回错误
        return -E_INVAL;
    }
    if (len > PROC_NAME_LEN) {
        len = PROC_NAME_LEN;//如果程序名的长度超过了预设的最大长度（PROC_NAME_LEN），则将其截断
    }

    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);//将程序名复制到一个本地变量local_name中

    if (mm != NULL) {// 如果当前进程具有内存管理结构体mm，则进行清理释放操作
        cputs("mm != NULL");
        lcr3(boot_cr3);//将CR3寄存器设置为内核页目录的物理地址
        //将当前的页表切换回引导页表（boot_cr3），从而确保不再引用已释放的内存区域
        if (mm_count_dec(mm) == 0) {// 如果当前进程的内存管理结构引用计数减为0，则清空相关内存管理区域和页表
            exit_mmap(mm);//释放内存映射
            put_pgdir(mm);//释放页目录
            mm_destroy(mm);//销毁内存管理结构
        }
        current->mm = NULL;// 将当前进程的内存管理结构指针设为NULL，表示没有有效的内存管理结构
    }
    int ret;
    if ((ret = load_icode(binary, size)) != 0) {// 加载新的可执行程序并建立新的内存映射关系
        goto execve_exit;
    }
    set_proc_name(current, local_name);// 给新进程设置进程名
    return 0;

execve_exit:
    do_exit(ret);// 执行出错，退出当前进程
    panic("already exit: %e.\n", ret);
}

```

我们主要通过do_execve函数来完成用户进程的创建工作。此函数的主要工作流程如下：

* 首先为加载新的执行码做好用户态内存空间清空准备。如果mm不为NULL，则设置页表为内核空间页表，且进一步判断mm的引用计数减1后是否为0，如果为0，则表明没有进程再需要此进程所占用的内存空间，为此将根据mm中的记录，释放进程所占用户空间内存和进程页表本身所占空间。最后把当前进程的mm内存管理指针为空。由于此处的initproc是内核线程，所以mm为NULL，整个处理都不会做。

* 接下来的一步是加载应用程序执行码到当前进程的新创建的用户态虚拟空中。这里涉及到读ELF格式的文件，申请内存空间，建立用户态虚存空间，加载应用程序执行码等。load_icode函数完成了整个复杂的工作。

总结do_execve函数其步骤如下：

- 检查程序名合法性:检查传入的程序名是否合法，若不合法，返回错误码 -E_INVAL。
- 处理程序名:如果程序名超过最大长度，截断并复制到本地缓冲区。
- 清理当前进程内存管理结构:如果当前进程有有效的内存管理结构，清理内存映射并销毁相关结构。
- 加载新程序:调用 load_icode() 加载新的可执行文件，加载失败则进行错误退出。
- 设置进程名:调用 set_proc_name() 更新进程名。
- 返回结果:加载成功则返回 0，失败则调用 do_exit() 终止进程。

>**如果set_proc_name的实现不变, 为什么不能直接set_proc_name(current, name)?**

1.内核空间与用户空间的分离：
在操作系统中，内核空间和用户空间是严格分离的。内核空间是操作系统的核心部分，而用户空间是用户程序运行的地方。操作系统通过内存保护机制，确保内核空间和用户空间之间无法直接互相访问，从而防止用户程序意外或恶意修改内核空间中的数据。

2.name 是用户空间的变量：
在 execve 系统调用中，用户程序通过参数传递文件名（如 name）。这个 name 存储在用户空间中，当 execve 被调用时，用户空间的 name 需要传递到内核空间中。由于用户空间和内核空间的分离，内核无法直接访问用户空间的内存。如果内核代码试图直接访问用户空间的数据（例如直接使用 name），就可能会引发访问冲突，导致段错误（Segmentation Fault）。

3.set_proc_name 和内核空间的处理：
set_proc_name 是一个内核函数，用于设置进程的名字。在调用 set_proc_name 时，它通常期望一个在内核空间中的字符串（例如，进程名称），而 name 是在用户空间中的字符串。如果我们直接传递 name 给 set_proc_name(current, name)，内核代码将尝试访问用户空间的 name，这在很多操作系统中是不允许的。

4.使用内核空间的本地变量 local_name：
为了避免直接访问用户空间，内核通常会在内核空间中创建一个本地的缓冲区（如 local_name），并将用户空间的字符串复制到这个缓冲区中。这样，内核函数就可以安全地操作内核空间的 local_name，而不是直接访问用户空间的 name。这种方式遵循了内核和用户空间的隔离原则，避免了可能的内存访问冲突。

load_icode函数的主要工作就是给用户进程建立一个能够让用户进程正常运行的用户环境。

```C
/* load_icode - load the content of binary program(ELF format) as the new content of current process
 * @binary:  the memory addr of the content of binary program
 * @size:  the size of the content of binary program
 */
static int
load_icode(unsigned char *binary, size_t size) {
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    //(1) create a new mm for current process
    // 为当前进程创建一个新的mm结构
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    //(2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
    // 为mm分配并设置一个新的页目录表
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    //(3) copy TEXT/DATA section, build BSS parts in binary to memory space of process
    // 从进程的二进制数据空间中分配内存，复制出对应的代码/数据段，建立BSS部分
    struct Page *page;
    //(3.1) get the file header of the bianry program (ELF format)
    // 从二进制程序中得到ELF格式的文件头(二进制程序数据的最开头的一部分是elf文件头,以elfhdr指针的形式将其映射、提取出来)
    struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    // 找到并映射出binary中程序段头的入口起始位置
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    // 根据elf的e_magic，判断其是否是一个合法的ELF文件
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    uint32_t vm_flags, perm;
    struct proghdr *ph_end = ph + elf->e_phnum;
    // 找到并映射出binary中程序段头的入口截止位置
    for (; ph < ph_end; ph ++) {// 遍历每一个程序段头
    //(3.4) find every program section headers
        if (ph->p_type != ELF_PT_LOAD) {
            continue ;// 如果不是需要加载的段，直接跳过
        }
        // 如果文件头标明的文件段大小大于所占用的内存大小(memsz可能包括了BSS，所以这是错误的程序段头)
        if (ph->p_filesz > ph->p_memsz) {
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        if (ph->p_filesz == 0) {// 文件段大小为0，直接跳过
            // continue ;
        }
    //(3.5) call mm_map fun to setup the new vma ( ph->p_va, ph->p_memsz)
    // vm_flags => VMA段的权限
    // perm => 对应物理页的权限(因为是用户程序，所以设置为PTE_U用户态)
        vm_flags = 0, perm = PTE_U | PTE_V;
        // 根据文件头中的配置，设置VMA段的权限
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
        // modify the perm bits here for RISC-V
        // 设置程序段所包含的物理页的权限
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;
        // 在mm中建立ph->p_va到ph->va+ph->p_memsz的合法虚拟地址空间段
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
            goto bad_cleanup_mmap;
        }
        unsigned char *from = binary + ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

     //(3.6) alloc memory, and  copy the contents of every program section (from, from+end) to process's memory (la, la+end)
        end = ph->p_va + ph->p_filesz;
     //(3.6.1) copy TEXT/DATA section of bianry program
     // 上面建立了合法的虚拟地址段，现在为这个虚拟地址段分配实际的物理内存页
        while (start < end) {// 分配一个内存页，建立la对应页的虚实映射关系
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            // 根据elf中程序头的设置，将binary中的对应数据复制到新分配的物理页中
            memcpy(page2kva(page) + off, from, size);
            start += size, from += size;
        }

      //(3.6.2) build BSS section of binary program
      // 设置当前程序段的BSS段
        end = ph->p_va + ph->p_memsz;
        // start < la代表BSS段存在，且最后一个物理页没有被填满。剩下空间作为BSS段
        if (start < la) {
            /* ph->p_memsz == ph->p_filesz */
            if (start == end) {
                continue ;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            // 将BSS段所属的部分格式化清零
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        // start < end代表还需要为BSS段分配更多的物理空间
        while (start < end) {
        // 为BSS段分配更多的物理页
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }
    //(4) build user stack memory
    // 建立用户栈空间
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    // 为用户栈设置对应的合法虚拟内存空间
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
    
    //(5) set current process's mm, sr3, and set CR3 reg = physical addr of Page Directory
    mm_count_inc(mm);// 当前mm被线程引用次数+1
    current->mm = mm;// 设置当前线程的mm
    current->cr3 = PADDR(mm->pgdir);// 设置当前线程的cr3
    lcr3(PADDR(mm->pgdir));// 将指定的页表地址mm->pgdir，加载进cr3寄存器

    //(6) setup trapframe for user environment
    // 设置用户环境下的中断栈帧
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 YOUR CODE
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */
    tf->gpr.sp=USTACKTOP;// 设置用户态的栈顶指针
    tf->epc = elf->e_entry;//epc指向ELF可执行文件加载到内存之后的入口处
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}
```
我简单来叙述一下这个长函数的步骤：

1. 检查当前进程的内存管理结构：
  首先检查当前进程的内存管理结构（mm）是否为空。如果不为空，则会触发错误，表示当前进程已在运行，不能加载新程序。
2. 创建新的内存管理结构：
  如果没有问题，接下来为当前进程创建一个新的内存管理结构（mm_struct），并进行初始化。
3. 设置页目录表（Page Directory）：
  为新进程的内存管理结构分配并设置页目录（Page Directory Table，PDT）。页目录表是虚拟内存管理中的关键数据结构，指示如何将虚拟地址映射到物理内存。
4. 读取并检查ELF文件头：
  从传入的二进制文件（ELF格式）中读取文件头，检查其魔术值（e_magic），判断该文件是否为合法的ELF文件。如果文件头不合法，则返回错误。
5. 遍历程序段头并加载程序段：
  获取程序头表，并遍历所有程序段。每个程序段可以有不同的类型，如加载段（ELF_PT_LOAD）和非加载段。对于每个加载段，代码会根据段的虚拟地址和内存大小，分配新的虚拟地址空间，并为该段分配物理内存。
  在分配内存时，程序会设置每个程序段的权限标志（vm_flags）和物理页的权限（perm）。具体权限取决于ELF文件中的标记，例如是否为可读、可写、可执行。
6. 复制程序段内容：
  复制ELF程序段的内容到分配的物理内存中。对于可执行代码和数据段，会将二进制文件中的数据复制到新分配的物理页。对于BSS段（未初始化的全局变量），会将其内容初始化为零。
7. 处理BSS段：
  BSS段是指未初始化的全局变量。在内存中，BSS段通常被填充为零。对于每个需要BSS段的程序，代码会在内存中分配物理页，并将其内容初始化为零。
8. 建立用户栈：
  为用户进程建立用户栈空间。栈空间会被分配并设置为可读、可写且标记为栈区域。此处栈空间从用户虚拟地址空间的顶部（USTACKTOP）开始分配。
9. 设置当前进程的内存管理结构：
  将当前进程的mm指针指向新的内存管理结构，并将cr3寄存器（用于存储页目录的物理地址）设置为新创建的页目录的物理地址。
10. 设置中断处理栈帧（Trapframe）：
  通过设置trapframe结构来准备进程从内核模式切换到用户模式。trapframe保存了当前进程的寄存器状态，包括栈指针（sp）、程序计数器（epc）和状态寄存器（status）。
  其中：
- sp设置为用户栈的顶部（USTACKTOP），即用户栈的初始位置。
- epc设置为ELF文件的入口点地址（e_entry），即程序执行的起始位置。
- status设置为适当的用户模式标志，确保进程能够正确地进入用户模式。
11. 错误处理和清理：
  在加载过程中，若任何一步失败，都会进行相应的清理工作，包括释放已分配的内存、销毁页目录等资源。
    
下面来讲一下我们要填写的部分。
- gpr.sp设置为用户栈的顶部地址。在用户模式下，栈通常从高地址向低地址增长，当新的数据被压入栈时，栈指针（SP）会向下移动（即地址减小）。这里USTACKTOP就是用户栈的顶部地址。
- epc设置为用户程序的入口地址。elf->e_entry 是可执行文件的入口地址，也就是用户程序的起始地址。这里赋值是为了sret返回用户态的时候，处理器将会跳转到用户程序的入口开始执行。

关于sstatus的设置，我们知道在sstatus寄存器中与异常和中断有关的位有SPP、SIE、SPIE，下面依次介绍一下。

**SPP位**
SPP记录的是在进入S-Mode之前处理器的特权级别，为0表示陷阱源自用户模式(U-Mode)，为1表示其他模式。当执行一个陷阱时，SPP会由硬件自动根据当前处理器所处的状态自动设置为0或者1。当执行SRET指令从陷阱中返回时，如果SPP位为0，那么处理器将会返回U-Mode，为1则会返回S-Mode，最后无论如何，SPP都被设置为0。

**SIE位**
SIE位是S-Mode下中断的总开关，就像是一个总电闸。如果SIE位置为0，那么无论在S-Mode下发生什么中断，处理器都不会响应。但是如果当前处理器运行在U-Mode，那么这一位不论是0还是1，S-Mode下的中断都是默认打开的。也就是说在任何时候S-Mode都有权因为自己的中断而抢占位于U-Mode下的处理器，这一点要格外注意。想想定时器中断而导致的CPU调度，事实上这种设计是非常合理的。

所以SIE位是S-Mode下的总开关，而不是任何情况下的总开关，真正完全负责禁用或者启用特定中断的位，都在sie寄存器里呢，下面再详细解释。

**SPIE位**
SPIE位记录的是在进入S-Mode之前S-Mode中断是否开启。当进入陷阱时，硬件会自动将SIE位放置到SPIE位上，相当于起到了记录原先SIE值的作用，并最后将SIE置为0，表明硬件不希望在处理一个陷阱的同时被其他中断所打扰，也就是从硬件的实现逻辑上来说不支持嵌套中断(即便如此，我们还是可以手动打开SIE位以支持嵌套中断)。当使用SRET指令从S-Mode返回时，SPIE的值会重新放置到SIE位上来恢复原先的值，并且将SPIE的值置为1。

总结一下就是：
>spp：中断前系统处于内核态（1）还是用户态（0）
>sie：内核态是否允许中断。对用户态而言，无论 sie 取何值都开启中断。
>spie：中断前是否开中断（用户态中断时可能 sie 为 0）

对spp和spie清零操作的原因（**确保在切换到用户模式时，特权级别被正确设置为用户模式，并且中断被禁用**）。

指导手册也是给了一个解释：
>进行系统调用sys_exec之后，我们在trap返回的时候调用了sret指令，这时只要sstatus寄存器的SPP二进制位为0，就会切换到U mode，但SPP存储的是“进入trap之前来自什么特权级”，也就是说我们这里ebreak之后SPP的数值为1，sret之后会回到S mode在内核态执行用户程序。所以load_icode()函数在构造新进程的时候，会把SSTATUS_SPP设置为0，使得sret的时候能回到U mode。

下面给出和上面有关的硬件处理流程：

* 在中断发生时，系统要切换到内核态。此时，切换前的状态会被保存在 spp 位中（1 表示切换前处于内核态）。同时，切换前是否开中断会被保存在 spie 位中，而 sie 位会被置 0，表示关闭中断。

* 在中断结束，执行 sret 指令时，会根据 spp 位的值决定 sret 执行后是处于内核态还是用户态。与此同时，spie 位的值会被写入 sie 位，而 spie 位置 1。这样，特权状态和中断状态就全部恢复了。

**请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。** 

- 进程创建：首先，操作系统内核会为新创建的用户进程分配必要的资源，包括内存和数据结构。这通常由内核线程initproc来完成。

- 进程调度：进程创建后进入就绪态，等待操作系统的调度。操作系统会通过调度机制，将进程加入到可运行队列中，等待被调度执行。

- 调度与上下文切换：当do_wait函数检测到有子进程可以执行时，会调用schedule函数选择下一个要运行的进程。在schedule中，proc_run函数负责切换当前进程的上下文，更新页表等，以便能够执行目标进程。然后，操作系统会调用switch_to函数完成上下文切换，将CPU的控制权交给新进程。

- 从内核返回用户态：一旦完成上下文切换，操作系统会跳转到forkret函数，这是进程创建和调度的一个回调函数。forkret会进一步调用forkrets函数，将新进程的中断帧放到栈指针中，然后跳转到__trapret。

- 恢复上下文并跳转到用户程序：__trapret函数恢复了所有寄存器的状态，然后通过sret指令跳转到用户进程的入口函数，这个入口函数是kernel_thread_entry，并且在kernel_thread_entry中会跳转到用户程序的起始地址。

- 执行用户程序：此时，用户程序的user_main函数会被执行。在user_main中，程序会打印一些信息（比如进程ID和名字），然后调用kernel_execve来执行应用程序。

- 加载新程序：kernel_execve并没有直接调用do_execve，而是使用了内联汇编（通过ebreak指令）产生一个断点中断，进而转发到syscall系统调用机制。系统调用号SYS_exec告诉操作系统，当前请求是执行一个新的程序。

- 加载程序内容：在sys_exec系统调用中，最终会调用do_execve，其主要任务是检查并准备用户程序的虚拟内存空间，加载应用程序的不同部分（比如.text, .data, .bss等），并初始化BSS区（未初始化的全局变量）为0。它还会分配用户栈内存并设置新的内存管理结构。

- 更新进程信息：do_execve通过load_icode将程序的各个部分加载到内存后，设置新的进程的堆栈、页表、以及程序入口点信息。然后，返回到exception_handler，继续执行kernel_execve_ret，该函数会调整栈指针，复制新的陷阱帧，并跳转到_trapret。

- 恢复到用户态并执行程序：最终，_trapret会恢复之前的中断帧，恢复上下文，并通过sret指令跳转到用户程序的入口地址，也就是程序的第一个指令，从而开始执行新的用户程序。



## 练习2: 父进程复制自己的内存空间给子进程（需要编码） 
创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于`kern/mm/pmm.c`中）实现的，请补充`copy_range`的实现，确保能够正确执行。
请在实验报告中简要说明你的设计实现过程
### 函数设计目的
`copy_range`函数用于在两个进程的页表（`to`和`from`）之间，按页单位复制一个线性地址范围 [`start`, `end`) 的内容。
### 整体实现步骤与思路
#### 参数校验
```
assert(start % PGSIZE == 0 && end % PGSIZE == 0);
assert(USER_ACCESS(start, end));

```
* 确保`start`和`end`是页大小对齐的地址（`PGSIZE`），避免非对齐问题。
* 确保`start`和`end`属于用户空间范围（通过`USER_ACCESS`宏验证）
#### 遍历地址范围
```
do {
    pte_t *ptep = get_pte(from, start, 0), *nptep;
    if (ptep == NULL) {
        start = ROUNDDOWN(start + PTSIZE, PTSIZE);
        continue;
    }
```
* 目的：逐页遍历[`start`,`end`)范围的地址，按页大小（`PGSIZE`）对每个页面内容进行复制。
* 具体步骤：
1. 使用`get_pte(from, start, 0)`检查源页表中对应地址的页表项是否存在。如果`ptep == NULL`，表示整个页表不存在，直接跳过该部分地址范围。
2. 跳过一整个页表大小（`PTSIZE`）的范围，节省效率。
#### 检查源页面有效性
```
if (*ptep & PTE_V) {
    if ((nptep = get_pte(to, start, 1)) == NULL) {
        return -E_NO_MEM;
    }
    uint32_t perm = (*ptep & PTE_USER);
```
* 目的：确保源地址有效且已映射，目标页表项（进程 B）存在（若不存在则创建新页表）。
* 具体步骤：
1. 检查页表项的`PTE_V`位，确认页面有效。
2. 调用`get_pte(to, start, 1)`，在目标页表中为目标地址分配页表项。
#### 分配新页面并复制内容
```
struct Page *page = pte2page(*ptep);
struct Page *npage = alloc_page();
assert(page != NULL);
assert(npage != NULL);
```
* `pte2page(*ptep)`：通过页表项找到源页面的`struct Page`结构。
* `alloc_page()`：为目标地址分配一个新的物理页面（`struct Page`）。如果分配失败，将导致程序`assert`中断运行。
```
void *src_kvaddr = page2kva(page);
void *dst_kvaddr = page2kva(npage);
memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
```
* 内容复制：
1. 使用`page2kva`将源页面和目标页面的物理地址转换为内核虚拟地址，方便直接访问数据。
2. 调用`memcpy`，按页大小（`PGSIZE`）将源页面内容复制到目标页面。
####  插入目标页表
```
ret = page_insert(to, npage, start, perm);
assert(ret == 0);
```
* 逻辑：
1. 使用`page_insert`函数将目标页面插入到目标进程B的页表中，并建立虚拟地址和物理页面的映射关系。
2. 将提取的权限`perm`应用到目标页面。
3. 如果插入失败，程序通过`assert`直接中断运行（实际项目中应有更优雅的错误处理机制）。
#### 更新地址
```
start += PGSIZE;
```
* 遍历完成当前页后，将地址加上页大小，继续处理下一个页面。
#### 整体循环终止
```
} while (start != 0 && start < end);
```
* 逻辑：当`start`达到`end`或出现地址回绕（`start == 0`）时结束循环。

如何设计实现`Copy on Write`机制？给出概要设计，鼓励给出详细设计。
>`Copy-on-write`（简称`COW`）的基本概念是指如果有多个使用者对一个资源A（比如内存块）进行读操作，则每个使用者只需获得一个指向同一个资源A的指针，就可以该资源了。若某使用者需要对这个资源A进行写操作，系统会对该资源进行拷贝操作，从而使得该“写操作”使用者获得一个该资源A的“私有”拷贝—资源B，可对资源B进行写操作。该“写操作”使用者对资源B的改变对于其他的使用者而言是不可见的，因为其他使用者看到的还是资源A。
### 概要设计
#### 基本设计思路
* 共享内存页：多个进程可以共享同一内存页，该内存页为只读。若没有进程需要修改该内存页，则可以保持共享，避免不必要的内存复制。
* 触发复制：当某个进程试图写入共享的内存页时，操作系统检测到写操作，并创建该页的一个副本，并将副本的内容指向该进程。这是“写时复制”的时刻。
* 页表标记：为了确保“写时复制”机制正常工作，操作系统必须在页表项中为每个共享的页面设置一个标记，表明该页是`COW`类型。当进程进行写操作时，操作系统会将该页的权限修改为可写，并在后台创建该页的副本。
#### 实现的关键步骤
##### 1.页表管理
* 在进程的页表中，每个共享的页面都会有一个标记，指示该页是否是`COW`页。例如，设置一个`PTE_COW`位，指示该页是共享的，只在写时复制。
* 页表项在第一次写入时，将其权限从只读（`PTE_RO`）修改为可写（`PTE_W`）。此时，操作系统将创建该页的副本，并将副本映射到该进程。
##### 2.触发写时复制
* 触发条件：当一个进程对一个`COW`页面进行写操作时，操作系统需要通过页表监控检测到写操作。
* 复制操作：操作系统会为该页分配一块新的物理内存，并将原页面内容复制到新的内存页中。
* 页表更新：操作系统更新页表，将新的物理页映射到进程的虚拟地址空间，并更新该页的权限为可写。
* 其他进程共享：其他进程依然保持对原始页面的只读访问，只有写操作的进程获得了副本。
##### 3.进程间共享和隔离
* 共享页面：如果多个进程在读取相同的内存页，操作系统不需要为它们分别分配新的物理页面，而是共享同一块物理内存。
* 私有副本：当某个进程试图修改共享的页面时，操作系统将会为该进程创建该页面的私有副本，从而保证其他进程继续共享原始页面。
##### 4.性能优化
* 延迟复制：`COW`机制的优势在于，只有在进程执行写操作时才会进行复制，从而大大减少了不必要的内存复制。
* 懒复制：`COW`避免了在进程创建时立即进行大量内存复制，而是采取懒复制的策略，直到进程需要修改内存页时，才触发复制。
* 内存合并：如果多个进程都共享相同的内存，并且都没有修改它们的页面，操作系统可以保留对该页面的共享使用，避免重复分配内存。
#### 实现细节
##### 1.进程创建（fork）时的COW
* 当一个进程通过`fork()`系统调用创建子进程时，父进程和子进程会共享同一份物理内存页。此时，它们的页表项会标记为`COW`类型，并且它们的页表项是只读的。
* 当子进程或父进程执行写操作时，会触发页表陷阱，操作系统会复制该页面，并将新的物理页分配给需要写操作的进程。
##### 2.内存访问与写时复制
* 操作系统需要实现一个页表缺页异常（`Page Fault`）处理程序，在检测到某个进程对`COW`页进行写操作时，发生缺页异常，并触发`COW`处理：
（1） 操作系统会分配一个新的页面并复制原页面的内容。
（2）更新页表，将新的物理页面映射到进程的虚拟地址，并设置为可写。
（3）设置`COW`页的标记，以保证其他进程在访问该页时仍然是共享的。
##### 3.页表管理
* `PTE_COW`：在页表中添加一个标志位（如`PTE_COW`），指示该页是否是`COW`页。这个标志会在`fork()`时由操作系统设置。
* `PTE_W`：当页表项标记为`COW`时，系统将该页设置为只读，并在发生写时复制时，更新为可写。


## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码） 

请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：
 - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
### 1.`do_fork`：创建一个新的进程
#### 内核态操作：
* `alloc_proc()`: 创建一个新的`proc_struct`，为新的进程分配内存空间。
* `setup_kstack(proc)`: 为子进程分配内核栈。
* `copy_mm(clone_flags, proc)`: 复制父进程的内存管理信息，除非`CLONE_VM`标志设置，才会共享内存空间。
* `copy_thread(proc, stack, tf)`: 设置子进程的`trapframe`以及栈信息。
* `get_pid()`: 分配一个新的进程`ID`。
* `hash_proc(proc)`: 将子进程添加到进程哈希表中。
* `set_links(proc)`: 设置进程的关系链（例如父子关系）。
* `wakeup_proc(proc)`: 将子进程设置为可运行状态。
#### 用户态操作：
* 用户态程序通过系统调用`fork()`调用`do_fork`。当`do_fork`返回时，父进程得到子进程的`PID`，而子进程会执行`fork()`之后的代码。
#### 内核态与用户态切换：
* 用户程序调用`fork()`时，程序会陷入内核态，执行上述内核函数。
* 在内核完成创建子进程后，它会返回子进程的`PID`给用户程序，进程切换回用户态。

### 2.`do_execve`：加载新程序并替换当前进程的映像
#### 内核态操作：
* `load_icode(binary, size)`: 加载新的程序映像，设置新的内存空间、堆栈、以及进程的代码段、数据段等。
* `exit_mmap(mm)`,`put_pgdir(mm)`,`mm_destroy(mm)`: 如果当前进程有内存映像，则先清理当前进程的内存映像。
* 设置新的`trapframe`，包括用户栈指针、程序入口地址等。
* 设置新的`mm`结构体，包含新程序的内存空间和页表。
#### 用户态操作：
* 用户态程序通过调用`execve()`系统调用进入内核，传递新程序的二进制映像。
* 系统调用完成后，内核加载新程序并替换当前进程的映像。
#### 内核态与用户态切换：
* 用户程序通过`execve()`进入内核，执行`load_icode`等内核操作，最终完成程序替换。
* 内核完成后，通过`trapframe`设置，用户程序将会从新程序的入口点开始执行（返回用户态）。

### 3.`do_wait`：等待子进程结束
#### 内核态操作：
* `find_proc(pid)`: 查找指定`PID`的子进程。
* 判断子进程的状态，如果是`PROC_ZOMBIE`，则处理它。
* `wakeup_proc(proc)`: 唤醒父进程，通知它子进程已经结束。
* `unhash_proc(proc)`,`remove_links(proc)`: 从哈希表和进程链表中移除子进程。
* 释放子进程的内存，调用`put_kstack(proc)`和`kfree(proc)`来释放资源。
#### 用户态操作：
* 用户通过`waitpid()`系统调用请求等待一个子进程结束，进入内核执行`do_wait`。
* 在子进程结束前，父进程会被挂起（`PROC_SLEEPING`状态），直到子进程的状态变为`PROC_ZOMBIE`。
* 子进程结束时，返回子进程的退出状态给父进程。
#### 内核态与用户态切换：
* 用户程序调用`waitpid()`后进入内核，内核处理等待的逻辑，并在子进程退出时通知父进程。
* 父进程如果没有子进程结束，会进入睡眠状态，直到子进程退出时再恢复执行。

### 4.`do_exit`：退出当前进程
#### 内核态操作：
* `exit_mmap(mm)`,`put_pgdir(mm)`,`mm_destroy(mm)`: 释放当前进程的内存映像。
* 设置当前进程的状态为`PROC_ZOMBIE`，并将退出码保存到`exit_code`。
* 如果当前进程有子进程，则通知父进程进行回收。
通过`schedule()`切换到其他进程，进行进程调度。
#### 用户态操作：
* 用户程序调用`exit()`系统调用时，进入内核执行`do_exit`。
* 内核清理资源并将当前进程标记为僵尸进程，父进程将会回收它。
* 最终，内核会进行调度，切换到另一个进程执行。
#### 内核态与用户态切换：
* 用户程序调用`exit()`后，进入内核执行清理操作。
* 内核完成进程的退出和资源回收后，返回调度器进行进程切换，最终返回用户程序（如果有的话）。

### 总结
* 用户态操作主要集中在系统调用的发起上（例如`fork()`、`execve()`、`waitpid()`、`exit()`）。这些调用会触发从用户态到内核态的切换，进入内核执行相应的操作。
* 内核态操作执行系统调用的具体功能，涉及进程的创建、内存管理、进程调度等核心操作，通常会修改进程的状态、内存映像以及进程控制块（`PCB`）等。
* 用户态和内核态通过系统调用进行交替，系统调用完成时，内核态的操作将影响用户程序的执行，比如返回一个新的进程`ID`或新的程序映像，并继续执行用户程序。




## 扩展练习 Challenge
1. 实现 Copy on Write  （COW）机制 

    给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

    这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

    由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/  看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

    这是一个big challenge.

2. 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？


