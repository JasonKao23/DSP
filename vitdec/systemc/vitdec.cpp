#include "vitdec.hpp"

const int vitdec::stout[64] = {
    0, 2, 0, 2, 3, 1, 3, 1,
    3, 1, 3, 1, 0, 2, 0, 2,
    1, 3, 1, 3, 2, 0, 2, 0,
    2, 0, 2, 0, 1, 3, 1, 3,
    3, 1, 3, 1, 0, 2, 0, 2,
    0, 2, 0, 2, 3, 1, 3, 1,
    2, 0, 2, 0, 1, 3, 1, 3, 
    1, 3, 1, 3, 2, 0, 2, 0
};

// Constructor
SC_HAS_PROCESS(vitdec);
vitdec::vitdec(sc_module_name nm)
    : sc_module(nm)
{
    SC_METHOD(entry);
    dont_initialize();
    sensitive << clock.pos();

    // tracefile
    char buffer[50];
    sprintf(buffer, "%s_wave", name());
    tracefile = sc_create_vcd_trace_file(buffer);
    sc_trace(tracefile, clock, "clock");
    sc_trace(tracefile, reset, "reset");

    sc_trace(tracefile, coderate, "coderate");
    sc_trace(tracefile, ndbps, "ndbps");
    sc_trace(tracefile, nofbits, "nofbits");
    sc_trace(tracefile, in_data, "in_data");
    sc_trace(tracefile, in_valid, "in_valid");
    for (int i = 0; i < 8; ++i) {
        sc_trace(tracefile, dec_bits[i], "dec_bits(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, dec_valid, "dec_valid");

    sc_trace(tracefile, phlen, "phlen");
    sc_trace(tracefile, winstep, "winstep");

    sc_trace(tracefile, in_data_delay, "in_data_delay");
    sc_trace(tracefile, in_cnt0, "in_cnt0");
    sc_trace(tracefile, in_cnt1, "in_cnt1");
    sc_trace(tracefile, vitin_valid, "vitin_valid");
    sc_trace(tracefile, bm_valid, "bm_valid");
    sc_trace(tracefile, vitin[0], "vitin(0)");
    sc_trace(tracefile, vitin[1], "vitin(1)");

    sc_trace(tracefile, in_cnt, "in_cnt");
    for (int i = 0; i < 4; ++i) {
        sc_trace(tracefile, bm[i], "bm(" + std::to_string(i) + ")");
    }

    sc_trace(tracefile, phind, "phind");
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 64; j++) {
            sc_trace(tracefile, pm[i][j], "pm(" + std::to_string(i) + ")(" +
                    std::to_string(j) + ")");
        }
    }
    for (int i = 0; i < winlen; i++) {
        for (int j = 0; j < 64; j++) {
            sc_trace(tracefile, ph[i][j], "ph(" + std::to_string(i) + ")(" +
                    std::to_string(j) + ")");
        }
    }

    sc_trace(tracefile, tb_running, "tb_running");
    sc_trace(tracefile, tb_start_idx, "tb_start_idx");
    sc_trace(tracefile, tb_cnt, "tb_cnt");
    sc_trace(tracefile, tb_pos, "tb_pos");
    sc_trace(tracefile, tb_st, "tb_st");
    sc_trace(tracefile, tb_last, "tb_last");
    sc_trace(tracefile, outbit, "outbit");

    sc_trace(tracefile, out_enable, "out_enable");
    sc_trace(tracefile, out_nbits, "out_nbits");
    sc_trace(tracefile, out_cnt, "out_cnt");
    for (unsigned int i = 0; i < sizeof(out_buf)/sizeof(out_buf[0]); ++i) {
        sc_trace(tracefile, out_buf[i], "out_buf(" + std::to_string(i) + ")");
    }
    sc_trace(tracefile, out_valid, "out_valid");

    sc_trace(tracefile, cnt, "cnt");
}


vitdec::~vitdec()
{
    sc_close_vcd_trace_file(tracefile);
}

void vitdec::entry()
{
    if (reset.read()) {
        in_cnt0.write(0);
        in_cnt1.write(1);
        in_cnt.write(0);

        phlen.write(ndbps.read()+tblen);
        winstep.write(ndbps.read());

        if (nofbits.read() <= winlen) {
            tb_start_idx.write(4096);
        }
        else {
            tb_start_idx.write(ndbps.read()+tblen);
        }
        
        tb_running.write(false);
        out_enable.write(false);
    }
    else {
        cnt.write(cnt.read() + 1);

        if (in_valid.read()) {
            // de-puncture
            in_data_delay.write(in_data.read());

            in_cnt0.write((in_cnt0.read() + 1) & 0x3);
            if (in_cnt1.read() == 2) {
                in_cnt1.write(0);
            }
            else {
                in_cnt1.write(in_cnt1.read() + 1);
            }

            switch (coderate) {
                case 0: // cordate: 1/2
                    if ((in_cnt0 & 0x1) == 1) {
                        vitin_valid.write(true);
                        vitin[0].write(in_data_delay.read());
                        vitin[1].write(in_data);
                    }
                    else {
                        vitin_valid.write(false);
                        vitin[0].write(0);
                        vitin[1].write(0);
                    }
                    break;

                case 1: // coderate: 2/3
                    switch (in_cnt1) {
                        case 1:
                            vitin_valid.write(true);
                            vitin[0].write(in_data_delay.read());
                            vitin[1].write(in_data);
                            break;
                        case 2:
                            vitin_valid.write(true);
                            vitin[0].write(in_data.read());
                            vitin[1].write(0);
                            break;
                        default:
                            vitin_valid.write(false);
                            vitin[0].write(0);
                            vitin[1].write(0);
                            break;
                    }
                    break;

                case 2: // coderate: 3/4
                    switch (in_cnt0) {
                        case 1:
                            vitin_valid.write(true);
                            vitin[0].write(in_data_delay.read());
                            vitin[1].write(in_data);
                            break;
                        case 2:
                            vitin_valid.write(true);
                            vitin[0].write(in_data.read());
                            vitin[1].write(0);
                            break;
                        case 3:
                            vitin_valid.write(true);
                            vitin[0].write(0); 
                            vitin[1].write(in_data.read());
                            break;
                        default:
                            vitin_valid.write(false);
                            vitin[0].write(0);
                            vitin[1].write(0);
                            break;
                    }
                    break;

                default:
                    vitin_valid.write(false);
                    vitin[0].write(0);
                    vitin[1].write(0);
                    break;
            }
        }
        else {
            vitin_valid.write(false);
            vitin[0].write(0);
            vitin[1].write(0);
        }
        bm_valid.write(vitin_valid);

        // calculate branch metric 
        if (vitin_valid.read()) {
            bm[0].write(-vitin[0].read() - vitin[1].read());
            bm[1].write(-vitin[0].read() + vitin[1].read());
            bm[2].write( vitin[0].read() - vitin[1].read());
            bm[3].write( vitin[0].read() + vitin[1].read());
        }

        // ACS
        if (bm_valid.read()) {
            for (int st = 0; st < 64; ++st) {
                // two prevous states
                int prest0 = st*2 % 64;
                int prest1 = st*2 % 64 + 1;

                // path metrix
                int idx = stout[st];
                int v = bm[idx].read();

                // addition
                int idx0 = in_cnt.read() % 2;
                int idx1 = (in_cnt.read() + 1) % 2;
                int t0 = pm[idx0][prest0].read() + v;
                int t1 = pm[idx0][prest1].read() - v;

                // compare
                t0 %= 8192;
                t1 %= 8192;
                unsigned int d = (unsigned int) (t0 - t1);
                d &= 0x1FFF;
                if (d < 4096) {
                    ph[phind][st].write(0);
                    pm[idx1][st].write(t0);
                }
                else {
                    ph[phind][st].write(1);
                    pm[idx1][st].write(t1);
                }
            }
            in_cnt.write(in_cnt.read() + 1);
            if (phind.read() == winlen - 1) {
                phind.write(0);
            }
            else {
                phind.write(phind.read() + 1);
            }
        }
        in_cnt_delay.write(in_cnt.read());
        phind_delay.write(phind.read());
        
        // traceback
        if (tb_running.read() == false) {
            if (in_cnt_delay.read() == tb_start_idx.read() - 1) {
                tb_cnt.write(phlen);
                
                if (out_cnt.read() + winstep.read() + winlen >= nofbits.read()) {
                    tb_start_idx.write(4096);
                }
                else {
                    tb_start_idx.write(tb_start_idx.read() + winstep);
                }
                tb_pos.write(phind_delay.read());
                tb_st.write(0);
                out_nbits.write(winstep.read());
                tb_last.write(false);
                tb_running.write(true);
            }
            else if (in_cnt_delay.read() == nofbits.read() - 1) {
                if (nofbits.read() <= phlen) {
                    tb_cnt.write(nofbits.read());
                    out_nbits.write(nofbits.read());
                }
                else {
                    tb_cnt.write(nofbits.read() - out_cnt.read());
                    out_nbits.write(nofbits.read() - out_cnt.read());
                }
                tb_pos.write(phind_delay.read());
                tb_st.write(0);
                tb_last.write(true);
                tb_running.write(true);
            }
        }
        else {
            if (tb_st.read() < 32) {
                outbit.write(0);
                tb_st.write((tb_st.read()*2 + ph[tb_pos.read()][tb_st.read()])&0x3F);
            }
            else {
                outbit.write(1);
                tb_st.write(((tb_st.read()-32)*2 + ph[tb_pos.read()][tb_st.read()])&0x3F);
            }

            if (tb_last.read() || (tb_cnt.read() <= winstep)) {
                out_buf[0].write(outbit.read());
                for (unsigned int i = 1; i < sizeof(out_buf)/sizeof(out_buf[0]); ++i) {
                    out_buf[i].write(out_buf[i-1].read());
                }
            }

            // check taceback complete?
            if (tb_cnt.read() == 0) {
                tb_running.write(false);
                out_enable.write(true);
            }
            else {
                if (tb_pos.read() == 0) {
                    tb_pos.write(winlen-1);
                }
                else {
                    tb_pos.write(tb_pos.read() - 1);
                }
                tb_cnt.write(tb_cnt.read() - 1);
            }
        }	// traceback

        // output
        if (out_enable.read()) {
            for (int i = 0; i < 8; ++i) {
                dec_bits[i].write(out_buf[i].read());
            }
            dec_valid.write(true);
            for (unsigned int i = 0; i < sizeof(out_buf)/sizeof(out_buf[0])-8; ++i) {
                out_buf[i].write(out_buf[i+8].read());
            }
            if ((out_nbits.read() >> 3) == 1) {
                out_enable.write(false);
            }
            else {
                out_nbits.write(out_nbits.read() - 8);
            }
            out_cnt.write(out_cnt.read() + 8);
        }
        else {
            for (int i = 0; i < 8; ++i) {
                dec_bits[i].write(0);
            }
            dec_valid.write(false);
        }
    } // reset
}

