`ifndef IFFT64_SCOREBOARD
`define IFFT64_SCOREBOARD

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_transaction.sv"

class ifft64_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ifft64_scoreboard);

  ifft64_transaction exp_trans;
  ifft64_transaction act_trans;
  int counter;
  int err_counter;

  // uvm_analysis_imp #(ifft64_transaction, ifft64_scoreboard) analysis_imp;
  uvm_analysis_export #(ifft64_transaction) rm2sb_export;
  uvm_analysis_export #(ifft64_transaction) mon2sb_export;
  uvm_tlm_analysis_fifo #(ifft64_transaction) rm2sb_export_fifo;
  uvm_tlm_analysis_fifo #(ifft64_transaction) mon2sb_export_fifo;

  function new(string name="ifft64_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // analysis_imp = new("analysis_imp", this);
    rm2sb_export = new("rm2sb_export", this);
    mon2sb_export = new("mon2sb_export", this);
    rm2sb_export_fifo = new("rm2sb_export_fifo", this);
    mon2sb_export_fifo = new("mon2sb_export_fifo", this);
  endfunction // build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    rm2sb_export.connect(rm2sb_export_fifo.analysis_export);
    mon2sb_export.connect(mon2sb_export_fifo.analysis_export);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      rm2sb_export_fifo.get(exp_trans);
      if(exp_trans==null)
        $stop;
      mon2sb_export_fifo.get(act_trans);
      if(act_trans==null)
        $stop;
      // compare
      `uvm_info(get_full_name(),$sformatf("actual ifft64 %s", act_trans.sprint()), UVM_LOW);
      `uvm_info(get_full_name(),$sformatf("expected ifft64 %s",exp_trans.sprint()), UVM_LOW);
      for (int i = 0; i < 80; i++) begin
        if ((exp_trans.time_data_re[i] != act_trans.time_data_re[i]) || (exp_trans.time_data_im[i] != act_trans.time_data_im[i])) begin
          err_counter++;
          `uvm_info(get_full_name(),$sformatf("Scoreboard Error! ref: %d %d, rec: %d %d",
                    exp_trans.time_data_re[i], exp_trans.time_data_im[i], act_trans.time_data_re[i], act_trans.time_data_im[i]), UVM_LOW);
        end
        counter++;
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    if(err_counter == 0) begin
      $display("-------------------------------------------------");
      $display("------ INFO : TEST CASE PASSED ------------------");
      $display("-----------------------------------------");
    end else begin
      $display("---------------------------------------------------");
      $display("------ ERROR : TEST CASE FAILED ------------------");
      $display("---------------------------------------------------");
    end
  endfunction

endclass // ifft64_scoreboard

`endif
