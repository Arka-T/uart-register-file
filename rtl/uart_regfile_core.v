`timescale 1ns/1ps

module uart_regfile_core (
    input  wire       clk,
    input  wire       rst,

    // Inputs from cmd_collector
    input  wire       cmd_ready,   // 1-cycle pulse
    input  wire [7:0] cmd,         // 'W' (0x57) or 'R' (0x52)
    input  wire [7:0] addr,        // 0x00..0x0F valid
    input  wire [7:0] data,        // write data (for W)

    // Outputs for response
    output wire       resp_ok,        // pulse for 'K'
    output wire       resp_data,      // pulse for 'D'
    output wire       resp_err,       // pulse for 'E'
    output wire [7:0] resp_addr,
    output wire [7:0] resp_data_byte,
    output wire [7:0] resp_err_code
);

    // Decoder / Regfile signals
    wire        reg_wr_en;
    wire [3:0]  reg_addr;
    wire [7:0]  reg_wr_data;
    wire [7:0]  reg_rd_data;

    // Command decoder
    cmd_decoder u_dec (
        .clk(clk),
        .rst(rst),

        .cmd_ready(cmd_ready),
        .cmd(cmd),
        .addr(addr),
        .data(data),

        .reg_rd_data(reg_rd_data),

        .reg_wr_en(reg_wr_en),
        .reg_addr(reg_addr),
        .reg_wr_data(reg_wr_data),

        .resp_ok(resp_ok),
        .resp_data(resp_data),
        .resp_err(resp_err),
        .resp_addr(resp_addr),
        .resp_data_byte(resp_data_byte),
        .resp_err_code(resp_err_code)
    );

    // Register file
    reg_file_16x8 u_rf (
        .clk(clk),
        .rst(rst),

        .wr_en(reg_wr_en),
        .addr(reg_addr),
        .wr_data(reg_wr_data),

        .rd_data(reg_rd_data)
    );

endmodule