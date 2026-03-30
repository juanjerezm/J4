from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class DirPaths:
    root: Path

    @property
    def scenarios(self) -> Path:
        return self.root / "scenarios"

    @property
    def runsets(self) -> Path:
        return self.scenarios / "runsets"

    @property
    def results(self) -> Path:
        return self.root / "results"

    @property
    def data(self) -> Path:
        return self.root / "data"

    @property
    def overrides(self) -> Path:
        return self.data / "overrides"

    @property
    def mappings(self) -> Path:
        return self.analysis / "mappings"

    @property
    def analysis(self) -> Path:
        return self.root / "analysis"


@dataclass(frozen=True)
class FilePaths:
    dir: DirPaths

    @property
    def scenario_catalog(self) -> Path:
        return self.dir.scenarios / "scenarios.csv"

    @property
    def mapping_fuels(self) -> Path:
        return self.dir.mappings / "fuels.yml"

    @property
    def mapping_countries(self) -> Path:
        return self.dir.mappings / "countries.yml"

    @property
    def mapping_policies(self) -> Path:
        return self.dir.mappings / "policies.yml"


@dataclass(frozen=True)
class RepoPaths:
    root: Path
    dir: DirPaths
    file: FilePaths


def get_repo_paths(root: Path = ROOT) -> RepoPaths:
    root = root.resolve()
    dir_paths = DirPaths(root=root)
    file_paths = FilePaths(dir=dir_paths)
    return RepoPaths(root=root, dir=dir_paths, file=file_paths)


PATHS = get_repo_paths()


def resolve_cli_path(default_dir: Path, input_path: Path, root: Path = ROOT) -> Path:
    """Interpret a user path with deterministic CLI-style rules.

    Rules:
    1. Absolute path: return unchanged.
    2. Bare filename: resolve under ``default_dir``.
    3. Relative path with directories: resolve under ``root``.

    In the default configuration, all returned paths are absolute because both
    ``default_dir`` and ``root`` are derived from ``ROOT``.
    """
    if input_path.is_absolute():
        return input_path

    if len(input_path.parts) == 1:
        return default_dir / input_path

    return root.resolve() / input_path
