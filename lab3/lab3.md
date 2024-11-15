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



