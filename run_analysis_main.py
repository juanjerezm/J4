from pathlib import Path

from scripts.analysis.pipelines.consolidate_metrics import main as consolidate_metrics
from scripts.analysis.pipelines.generate_plot import main as generate_plot
from scripts.infra.paths_2 import PATHS

SCOPE = "main"
RUNSET_PATH = PATHS.model.runset("main")  # TODO CHECK THIS
CATALOG_PATH = PATHS.model.scenario_catalog
CONSOLIDATION_PATH = Path("config/consolidations.yml")
PLOT_FILES = [
    "config/plot-NPV.yml",
    "config/plot-Carbon-Emissions-Change.yml",
    "config/plot-Fuel-Consumption-Change.yml",
    "config/plot-Fuel-Consumption-Change-includingCHP.yml",
    "config/plot-Electricity-Production-Change.yml",
    "config/plot-Heat-Production-Change.yml",
]


def main() -> None:
    # Step 1: Consolidate metrics across scenarios
    consolidate_metrics(
        scope=SCOPE,
        consolidation_job_path=CONSOLIDATION_PATH,
        runset_path=RUNSET_PATH,
        catalog_path=CATALOG_PATH,
    )

    # Step 2: Generate plots
    for plot_file in PLOT_FILES:
        generate_plot(scope=SCOPE, plot_spec_path=plot_file)


if __name__ == "__main__":
    main()
