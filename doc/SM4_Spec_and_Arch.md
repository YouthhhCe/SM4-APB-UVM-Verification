# SM4 Encryption/Decryption Module — Specification & Architecture

> **Document Version:** 1.0
> **Date:** 2026-07-15
> **Target IP:** `sm4_wrapper` (APB + Streaming Wrapper for `sm4_top`)

---

## Table of Contents

1. [Features](#1-features)
2. [Block Diagram](#2-block-diagram)
3. [Module Hierarchy](#3-module-hierarchy)
4. [Top-Level Interface Signals](#4-top-level-interface-signals)
5. [APB Register Map](#5-apb-register-map)
6. [Streaming Data Interface](#6-streaming-data-interface)
7. [Operation Timing](#7-operation-timing)
8. [Programming Model](#8-programming-model)
9. [Internal Architecture](#9-internal-architecture)
10. [Appendix — SM4 Algorithm Summary](#10-appendix--sm4-algorithm-summary)

---

## 1. Features

| Feature | Description |
|---|---|
| **Algorithm** | SM4 block cipher (GB/T 32907-2016) |
| **Block Size** | 128 bits (16 bytes) |
| **Key Size** | 128 bits (16 bytes) |
| **Round Count** | 32 rounds (unbalanced Feistel network) |
| **Modes** | Encryption and Decryption, software-selectable |
| **Bus Interface** | 32-bit APB Slave (AMBA 3 compatible) |
| **Data Interface** | 128-bit Valid/Ready streaming handshake |
| **Key Management** | Register-based: key expansion triggered by APB write |
| **Status** | Pollable key-expansion-ready flag |
| **Clock Domain** | Single synchronous domain (`clk`) |
| **Reset** | Asynchronous active-low (`rst_n`) |

---

## 2. Block Diagram

```
                        +-------------------------------------------+
                        |              sm4_wrapper                  |
                        |                                           |
  APB Master            |   +-------------+                         |
  ──────────────────────┤──►│ APB-to-Reg   │──── internal regs ─────┤
  paddr, pwdata,        |   │   Decoder    │    (CTRL, KEY, STATUS) |
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

### Signal Group Summary

| Group | Signals | Direction (w.r.t wrapper) |
|---|---|---|
| **Clock & Reset** | `clk`, `rst_n` | Input |
| **APB Control** | `psel`, `penable`, `pwrite`, `paddr[7:0]` | Input |
| **APB Data** | `pwdata[31:0]`, `prdata[31:0]`, `pready`, `pslverr` | In / Out |
| **Stream In** | `data_in_valid`, `data_in_ready`, `data_in[127:0]` | In / Out / In |
| **Stream Out** | `data_out_valid`, `data_out_ready`, `data_out[127:0]` | Out / In / Out |

---

## 3. Module Hierarchy

```
sm4_wrapper (this work)
├── APB Register File (CTRL, KEY_TRIG, STATUS, KEY_0..KEY_3)
├── Data-Path FSM (IDLE → PROC → DONE)
└── sm4_top (original core)
    ├── key_expansion
    │   ├── get_cki               (constant generation)
    │   ├── sbox_replace          (S-Box look-up)
    │   ├── transform_for_key_exp (L' linear transform)
    │   └── one_round_for_key_exp (single-round datapath)
    └── sm4_encdec
        ├── sbox_replace          (S-Box look-up)
        ├── transform_for_encdec  (L linear transform)
        └── one_round_for_encdec  (single-round datapath)
```

---

## 4. Top-Level Interface Signals

### 4.1 Clock and Reset

| Signal | Width | Dir | Description |
|---|---|---|---|
| `clk` | 1 | IN | System clock. All registers are posedge-triggered. |
| `rst_n` | 1 | IN | Asynchronous active-low reset. |

### 4.2 APB Slave Interface

| Signal | Width | Dir | Description |
|---|---|---|---|
| `psel` | 1 | IN | APB select. High during the entire transfer. |
| `penable` | 1 | IN | APB enable. Indicates the second (access) cycle. |
| `pwrite` | 1 | IN | Write = 1, Read = 0. |
| `paddr` | 8 | IN | Byte address. Only 0x00–0x1C are valid. |
| `pwdata` | 32 | IN | Write data (sampled when psel & penable & pwrite). |
| `prdata` | 32 | OUT | Read data (valid when psel & penable & ~pwrite). |
| `pready` | 1 | OUT | Ready. Zero-wait-state: tied to psel & penable. |
| `pslverr` | 1 | OUT | Slave error. Asserted for accesses to unimplemented addresses. |

### 4.3 Streaming Data Interface

| Signal | Width | Dir | Description |
|---|---|---|---|
| `data_in_valid` | 1 | IN | Input data valid (producer → wrapper). |
| `data_in_ready` | 1 | OUT | Input ready (wrapper → producer). High when wrapper can accept data. |
| `data_in` | 128 | IN | Input plaintext (encrypt) or ciphertext (decrypt). |
| `data_out_valid` | 1 | OUT | Output data valid (wrapper → consumer). |
| `data_out_ready` | 1 | IN | Output ready (consumer → wrapper). |
| `data_out` | 128 | OUT | Output ciphertext (encrypt) or plaintext (decrypt). |

---

## 5. APB Register Map

### 5.1 Address Table

| Offset | Name | Access | Width | Reset | Description |
|---|---|---|---|---|---|
| `0x00` | **CTRL** | RW | 32 | `0x0000_0000` | Control register |
| `0x04` | **KEY_TRIG** | WO | 32 | — | Key-expansion trigger |
| `0x08` | **STATUS** | RO | 32 | `0x0000_0000` | Status register |
| `0x10` | **KEY_0** | RW | 32 | `0x0000_0000` | User key word 0 (MSW) |
| `0x14` | **KEY_1** | RW | 32 | `0x0000_0000` | User key word 1 |
| `0x18` | **KEY_2** | RW | 32 | `0x0000_0000` | User key word 2 |
| `0x1C` | **KEY_3** | RW | 32 | `0x0000_0000` | User key word 3 (LSW) |

> **Note:** Any APB access to an address **not** listed above asserts `pslverr`.

### 5.2 CTRL — Control Register (0x00, RW)

```
 31 ───────────────────────────────────────────── 3 ── 2 ── 1 ── 0
|                  Reserved                          | ES | EE | SE |
```

| Bit(s) | Name | Access | Reset | Description |
|---|---|---|---|---|
| `0` | **SE** (sm4_enable) | RW | 0 | Global SM4 enable. Must be set for any operation. |
| `1` | **EE** (encdec_enable) | RW | 0 | Encryption/Decryption datapath enable. Set before sending data. |
| `2` | **ES** (encdec_sel) | RW | 0 | Algorithm selection: `0` = Encryption, `1` = Decryption. |
| `31:3` | Reserved | — | 0 | Read as 0; writes ignored. |

### 5.3 KEY_TRIG — Key-Expansion Trigger (0x04, WO)

```
 31 ───────────────────────────────────────────── 1 ── 0
|                  Reserved                          | TR |
```

| Bit(s) | Name | Access | Reset | Description |
|---|---|---|---|---|
| `0` | **TR** (trigger) | WO | — | Write `1` to trigger key expansion. The wrapper converts this into a single-cycle hardware pulse to `sm4_top`. |
| `31:1` | Reserved | WO | — | Ignored. |

> **Important:** The user key must be written to KEY_0–KEY_3 **before** writing KEY_TRIG. The trigger pulse simultaneously asserts `enable_key_exp_in` and `user_key_valid_in` to the internal core.

### 5.4 STATUS — Status Register (0x08, RO)

```
 31 ───────────────────────────────────────────── 1 ── 0
|                  Reserved                          | KR |
```

| Bit(s) | Name | Access | Reset | Description |
|---|---|---|---|---|
| `0` | **KR** (key_ready) | RO | 0 | Key-expansion ready. Mirrors `key_exp_ready_out` from `sm4_top`. `1` = round keys valid, data processing may begin. |
| `31:1` | Reserved | RO | 0 | Read as 0. |

### 5.5 KEY_0–KEY_3 — User Key Registers (0x10–0x1C, RW)

The 128-bit user key is assembled as:

```
user_key[127:0] = {KEY_0[31:0], KEY_1[31:0], KEY_2[31:0], KEY_3[31:0]}
```

| Offset | Register | Word Position | Description |
|---|---|---|---|
| `0x10` | KEY_0 | bits [127:96] | Most-significant 32-bit word of user key |
| `0x14` | KEY_1 | bits [95:64] | Second word |
| `0x18` | KEY_2 | bits [63:32] | Third word |
| `0x1C` | KEY_3 | bits [31:0] | Least-significant 32-bit word |

> **Example:** For key `01234567_89ABCDEF_FEDCBA98_76543210`:
> - KEY_0 = `0x01234567`
> - KEY_1 = `0x89ABCDEF`
> - KEY_2 = `0xFEDCBA98`
> - KEY_3 = `0x76543210`

---

## 6. Streaming Data Interface

### 6.1 Handshake Protocol

The streaming interface follows the standard Valid/Ready handshake:

```
               +---+   +---+       +---+
data_in_valid  |   |___|   |_______|   |_______
                    +---+       +---+
               +-------+       +---------------+
data_in_ready  |       |_______|               |
               +-------+       +---------------+
                    +---+       +---+
data_in[127:0] ----< A >-------< B >------------
```

- A transfer occurs on every cycle where **both** `valid` and `ready` are high.
- The producer must hold `data_in` stable until the handshake completes.
- The wrapper asserts `data_in_ready` only when it can accept new data (IDLE state).

### 6.2 Data Path States

The internal FSM transitions through three states:

```
              data_in_valid &
   ┌────────  data_in_ready   ────────┐
   │                                  │
   ▼                                  │
┌──────┐        ┌──────┐        ┌──────┐
│ IDLE │  ────► │ PROC │  ────► │ DONE │
│      │        │      │        │      │
└──────┘        └──────┘        └──────┘
   ▲              │  ▲               │
   │              │  │  sm4_ready_out│
   │              │  └───────────────┘
   │              │
   └── data_out_valid &
       data_out_ready
```

| State | `data_in_ready` | `data_out_valid` | Description |
|---|---|---|---|
| **IDLE** | 1 | 0 | Ready to accept new input block. |
| **PROC** | 0 | 0 | Computation in progress. Waiting for `ready_out` from `sm4_top`. |
| **DONE** | 0 | 1 | Output result ready on `data_out`. Waiting for consumer handshake. |

---

## 7. Operation Timing

### 7.1 Key-Expansion Sequence

```
        T0    T1    T2    T3    T4    T5    T6          Tn
        __    __    __    __    __    __    __          __
clk   _/  \__/  \__/  \__/  \__/  \__/  \__/  \________/  \_
           ____                ____                ___________
psel  ____/    \______________/    \______________/
                ____                ____
penable _______/    \______________/    \_____________________
           _________________
pwrite ___/                 \_________________________________
           ___                ___
paddr  ___/04 \______________/08 \____________________________
           ___                _________________
pwdata ___/01 \______________/
                              _______
prdata ----------------------<__0/1_>--------------------------
                                       _________________________
key_trig          ┌─┐
(pulse)           └─┘___________________________________________
                  ┌─┐
user_key_valid_in └─┘___________________________________________
                  ______________________________________________
key_exp_ready_out                  ┌────────────────────────────
                                   └
         (write KEY_TRIG=1)   (poll STATUS until bit0=1)
```

1. **T0**: APB write to KEY_TRIG (0x04) with data = `0x0000_0001`.
2. **T1**: The wrapper generates a single-cycle pulse on `key_trig_pulse`, which asserts `enable_key_exp_in` and `user_key_valid_in`. The key-expansion engine starts.
3. **T2–Tn**: Key expansion runs (typically tens of clock cycles). Software polls STATUS (0x08).
4. **Tn**: STATUS bit 0 reads `1`. The round keys are ready. Data processing may begin.

### 7.2 Data-Processing Sequence (Encryption Example)

```
        T0    T1    T2    T3           Tm    Tm+1  Tm+2
        __    __    __    __    __     __    __    __
clk   _/  \__/  \__/  \__/  \__/  \___/  \__/  \__/  \_
           _______________________________
valid  ____/                               \_______________
           _______________________________
ready  ____/                               \_______________
           _______________________________
data   ____X____plaintext[127:0]___________X_______________

        [  IDLE  ][            PROC ...            ][ DONE ]

        ___________                               ___________
dout_v ____________                             /           \___
                                             _________________
dout_rdy ___________________________________/                 \___
                                             _________________
dout    ------------------------------------X_result[127:0]_X---
```

1. **T0**: Handshake: `data_in_valid=1`, `data_in_ready=1`. Wrapper latches plaintext and starts `sm4_top` via `sm4_valid_in` pulse. FSM → PROC.
2. **T1–Tm-1**: `sm4_top` computes (32 rounds × pipeline depth). `data_in_ready=0` (back-pressure).
3. **Tm**: `sm4_ready_out` asserts. Wrapper latches `result_out` and FSM → DONE. `data_out_valid=1`.
4. **Tm+1**: Consumer asserts `data_out_ready`. Handshake completes. FSM → IDLE.

---

## 8. Programming Model

### 8.1 Initialization Sequence

```
Power-On / Reset
      │
      ▼
┌─────────────────────────┐
│ 1. Wait for reset de-   │
│    assertion (rst_n=1)  │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 2. Write CTRL (0x00)    │
│    - sm4_enable = 1     │
│    - encdec_sel = 0/1   │
│    (keep encdec_enable  │
│     = 0 for now)        │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 3. Write KEY_0–KEY_3    │
│    (0x10, 0x14, 0x18,   │
│     0x1C)               │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 4. Write KEY_TRIG (0x04)│
│    with data = 0x1      │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 5. Poll STATUS (0x08)   │
│    until bit0 == 1      │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ 6. Write CTRL (0x00)    │
│    - encdec_enable = 1  │
└───────────┬─────────────┘
            ▼
    Ready for data processing
```

### 8.2 Data Processing (Per 128-bit Block)

```
┌─────────────────────────┐
│ Send one block:         │
│  data_in_valid = 1      │
│  data_in = block[127:0] │
│  wait data_in_ready = 1 │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Wait for result:        │
│  poll data_out_valid=1  │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Read result:            │
│  result = data_out      │
│  data_out_ready = 1     │
└───────────┬─────────────┘
            ▼
    (repeat for next block)
```

### 8.3 C Pseudocode

```c
// --- Initialization ---
apb_write(0x00, 0x00000005);  // CTRL: sm4_enable=1, encdec_enable=0, encdec_sel=0
apb_write(0x10, key_word0);   // KEY_0
apb_write(0x14, key_word1);   // KEY_1
apb_write(0x18, key_word2);   // KEY_2
apb_write(0x1C, key_word3);   // KEY_3
apb_write(0x04, 0x00000001);  // KEY_TRIG: start key expansion

while ((apb_read(0x08) & 0x1) == 0);  // wait for key_exp_ready

apb_write(0x00, 0x00000007);  // CTRL: encdec_enable=1

// --- Data processing loop (encrypt N blocks) ---
for (int i = 0; i < N; i++) {
    stream_send(plaintext[i]);      // data_in_valid=1, wait data_in_ready
    ciphertext[i] = stream_recv();  // wait data_out_valid, assert data_out_ready
}

// --- Switch to decryption ---
apb_write(0x00, 0x00000001);  // CTRL: disable encdec while reconfiguring
apb_write(0x00, 0x00000005);  // sm4_enable=1, encdec_sel=1 (decrypt)
apb_write(0x04, 0x00000001);  // re-trigger key expansion (round key order reversed)

while ((apb_read(0x08) & 0x1) == 0);

apb_write(0x00, 0x00000007);  // CTRL: encdec_enable=1

for (int i = 0; i < N; i++) {
    stream_send(ciphertext[i]);
    plaintext_dec[i] = stream_recv();
}
```

### 8.4 Key-Change Sequence (Same Mode)

When only the key changes (same encrypt/decrypt mode):

```c
apb_write(0x00, 0x00000001);  // disable encdec_enable
apb_write(0x10, new_key_w0);  // write new key words
apb_write(0x14, new_key_w1);
apb_write(0x18, new_key_w2);
apb_write(0x1C, new_key_w3);
apb_write(0x04, 0x00000001);  // trigger key expansion
while ((apb_read(0x08) & 0x1) == 0);
apb_write(0x00, 0x00000007);  // re-enable encdec
```

---

## 9. Internal Architecture

### 9.1 Wrapper-to-Core Signal Mapping

| `sm4_wrapper` internal | `sm4_top` port | Source |
|---|---|---|
| `sm4_enable` | `sm4_enable_in` | CTRL[0] |
| `encdec_enable` | `encdec_enable_in` | CTRL[1] |
| `encdec_sel` | `encdec_sel_in` | CTRL[2] |
| `key_trig_pulse` | `enable_key_exp_in` | APB write to KEY_TRIG (one-cycle pulse) |
| `key_trig_pulse` | `user_key_valid_in` | Same pulse |
| `{key_reg0..3}` | `user_key_in[127:0]` | KEY_0..KEY_3 registers |
| `sm4_valid_in` | `valid_in` | Combinational: IDLE & handshake |
| `data_in` (stream) | `data_in[127:0]` | Pass-through from streaming port |
| `sm4_ready_out` | `ready_out` | From sm4_top |
| `sm4_result_out` | `result_out[127:0]` | From sm4_top (latched in DONE state) |
| `key_exp_ready` | `key_exp_ready_out` | From sm4_top (visible via STATUS[0]) |

### 9.2 Key-Expansion Trigger Pulse

```
                    +-----+
apb_write ──────────┤     │
(addr=0x04,data[0]) │Edge │──► key_trig_pulse (1 cycle)
pwdata[0] ──────────┤Det. │──► enable_key_exp_in
                    +-----+──► user_key_valid_in
```

- The APB write strobe to KEY_TRIG is **one cycle wide** in standard APB.
- The wrapper registers this strobe combinatorially as `key_trig_pulse`, which is also one cycle wide.
- No debouncing or stretching is needed since the APB protocol guarantees glitch-free control signals.

### 9.3 Reset Value Summary

| Element | Reset Value | Description |
|---|---|---|
| All APB registers | `0x0000_0000` | CTRL, KEY_0..3 cleared |
| `pslverr` | `0` | No error |
| FSM state | `IDLE (2'b00)` | Ready to accept data |
| `latched_data_in` | `128'b0` | Cleared |
| `latched_result` | `128'b0` | Cleared |
| `key_trig_pulse` | `0` | Inactive |

---

## 10. Appendix — SM4 Algorithm Summary

SM4 is a Chinese national standard block cipher (GB/T 32907-2016):

| Parameter | Value |
|---|---|
| Block size | 128 bits |
| Key size | 128 bits |
| Rounds | 32 |
| Structure | Unbalanced Feistel network |
| S-Box | 8-bit × 8-bit (256 entries) |
| Round function | `F(X0,X1,X2,X3,rk) = X0 ⊕ T(X1 ⊕ X2 ⊕ X3 ⊕ rk)` |
| T-transform | `T(·) = L(τ(·))` — S-Box substitution followed by linear transform |
| Key schedule | Similar structure with modified linear transform L' |

**Decryption** uses the identical datapath with round keys applied in **reverse order** (rk₃₁, rk₃₀, …, rk₀).

---

*— End of Document —*
