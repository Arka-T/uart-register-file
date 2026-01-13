`timescale 1ns/1ps

module reg_file_16x8 (
    input  wire       clk,
    input  wire       rst,       // active-high synchronous reset

    input  wire       wr_en,     // 1-cycle write enable
    input  wire [3:0] addr,      // 16 registers
    input  wire [7:0] wr_data,   // data to write

    output wire [7:0] rd_data    // data read from selected register
);

    // 16 registers x 8 bits
    reg [7:0] regs [0:15];

    integer i;

    // Synchronous write & synchronous reset
    always @(posedge clk) begin
        if (rst) begin
            // Clear all registers on reset
            for (i = 0; i < 16; i = i + 1) begin
                regs[i] <= 8'h00;
            end
        end else begin
            if (wr_en) begin
                regs[addr] <= wr_data;
            end
        end
    end

    // Asynchronous read (read updates immediately when addr changes)
    assign rd_data = regs[addr];

endmodule