////////////////////////////////////////////////////////////////////////////////
// Module     : sm4_wrapper
// Description: Standard IP wrapper for sm4_top core
//   - 32-bit APB Slave for register configuration
//   - 128-bit Valid/Ready streaming data input / output
// Author     : Generated for SM4 UVM verification project
////////////////////////////////////////////////////////////////////////////////

module sm4_wrapper (
    //===========================================================
    // Clock and Reset
    //===========================================================
    input  wire        clk,
    input  wire        rst_n,

    //===========================================================
    // APB Slave Interface (32-bit)
    //===========================================================
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,
    output reg         pslverr,

    //===========================================================
    // Data Input  — Valid/Ready Streaming (128-bit)
    //===========================================================
    input  wire        data_in_valid,
    output wire        data_in_ready,
    input  wire [127:0] data_in,

    //===========================================================
    // Data Output — Valid/Ready Streaming (128-bit)
    //===========================================================
    output wire        data_out_valid,
    input  wire        data_out_ready,
    output wire [127:0] data_out
);

    //===========================================================
    // Local Parameters
    //===========================================================
    localparam IDLE = 2'b00;
    localparam PROC = 2'b01;
    localparam DONE = 2'b10;

    //===========================================================
    // APB Internal Signals
    //===========================================================
    wire        apb_write;       // APB write strobe
    wire        apb_read;        // APB read  strobe
    wire        addr_valid;      // address decode for valid registers

    //===========================================================
    // Register File
    //===========================================================
    reg  [31:0] ctrl_reg;        // 0x00: CTRL
    reg  [31:0] key_reg0;        // 0x10: KEY_0
    reg  [31:0] key_reg1;        // 0x14: KEY_1
    reg  [31:0] key_reg2;        // 0x18: KEY_2
    reg  [31:0] key_reg3;        // 0x1C: KEY_3

    //===========================================================
    // Key-Expansion Trigger Pulse
    //===========================================================
    wire        key_trig_write;  // decoded APB write to KEY_TRIG (0x04)
    reg         key_trig_pulse;  // single-cycle pulse for enable_key_exp_in

    //===========================================================
    // Wires to sm4_top
    //===========================================================
    wire        sm4_enable;
    wire        encdec_enable;
    wire        encdec_sel;
    wire        sm4_valid_in;
    wire [127:0] sm4_data_in;
    wire [127:0] user_key;
    wire        key_exp_ready;
    wire        sm4_ready_out;
    wire [127:0] sm4_result_out;

    //===========================================================
    // Data-Path FSM
    //===========================================================
    reg  [1:0]  state, next_state;
    reg  [127:0] latched_data_in;
    reg  [127:0] latched_result;

    //===========================================================
    // APB Transfer Decode
    //===========================================================
    assign apb_write  = psel && penable &&  pwrite;
    assign apb_read   = psel && penable && !pwrite;
    assign pready     = psel && penable;          // zero-wait-state response

    // Valid address map: 0x00, 0x04, 0x08, 0x10, 0x14, 0x18, 0x1C
    assign addr_valid = (paddr == 8'h00) || (paddr == 8'h04) ||
                        (paddr == 8'h08) || (paddr == 8'h10) ||
                        (paddr == 8'h14) || (paddr == 8'h18) ||
                        (paddr == 8'h1C);

    //===========================================================
    // pslverr — asserted for accesses to unimplemented addresses
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pslverr <= 1'b0;
        else
            pslverr <= psel && penable && !addr_valid;
    end

    //===========================================================
    // APB Write (Register File)
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg  <= 32'h0000_0000;
            key_reg0  <= 32'h0000_0000;
            key_reg1  <= 32'h0000_0000;
            key_reg2  <= 32'h0000_0000;
            key_reg3  <= 32'h0000_0000;
        end else if (apb_write) begin
            case (paddr)
                8'h00: ctrl_reg  <= pwdata;
                8'h10: key_reg0  <= pwdata;
                8'h14: key_reg1  <= pwdata;
                8'h18: key_reg2  <= pwdata;
                8'h1C: key_reg3  <= pwdata;
                // 0x04 (KEY_TRIG) and 0x08 (STATUS RO) are handled separately
                default: ;
            endcase
        end
    end

    //===========================================================
    // APB Read (Register File)
    //===========================================================
    always @(*) begin
        prdata = 32'h0000_0000;
        if (apb_read) begin
            case (paddr)
                8'h00: prdata = ctrl_reg;
                8'h04: prdata = 32'h0000_0000;            // KEY_TRIG is WO
                8'h08: prdata = {31'b0, key_exp_ready};   // STATUS[0] = key_exp_ready
                8'h10: prdata = key_reg0;
                8'h14: prdata = key_reg1;
                8'h18: prdata = key_reg2;
                8'h1C: prdata = key_reg3;
                default: prdata = 32'hDEAD_DEAD;
            endcase
        end
    end

    //===========================================================
    // Key-Expansion Trigger Pulse Generation
    //
    // A write to KEY_TRIG (0x04) with pwdata[0]=1 produces a
    // single-cycle pulse on key_trig_pulse, which is routed to
    // enable_key_exp_in and user_key_valid_in of sm4_top.
    //===========================================================
    assign key_trig_write = apb_write && (paddr == 8'h04);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_trig_pulse <= 1'b0;
        else
            key_trig_pulse <= key_trig_write && pwdata[0];
    end

    //===========================================================
    // Signal mapping to sm4_top
    //===========================================================
    assign sm4_enable      = ctrl_reg[0];
    assign encdec_enable   = ctrl_reg[1];
    assign encdec_sel      = ctrl_reg[2];
    assign user_key        = {key_reg0, key_reg1, key_reg2, key_reg3};

    //===========================================================
    // Data-Path FSM: sequential block
    //===========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            latched_data_in  <= 128'b0;
            latched_result   <= 128'b0;
        end else begin
            state <= next_state;

            // Latch input data on input-handshake in IDLE
            if (state == IDLE && data_in_valid && data_in_ready)
                latched_data_in <= data_in;

            // Latch result when sm4_top asserts ready_out in PROC
            if (state == PROC && sm4_ready_out)
                latched_result <= sm4_result_out;
        end
    end


    //===========================================================
    // Data-Path FSM: combinatorial next-state logic
    //===========================================================
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                // When input-handshake completes, start processing
                if (data_in_valid && data_in_ready)
                    next_state = PROC;
            end

            PROC: begin
                // Wait until sm4_top finishes computation
                if (sm4_ready_out)
                    next_state = DONE;
            end

            DONE: begin
                // Wait until output-handshake completes
                if (data_out_valid && data_out_ready)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    //===========================================================
    // External streaming interface
    //===========================================================
    assign data_in_ready  = (state == IDLE);
    assign data_out_valid = (state == DONE);
    assign data_out       = latched_result;

    //===========================================================
    // Internal valid_in to sm4_top
    //
    // valid_in is a single-cycle pulse generated combinatorially
    // during the IDLE→PROC transition (input-handshake cycle).
    // sm4_top samples data_in together with this pulse.
    //===========================================================
    assign sm4_valid_in = (state == IDLE) && data_in_valid && data_in_ready;
    assign sm4_data_in  = data_in;

    //===========================================================
    // sm4_top Instantiation
    //===========================================================
    sm4_top u_sm4_top (
        .clk                (clk),
        .reset_n            (rst_n),
        .sm4_enable_in      (sm4_enable),
        .encdec_enable_in   (encdec_enable),
        .encdec_sel_in      (encdec_sel),
        .valid_in           (sm4_valid_in),
        .data_in            (sm4_data_in),
        .enable_key_exp_in  (key_trig_pulse),
        .user_key_valid_in  (key_trig_pulse),
        .user_key_in        (user_key),
        .key_exp_ready_out  (key_exp_ready),
        .ready_out          (sm4_ready_out),
        .result_out         (sm4_result_out)
    );

endmodule
