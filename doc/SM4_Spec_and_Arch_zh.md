# SM4 加解密模块 — 规格与架构

> **文档版本:** 1.0
> **日期:** 2026-07-15
> **目标 IP:** `sm4_wrapper`（`sm4_top` 的 APB + 流式封装层）

---

## 目录

1. [特性](#1-特性)
2. [框图](#2-框图)
3. [模块层次](#3-模块层次)
4. [顶层接口信号](#4-顶层接口信号)
5. [APB 寄存器映射](#5-apb-寄存器映射)
6. [流式数据接口](#6-流式数据接口)
7. [操作时序](#7-操作时序)
8. [编程模型](#8-编程模型)
9. [内部架构](#9-内部架构)
10. [附录 — SM4 算法概要](#10-附录--sm4-算法概要)

---

## 1. 特性

| 特性 | 描述 |
|---|---|
| **算法** | SM4 分组密码（GB/T 32907-2016） |
| **分组长度** | 128 bits（16 bytes） |
| **密钥长度** | 128 bits（16 bytes） |
| **轮数** | 32 轮（非平衡 Feistel 网络） |
| **模式** | 加密与解密，软件可选 |
| **总线接口** | 32-bit APB Slave（AMBA 3 兼容） |
| **数据接口** | 128-bit Valid/Ready 流式握手 |
| **密钥管理** | 基于寄存器：APB 写入触发密钥扩展 |
| **状态** | 可轮询的密钥扩展就绪标志 |
| **时钟域** | 单同步域（`clk`） |
| **复位** | 异步低有效（`rst_n`） |

---

## 2. 框图

```
                        +-------------------------------------------+
                        |              sm4_wrapper                  |
                        |                                           |
  APB Master            |   +-------------+                         |
  ──────────────────────┤──►│ APB-to-Reg   │──── 内部寄存器 ────────┤
  paddr, pwdata,        |   │   Decoder    │  (CTRL, KEY, STATUS)   |
  pwrite, psel, penable |   +-------------+                         |
  ◄─────────────────────┤─── prdata, pready, pslverr                |
                        |                                           |
  Data Producer         |   +-------------+    +---------------+    |   Data Consumer
  ──────────────────────┤──►│ Input       │───►│               │────┤──►
  data_in_valid         |   │ Handshake   │    │   sm4_top     │    |   data_out_valid
  data_in[127:0]        |   │ FSM         │    │   (core)      │    |   data_out[127:0]
  ◄─────────────────────┤─── data_in_ready│    │               │    |   ◄──────────────
                        |   +-------------+    +---------------+    |   data_out_ready
                        |                                           |
                        +-------------------------------------------+
```

### 信号分组概要

| 分组 | 信号 | 方向（相对 wrapper） |
|---|---|---|
| **时钟与复位** | `clk`, `rst_n` | Input |
| **APB 控制** | `psel`, `penable`, `pwrite`, `paddr[7:0]` | Input |
| **APB 数据** | `pwdata[31:0]`, `prdata[31:0]`, `pready`, `pslverr` | In / Out |
| **流式输入** | `data_in_valid`, `data_in_ready`, `data_in[127:0]` | In / Out / In |
| **流式输出** | `data_out_valid`, `data_out_ready`, `data_out[127:0]` | Out / In / Out |

---

## 3. 模块层次

```
sm4_wrapper（本设计）
├── APB 寄存器组（CTRL, KEY_TRIG, STATUS, KEY_0..KEY_3）
├── 数据通路 FSM（IDLE → PROC → DONE）
└── sm4_top（原始核心）
    ├── key_expansion
    │   ├── get_cki                 （常量生成）
    │   ├── sbox_replace            （S盒查表）
    │   ├── transform_for_key_exp   （L' 线性变换）
    │   └── one_round_for_key_exp   （单轮数据通路）
    └── sm4_encdec
        ├── sbox_replace            （S盒查表）
        ├── transform_for_encdec    （L 线性变换）
        └── one_round_for_encdec    （单轮数据通路）
```

---

## 4. 顶层接口信号

### 4.1 时钟与复位

| 信号 | 位宽 | 方向 | 描述 |
|---|---|---|---|
| `clk` | 1 | IN | 系统时钟。所有寄存器上升沿触发。 |
| `rst_n` | 1 | IN | 异步低有效复位。 |

### 4.2 APB Slave 接口

| 信号 | 位宽 | 方向 | 描述 |
|---|---|---|---|
| `psel` | 1 | IN | APB 选通。整个传输期间保持高电平。 |
| `penable` | 1 | IN | APB 使能。指示第二（访问）周期。 |
| `pwrite` | 1 | IN | 写 = 1，读 = 0。 |
| `paddr` | 8 | IN | 字节地址。仅 0x00–0x1C 有效。 |
| `pwdata` | 32 | IN | 写数据（psel & penable & pwrite 时采样）。 |
| `prdata` | 32 | OUT | 读数据（psel & penable & ~pwrite 时有效）。 |
| `pready` | 1 | OUT | 就绪。零等待态：直连 psel & penable。 |
| `pslverr` | 1 | OUT | Slave 错误。访问未实现地址时置位。 |

### 4.3 流式数据接口

| 信号 | 位宽 | 方向 | 描述 |
|---|---|---|---|
| `data_in_valid` | 1 | IN | 输入数据有效（生产者 → wrapper）。 |
| `data_in_ready` | 1 | OUT | 输入就绪（wrapper → 生产者）。高电平表示 wrapper 可接收数据。 |
| `data_in` | 128 | IN | 输入明文（加密）或密文（解密）。 |
| `data_out_valid` | 1 | OUT | 输出数据有效（wrapper → 消费者）。 |
| `data_out_ready` | 1 | IN | 输出就绪（消费者 → wrapper）。 |
| `data_out` | 128 | OUT | 输出密文（加密）或明文（解密）。 |

---

## 5. APB 寄存器映射

### 5.1 地址表

| 偏移 | 名称 | 访问 | 位宽 | 复位值 | 描述 |
|---|---|---|---|---|---|
| `0x00` | **CTRL** | RW | 32 | `0x0000_0000` | 控制寄存器 |
| `0x04` | **KEY_TRIG** | WO | 32 | — | 密钥扩展触发 |
| `0x08` | **STATUS** | RO | 32 | `0x0000_0000` | 状态寄存器 |
| `0x10` | **KEY_0** | RW | 32 | `0x0000_0000` | 用户密钥字 0（MSW） |
| `0x14` | **KEY_1** | RW | 32 | `0x0000_0000` | 用户密钥字 1 |
| `0x18` | **KEY_2** | RW | 32 | `0x0000_0000` | 用户密钥字 2 |
| `0x1C` | **KEY_3** | RW | 32 | `0x0000_0000` | 用户密钥字 3（LSW） |

> **注：** 对上表未列出的地址发起 APB 访问将导致 `pslverr` 置位。

### 5.2 CTRL — 控制寄存器（0x00, RW）

```
 31 ───────────────────────────────────────────── 3 ── 2 ── 1 ── 0
|                  Reserved                          | ES | EE | SE |
```

| 比特 | 名称 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| `0` | **SE**（sm4_enable） | RW | 0 | 全局 SM4 使能。任何操作前必须置位。 |
| `1` | **EE**（encdec_enable） | RW | 0 | 加解密数据通路使能。发送数据前置位。 |
| `2` | **ES**（encdec_sel） | RW | 0 | 算法选择：`0` = 加密，`1` = 解密。 |
| `31:3` | Reserved | — | 0 | 读返回 0；写忽略。 |

### 5.3 KEY_TRIG — 密钥扩展触发寄存器（0x04, WO）

```
 31 ───────────────────────────────────────────── 1 ── 0
|                  Reserved                          | TR |
```

| 比特 | 名称 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| `0` | **TR**（trigger） | WO | — | 写 `1` 触发密钥扩展。wrapper 将其转换为单周期硬件脉冲送至 `sm4_top`。 |
| `31:1` | Reserved | WO | — | 忽略。 |

> **要点：** 必须在写 KEY_TRIG **之前**将用户密钥写入 KEY_0–KEY_3。触发脉冲同时向内部核心置位 `enable_key_exp_in` 与 `user_key_valid_in`。

### 5.4 STATUS — 状态寄存器（0x08, RO）

```
 31 ───────────────────────────────────────────── 1 ── 0
|                  Reserved                          | KR |
```

| 比特 | 名称 | 访问 | 复位 | 描述 |
|---|---|---|---|---|
| `0` | **KR**（key_ready） | RO | 0 | 密钥扩展就绪。镜像 `sm4_top` 的 `key_exp_ready_out`。`1` = 轮密钥有效，可开始数据处理。 |
| `31:1` | Reserved | RO | 0 | 读返回 0。 |

### 5.5 KEY_0–KEY_3 — 用户密钥寄存器（0x10–0x1C, RW）

128-bit 用户密钥拼接方式：

```
user_key[127:0] = {KEY_0[31:0], KEY_1[31:0], KEY_2[31:0], KEY_3[31:0]}
```

| 偏移 | 寄存器 | 字位置 | 描述 |
|---|---|---|---|
| `0x10` | KEY_0 | bits [127:96] | 用户密钥最高 32-bit 字 |
| `0x14` | KEY_1 | bits [95:64] | 第二字 |
| `0x18` | KEY_2 | bits [63:32] | 第三字 |
| `0x1C` | KEY_3 | bits [31:0] | 最低 32-bit 字 |

> **示例：** 密钥 `01234567_89ABCDEF_FEDCBA98_76543210`：
> - KEY_0 = `0x01234567`
> - KEY_1 = `0x89ABCDEF`
> - KEY_2 = `0xFEDCBA98`
> - KEY_3 = `0x76543210`

---

## 6. 流式数据接口

### 6.1 握手协议

流式接口遵循标准 Valid/Ready 握手：

```
                      +---+       +---+
data_in_valid         |   |_______|   |_______________
                   +-------+       +-------+
data_in_ready     |       |_______|       |___________
                   +-------+       +-------+
                      +---+       +---+
data_in[127:0]    ----< A >-------< B >---------------
```

- 当 `valid` 与 `ready` 同时为高时，发生一次传输。
- 生产者必须保持 `data_in` 稳定直至握手完成。
- wrapper 仅在可接收新数据时（IDLE 状态）置位 `data_in_ready`。

### 6.2 数据通路状态

内部 FSM 经历三个状态：

```
                 data_in_valid &
   ┌─────────── data_in_ready ──────────┐
   │                                    │
   ▼                                    │
┌──────┐        ┌──────┐        ┌──────┐
│ IDLE │ ────► │ PROC │ ────► │ DONE │
│      │        │      │        │      │
└──────┘        └──────┘        └──────┘
   ▲              │  ▲                │
   │              │  │ sm4_ready_out  │
   │              │  └────────────────┘
   │              │
   └── data_out_valid &
       data_out_ready
```

| 状态 | `data_in_ready` | `data_out_valid` | 描述 |
|---|---|---|---|
| **IDLE** | 1 | 0 | 就绪，可接收新输入块。 |
| **PROC** | 0 | 0 | 计算进行中。等待 `sm4_top` 的 `ready_out`。 |
| **DONE** | 0 | 1 | 输出结果已在 `data_out` 上就绪。等待消费者握手。 |

---

## 7. 操作时序

### 7.1 密钥扩展序列

```
          T0    T1    T2    T3    T4    T5    T6          Tn
          __    __    __    __    __    __    __          __
clk     _/  \__/  \__/  \__/  \__/  \__/  \__/  \________/  \_
             ____                ____                ___________
psel    ____/    \______________/    \______________/
                  ____                ____
penable _______/    \______________/    \______________________
             _________________
pwrite   ___/                 \_________________________________
             ___                ___
paddr    ___/04 \______________/08 \____________________________
             ___                _________________
pwdata   ___/01 \______________/
                                _______
prdata   ----------------------<__0/1_>-------------------------
                                         _________________________
key_trig           ┌─┐
(pulse)            └─┘___________________________________________
                   ┌─┐
user_key_valid_in  └─┘___________________________________________
                   ______________________________________________
key_exp_ready_out                    ┌────────────────────────────
                                     └
          (写 KEY_TRIG=1)     (轮询 STATUS 直至 bit0=1)
```

1. **T0**: APB 写 KEY_TRIG（0x04），数据 = `0x0000_0001`。
2. **T1**: Wrapper 产生单周期 `key_trig_pulse`，同时置位 `enable_key_exp_in` 与 `user_key_valid_in`。密钥扩展引擎启动。
3. **T2–Tn**: 密钥扩展运行（通常数十个时钟周期）。软件轮询 STATUS（0x08）。
4. **Tn**: STATUS bit 0 读回 `1`。轮密钥就绪，可开始数据处理。

### 7.2 数据处理序列（以加密为例）

```
          T0    T1    T2    T3           Tm    Tm+1  Tm+2
          __    __    __    __    __     __    __    __
clk     _/  \__/  \__/  \__/  \__/  \___/  \__/  \__/  \_
             _______________________________
valid   ____/                               \_______________
             _______________________________
ready   ____/                               \_______________
             _______________________________
data    ____X____plaintext[127:0]___________X_______________

          [  IDLE  ][            PROC ...            ][ DONE ]

          ___________                               ___________
dout_v  ____________                             /           \___
                                              _________________
dout_rdy ___________________________________/                 \___
                                              _________________
dout    ------------------------------------X_result[127:0]_X---
```

1. **T0**: 握手：`data_in_valid=1`, `data_in_ready=1`。Wrapper 锁存明文并通过 `sm4_valid_in` 脉冲启动 `sm4_top`。FSM → PROC。
2. **T1–Tm-1**: `sm4_top` 计算（32 轮 × 流水线深度）。`data_in_ready=0`（背压）。
3. **Tm**: `sm4_ready_out` 置位。Wrapper 锁存 `result_out`，FSM → DONE。`data_out_valid=1`。
4. **Tm+1**: 消费者置位 `data_out_ready`。握手完成。FSM → IDLE。

---

## 8. 编程模型

### 8.1 初始化序列

```
上电 / 复位
      │
      ▼
┌───────────────────────────────┐
│ 1. 等待复位释放               │
│    （rst_n = 1）              │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 2. 写 CTRL（0x00）           │
│    - sm4_enable      = 1     │
│    - encdec_sel      = 0/1   │
│    - encdec_enable   = 0     │
│      （暂不使能）             │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 3. 写 KEY_0 – KEY_3          │
│    （0x10, 0x14, 0x18, 0x1C）│
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 4. 写 KEY_TRIG（0x04）       │
│    数据 = 0x1                │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 5. 轮询 STATUS（0x08）       │
│    直至 bit0 == 1            │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 6. 写 CTRL（0x00）           │
│    - encdec_enable = 1       │
└──────────────┬────────────────┘
               ▼
       数据处理就绪
```

### 8.2 数据处理（每 128-bit 块）

```
┌───────────────────────────────┐
│ 发送一个块：                  │
│   data_in_valid      = 1     │
│   data_in = block[127:0]     │
│   等待 data_in_ready  = 1    │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 等待结果：                    │
│   轮询 data_out_valid = 1    │
└──────────────┬────────────────┘
               ▼
┌───────────────────────────────┐
│ 读取结果：                    │
│   result = data_out          │
│   data_out_ready     = 1     │
└──────────────┬────────────────┘
               ▼
       （重复处理下一块）
```

### 8.3 C 伪代码

```c
// --- 初始化 ---
apb_write(0x00, 0x00000005);  // CTRL: sm4_enable=1, encdec_enable=0, encdec_sel=0
apb_write(0x10, key_word0);   // KEY_0
apb_write(0x14, key_word1);   // KEY_1
apb_write(0x18, key_word2);   // KEY_2
apb_write(0x1C, key_word3);   // KEY_3
apb_write(0x04, 0x00000001);  // KEY_TRIG: 启动密钥扩展

while ((apb_read(0x08) & 0x1) == 0);  // 等待 key_exp_ready

apb_write(0x00, 0x00000007);  // CTRL: encdec_enable=1

// --- 数据处理循环（加密 N 个块）---
for (int i = 0; i < N; i++) {
    stream_send(plaintext[i]);      // data_in_valid=1, 等待 data_in_ready
    ciphertext[i] = stream_recv();  // 等待 data_out_valid, 置位 data_out_ready
}

// --- 切换为解密 ---
apb_write(0x00, 0x00000001);  // CTRL: 重配置前禁用 encdec
apb_write(0x00, 0x00000005);  // sm4_enable=1, encdec_sel=1（解密）
apb_write(0x04, 0x00000001);  // 重新触发密钥扩展（轮密钥顺序反转）

while ((apb_read(0x08) & 0x1) == 0);

apb_write(0x00, 0x00000007);  // CTRL: encdec_enable=1

for (int i = 0; i < N; i++) {
    stream_send(ciphertext[i]);
    plaintext_dec[i] = stream_recv();
}
```

### 8.4 密钥更换序列（同模式）

仅更换密钥（加解密模式不变）：

```c
apb_write(0x00, 0x00000001);  // 禁用 encdec_enable
apb_write(0x10, new_key_w0);  // 写入新密钥字
apb_write(0x14, new_key_w1);
apb_write(0x18, new_key_w2);
apb_write(0x1C, new_key_w3);
apb_write(0x04, 0x00000001);  // 触发密钥扩展
while ((apb_read(0x08) & 0x1) == 0);
apb_write(0x00, 0x00000007);  // 重新使能 encdec
```

---

## 9. 内部架构

### 9.1 Wrapper 至 Core 信号映射

| `sm4_wrapper` 内部信号 | `sm4_top` 端口 | 来源 |
|---|---|---|
| `sm4_enable` | `sm4_enable_in` | CTRL[0] |
| `encdec_enable` | `encdec_enable_in` | CTRL[1] |
| `encdec_sel` | `encdec_sel_in` | CTRL[2] |
| `key_trig_pulse` | `enable_key_exp_in` | APB 写 KEY_TRIG（单周期脉冲） |
| `key_trig_pulse` | `user_key_valid_in` | 同一脉冲 |
| `{key_reg0..3}` | `user_key_in[127:0]` | KEY_0..KEY_3 寄存器 |
| `sm4_valid_in` | `valid_in` | 组合逻辑：IDLE & 握手 |
| `data_in`（流式） | `data_in[127:0]` | 流式端口直通 |
| `sm4_ready_out` | `ready_out` | 来自 sm4_top |
| `sm4_result_out` | `result_out[127:0]` | 来自 sm4_top（DONE 状态锁存） |
| `key_exp_ready` | `key_exp_ready_out` | 来自 sm4_top（通过 STATUS[0] 可见） |

### 9.2 密钥扩展触发脉冲

```
                      +----------+
apb_write ────────────┤          │
(addr=0x04, data[0])  │ 边沿检测 │──► key_trig_pulse（1 周期）
pwdata[0] ────────────┤          │──► enable_key_exp_in
                      +----------+──► user_key_valid_in
```

- APB 对 KEY_TRIG 的写选通在标准 APB 协议中为**单周期宽度**。
- Wrapper 将该选通以组合逻辑寄存为 `key_trig_pulse`，同样为单周期宽度。
- 无需消抖或展宽——APB 协议保证控制信号无毛刺。

### 9.3 复位值汇总

| 元素 | 复位值 | 描述 |
|---|---|---|
| 全部 APB 寄存器 | `0x0000_0000` | CTRL、KEY_0..3 清零 |
| `pslverr` | `0` | 无错误 |
| FSM 状态 | `IDLE (2'b00)` | 可接收数据 |
| `latched_data_in` | `128'b0` | 清零 |
| `latched_result` | `128'b0` | 清零 |
| `key_trig_pulse` | `0` | 无效 |

---

## 10. 附录 — SM4 算法概要

SM4 为中国国家密码标准分组密码（GB/T 32907-2016）：

| 参数 | 值 |
|---|---|
| 分组长度 | 128 bits |
| 密钥长度 | 128 bits |
| 轮数 | 32 |
| 结构 | 非平衡 Feistel 网络 |
| S盒 | 8-bit × 8-bit（256 条目） |
| 轮函数 | `F(X0,X1,X2,X3,rk) = X0 ⊕ T(X1 ⊕ X2 ⊕ X3 ⊕ rk)` |
| T 变换 | `T(·) = L(τ(·))` — S盒代换后接线性变换 |
| 密钥编排 | 类似结构，采用修正线性变换 L' |

**解密**使用相同数据通路，轮密钥按**逆序**施加（rk₃₁, rk₃₀, …, rk₀）。

---

*— 文档结束 —*
