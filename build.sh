nasm -f bin -o boot.bin asm/boot.asm
nasm -f bin -o loader.bin asm/loader.asm
nasm -f elf64 -o kernel.o asm/kernel.asm
nasm -f elf64 -o trapa.o asm/trap.asm
nasm -f elf64 -o lib.o asm/lib.asm
cargo rustc --bin op_system_rs --  --emit obj  -C link-arg=-nostartfiles -C no-redzone=yes -O
ld --allow-multiple-definition -nostdlib -T link.lds -o kernel kernel.o trapa.o lib.o $(find target/debug/deps -name 'op_system_rs*.o') 
objcopy -O binary kernel kernel.bin 
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc
dd if=kernel.bin of=boot.img bs=512 count=100 seek=6 conv=notrunc