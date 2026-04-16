from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, TypedDict

import matplotlib as mpl
import numpy as np
import yaml

# ---------- typing aliases ----------
FilterValue = str | int | float | bool
FilterMap = dict[str, FilterValue | list[FilterValue]]


class FilterSpec(TypedDict, total=False):
    include: FilterMap
    exclude: FilterMap


class DiffSpec(TypedDict):
    reference_col: str
    reference_item: str


# --------- schemas ---------
@dataclass(frozen=True)
class TransformSpec:
    groupby: list[str] | None = None
    filter: FilterSpec | None = None
    diff: DiffSpec | None = None
    set_columns: dict[str, object] | None = None
    select_columns: list[str] | None = None
    scale_factor: float = 1.0
    decimals: int | None = None


@dataclass(frozen=True)
class ConsolidationJob:
    name: str
    transform: TransformSpec

    @classmethod
    def from_dict(cls, data: dict) -> "ConsolidationJob":
        transform = TransformSpec(**data.get("transform", {}))
        return cls(name=data["name"], transform=transform)


# ----- Mapping Schemas -----
@dataclass(frozen=True)
class FuelMap:
    """Mapping entry for a fuel type."""

    id: str
    label: str
    color: str


@dataclass(frozen=True)
class CountryMap:
    """Mapping entry for a country."""

    id: str
    label: str


@dataclass(frozen=True)
class PolicyMap:
    """Mapping entry for a policy type."""

    id: str
    label: str
    marker: str


@dataclass(frozen=True)
class EntityMap:
    """Mapping entry for a generic entity."""

    id: str
    label: str
    color: str


@dataclass(frozen=True)
class OverrideMap:
    """Mapping entry for a scenario override."""

    id: str
    label: str


@dataclass(frozen=True)
class Mappings:
    """Container for all loaded mapping entries and their projection helpers."""

    fuels: list[FuelMap] = field(default_factory=list)
    countries: list[CountryMap] = field(default_factory=list)
    policies: list[PolicyMap] = field(default_factory=list)
    entities: list[EntityMap] = field(default_factory=list)
    overrides: list[OverrideMap] = field(default_factory=list)

    def to_dict(self, mapping: str, key_attr: str, value_attr: str) -> dict:
        """Return a dict {key_attr: value_attr} for entries in the selected mapping."""
        entries = getattr(self, mapping)
        return {getattr(item, key_attr): getattr(item, value_attr) for item in entries}

    def ordered(self, mapping: str, attr: str) -> list:
        """Return attribute values for entries in the selected mapping, preserving source order."""
        entries = getattr(self, mapping)
        return [getattr(item, attr) for item in entries]

    @staticmethod
    def _load_entries(path: Path, entry_cls) -> list:
        """Load mapping entries from a YAML file whose root key matches the filename."""
        with path.open("r", encoding="utf-8") as f:
            raw = yaml.safe_load(f)

        return [entry_cls(**item) for item in raw[path.stem]]

    @classmethod
    def from_dir(cls, mapping_dir: Path) -> "Mappings":
        """Load the standard shared mapping files from a mapping directory."""

        return cls(
            fuels=cls._load_entries(mapping_dir / "fuels.yml", FuelMap),
            countries=cls._load_entries(mapping_dir / "countries.yml", CountryMap),
            policies=cls._load_entries(mapping_dir / "policies.yml", PolicyMap),
            entities=cls._load_entries(mapping_dir / "entities.yml", EntityMap),
            overrides=cls._load_entries(mapping_dir / "overrides.yml", OverrideMap),
        )


# ----- Plotting -----
@dataclass(frozen=True)
class AxisSpec:
    min: float | None = None
    max: float | None = None
    pad: float | None = None
    major_ticks: list[int | float] | None = None
    minor_ticks: list[int | float] | None = None
    major_grid: bool = False
    minor_grid: bool = False
    label: str = ""
    label_kwargs: dict[str, Any] | None = None
    ticklabel_format: str | None = None
    ticklabel_kwargs: dict[str, Any] | None = None
    autoscale: bool = False

    @classmethod
    def from_dict(cls, data: dict) -> "AxisSpec":
        data = dict(data)

        for key in ("major_ticks", "minor_ticks"):
            tick_spec = data.get(key)
            if isinstance(tick_spec, dict):
                start = tick_spec["start"]
                stop = tick_spec["stop"]
                step = tick_spec["step"]
                epsilon = np.sign(step) * abs(step) * 1e-6
                data[key] = list(np.arange(start, stop + epsilon, step))

        return cls(**data)


@dataclass(frozen=True)
class PlotInput:
    path: Path
    transform: TransformSpec | None = None

    @classmethod
    def from_dict(cls, data: dict) -> "PlotInput":
        transform_data = data.get("transform")
        transform = None if transform_data is None else TransformSpec(**transform_data)
        return cls(path=data["path"], transform=transform)


@dataclass(frozen=True)
class PlotStructure:
    panel_col: str
    group_col: str
    series_col: str

    @classmethod
    def from_dict(cls, data: dict) -> "PlotStructure":
        return cls(**data)

    @property
    def sort_columns(self) -> list[str]:
        return [self.panel_col, self.group_col, self.series_col]


@dataclass(frozen=True)
class PlotSpec:
    name: str
    inputs: list[PlotInput]
    structure: PlotStructure
    style: str | None = None
    figsize: tuple[float, float] | None = None
    save: bool = False
    show: bool = True
    x1: AxisSpec | None = None
    y1: AxisSpec | None = None
    x2: AxisSpec | None = None
    y2: AxisSpec | None = None

    @classmethod
    def from_dict(cls, data: dict) -> "PlotSpec":
        data = dict(data)
        data["inputs"] = [PlotInput.from_dict(item) for item in data["inputs"]]

        if data.get("structure") is None:
            raise ValueError("Missing required plot.structure block in plot spec.")
        data["structure"] = PlotStructure.from_dict(data["structure"])

        for axis_key in ("x1", "x2", "y1", "y2"):
            if data.get(axis_key) is not None:
                data[axis_key] = AxisSpec.from_dict(data[axis_key])

        if data.get("figsize") is not None:
            data["figsize"] = tuple(data["figsize"])

        return cls(**data)

    @property
    def figsize_inches(self) -> tuple[float, float]:
        default_width, default_height = mpl.rcParams["figure.figsize"]

        if self.figsize is None:
            return (default_width, default_height)

        width_cm, height_cm = self.figsize
        return (width_cm / 2.54, height_cm / 2.54)
