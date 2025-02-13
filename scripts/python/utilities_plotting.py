from pathlib import Path
from typing import List, Tuple

from matplotlib import pyplot as plt
from matplotlib.figure import Figure
from matplotlib.legend import Legend
import numpy as np
from matplotlib.axes import Axes


def format_yaxis(
    axes: List[Axes], y_range: Tuple[float, float], y_step: float, title: str
) -> None:
    axes[0].set_ylabel(title, fontweight="bold")
    axes[0].set_ylim(y_range)
    y_ticks = np.arange(y_range[0], y_range[1] + y_step, y_step)
    axes[0].set_yticks(y_ticks)
    for ax in axes:
        ax.grid(axis="y", linestyle="--", linewidth=0.5, alpha=0.5)


def get_legend_elements(axes: List[Axes]) -> Tuple[List, List]:
    handles, labels = axes[0].get_legend_handles_labels()
    for ax in axes[1:]:
        ax_handles, ax_labels = ax.get_legend_handles_labels()
        if labels != ax_labels:
            print("-> Labels of subplots are not identical. Exiting...")
            break
    print("-> Labels of subplots are identical across subplots. Building legend...")
    return handles, labels


def legend_dimensions(fig: Figure, legend: Legend) -> Tuple[float, float]:
    legend_dimensions = legend.get_window_extent(
        renderer=fig.canvas.get_renderer()  # type: ignore
    ).transformed(fig.transFigure.inverted())
    return legend_dimensions.width, legend_dimensions.height


def standardize_axes_type(axes) -> List[Axes]:
    if isinstance(axes, Axes):
        return [axes]
    elif isinstance(axes, np.ndarray):
        return axes.flatten().tolist()
    elif isinstance(axes, list):
        return axes
    else:
        raise TypeError(
            "axes must be an Axes object, a NumPy array, or a list of Axes objects."
        )


def axes_coordinates(
    axes,
) -> Tuple[Tuple[float, float, float], Tuple[float, float, float]]:
    plt.tight_layout()
    axes_list = standardize_axes_type(axes)
    # Collect all positions
    left_positions = [ax.get_position().x0 for ax in axes_list]
    right_positions = [ax.get_position().x1 for ax in axes_list]
    bottom_positions = [ax.get_position().y0 for ax in axes_list]
    top_positions = [ax.get_position().y1 for ax in axes_list]

    left = min(left_positions)
    right = max(right_positions)
    bottom = min(bottom_positions)
    top = max(top_positions)
    center_x = (right + left) / 2
    center_y = (top + bottom) / 2

    return (left, right, center_x), (bottom, top, center_y)


def output_plot(
    show: bool = True,
    save: bool = False,
    outdir: Path | str = Path(),
    plotname: str = "defaultPlot",
    dpi: int = 600,
) -> None:
    """
    Saves and/or displays the current matplotlib plot.

    Args:
        show (bool, optional): Whether to display the plot. Defaults to True.
        save (bool, optional): Whether to save the plot to file. Defaults to False.
        outdir (Path | str, optional): Directory where the plot should be saved.
            Defaults to the current working directory.
        plotname (str, optional): Name of the plot file (without extension).
            Defaults to "defaultPlot".
        dpi (int, optional): Resolution in DPI for the saved plot. Defaults to 600.

    Raises:
        ValueError: If save=True but outdir or plotname are missing.

    Returns:
        None
    """
    if save:
        if not outdir or not plotname:
            raise ValueError(
                "Both 'outdir' and 'plotname' are required when save=True."
            )
        outdir = Path(outdir)
        outdir.mkdir(parents=True, exist_ok=True)
        plt.savefig(outdir / f"{plotname}.png", dpi=dpi)
        print(f"-> Plot saved to {outdir}/{plotname}.png")
    if show:
        plt.show()
