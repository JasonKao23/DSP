module vitdec #(
  parameter DWIDTH = 8
) (
  input              clock,
  input              reset,
  input [1:0]        coderate,
  input [14:0]       nofbits,
  input [7:0]        ndbps,
  input [DWIDTH-1:0] in_data,
  input              in_valid,
  output [7:0]       dec_byte,
  output             dec_valid
);

  // reg [31:0]          cnt;
  // always @ (posedge clock) begin
  //   if (reset)
  //     cnt <= 0;
  //   else
  //     cnt <= cnt + 1;
  // end

  // depuncture
  reg [14:0]        in_cnt;
  wire              vitin_valid;
  wire [DWIDTH-1:0] vitin [1:0];
  // calcualte BM
  reg [DWIDTH:0]    bm [3:0];
  reg [1:0]         bm_valid;
  // ACS
  wire [63:0]       ph;
  reg               ph_valid;
  // path history
  reg [9:0]         phind;
  reg [9:0]         phind_delay [1:0];
  reg               wen;
  reg [9:0]         waddr;
  reg [9:0]         raddr;
  wire [63:0]       rdata;
  // traceback
  reg [14:0]        tb_start_idx;
  reg               start_tb0;
  reg               start_tb1;
  reg               tb_running;
  reg [1:0]         tb_running_delay;
  reg [9:0]         tb_sz;
  reg [9:0]         tb_sz_delay;
  reg [9:0]         tb_pos;
  reg               tb_last;
  reg               tb_last_delay;
  wire [63:0]       phtb;
  reg               tb_start;
  reg               tb_start_delay;
  wire              tb_done;
  reg [14:0]        out_cnt;
  wire              out_bit;
  wire              out_bit_valid;
  // output
  reg               out_enable;
  reg [3:0]         out_enable_delay;
  reg [14:0]        out_nbits;
  reg [2:0]         dec_bit_cnt = 0;
  reg               dec_wen;
  reg [6:0]         dec_waddr;
  reg [6:0]         dec_raddr;
  reg [7:0]         dec_byte_in;
  wire [7:0]        dec_byte_out;
  reg [7:0]         dec_byte_reg;
  reg               dec_valid_reg;

  // depuncture
  always @ (posedge clock) begin
    if (reset)
      in_cnt <= 0;
    else begin
        if (ph_valid)
          in_cnt <= in_cnt + 1;
        else
          in_cnt <= in_cnt;
    end
  end

  depunct #(
    .DWIDTH(DWIDTH)
  ) depunct_inst(
    .clock(clock),
    .reset(reset),
    .coderate(coderate),
    .in_data(in_data),
    .in_valid(in_valid),
    .vitin0(vitin[0]),
    .vitin1(vitin[1]),
    .vitin_valid(vitin_valid)
  );

   // calcualte BM
   always @ (posedge clock) begin
      if (vitin_valid) begin
         bm[0] <= -{vitin[0][DWIDTH-1], vitin[0]} - {vitin[1][DWIDTH-1], vitin[1]};
         bm[1] <= -{vitin[0][DWIDTH-1], vitin[0]} + {vitin[1][DWIDTH-1], vitin[1]};
         bm[2] <=  {vitin[0][DWIDTH-1], vitin[0]} - {vitin[1][DWIDTH-1], vitin[1]};
         bm[3] <=  {vitin[0][DWIDTH-1], vitin[0]} + {vitin[1][DWIDTH-1], vitin[1]};
      end else begin
         bm[0] <= 0;
         bm[1] <= 0;
         bm[2] <= 0;
         bm[3] <= 0;
      end // else: !if(vitin_valid)
   end // always @ (posedge clock)

  always @ (posedge clock) begin
    bm_valid <= {bm_valid[0], vitin_valid};
  end

  // ACS
  acs #(
    .BM_WIDTH(DWIDTH+1),
    .PM_WIDTH(DWIDTH+4)
  ) acs_inst(
    .clock(clock),
    .reset(reset),
    .bm0(bm[0]),
    .bm1(bm[1]),
    .bm2(bm[2]),
    .bm3(bm[3]),
    .bm_valid(bm_valid[0]),
    .ph(ph)
  );

  // write path history into RAM
  always @ (posedge clock) begin
    if (reset)
      phind <= 0;
    else begin
      if (ph_valid)
        phind <= (phind == 653) ? 0 : phind + 1;
      else
        phind <= phind;
    end
    phind_delay[0] <= phind;
    phind_delay[1] <= phind_delay[0];
  end

  always @ (posedge clock) begin
    ph_valid <= bm_valid[1];
  end

  always @ (posedge clock) begin
    wen <= ph_valid & (~tb_last);
    waddr <= phind;
  end

  always @ (posedge clock) begin
    raddr <= tb_pos;
  end

  ram_dp #(
    .DSIZE(64),
    .ASIZE(10),
    .DEPTH(654)
  ) ph_ram(
    .clock(clock),
    .wen(wen),
    .waddr(waddr),
    .raddr(raddr),
    .wdata(ph),
    .rdata(rdata)
  );

  // traceback
  always @ (posedge clock) begin
    start_tb0 <= ((in_cnt == tb_start_idx) & (~tb_running)) ? 1 : 0;
    start_tb1 <= ((in_cnt == nofbits) & (~tb_running) & (~tb_last)) ? 1 : 0;
  end

  always @ (posedge clock) begin
    if (reset)
      tb_running <= 0;
    else begin
      if (tb_running)
        if (tb_done)
          tb_running <= 0;
        else
          tb_running <= tb_running;
      else
        if (start_tb0 | start_tb1)
          tb_running <= 1;
        else
          tb_running <= tb_running;
    end
    tb_running_delay <= {tb_running_delay[0], tb_running};
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (reset) begin
      if (nofbits <= 654)
        tb_start_idx <= 32767;
      else
        tb_start_idx <= {7'b0, ndbps} + 48;
    end else begin
      if ((~tb_running) & start_tb0) begin
        if (out_cnt + {7'b0, ndbps} + 654 >= nofbits)
          tb_start_idx <= 32767;
        else
          tb_start_idx <= tb_start_idx + {7'b0, ndbps};
      end else
        tb_start_idx <= tb_start_idx;
    end
  end

  always @ (posedge clock) begin
    tb_start <= (~tb_running) & (start_tb0 | start_tb1);
    tb_start_delay <= tb_start;
  end

  always @ (posedge clock) begin
    if (start_tb1) begin
      if (nofbits <= 654)
        tb_sz <= nofbits[9:0];
      else
        tb_sz <= nofbits[9:0] - out_cnt[9:0];
    end else begin
      tb_sz <= {2'b0, ndbps} + 48;
    end
    tb_sz_delay <= tb_sz;
  end

  always @ (posedge clock) begin
    if (tb_running) begin
      if (tb_pos == 0)
        tb_pos <= 653;
      else
        tb_pos <= tb_pos - 1;
    end else
      tb_pos <= phind_delay[1];
  end

  always @ (posedge clock) begin
    if (reset)
      tb_last <= 0;
    else begin
      if (start_tb1)
        tb_last <= 1;
      else
        tb_last <= tb_last;
    end
    tb_last_delay <= tb_last;
  end

  assign phtb = tb_running_delay[1] ? rdata : 0;

  traceback tb_inst(
    .clock(clock),
    .reset(reset),
    .start(tb_start_delay),
    .ndbps(ndbps),
    .tb_sz(tb_sz_delay),
    .ph(phtb),
    .tb_last(tb_last_delay),
    .tb_done(tb_done),
    .out_bit(out_bit),
    .out_valid(out_bit_valid)
  );

  // output
  always @ (posedge clock) begin
    if (reset)
      out_enable <= 0;
    else begin
      if (tb_done)
        out_enable <= 1;
      else
        if (out_nbits[14:3] == 1)
          out_enable <= 0;
        else
          out_enable <= out_enable;
    end // else: !if(reset)
    out_enable_delay <= {out_enable_delay[2:0], out_enable};
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if ((~tb_running) & (start_tb0 | start_tb1)) begin
      if (start_tb1)
        out_nbits <= nofbits - out_cnt;
      else
        out_nbits <= {7'b0, ndbps};
    end else begin
      if (out_enable)
        out_nbits <= out_nbits - 8;
      else
        out_nbits <= out_nbits;
    end // else: !if(~tb_running)
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (reset)
      dec_bit_cnt <= 0;
    else if ((nofbits[2:0] == 3'b110) & tb_last & (~tb_last_delay))
      dec_bit_cnt <= 2;
    else
      dec_bit_cnt <= out_bit_valid ? dec_bit_cnt + 1 : dec_bit_cnt;
  end

  always @ (posedge clock) begin
    if (out_bit_valid) begin
      dec_byte_in <= {dec_byte_in[6:0], out_bit};
    end else begin
      dec_byte_in <= dec_byte_in;
    end
  end

  always @ (posedge clock) begin
    if ((dec_bit_cnt == 7) & (out_bit_valid))
      dec_wen <= 1;
    else
      dec_wen <= 0;
  end

  always @ (posedge clock) begin
    if (reset)
      dec_waddr <= 0;
    else begin
      if (dec_wen)
        dec_waddr <= (dec_waddr == 81) ? 0 : dec_waddr + 1;
      else
        dec_waddr <= dec_waddr;
    end
  end

  always @ (posedge clock) begin
    if (out_enable_delay[0] & (~out_enable_delay[1]))
      dec_raddr <= dec_waddr;
    else if (out_enable_delay[1])
      dec_raddr <= (dec_raddr == 0) ? 81 : dec_raddr - 1;
    else
      dec_raddr <= dec_raddr;
  end

  always @ (posedge clock) begin
    if (out_enable_delay[3])
      dec_byte_reg <= dec_byte_out;
    else
      dec_byte_reg <= 0;

    dec_valid_reg <= out_enable_delay[3];
  end

  always @ (posedge clock) begin
    if (reset)
      out_cnt <= 0;
    else begin
      if (out_enable)
        out_cnt <= out_cnt + 8;
      else
        out_cnt <= out_cnt;
    end
  end

  ram_dp #(
    .DSIZE(8),
    .ASIZE(7),
    .DEPTH(82)
  ) dec_ram(
    .clock(clock),
    .wen(dec_wen),
    .waddr(dec_waddr),
    .raddr(dec_raddr),
    .wdata(dec_byte_in),
    .rdata(dec_byte_out)
  );

  assign dec_byte = dec_byte_reg;
  assign dec_valid = dec_valid_reg;

`ifdef __ICARUS__
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, vitdec);
end
`endif

endmodule // vitdec
