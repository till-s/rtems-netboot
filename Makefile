# REAL VALUES (for use in flash)
FLASHSTART=0xfff80000
DEST=0x100

# DEBUGGING VALUES (make clean; make when changing these)
#FLASHSTART=0x400000
#DEST=0x10000

# Use a destination address > 0, e.g. 0x10000
# for debugging. In this case, the image will
# merely be uncompressed but _not_ started.
# also, there are some messages printed using
# SMON.
#
# NOTE:
#  debug mode makes a couple of assumptions:
#  A) compressed image is loaded at link address
#     (==FLASHADDR). With SMON this can be achieved
#     doing 'load "<file>" <FLASHADDR>'
#  B) downloaded image does not overlap uncompressed
#     image
#  C) uncompressed destination (DEST) is out of
#     the way of SMON.
#
#  since the uncompressed image can relocate itself,
#  it is still possible to start it in debug mode
#  (see below)
#
# Good values for debugging are:
# FLASHADDR=0x400000
# DEST     =0x010000
#
# Smon0>  load "netboot.gzimage" 0x400000
# Received 248900 bytes in 0.7 seconds.
# loaded netboot.gzimage at 400000
# Smon0>  g r5
# data copied
# bss cleared
# zs set
# inflateInit done
# inflate done
# done
# Smon0>  g r5
# -----------------------------------------
# Welcome to RTEMS RELEASE rtems-ss-20020301/svgm on VGM5/PowerPC/MPC7400
# SSRL Release $Name$/$Date$
# Build Date: Tue May 7 17:08:02 PDT 2002
# -----------------------------------------
# 


PROGELF=o-optimize/netboot$(EXTENS)
# must still terminate in ".bin"
EXTENS=.elf
IMGEXT=.flashimg.bin
TMPNAM=tmp
MAKEFILE=Makefile

SCRIPTS=smonscript.st reflash.st

include $(RTEMS_MAKEFILE_PATH)/Makefile.inc
include $(RTEMS_CUSTOM)
include $(CONFIG.CC)

#CC=$(CROSS_COMPILE)gcc
#LD=$(CROSS_COMPILE)ld
#OBJCOPY=$(CROSS_COMPILE)objcopy

CFLAGS=-O -I.

TMPIMG=$(TMPNAM).img
LINKBINS= $(TMPIMG).gz
LINKOBJS=gunzip.o
LINKSCRIPT=gunzip.lds

FINALTGT = $(PROGELF:%$(EXTENS)=%$(IMGEXT))

#
# "--just-symbols" files must be loaded _before_ the binary images
LINKARGS=--defsym DEST=$(DEST) --defsym FLASHSTART=$(FLASHSTART) -T$(LINKSCRIPT) $(LINKOBJS) --just-symbols=$(PROGELF) -b binary  $(LINKBINS) 

all:	$(FINALTGT)

$(TMPIMG):	$(PROGELF)
	$(OBJCOPY) -Obinary $^ $@

$(PROGELF)::
	$(MAKE) -f Makefile.rtems 

$(TMPIMG).gz: $(TMPIMG)
	$(RM) $@
	gzip -c9 $^ > $@

gunzip.o: gunzip.c $(MAKEFILE)
	$(CC) -c $(CFLAGS) -DDEST=$(DEST) -o $@ $<

$(FINALTGT):	$(LINKOBJS) $(LINKBINS) $(LINKSCRIPT) $(MAKEFILE)
	$(RM) $@
	$(LD) -o $@ $(LINKARGS) -Map map --oformat=binary
#	$(LD) -o $(@:%.bin=%$(EXTENS)) $(LINKARGS)
	$(RM) $(LINKBINS)

ifndef RTEMS_SITE_INSTALLDIR
RTEMS_SITE_INSTALLDIR = $(PROJECT_RELEASE)
endif

install: $(PROGELF) $(FINALTGT) $(SCRIPTS)
	$(INSTALL_CHANGE) $^ $(RTEMS_SITE_INSTALLDIR)/$(RTEMS_BSP)/img

clean:
	$(RM) $(TMPIMG) $(LINKBINS) $(LINKOBJS) map
	$(MAKE) -f Makefile.rtems clean

distclean: clean

balla:
	echo $(FINALTGT)