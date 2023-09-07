module DCache#(
    parameter DEPTH = 8
)(
    input  logic [      0:0] clk,
    input  logic [     31:0] raddr,
    output logic [     31:0] rdata,

    input  logic [     31:0] waddr,
    input  logic [     31:0] wdata,
    input  logic [      4:0] mem_access,

    input  logic [      0:0] flush,
    input  logic [      0:0] stall
);
    import "DPI-C" function void pmem_read(input bit re, input int addr, input int mask, output int rword);
    import "DPI-C" function void pmem_write(input bit we, input int addr, input int mask, input int wword); 
    logic [31:0] rdata_temp;
    always_comb begin
        pmem_read(mem_access[3], raddr, {30'h0, mem_access[1:0]}, rdata_temp);
    end
    always_ff @(posedge clk) begin
        if(flush) begin
            rdata <= 0;
        end 
        else if(!stall) begin
            rdata <= rdata_temp;
        end
    end
    always_ff @(posedge clk) begin
        pmem_write(mem_access[4], waddr, {30'h0, mem_access[1:0]}, wdata);
    end

endmodule