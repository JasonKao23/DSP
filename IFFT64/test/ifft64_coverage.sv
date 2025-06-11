`ifndef IFFT64_COVERAGE
`define IFFT64_COVERAGE

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ifft64_transaction.sv"

class ifft64_coverage #(type T=ifft64_transaction) extends uvm_subscriber #(T);
  `uvm_component_utils(ifft64_coverage);

  ifft64_transaction cov_trans;

  covergroup ifft64_cg;
    option.per_instance = 1;
    option.goal = 100;

  endgroup

  function new(string name="ifft64_coverage", uvm_component parent=null);
    super.new(name, parent);
    cov_trans = new();
    ifft64_cg = new();
  endfunction

  function void write(T t);
    cov_trans = t;
    ifft64_cg.sample();
  endfunction

endclass

`endif
