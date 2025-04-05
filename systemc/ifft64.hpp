#ifndef IFFT64_HPP
#define IFFT64_HPP

#include <systemc.h>
#include "bfly.hpp"

SC_MODULE(ifft64)
{
    sc_in_clk clock;
    sc_in<bool> reset;

    sc_in<int> in_re;
    sc_in<int> in_im;
    sc_in<bool> in_valid;
    sc_out<bool> in_ready;

    sc_out<int> out_re;
    sc_out<int> out_im;
    sc_out<bool> out_valid;
    sc_in<bool> out_ready;

    // define states
    enum state_t {
        s_inout,
        s_proc_stage1,
        s_proc_stage2,
        s_proc_stage3
    };
    sc_signal<state_t> state;

    sc_signal<bool> input_done;
    sc_signal<uint> input_counter;
    sc_signal<uint> proc_counter;
    sc_signal<bool> output_ready;
    sc_signal<uint> output_counter;
    sc_signal<bool> output_done;
    sc_signal<bool> out_valid_reg;

    // butterfuly
    sc_signal<int> bfly_in_re;
    sc_signal<int> bfly_in_im;
    sc_signal<uint> bfly_w_addr;
    sc_signal<int> bfly_w_re[4];
    sc_signal<int> bfly_w_im[4];
    sc_signal<bool> bfly_start[3];
    sc_signal<int> bfly_out_re;
    sc_signal<int> bfly_out_im;
    sc_signal<bool> bfly_out_valid;

    // data RAM
    sc_signal<uint> rdaddr[14];
    sc_signal<uint> rdaddr_valid;
    sc_signal<uint> ramsel;
    sc_signal<bool> wen;
    sc_signal<uint> waddr;
    sc_signal<int> wdata_re;
    sc_signal<int> wdata_im;
    sc_signal<int> rdata_re;
    sc_signal<int> rdata_im;

    // output RAM
    sc_signal<bool> wout_en;
    sc_signal<uint> wout_waddr;
    sc_signal<uint> wout_raddr;
    sc_signal<int> wout_wdata_re;
    sc_signal<int> wout_wdata_im;
   // int out_data;

    // RAM block used for FFT process
    sc_signal<int> databuf_re[64];
    sc_signal<int> databuf_im[64];

    // output RAM block
    sc_signal<int> outbuf_re[64];
    sc_signal<int> outbuf_im[64];

    // Twiddle factor
    sc_signal<int> tw_re[48];
    sc_signal<int> tw_im[48];

    bfly *bfly_inst;

    sc_trace_file *tracefile;

    uint state1;  // TODO: delete, only used for debugging

    SC_CTOR(ifft64);
    ~ifft64();

    void entry();
};

#endif // IFFT64_HPP
