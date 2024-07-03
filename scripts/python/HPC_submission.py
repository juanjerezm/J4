"""
This script is used to submit jobs to a High-Performance Computing (HPC) system.
It reads scenario parameters from a CSV file, creates job scripts based on a template,
and submits the jobs to the HPC system.

Minimum usage:
python3 HPC_submission.py path/to/scenarios.csv --submit

Arguments:
- path/to/scenarios.csv: Path to the CSV file containing the scenario parameters.
- --submit: Optional flag to indicate whether to submit the jobs or not, set to False by default.
- --base_path: Optional argument to specify the base path for the project.
- --template_path: Optional argument to specify the path to the job template file.
- --max_runs: Optional argument to specify the maximum number of runs allowed.

The script performs the following steps:
1. Reads the scenario parameters from the CSV file.
2. Checks if the Python version is 3.7 or higher.
3. Checks if the input CSV file exists.
4. Validates the scenario parameters and ensures there are no missing values.
5. Checks if the number of scenarios is below the maximum allowed runs.
6. Loads the template file for the job script.
7. Creates a job script for each scenario based on the template.
8. Submits the job scripts to the HPC system (if the --submit flag is provided).

Note: This script requires Python 3.7 or higher to run.

Author: Juan Jerez Monsalves, jujmo@dtu.dk
Date: July 2024
"""

import argparse
import csv
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from string import Template
from typing import Dict, List

TIMESTAMP = datetime.now().strftime("%Y%m%d-%H%M%S")


cfg = {
    "base_path": Path("/zhome/f0/5/124363/J4"),
    "template_path": Path("scripts/python/job_template.sh"),
    "max_runs": 10,
    "opt_submit": False,
}


@dataclass
class ScenarioParams:
    """
    Represents the parameters for a scenario.

    Attributes:
        name (str): The name of the scenario.
        country (str): The country associated with the scenario.
        policy (str): The policy applied in the scenario.
        jobscript (Path): The path to the jobscript associated with the scenario.
    """

    name: str
    country: str
    policy: str
    jobscript: Path = field(init=False)

    def __post_init__(self) -> None:
        self.jobscript = (
            cfg["base_path"] / "results" / self.name / f"jobscript_{TIMESTAMP}.sh"
        )


def read_csv(file_path: Path) -> List[ScenarioParams]:
    """Read scenario parameters from a csv-file and return a list of ScenarioParams objects."""
    scenarios = []
    with open(file_path, "r") as file:
        delimiter = csv.Sniffer().sniff(file.read()).delimiter
        file.seek(0)
        reader = csv.DictReader(file, delimiter=delimiter)
        for row_number, row in enumerate(
            reader, start=2
        ):  # Start from 2, skipping header row
            validate_row(row, row_number)
            scenario = ScenarioParams(**row)
            scenarios.append(scenario)
    return scenarios


def check_version() -> None:
    """Check if the Python version is 3.7 or higher."""
    if sys.version_info < (3, 7):
        print("-----------------------------------------------------")
        sys.exit("ERROR: PYTHON 3.7+ IS REQUIRED. SCRIPT HAS STOPPED")
    return


def check_file_exist(file_path: Path) -> None:
    """Check if the input csv-file exists."""
    if not file_path.is_file():
        sys.exit(
            "ERROR: Input csv-file not found, make sure its full path is included. SCRIPT HAS STOPPED"
        )


def check_max_runs(scenarios: List[ScenarioParams]) -> None:
    """Check if the number of scenarios is below the maximum allowed runs."""
    if len(scenarios) > cfg["max_runs"]:
        raise ValueError(
            f"Number of scenarios ({len(scenarios)}) exceeds the maximum allowed runs ({cfg['max_runs']})"
        )


def validate_row(row: Dict[str, str], row_number: int) -> None:
    """Validate that rows are not empty and do not contain missing values."""
    if not any(row.values()):
        raise ValueError(f"Empty line detected at row {row_number}")
    if not all(row.values()):
        raise ValueError(f"Missing value in row {row_number}: {row}")


def load_template() -> Template:
    """Load the template file for the jobscript."""
    with cfg["template_path"].open(mode="r") as file:
        job_template = Template(file.read())
    return job_template


def job_creation(scenario: ScenarioParams) -> None:
    """
    Create a job submission file for a given scenario.

    Args:
        scenario (ScenarioParams): The scenario parameters.

    Returns:
        None
    """
    job_content = load_template().substitute(
        name=scenario.name,
        country=scenario.country,
        policytype=scenario.policy,
        hpc_dir=cfg["base_path"].as_posix(),
    )

    with scenario.jobscript.open(mode="w+") as file:
        file.write(job_content)
    print(f"Submission file for scenario '{scenario.name}' created")


def job_submision(scenario: ScenarioParams):
    """
    Submits a job for the given scenario.

    Args:
        scenario (ScenarioParams): The scenario for which the job needs to be submitted.

    Returns:
        None
    """
    if cfg["opt_submit"]:
        with scenario.jobscript.open(mode="r") as file:
            subprocess.run(["bsub"], stdin=file, cwd=Path.cwd())
        print(f"Scenario '{scenario.name}' successfully submitted")
    else:
        print(f"Scenario '{scenario.name}' not submitted due to settings")


def parse_args():
    """
    Parse command line arguments for submitting jobs to HPC.

    Returns:
        None
    """
    parser = argparse.ArgumentParser(description="Submit jobs to HPC")
    parser.add_argument(
        "file_path", type=Path, help="Path to the CSV file containing scenarios"
    )
    parser.add_argument(
        "--base_path",
        type=Path,
        default=cfg["base_path"],
        help="Base path for the project",
    )
    parser.add_argument(
        "--template_path",
        type=Path,
        default=cfg["template_path"],
        help="Path to the job template file",
    )
    parser.add_argument(
        "--max_runs",
        type=int,
        default=cfg["max_runs"],
        help="Maximum number of runs allowed",
    )
    parser.add_argument(
        "--submit",
        action="store_true",
        default=cfg["opt_submit"],
        help="Submit the job or not",
    )

    args = parser.parse_args()

    cfg.update(
        {
            "file_path": Path(args.file_path),
            "base_path": Path(args.base_path),
            "template_path": Path(args.template_path),
            "max_runs": args.max_runs,
            "opt_submit": args.submit,
        }
    )


def main():
    """
    Entry point of the program.
    """
    if len(sys.argv) > 1:
        parse_args()
    else:
        # Interactive input for file_path if running in an IDE without command-line arguments
        file_path_input = input("Enter the path to the CSV file containing scenarios: ")
        cfg["file_path"] = Path(file_path_input)

    check_version()
    check_file_exist(cfg["file_path"])
    scenarios = read_csv(cfg["file_path"])
    check_max_runs(scenarios)

    print(f"Scenarios loaded successfully ({len(scenarios)} scenarios):")
    for scenario in scenarios:
        print(scenario)

    for scenario in scenarios:
        scenario.jobscript.parent.mkdir(parents=True, exist_ok=True)
        job_creation(scenario)
        job_submision(scenario)


if __name__ == "__main__":
    main()
