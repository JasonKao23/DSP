module bfly #(
  parameter DWIDTH = 16,
  parameter WWIDTH = 16
) (
  input               clk,
  input               rst,
  input [DWIDTH-1:0]  in_re,
  input [DWIDTH-1:0]  in_im,
  input [WWIDTH-1:0]  w_re,
  input [WWIDTH-1:0]  w_im,
  input               start,
  output [DWIDTH-1:0] out_re,
  output [DWIDTH-1:0] out_im,
  output              out_valid
);
  reg [1:0]            stage;
  reg [9:0]            valid;
  // input registers
  reg [DWIDTH-1:0]     in_re_delay;
  reg [DWIDTH-1:0]     in_im_delay;
  // butterfly
  reg [DWIDTH-1:0]     u0_re;
  reg [DWIDTH-1:0]     u0_im;
  reg [DWIDTH-1:0]     u1_re;
  reg [DWIDTH-1:0]     u1_im;
  reg [DWIDTH-1:0]     u2_re;
  reg [DWIDTH-1:0]     u2_im;
  reg [DWIDTH-1:0]     u3_re;
  reg [DWIDTH-1:0]     u3_im;
  // output delay
  reg [DWIDTH-1:0]     u0_re_delay [4:0];
  reg [DWIDTH-1:0]     u0_im_delay [4:0];
  // delay for complex multiplication
  reg [WWIDTH-1:0]     w_re_delay [3:0];
  reg [WWIDTH-1:0]     w_im_delay [3:0];
  reg [DWIDTH-1:0]     u2_re_delay;
  reg [DWIDTH-1:0]     u2_im_delay;
  reg [DWIDTH-1:0]     u3_re_delay [1:0];
  reg [DWIDTH-1:0]     u3_im_delay [1:0];
  // complex multipication interface
  reg [DWIDTH-1:0]     in_a_re;
  reg [DWIDTH-1:0]     in_a_im;
  wire [WWIDTH-1:0]    in_b_re;
  wire [WWIDTH-1:0]    in_b_im;
  /* verilator lint_off UNUSED */
  wire [DWIDTH+WWIDTH:0] out_c_re;
  wire [DWIDTH+WWIDTH:0] out_c_im;
  /* verilator lint_on UNUSED */

  always @ (posedge clk) begin
    if (start)
      stage <= 0;
    else
      stage <= stage + 1;
  end

  always @ (posedge clk) begin
    if (rst)
      valid <= 0;
    else
      valid <= {valid[8:0], start};
  end

  always @ (posedge clk) begin
    in_re_delay <= in_re;
    in_im_delay <= in_im;
  end

  // butterfly
  always @ (posedge clk) begin
    case (stage)
      2'b00: begin
        u0_re <= in_re_delay;
        u0_im <= in_im_delay;
        u1_re <= in_re_delay;
        u1_im <= in_im_delay;
        u2_re <= in_re_delay;
        u2_im <= in_im_delay;
        u3_re <= in_re_delay;
        u3_im <= in_im_delay;
      end
      2'b01: begin
        u0_re <= u0_re + in_re_delay;
        u0_im <= u0_im + in_im_delay;
        u1_re <= u1_re - in_im_delay;
        u1_im <= u1_im + in_re_delay;
        u2_re <= u2_re - in_re_delay;
        u2_im <= u2_im - in_im_delay;
        u3_re <= u3_re + in_im_delay;
        u3_im <= u3_im - in_re_delay;
      end
      2'b10: begin
        u0_re <= u0_re + in_re_delay;
        u0_im <= u0_im + in_im_delay;
        u1_re <= u1_re - in_re_delay;
        u1_im <= u1_im - in_im_delay;
        u2_re <= u2_re + in_re_delay;
        u2_im <= u2_im + in_im_delay;
        u3_re <= u3_re - in_re_delay;
        u3_im <= u3_im - in_im_delay;
      end
      2'b11: begin
        u0_re <= u0_re + in_re_delay;
        u0_im <= u0_im + in_im_delay;
        u1_re <= u1_re + in_im_delay;
        u1_im <= u1_im - in_re_delay;
        u2_re <= u2_re - in_re_delay;
        u2_im <= u2_im - in_im_delay;
        u3_re <= u3_re - in_im_delay;
        u3_im <= u3_im + in_re_delay;
      end
    endcase // case (stage)
  end // always @ (posedge clk)

  // output delay
  integer          i;
  always @ (posedge clk) begin
    u0_re_delay[0] <= u0_re;
    u0_im_delay[0] <= u0_im;
    for (i = 1; i < 5; i = i + 1) begin
        u0_re_delay[i] <= u0_re_delay[i-1];
        u0_im_delay[i] <= u0_im_delay[i-1];
    end
  end

  always @ (posedge clk) begin
    w_re_delay[0] <= w_re;
    w_im_delay[0] <= w_im;
    for (i = 1; i < 4; i = i + 1) begin
        w_re_delay[i] <= w_re_delay[i-1];
        w_im_delay[i] <= w_im_delay[i-1];
    end
  end

  always @ (posedge clk) begin
    u2_re_delay <= u2_re;
    u2_im_delay <= u2_im;
  end

  always @ (posedge clk) begin
    u3_re_delay[0] <= u3_re;
    u3_im_delay[0] <= u3_im;
    u3_re_delay[1] <= u3_re_delay[0];
    u3_im_delay[1] <= u3_im_delay[0];
  end

  // complex multiplication
  always @ (*) begin
    case (stage)
      2'b00: begin
          in_a_re = u1_re;
          in_a_im = u1_im;
      end
      2'b01: begin
          in_a_re = u2_re_delay;
          in_a_im = u2_im_delay;
      end
      2'b10: begin
          in_a_re = u3_re_delay[1];
          in_a_im = u3_im_delay[1];
      end
      2'b11: begin
          in_a_re = 0;
          in_a_im = 0;
      end
    endcase // case (stage)
  end // always @ (*)

  assign in_b_re = w_re_delay[3];
  assign in_b_im = w_im_delay[3];

  cmult #(
    .AWIDTH(WWIDTH),
    .BWIDTH(DWIDTH)
  ) cmult_inst (
    .clk(clk),
    .ar(in_b_re),
    .ai(in_b_im),
    .br(in_a_re),
    .bi(in_a_im),
    .pr(out_c_re),
    .pi(out_c_im));

  assign out_re = valid[9] ? u0_re_delay[4] : out_c_re[DWIDTH+WWIDTH-3:WWIDTH-2];
  assign out_im = valid[9] ? u0_im_delay[4] : out_c_im[DWIDTH+WWIDTH-3:WWIDTH-2];
  assign out_valid = valid[9];

endmodule // bfly
