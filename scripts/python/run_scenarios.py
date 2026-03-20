import argparse
import csv
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass(frozen=True)
class ScenarioNew:
    """
    Immutable dataclass holding scenario configuration flags.
    All fields are required and validated at creation time.
    """

    id: str
    override: str
    solve_mode: str
    country: str
    policytype: str

    @classmethod
    def from_csv_row(cls, row: dict[str, str]) -> "ScenarioNew":
        """
        Create a ScenarioNew instance from a CSV row dictionary.
        Performs normalization (strip whitespace) and validation before creating the object.
        """
        row["id"] = row.pop("scenario_id")  # rename key for internal consistency
        normalized_values = cls._normalize_values(row)
        cls._validate_values(normalized_values)
        return cls(**normalized_values)

    @staticmethod
    def _normalize_values(values: dict[str, str]) -> dict[str, str]:
        """
        Normalize field values by stripping whitespace and checking for emptiness.
        """
        normalized = {key: value.strip() for key, value in values.items()}

        for key, value in normalized.items():
            if not value:
                raise ValueError(f"Field '{key}' must not be empty")

        return normalized

    @staticmethod
    def _validate_values(values: dict[str, str]) -> None:
        """
        Validate field values for reserved or disallowed combinations.
        """
        if values["override"] == "common":
            raise ValueError("override='common' is reserved")


@dataclass(frozen=True)
class Runset:
    """Immutable runset definition containing ordered scenario IDs."""

    scenario_ids: tuple[str, ...]

    def __post_init__(self) -> None:
        """Validate that scenario_ids is non-empty, contains no duplicates, and has no empty values."""
        if not self.scenario_ids:
            raise ValueError("Runset must contain at least one scenario_id")

        duplicates = {id for id in self.scenario_ids if self.scenario_ids.count(id) > 1}
        duplicates = sorted(duplicates)
        if duplicates:
            duplicate_ids = ", ".join(duplicates)
            raise ValueError(f"Runset contains duplicate scenario_ids: {duplicate_ids}")

        for id in self.scenario_ids:
            if not id:
                raise ValueError("scenario_ids values must not be empty")

    @classmethod
    def from_yaml(cls, path: Path) -> "Runset":
        """Load a runset from YAML using the required scenario_ids mapping."""
        content = yaml.safe_load(path.read_text())

        if content is None:  # Must not be an empty file
            raise ValueError("Runset YAML must contain a 'scenario_ids' key")

        if not isinstance(content, dict):  # Must be a dict at the top level
            raise ValueError("Runset YAML must be a mapping with a 'scenario_ids' key")

        if "scenario_ids" not in content:  # Mapping must contain the required key
            raise ValueError("Runset YAML must contain a 'scenario_ids' key")

        ids_raw = content["scenario_ids"]

        if not isinstance(ids_raw, list):  # The scenario_ids must be a list
            raise ValueError("'scenario_ids' must be a YAML list")

        # Ensure all scenario_ids are strings and normalize them by stripping whitespace.
        ids_normalized: list[str] = []
        for id in ids_raw:
            if not isinstance(id, str):
                raise ValueError("All scenario_ids values must be strings")
            id_normalized = id.strip()
            ids_normalized.append(id_normalized)

        return cls(scenario_ids=tuple(ids_normalized))


@dataclass(frozen=True)
class ScenarioCatalog:
    """Immutable catalog of scenarios with fast lookups and validation."""

    scenarios: tuple[ScenarioNew, ...]

    def __post_init__(self) -> None:
        """Validate that all scenario IDs are unique."""
        scenario_ids = [scenario.id for scenario in self.scenarios]
        duplicates = {id for id in scenario_ids if scenario_ids.count(id) > 1}
        if duplicates:
            duplicates = sorted(duplicates)
            raise ValueError(f"Catalog contains duplicate scenario ids: {duplicates}")

    @property
    def scenario_ids(self) -> frozenset[str]:
        """Return all scenario IDs as a frozenset for set operations."""
        return frozenset(scenario.id for scenario in self.scenarios)

    def get(self, scenario_id: str) -> ScenarioNew:
        """Get a scenario by ID, raising ValueError if not found."""
        for scenario in self.scenarios:
            if scenario.id == scenario_id:
                return scenario
        raise ValueError(f"scenario_id '{scenario_id}' not found in catalog")

    def missing_ids(self, ids: list[str]) -> set[str]:
        """Return IDs from the provided list that are not in the catalog."""
        return set(ids) - self.scenario_ids

    @classmethod
    def from_csv(cls, path: Path) -> "ScenarioCatalog":
        """Load scenario catalog from CSV file with validation."""
        with path.open("r", newline="") as f:
            reader = csv.DictReader(f)
            raw_rows = list(reader)

        # Validate that all required columns are present before processing any rows.
        NEEDED_COLS = {"scenario_id", "override", "solve_mode", "country", "policytype"}
        missing_cols = sorted(NEEDED_COLS - set(reader.fieldnames or []))
        if missing_cols:
            raise ValueError(f"Scenario catalog is missing columns: {missing_cols}")

        # Process each row into a ScenarioNew object.
        scenarios: list[ScenarioNew] = []
        for index, content in enumerate(raw_rows, start=2):
            try:
                scenarios.append(ScenarioNew.from_csv_row(content))
            except ValueError as exc:
                raise ValueError(f"Invalid scenario in row {index}: {exc}") from exc

        return cls(scenarios=tuple(scenarios))


def validate_override(root_path: Path, override: str) -> None:
    """
    Validate that the override corresponds to an existing directory in data/overrides.
    The special override "none" is reserved to indicate no overrides and must not exist as a directory.
    """
    if override == "none":
        path = root_path / "data" / "overrides" / "none"
        if path.exists():
            raise ValueError("Override directory 'none' is reserved and must not exist")
        return

    path = root_path / "data" / "overrides" / override
    if not path.is_dir():
        raise FileNotFoundError(f"Override directory not found: {path}")


def run_scenario(root_path: Path, scenario: ScenarioNew, purge: bool) -> None:
    """Run a single scenario by executing the GAMS model with the appropriate command-line arguments."""
    outdir = root_path / "results" / scenario.id

    if purge:
        shutil.rmtree(outdir, ignore_errors=True)

    outdir.mkdir(parents=True, exist_ok=True)

    cmd = [
        "gams",
        "run.gms",
        f"--scenario={scenario.id}",
        f"--override={scenario.override}",
        f"--solve_mode={scenario.solve_mode}",
        f"--country={scenario.country}",
        f"--policytype={scenario.policytype}",
        f"o={outdir / 'run.lst'}",
        f"lf={outdir / 'run.log'}",
        "logOption=4",
    ]

    print(f"Running {scenario.id} (override={scenario.override})")
    subprocess.run(cmd, check=True, cwd=root_path)
    print("--------------------------------------------------")
    print(f"--> Scenario {scenario.id} executed successfully.")
    print("--------------------------------------------------")


def main(
    scenario_id: str | None,
    runset_path: Path | None,
    catalog_path: Path,
    purge: bool,
) -> None:
    """Main function orchestrating local execution of model scenarios."""

    if (scenario_id is None) == (runset_path is None):
        raise ValueError("Provide exactly one of scenario_id or runset_path")

    workspace_root = Path.cwd()
    catalog = ScenarioCatalog.from_csv(catalog_path)

    selected_scenarios = []

    # If a single scenario_id is provided, validate it against the catalog and select it.
    if scenario_id is not None:
        selected_scenarios = [catalog.get(scenario_id)]

    # If a runset YAML file is provided, load the scenario IDs from it and validate against the catalog.
    if runset_path is not None:
        runset = Runset.from_yaml(runset_path)
        missing = catalog.missing_ids(list(runset.scenario_ids))
        if missing:
            missing = ", ".join(sorted(missing))
            raise ValueError(f"Runset has scenarios not found in catalog: {missing}")
        selected_scenarios = [catalog.get(id) for id in runset.scenario_ids]

    # Validate that all selected scenarios have valid override directories before starting any runs.
    for scenario in selected_scenarios:
        validate_override(workspace_root, scenario.override)

    # All validations passed, proceed to run the selected scenarios.
    print(f"Selected {len(selected_scenarios)} scenario(s)")
    for scenario in selected_scenarios:
        run_scenario(workspace_root, scenario, purge=purge)


def _parse_args() -> argparse.Namespace:
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
    return parser.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    main(
        scenario_id=args.scenario_id,
        runset_path=args.runset,
        catalog_path=args.scenario_catalog,
        purge=args.purge,
    )
