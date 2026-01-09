`timescale 1ns/1ps

module tb_cmd_decoder;

    // Clock/reset
    reg clk = 0;
    reg rst = 1;

    // Inputs from cmd_collector (pretend)
    reg        cmd_ready = 0;
    reg [7:0]  cmd  = 8'h00;
    reg [7:0]  addr = 8'h00;
    reg [7:0]  data = 8'h00;

    // "fake regfile read data"
    reg [7:0]  reg_rd_data = 8'h00;

    // DUT outputs to regfile
    wire       reg_wr_en;
    wire [3:0] reg_addr;
    wire [7:0] reg_wr_data;

    // DUT response outputs
    wire       resp_ok;
    wire       resp_data;
    wire       resp_err;
    wire [7:0] resp_addr;
    wire [7:0] resp_data_byte;
    wire [7:0] resp_err_code;

    // 50MHz clock (20 ns period)
    always #10 clk = ~clk;

    // DUT: cmd_decoder
    cmd_decoder dut (
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

    // 1-cycle cmd_ready pulse (command latched by DUT)
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

    // Helper: wait for one of the response pulses
    task wait_resp;
    begin
        wait(resp_ok || resp_data || resp_err);
        @(posedge clk); // move one cycle to check pulse width
    end
    endtask

    initial begin
        // Reset for a few cycles
        repeat (5) @(posedge clk);
        rst <= 0;
        repeat (2) @(posedge clk);

        // ---------------------------
        // TEST 1: WRITE valid
        // W = 8'h57, addr=0x03, data=0xB3
        // Expect: reg_wr_en pulse, reg_addr=3, reg_wr_data=B3, resp_ok pulse
        // ---------------------------
        $display("TEST1: WRITE valid (W 03 B3)");
        send_cmd(8'h57, 8'h03, 8'hB3);

        wait(resp_ok === 1'b1);
        if (reg_wr_en !== 1'b1) begin
            $display("FAIL: reg_wr_en should be 1 when resp_ok pulses");
            $fatal;
        end
        if (reg_addr !== 4'h3) begin
            $display("FAIL: expected reg_addr=3, got %h", reg_addr);
            $fatal;
        end
        if (reg_wr_data !== 8'hB3) begin
            $display("FAIL: expected reg_wr_data=B3, got %h", reg_wr_data);
            $fatal;
        end

        @(posedge clk);
        if (resp_ok !== 1'b0) begin
            $display("FAIL: resp_ok should be 1-cycle pulse");
            $fatal;
        end
        $display("PASS: WRITE valid");

        // ---------------------------
        // TEST 2: READ valid
        // R = 8'h52, addr=0x03
        // "fake" the regfile output by setting reg_rd_data first.
        // Expect: resp_data pulse, resp_addr=03, resp_data_byte = reg_rd_data
        // ---------------------------
        $display("TEST2: READ valid (R 03) -> reg_rd_data=5A");
        reg_rd_data <= 8'h5A;
        send_cmd(8'h52, 8'h03, 8'h00);

        wait(resp_data === 1'b1);
        if (resp_addr !== 8'h03) begin
            $display("FAIL: expected resp_addr=03, got %h", resp_addr);
            $fatal;
        end
        if (resp_data_byte !== 8'h5A) begin
            $display("FAIL: expected resp_data_byte=5A, got %h", resp_data_byte);
            $fatal;
        end

        @(posedge clk);
        if (resp_data !== 1'b0) begin
            $display("FAIL: resp_data should be 1-cycle pulse");
            $fatal;
        end
        $display("PASS: READ valid");

        // ---------------------------
        // TEST 3: BAD address
        // addr=0x10 is invalid for 16 regs
        // Expect: resp_err pulse, err_code=02
        // ---------------------------
        $display("TEST3: BAD address (W 10 AA)");
        send_cmd(8'h57, 8'h10, 8'hAA);

        wait(resp_err === 1'b1);
        if (resp_err_code !== 8'h02) begin
            $display("FAIL: expected ERR_BAD_ADDR=02, got %h", resp_err_code);
            $fatal;
        end
        @(posedge clk);
        if (resp_err !== 1'b0) begin
            $display("FAIL: resp_err should be 1-cycle pulse");
            $fatal;
        end
        $display("PASS: BAD address");

        // ---------------------------
        // TEST 4: UNKNOWN command
        // cmd=0x99
        // Expect: resp_err pulse, err_code=01
        // ---------------------------
        $display("TEST4: UNKNOWN cmd (99 02 11)");
        send_cmd(8'h99, 8'h02, 8'h11);

        wait(resp_err === 1'b1);
        if (resp_err_code !== 8'h01) begin
            $display("FAIL: expected ERR_UNKNOWN_CMD=01, got %h", resp_err_code);
            $fatal;
        end
        @(posedge clk);
        if (resp_err !== 1'b0) begin
            $display("FAIL: resp_err should be 1-cycle pulse");
            $fatal;
        end
        $display("PASS: UNKNOWN cmd");

        $display("ALL DECODER TESTS PASSED");
        $finish;
    end

endmodule