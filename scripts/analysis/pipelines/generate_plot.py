from dataclasses import asdict
from pathlib import Path

import pandas as pd
from matplotlib import pyplot as plt

from scripts.analysis.core.dataframe_ops import order_dataframe
from scripts.analysis.core.io import apply_matplotlib_style, load_plot_spec
from scripts.analysis.core.mappings import Mappings
from scripts.analysis.core.plotting_helpers import (
    build_figure,
    build_plot_table,
    save_plot,
)
from scripts.analysis.core.transforms import run_transform
from scripts.infra.dirs import DIRS


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
