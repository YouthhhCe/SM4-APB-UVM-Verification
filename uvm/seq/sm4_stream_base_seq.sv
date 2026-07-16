////////////////////////////////////////////////////////////////////////////////
// Sequence    : sm4_stream_base_seq
// Description : Streaming data sequence — sends `block_count` random
//               128-bit data blocks via the stream sequencer.
//
//   block_count  : number of blocks to send
//   rand_delay   : if 1, use randomized delay (valid jitter)
//                  if 0, delay = 0 (max throughput)
////////////////////////////////////////////////////////////////////////////////

class sm4_stream_base_seq extends uvm_sequence #(stream_item);

    `uvm_object_utils(sm4_stream_base_seq)

    //---- Configuration -------------------------------------------------------
    int  block_count  = 1;
    bit  rand_delay   = 1;

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_stream_base_seq");
        super.new(name);
    endfunction

    //---- body ----------------------------------------------------------------
    task body();
        stream_item item;
        `uvm_info("STRM_SEQ", $sformatf(
            "Sending %0d data blocks  (rand_delay=%0b)", block_count, rand_delay), UVM_LOW)

        for (int i = 0; i < block_count; i++) begin
            item = stream_item::type_id::create("item");

            if (!rand_delay) begin
                // No jitter — delay=0, but data still randomised
                void'(item.randomize() with { delay == 0; });
            end else begin
                void'(item.randomize());     // randomize both data and delay
            end

            start_item(item);
            finish_item(item);
            `uvm_info("STRM_SEQ", $sformatf(
                "[%0d/%0d] Sent: %s", i+1, block_count, item.convert2string()), UVM_HIGH)
        end

        `uvm_info("STRM_SEQ", $sformatf(
            "All %0d blocks sent", block_count), UVM_MEDIUM)
    endtask

endclass : sm4_stream_base_seq
