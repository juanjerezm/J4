#!/usr/bin/env python3
"""Root entrypoint for analysis pipelines.

Usage examples:
    python run_analysis.py --pipeline main
    python run_analysis.py --pipeline main --runset main.yml
    python run_analysis.py --pipeline main --catalog scenarios.csv

Pipelines are intentionally hardcoded: main, sadr, saep.
"""

import argparse
from pathlib import Path

from scripts.analysis.pipelines.execute_main import main as execute_main
from scripts.analysis.pipelines.execute_sadr import main as execute_sadr
from scripts.analysis.pipelines.execute_saep import main as execute_saep
from scripts.infra.paths import PATHS, resolve_cli_path

PIPELINES = {
    "main": execute_main,
    "sadr": execute_sadr,
    "saep": execute_saep,
}

DEFAULT_RUNSETS = {
    "main": PATHS.dir.runsets / "main.yml",
    "sadr": PATHS.dir.runsets / "sadr.yml",
    "saep": PATHS.dir.runsets / "saep.yml",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run one analysis pipeline from the repository root.",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "--pipeline",
        required=True,
        choices=tuple(PIPELINES),
        help="Pipeline name to run.",
    )
    parser.add_argument(
        "--runset",
        type=Path,
        default=None,
        help=(
            "Optional runset file override.\n"
            "If omitted, the default runset for the selected pipeline is used.\n"
            "Supported forms:\n"
            "  (1) bare filename,       e.g. 'main.yml' -> resolves to 'scenarios/runsets/main.yml'\n"
            "  (2) repo-relative path,  e.g. 'scenarios/runsets/main-other.yml'\n"
            "  (3) absolute path,       e.g. '/path/to/custom.yml'\n"
        ),
    )
    parser.add_argument(
        "--scenario-catalog",
        type=Path,
        default=PATHS.file.scenario_catalog,
        help=(
            "Optional scenario catalog file override.\n"
            "If omitted, defaults to 'scenarios/scenarios.csv'.\n"
            "Supported forms:\n"
            "  (1) bare filename,       e.g. 'scenarios.csv' -> resolves to 'scenarios/scenarios.csv'\n"
            "  (2) repo-relative path,  e.g. 'scenarios/scenarios-other.csv'\n"
            "  (3) absolute path,       e.g. '/path/to/scenarios.csv'\n"
        ),
    )

    return parser.parse_args()


def main(
    pipeline: str,
    runset: Path | None = None,
    scenario_catalog: Path = PATHS.file.scenario_catalog,
) -> None:
    # Use default runset file for the selected pipeline if no runset file is provided
    runset_candidate = DEFAULT_RUNSETS[pipeline] if runset is None else runset

    runset_path = resolve_cli_path(
        default_dir=PATHS.dir.runsets,
        input_path=runset_candidate,
    )
    catalog_path = resolve_cli_path(
        default_dir=PATHS.dir.scenarios,
        input_path=scenario_catalog,
    )

    if not runset_path.is_file():
        raise FileNotFoundError(f"Runset file not found: {runset_path}")
    if not catalog_path.is_file():
        raise FileNotFoundError(f"Scenario catalog file not found: {catalog_path}")

    PIPELINES[pipeline](runset_path=runset_path, catalog_path=catalog_path)
    return


if __name__ == "__main__":
    args = parse_args()

    main(
        pipeline=args.pipeline,
        runset=args.runset,
        scenario_catalog=args.scenario_catalog,
    )
