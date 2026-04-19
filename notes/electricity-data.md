# Electricity Data

This project uses data on electricity prices and carbon intensity.
These are hourly datasets corresponding to market zone DK2, which covers eastern Denmark and the Copenhagen area.

- Electricity prices are day-ahead market prices in EUR/MWh.
- Carbon intensity is measured in kg-CO2/MWh and represents the mean carbon intensity of the grid.

## Sensitivity Analysis

For sensitivity analysis, three electricity price cases are used: low prices from 2020, medium prices from 2025 (base case), and high prices from 2022. Statistical properties of the price timeseries are shown in the table below.

| Sensitivity   | year | mean   | std    |
|---------------|------|--------|--------|
| Low           | 2020 |  28.46 |  19.73 |
| Medium (base) | 2025 |  82.50 |  51.78 |
| High          | 2022 | 210.15 | 150.22 |

The same carbon intensity timeseries (base case, 2025) is used in all three cases to isolate the effect of price changes.

## Data Sources

### Energinet

The core electricity dataset is sourced from Energinet's [EnergiDataService](https://www.energidataservice.dk/), particularly from [Elspotprices API](https://api.energidataservice.dk/dataset/Elspotprices) and from [DeclarationGridEmission API](https://api.energidataservice.dk/dataset/DeclarationGridEmission). Both APIs provide data with hourly resolution and timestamps in UTC.

Data is retrieved using `scripts/data/get_electricity_data.py` and saved in `data/_master-data/electricity` [ENERGINET-price-emissions-all.csv](../data/_master-data/electricity/ENERGINET-price-emissions-all.csv).

Energinet's price data covers up to 2025-09-30. After this date, the market changed from 60-minute to 15-minute resolution and, as of April 2026, Energinet does not provide data in this new format.

### ENTSOE Transparency Platform

To complete the price series for late 2025, data is taken from the [ENTSOE Transparency Platform](https://transparency.entsoe.eu).
This data is accessed at: File Library -> TP Export -> EnergyPrices_12.1.D_r3 (requires log-in).

These 15-minute resolution prices are averaged to 60-minute resolution to match the hourly dataset used in the analysis.

The original ENTSOE files are stored in `data/_master-data/electricity`:

- [Sep 2025](../data/_master-data/electricity/ENTSOE-2025_09_EnergyPrices_12.1.D_r3.csv)
- [Oct 2025](../data/_master-data/electricity/ENTSOE-2025_10_EnergyPrices_12.1.D_r3.csv)
- [Nov 2025](../data/_master-data/electricity/ENTSOE-2025_11_EnergyPrices_12.1.D_r3.csv)
- [Dec 2025](../data/_master-data/electricity/ENTSOE-2025_12_EnergyPrices_12.1.D_r3.csv)
