# Standard library imports
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Tuple

# Third-party library imports
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from matplotlib.legend import Legend

# Local/custom module imports
import utilities as utils
import plt_config as cfg


# ----- Matplotlib settings -----
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 8


# ----- Functions -----
@dataclass
class Scenario:
    project: str
    name: str
    country: str
    policy: str
    dir: Path = field(init=False)
    data: pd.DataFrame = field(init=False)
    fig: Figure = field(init=False)

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
        df = utils.filter(df, {"case": "reference"})        
        # Rename fuels, aggregate, and calculate net change
        df['F'] = df['G'].map(cfg.GenFuelMap)

        df = utils.rename_values(df, {"F": cfg.FUEL_NAMES})
        df = utils.aggregate(df, ["T","F"], ["level"])
        df["level"] = df["level"] * SCALE

        # Assign country and policy data
        df = df.assign(country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True
        )  # .values() if renamed, .keys() if not

        # Clean up
        df = df[["country", "policy", "T", "F", "level"]]
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


def exclude_empty_category(df: pd.DataFrame, category: str) -> pd.DataFrame:
    exist_category = df.groupby(category)["level"].sum()
    idx_exist = exist_category[exist_category != 0].index
    df = df[df[category].isin(idx_exist)]
    return df


def format_yaxis(
    axes: List[Axes], y_range: Tuple[float, float], y_step: float, title: str
) -> None:
    axes[0].set_ylabel(title, fontweight="bold")
    axes[0].set_ylim(y_range)
    y_ticks = np.arange(y_range[0], y_range[1] + y_step, y_step)
    axes[0].set_yticks(y_ticks)
    for ax in axes:
        ax.grid(axis="y", linestyle="--", linewidth=0.5, alpha=0.5)


def get_legend_elements(axes: List[Axes]) -> Tuple[List, List]:
    handles, labels = axes[0].get_legend_handles_labels()
    for ax in axes[1:]:
        ax_handles, ax_labels = ax.get_legend_handles_labels()
        if labels != ax_labels:
            print("Labels of subplots are not identical. Exiting...")
            break
    print("Labels of subplots are identical across subplots.")
    return handles, labels


def axes_coordinates(
    axes: List[Axes],
) -> Tuple[Tuple[float, float, float], Tuple[float, float, float]]:
    plt.tight_layout()
    left = axes[0].get_position().x0
    right = axes[-1].get_position().x1
    bottom = axes[0].get_position().y0
    top = axes[0].get_position().y1
    center_x = (right + left) / 2
    center_y = (top + bottom) / 2
    return (left, right, center_x), (bottom, top, center_y)


def legend_dimensions(fig: Figure, legend: Legend) -> Tuple[float, float]:
    legend_dimensions = legend.get_window_extent(
        renderer=fig.canvas.get_renderer()  # type: ignore
    ).transformed(fig.transFigure.inverted())
    return legend_dimensions.width, legend_dimensions.height


# ----- Main -----
def main():
    scenarios = read_scenarios(scnParsFilePath)
    for scenario in scenarios:
        scenario.get_data(var)
        scenario.process_data()

        Fuel_order = ['Mun. waste', 'Biomass', 'Coal', 'Electricity', 'Oil products', 'Other', 'Natural gas']
        scenario.data['F'] = pd.Categorical(scenario.data['F'], categories=Fuel_order, ordered=True)

    for scenario in scenarios:
        country = scenario.country
        policy = scenario.policy
        scenario.data = exclude_empty_category(scenario.data, "F")
        scenario.data = scenario.data.pivot(index="T", columns="F", values="level")
        daily_data = scenario.data.groupby(np.arange(len(scenario.data)) // 24).sum()

        # Optionally, reset the index if needed
        daily_data = daily_data.reset_index(drop=True)

        scenario.fig, ax = plt.subplots(figsize=(width/2.54, height/2.54))
        daily_data.plot(kind='bar', stacked=True, ax=ax, color=cfg.FUEL_COLORS, width=1)

        # read a new dataframe 
        demand = pd.read_csv("data/common/ts-demand-heat.csv", header=None,names=['T','Demand'], index_col=0)
        demand = demand.groupby(np.arange(len(demand)) // 24).sum()

        # overlay a line plot in which every point is 10000
        ax.plot(demand.index, demand["Demand"], color='black', linewidth=0.5)


        ax.set_ylabel(y_title, fontweight="bold")
        ax.set_ylim(y_range)
        y_ticks = np.arange(y_range[0], y_range[1] + y_step, y_step)
        ax.set_yticks(y_ticks)
        ax.grid(axis="y", linestyle="--", linewidth=0.5, alpha=0.5)

        ax.set_title(f"{country}, {policy}", fontweight="bold")
        ax.set_xticks(range(0, len(demand), 30))

        ax.set_xticklabels([])

        # scenario.fig = fig
        if save:
            plt.savefig(f"{out_dir}/{plot_name}_{scenario.country}_{scenario.policy}.png", dpi=DPI)
        if show:
            plt.show()

    # for scenario in scenarios:
        # if save:
            # plt.savefig(f"{out_dir}/{plot_name}_{scenario.country}_{scenario.policy}.png", dpi=DPI)
        # if show:
            # plt.show()


if __name__ == "__main__":
    # modify process_data() for specific plot
    # modify exclude_empty_category() for specific plot
    save = True
    show = False

    PROJECT = "BASE"
    scnParsFilePath = f"data/{PROJECT}/{PROJECT}_scnpars.csv"
    var = "x_h"
    SCALE = 1  # MWh/MWh


    width = 19  # cm
    height = 10  # cm
    DPI = 900

    y_range = (0, 50000)
    y_step = 10000
    y_title = "Daily heat Production [MWh]"

    out_dir = rf"C:/Users/jujmo/OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article/diagrams/plots/{PROJECT}/tsHeatProd"
    Path(out_dir).mkdir(parents=True, exist_ok=True)
    plot_name = "tsHeatProd"

    main()
