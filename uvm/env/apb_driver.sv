////////////////////////////////////////////////////////////////////////////////
// Component   : apb_driver
// Description : UVM driver for the APB master interface.
//               Drives APB read / write transfers via the clocking block.
////////////////////////////////////////////////////////////////////////////////

class apb_driver extends uvm_driver #(apb_item);

    `uvm_component_utils(apb_driver)

    //---- Virtual interface ---------------------------------------------------
    virtual apb_if vif;

    //---- Constructor ---------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif_apb", vif))
            `uvm_fatal("APB_DRV", "Virtual APB interface not found in config_db")
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("APB_DRV", $sformatf("Driving: %s", req.convert2string()), UVM_HIGH)
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    //---- APB transfer protocol -----------------------------------------------
    task drive_transfer(apb_item item);
        // ---- Setup phase ----
        @(vif.drv_cb);
        vif.drv_cb.psel    <= 1'b1;
        vif.drv_cb.penable <= 1'b0;
        vif.drv_cb.pwrite  <= item.pwrite;
        vif.drv_cb.paddr   <= item.paddr;
        vif.drv_cb.pwdata  <= item.pwdata;

        // ---- Access phase ----
        @(vif.drv_cb);
        vif.drv_cb.penable <= 1'b1;

        @(vif.drv_cb);
        if (!item.pwrite)
            item.prdata = vif.drv_cb.prdata;

        // ---- Idle ----
        vif.drv_cb.psel    <= 1'b0;
        vif.drv_cb.penable <= 1'b0;
        vif.drv_cb.pwrite  <= 1'b0;
    endtask

endclass : apb_driver
