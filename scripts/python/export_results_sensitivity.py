import argparse
import csv
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import pandas as pd
import utilities as utils


cfg = {
    # "base_path": Path(r"C:\Users\jujmo\Github\J4")              # DTU laptop
    "base_path": Path("C:/Users/juanj/GitHub/PhD/J4 - model") # Home PC
    # "base_path": Path("/zhome/f0/5/124363/J4"),               # HPC (local)
    # "base_path": Path("//home.cc.dtu.dk/jujmo/J4")            # HPC (home)
}


@dataclass
class ScenarioParams:
    """
    Represents the parameters for a scenario.

    Attributes:
        name (str): The name of the scenario.
        project (str): The project associated with the scenario.
        country (str): The country associated with the scenario.
        policy (str): The policy associated with the scenario.
    """

    project: str
    name: str
    country: str
    policy: str
    dir: Path = field(init=False)

    def __post_init__(self) -> None:
        self.dir = cfg["base_path"] / "results" / self.project / self.name


def read_csv(file_path: Path) -> List[ScenarioParams]:
    """Read scenario parameters from a csv-file and return a list of ScenarioParams objects."""
    scenarios = []
    with open(file_path, "r") as file:
        delimiter = csv.Sniffer().sniff(file.read()).delimiter
        file.seek(0)
        reader = csv.DictReader(file, delimiter=delimiter)
        for row_number, row in enumerate(
            reader, start=2
        ):  # Start from 2, skipping header row
            validate_row(row, row_number)
            scenario = ScenarioParams(**row)
            scenarios.append(scenario)
    return scenarios


def validate_row(row: Dict[str, str], row_number: int) -> None:
    """Validate that rows are not empty and do not contain missing values."""
    if not any(row.values()):
        raise ValueError(f"Empty line detected at row {row_number}")
    if not all(row.values()):
        raise ValueError(f"Missing value in row {row_number}: {row}")


def check_file_exist(file_path: Path) -> None:
    """Check if the input csv-file exists."""
    if not file_path.is_file():
        sys.exit("ERROR: Input csv-file not found, script has stopped.")


def get_data(
    scenario: ScenarioParams,
    vars: Optional[List[str]] = None,
    pars: Optional[List[str]] = None,
) -> Dict[str, pd.DataFrame]:
    data: Dict[str, pd.DataFrame] = {}
    paths = [
        scenario.dir / f"results-{scenario.name}-integrated.gdx",
        scenario.dir / f"results-{scenario.name}-reference.gdx",
    ]

    if vars:
        if not isinstance(vars, list) or not all(
            isinstance(item, str) for item in vars
        ):
            raise TypeError("vars must be a list of strings")

    data = utils.gdxdf_var(paths, vars)

    if pars:
        if not isinstance(pars, list) or not all(
            isinstance(item, str) for item in pars
        ):
            raise TypeError("pars must be a list of strings")
        data.update(utils.gdxdf_par(paths, pars))
    return data


def export_to_csv(scenario: ScenarioParams, data: Dict[str, pd.DataFrame]) -> None:
    csv_dir = scenario.dir / "csv"
    csv_dir.mkdir(parents=True, exist_ok=True)
    for key in data.keys():
        data[key].to_csv(csv_dir / f"{key}.csv", index=False)
        print(f"Saved {key}.csv")
    pass


def parse_args():
    """
    Parse command line arguments for submitting jobs to HPC.

    Returns:
        None
    """
    parser = argparse.ArgumentParser(description="Submit jobs to HPC")
    parser.add_argument(
        "file_path", type=Path, help="Path to the CSV file containing scenarios"
    )
    parser.add_argument(
        "--base_path",
        type=Path,
        default=cfg["base_path"],
        help="Base path for the model",
    )

    args = parser.parse_args()

    cfg.update({"file_path": Path(args.file_path), "base_path": Path(args.base_path)})


def main(path):
    """
    Entry point of the program.
    """

    cfg["file_path"] = Path(path)

    pars = [
        "value_support",
        "value_tariffs",
        "value_taxes",
        "log_n",
        "pi_h",
        "out_FPC_DH",
        "out_FPC_HR",
        "out_MPC_DH",
        "out_MPC_HR",
        "AP_DH",
        "AP_HR",
    ]

    check_file_exist(cfg["file_path"])
    scenarios = read_csv(cfg["file_path"])
    print(f"Scenarios loaded successfully:")

    print("---------------------------------")
    for scenario in scenarios:
        data = get_data(scenario, vars=None, pars=pars)
        export_to_csv(scenario, data)
        print(scenario)
        print("---------------------------------")


if __name__ == "__main__":

    projects = ["SAEP2018", "SAEP2019", "SAEP2020", "SAEP2021", "SAEP2022", "SAEP2023"]
    # projects = ["SADR00", "SADR02", "SADR04", "SADR06", "SADR08", "SADR10", "SADR12"]

    scn_pars = [f"data/{run}/{run}_scnpars.csv" for run in projects]

    for file in scn_pars:
        main(file)
