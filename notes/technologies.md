# Technology Notes

## Assumptions
- Ramping rate of is assumed as 100% for all technologies.
- All cogeneration technologies are assumed as backpressure configuration.
- Minimum load is disregarded.
 
## Data Sources
Datasheets from technology catalogue:

| Name                   | Source                           | Comment                                                               |
|------------------------|----------------------------------|-----------------------------------------------------------------------|
| electric chiller       | 40 Comp. hp, excess heat 3 MW    | Efficiency and variable cost (adjusted according to comment below)    |
| free cooling           | -                                |                                                                       |
| HP - waste heat        | 40 Comp. hp, excess heat 3 MW    |                                                                       |
| CHP - coal             | 01 Coal CHP                      | Data for extraction unit, assumed to apply for backpressure           |
| CHP - natural gas      | 04 Gas turb. simple cycle, L     |                                                                       |
| HOB - natural gas      | 44 Natural Gas DH Only           | * Efficiency without condensing economizer                            |
| CHP - biomass residues | 09c Straw, Large, 40 degree      |                                                                       |
| CHP - wood chips       | 09a Wood Chips, Medium           |                                                                       |
| HP - seawater          | 40 Comp. hp, seawater 20 MW      |                                                                       |
| HP - air               | 40 Comp. hp, airsource 10 MW     |                                                                       |
| HOB electricity        | 41 Electric boiler, large        |                                                                       |

### Determining cooling cost of electric chiller
The cost of the electric chiller is approximated by comparing it to the heat pump, using its efficiency and variable cost.

The variable cost is adjusted to €/MWh~cold~ by, using the HP's nameplate efficiency (COP) :
$$
C_{HP_{cold}} = C_{HP_{heat}}  \frac{COP_{h}}{COP_{h} - 1}
$$

This value would represent the variable cost of a heat pump per unit of cold produced. This cost is then scaled by the relative efficiency of the electric chiller, whose source is detailed in my papers. The variable cost of the electric chiller is then obtained by:
$$
C_{EC_{cold}} = C_{HP_{heat}}  \frac{COP_{HP_{heat}}}{COP_{EC_{cold}}}
$$
