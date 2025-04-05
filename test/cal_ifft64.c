#include "svdpi.h"

#define FFT_LEN 64
#define CP_LEN  16
int tw_re[16][4] = {
    { 16384,  16384,  16384,  16384},
    { 16384,  16305,  16069,  15679},
    { 16384,  16069,  15137,  13623},
    { 16384,  15679,  13623,  10394},
    { 16384,  15137,  11585,   6270},
    { 16384,  14449,   9102,   1606},
    { 16384,  13623,   6270,  -3196},
    { 16384,  12665,   3196,  -7723},
    { 16384,  11585,      0, -11585},
    { 16384,  10394,  -3196, -14449},
    { 16384,   9102,  -6270, -16069},
    { 16384,   7723,  -9102, -16305},
    { 16384,   6270, -11585, -15137},
    { 16384,   4756, -13623, -12665},
    { 16384,   3196, -15137,  -9102},
    { 16384,   1606, -16069,  -4756},
};
int tw_im[16][4] = {
    {     0,      0,      0,      0},
    {     0,   1606,   3196,   4756},
    {     0,   3196,   6270,   9102},
    {     0,   4756,   9102,  12665},
    {     0,   6270,  11585,  15137},
    {     0,   7723,  13623,  16305},
    {     0,   9102,  15137,  16069},
    {     0,  10394,  16069,  14449},
    {     0,  11585,  16384,  11585},
    {     0,  12665,  16069,   7723},
    {     0,  13623,  15137,   3196},
    {     0,  14449,  13623,  -1606},
    {     0,  15137,  11585,  -6270},
    {     0,  15679,   9102, -10394},
    {     0,  16069,   6270, -13623},
    {     0,  16305,   3196, -15679}
};

void cal_ifft64_stage(int out_re[FFT_LEN], int out_im[FFT_LEN],
                      int in_re[FFT_LEN], int in_im[FFT_LEN], int stage)
{
    for (int i = 0; i < 16; i++) {
        // input data index
        int data_idx[4];
        for (int j = 0; j < 4; j++) {
            if (stage == 0)
                data_idx[j] = 16*j + i;
            else if (stage == 1)
                data_idx[j] = 4*j + (i&0x3) + 16*(i>>2);
            else // stage == 2
                data_idx[j] = j + 4*i;
        }
        // butterfly
        int re[4];
        int im[4];
        re[0] = in_re[data_idx[0]] + in_re[data_idx[1]] + in_re[data_idx[2]] + in_re[data_idx[3]];
        im[0] = in_im[data_idx[0]] + in_im[data_idx[1]] + in_im[data_idx[2]] + in_im[data_idx[3]];
        re[1] = in_re[data_idx[0]] - in_im[data_idx[1]] - in_re[data_idx[2]] + in_im[data_idx[3]];
        im[1] = in_im[data_idx[0]] + in_re[data_idx[1]] - in_im[data_idx[2]] - in_re[data_idx[3]];
        re[2] = in_re[data_idx[0]] - in_re[data_idx[1]] + in_re[data_idx[2]] - in_re[data_idx[3]];
        im[2] = in_im[data_idx[0]] - in_im[data_idx[1]] + in_im[data_idx[2]] - in_im[data_idx[3]];
        re[3] = in_re[data_idx[0]] + in_im[data_idx[1]] - in_re[data_idx[2]] - in_im[data_idx[3]];
        im[3] = in_im[data_idx[0]] - in_re[data_idx[1]] - in_im[data_idx[2]] + in_re[data_idx[3]];
        // tw index
        int tw_idx;
        if (stage == 0)
            tw_idx = i;
        else if (stage == 1)
            tw_idx = 4*(i&0x3);
        else
            tw_idx = 0;
        // output index for the last stage
        if (stage == 2) {
            for (int j = 0; j < 4; j++) {
                data_idx[j] = ((data_idx[j]&0x3)<<4)
                            + (data_idx[j]&0xC)
                            + ((data_idx[j]&0x30)>>4);
            }
        }
        // output
        for (int j = 0; j < 4; j++) {
            out_re[data_idx[j]] = tw_re[tw_idx][j]*re[j] - tw_im[tw_idx][j]*im[j];
            out_im[data_idx[j]] = tw_re[tw_idx][j]*im[j] + tw_im[tw_idx][j]*re[j];
            out_re[data_idx[j]] >>= 14;
            out_im[data_idx[j]] >>= 14;
        }
    }
}

DPI_DLLESPEC
void cal_ifft64(int out_re[FFT_LEN+CP_LEN], int out_im[FFT_LEN+CP_LEN],
                int in_re[FFT_LEN], int in_im[FFT_LEN])
{
    int re_buf[2][FFT_LEN];
    int im_buf[2][FFT_LEN];

    cal_ifft64_stage(re_buf[0], im_buf[0], in_re, in_im, 0);
    cal_ifft64_stage(re_buf[1], im_buf[1], re_buf[0], im_buf[0], 1);
    cal_ifft64_stage(&out_re[CP_LEN], &out_im[CP_LEN], re_buf[1], im_buf[1], 2);
    for (int i = 0; i < CP_LEN; i++) {
        out_re[i] = out_re[FFT_LEN+i];
        out_im[i] = out_im[FFT_LEN+i];
    }
}
