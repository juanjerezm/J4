# District Heating Load

This project uses hourly district heating (DH) load data for the Copenhagen metropolitan area.

The data corresponds to 2025 and is sourced from [Varmelast](https://www.varmelast.dk/). The original dataset is stored at [data/_master-data/varmelast_historisk_data_2025.csv](../data/_master-data/varmelast_historisk_data_2025.csv).

The dataset reports production by different technology types in the DH system. Their aggregate is assumed to represent total system load. Load values are hourly and reported in MW.

The source data is in local time, but it is treated as UTC in this project (i.e., effectively one to two hours ahead). The first hour of 2025 is also included in order to build a full-year series, because 2025's data contains only 8759 hours, with one hour missing due to the time-zone change.
