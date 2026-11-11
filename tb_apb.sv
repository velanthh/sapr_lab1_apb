`timescale 1ns/1ps

module tb_apb;
    localparam logic [31:0] BASE_ADDR = 32'h7000_0000;

    logic pclk = 1'b0;
    logic presetn = 1'b0;
    wire psel, penable, pwrite, pready, pslverr;
    wire [31:0] paddr, pwdata, prdata;

    always #10 pclk = ~pclk;

    apb_master master (
        .pclk(pclk), .pready(pready), .pslverr(pslverr), .prdata(prdata),
        .psel(psel), .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata)
    );

    apb_slave #(.BASE_ADDR(BASE_ADDR)) dut (
        .pclk(pclk), .presetn(presetn), .paddr(paddr), .pwdata(pwdata),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .pready(pready), .pslverr(pslverr), .prdata(prdata)
    );

    task automatic expect_write(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic expected_error
    );
        logic error;
        master.write(addr, data, error);
        if (error !== expected_error)
            $fatal(1, "WRITE addr=0x%08h: PSLVERR=%b, expected %b",
                   addr, error, expected_error);
    endtask

    task automatic expect_read(
        input logic [31:0] addr,
        input logic [31:0] expected_data,
        input logic expected_error
    );
        logic [31:0] data;
        logic error;
        master.read(addr, data, error);
        if (data !== expected_data || error !== expected_error)
            $fatal(1, "READ addr=0x%08h: data=0x%08h error=%b, expected data=0x%08h error=%b",
                   addr, data, error, expected_data, expected_error);
    endtask

    initial begin
        repeat (2) @(negedge pclk);
        presetn = 1'b1;

        expect_read(BASE_ADDR, 32'b0, 1'b0);
        expect_write(BASE_ADDR, 32'h1234_5678, 1'b0);
        expect_read(BASE_ADDR, 32'hAAAA_AAAA, 1'b0);
        master.idle_bus();
        repeat (3) @(posedge pclk);
        expect_read(BASE_ADDR, 32'hAAAA_AAAA, 1'b0);

        expect_write(BASE_ADDR, 32'h0000_0001, 1'b0);
        expect_read(BASE_ADDR, 32'h5555_5555, 1'b0);
        master.idle_bus();
        repeat (3) @(posedge pclk);
        expect_read(BASE_ADDR, 32'h5555_5555, 1'b0);

        expect_write(BASE_ADDR + 32'h100, 32'b0, 1'b1);
        expect_read(BASE_ADDR + 32'h04, 32'b0, 1'b1);
        expect_read(BASE_ADDR, 32'h5555_5555, 1'b0);
        expect_write(BASE_ADDR, 32'b0, 1'b0);
        expect_read(BASE_ADDR, 32'hAAAA_AAAA, 1'b0);

        master.idle_bus();
        $display("PASS: point 8, both register patterns and invalid accesses");
        $finish;
    end
endmodule
