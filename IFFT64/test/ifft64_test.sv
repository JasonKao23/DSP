`ifndef IFFT64_TEST
`define IFFT64_TEST

`include "uvm_macros.svh"
import uvm_pkg::*;

class ifft64_test extends uvm_test;
  `uvm_component_utils(ifft64_test)

  ifft64_env env;
  ifft64_seq seq;

  function new(string name="ifft64_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ifft64_env::type_id::create("env", this);
    seq = ifft64_seq::type_id::create("seq", this);
  endfunction
  
  virtual function void end_of_elaboration_phase (uvm_phase phase);
    uvm_top.print_topology ();
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this, "start of sequence");
    // apply reset
    seq.start(env.agnt.sequencer);
    phase.drop_objection(this, "end of sequence");
  endtask

endclass

`endif
