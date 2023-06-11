parameter DATA_WIDTH = 8;
parameter SIZE = 8;
parameter CLOCK_PERIOD = 1000;

class scoreboard;
	virtual rtl_if vif;
	
	function new(virtual rtl_if top_if);
    		vif = top_if;
  	endfunction : new
	
		logic [DATA_WIDTH-1:0] fifo [$ : SIZE-1];
		logic [DATA_WIDTH-1:0] predicted_rd_data, clear_data;
		logic predicted_fifo_full, predicted_fifo_empty, predicted_error=0,clren;
		logic readen;
		
		int ope;
		
task check();

fork
forever begin
readen = vif.rd_en & ~vif.wr_en & ~vif.clear & ~vif.RESET;
@(posedge vif.CLK) //or posedge readen)// or posedge vif.rd_en and negedge vif.wr_en and negedge vif.clear and negedge vif.RESET)
if(vif.RESET) begin
ope=0;
fifo.delete();
{predicted_fifo_full,predicted_fifo_empty} = 2'b01;
predicted_error = {vif.wr_en,vif.rd_en,vif.clear}==3'b000 ? 0 : 1;
end

else if(vif.clear &&fifo.size!= 0) begin
ope=1;
fifo.pop_front();
predicted_rd_data = 'bx;
predicted_fifo_full = fifo.size() == SIZE ? 1 : 0 ;
predicted_fifo_empty = fifo.size() == 0 ? 1 : 0 ;
predicted_error = vif.wr_en | vif.rd_en | predicted_fifo_empty;
end 

else if(vif.wr_en && vif.rd_en && predicted_fifo_empty && !vif.clear) begin
ope=2;
predicted_rd_data = vif.wr_data;
predicted_fifo_full = fifo.size() == SIZE ? 1 : 0 ;
predicted_fifo_empty = fifo.size() == 0 ? 1 : 0 ;
predicted_error = 1;
end 

else if(vif.wr_en && fifo.size != SIZE) begin
ope=3;
fifo.push_front(vif.wr_data);
predicted_rd_data = 'bx;
predicted_fifo_full = fifo.size() == SIZE ? 1 : 0 ;
predicted_fifo_empty = fifo.size() == 0 ? 1 : 0 ;
predicted_error = predicted_fifo_full | vif.rd_en | vif.clear;
end 

else if(vif.rd_en && fifo.size != 0) begin
ope=4;
if(vif.rd_en != readen ) predicted_rd_data = fifo.pop_back();
predicted_rd_data = fifo.pop_back();
predicted_fifo_full = fifo.size() == SIZE ? 1 : 0 ;
predicted_fifo_empty = fifo.size() == 0 ? 1 : 0 ;
predicted_error = predicted_fifo_empty | vif.clear | vif.wr_en;
//readen = vif.rd_en;
end 

else begin
ope=5;
predicted_rd_data = 'bx;
predicted_error = 1; //unsure
end
@(negedge vif.CLK)
if({predicted_rd_data,predicted_fifo_full,predicted_fifo_empty,predicted_error}!== {vif.rd_data,vif.fifo_full,vif.fifo_empty,vif.error}) begin
$display("OBSERVED %d",ope);
$display(" %7t reset = %d clear = %b wr_en = %b  rd_en = %b wr_data = %d ",
       $time/CLOCK_PERIOD, vif.RESET, vif.clear,vif.wr_en, vif.rd_en, vif.wr_data);  
$display(" rd_data = %d fifo_empty = %b   fifo_full = %b  error =%d", vif.rd_data, vif.fifo_empty, vif.fifo_full, vif.error);
$display("EXPECTED");
$display(" rd_data = %d fifo_empty = %b   fifo_full = %b  error =%d", predicted_rd_data, predicted_fifo_empty, predicted_fifo_full, predicted_error);
readen = vif.rd_en & ~(vif.wr_en | vif.clear | vif.RESET);
clren = vif.clear;
end end


join

endtask
endclass



class random_stimulus_packet;
  rand bit [7:0] datainput;
endclass


class tester;
  
  virtual rtl_if vif;
  random_stimulus_packet random_packet;
  
  
  function new(virtual rtl_if rif);
    vif = rif;
  endfunction : new
  
  
//BASIC TESTS 
  

  task reset();
	vif.reset();
  endtask


  task write();
      random_packet = new();
      assert(random_packet.randomize());
	vif.write(random_packet.datainput);
	@(negedge vif.CLK);
  endtask

  task corner_writes();
      	vif.write('b0);
	@(negedge vif.CLK);
      	vif.write('b1);
	@(negedge vif.CLK);
      	vif.write('ha);
	@(negedge vif.CLK);
      	vif.write('h5);
	@(negedge vif.CLK);
  endtask

  task read();
    vif.read();
    @(negedge vif.CLK);
  endtask

  task undo();
    vif.undo();
    @(negedge vif.CLK);
  endtask  

  task bypass();
      read_until_empty();
      random_packet = new();
      assert(random_packet.randomize());
	vif.bypass(random_packet.datainput);
	@(negedge vif.CLK);
  endtask

  task illegal_bypass();
      write();
      random_packet = new();
      assert(random_packet.randomize());
	vif.bypass(random_packet.datainput);
	@(negedge vif.CLK);
  endtask

/////////////////////////////////////////////////
/////////////////////////////////////////////////

//CYCLIC TESTS

 task write_until_full();
   
         while(!vif.fifo_full) 
      write();
     

endtask



task read_until_empty();

       while(!vif.fifo_empty) begin
		read();
	end
endtask


task clear_until_empty();
       while(!vif.fifo_empty) begin
		undo();
	end
endtask

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////

//RESET TESTS

task reset_and_clear(); //reset+clear
	vif.custom(1,0,0,1);
	@(negedge vif.CLK);
endtask

task reset_and_read(); //reset+read
	vif.custom(1,0,1,0);
	@(negedge vif.CLK);
endtask

task reset_and_write(); //reset+write
	vif.custom(1,1,0,0);
	@(negedge vif.CLK);
endtask

task nop();
	vif.custom(0,0,0,0);
	@(negedge vif.CLK);
endtask


//////////////////////////////////////////////////////
///////////////////////////////////////////////////////

//ERROR TESTS

task clear_we(); //clear+wr_en
	vif.custom(0,1,0,1);
	@(negedge vif.CLK);
endtask

task clear_re; //clear+rd_en
	vif.custom(0,0,1,1);
	@(negedge vif.CLK);
endtask

task empty_clrden(); //empty+clear+rd_en
	read_until_empty();
	vif.custom(0,0,1,1);
	@(negedge vif.CLK);
endtask

task full_clrden(); //full+clear+rd_en
	write_until_full();
	vif.custom(0,0,1,1);
	@(negedge vif.CLK);
endtask

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

//RESET ORDER TESTS

task f_reset(); //reset when full
	write_until_full();
	reset();
endtask

task e_reset(); //reset when empty
	read_until_empty();
	reset();
endtask

task clear_write();
	vif.custom(0,1,0,1);
endtask

task clear_write_empty();
	read_until_empty();
	clear_write();
endtask

task clear_write_full();
	write_until_full();
	clear_write();
endtask

task random_reset();
	vif.reset_wr_rd_cl();
endtask

task no_random_reset();
	vif.no_reset_wr_rd_cl();
endtask

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

//OVERFLOW AND UNDERFLOW

task write_full();

	write_until_full();
	write();
	@(negedge vif.CLK);
endtask


task read_empty();

	read_until_empty();
	vif.read();
	@(negedge vif.CLK);
endtask

task clear_empty();
	read_until_empty();
	vif.undo();
	@(negedge vif.CLK);
endtask

endclass

class testbench;
  tester testcase;
  scoreboard sb;

  function new(virtual rtl_if rif);
    testcase = new(rif);
    sb = new(rif);
  endfunction : new



  task run();
	testcase.reset();
	repeat(3)  testcase.write(); $display("\n"); //WRITE 
	repeat(3)  testcase.read(); $display("\n"); //READ
	repeat(3)  testcase.write(); $display("\n"); //WRITE
	repeat(3)  testcase.undo(); $display("\n"); //CLEAR
	repeat(3)  testcase.bypass(); $display("\n"); //BYPASS
	testcase.write_until_full(); $display("\n"); //FILL THE FIFO
	testcase.read_until_empty(); $display("\n"); //READ AND EMPTY FIFO
	testcase.write_until_full(); $display("\n"); 

	testcase.clear_we(); $display("\n"); // CLEAR + WRITE ENABLE
	testcase.clear_re(); $display("\n"); //CLEAR + READ ENABLE
	testcase.illegal_bypass(); $display("\n"); //illegal_bypass
	testcase.empty_clrden(); $display("\n"); //EMPTY THEN CLEAR + READ ENABLE
	testcase.clear_write();
	testcase.nop(); //no operation
	testcase.full_clrden(); $display("\n");  //FULL THEN CLEAR + READ ENABLE
	testcase.clear_write_empty(); $display("\n"); // CLEAR + WRITE when empty
	testcase.clear_write_full(); $display("\n"); // CLEAR + WRITE when full

	testcase.read_empty(); $display("\n"); //READ WHEN EMPTY
	testcase.write_full(); $display("\n"); //WRITE WHEN FULL
	testcase.clear_empty(); $display("\n"); //CLEAR WHEN EMPTY

	testcase.corner_writes(); $display("\n");repeat(4)testcase.read(); $display("\n"); //CORNER 00 FF AA 55 TESTS

	testcase.f_reset(); $display("\n"); //RESET WHEN FULL
	testcase.corner_writes();
	testcase.e_reset(); $display("\n"); //RESET WHEN EMPTY
	testcase.corner_writes();

	testcase.reset_and_clear(); $display("\n"); //RESET + CLEAR
	testcase.reset_and_read(); $display("\n"); //RESET + READ
	testcase.reset_and_write(); $display("\n"); //RESET + WRITE
	testcase.clear_until_empty();$display("\n"); //CLEAR UNTIL EMPTY
	
	$display("END OF DIRECT TESTS. NOW STARTING RANDOMIZED TESTS");$display("\n");
	
repeat(1000) begin //1000 random tests
randsequence (taskSequence)
    taskSequence : one | two | three | four | five | six | seven | eight | nine | ten | eleven | twelve | thirteen | fourteen | fifteen | sixteen | seventeen | eighteen | nineteen | twenty | twentyone | twentytwo;
      one : {testcase.write();};
      two : {testcase.read();};
      three : {testcase.undo();};
      four : {testcase.bypass();};
      five : {testcase.write_until_full();};
      six : {testcase.read_until_empty();};
      seven : {testcase.clear_we();};
      eight : {testcase.clear_re();};
      nine : {testcase.empty_clrden();};
      ten : {testcase.full_clrden();};
      eleven : {testcase.read_empty();};
      twelve : {testcase.write_full();};
      thirteen : {testcase.clear_empty();};
      fourteen : {testcase.corner_writes();};
      fifteen : { testcase.reset_and_clear();};
      sixteen : {testcase.reset_and_read();};
      seventeen : {testcase.reset_and_write();};
      eighteen : {testcase.illegal_bypass();};
      nineteen : {testcase.clear_write();};
      twenty : {testcase.clear_write_empty();};
      twentyone : {testcase.clear_write_full();};
	  twentytwo : {testcase.nop();};
   
  endsequence

end 
	


$stop();

  endtask

task execute_full();
fork 
run();
sb.check();
join
endtask 


    
endclass : testbench



module top_tb;

localparam CLOCK_PERIOD = 1000;
localparam RESET_CYCLES = 5;
localparam FIFO_SIZE = 8;

  rtl_if rif();
  fifo test_rtl( .rif(rif.dut) );
  testbench testbench_h;
	coverage #(.SIZE(FIFO_SIZE)) cov_dut (rif.cov);

  initial begin : main_sequence
    $display("\n\t Test Begin\n");
    testbench_h = new(rif);
    testbench_h.execute_full();
	$display("TESTS OVER");
    $stop();
	
  end : main_sequence


endmodule