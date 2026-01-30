// mode_arbiter.sv
// Decides when to switch between FAST and LOW-POWER execution modes safely

module mode_arbiter (
    input  logic clk,
    input  logic rst,

    // Inputs from Workload Analyzer
    input  logic        wa_req,          // workload analyzer requests evaluation
    input  logic [7:0]  confidence,      // confidence in decision
    input  logic [7:0]  predicted_runlen,// predicted arithmetic run length

    // Pipeline status
    input  logic        alu_idle,        // safe point to switch

    // Outputs
    output logic        switch_req,
    output logic        mode_fast        // 1 = FAST, 0 = LOWP
);

    typedef enum logic [1:0] {
        IDLE,
        REQUEST,
        APPLY,
        PROBATION
    } state_t;

    state_t state, next_state;

    logic [3:0] probation_cnt;

    // Thresholds (tunable parameters)
    localparam CONF_TH   = 8'd40;
    localparam RUNLEN_TH = 8'd6;

    // Decision logic: is FAST mode worth it?
    logic worthy_fast;
    assign worthy_fast = (confidence > CONF_TH) && (predicted_runlen > RUNLEN_TH);

    // FSM next state logic
    always_comb begin
        next_state = state;
        switch_req = 1'b0;

        case (state)
            IDLE: begin
                if (wa_req)
                    next_state = REQUEST;
            end

            REQUEST: begin
                switch_req = 1'b1;
                if (alu_idle)
                    next_state = APPLY;
            end

            APPLY: begin
                next_state = PROBATION;
            end

            PROBATION: begin
                if (probation_cnt == 4'd0)
                    next_state = IDLE;
            end
        endcase
    end

    // State + control registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            mode_fast   <= 1'b1;  // start in fast mode
            probation_cnt <= 4'd0;
        end else begin
            state <= next_state;

            if (state == APPLY) begin
                mode_fast <= worthy_fast;
                probation_cnt <= 4'd8;  // prevent rapid toggling
            end else if (state == PROBATION && probation_cnt != 0) begin
                probation_cnt <= probation_cnt - 1;
            end
        end
    end

endmodule
