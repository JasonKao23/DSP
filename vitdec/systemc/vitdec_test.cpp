#include <iostream>
#include <systemc.h>
#include "vitdec_source.hpp"
#include "vitdec.hpp"
#include "vitdec_display.hpp"

using namespace std;

int sc_main(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    sc_set_time_resolution(10, SC_PS);

    sc_clock clock{"clock", 10, SC_NS};
    sc_signal<bool> reset;
    sc_signal<bool> restart;

    sc_signal<int> coderate;
    sc_signal<int> ndbps;
    sc_signal<int> nofbits;
    sc_signal<int> sample;
    sc_signal<bool> sample_valid;

    sc_signal<int> dec_bits[8];
    sc_signal<bool> dec_valid;

    vitdec_source source_inst("vitdec_source_block");
    source_inst.clock(clock);
    source_inst.reset(reset);
    source_inst.restart(restart);
    source_inst.coderate(coderate);
    source_inst.ndbps(ndbps);
    source_inst.nofbits(nofbits);
    source_inst.sample(sample);
    source_inst.sample_valid(sample_valid);

    vitdec vitdec_inst("vitdec_block");
    vitdec_inst.clock(clock);
    vitdec_inst.reset(reset);
    vitdec_inst.restart(restart);
    vitdec_inst.coderate(coderate);
    vitdec_inst.ndbps(ndbps);
    vitdec_inst.nofbits(nofbits);
    vitdec_inst.in_data(sample);
    vitdec_inst.in_valid(sample_valid);
    for (int i = 0; i < 8; ++i) {
        vitdec_inst.dec_bits[i](dec_bits[i]);
    }
    vitdec_inst.dec_valid(dec_valid);

    vitdec_display display_inst("vitdec_display_block");
    display_inst.clock(clock);
    display_inst.reset(reset);
    for (int i = 0; i < 8; ++i) {
        display_inst.dec_bits[i](dec_bits[i]);
    }
    display_inst.dec_valid(dec_valid);

    sc_start();

    return 0;
}
