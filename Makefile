IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

RTL = rtl/spi_master.v
TB = tb/spi_master_tb.v

SIM = sim/spi_sim
VCD = sim/spi_simulation.vcd

all: test

$(SIM): $(RTL) $(TB)
	$(IVERILOG) -g2012 -o $(SIM) $(RTL) $(TB)

test: $(SIM)
	$(VVP) $(SIM)

wave: test
	$(GTKWAVE) $(VCD)

clean:
	rm -f $(SIM) $(VCD)

.PHONY: all test wave clean
