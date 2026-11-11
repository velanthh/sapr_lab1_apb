`timescale 1ns/1ps

module apb_master (
    input  logic        pclk,
    input  logic        pready,
    input  logic        pslverr,
    input  logic [31:0] prdata,
    output logic        psel,
    output logic        penable,
    output logic        pwrite,
    output logic [31:0] paddr,
    output logic [31:0] pwdata
);
    initial begin
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        paddr = '0;
        pwdata = '0;
    end

    task automatic transfer(
        input  logic        write_enable,
        input  logic [31:0] addr,
        input  logic [31:0] write_data,
        output logic [31:0] read_data,
        output logic        error
    );
        // Drive the bus on falling edges so it is stable at sampling edges.
        @(negedge pclk);
        psel = 1'b1;
        penable = 1'b0;
        pwrite = write_enable;
        paddr = addr;
        pwdata = write_data;

        @(negedge pclk);
        penable = 1'b1;

        begin : wait_for_ready
            for (int cycle = 0; cycle < 16; cycle++) begin
                @(posedge pclk);
                if (pready === 1'b1) begin
                    read_data = prdata;
                    error = pslverr;
                    // The next transfer may enter SETUP without dropping PSEL.
                    disable wait_for_ready;
                end
            end
            $fatal(1, "APB timeout at address 0x%08h", addr);
        end
    endtask

    task automatic write(
        input  logic [31:0] addr,
        input  logic [31:0] data,
        output logic        error
    );
        logic [31:0] unused_read_data;
        transfer(1'b1, addr, data, unused_read_data, error);
    endtask

    task automatic read(
        input  logic [31:0] addr,
        output logic [31:0] data,
        output logic        error
    );
        transfer(1'b0, addr, '0, data, error);
    endtask

    task automatic idle_bus;
        @(negedge pclk);
        psel = 1'b0;
        penable = 1'b0;
    endtask
endmodule
