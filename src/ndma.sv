// Antti Nurmi <antti.nurmi@tuni.fi>

module ndma #(
  // Depth of internal FIFO -> how much read data can be buffered if writes are congested
  parameter  int unsigned Depth     = 1,
  // Maximal transfer size, effects internal counter width
  parameter  int unsigned MaxTxSize = 256,
  parameter  int unsigned DataWidth = 32,
  localparam int unsigned TxCntBits = $clog2(MaxTxSize)
)(
  input  logic        clk_i,
  input  logic        rst_ni,
  output logic        tx_done_irq_o,
  OBI_BUS.Manager     read_mgr,
  OBI_BUS.Manager     write_mgr,
  input  logic        cfg_req_i,
  input  logic        cfg_we_i,
  output logic        cfg_gnt_o,
  input  logic [31:0] cfg_addr_i,
  input  logic [31:0] cfg_wdata_i,
  output logic [31:0] cfg_rdata_o,
  output logic        cfg_rvalid_o
);

logic          [31:0] src_addr, dst_addr;
logic          [31:0] read_data, write_data;
logic [TxCntBits-1:0] tx_counter_q, tx_counter_d;
logic                 rd_req, wr_req;

always_ff @(posedge clk_i or negedge rst_ni) begin : g_regs
  if (~rst_ni) begin
    tx_counter_q <= '0;
  end else begin
    tx_counter_q <= tx_counter_d;
  end
end : g_regs

fifo_v3 #(
  .DEPTH      (Depth),
  .DATA_WIDTH (DataWidth)
) i_data_fifo (
  .clk_i,
  .rst_ni,
  .flush_i    (),
  .testmode_i (),
  .full_o     (),
  .empty_o    (),
  .usage_o    (),
  .data_i     (),
  .push_i     (0),
  .data_o     (),
  .pop_i      (0)
);

ndma_reg #() i_cfg_regs (
  .clk_i,
  .rst_ni,
  .req_i         (cfg_req_i),
  .we_i          (cfg_we_i),
  .gnt_o         (cfg_gnt_o),
  .addr_i        (cfg_addr_i),
  .wdata_i       (cfg_wdata_i),
  .rdata_o       (cfg_rdata_o),
  .rvalid_o      (cfg_rvalid_o),
  .rd_mgr_addr_o (src_addr),
  .wr_mgr_addr_o (dst_addr),
  .rd_mgr_req_o  (rd_req),
  .dma_tx_len_o  ()
);

ndma_read_mgr  #() i_read_mgr (
  .clk_i,
  .rst_ni,
  .req_i    (rd_req),
  .addr_i   (src_addr),
  .rdata_o  (read_data),
  .read_mgr (read_mgr)
);
ndma_write_mgr #() i_write_mgr (
  .clk_i,
  .rst_ni,
  .req_i     (wr_req),
  .addr_i    (dst_addr),
  .wdata_i   (write_data),
  .write_mgr (write_mgr)
);

// sanity tieoff:
assign  read_mgr.req = 0;
assign write_mgr.req = 0;

endmodule : ndma
