# Standard library imports
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

# Third-party library imports
import pandas as pd

# Local/custom module imports
import utilities as utils
import plt_config as cfg

# ----- Functions -----
@dataclass
class Scenario:
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

    def process_data(self, mode) -> None:
        df = self.data
        df["value"] = df["value"] * SCALE

        if mode == 'reference':
            df = utils.filter(df, include={"case": "reference"})
        if mode == 'integrated':
            df = utils.filter(df, include={"case": "integrated"})
        if mode == 'difference':
            df = utils.diff(df, "case", "reference", "value")

        # # Assign country and policy data
        df = df.assign(country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True
        )  # .values() if renamed, .keys() if not

        # # Clean up
        df = df[["country", "policy", "E", "value"]]
        self.data = df
        return

def read_scenarios(filepath: str) -> List[Scenario]:
    df = pd.read_csv(filepath)
    scenarios = []
    for _, row in df.iterrows():
        scenario = Scenario(
            project=row["project"],
            name=row["name"],
            country=row["country"],
            policy=row["policy"],
        )
        scenarios.append(scenario)
    return scenarios


def exclude_empty_category(df: pd.DataFrame, category: str, tolerance: float = 1e-6) -> pd.DataFrame:
    """
    Exclude rows where the category column has a total 'level' sum within a tolerance of zero.
    
    Parameters:
        df (pd.DataFrame): The input DataFrame.
        category (str): The name of the column to group by.
        tolerance (float): The tolerance for considering a value as close to zero (default: 1e-6).
        
    Returns:
        pd.DataFrame: A filtered DataFrame without categories with marginal sums.
    """
    # Group by the category column and calculate the sum of 'level'
    category_sum = df.groupby(category)["level"].sum()
    
    # Identify categories with sums greater than the tolerance (in absolute terms)
    valid_categories = category_sum[abs(category_sum) > tolerance].index

    # Filter the original DataFrame to include only valid categories
    return df[df[category].isin(valid_categories)]

def summary_csv(df: pd.DataFrame, save: bool = False, outdir: Path = Path.cwd(), filename: str = ''):

    if mode == 'reference':
        df = df[df['policy'] == 'Technical']
        df = df.pivot(index="F", columns="country", values="level")
    if mode == 'integrated':
        df = df.pivot(index=["country", "F"], columns="policy", values="level")
    if mode == 'difference':
        df = df.pivot(index=["country", "item", "E"], columns="policy", values="value")

    print(df)

    if save:
        if not filename:
            raise ValueError("The 'filename' parameter is required when save=True.")
        
        outdir.mkdir(parents=True, exist_ok=True)
        output_path = outdir / f"{filename}.csv"
        df.to_csv(output_path)
        print(f"-> File saved to {output_path}")

    return

def result_collection(var):
    scenarios = read_scenarios(scnParsFilePath)
    for scenario in scenarios:
        scenario.get_data(var)
        scenario.process_data(mode=mode)

    df = pd.concat([scenario.data for scenario in scenarios], ignore_index=True)
    df['value'] = df['value'].round(3)
    
    # summary_csv(df, save=True, outdir=table_dir, filename=table_name)
    return df


def main(vars):
    df_all = []
    for key, value in vars.items():
        df = result_collection(key)
        df['item'] = value
        if key == "value_support":
            a = 1
            # df['value'] = df['value'] * (-1) # makes changes in support (positive, >0) negative, i.e. government deficit 
        df_all.append(df)

    # concatenate
    df_all = pd.concat(df_all, ignore_index=True)
    # to csv table_dir
    df_all.to_csv(table_dir / f'{table_name}.csv', index=False)

    # summary_csv(df_all)

    return df_all

if __name__ == "__main__":
    PROJECT = "BASE"
    scnParsFilePath = f"data/{PROJECT}/{PROJECT}_scnpars.csv"
    table_dir = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "diagrams"
        / "plots"
        / "plot-tables"
    )

    mode = 'difference'

    ## Electricity
    SCALE = 1e-3
    table_name = f'table-government-{mode}'

    vars = {'value_taxes': 'change in tax revenues', 'value_tariffs':'change in tariff revenues', 'value_support': 'change in support expenses'}

    main(vars)
