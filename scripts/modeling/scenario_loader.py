import csv
from pathlib import Path

from scripts.modeling.schemas import Runset, Scenario


def load_scenarios(catalog_path: Path, runset: Runset) -> list[Scenario]:
    """Load and return ordered Scenario objects from a catalog for the given runset."""
    with catalog_path.open("r", newline="") as f:
        reader = csv.DictReader(f)
        raw_rows = list(reader)

    missing_cols = sorted(set(Scenario.model_fields) - set(reader.fieldnames or []))
    if missing_cols:
        raise ValueError(f"Scenario catalog is missing columns: {missing_cols}")

    index = {row["id"]: row for row in raw_rows}

    missing_ids = set(runset.scenario_ids) - index.keys()
    if missing_ids:
        missing_str = ", ".join(sorted(missing_ids))
        raise ValueError(f"Scenarios not found in {catalog_path}: {missing_str}")

    scenarios: list[Scenario] = []
    for scenario_id in runset.scenario_ids:
        try:
            scenarios.append(Scenario(**index[scenario_id]))
        except ValueError as exc:
            raise ValueError(f"Invalid scenario '{scenario_id}': {exc}") from exc

    return scenarios
