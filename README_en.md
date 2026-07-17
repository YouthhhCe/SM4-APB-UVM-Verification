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

## Directory

| Dir | Description |
|-----|-------------|
| `rtl/` | RTL source (10 Verilog files) |
| `uvm/` | UVM 1.2 verification environment |
| `tb/` | Testbench top + interfaces |
| `c_model/` | C reference model (DPI-C) |
| `sim/` | VCS simulation Makefile |
| `syn/` | Design Compiler synthesis scripts |
| `lint/` | SpyGlass lint scripts |
| `doc/` | Specification, verification strategy & report |

## Verification Results

| Metric | Result |
|--------|--------|
| Test Cases | 6/6 all passed |
| Code Coverage | **93.48%** |
| Functional Coverage | Key covergroups 100% |
| Data Comparison | 153+ blocks verified against C model |

See `doc/SM4_Verification_Report_zh.md` for details.

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
