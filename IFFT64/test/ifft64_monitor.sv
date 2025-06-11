`ifndef IFFT64_MONITOR
`define IFFT64_MONITOR

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_transaction.sv"

class ifft64_monitor extends uvm_monitor;
  `uvm_component_utils(ifft64_monitor)

  uvm_analysis_port #(ifft64_transaction) mon_analysis_port;
  virtual ifft64_interface vif;
  ifft64_transaction act_trans;

  function new(string name="ifft64_monitor", uvm_component parent=null);
    super.new(name, parent);
    act_trans = new();
  endfunction // new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual ifft64_interface)::get(this, "", "ifft64_interface", vif)) begin
      `uvm_error(get_type_name(), "DUT interface not found")
    end
    mon_analysis_port = new("mon_analysis_port", this);
  endfunction // build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      repeat (100) @ (vif.rc_cb);
      // wait out_valid
      while (vif.rc_cb.out_valid == 0) @ (vif.rc_cb);
      // ready output samples
      for (int i = 0; i < 80; i++) begin
        while (vif.rc_cb.out_valid == 0) @ (vif.rc_cb);
        act_trans.time_data_re[i] = vif.out_re;
        act_trans.time_data_im[i] = vif.out_im;
        @ (vif.rc_cb);
      end
      //`uvm_info(get_type_name(), $sformatf("Monitor found packet %s", act_trans.sprint()), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("Monitor found packet"), UVM_LOW)
      // act_trans.print();
      mon_analysis_port.write(act_trans);
    end
  endtask // run_phase
endclass // ifft64_monitor

`endif
