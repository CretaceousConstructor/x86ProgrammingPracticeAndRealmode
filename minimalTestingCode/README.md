# Testing Code for "x86/x64 Architecture Exploration and Programming" by Deng Zhi

## Overview
This repository contains testing code from the book 《x86_x64体系探索及编程》(x86/x64 Architecture Exploration and Programming) by Deng Zhi.

## File: `x86TestingCode/CompileAndRun.bat`
This script is used to:
- **Compile**: Using NASM assembler.
- **Write to image**: Using `dd` utility to write binary code into a VM image file.
- **Run VM**: Start the virtual machine using `bochsdbg` (debug version of Bochs) for debugging. Bochs enhanced gui debugger is preferred:
https://sourceforge.net/p/bochs/discussion/39592/thread/76f5739c/#:~:text=You%20uncomment%20the%20following%20line%20in%20bochsrc.bxrc%3A%20display_library%3A,bochsrc.bxrc%20This%20starts%20the%20Bochs%20enhanced%20debugger%20GUI.


## File: `a.img` and `hd60M.img`
- **a.img**: Floppy disk.
- **hd60M.img**: Hard disk.


## Booting on a Physical Machine
The process is largely similar to booting on a virtual machine, with the following key differences:

### Writing to a USB Drive on Windows
To write data to a USB drive for physical booting:

1.  **Reference**:  
    [StackOverflow Guide](https://stackoverflow.com/questions/1894843/how-can-i-put-a-compiled-boot-sector-onto-a-usb-stick-or-disk/1894866#comment54678918_1894866)

2.  **Important Note**:  
    ⚠️ **You must run the command as Administrator!** ⚠️

3.  **Usage of `dd`**:  
    Use the `dd` command to write **directly to the entire USB drive**. This ensures the boot sector is overwritten. Using `if` to target a partition is insufficient.

4.  **Example Command**:
    ```bash
    D:\CS\x86expriments\mainBook\tools\dd.exe if=D:\CS\x86expriments\mainBook\Backup\source\topic03\ex3-2\uboot od=z: bs=512 count=1
    ```
    *(Note: The parameter should be `od` (output file) to specify the target device, not `of`.)*