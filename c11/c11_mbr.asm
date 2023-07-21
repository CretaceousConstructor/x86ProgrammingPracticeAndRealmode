         ;代码清单11-1
         ;文件名：c11_mbr.asm
         ;文件说明：硬盘主引导扇区代码 
         ;创建日期：2011-5-16 19:54

         ;设置堆栈段和栈指针 
         ;主引导扇区地址所在：内存地址 0x0000:0x7c00，此时ax内容为0x0000，cs内容0x0000
         mov ax,cs      
         mov ss,ax
         mov sp,0x7c00
      
         ;计算GDT所在的逻辑段地址 
         ;由于没有指定文件起始的地址，gdt_base代表的地址是相对于 默认文件开头地址0的；
         ;gdt_base         dd 0x00007e00     ;GDT的物理地址 
         ;ax中就是 0x7e00
         ;dx中就是 0x0000
         mov ax,[cs:gdt_base+0x7c00]        ;低16位 
         mov dx,[cs:gdt_base+0x7c00+0x02]   ;高16位 

         ;16位模式下地址的计算方法：段地址左移4位（乘以16） + 偏移地址
         ;因为 16 位的处理器无法直接提供 32 位的被除数，故要求被除数的高 16 位在DX 中，低 16 位在 AX 中。
         ;除数可以由 16 位的通用寄存器或者内存单元提供，指令执行后，商在 AX 中，余数在DX 中。

         mov bx,16        
         div bx            
         ;除法执行后：AX存有商：  0x07e0
         ;除法执行后：DX存有余数：0x0000
         mov ds,ax                          ;令DS指向该段以进行操作:商在 AX 中
         mov bx,dx                          ;段内起始偏移地址;     余数在DX 
      
         ;创建0#描述符，它是空描述符，这是处理器的要求
         mov dword [bx+0x00],0x00
         mov dword [bx+0x04],0x00  

         ;创建#1描述符，保护模式下的代码段描述符
         mov dword [bx+0x08],0x7c0001ff     
         mov dword [bx+0x0c],0x00409800     

         ;创建#2描述符，保护模式下的数据段描述符（文本模式下的显示缓冲区） 
         mov dword [bx+0x10],0x8000ffff     
         mov dword [bx+0x14],0x0040920b     

         ;创建#3描述符，保护模式下的堆栈段描述符
         mov dword [bx+0x18],0x00007a00
         mov dword [bx+0x1c],0x00409600

         ;初始化描述符表寄存器GDTR
         mov word [cs: gdt_size+0x7c00],31  ;描述符表的界限（总字节数减一，目前只安装了4个，4*8 = 32）   
         lgdt [cs: gdt_size+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;保护模式下中断机制尚未建立，应立刻禁止中断
                                            ;禁止中断 
         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位，开启保护模式
      
         ;以下进入保护模式，但是cs高速缓冲中存的内容其 D 位是“0”，因此，在这时刻，处理器运行在 16 位保护模式下。
         jmp dword 0x0008:flush             ;16位的描述符选择子：32位偏移
                                            ;清流水线并串行化处理器 
         [bits 32] 

    flush:
         mov cx,00000000000_10_000B         ;加载数据段选择子(0x10)
         mov ds,cx                          ;自动加载描述符高速缓存器的内容。

         ;以下在屏幕上显示"Protect mode OK." 
         mov byte [0x00],'P'  
         mov byte [0x02],'r'
         mov byte [0x04],'o'
         mov byte [0x06],'t'
         mov byte [0x08],'e'
         mov byte [0x0a],'c'
         mov byte [0x0c],'t'
         mov byte [0x0e],' '
         mov byte [0x10],'m'
         mov byte [0x12],'o'
         mov byte [0x14],'d'
         mov byte [0x16],'e'
         mov byte [0x18],' '
         mov byte [0x1a],'O'
         mov byte [0x1c],'K'

         ;以下用简单的示例来帮助阐述32位保护模式下的堆栈操作 
         mov cx,00000000000_11_000B         ;加载堆栈段选择子
         mov ss,cx
         mov esp,0x7c00

         mov ebp,esp                        ;保存堆栈指针 
         push byte '.'                      ;压入立即数（字节）
         
         sub ebp,4
         cmp ebp,esp                        ;判断压入立即数时，ESP是否减4 
         jnz ghalt                          
         pop eax
         mov [0x1e],al                      ;显示句点 
      
  ghalt:     
         hlt                                ;已经禁止中断，将不会被唤醒 

;-------------------------------------------------------------------------------
     
         gdt_size         dw 0              ;0000 0000 0000 0000B 一共16bits,全局描述符表边界
         gdt_base         dd 0x00007e00     ;一共32bits         GDT的物理地址 全局描述符表基址
                             
         times 510-($-$$) db 0
                          db 0x55,0xaa