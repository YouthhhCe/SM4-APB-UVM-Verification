////////////////////////////////////////////////////////////////////////////////
// Component   : stream_agent
// Description : Stream agent — encapsulates sequencer, driver, and monitor.
//               is_active = UVM_ACTIVE  → driver instantiated (input side)
//               is_active = UVM_PASSIVE → monitor only (output side)
//
//               The virtual interface key is configurable (default "vif")
//               so that stream_in_agent and stream_out_agent can each
//               receive a different interface from uvm_config_db.
////////////////////////////////////////////////////////////////////////////////

class stream_agent extends uvm_agent;

    `uvm_component_utils(stream_agent)

    //---- Sub-components ------------------------------------------------------
    stream_sequencer sqr;
    stream_driver    drv;
    stream_monitor   mon;

    //---- Configuration -------------------------------------------------------
    // Override in env to set different interface keys:
    //   stream_in_agent  → "vif_stream_in"
    //   stream_out_agent → "vif_stream_out"
    string vif_key = "vif";

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = stream_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = stream_sequencer::type_id::create("sqr", this);
            drv = stream_driver   ::type_id::create("drv", this);
        end
    endfunction

    //---- connect_phase -------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : stream_agent
