import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import utilities as utils
import utilities_plotting as utils_plot
from matplotlib import pyplot as plt

# ----- Globals -----
GLOBAL_STYLE_PATH = "configs/globals/plot_styles.yml"
MAPPING_PATH = "configs/globals/mappings.yml"
LINEWIDTH = 1
MARKERSIZE = 4
BARWIDTH = 0.25


# ----- Functions -----
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate plots for sensitivity analysis (SAEP) results by country and policy."
    )
    p.add_argument("--specification_path", type=str, help="Path to specification file.")
    return p.parse_args()


# ----- Main -----
def main(*, specification_path: str) -> None:
    """
    Load and prepare results from sensitivity analyses. Produce line plots by country,
    categorised by policy.
    """
    # --- load configs ---
    utils_plot.set_matplotlib_style(GLOBAL_STYLE_PATH, "paper-2col")
    mappings = utils_plot.load_mappings(MAPPING_PATH)
    run_args, plot_spec = utils_plot.load_plot_config(specification_path)
    project, var, scale = run_args["project"], run_args["var"], run_args["scale"]

    # --- setup paths ---
    data_path = Path("results-consolidated") / project / f"consolidated-table-{var}.csv"
    outdir = Path("results-consolidated") / project / "plots"

    # --- read results ---
    data = pd.read_csv(data_path)

    # --- standardize dataframe ---
    data = data.rename(columns={"CASE": "case", "value": "level"})

    # -- replace model names by human-readable labels ---
    data["country"] = data["country"].map(mappings["country_labels"])
    data["project"] = data["project"].map(mappings["project_labels"])

    # --- summarise results ---
    if plot_spec.name == "SAEP_NPV":
        pass
    if plot_spec.name == "SAEP_HeatProduction":
        include = {"G": "HR_DC"}
        data = utils.filter(data, include=include)
        data = utils.diff(data, "case", "reference", "level")
    else:
        pass

    data["level"] = (data["level"] * scale).round(6)

    # --- set categorical types for ordered plotting ---
    countries = list(mappings["country_labels"].values())
    policies = list(mappings["policy_labels"].values())
    projects = list(mappings["project_labels"].values())

    data["country"] = pd.Categorical(
        data["country"], categories=countries, ordered=True
    )
    data["policy"] = pd.Categorical(data["policy"], categories=policies, ordered=True)
    data["project"] = pd.Categorical(data["project"], categories=projects, ordered=True)

    # --- consolidate and output plot's data ---
    utils.output_table(
        data,
        index=["country", "policy"],
        columns=["project"],
        values="level",
        show=plot_spec.show,
        save=plot_spec.save,
        outdir=outdir,
        filename=plot_spec.name,
    )

    n_rows, n_cols = 1, len(countries)
    fig, axes = plt.subplots(
        nrows=n_rows,
        ncols=n_cols,
        figsize=plot_spec.figsize(),
        squeeze=False,
        sharex=True,
        sharey=True,
    )

    # --- loop over countries/subplots ---
    for (r_idx, c_idx), ax in np.ndenumerate(axes):
        country_label = countries[c_idx]

        # --- filter and plot data ---
        df = data[data["country"] == country_label]
        # Reindex to ensure all projects are present in the correct order
        df = df.pivot_table(
            index="project", columns="policy", values="level", observed=True
        ).reindex(projects)

        x_indices = range(len(projects))  # Indices for each project

        for i, policy in enumerate(df.columns):
            ax.bar(
                [x + i * BARWIDTH for x in x_indices],  # Bar positions
                df[policy],  # Bar heights
                width=BARWIDTH,
                label=policy,
            )

        # --- axis formatting ---
        on_edge = utils_plot.subplot_edges(r_idx, c_idx, n_rows, n_cols)
        ax.set_title(country_label, fontweight="bold")

        # --- x-axis ---
        ax.set_xlabel("Electricity Price")
        ax.set_xticks([x + (len(df.columns) - 1) * BARWIDTH / 2 for x in x_indices])
        ax.set_xticklabels(projects)

        # --- y-axis ---
        utils_plot.configure_yaxis(
            ax,
            plot_spec.y1,
            show_label=on_edge["left"],
            show_ticklabels=on_edge["left"],
            autoscaling=plot_spec.autoscale,
        )

    (_, _, x_center), (y_down, _, _) = utils_plot.axes_coordinates(axes)

    handles, labels = utils_plot.legend_entries(axes, order=policies)
    legend = fig.legend(
        handles,
        labels,
        loc="lower center",
        bbox_to_anchor=(x_center, 0),
        bbox_transform=fig.transFigure,
        ncol=3,
        title="Policy Scenario",
        title_fontproperties={"weight": "bold"},
    )
    _, legend_height = utils_plot.legend_dimensions(fig, legend)

    plt.subplots_adjust(wspace=0.125, bottom=(y_down + legend_height))

    utils_plot.output_plot(
        show=plot_spec.show, save=plot_spec.save, outdir=outdir, plotname=plot_spec.name
    )


# Default arguments for quick development runs in VS Code
# Bypasses CLI parsing if script is executed without arguments.
QUICKRUN_ARGS = {}
# QUICKRUN_ARGS = {"specification_path": "configs/plots/SAEP_NPV.yml"}
# QUICKRUN_ARGS = {"specification_path": "configs/plots/SAEP_HeatProduction.yml"}


if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = _parse_args()
        main(**vars(args))
