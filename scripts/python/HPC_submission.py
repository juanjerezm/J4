"""
This script is used to submit jobs to a High-Performance Computing (HPC) system.
It reads scenario parameters from a CSV file, creates job scripts based on a template,
and submits the jobs to the HPC system.

Minimum usage:
module load python3/3.11.0      (or any version 3.7+)
module load pandas
python3 HPC_submission.py path/to/scenario_specs.csv --submit

Arguments:
- path/to/scenario_specs.csv: Path to the CSV file containing the scenario specifications.
- --submit: Optional flag to indicate whether to submit the jobs or not, set to False by default.
- --base_path: Optional argument to specify the base path for the model. (default: current working directory)
- --template_path: Optional argument to specify the path to the job template file. (default: scripts/python/job_template.sh)
- --max_runs: Optional argument to specify the maximum number of runs allowed. (default: 12)
- --queue: Optional argument to specify the queue to submit the job to. (default: man)
- --cores: Optional argument to specify the number of cores to use for each job. (default: 12)
- --memory: Optional argument to specify the memory (in GB) to allocate for each job. (default: 4)
- --walltime: Optional argument to specify the walltime (in hh:mm) for each job. (default: 24:00)
- --email: Optional argument to specify a non-default email address for job notifications. (default: None)

The script performs the following steps:
1. Checks for the existence of the CSV file with scenario specifications.
2. Reads the scenario specifications from the file.
3. Checks for missing values in each scenario specification.
4. Checks for number of scenarios below the maximum allowed runs.
5. Loads the job submission template script.
6. Creates a job submission script for each scenario using the template.
7. Submits the job scripts to the HPC system (if the --submit flag is provided).


Author: Juan Jerez Monsalves, juanjerezmonsalves@gmail.com
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

TIMESTAMP = datetime.now().strftime("%Y%m%d-%H%M%S")


cfg = {
    "base_path": Path.cwd(),
    "template_path": Path("scripts/python/job_template.sh"),
    "max_runs": 12,
    "submit_flag": False,
    "queue": "man",  # specify the queue
    "cores": 12,  # number of cores to use for each job
    "memory": 4,  # allocated memory per core, in GB
    "walltime": "24:00",  # job walltime (hh:mm)
    "email": None,  # custom email address for job notifications
}


@dataclass
class ScenarioParams:
    """
    Represents the parameters for a scenario.

    Attributes:
        project (str): The project associated with the scenario.
        name (str): The name of the scenario.
        country (str): The country associated with the scenario.
        policy (str): The policy applied in the scenario.
        jobscript (Path): The path to the jobscript associated with the scenario.
    """

    project: str
    name: str
    extra_flags: dict[str, str] = field(default_factory=dict)

    jobscript: Path = field(init=False)

    def __post_init__(self) -> None:
        self.jobscript = (
            cfg["base_path"]
            / "results"
            / self.project
            / self.name
            / f"jobscript_{TIMESTAMP}.sh"
        )

    def __str__(self) -> str:
        flags_str = ", ".join(f"{k}={v}" for k, v in self.extra_flags.items())
        return (
            f"- Scenario: project={self.project}, name={self.name}\n"
            f"  Flags: {flags_str}"
        )


def read_csv(file_path: Path) -> list[ScenarioParams]:
    """Read scenario parameters from a csv-file and return a list of ScenarioParams objects."""
    scenarios = []
    with file_path.open("r") as file:
        delimiter = csv.Sniffer().sniff(file.read()).delimiter
        file.seek(0)
        reader = csv.DictReader(file, delimiter=delimiter)
        for row_number, row in enumerate(reader, start=2):
            validate_row(row, row_number)
            project = row.pop("project")
            name = row.pop("name")
            scenario_params = ScenarioParams(
                project=project, name=name, extra_flags=row
            )
            scenarios.append(scenario_params)
    return scenarios


def check_file_exist(file_path: Path) -> None:
    """Check if the input csv-file exists."""
    if not file_path.is_file():
        sys.exit("ERROR: Input csv-file not found, script has stopped.")


def check_max_runs(scenarios: list[ScenarioParams]) -> None:
    """Check if the number of scenarios is below the maximum allowed runs."""
    if len(scenarios) > cfg["max_runs"]:
        raise ValueError(
            f"Number of scenarios ({len(scenarios)}) exceeds the maximum allowed runs ({cfg['max_runs']})"
        )


def validate_row(row: dict[str, str], row_number: int) -> None:
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
    flags = " ".join(f"--{key}={value}" for key, value in scenario.extra_flags.items())

    job_content = load_template().safe_substitute(
        project=scenario.project,
        scenario=scenario.name,
        flags=flags,
        base_dir=cfg["base_path"].as_posix(),
        queue=cfg["queue"],
        cores=cfg["cores"],
        memory=cfg["memory"],
        walltime=cfg["walltime"],
        email=cfg["email"],
    )

    with scenario.jobscript.open(mode="w+") as file:
        file.write(job_content)
    print(f"Submission file for scenario '{scenario.name}' created")


def job_submission(scenario: ScenarioParams):
    """
    Submits a job for the given scenario.

    Args:
        scenario (ScenarioParams): The scenario for which the job needs to be submitted.

    Returns:
        None
    """
    if cfg["submit_flag"]:
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
        help="Base path for the model",
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
        "--queue",
        type=str,
        default=cfg["queue"],
        help="Queue to submit the job to",
    )
    parser.add_argument(
        "--cores",
        type=int,
        default=cfg["cores"],
        help="Number of cores to use for each job",
    )
    parser.add_argument(
        "--memory",
        type=int,
        default=cfg["memory"],
        help="Memory (in GB) to allocate for each job",
    )
    parser.add_argument(
        "--walltime",
        type=str,
        default=cfg["walltime"],
        help="Walltime (in hh:mm) for each job",
    )
    parser.add_argument(
        "--email",
        type=str,
        default=None,
        help="Non-default email address for job notifications",
    )
    parser.add_argument(
        "--submit",
        action="store_true",
        default=cfg["submit_flag"],
        help="Submit the job scripts to the HPC queue (default: False)",
    )

    args = parser.parse_args()

    # email resolution logic: CLI, pyproject.toml, interactive user input
    email = args.email
    if not email:
        while not email:
            email = input("Enter your email address for job notifications: ").strip()
            if not email:
                print("Email address cannot be empty. Please enter a valid email.")

    cfg.update(
        {
            "file_path": Path(args.file_path),
            "base_path": Path(args.base_path),
            "template_path": Path(args.template_path),
            "max_runs": args.max_runs,
            "submit_flag": args.submit,
            "queue": args.queue,
            "cores": args.cores,
            "memory": args.memory,
            "walltime": args.walltime,
            "email": email,
        }
    )


def main():
    """
    Entry point of the program.
    """
    if len(sys.argv) > 1:
        parse_args()
    else:
        # Interactive input if running in an IDE without command-line arguments
        file_path_input = input("Enter the path to the CSV file containing scenarios: ")
        cfg["file_path"] = Path(file_path_input)
        email = input("Enter your email address for job notifications: ").strip()
        while not email:
            print("Email address cannot be empty. Please enter a valid email.")
            email = input("Enter your email address for job notifications: ").strip()
        cfg["email"] = email

    check_file_exist(cfg["file_path"])
    scenarios = read_csv(cfg["file_path"])
    check_max_runs(scenarios)

    print("---------------------------------")
    print(f"Scenarios loaded successfully ({len(scenarios)} scenarios):")
    for scenario in scenarios:
        print(scenario)

    print("---------------------------------")
    for scenario in scenarios:
        scenario.jobscript.parent.mkdir(parents=True, exist_ok=True)
        job_creation(scenario)
        job_submission(scenario)
        print("---------------------------------")


if __name__ == "__main__":
    main()
