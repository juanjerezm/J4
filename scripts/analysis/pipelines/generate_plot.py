from dataclasses import asdict
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.figure import Figure

from scripts.analysis.core.io import apply_matplotlib_style, load_plot_spec
from scripts.analysis.core.plotting_helpers import (
    AxesBounds,
    SubplotEdges,
    build_plot_table,
    draw_subplot_clusters,
    draw_subplot_line,
    draw_subplot_stack,
    get_series_colors,
    get_series_markers,
    legend_bbox,
    legend_entries,
    prepare_panel_data,
    save_plot,
)
from scripts.analysis.core.schemas import Mappings, PlotSpec
from scripts.analysis.core.tables import DIMENSION_CONFIG, order_dataframe
from scripts.analysis.core.transforms import run_transform
from scripts.infra.dirs import DIRS


def build_figure(data: pd.DataFrame, plot_spec: PlotSpec, mappings: Mappings) -> Figure:
    """
    Build a multi-panel figure and place a shared legend below it.

    The function prepares one subplot per panel, delegates panel rendering to
    the subplot drawing function, and adjusts layout so the shared legend fits
    below the figure without overlap.

    Args:
        data: Canonical plot table containing all panels, groups, and series.
        plot_spec: Plot specification with panel structure, layout, and axis settings.
        mappings: Mapping object containing optional color mappings.

    Returns:
        A matplotlib Figure containing all panels and the shared legend.
    """
    # Extract structure
    panel_col = plot_spec.structure.panel_col
    group_col = plot_spec.structure.group_col
    series_col = plot_spec.structure.series_col

    # Compute panel data matrices
    panel_matrices = prepare_panel_data(data, panel_col, group_col)

    # Prepare subplot call
    if plot_spec.kind == "cluster_bar":
        colors = get_series_colors(mappings, series_col)
        draw_kwargs = {"colors": colors}
        draw_panel = draw_subplot_clusters
    elif plot_spec.kind == "stacked_bar":
        colors = get_series_colors(mappings, series_col)
        draw_kwargs = {"colors": colors}
        draw_panel = draw_subplot_stack
    elif plot_spec.kind == "line":
        markers = get_series_markers(mappings, series_col)
        colors = get_series_colors(mappings, series_col)
        draw_kwargs = {"colors": colors, "markers": markers}
        draw_panel = draw_subplot_line
    else:
        raise ValueError(f"Unsupported plot kind: {plot_spec.kind}")

    # Create figure grid
    nrows, ncols = 1, len(panel_matrices)
    figsize = plot_spec.figsize_inches

    fig, axes = plt.subplots(
        nrows=nrows, ncols=ncols, figsize=figsize, squeeze=False, sharey=True
    )

    # Draw each panel, still assumes 1 row of panels
    for (r_idx, c_idx), ax in np.ndenumerate(axes):
        on_edge = SubplotEdges.from_grid(r_idx, c_idx, nrows, ncols)
        label, data = panel_matrices[c_idx]
        draw_panel(data, ax, label, **draw_kwargs, plot_spec=plot_spec, on_edge=on_edge)

    # Get axes bounds in figure coords
    fig.tight_layout()
    axes_bounds = AxesBounds.from_axes(axes)

    # Configure legend
    handles, labels = legend_entries(axes)
    legend_kwargs = {
        "loc": "lower center",
        "bbox_to_anchor": (axes_bounds.center_x, 0),
        "bbox_transform": fig.transFigure,
        "title": get_legend_title(series_col),
        "title_fontproperties": {"weight": "bold"},
    }

    # Iteratively draw legend with decreasing ncol until it fits within axes bounds
    legend = None
    for ncol in range(len(labels), 0, -1):
        if legend is not None:
            legend.remove()

        legend = fig.legend(handles=handles, labels=labels, ncol=ncol, **legend_kwargs)

        fig.canvas.draw()  # Render to get accurate legend dimensions
        bbox = legend_bbox(fig, legend)

        fits_left = axes_bounds.left <= bbox.xmin
        fits_right = bbox.xmax <= axes_bounds.right
        if fits_left and fits_right:
            break  # Found the maximum ncol that fits

    legend_height = 0.0 if legend is None else legend_bbox(fig, legend).height
    fig.subplots_adjust(wspace=0.1, bottom=(axes_bounds.bottom + legend_height + 0.01))

    return fig


def get_legend_title(series_col: str) -> str:
    """
    Get legend title from DIMENSION CONFIG, if `series_col` is defined and
    has a `legend_title` field. Otherwise, return `series_col` as default.
    """
    return DIMENSION_CONFIG.get(series_col, {}).get("legend_title", series_col.title())


def main(analysis: str, plotspec_path: Path) -> None:

    # Resolve paths and load configurations
    analysis_dirs = DIRS.get_analysis_dirs(analysis)
    plotspec_path = analysis_dirs.resolve(plotspec_path)
    plot_spec = load_plot_spec(plotspec_path)

    mappings = Mappings.from_dir(DIRS.analysis_shared / "mappings")
    apply_matplotlib_style(plot_spec.style, DIRS.analysis_shared / "plot-styles.yml")

    print("\n===== Plotting =====\n")
    print(f"Selected plot spec: {plotspec_path}")

    # Load and prepare plot input data
    dfs = []
    for input_spec in plot_spec.inputs:
        input_path = analysis_dirs.resolve(input_spec.path)
        df = pd.read_csv(input_path)

        if input_spec.transform is not None:
            df = run_transform(df, input_spec.transform)

        dfs.append(df)

    # Merge input data, sort, and format for plotting/output
    data = pd.concat(dfs, ignore_index=True)
    data = order_dataframe(data, mappings, sort_by=plot_spec.structure.sort_columns)
    table = build_plot_table(data, **asdict(plot_spec.structure))

    # Render the figure
    fig = build_figure(table, plot_spec, mappings)

    # Handle output
    if plot_spec.save:
        plot_path = analysis_dirs.figures / f"{plot_spec.name}.png"
        save_plot(fig, plot_path)

        table_path = analysis_dirs.figures / f"{plot_spec.name}.csv"
        table.to_csv(table_path, index=False)

    if plot_spec.show:
        plt.show()


if __name__ == "__main__":
    PLOTS_TO_RUN = [
        {"analysis": "main", "plot_file": "config/plot-NPV.yml"},
        {"analysis": "main", "plot_file": "config/plot-Carbon-Emissions-Change.yml"},
        {"analysis": "main", "plot_file": "config/plot-Fuel-Consumption-Change.yml"},
        {
            "analysis": "main",
            "plot_file": "config/plot-Fuel-Consumption-Change-includingCHP.yml",
        },
        {
            "analysis": "main",
            "plot_file": "config/plot-Electricity-Production-Change.yml",
        },
        {"analysis": "saep", "plot_file": "config/plot-SAEP-NPV.yml"},
        {"analysis": "saep", "plot_file": "config/plot-SAEP-Heat-Production.yml"},
        {"analysis": "sadr", "plot_file": "config/plot-SADR-NPV.yml"},
        {"analysis": "sadr", "plot_file": "config/plot-SADR-Heat-Production.yml"},
    ]

    for item in PLOTS_TO_RUN:
        main(item["analysis"], Path(item["plot_file"]))
