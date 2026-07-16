////////////////////////////////////////////////////////////////////////////////
// Component   : sm4_coverage
// Description : Functional coverage collector for SM4 verification.
//
//   Coverage dimensions:
//     1. Mode Coverage      — encrypt (0) vs decrypt (1) from APB CTRL writes
//     2. Backpressure Cov.  — valid=1 & ready=0 on stream input interface
//     3. Burst Coverage     — length of consecutive (back-to-back) transfers
////////////////////////////////////////////////////////////////////////////////

class sm4_coverage extends uvm_component;

    `uvm_component_utils(sm4_coverage)

    //=======================================================================
    // Analysis Imp  —  receives APB transactions
    //=======================================================================
    uvm_analysis_imp #(apb_item, sm4_coverage) apb_imp;

    //=======================================================================
    // Virtual Interface  —  for cycle-level stream observation
    //=======================================================================
    virtual stream_if stream_vif;

    //=======================================================================
    // Coverage state
    //=======================================================================
    bit        encdec_sel;       // last observed mode
    bit        bp_seen;          // backpressure observed flag
    int        burst_len;        // current burst counter

    //=======================================================================
    // Covergroup 1 — Mode (encrypt / decrypt)
    //=======================================================================
    covergroup mode_cg;
        option.per_instance = 1;
        option.name = "mode_cg";

        encdec_sel_cp: coverpoint encdec_sel {
            bins encrypt = {0};
            bins decrypt = {1};
        }
    endgroup : mode_cg

    //=======================================================================
    // Covergroup 2 — Backpressure
    //=======================================================================
    covergroup backpressure_cg;
        option.per_instance = 1;
        option.name = "backpressure_cg";

        bp_seen_cp: coverpoint bp_seen {
            bins seen = {1};
        }
    endgroup : backpressure_cg

    //=======================================================================
    // Covergroup 3 — Burst Length
    //=======================================================================
    covergroup burst_cg;
        option.per_instance = 1;
        option.name = "burst_cg";

        burst_len_cp: coverpoint burst_len {
            bins single       = {1};
            bins burst_2_4    = {[2:4]};
            bins burst_5_10   = {[5:10]};
            bins burst_11_plus = {[11:50]};
        }
    endgroup : burst_cg

    //=======================================================================
    // Constructor
    //=======================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
        apb_imp      = new("apb_imp", this);
        mode_cg      = new();
        backpressure_cg = new();
        burst_cg     = new();
    endfunction

    //=======================================================================
    // build_phase  —  grab the stream virtual interface
    //=======================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual stream_if)::get(this, "", "vif_stream_in", stream_vif))
            `uvm_warning("COV", "stream_vif not found in config_db — backpressure / burst coverage disabled")
    endfunction

    //=======================================================================
    // write  —  APB analysis imp callback
    //=======================================================================
    function void write(apb_item item);
        // Only track writes to CTRL (0x00)
        if (item.pwrite && item.paddr == 8'h00) begin
            encdec_sel = item.pwdata[2];
            mode_cg.sample();
            `uvm_info("COV", $sformatf("Mode sampled: encdec_sel=%0b", encdec_sel), UVM_HIGH)
        end
    endfunction

    //=======================================================================
    // run_phase  —  cycle-level stream observation
    //=======================================================================
    task run_phase(uvm_phase phase);
        if (stream_vif == null) begin
            `uvm_info("COV", "No stream VIF — skipping stream coverage sampling", UVM_MEDIUM)
            return;
        end

        `uvm_info("COV", "Starting stream coverage sampling ...", UVM_MEDIUM)
        burst_len = 0;
        forever begin
            @(stream_vif.mon_cb);

            //---- Backpressure detection ----
            if (stream_vif.mon_cb.valid && !stream_vif.mon_cb.ready) begin
                if (!bp_seen) begin
                    bp_seen = 1'b1;
                    backpressure_cg.sample();
                    `uvm_info("COV", "Backpressure SEEN (valid=1, ready=0)", UVM_MEDIUM)
                end
            end

            //---- Burst-length detection ----
            if (stream_vif.mon_cb.valid && stream_vif.mon_cb.ready) begin
                burst_len++;
            end else begin
                if (burst_len > 0) begin
                    `uvm_info("COV", $sformatf("Burst ended: length=%0d", burst_len), UVM_HIGH)
                    burst_cg.sample();
                    burst_len = 0;
                end
            end
        end
    endtask

    //=======================================================================
    // report_phase  —  print coverage summary
    //=======================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("\n");
        $display("  ============================================");
        $display("  SM4 Functional Coverage Summary");
        $display("  ============================================");
        $display("  Mode coverage         : %0.0f %%", mode_cg.get_inst_coverage());
        $display("  Backpressure coverage : %0.0f %%", backpressure_cg.get_inst_coverage());
        $display("  Burst coverage        : %0.0f %%", burst_cg.get_inst_coverage());
        $display("  ============================================");
        $display("\n");
    endfunction

endclass : sm4_coverage
