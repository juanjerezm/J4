# Standard library imports
from pathlib import Path

# Third-party library imports
import pandas as pd

# Local/custom module imports
import utilities as utils
import plt_config as cfg

from utilities import Scenario
# ----- Functions -----
def summarize_results(scenario: Scenario, scale, decimals) -> pd.DataFrame:
    df = scenario.results
    

    if "T" in df.columns:
        if var in var_reduced:
            # cols = [col for col in df.columns if col != "T"]
            # cols is all columns except T, and value
            cols = [col for col in df.columns if col not in ["T", "value"]]
            df = utils.aggregate(df, cols, ['value'])

    df["value"] = df["value"] * scale
    df['value'] = df['value'].round(decimals)

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


def table(var, scale, decimals):
    scenarios = utils.read_scenarios(SCENARIO_SPECS)
    df_all = []
    for scenario in scenarios:
        scenario.load_results(var)
        df = summarize_results(scenario, scale, decimals)
        df_all.append(df)
    
    df_all = pd.concat(df_all, ignore_index=True)

    OUTDIR.mkdir(parents=True, exist_ok=True)
    output_path = OUTDIR / f"table-{var}.csv"
    df_all.to_csv(output_path, index=False)
    print(f"-> File saved to {output_path}")

    return df_all

if __name__ == "__main__":
    PROJECT = "MAIN"
    SCENARIO_SPECS = f"data/{PROJECT}/scenario_parameters.csv"
    
    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "consolidated results"
        / PROJECT
    )


runs = [
    ('ETSQuota',                1e-3,   3),  # €->k€
    ('Tariffs',                 1e-3,   3),  # €->k€
    ('Taxes',                   1e-3,   3),  # €->k€
    ('Support',                 1e-3,   3),  # €->k€

    ('WasteHeatPrice',          1e+0,   2),  # €/MWh
    ('AskPrice',                1e+0,   2),  # €/MWh
    ('BidPrice',                1e+0,   2),  # €/MWh
    ('FixedAsk',                1e+0,   2),  # €/MWh
    ('FixedBid',                1e+0,   2),  # €/MWh
    ('MarginalAsk',             1e+0,   2),  # €/MWh
    ('MarginalBid',             1e+0,   2),  # €/MWh

    ('CAPEX',                   1e-3,   3),  # €->k€
    ('NPV',                     1e-3,   3),  # €->k€
    ('NPV_all',                 1e-3,   3),  # €->k€
    ('OPEX',                    1e-3,   3),  # €->k€
    ('OPEX_Savings',            1e-3,   3),  # €->k€
    ('WH_transaction',          1e-3,   3),  # €->k€

    ('IRR',                     1e+0,   3),  # -
    ('PBT',                     1e+0,   2),  # years

    ('CarbonEmissions',         1e+0,   0),  # kg
    ('HeatProduction',          1e+0,   2),  # MWh
    ('ColdProduction',          1e+0,   2),  # MWh
    ('ElectricityProduction',   1e+0,   2),  # MWh
    ('FuelConsumption',         1e+0,   2),  # MWh
  # ('StorageFlow',             1e+0,   2),  # MWh
  # ('StorageLevel',            1e+0,   2),  # MWh
    ('HeatRecoveryCapacity',    1e+0,   2),  # MW
  # ('FuelMaxCapacity',         1e+0,   2),  # MW
]

# for these variables, we aggregate the results by summing over the time dimension, to save memory
var_reduced = ['CarbonEmissions', 'HeatProduction', 'ColdProduction', 'ElectricityProduction', 'FuelConsumption']


for _, (var, scale, decimals) in enumerate(runs):
    table(var, scale, decimals)
