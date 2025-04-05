`ifndef IFFT64_DRIVER
`define IFFT64_DRIVER

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_transaction.sv"

class ifft64_driver extends uvm_driver #(ifft64_transaction);
  `uvm_component_utils(ifft64_driver)

  virtual ifft64_interface vif;
  uvm_analysis_port #(ifft64_transaction) drv2rm_port;

  function new(string name = "ifft64_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv2rm_port = new("drv2rm_port", this);
    if (!uvm_config_db #(virtual ifft64_interface)::get(this, "", "ifft64_interface", vif)) begin
      `uvm_fatal(get_type_name(), "Didn't get handle to virtual interface dut_if")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    reset();
    forever begin
      `uvm_info(get_type_name(), $sformatf("Waiting for data from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      // `uvm_info(get_type_name(), $sformatf("Receive data from sequencer %s", req.sprint()), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("Receive data from sequencer"), UVM_LOW)
      drive_item();
      @ (vif.dr_cb);
      $cast(rsp, req.clone());;
      rsp.set_id_info(req);
      drv2rm_port.write(rsp);
      seq_item_port.item_done();
      seq_item_port.put(rsp);
    end
  endtask // run_phase

  virtual task drive_item();
    wait (!vif.rst);
    @ (vif.dr_cb);
    for (int i = 0; i < 64; i++) begin
      while (vif.dr_cb.in_ready == 0) @ (vif.dr_cb);
      vif.dr_cb.in_re <= req.freq_data_re[i];
      vif.dr_cb.in_im <= req.freq_data_im[i];
      vif.in_valid <= 1;
      @ (vif.dr_cb);
    end
    vif.dr_cb.in_re <= 0;
    vif.dr_cb.in_im <= 0;
    vif.in_valid <= 0;
  endtask // drive_item

  task reset();
    vif.dr_cb.rst <= 1;
    vif.dr_cb.in_re <= 0;
    vif.dr_cb.in_im <= 0;
    vif.in_valid <= 0;
    vif.out_ready <= 0;
    repeat (5) @ (vif.dr_cb);
    vif.dr_cb.rst <= 0;
    vif.out_ready <= 1;
  endtask // reset

endclass // ifft64_driver

`endif
