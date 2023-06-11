// types.sv

package dataTypes;

  parameter DATA_WIDTH = 8;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
  } data_packet_sp;

endpackage : dataTypes
