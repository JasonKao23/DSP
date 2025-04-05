`ifndef IFFT64_REF_MODEL
`define IFFT64_REF_MODEL

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_transaction.sv"

import "DPI-C" function void cal_ifft64(output int out_re[80], output int out_im[80],
                                        input int in_re[64], input int in_im[64]);

class ifft64_ref_model extends uvm_component;
  `uvm_component_utils(ifft64_ref_model);

  uvm_analysis_export #(ifft64_transaction) drv2rm_export;
  uvm_analysis_port #(ifft64_transaction) rm2sb_port;
  ifft64_transaction exp_trans;
  ifft64_transaction trans;
  uvm_tlm_analysis_fifo #(ifft64_transaction) exp_trans_fifo;

  function new(string name="ifft64_ref_model", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv2rm_export = new("drv2rm_export", this);
    rm2sb_port = new("rm2sb_port", this);
    exp_trans_fifo = new("exp_trans_fifo", this);
  endfunction // build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv2rm_export.connect(exp_trans_fifo.analysis_export);
  endfunction // connect_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      int in_re[64];
      int in_im[64];
      int out_re[80];
      int out_im[80];
      exp_trans_fifo.get(trans);
      exp_trans = trans;
      // compute expect value
      for (int i = 0; i < 64; i++) begin
        in_re[i] = exp_trans.freq_data_re[i];
        in_im[i] = exp_trans.freq_data_im[i];
      end
      cal_ifft64(out_re, out_im, in_re, in_im);
      for (int i = 0; i < 80; i++) begin
        exp_trans.time_data_re[i] = out_re[i];
        exp_trans.time_data_im[i] = out_im[i];
      end
      // `uvm_info(get_type_name(), $sformatf("Expected transaction from reference model %s", exp_trans.sprint()), UVM_LOW);
      `uvm_info(get_type_name(), $sformatf("Expected transaction from reference model"), UVM_LOW);
      rm2sb_port.write(exp_trans);
    end
  endtask // run_phase

endclass // ifft64_ref_model

`endif
