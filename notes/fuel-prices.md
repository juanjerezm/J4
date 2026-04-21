# Fuel Prices

## Description

The fuel prices used in this analysis correspond to Danish socioeconomic values for 2025, applied uniformly across all scenarios regardless of country. This ensures that energy policy parameters remain the only differentiating factor between country scenarios.

Socioeconomic prices exclude excise taxes, tariffs, VAT, and subsidies. Excise taxes and tariffs are described separately in [excise-taxes.md](./taxes.md) and [tariffs.md](./tariffs.md), respectively.

## Sources

Fuel prices are drawn from the following sources:

1. **Danish Energy Agency** — *Samfundsøkonomiske beregningsforudsætninger for energipriser og emissioner 2025* (SØB25, final edition March 2026). Retrieved from [Samfundsøkonomiske analysemetoder](https://ens.dk/analyser-og-statistik/samfundsoekonomiske-analysemetoder) and saved at: `[data/_master-data/SØB25_marts26.xlsx]`.
2. **Danish Energy Agency** — *Technology Data for Energy Plants for Electricity and District Heating Generation* (Technology Catalogue, Chapter 08: WtE CHP and HOP plants, version 0017, May 2025). Retrieved from [Teknologikatalog for produktion af el og fjernvarme](https://ens.dk/analyser-og-statistik/teknologikatalog-produktion-af-el-og-fjernvarme) and saved at: `[data/_master-data/Technology Data Catalogue - 0017.pdf]`.
3. **Danish Ministry of Climate, Energy, and Utilities** — *Klimastatus og -fremskrivning 2026: Affald Forudsætningsnotat* (KF26, 2026). Retrieved from [Klimastatus og -fremskrivning 2026](https://www.kefm.dk/klima/klimastatus-og-fremskrivning/klimastatus-og-fremskrivning-2026) and saved at: `[data/_master-data/KF26 forudsaetningsnotat Affald.pdf]`.

## Fuels

### Biogas

Biogas prices are taken from SØB25, Table 9 (*Samfundsøkonomiske biogaspriser an forbrugssted*), which provides socioeconomic prices broken down by annual consumption tier.

A single generator in `energy-producer-census-2024.xlsx` consumes biogas (ID: 970-2). Its consumption, at 15.76 TJ/year, places it in the **Forsyning, decentral 300,000–800,000 m³** tier. For this calculation, the heating value of natural gas (SØB25, Table 1a) is used.

The corresponding 2025 socioeconomic price is **194.4 kr./GJ**, which corresponds to **93.78 €/MWh**.

### Electricity

Electricity prices are detailed in [electricity-data.md](./electricity-data.md).

### Industrial Heat

Industrial heat is assumed to be free of charge for the DH utility.

### Gasoil

Gasoil prices are taken from SØB25, Table 2 (*Samfundsøkonomiske brændselspriser an forbrugssted*), which provides socioeconomic prices by consumer location, inclusive of CIF import price, transport, storage, and margin costs.

Gasoil-consuming generators in `energy-producer-census-2024.xlsx` are classified as decentralized plants, corresponding to the ***værk*** consumer type. The corresponding 2025 socioeconomic price is **126.8 kr./GJ**, which corresponds to **61.17 €/MWh**.

### Municipal Waste

Unlike conventional fuels, municipal waste carries a negative fuel price as incineration plants receive a gate fee (*modtagelsespris*) for accepting waste.

The gate fee is estimated at **20.20 €/MWh**, derived from the estimated Danish import price of approximately **490 kr./ton** (KF26, in 2026 prices) and a representative lower heating value of **11.7 GJ/ton** for Danish municipal solid waste (SØB25, Table 1a). It is noted that gate fees vary considerably across plants and are subject to significant uncertainty, as acknowledged in KF26, with a typical range between **340-610 kr./ton**.

### Natural Gas

Natural gas prices are taken from SØB25, Table 8 (*Samfundsøkonomiske gaspriser i det danske ledningsnet og an forbrugssted*), which provides socioeconomic prices broken down by consumer type and annual consumption tier, inclusive of transport, storage, and margin costs.

Generators consuming natural gas in `energy-producer-census-2024.xlsx` are predominantly decentralized plants of varying sizes. The average of the two decentralized tiers is therefore applied: **140.5 kr./GJ** (>800,000 m³) and **156.0 kr./GJ** (300,000–800,000 m³), yielding an average price of **148.25 kr./GJ**, corresponding to **71.52 €/MWh**.

### Woodchips

Woodchip prices are taken from SØB25, Table 2 (*Samfundsøkonomiske brændselspriser an forbrugssted*), which provides socioeconomic prices by consumer location, inclusive of CIF import price, transport, storage, and margin costs.

Woodchip-consuming generators in `energy-producer-census-2024.xlsx` are classified as central plants, corresponding to the ***kraftværk*** consumer type. The corresponding 2025 socioeconomic price is **75.3 kr./GJ**, which corresponds to **36.32 €/MWh**.

### Wood Pellets

Wood pellet prices are taken from SØB25, Table 2 (*Samfundsøkonomiske brændselspriser an forbrugssted*), which provides socioeconomic prices by consumer location, inclusive of CIF import price, transport, storage, and margin costs.

Wood pellet-consuming generators in `energy-producer-census-2024.xlsx` are largely classified as central plants, corresponding to the ***kraftværk*** consumer type. The corresponding 2025 socioeconomic price is **85.2 kr./GJ**, which corresponds to **41.07 €/MWh**.
