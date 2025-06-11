#include "ifft64_source.hpp"

void ifft64_source::entry()
{
    FILE *fp;
    int re, im;

    fp = fopen("ifft64_in_sample.txt", "r");

    wait(2);

    // reset
    reset.write(true);
    in_re.write(0);
    in_im.write(0);
    in_valid.write(false);
    wait(2);
    reset.write(false);
    wait();

    // main loop
    while (true) {
        if ((fscanf(fp, "%d, %d", &re, &im) == EOF))
        {
            in_re.write(0);
            in_im.write(0);
            in_valid.write(false);
            cout << "End of stimulus stream" << endl;
            break;
        }

        reset.write(false);
        in_re.write(re);
        in_im.write(im);
        in_valid.write(true);
        wait();
    }

    // wait extra 100 cycles before quit
    wait(300);
    cout << "stop" << endl;
    sc_stop();
}

