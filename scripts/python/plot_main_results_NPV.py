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
BAR_WIDTH = 0.35


# ----- Functions -----
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate plot of NPV results by country, policy, and entity."
    )
    p.add_argument("--specification_path", type=str, help="Path to specification file.")
    return p.parse_args()


def summarize_results(
    scenario: utils.Scenario, scale: float, mappings: dict
) -> pd.DataFrame:
    """
    Summarize scenario results into a standardized DataFrame aggregated by entity category,
    with columns ['country', 'policy', 'E', 'level'].
    """

    df = scenario.results

    # --- assign scenario metadata ---
    df = df.assign(country=scenario.country, policy=scenario.policy)

    # -- replace model names by human-readable labels ---
    df["country"] = df["country"].map(mappings["country_labels"])
    df["policy"] = df["policy"].map(mappings["policy_labels"])

    # --- standardize dataframe ---
    df = df.rename(columns={"CASE": "case", "value": "level"})

    # --- summarise results ---
    df["level"] = (df["level"] * scale).round(6)

    # --- set categorical types for ordered plotting ---
    countries = list(mappings["country_labels"].values())
    policies = list(mappings["policy_labels"].values())

    df["country"] = pd.Categorical(df["country"], categories=countries, ordered=True)
    df["policy"] = pd.Categorical(df["policy"], categories=policies, ordered=True)

    scenario.results = df
    return df


# ----- Main -----
def main(*, specification_path: str) -> None:
    """
    Load scenarios, summarize results, and produce bar plots by country and policy,
    categorised by entity.
    """

    # --- load configs ---
    utils_plot.set_matplotlib_style(GLOBAL_STYLE_PATH, "paper-1col")
    mappings = utils_plot.load_mappings(MAPPING_PATH)
    run_args, plot_spec = utils_plot.load_plot_config(specification_path)
    project, var, scale = run_args["project"], run_args["var"], run_args["scale"]

    # --- setup paths ---
    scenario_path = Path("data") / project / "scenario_parameters.csv"
    outdir = Path("results-consolidated") / project / "plots"

    # --- process scenarios ---
    scenario_list = utils.read_scenarios(scenario_path)
    result_summaries = []
    for scenario in scenario_list:
        scenario.load_results(var)
        result_summaries.append(summarize_results(scenario, scale, mappings))

    # --- consolidate and output plot's data ---
    df_all = pd.concat(result_summaries, ignore_index=True)
    utils.output_table(
        df_all,
        index=["country", "E"],
        columns=["policy"],
        values="level",
        show=plot_spec.show,
        save=plot_spec.save,
        outdir=outdir,
        filename=plot_spec.name,
    )

    countries = list(mappings["country_labels"].values())
    color = mappings["entity_colors"]

    n_rows, n_cols = 1, len(countries)
    fig, axes = plt.subplots(
        nrows=n_rows,
        ncols=n_cols,
        figsize=plot_spec.figsize(),
        squeeze=False,
        sharey=True,
    )

    # --- loop over countries/subplots ---
    for (r_idx, c_idx), ax in np.ndenumerate(axes):
        country_label = countries[c_idx]

        # --- filter and plot data ---
        df = df_all[df_all["country"] == country_label]
        df = df.pivot_table(index="policy", columns="E", values="level", observed=True)
        df = df.loc[:, df.sum() != 0]  # exclude empty categories
        positions = np.arange(len(df.index))
        for i, entity in enumerate(df.columns):
            ax.bar(
                positions + i * BAR_WIDTH,
                df[entity],
                BAR_WIDTH,
                label=entity,
                color=color[entity],
            )

        # --- axis formatting ---
        on_edge = utils_plot.subplot_edges(r_idx, c_idx, n_rows, n_cols)
        ax.set_title(country_label, fontweight="bold")

        # --- x-axis ---
        ax.set_xticks(positions + BAR_WIDTH / 2)  # Center x-ticks between grouped bars
        ax.set_xticklabels(df.index, rotation=90)
        ax.xaxis.label.set_visible(False)

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
        title="Entity",
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
QUICKRUN_ARGS = {"specification_path": "configs/plots/Main_NPV.yml"}

if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = _parse_args()
        main(**vars(args))
