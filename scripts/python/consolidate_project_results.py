import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

import pandas as pd
import utilities as utils
import utilities_plotting as utils_plot

# ----- Globals -----
MAPPING_PATH = "configs/globals/mappings.yml"

# specify the metrics to be consolidated, the scale factor, number of decimals, and whether the results are aggregated across timesteps
METRIC_PARAMETERS: list[tuple[str, float, int, bool]] = [
    ("ETSQuota", 1e0, 0, False),  # €->€
    ("Tariffs", 1e0, 0, False),  # €->€
    ("Taxes", 1e0, 0, False),  # €->€
    ("Support", 1e0, 0, False),  # €->€
    ("WasteHeatPrice", 1e0, 2, False),  # €/MWh
    ("AskPrice", 1e0, 2, False),  # €/MWh
    ("BidPrice", 1e0, 2, False),  # €/MWh
    ("FixedAsk", 1e0, 2, False),  # €/MWh
    ("FixedBid", 1e0, 2, False),  # €/MWh
    ("MarginalAsk", 1e0, 2, False),  # €/MWh
    ("MarginalBid", 1e0, 2, False),  # €/MWh
    ("CAPEX", 1e0, 0, False),  # €->€
    ("NPV", 1e0, 0, False),  # €->€
    ("NPV_all", 1e0, 0, False),  # €->€
    ("OPEX", 1e0, 0, False),  # €->€
    ("OPEX_Savings", 1e0, 0, False),  # €->€
    ("WH_transaction", 1e0, 0, False),  # €->€
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


# ----- Functions -----
@dataclass(frozen=True)
class Metric:  # store metric specifications
    name: str
    scale: float
    decimals: int
    aggregated: bool


metrics = [
    Metric(name, scale, decimals, aggregated)
    for name, scale, decimals, aggregated in METRIC_PARAMETERS
]


# ----- Functions -----
def summarize_results(
    scenario: utils.Scenario, specifications: Metric, mappings: dict
) -> pd.DataFrame:
    df = scenario.results

    # --- assign scenario metadata ---
    df = df.assign(country=scenario.country, policy=scenario.policy)

    # -- replace model names by human-readable labels ---
    df["policy"] = df["policy"].map(mappings["policy_labels"])

    # --- aggregate results over time if specified ---
    if "T" in df.columns and specifications.aggregated:
        cols = [col for col in df.columns if col not in ["T", "value"]]
        df = utils.aggregate(df, cols, ["value"])

    df["value"] = (df["value"] * specifications.scale).round(specifications.decimals)

    # --- set categorical types for ordered plotting ---
    policies = list(mappings["policy_labels"].values())
    df["policy"] = pd.Categorical(df["policy"], categories=policies, ordered=True)

    # --- order columns with country and policy first ---
    all_columns = list(df.columns)
    remaining_columns = [col for col in all_columns if col not in ["country", "policy"]]
    ordered_columns = ["country", "policy", *remaining_columns]
    df = df[ordered_columns]

    return df


def main(analysis: str) -> None:
    """
    Consolidate selected model results across projects for a specific analysis.
    """

    analysis_cfg = utils_plot.fetch_projects(analysis)
    mappings = utils_plot.load_mappings(MAPPING_PATH)
    outdir = Path("results-consolidated") / analysis

    for project in analysis_cfg["projects"]:
        scenario_path = f"data/{project}/scenario_parameters.csv"
        scenario_list = utils.read_scenarios(scenario_path)

        for metric in metrics:
            df_all = []
            for scenario in scenario_list:
                scenario.load_results(metric.name)
                df = summarize_results(scenario, metric, mappings)
                df_all.append(df)

            df_all = pd.concat(df_all, ignore_index=True)

            output_path = outdir / project / f"table-{metric.name}.csv"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            df_all.to_csv(output_path, index=False)
            print(f"-> File saved to {output_path}")


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Consolidate result metrics across a group of projects."
    )

    parser.add_argument(
        "--analysis",
        type=str,
        required=True,
        help="Analysis name (e.g. MAIN, SADR, SAEP)",
    )

    return parser.parse_args()


# Default arguments for quick development runs in VS Code
# Bypasses CLI parsing if script is executed without arguments.
QUICKRUN_ARGS = {}
# QUICKRUN_ARGS = {"analysis": "MAIN"}


if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = _parse_args()
        main(**vars(args))
