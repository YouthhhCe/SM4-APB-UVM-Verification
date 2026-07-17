////////////////////////////////////////////////////////////////////////////////
// Package     : sm4_pkg
// Description : SM4 UVM verification package.
//               Includes all UVM components in correct dependency order.
//
//   Dependency order:
//     Items  →  Sequencers  →  Drivers / Monitors  →  Agents
//     →  Scoreboard  →  Env  →  Test
////////////////////////////////////////////////////////////////////////////////

package sm4_pkg;

    //=======================================================================
    // UVM base
    //=======================================================================
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //=======================================================================
    // DPI-C  —  C reference model bridge
    //=======================================================================
    import "DPI-C" function void c_sm4_compute(
        input  bit [127:0] key,
        input  bit [127:0] data_in,
        input  int         mode,
        output bit [127:0] data_out
    );

    //=======================================================================
    // Transaction Items
    //=======================================================================
    `include "env/apb_item.sv"
    `include "env/stream_item.sv"

    //=======================================================================
    // APB Agent
    //=======================================================================
    `include "env/apb_sequencer.sv"
    `include "env/apb_driver.sv"
    `include "env/apb_monitor.sv"
    `include "env/apb_agent.sv"

    //=======================================================================
    // Stream Agent
    //=======================================================================
    `include "env/stream_sequencer.sv"
    `include "env/stream_driver.sv"
    `include "env/stream_monitor.sv"
    `include "env/stream_agent.sv"

    //=======================================================================
    // Scoreboard
    //=======================================================================
    `include "env/sm4_scoreboard.sv"

    //=======================================================================
    // Coverage
    //=======================================================================
    `include "env/sm4_coverage.sv"

    //=======================================================================
    // Environment
    //=======================================================================
    `include "env/sm4_env.sv"

    //=======================================================================
    // Sequences
    //=======================================================================
    `include "seq/sm4_apb_base_seq.sv"
    `include "seq/sm4_stream_base_seq.sv"
    `include "seq/sm4_virtual_seq.sv"
    `include "seq/sm4_golden_stream_seq.sv"

    //=======================================================================
    // Tests
    //=======================================================================
    `include "test/sm4_base_test.sv"
    `include "test/sm4_sanity_test.sv"
    `include "test/sm4_burst_test.sv"
    `include "test/sm4_random_test.sv"
    `include "test/sm4_golden_test.sv"
    `include "test/sm4_key_rotation_test.sv"
    `include "test/sm4_hard_reset_test.sv"

endpackage : sm4_pkg
