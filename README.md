# dreamchip

Most processors are designed with static microarchitectural assumptions, even though real workloads vary significantly over time. This mismatch leads to unnecessary energy consumption when execution behavior deviates from design-time expectations.

DreamChip explores a hardware-centric approach to runtime adaptivity. Instead of depending on software or operating system support, the architecture infers workload behavior directly within the pipeline using instruction lookahead, pipeline snooping, and lightweight execution telemetry. These signals are analyzed in hardware to drive safe, fine-grained adaptation of execution resources at runtime.

DreamChip addresses this by treating execution structure, energy, and throughput as runtime-controlled variables. The architecture dynamically adapts its active execution resources based on lightweight workload telemetry, while guaranteeing correctness through safe mode-switching at instruction boundaries.

The current implementation is a RISC-V soft-core prototype with:
- A dual-ALU microarchitecture (1-cycle high-speed ALU + multi-cycle low-power ALU)
- A workload analyzer combining instruction lookahead, pipeline snooping, and CPI feedback
- A conservative control FSM that enforces hysteresis, dwell time, and safe switching
- Instrumentation for CPI, stalls, and switching-activity–based power estimation

The repository focuses on the adaptive control path and execution selection logic, with simulation results from Phase 1 and an architectural RTL implementation of the Phase 2 pipelined design.
