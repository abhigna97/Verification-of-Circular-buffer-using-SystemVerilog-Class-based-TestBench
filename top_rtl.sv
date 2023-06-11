// top_rtl.sv
// Top-level RTL

module top_rtl
  import dataTypes::*;
#(
  parameter SIZE = 32
)(
  rtl_if top_if
);

  fifo #(.SIZE(SIZE)) fifo(top_if);

endmodule : top_rtl
