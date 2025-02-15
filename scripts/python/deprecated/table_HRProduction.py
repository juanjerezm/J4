from pathlib import Path
import pandas as pd
import utilities as utils
import plt_config as cfg
import utilities as utils
from utilities import Scenario


def summarize_results(scenario: Scenario) -> pd.DataFrame:
    df = scenario.results
    # rename columns CASE to case and value to level
    df = df.rename(columns={"CASE": "case", "value": "level"})

    df = utils.aggregate(df, ["case", "G"], ["level"])
    df = utils.diff(df, "case", "reference", "level")
    df = utils.filter(df, include={"G": "HR_DC"})
    df["level"] = df["level"] * SCALE
    df["level"] = df["level"].round(2)

    # Assign country and policy data
    df = df.assign(country=scenario.country, policy=scenario.policy)
    df = utils.rename_values(df, {"policy": cfg.POLICIES})
    df["policy"] = pd.Categorical(
        df["policy"], categories=cfg.POLICIES.values(), ordered=True  # type: ignore
    )  # .values() if renamed, .keys() if not

    # Clean up
    df = df.drop(columns=["case"])
    df = df[["country", "policy", "level"]]
    scenario.results = df
    return df


def main(file):
    scenarios = utils.read_scenarios(file)
    for scenario in scenarios:
        scenario.load_results(VAR)
        summarize_results(scenario)

    df = pd.concat([scenario.results for scenario in scenarios], ignore_index=True)

    utils.output_table(
        df,
        index=["country"],
        columns=["policy"],
        values="level",
        show=SHOW,
        save=SAVE,
        outdir=OUTDIR,
        filename=NAME,
    )


if __name__ == "__main__":
    PROJECT = "NEWOUTPUT"
    SCENARIO_PARAMETERS = f"data/{PROJECT}/scenario_parameters.csv"

    SAVE = False
    SHOW = True

    VAR = "HeatProduction"
    SCALE = 1e-3 # MWh/GWh

    NAME = "HRProduction"
    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "final results"
        / PROJECT
    )
    main(SCENARIO_PARAMETERS)
