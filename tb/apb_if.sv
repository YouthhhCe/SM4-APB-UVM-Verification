////////////////////////////////////////////////////////////////////////////////
// Interface   : apb_if
// Description : Standard 32-bit APB3 interface with clocking block and modports
//               for UVM-based verification of sm4_wrapper.
////////////////////////////////////////////////////////////////////////////////

interface apb_if (
    input logic pclk,
    input logic presetn
);
    //===========================================================
    // APB Signals
    //===========================================================
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [7:0]  paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
    logic        pslverr;

    //===========================================================
    // Clocking Block  —  Driver (Master) synchronous to pclk
    //
    // Output skew (#1step) models a small clk-to-q delay for the
    // driver.  Input skew is default (sample before edge).
    //===========================================================
    clocking drv_cb @(posedge pclk);
        default input #1step output #1step;
        output psel;
        output penable;
        output pwrite;
        output paddr;
        output pwdata;
        input  prdata;
        input  pready;
        input  pslverr;
    endclocking : drv_cb

    //===========================================================
    // Clocking Block  —  Monitor (passive, observe DUT side)
    //===========================================================
    clocking mon_cb @(posedge pclk);
        default input #1step;
        input psel;
        input penable;
        input pwrite;
        input paddr;
        input pwdata;
        input prdata;
        input pready;
        input pslverr;
    endclocking : mon_cb

    //===========================================================
    // Modports
    //===========================================================

    // MASTER  — used by UVM driver (agent active side)
    modport master (
        input  pclk, presetn,
        output psel, penable, pwrite, paddr, pwdata,
        input  prdata, pready, pslverr
    );

    // SLAVE   — used by DUT (sm4_wrapper)
    modport slave (
        input  pclk, presetn,
        input  psel, penable, pwrite, paddr, pwdata,
        output prdata, pready, pslverr
    );

    // MONITOR — used by UVM monitor (passive observation)
    modport monitor (
        input  pclk, presetn,
        input  psel, penable, pwrite, paddr, pwdata,
        input  prdata, pready, pslverr
    );

endinterface : apb_if
