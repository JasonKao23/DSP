module acs_butterfly #(
  parameter BM_WIDTH = 9,
  parameter PM_WIDTH = 12
) (
  input                 clock,
  input                 reset,
  input [PM_WIDTH-1:0]  in_pm0,
  input [PM_WIDTH-1:0]  in_pm1,
  input [BM_WIDTH-1:0]  in_bm,
  input                 in_valid,
  output [PM_WIDTH-1:0] out_pm0,
  output [PM_WIDTH-1:0] out_pm1,
  output                out_ph0,
  output                out_ph1
);

  reg [PM_WIDTH-1:0]    pm0;
  reg [PM_WIDTH-1:0]    pm1;
  reg                   ph0;
  reg                   ph1;

  wire [PM_WIDTH-1:0]   pm0t [1:0];
  wire [PM_WIDTH-1:0]   pm1t [1:0];
  wire [PM_WIDTH-1:0]   d0;
  wire [PM_WIDTH-1:0]   d1;

  assign pm0t[0] = in_pm0 + {{(PM_WIDTH-BM_WIDTH){in_bm[BM_WIDTH-1]}}, in_bm};
  assign pm0t[1] = in_pm1 - {{(PM_WIDTH-BM_WIDTH){in_bm[BM_WIDTH-1]}}, in_bm};
  assign pm1t[0] = in_pm0 - {{(PM_WIDTH-BM_WIDTH){in_bm[BM_WIDTH-1]}}, in_bm};
  assign pm1t[1] = in_pm1 + {{(PM_WIDTH-BM_WIDTH){in_bm[BM_WIDTH-1]}}, in_bm};

  assign d0 = pm0t[0] - pm0t[1];
  assign d1 = pm1t[0] - pm1t[1];

  always @ (posedge clock) begin
    if (reset) begin
      pm0 <= 0;
      pm1 <= 0;
    end else if (in_valid) begin
      pm0 <= d0[PM_WIDTH-1] ? pm0t[1] : pm0t[0];
      pm1 <= d1[PM_WIDTH-1] ? pm1t[1] : pm1t[0];
    end else begin
      pm0 <= pm0;
      pm1 <= pm1;
    end
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (in_valid) begin
      ph0 <= d0[PM_WIDTH-1];
      ph1 <= d1[PM_WIDTH-1];
    end else begin
      ph0 <= 0;
      ph1 <= 0;
    end
  end

  assign out_pm0 = pm0;
  assign out_pm1 = pm1;
  assign out_ph0 = ph0;
  assign out_ph1 = ph1;

endmodule // acs_butterfly
