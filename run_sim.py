import subprocess
from pathlib import Path
from shutil import which
from tempfile import TemporaryDirectory


def main():
    source_dir = Path(__file__).resolve().parent
    sources = ["apb_master.sv", "apb_slave.sv", "tb_apb.sv"]
    compiler = which("iverilog")
    runtime = which("vvp")
    if not compiler or not runtime:
        raise SystemExit("Add both iverilog and vvp from Icarus Verilog to PATH.")

    try:
        with TemporaryDirectory(prefix="sapr-apb-") as output_dir:
            image = Path(output_dir) / "tb_apb.vvp"
            subprocess.run(
                [compiler, "-g2012", "-Wall", "-s", "tb_apb", "-o", str(image), *sources],
                cwd=source_dir,
                check=True,
            )
            subprocess.run([runtime, str(image)], cwd=output_dir, check=True)
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from error


if __name__ == "__main__":
    main()
