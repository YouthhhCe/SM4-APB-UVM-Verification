/* This is the reference implementation for "Optimized Implementation of SM4 on
   AVR Microcontrollers and ARM Processors" by Hyeokdong Kwon, Hyunjun Kim, Eum
   Si Woo, Minjoo Shim, Wai-Kong Lee, Zhi Hu, Hwajeong Seo,
   https://eprint.iacr.org/2021/667 */

#ifndef HEADER_SM4_H
#define HEADER_SM4_H

#include <inttypes.h>

#define SM4_BLOCK_SIZE 16
#define SM4_KEY_SCHEDULE 32

void sm4_encrypt (uint8_t key[], unsigned char plaintext[],
                  unsigned char ciphertext[]);

void sm4_decrypt (uint8_t key[], unsigned char ciphertext[],
                  unsigned char plaintext[]);

#endif
