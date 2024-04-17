import pandas as pd
import numpy as np

# switch to write file
save = True

def clean_quotation_marks(df):
    df.index = df.index.str.replace("'", "")
    df.columns = df.columns.str.replace("'", "")
    return df


filepaths = {
    "elec price": "data/common/ts-electricity-price.csv",
    "elec carbon": "data/common/ts-electricity-carbon.csv",
    "efficiency": "data/common/ts-generator-efficiency.csv",
    "fuel data": "data/common/data-fuel.csv",
    "generator data": "data/common/data-generator.csv",
}

el_price = pd.read_csv(
    filepaths["elec price"], index_col=0, header=None, names=["timestep", "elec price"]
)

el_carbon = pd.read_csv(
    filepaths["elec carbon"],
    index_col=0,
    header=None,
    names=["timestep", "elec carbon"],
)

efficiency = pd.read_csv(filepaths["efficiency"], index_col=0)
fuels = pd.read_csv(filepaths["fuel data"], index_col=0)
generators = pd.read_csv(filepaths["generator data"], index_col=0)

fuels = clean_quotation_marks(fuels)
generators = clean_quotation_marks(generators)
efficiency = clean_quotation_marks(efficiency)

efficiency["HP - waste heat"] = efficiency["HP - waste heat"] + 1 # adjust efficiency from cold to heat

carbon_price = fuels.loc["electricity", "carbon pric4e"]
tax_tariff = (
    fuels.loc["electricity", "fuel tax"] + fuels.loc["electricity", "fuel tariff"]
)
var_cost = float(generators.loc["HP - waste heat", "variable cost - heat"])


wh_price = pd.DataFrame(index=el_price.index, columns=["hourly"])
wh_price["hourly"] = (
    el_price["elec price"] + (el_carbon["elec carbon"] * carbon_price) + tax_tariff
) / efficiency["HP - waste heat"] + var_cost

month_idx = np.arange(len(wh_price)) // 730
wh_price["monthly"] = wh_price.groupby(month_idx)["hourly"].transform("mean")
wh_price = wh_price.round(2)

# save only "monthly" column to file
if save:
    wh_price.to_csv("data/common/ts-waste-heat-price.csv", columns=["monthly"], header=False)