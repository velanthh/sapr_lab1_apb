`timescale 1ns/1ps

module apb_slave #(
    parameter [31:0] BASE_ADDR = 32'h7000_0000
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
    reg [31:0] registers [0:3];
    reg [1:0] register_index;
    reg address_valid;

    always @(*) begin
        address_valid = 1'b1;
        register_index = 2'd0;
        case (paddr - BASE_ADDR)
            32'h00: register_index = 2'd0;
            32'h04: register_index = 2'd1;
            32'h08: register_index = 2'd2;
            32'h0C: register_index = 2'd3;
            default: address_valid = 1'b0;
        endcase
    end
    assign pready = presetn && psel && penable;
    assign pslverr = pready && !address_valid;
    assign prdata = (pready && !pwrite && address_valid)
                    ? registers[register_index] : 32'b0;

    integer index;
    always @(posedge pclk) begin
        if (!presetn) begin
            for (index = 0; index < 4; index = index + 1)
                registers[index] <= '0;
        end else begin
            if (pready && pwrite && address_valid)
                registers[register_index] <= pwdata;
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
