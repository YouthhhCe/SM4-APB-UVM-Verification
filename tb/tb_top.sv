////////////////////////////////////////////////////////////////////////////////
// Testbench   : tb_top
// Description : Top-level UVM testbench for sm4_wrapper.
//               - Generates 100 MHz clock and async reset
//               - Instantiates APB and Streaming interfaces
//               - Instantiates sm4_wrapper (DUT)
//               - Configures uvm_config_db and launches run_test()
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import sm4_pkg::*;

module tb_top;

    //===========================================================
    // Clock & Reset
    //===========================================================
    reg clk;
    reg rst_n;

    // 100 MHz clock  (period = 10 ns)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Asynchronous active-low reset de-assertion after ~200 ns
    initial begin
        rst_n = 1'b0;
        repeat (30) @(posedge clk);
        rst_n = 1'b1;
    end

    //===========================================================
    // Interface Instantiation
    //===========================================================

    // APB  —  pclk / presetn driven by tb_top clock & reset
    apb_if #() apb_if_inst (
        .pclk   (clk),
        .presetn(rst_n)
    );

    // Streaming input  (testbench → DUT)
    stream_if #(.DATA_WIDTH(128)) stream_in_if (
        .clk  (clk),
        .rst_n(rst_n)
    );

    // Streaming output (DUT → testbench)
    stream_if #(.DATA_WIDTH(128)) stream_out_if (
        .clk  (clk),
        .rst_n(rst_n)
    );

    //===========================================================
    // DUT  —  sm4_wrapper
    //===========================================================
    sm4_wrapper u_dut (
        .clk            (clk),
        .rst_n          (rst_n),

        // APB
        .psel           (apb_if_inst.psel),
        .penable        (apb_if_inst.penable),
        .pwrite         (apb_if_inst.pwrite),
        .paddr          (apb_if_inst.paddr),
        .pwdata         (apb_if_inst.pwdata),
        .prdata         (apb_if_inst.prdata),
        .pready         (apb_if_inst.pready),
        .pslverr        (apb_if_inst.pslverr),

        // Data input stream
        .data_in_valid  (stream_in_if.valid),
        .data_in_ready  (stream_in_if.ready),
        .data_in        (stream_in_if.data),

        // Data output stream
        .data_out_valid (stream_out_if.valid),
        .data_out_ready (stream_out_if.ready),
        .data_out       (stream_out_if.data)
    );

    //===========================================================
    // Tie stream_out_if.ready HIGH — the testbench is always
    // ready to accept DUT output (passive monitoring only).
    //===========================================================
    assign stream_out_if.ready = 1'b1;

    //===========================================================
    // UVM Configuration Database  —  set virtual interfaces
    //===========================================================
    initial begin
        uvm_config_db #(virtual apb_if)::set(
            null, "*", "vif_apb", apb_if_inst);
        uvm_config_db #(virtual stream_if)::set(
            null, "*", "vif_stream_in", stream_in_if);
        uvm_config_db #(virtual stream_if)::set(
            null, "*", "vif_stream_out", stream_out_if);

        // Launch the UVM test
        run_test();
    end

    //===========================================================
    // Waveform Dump  —  FSDB for Verdi / DVE
    //===========================================================
    initial begin
        $fsdbDumpfile("sm4_tb.fsdb");
        $fsdbDumpvars(0, tb_top);
    end

endmodule : tb_top
