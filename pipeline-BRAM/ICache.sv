module ICache#(
    parameter DEPTH = 8
)(
    input  logic [      0:0] clk,
    input  logic [     31:0] raddr,
    output logic [     31:0] rdata,

    input  logic [      0:0] flush,
    input  logic [      0:0] stall
);
    import "DPI-C" function void pmem_read(input bit re, input int addr, input int mask, output int rword);
    logic [31:0] rdata_temp;
    always_comb begin
        pmem_read(1, raddr, 32'h2, rdata_temp);
    end
    always_ff@(posedge clk) begin
        if(flush) begin
            rdata <= 0;
        end 
        else if(!stall) begin
            rdata <= rdata_temp;
        end
    end

endmodule