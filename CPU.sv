`include "./include/config.sv"
module CPU#(
    parameter PC_RESET_VALUE = 32'h80000000,
    parameter I_CACHE_DEPTH = 8,
    parameter D_CACHE_DEPTH = 8
)(
    input  logic [   0:0] clk,
    input  logic [   0:0] rstn,
    output logic [   0:0] commit_wb,
    output logic [  31:0] pc_cur,
    output logic [  31:0] inst,
    output logic [   0:0] uncache_read_wb
);
    /* IF1 stage */
    logic [31:0]    pc_if1, pc_if2, pc_id, pc_ex, pc_ls, pc_wb;
    logic [31:0]    inst_if2, inst_id, inst_ex, inst_ls, inst_wb;
    logic [31:0]    pc_target, next_pc;
    logic [31:0]    imm_id, imm_ex;
    logic [31:0]    rf_wdata_wb;
    logic [31:0]    rf_rdata1_id, rf_rdata1_ex;
    logic [31:0]    rf_rdata2_id, rf_rdata2_ex;
    logic [31:0]    forward1_data, forward2_data;
    logic [31:0]    alu_rf_data1, alu_rf_data2;
    logic [31:0]    alu_rs1, alu_rs2;
    logic [31:0]    alu_result_ex, alu_result_ls, alu_result_wb;
    logic [31:0]    jump_target;
    logic [31:0]    mem_wdata_ex;
    logic [31:0]    mem_rdata_ls, mem_rdata_wb; 
    logic [31:0]    dcache_rdata_ls;
    logic [ 4:0]    alu_op_id, alu_op_ex;
    logic [ 4:0]    mem_access_id, mem_access_ex, mem_access_ls;
    logic [ 4:0]    br_type_id, br_type_ex;
    logic [ 3:0]    wstrb_ex;
    logic [ 1:0]    alu_rs1_sel_id, alu_rs1_sel_ex;
    logic [ 1:0]    alu_rs2_sel_id, alu_rs2_sel_ex;
    logic [ 0:0]    wb_rf_sel_id, wb_rf_sel_ex, wb_rf_sel_ls, wb_rf_sel_wb;
    logic [ 0:0]    rf_we_id, rf_we_ex, rf_we_ls, rf_we_wb;

    logic [ 0:0]    forward1_en, forward2_en;
    logic [ 0:0]    jump;
    logic [ 0:0]    pc_set, pc_stall;
    logic [ 0:0]    IF1_IF2_stall, IF1_IF2_flush;
    logic [ 0:0]    IF2_ID_stall, IF2_ID_flush;
    logic [ 0:0]    ID_EX_stall, ID_EX_flush;
    logic [ 0:0]    EX_LS_stall, EX_LS_flush;
    logic [ 0:0]    LS_WB_stall, LS_WB_flush;

    logic [ 0:0]    commit_if1, commit_if2, commit_id, commit_ex, commit_ls;

    assign inst = inst_wb;
    assign pc_cur = pc_wb;
    assign commit_if1 = rstn;
    NPC_Mux  NPC_Mux_inst (
        .pc         (pc_if1),
        .pc_set     (pc_set),
        .pc_target  (pc_target),
        .next_pc    (next_pc)
    );

    PC#(
        .RESET_VALUE(PC_RESET_VALUE)
    ) PC_inst (
        .clk        (clk),
        .rstn       (rstn),
        .stall      (pc_stall),
        .next_pc    (next_pc),
        .pc         (pc_if1)
    );


    /* IF1-IF2 segreg */
    SegReg_IF1_IF2 # (
        .PC_RESET_VAL(PC_RESET_VALUE)
    ) SegReg_IF1_IF2_inst (
        .clk        (clk),
        .rstn       (rstn),
        .stall      (IF1_IF2_stall),
        .flush      (IF1_IF2_flush),
        .pc_if1     (pc_if1),
        .pc_if2     (pc_if2),
        .commit_if1 (commit_if1),
        .commit_if2 (commit_if2)
    );
    ICache # (
        .DEPTH(I_CACHE_DEPTH)
    ) ICache_inst (
        .clk        (clk),
        .raddr      (pc_if1),
        .rdata      (inst_if2),
        .flush      (IF1_IF2_flush),
        .stall      (IF1_IF2_stall)
    );

    /* IF2 stage */
    /* IF2-ID segreg */
    SegReg_IF2_ID # (
        .PC_RESET_VAL(PC_RESET_VALUE)
    ) SegReg_IF2_ID_inst (
        .clk            (clk),
        .rstn           (rstn),
        .stall          (IF2_ID_stall),
        .flush          (IF1_IF2_flush),
        .pc_if2         (pc_if2),
        .inst_if2       (inst_if2),
        .pc_id          (pc_id),
        .inst_id        (inst_id),
        .commit_if2     (commit_if2),
        .commit_id      (commit_id)
    );

    /* ID stage */
    Decode  Decode_inst (
        .inst           (inst_id),
        .alu_op         (alu_op_id),
        .mem_access     (mem_access_id),
        .imm            (imm_id),
        .rf_we          (rf_we_id),
        .alu_rs1_sel    (alu_rs1_sel_id),
        .alu_rs2_sel    (alu_rs2_sel_id),
        .wb_rf_sel      (wb_rf_sel_id),
        .br_type        (br_type_id)
    );
    Regfile  Regfile_inst (
        .clk            (clk),
        .raddr1         (inst_id[19:15]),
        .raddr2         (inst_id[24:20]),
        .waddr          (inst_wb[11:7]),
        .wdata          (rf_wdata_wb),
        .we             (rf_we_wb),
        .rdata1         (rf_rdata1_id),
        .rdata2         (rf_rdata2_id)
    );

    /* ID-EX segreg */
    SegReg_ID_EX # (
        .PC_RESET_VAL(PC_RESET_VALUE)
    ) SegReg_ID_EX_inst (
        .clk            (clk),
        .rstn           (rstn),
        .stall          (ID_EX_stall),
        .flush          (ID_EX_flush),
        .pc_id          (pc_id),
        .inst_id        (inst_id),
        .rdata1_id      (rf_rdata1_id),
        .rdata2_id      (rf_rdata2_id),
        .imm_id         (imm_id),
        .mem_access_id  (mem_access_id),
        .op_id          (alu_op_id),
        .br_type_id     (br_type_id),
        .wb_rf_sel_id   (wb_rf_sel_id),
        .alu_rs1_sel_id (alu_rs1_sel_id),
        .alu_rs2_sel_id (alu_rs2_sel_id),
        .rf_we_id       (rf_we_id),
        .pc_ex          (pc_ex),
        .inst_ex        (inst_ex),
        .rdata1_ex      (rf_rdata1_ex),
        .rdata2_ex      (rf_rdata2_ex),
        .imm_ex         (imm_ex),
        .mem_access_ex  (mem_access_ex),
        .op_ex          (alu_op_ex),
        .br_type_ex     (br_type_ex),
        .wb_rf_sel_ex   (wb_rf_sel_ex),
        .alu_rs1_sel_ex (alu_rs1_sel_ex),
        .alu_rs2_sel_ex (alu_rs2_sel_ex),
        .rf_we_ex       (rf_we_ex),
        .commit_id      (commit_id),
        .commit_ex      (commit_ex)

    );

    /* EX stage */
    Mux2_1 # (
        .WIDTH(32)
    )   ALU_rf_data1_mux (
        .din1           (rf_rdata1_ex),
        .din2           (forward1_data),
        .sel            (forward1_en),
        .dout           (alu_rf_data1)
    );
    Mux2_1 # (
        .WIDTH(32)
    )   ALU_rf_data2_mux (
        .din1           (rf_rdata2_ex),
        .din2           (forward2_data),
        .sel            (forward2_en),
        .dout           (alu_rf_data2)
    );
    Mux4_1 # (
        .WIDTH(32)
    )   ALU_rs1_mux (
        .din1           (alu_rf_data1),
        .din2           (pc_ex),
        .din3           (32'h0),
        .din4           (32'h0),
        .sel            (alu_rs1_sel_ex),
        .dout           (alu_rs1)
    );
    Mux4_1 # (
        .WIDTH(32)
    )   ALU_rs2_mux (
        .din1           (alu_rf_data2),
        .din2           (imm_ex),
        .din3           (32'h4),
        .din4           (32'h0),
        .sel            (alu_rs2_sel_ex),
        .dout           (alu_rs2)
    );

    ALU  ALU_inst (
        .sr1            (alu_rs1),
        .sr2            (alu_rs2),
        .alu_op         (alu_op_ex),
        .result         (alu_result_ex)
    );

    Branch  Branch_inst (
        .br_type        (br_type_ex),
        .sr1            (alu_rf_data1),
        .sr2            (alu_rf_data2),
        .pc             (pc_ex),
        .imm            (imm_ex),
        .jump           (jump),
        .jump_target    (jump_target)
    );

    /* EX-LS segreg */
    SegReg_EX_LS # (
        .PC_RESET_VAL(PC_RESET_VALUE)
    ) SegReg_EX_LS_inst (
        .clk            (clk),
        .rstn           (rstn),
        .stall          (EX_LS_stall),
        .flush          (EX_LS_flush),
        .pc_ex          (pc_ex),
        .inst_ex        (inst_ex),
        .alu_result_ex  (alu_result_ex),
        .mem_access_ex  (mem_access_ex),
        .wb_rf_sel_ex   (wb_rf_sel_ex),
        .rf_we_ex       (rf_we_ex),
        .pc_ls          (pc_ls),
        .inst_ls        (inst_ls),
        .alu_result_ls  (alu_result_ls),
        .mem_access_ls  (mem_access_ls),
        .wb_rf_sel_ls   (wb_rf_sel_ls),
        .rf_we_ls       (rf_we_ls),
        .commit_ex      (commit_ex),
        .commit_ls      (commit_ls)
    );

    DCache # (
        .DEPTH(D_CACHE_DEPTH)
    ) DCache_inst (
        .clk            (clk),
        .raddr          (alu_result_ex),
        .rdata          (dcache_rdata_ls),
        .waddr          (alu_result_ex),
        .wdata          (alu_rf_data2),
        .mem_access     (mem_access_ex),
        .flush          (EX_LS_flush),
        .stall          (EX_LS_stall)
    );

    /* LS stage */
    DCache_Read_Ctrl  DCache_Read_Ctrl_inst (
        .mem_rdata      (dcache_rdata_ls),
        .mem_raddr      (alu_result_ls),
        .mem_access     (mem_access_ls),
        .rdata          (mem_rdata_ls)
    );

    /* LS-WB segreg */
    SegReg_LS_WB # (
        .PC_RESET_VAL(PC_RESET_VALUE)
    ) SegReg_LS_WB_inst (
        .clk                (clk),
        .rstn               (rstn),
        .stall              (LS_WB_stall),
        .flush              (LS_WB_flush),
        .pc_ls              (pc_ls),
        .inst_ls            (inst_ls),
        .alu_result_ls      (alu_result_ls),
        .mem_rdata_ls       (mem_rdata_ls),
        .wb_rf_sel_ls       (wb_rf_sel_ls),
        .rf_we_ls           (rf_we_ls),
        .pc_wb              (pc_wb),
        .inst_wb            (inst_wb),
        .alu_result_wb      (alu_result_wb),
        .mem_rdata_wb       (mem_rdata_wb),
        .wb_rf_sel_wb       (wb_rf_sel_wb),
        .rf_we_wb           (rf_we_wb),
        .commit_ls          (commit_ls),
        .commit_wb          (commit_wb),
        .read_ls            (mem_access_ls[`LOAD_BIT]),
        .uncache_read_wb    (uncache_read_wb)
    );

    /* WB stage */
    Mux2_1 # (
        .WIDTH(32)
    )   WB_rf_wdata_mux (
        .din1           (alu_result_wb),
        .din2           (mem_rdata_wb),
        .sel            (wb_rf_sel_wb),
        .dout           (rf_wdata_wb)
    );


    /* Hazard */
    Hazard  Hazard_inst (
        .rf_rd_ls           (inst_ls[11:7]),
        .rf_rd_wb           (inst_wb[11:7]),
        .rf_we_ls           (rf_we_ls),
        .rf_we_wb           (rf_we_wb),
        .rf_rs1_ex          (inst_ex[19:15]),
        .rf_rs2_ex          (inst_ex[24:20]),
        .rf_wdata_tmp_ls    (alu_result_ls),
        .rf_wdata_wb        (rf_wdata_wb),
        .forward1_en        (forward1_en),
        .forward2_en        (forward2_en),
        .forward1_data      (forward1_data),
        .forward2_data      (forward2_data),

        .mem_access_ex      (mem_access_ex),
        .rf_rd_ex           (inst_ex[11:7]),
        .rf_rs1_id          (inst_id[19:15]),
        .rf_rs2_id          (inst_id[24:20]),
        .jump               (jump),
        .jump_target        (jump_target),

        .pc_set             (pc_set),
        .IF1_IF2_flush      (IF1_IF2_flush),
        .IF2_ID_flush       (IF2_ID_flush),
        .ID_EX_flush        (ID_EX_flush),
        .EX_LS_flush        (EX_LS_flush),
        .LS_WB_flush        (LS_WB_flush),
        .pc_stall           (pc_stall),
        .IF1_IF2_stall      (IF1_IF2_stall),
        .IF2_ID_stall       (IF2_ID_stall),
        .ID_EX_stall        (ID_EX_stall),
        .EX_LS_stall        (EX_LS_stall),
        .LS_WB_stall        (LS_WB_stall),
        .pc_set_target      (pc_target)
    ); 
`ifdef DEBUG
    assign putchar = |wstrb_ex && (&alu_result_ex);
    assign c = mem_wdata_ex[31 : 24];
`endif
endmodule