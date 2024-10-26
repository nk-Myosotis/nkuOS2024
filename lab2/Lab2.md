### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

#### 练习0：填写已有实验

本实验依赖实验1。请把你做的实验1的代码填入本实验中代码中有“LAB1”的注释相应部分并按照实验手册进行进一步的修改。具体来说，就是跟着实验手册的教程一步步做，然后完成教程后继续完成完成exercise部分的剩余练习。

#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
- 你的first fit算法是否有进一步的改进空间？

### First-fit
##### init：初始化函数
###### defualt_init:初始化内存管理模块
list_init($free_list)初始化自由链表，向链表互相指，置为空
nr_free=0空闲页面数目置为0

###### page_init: 初始化物理内存的映射，设置一块可用内存。

可用空间0x8000 0000到0x88000000为128MiB空间。考虑到其中的OpensBl占用了0x8000 0000到0x80200000的空间，而kernel占用了0x80200000到end(在链接脚本中定义)的空间，也就是说，实际上我们能用来存东西的空间是从end到0x8800 0000。

具体来说，page_init分配了512M个page结构体，一个page4KB，连续分布因为一个page就代表了一个物理页。

接着，将我们存有`page`的空间置为保留，这部分不能给用户使用，用于页面状态等记录，然后对于剩下的空间，我们进行init_memmap.

###### init_memmap: 初始化内存映射
第一个page作为首页”链入free_list即可，page的property属性被置为它管理的页面数量n，而其它的page的property属性均为0。

每个page的flag属性表示是否空闲，所以每次进入free list的块中的所有页，要把flag置位SETPROPERTY，反之，则需要清位CLEARPROPERTY。

如果空闲链表为空，直接将base添加到链表中，反之遍历链表找到合适位置插入base

#### alloc and free: 分配界面
	free_list用以管理空闲块,分配的时候摘取free list中的一块;回收的时候，我们需要把一个块重新放回到free list里边。对于first fit算法，其实就是每次选择free_list中的第一个大小合适的块分配，在回收的时候，也按照地址顺序回收。
	具体而言，分配时遍历可用页面，寻找第一个可用的页面，如果找到了删除该页面链表节点，如改页面管理数目大于n则分为两部分，一部分减去n生成新页面，最后更新可用页面数量。
	释放时，重置页面状态，使其管理页面数变为n，更新可用页面数量。为了减轻这个问题，我们有必要将回收的地址连续的块合并在一起。

#### 关于优化的思考
##### 关于空间的优化
first fit算法最大的弊端就是在一系列反复的“分配-释放”之后，内存空间会变得零碎(即使有合并)。如何解决这个问题呢？
可以采用“内存紧凑”的方法，就是每隔一段时间，把不连续的内存重新分配一下；但显然这样的弊端也很明显，先不谈按怎样的方式才能排得紧凑，但是内存的I/O就开销巨大(当然可以在进程sleep的时候去挪动)，究竟合不合算也不清楚。

其次就是考虑“动态分配”的方式，就是检查局部内存利用率，然后对于利用率低的部分，将空闲的块进行强制合并。

挑战 :
	实现页面的连续分配需要设计一个链表结构来链接不同区域的内存块。
	在内存回收阶段，清晰地梳理和归还这些“东拼西凑”的空间是复杂的，需多次检查相邻空间。

最后，应该可以利用缓存的思想，比如内存池，可能有助于提高内存管理的效率。

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。
请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放，并回答如下问题：
- 你的 Best-Fit 算法是否有进一步的改进空间？
  
##### 设计与实现过程
首先理解`best_fit`核心思想为，接收到内存分配请求时，遍历空闲块列表，找出大小最相近且足够容纳的空闲块进行分配。`Best-Fit`相比于`First-Fit`算法更擅长减少碎片化，但查找过程较慢，因为它需要遍历整个列表。

###### 页面分配
`best_fit_alloc_pages`的作用是从空闲页面链表中找到一个大小最接近且足够大的块来满足分配请求。该块如果比所需页面数多，会进行拆分，将剩余部分保留在空闲链表中。
```
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: 2213247*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while((le = list_next(le)) != &free_list){
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) 
        {
            page = p;
            min_size = p->property;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) 
        {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}
``` 
函数首先使用`assert(n > 0)`确保请求的页面数`n`大于`0`，表示这是一个有效的请求。如果系统中空闲页面总数不足，则返回`NULL`。接着通过`while`循环遍历整个空闲链表`free_list`，检查每个空闲块的`property`值，判断它是否能够满足请求页面数`n`。具体来说，条件`p->property >=n`确保当前空闲块的大小至少能满足请求，`p->property < min_size `确保当前找到的块比之前找到的最小块更合适。遍历过程中`page`会更新为最合适的空闲块，`min_size`记录该块的大小。
如果找到最合适的块`page`，则从链表中移除该块。如果该块比请求的页面数多（即`p->property > n`），则将多余的页面拆分成一个新的块，并将其重新插入到空闲链表中。拆分后的块的大小为原块大小减去请求页面数`n`。最后，减少全局变量`nr_free`中的空闲页面数，并清除分配块的 `PG_property`标志，标志它已经被分配。然后返回找到并分配的`Page`块。

###### 页面释放
`best_fit_free_pages`函数的作用是释放从`base`开始的`n`个连续页面，并将它们重新插入到空闲链表`free_list`中。函数还会尝试将相邻的空闲块进行合并，减少内存碎片。
```
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: 2213247*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: 2213247*/ 
         // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        if(p + p->property == base)
        {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```
首先检查释放的页面数是否大于0，确保这是一个有效的操作。然后遍历每个页面，检查它们是否可以安全释放。通过`assert(!PageReserved(p) && !PageProperty(p))`，确保页面没有被保留并且不是空闲块。释放的页面的标志位被清除，引用计数重置。将`base->property`设置为`n`，表示从`base`开始的连续`n`个页面是一个新的空闲块，并通过`SetPageProperty`标记这个块为可用。然后将`nr_free`加上`n`，更新系统中的空闲页面总数。接着检查空闲链表`free_list`是否为空。如果空链表为空，直接将新的空闲块插入链表；否则，遍历链表找到合适的位置插入新块，保证链表保持按地址有序的状态。
检查当前块的前一个块`p`是否与`base`相邻。如果前一个块的结束地址与当前块的起始地址相同，则将它们合并为一个更大的块。 与后面块合并：同样检查当前块的后一个块 `p`，如果当前块的结束地址与后一个块的起始地址相邻，也可以合并。如果发生合并，合并后的块将被更新为新的空闲块，原来的块则从链表中移除。

##### 改进空间
###### 查找效率
对于一些规模较大的系统，查找开销大。可以使用一些更为高效的数据结构，提高分配效率。
###### 碎片整理
尽管best_fit可以减少碎片化，但仍会存在一些较小的、不好利用的碎片。可以进一步升级内存整理机制。

#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

 -  参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

在无法提前获取当前硬件的可用物理内存范围的情况下，操作系统可以通过以下方法获取可用的物理内存范围：

1. **BIOS/UEFI**：操作系统可以通过与计算机的基本输入/输出系统（BIOS）或统一的扩展固件接口（UEFI）进行通信，以获取关于硬件配置和内存布局的信息。BIOS/UEFI通常提供了访问内存映射表（Memory Mapping Table）或其他相关数据结构的接口。

2. **物理内存管理单元**（Memory Management Unit，**MMU**）：操作系统可以通过与MMU进行交互，获取有关物理内存的信息。由于MMU负责将虚拟内存地址转换为物理内存地址，并维护页面表（Page Table）或其他数据结构来跟踪内存分页情况，所以操作系统可以通过访问MMU的相关数据结构，从而获取可用的物理内存范围。

3. **物理内存映射文件**（Physical Memory Mapping File）：操作系统可以通过创建一个特殊的文件，将物理内存映射到该文件中。然后，操作系统可以读取该文件的内容以获取有关物理内存范围的信息。这种方法常用于调试和诊断目的，需要特权级的访问权限。

> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。
