# Phase 2 Adaptive Control Loop Integration

This file explains how the provided RTL modules connect within the DreamChip pipeline.


## Dataflow

1. **Lookahead FIFO**
   - Observes upcoming instructions
   - Produces early arithmetic intensity hints

2. **Workload Analyzer**
   - Combines lookahead hints, decode snooping, and retired stats
   - Produces:
     - `confidence`
     - `predicted_runlen`
     - `wa_req`

3. **Mode Arbiter**
   - Evaluates if switching execution mode is beneficial
   - Waits for safe execution boundary
   - Updates `mode_fast`

4. **ALU Arbiter**
   - Selects between:
     - Fast ALU (1-cycle, higher switching)
     - Low-power ALU (multi-cycle, lower switching)

## Research Focus

The RTL provided demonstrates the **control-path intelligence** of DreamChip Phase 2.  
The remaining CPU pipeline is standard and omitted to focus on adaptive microarchitectural innovation.
