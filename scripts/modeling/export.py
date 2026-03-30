from pathlib import Path

import gams.transfer as gt
import pandas as pd

from scripts.modeling.schemas import Scenario


def load_gdx(
    path: str | Path,
    symbol_type: str,
    symbols: list[str] | None = None,
    attributes: list[str] | None = None,
) -> dict[str, pd.DataFrame]:
    """
    Loads symbols of a single type from a GDX file.
    Different symbol types should be loaded in separate calls to this function.

    Args:
        path:        Path to the GDX file.
        symbol_type: Type of symbols to read.
                     Options: 'parameters', 'variables', 'equations', 'sets', 'aliases'.
        symbols:     Symbol names to read. If None, all symbols of the given type are read.
        attributes:  Attributes to include. If None, all valid attributes for the type are returned.
                     - variables/equations: 'level', 'marginal', 'lower', 'upper', 'scale'.
                     - sets/aliases:        'element_text'.
                     - parameters:          ignored, always returns 'value'.

    Returns:
        Dictionary mapping symbol names to DataFrames.

    Raises:
        FileNotFoundError: If the GDX file does not exist.
        ValueError:        If symbol_type is unknown, attributes are invalid for the
                           type, requested symbols are not found, or a symbol has no records.

    References:
        GAMS Transfer Python API — Main Classes:
        https://www.gams.com/latest/docs/API_PY_GAMSTRANSFER_MAIN_CLASSES.html
    """
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"GDX file not found: {path}")

    container = gt.Container(str(path))

    type_resolvers = {
        "parameters": container.listParameters,
        "variables": container.listVariables,
        "equations": container.listEquations,
        "sets": container.listSets,
        "aliases": container.listAliases,
    }

    type_attrs = {
        "parameters": [],
        "variables": ["level", "marginal", "lower", "upper", "scale"],
        "equations": ["level", "marginal", "lower", "upper", "scale"],
        "sets": ["element_text"],
        "aliases": ["element_text"],
    }

    # Validation of symbol_type
    if symbol_type not in type_resolvers:
        raise ValueError(
            f"Unknown symbol_type '{symbol_type}'. Valid: {list(type_resolvers)}"
        )

    # Validation of attributes
    available_attributes = type_attrs[symbol_type]
    if attributes is not None:
        invalid_attrs = set(attributes) - set(available_attributes)
        if invalid_attrs:
            raise ValueError(
                f"Invalid attributes {invalid_attrs} for symbol_type '{symbol_type}'. "
                f"Valid: {available_attributes}"
            )

    selected_attributes = attributes if attributes is not None else available_attributes

    # Validation of symbols
    available_symbols = type_resolvers[symbol_type]()
    if symbols is not None:
        missing_symbols = set(symbols) - set(available_symbols)
        if missing_symbols:
            raise ValueError(
                f"Symbols {missing_symbols} not found for symbol_type '{symbol_type}' in GDX."
            )

    selected_symbols = symbols if symbols is not None else available_symbols

    # Read data for selected_symbols and filter selected_attributes
    data = {}
    for symbol in selected_symbols:
        records = container[symbol].records  # type: ignore
        if records is None:
            raise ValueError(f"Symbol '{symbol}' has no records in GDX.")

        data[symbol] = records.drop(
            columns=[c for c in available_attributes if c not in selected_attributes]
        )

    return data


def export_to_csv(scenario: Scenario, results_dir: Path) -> None:
    """Export postprocessing GDX results to CSV for a completed scenario."""

    gdx_dir = results_dir / scenario.id / "gdx"
    csv_dir = results_dir / scenario.id / "csv"
    gdx_path = gdx_dir / "results-postprocessing.gdx"

    csv_dir.mkdir(parents=True, exist_ok=True)

    data = load_gdx(gdx_path, symbol_type="parameters")

    for symbol, df in data.items():
        df.to_csv(csv_dir / f"{symbol}.csv", index=False)
