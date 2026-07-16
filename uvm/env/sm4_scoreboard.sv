////////////////////////////////////////////////////////////////////////////////
// Component   : sm4_scoreboard
// Description : SM4 verification scoreboard.
//
//   Receives APB configuration (key / mode) and streaming data from three
//   analysis FIFOs, then:
//     1. Computes the expected SM4 result via the DPI-C reference model.
//     2. Compares expected vs. RTL actual output.
//     3. Reports PASS / FAIL with detailed diagnostics.
////////////////////////////////////////////////////////////////////////////////

class sm4_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(sm4_scoreboard)

    //=======================================================================
    // TLM Analysis FIFOs
    //=======================================================================
    uvm_tlm_analysis_fifo #(apb_item)    apb_fifo;
    uvm_tlm_analysis_fifo #(stream_item) stream_in_fifo;
    uvm_tlm_analysis_fifo #(stream_item) stream_out_fifo;

    //=======================================================================
    // Internal State
    //=======================================================================
    bit [31:0] key_words [0:3];   // KEY_0 .. KEY_3 from APB
    bit        encdec_sel;        // 0 = encrypt, 1 = decrypt
    bit        key_valid;         // set after KEY_TRIG write
    int        in_cnt, out_cnt;   // statistics

    //=======================================================================
    // Constructor
    //=======================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    //=======================================================================
    // build_phase
    //=======================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_fifo        = new("apb_fifo",        this);
        stream_in_fifo  = new("stream_in_fifo",  this);
        stream_out_fifo = new("stream_out_fifo", this);
    endfunction

    //=======================================================================
    // run_phase  —  two parallel threads
    //=======================================================================
    task run_phase(uvm_phase phase);
        fork
            process_apb();
            process_data();
        join
    endtask

    //=======================================================================
    // process_apb  —  track key and mode from APB writes
    //=======================================================================
    task process_apb();
        apb_item item;
        forever begin
            apb_fifo.get(item);
            if (item.pwrite) begin
                case (item.paddr)
                    8'h00: begin
                        // CTRL: bit2 = encdec_sel
                        encdec_sel = item.pwdata[2];
                        `uvm_info("SCB_APB",
                            $sformatf("CTRL write: encdec_sel=%0b", encdec_sel), UVM_MEDIUM)
                    end
                    8'h10: begin
                        key_words[0] = item.pwdata;
                        `uvm_info("SCB_APB",
                            $sformatf("KEY_0 = 0x%0h", item.pwdata), UVM_MEDIUM)
                    end
                    8'h14: begin
                        key_words[1] = item.pwdata;
                        `uvm_info("SCB_APB",
                            $sformatf("KEY_1 = 0x%0h", item.pwdata), UVM_MEDIUM)
                    end
                    8'h18: begin
                        key_words[2] = item.pwdata;
                        `uvm_info("SCB_APB",
                            $sformatf("KEY_2 = 0x%0h", item.pwdata), UVM_MEDIUM)
                    end
                    8'h1C: begin
                        key_words[3] = item.pwdata;
                        `uvm_info("SCB_APB",
                            $sformatf("KEY_3 = 0x%0h", item.pwdata), UVM_MEDIUM)
                    end
                    8'h04: begin
                        if (item.pwdata[0]) begin
                            key_valid = 1'b1;
                            `uvm_info("SCB_APB",
                                $sformatf("KEY_TRIG: key committed | key=0x%0h_%0h_%0h_%0h  mode=%0s",
                                    key_words[0], key_words[1], key_words[2], key_words[3],
                                    encdec_sel ? "DECRYPT" : "ENCRYPT"), UVM_MEDIUM)
                        end
                    end
                    default: ;
                endcase
            end
        end
    endtask

    //=======================================================================
    // process_data  —  consume stream_in, compute expected, compare
    //=======================================================================
    task process_data();
        stream_item in_item, out_item;
        bit [127:0]  user_key;
        bit [127:0]  expected_data;
        bit [127:0]  actual_data;
        int          mode_int;

        forever begin
            // Wait until both input and output items are available.
            // The DUT processes one block at a time; the two monitors
            // capture the data on the respective handshakes.
            stream_in_fifo.get(in_item);
            in_cnt++;
            `uvm_info("SCB_DATA",
                $sformatf("[%0d] Stream IN  = 0x%0h", in_cnt, in_item.data), UVM_MEDIUM)

            //---- Sanity check: key must have been configured ----
            if (!key_valid) begin
                `uvm_warning("SCB_DATA",
                    "stream_in received before key was configured via KEY_TRIG")
            end

            //---- Assemble the 128-bit user key ----
            user_key = {key_words[0], key_words[1], key_words[2], key_words[3]};
            mode_int = int'(encdec_sel);

            //---- Call DPI-C reference model ----
            c_sm4_compute(user_key, in_item.data, mode_int, expected_data);
            `uvm_info("SCB_DATA",
                $sformatf("[%0d] Expected   = 0x%0h  (mode=%0s)",
                    in_cnt, expected_data, encdec_sel ? "DEC" : "ENC"), UVM_MEDIUM)

            //---- Get RTL result ----
            stream_out_fifo.get(out_item);
            out_cnt++;
            actual_data = out_item.data;
            `uvm_info("SCB_DATA",
                $sformatf("[%0d] Actual RTL = 0x%0h", out_cnt, actual_data), UVM_MEDIUM)

            //---- Compare ----
            if (expected_data === actual_data) begin
                `uvm_info("SCB_PASS",
                    $sformatf("[%0d] PASS  |  in=0x%0h  out=0x%0h  key=0x%0h  mode=%0s",
                        in_cnt, in_item.data, actual_data, user_key,
                        encdec_sel ? "DEC" : "ENC"), UVM_NONE)
            end else begin
                `uvm_error("SCB_FAIL",
                    $sformatf("[%0d] FAIL  |  in=0x%0h  expected=0x%0h  actual=0x%0h  key=0x%0h  mode=%0s",
                        in_cnt, in_item.data, expected_data, actual_data, user_key,
                        encdec_sel ? "DEC" : "ENC"))
            end
        end
    endtask

    //=======================================================================
    // report_phase  —  final statistics
    //=======================================================================
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_STATS",
            $sformatf("Scoreboard summary: %0d input blocks, %0d output blocks",
                in_cnt, out_cnt), UVM_NONE)
    endfunction

endclass : sm4_scoreboard
