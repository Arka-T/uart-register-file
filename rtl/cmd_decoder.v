`timescale 1ns/1ps

module cmd_decoder (
    input  wire       clk,
    input  wire       rst,

    // From cmd_collector
    input  wire       cmd_ready,   // 1-cycle pulse when CMD/ADDR/DATA are valid
    input  wire [7:0] cmd,
    input  wire [7:0] addr,
    input  wire [7:0] data,

    // From register file (read data for current addr)
    input  wire [7:0] reg_rd_data,

    // To register file (write controls)
    output reg        reg_wr_en,    // 1-cycle write pulse
    output reg  [3:0] reg_addr,     // 16 regs: 0x0 .. 0xF
    output reg  [7:0] reg_wr_data,

    // To response/TX logic
    output reg        resp_ok,      // 'K'
    output reg        resp_data,    // 'D'
    output reg        resp_err,     // 'E'
    output reg  [7:0] resp_addr,
    output reg  [7:0] resp_data_byte,
    output reg  [7:0] resp_err_code
);

    // ASCII command bytes
    localparam [7:0] CMD_W = 8'h57; // 'W'
    localparam [7:0] CMD_R = 8'h52; // 'R'

    // Error codes
    localparam [7:0] ERR_UNKNOWN_CMD = 8'h01;
    localparam [7:0] ERR_BAD_ADDR    = 8'h02;

    // FSM states
    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_EXEC = 2'd1;
    localparam [1:0] S_DONE = 2'd2;

    reg [1:0] state;

    // Helper: valid address for 16 regs (0x00..0x0F)
    wire addr_valid = (addr[7:4] == 4'h0);

    always @(posedge clk) begin
        if (rst) begin
            state         <= S_IDLE;

            reg_wr_en      <= 1'b0;
            reg_addr       <= 4'h0;
            reg_wr_data    <= 8'h00;

            resp_ok        <= 1'b0;
            resp_data      <= 1'b0;
            resp_err       <= 1'b0;
            resp_addr      <= 8'h00;
            resp_data_byte <= 8'h00;
            resp_err_code  <= 8'h00;

        end else begin
            // Default: all "action" outputs are pulses, so deassert every cycle
            reg_wr_en   <= 1'b0;
            resp_ok     <= 1'b0;
            resp_data   <= 1'b0;
            resp_err    <= 1'b0;

            case (state)

                S_IDLE: begin
                    // Wait for a complete command (1-cycle event)
                    if (cmd_ready) begin
                        state <= S_EXEC;
                    end
                end

                S_EXEC: begin
                    // Latch address into 4-bit regfile address
                    reg_addr  <= addr[3:0];
                    resp_addr <= addr;

                    // 1) Address check first
                    if (!addr_valid) begin
                        resp_err      <= 1'b1;
                        resp_err_code <= ERR_BAD_ADDR;
                        state         <= S_DONE;
                    end else begin
                        // 2) Decode command
                        if (cmd == CMD_W) begin
                            // WRITE: reg[addr] = data
                            reg_wr_en   <= 1'b1;
                            reg_wr_data <= data;

                            resp_ok     <= 1'b1;   // 'K'
                            state       <= S_DONE;

                        end else if (cmd == CMD_R) begin
                            // READ: respond with current reg data
                            resp_data      <= 1'b1;       // 'D'
                            resp_data_byte <= reg_rd_data;
                            state          <= S_DONE;

                        end else begin
                            // Unknown command
                            resp_err      <= 1'b1;
                            resp_err_code <= ERR_UNKNOWN_CMD;
                            state         <= S_DONE;
                        end
                    end
                end

                S_DONE: begin
                    // One-cycle "cooldown" state
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule