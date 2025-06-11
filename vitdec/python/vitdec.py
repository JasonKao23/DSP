# -*- coding: utf-8 -*-
"""
WLAN convoluational Viterbi decoder

@author:
"""
import numpy as np
import matplotlib.pyplot as plt


class ViterbiDecoder:
    """ Viterbi decoder """

    N_STATES = 64   # number of states

    def __init__(self, rate : str, nbits : int, fixpoint : bool):
        """ initialize Viterbi decoder """
        # tre = poly2trellis(7, [133, 171])
        self.stout = np.array([0, 2, 0, 2, 3, 1, 3, 1,
                               3, 1, 3, 1, 0, 2, 0, 2,
                               1, 3, 1, 3, 2, 0, 2, 0,
                               2, 0, 2, 0, 1, 3, 1, 3,
                               3, 1, 3, 1, 0, 2, 0, 2,
                               0, 2, 0, 2, 3, 1, 3, 1,
                               2, 0, 2, 0, 1, 3, 1, 3,
                               1, 3, 1, 3, 2, 0, 2, 0], dtype=np.int8)

        self.rate = rate
        self.nbits = nbits
        self.tblen = 64             # traceback length
        self.winlen = self.tblen*3  # sliding window length
        self.phlen = self.tblen*2   # valid phase history window length
        self.winstep = self.winlen - self.phlen # step size of sliding window
        self.sttbind = self.phlen
        self.fixed = fixpoint

        self.pm = np.zeros((2, self.N_STATES), dtype=float)
        self.ph = np.empty((self.winlen, self.N_STATES), dtype=np.int8)

        self.punccnt = 0
        self.insig = 0.0

        self.incnt = 0
        self.outcnt = 0
        self.phind = 0
        self.outvalid = False
        self.outbufsz = 0
        self.outbuf = np.empty(self.winlen, dtype=np.int8)
        self.outbits = np.array([], dtype=np.int8)

        self.tbstate = 0   # 0: idle, 1: running
        self.tbstart = 0
        self.tbsz = 0
        self.tblastpos = 0
        self.tbcnt = 0
        self.tbpos = 0
        self.tbst = 0
        self.tboutsz = 0


    def proc(self, rxsig):
        """ Viterbi decoding """
        if self.incnt < self.nbits:
            # de-puncture
            vitin_valid = False
            if self.rate == '1/2':
                if self.punccnt == 0:
                    self.insig = rxsig
                    self.punccnt = 1
                else:
                    d0 = self.insig
                    d1 = rxsig
                    self.punccnt = 0
                    vitin_valid = True
            elif self.rate == '2/3':
                if self.punccnt == 0:
                    self.insig = rxsig
                    self.punccnt = 1
                elif self.punccnt == 1:
                    d0 = self.insig
                    d1 = rxsig
                    self.punccnt = 2
                    vitin_valid = True
                elif self.punccnt == 2:
                    d0 = rxsig
                    d1 = 0.0
                    self.punccnt = 0
                    vitin_valid = True
            else:
                # cod rate: 3/4
                if self.punccnt == 0:
                    self.insig = rxsig
                    self.punccnt = 1
                elif self.punccnt == 1:
                    d0 = self.insig
                    d1 = rxsig
                    self.punccnt = 2
                    vitin_valid = True
                elif self.punccnt == 2:
                    d0 = rxsig
                    d1 = 0.0
                    self.punccnt = 3
                    vitin_valid = True
                elif self.punccnt == 3:
                    d0 = 0.0
                    d1 = rxsig
                    self.punccnt = 0
                    vitin_valid = True

            # calculate branch metric
            if vitin_valid:
                bm = self.cal_branch_metric(d0, d1)

            # ACS
            if vitin_valid:
                self.acs_proc(bm)

            # traceback
            if vitin_valid and self.incnt == self.sttbind-1:
                self.tbsz = self.phlen
                self.tblastpos = self.phind
                if (self.sttbind + self.winstep*2 > self.nbits):
                    self.sttbind = 4096
                else:
                    self.sttbind += self.winstep
                self.outbufsz = self.winstep
                self.tbstart = 1
            elif vitin_valid and self.incnt == self.nbits-1:
                if self.nbits <= self.phlen:
                    self.tbsz = self.nbits
                else:
                    self.tbsz = self.nbits - self.outcnt
                self.tblastpos = self.phind
                self.outbufsz = self.tbsz
                self.tbstart = 1

            # update counters
            if vitin_valid:
                self.incnt += 1
                if (self.phind == self.winlen - 1):
                    self.phind = 0
                else:
                    self.phind += 1

        (outbit0, outbit1, tbdone, outsz) = self.traceback()
        self.outbuf = np.hstack(((outbit1, outbit0), self.outbuf[:-2]))
        if tbdone:
            self.outbits = np.hstack((self.outbits, self.outbuf[:outsz]))
            self.outcnt += outsz
            if self.outcnt == self.nbits:
                self.outvalid = True

        return (self.outbits, self.outvalid)


    def cal_branch_metric(self, d0, d1):
        """ input d0 and d1: 8-bit integers
            output bm: 10-bit vector
        """
        bm = np.empty(4, dtype=float)
        bm[0] = -d0 - d1
        bm[1] = -d0 + d1
        bm[2] =  d0 - d1
        bm[3] =  d0 + d1
        return bm


    def acs_proc(self, bm):
        """ input bm: 9-bit vector with size of 4
                  pm0: 13-bit vector with size of 64
            output pm1: 13-bit vector with size of 64
                   ph: 1-bit vector with size of 64
        """
        for st in range(64):
            # ACS
            # two previous states
            prest0 = st*2 % 64
            prest1 = st*2 % 64 + 1

            # path metric
            idx = self.stout[st]
            v = bm[idx]

            # addition
            idx0 = self.incnt % 2
            idx1 = (self.incnt + 1) % 2
            t0 = self.pm[idx0, prest0] + v
            t1 = self.pm[idx0, prest1] - v

            # compare
            if self.fixed:
                t0 = int(t0) % 8192
                t1 = int(t1) % 8192
                d = t0 - t1
                d = d % 8192
                if (d < 4096):
                    self.ph[self.phind, st] = 0
                    self.pm[idx1, st] = t0
                else:
                    self.ph[self.phind, st] = 1
                    self.pm[idx1, st] = t1
            else:
                d = t0 - t1
                if (d >= 0):
                    self.ph[self.phind, st] = 0
                    self.pm[idx1, st] = t0
                else:
                    self.ph[self.phind, st] = 1
                    self.pm[idx1, st] = t1


    def traceback(self):
        """
        input ph: 1-bit matrix with size of 64 * winlen
              nbits: maximum value is winlen
              winlen: constant, current value is 128
              lastpos: maximum is winlen-1
        output outbits: 1-bit vector with size of nbits
        """
        if self.tbstate == 0:
            if self.tbstart:
                self.tbstate = 1
                self.tbstart = 0
                self.tbcnt = self.tbsz
                self.tbpos = self.tblastpos
                self.tbst = 0
                self.tboutsz = self.outbufsz
            outbit0 = 0
            outbit1 = 0
            tbdone = False
            outsz = 0
        else:
            if self.tbst < 16:
                outbit0 = 0
                outbit1 = 0
                st0 = self.tbst*2 + self.ph[self.tbpos, self.tbst]
                self.tbst = st0*2 + self.ph[self.tbpos-1, st0]
            elif self.tbst < 32:
                outbit0 = 0
                outbit1 = 1
                st0 = self.tbst*2 + self.ph[self.tbpos, self.tbst]
                self.tbst = (st0-32)*2 + self.ph[self.tbpos-1, st0]
            elif self.tbst < 48:
                outbit0 = 1
                outbit1 = 0
                st0 = (self.tbst-32)*2 + self.ph[self.tbpos, self.tbst]
                self.tbst = st0*2 + self.ph[self.tbpos-1, st0]
            else:
                outbit0 = 1
                outbit1 = 1
                st0 = (self.tbst-32)*2 + self.ph[self.tbpos, self.tbst]
                self.tbst = (st0-32)*2 + self.ph[self.tbpos-1, st0]

            if self.tbpos == 1:
                self.tbpos = self.winlen - 1
            else:
                self.tbpos -= 2

            self.tbcnt -= 2
            if self.tbcnt == 0:
                tbdone = True
                outsz = self.tboutsz
                self.tbstate = 0
            else:
                tbdone = False
                outsz = 0

        return (outbit0, outbit1, tbdone, outsz)


def conv_enc(sbits, coderate='1/2'):
    """ convolutional encoder """
    regs = np.zeros(6, dtype=np.int8)
    codebits = []
    punc_buf = []
    bitcnt = 0

    # puncturing parameters
    if coderate == '1/2':
        punc_sz = 2
    elif coderate == '2/3':
        punc_sz = 4
    elif coderate == '3/4':
        punc_sz = 6
    else: # coderate == '5/6'
        punc_sz = 10
    punc_pattern = [1, 1, 1, 0, 0, 1, 1, 0, 0, 1]

    # run encoding and puncturing
    for s in sbits:
        # code bits
        aval = s + regs[1] + regs[2] + regs[4] + regs[5]
        bval = s + regs[0] + regs[1] + regs[2] + regs[5]
        punc_buf.append(aval % 2)
        punc_buf.append(bval % 2)

        # update registers
        regs = np.hstack((s, regs[:-1]))

        # puncturing
        bitcnt = bitcnt + 2
        if bitcnt == punc_sz:
            for b, t in zip(punc_buf, punc_pattern[:punc_sz]):
                if t == 1:
                    codebits.append(b)
            bitcnt = 0
            punc_buf.clear()

    # output
    codebit = np.array(codebits, dtype=np.int8)
    return codebit


def sim_performance(coderate, enbo):
    """ Viterbi decoder performance simulation """
    rng = np.random.default_rng()

    # simulation parameters
    nbits = 296
    fixed = True
    niters = 50000
    nerrs = np.zeros(len(ebno), dtype=int)
    for i in range(len(ebno)):
        for _ in range(niters):
            # generate random source bits
            sbits = rng.integers(0, 2, nbits, dtype=np.int8)
            sbits = np.concatenate((sbits, np.zeros(16, dtype=np.int8)))
            # encode source bits
            codebits = conv_enc(sbits, coderate)
            np.savetxt('vitdec_outbits.txt', codebits[np.newaxis,:], delimiter=',', fmt='%d')
            # BPSK modulation
            txsig = 2*codebits - 1

            # AWGN channel
            s = ebno[i] + 10*np.log10(eval(coderate))
            s = 10 ** (-s/20)
            rxsig = txsig + rng.normal(0, s, len(txsig))

            # receiver
            if fixed:
                rxsig = np.floor(rxsig*64)
                rxsig = np.clip(rxsig, -128, 127)
            # Viteri decoder
            vitobj = ViterbiDecoder(coderate, nbits+16, fixed)
            rxsig = np.concatenate((rxsig, np.zeros(600, dtype=float)))
            for sig in rxsig:
                (outbits, outvalid) = vitobj.proc(sig)
                if outvalid:
                    break
            # check output bits
            nerrs[i] += np.sum(np.abs(outbits[:nbits] - sbits[:nbits]))
    ber = nerrs / (nbits * niters)
    print(f"Error count: {nerrs}, bit error rate: {nerrs/(nbits*niters)}")
    return ber


if __name__ == "__main__":

    ebno = np.arange(0, 12, 2)
    coderate = ['1/2', '2/3', '3/4']
    bers = np.zeros((len(coderate), len(ebno)), dtype=float)
    for k, rate in enumerate(coderate):
        bers[k] = sim_performance(rate, ebno)

    plt.plot(ebno, bers[0], '-ro')
    plt.plot(ebno, bers[1], '-ks')
    plt.plot(ebno, bers[2], '-bx')
    plt.legend(['1/2', '2/3', '3/4'])
    plt.yscale('log')
    plt.xlabel('Eb/No (dB)')
    plt.ylabel('Bit Error Rate (BER)')
    plt.title('Viterbi Decoder Performance')
    plt.grid(True)
    plt.show()


    # # write test vector
    # rxsig = np.reshape(rxsig, (-1, 2))
    # with open('vitdec_in_samples.txt', 'w') as f:
    #     for d in rxsig:
    #         f.write(f'{d[0]:.0f}, {d[1]:.0f}\n')

    # with open('vitdec_output_ref.txt', 'w') as f:
    #     for b in outbits:
    #         f.write(f'{b}\n')





