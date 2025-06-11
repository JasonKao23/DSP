set test [pwd]
cd ..
set ifft64_root_path [pwd]
create_project ifft64_proj -part xc7z020clg484-1 -force ./sim_project

add_files -norecurse ${ifft64_root_path}/hdl/bfly.v
add_files -norecurse ${ifft64_root_path}/hdl/cmult.v
add_files -norecurse ${ifft64_root_path}/hdl/ifft64_tw_rom.v
add_files -norecurse ${ifft64_root_path}/hdl/ifft64.v
add_files -norecurse ${ifft64_root_path}/hdl/ram_dp.v
add_files -norecurse ${ifft64_root_path}/hdl/shift_registers_srl.v
add_files -norecurse ${ifft64_root_path}/test/cal_ifft64.c
add_files -norecurse ${ifft64_root_path}/test/ifft64_agent.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_coverage.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_driver.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_env.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_interface.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_monitor.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_ref_model.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_scoreboard.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_seq.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_sequencer.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_tb_top.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_test.sv
add_files -norecurse ${ifft64_root_path}/test/ifft64_transaction.sv

set_property top ifft64_tb_top [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm -define "NO_OF_TRANSACTIONS=2000"} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm -timescale 1ns/1ps} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} \
             -value {-testplusarg UVM_TESTNAME=ifft64_test -testplusarg UVM_VERBOSITY=UVM_LOW, -testplusarg sv_seed=123} \
             -objects [get_filesets sim_1]
launch_simulation
