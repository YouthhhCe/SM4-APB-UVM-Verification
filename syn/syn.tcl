################################################################################
# syn.tcl  —  Design Compiler Synthesis Script for SM4 Wrapper
#             Target Library: lsi_10k   |   Clock: 100 MHz
################################################################################

suppress_message {LINT-1}
suppress_message {UID-401}

# ---- Read RTL (bottom-up) -----------------------------------------------------
set RTL ../rtl
foreach f [list sbox_replace.v transform_for_encdec.v transform_for_key_exp.v \
                one_round_for_encdec.v one_round_for_key_exp.v get_cki.v \
                key_expansion.v sm4_encdec.v sm4_top.v sm4_wrapper.v] {
    read_file -format verilog ${RTL}/${f}
}

# ---- Elaborate & link ---------------------------------------------------------
current_design sm4_wrapper
link

# ---- Source constraints -------------------------------------------------------
source sm4.sdc

# ---- Compile ------------------------------------------------------------------
compile -map_effort medium

# ---- Generate reports ---------------------------------------------------------
file mkdir rpt

redirect -file rpt/timing.rpt  { report_timing -path full -delay max -max_paths 10 -nosplit }
redirect -file rpt/area.rpt    { report_area -hierarchy }
redirect -file rpt/power.rpt   { report_power -hierarchy }
redirect -file rpt/resource.rpt { report_resources }

# ---- Write netlist ------------------------------------------------------------
write -format verilog -hierarchy -output rpt/sm4_wrapper_syn.v
write_sdc rpt/sm4_wrapper_syn.sdc

echo "============================================"
echo " Synthesis Complete  —  Reports in syn/rpt/"
echo "============================================"
exit
