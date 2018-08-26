NAME=wz83

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
LDFLAGS=-T z80.x


all: $(TARGET).rom

$(TARGET).rom: $(TARGET).elf
	@mkdir -p $(OUTDIR)
	$(OBJCOPY) -O binary $^ $@

$(TARGET).elf: $(OBJS)
	@mkdir -p $(OUTDIR)
	$(LD) $(LDFLAGS) $^ -o $@

$(OUTDIR)/%.o: $(SRCDIR)/%.s
	@mkdir -p $(OUTDIR)
	$(AS) $(ASFLAGS) $(DEFINES) $(INCLUDE) $^ -o $@

clean:
	-rm -r $(OUTDIR)
