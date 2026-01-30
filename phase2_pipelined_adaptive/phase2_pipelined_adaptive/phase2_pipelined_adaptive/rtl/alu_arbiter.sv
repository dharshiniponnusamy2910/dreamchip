// alu_arbiter.sv
// Selects between fast ALU and low-power ALU and manages execution handshake

module alu_arbiter (
    input  logic        clk,
    input  logic        rst,

    // Control
    input  logic        start_exec,
    input  logic        mode_fast,     // 1 = fast ALU, 0 = low-power ALU

    // Operands & operation
    input  logic [31:0] op_a,
    input  logic [31:0] op_b,
    input  logic [3:0]  alu_op,

    // Outputs
    output logic [31:0] result,
    output logic        alu_busy,
    output logic        alu_done
);

    // Internal signals
    logic [31:0] fast_result, lowp_result;
    logic fast_done, lowp_done;
    logic fast_busy, lowp_busy;

    // Fast ALU (single-cycle model)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fast_result <= 32'd0;
        end else if (start_exec && mode_fast) begin
            case (alu_op)
                4'd0: fast_result <= op_a + op_b;
                4'd1: fast_result <= op_a - op_b;
                4'd2: fast_result <= op_a & op_b;
                4'd3: fast_result <= op_a | op_b;
                default: fast_result <= 32'd0;
            endcase
        end
    end

    assign fast_done = start_exec && mode_fast;
    assign fast_busy = 1'b0; // single-cycle

    // Low-power ALU (multi-cycle model)
    logic [1:0] lowp_counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lowp_counter <= 2'd0;
            lowp_result  <= 32'd0;
        end else begin
            if (start_exec && !mode_fast && lowp_counter == 2'd0)
                lowp_counter <= 2'd2;  // 2-cycle latency model
            else if (lowp_counter != 2'd0)
                lowp_counter <= lowp_counter - 1;

            if (lowp_counter == 2'd1) begin
                case (alu_op)
                    4'd0: lowp_result <= op_a + op_b;
                    4'd1: lowp_result <= op_a - op_b;
                    4'd2: lowp_result <= op_a & op_b;
                    4'd3: lowp_result <= op_a | op_b;
                    default: lowp_result <= 32'd0;
                endcase
            end
        end
    end

    assign lowp_done = (lowp_counter == 2'd1);
    assign lowp_busy = (lowp_counter != 2'd0);

    // Output mux
    assign result   = mode_fast ? fast_result : lowp_result;
    assign alu_done = mode_fast ? fast_done   : lowp_done;
    assign alu_busy = mode_fast ? fast_busy   : lowp_busy;

endmodule
