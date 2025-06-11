module ram_dp #(
  parameter DSIZE = 32,
  parameter ASIZE = 6,
  parameter DEPTH = 2**ASIZE
) (
  input clock,
  input              wen,
  input [ASIZE-1:0]  waddr,
  input [ASIZE-1:0]  raddr,
  input [DSIZE-1:0]  wdata,
  output [DSIZE-1:0] rdata
);

  reg [DSIZE-1:0]    ram [DEPTH-1:0];
  reg [DSIZE-1:0]    dr;

  always @ (posedge clock)
    if (wen)
      ram[waddr] <= wdata;

  always @ (posedge clock)
    dr <= ram[raddr];

  assign rdata = dr;

endmodule // ram_dp
