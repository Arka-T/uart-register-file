`timescale 1ns/1ps

module tb_cmd_collector;

    reg clk = 0;
    reg rst = 1;

    reg        rx_valid;
    reg [7:0]  rx_data;

    wire [7:0] cmd;
    wire [7:0] addr;
    wire [7:0] data;
    wire       cmd_ready;

    // DUT
    cmd_collector dut (
        .clk(clk),
        .rst(rst),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .cmd(cmd),
        .addr(addr),
        .data(data),
        .cmd_ready(cmd_ready)
    );

    // clock: 100 MHz (arbitrary)
    always #5 clk = ~clk;

    // helper task: send one byte
    task send_byte(input [7:0] b);
    begin
        @(posedge clk);
        rx_data  <= b;
        rx_valid <= 1'b1;
        @(posedge clk);
        rx_valid <= 1'b0;
    end
    endtask

    initial begin
        // init
        rx_valid = 0;
        rx_data  = 8'h00;

        // reset
        #20;
        rst = 0;

        // wait a bit
        #20;

        // send command: W 03 AA
        send_byte(8'h57); // 'W'
        #30;
        send_byte(8'h03); // address
        #40;
        send_byte(8'hAA); // data

        // wait for cmd_ready
        wait(cmd_ready);

        // check results
        if (cmd  !== 8'h57 ||
            addr !== 8'h03 ||
            data !== 8'hAA) begin
            $display("FAIL: cmd=%h addr=%h data=%h", cmd, addr, data);
            $fatal;
        end else begin
            $display("PASS: cmd=%h addr=%h data=%h", cmd, addr, data);
        end

        #20;
        $finish;
    end

endmodule
