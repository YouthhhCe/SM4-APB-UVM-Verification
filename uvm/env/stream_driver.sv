////////////////////////////////////////////////////////////////////////////////
// Component   : stream_driver
// Description : UVM driver for the streaming output interface.
//               Drives valid/data and waits for the ready handshake.
//
//               NOTE: valid/data are driven directly on the interface signals
//               (not through a clocking block output) to avoid multi-driver
//               conflicts when the same interface type is used on the DUT
//               output side.  drv_cb is used for synchronous sampling of ready.
////////////////////////////////////////////////////////////////////////////////

class stream_driver extends uvm_driver #(stream_item);

    `uvm_component_utils(stream_driver)

    //---- Virtual interface ---------------------------------------------------
    virtual stream_if vif;

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual stream_if)::get(this, "", "vif", vif))
            `uvm_fatal("STRM_DRV", "Virtual stream interface not found in config_db")
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("STRM_DRV", $sformatf("Driving: %s", req.convert2string()), UVM_HIGH)
            drive_stream(req);
            seq_item_port.item_done();
        end
    endtask

    //---- Valid/Ready handshake protocol --------------------------------------
    task drive_stream(stream_item item);
        //---- Random idle delay (creates valid jitter) ----
        repeat (item.delay) @(vif.drv_cb);

        //---- Assert valid + data ----
        @(vif.drv_cb);
        vif.valid <= 1'b1;
        vif.data  <= item.data;

        // Wait for the consumer to assert ready
        do begin
            @(vif.drv_cb);
        end while (!vif.ready);

        // Handshake complete — de-assert
        vif.valid <= 1'b0;
        vif.data  <= '0;
    endtask

endclass : stream_driver
