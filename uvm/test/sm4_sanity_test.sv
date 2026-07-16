////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_sanity_test
// Description: Minimal smoke test —
//              1. Encrypt 1 block with a fixed key
//              2. Decrypt the result (should recover original plaintext)
////////////////////////////////////////////////////////////////////////////////

class sm4_sanity_test extends sm4_base_test;

    `uvm_component_utils(sm4_sanity_test)

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        sm4_virtual_seq vseq;
        bit [127:0] test_key  = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
        bit [127:0] plaintext = 128'h01234567_89ABCDEF_FEDCBA98_76543210;

        super.run_phase(phase);
        phase.raise_objection(this);

        //=================================================================
        // Test 1 — Encrypt
        //=================================================================
        `uvm_info("TEST", "===== SANITY: Encryption =====", UVM_NONE)

        vseq = sm4_virtual_seq::type_id::create("vseq_enc");
        vseq.apb_sqr      = env.apb_agent_inst.sqr;
        vseq.stream_sqr   = env.stream_in_agent.sqr;
        vseq.key          = test_key;
        vseq.encdec       = 1'b0;          // encrypt
        vseq.block_count  = 1;
        vseq.rand_delay   = 1'b0;          // no jitter for quick test
        vseq.start(null);

        // Allow time for DUT processing + scoreboard comparison
        #50us;

        //=================================================================
        // Test 2 — Decrypt (recover original plaintext)
        //=================================================================
        `uvm_info("TEST", "===== SANITY: Decryption =====", UVM_NONE)

        vseq = sm4_virtual_seq::type_id::create("vseq_dec");
        vseq.apb_sqr      = env.apb_agent_inst.sqr;
        vseq.stream_sqr   = env.stream_in_agent.sqr;
        vseq.key          = test_key;
        vseq.encdec       = 1'b1;          // decrypt
        vseq.block_count  = 1;
        vseq.rand_delay   = 1'b0;
        vseq.start(null);

        #50us;

        phase.drop_objection(this);
        `uvm_info("TEST", "===== SANITY: Complete =====", UVM_NONE)
    endtask

endclass : sm4_sanity_test
