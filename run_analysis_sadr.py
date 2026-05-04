from pathlib import Path

from scripts.analysis.pipelines.consolidate_metrics import main as consolidate_metrics
from scripts.analysis.pipelines.generate_plot import main as generate_plot
from scripts.infra.dirs import DIRS

ANALYSIS = "sadr"
RUNSET_PATH = DIRS.runsets / f"{ANALYSIS}.yml"
CATALOG_PATH = DIRS.scenarios / "scenarios.csv"
CONSOLIDATION_PATH = Path("config/consolidations.yml")
PLOT_SPECS = [
    "config/plot-SADR-NPV.yml",
    "config/plot-SADR-Heat-Production.yml",
]


def main() -> None:
    # Step 1: Consolidate metrics across scenarios
    consolidate_metrics(
        analysis=ANALYSIS,
        job_path=CONSOLIDATION_PATH,
        runset_path=RUNSET_PATH,
        catalog_path=CATALOG_PATH,
    )

    # Step 2: Generate plots
    for plot_file in PLOT_SPECS:
        generate_plot(analysis=ANALYSIS, plotspec_path=Path(plot_file))


if __name__ == "__main__":
    main()
