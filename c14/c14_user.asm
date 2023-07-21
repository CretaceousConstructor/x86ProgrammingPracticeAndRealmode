         ;�����嵥13-3
         ;�ļ�����c13.asm
         ;�ļ�˵�����û����� 
         ;�������ڣ�2011-10-30 15:19   

;����ͷ��
;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;�����ܳ���#0x00
         
         head_len         dd header_end           ;����ͷ���ĳ���#0x04,����֮��ᱻ��дһ������ͷ���Ķ�������

         ;��ջ�ռ����ں˷��䣬;ѡ�������ں�֮����д
         stack_seg        dd 0                    ;���ڽ��ն�ջ��ѡ����#0x08
         stack_len        dd 1                    ;������Ķ�ջ��С����4KBΪ��λ��#0x0C
                                                  
         prgentry         dd start                ;�������#0x10 
         ;ѡ�������ں�֮����д
         code_seg         dd section.code.start   ;�����λ��#0x14 ����������û�����ͷ��[����֮��ᱻ�ں˱���дһ����������������]
         code_len         dd code_end             ;�û�����γ���#0x18

         ;ѡ�������ں�֮����д
         data_seg         dd section.data.start   ;���ݶ�λ��#0x1c ����������û�����ͷ��[����֮��ᱻ�ں���дһ���������ݶ�������]
         data_len         dd data_end             ;���ݶγ���#0x20
             
;-------------------------------------------------------------------------------
         ;���ŵ�ַ������ Symbol-Address Lookup Table��SALT��ÿ�����Ϊ256
         ;�ں˻���������񣬲���ÿһ���������滻����Ӧ���ڴ��ַ������ǹ��̵��ض�λ��
         salt_items       dd (header_end - salt) / 256 ;#0x24
         
         salt:                                     ;#0x28
         PrintString      db  '@PrintString'       ;�ں˽����ض�λ����Щ�ַ����Ŀ�ͷ�ͻᱻ���� �����ú����� ƫ�Ƶ�ַ + ��ѡ����
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram';�ں˽����ض�λ����Щ�ַ����Ŀ�ͷ�ͻᱻ���� �����ú����� ƫ�Ƶ�ַ + ��ѡ����
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData';�ں˽����ض�λ����Щ�ַ����Ŀ�ͷ�ͻᱻ���� �����ú����� ƫ�Ƶ�ַ + ��ѡ����
                     times 256-($-ReadDiskData) db 0
                 
header_end:



;�û��������ݶ�
;===============================================================================
SECTION data vstart=0    
                         
         buffer times 1024 db  0         ;������

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:




;�û���������
;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0
start:
         mov eax,ds
         mov fs,eax                          ;fs��õ� ָ�����ͷ�� �Ķ�ѡ����
     
         mov eax,[stack_seg]
         mov ss,eax
         mov esp,0
     
         mov eax,[data_seg]
         mov ds,eax
     
         mov ebx,message_1
         call far [fs:PrintString]
     
         mov eax,100                         ;�߼�������100
         mov ebx,buffer                      ;������ƫ�Ƶ�ַ
         call far [fs:ReadDiskData]          ;�μ����
     
         mov ebx,message_2
         call far [fs:PrintString]
     
         mov ebx,buffer 
         call far [fs:PrintString]           ;too.
     
         jmp far [fs:TerminateProgram]       ;������Ȩ���ص�ϵͳ 
      
code_end:



;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end: