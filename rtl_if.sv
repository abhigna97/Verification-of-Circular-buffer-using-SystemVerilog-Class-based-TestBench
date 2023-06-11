// rtl_if.sv

interface rtl_if
  import dataTypes::*;
(

);

  logic clear;
  logic rd_en;
  logic wr_en;
  data_packet_sp wr_data;
  data_packet_sp rd_data;
  logic fifo_empty;
  logic fifo_full;
  logic error;

  logic CLK;
  logic RESET;

  modport dut (
    input CLK, RESET, clear, rd_en, wr_en, wr_data,
    output rd_data, fifo_empty, fifo_full,error
  );

  modport cov (
    input CLK, RESET, clear, rd_en, wr_en, wr_data, rd_data, fifo_empty, fifo_full, error
  );

  localparam CLOCK_PERIOD = 1000;
  localparam RESET_CYCLES = 5;

  initial begin 
    CLK = 0;
    forever #(CLOCK_PERIOD/2) CLK = ~CLK;
  end 

//RESET
  task reset();
    RESET = 1;
    wr_en = 0;
    rd_en = 0;
    clear = 0;
    wr_data = 'bx;
    repeat(RESET_CYCLES) @(negedge CLK);
    RESET = 0;
  endtask


//WRITE
  task write(input logic [7:0] writedata);
    RESET = 0;
    wr_en = 1;
    rd_en = 0;
    clear = 0;
    wr_data = writedata;
    //$display("wr_data = %d, data11 = %d",wr_data,data11);
  endtask 
  
  
//READ  
  task read();
    RESET = 0;
    wr_en = 0;
    rd_en = 1;
    clear = 0;
    wr_data='bx;
  endtask: read
  
  
//UNDO (CLEAR)  
  task undo();
    RESET = 0;
    wr_en = 0;
    rd_en = 0;
    clear = 1;
  endtask : undo

//BYPASS
  task bypass(input logic [7:0] writedata);
    RESET = 0;
    wr_en = 1;
    rd_en = 1;
    clear = 0;
    wr_data = writedata;
    //$display("wr_data = %d, data11 = %d",wr_data,data11);
  endtask 


//ERROR FUNCTIONS

//Write + Clear
  task write_clear(input logic [7:0] writedata);
    RESET = 0;
    wr_en = 1;
    rd_en = 0;
    clear = 1;
    wr_data = writedata;
   // $display("wr_data = %d, data11 = %d",wr_data,data11);
  endtask


//Trying commands while reset
  task reset_wr_rd_cl ();
    RESET = 1;
    {wr_en, rd_en, clear} = $urandom_range(1, 7);;
    //$display("wr_data = %d, data11 = %d",wr_data,data11);
  endtask  

  task no_reset_wr_rd_cl ();
    RESET = 1;
    {wr_en, rd_en, clear} = 7;
    //$display("wr_data = %d, data11 = %d",wr_data,data11);
  endtask

//CUSTOM TASK
  task custom (input logic rs,wr,rd,cl);
    {RESET, wr_en, rd_en, clear} = {rs,wr,rd,cl};
  endtask


endinterface : rtl_if
