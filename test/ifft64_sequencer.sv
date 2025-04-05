`ifndef IFFT64_SEQUENCER
`define IFFT64_SEQUENCER

`include "uvm_macros.svh"
import uvm_pkg::*;

class ifft64_sequencer extends uvm_sequencer #(ifft64_transaction);
	`uvm_component_utils(ifft64_sequencer)

	function new(string name="ifft64_sequence", uvm_component parent=null);
		super.new(name, parent);
	endfunction // new

endclass // ifft64_sequencer

`endif //  `ifndef IFFT64_SEQUENCER
