         ;代码清单13-2
         ;文件名：c13_core.asm
         ;文件说明：保护模式微型核心程序 
         ;创建日期：2011-10-26 12:11

         ;以下常量定义部分。内核的大部分内容都应当固定 
         core_code_seg_sel     equ  0x38    ;内核代码段选择子 
         core_data_seg_sel     equ  0x30    ;内核数据段选择子 
         sys_routine_seg_sel   equ  0x28    ;系统公共例程代码段的选择子 
         video_ram_seg_sel     equ  0x20    ;视频显示缓冲区的段选择子
         core_stack_seg_sel    equ  0x18    ;内核堆栈段选择子
         mem_0_4_gb_seg_sel    equ  0x08    ;整个0-4GB内存的段的选择子

;-------------------------------------------------------------------------------
         ;以下是系统核心的头部，用于加载核心程序 
         core_length      dd core_end       ;核心程序总长度#00

         sys_routine_seg  dd section.sys_routine.start
                                            ;系统公用例程段位置#04

         core_data_seg    dd section.core_data.start
                                            ;核心数据段位置#08

         core_code_seg    dd section.core_code.start
                                            ;核心代码段位置#0c


         core_entry       dd start          ;核心代码段入口点#10  ;32bit
                          dw core_code_seg_sel         ;16bit

;===============================================================================
         [bits 32]
;===============================================================================
SECTION sys_routine vstart=0                ;系统公共例程代码段用于提供各种用途和功能的子过程以简化代码的编写。这些例程既可以用于内核，也供用户程序调用。 
;-------------------------------------------------------------------------------
         ;字符串显示例程
put_string:                                 ;显示0终止的字符串并移动光标 
                                            ;输入：DS:EBX=串地址
         push ecx
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
         pop ecx
         retf                               ;段间返回

;-------------------------------------------------------------------------------
put_char:                                   ;在当前光标处显示一个字符,并推进
                                            ;光标。仅用于段内调用 
                                            ;输入：CL=字符ASCII码 
         pushad

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;高字
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;低字
         mov bx,ax                          ;BX=代表光标位置的16位数

         cmp cl,0x0d                        ;回车符？
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;换行符？
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;正常显示字符
         push es
         mov eax,video_ram_seg_sel          ;0xb8000段的选择子
         mov es,eax
         shl bx,1
         mov [es:bx],cl
         pop es

         ;以下将光标位置推进一个字符
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;光标超出屏幕？滚屏
         jl .set_cursor

         push ds
         push es
         mov eax,video_ram_seg_sel
         mov ds,eax
         mov es,eax
         cld
         mov esi,0xa0                       ;小心！32位模式下movsb/w/d 
         mov edi,0x00                       ;使用的是esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;清除屏幕最底一行
         mov ecx,80                         ;32位程序应该使用ECX
  .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         pop es
         pop ds

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         ret                                

;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;从硬盘读取一个逻辑扇区
                                            ;EAX=逻辑扇区号
                                            ;DS:EBX=目标缓冲区地址
                                            ;返回：EBX=EBX+512
                                            ;默认使用调用这个过程的caller的DS选择子
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;读取的扇区数

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA地址7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA地址15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA地址23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                        ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         retf                               ;段间返回 

;-------------------------------------------------------------------------------
;汇编语言程序是极难一次成功，而且调试非常困难。这个例程可以提供帮助 
put_hex_dword:                              ;在当前光标处以十六进制形式显示
                                            ;一个双字并推进光标 
                                            ;输入：EDX=要转换并显示的数字
                                            ;输出：无
         pushad
         push ds
      
         mov ax,core_data_seg_sel           ;切换到核心数据段 
         mov ds,ax
      
         mov ebx,bin_hex                    ;指向核心数据段内的转换表
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         pop ds
         popad
         retf
      
;-------------------------------------------------------------------------------
allocate_memory:                            ;分配内存
                                            ;输入：ECX=希望分配的字节数
                                            ;输出：ECX=起始线性地址 
         push ds;要用覆盖整个4G的选择子
         push eax
         push ebx
      
         mov eax,core_data_seg_sel
         mov ds,eax
      
         mov eax,[ram_alloc]
         add eax,ecx                        ;下一次分配时的起始地址（包含）在EAX中，
      
         ;这里应当检测可用内存数量，如果不够就需要进行错误处理
         mov ecx,[ram_alloc]                ;返回分配的起始地址


         ;eax中存的是结果,ebx中存的是补齐4字节的结果，如果eax刚好4字节对齐，那么ebx就会多加4个字节

         mov ebx,eax
         and ebx,0xfffffffc
         add ebx,4                          ;强制4字节对齐 
         test eax,0x00000003                ;下次分配的起始地址最好是4字节对齐
         cmovnz eax,ebx                     ;如果没有对齐，则强制对齐，cmovcc指令可以避免控制转移

         mov [ram_alloc],eax                ;下次从该地址分配内存，从EAX存回去
                                            ; 
         pop ebx
         pop eax
         pop ds

         retf

;-------------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;在GDT内安装一个新的描述符
                                            ;输入：EDX:EAX=描述符 
                                            ;输出：CX=描述符的选择子
         push eax
         push ebx
         push edx
      
         push ds
         push es
      
         mov ebx,core_data_seg_sel          ;切换到核心数据段
         mov ds,ebx


         sgdt [pgdt]                        ;先把已经有的gdt的起始地址和界限存到[pgdt] 以便开始处理GDT
         ;pgdt的声明如下：
         ;pgdt             dw  0             ;用于设置和修改GDT 
         ;                 dd  0

         mov ebx,mem_0_4_gb_seg_sel         ;es段选择子用覆盖全部4G的段选择子
         mov es,ebx                         ;es段选择子用覆盖全部4G的段选择子

         movzx ebx,word [pgdt]              ;GDT界限，move with zero-extend，记得默认选择子是DS
         inc bx                             ;GDT总字节数，也是下一个描述符的起始偏移 
         add ebx,[pgdt+2]                   ;下一个描述符的起始线性地址，存在ebx中，[pgdt+2]就是GDT表的起始地址
      
         mov [es:ebx],eax
         mov [es:ebx+4],edx
      
         add word [pgdt],8                  ;增加一个描述符的大小   
      
         lgdt [pgdt]                        ;对GDT的更改生效 
       
         mov ax,[pgdt]                      ;得到GDT界限值
         xor dx,dx
         mov bx,8
         div bx                             ;除以8，去掉余数
         mov cx,ax                          
         shl cx,3                           ;将索引号移到正确位置 

         pop es
         pop ds

         pop edx
         pop ebx
         pop eax
      
         retf 
;-------------------------------------------------------------------------------
make_seg_descriptor:                        ;构造存储器和系统的段描述符
                                            ;输入：EAX=线性基地址
                                            ;      EBX=段界限
                                            ;      ECX=属性。各属性位都在原始
                                            ;          位置，无关的位清零 
                                            ;返回：EDX:EAX=描述符
         mov edx,eax
         shl eax,16
         or ax,bx                           ;描述符前32位(EAX)构造完毕

         and edx,0xffff0000                 ;清除基地址中无关的位
         rol edx,8
         bswap edx                          ;装配基址的31~24和23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;装配段界限的高4位

         or edx,ecx                         ;装配属性

         retf

;===============================================================================
SECTION core_data vstart=0                  ;系统核心的数据段
;-------------------------------------------------------------------------------
         pgdt             dw  0             ;用于设置和修改GDT 
                          dd  0

         ram_alloc        dd  0x00100000    ;下次为用户程序分配内存时的起始地址，用户内存起始地址为0x00100000

         ;内核符号地址检索表
         salt:
         salt_1           db  '@PrintString'
                     times 256-($-salt_1) db 0
                          dd  put_string
                          dw  sys_routine_seg_sel

         salt_2           db  '@ReadDiskData'
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0
                          dw  sys_routine_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  sys_routine_seg_sel

         salt_4           db  '@TerminateProgram'
                     times 256-($-salt_4) db 0
                          dd  return_point
                          dw  core_code_seg_sel

         salt_item_len   equ $-salt_4                     ;内核符号地址检索表 的表项 长度
         salt_items      equ ($-salt)/salt_item_len       ;内核符号地址检索表 的表项 数目

         message_1        db  'If you seen this message,that means we '
                          db  'are now in protect mode,and the system '
                          db  'core is loaded,and the video display '
                          db  'routine works perfectly.',0x0d,0x0a,0

         message_5        db  '  Loading user program...',0
         
         do_status        db  'Done.',0x0d,0x0a,0
         
         message_6        db  0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
                          db  '  User program terminated,control returned.',0

         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword子过程用的查找表 
         core_buf   times 2048 db 0         ;内核用的缓冲区

         esp_pointer      dd 0              ;内核用来临时保存自己的栈指针     

         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

;===============================================================================
SECTION core_code vstart=0                  ;系统核心代码段
;-------------------------------------------------------------------------------
load_relocate_program:                      ;加载并重定位用户程序
                                            ;输入：ESI=起始逻辑扇区号
                                            ;返回：AX=指向用户程序头部的选择子 
         push ebx
         push ecx
         push edx
         push esi
         push edi
      
         push ds
         push es
      
         mov eax,core_data_seg_sel
         
         mov ds,eax                         ;切换DS到内核数据段

         ;读取程序头部数据
         mov eax,esi                        ;esi存储起始扇区号      
         mov ebx,core_buf                   ;从硬盘读取一个逻辑扇区，然后放到core_buf ;内核用的缓冲区core_buf，大小就2048
         ;sys_routine_seg_sel:read_hard_disk_0这个过程使用的DS是调用者给出的
         call sys_routine_seg_sel:read_hard_disk_0

         ;以下判断整个程序有多大，最后程序占用的内存大小存储在EAX中，并且这个大小是512对齐的
         mov eax,[core_buf]                 ;程序尺寸
         mov ebx,eax                        ;ebx中备份程序实际尺寸
         and ebx,0xfffffe00                 ;使之512字节对齐（能被512整除的数， 低9位都为0）
         add ebx,512                        ;不足512的就多凑一个512字节
         test eax,0x000001ff                ;程序的大小正好是512的倍数吗? 
         cmovnz eax,ebx                     ;不是。使用凑整的结果，是的话就直接用ebx中备份程序实际尺寸
      
         mov ecx,eax                        ;实际需要申请的内存数量（程序大小）
                                            ;输入：ECX=希望分配的字节数
                                            ;输出：ECX=起始线性地址 
         call sys_routine_seg_sel:allocate_memory
         mov ebx,ecx                        ;ebx -> 申请到的内存首地址（包含）
         push ebx                           ;保存该首地址 
         xor edx,edx                        ;清零EDX
         mov ecx,512                        ;EAX作为被除数的一部分，是512对齐的
         div ecx
         mov ecx,eax                        ;总扇区数 
      
         mov eax,mem_0_4_gb_seg_sel         ;切换DS到0-4GB的段
         mov ds,eax

         mov eax,esi                        ;起始扇区号,ESI=起始逻辑扇区号 
  .b1:
         ;sys_routine_seg_sel:read_hard_disk_0这个过程使用的DS是调用者给出的，所以使用的是到0-4GB的段
                                            ;DS:EBX=目标缓冲区地址
                                            ;返回：EBX=EBX+512

         call sys_routine_seg_sel:read_hard_disk_0   ;从硬盘读取一个逻辑扇区
         inc eax
         loop .b1                           ;循环读，直到读完整个用户程序

         ;建立程序头部的段描述符
         pop edi                            ;恢复用户程序装载的首地址 
         mov eax,edi                        ;程序头部起始线性地址位于EAX中

         mov ebx,[edi+0x04]                 ;段长度
         dec ebx                            ;段界限 
         mov ecx,0x00409200                 ;字节粒度的数据段描述符
         call sys_routine_seg_sel:make_seg_descriptor
                                            ;构造存储器和系统的段描述符
                                            ;输入：EAX=线性基地址
                                            ;      EBX=段界限
                                            ;      ECX=属性。各属性位都在原始
                                            ;          位置，无关的位清零 
                                            ;返回：EDX:EAX=描述符

         call sys_routine_seg_sel:set_up_gdt_descriptor
                                            ;在GDT内安装一个新的描述符
                                            ;输入：EDX:EAX=描述符 
                                            ;输出：CX=描述符的选择子
         mov [edi+0x04],cx                   

         ;建立程序代码段描述符
         mov eax,edi
         add eax,[edi+0x14]                 ;代码起始线性地址
         mov ebx,[edi+0x18]                 ;段长度
         dec ebx                            ;段界限
         mov ecx,0x00409800                 ;字节粒度的代码段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x14],cx

         ;建立程序数据段描述符
         mov eax,edi
         add eax,[edi+0x1c]                 ;数据段起始线性地址
         mov ebx,[edi+0x20]                 ;段长度
         dec ebx                            ;段界限
         mov ecx,0x00409200                 ;字节粒度的数据段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x1c],cx




         ;建立程序堆栈段描述符
         mov ecx,[edi+0x0c]                 ;4KB的倍率 
         mov ebx,0x000fffff
         sub ebx,ecx                        ;得到段界限，放在EBX中
         mov eax,4096                        
         mul dword [edi+0x0c]               ;EAX中存放以字节为单位的栈大小。
         mov ecx,eax                        ;准备为堆栈分配内存 
         call sys_routine_seg_sel:allocate_memory;分配内存
                                            ;输入：ECX=希望分配的字节数
                                            ;输出：ECX=起始线性地址 

         add eax,ecx                        ;得到堆栈的高端物理地址（exlusive）
         mov ecx,0x00c09600                 ;4KB粒度的堆栈段描述符
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x08],cx







         ;重定位SALT
         mov eax,[edi+0x04]
         mov es,eax                         ;es -> 用户程序头部段选择子，用来拿到用户程序的SALT
         mov eax,core_data_seg_sel
         mov ds,eax                         ;ds -> 核心数据段选择子，用来拿到内核的SALT
      
         cld                                ;清空方向标志位

         mov ecx,[es:0x24]                  ;ECX存储的是  用户程序的SALT条目数
         mov edi,0x28                       ;edi：用户程序内的SALT位于头部内0x28偏移处

    .b2:                                      ;b2外循环，从 U-SALT 中依次取出表项，
       push ecx                             ;ECX存储的是  用户程序的SALT条目数，用于计数外循环次数
       push edi                             ;EDI为U-SALT当前表项的偏移地址
      
              mov ecx,salt_items                 ;salt_items   ECX指向内核符号地址检索表 的表项 数目，用于内层循环的计数
              mov esi,salt                       ;ESI指向当前C-SALT表项在内核数据段的偏移

       .b3:
              push edi
              push esi
              push ecx

              mov ecx,64                         ;检索表中，每条目的比较次数。因为每个条目的符号名部分是 256 字节，每次用 cmpsd 指令比较 4 字节，
                                                 ;故每个条目至多需要比对 64 次。 

              repe cmpsd                         ;每次比较4字节 

              jnz .b4                            ;循环末尾：如果ZF标志位为0则转移，继续对比其他字符串。为1的时候不跳转，表示已经找到

              mov eax,[esi]                      ;若匹配，esi恰好指向其后的地址数据
              mov [es:edi-256],eax               ;将字符串改写成偏移地址 
              mov ax,[esi+4]
              mov [es:edi-252],ax                ;以及改写段选择子 
       .b4:
       
              pop ecx
              pop esi                            ;恢复内核表指针
              add esi,salt_item_len              ;以指向C-SALT下一个条目。 C = kernal
              pop edi                            ;恢复EDI
              loop .b3

       pop edi
       add edi,256                               ;以指向U-SALT下一个条目。 U = user
       pop ecx                            ;      ;ECX存储的是  用户程序的SALT条目数
  loop .b2

         mov ax,[es:0x04]                 ;整个load_relocate_program的返回值
                                          ;返回：AX=指向用户程序头部的选择子 

         pop es                             ;恢复到调用此过程前的es段 
         pop ds                             ;恢复到调用此过程前的ds段
      
         pop edi
         pop esi
         pop edx
         pop ecx
         pop ebx
      
         ret
      
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
start:
         mov ecx,core_data_seg_sel           ;使ds指向核心数据段 
         mov ds,ecx

         mov ebx,message_1
         call sys_routine_seg_sel:put_string
                                         
         ;显示处理器品牌信息 
         mov eax,0x80000002
         cpuid
         mov [cpu_brand + 0x00],eax
         mov [cpu_brand + 0x04],ebx
         mov [cpu_brand + 0x08],ecx
         mov [cpu_brand + 0x0c],edx
      
         mov eax,0x80000003
         cpuid
         mov [cpu_brand + 0x10],eax
         mov [cpu_brand + 0x14],ebx
         mov [cpu_brand + 0x18],ecx
         mov [cpu_brand + 0x1c],edx

         mov eax,0x80000004
         cpuid
         mov [cpu_brand + 0x20],eax
         mov [cpu_brand + 0x24],ebx
         mov [cpu_brand + 0x28],ecx
         mov [cpu_brand + 0x2c],edx

         mov ebx,cpu_brnd0
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brand
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brnd1
         call sys_routine_seg_sel:put_string

         mov ebx,message_5
         call sys_routine_seg_sel:put_string
         mov esi,50                          ;用户程序位于逻辑50扇区 
         call load_relocate_program
                                          ;load_relocate_program
                                          ;输入：ESI=起始逻辑扇区号
                                          ;返回：AX=指向用户程序头部的选择子 

      
         mov ebx,do_status
         call sys_routine_seg_sel:put_string
      
         mov [esp_pointer],esp               ;临时保存堆栈指针
       
         mov ds,ax                           ;AX=指向用户程序头部的选择子
      
         jmp far [0x10]                      ;控制权交给用户程序（入口点就在偏移0x10处）
                                             ;堆栈可能切换 

return_point:                                ;用户程序返回点
         mov eax,core_data_seg_sel           ;使ds指向核心数据段
         mov ds,eax

         mov eax,core_stack_seg_sel          ;切换回内核自己的堆栈
         mov ss,eax 
         mov esp,[esp_pointer]               ;esp_pointer      内核用来临时保存自己的栈指针
              

         mov ebx,message_6
         call sys_routine_seg_sel:put_string

         ;这里可以放置清除用户程序各种描述符的指令
         ;也可以加载并启动其它程序
       
         hlt
            
;===============================================================================
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: