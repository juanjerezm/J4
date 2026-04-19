# Fuel Emissions

## Sources

Fuel emission factors are drawn from the following sources:

1. **Danish Energy Agency** — *Samfundsøkonomiske beregningsforudsætninger for energipriser og emissioner 2025* (SØB25, final edition March 2026). Retrieved from [Samfundsøkonomiske analysemetoder](https://ens.dk/analyser-og-statistik/samfundsoekonomiske-analysemetoder) and saved at: `[data/_master-data/SØB25_marts26.xlsx]`.
2. **Danish Energy Agency** — *Technology Data for Energy Plants for Electricity and District Heating Generation* (Technology Catalogue, Chapter 08: WtE CHP and HOP plants, version 0017, May 2025). Retrieved from [Teknologikatalog for produktion af el og fjernvarme](https://ens.dk/analyser-og-statistik/teknologikatalog-produktion-af-el-og-fjernvarme) and saved at: `[data/_master-data/Technology Data Catalogue - 0017.pdf]`.

## Fuels

### Biogas

Biogas is considered carbon-neutral, with an emission factor of 0 kg-CO₂/MWh, as per SØB25, Table 12.

### Electricity

Electricity emission factors are variable and are detailed in [electricity-data.md](./electricity-data.md).

### Industrial Heat

Industrial heat is assumed to be carbon-neutral, provided that it is the result of an otherwise unavoidable economic activity.

### Gasoil

Gasoil has an emission factor of 266.76 kg-CO₂/MWh, as per SØB25, Table 12.

### Municipal Waste

Municipal waste is assumed to have an emission factor of 133.20 kg-CO₂/MWh, as suggested by the Technology Catalogue (Chapter 08, Section Environment) based on a representative values for Danish municipal solid waste.

### Natural Gas

Natural gas has an emission factor of 205.56 kg-CO₂/MWh, as per SØB25, Table 13.

### Wood Chips and Pellets

Wood chips and pellets are considered carbon-neutral, with an emission factor of 0 kg-CO₂/MWh, as per SØB25, Table 12.
