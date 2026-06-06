# clk is from the 100 MHz oscillator on Boolean board
set_property PACKAGE_PIN N15 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]

# RBG0 LED
set_property PACKAGE_PIN C9 [get_ports RGB0_red]
set_property IOSTANDARD LVCMOS33 [get_ports RGB0_red]
#set_property PACKAGE_PIN A9 [get_ports RGB0_green]
#set_property IOSTANDARD LVCMOS33 [get_ports RGB0_green] 

# BTN0
set_property PACKAGE_PIN J2 [get_ports rst] 
set_property IOSTANDARD LVCMOS18 [get_ports rst]

# BTN1
#set_property PACKAGE_PIN J1 [get_ports start]
#set_property IOSTANDARD LVCMOS18 [get_ports start]

# UART Pins
set_property PACKAGE_PIN A16 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS18 [get_ports uart_tx]
set_property PACKAGE_PIN B16 [get_ports pc_rx]
set_property IOSTANDARD LVCMOS18 [get_ports pc_rx]