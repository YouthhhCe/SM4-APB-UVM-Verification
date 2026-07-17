# SM4 加解密模块 — UVM 验证项目 / SM4 Encryption Module — UVM Verification Project

[中文](README.md)

SM4 block cipher IP (GB/T 32907-2016), 128-bit block / 128-bit key, 32-round unbalanced Feistel network. APB slave interface + 128-bit Valid/Ready streaming data interface.

## Quick Start

```bash
cd sim
make compile                          # VCS compilation
make run TESTNAME=sm4_sanity_test     # Run a single test
make run TESTNAME=sm4_random_test     # Random test (1000 blocks)
make cov                              # Generate coverage report
```

## Directory Structure

```
├── rtl/                     # RTL source (10 .v files)
│   ├── sm4_wrapper.v        #   Top-level wrapper (APB + Stream)
│   ├── sm4_top.v            #   Core top
│   ├── sm4_encdec.v         #   Encryption/decryption control
│   ├── key_expansion.v      #   Key expansion
│   └── ...                  #   S-box, transforms, round functions
├── c_model/                 # C reference model + DPI-C (4 files)
├── uvm/                     # UVM 1.2 verification environment
│   ├── env/                 #   agent / driver / monitor / scoreboard / coverage
│   ├── seq/                 #   sequences
│   └── test/                #   6 test cases
├── tb/                      # Testbench top + interfaces (tb_top / apb_if / stream_if)
├── sim/                     # Simulation
│   ├── Makefile             #   VCS compile/run/coverage
│   ├── vcs_compile.log      #   Compilation log
│   ├── sim_sm4_*_test.log   #   6 test run logs
│   ├── sm4_tb.fsdb          #   Waveform (Verdi)
│   └── coverage_report/     #   Code coverage report (URG, HTML)
├── syn/                     # Synthesis
│   ├── syn.tcl              #   DC synthesis script
│   ├── sm4.sdc              #   Timing constraints
│   ├── dc_shell.log         #   Synthesis log
│   └── rpt/                 #   Reports: timing / area / power / resource
├── lint/                    # Lint
│   ├── run_spyglass.tcl     #   SpyGlass script
│   └── lint.log             #   Lint log
└── doc/                     # Documentation
    ├── SM4_Spec_and_Arch_zh.md             # Specification & Architecture (CN)
    ├── SM4_Verification_Strategy_zh.md     # Verification Strategy (CN)
    ├── SM4_Verification_Report_zh.md       # Verification Report (CN)
    ├── SM4_Verification_Strategy.md        # Verification Strategy (EN)
    └── SM4_Verification_Report.md          # Verification Report (EN)
```

## Verification Results

| Metric | Result |
|--------|--------|
| Test Cases | 6/6 all passed |
| Code Coverage | **93.48%** |
| Functional Coverage | Key covergroups 100% |
| Data Comparison | 153+ blocks verified against C model |

See `doc/SM4_Verification_Report_zh.md` for details.

> Built with [Claude Code](https://claude.ai/code).

## References

- RTL design adapted from: [gongxunwu/sm4-verilog](https://github.com/gongxunwu/sm4-verilog.git)
- C reference model adapted from: [jeremybennett/sm4](https://github.com/jeremybennett/sm4.git)

## Toolchain

| Tool | Version | Purpose |
|------|---------|---------|
| Synopsys VCS | V-2023.12-SP2 | Simulation |
| Verdi | — | Waveform viewer |
| Design Compiler | — | Logic synthesis |
| Spyglass | — | Lint checking |
