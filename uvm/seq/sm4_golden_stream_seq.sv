////////////////////////////////////////////////////////////////////////////////
// Sequence    : sm4_golden_stream_seq
// Description : Sends a single, user-specified 128-bit data block.
//               Used for golden-vector verification.
////////////////////////////////////////////////////////////////////////////////

class sm4_golden_stream_seq extends uvm_sequence #(stream_item);

    `uvm_object_utils(sm4_golden_stream_seq)

    //---- Fixed data (set by test) --------------------------------------------
    bit [127:0] fixed_data = 128'h0;

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_golden_stream_seq");
        super.new(name);
    endfunction

    //---- body ----------------------------------------------------------------
    task body();
        stream_item item;
        item = stream_item::type_id::create("item");
        item.data  = fixed_data;
        item.delay = 0;
        start_item(item);
        finish_item(item);
        `uvm_info("GSTRM", $sformatf("Golden data sent: 0x%0h", fixed_data), UVM_NONE)
    endtask

endclass : sm4_golden_stream_seq
