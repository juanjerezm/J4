# Notes on Electricity Tariffs

## Electricity consumers

The following electricity consumers are present in the portfolio in the current analysis:

> **Waste-heat source**
>
> - Cold-only generators (*< 10 MW*)
> - Heat-recovery generator (*< 10 MW*)
>
> **District heating network:**
>
> - Heat pumps from ambient sources (HP_AMBIENT, *< 10 MW*)
> - Heat pumps driven by process heat (HP_PROCESS, *< 10 MW*)
> - Electric boilers (HOB_EL, *120 MW*), consisting in the unaggregated data of two separate units of 40 MW and 80 MW.

## Voltage levels

The applicable grid voltage level is determined by the size of the electrical load at the connection point. All consumer types below 10 MW are assumed to connect at 20 kV medium voltage in all three countries, consistent with standard DSO practice for industrial customers at this scale.

For the electric boiler units (40 MW and 80 MW), the assumed voltage level differs by country, reflecting the distinct grid voltage hierarchies in each jurisdiction. Denmark operates intermediate sub-transmission levels at 50 kV and 132 kV; France similarly has distinct levels at 63 kV and 90 kV. Germany, by contrast, has no standard intermediate voltage level between 20 kV and 110 kV — the grid moves directly from Mittelspannung (20 kV) to Hochspannung (110 kV). As a result, both the 40 MW and 80 MW units are assigned to 110 kV in Germany, regardless of size.

| Load size | Denmark | Germany | France |
| --------- | ------- | ------- | ------ |
| < 10 MW   | 20 kV   | 20 kV   | 20 kV  |
| 40 MW     | 50 kV   | 110 kV  | 63 kV  |
| 60 MW     | 132 kV  | 110 kV  | 90 kV  |
| 80 MW     | 132 kV  | 110 kV  | 90 kV  |

## Tariffs per country

### Denmark

Danish transmission and distribution tariffs are calculated separately by the Transmission System Operator (TSO) and Distribution System Operators (DSOs), respectively. The TSO is Energinet, while there are multiple DSOs across the country. The total network tariff paid by the consumer is the sum of both ([Nordic Energy Regulators, p. 29](https://nordicenergyregulators.org/Media/638995687807590313/20210216-NR-WG-Tariff-report.pdf)).

It is important to note that voltage levels and time-of-use schedules vary across DSOs, which may lead to different tariff structures. **For the purpose of this analysis, the distribution tariff of Radius is used as a representative example (Copenhagen area).**

#### Sources

1. Transmission tariffs are obtained from [Energinet's website](https://en.energinet.dk/electricity/tariffs/current-tariffs/), (historical tariffs are available at the end of the page). This file is locally saved as ["energinet-tariffs-historical.xlsx"](../data/_master-data/energinet-tariffs-historical.xlsx) on this repository.
2. Distribution tariffs are obtained from Radius' [price list](https://radiuselnet.dk/priser/alle/) and [price explanation](https://radiuselnet.dk/priser/alle/prisforklaring/) websites. Historical 2025's tariffs are locally saved as ["radius-tariffs-2025.pdf"](../data/_master-data/radius-tariffs-2025.pdf) on this repository.

### Tariff structure

As of 2025, the transmission tariff structure consisted of two volumetric components (*transmissionsnettarif* and *systemtarif*) as well as a fixed component per connection point, which is  disregarded from this analysis.

The distribution tariff structure consists of a fixed component per connection point, a capacity componenet, and a volumetric component. The latter is time-differentiated by time-of-use and season. The former is disregarded from this analysis.

#### Tariff categories

Tariff type is determined by the voltage level of the connection point as indicated in [Radius' website](https://radiuselnet.dk/priser/alle/). The following table summarizes the tariff types assumed in this analysis:

| Load size | Tension level | Tariff type |
| --------- | ------------- | ----------- |
| < 10 MW   |  20 kV        | A-lav       |
| 40 MW     |  50 kV        | A-høj       |
| 60 MW     | 132 kV        | A-høj+      |
| 80 MW     | 132 kV        | A-høj+      |

Although A-høj+ corresponds to transmission voltage levels (132–150 kV), customers in this category connect at the low-voltage busbar (30–60 kV side) of the 132–150/30–60 kV transformer station. The connection point is therefore within the DSO network, and both DSO and TSO tariff components apply.

---

### Germany

Germany's transmission network is operated by four Transmission System Operators (TSOs) — 50Hertz, Amprion, TenneT, and TransnetBW — each covering distinct regional control areas. Since 2023, transmission tariffs have been harmonised into a single nationally unified tariff level, meaning the TSO control area is irrelevant for tariff purposes. On the distribution side, there are approximately 900 Distribution System Operators (DSOs) across the country. These share a common regulated tariff structure — defined by the Stromnetzentgeltverordnung (StromNEV) — but tariff levels vary significantly across DSOs.

National average network tariff statistics are published annually by the Bundesnetzagentur, but these are reported as blended averages (ct/kWh) and are not disaggregated by capacity component, volumetric component, or load profile. **Therefore, for the purpose of this analysis, the distribution tariff of Stromnetz Berlin GmbH is used as a representative example.**

Unlike in Denmark, the consumer does not pay TSO and DSO tariffs as separate line items. Instead, DSO charges include upstream transmission costs passed through in a single bill ([Bundesnetzagentur](https://www.bundesnetzagentur.de/EN/RulingChambers/Chamber8/RC8_06_Network%20charges/RC8_06_Network%20charges.html)).

#### Sources

1. Berlin's distribution tariffs are obtained from Stromnetz Berlin's [price list](https://www.stromnetz.berlin/en/grid-use/fees/). Historical 2025's tariffs are locally saved as ["stromnetz-berlin-tariffs-2025.pdf"](../data/_master-data/stromnetz-berlin-tariffs-2025.pdf) on this repository.

#### Tariff structure

The tariff structure mandated by StromNEV consists of several components for industrial customers. Most importantly, a **capacity component** (*Leistungspreis*, €/kW/year) based on the highest 15-minute average demand peak recorded during the billing period, and a **volumetric component** (*Arbeitspreis*, ct/kWh) applied to total energy consumed. For this analysis, only these two components are considered; additional levies such as the Konzessionsabgabe, KWKG surcharge, and Offshore-Netzumlage are excluded.

Two metering systems are available. Under the *Jahresleistungspreissystem* (annual peak system), the Leistungspreis is based on the single highest demand peak recorded across the entire year — **this is the standard system for large industrial customers and is used in this analysis**. The alternative *Monatsleistungspreissystem* (monthly peak system) determines the Leistungspreis based on the highest peak in each individual month and is more common for customers with variable load profiles.

Time-of-use tariffs have been gradually introduced since 2025 under §14a EnWG, but apply primarily to controllable residential and small commercial loads such as heat pumps and electric vehicles. For industrial customers at medium and high voltage no time-of-use differentiation applies.

There are, however, two tariff subtypes differentiated by annual utilisation hours, serving as a proxy for load profile. Customers with **2,500 or more full-load hours per year** are charged a high Leistungspreis and low Arbeitspreis, reflecting the grid planning benefit of a steady, predictable load. Customers with **fewer than 2,500 full-load hours per year** face a low Leistungspreis and high Arbeitspreis, reflecting more peaky and less predictable demand.


#### Tariff categories

The applicable tariff type is determined by the voltage level of the grid connection point, as specified in the Stromnetz Berlin price sheet (Kapitel 3.1.1). The following table summarises the resulting tariff categories considered in this analysis:

| Load size | Tension level | Tariff type    | Tariff subtype |
| --------- | ------------- | -------------- | -------------- |
| < 10 MW   |  20 kV        | Mittelspannung | > 2500 h/year  |
| 40 MW     | 110 kV        | Hochspannung   | < 2500 h/year  |
| 60 MW     | 110 kV        | Hochspannung   | < 2500 h/year  |
| 80 MW     | 110 kV        | Hochspannung   | < 2500 h/year  |

---

### France

French network transmission and distribution tariffs are unified and nationally regulated under the the **TURPE 7** (*Tarif d'Utilisation des Réseaux Publics d'Électricité*) framework, which has been in force since 1 August 2025.

#### Source

The full tariff structure is documented in the official [TURPE 7 consumer and generator guide](https://www.services-rte.com/files/live//sites/services-rte/files/documentsLibrary/Understanding_the_tariff_TURPE_7_Consumers_and_Generators_7847_en). This document has been locally saved as ["TURPE-7-guide.pdf"](../data/_master-data/TURPE-7-guide.pdf) on this repository.

#### Tariff structure

The TURPE 7 tariff comprises three component groups: fixed annual components, extraction components (power and energy), and technical components (*TURPE 7 guide, p. 6*). This analysis considers only the extraction components, as the fixed components are invariant and the technical components are out of scope.

The extraction component consists of three sub-components (*TURPE 7 guide, p. 8*): a capacity term, a volumetric term, and a capacity overrun penalty. The latter applies only when consumption exceeds the subscribed capacity and is excluded here.

Both the volumetric and capacity terms are time-differentiated (*TURPE 7 guide, p. 23*) by time-of-day and season. There is a different schedule for saturdays, sundays, and public holidays, but these are disregarded in this analysis for simplicity.

The volumetric term is based on time-of-use of energy; the capacity term is based on the maximum power subscribed per time slot. In this analysis, a flat subscription is assumed — the peak load is subscribed uniformly across all time slots — which simplifies the capacity term to a single coefficient *b₁* .

#### Tariff categories

Tariff type is determined by voltage level (*TURPE 7 guide, p. 21*) and its subtype is assumed based on load characteristics (*TURPE 7 guide, p. 22*). The following table summarizes the tariff types and subtypes considered in this analysis:

| Load size | Tension level | Tariff type | Tariff subtype |
| --------- | ------------- | ----------- | -------------- |
| < 10 MW   | 20 kV         | HV-A 1      | LTU            |
| 40 MW     | 63 kV         | HV-B 1      | MTU            |
| 60 MW     | 90 kV         | HV-B 1      | MTU            |
| 80 MW     | 90 kV         | HV-B 1      | MTU            |

---
