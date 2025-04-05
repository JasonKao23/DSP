#include "ifft64.hpp"

static int tw_re_table[48] = {
    16384,  16384,  16384,
    16305,  16069,  15679,
    16069,  15137,  13623,
    15679,  13623,  10394,
    15137,  11585,   6270,
    14449,   9102,   1606,
    13623,   6270,  -3196,
    12665,   3196,  -7723,
    11585,      0, -11585,
    10394,  -3196, -14449,
     9102,  -6270, -16069,
     7723,  -9102, -16305,
     6270, -11585, -15137,
     4756, -13623, -12665,
     3196, -15137,  -9102,
     1606, -16069,  -4756
};

static int tw_im_table[48] = {
         0,      0,      0,
      1606,   3196,   4756,
      3196,   6270,   9102,
      4756,   9102,  12665,
      6270,  11585,  15137,
      7723,  13623,  16305,
      9102,  15137,  16069,
     10394,  16069,  14449,
     11585,  16384,  11585,
     12665,  16069,   7723,
     13623,  15137,   3196,
     14449,  13623,  -1606,
     15137,  11585,  -6270,
     15679,   9102, -10394,
     16069,   6270, -13623,
     16305,   3196, -15679
};

// constructor
SC_HAS_PROCESS(ifft64);
ifft64::ifft64(sc_module_name nm)
    : sc_module(nm)
{
    SC_METHOD(entry);
    dont_initialize();
    sensitive << clock.pos();

    char buffer[256];
    sprintf(buffer, "%s_bfly_inst", name());
    bfly_inst = new bfly(buffer);
    bfly_inst->clock(clock);
    bfly_inst->reset(reset);
    bfly_inst->in_re(bfly_in_re);
    bfly_inst->in_im(bfly_in_im);
    bfly_inst->w_re(bfly_w_re[3]);
    bfly_inst->w_im(bfly_w_im[3]);
    bfly_inst->start(bfly_start[2]);
    bfly_inst->out_re(bfly_out_re);
    bfly_inst->out_im(bfly_out_im);
    bfly_inst->out_valid(bfly_out_valid);

    for (int i = 0; i < 48; ++i) {
        tw_re[i].write(tw_re_table[i]);
        tw_im[i].write(tw_im_table[i]);
    }

    // tracefile
    sprintf(buffer, "%s_wave", name());
    tracefile = sc_create_vcd_trace_file(buffer);
    sc_trace(tracefile, clock, "clock");
    sc_trace(tracefile, reset, "reset");
    sc_trace(tracefile, in_re, "in_re");
    sc_trace(tracefile, in_im, "in_im");
    sc_trace(tracefile, in_valid, "in_valid");
    sc_trace(tracefile, in_ready, "in_ready");
    sc_trace(tracefile, out_re, "out_re");
    sc_trace(tracefile, out_im, "out_im");
    sc_trace(tracefile, out_valid, "out_valid");
    sc_trace(tracefile, out_ready, "out_ready");

    sc_trace(tracefile, input_done, "input_done");
    sc_trace(tracefile, input_counter, "input_counter");
    sc_trace(tracefile, proc_counter, "proc_counter");
    sc_trace(tracefile, output_ready, "output_ready");
    sc_trace(tracefile, output_counter, "output_counter");
    sc_trace(tracefile, output_done, "output_done");
    sc_trace(tracefile, out_valid_reg, "out_valid_reg");

    sc_trace(tracefile, bfly_in_re, "bfly_in_re");
    sc_trace(tracefile, bfly_in_im, "bfly_in_im");
    sc_trace(tracefile, bfly_w_addr, "bfly_w_addr");
    for (int i = 0; i != sizeof(bfly_w_re)/sizeof(bfly_w_re[0]); ++i) {
        sc_trace(tracefile, bfly_w_re[i], "bfly_w_re(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(bfly_w_im)/sizeof(bfly_w_im[0]); ++i) {
        sc_trace(tracefile, bfly_w_im[i], "bfly_w_im(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(bfly_start)/sizeof(bfly_start[0]); ++i) {
        sc_trace(tracefile, bfly_start[i], "bfly_start(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, bfly_out_re, "bfly_out_re");
    sc_trace(tracefile, bfly_out_im, "bfly_out_im");
    sc_trace(tracefile, bfly_out_valid, "bfly_out_valid");
    for (int i = 0; i != sizeof(rdaddr)/sizeof(rdaddr[0]); ++i) {
        sc_trace(tracefile, rdaddr[i], "rdaddr(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, rdaddr_valid, "rdaddr_valid");
    sc_trace(tracefile, ramsel, "ramsel");
    sc_trace(tracefile, wen, "wen");
    sc_trace(tracefile, waddr, "waddr");
    sc_trace(tracefile, wdata_re, "wdata_re");
    sc_trace(tracefile, wdata_im, "wdata_im");
    sc_trace(tracefile, rdata_re, "rdata_re");
    sc_trace(tracefile, rdata_im, "rdata_im");
    sc_trace(tracefile, wout_en, "wout_en");
    sc_trace(tracefile, wout_waddr, "wout_waddr");
    sc_trace(tracefile, wout_raddr, "wout_raddr");
    sc_trace(tracefile, wout_wdata_re, "wout_wdata_re");
    sc_trace(tracefile, wout_wdata_im, "wout_wdata_im");
    for (int i = 0; i != sizeof(databuf_re)/sizeof(databuf_re[0]); ++i) {
        sc_trace(tracefile, databuf_re[i], "databuf_re(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(databuf_im)/sizeof(databuf_im[0]); ++i) {
        sc_trace(tracefile, databuf_im[i], "databuf_im(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(outbuf_re)/sizeof(outbuf_re[0]); ++i) {
        sc_trace(tracefile, outbuf_re[i], "outbuf_re(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(outbuf_im)/sizeof(outbuf_im[0]); ++i) {
        sc_trace(tracefile, outbuf_im[i], "outbuf_im(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(tw_re)/sizeof(tw_re[0]); ++i) {
        sc_trace(tracefile, tw_re[i], "tw_re(" + std::to_string(i) + ")");
    }
    for (int i = 0; i != sizeof(tw_im)/sizeof(tw_im[0]); ++i) {
        sc_trace(tracefile, tw_im[i], "tw_im(" + std::to_string(i) + ")");
    }

    sc_trace(tracefile, state1, "state1");
}

ifft64::~ifft64()
{
    sc_close_vcd_trace_file(tracefile);
}

void ifft64::entry()
{
    state1 = state.read();  // used simply for tracing, TODO: delete

    if (reset.read() == true) {
        // reset behavior
        state.write(s_inout);
        input_done.write(false);
        output_done.write(true);
    }
    else {
        // state update
        switch (state.read()) {
            case s_inout:
                if (input_done.read() && output_done.read())
                    state.write(s_proc_stage1);
                else
                    state.write(s_inout);
                break;
            case s_proc_stage1:
                if ((proc_counter.read() & 0x3F) == 63) {
                    state.write(s_proc_stage2);
                }
                else {
                    state.write(s_proc_stage1);
                }
                break;
            case s_proc_stage2:
                if ((proc_counter.read() & 0x3F) == 63) {
                    state.write(s_proc_stage3);
                }
                else {
                    state.write(s_proc_stage2);
                }
                break;
            case s_proc_stage3:
                if ((proc_counter.read() & 0x7F) == 77) {
                    state.write(s_inout);
                }
                else {
                    state.write(s_proc_stage3);
                }
                break;
            default:
                state.write(s_inout);
                break;
        }
        // cout << "state " << state.read() << "\n";

        // input counter
        if (state.read() == s_inout) {
            if ((in_valid.read() == true) && (!input_done.read())) {
                input_counter.write((input_counter.read()+1) & 0x3F);
            }
            else {
                input_counter.write(input_counter.read());
            }
        }
        else {
            input_counter.write(0);
        }

        // input done flag
        if (state.read() != s_inout) {
            input_done.write(false);
        }
        else if ((input_counter.read() == 63) && in_valid.read()) {
            input_done.write(true);
        }
        else {
            input_done.write(input_done.read());
        }

        // process counter
        if ((state.read() == s_proc_stage1) ||
            (state.read() == s_proc_stage2) ||
            (state.read() == s_proc_stage3))
        {
            proc_counter.write((proc_counter.read() + 1) % 16);
        }
        else {
            proc_counter.write(0);
        }

        // input ready
        bool rdyn = (state.read() != s_inout)
                 || input_done.read()
                 || ((input_counter.read() == 63) && in_valid.read());
        in_ready.write(!rdyn);

        // process counter
        if (state.read() != s_inout) {
            proc_counter.write((proc_counter.read() + 1) & 0x7F);
        }
        else {
            proc_counter.write(0);
        }

        // output ready
        if ((state.read() == s_proc_stage3) && (proc_counter.read() == 77)) {
            output_ready.write(true);
        }
        else if((state == s_inout) && !output_done.read()) {
            output_ready.write(output_ready.read());
        }
        else {
            output_ready.write(false);
        }

        // output counter
        if (state.read() == s_inout) {
            if (out_ready.read() && (!output_done.read())) {
                output_counter.write((output_counter.read() + 1) & 0x7F);
            }
            else {
                output_counter.write(output_counter.read());
            }
        }
        else {
            // output CP first
            output_counter.write(48);
        }

        // output done
        if (state.read() == s_inout) {
            if (((output_counter.read() & 0x7F) == 127) && out_ready.read()) {
                output_done.write(true);
            }
            else {
                output_done.write(output_done.read());
            }
        }
        else {
            output_done.write(false);
        }

        // data ram read address
        rdaddr_valid.write((rdaddr_valid.read() << 1)
                         | ((state.read() != s_inout) && ((proc_counter.read() & 0x3) == 0)));
        switch (state.read()) {
            case s_proc_stage1:
                rdaddr[0].write(((proc_counter.read() & 0x3) << 4)
                              + (proc_counter.read() >> 2));
                break;
            case s_proc_stage2:
                rdaddr[0].write((proc_counter.read() & 0x30)
                              + ((proc_counter.read() & 0x3) << 2)
                              + ((proc_counter.read() >> 2) & 0x3));
                break;
            case s_proc_stage3:
                rdaddr[0].write(proc_counter.read() & 0x3F);
                break;
            default:
                rdaddr[0].write(0);
                break;
        }
        for (int i = 1; i != sizeof(rdaddr)/sizeof(rdaddr[0]); ++i) {
            rdaddr[i].write(rdaddr[i-1].read());
        }

        // data RAM write address
        waddr.write((state.read() == s_inout) ? input_counter.read() : rdaddr[13].read());

        // data RAM write enable
        if (state.read() == s_inout) {
            wen.write(!input_done.read() && in_valid.read());
        }
        else if (~((ramsel & 0x1) & ((ramsel >> 13) & 0x1))) {
            wen.write(((rdaddr_valid.read() >> 13) & 0xF) != 0);
        }
        else {
            wen.write(false);
        }

        // data RAM write data
        if (state.read() == s_inout) {
            wdata_re.write(in_re.read());
            wdata_im.write(in_im.read());
        }
        else {
            wdata_re.write(bfly_out_re.read());
            wdata_im.write(bfly_out_im.read());
        }

        // data RAM read/write
        rdata_re.write(databuf_re[rdaddr[0].read()]);
        rdata_im.write(databuf_im[rdaddr[0].read()]);
        if (wen.read()) {
            databuf_re[waddr.read()].write(wdata_re.read());
            databuf_im[waddr.read()].write(wdata_im.read());
        }

        // select output RAM
        ramsel.write((ramsel.read() << 1) | (state.read() == s_proc_stage3));

        // output RAM write enable, address and data
        wout_en.write((ramsel & 0x1) & ((ramsel >> 14) & 0x1));
        if ((ramsel >> 14) & 0x1) {
            wout_waddr.write(waddr.read());
            wout_wdata_re.write(wdata_re.read());
            wout_wdata_im.write(wdata_im.read());
        }
        else {
            wout_waddr.write(0);
            wout_wdata_re.write(0);
            wout_wdata_im.write(0);
        }

        wout_raddr.write(
            ((output_counter & 0x3) << 4)
          | (((output_counter >> 2) & 0x3) << 2)
          | ((output_counter >> 4) & 0x3)
        );

        // output RAM read and write
        out_re.write(outbuf_re[wout_raddr.read()]);
        out_im.write(outbuf_im[wout_raddr.read()]);
        if (wout_en.read()) {
            outbuf_re[wout_waddr.read()].write(wout_wdata_re);
            outbuf_im[wout_waddr.read()].write(wout_wdata_im);
        }
        out_valid_reg.write((output_ready.read() & (!output_done.read())));
        out_valid.write(out_valid_reg.read());

        // bufferfly input data
        bfly_in_re.write(rdata_re.read());
        bfly_in_im.write(rdata_im.read());

        // read twiddle factor
        switch (state.read()) {
            case s_proc_stage1:
                bfly_w_addr.write(
                    (((proc_counter.read() >> 2) & 0xF) << 1)
                  + ((proc_counter.read() >> 2) & 0xF)
                  + (proc_counter.read() & 0x3)
                );
                break;
            case s_proc_stage2:
                bfly_w_addr.write(
                    (((proc_counter.read() >> 2) & 0x3) << 3)
                  + (((proc_counter.read() >> 2) & 0x3) << 2)
                  + (proc_counter.read() & 0x3)
                );
                break;
            default:
                bfly_w_addr.write(0);
        }
        bfly_w_re[0].write(tw_re[bfly_w_addr.read() % 48]);
        bfly_w_im[0].write(tw_im[bfly_w_addr.read() % 48]);
        for (int i = 1; i != sizeof(bfly_w_re)/sizeof(bfly_w_re[0]); ++i) {
            bfly_w_re[i].write(bfly_w_re[i-1].read());
            bfly_w_im[i].write(bfly_w_im[i-1].read());
        }
        // bufferfly start indicator
        bfly_start[0].write((state.read() != s_inout) & ((proc_counter & 0x3) == 0));
        for (int i = 1; i != sizeof(bfly_start)/sizeof(bfly_start[0]); ++i) {
            bfly_start[i].write(bfly_start[i-1].read());
        }
    }
}










