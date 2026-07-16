////////////////////////////////////////////////////////////////////////////////
// Component   : sm4_env
// Description : Top-level UVM environment for SM4 verification.
//
//   Instantiates:
//     - apb_agent        (active)   — drives APB register accesses
//     - stream_in_agent  (active)   — drives input data into DUT
//     - stream_out_agent (passive)  — monitors DUT output data
//     - sm4_scoreboard              — DPI-C reference model + comparison
//     - sm4_coverage                — functional coverage collection
//
//   TLM connections route all monitors to the scoreboard's analysis FIFOs
//   and to the coverage collector.
////////////////////////////////////////////////////////////////////////////////

class sm4_env extends uvm_env;

    `uvm_component_utils(sm4_env)

    //=======================================================================
    // Sub-components
    //=======================================================================
    apb_agent        apb_agent_inst;
    stream_agent     stream_in_agent;
    stream_agent     stream_out_agent;
    sm4_scoreboard   scoreboard;
    sm4_coverage     cov;

    //=======================================================================
    // Constructor
    //=======================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //=======================================================================
    // build_phase  —  create agents and scoreboard
    //=======================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // APB agent  (active — drives register reads/writes)
        apb_agent_inst = apb_agent::type_id::create("apb_agent_inst", this);
        uvm_config_db #(int)::set(this, "apb_agent_inst", "is_active", UVM_ACTIVE);

        // Stream-in agent  (active — sends input blocks to DUT)
        stream_in_agent = stream_agent::type_id::create("stream_in_agent", this);
        uvm_config_db #(int)::set(this, "stream_in_agent", "is_active", UVM_ACTIVE);

        // Stream-out agent  (passive — monitors DUT result)
        stream_out_agent = stream_agent::type_id::create("stream_out_agent", this);
        uvm_config_db #(int)::set(this, "stream_out_agent", "is_active", UVM_PASSIVE);

        // Scoreboard
        scoreboard = sm4_scoreboard::type_id::create("scoreboard", this);

        // Functional coverage
        cov = sm4_coverage::type_id::create("cov", this);

        //---- Re-distribute virtual interfaces to agents ----
        redistribute_vifs();
    endfunction

    //=======================================================================
    // redistribute_vifs  —  route top-level interfaces to agent instances
    //
    //   tb_top sets:  "vif_apb", "vif_stream_in", "vif_stream_out"  (global)
    //   Agents need:  "vif_apb" (apb),  "vif" (stream)
    //
    //   Each agent's children look up the interface under their own
    //   hierarchical path, so we set with the agent instance as context.
    //=======================================================================
    function void redistribute_vifs();
        virtual apb_if    va;
        virtual stream_if vs_in, vs_out;

        // APB
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif_apb", va))
            `uvm_fatal("ENV", "vif_apb not in config_db")
        uvm_config_db #(virtual apb_if)::set(this, "apb_agent_inst.*", "vif_apb", va);

        // Stream in
        if (!uvm_config_db #(virtual stream_if)::get(this, "", "vif_stream_in", vs_in))
            `uvm_fatal("ENV", "vif_stream_in not in config_db")
        uvm_config_db #(virtual stream_if)::set(this, "stream_in_agent.*", "vif", vs_in);

        // Stream out
        if (!uvm_config_db #(virtual stream_if)::get(this, "", "vif_stream_out", vs_out))
            `uvm_fatal("ENV", "vif_stream_out not in config_db")
        uvm_config_db #(virtual stream_if)::set(this, "stream_out_agent.*", "vif", vs_out);

        // Coverage  —  needs stream VIF for backpressure / burst sampling
        uvm_config_db #(virtual stream_if)::set(this, "cov", "vif_stream_in", vs_in);
    endfunction

    //=======================================================================
    // connect_phase  —  wire TLM ports to scoreboard FIFOs
    //=======================================================================
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        apb_agent_inst.mon.ap_port.connect(
            scoreboard.apb_fifo.analysis_export);

        stream_in_agent.mon.ap_port.connect(
            scoreboard.stream_in_fifo.analysis_export);

        stream_out_agent.mon.ap_port.connect(
            scoreboard.stream_out_fifo.analysis_export);

        // Coverage  —  APB writes feed mode coverage
        apb_agent_inst.mon.ap_port.connect(
            cov.apb_imp);
    endfunction

endclass : sm4_env
