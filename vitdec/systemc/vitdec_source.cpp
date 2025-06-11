#include "vitdec_source.hpp"

void vitdec_source::entry()
{
    FILE *fp;
    int s;
    int c;
    int ncbps;

    fp = fopen("vitdec_in_samples.txt", "r");

    wait(2);

    // reset
    ncbps = 288;
    coderate.write(2);
    ndbps.write(216);
    nofbits.write(1038);
    reset.write(true);
    restart.write(false);
    sample.write(0);
    sample_valid.write(false);
    wait(2);
    reset.write(false);
    wait();

    // main loop
    c = 0;
    while (true) {
        if (fscanf(fp, "%d", &s) == EOF)
        {
            sample.write(0);
            sample_valid.write(false);
            cout << "End of stimulus stream" << endl;
            break;
        }

        reset.write(false);
        sample.write(s);
        sample_valid.write(true);
        wait();

        if (c == ncbps - 1) {
            c = 0;
            sample.write(0);
            sample_valid.write(false);
            wait(200);
        }
        else {
            ++c;
        }
    }

    // wait extra 2000 cycles before quit
    wait(700);
    cout << "stop" << endl;
    sc_stop();
    fclose(fp);
}
