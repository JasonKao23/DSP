#include "vitdec_display.hpp"

void vitdec_display::entry()
{
    if (dec_valid.read()) {
        cout << "Viterbi decoder output" << std::endl;
        cout << "at time " << sc_time_stamp().to_double() << std::endl;
        for (int i = 0; i < 8; ++i) {
            cout << dec_bits[i].read();
            fprintf(fp, "%d\n", dec_bits[i].read());
        }
        cout << std::endl;
    }
}

