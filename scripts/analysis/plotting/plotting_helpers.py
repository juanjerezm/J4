from collections.abc import Callable, Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.artist import Artist
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from matplotlib.legend import Legend
from matplotlib.ticker import FuncFormatter
from matplotlib.transforms import Bbox

from scripts.analysis.core.schemas import AxisSpec, Mappings
from scripts.analysis.core.tables import DIMENSION_CONFIG

# ===== GRID STYLE CONFIGURATION =====
# TODO: check where they should live and how should be applied
GRID_STYLES = {
    "major": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.9},
    "minor": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.5},
}


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


def format_numeric_axis(
    ax: Axes,
    axis: str,
    spec: AxisSpec | None,
    show_label: bool = True,
    show_ticklabels: bool = True,
) -> None:
    """Configure either the x- or y-axis of a plot from an AxisSpec.

    This function supports two modes based on the `autoscale` parameter:
        1. Presentation mode (autoscale=False): limits, ticks, and tick
           formatting from the spec are applied.
        2. Exploratory mode (autoscale=True): matplotlib chooses limits
           and ticks automatically.

    """
    if spec is None:
        return

    # Determine axis-specific functions and parameters
    if axis == "x":
        set_label: Callable[..., Any] = ax.set_xlabel
        set_limits: Callable[..., Any] = ax.set_xlim
        set_ticks: Callable[..., Any] = ax.set_xticks
        axis_obj = ax.xaxis
        hide_ticklabels_kwargs = {"axis": "x", "labelbottom": False}
        limit_keys = ("left", "right")
        grid_axis = "x"
    elif axis == "y":
        set_label = ax.set_ylabel
        set_limits = ax.set_ylim
        set_ticks = ax.set_yticks
        axis_obj = ax.yaxis
        hide_ticklabels_kwargs = {"axis": "y", "labelleft": False}
        limit_keys = ("bottom", "top")
        grid_axis = "y"
    else:
        raise ValueError("axis must be 'x' or 'y'")

    # Axis label
    if show_label:
        set_label(spec.label, **(spec.label_kwargs or {}))
    else:
        axis_obj.label.set_visible(False)

    # Presentation mode: apply manual limits, ticks, and formatting
    if not spec.autoscale:
        # Limits with optional padding
        pad = 0.0 if spec.pad is None else spec.pad
        bottom = None if spec.min is None else spec.min - pad
        top = None if spec.max is None else spec.max + pad

        if spec.min is not None or spec.max is not None:
            set_limits(**{limit_keys[0]: bottom, limit_keys[1]: top})

        # Ticks positions
        if spec.major_ticks is not None:
            set_ticks(spec.major_ticks)

        if spec.minor_ticks is not None:
            set_ticks(spec.minor_ticks, minor=True)

    # Ticklabel formatting and visibility
    if spec.ticklabel_format is not None:
        fmt = spec.ticklabel_format
        axis_obj.set_major_formatter(FuncFormatter(lambda value, _: fmt.format(value)))

    if not show_ticklabels:
        ax.tick_params(**hide_ticklabels_kwargs)

    # Grid
    if spec.major_grid:
        ax.grid(True, axis=grid_axis, which="major", **GRID_STYLES["major"])

    if spec.minor_grid:
        ax.grid(True, axis=grid_axis, which="minor", **GRID_STYLES["minor"])

    ax.set_axisbelow(True)


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
    axes: Axes | Iterable[Axes] | np.ndarray,
    order: list[str] | None = None,
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


# def choose_legend_ncol(
#     fig: Figure,
#     handles: list[Artist],
#     labels: list[str],
#     axes_bounds: AxesBounds,
#     legend_kwargs: dict[str, Any],
# ) -> int:
#     """
#     Pick the largest ncol whose rendered legend stays inside the axis span.

#     Falls back to 1 column if no candidate fits.
#     """
#     if not labels:
#         return 1

#     max_cols = len(labels)
#     legend: Legend | None = None

#     for ncol in range(max_cols, 0, -1):
#         if legend is not None:
#             legend.remove()

#         legend = fig.legend(handles=handles, labels=labels, ncol=ncol, **legend_kwargs)

#         fig.canvas.draw()
#         bbox = legend_bbox(fig, legend)

#         fits_left = axes_bounds.left <= bbox.xmin
#         fits_right = bbox.xmax <= axes_bounds.right

#         if fits_left and fits_right:
#             legend.remove()
#             return ncol

#     if legend is not None:
#         legend.remove()

#     return 1


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
