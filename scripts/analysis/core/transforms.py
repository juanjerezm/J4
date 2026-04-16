import pandas as pd

from scripts.analysis.core.schemas import TransformSpec


def filter_rows(
    df: pd.DataFrame, include: dict | None = None, exclude: dict | None = None
) -> pd.DataFrame:
    """
    Filter rows in a DataFrame using column-based inclusion and exclusion rules.
    The `include` and `exclude` arguments are dictionaries where each key is a
    column name in `df`, and each value is either:
    - a single scalar value, such as `"reference"` or `2030`
    - a collection of values, such as `["DK", "FR"]` or `("CHP", "BOILER")`

    For `include`, only rows matching the specified values are kept.
    For `exclude`, rows matching the specified values are removed.

    Rules are applied sequentially: all inclusion filters are applied first,
    then all exclusion filters are applied afterwards.

    Args:
        df: Input DataFrame to filter.
        include: Optional mapping of column names to values that should be kept.
        exclude: Optional mapping of column names to values that should be removed.

    Returns:
        A filtered DataFrame containing only rows that satisfy the requested criteria.

    Raises:
        ValueError: If a requested filter column is not present in the DataFrame.

    Examples:
        Keep only reference rows:
            include = {"CASE": "reference"}

        Keep rows for Denmark and France:
            include = {"COUNTRY": ["DK", "FR"]}

        Exclude one generator type:
            exclude = {"G": "CHP_BACKUP"}

        Combine include and exclude:
            include = {"COUNTRY": ["DK", "FR"], "POLICY": "Base"}
            exclude = {"F": ["Waste", "Oil"]}
    """

    def _as_list(value):
        if isinstance(value, (list, tuple, set)):
            return list(value)
        return [value]

    include = {} if include is None else include
    exclude = {} if exclude is None else exclude

    for key, value in include.items():
        if key not in df.columns:
            raise ValueError(f"Filter column '{key}' not found in DataFrame.")
        df = df[df[key].isin(_as_list(value))]

    for key, value in exclude.items():
        if key not in df.columns:
            raise ValueError(f"Filter column '{key}' not found in DataFrame.")
        df = df[~df[key].isin(_as_list(value))]
    return df


def aggregate(df: pd.DataFrame, groupby: list[str], sums: list[str]) -> pd.DataFrame:
    """
    Aggregate numeric value columns by summing over the requested grouping columns.

    Args:
        df: Input DataFrame.
        groupby: Column names that define the aggregation groups. If empty, the
            function returns a single-row DataFrame with totals over the entire input.
        sums: Columns to sum within each group.

    Returns:
        A DataFrame aggregated to the requested grouping level.

    Raises:
        ValueError: If any grouping column or value column is not present in
            the DataFrame.
    """

    missing_groupby = [col for col in groupby if col not in df.columns]
    if missing_groupby:
        error_str = f"Grouping column(s) not found in DataFrame: {missing_groupby}"
        raise ValueError(error_str)

    missing_value_cols = [col for col in sums if col not in df.columns]
    if missing_value_cols:
        error_str = f"Value column(s) not found in DataFrame: {missing_value_cols}"
        raise ValueError(error_str)

    if groupby:
        return df.groupby(groupby, as_index=False, observed=False)[sums].sum()

    return pd.DataFrame([{col: df[col].sum() for col in sums}])


def diff(df, reference_col: str, reference_item: str, value_col: str) -> pd.DataFrame:
    """
    Compute row-wise differences relative to a matching reference row.

    Rows are matched on all columns except `reference_col` and `value_col`.
    Within each match, the row where `reference_col == reference_item` is used
    as the baseline. Its value is subtracted from the other rows, and the
    reference rows are omitted from the result.

    Example:
        Input:
            COUNTRY  POLICY  CASE       value
            DK       Base    reference  10
            DK       Base    opt1       13
            DK       Base    opt2       8

        Output:
            COUNTRY  POLICY  CASE  value
            DK       Base    opt1      3
            DK       Base    opt2     -2

    Args:
        df: Input DataFrame.
        reference_col: Column containing the reference category.
        reference_item: Value in `reference_col` to use as the baseline.
        value_col: Numeric column to difference.

    Returns:
        A DataFrame of non-reference rows with `value_col` replaced by
        differences from the matching reference value.

    Raises:
        ValueError: If required columns are missing, the reference item is not
            present, or a row cannot be matched to exactly one reference row.
    """

    if reference_col not in df.columns:
        raise ValueError(f"Reference column '{reference_col}' not found in DataFrame.")
    if value_col not in df.columns:
        raise ValueError(f"Value column '{value_col}' not found in DataFrame.")
    if reference_item not in df[reference_col].to_numpy():
        error_str = f"Item '{reference_item}' not found in column '{reference_col}'."
        raise ValueError(error_str)

    df = df.copy()

    # --- define grouping columns as all dimensions except reference and value ---
    temp_group_col = None
    group_cols = [col for col in df.columns if col not in {reference_col, value_col}]

    # --- if no grouping columns remain to perform row matches, create one global group ---
    if not group_cols:
        temp_group_col = "_group"
        df[temp_group_col] = "__all__"
        group_cols = [temp_group_col]

    # --- identify reference rows and build a table of reference values ---
    ref_mask = df[reference_col] == reference_item
    ref_df = df.loc[ref_mask, [*group_cols, value_col]].copy()
    ref_df = ref_df.rename(columns={value_col: "_reference_value"})

    # --- validate that each group has exactly one reference row ---
    ref_counts = ref_df.groupby(group_cols, observed=False).size()
    bad_groups = ref_counts[ref_counts != 1]
    if not bad_groups.empty:
        raise ValueError("Some rows have no unique reference row to compare against.")

    # --- keep only rows that should be compared against the reference ---
    result = df.loc[~ref_mask].copy()
    # --- attach the group-specific reference value to each remaining row ---
    result = result.merge(ref_df, on=group_cols, how="left", validate="many_to_one")

    # --- ensure every row found a matching reference value ---
    if result["_reference_value"].isna().any():
        raise ValueError("Some groups do not have a matching reference row.")

    # --- subtract the reference value within each group ---
    result[value_col] = result[value_col] - result["_reference_value"]

    # --- drop temporary helper columns ---
    result = result.drop(columns="_reference_value")
    if temp_group_col is not None:
        result = result.drop(columns=temp_group_col)

    return result.reset_index(drop=True)


def assign_columns(df: pd.DataFrame, values: dict) -> pd.DataFrame:
    """
    Return a DataFrame with columns assigned fixed values.

    Existing columns are overwritten if they appear in `values`.

    Args:
        df: Input DataFrame.
        values: Mapping of column names to values to assign.

    Returns:
        A new DataFrame with the requested columns added or updated.
    """
    return df.assign(**values)


def select_columns(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    """
    Return a DataFrame containing only the selected columns, in the given order.

    Args:
        df: Input DataFrame.
        columns: Columns to keep in the output.

    Returns:
        A DataFrame with only the requested columns.

    Raises:
        ValueError: If any requested column is not present in the DataFrame.
    """
    missing = [col for col in columns if col not in df.columns]
    if missing:
        raise ValueError(f"Column(s) not found in DataFrame: {missing}")

    return df[columns].copy()


def scale_values(
    df: pd.DataFrame,
    scale_factor: float = 1.0,
    decimals: int | None = None,
    value_col: str = "value",
) -> pd.DataFrame:
    """
    Scale and optionally round a numeric value column.

    Args:
        df: Input DataFrame.
        scale_factor: Factor to multiply the value column by.
        decimals: Number of decimal places to round to. If None, no rounding applied.
        value_col: Name of the numeric column to scale.

    Returns:
        A DataFrame with the scaled value column.

    Raises:
        ValueError: If `value_col` is not present in the DataFrame.
    """
    if value_col not in df.columns:
        raise ValueError(f"Value column '{value_col}' not found in DataFrame.")

    df = df.copy()
    df[value_col] = df[value_col] * scale_factor

    if decimals is not None:
        df[value_col] = df[value_col].round(decimals)

    return df


def run_transform(df: pd.DataFrame, spec: TransformSpec) -> pd.DataFrame:
    """Apply the configured transformation steps to a DataFrame."""
    if spec.filter is not None:
        include = spec.filter.get("include")
        exclude = spec.filter.get("exclude")
        df = filter_rows(df, include=include, exclude=exclude)

    if spec.groupby:
        df = aggregate(df, spec.groupby, ["value"])

    if spec.diff:
        df = diff(df, spec.diff["reference_col"], spec.diff["reference_item"], "value")

    if spec.set_columns:
        df = assign_columns(df, spec.set_columns)

    if spec.select_columns:
        df = select_columns(df, spec.select_columns)

    df = scale_values(df, spec.scale_factor, spec.decimals, "value")
    return df
