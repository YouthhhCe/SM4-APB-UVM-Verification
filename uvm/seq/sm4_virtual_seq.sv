////////////////////////////////////////////////////////////////////////////////
// Sequence    : sm4_virtual_seq
// Description : Top-level virtual sequence — orchestrates:
//                 1. APB configuration  (key, mode) via sm4_apb_base_seq
//                 2. Stream data         via sm4_stream_base_seq
//
//   Runs on the null sequencer; sub-sequencer handles are set by the test.
////////////////////////////////////////////////////////////////////////////////

class sm4_virtual_seq extends uvm_sequence;

    `uvm_object_utils(sm4_virtual_seq)

    //---- Sub-sequencer handles (set by test) ---------------------------------
    uvm_sequencer #(apb_item)    apb_sqr;
    uvm_sequencer #(stream_item) stream_sqr;

    //---- Configuration -------------------------------------------------------
    bit [127:0] key          = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
    bit         encdec       = 1'b0;       // 0=encrypt, 1=decrypt
    int         block_count  = 1;
    bit         rand_delay   = 1;

    //---- Sub-sequences -------------------------------------------------------
    sm4_apb_base_seq    apb_seq;
    sm4_stream_base_seq stream_seq;

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_virtual_seq");
        super.new(name);
    endfunction

    //---- body ----------------------------------------------------------------
    task body();
        // Wait for reset de-assertion (tb_top releases rst_n after ~300 ns)
        #2000ns;

        `uvm_info("VSEQ", $sformatf(
            "=== SM4 Virtual Sequence Start ===\n    key      = 0x%0h\n    mode     = %0s\n    blocks   = %0d\n    rand_dly = %0b",
            key, encdec ? "DECRYPT" : "ENCRYPT", block_count, rand_delay), UVM_NONE)

        //-----------------------------------------------------------------
        // Phase 1 — Configure APB (key + mode)
        //-----------------------------------------------------------------
        if (apb_sqr == null)
            `uvm_fatal("VSEQ", "apb_sqr handle is null — was it set by the test?")
        `uvm_info("VSEQ", "--- Phase 1: APB Configuration ---", UVM_MEDIUM)
        apb_seq = sm4_apb_base_seq::type_id::create("apb_seq");
        apb_seq.key    = key;
        apb_seq.encdec = encdec;
        apb_seq.start(apb_sqr);

        //-----------------------------------------------------------------
        // Phase 2 — Send stream data
        //-----------------------------------------------------------------
        if (stream_sqr == null)
            `uvm_fatal("VSEQ", "stream_sqr handle is null — was it set by the test?")
        `uvm_info("VSEQ", "--- Phase 2: Stream Data ---", UVM_MEDIUM)
        stream_seq = sm4_stream_base_seq::type_id::create("stream_seq");
        stream_seq.block_count = block_count;
        stream_seq.rand_delay  = rand_delay;
        stream_seq.start(stream_sqr);

        `uvm_info("VSEQ", "=== SM4 Virtual Sequence Complete ===", UVM_NONE)
    endtask

endclass : sm4_virtual_seq
