NAME=wz83
VERSION=$(shell git describe --tags)

AS=z80-unknown-coff-as
LD=z80-unknown-coff-ld
OBJCOPY=z80-unknown-coff-objcopy
OBJDUMP=z80-unknown-coff-objdump

SRCDIR=src
OUTDIR=out

SRCS=$(wildcard $(SRCDIR)/*.s)
OBJS=$(patsubst $(SRCDIR)/%.s,$(OUTDIR)/%.o,$(SRCS))
TARGET=$(OUTDIR)/$(NAME)

INCLUDE=-I./include
LDSCRIPT=z80.x
PAGES=00 01 02

.PHONY: all signed run debug clean



all: $(TARGET).unsigned.8Xu
signed: $(TARGET).8Xu

run: $(TARGET).rom
	z80e-sdl $(TARGET).rom

debug: $(TARGET).rom
	z80e-sdl --debug $(TARGET).rom

$(TARGET).8Xu: $(TARGET).rom
	mktiupgrade -d TI-83+ -v $(VERSION) -n 04 -k 04.key -p $^ $@ $(PAGES)

$(TARGET).unsigned.8Xu: $(TARGET).rom
	mktiupgrade -d TI-83+ -v $(VERSION) -p $^ $@ $(PAGES)

$(TARGET).rom: $(TARGET).elf
	@mkdir -p $(OUTDIR)
	$(OBJCOPY) -O binary $^ $@

$(TARGET).elf: $(OBJS) $(LDSCRIPT)
	@mkdir -p $(OUTDIR)
	$(LD) $(LDFLAGS) -T $(LDSCRIPT) $(OBJS) -o $@

$(OUTDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(OUTDIR)
	$(AS) $(ASFLAGS) $(DEFINES) $(INCLUDE) $^ -o $@

clean:
	-rm -r $(OUTDIR)
