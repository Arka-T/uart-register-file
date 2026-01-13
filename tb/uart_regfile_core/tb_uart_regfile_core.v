`timescale 1ns/1ps

module tb_uart_regfile_core;

    reg clk = 0;
    reg rst = 1;

    reg        cmd_ready = 0;
    reg [7:0]  cmd  = 8'h00;
    reg [7:0]  addr = 8'h00;
    reg [7:0]  data = 8'h00;

    wire       resp_ok;
    wire       resp_data;
    wire       resp_err;
    wire [7:0] resp_addr;
    wire [7:0] resp_data_byte;
    wire [7:0] resp_err_code;

    // 50 MHz clock (20 ns period)
    always #10 clk = ~clk;

    uart_regfile_core dut (
        .clk(clk),
        .rst(rst),

        .cmd_ready(cmd_ready),
        .cmd(cmd),
        .addr(addr),
        .data(data),

        .resp_ok(resp_ok),
        .resp_data(resp_data),
        .resp_err(resp_err),
        .resp_addr(resp_addr),
        .resp_data_byte(resp_data_byte),
        .resp_err_code(resp_err_code)
    );

    // Helper: send one command packet (cmd_ready pulses once)
    task send_cmd(input [7:0] c, input [7:0] a, input [7:0] d);
    begin
        @(posedge clk);
        cmd <= c;
        addr <= a;
        data <= d;
        cmd_ready <= 1'b1;
        @(posedge clk);
        cmd_ready <= 1'b0;
    end
    endtask

    // Helper: wait for any response pulse
    task wait_resp;
    begin
        wait(resp_ok || resp_data || resp_err);
        @(posedge clk); // let signals settle for waveform
    end
    endtask

    initial begin
        // Reset
        #50;
        rst = 1;
        #60;
        @(posedge clk);
        rst = 0;

        // -------------------------
        // 1) WRITE: reg[0x03] = 0xB3
        // cmd = 'W' (0x57)
        // -------------------------
        send_cmd(8'h57, 8'h03, 8'hB3);
        wait_resp;

        if (!resp_ok) begin
            $display("FAIL: Expected resp_ok on WRITE");
            $fatal;
        end else begin
            $display("PASS: WRITE acknowledged (K)");
        end

        // -------------------------
        // 2) READ: reg[0x03] should be 0xB3
        // cmd = 'R' (0x52)
        // -------------------------
        send_cmd(8'h52, 8'h03, 8'h00);
        wait_resp;

        if (!resp_data) begin
            $display("FAIL: Expected resp_data on READ");
            $fatal;
        end

        if (resp_data_byte !== 8'hB3) begin
            $display("FAIL: Expected 0xB3, got %h", resp_data_byte);
            $fatal;
        end else begin
            $display("PASS: READ returned 0x%h", resp_data_byte);
        end

        // -------------------------
        // 3) Bad address: 0x10 should error
        // -------------------------
        send_cmd(8'h52, 8'h10, 8'h00);
        wait_resp;

        if (!resp_err || resp_err_code !== 8'h02) begin
            $display("FAIL: Expected ERR_BAD_ADDR (0x02)");
            $fatal;
        end else begin
            $display("PASS: Bad address rejected (E, code %h)", resp_err_code);
        end

        // -------------------------
        // 4) Unknown command: 0x99 should error
        // -------------------------
        send_cmd(8'h99, 8'h03, 8'h00);
        wait_resp;

        if (!resp_err || resp_err_code !== 8'h01) begin
            $display("FAIL: Expected ERR_UNKNOWN_CMD (0x01)");
            $fatal;
        end else begin
            $display("PASS: Unknown cmd rejected (E, code %h)", resp_err_code);
        end

        $display("ALL TESTS PASSED");
        #100;
        $finish;
    end

endmodule
