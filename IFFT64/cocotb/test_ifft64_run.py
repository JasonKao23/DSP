import os
import sys
from pathlib import Path
from cocotb.runner import get_runner


def test_ifft64_runner():
    """Simulate the IFFT64 using the Python runner.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    verilog_sources = [
        proj_path/'hdl'/'ifft64.v',
        proj_path/'hdl'/'ifft64_tw_rom.v',
        proj_path/'hdl'/'bfly.v',
        proj_path/'hdl'/'cmult.v',
        proj_path/'hdl'/'ram_dp.v',
        proj_path/'hdl'/'shift_registers_srl.v'
    ]

    parameters = {
        'DWIDTH': 16
    }

    sys.path.append(str(proj_path / "tests"))

    runner = get_runner(sim)

    runner.build(
        hdl_toplevel='ifft64',
        verilog_sources=verilog_sources,
        parameters=parameters,
        always=True,
        timescale=('1ns', '1ps')
    )

    runner.test(
        hdl_toplevel="ifft64",
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_ifft64"
    )


if __name__ == "__main__":
    test_ifft64_runner()

