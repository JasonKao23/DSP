`timescale 1ns / 1ps

module ifft64 #(
  parameter DWIDTH = 16
) (
   input                      clk,
   input                      rst,
   input signed [DWIDTH-1:0]  in_re,
   input signed [DWIDTH-1:0]  in_im,
   input                      in_valid,
   output                     in_ready,
   input                      out_ready,
   output signed [DWIDTH+7:0] out_re,
   output signed [DWIDTH+7:0] out_im,
   output                     out_valid
);

  reg [1:0]                   state, nextstate;
  localparam                  S_INOUT = 2'b00;
  localparam                  S_PROC_STAGE1 = 2'b01;
  localparam                  S_PROC_STAGE2 = 2'b11;
  localparam                  S_PROC_STAGE3 = 2'b10;

  // input
  reg                         input_done;
  reg [5:0]                   input_counter;
  reg                         in_ready_reg;
  // proc
  reg [6:0]                   proc_counter;
  // output
  reg                         output_ready;
  reg [6:0]                   output_counter;
  reg                         output_done;
  reg                         out_valid_reg;
  reg [2:0]                   out_valid_reg_delay;
  reg signed [DWIDTH+7:0]     out_re_reg;
  reg signed [DWIDTH+7:0]     out_im_reg;

  // butterfy interface
  reg                         bfly_st;
  reg [2:0]                   bfly_st_delay;
  reg [5:0]                   bfly_w_addr;
  reg [DWIDTH*2+15:0]         bfly_d;
  wire [DWIDTH*2-1:0]         bfly_w;
  wire signed [DWIDTH+7:0]    bflyout_re;
  wire signed [DWIDTH+7:0]    bflyout_im;
  wire [DWIDTH*2-1:0]         bfly_w_delay;

  // data RAM interface
  reg [5:0]                   rdaddr;
  reg                         rdaddr_valid;
  wire [5:0]                  wraddr;
  reg [15:0]                  wraddr_valid;
  reg [14:0]                  ramsel;
  reg                         wen;
  reg [5:0]                   waddr;
  reg [DWIDTH*2+15:0]         wdata;
  wire [DWIDTH*2+15:0]        rdata;

  // output RAM interface
  reg                         wout_en;
  reg [5:0]                   wout_waddr;
  reg [5:0]                   wout_raddr;
  reg [DWIDTH*2+15:0]         wout_wdata;
  wire [DWIDTH*2+15:0]        out_data;

  // state register
  always @ (posedge clk) begin
    if (rst)
      state <= S_INOUT;
    else
      state <= nextstate;
  end

  // next stage logic
  always @ (*) begin
    case (state)
      S_INOUT:
        if (input_done & output_done)
          nextstate = S_PROC_STAGE1;
        else
          nextstate = S_INOUT;
      S_PROC_STAGE1:
        if (proc_counter[5:0] == 63)
          nextstate = S_PROC_STAGE2;
        else
          nextstate = S_PROC_STAGE1;
      S_PROC_STAGE2:
        if (proc_counter[5:0] == 63)
          nextstate = S_PROC_STAGE3;
        else
          nextstate = S_PROC_STAGE2;
      S_PROC_STAGE3:
        if (proc_counter == 77)
          nextstate = S_INOUT;
        else
          nextstate = S_PROC_STAGE3;
      default:
        nextstate = S_INOUT;
    endcase // case (state)
  end // always @ (*)

  // input counter
  always @ (posedge clk) begin
    if (state == S_INOUT) begin
      if (in_ready & in_valid & (~input_done))
        input_counter <= input_counter + 1;
      else
        input_counter <= input_counter;
    end else begin
      input_counter <= 0;
    end
  end

  // input done flag
  always @ (posedge clk) begin
    if (rst | (state != S_INOUT))
      input_done <= 0;
    else if ((input_counter == 63) & in_valid)
      input_done <= 1;
    else
      input_done <= input_done;
  end

  // input ready
  always @ (posedge clk) begin
    in_ready_reg <= ((state != S_INOUT) |
                     input_done |
                     ((input_counter == 63) & in_valid))
                    ? 0
                    : 1;
  end
  assign in_ready = in_ready_reg;

  // process counter
  always @ (posedge clk) begin
    if (state != S_INOUT)
      proc_counter <= proc_counter + 1;
    else
      proc_counter <= 0;
  end

  // ouput ready
  always @ (posedge clk) begin
    if ((state == S_PROC_STAGE3) & (proc_counter == 77))
      output_ready <= 1;
    else if ((state == S_INOUT) & (~output_done))
      output_ready <= output_ready;
    else
      output_ready <= 0;
  end

  // output counter
  always @ (posedge clk) begin
  if (state == S_INOUT)
    if (out_ready & (~output_done))
      output_counter <= output_counter + 1;
    else
      output_counter <= output_counter;
  else
    output_counter <= 7'd48;
  end

  // output done
  always @ (posedge clk) begin
  if (rst)
    output_done <= 1;
  else
    if (state == S_INOUT)
      if ((output_counter == 127) & out_ready)
        output_done <= 1;
      else
        output_done <= output_done;
    else
      output_done <= 0;
  end // always @ (posedge clk)

  // read address
  always @ (posedge clk) begin
    case (state)
      S_PROC_STAGE1:
        rdaddr <= {proc_counter[1:0], 4'b0} + {2'b0, proc_counter[5:2]};
      S_PROC_STAGE2:
        rdaddr <= {proc_counter[5:4], proc_counter[1:0], proc_counter[3:2]};
      S_PROC_STAGE3:
        rdaddr <= proc_counter[5:0];
      default:
        rdaddr <= 0;
    endcase // case (state)

    rdaddr_valid <= ((state != S_INOUT) & (proc_counter[1:0] == 0)) ? 1 : 0;
  end // always @ (posedge clk)

  // write address
  integer    i;
  always @ (posedge clk) begin
    wraddr_valid[0] <= rdaddr_valid;
    for (i = 1; i < 16; i = i + 1)
      wraddr_valid[i] <= wraddr_valid[i-1];
  end // always @ (posedge clk)

  shift_registers_srl #(
    .CLOCK_CYCLES(13),
    .DATA_WIDTH(6)
  ) waddr_delay_inst (
    .clk(clk),
    .clken(1'b1),
    .data_in(rdaddr),
    .data_out(wraddr)
  );

  always @ (posedge clk) begin
    ramsel[0] <= (state == S_PROC_STAGE3) ? 1 : 0;
    for (i = 1; i < 15; i = i + 1)
      ramsel[i] <= ramsel[i-1];
  end // always @ (posedge clk)

  always @ (posedge clk) begin
    waddr <= (state == S_INOUT) ? input_counter : wraddr;
  end

  always @ (posedge clk) begin
    if (state == S_INOUT)
      wen <= (~input_done) & in_valid;
    else if (~(ramsel[0] & ramsel[13]))
      wen <= |wraddr_valid[15:12];
    else
      wen <= 0;
  end

  always @ (posedge clk) begin
    wdata <= (state == S_INOUT)
           ? {{8{in_im[DWIDTH-1]}}, in_im, {8{in_re[DWIDTH-1]}}, in_re}
           : {bflyout_im, bflyout_re};
  end

  ram_dp #(
    .DSIZE(DWIDTH*2+16),
    .ASIZE(6),
    .DEPTH(64)
  ) data_ram(
    .clk(clk),
    .wen(wen),
    .waddr(waddr),
    .raddr(rdaddr),
    .wdata(wdata),
    .rdata(rdata));

  // read/write output buffer
  always @ (posedge clk) begin
    wout_en <= ramsel[0] & ramsel[14];
    wout_waddr <= ramsel[14] ? waddr : 0;
    wout_wdata <= ramsel[14] ? wdata : 0;
  end

  always @ (posedge clk) begin
    wout_raddr <= {output_counter[1:0],
                   output_counter[3:2],
                   output_counter[5:4]};
  end

  ram_dp #(
    .DSIZE(DWIDTH*2+16),
    .ASIZE(6),
    .DEPTH(64)
  ) out_ram (
    .clk(clk),
    .wen(wout_en),
    .waddr(wout_waddr),
    .raddr(wout_raddr),
    .wdata(wout_wdata),
    .rdata(out_data));

  always @ (posedge clk) begin
    out_valid_reg <= output_ready & (~output_done);
    out_valid_reg_delay <= {out_valid_reg_delay[1:0], out_valid_reg};
  end

  always @ (posedge clk) begin
    out_re_reg <= out_data[DWIDTH+7:0];
    out_im_reg <= out_data[2*DWIDTH+15:DWIDTH+8];
  end

  assign out_re = out_re_reg;
  assign out_im = out_im_reg;
  assign out_valid = out_valid_reg_delay[2];

  // read twiddle factor
  always @ (posedge clk) begin
    bfly_d <= rdata;
  end

  always @ (posedge clk) begin
  case (state)
    S_PROC_STAGE1:
      bfly_w_addr <= {1'b0, proc_counter[5:2], 1'b0}
                   + {2'b0, proc_counter[5:2]}
                   + {4'b0, proc_counter[1:0]};
    S_PROC_STAGE2:
      bfly_w_addr <= {1'b0, proc_counter[3:2], 3'b0}
                   + {2'b0, proc_counter[3:2], 2'b0}
                   + {4'b0, proc_counter[1:0]};
    default:
    bfly_w_addr <= 0;
  endcase // case (state)
  end // always @ (posedge clk)

  ifft64_tw_rom tw_rom_inst (
    .clk(clk),
    .enable(1'b1),
    .addr(bfly_w_addr),
    .dout(bfly_w));

  shift_registers_srl #(
    .CLOCK_CYCLES(3),
    .DATA_WIDTH(DWIDTH*2)
  ) bfly_delay_inst (
    .clk(clk),
    .clken(1'b1),
    .data_in(bfly_w),
    .data_out(bfly_w_delay)
  );

  // butterfly instant
  always @ (posedge clk) begin
    if ((state != S_INOUT) & (proc_counter[1:0] == 0))
      bfly_st <= 1;
    else
      bfly_st <= 0;
    bfly_st_delay <= {bfly_st_delay[1:0], bfly_st};
  end

   /* verilator lint_off PINCONNECTEMPTY */
   bfly #(
     .DWIDTH(DWIDTH+8),
     .WWIDTH(DWIDTH)
   ) bfly_inst (
     .clk(clk),
     .rst(rst),
     .in_re(bfly_d[DWIDTH+7:0]),
     .in_im(bfly_d[DWIDTH*2+15:DWIDTH+8]),
     .w_re(bfly_w_delay[DWIDTH-1:0]),
     .w_im(bfly_w_delay[DWIDTH*2-1:DWIDTH]),
     .start(bfly_st_delay[2]),
     .out_re(bflyout_re),
     .out_im(bflyout_im),
     .out_valid());
  /* verilator lint_on PINCONNECTEMPTY */

`ifdef __ICARUS__
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, ifft64);
end
`endif

endmodule // ifft64
