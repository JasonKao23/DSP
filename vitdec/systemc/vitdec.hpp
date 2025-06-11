#ifndef VITDEC_H
#define VITDEC_H

#include <systemc.h>


SC_MODULE(vitdec)
{
    sc_in_clk clock;
    sc_in<bool> reset;

    sc_in<int> coderate;    // code rate
    sc_in<int> ndbps;       // NDBPS
    sc_in<int> nofbits;     // number of bits

    sc_in<int> in_data;
    sc_in<bool> in_valid;
    sc_out<int> dec_bits[8];
    sc_out<bool> dec_valid;

    static const int max_ndbps = 216;
    static const int tblen = 48;
    static const int winlen = 216*3 + 6;
    static const int stout[64]; 

    sc_signal<int> phlen;
    sc_signal<int> winstep;

    sc_signal<int> in_data_delay;
    sc_signal<int> in_cnt0;
    sc_signal<int> in_cnt1;
    sc_signal<bool> vitin_valid;
    sc_signal<int> vitin[2];

    sc_signal<int> in_cnt;
    sc_signal<int> in_cnt_delay;
    sc_signal<int> bm[4];
    sc_signal<bool> bm_valid;

    // ACS
    sc_signal<int> phind;
    sc_signal<int> phind_delay;
    sc_signal<int> pm[2][64];
    sc_signal<int> ph[winlen][64];

    // traceback
    sc_signal<bool> tb_running;
    sc_signal<int> tb_start_idx; // position to start traceback
    sc_signal<int> tb_cnt;
    sc_signal<int> tb_pos;
    sc_signal<int> tb_st;
    sc_signal<bool> tb_last;
    sc_signal<int> outbit;

    // output
    sc_signal<bool> out_enable;
    sc_signal<int> out_nbits;
    sc_signal<int> out_cnt;
    sc_signal<int> out_buf[winlen];
    sc_signal<bool> out_valid;

    sc_signal<unsigned int> cnt;    // for debug only
    sc_trace_file *tracefile;

    SC_CTOR(vitdec);
    ~vitdec();

    void entry();
};


#endif // VITDEC_H
    
