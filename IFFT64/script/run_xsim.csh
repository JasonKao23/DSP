#!/bin/csh -f
xsc ../test/cal_ifft64.c
xvlog -sv -f ifft64_compile_list.f -L uvm
xsc -compile ../test/cal_ifft64.c
xelab ifft64_tb_top -relax -s top -timescale 1ns/1ps;  
xsim top -testplusarg UVM_TESTNAME=ifft64_test -testplusarg UVM_VERBOSITY=UVM_LOW -testplusarg sv_seed=123 -runall 
