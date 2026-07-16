////////////////////////////////////////////////////////////////////////////////
// Transaction  : apb_item
// Description : APB bus transaction — carries address, data, and direction
//               from monitor to scoreboard, and from sequencer to driver.
////////////////////////////////////////////////////////////////////////////////

class apb_item extends uvm_sequence_item;

    //---- APB transfer fields ------------------------------------------------
    rand bit [7:0]  paddr;
    rand bit [31:0] pwdata;
    rand bit        pwrite;      // 1 = write, 0 = read
    bit [31:0]      prdata;      // read data (filled by monitor / driver)

    //---- UVM macros ----------------------------------------------------------
    `uvm_object_utils_begin(apb_item)
        `uvm_field_int(paddr,  UVM_ALL_ON)
        `uvm_field_int(pwdata, UVM_ALL_ON)
        `uvm_field_int(pwrite, UVM_ALL_ON)
        `uvm_field_int(prdata, UVM_ALL_ON)
    `uvm_object_utils_end

    //---- Constraints ---------------------------------------------------------
    // Limit paddr to the valid register range
    constraint addr_valid_c {
        paddr inside {8'h00, 8'h04, 8'h08, 8'h10, 8'h14, 8'h18, 8'h1C};
    }

    //---- Constructor ---------------------------------------------------------
    function new(string name = "apb_item");
        super.new(name);
    endfunction

    //---- Utility methods -----------------------------------------------------
    function string convert2string();
        if (pwrite)
            return $sformatf("APB_WR addr=0x%0h data=0x%0h", paddr, pwdata);
        else
            return $sformatf("APB_RD addr=0x%0h data=0x%0h", paddr, prdata);
    endfunction

endclass : apb_item
