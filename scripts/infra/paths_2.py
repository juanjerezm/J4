from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def resolve_under(base: Path, path: str | Path) -> Path:
    """Resolve a path using ``base`` for relative paths."""
    path = Path(path)

    if path.is_absolute():
        return path

    return base / path


def with_suffix(path: str | Path, suffix: str) -> Path:
    """Return ``path`` with ``suffix`` when it has no suffix already."""
    path = Path(path)

    if path.suffix:
        return path

    return path.with_suffix(suffix)


@dataclass(frozen=True)
class ModelPaths:
    """Paths owned by the model execution pipeline."""

    repo_root: Path

    @property
    def scenarios(self) -> Path:
        return self.repo_root / "scenarios"

    @property
    def runsets(self) -> Path:
        return self.scenarios / "runsets"

    @property
    def scenario_catalog(self) -> Path:
        return self.scenarios / "scenarios.csv"

    @property
    def results(self) -> Path:
        return self.repo_root / "results"

    @property
    def data(self) -> Path:
        return self.repo_root / "data"

    @property
    def common_data(self) -> Path:
        return self.data / "common"

    @property
    def master_data(self) -> Path:
        return self.data / "_master-data"

    @property
    def overrides(self) -> Path:
        return self.data / "overrides"

    def runset(self, name: str | Path) -> Path:
        """Return a runset path, adding ``.yml`` for bare runset names."""
        path = with_suffix(name, ".yml")
        return resolve_under(self.runsets, path)

    def result_dir(self, scenario_id: str) -> Path:
        return self.results / scenario_id

    def result_csv_dir(self, scenario_id: str) -> Path:
        return self.result_dir(scenario_id) / "csv"

    def result_gdx_dir(self, scenario_id: str) -> Path:
        return self.result_dir(scenario_id) / "gdx"

    def result_csv(self, scenario_id: str, metric: str | Path) -> Path:
        metric_path = with_suffix(metric, ".csv")
        return resolve_under(self.result_csv_dir(scenario_id), metric_path)

    def override_dir(self, name: str | Path) -> Path:
        return resolve_under(self.overrides, name)


@dataclass(frozen=True)
class AnalysisScopePaths:
    """Paths for one paper-analysis scope, such as main, sadr, or saep."""

    name: str
    root: Path

    @property
    def config(self) -> Path:
        return self.root / "config"

    @property
    def tables(self) -> Path:
        return self.root / "tables"

    @property
    def figures(self) -> Path:
        return self.root / "figures"

    def resolve(self, path: str | Path) -> Path:
        """Resolve an analysis-local config path against this scope root."""
        return resolve_under(self.root, path)


@dataclass(frozen=True)
class AnalysisPaths:
    """Paths owned by the paper-analysis pipeline."""

    root: Path

    @property
    def shared(self) -> Path:
        return self.root / "shared"

    @property
    def mappings(self) -> Path:
        return self.shared / "mappings"

    @property
    def plot_styles(self) -> Path:
        return self.shared / "plot-styles.yml"

    def scope(self, name: str) -> AnalysisScopePaths:
        return AnalysisScopePaths(name=name, root=self.root / name)


@dataclass(frozen=True)
class RepoPaths:
    """Top-level path registry with model and analysis namespaces."""

    root: Path
    model: ModelPaths
    analysis: AnalysisPaths

    def resolve(self, path: str | Path) -> Path:
        """Resolve a path against the repository root."""
        return resolve_under(self.root, path)


def get_repo_paths(root: Path = ROOT) -> RepoPaths:
    root = root.resolve()
    return RepoPaths(
        root=root,
        model=ModelPaths(repo_root=root),
        analysis=AnalysisPaths(root=root / "analysis"),
    )


PATHS = get_repo_paths()


def resolve_cli_path(default_dir: Path, input_path: Path, root: Path = ROOT) -> Path:
    """Interpret a CLI path using the repo root for nested relative paths.

    Rules:
    1. Absolute path: return unchanged.
    2. Bare filename: resolve under ``default_dir``.
    3. Relative path with directories: resolve under ``root``.
    """
    if input_path.is_absolute():
        return input_path

    if len(input_path.parts) == 1:
        return default_dir / input_path

    return root.resolve() / input_path
