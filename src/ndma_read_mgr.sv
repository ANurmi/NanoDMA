module ndma_read_mgr #()(
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        req_i,
  input  logic [31:0] addr_i,
  output logic [31:0] rdata_o,
  output logic        busy_o,
  OBI_BUS.Manager     read_mgr
);

typedef enum logic [1:0] {
  IDLE,
  ACK,
  VALID
} state_t;

state_t curr_state, next_state;

always_ff @(posedge(clk_i) or negedge(rst_ni))
  begin : state_reg
    if(~rst_ni) begin
      curr_state <= IDLE;
    end
    else begin
      curr_state <= next_state;
    end
  end : state_reg

always_comb
  begin : main_fsm
    next_state   = IDLE;
    read_mgr.req = 0;
    rdata_o      = 0;
    busy_o       = 0;

    case (curr_state)
      IDLE: begin
        if (req_i) begin
          read_mgr.req  = 1;
          read_mgr.addr = addr_i;
          next_state    = ACK;
        end
      end
      ACK: begin
        busy_o = 1;
        if (read_mgr.gnt) begin
          next_state = VALID;
        end else begin
          next_state = ACK;
        end
      end
      VALID: begin
        busy_o = 1;
        if (read_mgr.rvalid) begin
          rdata_o = read_mgr.rdata;
          if (req_i) begin
            read_mgr.req  = 1;
            read_mgr.addr = addr_i;
            next_state    = ACK;
          end else begin
            busy_o = 0;
            next_state = IDLE;
          end
        end else begin
          next_state = VALID;
        end
      end
      default: next_state = IDLE;
    endcase
  end

// always reading
assign read_mgr.we         = 1'b0;

assign read_mgr.be         = 4'b0;
assign read_mgr.wdata      = '0;
assign read_mgr.aid        = '0;
assign read_mgr.a_optional = '0;


endmodule : ndma_read_mgr
