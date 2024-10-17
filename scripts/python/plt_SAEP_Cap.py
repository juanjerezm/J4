


import csv
from dataclasses import dataclass, field
from pathlib import Path
import sys
from typing import Dict, List

from matplotlib import pyplot as plt

import utilities as utils
import plt_config as cfg

import pandas as pd


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
        df["level"] = df["level"] * SCALE

        # Assign country and policy data
        df = df.assign(project=self.project, country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True # type: ignore
        )  # .values() if renamed, .keys() if not

        df["project"] = df["project"].str[-4:].astype(str)        

        # Clean up
        df = df.drop(columns=["case"])
        df = df[["project", "country", "policy", "level"]]
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
        


def main(param_files):
    var = "y_hr"

    scenarios = []

    for project in param_files:
        check_file_exist(Path(project))
        scenarios += load_scenario_params(Path(project))   


        for scenario in scenarios:
            scenario.get_data(var)
            scenario.process_data()
    
    df = pd.concat([scenario.data for scenario in scenarios], ignore_index=True)
    
    df = utils.rename_values(df, {"country": cfg.COUNTRIES})

    country_colors = {
        "Germany": "red",
        "Denmark": "green",
        "France": "blue"
    }

    policy_markers = {
        "Technical": "o",  # Circle
        "Taxation": "s",   # Square
        "Support": "^"     # Triangle
    }

    fig, ax = plt.subplots(figsize=(10, 6))

    for (country, policy), group in df.groupby(["country", "policy"]):
        ax.plot(group["project"], group["level"], marker=policy_markers[policy], color=country_colors[country],
                linestyle='-', label=f'{country}, {policy}')

    ax.set_xlabel('Discount rate [%]')
    ax.set_ylabel('Year (electricity price)')
    # ax.set_title('Level by Project for Each Country-Policy Pair')
    # make legend title bold
    ax.legend(title='Country, Policy', bbox_to_anchor=(1.05, 1), loc='upper left', title_fontproperties={"weight": "bold"})
    plt.xticks(rotation=45)
    plt.tight_layout()

    # make dir
    Path(out_dir).mkdir(parents=True, exist_ok=True)

    if save:
        plt.savefig(f"{out_dir}/{plot_name}.png", dpi=DPI)
    if show:
        plt.show()


    # print(df.head(50))
    # to csv
    # df.to_csv("results.csv")


if __name__ == "__main__":
    save = True
    show = False
    folder = "SA-EP"

    # width = 8.5  # cm
    # height = 10  # cm
    DPI = 900

    out_dir = f"C:/Users/jujmo/OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article/diagrams/plots/{folder}"
    plot_name = "SAEP_Cap"

    projects = ["SAEP2018", "SAEP2019", "SAEP2020", "SAEP2021", "SAEP2022", "SAEP2023"]
    param_files = [f"data/{run}/{run}_scnpars.csv" for run in projects]
    SCALE = 1 # MW/MW
    main(param_files)
