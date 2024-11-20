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
  input  logic [31:0] cfg_rdata_o,
  input  logic        cfg_rvalid_o
);

logic          [31:0] src_addr_q, dst_addr_q, src_addr_d, dst_addr_d;
logic [TxCntBits-1:0] tx_counter_q, tx_counter_d;

always_ff @(posedge clk_i or negedge rst_ni) begin : g_regs
  if (~rst_ni) begin
    src_addr_q   <= '0;
    dst_addr_q   <= '0;
    tx_counter_q <= '0;
  end else begin
    src_addr_q   <= src_addr_d;
    dst_addr_q   <= dst_addr_d;
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
  .push_i     (),
  .data_o     (),
  .pop_o      ()
);

ndma_read_mgr  #() i_read_mgr (
  .clk_i,
  .rst_ni,
  .addr_i ()
);
ndma_write_mgr #() i_write_mgr (
  .clk_i,
  .rst_ni,
  .addr_i ()
);

endmodule : ndma
