nasm boot.asm -o boot.bin 
dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
bochsdbg -f .\bochsrc.disk

::ata0-master: type=disk, path="hd60M.img", mode=flat    for hard disk
::floppya: image="shit.img", status=inserted         for floppy