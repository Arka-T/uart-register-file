`timescale 1ns/1ps

module tb_reg_file_16x8;

    reg        clk = 0;
    reg        rst = 1;
    reg        wr_en = 0;
    reg [3:0]  addr = 4'h0;
    reg [7:0]  wr_data = 8'h00;
    wire [7:0] rd_data;

    // 50 MHz clock (20 ns period)
    always #10 clk = ~clk;

    // DUT
    reg_file_16x8 dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

    initial begin
        // -----------------------
        // RESET
        // -----------------------
        repeat (3) @(posedge clk);
        rst <= 0;

        // -----------------------
        // TEST 1: Read after reset
        // -----------------------
        $display("TEST 1: Read after reset");
        addr <= 4'h3;
        @(posedge clk);
        if (rd_data !== 8'h00) begin
            $display("FAIL: expected 00 after reset, got %h", rd_data);
            $fatal;
        end
        $display("PASS: Reset clears registers");

        // -----------------------
        // TEST 2: Write register 3
        // -----------------------
        $display("TEST 2: Write reg[3] = B3");
        @(posedge clk);
        wr_en   <= 1'b1;
        addr    <= 4'h3;
        wr_data <= 8'hB3;

        @(posedge clk);
        wr_en <= 1'b0;

        // Read back
        addr <= 4'h3;
        @(posedge clk);
        if (rd_data !== 8'hB3) begin
            $display("FAIL: expected B3, got %h", rd_data);
            $fatal;
        end
        $display("PASS: Write and read reg[3]");

        // -----------------------
        // TEST 3: Write another register
        // -----------------------
        $display("TEST 3: Write reg[7] = 5A");
        @(posedge clk);
        wr_en   <= 1'b1;
        addr    <= 4'h7;
        wr_data <= 8'h5A;

        @(posedge clk);
        wr_en <= 1'b0;

        // Check reg[7]
        addr <= 4'h7;
        @(posedge clk);
        if (rd_data !== 8'h5A) begin
            $display("FAIL: expected 5A, got %h", rd_data);
            $fatal;
        end

        // Check reg[3] unchanged
        addr <= 4'h3;
        @(posedge clk);
        if (rd_data !== 8'hB3) begin
            $display("FAIL: reg[3] changed unexpectedly");
            $fatal;
        end
        $display("PASS: Independent registers verified");

        // -----------------------
        // TEST 4: Write disabled
        // -----------------------
        $display("TEST 4: Write disabled");
        @(posedge clk);
        wr_en   <= 1'b0;
        addr    <= 4'h3;
        wr_data <= 8'hFF;

        @(posedge clk);
        addr <= 4'h3;
        @(posedge clk);
        if (rd_data !== 8'hB3) begin
            $display("FAIL: data changed without write enable");
            $fatal;
        end
        $display("PASS: wr_en gating works");

        $display("ALL REGFILE TESTS PASSED");
        $finish;
    end

endmodule