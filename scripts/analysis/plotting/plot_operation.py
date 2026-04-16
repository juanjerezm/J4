from dataclasses import asdict

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.axes import Axes
from matplotlib.figure import Figure

from scripts.analysis.core.io import apply_matplotlib_style, load_plot_spec
from scripts.analysis.core.schemas import Mappings, PlotSpec
from scripts.analysis.core.tables import DIMENSION_CONFIG, order_dataframe
from scripts.analysis.core.transforms import run_transform
from scripts.analysis.plotting.plotting_helpers import (
    AxesBounds,
    SubplotEdges,
    build_plot_table,
    format_numeric_axis,
    get_series_colors,
    legend_bbox,
    legend_entries,
    prepare_panel_data,
    save_plot,
    show_plot,
)
from scripts.infra.paths_2 import PATHS


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

    # Prepare colors
    colors = get_series_colors(mappings, series_col)

    # Create figure grid
    nrows, ncols = 1, len(panel_matrices)
    figsize = plot_spec.figsize_inches

    fig, axes = plt.subplots(
        nrows=nrows, ncols=ncols, figsize=figsize, squeeze=False, sharey=True
    )

    # Draw each panel, still assumes 1 row of panels
    for (r_idx, c_idx), ax in np.ndenumerate(axes):
        on_edge = SubplotEdges.from_grid(r_idx, c_idx, nrows, ncols)
        panel_label, panel_data = panel_matrices[c_idx]
        draw_subplot_stack(panel_data, ax, panel_label, colors, plot_spec, on_edge)

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


def draw_subplot_stack(
    df: pd.DataFrame,
    ax: Axes,
    panel_label: str,
    colors: dict[str, str] | None,
    plot_spec: PlotSpec,
    on_edge: SubplotEdges,
) -> None:
    """
    Draw stacked bars in a subplot.

    Renders series as stacked bars, grouped by index values.
    Skips series with all-zero values to keep visualization clean.

    Applies axis formatting over a categorical x-axis and a numeric y-axis.
    """

    df.plot(kind="bar", stacked=True, ax=ax, legend=False, color=colors)

    # Configure subplot appeareance
    ax.set_title(panel_label, fontweight="bold")

    # Configure x-axis
    ax.set_xticklabels(df.index, rotation=90)
    ax.xaxis.label.set_visible(False)

    # Configure y-axis
    on_left = on_edge.left
    format_numeric_axis(
        ax, axis="y", spec=plot_spec.y1, show_label=on_left, show_ticklabels=on_left
    )


def main() -> None:
    # TODO: input handling for:
    # - analysis "MAIN",
    # - plot spec "plot-NPV.yml",

    # check docstirng again when all pipelines are finished
    """
    Run the plotting pipeline end-to-end.

    Loads plot spec and style, reads and transforms data inputs,
    builds the canonical plot table, renders the panel figure, and
    optionally saves outputs or shows the plot.
    """

    # Resolve paths and load configurations
    analysis_scope = PATHS.analysis.scope("main")

    mappings = Mappings.from_dir(PATHS.analysis.mappings)

    # plot_file = "plot-Heat-Production-Change.yml"
    # plot_file = "plot-Carbon-Emissions-Change.yml"
    # plot_file = "plot-Fuel-Consumption-Change.yml"
    # plot_file = "plot-Electricity-Production-Change.yml"
    plot_file = "plot-Fuel-Consumption-Change-withCHP.yml"

    plot_spec = load_plot_spec(analysis_scope.config / plot_file)
    apply_matplotlib_style(plot_spec.style, PATHS.analysis.plot_styles)

    # Load and prepare plot input data
    dfs = []
    for input_spec in plot_spec.inputs:
        input_path = analysis_scope.resolve(input_spec.path)
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
        plot_path = analysis_scope.figures / f"{plot_spec.name}.png"
        save_plot(fig, plot_path)

        table_path = analysis_scope.figures / f"{plot_spec.name}.csv"
        table.to_csv(table_path, index=False)

    if plot_spec.show:
        show_plot()


if __name__ == "__main__":
    main()
