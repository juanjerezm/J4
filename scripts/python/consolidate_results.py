# Standard library imports
from dataclasses import dataclass
from pathlib import Path

# Third-party library imports
import pandas as pd
import plt_config as cfg

# Local/custom module imports
import utilities as utils
from utilities import Scenario

# ----- Constants -----

# specify the metrics to be consolidated, the scale factor, number of decimals, and whether the results are aggregated across timesteps
METRIC_PARAMETERS = [
    ("ETSQuota", 1e-3, 3, False),  # €->k€
    ("Tariffs", 1e-3, 3, False),  # €->k€
    ("Taxes", 1e-3, 3, False),  # €->k€
    ("Support", 1e-3, 3, False),  # €->k€
    ("WasteHeatPrice", 1e0, 2, False),  # €/MWh
    ("AskPrice", 1e0, 2, False),  # €/MWh
    ("BidPrice", 1e0, 2, False),  # €/MWh
    ("FixedAsk", 1e0, 2, False),  # €/MWh
    ("FixedBid", 1e0, 2, False),  # €/MWh
    ("MarginalAsk", 1e0, 2, False),  # €/MWh
    ("MarginalBid", 1e0, 2, False),  # €/MWh
    ("CAPEX", 1e-3, 3, False),  # €->k€
    ("NPV", 1e-3, 3, False),  # €->k€
    ("NPV_all", 1e-3, 3, False),  # €->k€
    ("OPEX", 1e-3, 3, False),  # €->k€
    ("OPEX_Savings", 1e-3, 3, False),  # €->k€
    ("WH_transaction", 1e-3, 3, False),  # €->k€
    ("IRR", 1e0, 3, False),  # -
    ("PBT", 1e0, 2, False),  # years
    ("FLH", 1e0, 0, False),  # hours
    ("CarbonEmissions", 1e0, 0, True),  # kg
    ("HeatProduction", 1e0, 2, True),  # MWh
    ("ColdProduction", 1e0, 2, True),  # MWh
    ("ElectricityProduction", 1e0, 2, True),  # MWh
    ("FuelConsumption", 1e0, 2, True),  # MWh
    # ('StorageFlow',             1e+0,   2, False),  # MWh
    # ('StorageLevel',            1e+0,   2, False),  # MWh
    ("HeatRecoveryCapacity", 1e0, 2, False),  # MW
    # ('FuelMaxCapacity',         1e+0,   2, False),  # MW
]


# dataclass to store the parameters for each metric
@dataclass(frozen=True)
class Metric:
    name: str
    scale: float
    decimals: int
    aggregated: bool


# Generate instances holding the metric specifications
metrics = [
    Metric(name, scale, decimals, aggregated)
    for name, scale, decimals, aggregated in METRIC_PARAMETERS
]


# ----- Functions -----
def summarize_results(scenario: Scenario, specifications) -> pd.DataFrame:
    df = scenario.results

    if "T" in df.columns:
        if specifications.aggregated:
            cols = [col for col in df.columns if col not in ["T", "value"]]
            df = utils.aggregate(df, cols, ["value"])

    df["value"] = df["value"] * specifications.scale
    df["value"] = df["value"].round(specifications.decimals)

    # Assign country and policy data
    df = df.assign(country=scenario.country, policy=scenario.policy)
    df = utils.rename_values(df, {"policy": cfg.POLICIES})
    df["policy"] = pd.Categorical(
        df["policy"], categories=cfg.POLICIES.values(), ordered=True
    )  # .values() if renamed, .keys() if not

    # Ensure country and policy are the first columns
    all_columns = list(df.columns)
    remaining_columns = [col for col in all_columns if col not in ["country", "policy"]]
    ordered_columns = ["country", "policy"] + remaining_columns
    df = df[ordered_columns]

    return df


def consolidate_results(project, outdir, metric):
    scenario_specifications = f"data/{project}/scenario_parameters.csv"
    scenarios = utils.read_scenarios(scenario_specifications)
    df_all = []
    for scenario in scenarios:
        scenario.load_results(metric.name)
        df = summarize_results(scenario, metric)
        df_all.append(df)

    df_all = pd.concat(df_all, ignore_index=True)

    output_path = outdir / project / f"table-{metric.name}.csv"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df_all.to_csv(output_path, index=False)
    print(f"-> File saved to {output_path}")

    return df_all


if __name__ == "__main__":
    """
    This script loads scenario definitions with the goal of combining their results, providing consolidated CSV tables for each metric.
    It reads the scenario definitions from a CSV file, and summarises the results based on scaling, rounding, and aggregation specifications.    
    It then saves the consolidated results to CSV files in the specified output directory.
    """

    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "consolidated results"
    )

    # ----- main analysis -----
    projects = ["MAIN"]

    # ----- sensitivity analysis (discount rate) -----
    # projects = ["SADR_00", "SADR_02", "SADR_04", "SADR_06", "SADR_08", "SADR_10", "SADR_12"]
    # OUTDIR = OUTDIR / "SADR"

    # ---- sensitivity analysis (electricity prices) -----
    # projects = ["SAEP_low", "SAEP_base", "SAEP_high"]
    # OUTDIR = OUTDIR / "SAEP"

    for project in projects:
        for result in metrics:
            consolidate_results(project, OUTDIR, result)
