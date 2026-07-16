################################################################################
# Makefile  —  VCS Compilation & Simulation for SM4 UVM Testbench
################################################################################

# ---- Test Selection ----------------------------------------------------------
TESTNAME ?= sm4_sanity_test

# ---- Tool Settings -----------------------------------------------------------
VCS         = vcs
COV_TYPES   = line+cond+fsm+tgl+branch

VCS_FLAGS   = -sverilog                     \
              -full64                       \
              -timescale=1ns/1ps            \
              -ntb_opts uvm-1.2             \
              -debug_access+all             \
              +vcs+lic+wait                 \
              +incdir+../uvm                \
              -cm $(COV_TYPES)              \
              -cm_name $(TESTNAME)          \
              -cm_hier cov_hier.cfg         \
              -l vcs_compile.log

# ---- C Compiler Settings (DPI-C) ---------------------------------------------
CFLAGS      = -I../c_model
VCS_FLAGS  += -CFLAGS "$(CFLAGS)"

# ---- Source Files ------------------------------------------------------------
RTL_DIR     = ../rtl
RTL_FILES   = $(RTL_DIR)/get_cki.v                \
              $(RTL_DIR)/key_expansion.v           \
              $(RTL_DIR)/one_round_for_encdec.v    \
              $(RTL_DIR)/one_round_for_key_exp.v   \
              $(RTL_DIR)/sbox_replace.v            \
              $(RTL_DIR)/sm4_encdec.v              \
              $(RTL_DIR)/sm4_top.v                 \
              $(RTL_DIR)/sm4_wrapper.v             \
              $(RTL_DIR)/transform_for_encdec.v    \
              $(RTL_DIR)/transform_for_key_exp.v

TB_DIR      = ../tb
UVM_DIR     = ../uvm
TB_FILES    = $(TB_DIR)/apb_if.sv                \
              $(TB_DIR)/stream_if.sv              \
              $(UVM_DIR)/sm4_pkg.sv              \
              $(TB_DIR)/tb_top.sv

C_DIR       = ../c_model
C_FILES     = $(C_DIR)/sm4.c                      \
              $(C_DIR)/sm4_dpic.c

ALL_SRCS    = $(RTL_FILES) $(TB_FILES) $(C_FILES)

# ---- Output ------------------------------------------------------------------
SIMV        = simv
SIM_LOG     = sim_$(TESTNAME).log
COV_DIR     = simv.vdb
COV_RPT     = coverage_report

# ---- Phony Targets -----------------------------------------------------------
.PHONY: compile run cov clean help

# ---- compile -----------------------------------------------------------------
compile: $(SIMV)

$(SIMV): $(ALL_SRCS)
	@echo "============================================"
	@echo " Compiling SM4 UVM Testbench with VCS"
	@echo " Coverage : $(COV_TYPES)"
	@echo "============================================"
	$(VCS) $(VCS_FLAGS) -o $(SIMV) $(ALL_SRCS)

# ---- run ---------------------------------------------------------------------
run: $(SIMV)
	@echo "============================================"
	@echo " Running test : $(TESTNAME)"
	@echo "============================================"
	./$(SIMV)                           \
		+UVM_TESTNAME=$(TESTNAME)       \
		+UVM_VERBOSITY=UVM_MEDIUM       \
		-cm $(COV_TYPES)                \
		-cm_name $(TESTNAME)            \
		-cm_hier cov_hier.cfg           \
		-l $(SIM_LOG)
	@echo ""
	@echo "============================================"
	@echo " Simulation finished"
	@echo " Log      : $(SIM_LOG)"
	@echo " Coverage : simv.vdb"
	@echo "============================================"

# ---- cov  (coverage report) --------------------------------------------------
cov:
	@echo "============================================"
	@echo " Generating coverage report ..."
	@echo "============================================"
	urg -dir $(COV_DIR) -format both -report $(COV_RPT)
	@echo ""
	@echo " Report  : $(COV_RPT)/"
	@echo " Open with: firefox $(COV_RPT)/dashboard.html"
	@echo "       or: verdi -cov -covdir $(COV_DIR)"

# ---- clean -------------------------------------------------------------------
clean:
	@echo " Cleaning simulation artifacts..."
	rm -rf $(SIMV) $(SIMV).daidir csrc
	rm -rf DVEfiles
	rm -rf ucli.key
	rm -rf novas.*
	rm -rf verdiLog
	rm -rf *.fsdb *.vpd *.vcd
	rm -rf *.log
	rm -rf *.vdb
	rm -rf $(COV_RPT)
	rm -rf vc_hdrs.h
	rm -rf stack.info.*
	rm -rf *__*__*.so
	@echo " Done."

# ---- help --------------------------------------------------------------------
help:
	@echo " make compile              —  Build simv with coverage instrumentation"
	@echo " make run TESTNAME=<name>  —  Run simulation (default: sm4_sanity_test)"
	@echo " make cov                  —  Generate coverage report (urg)"
	@echo " make clean                —  Remove all generated files"
	@echo ""
	@echo " Usage example:"
	@echo "   make compile"
	@echo "   make run TESTNAME=sm4_sanity_test"
	@echo "   make run TESTNAME=sm4_burst_test"
	@echo "   make run TESTNAME=sm4_random_test"
	@echo "   make cov"
