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

创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。

请在实验报告中简要说明你的设计实现过程。



## 练习3: 阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码） 

请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：
 - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？



## 扩展练习 Challenge
1. 实现 Copy on Write  （COW）机制 

    给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

    这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

    由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/  看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

    这是一个big challenge.

2. 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

