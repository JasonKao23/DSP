`timescale 1ns/1ns

`define NOF_TESTVECTOR 112
`define CLOCK_PERIOD 10
`define T_HOLD 2

module vitdec_tb2();
  reg clock;
  reg reset;
  reg [7:0] testvectors [`NOF_TESTVECTOR-1:0];

  reg [7:0] in_data [`NOF_TESTVECTOR-1:0];
  reg [31:0] in_idx;
  reg [31:0] tv_idx;
  reg [31:0] clk_cnt;
  reg [31:0] sim_cnt;
  reg        start;
  integer    outfile;

  reg [1:0]  coderate;
  reg [14:0] nofbits;
  reg [8:0]  ncbps;
  reg [7:0]  ndbps;
  reg [7:0]  in_sample;
  reg        in_valid;
  wire [7:0] dec_byte;
  wire       dec_valid;

   // instantiate DUT
  vitdec #(
    .DWIDTH(8)
  ) vitdec_inst(
    .clock(clock),
    .reset(reset),
    .coderate(coderate),
    .nofbits(nofbits),
    .ndbps(ndbps),
    .in_data(in_sample),
    .in_valid(in_valid),
    .dec_byte(dec_byte),
    .dec_valid(dec_valid)
  );

  // generate clock
  always
    begin
      clock = 1;
      #(`CLOCK_PERIOD/2);
      clock = 0;
      #(`CLOCK_PERIOD/2);
    end

  // load test vector
  initial
    begin
      $readmemb("vitdec_input2.txt", testvectors);
    end

  initial
    begin
      reset = 1;
      coderate = 0;
      nofbits = 24;
      ncbps = 48;
      ndbps = 24;
      in_sample = 0;
      in_valid = 0;

      clk_cnt = 0;
      sim_cnt = 0;
      start = 0;

      // copy samples into the input buffer
      tv_idx = 0;
      while (tv_idx < `NOF_TESTVECTOR) begin
        in_data[tv_idx] = testvectors[tv_idx];
        tv_idx = tv_idx + 1;
      end

      in_idx = 0;
      outfile = $fopen("vitdec_outdata.txt", "w");

      // set initial state, wait for a few clock cycles
      repeat(10) @(posedge clock);
      #`CLOCK_PERIOD;
      reset = 0;
      #`CLOCK_PERIOD;

      // drive input after rising edge of clock
      @(posedge clock);
      #`T_HOLD;
      start = 1;
    end // initial begin

  initial
    begin
      $dumpfile("vitdec_tb.vcd");
      $dumpvars(0, vitdec_tb2);
    end

  //
  always @ (posedge clock) begin
    if (start)
      clk_cnt <= (clk_cnt == 399) ? 0 : (clk_cnt + 1);
    else
      clk_cnt <= 0;
  end

  // apply test vector
  always @ (posedge clock) begin
    if (start & (in_idx < `NOF_TESTVECTOR) & (clk_cnt < ncbps)) begin
      in_sample <= in_data[in_idx];
      in_valid <= 1;
      in_idx <= in_idx + 1;
    end else begin
      in_sample <= 0;
      in_valid <= 0;
    end
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (dec_valid) begin
      $fdisplay(outfile, "%H", dec_byte);
    end
  end

  always @ (posedge clock) begin
    sim_cnt <=  sim_cnt + 1;
    if (sim_cnt > 110) begin
      $fclose(outfile);
      $display("simulation completed");
      $finish;
    end
  end

endmodule // vitdec_tb
