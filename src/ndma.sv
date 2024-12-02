// Antti Nurmi <antti.nurmi@tuni.fi>

module ndma #(
  // Depth of internal FIFO -> how much read data can be buffered if writes are congested
  parameter  int unsigned Depth     = 3,
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
logic          [31:0] src_addr_reg, dst_addr_reg;
logic          [31:0] read_data, write_data;
logic [TxCntBits-1:0] rd_counter_q, rd_counter_d;
logic [TxCntBits-1:0] wr_counter_q, wr_counter_d;
logic [TxCntBits-1:0] tx_len;
logic                 reg_rd_req, rd_req, wr_req;
logic                 fifo_full, fifo_empty;
logic                 read_busy, write_busy;
logic                 tx_done;

typedef enum logic [1:0] {
  RESET,
  RD_REQ,
  RD_ACK,
  WAIT
} state_t;

state_t curr_state, next_state;

always_ff @(posedge clk_i or negedge rst_ni) begin : g_regs
  if (~rst_ni) begin
    rd_counter_q <= '0;
    wr_counter_q <= '0;
    curr_state <= RESET;
  end else begin
    curr_state <= next_state;
    rd_counter_q <= rd_counter_d;
    wr_counter_q <= wr_counter_d;
  end
end : g_regs

assign rd_counter_d =  (read_mgr.rvalid) ? rd_counter_q + 1 : rd_counter_q;
assign wr_counter_d = (write_mgr.rvalid) ? wr_counter_q + 1 : wr_counter_q;

assign src_addr = src_addr_reg + (rd_counter_d * 4);
assign dst_addr = dst_addr_reg + (wr_counter_d * 4);

assign tx_done = ((rd_counter_q == tx_len) && (wr_counter_q == tx_len));

always_comb
  begin : main_fsm
    next_state = RESET;
    wr_req     = 0;
    rd_req     = 0;

    case (curr_state)
      RESET: begin
        if (reg_rd_req ) begin
          //rd_req     = 1;
          next_state = RD_REQ;
        end
      end
      RD_REQ: begin
        if (!tx_done)
          next_state = WAIT;
        if (!fifo_full)
          rd_req = 1;
      end
      WAIT: begin
        //if(read_mgr.rvalid & write_mgr.rvalid)
        //  next_state = RD_WR_REQ;
        if (tx_done)
          next_state = RESET;
        else if (read_mgr.rvalid)
          next_state = RD_ACK;
        //else if ( write_mgr.rvalid)
        //  next_state = WR_REQ;
        else
          next_state = WAIT;
      end
      RD_ACK: begin
        if (!fifo_full & !read_busy)
          rd_req = 1;
        if (!fifo_empty & !write_busy)
          wr_req = 1;
        next_state = WAIT;
      end
      default:;
    endcase
  end


fifo_v3 #(
  .DEPTH      (Depth),
  .DATA_WIDTH (DataWidth)
) i_data_fifo (
  .clk_i,
  .rst_ni,
  .flush_i    (),
  .testmode_i (),
  .full_o     (fifo_full),
  .empty_o    (fifo_empty),
  .usage_o    (),
  .data_i     (read_data),
  .push_i     (read_mgr.rvalid),
  .data_o     (write_data),
  .pop_i      (wr_req)
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
  .rd_mgr_addr_o (src_addr_reg),
  .wr_mgr_addr_o (dst_addr_reg),
  .rd_mgr_req_o  (reg_rd_req),
  .dma_tx_len_o  (tx_len)
);

ndma_read_mgr  #() i_read_mgr (
  .clk_i,
  .rst_ni,
  .req_i    (rd_req),
  .addr_i   (src_addr),
  .rdata_o  (read_data),
  .read_mgr (read_mgr),
  .busy_o   (read_busy)
);
ndma_write_mgr #() i_write_mgr (
  .clk_i,
  .rst_ni,
  .req_i     (wr_req),
  .addr_i    (dst_addr),
  .wdata_i   (write_data),
  .write_mgr (write_mgr),
  .busy_o    (write_busy)
);

endmodule : ndma
