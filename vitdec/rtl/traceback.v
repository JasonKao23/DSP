module traceback(
  input        clock,
  input        reset,
  input        start,
  input [7:0]  ndbps,
  input [9:0]  tb_sz,
  input [63:0] ph,
  input        tb_last,
  output       tb_done,
  output       out_bit,
  output       out_valid
);

  reg          tb_running;
  reg          tb_running_delay;
  reg [9:0]    tb_cnt;
  reg          obit;
  reg          ovalid;
  reg          tdone;
  reg [63:0]   ph_reg;
  reg [5:0]    tb_st;
  wire         p;

  always @ (posedge clock) begin
    if (reset)
      tb_running <= 0;
    else begin
      if (start)
        tb_running <= 1;
      else
        tb_running <= (tb_cnt == 1) ? 0 : tb_running;
    end
    tb_running_delay <= tb_running;
  end

  always @ (posedge clock) begin
    if (reset)
      tb_cnt <= 0;
    else begin
      if (start)
        tb_cnt <= tb_sz;
      else
        tb_cnt <= tb_running ? tb_cnt - 1 : 0;
    end
  end

   always @ (posedge clock) begin
      ph_reg <= ph;
   end

   assign p = ph_reg[tb_st];

   always @ (posedge clock) begin
      if (reset)
        tb_st <= 0;
      else begin
         if (tb_running_delay)
           tb_st <= {tb_st[4:0], 1'b0} + {5'b0, p};
         else
           tb_st <= 0;
      end
   end

   always @ (posedge clock) begin
      obit <= tb_running_delay ? tb_st[5] : 1'b0;
   end

   always @ (posedge clock) begin
     if (tb_last | (tb_cnt < {2'b0, ndbps}))
       ovalid <= tb_running_delay;
     else
      ovalid <= 0;
   end

   always @ (posedge clock) begin
      tdone <= tb_running_delay & (tb_cnt == 0);
   end

   assign tb_done = tdone;
   assign out_bit = obit;
   assign out_valid = ovalid;

endmodule // traceback
