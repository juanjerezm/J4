# Technology Notes

## Assumptions

The following assumptions have been taken with regard to generation technologies:

- Ramping rate is disregarded, even though values are included in datasets.
- Minimum load is disregarded.

## District Heating Technologies

### CHP configuration

The configuration of the all cogeneration plants, excluding AMV4, is based on [Ommen et al, 2016](http://dx.doi.org/10.1016/j.energy.2015.10.063). This indicates back-pressure/extraction configuration, the option for turbine bypass, and priority access.

AMV4's configuration is taken from [Varmeplan Hovedstaden](https://varmeplanhovedstaden.dk/) and [HOFOR website](https://www.hofor.dk/baeredygtige-byer/fremtidens-fjernvarme/amagervaerket/blok-4-paa-amagervaerket/tekniske-facts-blok4/).

### Technical parameters

Technical parameters are obtained from different sources depending on the type of generator.

#### Boilers

Technical parameters (heating efficiency, VO&M and ramping) are taken from the [Technology Catalogue - Generation](https://ens.dk/en/our-services/projections-and-models/technology-data/technology-data-generation-electricity-and). The following spreadsheets are used:

- HOB_BG: 44 DH boiler, gas fired
- HOB_EL: 41 electric boiler, large
- HOB_GO: 44 DH boiler, gas fired
- HOB_GO_NOETS: 44 DH boiler, gas fired
- HOB_NG: 44 DH boiler, gas fired
- HOB_NG_NOETS: 44 DH boiler, gas fired
- HOB_WP: 09b Wood Pellets HOP

#### Heat Pumps

Technical parameters (VO&M and ramping) are taken from the [Technology Catalogue - Generation](https://ens.dk/en/our-services/projections-and-models/technology-data/technology-data-generation-electricity-and).

- HP_AMBIENT: 40 - Comp. hp, airsource 3 MW
- HP_PROCESS: 40 Comp. hp, excess heat 3 MW

Efficiency is calculated by `scripts/data/compute_COP.py`. The following parameters are used:

- DH distribution temperatures, as indicated in manuscript.
- Copenhagen's air temperatures for HP_AMBIENT, with 5 °C decrease at output.
- Process heat temperatures of 30/20 °C supply/return for HP_PROCESS.

#### Industrial heat

The following parameters are assumed:

- Heating efficiency is assumed to 1, i.e., all heat is delivered to the DH network.
- VO&M is assumed to be 0 €/MW~h~.

#### Back-pressure units

Total and electric efficiencies are obtained from [Ommen et al, 2016](http://dx.doi.org/10.1016/j.energy.2015.10.063) for all CHPs except AMV4, which is obtained from [Varmeplan Hovedstaden](https://varmeplanhovedstaden.dk/).

C~b~ is calculated as follows:
$$
    C_b = \frac{\eta_{electric}}{\eta_{total} -\eta_{electric}}
$$

The following spreadsheets from [Technology Catalogue - Generation](https://ens.dk/en/our-services/projections-and-models/technology-data/technology-data-generation-electricity-and) are used for costs:

- AMV1  : 09b Wood Pellets, Medium
- AMV4  : 09a Wood Chips, Large 50 degree
- ARC   : 08 WtE CHP, Large, 50 degree
- ARGO5 : 08 WtE CHP, Medium
- ARGO6 : 08 WtE CHP, Medium
- HCV7  : 01 Coal CHP (*assumed, actually the system is a steam turbine*)
- HCV8  : 05 Gas turb. CC, Back-pressure
- KKV8  : 09a Wood Chips, Medium
- VF5   : 08 WtE CHP, Medium
- VF6   : 08 WtE CHP, Medium

#### Extraction units

Total and electric efficiencies are obtained from [Ommen et al, 2016](http://dx.doi.org/10.1016/j.energy.2015.10.063).

C~v~ factors are obtained from [Ommen et al, 2014](http://dx.doi.org/10.1016/j.energy.2014.04.023).

C~b~factors are calculated as follows:
$$
    C_b = \frac{Y_{electric}}{Y_{heat}} - C_v
$$

Boiler ramping rates are taken from [Ommen et al, 2016](http://dx.doi.org/10.1016/j.energy.2015.10.063).

The following spreadsheets from [Technology Catalogue - Generation](https://ens.dk/en/our-services/projections-and-models/technology-data/technology-data-generation-electricity-and) are used for costs:

- AVV1  : 09b Wood Pellets extract. plant
- AVV2  : 09b Wood Pellets extract. plant

## Waste Heat Source

Their efficiencies are calculated by `scripts/python/compute_COP.py`, according to sources indicated in the manuscript.

The cost are obtained from from [Technology Catalogue - Generation](https://ens.dk/en/our-services/projections-and-models/technology-data/technology-data-generation-electricity-and):

- HR_DC: 40 Comp. hp, excess heat 3 MW.
- ELECTRIC_CHILLER: 40 - Comp. hp, airsource 3 MW, with costs adjusted as indicated below.
- FREE_COOLING: Assumed free.

### Electric chiller costs

The cost of the electric chiller is approximated by comparing it to the heat pump, using its efficiency and variable cost.

The variable cost is adjusted to €/MWh~cold~ by, using the HP's nameplate efficiency (COP) :
$$
C_{HP_{cold}} = C_{HP_{heat}}  \frac{COP_{h}}{COP_{h} - 1}
$$

This value would represent the variable cost of a heat pump per unit of cold produced. This cost is then scaled by the relative efficiency of the electric chiller, whose source is detailed in the manuscript. The variable cost of the electric chiller is then obtained by:
$$
C_{EC_{cold}} = C_{HP_{heat}}  \frac{COP_{HP_{heat}}}{COP_{EC_{cold}}}
$$
