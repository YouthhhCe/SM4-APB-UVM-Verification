////////////////////////////////////////////////////////////////////////////////
// Component   : stream_monitor
// Description : Passive stream monitor.  Observes the valid/ready handshake
//               and publishes a stream_item via the analysis port.
//               Works on both input (producer) and output (consumer) sides.
////////////////////////////////////////////////////////////////////////////////

class stream_monitor extends uvm_monitor;

    `uvm_component_utils(stream_monitor)

    //---- Virtual interface ---------------------------------------------------
    virtual stream_if vif;

    //---- Analysis port -------------------------------------------------------
    uvm_analysis_port #(stream_item) ap_port;

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_port = new("ap_port", this);
        if (!uvm_config_db #(virtual stream_if)::get(this, "", "vif", vif))
            `uvm_fatal("STRM_MON", "Virtual stream interface not found in config_db")
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        stream_item item;
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.valid && vif.mon_cb.ready) begin
                item = stream_item::type_id::create("item");
                item.data = vif.mon_cb.data;
                `uvm_info("STRM_MON", $sformatf("Observed: %s", item.convert2string()), UVM_HIGH)
                ap_port.write(item);
            end
        end
    endtask

endclass : stream_monitor
