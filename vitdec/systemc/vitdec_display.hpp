#ifndef VITDEC_DISPLAY_H
#define VITDEC_DISPLAY_H

#include <systemc.h>

SC_MODULE(vitdec_display)
{
    sc_in_clk clock;
    sc_in<bool> reset;

    sc_in<int> dec_bits[8];
    sc_in<bool> dec_valid;

    FILE *fp;

    SC_CTOR(vitdec_display)
    {
        SC_METHOD(entry);
        dont_initialize();
        sensitive << clock.pos();

        fp = fopen("vitdec_out.txt", "w");
    }

    void entry();
};




#endif // VITDEC_DISPLAY_H
