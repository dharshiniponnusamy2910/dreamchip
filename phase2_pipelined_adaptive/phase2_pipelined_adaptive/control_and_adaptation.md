# Control and Adaptation Logic

This document explains how DreamChip monitors workload behavior and safely adapts execution modes at runtime.

---

## Overview

Phase 2 introduces a control layer that operates alongside the pipeline datapath.  
It does **not** modify instruction execution semantics. Instead, it observes behavior and decides when to switch between:

- **FAST mode** → 1-cycle ALU (higher performance, higher switching activity)
- **ECO mode** → Multi-cycle ALU (lower power, longer latency)

Switching is only allowed at safe boundaries to ensure correctness.

---

## Workload Monitoring

Workload behavior is observed using signals from multiple pipeline stages:

| Source | Purpose |
|-------|---------|
| **Instruction Lookahead (Fetch)** | Early hint of upcoming arithmetic intensity |
| **Pipeline Snooping (Decode/Execute)** | Confirms in-flight instruction types |
| **Retire Statistics** | Ground truth of completed instruction mix |

These signals are fused in the **Workload Analyzer**.

### Workload Analyzer Internals

The analyzer combines short-term and long-term trends:

- **Sliding Window Counter** → Tracks recent arithmetic density  
- **EMA Filter** → Smooths fluctuations over time  
- **Burst Detector** → Detects sustained arithmetic runs  
- **Trend Counter** → Identifies increasing or decreasing intensity  

These are combined in **Fusion Logic** to produce:

- `score` — estimated arithmetic intensity  
- `confidence` — stability of prediction  
- `predicted_runlen` — expected duration of the phase
  
The workload score is computed as a weighted combination of multiple telemetry signals:

score = W_la·LA + W_snoop·S + W_win·Win + W_ema·EMA + W_trend·Trend + Burst_bonus

where:
- LA = lookahead arithmetic density  
- S = in-flight snoop signal  
- Win = sliding window arithmetic ratio  
- EMA = smoothed long-term trend  
- Trend = phase growth indicator  

---

## Mode Decision Logic

The **Mode Arbiter** receives workload estimates and decides whether a mode change is worthwhile.

### Key Safeguards

To prevent unstable behavior:

- **Hysteresis thresholds** prevent frequent toggling  
- **Minimum dwell time** ensures a mode stays active long enough  
- **Probation period** evaluates the impact after switching  

A switch is requested only if:

- Workload confidence is high  
- Predicted run length justifies the transition cost  

---

## Safe Mode Switching

Switching between FAST and ECO must never interrupt an instruction mid-execution.

### Switching Sequence

```
Workload Analyzer → Mode Arbiter → Switch Request
                                     ↓
                            Wait for ALU Idle
                                     ↓
                               Apply Mode
                                     ↓
                               Enter Probation
```

### Safety Conditions

Mode updates occur only when:

- `alu_busy == 0`
- No instruction is in the middle of execution
- Pipeline backpressure is handled before transition

If the ECO ALU is active (multi-cycle), the pipeline may stall briefly, but correctness is preserved.

---

## Adaptive Thresholds

The system includes optional threshold tuning based on observed CPI changes:

- After a mode switch, CPI is monitored
- If performance improves or degrades consistently, thresholds adjust slightly
- This allows the controller to adapt to workload characteristics over time

---

## Design Philosophy

The adaptation framework in DreamChip Phase 2 is designed as an experimental control layer that allows systematic evaluation of runtime architectural telemetry and switching policies.

Rather than assuming minimal overhead, this work explicitly **includes multiple telemetry sources and control mechanisms** to study:

- Which signals are most predictive of workload phases  
- How much control complexity is required for stable adaptation  
- The trade-off between adaptation benefits and control-path overhead  

By instrumenting and analyzing the cost of these mechanisms, the project aims to determine which components are truly necessary for effective runtime adaptivity in future designs.

---

## Summary

DreamChip Phase 2 adds a runtime adaptation control layer to a simple pipelined processor in order to study how architectural telemetry can guide safe execution mode switching.

The system:

- Observes workload behavior across multiple pipeline stages  
- Uses early hints and confirmed execution trends to estimate upcoming workload phases  
- Switches execution modes only at architecturally safe boundaries  
- Measures the performance, stall behavior, and control overhead introduced by adaptation  

Together, these mechanisms provide a structured platform for evaluating the real costs and benefits of runtime microarchitectural adaptivity without compromising correctness.

