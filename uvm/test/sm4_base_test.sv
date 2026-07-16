////////////////////////////////////////////////////////////////////////////////
// Component   : sm4_base_test
// Description : Base UVM test — instantiates sm4_env and starts the
//               virtual sequence on the APB sequencer.
////////////////////////////////////////////////////////////////////////////////

class sm4_base_test extends uvm_test;

    `uvm_component_utils(sm4_base_test)

    //---- Environment ---------------------------------------------------------
    sm4_env env;

    //---- Constructor ---------------------------------------------------------
    function new(string name = "sm4_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //---- build_phase ---------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sm4_env::type_id::create("env", this);
    endfunction

    //---- end_of_elaboration_phase --------------------------------------------
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass : sm4_base_test
