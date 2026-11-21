vlib work
vlog -sv apb_slave.sv
vlog -sv tb_apb_slave.sv
vsim TB
add wave -r sim:/TB/*
run -all
