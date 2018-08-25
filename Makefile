NAME=init
AS=sass
OUTDIR=out/
BINDIR=$(OUTDIR)fs/bin/
INCLUDE=include/
LENGTH := 0x80000
TARGET=$(BINDIR)$(NAME)

$(TARGET):
	mkdir -p $(BINDIR)
	$(AS) $(ASFLAGS) $(DEFINES) --include "$(INCLUDE)" --listing $(OUTDIR)$(NAME).list src/$(NAME).asm $(BINDIR)$(NAME)

clean:
	-rm -r $(OUTDIR)
