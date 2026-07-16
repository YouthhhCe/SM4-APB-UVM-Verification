////////////////////////////////////////////////////////////////////////////////
// File        : sm4_dpic.c
// Description : DPI-C bridge between SystemVerilog testbench and sm4.h C model
//               Exports c_sm4_compute() for SV-side DPI import.
//
// Data Layout (FIXED):
//   SV  svBitVecVal[3:0]  (canonical DPI)  →  C  uint8_t[0:15]
//   –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
//   key[3] bits [127:96]  ↔  c_key[ 0.. 3]
//   key[2] bits [ 95:64]  ↔  c_key[ 4.. 7]
//   key[1] bits [ 63:32]  ↔  c_key[ 8..11]
//   key[0] bits [ 31: 0]  ↔  c_key[12..15]
//
//   CRITICAL: sm4.c's load_u32_be(b, n) reads b[4n+3] as MSB
//   and b[4n] as LSB.  Therefore we must store the SV word's
//   LSB at c_xxx[i*4+0] and MSB at c_xxx[i*4+3].
//
//   store_u32_be(v, b) writes v's MSB to b[3] and LSB to b[0],
//   which matches how we assemble data_out from c_out below.
////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdint.h>
#include "svdpi.h"
#include "sm4.h"

//===================================================================
// c_sm4_compute  —  DPI-C entry point for SM4 encryption / decryption
//
//   key      [IN]  128-bit user key      (svBitVecVal[0:3])
//   data_in  [IN]  128-bit input block   (svBitVecVal[0:3])
//   mode     [IN]  0 = encrypt, 1 = decrypt
//   data_out [OUT] 128-bit output block  (svBitVecVal[0:3])
//===================================================================
void c_sm4_compute(const svBitVecVal *key,
                   const svBitVecVal *data_in,
                   int                mode,
                   svBitVecVal       *data_out)
{
    uint8_t c_key[16];
    uint8_t c_in[16];
    uint8_t c_out[16];
    int i;

    //---------------------------------------------------------------
    // Step 1 — SV canonical → C big-endian byte array
    //
    //   SV canonical layout (DPI):
    //     key[0] = bits [31:0],   key[1] = bits [63:32],
    //     key[2] = bits [95:64],  key[3] = bits [127:96]
    //
    //   C model expects big-endian bytes:
    //     c_key[0] = MSByte (bits 127:120),  c_key[15] = LSByte (bits 7:0)
    //---------------------------------------------------------------
    for (i = 0; i < 4; i++) {
        // key[3-i]: iterate from the most-significant SV word downward
        //
        // load_u32_be(b, n) reads b[4n+3] as MSB, b[4n] as LSB.
        // So we store: c_xxx[i*4+0]=LSB, c_xxx[i*4+3]=MSB.
        c_key[i*4 + 0] = (uint8_t)(key[3-i]);          // byte 0 = LSB of word
        c_key[i*4 + 1] = (uint8_t)(key[3-i] >> 8);
        c_key[i*4 + 2] = (uint8_t)(key[3-i] >> 16);
        c_key[i*4 + 3] = (uint8_t)(key[3-i] >> 24);   // byte 3 = MSB of word

        c_in[i*4 + 0]  = (uint8_t)(data_in[3-i]);
        c_in[i*4 + 1]  = (uint8_t)(data_in[3-i] >> 8);
        c_in[i*4 + 2]  = (uint8_t)(data_in[3-i] >> 16);
        c_in[i*4 + 3]  = (uint8_t)(data_in[3-i] >> 24);
    }

    //---------------------------------------------------------------
    // Step 2 — Call the reference C-model SM4 function
    //---------------------------------------------------------------
    if (mode == 0) {
        sm4_encrypt(c_key, c_in, c_out);
    } else {
        sm4_decrypt(c_key, c_in, c_out);
    }

    //---------------------------------------------------------------
    // Step 3 — C big-endian byte array → SV canonical
    //
    //   store_u32_be(v, b) writes v's MSB to b[3] and LSB to b[0],
    //   so c_out[i*4+3] is the MSB.  We assemble SV words accordingly.
    //---------------------------------------------------------------
    for (i = 0; i < 4; i++) {
        data_out[3-i] = ((uint32_t)c_out[i*4 + 3] << 24) |
                        ((uint32_t)c_out[i*4 + 2] << 16) |
                        ((uint32_t)c_out[i*4 + 1] << 8)  |
                        ((uint32_t)c_out[i*4 + 0]);
    }
}

//===================================================================
// debug_print  —  Stub to satisfy linker
//
// sm4.c references debug_print() in its SM4_ROUNDS macro.
// We provide an empty implementation to suppress the linker error
// and to discard the internal debug output of the C reference model.
//===================================================================
void debug_print() {
    // intentionally empty
}
