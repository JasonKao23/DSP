module ifft64_tw_rom(
  input         clk,
  input         enable,
  input [5:0]   addr,
  output [31:0] dout
);

  reg [31:0]                     data;

  always @ (posedge clk) begin
    if (enable) begin
      case (addr)
        6'b000000: data <= 32'h00004000;
        6'b000001: data <= 32'h00004000;
        6'b000010: data <= 32'h00004000;
        6'b000011: data <= 32'h06463fb1;
        6'b000100: data <= 32'h0c7c3ec5;
        6'b000101: data <= 32'h12943d3f;
        6'b000110: data <= 32'h0c7c3ec5;
        6'b000111: data <= 32'h187e3b21;
        6'b001000: data <= 32'h238e3537;
        6'b001001: data <= 32'h12943d3f;
        6'b001010: data <= 32'h238e3537;
        6'b001011: data <= 32'h3179289a;
        6'b001100: data <= 32'h187e3b21;
        6'b001101: data <= 32'h2d412d41;
        6'b001110: data <= 32'h3b21187e;
        6'b001111: data <= 32'h1e2b3871;
        6'b010000: data <= 32'h3537238e;
        6'b010001: data <= 32'h3fb10646;
        6'b010010: data <= 32'h238e3537;
        6'b010011: data <= 32'h3b21187e;
        6'b010100: data <= 32'h3ec5f384;
        6'b010101: data <= 32'h289a3179;
        6'b010110: data <= 32'h3ec50c7c;
        6'b010111: data <= 32'h3871e1d5;
        6'b011000: data <= 32'h2d412d41;
        6'b011001: data <= 32'h40000000;
        6'b011010: data <= 32'h2d41d2bf;
        6'b011011: data <= 32'h3179289a;
        6'b011100: data <= 32'h3ec5f384;
        6'b011101: data <= 32'h1e2bc78f;
        6'b011110: data <= 32'h3537238e;
        6'b011111: data <= 32'h3b21e782;
        6'b100000: data <= 32'h0c7cc13b;
        6'b100001: data <= 32'h38711e2b;
        6'b100010: data <= 32'h3537dc72;
        6'b100011: data <= 32'hf9bac04f;
        6'b100100: data <= 32'h3b21187e;
        6'b100101: data <= 32'h2d41d2bf;
        6'b100110: data <= 32'he782c4df;
        6'b100111: data <= 32'h3d3f1294;
        6'b101000: data <= 32'h238ecac9;
        6'b101001: data <= 32'hd766ce87;
        6'b101010: data <= 32'h3ec50c7c;
        6'b101011: data <= 32'h187ec4df;
        6'b101100: data <= 32'hcac9dc72;
        6'b101101: data <= 32'h3fb10646;
        6'b101110: data <= 32'h0c7cc13b;
        6'b101111: data <= 32'hc2c1ed6c;
        default: data <= 0;
      endcase // case (addr)
    end // if (enable)
  end // always @ (posedge clk)

  assign dout = data;

endmodule // ifft64_tw_rom

