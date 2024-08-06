import pandas as pd
import requests
from typing import Literal, Dict, Any, List

def build_index(df: pd.DataFrame) -> pd.DataFrame:
    """
    Set up the index for a pandas DataFrame.

    Args:
    df (pd.DataFrame): The DataFrame to index.

    Returns:
    pd.DataFrame: The DataFrame with the index set up.
    """
    df["HourUTC"] = pd.to_datetime(df["HourUTC"])
    df.set_index("HourUTC", inplace=True)
    return df

def query_emissions_api(
    api_version: Literal["old", "new"], period_start: str, period_end: str
) -> pd.DataFrame:
    """
    Make an API call to the Energi Data Service to retrieve electricity emissions data.

    Args:
    api_version (Literal['old', 'new']): Determines which API endpoint to use.
    period_start (str): Start date for the data period.
    period_end (str): End date for the data period.

    Returns:
    pd.DataFrame: The DataFrame with the electricity emissions data.

    Raises:
    ValueError: If an invalid api_version is provided.
    requests.RequestException: If there's an issue with the API request.
    """
    api_address: Dict[str, str] = {
        "old": "https://api.energidataservice.dk/dataset/DeclarationEmissionHour",
        "new": "https://api.energidataservice.dk/dataset/DeclarationGridEmission",
    }

    filter: Dict[str, str] = {
        "old": '{"PriceArea":["DK2"]}',
        "new": '{"PriceArea":["DK2"], "FuelAllocationMethod":["125%"]}',
    }

    if api_version not in api_address:
        raise ValueError(f"Invalid api_version: {api_version}. Must be 'old' or 'new'.")

    parameters: Dict[str, Any] = {
        "timezone": "UTC",
        "start": period_start,
        "end": period_end,
        "sort": "HourUTC asc",
        "filter": filter[api_version],
        "columns": "HourUTC,CO2PerkWh",
    }

    try:
        response = requests.get(url=api_address[api_version], params=parameters)
        response.raise_for_status()  # Raises an HTTPError for bad responses
        records = response.json()["records"]
        return pd.json_normalize(records)
    except requests.RequestException as e:
        print(f"API request failed: {e}")
        raise


def get_electricity_emissions(period_start: str, period_end: str) -> pd.DataFrame:
    """
    Retrieve and combine CO2 data from both old and new API versions, prioritizing 'new' data.
    
    Args:
    period_start (str): Start date for the data period.
    period_end (str): End date for the data period.
    
    Returns:
    pd.DataFrame: Combined DataFrame with prioritized CO2 data
    """
    df_new = query_emissions_api("new", period_start, period_end)
    df_old = query_emissions_api("old", period_start, period_end)

    df_new = build_index(df_new)
    df_old = build_index(df_old)

    # Consolidate the data, prioritizing the 'new' data where available and filling in with 'old' data where not
    union_index = df_new.index.union(df_old.index)
    df_final = pd.DataFrame(index=union_index)
    df_final['CO2'] = df_new['CO2PerkWh']
    df_final['CO2'] = df_final['CO2'].fillna(df_old['CO2PerkWh'])
    
    return df_final.sort_index()


def query_price_api(period_start: str, period_end: str) -> pd.DataFrame:
    """
    Make an API call to the Energi Data Service to retrieve electricity emissions data.

    Args:
    api_version (Literal['old', 'new']): Determines which API endpoint to use.
    period_start (str): Start date for the data period.
    period_end (str): End date for the data period.

    Returns:
    pd.DataFrame: The DataFrame with the electricity emissions data.

    Raises:
    ValueError: If an invalid api_version is provided.
    requests.RequestException: If there's an issue with the API request.
    """
    api_address = 'https://api.energidataservice.dk/dataset/Elspotprices'

    filter = '{"PriceArea":["DK2"]}'

    parameters: Dict[str, str] = {
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

def get_electricity_price(period_start: str, period_end: str) -> pd.DataFrame:
    """
    Retrieve and combine CO2 data from both old and new API versions, prioritizing 'new' data.
    
    Args:
    period_start (str): Start date for the data period.
    period_end (str): End date for the data period.
    
    Returns:
    pd.DataFrame: Combined DataFrame with prioritized CO2 data
    """
    df = query_price_api(period_start, period_end)
    df = build_index(df)
    return df.sort_index()

def separate_data(df: pd.DataFrame, outdir: str) -> None:
    """
    Separates the data in the given DataFrame by year and saves the subsets as CSV files.
    Args:
        df (pd.DataFrame): The DataFrame containing the data.
        outdir (str): The directory where the CSV files will be saved.
    Returns:
        None
    """
    df = df.copy()
    df.rename(columns={'SpotPriceEUR': 'SpotPrice EUR/MWh', 'CO2': 'CarbonIntensity kg/MWh'}, inplace=True)
    
    df['Year'] = df.index.year # type: ignore
    
    years = df['Year'].unique()
    
    for year in years:
        df_year = df[df['Year'] == year].reset_index(drop=True)
        df_year.index = ['T{:04d}'.format(i+1) for i in range(len(df_year))]
        
        # Print the length of each year
        print(f'Year {year}: {len(df_year)} records')

        # SpotPriceEUR
        df_price = df_year[['SpotPrice EUR/MWh']]
        df_price.to_csv(f'{outdir}/ts-electricity-price-{year}.csv', header=False)
        
        # CO2
        df_co2 = df_year[['CarbonIntensity kg/MWh']]
        df_co2.to_csv(f'{outdir}/ts-electricity-carbon-{year}.csv', header=False)

period_start = "2017-01-01"
period_end = "2024-01-01" # It's an open interval

df_emissions = get_electricity_emissions(period_start, period_end)
df_price = get_electricity_price(period_start, period_end)

# Merge price and emissions data
df = pd.merge(df_price, df_emissions, left_index=True, right_index=True, how='outer')
df = df.round(3)

# Filter out leap days
df = df[~((df.index.month == 2) & (df.index.day == 29))] # type: ignore

# Data check
print(f"The number of rows in the merged DataFrame is: {df.shape[0]}")
print(f"Rows with NaN values: \n {df.isna().sum()}")

# Save the master data
df.to_csv("data/_master-data/electricity_data.csv")

# Separate the data by year and type
outdir = "data"
separate_data(df, outdir)
