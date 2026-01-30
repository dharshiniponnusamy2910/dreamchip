# Hazards and Correctness

This document explains how the Phase 2 pipelined DreamChip design maintains architectural correctness while introducing runtime adaptation and multi-cycle execution behavior.

---

## 1. Pipeline Hazards

DreamChip Phase 2 uses a simple 3-stage pipeline (Fetch → Decode → Execute) with an execution queue between Decode and Execute. This introduces potential structural and timing hazards which are handled conservatively.

### Structural Hazard: Multi-Cycle Low-Power ALU

The low-power ALU (`alu_lowp`) requires multiple cycles to complete an operation.

**Handling Strategy:**
- The Execute stage asserts `alu_busy` while a multi-cycle operation is in progress.
- The execution queue does **not dequeue** a new instruction while `alu_busy = 1`.
- The Decode stage may continue briefly (queue depth = 4), but will stall once the queue is full.

This ensures:
- No instruction enters Execute before the previous one completes.
- In-order completion is preserved.

---

## 2. Mode Switching Safety

Adaptive mode switching changes which ALU is active (FAST vs LOWP). Switching at the wrong time could corrupt results, so strict safety rules are enforced.

### Switching Rule

A mode switch is only applied when:

```
alu_busy == 0   AND   execute_stage_idle == 1
```

Meaning:
- No instruction is currently executing
- The Execute stage is between instructions

### Switching Sequence

1. Workload Analyzer raises `wa_req`
2. Mode Arbiter evaluates confidence and predicted run length
3. Arbiter issues `switch_req`
4. Top-level control waits for `alu_idle`
5. `current_mode` register updates
6. Execution resumes

No instruction is ever switched mid-execution.

---

## 3. Control-Path Stalls

Short, controlled pipeline pauses may occur during:

- Mode transition (1-cycle safety pause)
- Full execution queue with busy ALU

These stalls are:

✔ Explicitly counted in `stall_cycles`  
✔ Included in CPI and energy evaluation  
✔ Part of the adaptation cost being studied  

This makes the overhead measurable rather than hidden.

---

## 4. In-Order Completion Guarantee

DreamChip Phase 2 maintains **in-order execution and retirement**:

- Only one instruction occupies the Execute stage at a time
- Instructions retire strictly when `alu_done` is asserted
- No speculative execution or out-of-order behavior is introduced

This greatly simplifies correctness reasoning and ensures ISA-level consistency.

---

## 5. Telemetry Isolation from Datapath

All adaptation logic (Workload Analyzer, Mode Arbiter, counters, thresholds):

- Operates on **side-band telemetry signals**
- Does **not modify register values or instruction results**
- Only affects *when* and *how* execution units are selected

Thus, adaptation cannot directly corrupt architectural state.

---

## 6. Summary

DreamChip Phase 2 prioritizes correctness and analyzability over aggressive performance techniques.

| Feature | Safety Approach |
|--------|----------------|
| Multi-cycle execution | Backpressure + queue stall |
| Mode switching | Only at Execute idle |
| Control overhead | Measured via counters |
| Instruction order | Strict in-order |
| Adaptation logic | Control-path only |

The goal is to study runtime adaptation in a controlled, architecturally safe environment.
