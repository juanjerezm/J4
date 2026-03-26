import argparse
from pathlib import Path

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
        default=Path("scenarios/scenarios.csv"),
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
    main(
        scenario_id=args.scenario_id,
        runset_path=args.runset,
        catalog_path=args.scenario_catalog,
        purge=args.purge,
        export_csv=not args.no_csv_export,
    )
