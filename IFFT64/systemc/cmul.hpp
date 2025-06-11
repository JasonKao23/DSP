#ifndef CMUL_HPP
#define CMUL_HPP

#include <systemc.h>

SC_MODULE(cmul)
{
    sc_in_clk clock;
    sc_in<bool> reset;

    sc_in<int> in_a_re;
    sc_in<int> in_a_im;
    sc_in<int> in_b_re;
    sc_in<int> in_b_im;
    sc_out<int> out_re;
    sc_out<int> out_im;

    sc_signal<int> in_a_re_delay;
    sc_signal<int> in_a_im_delay;
    sc_signal<int> in_b_re_delay;
    sc_signal<int> in_b_im_delay;

    sc_signal<int> delay1[4];
    sc_signal<int> delay2[3];
    sc_signal<int> delay3[2];

    SC_CTOR(cmul)
    {
        SC_METHOD(entry);
        dont_initialize();
        sensitive << clock.pos();
    }

    void entry();
};



#endif // CMUL_HPP
