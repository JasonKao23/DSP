#ifndef VITDEC_SOURCE_H 
#define VITDEC_SOURCE_H

#include <systemc.h>

SC_MODULE(vitdec_source)
{
    sc_in_clk clock;
    sc_out<bool> reset;
    sc_out<bool> restart;

    sc_out<int> coderate;
    sc_out<int> nofbits;
    sc_out<int> ndbps;
    sc_out<int> sample;
    sc_out<bool> sample_valid;


    SC_CTOR(vitdec_source)
    {
        SC_CTHREAD(entry, clock.pos());
    }

    void entry();
};




#endif // VITDEC_SOURCE_H

