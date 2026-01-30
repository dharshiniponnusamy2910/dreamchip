# Architecture and Dataflow

This document describes the structural organization of the Phase 2 pipelined DreamChip design and how data and control information flow through the system.

---

## Top-Level Dataflow

                +--------------------+
                |   Instruction      |
                |      Memory        |
                +---------+----------+
                          | inst_F, is_arith_hint_F
                          v
+------------------+ <-> +------------------+
| Lookahead FIFO | | la_count |
+---------+--------+ +------------------+
| la_push/pop ↑
v |
+------------------+ |
| Decode Stage | <-----------+ (snoop is_arith_D)
+---------+--------+
| rf_raddr1/2
v
+------------------+ +------------------+
| Register File | | Exec Queue |
| (32x32) | | (depth=4) |
+---------+--------+ +---------+--------+
| rf_rdata1/2 | execq_out_inst
v v
+-------------------------+
| Execute Stage |
| +-------------------+ |
| | ALU Bank | |
| | ├─ alu_fast | |
| | └─ alu_lowp | |
| +--------+----------+ |
| | |
| alu_busy | alu_done |
+----------+--------------+
| alu_y
v
+---------------------+
| Retire Logic |
+-----------+---------+
| instr_valid_R, is_arith_R
v
+---------------------+
| Workload Analyzer |
+-----------+---------+
| wa_req, conf, pred_runlen
v
+---------------------+
| Mode Arbiter |
+-----------+---------+
| switch_req, pending_mode
v
+---------------------+
| Top-Level Control |
| (switch_ack, |
| current_mode, |
| probation, pause) |
+---------------------+
---

## Module Hierarchy

dreamchip_top.sv
├── core_pipeline.sv
│ ├── fetch_stub.sv // IMEM + predecode
│ ├── lookahead_fifo.sv // LA_DEPTH = 4
│ ├── stage_reg_F.sv // F → D
│ ├── decoder_stub.sv // Decode + snoop tap
│ ├── exec_queue.sv // depth = 4
│ ├── stage_reg_D.sv // D → ExecQ
│ ├── execute_stage.sv
│ │ ├── alu_arbiter.sv // selects FAST / LOWP
│ │ ├── alu_fast.sv // single-cycle
│ │ └── alu_lowp.sv // multi-cycle
│ ├── regfile.sv // 32 × 32 register file
│ ├── cpi_tracker.sv // issue vs retire tracking
│ └── retire_logic.sv
│
├── workload_analyzer.sv
│ ├── sliding_window_counter
│ ├── ema_filter
│ ├── burst_detector
│ ├── trend_counter
│ └── fusion_logic
│
├── mode_arbiter.sv
│ ├── meta_fsm
│ ├── dwell_counter
│ ├── probation_counter
│ └── adaptive_thresholds
│
└── instrumentation.sv
├── metrics_logger.sv
├── toggle_monitor.sv
└── performance_counters.sv
---

## Pipeline Timing (Conceptual)

Cycle: 1 2 3 4 5 6

FETCH: I1 I2 I3 I4 I5 I6
DECODE: I1 I2 I3 I4 I5
EXEC-Q: I1 I2 I3
EXECUTE: I1 I2 I3
RETIRE: I1 I2 I3
The Execution Queue allows the front-end (Fetch/Decode) to continue briefly even when the low-power ALU requires multiple cycles.

---

## Implementation Scope

The additional structures introduced in Phase 2 are primarily control-path components (counters, small FIFOs, and FSM logic). No large duplicated datapaths are added beyond the second ALU, allowing the overhead of adaptation to be measured explicitly.
