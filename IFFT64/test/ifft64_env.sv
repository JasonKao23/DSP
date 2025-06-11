`ifndef IFFT64__ENV
`define IFFT64_ENV

`include "uvm_macros.svh"
import uvm_pkg::*;

class ifft64_env extends uvm_env;
  `uvm_component_utils(ifft64_env)
  function new(string name="ifft64_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  ifft64_agent agnt;
  ifft64_ref_model ref_model;
  ifft64_coverage #(ifft64_transaction) coverage;
  ifft64_scoreboard sb;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt = ifft64_agent::type_id::create("agnt", this);
    ref_model = ifft64_ref_model::type_id::create("ref_model", this);
    coverage = ifft64_coverage::type_id::create("coverage", this);
    sb = ifft64_scoreboard::type_id::create("sb", this);
  endfunction // build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.monitor.mon_analysis_port.connect(sb.mon2sb_export);
    agnt.driver.drv2rm_port.connect(ref_model.drv2rm_export);
    ref_model.rm2sb_port.connect(coverage.analysis_export);
    ref_model.rm2sb_port.connect(sb.rm2sb_export);
  endfunction // connect_phase

endclass // ifft64_env

`endif
