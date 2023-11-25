AS := i686-elf-gcc
LD := i686-elf-ld

LDFLAGS := -T linker.ld
ASFLAGS := -x assembler-with-cpp

OBJS := bin/boot.o bin/main.o

all: $(OBJS)
	@mkdir -p bin
	$(LD) $(LDFLAGS) $(OBJS) -o bin/boot.bin
	
	@dd if=/dev/zero of=boot.img bs=512 count=2880
	@dd if=bin/boot.bin of=boot.img conv=notrunc

bin/%.o: src/%.s
	$(AS) $(ASFLAGS) -c $< -o $@
