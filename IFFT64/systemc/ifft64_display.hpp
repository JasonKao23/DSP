#ifndef IFFT64_DISPLAY_HPP
#define IFFT64_DISPLAY_HPP

#include <systemc.h>

SC_MODULE(ifft64_display)
{
    sc_in_clk clock;
    sc_in<bool> reset;

    sc_in<int> out_re;
    sc_in<int> out_im;
    sc_in<bool> out_valid;
    sc_out<bool> out_ready;

    int ref_re[80];
    int ref_im[80];
    uint out_counter;

    FILE *fout;

    SC_CTOR(ifft64_display)
    {
        SC_METHOD(entry);
        dont_initialize();
        sensitive << clock.pos();

        fout = fopen("ifft64_out_sample.txt", "w");

        FILE *fref = fopen("ifft64_ref_sample.txt", "r");
        int re;
        int im;
        for (int i = 0; i != 80; ++i) {
            if ((fscanf(fref, "%d, %d", &re, &im) == EOF)) {
                break;
            }
            ref_re[i] = re;
            ref_im[i] = im;
        }
        fclose(fref);
        out_counter = 0;
    }

    void entry();
};

#endif // DISPLAY_FFT64_HPP

