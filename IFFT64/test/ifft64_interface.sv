`ifndef IFFT64_INTERFACE
`define IFFT64_INTERFACE

interface ifft64_interface(
  input logic clk
);
  logic        rst;
  logic [15:0] in_re;
  logic [15:0] in_im;
  logic        in_valid;
  logic        in_ready;
  logic        out_ready;
  logic [23:0] out_re;
  logic [23:0] out_im;
  logic        out_valid;

  // clocking block and mobport declaration for driver
  clocking dr_cb @ (posedge clk);
    default input #3 output #2;
    output     rst;
    output     in_re;
    output     in_im;
    output     in_valid;
    output     out_ready;
    input      in_ready;
    input      out_re;
    input      out_im;
    input      out_valid;
  endclocking // dr_cb

  // clocking block and mobport declaration for monitor
  clocking rc_cb @ (negedge clk);
    input rst;
    input in_re;
    input in_im;
    input in_valid;
    input out_ready;
    input in_ready;
    input out_re;
    input out_im;
    input out_valid;
  endclocking // dr_cb

endinterface // adder_interface

`endif
