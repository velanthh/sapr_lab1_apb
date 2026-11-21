`timescale 1ns/1ps

module TB;
    localparam [31:0] BASE_ADDR = 32'h7000_0000;

    reg         pclk;
    reg         presetn;
    reg  [31:0] paddr;
    reg  [31:0] pwdata;
    reg         psel;
    reg         penable;
    reg         pwrite;
    wire        pready;
    wire        pslverr;
    wire [31:0] prdata;

    apb_slave #(.BASE_ADDR(BASE_ADDR)) DUT (
        .pclk(pclk), .presetn(presetn), .paddr(paddr), .pwdata(pwdata),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .pready(pready), .pslverr(pslverr), .prdata(prdata)
    );

    always #10 pclk = ~pclk;

    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        input        expected_error;
        begin
            @(negedge pclk);
            paddr = addr;
            pwdata = data;
            pwrite = 1'b1;
            psel = 1'b1;
            penable = 1'b0;

            @(negedge pclk);
            penable = 1'b1;

            @(posedge pclk);
            #1;
            if (pready !== 1'b1)
                $fatal(1, "APB write timeout: addr=0x%08h", addr);
            if (pslverr !== expected_error)
                $fatal(1, "APB write error mismatch: addr=0x%08h", addr);

            @(negedge pclk);
            psel = 1'b0;
            penable = 1'b0;
            pwrite = 1'b0;
        end
    endtask

    task apb_read;
        input [31:0] addr;
        input [31:0] expected_data;
        input        expected_error;
        begin
            @(negedge pclk);
            paddr = addr;
            pwdata = 32'b0;
            pwrite = 1'b0;
            psel = 1'b1;
            penable = 1'b0;

            @(negedge pclk);
            penable = 1'b1;

            @(posedge pclk);
            #1;
            if (pready !== 1'b1)
                $fatal(1, "APB read timeout: addr=0x%08h", addr);
            if (pslverr !== expected_error)
                $fatal(1, "APB read error mismatch: addr=0x%08h", addr);
            if (!expected_error && prdata !== expected_data)
                $fatal(1, "APB read mismatch: addr=0x%08h data=0x%08h expected=0x%08h",
                       addr, prdata, expected_data);

            @(negedge pclk);
            psel = 1'b0;
            penable = 1'b0;
        end
    endtask

    initial begin
        pclk = 1'b0;
        presetn = 1'b0;
        paddr = 32'b0;
        pwdata = 32'b0;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;

        repeat (2) @(posedge pclk);
        @(negedge pclk);
        presetn = 1'b1;

        apb_read(BASE_ADDR + 32'h00, 32'h0000_0000, 1'b0);
        apb_read(BASE_ADDR + 32'h04, 32'h0000_0000, 1'b0);
        apb_read(BASE_ADDR + 32'h08, 32'h0000_0000, 1'b0);
        apb_read(BASE_ADDR + 32'h0C, 32'h0000_0000, 1'b0);

        apb_write(BASE_ADDR + 32'h00, 32'h0000_000F, 1'b0);
        apb_write(BASE_ADDR + 32'h04, 32'h1111_2026, 1'b0);
        apb_write(BASE_ADDR + 32'h08, 32'h4875_6461, 1'b0);
        apb_write(BASE_ADDR + 32'h0C, 32'h5975_7375, 1'b0);

        apb_read(BASE_ADDR + 32'h00, 32'h0000_000F, 1'b0);
        apb_read(BASE_ADDR + 32'h04, 32'h1111_2026, 1'b0);
        apb_read(BASE_ADDR + 32'h08, 32'h4875_6461, 1'b0);
        apb_read(BASE_ADDR + 32'h0C, 32'h5975_7375, 1'b0);

        apb_write(BASE_ADDR + 32'h100, 32'hFFFF_FFFF, 1'b1);
        apb_read(BASE_ADDR + 32'h10, 32'h0000_0000, 1'b1);

        $display("PASS: all APB checks completed successfully");
        $finish;
    end
endmodule
