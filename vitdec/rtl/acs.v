module acs #(
  parameter BM_WIDTH = 9,
  parameter PM_WIDTH = 12
) (
  input                clock,
  input                reset,
  input [BM_WIDTH-1:0] bm0,
  input [BM_WIDTH-1:0] bm1,
  input [BM_WIDTH-1:0] bm2,
  input [BM_WIDTH-1:0] bm3,
  input                bm_valid,
  output [63:0]        ph
);

  reg [63:0]           ph_reg = 64'b0;
  reg [1:0]            bm_valid_delay = 2'b0;

  reg [BM_WIDTH-1:0]   in_bm [31:0];
  reg                  in_bm_valid;
  wire [PM_WIDTH-1:0]  in_pm0 [31:0];
  wire [PM_WIDTH-1:0]  in_pm1 [31:0];
  wire [PM_WIDTH-1:0]  out_pm0 [31:0];
  wire [PM_WIDTH-1:0]  out_pm1 [31:0];
  wire [31:0]          out_ph0;
  wire [31:0]          out_ph1;

  always @ (posedge clock) begin
    if (bm_valid_delay[1])
      ph_reg <= {out_ph1, out_ph0};
    else
      ph_reg <= ph_reg;
  end

  assign ph = ph_reg;

  always @ (posedge clock) begin
    bm_valid_delay <= {bm_valid_delay[0], bm_valid};
  end

  genvar                i;
  generate
    for (i = 0; i < 16; i = i + 1) begin: input_pm
      assign in_pm0[i] = out_pm0[2*i];
      assign in_pm1[i] = out_pm0[2*i+1];
      assign in_pm0[i+16] = out_pm1[2*i];
      assign in_pm1[i+16] = out_pm1[2*i+1];
    end
  endgenerate

  always @ (posedge clock) begin
    in_bm[0] <= bm0;
    in_bm[1] <= bm2;
    in_bm[2] <= bm0;
    in_bm[3] <= bm2;
    in_bm[4] <= bm3;
    in_bm[5] <= bm1;
    in_bm[6] <= bm3;
    in_bm[7] <= bm1;
    in_bm[8] <= bm3;
    in_bm[9] <= bm1;
    in_bm[10] <= bm3;
    in_bm[11] <= bm1;
    in_bm[12] <= bm0;
    in_bm[13] <= bm2;
    in_bm[14] <= bm0;
    in_bm[15] <= bm2;
    in_bm[16] <= bm1;
    in_bm[17] <= bm3;
    in_bm[18] <= bm1;
    in_bm[19] <= bm3;
    in_bm[20] <= bm2;
    in_bm[21] <= bm0;
    in_bm[22] <= bm2;
    in_bm[23] <= bm0;
    in_bm[24] <= bm2;
    in_bm[25] <= bm0;
    in_bm[26] <= bm2;
    in_bm[27] <= bm0;
    in_bm[28] <= bm1;
    in_bm[29] <= bm3;
    in_bm[30] <= bm1;
    in_bm[31] <= bm3;
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    in_bm_valid <= bm_valid;
  end

  generate
    for (i = 0; i < 32; i = i + 1) begin: acs_bfly
      acs_butterfly #(
        .BM_WIDTH(BM_WIDTH),
        .PM_WIDTH(PM_WIDTH)
      ) bfy(
        .clock(clock),
        .reset(reset),
        .in_pm0(in_pm0[i]),
        .in_pm1(in_pm1[i]),
        .in_bm(in_bm[i]),
        .in_valid(in_bm_valid),
        .out_pm0(out_pm0[i]),
        .out_pm1(out_pm1[i]),
        .out_ph0(out_ph0[i]),
        .out_ph1(out_ph1[i])
      );
    end // block: acs_bfly
  endgenerate

endmodule // acs
