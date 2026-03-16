"""
End-to-end test for model's pipeline

This script
- runs a single test scenario locally,
- exports gdx outputs into csv files, and
- asserts that key KPIs match expected values.
"""

import argparse
import shutil
import subprocess
from pathlib import Path

import pandas as pd
import yaml

REQUIRED_KEYS = [
    "project",
    "scenario",
    "country",
    "policy",
    "mode",
    "scenario_file",
    "tol_abs",
    "expected",
]


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments for this test script."""
    parser = argparse.ArgumentParser(
        description="Run an E2E for the model's pipeline locally"
    )
    parser.add_argument(
        "config_file",
        help="Path to YAML config file with run parameters and expected KPIs",
    )
    parser.add_argument(
        "--no-clean",
        action="store_true",
        help="Skip deleting results from previous tests before running",
    )
    return parser.parse_args()


def load_config(path: str) -> dict:
    """Load the YAML test config file into a dictionary."""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"Config file not found: {p}")
    with p.open() as f:
        return yaml.safe_load(f) or {}


def validate_config(cfg: dict, required_keys: list[str]) -> None:
    """Validate that all required config keys are present and non-null."""

    missing = [key for key in required_keys if cfg.get(key) is None]

    if missing:
        missing_str = ", ".join(missing)
        raise ValueError(f"Missing required spec keys: {missing_str}")

    return


def run_model(cfg: dict, outdir: Path) -> None:
    """Run the GAMS model locally using the provided configuration."""
    if shutil.which("gams") is None:
        raise RuntimeError("GAMS executable not found in PATH")

    outdir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "gams",
        "run.gms",
        f"--project={cfg['project']}",
        f"--scenario={cfg['scenario']}",
        f"--country={cfg['country']}",
        f"--policytype={cfg['policy']}",
        f"--mode={cfg['mode']}",
        f"o={outdir / 'run.lst'}",
    ]
    subprocess.run(cmd, check=True)


def export_results(scenario_file: str) -> None:
    """Export scenario outputs from GDX to CSV files."""
    cmd = [
        "python",
        "scripts/python/export_gdx2csv.py",
        "--scenario-file",
        scenario_file,
    ]
    subprocess.run(cmd, check=True)


def metric_sum(path: Path) -> float:
    """Return the sum of the `value` column for one KPI CSV file."""
    if not path.exists():
        raise FileNotFoundError(f"Expected KPI file not found: {path}")

    df = pd.read_csv(path)
    if df.empty:
        raise ValueError(f"KPI file is empty: {path}")
    if "value" not in df.columns:
        raise ValueError(f"Expected 'value' column missing in: {path}")

    return float(df["value"].sum())


def collect_kpis(outdir: Path, metric_names: list[str]) -> dict[str, float]:
    """Collect KPI totals from CSV files for all requested metric names."""
    return {
        metric_name: metric_sum(outdir / "csv" / f"{metric_name}.csv")
        for metric_name in metric_names
    }


def assert_expected(
    kpis: dict[str, float], expected: dict[str, float], tol_abs: float
) -> None:
    """Assert that each collected KPI matches its expected value within tolerance."""
    for metric_name, expected_value in expected.items():
        if metric_name not in kpis:
            raise AssertionError(f"Missing KPI in collected outputs: {metric_name}")

        diff = abs(kpis[metric_name] - expected_value)
        if diff > tol_abs:
            raise AssertionError(
                f"{metric_name} mismatch: "
                f"actual={kpis[metric_name]}, expected={expected_value}, diff={diff}, tol_abs={tol_abs}"
            )


def main() -> None:
    """Run the full local test flow from scenario config to KPI validation."""

    print("==================================================")
    print("Starting modelling pipeline's E2E test")

    args = parse_args()
    cfg = load_config(args.config_file)
    validate_config(cfg, REQUIRED_KEYS)

    outdir = Path("results") / cfg["project"] / cfg["scenario"]

    if not args.no_clean:
        print(f"Cleaning previous results at {outdir}")
        shutil.rmtree(outdir, ignore_errors=True)

    print("[1/3] Running local solve")
    run_model(cfg, outdir)

    print("[2/3] Exporting outputs")
    export_results(cfg["scenario_file"])

    print("[3/3] Collecting KPIs and validating")
    metric_names = list(cfg["expected"].keys())
    kpis = collect_kpis(outdir, metric_names)
    assert_expected(kpis, expected=cfg["expected"], tol_abs=cfg["tol_abs"])

    print("Modelling pipeline E2E test passed.")
    print("==================================================")


if __name__ == "__main__":
    main()
