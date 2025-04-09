from matplotlib import pyplot as plt
import pandas as pd
from pathlib import Path
import utilities as utils
import plt_config as cfg
import utilities_plotting as utils_plot

# ----- Matplotlib settings -----
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["font.size"] = 8

# ----- Function definitions -----
def plot_sensitivity_NPV(file):

    data = pd.read_csv(file)

    renames = {"country": cfg.COUNTRIES, "policy": cfg.POLICIES, 'project': cfg.SAEP_PROJECTS}
    sorting = {"country": cfg.COUNTRIES.values(), "policy": cfg.POLICIES.values(), 'project': cfg.SAEP_PROJECTS.values()}

    data = utils.rename_values(data, renames)
    data["value"] = data["value"] * VALUE_SCALE

    data["country"] = pd.Categorical(
        data["country"], categories=sorting["country"], ordered=True
    )
    data["policy"] = pd.Categorical(
        data["policy"], categories=sorting["policy"], ordered=True
    )
    data['project'] = pd.Categorical(
        data['project'], categories=sorting["project"], ordered=True
    )

    #sort data by country, project, and policy
    data = data.sort_values(by=['country', 'project', 'policy'])

    # outputting table
    utils.output_table(data, SHOW, SAVE, DIR / "plots", OUTNAME, ['country', 'project'], ['policy'], 'value')

    # creating figure
    fig, axes = plt.subplots(
        1,
        3,
        figsize=(FIGSIZE[0] / 2.54, FIGSIZE[1] / 2.54),
        sharey=True,
        sharex=True,
    )

    # drawing subplots
    for ax, country in zip(axes, cfg.COUNTRIES.values()):
        df = data[(data["country"] == country)]
        df = df.pivot(index="project", columns="policy", values="value")
        # for policy in df.columns:
        #     df[policy].plot(ax=ax, linewidth=0.75, marker=MARKERS[policy][0], markersize=MARKERS[policy][1], markerfacecolor='none', legend=False)

        # Plotting each policy as a separate bar
        bar_width = 0.25
        x_indices = range(len(df.index))  # Indices for each project

        for i, policy in enumerate(df.columns):
            ax.bar(
                [x + i * bar_width for x in x_indices],  # Bar positions
                df[policy],  # Bar heights
                width=bar_width,  # Bar width
                label=policy,  # Label for legend
            )

        ax.set_title(country, fontweight="bold")

    # x-axis formatting
    xticks = data["project"].unique()
    x_indices = range(len(xticks))
    ax.set_xticks([x + (len(df.columns) - 1) * bar_width / 2 for x in x_indices])
    ax.set_xticklabels(xticks)
    # ax.set_xticklabels([f"{int(x[4:])}" for x in xticks])
    for ax in axes:
        ax.set_xlabel(X_LABEL)
        # ax.grid(axis="x", linestyle="--", linewidth=0.5, alpha=0.5)

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
    handles, labels = utils_plot.get_legend_elements(axes)

    legend = fig.legend(
        handles,
        labels,
        loc="lower center",
        bbox_to_anchor=(x_center, 0),
        bbox_transform=fig.transFigure,
        ncol=3,
        title="Scenario",
        title_fontproperties={"weight": "bold"},
    )

    # space adjustment
    _, legend_height = utils_plot.legend_dimensions(fig, legend)
    plt.subplots_adjust(wspace=0.125, bottom=(y_down + legend_height))

    # output
    utils_plot.output_plot(
        show=SHOW, save=SAVE, outdir=DIR / "plots", plotname=OUTNAME, dpi=DPI
    )

    return

if __name__ == "__main__":
    SENSITIVITY = "SAEP"

    VAR = "NPV_all"
    VALUE_SCALE = 1e-3  # k€ -> M€

    OUTNAME = f"SAEP_NPV_Plot"
    SHOW = True
    SAVE = True

    DIR = (
        Path.home()
        / "PhD/OneDrive/Papers/J4 - article"
        / "consolidated results"
        / SENSITIVITY
    )

    FIGSIZE = (16, 7)  # width, height in cm
    DPI = 900

    FORMATTED_YAXIS = True
    Y_VALUES = {"min": 0, "max": 40, "step": 10, "pad": 0}
    Y_LABEL = "NPV [M€]"
    X_LABEL = "Electricity Price"

    MARKERS = {
        "Technical": ("o", 4),    # Circle
        "Taxation": ("^", 4),     # Triangle
        "Policy": ("s", 4)       # Square
    }

    plot_sensitivity_NPV(DIR / f"consolidated-table-{VAR}.csv")
