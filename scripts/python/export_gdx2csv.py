import argparse
from pathlib import Path

import pandas as pd
import utilities as utils
from utilities import Scenario

cfg = {"base_path": Path.cwd()}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export postprocessing GDX files to CSV"
    )
    parser.add_argument(
        "--scenario-file",
        help="Path to a scenario_parameters.csv file to export",
    )
    return parser.parse_args()


def export_to_csv(scenario: Scenario, data: dict[str, pd.DataFrame]) -> None:
    csv_dir = scenario.outdir / "csv"
    csv_dir.mkdir(parents=True, exist_ok=True)
    for key in data:
        data[key].to_csv(csv_dir / f"{key}.csv", index=False)
        print(f"--> Saved {key}.csv")
    pass


def main(file: str | Path) -> None:
    scenarios = utils.read_scenarios(file)
    utils.print_line()
    for scenario in scenarios:
        print(f"Processing scenario: {scenario.name}")
        gdx_path = scenario.outdir / f"results-{scenario.name}-postprocessing.gdx"
        results = utils.gdxdf_postprocess(gdx_path)
        export_to_csv(scenario, results)


if __name__ == "__main__":
    args = parse_args()

    if args.scenario_file:
        main(args.scenario_file)
        raise SystemExit(0)

    # ----- main analysis -----
    # projects = ["MAIN"]

    # ----- sensitivity analysis (discount rate) -----
    # projects = ["SADR00", "SADR02", "SADR04", "SADR06", "SADR08", "SADR10", "SADR12"]

    # ---- sensitivity analysis (electricity prices) -----
    projects = ["SAEP_low", "SAEP_base", "SAEP_high"]

    for project in projects:
        scenario_parameters = f"data/{project}/scenario_parameters.csv"
        main(scenario_parameters)
