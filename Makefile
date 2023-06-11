
all: clean compile run cov

compile:
	vlib work
	vlog FILES.svh

run:
	vsim -c -coverage -voptargs=+acc -do "coverage save -onexit testcov.ucdb; run -all; quit -sim; exit" top_tb
	
cov:
	vcover report testcov.ucdb

clean:
	rm -rf work
	rm -rf transcript
	rm -rf *.ucdb
