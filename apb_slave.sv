`timescale 1ns/1ps

module apb_slave #(
    parameter logic [31:0] BASE_ADDR = 32'h7000_0000
) (
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    output wire         pready,
    output wire         pslverr,
    output wire  [31:0] prdata
);
    logic in_access;
    logic [31:0] register_with_some_name;
    wire address_valid;

    assign address_valid = (paddr == BASE_ADDR);
    assign pready = presetn && in_access && psel && penable;
    assign pslverr = pready && !address_valid;
    assign prdata = (pready && !pwrite && address_valid)
                    ? register_with_some_name : 32'b0;

    always_ff @(posedge pclk) begin
        if (!presetn) begin
            in_access <= 1'b0;
            register_with_some_name <= '0;
        end else begin
            // Sample SETUP, then complete ACCESS on the next rising edge.
            in_access <= psel && !penable;
            if (pready && pwrite && address_valid)
                register_with_some_name <= pwdata[0] ? 32'h5555_5555 : 32'hAAAA_AAAA;
        end
    end

`ifndef SYNTHESIS
    always @(posedge pclk) begin
        if (pslverr)
            $display("APB ERROR addr=0x%08h write=%b", paddr, pwrite);
        else if (pready && pwrite)
            $display("APB WRITE addr=0x%08h data=0x%08h", paddr, pwdata);
        else if (pready)
            $display("APB READ  addr=0x%08h data=0x%08h", paddr, prdata);
    end
`endif
endmodule
