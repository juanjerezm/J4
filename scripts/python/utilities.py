import pandas as pd
import gams.transfer as gt
from pathlib import Path
from typing import List, Union, Dict, Optional

def print_line(length: int = 50) -> None:
    """
    Prints a horizontal line of a given length.

    Args:
        length (int): The length of the line. Default is 50.

    Returns:
        None
    """
    print("-" * length)


def print_title(title: str) -> None:
    """
    Prints a title surrounded by lines.

    Args:
        title (str): The title to be printed.

    Returns:
        None
    """
    print_line()
    print(title)
    print_line()


def filter(df: pd.DataFrame, include: dict = {}, exclude: dict = {}) -> pd.DataFrame:
    """
    Filters a DataFrame based on inclusion (whitelist) and exclusion (blacklist) criteria.
    Keys are strings that correspond to dataframe columns.
    Values correspond to strings or lists of strings that are the elements to keep or remove.

    Args:
        df (pd.DataFrame): The DataFrame to be filtered.
        include (dict): A dictionary specifying the inclusion criteria. Default is an empty dictionary.
        exclude (dict): A dictionary specifying the exclusion criteria. Default is an empty dictionary.

    Returns:
        pd.DataFrame: The filtered DataFrame.

    Examples:
        >>> df = pd.DataFrame({'A': [1, 2, 3], 'B': ['x', 'y', 'z']})
        >>> include_criteria = {'A': [1, 3]}
        >>> exclude_criteria = {'B': 'x'}
        >>> filtered_df = filter_df(df, include=include_criteria, exclude=exclude_criteria)
        >>> print(filtered_df)
           A  B
        2  3  z
    """
    df = df.copy()
    if include:
        for key, value in include.items():
            if isinstance(value, str):
                df = df[df[key] == value]
            else:
                df = df[df[key].isin(value)]
    if exclude:
        for key, value in exclude.items():
            if isinstance(value, str):
                df = df[df[key] != value]
            else:
                df = df[~df[key].isin(value)]
    return df


def rename_values(
    df: pd.DataFrame, rename_dict: Dict[str, Dict[str, str]]
) -> pd.DataFrame:
    """
    Renames values in a DataFrame based on a provided dictionary, with added checks
    for column existence.

    Args:
        df (pd.DataFrame): The DataFrame to be modified.
        rename_dict (Dict[str, Dict[str, str]]): Dictionary specifying rename operations in the form
                                                 {column_name: {old_value: new_value}}, with a check for column existence.

    Returns:
        pd.DataFrame: Modified DataFrame with values renamed according to rename_dict, if columns exist.

    Examples:
        >>> df = pd.DataFrame({'A': [1, 2, 3], 'B': ['x', 'y', 'z']})
        >>> rename_dict = {'A': {1: 'One', 2: 'Two'}, 'B': {'z': 'zed'}}
        >>> renamed_df = rename_values(df, rename_dict)
        >>> print(renamed_df)
           A  B
        0  One  x
        1  Two  y
        2    3  zed
    """
    # Ensure the DataFrame is not modified in place
    df = df.copy()

    # Iterate over the dictionary to replace values in the specified columns, with a check for column existence
    for column, replacements in rename_dict.items():
        if column in df.columns:
            df[column] = df[column].replace(replacements)
        else:
            print(f"Column '{column}' does not exist in the DataFrame.")

    return df


def rename_columns(df: pd.DataFrame, column_mapping: Dict[str, str]) -> pd.DataFrame:
    """
    Wrapper for rename pandas function, specific for column mapping.

    Args:
        df (pd.DataFrame): The DataFrame whose columns need to be renamed.
        column_mapping (Dict[str, str]): A dictionary mapping old column names to new column names.

    Returns:
        pd.DataFrame: The DataFrame with renamed columns.

    Example:
        >>> df = pd.DataFrame({'A': [1, 2, 3], 'B': [4, 5, 6]})
        >>> column_mapping = {'A': 'New_A', 'B': 'New_B'}
        >>> renamed_df = rename_columns(df, column_mapping)
        >>> print(renamed_df)
           New_A  New_B
        0      1      4
        1      2      5
        2      3      6
    """
    df = df.rename(columns=column_mapping)
    return df


def aggregate(df: pd.DataFrame, categories: List[str], sums: List[str]) -> pd.DataFrame:
    """
    Aggregates data in a DataFrame by grouping it based on specified columns and summing the values in other columns.
    It's a wrapper for the pandas groupby function with the sum operation, and it resets the index.

    Args:
        df (pd.DataFrame): The DataFrame to be aggregated.
        categories (List[str]): A list of column names to group the data by.
        sums (List[str]): A list of column names to sum the values of.

    Returns:
        pd.DataFrame: The aggregated DataFrame.

    Examples:
        >>> df = pd.DataFrame({'Category': ['A', 'A', 'B', 'B'], 'Value': [1, 2, 3, 4]})
        >>> categories = ['Category']
        >>> sums = ['Value']
        >>> aggregated_df = aggregate_data(df, categories, sums)
        >>> print(aggregated_df)
          Category  Value
        0        A      3
        1        B      7
    """
    df = df.groupby(categories, as_index=False)[sums].sum()
    return df


def diff(df, reference_col: str, reference_item: str, value_col: str) -> pd.DataFrame:
    """
    Calculate the change in value_col relative to a reference item on a reference column, such as a baseline (item) scenario (column).
    Differences are calculated for each combination of elements in the columns that are not value_col.

    Parameters:
    - df (pandas.DataFrame): The DataFrame to perform the difference calculation on.
    - reference_col (str): The name of the column that contains the reference.
    - reference_item (str): The reference item to subtract from other values in the DataFrame.
    - value_col (str): The column to perform the difference calculation on.

    Returns:
    - pandas.DataFrame: The DataFrame with the difference values calculated.

    Raises:
    - ValueError: If the base item specified by `reference_item` is not found in the index.
    - ValueError: If the DataFrame's index does not match the base field specified by `reference_col`.

    Example:
    >>> import pandas as pd
    >>> data = {'A': ['x', 'x', 'y', 'y'], 'B': ['a', 'b', 'a', 'b'], 'C': [1, 2, 6, 5], 'D': [5, 4, 1, 2]}
    >>> df = pd.DataFrame(data)
    >>> diff(df, 'A', 'x', ['C', 'D'])
       A  B  C  D
    0  y  a  5 -4
    1  y  b  3 -2
    """
    if reference_col not in df.columns:
        raise ValueError(f"Column '{reference_col}' does not exist in the DataFrame.")
    if reference_item not in df[reference_col].values:
        raise ValueError(
            f"Reference item '{reference_item}' not found in the column '{reference_col}'."
        )

    df = df.copy()
    df = df.set_index([col for col in df.columns if col not in value_col])

    # MultiIndex case
    if isinstance(df.index, pd.MultiIndex):
        idx_reference = [reference_item in index for index in df.index]
        df_reference = df[idx_reference].droplevel(reference_col)
        idx = [not i for i in idx_reference]
        df = df[idx].subtract(df_reference, axis=1, fill_value=0)

    # SingleIndex case: Adapted logic for a single-level index
    else:
        # Select the base rows and perform subtraction for the other rows
        df_reference = df.loc[[reference_item]]
        # Exclude the base row from the main dataframe
        df_filtered = df.drop(reference_item)
        # Subtract the base row from the rest of the dataframe
        df = df_filtered.subtract(df_reference.squeeze(), axis=1)

    df = df.reset_index()
    return df


def gdxdf_var(
    paths: Union[List[str], List[Path]],
    variables: Optional[List[str]] = None,
    attributes: List[str] = ["level"],
) -> Dict[str, pd.DataFrame]:
    """
    Reads GDX files from the given paths and returns all or some variables in a dictionary of pandas DataFrames.

    Args:
        paths (Union[List[str], List[Path]]): A list of file paths to the GDX files.
        variables (List[str], optional): A list of variable names to read from the GDX files. If None, all variables will be read.
        attributes (List[str], optional): A list of attribute names to include in the resulting DataFrames. Defaults to ['level'].

    Returns:
        dict: A dictionary where the keys are variable names and the values are pandas DataFrames containing the data.

    """
    gams_attrs = ["level", "marginal", "lower", "upper", "scale"]

    paths = [Path(path) for path in paths]

    # scenario names are the last part of the file name after the last hyphen
    scenarios = [path.stem.split("-")[-1] for path in paths]

    # read gdx files into containers
    containers = [gt.Container(str(path)) for path in paths]

    data_all = dict()
    for scenario, container in zip(scenarios, containers):
        if variables is None:
            spec_var = container.listVariables()
        else:
            spec_var = variables

        for var in spec_var:
            df_temp = container[var].records  # type: ignore
            if df_temp is None:
                print(f"Empty DataFrame for {var} in {scenario}")
                continue

            df_temp.insert(0, "scenario", scenario)
            df_temp.drop(
                columns=[col for col in gams_attrs if col not in attributes],
                inplace=True,
            )

            if var not in data_all:
                data_all[var] = pd.DataFrame()
            data_all[var] = pd.concat([data_all[var], df_temp])

    return data_all


def gdxdf_par(
    paths: Union[List[str], List[Path]], parameters: List[str]
) -> Dict[str, pd.DataFrame]:
    """
    Reads GDX files from the given paths and returns the specified parameters in a dictionary of DataFrames.

    Note:
    - If a parameter is not found in a GDX file, an empty DataFrame will be returned for that parameter.

    Args:
        paths ([List[str], List[Path]]): A list of file paths to the GDX files.
        parameters (List[str]): A list of parameters names to read from the GDX files.

    Returns:
        Dict[str, pd.DataFrame]: A dictionary where the keys are parameter names and the values are pandas DataFrames containing the data.

    """

    paths = [Path(path) for path in paths]

    # scenario names are the last part of the file name after the last hyphen
    scenarios = [path.stem.split("-")[-1] for path in paths]

    # read gdx files into containers
    containers = [gt.Container(str(path)) for path in paths]

    data_all = dict()
    for scenario, container in zip(scenarios, containers):
        for par in parameters:
            try:
                df_temp = container[par].records  # type: ignore
            except KeyError:
                print(f"KeyError: {par} not found in {scenario}")
                continue
            if df_temp is None:
                print(f"Empty DataFrame for {par} in {scenario}")
                continue

            df_temp.insert(0, "scenario", scenario)
            if par not in data_all:
                data_all[par] = pd.DataFrame()
            data_all[par] = pd.concat([data_all[par], df_temp])

    return data_all
