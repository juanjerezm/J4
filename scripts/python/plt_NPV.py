# Standard library imports
from calendar import c
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
        df["level"] = df["level"] * SCALE

        # Assign country and policy data
        df = df.assign(country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True
        )  # .values() if renamed, .keys() if not

        # Clean up
        df = df.drop(columns=["case"])
        df = df[["country", "policy", "E", "level"]]
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

    df = pd.concat([scenario.data for scenario in scenarios], ignore_index=True)
    df = exclude_empty_category(df, "E")

    fig, axes = plt.subplots(1, 3, figsize=(width / 2.54, height / 2.54), sharey=True)

    bar_width = 0.35


    for ax, country in zip(axes, cfg.COUNTRIES):
        data = df[df["country"] == country]
        data = data.pivot(index="policy", columns="E", values="level")

        # Plot grouped bars instead of stacked
        positions = np.arange(len(data.index))
        for i, entity in enumerate(data.columns):
            ax.bar(positions + i * bar_width, data[entity], bar_width, label=entity, color=cfg.EntityPallete[entity])

        ax.set_title(f"{cfg.COUNTRIES[country]}", fontweight="bold")
        ax.set_xticks(positions + bar_width / 2)  # Center x-ticks between grouped bars
        ax.set_xticklabels(data.index, rotation=90)
        ax.set_xlabel("")

    if FORMAT_YAXIS:
        format_yaxis(axes, y_range, y_step, y_title)

    (_, _, x_center), (y_down, _, _) = axes_coordinates(axes)

    handles, labels = get_legend_elements(axes)

    legend = fig.legend(
        handles,
        labels,
        loc="lower center",
        bbox_to_anchor=(x_center, 0),
        bbox_transform=fig.transFigure,
        ncol=3,
        title="Entity",
        title_fontproperties={"weight": "bold"},
    )

    _, legend_height = legend_dimensions(fig, legend)
    plt.subplots_adjust(wspace=0.1, bottom=(y_down + legend_height))

    if save:
        plt.savefig(f"{out_dir}/{plot_name}.png", dpi=DPI)
    if show:
        plt.show()


if __name__ == "__main__":
    # modify process_data() for specific plot
    # modify exclude_empty_category() for specific plot
    save = False
    show = True
    FORMAT_YAXIS = True

    scnParsFilePath = "C:/Users/juanj/GitHub/PhD/J4 - model/results/B0/B0_scnpars.csv"
    var = "NPV"
    SCALE = 1e-6  # M€/€


    width = 8.5  # cm
    height = 10  # cm
    DPI = 900

    y_range = (0, 15)
    y_step = 3
    y_title = "NPV [M€]"

    out_dir = "C:/Users/juanj/OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article/diagrams/plots"
    plot_name = "NPV"

    main()
