#include <systemc.h>
#include "cmul.hpp"
#include "bfly.hpp"
#include "ifft64.hpp"
#include "ifft64_source.hpp"
#include "ifft64_display.hpp"

int sc_main(int, char *[])
{
    sc_set_time_resolution(10, SC_PS);

    sc_clock         clock{"clock", 10, SC_NS};
    sc_signal<bool>  reset;

    sc_signal<int> in_re;
    sc_signal<int> in_im;
    sc_signal<bool> in_valid;
    sc_signal<bool> in_ready;

    sc_signal<int> out_re;
    sc_signal<int> out_im;
    sc_signal<bool> out_valid;
    sc_signal<bool> out_ready;

    ifft64_source source_inst("ifft64_source_block");
    source_inst.clock(clock);
    source_inst.reset(reset);
    source_inst.in_re(in_re);
    source_inst.in_im(in_im);
    source_inst.in_valid(in_valid);
    source_inst.in_ready(in_ready);

    ifft64 ifft64_inst("ifft64_inst");
    ifft64_inst.clock(clock);
    ifft64_inst.reset(reset);
    ifft64_inst.in_re(in_re);
    ifft64_inst.in_im(in_im);
    ifft64_inst.in_valid(in_valid);
    ifft64_inst.in_ready(in_ready);
    ifft64_inst.out_re(out_re);
    ifft64_inst.out_im(out_im);
    ifft64_inst.out_valid(out_valid);
    ifft64_inst.out_ready(out_ready);

    ifft64_display display_inst("fft64_display_block");
    display_inst.clock(clock);
    display_inst.reset(reset);
    display_inst.out_re(out_re);
    display_inst.out_im(out_im);
    display_inst.out_valid(out_valid);
    display_inst.out_ready(out_ready);

    in_ready.write(true);
    sc_start();

    return 0;
}



