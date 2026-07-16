# SM4 加密/解密硬件加速器 — UVM 验证项目

基于 **UVM 1.2** 的 SM4 分组密码硬件加速器功能验证环境，包含 APB 总线接口和 128-bit 流式数据接口。

## 项目概况

| 项目 | 说明 |
|------|------|
| **算法** | SM4 分组密码 (GB/T 32907-2016) |
| **分组长度** | 128 bits |
| **密钥长度** | 128 bits |
| **轮数** | 32 轮非平衡 Feistel 网络 |
| **总线接口** | 32-bit APB Slave (AMBA 3) |
| **数据接口** | 128-bit Valid/Ready 握手 |
| **验证方法** | UVM 1.2 (SystemVerilog) |
| **参考模型** | C 语言 DPI-C 黄金模型 |

## 目录结构

```
.
├── rtl/           # RTL 设计源码 (Verilog)
├── uvm/           # UVM 验证环境 (SystemVerilog)
│   ├── env/       #   Agent, Driver, Monitor, Scoreboard, Coverage
│   ├── seq/       #   测试序列
│   └── test/      #   测试用例
├── tb/            # Testbench 顶层 + 接口
├── c_model/       # C 参考模型 (DPI-C)
├── sim/           # 仿真目录 (Makefile + VCS 脚本)
├── syn/           # 综合目录 (Design Compiler 脚本 + SDC)
├── lint/          # SpyGlass Lint 脚本
└── doc/           # 设计文档
```

## 快速开始

### 前置条件

- Synopsys VCS (带 UVM 1.2 支持)
- Synopsys Design Compiler (综合用)
- Synopsys SpyGlass (Lint 用)
- GNU Make

### 仿真流程

```bash
cd sim

# 编译
make compile

# 运行测试
make run TESTNAME=sm4_sanity_test
make run TESTNAME=sm4_burst_test
make run TESTNAME=sm4_random_test
make run TESTNAME=sm4_golden_test

# 生成覆盖率报告
make cov

# 清理仿真文件
make clean
```

### 综合流程

```bash
cd syn
dc_shell -f syn.tcl
```

### Lint 检查

```bash
cd lint
spyglass -project sm4_lint.prj
```

## 测试用例

| 测试名称 | 说明 |
|----------|------|
| `sm4_sanity_test` | 基础冒烟测试，单次加密/解密 |
| `sm4_burst_test` | 连续多包加密/解密测试 |
| `sm4_random_test` | 随机明文 + 随机密钥测试 |
| `sm4_golden_test` | 与 C 参考模型逐包比对 |

## UVM 环境架构

```
sm4_env
├── apb_agent       (APB 总线 Agent)
│   ├── apb_sequencer
│   ├── apb_driver
│   └── apb_monitor
├── stream_agent    (流式数据 Agent)
│   ├── stream_sequencer
│   ├── stream_driver
│   └── stream_monitor
├── sm4_scoreboard  (比对 C 参考模型)
├── sm4_coverage    (功能覆盖率收集)
└── sm4_virtual_seq (协调 APB + Stream 时序)
```

## 参考文档

- [SM4 规格与架构说明](doc/SM4_Spec_and_Arch.md)
- GB/T 32907-2016 — SM4 分组密码算法国家标准

## License

Internal project — all rights reserved.
