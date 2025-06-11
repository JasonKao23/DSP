SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PWD=$(shell pwd)

# parameters
DWIDTH ?= 8

VERILOG_SOURCES = $(PWD)/../rtl/vitdec.v \
                  $(PWD)/../rtl/depunct.v \
                  $(PWD)/../rtl/acs.v \
                  $(PWD)/../rtl/acs_butterfly.v \
                  $(PWD)/../rtl/traceback.v \
                  $(PWD)/../rtl/ram_dp.v

COMPILE_ARGS += -Pvitdec.DWIDTH=$(DWIDTH)

export RANDOM_SEED := 123456789

TOPLEVEL = vitdec
MODULE = test_vitdec

include $(shell cocotb-config --makefiles)/Makefile.sim
