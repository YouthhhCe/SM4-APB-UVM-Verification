################################################################################
# sm4.sdc  —  Timing Constraints for SM4 Wrapper
#             Target: 100 MHz (10 ns period)
################################################################################

# ---- Clock Definition --------------------------------------------------------
create_clock -name clk -period 10.0 [get_ports clk]

# ---- Clock Uncertainty (jitter + skew margin) --------------------------------
set_clock_uncertainty 0.2 [get_clocks clk]

# ---- Input Delay (20% of clock period = 2.0 ns) ------------------------------
set_input_delay -clock clk -max 2.0 [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay -clock clk -min 0.5 [remove_from_collection [all_inputs] [get_ports clk]]

# ---- Output Delay (20% of clock period = 2.0 ns) -----------------------------
set_output_delay -clock clk -max 2.0 [all_outputs]
set_output_delay -clock clk -min 0.5 [all_outputs]

# ---- Reset as false path (not timing-critical) --------------------------------
set_false_path -from [get_ports rst_n]

# ---- Load & Drive -------------------------------------------------------------
set_load 0.05 [all_outputs]
set_driving_cell -lib_cell AN2 [all_inputs]
