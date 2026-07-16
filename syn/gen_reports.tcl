current_design sm4_wrapper
link
source sm4.sdc

redirect -file rpt/timing.rpt  { report_timing -path full -delay max -max_paths 10 -nosplit }
redirect -file rpt/area.rpt    { report_area -hierarchy }
redirect -file rpt/power.rpt   { report_power -hierarchy }
redirect -file rpt/resource.rpt { report_resources }

write -format verilog -hierarchy -output rpt/sm4_wrapper_syn.v
write_sdc rpt/sm4_wrapper_syn.sdc

echo "Reports generated successfully."
exit
