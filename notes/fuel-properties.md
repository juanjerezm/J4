# Fuel Properties

## Sources

Fuel properties are drawn from the following sources:

1. **Danish Energy Agency** — *Samfundsøkonomiske beregningsforudsætninger for energipriser og emissioner 2025* (SØB25, final edition March 2026). Retrieved from [Samfundsøkonomiske analysemetoder](https://ens.dk/analyser-og-statistik/samfundsoekonomiske-analysemetoder) and saved at: `[data/_master-data/SØB25_marts26.xlsx]`.
2. **Danish Energy Agency** — *Technology Data for Energy Plants for Electricity and District Heating Generation* (Technology Catalogue). Retrieved from [Teknologikatalog for produktion af el og fjernvarme](https://ens.dk/analyser-og-statistik/teknologikatalog-produktion-af-el-og-fjernvarme) and saved at: `[data/_master-data/Technology Data Catalogue - 0017.pdf]`.
3. **Skatteministeriet** — [*Energy content of fuels*](https://info.skat.dk/data.aspx?oid=2061646).

## Fuels

### Biogas

> **Energy intensity**: Assumed to be identical to natural gas, with a value of 38.03 GJ/1000-Nm³ (SØB25, Table 1).
> **Carbon intensity**: Considered carbon-neutral, with an emission factor of 0 kg-CO₂/GJ (SØB25, Table 12).

### Electricity

> **Carbon intensity**: Variable and detailed in [electricity-data.md](./electricity-data.md).

### Industrial Heat

> **Carbon intensity**: Considered carbon-neutral provided that it is the result of an otherwise unavoidable economic activity.

### Gasoil

> **Energy intensity**: 35.90 GJ/Nm³ ([Skat](https://info.skat.dk/data.aspx?oid=2061646)).
> **Carbon intensity**: 74.10 kg-CO₂/GJ (SØB25, Table 12).

### Municipal Waste

> **Energy intensity**: 11.70 GJ/ton (SØB25, Table 1).
> **Carbon intensity**: 37.0 kg-CO₂/GJ *(Technology Catalogue, Chapter 08, Section "Environment")*, based on a typical emission factor for **fossil-CO₂** for the waste mixture currently incinerated in Denmark.
>
> **For the purposes of this study, it is assumed that 40% of the energy content of municipal waste is derived from non-biogenic waste** *(Technology Catalogue, Chapter 08, Section "Environment")*.

### Natural Gas

> **Energy intensity**: 38.03 GJ/1000-Nm³ (SØB25, Table 1).
> **Carbon intensity**: 57.1 kg-CO₂/GJ (SØB25, Table 13).

### Wood Chips

> **Energy intensity**: 10.40 GJ/ton (SØB25, Table 1).
> **Carbon intensity**: Considered carbon-neutral.

### Wood Pellets

> **Energy intensity**: 17.50 GJ/ton (SØB25, Table 1).
> **Carbon intensity**: Considered carbon-neutral.
