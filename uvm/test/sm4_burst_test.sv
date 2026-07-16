////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_burst_test
// Description: Back-to-back throughput test —
//              Encrypt 50 random blocks with zero inter-block delay.
//              Tests the DUT's streaming throughput and back-pressure
//              handling under maximum load.
////////////////////////////////////////////////////////////////////////////////

class sm4_burst_test extends sm4_base_test;

    `uvm_component_utils(sm4_burst_test)

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_burst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        sm4_virtual_seq vseq;

        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "===== BURST: 50 random blocks =====", UVM_NONE)

        vseq = sm4_virtual_seq::type_id::create("vseq");
        vseq.apb_sqr      = env.apb_agent_inst.sqr;
        vseq.stream_sqr   = env.stream_in_agent.sqr;

        // Use a randomised key for variety
        void'(std::randomize(vseq.key));
        vseq.encdec       = 1'b0;          // encrypt
        vseq.block_count  = 200;
        vseq.rand_delay   = 1'b0;          // NO jitter — max throughput
        vseq.start(null);

        // Drain time: 200 blocks × ~40 cycles/block + margin
        #200us;

        phase.drop_objection(this);
        `uvm_info("TEST", "===== BURST: Complete =====", UVM_NONE)
    endtask

endclass : sm4_burst_test
