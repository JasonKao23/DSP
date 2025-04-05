import os
import random
from typing import Dict
import numpy as np

import cocotb
# from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge

NUM_FRAMES = int(os.environ.get("NUM_FRAMES", 50))
if cocotb.simulator.is_running():
    DWIDTH = int(cocotb.top.DWIDTH)


class DataValidMonitor:
    """
    Monitor of one-way control flow (data/valid) data interface
    Args
        clk: clock signal
        valid: control signal noting a transaction occured
        datas: named handles to be sampled
    """

    def __init__(
        self, clk: SimHandleBase, datas: Dict[str, SimHandleBase],
        valid: SimHandleBase, ready: SimHandleBase
    ):
        self.values = Queue[Dict[str, int]]()
        self._clk = clk
        self._datas = datas
        self._valid = valid
        self._ready = ready
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
            await RisingEdge(self._clk)
            if self._valid.value != 1 or self._ready.value != 1:
                continue
            self.values.put_nowait(self._sample())

    def _sample(self) -> int:
        """_summary_
        Samples the data signals
        """
        return {name: handle.value for name, handle in self._datas.items()}


class IFFT64Tester:
    """
    IFFT64 tester
    Args
        ifft64_entity: handle to an instance of IFFT64
    """
    def __init__(self, ifft64_entity: SimHandleBase):
        self.dut = ifft64_entity

        self.input_mon = DataValidMonitor(
            clk=self.dut.clk,
            valid=self.dut.in_valid,
            ready=self.dut.in_ready,
            datas=dict(in_re=self.dut.in_re, in_im=self.dut.in_im)
        )

        self.output_mon = DataValidMonitor(
            clk=self.dut.clk,
            valid=self.dut.out_valid,
            ready=self.dut.out_ready,
            datas=dict(out_re=self.dut.out_re, out_im=self.dut.out_im)
        )

        self._checker = None

    def start(self) -> None:
        """ Starts monitors, model, and checker coroutine """
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self.input_mon.start()
        self.output_mon.start()
        self._checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        """Stops everything"""
        if self._checker is None:
            raise RuntimeError("Monitor never started")
        self.input_mon.stop()
        self.output_mon.stop()
        self._checker.kill()
        self._checker = None

    async def _check(self) -> None:
        while True:
            # wait IFFT output samples
            await RisingEdge(self.dut.clk)
            if self.output_mon.values.qsize() < 80:
                await RisingEdge(self.dut.clk)
                continue
            # read 64 input samples
            assert self.input_mon.values.qsize() >= 64, 'expect 64 input samples ready'
            # print(self.input_mon.values.qsize())
            input_vals = np.zeros(64, dtype=complex)
            for ii in range(64):
                inval = await self.input_mon.values.get()
                re = inval['in_re'].integer
                im = inval['in_im'].integer
                if re >= (1 << (DWIDTH-1)):
                    re -= (1 << (DWIDTH))
                if im >= (1 << (DWIDTH-1)):
                    im -= (1 << (DWIDTH))
                input_vals[ii] = re + 1j*im
            ifft_vals = np.fft.ifft(input_vals) * 64
            expected_vals = np.concatenate((ifft_vals[48:], ifft_vals))
            # read 80 output samples
            output_vals = np.zeros(80, dtype=complex)
            for ii in range(80):
                outval = await self.output_mon.values.get()
                re = outval['out_re'].integer
                im = outval['out_im'].integer
                if re >= (1 << (DWIDTH+7)):
                    re -= (1 << (DWIDTH+8))
                if im >= (1 << (DWIDTH+7)):
                    im -= (1 << (DWIDTH+8))
                output_vals[ii] = re + 1j*im
            # print(f'expect {expected_vals}')
            # print(f'output {output_vals}')
            d = expected_vals - output_vals
            # print(d.real)
            # print(np.max(np.abs(d.real)))
            # print(np.max(np.abs(d.imag)))
            assert np.max(np.abs(d.real)) < 32
            assert np.max(np.abs(d.imag)) < 32


@cocotb.test()
async def ifft64_test(dut):
    """ IFFT64 testing """

    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
    tester = IFFT64Tester(dut)

    dut._log.info("Initialize and reset model")
    # initial
    dut.in_re.value = 0
    dut.in_im.value = 0
    dut.in_valid.value = 0
    dut.out_ready.value = 0
    # reset
    dut.rst.value = 1
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.out_ready.value = 1
    await RisingEdge(dut.clk)

    # start tester
    tester.start()
    dut._log.info("Testing")
    for c in range(NUM_FRAMES):
        dut._log.info(f"frame: {c}")
        for ii in range(64):
            while dut.in_ready.value != 1:
                await RisingEdge(dut.clk)
            dut.in_re.value = random.randint(-1024, 1023)
            dut.in_im.value = random.randint(-1024, 1023)
            dut.in_valid.value = 1
            await RisingEdge(dut.clk)

    for _ in range(300):
        await RisingEdge(dut.clk)








