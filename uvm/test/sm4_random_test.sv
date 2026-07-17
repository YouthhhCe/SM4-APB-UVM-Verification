////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_random_test
// Description: Full random stress test —
//              1000 random blocks with FREQUENT key rotation (every 5 blocks)
//              and enc/dec mode toggling, to exercise:
//                - key_expansion S-Box (many different keys → 256 S-Box entries)
//                - sm4_encdec operator pipelines (both encrypt + decrypt)
//                - u_one_round / u_transform / u_0..u_3 coverage
////////////////////////////////////////////////////////////////////////////////

class sm4_random_test extends sm4_base_test;

    `uvm_component_utils(sm4_random_test)

    function new(string name = "sm4_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sm4_apb_base_seq      apb_seq;
        sm4_stream_base_seq   stream_seq;
        bit [127:0]           rand_key;
        bit                   encdec_sel;

        super.run_phase(phase);
        phase.raise_objection(this);
        #2000ns;

        // 200 batches × 5 blocks = 1000 total blocks
        // Each batch: new random key + toggled enc/dec mode
        encdec_sel = 1'b0;

        for (int batch = 0; batch < 200; batch++) begin
            // Toggle mode every batch (bimodal coverage)
            encdec_sel = ~encdec_sel;

            // Fresh random key every batch → exercises key-expansion S-Box
            void'(std::randomize(rand_key));

            `uvm_info("RND", $sformatf(
                "Batch %0d/200: key=0x%0h  mode=%0s",
                batch+1, rand_key, encdec_sel ? "DEC" : "ENC"), UVM_MEDIUM)

            // APB reconfiguration
            apb_seq = sm4_apb_base_seq::type_id::create($sformatf("apb_b%0d", batch));
            apb_seq.key    = rand_key;
            apb_seq.encdec = encdec_sel;
            apb_seq.start(env.apb_agent_inst.sqr);

            // Send 5 blocks with jitter
            stream_seq = sm4_stream_base_seq::type_id::create($sformatf("strm_b%0d", batch));
            stream_seq.block_count = 5;
            stream_seq.rand_delay  = 1'b1;
            stream_seq.start(env.stream_in_agent.sqr);
        end

        // Drain: 1000 blocks × ~40 cycles/block
        #1000us;

        phase.drop_objection(this);
        `uvm_info("RND", "===== RANDOM (1000 blocks, 200 keys, bimodal) COMPLETE =====", UVM_NONE)
    endtask

endclass : sm4_random_test
