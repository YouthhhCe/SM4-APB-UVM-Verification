////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_random_test
// Description: Full random stress test —
//              Random key, random mode, 100 random data blocks with
//              randomised valid/ready jitter (delay 0–5 cycles).
//              Tests the DUT's robustness under unpredictable timing.
////////////////////////////////////////////////////////////////////////////////

class sm4_random_test extends sm4_base_test;

    `uvm_component_utils(sm4_random_test)

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        sm4_virtual_seq vseq;

        super.run_phase(phase);
        phase.raise_objection(this);

        `uvm_info("TEST", "===== RANDOM: 100 blocks, random key + jitter =====", UVM_NONE)

        vseq = sm4_virtual_seq::type_id::create("vseq");
        vseq.apb_sqr      = env.apb_agent_inst.sqr;
        vseq.stream_sqr   = env.stream_in_agent.sqr;

        // Randomise everything
        void'(std::randomize(vseq.key));
        void'(std::randomize(vseq.encdec));
        vseq.block_count  = 1000;
        vseq.rand_delay   = 1'b1;          // ENABLE jitter (0-5 idle cycles)
        vseq.start(null);

        // Drain time: 1000 blocks × (avg 2.5 idle + ~40 compute) cycles + margin
        #1000us;

        phase.drop_objection(this);
        `uvm_info("TEST", "===== RANDOM: Complete =====", UVM_NONE)
    endtask

endclass : sm4_random_test
