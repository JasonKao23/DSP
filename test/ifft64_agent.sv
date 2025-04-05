`ifndef IFFT64_AGENT
`define IFFT64_AGENT

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_driver.sv"
`include "ifft64_monitor.sv"
`include "ifft64_sequencer.sv"

class ifft64_agent extends uvm_agent;
  `uvm_component_utils(ifft64_agent)
  function new(string name="ifft64_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  ifft64_driver driver;
  ifft64_monitor monitor;
  ifft64_sequencer sequencer;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver = ifft64_driver::type_id::create("driver", this);
    monitor = ifft64_monitor::type_id::create("monitor", this);
    sequencer = ifft64_sequencer::type_id::create("sequencer", this);
  endfunction // build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction // connect_phase

endclass // ifft64_agent

`endif
