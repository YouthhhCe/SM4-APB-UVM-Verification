////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_hard_reset_test
// Description: Mid-flight hardware reset test.
//
//   sm4_encdec FSM (line ~185):
//     always@(posedge clk or negedge reset_n)
//       if(!reset_n)       current <= IDLE;
//       else if(sm4_en)    current <= next;   // FREEZES when sm4_en=0 !
//
//   APB write to disable sm4_en only FREEZES the FSM — it does NOT
//   transition back to IDLE.  The ONLY physical path back to IDLE
//   from WAITING_FOR_KEY or ENCRYPTION is a hardware reset_n pulse.
//
//   This test:
//     A. Enables SM4 so the FSM enters WAITING_FOR_KEY
//     B. Force-asserts reset_n while FSM is in WAITING_FOR_KEY
//     C. Releases reset → FSM returns to IDLE
//     D. Re-configures and runs a few blocks to verify recovery
////////////////////////////////////////////////////////////////////////////////

class sm4_hard_reset_test extends sm4_base_test;

    `uvm_component_utils(sm4_hard_reset_test)

    function new(string name = "sm4_hard_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sm4_apb_base_seq      apb_seq;
        sm4_stream_base_seq   stream_seq;

        super.run_phase(phase);
        phase.raise_objection(this);
        #2000ns;  // wait for initial reset to complete

        //=================================================================
        // Step A — Enable SM4 + encdec → FSM: IDLE → WAITING_FOR_KEY
        //          Do NOT trigger key expansion, so FSM stays in WF_K.
        //=================================================================
        `uvm_info("HRST", "===== Step A: Enter WAITING_FOR_KEY =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_enter");
        apb_seq.csr_write_mode = 1;
        apb_seq.csr_sm4_en     = 1'b1;
        apb_seq.csr_encdec_en  = 1'b1;
        apb_seq.csr_encdec_sel = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);
        #500ns;  // wait a few cycles — FSM is now in WAITING_FOR_KEY

        //=================================================================
        // Step B — Force hardware reset_n LOW while FSM is mid-flight
        //          This is the ONLY way to hit WAITING_FOR_KEY → IDLE
        //=================================================================
        `uvm_info("HRST", "===== Step B: Force reset_n=0 (mid-flight HW reset) =====", UVM_NONE)

        uvm_hdl_force("tb_top.rst_n", 1'b0);
        #100ns;  // hold reset low for 10 clock cycles @ 100MHz
        uvm_hdl_force("tb_top.rst_n", 1'b1);  // explicitly drive back to 1
        #500ns;  // let everything recover

        //=================================================================
        // Step C — Re-configure and verify the design still works
        //=================================================================
        `uvm_info("HRST", "===== Step C: Recovery — normal encrypt operation =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_recover");
        apb_seq.key    = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
        apb_seq.encdec = 1'b0;
        apb_seq.start(env.apb_agent_inst.sqr);

        stream_seq = sm4_stream_base_seq::type_id::create("stream_recover");
        stream_seq.block_count = 3;
        stream_seq.rand_delay  = 1'b0;
        stream_seq.start(env.stream_in_agent.sqr);
        #50us;

        //=================================================================
        // Step D — Second mid-flight reset, this time from ENCRYPTION
        //=================================================================
        `uvm_info("HRST", "===== Step D: Second reset from ENCRYPTION state =====", UVM_NONE)

        apb_seq = sm4_apb_base_seq::type_id::create("apb_enc");
        apb_seq.key    = 128'hFEDCBA98_76543210_01234567_89ABCDEF;
        apb_seq.encdec = 1'b1;                              // decrypt
        apb_seq.start(env.apb_agent_inst.sqr);

        stream_seq = sm4_stream_base_seq::type_id::create("stream_pre_reset");
        stream_seq.block_count = 2;
        stream_seq.rand_delay  = 1'b0;
        stream_seq.start(env.stream_in_agent.sqr);

        // Force reset while data is being processed (ENCRYPTION state)
        uvm_hdl_force("tb_top.rst_n", 1'b0);
        #100ns;
        uvm_hdl_force("tb_top.rst_n", 1'b1);  // explicitly drive back to 1
        #500ns;

        phase.drop_objection(this);
        `uvm_info("HRST", "===== Hard Reset Test Complete =====", UVM_NONE)
    endtask

endclass : sm4_hard_reset_test
