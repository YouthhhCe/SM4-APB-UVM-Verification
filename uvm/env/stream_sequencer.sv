////////////////////////////////////////////////////////////////////////////////
// Component   : stream_sequencer
// Description : Simple sequencer for stream transactions.
////////////////////////////////////////////////////////////////////////////////

class stream_sequencer extends uvm_sequencer #(stream_item);

    `uvm_component_utils(stream_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : stream_sequencer
