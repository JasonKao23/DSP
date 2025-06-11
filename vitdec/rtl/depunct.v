module depunct #(
  parameter DWIDTH = 8
) (
  input               clock,
  input               reset,
  input [1:0]         coderate,
  input [DWIDTH-1:0]  in_data,
  input               in_valid,
  output [DWIDTH-1:0] vitin0,
  output [DWIDTH-1:0] vitin1,
  output              vitin_valid
);

  reg [1:0]           in_cnt0;
  reg [1:0]           in_cnt1;
  reg                 vitin_valid_reg;
  reg [DWIDTH-1:0]    in_data_delay;
  reg [DWIDTH-1:0]    vitin [1:0];

  always @ (posedge clock) begin
    if (reset) begin
      in_cnt0 <= 0;
      in_cnt1 <= 0;
    end else begin
      if (in_valid) begin
        in_cnt0 <= in_cnt0 + 1;
        in_cnt1 <= (in_cnt1 == 2) ? 0 : in_cnt1 + 1;
      end else begin
        in_cnt0 <= in_cnt0;
        in_cnt1 <= in_cnt1;
      end
    end // else: !if(reset)
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (reset | (~in_valid))
      vitin_valid_reg <= 0;
    else begin
      case (coderate)
        2'b00: vitin_valid_reg <= in_cnt0[0];
        2'b01: vitin_valid_reg <= in_cnt1[0] ^ in_cnt1[1];
        2'b10: vitin_valid_reg <= in_cnt0[0] | in_cnt0[1];
        default: vitin_valid_reg <= 0;
      endcase
    end
  end // always @ (posedge clock)

  always @ (posedge clock) begin
    if (in_valid)
      in_data_delay <= in_data;
    else
      in_data_delay <= in_data_delay;

    if (in_valid) begin
      case (coderate)
        2'b00: begin
          if (in_cnt0[0]) begin
            vitin[0] <= in_data_delay;
            vitin[1] <= in_data;
          end else begin
            vitin[0] <= 0;
            vitin[1] <= 0;
          end
        end

        2'b01: begin
          case (in_cnt1)
            2'b01: begin
              vitin[0] <= in_data_delay;
              vitin[1] <= in_data;
            end
            2'b10: begin
              vitin[0] <= in_data;
              vitin[1] <= 0;
            end
            default: begin
              vitin[0] <= 0;
              vitin[1] <= 0;
            end
          endcase // case (in_cnt1)
        end // case: 2'b01

        2'b10: begin
          case (in_cnt0)
            2'b01: begin
              vitin[0] <= in_data_delay;
              vitin[1] <= in_data;
            end
            2'b10: begin
              vitin[0] <= in_data;
              vitin[1] <= 0;
            end
            2'b11: begin
              vitin[0] <= 0;
              vitin[1] <= in_data;
            end
            default: begin
              vitin[0] <= 0;
              vitin[1] <= 0;
            end
          endcase // case (in_cnt0)
        end // case: 2'b10

        default: begin
          vitin[0] <= 0;
          vitin[01] <= 1;
        end
      endcase // case (coderate)
    end else begin // if (in_valid)
      vitin[0] <= 0;
      vitin[1] <= 1;
    end // else: !if(in_valid)
  end // always @ (posedge clock)

  assign vitin0 = vitin[0];
  assign vitin1 = vitin[1];
  assign vitin_valid = vitin_valid_reg;

endmodule // depunct
