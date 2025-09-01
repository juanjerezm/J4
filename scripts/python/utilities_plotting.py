from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import matplotlib as mpl
import numpy as np
import yaml
from matplotlib import pyplot as plt
from matplotlib.artist import Artist
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from matplotlib.legend import Legend

# =============================================================================
# CONSTANTS
# =============================================================================

GRID_STYLES = {
    "major": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.9},
    "minor": {"linestyle": ":", "linewidth": 0.5, "alpha": 0.5},
}


# =============================================================================
# DATACLASSES
# =============================================================================
@dataclass(frozen=True)
class AxisParams:
    """Axis parameters for a plot axis."""

    min: float | None = None
    max: float | None = None
    pad: float | None = None
    major_ticks: Sequence[float] | None = None
    minor_ticks: Sequence[float] | None = None
    major_grid: bool = False
    minor_grid: bool = False
    label: str = ""
    label_kwargs: dict[str, Any] | None = None
    ticklabel_transform: Callable[[float], str] | None = None
    ticklabel_kwargs: dict[str, Any] | None = None


@dataclass(frozen=True)
class PlotSpecs:
    """Plot specification settings"""

    name: str
    show: bool = True
    save: bool = False
    width: float | None = None  # in centimeters
    height: float | None = None  # in centimeters
    autoscale: bool = True
    x1: AxisParams | None = None
    x2: AxisParams | None = None
    y1: AxisParams | None = None
    y2: AxisParams | None = None

    def figsize(self) -> tuple[float, float]:
        """Figure size in inches, falling back to rcParams when a dim is None."""
        dw, dh = mpl.rcParams["figure.figsize"]
        w = dw if self.width is None else self.width / 2.54
        h = dh if self.height is None else self.height / 2.54
        return (w, h)


# =============================================================================
# LEGEND UTILITIES
# =============================================================================
def legend_entries(
    axes: Axes | Iterable[Axes], order: list[str] | None = None
) -> tuple[list[Artist], list[str]]:
    """
    Collect legend entries from all subplots, de-duplicate by label (first handle wins),
    then return handles/labels sorted alphabetically by label.
    """
    # normalize input axes to an iterable of Axes
    if isinstance(axes, np.ndarray):
        ax_iter = axes.flat
    elif isinstance(axes, Axes):
        ax_iter = (axes,)  # wrap single Axes into a 1-tuple
    else:
        ax_iter = axes  # assume it's already iterable (like list)

    # collect legend entries without duplicates
    legend_entries: dict[str, Artist] = {}
    for ax in ax_iter:
        handles, labels = ax.get_legend_handles_labels()
        for handle, label in zip(handles, labels, strict=True):
            if label and label not in legend_entries:
                legend_entries[label] = handle

    # sort labels by custom order, alphabetically otherwise
    if order is not None:
        priority = {label: i for i, label in enumerate(order)}
        labels_sorted = sorted(
            legend_entries.keys(),
            key=lambda lbl: (priority.get(lbl, float("inf")), lbl),
        )
    else:
        labels_sorted = sorted(legend_entries.keys())

    # Sort handles based on sorted labels
    handles_sorted = [legend_entries[label] for label in labels_sorted]
    return handles_sorted, labels_sorted


def legend_dimensions(fig: Figure, legend: Legend) -> tuple[float, float]:
    """
    Return the width and height of a legend in figure coordinates.
    """
    bbox_fig = legend.get_window_extent(
        renderer=fig.canvas.get_renderer()  # type: ignore
    ).transformed(fig.transFigure.inverted())
    return bbox_fig.width, bbox_fig.height


# =============================================================================
# AXES UTILITIES
# =============================================================================
def axes_coordinates(
    axes: Axes | Iterable[Axes] | np.ndarray,
) -> tuple[tuple[float, float, float], tuple[float, float, float]]:
    """
    Return ((left, right, center_x), (bottom, top, center_y)) in figure coords
    covering all provided axes.
    """

    plt.tight_layout()
    axes_iter = list(np.atleast_2d(axes).flat)  # type: ignore

    left = min(ax.get_position().x0 for ax in axes_iter)
    right = max(ax.get_position().x1 for ax in axes_iter)
    bottom = min(ax.get_position().y0 for ax in axes_iter)
    top = max(ax.get_position().y1 for ax in axes_iter)
    center_x = (left + right) / 2
    center_y = (bottom + top) / 2

    return (left, right, center_x), (bottom, top, center_y)


def subplot_edges(r_idx: int, c_idx: int, n_rows: int, n_cols: int) -> dict[str, bool]:
    """Returns edge flags indicating if the subplot is on the edge of the grid."""
    return {
        "top": r_idx == 0,
        "bottom": r_idx == n_rows - 1,
        "left": c_idx == 0,
        "right": c_idx == n_cols - 1,
    }


def configure_xaxis(
    ax: Axes,
    params: AxisParams | None,
    show_label: bool,
    show_ticklabels: bool,
    autoscaling: bool,
) -> None:
    """Configures x-axis limits, ticks, grids, and labels."""

    if params is None:
        return  # nothing to do, leave axis untouched

    # Axis label
    if show_label:
        ax.set_xlabel(params.label, **(params.label_kwargs or {}))
    else:
        ax.xaxis.label.set_visible(False)

    # Return if autoscaling is enabled
    if autoscaling:
        return

    # Remaining code is applicable only if user specifies scaling
    # Limits
    pad = 0.0 if params.pad is None else params.pad
    left = None if params.min is None else params.min - pad
    right = None if params.max is None else params.max + pad
    if params.min is not None or params.max is not None:
        ax.set_xlim(left=left, right=right)

    # Ticks
    if params.major_ticks is not None:
        ax.set_xticks(params.major_ticks)
    if params.minor_ticks is not None:
        ax.set_xticks(params.minor_ticks, minor=True)

    # Tick labels
    if show_ticklabels and params.major_ticks is not None:
        if params.ticklabel_transform is not None:
            labels = [params.ticklabel_transform(x) for x in params.major_ticks]
        else:
            labels = [str(x) for x in params.major_ticks]
        ax.set_xticklabels(labels, **(params.ticklabel_kwargs or {}))
    else:
        ax.tick_params(axis="x", labelbottom=False)

    # Grids
    if params.major_grid:
        ax.grid(True, axis="x", which="major", **GRID_STYLES["major"])
    if params.minor_grid:
        ax.grid(True, axis="x", which="minor", **GRID_STYLES["minor"])
    ax.set_axisbelow(True)


def configure_yaxis(
    ax: Axes,
    params: AxisParams | None,
    show_label: bool,
    show_ticklabels: bool,
    autoscaling: bool,
) -> None:
    """Configures y-axis limits, ticks, grids, and labels."""

    if params is None:
        return  # nothing to do, leave axis untouched

    # Axis label
    if show_label:
        ax.set_ylabel(params.label, **(params.label_kwargs or {}))
    else:
        ax.yaxis.label.set_visible(False)

    # Return if autoscaling is enabled
    if autoscaling:
        return

    # Remaining code is applicable only if user specifies scaling
    # Limits
    pad = 0.0 if params.pad is None else params.pad
    bottom = None if params.min is None else params.min - pad
    top = None if params.max is None else params.max + pad
    if params.min is not None or params.max is not None:
        ax.set_ylim(bottom=bottom, top=top)

    # Ticks
    if params.major_ticks is not None:
        ax.set_yticks(params.major_ticks)
    if params.minor_ticks is not None:
        ax.set_yticks(params.minor_ticks, minor=True)

    # Tick labels
    if show_ticklabels and params.major_ticks is not None:
        if params.ticklabel_transform is not None:
            labels = [params.ticklabel_transform(y) for y in params.major_ticks]
        else:
            labels = [str(y) for y in params.major_ticks]
        ax.set_yticklabels(labels, **(params.ticklabel_kwargs or {}))
    else:
        ax.tick_params(axis="y", labelleft=False)

    # Grids
    if params.major_grid:
        ax.grid(True, axis="y", which="major", **GRID_STYLES["major"])
    if params.minor_grid:
        ax.grid(True, axis="y", which="minor", **GRID_STYLES["minor"])
    ax.set_axisbelow(True)


def output_plot(
    plotname: str = "defaultPlot",
    outdir: Path | str = Path(),
    show: bool = True,
    save: bool = False,
    dpi: int | None = None,
) -> None:
    """
    Saves and/or displays the current matplotlib plot.

    Args:
        show (bool, optional): Whether to display the plot.
        save (bool, optional): Whether to save the plot to file.
        outdir (Path | str, optional): Directory where the plot should be saved.
        plotname (str, optional): Name of the plot file (without extension).
        dpi (int, optional): Resolution in DPI for the saved plot.
            If None, uses matplotlib's rcParams["savefig.dpi"].
    """
    if save and (not outdir or not plotname):
        raise ValueError("Both 'outdir' and 'plotname' are required when save=True.")

    if save:
        path = Path(outdir) / f"{plotname}.png"
        path.parent.mkdir(parents=True, exist_ok=True)

        # This is necessary to avoid overriding matplotlib's rcParams
        save_kwargs = {"dpi": dpi} if dpi is not None else {}

        plt.savefig(path, **save_kwargs)
        print(f"-> Plot saved to {path}")
    if show:
        plt.show()


# =============================================================================
# YAML loaders
# =============================================================================
def set_matplotlib_style(path: str, name: str) -> None:
    """
    Load a style dictionary from YAML and apply it to Matplotlib rcParams.

    Args:
        path: Path to the YAML file containing style definitions.
        name: The key in the YAML file identifying the desired style.
    """
    with Path(path).open("r") as f:
        styles = yaml.safe_load(f) or {}
    rc = styles[name]

    # Convert figsize in cm to inches
    if "figure.figsize" in rc:
        w_cm, h_cm = rc.pop("figure.figsize")
        rc["figure.figsize"] = (w_cm / 2.54, h_cm / 2.54)

    mpl.rcParams.update(rc)


def load_mappings(path: str | Path) -> dict:
    """
    Load a YAML config file and return its contents as a dictionary.
    """
    with Path(path).open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}

    country_labels = {k: v["label"] for k, v in raw["countries"].items()}
    policy_labels = {k: v["label"] for k, v in raw["policies"].items()}
    policy_markers = {k: v["marker"] for k, v in raw["policies"].items()}
    genfuel_map = {k: v["fuel"] for k, v in raw["generators"].items()}
    fuel_labels = {k: v["label"] for k, v in raw["fuels"].items()}
    fuel_group_color = {k: v["color"] for k, v in raw["fuel_groups"].items()}
    entity_colors = {k: v["color"] for k, v in raw["entities"].items()}
    project_labels = {k: v["label"] for k, v in raw["projects"].items()}

    return {
        "country_labels": country_labels,
        "policy_labels": policy_labels,
        "policy_markers": policy_markers,
        "genfuel_map": genfuel_map,
        "fuel_labels": fuel_labels,
        "fuel_group_color": fuel_group_color,
        "entity_colors": entity_colors,
        "project_labels": project_labels,
    }


def fetch_projects(analysis: str) -> dict:
    """
    Load project configuration for a given analysis from YAML.

    Args:
        analysis: Key identifying the analysis to fetch.

    Returns:
        dict: A dictionary with {"name": analysis, ...analysis_config}.
    """
    config_path = Path("configs/globals/analyses.yml")
    with config_path.open() as f:
        config: dict = yaml.safe_load(f)["analyses"]
    return {"name": analysis, **config[analysis]}


def load_plot_config(path: str) -> tuple[dict, PlotSpecs]:
    """
    Load a YAML file containing both run-time args and a nested plot specification under 'plot'.

    Returns:
        run_args (dict): remaining keys from the YAML
        plot_spec (PlotSpecs): structured plotting config.
    """

    with Path(path).open("r", encoding="utf-8") as f:
        raw_spec = yaml.safe_load(f) or {}

    plot_config = raw_spec.pop("plot", {})

    # Validate and build AxisParams objects
    for axis_key in ("x1", "x2", "y1", "y2"):
        axis_config = plot_config.get(axis_key)
        if axis_config is None:
            continue
        if isinstance(axis_config, dict):
            plot_config[axis_key] = load_axis_params(axis_config)
            continue
        raise TypeError(
            f"{axis_key} must be a dict or null; got {type(axis_config).__name__}"
        )

    run_args = raw_spec  # what's left aside the plot specs
    plot_config = PlotSpecs(**plot_config)

    return run_args, plot_config


def load_axis_params(axis_dict: dict) -> AxisParams:
    """
    Convert a raw axis configuration dictionary into an AxisParams object.

    - Builds a tick label transform if `ticklabel_format` (+ optional scale)
      is specified.
    - Expands tick specifications given as dicts with
      {"start": ..., "stop": ..., "step": ...} into explicit lists.
    - Passes all other fields through unchanged.

    Args:
        axis_dict: Raw axis configuration parsed from YAML.

    Returns:
        AxisParams: A structured axis configuration.
    """
    axis_dict = dict(axis_dict)

    # --- turn ticklabel_format + ticklabel_scale into a transform function ---
    fmt_spec = axis_dict.pop("ticklabel_format", None)
    if fmt_spec is not None:
        fmt_spec = "{" + fmt_spec + "}" if "{" not in fmt_spec else fmt_spec
        scale = float(axis_dict.pop("ticklabel_scale", 1.0))
        axis_dict["ticklabel_transform"] = (
            lambda x, _fmt=fmt_spec, _s=scale: _fmt.format(x * _s)
        )

    # --- convert ticks specified as dict into list of values ---
    for key in ("major_ticks", "minor_ticks"):
        ticks = axis_dict.get(key)
        if isinstance(ticks, dict):
            start, stop, step = ticks["start"], ticks["stop"], ticks["step"]
            eps = np.sign(step) * abs(step) * 1e-6
            axis_dict[key] = list(np.arange(start, stop + eps, step))

    return AxisParams(**axis_dict)
