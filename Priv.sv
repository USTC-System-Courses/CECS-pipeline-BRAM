module Priv(
    input  logic [ 2:0] csr_op,
    input  logic [31:0] csr_rdata,
    input  logic [31:0] rf_rdata1,
    input  logic [31:0] zimm,
    output logic [31:0] csr_wdata
);
    localparam 
        CSRRW   = 3'b001,
        CSRRS   = 3'b010,
        CSRRC   = 3'b011,
        CSRRWI  = 3'b101,
        CSRRSI  = 3'b110,
        CSRRCI  = 3'b111;
    always_comb begin
        // Lab4 TODO: implement CSR calculate logic
    end
endmodule