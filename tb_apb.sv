`timescale 1ns/1ps

module tb_apb;
    localparam logic [31:0] BASE_ADDR = 32'h7000_0000;

    localparam logic [31:0] NUMBER_ADDR = BASE_ADDR + 32'h00;
    localparam logic [31:0] DATE_ADDR = BASE_ADDR + 32'h04;
    localparam logic [31:0] SURNAME_ADDR = BASE_ADDR + 32'h08;
    localparam logic [31:0] NAME_ADDR = BASE_ADDR + 32'h0C;

    localparam logic [31:0] STUDENT_NUMBER = 32'd15;
    localparam logic [31:0] LAB_DATE = 32'h1111_2026;
    localparam logic [31:0] SURNAME_ASCII = "Huda";
    localparam logic [31:0] NAME_ASCII = "Yusu";

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

    task automatic expect_reset_values;
        expect_read(NUMBER_ADDR, 32'b0, 1'b0);
        expect_read(DATE_ADDR, 32'b0, 1'b0);
        expect_read(SURNAME_ADDR, 32'b0, 1'b0);
        expect_read(NAME_ADDR, 32'b0, 1'b0);
    endtask

    initial begin
        repeat (2) @(negedge pclk);
        presetn = 1'b1;
        expect_reset_values();

        expect_write(NUMBER_ADDR, STUDENT_NUMBER, 1'b0);
        expect_write(DATE_ADDR, LAB_DATE, 1'b0);
        expect_write(SURNAME_ADDR, SURNAME_ASCII, 1'b0);
        expect_write(NAME_ADDR, NAME_ASCII, 1'b0);

        master.idle_bus();
        repeat (3) @(posedge pclk);
        expect_write(BASE_ADDR + 32'h100, 32'hFFFF_FFFF, 1'b1);
        expect_read(BASE_ADDR + 32'h10, 32'b0, 1'b1);
        expect_write(BASE_ADDR + 32'h05, 32'hFFFF_FFFF, 1'b1);

        expect_read(NUMBER_ADDR, STUDENT_NUMBER, 1'b0);
        expect_read(DATE_ADDR, LAB_DATE, 1'b0);
        expect_read(SURNAME_ADDR, SURNAME_ASCII, 1'b0);
        expect_read(NAME_ADDR, NAME_ASCII, 1'b0);

        master.idle_bus();
        presetn = 1'b0;
        repeat (2) @(negedge pclk);
        presetn = 1'b1;
        expect_reset_values();

        master.idle_bus();
        $display("PASS: point 9, four APB registers, invalid accesses and reset");
        $finish;
    end
endmodule
