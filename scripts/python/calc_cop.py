import numpy as np
import pandas as pd


def cop_heatpump(
    source, size, year, T_source_i, T_source_o, T_sink_i, T_sink_o, T_units="C"
):
    if T_units == "C":
        T_source_i = T_source_i + 273.15
        T_source_o = T_source_o + 273.15
        T_sink_i = T_sink_i + 273.15
        T_sink_o = T_sink_o + 273.15

    efficiency, auxiliary_consumption = get_heatpump_parameters(source, size, year)

    Tm_sink = log_temperature(T_sink_i, T_sink_o)
    Tm_source = log_temperature(T_source_i, T_source_o)

    COP_nominal = (Tm_sink / (Tm_sink - Tm_source)) * efficiency
    COP_real = COP_nominal / (1 + auxiliary_consumption * COP_nominal)
    return COP_real


def log_temperature(T_in, T_out):
    Tm_log = (T_in - T_out) / np.log(T_in / T_out)
    return Tm_log


def get_heatpump_parameters(source, size, year):
    df = pd.read_json("data/_master-data/heatpump_parameters.json")
    results = df[(df["source"] == source) & (df["size"] == size) & (df["year"] == year)]
    if results.empty:
        raise ValueError("No value found for the given parameters.")
    return (
        results["lorentz efficiency"].iloc[0],
        results["auxiliary consumption"].iloc[0],
    )


def cop_chiller(T_in):
    COP_0 = 5.82
    COP_T = -0.0762
    COP_EC = COP_0 + COP_T * T_in
    return COP_EC



df_source = pd.read_csv("data/_master-data/temperature-source-2023.csv", skiprows=[1, 2], index_col="timestep")
df_sink = pd.read_csv("data/_master-data/temperature-sink.csv", skiprows=[1, 2], index_col="timestep")

df_efficiency = pd.DataFrame(index=df_source.index)

DT = 5 #K
df_efficiency["HP - air"] = cop_heatpump("air", 10, 2020, df_source['air'], df_source['air'] - DT, df_sink['distribution return'], df_sink['distribution supply'])
df_efficiency["HP - seawater"] = cop_heatpump("seawater", 20, 2020, df_source['seawater'], df_source['seawater'] - DT, df_sink['distribution return'], df_sink['distribution supply'])
df_efficiency['HP - heat recovery'] = cop_heatpump("excess heat", 3, 2020, 30, 20, df_sink['distribution return'], df_sink['distribution supply'])
df_efficiency["electric chiller"] = cop_chiller(df_source['air']+ DT)

df_efficiency = df_efficiency.round(3)

df_efficiency.to_csv("data/_master-data/variable-efficiencies-2023.csv")
