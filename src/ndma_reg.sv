module ndma_reg #()(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        req_i,
  input  logic        we_i,
  output logic        gnt_o,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic [31:0] rdata_o,
  output logic        rvalid_o,
  output logic [31:0] rd_mgr_addr_o,
  output logic [31:0] wr_mgr_addr_o,
  output logic  [7:0] dma_tx_len_o,
  output logic        rd_mgr_req_o
);

localparam int unsigned CfgAddr = 2'b00; // BASE + 0x0
localparam int unsigned RdAddr  = 2'b01; // BASE + 0x4
localparam int unsigned WrAddr  = 2'b10; // BASE + 0x8

logic [31:0] rd_mgr_addr_d, rd_mgr_addr_q;
logic [31:0] wr_mgr_addr_d, wr_mgr_addr_q;
logic [31:0] rdata_d, rdata_q;
logic  [7:0] dma_tx_len_d, dma_tx_len_q;
logic        dma_tx_req_d, dma_tx_req_q;

assign rd_mgr_addr_o = rd_mgr_addr_q;
assign wr_mgr_addr_o = wr_mgr_addr_q;
assign dma_tx_len_o  = dma_tx_len_q;
assign rd_mgr_req_o  = dma_tx_req_q;
assign rdata_o       = rdata_q;

obi_handshake_fsm i_obi_fms (
  .clk_i,
  .rst_ni,
  .req_i    (req_i),
  .gnt_o    (gnt_o),
  .rvalid_o (rvalid_o)
);

always_ff @(posedge clk_i or negedge rst_ni) begin : g_regs
  if (~rst_ni) begin
    rd_mgr_addr_q <= 0;
    wr_mgr_addr_q <= 0;
    rdata_q       <= 0;
    dma_tx_len_q  <= 0;
    dma_tx_req_q  <= 0;
  end else begin
    rd_mgr_addr_q <= rd_mgr_addr_d;
    wr_mgr_addr_q <= wr_mgr_addr_d;
    rdata_q       <= rdata_d;
    dma_tx_len_q  <= dma_tx_len_d;
    dma_tx_req_q  <= dma_tx_req_d;
  end
end

always_comb begin : addr_decode
  rd_mgr_addr_d = rd_mgr_addr_q;
  wr_mgr_addr_d = wr_mgr_addr_q;
  rdata_d       = 0;
  dma_tx_len_d  = dma_tx_len_q;
  dma_tx_req_d  = 0;
  if (req_i) begin
    if (we_i) begin : write_logic
      unique case (addr_i[3:2]) inside
        CfgAddr: begin
          dma_tx_len_d = wdata_i[7:0];
          dma_tx_req_d = wdata_i[31];
        end
        RdAddr:  begin
          rd_mgr_addr_d = wdata_i;
        end
        WrAddr:  begin
          wr_mgr_addr_d = wdata_i;
        end
        default: begin
        end
      endcase
    end else begin : read_logic
      unique case (addr_i[3:2]) inside
        CfgAddr: rdata_d = {dma_tx_req_q, 23'b0, dma_tx_len_q};
        RdAddr:  rdata_d = rd_mgr_addr_q;
        WrAddr:  rdata_d = wr_mgr_addr_q;
        default: rdata_d = 0;
      endcase
    end
  end
end

endmodule : ndma_reg
