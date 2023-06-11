////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Coverage
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module coverage 
  import dataTypes::*;
#(
  parameter SIZE = 8
)(
  rtl_if rif
);


localparam HIGH=1, LOW=0;
covergroup fifo_cg @(posedge rif.CLK, posedge rif.RESET);
clear: 		coverpoint rif.clear 	iff(!rif.RESET) {bins clearEnabled = {HIGH};     bins clearDisabled = {LOW};}
rd_en: 		coverpoint rif.rd_en 	iff(!rif.RESET) {bins rdEnabled = {HIGH};        bins rdDisabled = {LOW};}
wr_en: 		coverpoint rif.wr_en 	iff(!rif.RESET) {bins wrEnabled = {HIGH};        bins wrDisabled = {LOW};}

RESET:		coverpoint rif.RESET {bins resethigh = {HIGH}; bins resetlow = {LOW};}

fifo_empty: 	coverpoint rif.fifo_empty 	iff(!rif.RESET) {bins fifoemptyEnabled = {HIGH}; bins fifoemptyDisabled = {LOW};}
fifo_full: 	coverpoint rif.fifo_full 	iff(!rif.RESET) {bins fifofullEnabled = {HIGH};  bins fifofullDisabled = {LOW};}

error:		coverpoint rif.error {bins errorhigh = {HIGH}; bins errorlow = {LOW};}


cross_error: cross error,rd_en,wr_en,rif.RESET,clear;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////MODIFCATIONS PROF. OLSON PERSONALLY ASKED US TO MAKE//////////////////////////

	B2B_Write:		coverpoint rif.wr_en		iff(!rif.RESET)	{ bins b2b_wr = (1[*SIZE]);}
	B2B_Read:		coverpoint rif.rd_en		iff(!rif.RESET)	{ bins b2b_rd = (1[*SIZE]);}
	Cross_bypass:				cross rif.rd_en,rif.wr_en,rif.fifo_empty;	  	    
	Cross_clear_fifo_empty:			cross rif.clear,rif.fifo_empty;	

//Corner test values bins
write_data: coverpoint rif.wr_data iff(!rif.RESET) {
    bins WriteData00 = {'h00};
    bins WriteData55 = {'h55};
    bins WriteDataAA = {'hAA};
    bins WriteDataFF = {'hFF};
    bins WriteDataRemaining = default;
}

read_data: coverpoint rif.rd_data iff(!rif.RESET) {
    bins ReadData00 = {'h00};
    bins ReadData55 = {'h55};
    bins ReadDataAA = {'hAA};
    bins ReadDataFF = {'hFF};
    bins ReadDataRemaining = default;
} 
			    						    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// FIFO is full and performing a write
full_x_write: cross rif.fifo_full, rif.wr_en;

// FIFO is empty and performing a read
empty_x_read: cross rif.fifo_empty, rif.rd_en;

// Performing a read when clear signal is asserted
rd_en_x_clear: cross rif.rd_en, rif.clear;

// fifo_full goes 0->1
fifo_full_transition: coverpoint rif.fifo_full iff(!rif.RESET) {bins fifofullGoingHigh = (0=>1); bins fifofullGoingLow = (1=>0);}

// fifo_empty goes 0->1
fifo_empty_transition: coverpoint rif.fifo_empty iff(!rif.RESET) {bins fifoemptyGoingHigh = (0=>1); bins fifoemptyGoingLow = (1=>0);}

// FIFO is empty and clear signals are asserted
empty_x_clear: cross rif.fifo_empty, rif.clear;

// Performing a write when clear signal is asserted
wr_en_x_clear: cross rif.wr_en, rif.clear;

// Read and Write signals are asserted
rd_en_x_wr_en: cross rif.rd_en, rif.wr_en;


// FIFO is empty and read and write signals are asserted
fifo_empty_x_rd_en_x_wr_en: 	cross rif.fifo_empty, rif.rd_en, rif.wr_en;

// FIFO is full and read and write signals are asserted
fifo_full_x_rd_en_x_wr_en: 	cross rif.fifo_full, rif.rd_en, rif.wr_en;

rd_en_x_wr_en_x_clear: cross rif.rd_en, rif.wr_en, rif.clear;

endgroup : fifo_cg

fifo_cg cg;

initial begin
cg = new();
end
endmodule
