from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.artist import Artist
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from matplotlib.legend import Legend
from matplotlib.ticker import FuncFormatter
from matplotlib.transforms import Bbox

from scripts.analysis.core.schemas import AxisSpec, Mappings, PlotSpec
from scripts.analysis.core.tables import DIMENSION_CONFIG

# ===== GRID STYLE CONFIGURATION =====
# TODO: check where they should live and how should be applied
GRID_STYLES = {
    "major": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.9},
    "minor": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.5},
}


def format_xaxis(
    ax: Axes,
    spec: AxisSpec | None,
    show_label: bool = True,
    show_ticklabels: bool = True,
    ticklabels: Sequence[str] | None = None,
) -> None:
    """
    Configure the y-axis from an `AxisSpec`.

    Supports two axis kinds:
    - `categorical`: tick positions are derived from `ticklabels`.
    - `numerical`: manual limits/ticks/formatter are applied unless `autoscale` is enabled.
    """

    if spec is None:
        return

    # --- Validation of ticklabel source ---
    if spec.kind == "numerical" and ticklabels is not None:
        raise ValueError("Ticklabels not allowed for numeric axis")

    # --- Axis label ---
    if show_label and spec.label is not None:
        ax.set_xlabel(spec.label, **(spec.label_kwargs or {}))
        ax.xaxis.label.set_visible(True)
    else:
        ax.xaxis.label.set_visible(False)

    # --- Categorical axis ---
    if spec.kind == "categorical":
        # --- Tick positions (major only) ---
        if ticklabels is None:
            raise ValueError("Categorical axis requires ticklabels")
        if len(ticklabels) == 0:
            raise ValueError("Categorical axis requires at least one ticklabel")

        positions = np.arange(len(ticklabels), dtype=float)
        ax.set_xticks(positions)
        ax.set_xticklabels(ticklabels)

        # --- Axis limits ---
        if positions.size > 0:
            pad = 0.5 if spec.pad is None else spec.pad
            ax.set_xlim(left=positions[0] - pad, right=positions[-1] + pad)

    # --- Numeric axis ---
    elif spec.kind == "numerical":
        if spec.autoscale:  # Automatic limits and tick positions
            pass
        else:  # Manual limits and tick positions
            # --- Tick positions ---
            if spec.major_ticks is not None:
                ax.set_xticks(spec.major_ticks)
            if spec.minor_ticks is not None:
                ax.set_xticks(spec.minor_ticks, minor=True)

            # --- Axis limits ---
            if spec.min is not None or spec.max is not None:
                pad = 0.0 if spec.pad is None else spec.pad
                left = None if spec.min is None else spec.min - pad
                right = None if spec.max is None else spec.max + pad
                ax.set_xlim(left=left, right=right)

    else:
        raise ValueError(f"Unsupported axis kind: {spec.kind}")

    # --- Ticklabel visibility ---
    which = "major" if spec.kind == "categorical" else "both"
    ax.tick_params(axis="x", which=which, labelbottom=show_ticklabels)

    # --- Ticklabel formatting and styling ---
    if spec.kind == "numerical" and spec.ticklabel_format is not None:
        fmt = spec.ticklabel_format
        ax.xaxis.set_major_formatter(FuncFormatter(lambda value, _: fmt.format(value)))

    if spec.ticklabel_kwargs is not None:
        for lbl in ax.get_xticklabels():
            lbl.update(spec.ticklabel_kwargs)

    # --- Grid ---
    if spec.major_grid:
        ax.grid(True, axis="x", which="major", **GRID_STYLES["major"])

    if spec.minor_grid:
        ax.grid(True, axis="x", which="minor", **GRID_STYLES["minor"])

    ax.set_axisbelow(True)


def format_yaxis(
    ax: Axes,
    spec: AxisSpec | None,
    show_label: bool = True,
    show_ticklabels: bool = True,
    ticklabels: Sequence[str] | None = None,
) -> None:
    """
    Configure the y-axis from an `AxisSpec`.

    Supports two axis kinds:
    - `categorical`: tick positions are derived from `ticklabels`.
    - `numerical`: manual limits/ticks/formatter are applied unless `autoscale` is enabled.
    """

    if spec is None:
        return

    # --- Validation of ticklabel source ---
    if spec.kind == "numerical" and ticklabels is not None:
        raise ValueError("Ticklabels not allowed for numeric axis")

    # --- Axis label ---
    if show_label and spec.label is not None:
        ax.set_ylabel(spec.label, **(spec.label_kwargs or {}))
        ax.yaxis.label.set_visible(True)
    else:
        ax.yaxis.label.set_visible(False)

    # --- Categorical axis ---
    if spec.kind == "categorical":
        # --- Tick positions (major only) ---
        if ticklabels is None:
            raise ValueError("Categorical axis requires ticklabels")
        if len(ticklabels) == 0:
            raise ValueError("Categorical axis requires at least one ticklabel")

        positions = np.arange(len(ticklabels), dtype=float)
        ax.set_yticks(positions)
        ax.set_yticklabels(ticklabels)

        # --- Axis limits ---
        if positions.size > 0:
            pad = 0.5 if spec.pad is None else spec.pad
            ax.set_ylim(bottom=positions[0] - pad, top=positions[-1] + pad)

    # --- Numeric axis ---
    elif spec.kind == "numerical":
        if spec.autoscale:  # Automatic limits and tick positions
            pass
        else:  # Manual limits and tick positions
            # --- Tick positions ---
            if spec.major_ticks is not None:
                ax.set_yticks(spec.major_ticks)
            if spec.minor_ticks is not None:
                ax.set_yticks(spec.minor_ticks, minor=True)

            # --- Axis limits ---
            if spec.min is not None or spec.max is not None:
                pad = 0.0 if spec.pad is None else spec.pad
                bottom = None if spec.min is None else spec.min - pad
                top = None if spec.max is None else spec.max + pad
                ax.set_ylim(bottom=bottom, top=top)

    else:
        raise ValueError(f"Unsupported axis kind: {spec.kind}")

    # --- Ticklabel visibility ---
    which = "major" if spec.kind == "categorical" else "both"
    ax.tick_params(axis="y", which=which, labelleft=show_ticklabels)

    # --- Ticklabel formatting and styling ---
    if spec.kind == "numerical" and spec.ticklabel_format is not None:
        fmt = spec.ticklabel_format
        ax.yaxis.set_major_formatter(FuncFormatter(lambda value, _: fmt.format(value)))

    if spec.ticklabel_kwargs is not None:
        for lbl in ax.get_yticklabels():
            lbl.update(spec.ticklabel_kwargs)

    # --- Grid ---
    if spec.major_grid:
        ax.grid(True, axis="y", which="major", **GRID_STYLES["major"])

    if spec.minor_grid:
        ax.grid(True, axis="y", which="minor", **GRID_STYLES["minor"])

    ax.set_axisbelow(True)


def prepare_panel_data(
    data: pd.DataFrame, panel_col: str, group_col: str
) -> list[tuple[str, pd.DataFrame]]:
    """
    Split data into per-panel matrices, dropping series columns that are
    entirely zero across all panels.

    Returns an ordered list of (panel_label, matrix) pairs.
    """

    value_cols = [c for c in data.columns if c not in (panel_col, group_col)]
    zero_cols = [c for c in value_cols if (data[c] == 0).all()]
    data = data.drop(columns=zero_cols)

    result = []
    for label, panel_df in data.groupby(panel_col, sort=False):
        matrix = panel_df.drop(columns=panel_col).set_index(group_col)
        result.append((label, matrix))

    return result


def get_series_colors(mappings: Mappings, series_col: str) -> dict[str, str] | None:
    """Return optional ``{label: color}`` mapping for the selected series column."""
    mapping_name = DIMENSION_CONFIG.get(series_col, {}).get("mapping")
    if not mapping_name:
        return None

    try:
        return mappings.to_dict(mapping_name, "label", "color")
    except (AttributeError, TypeError, KeyError):
        return None


def get_series_markers(mappings: Mappings, series_col: str) -> dict[str, str] | None:
    """Return optional ``{label: marker}`` mapping for the selected series column."""
    mapping_name = DIMENSION_CONFIG.get(series_col, {}).get("mapping")
    if not mapping_name:
        return None

    try:
        return mappings.to_dict(mapping_name, "label", "marker")
    except (AttributeError, TypeError, KeyError):
        return None


def build_plot_table(
    df: pd.DataFrame,
    panel_col: str,
    group_col: str,
    series_col: str,
    value_col: str = "value",
) -> pd.DataFrame:
    """Build wide plot table: panel+series rows, groups as columns."""
    table = df.pivot_table(
        index=[panel_col, group_col],
        columns=series_col,
        values=value_col,
        aggfunc="sum",
        observed=True,
        fill_value=0.0,
    )
    return table.reset_index()


def draw_subplot_clusters(
    df: pd.DataFrame,
    ax: Axes,
    panel_label: str,
    colors: dict[str, str] | None,
    plot_spec: PlotSpec,
    on_edge: "SubplotEdges",
) -> None:
    """Draw clustered bars in a subplot."""

    group_names = df.index
    series_names = df.columns
    n_groups = len(group_names)
    n_series = len(series_names)

    group_width = 0.8
    bar_width = group_width / n_series
    group_positions = np.arange(n_groups)
    series_offsets = (np.arange(n_series) - (n_series - 1) / 2) * bar_width

    for offset, name in zip(series_offsets, series_names, strict=True):
        bar_kwargs = {"width": bar_width, "label": name}
        if colors and (color := colors.get(name)):
            bar_kwargs["color"] = color

        ax.bar(group_positions + offset, df[name].to_numpy(), **bar_kwargs)

    ax.set_title(panel_label, fontweight="bold")
    format_xaxis(ax, plot_spec.x1, on_edge.bottom, on_edge.bottom, list(group_names))
    format_yaxis(ax, plot_spec.y1, on_edge.left, on_edge.left, None)


def draw_subplot_stack(
    df: pd.DataFrame,
    ax: Axes,
    panel_label: str,
    colors: dict[str, str] | None,
    plot_spec: PlotSpec,
    on_edge: "SubplotEdges",
) -> None:
    """Draw stacked bars in a subplot."""

    df.plot(kind="bar", stacked=True, ax=ax, legend=False, color=colors)

    ax.set_title(panel_label, fontweight="bold")
    format_xaxis(ax, plot_spec.x1, on_edge.bottom, on_edge.bottom, list(df.index))
    format_yaxis(ax, plot_spec.y1, on_edge.left, on_edge.left, None)


def draw_subplot_line(
    df: pd.DataFrame,
    ax: Axes,
    panel_label: str,
    colors: dict[str, str] | None,
    markers: dict[str, str] | None,
    plot_spec: PlotSpec,
    on_edge: "SubplotEdges",
) -> None:
    """Draw lines in a subplot."""

    linewidth = 1
    markersize = 4
    markerfacecolor = "white"

    for col in df.columns:
        ax.plot(
            df.index,
            df[col],
            linewidth=linewidth,
            marker=markers.get(col, None) if markers else None,
            markersize=markersize,
            markerfacecolor=markerfacecolor,
            color=colors.get(col, None) if colors else None,
            label=col,
        )

    ax.set_title(panel_label, fontweight="bold")
    format_xaxis(ax, plot_spec.x1, on_edge.bottom, on_edge.bottom, list(df.index))
    format_yaxis(ax, plot_spec.y1, on_edge.left, on_edge.left, None)


@dataclass(frozen=True)
class SubplotEdges:
    """Flags indicating whether a subplot lies on the outer edges of a grid."""

    top: bool
    bottom: bool
    left: bool
    right: bool

    @classmethod
    def from_grid(cls, row: int, col: int, n_rows: int, n_cols: int) -> "SubplotEdges":
        """Return edge flags for a subplot at the given grid position."""
        top = row == 0
        bottom = row == n_rows - 1
        left = col == 0
        right = col == n_cols - 1

        return cls(top=top, bottom=bottom, left=left, right=right)


def normalize_axes(axes: Axes | Iterable[Axes] | np.ndarray) -> list[Axes]:
    """
    Return a Matplotlib collection of axes as a flat list.
    Use this when iterating over axes without needing to preserve their original
    subplot grid shape.

    This accepts the common squeezed outputs returned by ``plt.subplots``:
    - a single ``Axes``,
    - a 1D or 2D NumPy array of axes,
    - or another iterable of axes.
    """

    if isinstance(axes, Axes):
        return [axes]

    if isinstance(axes, np.ndarray):
        return list(axes.flat)

    return list(axes)


@dataclass(frozen=True)
class AxesBounds:
    """
    Bounding box of multiple axes in figure coordinates.

    The bounds describe the rectangular area occupied by one axis or by the
    full block of subplots, excluding external figure-level artists such as
    legends or suptitles.
    """

    left: float
    right: float
    bottom: float
    top: float

    @property
    def center_x(self) -> float:
        return (self.left + self.right) / 2

    @property
    def center_y(self) -> float:
        return (self.bottom + self.top) / 2

    @classmethod
    def from_axes(cls, axes: Axes | Iterable[Axes] | np.ndarray) -> "AxesBounds":
        """Compute bounds from the current position of all provided axes."""
        axes_iter = normalize_axes(axes)

        left = min(ax.get_position().x0 for ax in axes_iter)
        right = max(ax.get_position().x1 for ax in axes_iter)
        bottom = min(ax.get_position().y0 for ax in axes_iter)
        top = max(ax.get_position().y1 for ax in axes_iter)

        return cls(left=left, right=right, bottom=bottom, top=top)


def legend_bbox(fig: Figure, legend: Legend) -> Bbox:
    """
    Return legend bounding box in figure coordinates.

    The figure canvas must be drawn before calling this function,
    so text extents and legend layout are up to date.
    """

    renderer = fig.canvas.get_renderer()  # type: ignore
    bbox_pixels = legend.get_window_extent(renderer=renderer)  # Legend in display coord
    fig_coords = fig.transFigure.inverted()  # Transform from display to figure coords
    return bbox_pixels.transformed(fig_coords)  # Legend bounds in figure coords


def legend_entries(
    axes: Axes | Iterable[Axes] | np.ndarray, order: list[str] | None = None
) -> tuple[list[Artist], list[str]]:
    """
    Collect unique legend handles and labels from one or more axes.

    The first handle seen for each label is kept. If `order` is provided,
    labels included in `order` are returned first in that order, and any
    remaining labels are appended in plotting order.
    """
    handles_by_label: dict[str, Artist] = {}

    # Collect handles and labels from all axes, keeping only the first handle for each label
    for ax in normalize_axes(axes):
        handles, labels = ax.get_legend_handles_labels()

        for handle, label in zip(handles, labels, strict=True):
            if label and label not in handles_by_label:
                handles_by_label[label] = handle

    legend_labels = list(handles_by_label)

    # Reorder labels if an order is specified
    if order is not None:
        ordered_labels = [label for label in order if label in handles_by_label]
        remaining_labels = [label for label in legend_labels if label not in order]
        legend_labels = ordered_labels + remaining_labels

    # Get the corresponding handles in the same order as the ordered labels
    legend_handles = [handles_by_label[label] for label in legend_labels]

    return legend_handles, legend_labels


def save_plot(
    fig: Figure,
    path: Path | str,
    *,
    dpi: int | str | None = None,
    bbox_inches: str | None = None,
) -> None:
    """Save a Matplotlib figure, creating the output directory if needed."""
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    save_kwargs = {}

    if dpi is not None:
        save_kwargs["dpi"] = dpi

    if bbox_inches is not None:
        save_kwargs["bbox_inches"] = bbox_inches

    fig.savefig(output_path, **save_kwargs)


def show_plot() -> None:
    """Display all open Matplotlib figures."""
    plt.show()
