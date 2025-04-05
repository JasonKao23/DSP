#include "cmul.hpp"

void cmul::entry()
{
    if (reset.read() == true) {
        in_a_re_delay.write(0);
        in_a_im_delay.write(0);
        in_b_re_delay.write(0);
        in_b_im_delay.write(0);
    }
    else {
        // clock 0
        in_a_re_delay.write(in_a_re.read());
        in_a_im_delay.write(in_a_im.read());
        in_b_re_delay.write(in_b_re.read());
        in_b_im_delay.write(in_b_im.read());

        // clock 1
        delay1[0].write(in_a_re_delay.read() * in_b_re_delay.read());
        delay1[1].write(in_a_im_delay.read() * in_b_im_delay.read());
        delay1[2].write(in_a_re_delay.read() + in_a_im_delay.read());
        delay1[3].write(in_b_re_delay.read() + in_b_im_delay.read());

        // clock 2
        delay2[0].write(delay1[0].read() - delay1[1].read());
        delay2[1].write(delay1[2].read() * delay1[3].read());
        delay2[2].write(delay1[0].read() + delay1[1].read());

        // clock 3
        delay3[0].write(delay2[0].read());
        delay3[1].write(delay2[1].read() - delay2[2].read());

        // clock 4
        out_re.write(delay3[0]);
        out_im.write(delay3[1]);
    }
}
