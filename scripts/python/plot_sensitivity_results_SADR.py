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


# ----- Functions -----
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate plots for sensitivity analysis (SADR) results by country and policy."
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

    # --- summarise results ---
    if plot_spec.name == "SADR_NPV":
        pass
    if plot_spec.name == "SADR_HeatProduction":
        print(data)
        include = {"G": "HR_DC"}
        data = utils.filter(data, include=include)
        data = utils.diff(data, "case", "reference", "level")
        print(data)
    else:
        pass

    data["level"] = (data["level"] * scale).round(6)

    # --- set categorical types for ordered plotting ---
    countries = list(mappings["country_labels"].values())
    policies = list(mappings["policy_labels"].values())

    data["country"] = pd.Categorical(
        data["country"], categories=countries, ordered=True
    )
    data["policy"] = pd.Categorical(data["policy"], categories=policies, ordered=True)

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
        df = df.pivot_table(
            index="project", columns="policy", values="level", observed=True
        )
        for policy in df.columns:
            # reversed mapping to find policy model name
            inverse_label_map = {v: k for k, v in mappings["policy_labels"].items()}
            policy_model_name = inverse_label_map[policy]
            df[policy].plot(
                ax=ax,
                linewidth=LINEWIDTH,
                marker=mappings["policy_markers"][policy_model_name],
                markersize=MARKERSIZE,
                markerfacecolor="white",
                legend=False,
            )

        # --- axis formatting ---
        on_edge = utils_plot.subplot_edges(r_idx, c_idx, n_rows, n_cols)
        ax.set_title(country_label, fontweight="bold")

        # --- x-axis ---
        xticks = data["project"].unique()
        ax.set_xlabel("Discount rate (%)")
        ax.set_xlim([0, len(xticks) - 1])
        ax.set_xticks(range(len(xticks)))
        ax.set_xticklabels([f"{int(x[4:])}%" for x in xticks])
        ax.grid(True, axis="x", which="major", **utils_plot.GRID_STYLES["major"])

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
# QUICKRUN_ARGS = {"specification_path": "configs/plots/SADR_NPV.yml"}
QUICKRUN_ARGS = {"specification_path": "configs/plots/SADR_HeatProduction.yml"}


if __name__ == "__main__":
    if len(sys.argv) == 1:
        main(**QUICKRUN_ARGS)
    else:
        args = _parse_args()
        main(**vars(args))
