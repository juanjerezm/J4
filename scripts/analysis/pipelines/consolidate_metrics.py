from pathlib import Path

import pandas as pd

from scripts.analysis.core.io import load_consolidation_jobs, save_consolidated_results
from scripts.analysis.core.schemas import ConsolidationJob, Mappings
from scripts.analysis.core.tables import order_dataframe, relabel_dimensions
from scripts.analysis.core.transforms import run_transform
from scripts.infra.paths_2 import PATHS
from scripts.modeling.scenario_loader import load_scenarios
from scripts.modeling.schemas import Runset, Scenario

SCENARIO_ATTRS = {
    "ID": "id",
    "OVERRIDE": "override",
    "COUNTRY": "country",
    "POLICY": "policytype",
}


def collect_results(
    scenarios: list[Scenario],
    job: ConsolidationJob,
    results_dir: Path = PATHS.model.results,
) -> pd.DataFrame:
    """Load one metric CSV for each scenario and append scenario metadata columns."""
    frames: list[pd.DataFrame] = []

    for s in scenarios:
        metric_path = results_dir / s.id / "csv" / f"{job.name}.csv"
        if not metric_path.is_file():
            raise FileNotFoundError(f"Metric file not found: {metric_path}")

        df = pd.read_csv(metric_path)

        scenario_metadata = {
            k: getattr(s, SCENARIO_ATTRS[k]) for k in job.scenario_metadata
        }
        df = df.assign(**scenario_metadata)

        if "Val" in df.columns:  # if csv produced by gdxdump pipeline
            df = df.rename(columns={"Val": "value"})

        frames.append(df)

    if not frames:
        return pd.DataFrame()

    return pd.concat(frames, ignore_index=True)


def main(
    scope: str,
    consolidation_job_path: Path,
    runset_path: Path,
    catalog_path: Path,
) -> None:

    analysis_scope = PATHS.analysis.scope(scope)
    resolved_spec_path = analysis_scope.resolve(consolidation_job_path)
    consolidation_jobs = load_consolidation_jobs(resolved_spec_path)

    runset = Runset.from_yaml(runset_path)
    scenarios = load_scenarios(catalog_path, runset)

    mappings = Mappings.from_dir(PATHS.analysis.mappings)

    print("\n===== Metric Consolidation Pipeline =====\n")
    print(f"Selected runset: {runset_path}")
    print(f"Selected scenario catalog: {catalog_path}")
    print(f"Selected consolidation spec: {resolved_spec_path}\n")
    print(f"Consolidating across {len(scenarios)} scenarios:")
    for idx, scenario in enumerate(scenarios, start=1):
        print(f"  {idx}. {scenario.id}")
    print()

    for idx, job in enumerate(consolidation_jobs, start=1):
        print(f"[{idx}/{len(consolidation_jobs)}] Consolidating '{job.name}'")

        df = collect_results(scenarios, job=job)
        df = relabel_dimensions(df, mappings)  # Before transform to for correct aggr.
        df = run_transform(df, job.transform)
        df = order_dataframe(df, mappings, sort_by=job.transform.groupby)

        output_path = save_consolidated_results(df, analysis_scope.tables, job.name)
        print(f"[{idx}/{len(consolidation_jobs)}] Saved to: {output_path}\n")


if __name__ == "__main__":
    scope = "main"
    main(
        scope=scope,
        runset_path=Path(f"scenarios/runsets/{scope}.yml"),
        catalog_path=Path("scenarios/scenarios.csv"),
        consolidation_job_path=Path("config/consolidations.yml"),
    )
