`ifndef IFFT64_SEQ
`define IFFT64_SEQ

`include "uvm_macros.svh"
import uvm_pkg::*;

`define NO_OF_TRANSACTIONS 100

class ifft64_seq extends uvm_sequence #(ifft64_transaction);
  `uvm_object_utils(ifft64_seq)
  function new(string name="ifft64_seq");
    super.new(name);
  endfunction

  virtual task body();
    for (int i = 0; i < `NO_OF_TRANSACTIONS; i++) begin
      req = ifft64_transaction::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      // `uvm_info(get_type_name(),$sformatf("RANDOMIZED TRANSACTION FROM SEQUENCE %s", req.sprint()),UVM_LOW);
      `uvm_info(get_type_name(),$sformatf("RANDOMIZED TRANSACTION FROM SEQUENCE"),UVM_LOW);
      finish_item(req);
      get_response(rsp);
    end
    `uvm_info("SEQ", $sformatf("Done generation of %0d items", `NO_OF_TRANSACTIONS), UVM_LOW)
  endtask
endclass

`endif
