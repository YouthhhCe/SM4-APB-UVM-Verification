# SM4 加解密模块 — UVM 验证项目

[English](README.md)

SM4 分组密码 IP（GB/T 32907-2016），128-bit 分组 / 128-bit 密钥，32 轮非平衡 Feistel 网络。APB 从接口配置 + 128-bit Valid/Ready 流式数据接口。

## 快速开始

```bash
cd sim
make compile                          # VCS 编译
make run TESTNAME=sm4_sanity_test     # 运行单个测试
make run TESTNAME=sm4_random_test     # 随机测试 (1000 块)
make cov                              # 生成覆盖率报告
```

## 目录

| 目录 | 说明 |
|------|------|
| `rtl/` | RTL 源码 (10 个 Verilog 文件) |
| `uvm/` | UVM 1.2 验证环境 |
| `tb/` | Testbench 顶层 + 接口 |
| `c_model/` | C 参考模型 (DPI-C) |
| `sim/` | VCS 仿真脚本 |
| `syn/` | Design Compiler 综合脚本 |
| `lint/` | SpyGlass Lint 脚本 |
| `doc/` | 规格、验证策略、验证报告 |

## 验证结果

| 指标 | 结果 |
|------|------|
| 测试用例 | 6/6 全部通过 |
| Code Coverage | **93.48%** |
| Functional Coverage | 关键 Covergroup 100% |
| 数据比对 | 153+ 笔与 C 模型逐位一致 |

详见 `doc/SM4_Verification_Report_zh.md`。

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
