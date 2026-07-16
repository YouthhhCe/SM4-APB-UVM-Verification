////////////////////////////////////////////////////////////////////////////////
// Component   : apb_monitor
// Description : Passive APB bus monitor.  Samples every transfer and
//               publishes an apb_item via the analysis port.
////////////////////////////////////////////////////////////////////////////////

class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    //---- Virtual interface ---------------------------------------------------
    virtual apb_if vif;

    //---- Analysis port -------------------------------------------------------
    uvm_analysis_port #(apb_item) ap_port;

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_port = new("ap_port", this);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif_apb", vif))
            `uvm_fatal("APB_MON", "Virtual APB interface not found in config_db")
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_item item;
        forever begin
            // Wait for a valid APB transfer (psel & penable)
            @(vif.mon_cb);
            if (vif.mon_cb.psel && vif.mon_cb.penable) begin
                item = apb_item::type_id::create("item");
                item.paddr  = vif.mon_cb.paddr;
                item.pwrite = vif.mon_cb.pwrite;
                item.pwdata = vif.mon_cb.pwdata;
                item.prdata = vif.mon_cb.prdata;
                `uvm_info("APB_MON", $sformatf("Observed: %s", item.convert2string()), UVM_HIGH)
                ap_port.write(item);
            end
        end
    endtask

endclass : apb_monitor
