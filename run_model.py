import argparse
from pathlib import Path

from scripts.infra.paths import PATHS, resolve_cli_path
from scripts.modeling.execution import main


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run model scenarios locally.")

    selector = parser.add_mutually_exclusive_group(required=True)
    selector.add_argument(
        "--scenario-id",
        type=str,
        help="Scenario ID to run.",
    )
    selector.add_argument(
        "--runset",
        type=Path,
        help="Path to YAML file with scenario IDs to run.",
    )
    parser.add_argument(
        "--scenario-catalog",
        type=Path,
        default=PATHS.file.scenario_catalog,
        help="Path to scenario catalog (default: scenarios/scenarios.csv).",
    )
    parser.add_argument(
        "--purge",
        action="store_true",
        help="Remove existing output directory before each run.",
    )
    parser.add_argument(
        "--no-csv-export",
        action="store_true",
        help="Skip CSV export of postprocessing GDX results after each scenario run.",
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.runset:
        runset_path = resolve_cli_path(
            default_dir=PATHS.dir.runsets,
            input_path=args.runset,
        )
    else:
        runset_path = None

    catalog_path = resolve_cli_path(
        default_dir=PATHS.dir.scenarios,
        input_path=args.scenario_catalog,
    )

    main(
        scenario_id=args.scenario_id,
        runset_path=runset_path,
        catalog_path=catalog_path,
        purge=args.purge,
        export_csv=not args.no_csv_export,
    )
