from pathlib import Path

import pandas as pd

from scripts.analysis.core.io import load_consolidation_jobs, save_consolidated_results
from scripts.analysis.core.schemas import Mappings
from scripts.analysis.core.tables import order_dataframe, relabel_dimensions
from scripts.analysis.core.transforms import run_transform
from scripts.infra.paths_2 import PATHS
from scripts.modeling.scenario_loader import load_scenarios
from scripts.modeling.schemas import Runset, Scenario


def collect_results(
    scenarios: list[Scenario],
    metric: str,
    results_dir: Path = PATHS.model.results,
) -> pd.DataFrame:
    """Load one metric CSV for each scenario and append scenario metadata columns."""
    frames: list[pd.DataFrame] = []

    for s in scenarios:
        metric_path = results_dir / s.id / "csv" / f"{metric}.csv"
        if not metric_path.is_file():
            raise FileNotFoundError(f"Metric file not found: {metric_path}")

        df = pd.read_csv(metric_path)
        df = df.assign(
            ID=s.id, COUNTRY=s.country, POLICY=s.policytype, OVERRIDE=s.override
        )

        if "Val" in df.columns:  # if csv produced by gdxdump pipeline
            df = df.rename(columns={"Val": "value"})

        frames.append(df)

    if not frames:
        return pd.DataFrame()

    return pd.concat(frames, ignore_index=True)


def main(runset_path: Path, catalog_path: Path) -> None:
    # TODO: Check inputting strategy for the following:
    # - runset_path,
    # - catalog_path,
    # - metrics_path,
    # - analysis "MAIN",
    # - and "consolidations.yml"

    analysis_scope = PATHS.analysis.scope("sadr")
    mappings = Mappings.from_dir(PATHS.analysis.mappings)

    runset = Runset.from_yaml(runset_path)
    scenarios = load_scenarios(catalog_path, runset)

    # TODO: rename var below after inputs are handled
    metrics_path = analysis_scope.config / "consolidations.yml"
    consolidation_jobs = load_consolidation_jobs(metrics_path)

    print("===== Metric Consolidation Pipeline =====\n")
    print(f"Selected runset: {runset_path}")
    print(f"Selected scenario catalog: {catalog_path}\n")
    print(f"Consolidating across {len(scenarios)} scenarios:")
    for idx, scenario in enumerate(scenarios, start=1):
        print(f"  {idx}. {scenario.id}")
    print()

    for idx, job in enumerate(consolidation_jobs, start=1):
        print(f"[{idx}/{len(consolidation_jobs)}] Consolidating '{job.name}'")
        df = collect_results(scenarios, metric=job.name)

        # Relabeling before transform (aggregation) to ensure correct grouping
        df = relabel_dimensions(df, mappings)
        df = run_transform(df, job.transform)
        df = order_dataframe(df, mappings, sort_by=job.transform.groupby)

        output_path = save_consolidated_results(df, analysis_scope.tables, job.name)
        print(f"[{idx}/{len(consolidation_jobs)}] Saved to: {output_path}\n")
