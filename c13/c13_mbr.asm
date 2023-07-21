         ;�����嵥13-1
         ;�ļ�����c13_mbr.asm
         ;�ļ�˵����Ӳ���������������� 
         ;�������ڣ�2011-10-28 22:35          ;���ö�ջ�κ�ջָ�� 
         
         core_base_address equ 0x00040000   ;�������ں˼��ص���ʼ�ڴ��ַ 
         core_start_sector equ 0x00000001   ;�������ں˵���ʼ�߼������� 
         
         mov ax,cs      
         mov ss,ax
         mov sp,0x7c00
      
         ;����GDT���ڵ��߼��ε�ַ
         mov eax,[cs:pgdt+0x7c00+0x02]      ;GDT��32λ�����ַ 
         xor edx,edx
         mov ebx,16
         div ebx                            ;�ֽ��16λ�߼���ַ 

         mov ds,eax                         ;��DSָ��ö��Խ��в���
         mov ebx,edx                        ;������ʼƫ�Ƶ�ַ 

         ;����0#���������Ĳ�λ
         ;0��������һ���ǿյ�


         ;����1#������������һ�����ݶΣ���Ӧ0~4GB�����Ե�ַ�ռ�
         mov dword [ebx+0x08],0x0000ffff    ;����ַΪ0���ν���Ϊ0xFFFFF
         mov dword [ebx+0x0c],0x00cf9200    ;����Ϊ4KB���洢���������� 

         ;��������ģʽ�³�ʼ�����������
         mov dword [ebx+0x10],0x7c0001ff    ;����ַΪ0x00007c00������0x1FF 
         mov dword [ebx+0x14],0x00409800    ;����Ϊ1���ֽڣ������������ 

         ;��������ģʽ�µĶ�ջ��������           ;����ַΪ0x00007C00������0xFFFFE 
         mov dword [ebx+0x18],0x7c00fffe    ;����Ϊ4KB 
         mov dword [ebx+0x1c],0x00cf9600    ;��ջ��Ͷ˵���Ч�����ַ:0x00006C00
                                            ;��ջ��Ͷ˵���Ч�����ַ:0x00007BFF
         
         ;��������ģʽ�µ���ʾ������������   
         mov dword [ebx+0x20],0x80007fff    ;����ַΪ0x000B8000������0x07FFF 
         mov dword [ebx+0x24],0x0040920b    ;����Ϊ�ֽ�
         
         ;��ʼ����������Ĵ���GDTR
         mov word [cs: pgdt+0x7c00],39      ;��������Ľ���   
 
         lgdt [cs: pgdt+0x7c00]
      
         in al,0x92                         ;����оƬ�ڵĶ˿� 
         or al,0000_0010B
         out 0x92,al                        ;��A20

         cli                                ;�жϻ�����δ����

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;����PEλ
      
         ;���½��뱣��ģʽ... ...
         jmp dword 0x0010:flush             ;16λ��������ѡ���ӣ�32λƫ��
                                            ;����ˮ�߲����л�������
         [bits 32]               
  flush:                                  
         mov eax,0x0008                     ;�������ݶ�(0..4GB)ѡ����
         mov ds,eax
      
         mov eax,0x0018                     ;���ض�ջ��ѡ���� 
         mov ss,eax
         xor esp,esp                        ;��ջָ�� <- 0 




         ;���¼���ϵͳ���ĳ��� 
         mov edi,core_base_address          ;�üĴ����洢 ����

         mov eax,core_start_sector          
         mov ebx,edi                        ;��ʼ��ַ����������ڴ���ʼ���� 
         call read_hard_disk_0              ;read_hard_disk_0��ȡ�������ʼ���֣�һ�������������к�EBX=EBX+512���պÿ��Խ��Ŷ�
      
         ;�����ж����������ж��
         mov eax,[edi]                      ;���ĳ���ߴ磬[edi]�����ַ�е����ݣ���Ӧ��������˵�һ����������������Ŀ�ͷ��¼���ں˳���Ĵ�С��
         xor edx,edx                        ;EDX:EAX / operand
         mov ecx,512                        ;512�ֽ�ÿ����
         div ecx                            ;����EAX��������EDX

         or edx,edx
         jnz @1                             ;δ��������˽����ʵ����������1 
         dec eax                            ;�Ѿ�����һ������������������1 
   @1:
         or eax,eax                         ;����ʵ�ʳ��ȡ�512���ֽڵ���� 
         jz setup                           ;�ж��Ƿ�EAX=0 ?��EAX����װ�ľ�����Ҫ���������������Ŀ

         ;��ȡʣ�������
         mov ecx,eax                        ;32λģʽ�µ�LOOPʹ��ECX
         mov eax,core_start_sector
         inc eax                            ;����һ���߼��������Ŷ�
   @2:
         call read_hard_disk_0
         inc eax
         loop @2                            ;ѭ������ֱ�����������ں� 

 setup:
         mov esi,[0x7c00+pgdt+0x02]         ;�������ô����������Ѱַpgdt����Ϊ��������ִֻ�У����ܶ�����������ͨ��4GB�Ķ�������

         ;�����������̶�������
         mov eax,[edi+0x04]                 ;�������̴������ʼ����ַ��������ļ��ʼ��
         mov ebx,[edi+0x08]                 ;�������ݶλ���ַ
         sub ebx,eax

         dec ebx                            ;�������̶ν��ޣ�ƫ�Ƶ�ȡֵ���������һ���ֽڣ� 
         add eax,edi                        ;�������̶Σ����ڴ��еģ�����ַ��edi�ŵ���core_base_address
         mov ecx,0x00409800                 ;�ֽ����ȵĴ������������Լ��������λ����ԭʼλ�ã�����û�õ���λ��0��
         ;make_gdt_descriptor���̷������´���EDX:EAX������������
         call make_gdt_descriptor
         mov [esi+0x28],eax                 ;0x28 = 40decimal,һ��������8���ֽڣ�˵��ǰ���Ѿ���5��������
         mov [esi+0x2c],edx
       
         ;�����������ݶ�������
         mov eax,[edi+0x08]                 ;�������ݶ���ʼ����ַ
         mov ebx,[edi+0x0c]                 ;���Ĵ���λ���ַ 
         sub ebx,eax
         dec ebx                            ;�������ݶν���
         add eax,edi                        ;�������ݶλ���ַ��edi�ŵ���core_base_address
         mov ecx,0x00409200                 ;�ֽ����ȵ����ݶ�����������Լ��������λ����ԭʼλ�ã�����û�õ���λ��0��
         call make_gdt_descriptor
         mov [esi+0x30],eax
         mov [esi+0x34],edx 
      
         ;�������Ĵ����������
         mov eax,[edi+0x0c]                 ;���Ĵ������ʼ����ַ
         mov ebx,[edi+0x00]                 ;�����ܳ���
         sub ebx,eax
         dec ebx                            ;���Ĵ���ν���
         add eax,edi                        ;���Ĵ���λ���ַ
         mov ecx,0x00409800                 ;�ֽ����ȵĴ����������
         call make_gdt_descriptor
         mov [esi+0x38],eax
         mov [esi+0x3c],edx

         mov word [0x7c00+pgdt],63          ;������������Ľ��ޣ��Ӷ������µ�������
                                        
         lgdt [0x7c00+pgdt]                 ;���¼���gdt
       
         jmp far [edi+0x10]                 ;Զ��תcore_base_address + 0x10����ǳ������ڣ��ߵ�ַ��CS���͵�ַ��ESP
       
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;��Ӳ�̶�ȡһ���߼�����
                                         ;EAX=�߼�������
                                         ;DS:EBX=Ŀ�껺������ַ
                                         ;���أ�EBX=EBX+512 
         ;������õ��ļĴ���
         push eax 
         push ecx
         push edx

         ;�����߼������Ų���
         push eax
       

         ;�� 1 ��������Ҫ��ȡ������������ 
         mov dx,0x1f2
         mov al,1                        ;��ȡ��������
         out dx,al                       ;��al��ֵд��dx�Ĵ����д���Ķ˿ںţ��˿ھ��ǼĴ������С�


         ;�� 2 ����������ʼ LBA �����š�
         ;28 λ��������̫������Ҫ����ֳ� 4 �Σ��ֱ�д��˿� 0x1f3��0x1f4��0x1f5 �� 0x1f6 �Ŷ˿ڡ�
         inc dx                          ;dx�Ĵ����д���Ķ˿ں�:0x1f3
         pop eax
         out dx,al                       ;LBA��ַ7~0

         inc dx                          ;dx�Ĵ����д���Ķ˿ں�:0x1f4
         mov cl,8                        
         shr eax,cl                      ;���߼�������
         out dx,al                       ;LBA��ַ15~8

         inc dx                          ;0x1f5
         shr eax,cl
         out dx,al                       ;LBA��ַ23~16

         inc dx                          ;0x1f6
         shr eax,cl
         or al,0xe0                      ;��һӲ�̣���Ӳ�̣�  LBA��ַ27~24���ο�0x1f6 �Ŷ˿��еļĴ�������
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;������
         out dx,al

  .waits:                                ;��ѯʽ�ȴ�����ѯ
         in al,dx                        ;��ȡ�˿�0x1f7�е�ֵ
         and al,0x88                     ;0x88 1000_1000B
         cmp al,0x08                     ;0x08 0000_1000B ��ʾ��æ����Ӳ����׼�������ݴ���
         jnz .waits                      ;��æ����Ӳ����׼�������ݴ��� 

         mov ecx,256                     ;�ܹ�Ҫ��ȡ������
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2                       ;ÿ�������ֽ�
         loop .readw
       
         ;ջƽ��
         pop edx
         pop ecx
         pop eax
      
         ret

;-------------------------------------------------------------------------------
make_gdt_descriptor:                     ;����������
                                         ;���룺 EAX=���Ի���ַ���ڴ��еģ�
                                         ;      EBX=�ν���
                                         ;      ECX=���ԣ�Լ��������λ����ԭʼλ�ã�����û�õ���λ��0�� 
                                         ;
                                         ;���أ� EDX:EAX=������������
         mov edx,eax
         shl eax,16                     
         or ax,bx                        ;������ǰ��λ�ڵ͵�ַ��32λ��32λ(EAX)�������
      
         and edx,0xffff0000              ;�������ַ���޹ص�λ
         rol edx,8
         bswap edx                       ;װ���ַ��31~24��23~16  (80486+)bswap����edx���ֽڵ�˳��3210���0123
      
         xor bx,bx                       ;���EBX�Ĵ����ĵ�16λ(EBX�Ĵ�������20λ�ν���)
         or edx,ebx                      ;װ��ν��޵ĸ�4λ
      
         or edx,ecx                      ;װ������ 
      
         ret
      
;-------------------------------------------------------------------------------
         pgdt             dw 0
                          dd 0x00007e00      ;GDT�������ַ
;-------------------------------------------------------------------------------                             
         times 510-($-$$) db 0
                          db 0x55,0xaa