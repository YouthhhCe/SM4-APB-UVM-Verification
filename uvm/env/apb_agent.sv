////////////////////////////////////////////////////////////////////////////////
// Component   : apb_agent
// Description : APB agent — encapsulates sequencer, driver, and monitor.
//               Controlled by is_active (UVM_ACTIVE / UVM_PASSIVE).
////////////////////////////////////////////////////////////////////////////////

class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    //---- Sub-components ------------------------------------------------------
    apb_sequencer sqr;
    apb_driver    drv;
    apb_monitor   mon;

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = apb_monitor  ::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = apb_sequencer::type_id::create("sqr", this);
            drv = apb_driver   ::type_id::create("drv", this);
        end
    endfunction

    //---- connect_phase -------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : apb_agent
