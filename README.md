# SM4 加解密模块 — UVM 验证项目 / SM4 Encryption Module — UVM Verification Project

[English](README_en.md)

SM4 分组密码 IP（GB/T 32907-2016），128-bit 分组 / 128-bit 密钥，32 轮非平衡 Feistel 网络。APB 从接口配置 + 128-bit Valid/Ready 流式数据接口。

## 快速开始

```bash
cd sim
make compile                          # VCS 编译
make run TESTNAME=sm4_sanity_test     # 运行单个测试
make run TESTNAME=sm4_random_test     # 随机测试 (1000 块)
make cov                              # 生成覆盖率报告
```

## 目录结构

```
├── rtl/                     # RTL 源码 (10 个 .v)
│   ├── sm4_wrapper.v        #   顶层封装 (APB + Stream Wrapper)
│   ├── sm4_top.v            #   内核顶层
│   ├── sm4_encdec.v         #   加解密控制
│   ├── key_expansion.v      #   密钥扩展
│   └── ...                  #   S盒、变换、轮函数等子模块
├── c_model/                 # C 参考模型 + DPI-C (4 文件)
├── uvm/                     # UVM 1.2 验证环境
│   ├── env/                 #   agent / driver / monitor / scoreboard / coverage
│   ├── seq/                 #   sequence
│   └── test/                #   6 个测试用例
├── tb/                      # Testbench 顶层 + 接口 (tb_top / apb_if / stream_if)
├── sim/                     # 仿真目录
│   ├── Makefile             #   VCS 编译/运行/覆盖率脚本
│   ├── vcs_compile.log      #   仿真编译日志
│   ├── sim_sm4_*_test.log   #   6 个用例运行日志
│   ├── sm4_tb.fsdb          #   波形文件 (Verdi)
│   └── coverage_report/     #   代码覆盖率报告 (URG, HTML)
├── syn/                     # 综合目录
│   ├── syn.tcl              #   DC 综合脚本
│   ├── sm4.sdc              #   时序约束
│   ├── dc_shell.log         #   综合日志
│   └── rpt/                 #   报告: timing / area / power / resource
├── lint/                    # Lint 目录
│   ├── run_spyglass.tcl     #   Spyglass 脚本
│   └── lint.log             #   Lint 日志
└── doc/                     # 文档
    ├── SM4_Spec_and_Arch_zh.md             # 规格与架构 (中文)
    ├── SM4_Verification_Strategy_zh.md     # 验证策略 (中文)
    ├── SM4_Verification_Report_zh.md       # 验证报告 (中文)
    ├── SM4_Verification_Strategy.md        # 验证策略 (英文)
    └── SM4_Verification_Report.md          # 验证报告 (英文)
```

## 验证结果

| 指标 | 结果 |
|------|------|
| 测试用例 | 6/6 全部通过 |
| Code Coverage | **93.48%** |
| Functional Coverage | 关键 Covergroup 100% |
| 数据比对 | 153+ 笔与 C 模型逐位一致 |

详见 `doc/SM4_Verification_Report_zh.md`。

> 本项目基于 [Claude Code](https://claude.ai/code) 辅助完成。

## 参考与致谢

- RTL 设计参考：[gongxunwu/sm4-verilog](https://github.com/gongxunwu/sm4-verilog.git)
- C 参考模型参考：[jeremybennett/sm4](https://github.com/jeremybennett/sm4.git)

## 工具链

| 工具 | 版本 | 用途 |
|------|------|------|
| Synopsys VCS | V-2023.12-SP2 | 仿真编译 |
| Verdi | — | 波形查看 |
| Design Compiler | — | 逻辑综合 |
| Spyglass | — | Lint 检查 |
