module ram_dp #(
  parameter DSIZE = 32,
  parameter ASIZE = 6,
  parameter DEPTH = 2**ASIZE
) (
  input              clk,
  input              wen,
  input [ASIZE-1:0]  waddr,
  input [ASIZE-1:0]  raddr,
  input [DSIZE-1:0]  wdata,
  output [DSIZE-1:0] rdata
);

  (* ram_style = "block" *)
  reg [DSIZE-1:0]     ram [DEPTH-1:0];
  reg [DSIZE-1:0]     dr;
  reg [DSIZE-1:0]     rdata_reg;

  always @ (posedge clk)
    if (wen)
      ram[waddr] <= wdata;

  always @ (posedge clk)
    dr <= ram[raddr];
  
  always @ (posedge clk)
     rdata_reg <= dr;

  assign rdata = rdata_reg;

endmodule // ram_dp
