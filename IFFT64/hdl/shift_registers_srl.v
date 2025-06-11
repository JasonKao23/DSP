module shift_registers_srl #(
  parameter CLOCK_CYCLES = 32,
  parameter DATA_WIDTH = 16
) (
  input  clk,
  input  clken,
  input  [DATA_WIDTH-1:0] data_in,
  output [DATA_WIDTH-1:0] data_out
);

reg [CLOCK_CYCLES-1:0] shift_regs [DATA_WIDTH-1:0];

integer srl_index;
initial begin
    for (srl_index = 0; srl_index < DATA_WIDTH; srl_index = srl_index + 1)
      shift_regs[srl_index] = {CLOCK_CYCLES{1'b0}};
end

genvar i;
generate
  for (i = 0; i < DATA_WIDTH; i = i + 1) begin
    always @ (posedge clk)
      if (clken)
        shift_regs[i] <= {shift_regs[i][CLOCK_CYCLES-2:0], data_in[i]};

    assign data_out[i] = shift_regs[i][CLOCK_CYCLES-1];
    end
endgenerate

endmodule
