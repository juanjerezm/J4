from __future__ import annotations

from pathlib import Path

import pandas as pd

WorkbookPath = str | Path
CountryGeneratorTariffMap = dict[str, dict[str, str]]

HOURS_PER_DAY = 24
MONTHS_PER_YEAR = 12
TIMESTEPS_PER_MONTH = 730
TIMESTEPS_PER_YEAR = TIMESTEPS_PER_MONTH * MONTHS_PER_YEAR


def generate_volumetric_tariffs(
    country_generator_tariffs: CountryGeneratorTariffMap,
    workbook_path: WorkbookPath,
    output_dir: WorkbookPath,
) -> None:
    """Generate one headerless volumetric tariff CSV per country."""
    if not country_generator_tariffs:
        print("No generator/country/tariff mappings were provided. Nothing to write.")
        return

    workbook_path = Path(workbook_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    workbook = pd.ExcelFile(workbook_path)
    tariff_tables = read_tariff_tables(workbook)
    tariff_timeseries = {
        id: convert_to_timeseries(vals) for id, vals in tariff_tables.items()
    }

    for country, generator_tariffs in country_generator_tariffs.items():
        country_data = _build_country_data(generator_tariffs, tariff_timeseries)
        country_data = country_data.round(2)

        output_path = output_dir / f"data-volumetric-tariff-{country}.csv"
        country_data.to_csv(output_path, index=False)

        print(f"Wrote {output_path} with {len(country_data)} rows.")


def read_tariff_tables(workbook: pd.ExcelFile) -> dict[str, pd.DataFrame]:
    """Read every workbook sheet into a 24x12 float tariff table."""
    tariff_tables: dict[str, pd.DataFrame] = {}

    for sheet_name in workbook.sheet_names:
        tariff_id = str(sheet_name)
        tariff_vals = pd.read_excel(
            workbook, sheet_name=tariff_id, header=0, index_col=0
        )
        _validate_shape(tariff_vals, tariff_id)
        tariff_tables[tariff_id] = tariff_vals.astype(float)

    return tariff_tables


def _validate_shape(tariff_vals: pd.DataFrame, tariff_id: str) -> None:
    """Check that a tariff sheet contains exactly 24 hourly rows and 12 monthly columns."""
    expected_shape = (HOURS_PER_DAY, MONTHS_PER_YEAR)
    if tariff_vals.shape != expected_shape:
        msg = (
            f"Tariff sheet '{tariff_id}' has shape {tariff_vals.shape}; "
            f"expected {expected_shape}."
        )
        raise ValueError(msg)


def convert_to_timeseries(tariff_table: pd.DataFrame) -> pd.DataFrame:
    """Convert a 24x12 tariff table into an 8760-row timestep/value table."""
    values: list[float] = []
    for month_idx in range(MONTHS_PER_YEAR):
        month_vals = tariff_table.iloc[:, month_idx].tolist()

        repeated_month_vals = (
            month_vals[step % HOURS_PER_DAY] for step in range(TIMESTEPS_PER_MONTH)
        )
        values.extend(repeated_month_vals)

    if len(values) != TIMESTEPS_PER_YEAR:
        msg = (
            f"Converted tariff produced {len(values)} values; "
            f"expected {TIMESTEPS_PER_YEAR}."
        )
        raise ValueError(msg)

    timesteps = [f"T{step:04d}" for step in range(1, TIMESTEPS_PER_YEAR + 1)]

    return pd.DataFrame({"timestep": timesteps, "value": values})


def _build_country_data(
    generator_tariffs: dict[str, str], tariff_timeseries: dict[str, pd.DataFrame]
) -> pd.DataFrame:
    """Build one country's timestep-by-generator tariff table from tariff ids."""
    generator_data: list[pd.DataFrame] = []

    for generator_id, tariff_id in generator_tariffs.items():
        if tariff_id not in tariff_timeseries:
            raise ValueError(f"Tariff sheet '{tariff_id}' not found.")

        tariff_data = tariff_timeseries[tariff_id].assign(generator=generator_id)
        tariff_data = tariff_data[["generator", "timestep", "value"]]
        generator_data.append(tariff_data)

    country_data = pd.concat(generator_data, ignore_index=True)

    return (
        country_data.pivot_table(
            index="timestep",
            columns="generator",
            values="value",
            aggfunc="first",
            sort=False,
        ).reset_index()
        # .rename_axis(columns=None)
    )


if __name__ == "__main__":
    country_generator_tariffs: CountryGeneratorTariffMap = {
        "DK": {
            "HOB_EL": "A-høj+",
            "HP_AMBIENT": "A-lav",
            "HP_PROCESS": "A-lav",
            "ELECTRIC_CHILLER": "A-lav",
            "FREE_COOLING": "A-lav",
            "HP_RECOVERY": "A-lav",
        },
        "DE": {
            "HOB_EL": "HS-peak",
            "HP_AMBIENT": "MS-baseline",
            "HP_PROCESS": "MS-baseline",
            "ELECTRIC_CHILLER": "MS-baseline",
            "FREE_COOLING": "MS-baseline",
            "HP_RECOVERY": "MS-baseline",
        },
        "FR": {
            "HOB_EL": "HVB-1-MTU",
            "HP_AMBIENT": "HVA-1-LTU",
            "HP_PROCESS": "HVA-1-LTU",
            "ELECTRIC_CHILLER": "HVA-1-LTU",
            "FREE_COOLING": "HVA-1-LTU",
            "HP_RECOVERY": "HVA-1-LTU",
        },
    }

    generate_volumetric_tariffs(
        country_generator_tariffs=country_generator_tariffs,
        workbook_path="data/_master-data/tariffs/volumetric-schedule-model-input.xlsx",
        output_dir="data/common/TEST",
    )
