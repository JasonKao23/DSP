# -*- coding: utf-8 -*-
"""
64-FFT radix 4
decimation in frequency

@author:
"""


import numpy as np
from scipy import fftpack
import matplotlib.pyplot as plt


def cmul(a, b):
    """ multiplying two complex numbers
    """
    re = a.real*b.real - a.imag*b.imag
    im = (a.real+a.imag)*(b.real+b.imag) - a.real*b.real - a.imag*b.imag
    c = re + 1j*im

    return c


def bfly(x, w, fixed):
    """ bufferfly for radix 4 FFT
    """
    Q = np.array([[1,   1,  1,   1],
                  [1,  1j, -1,  -1j],
                  [1,  -1,  1,  -1],
                  [1, -1j, -1,  1j]])
    u = np.matmul(Q, np.reshape(x, (4,1)))
    r = np.multiply(u.flatten(), w)
    if fixed:
        r = np.floor(r.real*2**14)/2**14 + 1j*np.floor(r.imag*2**14)/2**14

    return r


class FFT64:
    """
    FFT64, radix 4
    decimation in frequency
    """
    def __init__(self, isfixed=True):
        self.isfixed = isfixed
        self.outbuf = np.empty(64, dtype=complex)

    def proc(self, inbuf):
        isfixed = self.isfixed
        a = np.reshape(np.arange(16), (16, 1))
        b = np.arange(4)
        tw = np.exp(1j*2*np.pi*(a*b)/64)
        if isfixed:
            tw = (np.round(tw*2**14))/2**14

        # stage 1
        for k in range(16):
            idx = np.arange(4)*16 + k
            u = bfly(inbuf[idx], tw[k], isfixed)
            inbuf[idx] = u
            # print((idx, u*2**14))

        # stage 2
        for k in range(16):
            idx0 = k // 4
            idx1 = k % 4
            idx = np.arange(4)*4 + idx1 + idx0*16
            u = bfly(inbuf[idx], tw[idx1*4], isfixed)
            inbuf[idx] = u

        # stage 3
        for k in range(16):
            idx = np.arange(4) + k*4
            u = bfly(inbuf[idx], tw[0], isfixed)
            idx = ((idx&0x3)<<4) + (idx&0xC) + ((idx&0x30)>>4)
            self.outbuf[idx] = u
            # print((idx, u*2**14))

        return self.outbuf


if __name__=="__main__":
    """ check FFt64
    """
    np.random.seed(123)
    data_re = np.random.randint(low=-1024, high=1023, size=64)/2**14
    data_im = np.random.randint(low=-1024, high=1023, size=64)/2**14
    indata = data_re + 1j*data_im
    indata2 = indata.copy()
    isfixed = True
    fftobj = FFT64(isfixed)
    outdata = fftobj.proc(indata)

    # check results
    refdata = fftpack.ifft(indata2) * 64
    d = outdata - refdata
    print(np.max(np.abs(d.real)))
    print(np.max(np.abs(d.imag)))

    # save input/output date
    t = np.stack((indata2.real*2**14, indata2.imag*2**14)).T
    np.savetxt('./systemc/ifft64/ifft64_in_sample.txt', t.astype(int), fmt='%d', delimiter=',')
    v = np.concatenate((outdata[-16:], outdata))
    t = np.stack((v.real*2**14, v.imag*2**14)).T
    np.savetxt('./systemc/ifft64/ifft64_ref_sample.txt', t.astype(int), fmt='%d', delimiter=',')
