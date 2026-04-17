import pandas as pd

from scripts.analysis.core.dimensions import DIMENSION_CONFIG
from scripts.analysis.core.mappings import Mappings


def relabel_dimensions(df: pd.DataFrame, mappings: Mappings) -> pd.DataFrame:
    """Replace internal model IDs with display labels."""
    df = df.copy()

    for column, config in DIMENSION_CONFIG.items():
        if column not in df.columns:
            continue

        map_dict = mappings.to_dict(config["mapping"], "id", "label")
        df[column] = df[column].map(map_dict).fillna(df[column])

    return df


def set_categoricals(df: pd.DataFrame, mappings: Mappings) -> pd.DataFrame:
    """Set ordered display categories following mapping order."""
    df = df.copy()

    for column, config in DIMENSION_CONFIG.items():
        # if column not defined as categorical in DIMENSION_CONFIG, skip it
        if not config.get("categorical", False):
            continue

        if column not in df.columns:
            continue

        category_order = mappings.ordered(config["mapping"], "label")

        df[column] = pd.Categorical(df[column], categories=category_order, ordered=True)

    return df


def sort_rows(df: pd.DataFrame, sort_by: list[str] | None) -> pd.DataFrame:
    """Sort rows by the specified sort_by columns that are present in the DataFrame."""
    if sort_by is None:
        return df

    valid = [col for col in sort_by if col in df.columns]
    missing = [col for col in sort_by if col not in df.columns]

    if missing:
        print(f"Warning: Sort columns not found and ignored: {missing}")

    if not valid:
        print("Warning: No requested sort columns found; leaving row order unchanged.")
        return df

    return df.sort_values(valid).reset_index(drop=True)


def order_dataframe(
    df: pd.DataFrame,
    mappings: Mappings,
    sort_by: list[str] | None = None,
) -> pd.DataFrame:
    """Apply mapped categorical ordering and optional row sorting."""
    df = set_categoricals(df, mappings)
    df = sort_rows(df, sort_by)
    return df
