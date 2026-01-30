# Evaluation Plan

This document describes how the Phase 2 DreamChip architecture will be evaluated in a structured and reproducible manner.

The goal is to quantify the **costs and benefits of runtime architectural adaptation** compared to static execution modes.

---

## 1. Evaluation Modes

The processor supports three execution configurations:

| Mode | Description |
|------|-------------|
| FAST_ONLY | Only the 1-cycle high-performance ALU is used |
| ECO_ONLY | Only the multi-cycle low-power ALU is used |
| ADAPTIVE | Runtime switching between ALUs using telemetry |

These modes allow direct comparison between static and adaptive behavior under identical workloads.

---

## 2. Metrics Collected

Instrumentation modules collect the following runtime statistics:

| Metric | Description |
|-------|-------------|
| `cycle_count` | Total execution cycles |
| `instr_count` | Number of retired instructions |
| `stall_cycles` | Cycles stalled due to ALU busy or switching |
| `fast_ops` | Number of operations executed on FAST ALU |
| `eco_ops` | Number of operations executed on LOWP ALU |
| `mode_transitions` | Number of mode switches |
| `toggle_count_fast` | Switching activity proxy for FAST ALU |
| `toggle_count_eco` | Switching activity proxy for LOWP ALU |

From these we compute:

- **CPI (Cycles Per Instruction)**  
  CPI = cycle_count / instr_count  

- **Energy Proxy**  
  Energy_proxy = α × toggle_count_fast + β × toggle_count_eco  

  where α and β represent relative switching cost of each ALU.

- **Energy–Delay Product (EDP) Proxy**  
  EDP_proxy = CPI × Energy_proxy


---

## 3. Workload Categories

Evaluation will use instruction streams with varying behavior:

| Workload Type | Description |
|--------------|-------------|
| Compute-Heavy | Long arithmetic runs |
| Mixed | Alternating arithmetic and non-arithmetic phases |
| Memory-Dominated | Sparse arithmetic, frequent non-ALU ops |
| Burst Behavior | Sudden short arithmetic spikes |

These patterns test how well telemetry predicts and adapts to changing workload phases.

---

## 4. Adaptation Overhead Analysis

The following adaptation costs are explicitly measured:

- Performance penalty from multi-cycle low-power ALU
- Stall cycles introduced during mode switching
- Hardware overhead of control-path logic (estimated via synthesis)
- Impact of mispredicted mode switches

This ensures the benefits of adaptation are evaluated **net of overhead**.

---

## 5. Ablation Studies

To understand which telemetry signals are most useful, controlled experiments may disable components:

| Variant | Disabled Component |
|--------|-------------------|
| No Lookahead | Ignore lookahead FIFO signals |
| No Snooping | Ignore decode-stage arithmetic detection |
| No Trend | Disable trend counter contribution |
| Static Thresholds | Disable adaptive thresholds |

This helps determine which signals contribute most to stable and effective switching.

---

## 6. Expected Outcomes

The evaluation seeks to determine:

- When runtime adaptation provides energy savings
- How often switching overhead outweighs benefits
- Which telemetry sources best predict useful phase changes
- The real tradeoff between stability and responsiveness

---

## 7. Reproducibility

All metrics are logged via `metrics_logger` in CSV format, enabling:

- Offline analysis
- Visualization of CPI vs energy trends
- Direct comparison across execution modes

The design intentionally exposes all control overheads so adaptation can be studied transparently.
