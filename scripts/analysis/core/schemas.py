from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal, TypedDict

import matplotlib as mpl
import numpy as np

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
    scenario_metadata: list[str]
    transform: TransformSpec

    @classmethod
    def from_dict(cls, data: dict) -> "ConsolidationJob":
        data = dict(data)  # avoid mutating caller-owned dict
        data["transform"] = TransformSpec(**(data.get("transform") or {}))
        return cls(**data)


# ----- Plotting -----
@dataclass(frozen=True)
class AxisSpec:
    kind: Literal["numerical", "categorical"]

    label: str | None = None  # both
    label_kwargs: dict[str, Any] | None = None  # both

    autoscale: bool = False  # numeric
    min: float | None = None  # numeric
    max: float | None = None  # numeric
    pad: float | None = None  # both

    major_ticks: list[int | float] | None = None  # numeric
    minor_ticks: list[int | float] | None = None  # numeric
    ticklabel_format: str | None = None  # numeric, e.g. "{:.1f}M"
    ticklabel_kwargs: dict[str, Any] | None = None  # both

    major_grid: bool = False  # both
    minor_grid: bool = False  # both

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
    kind: Literal["cluster_bar", "stacked_bar", "line"]
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
