module ndma_read_mgr #()(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        req_i,
  input  logic [31:0] addr_i,
  output logic [31:0] rdata_o,
  OBI_BUS.Manager     read_mgr
);


// sanity tieoff:
assign  read_mgr.req = 0;


endmodule : ndma_read_mgr
