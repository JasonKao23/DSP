`ifndef IFFT64_TRANSACTION
`define IFFT64_TRANSACTION

`include "uvm_macros.svh"
import uvm_pkg::*;

class ifft64_transaction extends uvm_sequence_item;
  // input data in frequency domain
  rand bit signed [15:0] freq_data_re[64];
  rand bit signed [15:0] freq_data_im[64];
  // output data in time domain
  bit signed [22:0] time_data_re[80];
  bit signed [22:0] time_data_im[80];
  // IFFT transaction counter
  static int static_counter = 0;
  int counter;

	`uvm_object_utils_begin(ifft64_transaction)
		`uvm_field_sarray_int(freq_data_re, UVM_ALL_ON)
		`uvm_field_sarray_int(freq_data_im, UVM_ALL_ON)
		`uvm_field_sarray_int(time_data_re, UVM_ALL_ON)
		`uvm_field_sarray_int(time_data_im, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name="ifft64_transaction");
		super.new(name);
		counter = static_counter++;
	endfunction // new

  constraint in_samples {
    foreach (freq_data_re[i]) {
      freq_data_re[i] inside {[-4096:-1024], [1024:4096]};
    }
    foreach (freq_data_im[i]) {
      freq_data_im[i] inside {[-4096:-1024], [1024:4096]};
    }
  }

	function void post_randomize();
	endfunction // post_randomize

endclass // adder_transaction

`endif
