from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2].resolve()


@dataclass(frozen=True)
class AnalysisDirs:
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
        path = Path(path)
        if path.is_absolute():
            return path

        return self.root / path


@dataclass(frozen=True)
class RepoDirs:
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
    def analysis(self) -> Path:
        return self.root / "analysis"

    @property
    def analysis_shared(self) -> Path:
        return self.analysis / "shared"

    def get_analysis_dirs(self, analysis_name: str) -> AnalysisDirs:
        return AnalysisDirs(root=self.analysis / analysis_name)


DIRS = RepoDirs(root=REPO_ROOT)


def resolve_cli_path(
    default_dir: Path,
    input_path: Path,
    root: Path = REPO_ROOT,
) -> Path:
    """Interpret a user path with deterministic CLI-style rules.

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
