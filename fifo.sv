

module fifo
	import dataTypes::*;
#(
	parameter SIZE = 8
)(
	rtl_if rif
);
	localparam PTR_WIDTH = $clog2(SIZE);
  
	logic [DATA_WIDTH-1	:0] 	FIFO [SIZE-1:0];
	logic [PTR_WIDTH	:0] 	rdptr,wrptr;
	logic [DATA_WIDTH-1	:0] 	wr_data;
	logic [DATA_WIDTH-1	:0] 	rd_data;
	
	logic readtemp;
	assign readtemp = rif.rd_en & ~(rif.clear | rif.RESET | rif.wr_en);

	logic tw=0,tr=0;
	
	logic ff,fe;


	always_ff@(posedge rif.CLK or posedge readtemp) begin
		if(rif.RESET) begin
			FIFO	<=	'{default:'x};
			wrptr	<=	0;
			rdptr	<=	0;
			tw<=0;
			tr<=0;
		end else if(rif.clear && ~ rif.fifo_empty) begin //clear
				wrptr		<=	wrptr==0 ? SIZE-1 : wrptr - 1;
				tw		<=	wrptr==0 ? ~tw:tw;
				FIFO[wrptr - 1]	<= 'bx;
				rif.rd_data <= 'bx;
		end else if(rif.wr_en && rif.rd_en && rif.fifo_empty) begin //MODIFICATION
				wrptr		<=	wrptr;
				rdptr		<=	rdptr;
				rif.rd_data = rif.wr_data;
		end else if(rif.wr_en && !rif.fifo_full) begin //write
				wrptr		<=	wrptr==SIZE-1 ? 0 : wrptr+ 1;
				tw		<=	wrptr==SIZE-1 ? ~tw:tw;
				FIFO[wrptr]	<=	rif.wr_data;
				rif.rd_data = 'bx;
		end else if(rif.rd_en && !rif.fifo_empty) begin //read
				rdptr		<=	rdptr==SIZE-1 ? 0 : rdptr+ 1;
				tr		<=	rdptr==SIZE-1 ? ~tr:tr;
				FIFO[rdptr] <= 'bx;
				rif.rd_data = FIFO[rdptr];
		end else begin
				rdptr		<= 	rdptr;
				wrptr		<=	wrptr;
				if((rif.clear || rif.rd_en )&& rif.fifo_empty) rif.rd_data <= 'bx;
		end

	end
	
	assign rif.error = (rif.rd_en && rif.wr_en) || (rif.fifo_empty && rif.rd_en ) || (rif.fifo_empty && rif.clear) || (rif.fifo_empty && rif.rd_en && rif.clear) || (rif.fifo_full && rif.wr_en) || (rif.clear && rif.rd_en) || (rif.clear && rif.wr_en) || (rif.RESET &&(rif.rd_en || rif.wr_en || rif.clear));




	assign	rif.fifo_empty 	= rif.RESET ? '1 	: 	rdptr == wrptr && tr==tw ? 1 : 0;
	assign	rif.fifo_full 	= rif.RESET ? '0 	: 	rdptr == wrptr && tr!=tw ? 1 : 0;



//a1 8 r -
//a4 15 r -
//a5 2 d - multiple r
//a15 9 r -
//a8 3d - mult r -



// When FIFO is empty and wr_en is HIGH then fifo_empty goes from HIGH to LOW
a1: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (!rif.clear && rif.wr_en &&!rif.rd_en &&rif.fifo_empty) |=> $fell(rif.fifo_empty));
// When FIFO is full and rd_en is HIGH then fifo_full goes from HIGH to LOW
a2: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (!rif.wr_en && !rif.clear&& rif.rd_en && rif.fifo_full) |=> $fell(rif.fifo_full));
// When FIFO is full and clear is HIGH then fifo full goes from HIGH to LOW
a3: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (!rif.wr_en && !rif.rd_en && rif.clear && rif.fifo_full) |=> $fell(rif.fifo_full));
// When FIFO is empty then rdptr must not change
a4: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (rif.fifo_empty |=> $stable(rdptr)));
// When FIFO is full then wrptr must not change
a5: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (rif.fifo_full |=> $stable(wrptr))); // <- fails
// fifo full and fifo empty cannot be asserted at the same time
a6: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (rif.fifo_full |-> !rif.fifo_empty));
a7: assert property (@(posedge rif.CLK) disable iff(rif.RESET) (rif.fifo_empty |-> !rif.fifo_full));
// Bypass logic checking
a8: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.fifo_empty && rif.rd_en && rif.wr_en && !rif.clear) |-> (rif.rd_data == rif.wr_data))); // <- fails for 3 times
// When rd_en and fifo_empty is HIGH then error must go HIGH
a9: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.fifo_empty && rif.rd_en | rif.clear && !rif.wr_en) |-> rif.error)); // <- runs
// Whe fifo_empty is HIGH and clear is HIGH then error must go HIGH
a10: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.fifo_empty && rif.clear) |-> rif.error));
// When fifo_empty, rd_en and clear all are HIGH then error must go HIGH
a11: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.fifo_empty && rif.rd_en && rif.clear) |-> rif.error));
// When FIFO is full and wr_en is asserted then error must go HIGH
a12: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.fifo_full && rif.wr_en && !rif.clear && !rif.rd_en) |-> rif.error));
// When clear and wr_en both are asserted then error must go HIGH
a13: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.wr_en && rif.clear && !rif.rd_en) |-> rif.error));
// When RESET is asserted and either of rd_en, wr_en or clear are asserted then error must go HIGH
a14: assert property(@(posedge rif.CLK) ((rif.RESET && (rif.rd_en || rif.wr_en || rif.clear)) |-> rif.error));
// If clear is asserted, wrptr decreases by 1
a15: assert property(@(posedge rif.CLK) disable iff(rif.RESET) ((rif.clear && !rif.fifo_empty && !rif.wr_en && !rif.rd_en) |=> (wrptr==$past(wrptr)-1)));



endmodule : fifo