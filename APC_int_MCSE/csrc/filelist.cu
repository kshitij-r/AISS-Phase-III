LDVERSION= $(shell $(PIC_LD) -v | grep -q 2.30 ;echo $$?)
ifeq ($(LDVERSION), 0)
     LD_NORELAX_FLAG= --no-relax
endif

ARCHIVE_OBJS=
ARCHIVE_OBJS += _41287_archive_1.so
_41287_archive_1.so : archive.19/_41287_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -z notext -m elf_i386  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//../simv.daidir//_41287_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//../simv.daidir//_41287_archive_1.so $@




VCS_CU_ARC_OBJS = 


O0_OBJS =

$(O0_OBJS) : %.o: %.c
	$(CC_CG) $(CFLAGS_O0) -c -o $@ $<


%.o: %.c
	$(CC_CG) $(CFLAGS_CG) -c -o $@ $<
CU_UDP_OBJS = \
objs/udps/VaC89.o objs/udps/IkBJ3.o objs/udps/YKGze.o objs/udps/UxzzW.o objs/udps/rm4H1.o  \
objs/udps/KyUNy.o objs/udps/ekIQf.o objs/udps/U7Vwg.o objs/udps/vCfas.o objs/udps/exIG1.o  \
objs/udps/gSqMj.o objs/udps/Hkmrd.o objs/udps/SYjWk.o objs/udps/hUcmi.o objs/udps/PjGxs.o  \
objs/udps/MzHq6.o objs/udps/guAtk.o objs/udps/aKVa7.o objs/udps/F8ezs.o objs/udps/GLrQJ.o  \
objs/udps/dKp3B.o 

CU_LVL_OBJS = \
SIM_l.o 

MAIN_OBJS = \
objs/amcQw_d.o 

CU_OBJS = $(MAIN_OBJS) $(ARCHIVE_OBJS) $(CU_UDP_OBJS) $(CU_LVL_OBJS)

