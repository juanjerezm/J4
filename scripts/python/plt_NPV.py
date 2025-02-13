# Standard library imports
from pathlib import Path

# Third-party library imports
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

# Local/custom module imports
import plt_config as cfg
import utilities as utils
import utilities_plotting as utils_plot
from utilities import Scenario

# ----- Matplotlib settings -----
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 8


# ----- Functions -----
def summarize_results(scenario: Scenario) -> pd.DataFrame:
    """
    Summarize the 'results' DataFrame in a Scenario by:
    1. Mapping and renaming fuels.
    2. Aggregating results.
    3. Computing differences from a reference scenario.
    4. Scaling the 'level' column.
    5. Assigning country and policy metadata.
    6. Returning the final summarized DataFrame.

    Args:
        scenario (Scenario): An object containing 'results' (pandas DataFrame)
            and attributes 'country' and 'policy'.

    Returns:
        pd.DataFrame: The summarized results.
    """
    df = scenario.results

    df["level"] = df["level"] * SCALE
    df['level'] = df['level'].round(6) # just to remove any negligible difference

    # Assign country and policy to summarised results
    df = df.assign(country=scenario.country, policy=scenario.policy)
    df = utils.rename_values(df, {"policy": cfg.POLICIES})
    df["policy"] = pd.Categorical(df["policy"], categories=cfg.POLICIES.values(), ordered=True)  # .values() if renamed, .keys() if not

    # Clean up
    df = df.drop(columns=["case"])
    df = df[["country", "policy", "E", "level"]]

    scenario.results = df
    return df




# ----- Main -----
def main():

    scenarios = utils.read_scenarios(SCENARIO_PARAMETERS)
    for scenario in scenarios:
        scenario.load_results(VAR)
        summarize_results(scenario)

    # Consolidate results across scenarios
    df = pd.concat([scenario.results for scenario in scenarios], ignore_index=True)
    utils.output_table(df, index=["country", "E"], show=SHOW, save=SAVE, outdir=OUTDIR, filename=NAME)
    df = utils.exclude_empty_category(df, "E")

    fig, axes = plt.subplots(1, 3, figsize=(FIGSIZE[0] / 2.54, FIGSIZE[1] / 2.54), sharey=True)

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
        utils_plot.format_yaxis(axes, Y_RANGE, Y_STEP, Y_TITLE)

    (_, _, x_center), (y_down, _, _) = utils_plot.axes_coordinates(axes)

    handles, labels = utils_plot.get_legend_elements(axes)

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

    _, legend_height = utils_plot.legend_dimensions(fig, legend)
    plt.subplots_adjust(wspace=0.1, bottom=(y_down + legend_height))

    utils_plot.output_plot(
        show=SHOW, save=SAVE, outdir=OUTDIR, plotname=NAME, dpi=DPI
    )


if __name__ == "__main__":

    PROJECT = "BASE"
    SCENARIO_PARAMETERS = f"data/{PROJECT}/{PROJECT}_scnpars.csv"

    SAVE = True
    SHOW = False

    VAR = "NPV"
    SCALE = 1e-6  # M€/€

    FIGSIZE = (8.5, 9) # width, heigth in cm
    DPI = 900

    FORMAT_YAXIS = True
    Y_RANGE = (0, 12)
    Y_STEP = 3
    Y_TITLE = "NPV [M€]"

    NAME = "NPV"
    OUTDIR = (
        Path.home()
        / "OneDrive - Danmarks Tekniske Universitet/Papers/J4 - article"
        / "diagrams"
        / "plots"
        / PROJECT
    )


    main()
