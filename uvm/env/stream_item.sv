////////////////////////////////////////////////////////////////////////////////
// Transaction  : stream_item
// Description : 128-bit streaming data transaction — used for both input
//               (plaintext/ciphertext) and output (result) sides.
//
//   delay  —  number of idle cycles before asserting valid.
//             Randomized to create jitter in the valid/ready handshake
//             and stress-test the DUT's back-pressure handling.
////////////////////////////////////////////////////////////////////////////////

class stream_item extends uvm_sequence_item;

    //---- Stream data ---------------------------------------------------------
    rand bit [127:0] data;

    //---- Timing jitter -------------------------------------------------------
    rand int delay;

    //---- Constraints ---------------------------------------------------------
    constraint delay_default_c {
        delay inside {[0:5]};    // 0 = immediate, 1-5 = idle cycles before valid
    }

    //---- UVM macros ----------------------------------------------------------
    `uvm_object_utils_begin(stream_item)
        `uvm_field_int(data,  UVM_ALL_ON)
        `uvm_field_int(delay, UVM_ALL_ON)
    `uvm_object_utils_end

    //---- Constructor ---------------------------------------------------------
    function new(string name = "stream_item");
        super.new(name);
    endfunction

    //---- Utility methods -----------------------------------------------------
    function string convert2string();
        return $sformatf("STREAM data=0x%0h  delay=%0d", data, delay);
    endfunction

endclass : stream_item
