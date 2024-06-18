#############################################################
##
##user cfg
##
##############################################################

export seed ?= random
export tc   ?= sanity
export wave ?= off
export ccov ?= off
export mode ?= sim_base

##############################################################
##
##env path
##
##############################################################
export SIM_PATH  := ./$(mode)

ifeq ($(seed), random)
	SEED := $(shell python -c "from random import randint; print randint(0,99999999)")
	#SEED := $(shell perl -e "print int(rand(100000000))")
else
	SEED := $(seed)
endif

export PRE_PROC:= mkdir -p $(SIM_PATH)/log $(SIM_PATH)/exec 
ifeq ($(wave), on)
	PRE_PROC += $(SIM_PATH)/wave 
endif
ifeq ($(ccov), on)
	PRE_PROC += $(SIM_PATH)/cov
endif

SIM_LOG   ?= $(SIM_PATH)/log/sim.log
RUN_LOG   ?= $(SIM_PATH)/log/$(tc)_$(SEED).log
RUN_WAVE  ?= $(SIM_PATH)/wave/$(tc)_$(SEED).fsdb
EXEC_SIMV ?= $(SIM_PATH)/exec/simv
RUN_COV   ?= $(tc)_$(SEED)
FILELIST  ?= ../cfg/tb.f
TOP_MOD   ?= testbench

VERDI_P := ${VERDI_HOME}/share/PLI/VCS/LINUXAMD64/novas.tab \
  		 		  ${VERDI_HOME}/share/PLI/VCS/LINUXAMD64/pli.a
##############################################################
##
##vcs cmp command
##
##############################################################

export CMP_OPTIONS :=
CMP_OPTIONS += -f $(FILELIST) -P $(VERDI_P) -l $(SIM_LOG) -o $(EXEC_SIMV)
CMP_OPTIONS += +libext+.sv+.v +indir+/home/xiaotu/my_work/code_lib
CMP_OPTIONS += +v2k +define+RTL_SAIF +notimingcheck +nospecify +vpi +memcbk +vcsd +plusarg_save +nospecify +udpsched
CMP_OPTIONS += +vcs+lic+wait
CMP_OPTIONS += -sverilog -full64 -sverilog -debug_all -ntb_opts uvm-1.2
CMP_OPTIONS += -sv_pragma -lca -kdb
CMP_OPTIONS += -top $(TOP_MOD)
CMP_OPTIONS += -timescale=1ns/1ps -unit_timescale=1ns/1ps
CMP_OPTIONS += +vcs+initreg+random
#CMP_OPTIONS += -xprop=tmerge

ifeq ($(ccov), on)
	CMP_OPTIONS += -cm line+fsm+cond+tgl+assert+branch
	CMP_OPTIONS += -cm_cond allops+for+tf -cm_libs yv -cm_cond obs -cm_tgl portsonly -cm_glitch 0
	CMP_OPTIONS += -cm_dir $(SIM_PATH)/cov/simv.vdb
endif

##############################################################
##
##vcs run command
##
##############################################################

export RUN_OPTIONS :=
RUN_OPTIONS += +ntb_random_seed=$(SEED) +tc_name=$(tc) -l $(RUN_LOG)
RUN_OPTIONS += -assert nopostproc
RUN_OPTIONS += +vcs+lic+wait
RUN_OPTIONS += +vcs+initreg+$(SEED)
ifeq ($(wave), on)
	RUN_OPTIONS += +fsdbfile+$(RUN_WAVE) -ucli -do ../cfg/run.do
endif
ifeq ($(ccov), on)
	RUN_OPTIONS += -cm line+cond+tgl+fsm+branch+assert
	RUN_OPTIONS += -cm_dir $(SIM_PATH)/cov/simv.vdb -cm_name $(RUN_COV)
endif

##############################################################
##
## PHONY order
##
##############################################################
.PHONY: cmp ncrun run verdi clean clean_all

test:
	@echo $(SIM_LOG)

cmp:
	@$(PRE_PROC)
	@vcs $(CMP_OPTIONS)

ncrun:
	@$(EXEC_SIMV) $(RUN_OPTIONS)
	@../cfg/check_fail.pl $(RUN_LOG)
	@echo "[Note] report log path: $(RUN_LOG)"

run: cmp ncrun

verdi:
	@verdi -simflow -dbdir $(SIM_PATH)/exec/simv.daidir

clean:
	@rm -rf $(SIM_PATH)/exec ucli.key csrc vc_hdrs.h novas.conf  novas_dump.log  novas.rc verdiLog

clean_all: clean
	@rm -rf $(SIM_PATH)
