AS := i686-elf-as
LD := i686-elf-ld

LDFLAGS := -T linker.ld

OBJS := bin/boot.o

all: $(OBJS)
	@mkdir -p bin
	$(LD) $(LDFLAGS) $(OBJS) -o bin/boot.bin
	
	@dd if=/dev/zero of=boot.img bs=512 count=2880
	@dd if=bin/boot.bin of=boot.img conv=notrunc

bin/%.o: src/%.s
	$(AS) $< -o $@