import os
import sys
import random
from pathlib import Path
from typing import Dict, Any
import numpy as np

import cocotb
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge
from cocotb.runner import get_runner


if cocotb.simulator.is_running():
    DWIDTH = int(cocotb.top.DWIDTH)


class DataValidMonitor:
    """
    Monitor of one-way control flow (data/valid) data interface
    Args
        clock: clock signal
        valid: control signal noting a transaction occured
        datas: named handles to be sampled
    """
    def __init__(
        self, clock: SimHandleBase, datas: Dict[str, SimHandleBase], valid: SimHandleBase
    ):
        self.values = Queue[Dict[str, int]]()
        self._clock = clock
        self._datas = datas
        self._valid = valid
        self._coro = None

    def start(self) -> None:
        """ Start monitor """
        if self._coro is not None:
            raise RuntimeError("Monitor already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        """ Stop monitor """
        if self._coro is None:
            raise RuntimeError("Monitor never started")
        self._coro.kill()
        self._coro = None

    async def _run(self) -> None:
        while True:
            await RisingEdge(self._clock)
            if self._valid.value != 1:
                continue
            self.values.put_nowait(self._sample())

    def _sample(self) -> Dict[str, Any]:
        """_summary_
        Samples the data signals
        """
        return {name: handle.value for name, handle in self._datas.items()}


class VitdecTester:
    """
    Viterbi decoder tester
    Args
        vitdec_entity: handle to an instance of Viterbi decoder
    """
    def __init__(self, vitdec_entity: SimHandleBase):
        self.dut = vitdec_entity

        self.output_mon = DataValidMonitor(
            clock=self.dut.clock,
            valid=self.dut.dec_valid,
            datas=dict(dec_byte=self.dut.dec_byte)
        )

        self._checker = None

    def start(self) -> None:
        """ Starts monitors, model, and checker coroutine """
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stops everything"""
        if self._checker is None:
            raise RuntimeError("Monitor never started")
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None

    async def _check(self) -> None:
        nrxbits = 0
        rxbits = []
        while nrxbits < self.nofbits:
            # wait for output
            byte = await self.output_mon.values.get()
            rxbits += [(byte['dec_byte'].integer >> ii) & 0x1 for ii in range(8)]
            nrxbits += 8
        # d = np.abs(rxbits[:nrxbits] - self.srcbits[:nrxbits])
        # print([int(t) for t in d])
        nerrs = np.sum(np.abs(rxbits[:self.nofbits] - self.srcbits[:self.nofbits]))
        assert nerrs == 0, f"Number of errors: {nerrs}, expected 0"
        self.dut._log.info("Test passed")

    def _conv_enc(self):
        """ convolutional encoder """
        regs = np.zeros(6, dtype=np.int8)
        codebits = []
        punc_buf = []
        bitcnt = 0

        # puncturing parameters
        if self.coderate == 0:   # '1/2'
            punc_sz = 2
        elif self.coderate == 1: # '2/3'
            punc_sz = 4
        elif self.coderate == 2: # '3/4'
            punc_sz = 6
        else:                   # '5/6'
            punc_sz = 10
        punc_pattern = [1, 1, 1, 0, 0, 1, 1, 0, 0, 1]

        # run encoding and puncturing
        for s in self.srcbits:
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

    def gen_testvector(self, coderate, nofbits, ncbps, ndbps):
        self.coderate = coderate
        self.nofbits = nofbits
        self.ncbps = ncbps
        self.ndbps = ndbps
        # generate random souce bits
        ntail = 6
        rng = np.random.default_rng(123)
        self.srcbits = rng.integers(0, 2, self.nofbits-ntail, dtype=np.int8)
        self.srcbits = np.concatenate((self.srcbits, np.zeros(ntail, dtype=np.int8)))
        # print(f"Source bits: {self.srcbits[:32]}")
        # generate decoder input samples
        codebits = self._conv_enc()
        sig = 2*codebits - 1
        snr = 10
        s = 10 ** (-snr/20)
        sig = sig + rng.normal(0, s, len(sig))
        sig = np.floor(sig * 64)
        sig = np.clip(sig, -128, 127)

        return sig


@cocotb.test()
async def vitdec_test(dut):
    """ vitdec testing """

    cocotb.start_soon(Clock(dut.clock, 10, units='ns').start())
    tester = VitdecTester(dut)

    dut._log.info("Initialize and reset model")

    # generate test vector
    coderate = 2
    nofbits = 1032
    ncbps = 288
    ndbps = 216
    in_datas = tester.gen_testvector(coderate, nofbits, ncbps, ndbps)

    # initial
    dut.coderate.value = coderate
    dut.nofbits.value = nofbits
    dut.ndbps.value = ndbps
    dut.in_data.value = 0
    dut.in_valid.value = 0
    # reset
    dut.reset.value = 1
    for _ in range(5):
        await RisingEdge(dut.clock)
    dut.reset.value = 0
    await RisingEdge(dut.clock)

    # start tester
    tester.start()
    dut._log.info("Testing")
    in_data_cnt = 0
    while in_data_cnt < len(in_datas):
        for ii in range(np.min((400, len(in_datas)-in_data_cnt))):
            if ii < ncbps:
                dut.in_data.value = int(in_datas[in_data_cnt])
                dut.in_valid.value = 1
                in_data_cnt += 1
            else:
                dut.in_data.value = 0
                dut.in_valid.value = 0
            await RisingEdge(dut.clock)
    dut.in_data.value = 0
    dut.in_valid.value = 0
    # wait decoder to finish
    for _ in range(4000):
        await RisingEdge(dut.clock)


def test_vitdec_runner():
    """Simulate the vitdec using the Python runner.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    verilog_sources = [
        proj_path/'rtl'/'vitdec.v',
        proj_path/'rtl'/'depunct.v',
        proj_path/'rtl'/'acs.v',
        proj_path/'rtl'/'acs_butterfly.v',
        proj_path/'rtl'/'traceback.v',
        proj_path/'rtl'/'ram_dp.v'
    ]

    parameters = {
        'DWIDTH': 8
    }

    sys.path.append(str(proj_path / "tests"))

    runner = get_runner(sim)

    runner.build(
        hdl_toplevel='vitdec',
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
        timescale=('1ns', '1ps')
    )

    runner.test(
        hdl_toplevel="vitdec",
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_vitdec"
    )


if __name__ == "__main__":
    test_vitdec_runner()

