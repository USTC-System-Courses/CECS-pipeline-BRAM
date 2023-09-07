module Regfile(
    input  logic [ 0:0] clk,
    input  logic [ 4:0] raddr1,
    input  logic [ 4:0] raddr2,
    input  logic [ 4:0] waddr,
    input  logic [31:0] wdata,
    input  logic        we,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);
    logic [31:0] rf [31:0];
    import "DPI-C" function void set_gpr_ptr(input logic [31 : 0] a []);
    initial begin
        set_gpr_ptr(rf);
        for(integer i = 0; i < 32; i++) begin
            rf[i] = 0;
        end
    end
    always_ff @(posedge clk) begin
        if (we) begin
            rf[waddr] <= wdata;
        end
    end

    assign rdata1 = (we && waddr == raddr1) ? wdata : rf[raddr1];
    assign rdata2 = (we && waddr == raddr2) ? wdata : rf[raddr2];
endmodule