`ifndef IFFT64_TB_TOP
`define IFFT64_TB_TOP

`include "uvm_macros.svh"
`include "ifft64_interface.sv"

import uvm_pkg::*;

`include "ifft64_test.sv"

module ifft64_tb_top;
  parameter cycle_period = 10;
  bit clk;

  initial begin
    clk = 0;
    forever #(cycle_period/2) clk = ~clk;
  end
  
  ifft64_interface ifft64_intf(clk);

  ifft64 #(
    .DWIDTH(16)
  ) fft64_inst (
    .clk(clk),
    .rst(ifft64_intf.rst),
    .out_ready(ifft64_intf.out_ready),
    .in_re(ifft64_intf.in_re),
    .in_im(ifft64_intf.in_im),
    .in_valid(ifft64_intf.in_valid),
    .in_ready(ifft64_intf.in_ready),
    .out_re(ifft64_intf.out_re),
    .out_im(ifft64_intf.out_im),
    .out_valid(ifft64_intf.out_valid)
  );

  initial begin
    uvm_config_db #(virtual ifft64_interface)::set(uvm_root::get(), "*", "ifft64_interface", ifft64_intf);
  end

  initial begin
    run_test();
  end

endmodule

`endif
