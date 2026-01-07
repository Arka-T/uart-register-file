`timescale 1ns/1ps

module cmd_collector (
    input  wire       clk,
    input  wire       rst,

    input  wire       rx_valid,
    input  wire [7:0] rx_data,

    output reg  [7:0] cmd,
    output reg  [7:0] addr,
    output reg  [7:0] data,
    output reg        cmd_ready
);

    // FSM states
    localparam S_IDLE = 2'd0;
    localparam S_CMD  = 2'd1;
    localparam S_ADDR = 2'd2;
    localparam S_DATA = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            cmd       <= 8'h00;
            addr      <= 8'h00;
            data      <= 8'h00;
            cmd_ready <= 1'b0;
        end else begin
            cmd_ready <= 1'b0; // default: pulse only

            case (state)

                S_IDLE: begin
                    if (rx_valid) begin
                        cmd   <= rx_data;
                        state <= S_ADDR;
                    end
                end

                S_ADDR: begin
                    if (rx_valid) begin
                        addr  <= rx_data;
                        state <= S_DATA;
                    end
                end

                S_DATA: begin
                    if (rx_valid) begin
                        data      <= rx_data;
                        cmd_ready <= 1'b1; // full command collected
                        state     <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
