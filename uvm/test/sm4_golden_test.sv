////////////////////////////////////////////////////////////////////////////////
// Test       : sm4_golden_test
// Description: Golden-vector debug test using the official SM4 test vector
//              from GB/T 32907-2016.
//
//   KEY        : 01234567_89ABCDEF_FEDCBA98_76543210
//   PLAINTEXT  : 01234567_89ABCDEF_FEDCBA98_76543210
//   CIPHERTEXT : 681EDF34_D206965E_86B3E94F_536E4246
//
//   Prints all three values (RTL actual, C-model expected, standard answer)
//   so the byte-ordering mismatch can be diagnosed.
////////////////////////////////////////////////////////////////////////////////

class sm4_golden_test extends sm4_base_test;

    `uvm_component_utils(sm4_golden_test)

    //---- Golden constants ----------------------------------------------------
    localparam bit [127:0] GOLDEN_KEY        = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
    localparam bit [127:0] GOLDEN_PLAINTEXT  = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
    localparam bit [127:0] GOLDEN_CIPHERTEXT = 128'h681EDF34_D206965E_86B3E94F_536E4246;

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_golden_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //---- run_phase -----------------------------------------------------------
    task run_phase(uvm_phase phase);
        sm4_apb_base_seq      apb_seq;
        sm4_golden_stream_seq stream_seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        //=================================================================
        // Print the golden standard
        //=================================================================
        `uvm_info("GOLDEN", $sformatf(
            "\n  >>> GOLDEN STANDARD <<<\n  KEY        = 0x%0h\n  PLAINTEXT  = 0x%0h\n  CIPHERTEXT = 0x%0h",
            GOLDEN_KEY, GOLDEN_PLAINTEXT, GOLDEN_CIPHERTEXT), UVM_NONE)

        //=================================================================
        // Wait for reset de-assertion (rst_n goes high after ~300ns)
        //=================================================================
        #2000ns;

        //=================================================================
        // Phase 1 — APB Configuration
        //=================================================================
        apb_seq = sm4_apb_base_seq::type_id::create("apb_seq");
        apb_seq.key    = GOLDEN_KEY;
        apb_seq.encdec = 1'b0;               // encrypt
        apb_seq.start(env.apb_agent_inst.sqr);

        //=================================================================
        // Phase 2 — Send golden plaintext
        //=================================================================
        stream_seq = sm4_golden_stream_seq::type_id::create("stream_seq");
        stream_seq.fixed_data = GOLDEN_PLAINTEXT;
        stream_seq.start(env.stream_in_agent.sqr);

        //=================================================================
        // Drain time — wait for DUT + scoreboard comparison
        //=================================================================
        #50us;

        //=================================================================
        // Diagnostic — print all three values from scoreboard
        //=================================================================
        print_diagnostics();

        phase.drop_objection(this);
        `uvm_info("GOLDEN", "===== GOLDEN TEST COMPLETE =====", UVM_NONE)
    endtask

    //=======================================================================
    // print_diagnostics  —  explicit comparison with golden standard
    //=======================================================================
    function void print_diagnostics();
        // The scoreboard has already printed SCB_DATA with Expected and
        // SCB_PASS/FAIL with both Expected and Actual.
        //
        // Expected value   = DPI-C c_sm4_compute() output
        // Actual value     = RTL stream_out data
        // Standard answer  = GOLDEN_CIPHERTEXT (from GB/T 32907-2016)
        //
        // By comparing these three, we can determine:
        //   - If Expected == Standard  → C model / DPI-C wrapper is correct
        //   - If Expected != Standard  → C model or DPI-C conversion has bug
        //   - If Actual   != Expected  → RTL byte ordering differs from C model
        `uvm_info("GOLDEN", $sformatf(
            "\n  >>> DIAGNOSIS <<<\n  Standard ciphertext (GB/T 32907-2016):\n    0x%0h\n  (Check SCB_DATA / SCB_FAIL above for Expected vs Actual values)",
            GOLDEN_CIPHERTEXT), UVM_NONE)
    endfunction

endclass : sm4_golden_test
