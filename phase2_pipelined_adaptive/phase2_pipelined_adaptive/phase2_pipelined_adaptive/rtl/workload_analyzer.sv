// workload_analyzer.sv
// Fuses multiple telemetry signals to predict arithmetic intensity

module workload_analyzer (
    input  logic clk,
    input  logic rst,

    // Telemetry inputs
    input  logic        is_arith_D,     // decode-stage arithmetic hint
    input  logic        is_arith_R,     // retired instruction was arithmetic
    input  logic [3:0]  la_count,       // lookahead FIFO count

    // Outputs to Mode Arbiter
    output logic        wa_req,
    output logic [7:0]  confidence,
    output logic [7:0]  predicted_runlen
);

    // --- Sliding window counter ---
    logic [7:0] window_sum;
    logic [3:0] window_cnt;

    // --- Exponential Moving Average ---
    logic [7:0] ema;
    localparam EMA_SHIFT = 2; // weight factor

    // --- Trend detector ---
    logic [7:0] trend;

    // --- Simple burst detector ---
    logic [7:0] runlen_est;

    // Sliding window accumulation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            window_sum <= 0;
            window_cnt <= 0;
        end else begin
            if (window_cnt < 15)
                window_cnt <= window_cnt + 1;

            if (is_arith_R)
                window_sum <= window_sum + 1;
            else if (window_sum > 0)
                window_sum <= window_sum - 1;
        end
    end

    // EMA update
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            ema <= 0;
        else
            ema <= ema - (ema >> EMA_SHIFT) + (is_arith_R ? 8'd4 : 8'd0);
    end

    // Trend tracking
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            trend <= 0;
        else if (is_arith_R)
            trend <= trend + 1;
        else if (trend > 0)
            trend <= trend - 1;
    end

    // Predict run length from lookahead + trend
    always_comb begin
        runlen_est = (la_count << 1) + (trend >> 1);
    end

    // Confidence combines multiple signals
    always_comb begin
        confidence = window_sum + (ema >> 2) + trend;
    end

    // Request evaluation when confidence passes threshold
    assign wa_req = (confidence > 8'd20);

    assign predicted_runlen = runlen_est;

endmodule
