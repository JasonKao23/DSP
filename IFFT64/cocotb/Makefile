SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PWD=$(shell pwd)

# parameters
DWIDTH ?= 16

VERILOG_SOURCES = $(PWD)/../hdl/ifft64.v \
                  $(PWD)/../hdl/ifft64_tw_rom.v \
                  $(PWD)/../hdl/bfly.v \
                  $(PWD)/../hdl/cmult.v \
                  $(PWD)/../hdl/ram_dp.v \
                  $(PWD)/../hdl/shift_registers_srl.v

COMPILE_ARGS += -Pifft64.DWIDTH=$(DWIDTH)

# SIM_ARGS+=--vcd=anyname.vcd

export RANDOM_SEED := 123456789

TOPLEVEL = ifft64
MODULE = test_ifft64

include $(shell cocotb-config --makefiles)/Makefile.sim

# Profiling

DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg
