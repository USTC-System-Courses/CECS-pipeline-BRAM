`include "./include/config.sv"
module Decode(
    input  logic [31:0] inst,
    output logic [ 4:0] alu_op,
    output logic [ 4:0] mem_access,
    output logic [31:0] imm,
    output logic [ 0:0] rf_we,
    output logic [ 1:0] alu_rs1_sel,
    output logic [ 1:0] alu_rs2_sel,
    output logic [ 0:0] wb_rf_sel,
    output logic [ 4:0] br_type
);
    // normal decode 
    wire [4:0] rd = inst[11:7];
    wire [2:0] funct3 = inst[14:12];
    always_comb begin
        case(inst[6:0])
        'h37: begin
            // lui, U_TYPE
            imm         = {inst[31:12], 12'b0};
            mem_access  = `NO_ACCESS;
            alu_op      = `ADD;
            rf_we       = |rd;
            alu_rs1_sel = `SRC1_ZERO;
            alu_rs2_sel = `SRC2_IMM;
            wb_rf_sel   = `FROM_ALU;
            br_type     = {2'b0, funct3};
        end
        'h17: begin
            // auipc, U_TYPE
            // Lab3 TODO: finish auipc instruction decode

            // imm         
            // mem_access  
            // alu_op      = 
            // rf_we       = 
            // alu_rs1_sel = 
            // alu_rs2_sel = 
            // wb_rf_sel   = 
            // br_type     = 
        end
        'h6f: begin
            // jal, J_TYPE
            imm         = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            mem_access  = `NO_ACCESS;
            alu_op      = `ADD;
            rf_we       = |rd;
            alu_rs1_sel = `SRC1_PC;
            alu_rs2_sel = `SRC2_FOUR;
            wb_rf_sel   = `FROM_ALU;
            br_type     = {1'b1, inst[2], inst[3], inst[1:0]};
        end
        'h67: begin
            // jalr, I_TYPE
            // Lab3 TODO: finish jalr instruction decode

            // imm         =
            // mem_access  =
            // alu_op      =
            // rf_we       =
            // alu_rs1_sel =
            // alu_rs2_sel =
            // wb_rf_sel   =
            // br_type     =
        end
        'h63: begin
            // branch, B_TYPE
            imm         = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            mem_access  = `NO_ACCESS;
            alu_op      = `ADD;
            rf_we       = 0;
            alu_rs1_sel = `SRC1_REG1;
            alu_rs2_sel = `SRC2_REG2;
            wb_rf_sel   = `FROM_ALU;
            br_type     = {1'b1, inst[2], funct3};
        end
        'h03: begin
            // load, I_TYPE
            imm         = {{20{inst[31]}}, inst[31:20]};
            mem_access  = {2'b01, funct3}; 
            alu_op      = `ADD;
            rf_we       = |rd;
            alu_rs1_sel = `SRC1_REG1;
            alu_rs2_sel = `SRC2_IMM;
            wb_rf_sel   = `FROM_MEM;
            br_type     = {1'b0, inst[2], funct3};
        end
        'h23: begin
            // store, S_TYPE
            imm         = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            mem_access  = {2'b10, funct3};
            alu_op      = `ADD;
            rf_we       = 0;
            alu_rs1_sel = `SRC1_REG1;
            alu_rs2_sel = `SRC2_IMM;
            wb_rf_sel   = `FROM_ALU;
            br_type     = {1'b0, inst[2], funct3};
        end
        'h13: begin
            // imm, I_TYPE
            imm         = {{20{inst[31]}}, inst[31:20]};
            mem_access  = `NO_ACCESS;
            alu_op      = {(funct3 == 3'h5 && inst[30]), 1'b0, funct3};
            rf_we       = |rd;
            alu_rs1_sel = `SRC1_REG1;
            alu_rs2_sel = `SRC2_IMM;
            wb_rf_sel   = `FROM_ALU;
            br_type     = {1'b0, inst[2], funct3};
        end
        'h33: begin
            // R_TYPE
            // Lab3 TODO: finish R_TYPE instruction decode
            
            // imm         = 
            // mem_access  = 
            // alu_op      = 
            // rf_we       = 
            // alu_rs1_sel = 
            // alu_rs2_sel = 
            // wb_rf_sel   = 
            // br_type     = 
        end
        'h73: begin
            // CSR instruction
            // Lab4 TODO: finish CSR instruction decode

            // imm         = 
            // mem_access  = 
            // alu_op      = 
            // rf_we       = 
            // alu_rs1_sel = 
            // alu_rs2_sel = 
            // wb_rf_sel   = 
            // br_type     = 
        end
        default: begin
            imm         = 0;
            mem_access  = 0;
            alu_op      = 0;
            rf_we       = 0;
            alu_rs1_sel = 0;
            alu_rs2_sel = 0;
            wb_rf_sel   = 0;
            br_type     = 0;
        end
        endcase
    end
    // Lab4 TODO: you may need to decode for ecall and mret specially here

endmodule