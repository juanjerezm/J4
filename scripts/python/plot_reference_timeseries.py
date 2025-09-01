import argparse
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import utilities as utils
import utilities_plotting as utils_plot

# ----- Globals -----
GLOBAL_STYLE_PATH = "configs/globals/plot_styles.yml"
MAPPING_PATH = "configs/globals/mappings.yml"
LINEWIDTH = 0
BARWIDTH = 1
MERIT_ORDER = [
    "Mun. waste",
    "Other",
    "Biomass",
    "Electricity",
    "Natural gas",
    "Oil products",
]


# ----- Functions -----
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate timeseries plot by country, and fuel."
    )
    p.add_argument("--specification_path", type=str, help="Path to specification file.")
    return p.parse_args()


def summarize_results(
    scenario: utils.Scenario, scale: float, mappings: dict
) -> pd.DataFrame:
    """
    Summarize results for a specific scenario, providing dataframe with columns
    country, policy, D (aggregated from T), F, and level.
    """
    df = scenario.results

    # --- assign scenario metadata ---
    df = df.assign(country=scenario.country, policy=scenario.policy)

    # --- standardize dataframe ---
    df = df.rename(columns={"CASE": "case", "value": "level"})

    # -- replace model names by human-readable labels ---
    df["country"] = df["country"].map(mappings["country_labels"])
    df["policy"] = df["policy"].map(mappings["policy_labels"])
    df["F"] = df["F"].map(mappings["fuel_labels"])  # individual fuels into fuel groups

    # --- summarise results ---
    df = utils.filter(df, include={"case": ["reference"]})
    df = utils.aggregate(df, ["country", "T", "F"], ["level"])

    # Aggregate by day and fuel group
    df["T_int"] = df["T"].str.extract(r"(\d+)").astype(int)
    df["D_int"] = np.ceil(df["T_int"] / 24).astype(int)  # 1..365

    df_day = df.groupby(["country", "D_int", "F"], as_index=False).agg({"level": "sum"})
    df_day["D"] = "D" + (df_day["D_int"].astype(str).str.zfill(3))
    df_day["level"] = (df_day["level"] * scale).round(6)
    df_day = df_day[["country", "D", "F", "level"]]

    # --- set categorical types for ordered plotting ---
    df_day["F"] = pd.Categorical(df_day["F"], categories=MERIT_ORDER, ordered=True)
    df_day = df_day.sort_values(by=["D", "F"]).reset_index(drop=True)

    scenario.results = df_day
    return df_day


# ----- Main -----
def main(*, specification_path: str):
    """
    Generate timeseries plots for a specific variable.
    """

    # --- load configs ---
    utils_plot.set_matplotlib_style(GLOBAL_STYLE_PATH, "paper-1col")
    mappings = utils_plot.load_mappings(MAPPING_PATH)
    run_args, plot_spec = utils_plot.load_plot_config(specification_path)
    project, var, scale = run_args["project"], run_args["var"], run_args["scale"]

    # --- setup paths ---
    scenario_path = Path("data") / project / "scenario_parameters.csv"
    outdir = Path("results-consolidated") / project / "plots"

    scenario_list = utils.read_scenarios(scenario_path)
    result_summaries = []
    for scenario in scenario_list:
        if scenario.policy != "socioeconomic":
            continue
        scenario.load_results(var)
        result_summaries.append(summarize_results(scenario, scale, mappings))

    # --- consolidate and output plot's data ---
    df_all = pd.concat(result_summaries, ignore_index=True)

    df_out = df_all.copy()
    fuels = sorted(df_out["F"].unique())
    df_out["F"] = pd.Categorical(values=df_out["F"], categories=fuels, ordered=True)

    utils.output_table(
        df_out,
        index=["F"],
        columns=["country"],
        values="level",
        aggfunc="sum",
        show=plot_spec.show,
        save=plot_spec.save,
        outdir=outdir,
        filename="Reference_HeatProduction",
    )

    countries = list(mappings["country_labels"].values())
    color = mappings["fuel_group_color"]

    n_rows, n_cols = len(countries), 1

    fig, axes = plt.subplots(
        n_rows, n_cols, figsize=plot_spec.figsize(), squeeze=False, sharey=True
    )

    # --- loop over countries/subplots ---
    for (r_idx, c_idx), ax in np.ndenumerate(axes):
        country_label = countries[r_idx]

        # --- filter and plot data ---
        df = df_all[df_all["country"] == country_label]
        df = df.pivot_table(index="D", columns="F", values="level", observed=True)
        df.plot(
            kind="bar",
            stacked=True,
            ax=ax,
            legend=False,
            color=color,
            linewidth=LINEWIDTH,
            width=BARWIDTH,
        )

        # --- axis formatting ---
        on_edge = utils_plot.subplot_edges(r_idx, c_idx, n_rows, n_cols)
        ax.set_title(country_label, fontweight="bold")

        # --- x-axis ---
        month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        month_boundaries = np.cumsum(month_days)  # [31, 59, 90, ..., 365]
        month_ticks = np.concatenate(([0], month_boundaries - 1))

        ax.set_xticks(month_ticks)
        ax.set_xticklabels([])
        ax.set_xlabel("")
        ax.set_xlim(0, 364)

        if on_edge["bottom"]:
            ax.set_xlabel("Year")

        # --- y-axis ---
        utils_plot.configure_yaxis(
            ax,
            plot_spec.y1,
            show_label=on_edge["left"],
            show_ticklabels=on_edge["left"],
            autoscaling=plot_spec.autoscale,
        )

    (_, _, x_center), (y_down, _, _) = utils_plot.axes_coordinates(axes)

    handles, labels = utils_plot.legend_entries(axes)
    legend = fig.legend(
        handles,
        labels,
        loc="lower center",
        bbox_to_anchor=(x_center, 0),
        bbox_transform=fig.transFigure,
        ncol=3,
        title="Fuel",
        title_fontproperties={"weight": "bold"},
    )
    _, legend_height = utils_plot.legend_dimensions(fig, legend)

    plt.subplots_adjust(wspace=0.1, bottom=(y_down + legend_height))

    utils_plot.output_plot(
        show=plot_spec.show, save=plot_spec.save, outdir=outdir, plotname=plot_spec.name
    )


# Default arguments for quick development runs in VS Code
# Bypasses CLI parsing if script is executed without arguments.
QUICKRUN_ARGS = {}
QUICKRUN_ARGS = {
    "specification_path": "configs/plots/MAIN_HeatProductionTimeseries.yml"
}

if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = _parse_args()
        main(**vars(args))
