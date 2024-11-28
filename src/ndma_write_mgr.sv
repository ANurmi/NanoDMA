module ndma_write_mgr #()(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        req_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  OBI_BUS.Manager     write_mgr
);

// sanity tieoff:

assign write_mgr.req = 0;

endmodule : ndma_write_mgr
