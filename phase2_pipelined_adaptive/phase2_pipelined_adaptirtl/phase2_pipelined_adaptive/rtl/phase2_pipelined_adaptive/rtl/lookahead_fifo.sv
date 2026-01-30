// lookahead_fifo.sv
// Small FIFO to hold early arithmetic hints from fetch stage

module lookahead_fifo #(
    parameter DEPTH = 4
) (
    input  logic        clk,
    input  logic        rst,

    input  logic        push,
    input  logic        pop,
    input  logic        is_arith_in,

    output logic [DEPTH-1:0] fifo_bits,
    output logic        valid
);

    logic [DEPTH-1:0] fifo_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_reg <= '0;
        end else begin
            if (push && !pop) begin
                fifo_reg <= {fifo_reg[DEPTH-2:0], is_arith_in};
            end else if (!push && pop) begin
                fifo_reg <= {fifo_reg[DEPTH-2:0], 1'b0};
            end
        end
    end

    assign fifo_bits = fifo_reg;
    assign valid = |fifo_reg;

endmodule
