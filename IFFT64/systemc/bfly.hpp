#ifndef BFLY_H
#define BFLY_H

#include <systemc.h>
#include "cmul.hpp"

SC_MODULE(bfly)
{
    sc_in_clk clock;
    sc_in<bool> reset;
    sc_in<int> in_re;
    sc_in<int> in_im;
    sc_in<int> w_re;
    sc_in<int> w_im;
    sc_in<bool> start;
    sc_out<int> out_re;
    sc_out<int> out_im;
    sc_out<bool> out_valid;

    sc_signal<uint> stage;
    sc_signal<int> valid;
    sc_signal<int> in_re_delay;
    sc_signal<int> in_im_delay;
    sc_signal<int> u0_re;
    sc_signal<int> u0_im;
    sc_signal<int> u1_re;
    sc_signal<int> u1_im;
    sc_signal<int> u2_re;
    sc_signal<int> u2_im;
    sc_signal<int> u3_re;
    sc_signal<int> u3_im;
    sc_signal<int> u0_re_delay[5];
    sc_signal<int> u0_im_delay[5];
    sc_signal<int> u2_re_delay;
    sc_signal<int> u2_im_delay;
    sc_signal<int> u3_re_delay[2];
    sc_signal<int> u3_im_delay[2];
    sc_signal<int> w_re_delay[3];
    sc_signal<int> w_im_delay[3];
    sc_signal<int> in_a_re;
    sc_signal<int> in_a_im;
    sc_signal<int> in_b_re;
    sc_signal<int> in_b_im;
    sc_signal<int> out_c_re;
    sc_signal<int> out_c_im;

    cmul *cmul_inst;

    sc_trace_file *tracefile;

    SC_CTOR(bfly);
    ~bfly();

    void entry();
};

#endif // BFLY_H
