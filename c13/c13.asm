         ;代码清单13-3
         ;文件名：c13.asm
         ;文件说明：用户程序 
         ;创建日期：2011-10-30 15:19   

;程序头部
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04,这里之后会被填写一个程序头部的段描述符

         ;堆栈空间由内核分配，;选择子由内核之后填写
         stack_seg        dd 0                    ;用于接收堆栈段选择子#0x08
         stack_len        dd 1                    ;程序建议的堆栈大小，以4KB为单位，#0x0C
                                                  
         prgentry         dd start                ;程序入口#0x10 
         ;选择子由内核之后填写
         code_seg         dd section.code.start   ;代码段位置#0x14 相对于整个用户程序开头。[这里之后会被内核被填写一个程序代码段描述符]
         code_len         dd code_end             ;用户代码段长度#0x18

         ;选择子由内核之后填写
         data_seg         dd section.data.start   ;数据段位置#0x1c 相对于整个用户程序开头。[这里之后会被内核填写一个程序数据段描述符]
         data_len         dd data_end             ;数据段长度#0x20
             
;-------------------------------------------------------------------------------
         ;符号地址检索表 Symbol-Address Lookup Table，SALT；每个项长度为256
         ;内核会分析这个表格，并将每一个符号名替换成相应的内存地址，这就是过程的重定位。
         salt_items       dd (header_end - salt) / 256 ;#0x24
         
         salt:                                     ;#0x28
         PrintString      db  '@PrintString'       ;内核进行重定位后，这些字符串的开头就会被换成 被调用函数的 偏移地址 + 段选择子
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram';内核进行重定位后，这些字符串的开头就会被换成 被调用函数的 偏移地址 + 段选择子
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData';内核进行重定位后，这些字符串的开头就会被换成 被调用函数的 偏移地址 + 段选择子
                     times 256-($-ReadDiskData) db 0
                 
header_end:



;用户程序数据段
;===============================================================================
SECTION data vstart=0    
                         
         buffer times 1024 db  0         ;缓冲区

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:




;用户程序代码段
;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0
start:
         mov eax,ds
         mov fs,eax                          ;fs会得到 指向程序头部 的段选择子
     
         mov eax,[stack_seg]
         mov ss,eax
         mov esp,0
     
         mov eax,[data_seg]
         mov ds,eax
     
         mov ebx,message_1
         call far [fs:PrintString]
     
         mov eax,100                         ;逻辑扇区号100
         mov ebx,buffer                      ;缓冲区偏移地址
         call far [fs:ReadDiskData]          ;段间调用
     
         mov ebx,message_2
         call far [fs:PrintString]
     
         mov ebx,buffer 
         call far [fs:PrintString]           ;too.
     
         jmp far [fs:TerminateProgram]       ;将控制权返回到系统 
      
code_end:



;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: