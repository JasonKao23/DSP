#include "ifft64_display.hpp"

void ifft64_display::entry()
{
    int re;
    int im;
    bool valid;

    out_ready.write(true);

    re = out_re.read();
    im = out_im.read();
    valid = out_valid.read();

    if (valid) {
        fprintf(fout, "%d, %d\n", re, im);

        if ((ref_re[out_counter] != re) || (ref_im[out_counter] != im)) {
            cout << "Error: ";
            cout << "Expected: " << ref_re[out_counter]  << " " << ref_im[out_counter]  << " ";
            cout << "Received: " << re << " " << im << " ";
            cout << " at time " << sc_time_stamp().to_double() << endl;
        }
        ++out_counter;
    }
}

