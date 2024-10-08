# better check similarities with plt_FuelUse and move to utilities accordingly.
import argparse
import csv
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import pandas as pd
import utilities as utils
import plt_config as cfg


@dataclass
class ScenarioParams:
    project: str
    name: str
    country: str
    policy: str
    dir: Path = field(init=False)
    data: pd.DataFrame = field(init=False)

    def __post_init__(self):
        self.dir = Path("results") / self.project / self.name / "csv"

    def __str__(self) -> str:
        return f"- Scenario {self.name}: country={self.country}, policy={self.policy}"

    def get_data(self, var: str) -> None:
        file = self.dir / f"{var}.csv"
        self.data = pd.read_csv(file)
        return

    def process_data(self) -> None:
        df = self.data
        
        df = utils.aggregate(df, ["case", "G"], ["level"])
        df = utils.diff(df, "case", "reference", "level")
        df = utils.filter(df, include={"G": "HR_DC"})
        df["level"] = df["level"] * SCALE

        df["level"] = df["level"].round(2)

        # Assign country and policy data
        df = df.assign(country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True # type: ignore
        )  # .values() if renamed, .keys() if not

        # Clean up
        df = df.drop(columns=["case"])
        df = df[["country", "policy", "level"]]
        self.data = df
        return


def load_scenario_params(file_path: Path) -> List[ScenarioParams]:
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


def main(file_path_input):
    check_file_exist(Path(file_path_input))
    scenarios = load_scenario_params(Path(file_path_input))
    print(f"Scenarios loaded successfully:")

    var = "x_h"
    for scenario in scenarios:
        scenario.get_data(var)
        scenario.process_data()
    
    df = pd.concat([scenario.data for scenario in scenarios], ignore_index=True)
    # pivot table, country on rows and policy on columns
    df = df.pivot_table(index="country", columns="policy", values="level")
    print(df.head(20))

    # save to csv
    outdir = rf"C:\Users\jujmo\OneDrive - Danmarks Tekniske Universitet\Papers\J4 - article\diagrams\plots\{PROJECT}"
    Path(outdir).mkdir(parents=True, exist_ok=True)
    outfile = Path(outdir) / "tab_HeatProd.csv"
    df.to_csv(outfile)


if __name__ == "__main__":
    PROJECT = "BASE"
    scnParsFilePath = f"data/{PROJECT}/{PROJECT}_scnpars.csv"
    SCALE = 1 # MWh/MWh
    main(scnParsFilePath)
