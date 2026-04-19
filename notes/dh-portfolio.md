# Generation Portfolio  

This document describes the process followed to define the generation portfolio for this analysis, including data cleaning, unit categorisation, assumptions, and specific adjustments.

## Source  

The primary dataset is the **Energy Producer Census** from the [Danish Energy Agency](https://ens.dk/analyser-og-statistik/data-oversigt-over-energisektoren). The 2024 release (covering years 2022–2024) was used, particularly data pertaining to **2023**.

The dataset is stored in `data/_master_data/energy-producer-census-2024.xlsx`, which contains:  

- the original datasheet (`original_file`),  
- a filtered and classified datasheet (`filtered_classified`),  
- a filtered and classified datasheet, with multi-fuel units separated (`filtered_classified_split`), and
- a final consolidation sheet (`consolidated`).  

Each row in the dataset corresponds to a **generation unit**. A single generation facility (or plant) may contain multiple units.  

## Data Cleaning  

The dataset was filtered as follows:  

1. Excluded rows where the year (`aar`) ≠ 2023.  
2. Excluded rows where the district heating network name (`fv_net_navn`) ≠ *Storkøbenhavns Fjernvarme* (Copenhagen).  
3. Excluded rows with heating capacity (`varmekapacitet_MW`) ≤ 0.  
4. Excluded rows where the share of process heating (`andel_process`) = 100% (i.e. units delivering heat exclusively for internal processes).  
5. Excluded rows where the share of process heating (`andel_process`) > 15%.  

## Unit Classification  

Each unit was classified according to the following criteria, which guided the consolidation:  

1. **Category**  
   - Units with electrical capacity (`elkapacitet_MW`) > 0 → *CHP units*.  
   - Units with no electrical capacity → *heat-only (HO) units*.  

2. **Technology type**  
   - As reported in the dataset (`anlaegstype_navn`).  

3. **Fuel**  
   - Based on reported fuel shares in 2023.  
   - Shares < 10% were treated as startup fuels and assumed to be identical to the primary fuel.  
   - Units not operating in 2023 were assigned *unknown fuel* where it could not be inferred.  
   - Units with ≥ 2 fuels above 10% were considered **multi-fuel**; their capacities were split proportionally by fuel share.

4. **ETS applicability**  
   - As reported in the dataset (`kvoteaktivitet`).  
   - Units < 20 MW may still fall under ETS if the plant-level capacity (sum of units) exceeds this threshold.  

5. **Operational status (2023)**  
   - Categorised as *active*, *decommissioned*, or *inoperative*.  

6. **Heat pump source**  
   - Categorised as *process heat* (overskudsvarme) or *ambient* (air, water, etc.).  

Then, units are consolidated into specific **MODEL_NAMES** based on this classification.
Units with unknown fuel or decommissioned status were not assigned to model categories.  

## Specific Adjustments  

The following units were excluded despite meeting the above criteria:  

- ID 808-5 – *Spildevandscenter Avedøre* (low-capacity CHP)  
- ID 970-4 – *VEKS – Solrød Kedelcentral* (low-capacity CHP)  
- ID 2303-1 – *Solvarmecentral Vesterled* (small unique solar unit)  
- ID 1922-1 – *Geotermisk anlæg, Amagerværket* (inoperative testing unit)  
- ID 332-2 – *Svanemølleværket* (SMV1 & SMV7 removed as per [Ørsted](https://orsted.dk/vores-groenne-loesninger/bioenergi/vores-kraftvarmevaerker)).

The following adjustments were made to multi-fuel units:

- ID 269-2 - *Avedøreværket, AVV2*: a 100% wood pellet share is assumed to avoid including straw as an additional fuel within the model (original shares: 3% natural gas, 12% straw, 85% wood pellets).
- ID 244-2 - *I/S Amager Ressourcecenter*: separated into 77% municipal waste, 23% wood waste.
- ID 73-1 - *CTR, Nybrovej Centralen*: separated into 12% gasoil  and 88% natural gas.
- ID 285-5 - *I/S Vestforbrænding*: separated into 19% gasoil  and 81% natural gas.
- ID 285-6 - *I/S Vestforbrænding*: separated into 19% gasoil  and 81% natural gas.
- ID 285-7 - *I/S Vestforbrænding*: separated into 15% gasoil  and 85% natural gas.
- ID 2075-2 - *Høje Taastrup Fjernvarme - Malervej-centralen*: separated into 37% gasoil and 63% natural gas.

## CHP turbine configuration

Heating capacities stated in the Energy Producer Census (EPC) seem to not include turbine bypass. The following reasons apply:

- [ARC website](https://a-r-c.dk/amager-bakke/teknik/) mentions the existence of a turbine-bypass, while indicating a maximum heating capacity up to 247 MW~h~, which is in the range (although higher) of its boiler capacity.
- [HOFOR website](https://www.hofor.dk/baeredygtige-byer/fremtidens-fjernvarme/amagervaerket/blok-4-paa-amagervaerket/tekniske-facts-blok4/) also mentions the existence of a turbine-bypass for AMV4. It also clearly states nominal heating capacity that matches EPC, and explicitly states 150 MW~h~ extra due to turbine bypass.
- [Varmeplan Hovedstaden](https://varmeplanhovedstaden.dk/) technical data includes heating capacity and extra bypass capacity separately. Although they don't exactly match EPC, nominal capacities are in the range of what's stated in EPC.

- HCV 7: Its firing capacity is 200 MW, even though its heating capacity is significantly larger. The real boiler capacity is 285 MW, but it is restricted in its operation ([source](https://dma.mst.dk/vis-sag/1352675)). Additionally, EPC seems to indicate a heating capacity that includes bypass.

In a similar way, data from Varmeplan Hovedstaden seems to indicate that EPC reports condensing capacity.
