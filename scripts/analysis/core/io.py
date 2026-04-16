from pathlib import Path

import matplotlib as mpl
import pandas as pd
import yaml

from scripts.analysis.core.schemas import ConsolidationJob, PlotSpec


# ---------- consolidation pipeline ----------
def load_consolidation_jobs(path: Path) -> list[ConsolidationJob]:
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
        # TODO: check if or {} is needed above, it helps handling empty files but may mask other issues

    return [ConsolidationJob.from_dict(item) for item in raw["consolidations"]]


def save_consolidated_results(df: pd.DataFrame, outdir: Path, metric_name: str) -> Path:
    outdir.mkdir(parents=True, exist_ok=True)
    output_path = outdir / f"{metric_name}.csv"
    df.to_csv(output_path, index=False)
    return output_path


# ---------- plotting pipeline ----------
def load_plot_spec(path: Path) -> PlotSpec:
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}
        # TODO: check if or {} is needed above, it helps handling empty files but may mask other issues

    return PlotSpec.from_dict(raw["plot"])


def apply_matplotlib_style(style_name: str | None, path: Path) -> None:
    """Apply a named style from YAML to matplotlib rcParams."""

    if style_name is None:
        return

    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    styles = raw["plot-styles"]

    if style_name not in styles:
        available = ", ".join(sorted(styles.keys()))
        msg = f"Style '{style_name}' not found in {path}. Available styles: {available}"
        raise ValueError(msg)

    mpl.rcParams.update(styles[style_name])
