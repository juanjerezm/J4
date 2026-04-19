from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

import numpy as np
import pandas as pd
import yaml

# Helper type for vectorising functions
type ArrayLike = float | pd.Series[float]


# Holds heat pump specifications from YAML file
@dataclass
class HeatPumpSpecs:
    source: Literal["air", "seawater", "excess heat"]
    size: int
    year: int
    lorentz_efficiency: float = field(init=False)
    auxiliary_consumption: float = field(init=False)

    def __post_init__(self):
        # Reads lorentz efficiency and auxiliary consumption from config file
        PATH = Path("data/_master-data/heat_pump_specs.yaml")
        with PATH.open() as f:
            specs = yaml.safe_load(f)
        for spec in specs:
            if (
                spec["source"] == self.source
                and spec["size"] == self.size
                and spec["year"] == self.year
            ):
                self.lorentz_efficiency = spec["lorentz_efficiency"]
                self.auxiliary_consumption = spec["auxiliary_consumption"]
                return
        raise ValueError(f"No specs found for {self}")


def cop_heatpump(
    *,
    HP_specs: HeatPumpSpecs,
    T_source_i: ArrayLike,
    T_source_o: ArrayLike,
    T_sink_i: ArrayLike,
    T_sink_o: ArrayLike,
    unit: Literal["C", "K"] = "C",
) -> ArrayLike:
    """
    Calculates the coefficient of performance (COP) for a heat pump.

    Methodology based on:
    'Technology Data - Generation of Electricity and District Heating', Danish Energy Agency.
    """

    def to_kelvin(T: ArrayLike) -> ArrayLike:
        if unit == "C":
            return T + 273.15
        if unit == "K":
            return T
        raise ValueError("unit must be 'C' or 'K'")

    T_source_i = to_kelvin(T_source_i)
    T_source_o = to_kelvin(T_source_o)
    T_sink_i = to_kelvin(T_sink_i)
    T_sink_o = to_kelvin(T_sink_o)

    Tm_sink = log_temperature(T_sink_i, T_sink_o)
    Tm_source = log_temperature(T_source_i, T_source_o)

    COP_nominal = (Tm_sink / (Tm_sink - Tm_source)) * HP_specs.lorentz_efficiency
    COP_real = COP_nominal / (1 + HP_specs.auxiliary_consumption * COP_nominal)
    return COP_real


def log_temperature(T_in: ArrayLike, T_out: ArrayLike) -> ArrayLike:
    """
    Calculates the logarithmic mean temperature difference between two temperatures.
    """
    return (T_in - T_out) / np.log(T_in / T_out)  # type: ignore


def cop_chiller(T_ambient: ArrayLike) -> ArrayLike:
    """
    Calculates the efficiency of a chiller, based on ambient temperature (°C).

    Reference:
        doi: 10.1016/j.apenergy.2014.11.067
    """
    cop_intercept = 5.82  # COP at 0°C (y-intercept)
    cop_slope = -0.0762  # Change in COP per °C (slope)
    cop_value = cop_intercept + cop_slope * T_ambient
    return cop_value


if __name__ == "__main__":
    # Define temperature difference within heat exchangers
    DT = 5  # Kelvin or Celsius

    # Read temperature files
    data = {
        "source": "data/_master-data/temperature-sources.csv",
        "sink": "data/_master-data/temperature-sinks.csv",
    }

    source_temps = pd.read_csv(data["source"], skiprows=[1, 2], index_col="timestep")
    sink_temps = pd.read_csv(data["sink"], skiprows=[1, 2], index_col="timestep")

    # Define Heat Pumps
    hp_air = HeatPumpSpecs("air", size=10, year=2020)
    hp_seawater = HeatPumpSpecs("seawater", size=20, year=2020)
    hp_heatrecovery = HeatPumpSpecs("excess heat", size=3, year=2020)

    # Calculate efficiency timeseries
    efficiencies = pd.DataFrame(index=source_temps.index)

    efficiencies["HP - air"] = cop_heatpump(
        HP_specs=hp_air,
        T_source_i=source_temps["air"],
        T_source_o=source_temps["air"] - DT,
        T_sink_i=sink_temps["distribution return"],
        T_sink_o=sink_temps["distribution supply"],
    )
    efficiencies["HP - seawater"] = cop_heatpump(
        HP_specs=hp_seawater,
        T_source_i=source_temps["seawater"],
        T_source_o=source_temps["seawater"] - DT,
        T_sink_i=sink_temps["distribution return"],
        T_sink_o=sink_temps["distribution supply"],
    )
    efficiencies["HP - heat recovery"] = cop_heatpump(
        HP_specs=hp_heatrecovery,
        T_source_i=30,
        T_source_o=20,
        T_sink_i=sink_temps["distribution return"],
        T_sink_o=sink_temps["distribution supply"],
    )
    efficiencies["electric chiller"] = cop_chiller(source_temps["air"] + DT)

    # Clean up and output
    efficiencies = efficiencies.round(3)
    efficiencies.to_csv("data/_master-data/variable-efficiencies.csv")
