from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import yaml
from pydantic import BaseModel, ConfigDict, Field, ValidationInfo, field_validator


class Scenario(BaseModel):
    """
    Pydantic model for scenario configuration.
    All fields are required and validated at assignment time.
    """

    id: str
    override: str
    solve_mode: str
    country: str
    policytype: str

    model_config = ConfigDict(validate_assignment=True)

    @field_validator("id", "override", "solve_mode", "country", "policytype")
    @classmethod
    def not_empty(cls, value: str, info: ValidationInfo) -> str:
        if not value.strip():
            raise ValueError(f"Field '{info.field_name}' must not be empty")
        return value.strip()

    @field_validator("override")
    @classmethod
    def override_not_reserved(cls, v: str) -> str:
        if v == "common":
            raise ValueError("override='common' is reserved")
        return v

    @classmethod
    def from_csv_row(cls, row: dict[str, str]) -> "Scenario":
        row["id"] = row.pop("scenario_id")
        return cls(**row)


class Runset(BaseModel):
    """Ordered collection of scenario IDs to be executed together as a single run."""

    scenario_ids: Annotated[tuple[str, ...], Field(min_length=1)]

    @field_validator("scenario_ids")
    @classmethod
    def no_duplicates(cls, v: tuple[str, ...]) -> tuple[str, ...]:
        """Ensure all scenario IDs are unique within the runset."""
        duplicates = sorted({id for id in v if v.count(id) > 1})
        if duplicates:
            raise ValueError(f"duplicate scenario_ids: {', '.join(duplicates)}")
        return v

    @classmethod
    def from_yaml(cls, path: Path) -> "Runset":
        """Load a runset from a YAML file."""

        content = yaml.safe_load(path.read_text())

        return cls(**content)


class ExecutionStatus(StrEnum):
    PASSED = "passed"
    FAILED_GAMS = "failed (gams)"
    FAILED_EXPORT = "failed (export)"


@dataclass
class ExecutionOutcome:
    """Execution outcome for a single scenario, including status, timing, and optional failure reason."""

    scenario_id: str
    elapsed: float
    status: ExecutionStatus
    reason: str | None = None

    @classmethod
    def passed(cls, scenario_id: str, elapsed: float) -> "ExecutionOutcome":
        return cls(scenario_id, elapsed, ExecutionStatus.PASSED)

    @classmethod
    def gams_fail(
        cls, scenario_id: str, elapsed: float, code: int
    ) -> "ExecutionOutcome":
        str_code = f"exit code {code}"
        return cls(scenario_id, elapsed, ExecutionStatus.FAILED_GAMS, str_code)

    @classmethod
    def export_fail(
        cls, scenario_id: str, elapsed: float, exc: Exception
    ) -> "ExecutionOutcome":
        return cls(scenario_id, elapsed, ExecutionStatus.FAILED_EXPORT, str(exc))
