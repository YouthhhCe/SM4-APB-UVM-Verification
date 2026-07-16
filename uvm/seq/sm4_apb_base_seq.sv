////////////////////////////////////////////////////////////////////////////////
// Sequence    : sm4_apb_base_seq
// Description : APB configuration sequence for SM4.
//               Provides the config_and_start() task that:
//                 1. Writes CTRL  (sm4_enable=1, encdec_enable=0)
//                 2. Writes KEY_0 … KEY_3
//                 3. Pulses KEY_TRIG to start key expansion
//                 4. Polls STATUS until key_exp_ready = 1
//                 5. Writes CTRL  (sm4_enable=1, encdec_enable=1)
////////////////////////////////////////////////////////////////////////////////

class sm4_apb_base_seq extends uvm_sequence #(apb_item);

    `uvm_object_utils(sm4_apb_base_seq)

    //---- Configuration (set by virtual sequence before start()) ---------------
    bit [127:0] key    = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
    bit         encdec = 1'b0;       // 0=encrypt, 1=decrypt

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_apb_base_seq");
        super.new(name);
    endfunction

    //---- body  —  called when started on apb_sequencer -----------------------
    task body();
        `uvm_info("APB_SEQ", $sformatf(
            "Starting APB config: key=0x%0h  mode=%0s", key, encdec ? "DEC" : "ENC"), UVM_LOW)
        config_and_start(key, encdec);
    endtask

    //=======================================================================
    // config_and_start  —  full key-setup sequence  (internal, called by body)
    //=======================================================================
    task config_and_start(bit [127:0] key, bit encdec);
        apb_item item;
        bit [31:0] key_w[0:3];

        // Split 128-bit key into four 32-bit words
        key_w[0] = key[127:96];
        key_w[1] = key[95:64];
        key_w[2] = key[63:32];
        key_w[3] = key[31:0];

        //===============================================================
        // Step 1 — Write CTRL:  sm4_enable=1, encdec_enable=0, encdec_sel=encdec
        //===============================================================
        item = apb_item::type_id::create("item");
        start_item(item);
        item.paddr  = 8'h00;
        item.pwrite = 1'b1;
        item.pwdata = {29'b0, encdec, 1'b0, 1'b1};   // bit2=encdec, bit1=0, bit0=1
        finish_item(item);
        `uvm_info("APB_SEQ", $sformatf(
            "CTRL write: sm4_en=1 encdec_en=0 encdec_sel=%0b", encdec), UVM_MEDIUM)

        //===============================================================
        // Step 2 — Write KEY_0 … KEY_3
        //===============================================================
        for (int i = 0; i < 4; i++) begin
            item = apb_item::type_id::create("item");
            start_item(item);
            item.paddr  = 8'h10 + i * 4;     // 0x10, 0x14, 0x18, 0x1C
            item.pwrite = 1'b1;
            item.pwdata = key_w[i];
            finish_item(item);
            `uvm_info("APB_SEQ", $sformatf(
                "KEY_%0d write: 0x%0h", i, key_w[i]), UVM_MEDIUM)
        end

        //===============================================================
        // Step 3 — KEY_TRIG pulse
        //===============================================================
        item = apb_item::type_id::create("item");
        start_item(item);
        item.paddr  = 8'h04;
        item.pwrite = 1'b1;
        item.pwdata = 32'h0000_0001;         // bit0 = 1  triggers key expansion
        finish_item(item);
        `uvm_info("APB_SEQ", "KEY_TRIG pulse", UVM_MEDIUM)

        //===============================================================
        // Step 4 — Poll STATUS until key_exp_ready (bit0)
        //===============================================================
        `uvm_info("APB_SEQ", "Polling STATUS for key_exp_ready ...", UVM_MEDIUM)
        do begin
            item = apb_item::type_id::create("item");
            start_item(item);
            item.paddr  = 8'h08;
            item.pwrite = 1'b0;              // read
            finish_item(item);
            `uvm_info("APB_SEQ", $sformatf(
                "STATUS = 0x%0h  (key_ready=%0b)", item.prdata, item.prdata[0]), UVM_HIGH)
        end while (!item.prdata[0]);
        `uvm_info("APB_SEQ", "Key expansion complete!", UVM_MEDIUM)

        //===============================================================
        // Step 5 — Write CTRL:  sm4_enable=1, encdec_enable=1, encdec_sel=encdec
        //===============================================================
        item = apb_item::type_id::create("item");
        start_item(item);
        item.paddr  = 8'h00;
        item.pwrite = 1'b1;
        item.pwdata = {29'b0, encdec, 2'b11};    // bit2=encdec, bit1=1, bit0=1
        finish_item(item);
        `uvm_info("APB_SEQ", $sformatf(
            "CTRL write: sm4_en=1 encdec_en=1  →  READY for data"), UVM_MEDIUM)

        //===============================================================
        // Step 6 — Dummy STATUS reads to let encdec FSM settle
        //
        // The encdec FSM needs 2-3 cycles after encdec_enable=1 to
        // transition IDLE→WAITING_FOR_KEY→ENCRYPTION.  Two dummy reads
        // add ~6 cycles of margin so that the subsequent stream data
        // valid_in pulse arrives when current==ENCRYPTION.
        //===============================================================
        for (int i = 0; i < 2; i++) begin
            item = apb_item::type_id::create("item");
            start_item(item);
            item.paddr  = 8'h08;
            item.pwrite = 1'b0;              // read STATUS
            finish_item(item);
        end

    endtask

endclass : sm4_apb_base_seq
