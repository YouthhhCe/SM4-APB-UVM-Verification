////////////////////////////////////////////////////////////////////////////////
// Interface   : stream_if
// Description : Parameterized Valid/Ready streaming interface with
//               clocking blocks and modports for UVM verification.
//
// Usage:
//   - UVM driver  drives valid/data directly on the interface (non-blocking)
//                 and samples ready via drv_cb.ready.
//   - UVM monitor samples all signals via mon_cb.
//
//   Clocking blocks are input-only to avoid multiple-driver conflicts
//   when the same interface is used on both the producer (DUT input) and
//   consumer (DUT output) sides.
////////////////////////////////////////////////////////////////////////////////

interface stream_if #(
    parameter int DATA_WIDTH = 128
) (
    input logic clk,
    input logic rst_n
);
    //===========================================================
    // Streaming Signals
    //===========================================================
    logic                 valid;
    logic                 ready;
    logic [DATA_WIDTH-1:0] data;

    //===========================================================
    // Driver Clocking Block
    //
    // All signals are inputs — the UVM driver assigns valid/data
    // directly on the interface signals (e.g. vif.valid <= 1'b1).
    // The #1step input skew provides safe synchronous sampling
    // of ready and of the driver's own output values.
    //===========================================================
    clocking drv_cb @(posedge clk);
        default input #1step;
        input valid;
        input data;
        input ready;
    endclocking : drv_cb

    //===========================================================
    // Monitor Clocking Block  —  passive observation only
    //===========================================================
    clocking mon_cb @(posedge clk);
        default input #1step;
        input valid;
        input ready;
        input data;
    endclocking : mon_cb

    //===========================================================
    // Modports
    //===========================================================

    // MASTER  — used by UVM agent driving data into the DUT
    modport master (
        input  clk, rst_n,
        output valid, data,
        input  ready
    );

    // SLAVE   — used by consumer (DUT input port receives valid/data)
    modport slave (
        input  clk, rst_n,
        input  valid, data,
        output ready
    );

    // MONITOR — passive observation
    modport monitor (
        input  clk, rst_n,
        input  valid, ready, data
    );

endinterface : stream_if
