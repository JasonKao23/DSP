#ifndef IFFT64_SOURCE_HPP
#define IFFT64_SOURCE_HPP

#include <systemc.h>

SC_MODULE(ifft64_source)
{
    sc_in_clk clock;
    sc_out<bool> reset;

    sc_out<int> in_re;
    sc_out<int> in_im;
    sc_out<bool> in_valid;
    sc_in<bool> in_ready;

    SC_CTOR(ifft64_source)
    {
        SC_CTHREAD(entry, clock.pos());
    }

    void entry();
};

#endif  // IFFT64_SOURCE_HPP

