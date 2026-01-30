# Phase 2 — Pipelined Adaptive DreamChip

Phase 2 extends DreamChip into a pipelined microarchitecture that supports runtime adaptation of execution resources based on observed workload behavior.

The focus of this phase is to design a **stable and correct control framework** around a simple pipeline, so that adaptive execution can be evaluated in a realistic architectural setting.

This directory documents the pipeline structure, workload monitoring mechanisms, control logic, and design considerations for safe operation.

---

## Goals of This Phase

- Introduce a 3-stage pipeline (Fetch → Decode → Execute)
- Monitor workload behavior using multiple telemetry sources
- Use this information to guide execution mode selection
- Ensure switching between execution modes does not violate correctness
- Measure the performance and switching overheads introduced by adaptation

---

## Key Design Ideas

- **Instruction Lookahead** provides early hints about upcoming instruction patterns  
- **Pipeline Snooping** observes in-flight instructions  
- **Retire Statistics** provide stable long-term behavior tracking  
- A **Workload Analyzer** combines these signals  
- A **Mode Arbiter** applies simple rules to request safe mode transitions

Mode changes are only applied when the execution unit is idle to ensure that no instruction is affected mid-execution.

---

## Contents of This Folder

| File | Description |
|------|-------------|
| `architecture.md` | Pipeline organization and dataflow |
| `control_and_adaptation.md` | Workload Analyzer and Mode Arbiter design |
| `hazards_and_correctness.md` | How pipeline hazards and switching safety are handled |
| `evaluation_plan.md` | Planned performance and energy evaluation approach |
| `rtl/` | Key RTL modules for control and monitoring logic |
