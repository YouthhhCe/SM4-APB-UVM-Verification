#include <stdio.h>
#include <stdint.h>
#include "svdpi.h"
#include "sm4.h"

// 暴露给 SystemVerilog 调用的 DPI-C 函数
// 参数说明：key(128bit), data_in(128bit), mode(0=加密, 1=解密), data_out(128bit)
void sm4_c_model(const svBitVecVal* key, const svBitVecVal* data_in, int mode, svBitVecVal* data_out) {
    uint8_t c_key[16];
    uint8_t c_in[16];
    uint8_t c_out[16];

    // 1. 将 SV 的 128-bit (4个32-bit整型) 转换为 C 的 16字节数组 (大端模式转换)
    for (int i = 0; i < 4; i++) {
        c_key[i*4 + 0] = (key[3-i] >> 24) & 0xFF;
        c_key[i*4 + 1] = (key[3-i] >> 16) & 0xFF;
        c_key[i*4 + 2] = (key[3-i] >> 8)  & 0xFF;
        c_key[i*4 + 3] = (key[3-i])       & 0xFF;

        c_in[i*4 + 0] = (data_in[3-i] >> 24) & 0xFF;
        c_in[i*4 + 1] = (data_in[3-i] >> 16) & 0xFF;
        c_in[i*4 + 2] = (data_in[3-i] >> 8)  & 0xFF;
        c_in[i*4 + 3] = (data_in[3-i])       & 0xFF;
    }

    // 2. 调用开源库的加解密函数
    if (mode == 0) {
        sm4_encrypt(c_key, c_in, c_out); // 调用头文件定义的加密接口
    } else {
        sm4_decrypt(c_key, c_in, c_out); // 调用头文件定义的解密接口
    }

    // 3. 将 C 算出的 16 字节结果，拼装回 SV 需要的 128-bit (4个32-bit整型)
    for (int i = 0; i < 4; i++) {
        data_out[3-i] = ((uint32_t)c_out[i*4 + 0] << 24) |
                        ((uint32_t)c_out[i*4 + 1] << 16) |
                        ((uint32_t)c_out[i*4 + 2] << 8)  |
                        ((uint32_t)c_out[i*4 + 3]);
    }
}

// 这是一个桩函数 (Stub)
// 用来骗过链接器，解决 sm4.c 找不到 debug_print 的报错
// 内部为空，刚好可以屏蔽掉 C 模型里多余的垃圾打印信息
void debug_print() {
    // 什么都不做
}