# Standard library imports
from pathlib import Path

# Third-party library imports
import pandas as pd

# Local/custom module imports
import utilities as utils
import plt_config as cfg

from utilities import Scenario
# ----- Functions -----
def summarize_results(scenario: Scenario, mode) -> pd.DataFrame:
    df = scenario.results
    
    df["value"] = df["value"] * SCALE

    if mode == 'reference':
        df = utils.filter(df, include={"CASE": "reference"})
    if mode == 'integrated':
        df = utils.filter(df, include={"CASE": "integrated"})
    if mode == 'difference':
        df = utils.diff(df, "CASE", "reference", "value")

    # # Assign country and policy data
    df = df.assign(country=scenario.country, policy=scenario.policy)
    df = utils.rename_values(df, {"policy": cfg.POLICIES})
    df["policy"] = pd.Categorical(
        df["policy"], categories=cfg.POLICIES.values(), ordered=True
    )  # .values() if renamed, .keys() if not

    # # Clean up
    df = df[["country", "policy", "E", "value"]]

    return df


def summary_csv(df: pd.DataFrame, save: bool = False, outdir: Path = Path.cwd(), filename: str = ''):
    print(df)
    if mode == 'reference':
        df = df[df['policy'] == 'Technical']
        df = df.pivot(index="F", columns="country", values="value")
    if mode == 'integrated':
        df = df.pivot(index=["country", "F"], columns="policy", values="value")
    if mode == 'difference':
        df = df.pivot(index=["country", "E"], columns="policy", values="value")

    print(df)

    save = False
    if save:
        if not filename:
            raise ValueError("The 'filename' parameter is required when save=True.")
        
        outdir.mkdir(parents=True, exist_ok=True)
        output_path = outdir / f"{filename}.csv"
        df.to_csv(output_path)
        print(f"-> File saved to {output_path}")

    return


def main(file, var, mode):
    scenarios = utils.read_scenarios(file)
    df_all = []
    for scenario in scenarios:
        scenario.load_results(var)
        df = summarize_results(scenario, mode=mode)
        df_all.append(df)
    df_all = pd.concat(df_all, ignore_index=True)

    summary_csv(df_all)

    return df_all

if __name__ == "__main__":
    PROJECT = "NEWOUTPUT"
    VAR = "HeatProduction"
    file = f"data/{PROJECT}/scenario_parameters.csv"
    
    outdir = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "consolidated results"
        / PROJECT
    )

    mode = 'difference'

    SCALE = 1e-3
    table_name = f'table-{VAR}-{mode}'


    main(file, VAR, mode)
