transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv apb_master.sv
vlog -sv apb_slave.sv
vlog -sv tb_apb.sv

vsim -voptargs=+acc work.tb_apb

add wave -divider "Clock and Reset"
add wave sim:/tb_apb/pclk
add wave sim:/tb_apb/presetn

add wave -divider "APB Control"
add wave sim:/tb_apb/psel
add wave sim:/tb_apb/penable
add wave sim:/tb_apb/pwrite
add wave sim:/tb_apb/pready
add wave sim:/tb_apb/pslverr

add wave -divider "APB Data"
add wave -radix hexadecimal sim:/tb_apb/paddr
add wave -radix hexadecimal sim:/tb_apb/pwdata
add wave -radix hexadecimal sim:/tb_apb/prdata

add wave -divider "Slave Registers"
add wave -radix hexadecimal sim:/tb_apb/dut/*

run -all
wave zoom full