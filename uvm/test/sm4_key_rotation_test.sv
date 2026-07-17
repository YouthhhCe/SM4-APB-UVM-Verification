////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_key_rotation_test
// Description: Advanced control-flow test that hits the ENCRYPTION→IDLE
//              FSM transition in sm4_encdec by explicitly disabling and
//              re-enabling encdec_enable mid-session.
//
//   Coverage targets:
//     - sm4_encdec FSM: ENCRYPTION→IDLE (encdec_enable→0 while active)
//     - key_expansion:   second KEY_TRIG after first data processed
////////////////////////////////////////////////////////////////////////////////

class sm4_key_rotation_test extends sm4_base_test;

    `uvm_component_utils(sm4_key_rotation_test)

    function new(string name = "sm4_key_rotation_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sm4_apb_base_seq      apb_seq;
        sm4_stream_base_seq   stream_seq;

        super.run_phase(phase);
        phase.raise_objection(this);
        #2000ns;  // wait for reset

        //=================================================================
        // Phase 0 — WAITING_FOR_KEY → IDLE  transition
        //           Enable SM4 + encdec (enter WAITING_FOR_KEY),
        //           but WITHOUT triggering key expansion, then
        //           immediately disable it to force the return arc.
        //=================================================================
        `uvm_info("KEYROT", "===== Phase 0: WAITING_FOR_KEY → IDLE =====", UVM_NONE)

        // Step A: enable SM4 + encdec → FSM moves IDLE → WAITING_FOR_KEY
        apb_seq = sm4_apb_base_seq::type_id::create("apb_enter_wfk");
        apb_seq.csr_write_mode = 1;
        apb_seq.csr_sm4_en     = 1'b1;
        apb_seq.csr_encdec_en  = 1'b1;           // both enables ON
        apb_seq.csr_encdec_sel = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);   // FSM now in WAITING_FOR_KEY

        // Step B: disable all → FSM moves WAITING_FOR_KEY → IDLE
        apb_seq = sm4_apb_base_seq::type_id::create("apb_leave_wfk");
        apb_seq.csr_write_mode = 1;
        apb_seq.csr_sm4_en     = 1'b0;
        apb_seq.csr_encdec_en  = 1'b0;
        apb_seq.csr_encdec_sel = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);   // FSM back to IDLE
        #5us;

        //=================================================================
        // Phase 1 — First key: encrypt 5 blocks
        //=================================================================
        `uvm_info("KEYROT", "===== Phase 1: Key A, encrypt 5 blocks =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_seq");
        apb_seq.key    = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
        apb_seq.encdec = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);

        stream_seq = sm4_stream_base_seq::type_id::create("stream_seq");
        stream_seq.block_count = 5;
        stream_seq.rand_delay  = 1'b0;
        stream_seq.start(env.stream_in_agent.sqr);
        #50us;

        //=================================================================
        // Phase 2 — DISABLE sm4_enable (CTRL bit0=0) mid-flight
        //           This hits the MISSING_ELSE arc in both:
        //           - sm4_encdec FSM: sm4_enable_in=0 → current holds
        //           - sm4_wrapper FSM: data_out_valid=0 makes DONE→DONE (ready tied high, but valid pulses)
        //
        //           Also disables encdec_enable, covering ENCRYPTION→IDLE
        //=================================================================
        `uvm_info("KEYROT", "===== Phase 2: Disable sm4_en + encdec_en (FSM arcs) =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_disable");
        apb_seq.csr_write_mode = 1;
        apb_seq.csr_sm4_en     = 1'b0;
        apb_seq.csr_encdec_en  = 1'b0;
        apb_seq.csr_encdec_sel = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);              // body calls write_ctrl then returns
        #5us;
        #5us;

        //=================================================================
        // Phase 3 — Second key: re-enable with NEW key material
        //=================================================================
        `uvm_info("KEYROT", "===== Phase 3: Key B, encrypt 5 blocks =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_seq2");
        apb_seq.key    = 128'hFEDCBA98_76543210_01234567_89ABCDEF;
        apb_seq.encdec = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);

        stream_seq = sm4_stream_base_seq::type_id::create("stream_seq2");
        stream_seq.block_count = 5;
        stream_seq.rand_delay  = 1'b0;
        stream_seq.start(env.stream_in_agent.sqr);
        #50us;

        //=================================================================
        // Phase 4 — Third key: decrypt mode with re-configuration
        //=================================================================
        `uvm_info("KEYROT", "===== Phase 4: Key C, decrypt 3 blocks =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_seq3");
        apb_seq.key    = 128'hAABBCCDD_EEFF0011_22334455_66778899;
        apb_seq.encdec = 1'b1;                              // decrypt
        apb_seq.start(env.apb_agent_inst.sqr);

        stream_seq = sm4_stream_base_seq::type_id::create("stream_seq3");
        stream_seq.block_count = 3;
        stream_seq.rand_delay  = 1'b0;
        stream_seq.start(env.stream_in_agent.sqr);
        #50us;

        phase.drop_objection(this);
        `uvm_info("KEYROT", "===== Key Rotation Test Complete =====", UVM_NONE)
    endtask

endclass : sm4_key_rotation_test
