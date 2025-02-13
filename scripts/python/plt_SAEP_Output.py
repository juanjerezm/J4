import csv
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List

import pandas as pd
import plt_config as cfg
import utilities as utils
import utilities_plotting as utils_plot
from matplotlib import pyplot as plt

# ----- Matplotlib settings -----
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 8


@dataclass
class ScenarioParams:
    """
    Represents the parameters for a scenario.

    Attributes:
        name (str): The name of the scenario.
        project (str): The project associated with the scenario.
        country (str): The country associated with the scenario.
        policy (str): The policy associated with the scenario.
    """

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
        df = utils.aggregate(df, ["case", "G"], ["level"])
        df = utils.diff(df, "case", "reference", "level")
        df = utils.filter(df, include={"G": "HR_DC"})
        df["level"] = df["level"] * VALUE_SCALING
        df["level"] = df["level"].round(2)

        # Assign country and policy data
        df = df.assign(project=self.project, country=self.country, policy=self.policy)
        df = utils.rename_values(df, {"policy": cfg.POLICIES})
        df["policy"] = pd.Categorical(
            df["policy"], categories=cfg.POLICIES.values(), ordered=True  # type: ignore
        )  # .values() if renamed, .keys() if not

        # Clean up
        df = df.drop(columns=["case"])
        df = df[["project", "country", "policy", "level"]]
        self.data = df
        return
    

def load_scenario_params(file_path: Path) -> List[ScenarioParams]:
    """Read scenario parameters from a csv-file and return a list of ScenarioParams objects."""
    scenarios = []
    with open(file_path, "r") as file:
        delimiter = csv.Sniffer().sniff(file.read()).delimiter
        file.seek(0)
        reader = csv.DictReader(file, delimiter=delimiter)
        for row_number, row in enumerate(
            reader, start=2
        ):  # Start from 2, skipping header row
            validate_row(row, row_number)
            scenario = ScenarioParams(**row)
            scenarios.append(scenario)
    return scenarios


def validate_row(row: Dict[str, str], row_number: int) -> None:
    """Validate that rows are not empty and do not contain missing values."""
    if not any(row.values()):
        raise ValueError(f"Empty line detected at row {row_number}")
    if not all(row.values()):
        raise ValueError(f"Missing value in row {row_number}: {row}")


def check_file_exist(file_path: Path) -> None:
    """Check if the input csv-file exists."""
    if not file_path.is_file():
        sys.exit("ERROR: Input csv-file not found, script has stopped.")


def summary_csv(df: pd.DataFrame, save: bool = False, outdir: Path = Path.cwd(), filename: str = '') -> None:
    df = df.copy()
    df['level'] = df['level'].round(3)
    df["project"] = df["project"].apply(lambda x: f"{int(x[4:])}")
    df = df.pivot(index=["country", "project"], columns="policy", values="level")
    df.rename_axis(index={"project": "year (electricity price)"}, inplace=True)

    print(df)

    if save:
        if not filename:
            raise ValueError("The 'filename' parameter is required when save=True.")
        
        outdir.mkdir(parents=True, exist_ok=True)
        output_path = outdir / f"{filename}.csv"
        df.to_csv(output_path)
        print(f"-> File saved to {output_path}")

    return


def main(param_files, var):
    # scenarios = []
    # # collecting data
    # for project in param_files:
    #     check_file_exist(Path(project))
    #     scenarios += load_scenario_params(Path(project))

    #     for scenario in scenarios:
    #         scenario.get_data(var)
    #         scenario.process_data()

    # df = pd.concat([scenario.data for scenario in scenarios], ignore_index=True)
    # df = utils.rename_values(df, {"country": cfg.COUNTRIES})
    # # save to csv
    # df.to_csv(f"{PLOTNAME}.csv", index=False)

    # read csv
    df = pd.read_csv(f"{PLOTNAME}.csv")

    summary_csv(df, save=True, outdir=OUTDIR / "plot-tables", filename="table-SAEP-Output")

    # creating figure
    fig, axes = plt.subplots(
        1,
        3,
        figsize=(FIGSIZE["width"] / 2.54, FIGSIZE["height"] / 2.54),
        sharey=True,
        sharex=True,
    )

    # drawing subplots
    for ax, country in zip(axes, cfg.COUNTRIES.values()):
        data = df[(df["country"] == country)]
        data = data.pivot(index="project", columns="policy", values="level")

        bar_width = 0.25  # Width of each bar
        x_indices = range(len(data.index))  # Indices for each project
        # order columns, first technical, then taxation, then support
        data = data[["Technical", "Taxation", "Support"]]

        # Plotting each policy as a separate bar
        for i, policy in enumerate(data.columns):
            ax.bar(
                [x + i * bar_width for x in x_indices],  # Bar positions
                data[policy],  # Bar heights
                width=bar_width,  # Bar width
                label=policy,  # Label for legend
            )

        ax.set_title(country, fontweight="bold")

    # x-axis formatting
    xticks = df["project"].unique()
    x_indices = range(len(xticks))
    ax.set_xticks([x + (len(data.columns) - 1) * bar_width / 2 for x in x_indices])
    ax.set_xticklabels([f"{int(x[4:])}" for x in xticks])
    for ax in axes:
        ax.set_xlabel(X_LABEL)
        ax.grid(axis="x", linestyle="--", linewidth=0.5, alpha=0.5)

    # y-axis formatting
    if FORMATTED_YAXIS:
        ax.set_yticks(
            range(Y_VALUES["min"], Y_VALUES["max"] + Y_VALUES["step"], Y_VALUES["step"])
        )
        ax.set_ylim([Y_VALUES["min"] - Y_VALUES["pad"], Y_VALUES["max"] + Y_VALUES["pad"]])
    for ax in axes:
        # ax.set_ylabel(Y_LABEL)
        ax.grid(axis="y", linestyle="--", linewidth=0.5, alpha=0.5)
    axes[0].set_ylabel(Y_LABEL)

    # legend formatting
    (_, _, x_center), (y_down, _, _) = utils_plot.axes_coordinates(axes)
    handles, labels = axes[0].get_legend_handles_labels()

    legend = fig.legend(
        handles,
        labels,
        loc="lower center",
        bbox_to_anchor=(x_center, 0),
        bbox_transform=fig.transFigure,
        ncol=len(handles),
        title="Scenario",
        title_fontproperties={"weight": "bold"},
    )

    # space adjustment
    _, legend_height = utils_plot.legend_dimensions(fig, legend)
    plt.subplots_adjust(wspace=0.125, bottom=(y_down + legend_height))


    # output
    utils_plot.output_plot(
        show=SHOW, save=SAVE, outdir=OUTDIR, plotname=PLOTNAME, dpi=DPI
    )


if __name__ == "__main__":
    SAVE = True
    SHOW = False

    PLOTNAME = "SensitivityEP_Output"
    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "diagrams"
        / "plots"
    )

    FIGSIZE = {"width": 16, "height": 7}  # cm
    DPI = 900

    VALUE_SCALING = 1e-3  # MWh/GWh

    FORMATTED_YAXIS = True
    Y_VALUES = {"min": 0, "max": 35, "step": 5, "pad":0}
    Y_LABEL = "Heat-recovery output [GWh/year]"
    X_LABEL = "Year (electricity price)"

    MARKERS = {
        "Technical": ("o", 4),    # Circle
        "Taxation": ("^", 4),     # Triangle
        "Support": ("s", 4)       # Square
    }

    runs = ["SAEP2018", "SAEP2019", "SAEP2020", "SAEP2021", "SAEP2022", "SAEP2023"]
    param_files = [f"data/{run}/{run}_scnpars.csv" for run in runs]

    main(param_files, 'x_h')
