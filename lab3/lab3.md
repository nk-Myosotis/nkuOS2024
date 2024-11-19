### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

##### 1.页面换入
>（1）`_fifo_init_mm`  
作用: 初始化`FIFO`队列 (`pra_list_head`)，将该队列的地址保存到`mm_struct`中的`sm_priv`字段。  
（2）`_fifo_map_swappable`  
作用: 将页面加入到队列的末尾，表示是一个新的可以交换的页面。调用`list_add`把页面加入链表中，将页面标记为可交换，并将其插入到`FIFO`队列中。  
（3）`list_init`  
作用：初始化链表，确保链表为空。  
（4）`swap_in`  
作用：当页面缺失且需要从磁盘加载时，`swap_in`会被调用，将页面从磁盘的交换空间加载到物理内存中。  
（5）`page_insert`  
作用：当一个页面被加载到物理内存后，调用`page_insert`将该页面插入到页表中，建立虚拟地址到物理地址的映射。  

##### 2.页面换出
>（6）`_fifo_swap_out_victim`  
作用: 从`FIFO`队列中选择并删除最早到达的页面，并将其传递给`ptr_page`，表示这个页面将被置换出去。  
（7）`free_page`  
作用：当页面被换出时，`free_page`会释放不再需要的物理页面。释放后将其标记为可用。  
（8）`page_remove`  
作用：当一个页面需要被换出时，解除虚拟地址与物理地址的映射。移除后标记该物理页面为不再使用。  
（9）`list_del`  
作用：从链表中删除指定节点，释放页面。  

##### 3.辅助
>（10）`_fifo_check_swap`  
作用: 主要用于模拟页面的访问，并检查页面缺页异常（`pgfault_num`）的数量。  
（11）`assert`  
作用：断言检查，确保某些条件成立，否则程序会终止。  

#### 练习2：深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
 - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

##### 问题解答
##### 关于两段相似代码的分析
 
###### 代码功能概述
这两段代码的功能都是查询页目录获取下一级页表地址，其逻辑功能相似，代码内容当然相似。sv32、sv39、sv48甚至没应用的sv57，只不过是页表级数的问题而已，分别对应两级、三级、四级、五级页表。本次实验采用的是sv39，有2层页目录，因此有两段相关代码；相似的，sv32仅需要一段即可，sv48则需要3段。
 
###### 页表项的查找与分配
感觉没什么问题，一般而言，我们要查询页表，都是意味着我们需要这个页，而不是说检查它是否有效。所以一般情况下，查询即意味着要分配。可能有没注意到的其它应用方式，不过，`get_pte`函数也有一个`create`参数，如果将这个参数设置为0，则不会创建。
 
##### 代码实现详细解析
 
###### pte与pde
- pte（Page Table Entry）：页表项。
- pde（Page Directory Entry）：页目录项。
- 在RISC-V中，pde和pte在概念上可能有所重叠，特别是在使用大大页或大页时。
- `pte_t`和`pde_t`都是`uintptr_t`的重定义，后者是`uint_t`（根据系统位数定义）的重定义。这种类型定义便于指针和整数之间的转换，解决了不同位数系统的兼容性问题。
```C
#if __riscv_xlen == 64
  typedef uint64_t uint_t;
#elif __riscv_xlen == 32
  typedef uint32_t uint_t;

typedef uint_t uintptr_t;

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;
```

 
###### pgdir
- `pgdir`代表大大页的地址，通常由stap寄存器传递（如`mm->pgdir`）。
- 通过移位和按位与操作，可以从线性虚拟地址（la）中提取出页目录索引（PDX1、PDX0）和页表索引（PTX）。
```C
// +--------9-------+-------9--------+-------9--------+---------12----------+
// | Page Directory | Page Directory |   Page Table   | Offset within Page  |
// |     Index 1    |    Index 2     |                |                     |
// +----------------+----------------+----------------+---------------------+
//  \-- PDX1(la) --/ \-- PDX0(la) --/ \--- PTX(la) --/ \---- PGOFF(la) ----/
//  \-------------------PPN(la)----------------------/

#define PTXSHIFT        12                      // offset of PTX in a linear address
#define PDX0SHIFT       21                      // offset of PDX0 in a linear address
#define PDX1SHIFT       30                      // offset of PDX0 in a linear address

#define PDX1(la) ((((uintptr_t)(la)) >> PDX1SHIFT) & 0x1FF)
#define PDX0(la) ((((uintptr_t)(la)) >> PDX0SHIFT) & 0x1FF)
#define PTX(la) ((((uintptr_t)(la)) >> PTXSHIFT) & 0x1FF)

pde_t *pdep1 = &pgdir[PDX1(la)];
```
 

##### 两段相似代码的逻辑
 
1. **检查页表项的有效性**
   - 如果页表项有效，则将其转换为物理地址（通过清空低10位并左移特定位数）。
```C
#define PTE_ADDR(pte)   (((uintptr_t)(pte) & ~0x3FF) << (PTXSHIFT - PTE_PPN_SHIFT))
#define PDE_ADDR(pde)   PTE_ADDR(pde)
pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
```

2. **页表项无效时的处理**
   - 如果页表项无效且`create`标志为true，则分配一个新页，初始化该页面，并更新页表项。
   - 分配页的过程包括调用`alloc_page`（页面分配算法），设置引用位，获取物理地址，并清空页空间。
```C
if (!(*pdep1 & PTE_V)) {                    //invalid page
    struct Page *page;
    if (!create || (page = alloc_page()) == NULL) {    //we can't get a page, this alloc_page means get 1 page
        return NULL;
    }
    set_page_ref(page, 1);
    uintptr_t pa = page2pa(page);
    memset(KADDR(pa), 0, PGSIZE);
    *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); //user can use
}
```

3. **更新页表项**
   - 使用`page2ppn`将页面结构体指针转换为物理页号（ppn），并通过`pte_create`函数创建新的页表项。
`page2ppn`可以将一个`page`结构体的指针，转为`ppn_t`类型，具体方式就是用这个`page`指针，减去page结构体的起始指针`pages`，得到其相对与`pages`的页号，但是`pages`对应的物理地址是0x80000000，因此还需要加上0x80000才能得到其真实的物理页号。`pte_create`将得到的物理页号左移10位(并置位)，这样就能够得到一个新的页表项。

```C
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
*pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
```

##### 直接使用大大页和大页的情况
如果直接使用大大页或大页作为分配的空间，而非页表目录，则上述代码将不再适用。此时，只能分配一个页面并进行初始化，且无需检查PTR_X和PTR_R位（因为这两个位在这种情况下可能不适用）。

#### 练习3：给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
 - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

##### 设计实现过程
在`do_pgfault`函数中需要补充代码的部分主要是交换页面的加载和页面映射。
```
swap_in(mm, addr, &page);
page_insert(mm->pgdir, page, addr, perm); 
swap_map_swappable(mm, addr, page, 1);
```
首先从交换空间加载页面，`swap_in(mm, addr, &page)`从交换空间（磁盘）加载与虚拟地址`addr`对应的页面。交换空间用于存储从物理内存中换出的页面，`swap_in`会根据`addr`获取对应的页面，将它加载到物理内存中，并将该页面的指针赋值给`page`。
接着将页面映射到虚拟地址，`page_insert`将加载到内存中的物理页面`page`与虚拟地址`addr`建立映射。`perm`是该页面的权限，控制是否可读、可写等。这个操作会更新页表，使得进程可以通过虚拟地址`addr`访问到物理页面`page`。
最后标记页面为可交换，`swap_map_swappable`将页面`page`标记为“可交换”的状态。意味着这个页面可以再次被交换到磁盘（如果内存压力增大，系统需要腾出空间）。

##### 问题回答
1.请描述页目录项（`Page Directory Entry`）和页表项（`Page Table Entry`）中组成部分对`ucore`实现页替换算法的潜在用处。
* `PDE`的有效位和`PTE`的有效位决定了一个虚拟地址是否已经映射到物理内存。如果页目录项或者页表项无效，表示该虚拟地址没有有效的物理内存映射。在实现页替换算法时，可以通过检查这些标志位来确定哪些页面不再使用，或者哪些页面需要被替换。在页面置换时，操作系统可以通过检查这些标志位，快速判断哪些页面是有效的，哪些页面可以被换出。如果页面的有效位为0，说明该页面不在内存中，可以通过置换将其加载进来。
* 页目录项和页表项中的权限位（`PTE_U`和`PTE_W`） 控制了页面的访问权限，决定了页面是否可读、可写以及是否可由用户访问。操作系统在进行页替换时，可能需要考虑页面的访问权限。在页替换算法中，操作系统可能会优先选择可写（`PTE_W`）的页面进行置换，或者根据`PTE_U`判断是否允许用户进程访问该页面。如果页面是只读的或具有高优先级的访问权限（如代码页面），则可能不容易被替换。在某些实现中，脏页标志（可能存在于`PTE`）表示页面自上次交换以来是否被修改，操作系统在选择置换页面时会考虑这一点，以确保写入过的页面被正确地保存回磁盘。
* 页表项中的引用位（通常在访问页面时被设置为1，在页替换算法中，系统可以通过检查引用位来判断页面是否近期被访问过）和脏页标志（表示页面自上次被换出以来是否被修改，操作系统需要在换出页面时检查这个标志，如果页面是脏的，则需要将其内容保存回磁盘）对实现页替换算法非常重要。现代的操作系统会使用`LRU`（最近最少使用）或`CLOCK`算法来进行页面置换，这些算法通常会根据页面的访问历史来决定哪些页面应该被换出。

2.如果`ucore`的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
* 中断处理：硬件会生成一个中断，将控制权交给操作系统。
* 保存状态：硬件会保存当前的处理器状态，包括程序计数器（PC）、寄存器状态等。
* 传递错误码：硬件会将错误码传递给操作系统。
* 传递故障地址：硬件会将引起页故障的虚拟地址传递给操作系统。
* 中断向量表：硬件会根据中断类型跳转到相应的中断处理程序。
  
3.数据结构`Page`的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？  
在`ucore`操作系统中，`Page`是用于管理物理内存页面的数据结构。每个`Page`对象代表物理内存中的一页，`Page`数组则是一个全局变量，表示整个物理内存中的所有页面。而页目录项（`PDE`）和页表项（`PTE`）则是虚拟内存到物理内存的映射的关键结构，它们用于管理虚拟地址与物理内存之间的映射关系。
* `Page`结构：每个`Page`结构表示一个物理页面，包含页面的各种属性和状态信息。
* 页表项（`PTE`）：每个`PTE`包含一个物理页面的地址和其他属性（如存在位、读写位等）。
* 对应关系：每个`Page`结构可以通过其物理地址与页表项中的物理地址字段对应。具体来说，`Page`结构中的物理地址可以通过`page2pa`函数转换为物理地址，而页表项中的物理地址可以通过`PTE_ADDR`宏提取出来。两者通过物理地址建立对应关系。

#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

实验指导手册中的介绍：
>时钟（Clock）页替换算法：是 LRU 算法的一种近似实现。时钟页替换算法把各个页面组织成环形链表的形式，类似于一个钟的表面。然后把一个指针（简称当前指针）指向最老的那个页面，即最先进来的那个页面。另外，时钟算法需要在页表项（PTE）中设置了一位访问位来表示此页表项对应的页当前是否被访问过。当该页被访问时，CPU 中的 MMU 硬件将把访问位置“1”。当操作系统需要淘汰页时，对当前指针指向的页所对应的页表项进行查询，如果访问位为“0”，则淘汰该页，如果该页被写过，则还要把它换出到硬盘上；如果访问位为“1”，则将该页表项的此位置“0”，继续访问下一个页。该算法近似地体现了 LRU 的思想，且易于实现，开销少，需要硬件支持来设置访问位。时钟页替换算法在本质上与 FIFO 算法是类似的，不同之处是在时钟页替换算法中跳过了访问位为 1 的页。

下面是这次实验的代码的分析。

init_mm函数是初始化函数，初始化 pra_list_head 并让 mm->sm_priv 指向 pra_list_head 的地址，现在我们就可以用mm_struct进行访问这个队列，具体定义的队列指针在Page结构体里。

map_swappable用于记录页访问情况相关属性，和FIFO一样的是，首先我们应该将最近到达的页面链接到 pra_list_head 队列的末尾。和FIFO不一样的是，我们要将页面的visited标志置为1，表示该页面已被访问。

swap_out_victim其实就是我们的换出函数，他要实现挑选需要换出的页。首先要获取当前页面对应的Page结构指针，赋初值是头指针前一个也就是最早的那个。现在我们就要根据这个物理页的visited位来进行判断，如果是1就置0，如果是0，我们就把他删去并把指针赋值给ptr_page作为换出页面，这里就想一个钟面，一直去循环这个过程，直到找到一个合适的换出页面。
```C
/*
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_clock_init_mm(struct mm_struct *mm)
{     /*LAB3 EXERCISE 4: 2212880*/
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     list_init(&pra_list_head);
     curr_ptr = &pra_list_head;
     mm->sm_priv = &pra_list_head;
     cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: 2212880*/
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问
    list_add(&pra_list_head, entry);
    page->visited=1;
    cprintf("curr_ptr %p\n", curr_ptr);
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    /*LAB3 EXERCISE 4: 2212880*/
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
    curr_ptr = head;
    while (1) {
        curr_ptr = list_prev(curr_ptr);
        if (!curr_ptr) {
            break;  // 如果没有找到前一个节点，跳出循环
        }
        struct Page *p = le2page(curr_ptr, pra_page_link);
        if (p->visited == 0) {
            list_del(curr_ptr);
            *ptr_page = le2page(curr_ptr, pra_page_link);
            break;  // 找到未访问的页面并删除，跳出循环
        } else {
            p->visited = 0;  // 标记页面为未访问
        }
    }
    return 0;
}
```
 - 比较Clock页替换算法和FIFO算法的不同。
Clock页替换算法和FIFO页替换算法主要不同在于前者在决定替换页面前会检查页面的使用情况，通过使用位来减少不必要的替换，从而提升整体性能；而后者则是简单地按照页面进入内存的顺序进行替换，不考虑页面使用频率，虽然实现简单但可能导致更高的页面故障率（Belady's Anomaly）。Clock算法结合了FIFO算法的简单性和LRU（Least Recently Used）算法的有效性，尽管实现上稍微复杂一些。

> Belady现象
>> 采用FIFO等算法时，可能出现分配的物理页面数增加，缺页次数反而升高的异常情况
>>* FIFO算法的置换特征与进程访问内存的动态特征矛盾
>>* 被置换出去的页面并不一定是进程近期不会访问的。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。



