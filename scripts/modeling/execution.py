import csv
import shutil
import subprocess
import time
from datetime import datetime
from pathlib import Path

from scripts.modeling.export import export_to_csv
from scripts.modeling.schemas import ExecutionOutcome, ExecutionStatus, Runset, Scenario


def check_override_dir(root_path: Path, override: str) -> None:
    """
    Raise if the override directory does not exist in data/overrides.
    Override 'none' is reserved and must not exist as a directory.
    """
    if override == "none":
        path = root_path / "data" / "overrides" / "none"
        if path.exists():
            raise ValueError("Override directory 'none' is reserved and must not exist")
        return

    path = root_path / "data" / "overrides" / override
    if not path.is_dir():
        raise FileNotFoundError(f"Override directory not found: {path}")


def run_scenario(root_path: Path, scenario: Scenario, purge: bool) -> None:
    """Run a single scenario by executing the GAMS model with the appropriate command-line arguments."""
    outdir = root_path / "results" / scenario.id

    if purge:
        shutil.rmtree(outdir, ignore_errors=True)

    outdir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "gams",
        "run.gms",
        f"--scenario={scenario.id}",
        f"--override={scenario.override}",
        f"--solve_mode={scenario.solve_mode}",
        f"--country={scenario.country}",
        f"--policytype={scenario.policytype}",
        f"o={outdir / 'run.lst'}",
        f"lf={outdir / 'run.log'}",
        "logOption=4",
    ]

    print(f"Running {scenario.id} (override={scenario.override})")
    subprocess.run(cmd, check=True, cwd=root_path)
    print("--------------------------------------------------")
    print(f"--> Scenario {scenario.id} executed successfully.")
    print("--------------------------------------------------")


def load_scenarios(catalog_path: Path, runset: Runset) -> list[Scenario]:
    """Load and return the ordered list of Scenario objects from catalog_path for the given runset."""
    with catalog_path.open("r", newline="") as f:
        reader = csv.DictReader(f)
        raw_rows = list(reader)

    missing_cols = sorted(set(Scenario.model_fields) - set(reader.fieldnames or []))
    if missing_cols:
        raise ValueError(f"Scenario catalog is missing columns: {missing_cols}")

    index = {row["id"]: row for row in raw_rows}

    missing_ids = set(runset.scenario_ids) - index.keys()
    if missing_ids:
        missing_str = ", ".join(sorted(missing_ids))
        raise ValueError(f"Scenarios not found in {catalog_path}: {missing_str}")

    scenarios = []

    for scenario_id in runset.scenario_ids:
        try:
            scenarios.append(Scenario(**index[scenario_id]))
        except ValueError as exc:
            raise ValueError(f"Invalid scenario '{scenario_id}': {exc}") from exc

    return scenarios


def save_summary(
    root_path: Path,
    scenarios: list[Scenario],
    logs: list[ExecutionOutcome],
    total_elapsed: float,
) -> None:
    """Write a summary of scenario execution outcomes."""
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    summary_path = root_path / "results" / f"summary_{timestamp}.txt"
    summary_path.parent.mkdir(parents=True, exist_ok=True)

    passed = [r for r in logs if r.status == ExecutionStatus.PASSED]
    failed_gams = [r for r in logs if r.status == ExecutionStatus.FAILED_GAMS]
    failed_export = [r for r in logs if r.status == ExecutionStatus.FAILED_EXPORT]

    with summary_path.open("w") as f:
        f.write("Run summary\n")
        f.write(f"Timestamp:       {timestamp}\n")
        f.write(f"Total elapsed:   {total_elapsed:.1f}s\n")
        f.write(f"Scenarios:       {len(scenarios)}\n")
        f.write(f"Passed:          {len(passed)}\n")
        f.write(f"Failed (gams):   {len(failed_gams)}\n")
        f.write(f"Failed (export): {len(failed_export)}\n\n")

        f.write("Per-scenario results:\n")
        f.write(f"  {'Scenario':<30} {'Elapsed':>9} {'Status':<16} {'Reason'}\n")
        f.write(f"  {'-' * 30} {'-' * 9} {'-' * 16} {'-' * 40}\n")
        for r in logs:
            reason = r.reason or ""
            f.write(
                f"  {r.scenario_id:<30} {r.elapsed:>8.1f}s {r.status:<16} {reason}\n"
            )

    print(f"Summary written to: {summary_path}")


def main(
    scenario_id: str | None,
    runset_path: Path | None,
    catalog_path: Path,
    purge: bool,
    export_csv: bool,
) -> None:
    """Orchestrate local execution of model scenarios from a single ID or runset."""

    workspace_root = Path.cwd()

    if runset_path is not None:
        runset = Runset.from_yaml(runset_path)
    elif scenario_id is not None:
        runset = Runset(scenario_ids=(scenario_id,))
    else:
        raise ValueError("Either scenario_id or runset_path must be provided")

    scenarios = load_scenarios(catalog_path, runset)

    for scn in scenarios:
        check_override_dir(workspace_root, scn.override)

    print(f"Selected {len(scenarios)} scenario(s)")

    logs: list[ExecutionOutcome] = []
    start_all = time.monotonic()

    for scn in scenarios:
        start_scenario = time.monotonic()
        try:
            run_scenario(workspace_root, scn, purge=purge)
        except subprocess.CalledProcessError as exc:
            scn_elapsed = time.monotonic() - start_scenario
            logs.append(ExecutionOutcome.gams_fail(scn.id, scn_elapsed, exc.returncode))
            continue

        if export_csv:
            try:
                export_to_csv(workspace_root, scn)
            except Exception as exc:
                scn_elapsed = time.monotonic() - start_scenario
                logs.append(ExecutionOutcome.export_fail(scn.id, scn_elapsed, exc))
                continue

        scn_elapsed = time.monotonic() - start_scenario
        logs.append(ExecutionOutcome.passed(scn.id, scn_elapsed))

    total_elapsed = time.monotonic() - start_all
    save_summary(workspace_root, scenarios, logs, total_elapsed)
