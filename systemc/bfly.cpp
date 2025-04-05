#include "bfly.hpp"

SC_HAS_PROCESS(bfly);
bfly::bfly(sc_module_name nm)
    : sc_module(nm)
{
    SC_METHOD(entry);
    dont_initialize();
    sensitive << clock.pos();

    char buffer[256];
    sprintf(buffer, "%s_cmul_inst", name());
    cmul_inst = new cmul(buffer);
    cmul_inst->clock(clock);
    cmul_inst->reset(reset);
    cmul_inst->in_a_re(in_b_re);
    cmul_inst->in_a_im(in_b_im);
    cmul_inst->in_b_re(in_a_re);
    cmul_inst->in_b_im(in_a_im);
    cmul_inst->out_re(out_c_re);
    cmul_inst->out_im(out_c_im);

    // tracefile
    sprintf(buffer, "%s_wave", name());
    tracefile = sc_create_vcd_trace_file(buffer);
    sc_trace(tracefile, clock, "clock");
    sc_trace(tracefile, reset, "reset");
    sc_trace(tracefile, in_re, "in_re");
    sc_trace(tracefile, in_im, "in_im");
    sc_trace(tracefile, w_re, "w_re");
    sc_trace(tracefile, w_im, "w_im");
    sc_trace(tracefile, start, "start");
    sc_trace(tracefile, out_re, "out_re");
    sc_trace(tracefile, out_im, "out_im");
    sc_trace(tracefile, out_valid, "out_valid");
    sc_trace(tracefile, stage, "stage");
    sc_trace(tracefile, valid, "valid");
    sc_trace(tracefile, in_re_delay, "in_re_delay");
    sc_trace(tracefile, in_im_delay, "in_im_delay");
    sc_trace(tracefile, u0_re, "u0_re");
    sc_trace(tracefile, u0_im, "u0_im");
    sc_trace(tracefile, u1_re, "u1_re");
    sc_trace(tracefile, u1_im, "u1_im");
    sc_trace(tracefile, u2_re, "u2_re");
    sc_trace(tracefile, u2_im, "u2_im");
    sc_trace(tracefile, u3_re, "u3_re");
    sc_trace(tracefile, u3_im, "u3_im");
    for (int i = 0; i != sizeof(u0_re_delay)/sizeof(u0_re_delay[0]); ++i) {
        sc_trace(tracefile, u0_re_delay[i], "u0_re_delay(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(u0_im_delay)/sizeof(u0_im_delay[0]); ++i) {
        sc_trace(tracefile, u0_im_delay[i], "u0_im_delay(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, u2_re_delay, "u2_re_delay");
    sc_trace(tracefile, u2_im_delay, "u2_im_delay");
    for (int i = 0; i != sizeof(u3_re_delay)/sizeof(u3_re_delay[0]); ++i) {
        sc_trace(tracefile, u3_re_delay[i], "u3_re_delay(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(u3_im_delay)/sizeof(u3_im_delay[0]); ++i) {
        sc_trace(tracefile, u3_im_delay[i], "u3_im_delay(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, in_a_re, "in_a_re");
    sc_trace(tracefile, in_a_im, "in_a_im");
    sc_trace(tracefile, in_b_re, "in_b_re");
    sc_trace(tracefile, in_b_im, "in_b_im");
    sc_trace(tracefile, out_c_re, "out_c_re");
    sc_trace(tracefile, out_c_im, "out_c_im");
}

bfly::~bfly()
{
    sc_close_vcd_trace_file(tracefile);
}

void bfly::entry()
{
    if (reset.read() == true) {
        valid.write(0);
    }
    else {
        valid.write(((valid.read() << 1) + start.read()) & 0x3FF);

        if (start)
            stage.write(0);
        else
            stage.write(stage.read() + 1);

        in_re_delay.write(in_re.read());
        in_im_delay.write(in_im.read());

        switch (stage.read()&0x3) {
            case 0:
                u0_re.write(in_re_delay.read());
                u0_im.write(in_im_delay.read());
                u1_re.write(in_re_delay.read());
                u1_im.write(in_im_delay.read());
                u2_re.write(in_re_delay.read());
                u2_im.write(in_im_delay.read());
                u3_re.write(in_re_delay.read());
                u3_im.write(in_im_delay.read());
                break;
            case 1:
                u0_re.write(u0_re.read() + in_re_delay.read());
                u0_im.write(u0_im.read() + in_im_delay.read());
                u1_re.write(u1_re.read() - in_im_delay.read());
                u1_im.write(u1_im.read() + in_re_delay.read());
                u2_re.write(u2_re.read() - in_re_delay.read());
                u2_im.write(u2_im.read() - in_im_delay.read());
                u3_re.write(u3_re.read() + in_im_delay.read());
                u3_im.write(u3_im.read() - in_re_delay.read());
                break;
            case 2:
                u0_re.write(u0_re.read() + in_re_delay.read());
                u0_im.write(u0_im.read() + in_im_delay.read());
                u1_re.write(u1_re.read() - in_re_delay.read());
                u1_im.write(u1_im.read() - in_im_delay.read());
                u2_re.write(u2_re.read() + in_re_delay.read());
                u2_im.write(u2_im.read() + in_im_delay.read());
                u3_re.write(u3_re.read() - in_re_delay.read());
                u3_im.write(u3_im.read() - in_im_delay.read());
                break;
            default: // 3
                u0_re.write(u0_re.read() + in_re_delay.read());
                u0_im.write(u0_im.read() + in_im_delay.read());
                u1_re.write(u1_re.read() + in_im_delay.read());
                u1_im.write(u1_im.read() - in_re_delay.read());
                u2_re.write(u2_re.read() - in_re_delay.read());
                u2_im.write(u2_im.read() - in_im_delay.read());
                u3_re.write(u3_re.read() - in_im_delay.read());
                u3_im.write(u3_im.read() + in_re_delay.read());
                break;
        }

        u0_re_delay[0].write(u0_re.read());
        u0_im_delay[0].write(u0_im.read());
        for (int i = 1; i != 5; ++i) {
            u0_re_delay[i].write(u0_re_delay[i-1]);
            u0_im_delay[i].write(u0_im_delay[i-1]);
        }
        u2_re_delay.write(u2_re.read());
        u2_im_delay.write(u2_im.read());
        u3_re_delay[0].write(u3_re);
        u3_im_delay[0].write(u3_im);
        u3_re_delay[1].write(u3_re_delay[0]);
        u3_im_delay[1].write(u3_im_delay[0]);

        w_re_delay[0].write(w_re.read());
        w_im_delay[0].write(w_im.read());
        for (int i = 1; i != 3; ++i) {
            w_re_delay[i].write(w_re_delay[i-1]);
            w_im_delay[i].write(w_im_delay[i-1]);
        }

        switch (stage&0x3) {
            case 0:
                in_a_re.write(u1_re.read());
                in_a_im.write(u1_im.read());
                break;
            case 1:
                in_a_re.write(u2_re_delay.read());
                in_a_im.write(u2_im_delay.read());
                break;
            case 2:
                in_a_re.write(u3_re_delay[1].read());
                in_a_im.write(u3_im_delay[1].read());
                break;
            default: // 3
                in_a_re.write(0);
                in_a_im.write(0);
                break;
        }
    }

    in_b_re.write(w_re_delay[2]);
    in_b_im.write(w_im_delay[2]);

    bool vld = (valid.read() >> 9) & 0x1;
    int re = vld ? u0_re_delay[4].read() : (out_c_re.read() >> 14);
    int im = vld ? u0_im_delay[4].read() : (out_c_im.read() >> 14);
    out_re.write(re);
    out_im.write(im);
    out_valid.write(vld);
}
