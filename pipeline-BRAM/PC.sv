module PC#(
    parameter RESET_VALUE = 0
)(
    input  logic [ 0:0] clk,
    input  logic [ 0:0] rstn,
    input  logic [ 0:0] stall,
    input  logic [31:0] next_pc,
    output logic [31:0] pc 
);
    logic [31:0] pc_reg;
    initial begin
        pc_reg = RESET_VALUE;
    end
    always_ff @(posedge clk) begin
        if(!rstn) begin
            pc_reg <= RESET_VALUE;
        end 
        else if(!stall) begin
            pc_reg <= next_pc;
        end
    end
    assign pc = pc_reg;
endmodule