from pathlib import Path
from typing import Any

import pandas as pd
import requests


def query_emissions_api(period_start: str, period_end: str) -> pd.DataFrame:
    """
    Make an API call to the Energi Data Service to retrieve electricity emissions data.
    """
    api_address = "https://api.energidataservice.dk/dataset/DeclarationGridEmission"

    filter = '{"PriceArea": ["DK2"], "FuelAllocationMethod": ["125%"]}'  # Must be str for API call

    parameters: dict[str, Any] = {
        "timezone": "UTC",
        "start": period_start,
        "end": period_end,
        "sort": "HourUTC asc",
        "filter": filter,
        "columns": "HourUTC,CO2PerkWh",
    }

    try:
        response = requests.get(url=api_address, params=parameters)
        response.raise_for_status()  # Raises an HTTPError for bad responses
        records = response.json()["records"]
        return pd.json_normalize(records)
    except requests.RequestException as e:
        print(f"API request failed: {e}")
        raise


def query_price_api(period_start: str, period_end: str) -> pd.DataFrame:
    """
    Make an API call to the Energi Data Service to retrieve day-ahead electricity prices.
    """
    api_address = "https://api.energidataservice.dk/dataset/Elspotprices"

    filter = '{"PriceArea":["DK2"]}'  # Must be str for API call

    parameters: dict[str, str] = {
        "timezone": "UTC",
        "start": period_start,
        "end": period_end,
        "sort": "HourUTC asc",
        "filter": filter,
        "columns": "HourUTC,SpotPriceEUR",
    }

    try:
        response = requests.get(url=api_address, params=parameters)
        response.raise_for_status()  # Raises an HTTPError for bad responses
        records = response.json()["records"]
        return pd.json_normalize(records)
    except requests.RequestException as e:
        print(f"API request failed: {e}")
        raise


def separate_data(
    df: pd.DataFrame,
) -> tuple[dict[int, pd.DataFrame], dict[int, pd.DataFrame]]:
    """
    Separates the data by year and type.
    Args:
        df (pd.DataFrame): The DataFrame containing the data.
    Returns:
        tuple[dict[int, pd.DataFrame], dict[int, pd.DataFrame]]
    """
    df = df.copy()

    df["Year"] = df.index.year  # type: ignore

    years = df["Year"].unique()
    price_by_year: dict[int, pd.DataFrame] = {}
    co2_by_year: dict[int, pd.DataFrame] = {}

    for year in years:
        df_year = df[df["Year"] == year].reset_index(drop=True)
        df_year.index = [f"T{i + 1:04d}" for i in range(len(df_year))]

        year_key = int(year)
        price_by_year[year_key] = df_year[["SpotPrice EUR/MWh"]]
        co2_by_year[year_key] = df_year[["CarbonIntensity kg/MWh"]]

    return price_by_year, co2_by_year


def print_split_checks(
    price_by_year: dict[int, pd.DataFrame],
    co2_by_year: dict[int, pd.DataFrame],
) -> None:
    headers = [
        "Year",
        "Price Rows",
        "Price NaNs",
        "Price Mean",
        "Price Std",
        "CO2 Rows",
        "CO2 NaNs",
        "CO2 Mean",
        "CO2 Std",
    ]
    col_widths = [6, 11, 11, 11, 10, 9, 9, 10, 9]

    header_line = " ".join(
        f"{header:<{width}}" for header, width in zip(headers, col_widths, strict=True)
    )
    separator_line = " ".join("-" * width for width in col_widths)

    print("Per-year checks:")
    print(header_line)
    print(separator_line)

    for year in sorted(price_by_year):
        df_price = price_by_year[year]
        df_co2 = co2_by_year[year]

        price_series = df_price["SpotPrice EUR/MWh"]
        co2_series = df_co2["CarbonIntensity kg/MWh"]

        row_values = [
            f"{year:<6}",
            f"{len(df_price):>11}",
            f"{price_series.isna().sum():>11}",
            f"{price_series.mean():>11.3f}",
            f"{price_series.std():>10.3f}",
            f"{len(df_co2):>9}",
            f"{co2_series.isna().sum():>9}",
            f"{co2_series.mean():>10.3f}",
            f"{co2_series.std():>9.3f}",
        ]
        print(" ".join(row_values))


def save_separated(
    dfs_price: dict[int, pd.DataFrame], dfs_co2: dict[int, pd.DataFrame], outdir: str
) -> None:
    """Saves yearly split data for price and CO2."""
    for year in sorted(dfs_price):
        path_price = f"{outdir}/ts-electricity-price-{year}.csv"
        path_co2 = f"{outdir}/ts-electricity-carbon-{year}.csv"

        dfs_price[year].to_csv(path_price, header=False)
        dfs_co2[year].to_csv(path_co2, header=False)


def set_datetime_index(df, col) -> pd.DataFrame:
    df = df.copy()
    df[col] = pd.to_datetime(df[col])
    df = df.set_index(col).sort_index()
    return df


def prepare_data(df1, df2, header_mapping) -> pd.DataFrame:

    # Set datetime index for both dataframes
    df1 = set_datetime_index(df1, "HourUTC")
    df2 = set_datetime_index(df2, "HourUTC")

    # Merge dataframes
    df = df1.merge(df2, left_index=True, right_index=True, how="outer")

    # Filter out leap days
    df = df[~((df.index.month == 2) & (df.index.day == 29))]  # type: ignore

    # Other formatting
    df = df.rename(columns=header_mapping)
    df = df.round(3)
    return df


def main(
    period_start: str, period_end: str, outdir: str, col_names: dict[str, str]
) -> None:

    # Data retrieval
    data_price = query_price_api(period_start, period_end)
    data_co2 = query_emissions_api(period_start, period_end)

    # Data preparation
    df = prepare_data(data_price, data_co2, col_names)
    dfs_price, dfs_co2 = separate_data(df)

    # Data check
    print(f"The number of rows in the merged DataFrame is: {df.shape[0]}")
    print(f"Rows with NaN values: \n {df.isna().sum()}")
    print_split_checks(dfs_price, dfs_co2)

    # Save
    # make dir if not exist with path module

    Path(outdir).mkdir(parents=True, exist_ok=True)

    df.to_csv(f"{outdir}/ENERGINET-price-emissions-all.csv")  # all data in one file
    save_separated(dfs_price, dfs_co2, outdir)  # separate files by year and type


if __name__ == "__main__":
    period_start = "2020-01-01"
    period_end = "2026-01-01"

    col_names = {
        "SpotPriceEUR": "SpotPrice EUR/MWh",
        "CO2PerkWh": "CarbonIntensity kg/MWh",
    }

    outdir = "data/_master-data/electricity"

    main(
        period_start=period_start,
        period_end=period_end,
        outdir=outdir,
        col_names=col_names,
    )
